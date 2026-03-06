from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.email import Email
from app.models.user import User
from app.schemas.email import EmailOut
from app.utils.email_sender import sendMailUsingSendGrid


async def send_email_and_log(
    db: AsyncSession,
    *,
    owner_id: int,
    client_id: Optional[int],
    to_email: str,
    subject: str,
    body: str,
    reply_to: str,
    ai_generated: bool = False,
    ai_model: Optional[str] = None,
):
    email = Email(
        owner_id=owner_id,
        client_id=client_id,
        to_email=to_email,
        subject=subject,
        body=body,
        ai_generated=ai_generated,
        ai_model=ai_model,
        status="pending",
    )
    db.add(email)
    await db.commit()
    await db.refresh(email)
    try:
        sendMailUsingSendGrid(
            to_email=to_email, subject=subject, html_content=body, reply_to=reply_to
        )
        email.status = "sent"
    except Exception:
        email.status = "failed"
    await db.commit()
    owner_result = await db.execute(select(User).where(User.id == owner_id))
    owner = owner_result.scalar_one_or_none()
    sender_email = owner.email if owner else reply_to
    return EmailOut.from_orm_with_sender(email, sender_email)
