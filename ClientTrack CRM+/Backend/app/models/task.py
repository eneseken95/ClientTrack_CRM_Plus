from typing import Optional
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, Text, DateTime, ForeignKey
from datetime import datetime, timezone
from app.core.db import Base


class Task(Base):
    __tablename__ = "tasks"
    id = mapped_column(Integer, primary_key=True)
    title = mapped_column(String(255))
    description = mapped_column(Text)
    status = mapped_column(String(50), default="pending")
    due_date = mapped_column(DateTime(timezone=True), nullable=True)
    reminder_sent: Mapped[bool] = mapped_column(default=False)
    owner_id = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    client_id = mapped_column(ForeignKey("clients.id", ondelete="CASCADE"))
    created_at = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    owner = relationship("User")
    client = relationship("Client")

    @property
    def client_name(self) -> Optional[str]:
        if self.client:
            return f"{self.client.name} {self.client.surname or ''}".strip()
        return None

    @property
    def client_logo(self) -> Optional[str]:
        if self.client:
            return self.client.company_logo
        return None

    @property
    def client_company(self) -> Optional[str]:
        if self.client:
            return self.client.company
        return None

    @property
    def client_email(self) -> Optional[str]:
        if self.client:
            return self.client.email
        return None

    @property
    def client_category(self) -> Optional[str]:
        if self.client:
            return self.client.category
        return None

    @property
    def client_industry(self) -> Optional[str]:
        if self.client:
            return self.client.industry
        return None

    @property
    def client_status(self) -> Optional[str]:
        if self.client:
            return self.client.status
        return None
