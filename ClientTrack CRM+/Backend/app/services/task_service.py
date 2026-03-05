from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.client import Client
from app.repositories import task_repo
from app.utils.datetime import normalize_to_utc


async def create_task(db: AsyncSession, data, owner_id: int):
    client_stmt = select(Client).where(
        Client.id == data.client_id, Client.owner_id == owner_id
    )
    client_res = await db.execute(client_stmt)
    client = client_res.scalar_one_or_none()
    if client is None:
        raise HTTPException(
            status_code=400, detail="Client does not exist or not owned by user"
        )
    payload = data.model_dump()
    payload["due_date"] = normalize_to_utc(payload.get("due_date"))
    payload["owner_id"] = owner_id
    return await task_repo.create(db, **payload)


async def list_tasks(db: AsyncSession, owner_id: int):
    return await task_repo.list_by_owner(db, owner_id)


async def list_client_tasks(db: AsyncSession, owner_id: int, client_id: int):
    client_stmt = select(Client).where(
        Client.id == client_id, Client.owner_id == owner_id
    )
    client_res = await db.execute(client_stmt)
    client = client_res.scalar_one_or_none()
    if client is None:
        raise HTTPException(
            status_code=400, detail="Client does not exist or not owned by user"
        )
    return await task_repo.list_by_client(db, owner_id, client_id)


async def update_task(db: AsyncSession, task_id: int, owner_id: int, data):
    task = await task_repo.get(db, task_id)
    if not task or task.owner_id != owner_id:
        return None
    updates = data.model_dump(exclude_none=True)
    if "client_id" in updates:
        client_stmt = select(Client).where(
            Client.id == updates["client_id"], Client.owner_id == owner_id
        )
        client_res = await db.execute(client_stmt)
        client = client_res.scalar_one_or_none()
        if client is None:
            raise HTTPException(
                status_code=400, detail="Client does not exist or not owned by user"
            )
    if "due_date" in updates:
        updates["due_date"] = normalize_to_utc(updates["due_date"])
    return await task_repo.update(db, task_id, **updates)


async def get_tasks_due_soon(db: AsyncSession, lead_minutes: int = 2):
    return await task_repo.get_tasks_due_soon(db, lead_minutes)


async def mark_reminder_sent(db: AsyncSession, task_id: int):
    await task_repo.mark_reminder_sent(db, task_id)


async def delete_task(db: AsyncSession, task_id: int, owner_id: int):
    task = await task_repo.get(db, task_id)
    if not task or task.owner_id != owner_id:
        return False
    return await task_repo.delete_task(db, task_id)
