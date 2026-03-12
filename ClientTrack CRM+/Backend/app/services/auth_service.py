from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import delete
from app.core.config import settings
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    hash_refresh_token,
)
from app.models import RefreshToken
from app.utils.email_sender import sendMailUsingSendGrid
from app.utils.email_templates import (
    render_verification_email,
    render_password_reset_email,
)
from app.repositories import user_repo, refresh_token_repo
from app.services.otp_service import store_otp, otp_exists, verify_and_consume_otp
from email_validator import validate_email, EmailNotValidError
from datetime import datetime, timedelta, timezone
from jose import jwt, JWTError
import random
import json
import re


async def register_user(
    db: AsyncSession, name: str, surname: str, email: str, password: str, phone: str
):
    email = email.strip().lower()
    try:
        validate_email(email)
    except EmailNotValidError:
        raise HTTPException(status_code=400, detail="Invalid email format")
    if await user_repo.get_by_email(db, email):
        raise HTTPException(status_code=400, detail="Email already exists")
    if not re.match(r"^\+?\d{10,15}$", phone):
        raise HTTPException(status_code=400, detail="Invalid phone format")
    otp = f"{random.randint(100000, 999999)}"
    u = await user_repo.create(
        db,
        name=name,
        surname=surname,
        email=email,
        password_hash=hash_password(password),
        phone=phone,
        is_verified=False,
    )
    await store_otp("verify_email", email, otp)
    await send_verification_email(name, email, otp)
    return u


async def send_verification_email(name: str, email: str, otp: str):
    html = render_verification_email(name, otp)
    sendMailUsingSendGrid(
        to_email=email,
        subject="Email Verification Code",
        html_content=html,
        reply_to=settings.SENDGRID_SENDER,
    )


async def verify_email(db, email, otp):
    user = await user_repo.get_by_email(db, email)
    if not user:
        raise HTTPException(404, "User not found")
    if user.is_verified:
        raise HTTPException(400, "Already verified")
    ok = await verify_and_consume_otp("verify_email", email, otp)
    if not ok:
        raise HTTPException(400, "Invalid or expired OTP")
    user.is_verified = True
    await db.commit()


async def resend_otp(db: AsyncSession, email: str):
    user = await user_repo.get_by_email(db, email)
    if not user:
        raise HTTPException(404, "User not found")
    if user.is_verified:
        raise HTTPException(400, "Email already verified")
    if await otp_exists("verify_email", email):
        raise HTTPException(400, "Current OTP is still valid")
    otp = f"{random.randint(100000, 999999)}"
    await store_otp("verify_email", email, otp)
    await send_verification_email(user.name, user.email, otp)
    return {"message": "New OTP sent"}


async def login(db: AsyncSession, email: str, password: str):
    email = email.strip().lower()
    try:
        validate_email(email)
    except EmailNotValidError:
        raise HTTPException(status_code=400, detail="Invalid email format")
    u = await user_repo.get_by_email(db, email)
    if not u:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials"
        )
    if not u.is_verified:
        raise HTTPException(
            status_code=400, detail="Email is not verified. Please verify your email."
        )
    if not verify_password(password, u.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials"
        )
    access = create_access_token(
        json.dumps({"id": u.id, "role": u.role}),
        minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES,
    )
    refresh, jti, exp = create_refresh_token(
        str(u.id), minutes=settings.REFRESH_TOKEN_EXPIRE_MINUTES
    )
    await refresh_token_repo.add(
        db, user_id=u.id, jti=jti, token=hash_refresh_token(refresh), expires_at=exp
    )
    return u, access, refresh


async def forgot_password(db: AsyncSession, email: str):
    email = email.strip().lower()
    user = await user_repo.get_by_email(db, email)
    if not user:
        raise HTTPException(404, "User not found")
    if not user.is_verified:
        raise HTTPException(400, "Email is not verified")
    if await otp_exists("forgot_password", email):
        raise HTTPException(
            status_code=400, detail="A reset code was already sent. Please wait."
        )
    otp = f"{random.randint(100000, 999999)}"
    await store_otp("forgot_password", email, otp)
    html = render_password_reset_email(user.name, otp)
    sendMailUsingSendGrid(
        to_email=user.email,
        subject="Password Reset Code",
        html_content=html,
        reply_to=settings.SENDGRID_SENDER,
    )
    return {"message": "Reset code sent"}


async def reset_password(db: AsyncSession, email: str, otp: str, new_password: str):
    email = email.strip().lower()
    user = await user_repo.get_by_email(db, email)
    if not user:
        raise HTTPException(404, "User not found")
    ok = await verify_and_consume_otp(
        purpose="forgot_password", email=email, raw_otp=otp
    )
    if not ok:
        raise HTTPException(400, "Invalid or expired OTP")
    user.password_hash = hash_password(new_password)
    await db.commit()
    return {"message": "Password has been reset successfully"}


async def delete_old_revoked_tokens(db: AsyncSession):
    cutoff = datetime.now(timezone.utc) - timedelta(seconds=30)
    stmt = delete(RefreshToken).where(
        RefreshToken.revoked == True, RefreshToken.expires_at < cutoff
    )
    result = await db.execute(stmt)
    await db.commit()
    return result.rowcount


async def refresh(db: AsyncSession, refresh_token: str) -> tuple[str, str]:
    try:
        payload = jwt.decode(
            refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        if payload.get("type") != "refresh":
            raise JWTError("Invalid token type")
        jti = payload.get("jti")
        sub = payload.get("sub")
        exp = payload.get("exp")
        if not jti or not sub:
            raise JWTError("Missing claims")
        if datetime.now(timezone.utc).timestamp() > exp:
            raise JWTError("Token expired")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    db_rt = await refresh_token_repo.get_valid_by_jti(db, jti)
    if not db_rt:
        raise HTTPException(
            status_code=401, detail="Refresh token revoked or not found"
        )
    u = await user_repo.get_by_id(db, db_rt.user_id)
    await refresh_token_repo.revoke(db, jti)
    access = create_access_token(
        json.dumps({"id": u.id, "role": u.role}),
        minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES,
    )
    new_refresh, new_jti, new_exp = create_refresh_token(
        str(u.id), minutes=settings.REFRESH_TOKEN_EXPIRE_MINUTES
    )
    await refresh_token_repo.add(
        db,
        user_id=db_rt.user_id,
        jti=new_jti,
        token=hash_refresh_token(new_refresh),
        expires_at=new_exp,
    )
    return access, new_refresh


async def logout_all(db: AsyncSession, user_id: int) -> None:
    await refresh_token_repo.revoke_all_for_user(db, user_id)


async def admin_list_users(db: AsyncSession):
    return await user_repo.list_all(db)


async def admin_delete_user(db: AsyncSession, user_id: int) -> bool:
    return await user_repo.delete_user(db, user_id)
