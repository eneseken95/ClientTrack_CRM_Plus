from typing import Optional
from pydantic import BaseModel, EmailStr


class EmailCreate(BaseModel):
    client_id: Optional[int]
    to_email: EmailStr
    subject: str
    body: str


class AiEmailDraftRequest(BaseModel):
    purpose: str
    tone: str
    language: str
    client_name: str


class EmailOut(BaseModel):
    id: int
    subject: str
    body: str
    sender: str
    recipient: str
    sentAt: str
    isRead: bool = False
    clientName: Optional[str] = None
    clientCompanyLogo: Optional[str] = None

    @classmethod
    def from_orm_with_sender(
        cls,
        email,
        sender_email: str,
        client_name: Optional[str] = None,
        client_company_logo: Optional[str] = None,
    ):
        return cls(
            id=email.id,
            subject=email.subject,
            body=email.body,
            sender=sender_email,
            recipient=email.to_email,
            sentAt=email.sent_at.isoformat() if email.sent_at else "",
            isRead=False,
            clientName=client_name,
            clientCompanyLogo=client_company_logo,
        )

    class Config:
        from_attributes = True
