from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload
from app.models.task import Task
from datetime import datetime, timedelta, timezone


async def create(db: AsyncSession, **kwargs) -> Task:
    obj = Task(**kwargs)
    db.add(obj)
    await db.commit()
    await db.refresh(obj, ["client"])
    return obj


async def get(db: AsyncSession, id: int) -> Task:
    res = await db.execute(
        select(Task).options(joinedload(Task.client)).where(Task.id == id)
    )
    return res.scalar_one_or_none()


async def list_by_owner(db: AsyncSession, owner_id: int):
    stmt = (
        select(Task)
        .options(joinedload(Task.client))
        .where(Task.owner_id == owner_id)
        .order_by(Task.created_at.desc())
    )
    result = await db.execute(stmt)
    return result.scalars().all()


async def list_by_client(db: AsyncSession, owner_id: int, client_id: int):
    stmt = (
        select(Task)
        .options(joinedload(Task.client))
        .where(Task.owner_id == owner_id, Task.client_id == client_id)
        .order_by(Task.created_at.desc())
    )
    result = await db.execute(stmt)
    return result.scalars().all()


async def get_tasks_due_soon(db: AsyncSession, lead_minutes: int = 2):
    now = datetime.now(timezone.utc)
    window_start = now
    window_end = now + timedelta(minutes=lead_minutes)
    stmt = select(Task).where(
        Task.due_date != None,
        Task.reminder_sent == False,
        Task.due_date > window_start,
        Task.due_date <= window_end,
    )
    res = await db.execute(stmt)
    return res.scalars().all()


async def update(db: AsyncSession, id: int, **kwargs) -> Task:
    obj = await get(db, id)
    if not obj:
        return None
    for k, v in kwargs.items():
        if v is not None:
            setattr(obj, k, v)
    await db.commit()
    await db.refresh(obj)
    return obj


async def mark_reminder_sent(db: AsyncSession, task_id: int):
    stmt = select(Task).where(Task.id == task_id)
    res = await db.execute(stmt)
    task = res.scalar_one_or_none()
    if task:
        task.reminder_sent = True
        await db.commit()


async def delete_task(db: AsyncSession, id: int) -> bool:
    obj = await get(db, id)
    if not obj:
        return False
    await db.delete(obj)
    await db.commit()
    return True
