from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
from app.models.email import Email
from app.repositories import email_repo
from app.services.email_log_service import send_email_and_log
from app.utils.email_templates import render_task_deadline_email
from datetime import datetime
from zoneinfo import ZoneInfo

TURKEY_TZ = ZoneInfo("Europe/Istanbul")


async def list_client_emails(db: AsyncSession, client_id: int):
    from sqlalchemy import select
    from app.models.user import User
    from app.schemas.email import EmailOut

    emails = await email_repo.list_by_client(db, client_id)
    result = []
    for email in emails:
        owner_result = await db.execute(select(User).where(User.id == email.owner_id))
        owner = owner_result.scalar_one_or_none()
        sender_email = owner.email if owner else "unknown@example.com"
        email_out = EmailOut.from_orm_with_sender(email, sender_email)
        result.append(email_out)
    return result


async def send_task_reminder_email(
    *,
    db: AsyncSession,
    owner_id: int,
    client_id: Optional[int],
    to_email: str,
    user_name: str,
    task_title: str,
    due_date: datetime,
    reply_to: str,
):
    subject = f"Task Reminder: {task_title}"
    formatted_date = format_due_date(due_date)
    html_body = render_task_deadline_email(
        task_title=task_title, due_date=formatted_date, user_name=user_name
    )
    await send_email_and_log(
        db=db,
        owner_id=owner_id,
        client_id=client_id,
        to_email=to_email,
        subject=subject,
        body=html_body,
        reply_to=reply_to,
        ai_generated=False,
    )


async def delete_email_by_id(
    db: AsyncSession,
    *,
    email_id: int,
    owner_id: int,
) -> bool:
    res = await db.execute(
        select(Email).where(Email.id == email_id, Email.owner_id == owner_id)
    )
    email = res.scalar_one_or_none()
    if not email:
        return False
    await db.execute(delete(Email).where(Email.id == email_id))
    await db.commit()
    return True


def format_due_date(due_date: datetime) -> str:
    due_date_local = due_date.astimezone(TURKEY_TZ)
    date_part = due_date_local.strftime("%d %B %Y")
    time_part = due_date_local.strftime("%H:%M")
    return f"{date_part} • {time_part}"
