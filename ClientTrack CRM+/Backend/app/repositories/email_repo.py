from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.email import Email


async def list_by_client(db: AsyncSession, client_id: int):
    res = await db.execute(select(Email).where(Email.client_id == client_id))
    return res.scalars().all()
