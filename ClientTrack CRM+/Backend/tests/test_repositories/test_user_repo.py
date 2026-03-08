import pytest
from app.repositories import user_repo
from app.core.security import hash_password, verify_password


@pytest.mark.unit
@pytest.mark.asyncio
class TestUserRepo:
    async def test_create_user(self, test_db_session):
        user = await user_repo.create(
            db=test_db_session,
            name="John",
            surname="Doe",
            email="john@example.org",
            password_hash=hash_password("password123"),
            phone="+905551234567",
            is_verified=False,
        )
        assert user.id is not None
        assert user.name == "John"
        assert user.surname == "Doe"
        assert user.email == "john@example.org"
        assert user.phone == "+905551234567"
        assert user.is_verified is False
        assert verify_password("password123", user.password_hash)

    async def test_get_by_email(self, test_db_session, create_test_user):
        created_user = await create_test_user(email="test@example.org")
        found_user = await user_repo.get_by_email(test_db_session, "test@example.org")
        assert found_user is not None
        assert found_user.id == created_user.id
        assert found_user.email == "test@example.org"

    async def test_get_by_email_not_found(self, test_db_session):
        user = await user_repo.get_by_email(test_db_session, "nonexistent@example.org")
        assert user is None

    async def test_get_by_id(self, test_db_session, create_test_user):
        created_user = await create_test_user()
        found_user = await user_repo.get_by_id(test_db_session, created_user.id)
        assert found_user is not None
        assert found_user.id == created_user.id
        assert found_user.email == created_user.email

    async def test_get_by_id_not_found(self, test_db_session):
        user = await user_repo.get_by_id(test_db_session, 99999)
        assert user is None

    async def test_get_by_name(self, test_db_session, create_test_user):
        created_user = await create_test_user(name="TestName")
        found_user = await user_repo.get_by_name(test_db_session, "TestName")
        assert found_user is not None
        assert found_user.id == created_user.id
        assert found_user.name == "TestName"

    async def test_get_by_surname(self, test_db_session, create_test_user):
        created_user = await create_test_user(surname="TestSurname")
        found_user = await user_repo.get_by_surname(test_db_session, "TestSurname")
        assert found_user is not None
        assert found_user.id == created_user.id
        assert found_user.surname == "TestSurname"

    async def test_list_all(self, test_db_session, create_test_user):
        await create_test_user(email="user1@example.org")
        await create_test_user(email="user2@example.org")
        await create_test_user(email="user3@example.org")
        users = await user_repo.list_all(test_db_session)
        assert len(users) == 3
        emails = {user.email for user in users}
        assert "user1@example.org" in emails
        assert "user2@example.org" in emails
        assert "user3@example.org" in emails

    async def test_delete_user(self, test_db_session, create_test_user):
        created_user = await create_test_user()
        user_id = created_user.id
        result = await user_repo.delete_user(test_db_session, user_id)
        assert result is True
        deleted_user = await user_repo.get_by_id(test_db_session, user_id)
        assert deleted_user is None

    async def test_delete_user_not_found(self, test_db_session):
        result = await user_repo.delete_user(test_db_session, 99999)
        assert result is False
