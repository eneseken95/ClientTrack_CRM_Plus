from typing import Optional
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import String, Integer, Boolean, DateTime
from app.models.base import Base


class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(150), index=True, nullable=False)
    surname: Mapped[str] = mapped_column(String(150), index=True, nullable=True)
    email: Mapped[str] = mapped_column(
        String(255), unique=True, index=True, nullable=False
    )
    phone: Mapped[str] = mapped_column(String(40), nullable=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[str] = mapped_column(String(50), nullable=False, default="user")
    refresh_tokens = relationship(
        "RefreshToken", back_populates="user", cascade="all, delete-orphan"
    )
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    avatar_path: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    pending_new_email: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    stripe_customer_id: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    subscription_status: Mapped[str] = mapped_column(
        String(50), nullable=False, default="none"
    )
    subscription_plan_id: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    current_period_end: Mapped[Optional[str]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
