import pytest
from fastapi import HTTPException
from app.services import auth_service
from app.core.security import verify_password


@pytest.mark.unit
@pytest.mark.asyncio
class TestAuthService:
    async def test_register_user_success(
        self, test_db_session, mock_redis, mock_sendgrid
    ):
        user = await auth_service.register_user(
            db=test_db_session,
            name="John",
            surname="Doe",
            email="john@example.org",
            password="Password123!",
            phone="+905551234567",
        )
        assert user.id is not None
        assert user.name == "John"
        assert user.surname == "Doe"
        assert user.email == "john@example.org"
        assert user.phone == "+905551234567"
        assert user.is_verified is False
        assert verify_password("Password123!", user.password_hash)

    async def test_register_user_duplicate_email(
        self, test_db_session, create_test_user, mock_redis, mock_sendgrid
    ):
        await create_test_user(email="existing@example.org")
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.register_user(
                db=test_db_session,
                name="Jane",
                surname="Doe",
                email="existing@example.org",
                password="Password123!",
                phone="+905551234568",
            )
        assert exc_info.value.status_code == 400
        assert "Email already exists" in str(exc_info.value.detail)

    async def test_register_user_invalid_email(
        self, test_db_session, mock_redis, mock_sendgrid
    ):
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.register_user(
                db=test_db_session,
                name="John",
                surname="Doe",
                email="invalid-email",
                password="Password123!",
                phone="+905551234567",
            )
        assert exc_info.value.status_code == 400
        assert "Invalid email format" in str(exc_info.value.detail)

    async def test_register_user_invalid_phone(
        self, test_db_session, mock_redis, mock_sendgrid
    ):
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.register_user(
                db=test_db_session,
                name="John",
                surname="Doe",
                email="john@example.org",
                password="Password123!",
                phone="123",
            )
        assert exc_info.value.status_code == 400
        assert "Invalid phone format" in str(exc_info.value.detail)

    async def test_login_success(self, test_db_session, create_test_user, mock_redis):
        user = await create_test_user(
            email="test@example.org", password="TestPassword123", is_verified=True
        )
        logged_in_user, access_token, refresh_token = await auth_service.login(
            db=test_db_session, email="test@example.org", password="TestPassword123"
        )
        assert logged_in_user.id == user.id
        assert access_token is not None
        assert refresh_token is not None

    async def test_login_invalid_credentials(
        self, test_db_session, create_test_user, mock_redis
    ):
        await create_test_user(
            email="test@example.org", password="CorrectPassword", is_verified=True
        )
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.login(
                db=test_db_session, email="test@example.org", password="WrongPassword"
            )
        assert exc_info.value.status_code == 401

    async def test_login_user_not_found(self, test_db_session, mock_redis):
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.login(
                db=test_db_session,
                email="nonexistent@example.org",
                password="Password123",
            )
        assert exc_info.value.status_code == 401

    async def test_login_unverified_email(
        self, test_db_session, create_test_user, mock_redis
    ):
        await create_test_user(
            email="test@example.org", password="TestPassword123", is_verified=False
        )
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.login(
                db=test_db_session, email="test@example.org", password="TestPassword123"
            )
        assert exc_info.value.status_code == 400
        assert "not verified" in str(exc_info.value.detail).lower()

    async def test_verify_email_success(
        self, test_db_session, create_test_user, mock_redis, mocker
    ):
        user = await create_test_user(email="test@example.org", is_verified=False)
        mocker.patch(
            "app.services.auth_service.verify_and_consume_otp", return_value=True
        )
        await auth_service.verify_email(
            db=test_db_session, email="test@example.org", otp="123456"
        )
        from app.repositories import user_repo

        verified_user = await user_repo.get_by_email(
            test_db_session, "test@example.org"
        )
        assert verified_user.is_verified is True

    async def test_verify_email_already_verified(
        self, test_db_session, create_test_user, mock_redis
    ):
        await create_test_user(email="test@example.org", is_verified=True)
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.verify_email(
                db=test_db_session, email="test@example.org", otp="123456"
            )
        assert exc_info.value.status_code == 400
        assert "Already verified" in str(exc_info.value.detail)

    async def test_verify_email_invalid_otp(
        self, test_db_session, create_test_user, mock_redis, mocker
    ):
        await create_test_user(email="test@example.org", is_verified=False)
        mocker.patch(
            "app.services.auth_service.verify_and_consume_otp", return_value=False
        )
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.verify_email(
                db=test_db_session, email="test@example.org", otp="wrong-otp"
            )
        assert exc_info.value.status_code == 400
        assert "Invalid or expired OTP" in str(exc_info.value.detail)

    async def test_forgot_password(
        self, test_db_session, create_test_user, mock_redis, mock_sendgrid, mocker
    ):
        await create_test_user(email="test@example.org", is_verified=True)
        mocker.patch("app.services.auth_service.otp_exists", return_value=False)
        result = await auth_service.forgot_password(
            db=test_db_session, email="test@example.org"
        )
        assert "Reset code sent" in result["message"]

    async def test_reset_password_success(
        self, test_db_session, create_test_user, mock_redis, mocker
    ):
        user = await create_test_user(
            email="test@example.org", password="OldPassword123", is_verified=True
        )
        mocker.patch(
            "app.services.auth_service.verify_and_consume_otp", return_value=True
        )
        result = await auth_service.reset_password(
            db=test_db_session,
            email="test@example.org",
            otp="123456",
            new_password="NewPassword123",
        )
        assert "reset successfully" in result["message"].lower()
        from app.repositories import user_repo

        updated_user = await user_repo.get_by_email(test_db_session, "test@example.org")
        assert verify_password("NewPassword123", updated_user.password_hash)
