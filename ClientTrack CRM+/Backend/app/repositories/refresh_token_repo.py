from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from app.models import RefreshToken
from datetime import datetime


async def add(
    db: AsyncSession, user_id: int, jti: str, token: str, expires_at: datetime
) -> RefreshToken:
    rt = RefreshToken(user_id=user_id, jti=jti, token=token, expires_at=expires_at)
    db.add(rt)
    await db.commit()
    await db.refresh(rt)
    return rt


async def get_valid_by_jti(db: AsyncSession, jti: str) -> RefreshToken:
    res = await db.execute(
        select(RefreshToken).where(
            RefreshToken.jti == jti, RefreshToken.revoked == False
        )
    )
    return res.scalar_one_or_none()


async def revoke(db: AsyncSession, jti: str) -> None:
    await db.execute(
        update(RefreshToken).where(RefreshToken.jti == jti).values(revoked=True)
    )
    await db.commit()


async def revoke_all_for_user(db: AsyncSession, user_id: int) -> None:
    await db.execute(
        update(RefreshToken).where(RefreshToken.user_id == user_id).values(revoked=True)
    )
    await db.commit()
