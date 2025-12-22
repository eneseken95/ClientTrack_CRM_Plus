from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import String, Integer, Text, DateTime, ForeignKey, func, JSON
from app.models.base import Base


class Client(Base):
    __tablename__ = "clients"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    surname: Mapped[str] = mapped_column(String(255), nullable=True)
    email: Mapped[str] = mapped_column(String(255), nullable=False)
    phone: Mapped[str] = mapped_column(String(40), nullable=True)
    company: Mapped[str] = mapped_column(String(255), nullable=True)
    notes: Mapped[str] = mapped_column(Text, nullable=True)
    source: Mapped[str] = mapped_column(String(255), nullable=True)
    status: Mapped[str] = mapped_column(String(255), nullable=True)
    category: Mapped[str] = mapped_column(String(255), nullable=True)
    industry: Mapped[str] = mapped_column(String(255), nullable=True)
    latitude: Mapped[str] = mapped_column(String(50), nullable=True)
    longitude: Mapped[str] = mapped_column(String(50), nullable=True)
    company_logo: Mapped[str | None] = mapped_column(String(500), nullable=True)
    owner_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=False
    )
    created_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    attachments: Mapped[list[str] | None] = mapped_column(JSON, nullable=True)
