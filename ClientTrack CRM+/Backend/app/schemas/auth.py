from pydantic import BaseModel, EmailStr
from app.schemas.user import UserOut


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class LoginResponse(BaseModel):
    user: UserOut
    tokens: TokenPair


class VerifyEmailRequest(BaseModel):
    email: EmailStr
    otp: str
