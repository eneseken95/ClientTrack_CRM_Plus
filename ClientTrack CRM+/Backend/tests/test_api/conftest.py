import pytest
from app.core.security import create_access_token
import json


@pytest.fixture
async def authenticated_user(create_test_user):
    user = await create_test_user(is_verified=True)
    access_token = create_access_token(
        json.dumps({"id": user.id, "role": user.role}), minutes=30
    )
    return user, access_token


@pytest.fixture
async def admin_user(test_db_session, create_test_user):
    from app.repositories import user_repo
    from app.core.security import hash_password

    admin = await user_repo.create(
        db=test_db_session,
        name="Admin",
        surname="User",
        email="admin@example.org",
        password_hash=hash_password("Admin123!"),
        phone="+905551111111",
        is_verified=True,
    )
    admin.role = "admin"
    await test_db_session.commit()
    await test_db_session.refresh(admin)
    access_token = create_access_token(
        json.dumps({"id": admin.id, "role": admin.role}), minutes=30
    )
    return admin, access_token
