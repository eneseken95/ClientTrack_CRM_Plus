"""fix attachments json

Revision ID: 814cedf58842
Revises: a813737d9861
Create Date: 2025-12-06 14:17:51.963170

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "814cedf58842"
down_revision: Union[str, Sequence[str], None] = "a813737d9861"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    op.alter_column(
        "clients", "attachments", type_=sa.JSON(), postgresql_using="attachments::jsonb"
    )


def downgrade():
    op.alter_column(
        "clients", "attachments", type_=sa.TEXT(), postgresql_using="attachments::text"
    )
