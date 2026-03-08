from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.core.config import settings
from app.api.deps import get_current_user
from app.schemas.client import ClientCreate, ClientUpdate, ClientOut
from app.schemas.common import Paginated, PageMeta
from app.schemas.attachment import DeleteAttachmentRequest
from app.services import client_service
from app.services import attachment_service
from app.services import email_service
from app.services.cache_service import get_or_set_cache, invalidate_pattern
from app.services.storage_service import generate_signed_url
from app.models.client import Client

router = APIRouter(prefix="/clients", tags=["clients"])


async def convert_client_urls(client_dict: dict) -> dict:
    if client_dict.get("company_logo"):
        try:
            client_dict["company_logo"] = await generate_signed_url(
                path=client_dict["company_logo"],
                expires_in=3600,
                bucket=settings.SUPABASE_ATTACHMENT_BUCKET,
            )
        except:
            pass
    if client_dict.get("attachments"):
        signed_attachments = []
        for att in client_dict["attachments"]:
            if isinstance(att, str):
                try:
                    signed_url = await generate_signed_url(
                        path=att,
                        expires_in=3600,
                        bucket=settings.SUPABASE_ATTACHMENT_BUCKET,
                    )
                    signed_attachments.append(signed_url)
                except:
                    signed_attachments.append(att)
            else:
                signed_attachments.append(att)
        client_dict["attachments"] = signed_attachments
    return client_dict


@router.post("/", response_model=ClientOut)
async def create_client(
    payload: ClientCreate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.subscription_status != "active":
        from sqlalchemy import func

        count_q = (
            select(func.count())
            .select_from(Client)
            .where(Client.owner_id == current_user.id)
        )
        total_clients = (await db.execute(count_q)).scalar_one()
        if total_clients >= 50:
            raise HTTPException(
                status_code=403,
                detail="You have reached the 50 client limit on the Basic plan. Please upgrade your plan to add unlimited clients.",
            )
    obj = await client_service.create_client(
        db, owner_id=current_user.id, **payload.model_dump()
    )
    await invalidate_pattern(f"cache:clients:{current_user.id}*")
    return ClientOut.model_validate(obj)


@router.get("/{client_id}/emails")
async def list_client_emails(
    client_id: int,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    client = await client_service.get_client_by_id(db, client_id)
    if not client:
        raise HTTPException(404, "Client not found")
    if client.owner_id != current_user.id and current_user.role != "admin":
        raise HTTPException(403, "Forbidden")
    return await email_service.list_client_emails(db, client_id)


@router.put("/{client_id}/company-logo")
async def upload_company_logo(
    client_id: int,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = await attachment_service.upload_company_logo(
        db=db, client_id=client_id, file=file, current_user=current_user
    )
    return {"status": "ok", "path": result["path"], "signed_url": result["signed_url"]}


@router.get("/{client_id}/logo")
async def get_company_logo(
    client_id: int,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    logo = await attachment_service.get_company_logo(db, client_id, current_user)
    return {"logo": logo}


@router.delete("/{client_id}/logo")
async def delete_company_logo(
    client_id: int,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    await attachment_service.delete_company_logo(db, client_id, current_user)
    return {"status": "deleted"}


@router.patch("/patch/{client_id}", response_model=ClientOut)
async def update_client(
    client_id: int,
    payload: ClientUpdate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    obj = await client_service.update_client(
        db, client_id, current_user, **payload.model_dump(exclude_unset=True)
    )
    if not obj:
        raise HTTPException(status_code=404, detail="Client not found")
    await invalidate_pattern(f"cache:clients:{current_user.id}*")
    return ClientOut.model_validate(obj)


@router.post("/{client_id}/upload")
async def upload_attachment(
    client_id: int,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    url = await attachment_service.upload_and_attach(
        db=db,
        client_id=client_id,
        file=file,
        current_user=current_user,
    )
    return {"status": "ok", "signed_url": url, "name": file.filename}


@router.get("/{client_id}/attachments")
async def get_attachments(
    client_id: int,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return await attachment_service.get_all_attachments(db, client_id, current_user)


@router.post("/{client_id}/attachments/delete")
async def delete_attachment(
    client_id: int,
    body: DeleteAttachmentRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    await attachment_service.delete_attachment(
        db=db,
        client_id=client_id,
        path=body.path,
        current_user=current_user,
    )
    return {"status": "ok"}


@router.delete("/{client_id}")
async def delete_client(
    client_id: int,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    ok = await client_service.delete_client(db, client_id, current_user)
    if not ok:
        raise HTTPException(404, "Client not found")
    await invalidate_pattern(f"cache:clients:{current_user.id}*")
    await invalidate_pattern(f"cache:tasks_client:{current_user.id}:{client_id}")
    return {"status": "deleted"}


@router.get("/", response_model=Paginated)
async def list_clients(
    page: int = 1,
    size: int = 20,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    owner_id = current_user.id
    cache_key = f"cache:clients:{current_user.id}:{page}:{size}"

    async def fetch():
        items, total = await client_service.list_clients(db, owner_id, page, size)
        client_dicts = [ClientOut.model_validate(i).model_dump() for i in items]
        for client_dict in client_dicts:
            await convert_client_urls(client_dict)
        return {
            "items": client_dicts,
            "meta": {"page": page, "size": size, "total": total},
        }

    data = await get_or_set_cache(cache_key, fetch)
    return Paginated(
        items=[ClientOut(**i) for i in data["items"]], meta=PageMeta(**data["meta"])
    )
