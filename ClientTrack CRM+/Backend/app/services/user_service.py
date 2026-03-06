from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
from app.core.config import settings
from app.models import User, Client
from app.schemas.user import UserUpdate
from app.repositories import user_repo, refresh_token_repo
from app.utils.email_templates import render_email_change, render_delete_account_email
from app.utils.email_sender import sendMailUsingSendGrid
from app.services.storage_service import upload_file, delete_file
from app.services.otp_service import store_otp, verify_and_consume_otp
from app.services.stripe_service import cancel_user_subscription
import uuid
import random


async def update_user_info(db: AsyncSession, user_id: int, data: UserUpdate):
    user = await user_repo.get_by_id(db, user_id)
    if data.name is not None:
        user.name = data.name
    if data.surname is not None:
        user.surname = data.surname
    if data.phone is not None:
        user.phone = data.phone
    await db.commit()
    await db.refresh(user)
    return user


async def request_email_change(db: AsyncSession, user, new_email: str):
    existing = await user_repo.get_by_email(db, new_email)
    if existing:
        raise HTTPException(status_code=400, detail="Email already in use")
    user.pending_new_email = new_email
    await db.commit()
    otp = f"{random.randint(100000, 999999)}"
    await store_otp("email_change", new_email, otp)
    await send_email_change_otp(user.name, new_email, otp)


async def send_email_change_otp(name: str, email: str, otp: str):
    html = render_email_change(name, otp)
    sendMailUsingSendGrid(
        to_email=email,
        subject="Email Change Verification Code",
        html_content=html,
        reply_to=settings.SENDGRID_SENDER,
    )


async def verify_email_change(db: AsyncSession, user, otp: str):
    if not user.pending_new_email:
        raise HTTPException(status_code=400, detail="No pending email change")
    ok = await verify_and_consume_otp("email_change", user.pending_new_email, otp)
    if not ok:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")
    user.email = user.pending_new_email
    user.pending_new_email = None
    await db.commit()
    await db.refresh(user)
    return user


async def request_delete_account(db: AsyncSession, user):
    otp = f"{random.randint(100000, 999999)}"
    await store_otp("delete_account", user.email, otp)
    html = render_delete_account_email(user.name, otp)
    sendMailUsingSendGrid(
        to_email=user.email,
        subject="Delete Account Verification Code",
        html_content=html,
        reply_to=settings.SENDGRID_SENDER,
    )
    return {"message": "OTP sent to your email"}


async def verify_delete_account(db: AsyncSession, user, otp: str):
    if user.role == "admin":
        raise HTTPException(
            status_code=403, detail="Admin accounts cannot delete themselves."
        )
    ok = await verify_and_consume_otp("delete_account", user.email, otp)
    if not ok:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")
    if user.avatar_path:
        try:
            await delete_file(user.avatar_path, bucket=settings.SUPABASE_AVATAR_BUCKET)
        except Exception:
            pass
    res = await db.execute(select(Client).where(Client.owner_id == user.id))
    clients = res.scalars().all()
    for client in clients:
        if client.attachments:
            for path in client.attachments:
                try:
                    await delete_file(path, bucket=settings.SUPABASE_ATTACHMENT_BUCKET)
                except Exception:
                    pass
    await db.execute(delete(Client).where(Client.owner_id == user.id))

    await cancel_user_subscription(db, user)

    await db.commit()
    await refresh_token_repo.revoke_all_for_user(db, user.id)
    deleted = await user_repo.delete_user(db, user.id)
    if not deleted:
        raise HTTPException(500, "Failed to delete account")
    return {"message": "Account deleted successfully"}


async def update_avatar(
    db: AsyncSession, user_id: int, file_bytes: bytes, content_type: str
):
    user = await user_repo.get_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.avatar_path:
        try:
            await delete_file(user.avatar_path, bucket=settings.SUPABASE_AVATAR_BUCKET)
        except:
            pass
    filename = f"{uuid.uuid4()}.webp"
    path = f"{user_id}/{filename}"
    await upload_file(
        path=path,
        file_bytes=file_bytes,
        content_type=content_type,
        bucket=settings.SUPABASE_AVATAR_BUCKET,
    )
    user.avatar_path = path
    await db.commit()
    await db.refresh(user)
    return user


async def delete_avatar(db: AsyncSession, user_id: int):
    stmt = select(User).where(User.id == user_id)
    result = await db.execute(stmt)
    user = result.scalars().first()
    if not user:
        raise HTTPException(404, "User not found")
    if not user.avatar_path:
        user.avatar_url = None
        return user
    try:
        await delete_file(user.avatar_path, bucket=settings.SUPABASE_AVATAR_BUCKET)
    except:
        pass
    user.avatar_path = None
    user.avatar_url = None
    await db.commit()
    await db.refresh(user)
    return user


async def admin_delete_user_and_files(db: AsyncSession, user_id: int) -> bool:
    res = await db.execute(select(User).where(User.id == user_id))
    user = res.scalar_one_or_none()
    if not user:
        return False
    if user.avatar_path:
        try:
            await delete_file(
                path=user.avatar_path, bucket=settings.SUPABASE_AVATAR_BUCKET
            )
        except Exception as e:
            pass
    res = await db.execute(select(Client).where(Client.owner_id == user_id))
    clients = res.scalars().all()
    for client in clients:
        if client.attachments:
            for path in client.attachments:
                try:
                    await delete_file(
                        path=path, bucket=settings.SUPABASE_ATTACHMENT_BUCKET
                    )
                except Exception as e:
                    pass
        if client.company_logo:
            try:
                await delete_file(
                    path=client.company_logo, bucket=settings.SUPABASE_ATTACHMENT_BUCKET
                )
            except Exception as e:
                pass
    await db.execute(delete(Client).where(Client.owner_id == user_id))

    await cancel_user_subscription(db, user)

    await db.commit()
    await db.execute(delete(User).where(User.id == user_id))
    await db.commit()
    return True
