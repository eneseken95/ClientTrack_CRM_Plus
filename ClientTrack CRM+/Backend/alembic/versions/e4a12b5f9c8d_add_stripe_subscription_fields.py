"""add stripe subscription fields to users

Revision ID: e4a12b5f9c8d
Revises: ccf3599c28d2
Create Date: 2026-02-23 00:40:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "e4a12b5f9c8d"
down_revision: str = "a26f463a55a6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("stripe_customer_id", sa.String(255), nullable=True))
    op.add_column("users", sa.Column("subscription_status", sa.String(50), nullable=False, server_default="none"))
    op.add_column("users", sa.Column("subscription_plan_id", sa.String(255), nullable=True))
    op.add_column("users", sa.Column("current_period_end", sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "current_period_end")
    op.drop_column("users", "subscription_plan_id")
    op.drop_column("users", "subscription_status")
    op.drop_column("users", "stripe_customer_id")
