from typing import Optional
from pydantic import BaseModel, ConfigDict
from datetime import datetime


class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None
    status: str = "pending"
    due_date: Optional[datetime] = None
    client_id: int


class TaskCreate(TaskBase):
    pass


class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None
    due_date: Optional[datetime] = None


class TaskOut(TaskBase):
    id: int
    owner_id: int
    created_at: datetime
    client_name: Optional[str] = None
    client_logo: Optional[str] = None
    client_company: Optional[str] = None
    client_email: Optional[str] = None
    client_category: Optional[str] = None
    client_industry: Optional[str] = None
    client_status: Optional[str] = None
    model_config = ConfigDict(from_attributes=True)
