from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.models import Client


async def create(db: AsyncSession, **kwargs) -> Client:
    obj = Client(**kwargs)
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj


async def get(db: AsyncSession, id: int) -> Client:
    res = await db.execute(select(Client).where(Client.id == id))
    return res.scalar_one_or_none()


async def list_paginated(
    db: AsyncSession, owner_id: int, page: int = 1, size: int = 20
):
    offset = (page - 1) * size
    q = select(Client).where(Client.owner_id == owner_id)
    result = await db.execute(q.offset(offset).limit(size))
    items = result.scalars().all()
    count_q = (
        select(func.count()).select_from(Client).where(Client.owner_id == owner_id)
    )
    total = (await db.execute(count_q)).scalar_one()
    return items, total


async def update(db: AsyncSession, obj: Client, **kwargs) -> Client:
    for k, v in kwargs.items():
        if v is not None:
            setattr(obj, k, v)
    await db.commit()
    await db.refresh(obj)
    return obj


async def delete(db: AsyncSession, id: int) -> bool:
    obj = await get(db, id)
    if not obj:
        return False
    await db.delete(obj)
    await db.commit()
    return True


async def list_paginated_admin(db: AsyncSession, page: int = 1, size: int = 20):
    offset = (page - 1) * size
    res = await db.execute(select(Client).offset(offset).limit(size))
    items = list(res.scalars())
    total_q = select(func.count()).select_from(Client)
    total = (await db.execute(total_q)).scalar_one()
    return items, total
