from typing import Optional
from pydantic import BaseModel, ConfigDict, EmailStr, Field
from datetime import datetime


class UserCreate(BaseModel):
    name: str = Field(..., min_length=1)
    surname: Optional[str] = None
    email: EmailStr = Field(..., min_length=1)
    password: str = Field(..., min_length=6)
    phone: Optional[str] = None


class UserLogin(BaseModel):
    email: EmailStr = Field(..., min_length=1)
    password: str = Field(..., min_length=6)


class UserOut(BaseModel):
    id: int
    name: str
    surname: Optional[str]
    email: EmailStr
    role: str
    phone: Optional[str]
    avatar_url: Optional[str] = None
    subscription_status: str = "none"
    subscription_plan_id: Optional[str] = None
    current_period_end: Optional[datetime] = None
    model_config = ConfigDict(from_attributes=True)


class UserUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1)
    surname: Optional[str] = None
    phone: Optional[str] = None


class EmailChangeRequest(BaseModel):
    new_email: EmailStr


class VerifyEmailChange(BaseModel):
    otp: str


class DeleteAccountVerify(BaseModel):
    otp: str
