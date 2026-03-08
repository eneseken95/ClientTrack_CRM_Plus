from pydantic import BaseModel
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.db import get_db
from app.core.config import settings
from app.api.deps import get_current_user
from app.models.client import Client
from app.schemas.email import EmailCreate, EmailOut
from app.services.email_service import delete_email_by_id
from app.services.ai_email_service import polish_email_draft
from app.services.rate_limit_service import rate_limit_or_429
from app.services.email_log_service import send_email_and_log
from app.services.storage_service import generate_signed_url
from app.utils.email_templates import render_client_email

router = APIRouter(prefix="/emails", tags=["emails"])


@router.get("/", response_model=list[EmailOut])
async def list_all_emails(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    from app.models.email import Email

    result = await db.execute(
        select(Email)
        .where(Email.owner_id == current_user.id)
        .order_by(Email.sent_at.desc())
    )
    emails = result.scalars().all()
    client_ids = {e.client_id for e in emails if e.client_id}
    unlinked_emails = {e.to_email for e in emails if not e.client_id}
    client_map_by_id = {}
    client_map_by_email = {}
    if client_ids or unlinked_emails:
        queries = []
        if client_ids:
            queries.append(Client.id.in_(client_ids))
        if unlinked_emails:
            queries.append(Client.email.in_(unlinked_emails))
        from sqlalchemy import or_

        client_result = await db.execute(
            select(Client).where(Client.owner_id == current_user.id, or_(*queries))
        )
        for c in client_result.scalars().all():
            client_map_by_id[c.id] = c
            if c.email:
                client_map_by_email[c.email] = c
    out = []
    for e in emails:
        client = (
            client_map_by_id.get(e.client_id)
            if e.client_id
            else client_map_by_email.get(e.to_email)
        )
        company_logo = client.company_logo if client else None
        if company_logo and not company_logo.startswith("http"):
            company_logo = await generate_signed_url(
                company_logo,
                expires_in=3600,
                bucket=settings.SUPABASE_ATTACHMENT_BUCKET,
            )
        out.append(
            EmailOut.from_orm_with_sender(
                e,
                current_user.email,
                client_name=(
                    f"{client.name} {client.surname or ''}".strip() if client else None
                ),
                client_company_logo=company_logo,
            )
        )
    return out


class AiPolishRequest(BaseModel):
    subject: str
    body: str


@router.post("/ai-polish")
async def ai_polish(
    payload: AiPolishRequest,
    current_user=Depends(get_current_user),
):
    if current_user.subscription_status != "active":
        raise HTTPException(
            status_code=403,
            detail="AI features are only available on premium plans. Please upgrade your plan.",
        )
    await rate_limit_or_429(
        purpose="ai_polish",
        identifier=f"user:{current_user.id}",
        limit=5,
        window_seconds=60,
    )
    full_name = f"{current_user.name} {current_user.surname or ''}".strip()
    return await polish_email_draft(
        subject=payload.subject,
        body=payload.body,
        sender_name=full_name,
    )


@router.post("/send-ai", response_model=EmailOut)
async def send_ai_email(
    payload: EmailCreate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    await rate_limit_or_429(
        purpose="email_send_ai",
        identifier=f"user:{current_user.id}",
        limit=2,
        window_seconds=30,
    )
    client = None
    if payload.client_id is not None:
        res = await db.execute(
            select(Client).where(
                Client.id == payload.client_id, Client.owner_id == current_user.id
            )
        )
        client = res.scalar_one_or_none()
        if not client:
            raise HTTPException(
                status_code=403, detail="Client not found or not owned by user"
            )
    html_body = render_client_email(
        client_name=client.name if client else "there",
        sender_name=current_user.name,
        sender_email=current_user.email,
        body_text=payload.body,
    )
    return await send_email_and_log(
        db,
        owner_id=current_user.id,
        client_id=payload.client_id,
        to_email=payload.to_email,
        subject=payload.subject,
        body=html_body,
        reply_to=current_user.email,
        ai_generated=True,
        ai_model=settings.OPENROUTER_MODEL,
    )


@router.post("/send", response_model=EmailOut)
async def send_email(
    payload: EmailCreate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    await rate_limit_or_429(
        purpose="email_send",
        identifier=f"user:{current_user.id}",
        limit=2,
        window_seconds=30,
    )
    client = None
    if payload.client_id is not None:
        res = await db.execute(
            select(Client).where(
                Client.id == payload.client_id, Client.owner_id == current_user.id
            )
        )
        client = res.scalar_one_or_none()
        if not client:
            raise HTTPException(
                status_code=403, detail="Client not found or not owned by user"
            )
    html_body = render_client_email(
        client_name=client.name if client else "there",
        sender_name=current_user.name,
        sender_email=current_user.email,
        body_text=payload.body,
    )
    return await send_email_and_log(
        db,
        owner_id=current_user.id,
        client_id=payload.client_id,
        to_email=payload.to_email,
        subject=payload.subject,
        body=html_body,
        reply_to=current_user.email,
        ai_generated=False,
        ai_model=None,
    )


@router.delete("/{email_id}")
async def delete_email(
    email_id: int,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    ok = await delete_email_by_id(
        db,
        email_id=email_id,
        owner_id=current_user.id,
    )
    if not ok:
        raise HTTPException(
            status_code=404, detail="Email not found or not owned by user"
        )
    return {"message": "Email deleted successfully"}
