from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models import User


async def create(
    db: AsyncSession,
    name: str,
    surname: str,
    email: str,
    password_hash: str,
    phone: str,
    is_verified: bool,
) -> User:
    user = User(
        name=name,
        surname=surname,
        email=email,
        password_hash=password_hash,
        phone=phone,
        is_verified=is_verified,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def get_by_name(db: AsyncSession, name: str) -> User:
    res = await db.execute(select(User).where(User.name == name))
    return res.scalar_one_or_none()


async def get_by_surname(db: AsyncSession, surname: str) -> User:
    res = await db.execute(select(User).where(User.surname == surname))
    return res.scalar_one_or_none()


async def get_by_email(db: AsyncSession, email: str) -> User:
    res = await db.execute(select(User).where(User.email == email))
    return res.scalar_one_or_none()


async def get_by_id(db: AsyncSession, user_id: int):
    res = await db.execute(select(User).where(User.id == user_id))
    return res.scalar_one_or_none()


async def list_all(db: AsyncSession) -> list[User]:
    res = await db.execute(select(User))
    return list(res.scalars())


async def delete_user(db: AsyncSession, user_id: int) -> bool:
    res = await db.execute(select(User).where(User.id == user_id))
    user = res.scalar_one_or_none()
    if not user:
        return False
    await db.delete(user)
    await db.commit()
    return True
