from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import Integer, String, Text, DateTime, Boolean, ForeignKey, func
from app.models.base import Base


class Email(Base):
    __tablename__ = "emails"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    owner_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    client_id: Mapped[int | None] = mapped_column(
        ForeignKey("clients.id", ondelete="CASCADE"), nullable=True
    )

    to_email: Mapped[str] = mapped_column(String(255), nullable=False)
    subject: Mapped[str] = mapped_column(String(255), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)

    status: Mapped[str] = mapped_column(String(20), default="sent")
    ai_generated: Mapped[bool] = mapped_column(Boolean, default=False)
    ai_model: Mapped[str | None] = mapped_column(String(50))

    sent_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
