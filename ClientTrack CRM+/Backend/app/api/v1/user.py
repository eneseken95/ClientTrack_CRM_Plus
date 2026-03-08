from fastapi import APIRouter, Depends, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.core.config import settings
from app.api.deps import get_current_user
from app.schemas.user import (
    UserOut,
    UserUpdate,
    EmailChangeRequest,
    VerifyEmailChange,
    DeleteAccountVerify,
)
from app.services import user_service
from app.services.storage_service import generate_signed_url
from app.services.rate_limit_service import rate_limit_or_429

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserOut)
async def get_me(db: AsyncSession = Depends(get_db), user=Depends(get_current_user)):
    if user.avatar_path:
        user.avatar_url = await generate_signed_url(
            user.avatar_path, expires_in=30, bucket=settings.SUPABASE_AVATAR_BUCKET
        )
    else:
        user.avatar_url = None
    return user


@router.put("/me", response_model=UserOut)
async def update_user(
    payload: UserUpdate,
    db: AsyncSession = Depends(get_db),
    user=Depends(get_current_user),
):
    updated_user = await user_service.update_user_info(db, user.id, payload)
    if updated_user.avatar_path:
        updated_user.avatar_url = await generate_signed_url(
            updated_user.avatar_path,
            expires_in=30,
            bucket=settings.SUPABASE_AVATAR_BUCKET,
        )
    else:
        updated_user.avatar_url = None
    return UserOut.model_validate(updated_user)


@router.put("/me/avatar", response_model=UserOut)
async def update_avatar(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    user=Depends(get_current_user),
):
    file_bytes = await file.read()
    content_type = file.content_type
    updated_user = await user_service.update_avatar(
        db=db, user_id=user.id, file_bytes=file_bytes, content_type=content_type
    )
    if updated_user.avatar_path:
        updated_user.avatar_url = await generate_signed_url(
            updated_user.avatar_path,
            expires_in=30,
            bucket=settings.SUPABASE_AVATAR_BUCKET,
        )
    else:
        updated_user.avatar_url = None
    return UserOut.model_validate(updated_user)


@router.delete("/me/avatar", response_model=UserOut)
async def delete_avatar(
    db: AsyncSession = Depends(get_db), user=Depends(get_current_user)
):
    updated_user = await user_service.delete_avatar(db, user.id)
    updated_user.avatar_url = None
    return UserOut.model_validate(updated_user)


@router.post("/me/change-email")
async def request_email_change(
    payload: EmailChangeRequest,
    db: AsyncSession = Depends(get_db),
    user=Depends(get_current_user),
):
    await rate_limit_or_429(
        purpose="request_email_change",
        identifier=user.email,
        limit=3,
        window_seconds=30,
    )
    await user_service.request_email_change(db, user, payload.new_email)
    return {"message": "OTP sent"}


@router.post("/me/verify-email-change")
async def verify_email_change(
    payload: VerifyEmailChange,
    db: AsyncSession = Depends(get_db),
    user=Depends(get_current_user),
):
    updated = await user_service.verify_email_change(db, user, payload.otp)
    if updated.avatar_path:
        updated.avatar_url = await generate_signed_url(
            updated.avatar_path, expires_in=30, bucket=settings.SUPABASE_AVATAR_BUCKET
        )
    else:
        updated.avatar_url = None
    return UserOut.model_validate(updated)


@router.post("/me/delete-request")
async def delete_account_request(
    db: AsyncSession = Depends(get_db), user=Depends(get_current_user)
):
    await rate_limit_or_429(
        purpose="request_delete_account",
        identifier=user.email,
        limit=3,
        window_seconds=30,
    )
    await user_service.request_delete_account(db, user)
    return {"message": "OTP sent for account deletion"}


@router.post("/me/verify-delete")
async def verify_delete_account(
    payload: DeleteAccountVerify,
    db: AsyncSession = Depends(get_db),
    user=Depends(get_current_user),
):
    return await user_service.verify_delete_account(db, user, payload.otp)
