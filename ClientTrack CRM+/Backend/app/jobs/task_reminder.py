from apscheduler.schedulers.asyncio import AsyncIOScheduler
from app.core.db import SessionLocal
from app.services import task_service, email_service
from app.repositories import user_repo
from app.core.config import settings

scheduler = AsyncIOScheduler()


async def check_due_tasks():
    async with SessionLocal() as db:
        tasks = await task_service.get_tasks_due_soon(db)
        for task in tasks:
            user = await user_repo.get_by_id(db, task.owner_id)
            await email_service.send_task_reminder_email(
                db=db,
                owner_id=task.owner_id,
                client_id=task.client_id,
                to_email=user.email,
                user_name=user.name,
                task_title=task.title,
                due_date=task.due_date,
                reply_to=settings.SENDGRID_SENDER,
            )
            await task_service.mark_reminder_sent(db, task.id)


def start_scheduler():
    scheduler.add_job(check_due_tasks, "interval", minutes=1)
    scheduler.start()
