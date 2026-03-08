from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.schemas.user import UserCreate, UserLogin, UserOut
from app.schemas.auth import LoginResponse, TokenPair, VerifyEmailRequest
from app.schemas.refresh_token_request import RefreshTokenRequest
from app.schemas.reset_password_request import ResetPasswordRequest
from app.schemas.forgot_password_request import ForgotPasswordRequest
from app.schemas.resend_otp_request import ResendOTPRequest
from app.services.rate_limit_service import rate_limit_or_429
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=UserOut)
async def register(payload: UserCreate, db: AsyncSession = Depends(get_db)):
    email = payload.email.strip().lower()
    await rate_limit_or_429(
        purpose="register",
        identifier=email,
        limit=3,
        window_seconds=30,
    )
    u = await auth_service.register_user(
        db,
        payload.name,
        payload.surname,
        payload.email,
        payload.password,
        payload.phone,
    )
    return u


@router.post("/verify-email")
async def verify_email(payload: VerifyEmailRequest, db: AsyncSession = Depends(get_db)):
    await auth_service.verify_email(db, payload.email, payload.otp)
    return {"message": "Email verified successfully"}


@router.post("/resend-otp")
async def resend_otp(payload: ResendOTPRequest, db: AsyncSession = Depends(get_db)):
    email = payload.email.strip().lower()
    await rate_limit_or_429(
        purpose="resend_otp",
        identifier=email,
        limit=3,
        window_seconds=30,
    )
    return await auth_service.resend_otp(db, payload.email)


@router.post("/login", response_model=LoginResponse)
async def login(payload: UserLogin, db: AsyncSession = Depends(get_db)):
    email = payload.email.strip().lower()
    await rate_limit_or_429(
        purpose="login",
        identifier=email,
        limit=3,
        window_seconds=30,
    )
    u, access, refresh = await auth_service.login(db, payload.email, payload.password)
    return LoginResponse(
        user=UserOut.model_validate(u),
        tokens=TokenPair(access_token=access, refresh_token=refresh),
    )


@router.post("/forgot-password")
async def forgot_password(
    payload: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)
):
    email = payload.email.strip().lower()
    await rate_limit_or_429(
        purpose="forgot_password",
        identifier=email,
        limit=3,
        window_seconds=30,
    )
    return await auth_service.forgot_password(db, payload.email)


@router.post("/reset-password")
async def reset_password(
    payload: ResetPasswordRequest, db: AsyncSession = Depends(get_db)
):
    return await auth_service.reset_password(
        db, payload.email, payload.otp, payload.new_password
    )


@router.post("/refresh", response_model=TokenPair)
async def refresh_tokens(data: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    access, refresh = await auth_service.refresh(db, data.refresh_token)
    return TokenPair(access_token=access, refresh_token=refresh)


@router.post("/logout")
async def logout():
    return {"message": "Logged out successfully"}
