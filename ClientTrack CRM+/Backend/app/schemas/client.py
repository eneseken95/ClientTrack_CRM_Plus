from typing import Optional
from pydantic import BaseModel, ConfigDict, EmailStr, Field
from datetime import datetime


class ClientCreate(BaseModel):
    name: str = Field(..., min_length=1)
    surname: Optional[str] = None
    email: EmailStr = Field(..., min_length=1)
    phone: Optional[str] = None
    company: Optional[str] = None
    notes: Optional[str] = None
    source: Optional[str] = None
    status: Optional[str] = None
    category: Optional[str] = None
    industry: Optional[str] = None
    latitude: Optional[str] = None
    longitude: Optional[str] = None


class ClientUpdate(BaseModel):
    name: Optional[str] = None
    surname: Optional[str] = None
    email: EmailStr | None = None
    phone: Optional[str] = None
    company: Optional[str] = None
    notes: Optional[str] = None
    source: Optional[str] = None
    status: Optional[str] = None
    category: Optional[str] = None
    industry: Optional[str] = None
    latitude: Optional[str] = None
    longitude: Optional[str] = None


class ClientOut(BaseModel):
    id: int
    name: str
    surname: Optional[str]
    email: EmailStr
    phone: Optional[str]
    company: Optional[str]
    notes: Optional[str]
    source: Optional[str]
    status: Optional[str]
    category: Optional[str]
    industry: Optional[str]
    latitude: Optional[str]
    longitude: Optional[str]
    attachments: list[str | dict] | None = None
    company_logo: Optional[str] = None
    created_at: Optional[datetime] = None
    model_config = ConfigDict(from_attributes=True)

