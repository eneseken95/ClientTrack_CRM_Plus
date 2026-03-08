import pytest


@pytest.mark.integration
@pytest.mark.asyncio
class TestAuthEndpoints:
    async def test_register_endpoint_success(
        self, test_client, mock_redis, mock_sendgrid
    ):
        response = await test_client.post(
            "/api/v1/auth/register",
            json={
                "name": "John",
                "surname": "Doe",
                "email": "john@example.org",
                "password": "Password123!",
                "phone": "+905551234567",
            },
        )
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "john@example.org"
        assert data["name"] == "John"
        assert "password_hash" not in data

    async def test_register_endpoint_invalid_email(
        self, test_client, mock_redis, mock_sendgrid
    ):
        response = await test_client.post(
            "/api/v1/auth/register",
            json={
                "name": "John",
                "surname": "Doe",
                "email": "invalid-email",
                "password": "Password123!",
                "phone": "+905551234567",
            },
        )
        assert response.status_code == 422

    async def test_register_endpoint_duplicate_email(
        self, test_client, create_test_user, mock_redis, mock_sendgrid
    ):
        await create_test_user(email="existing@example.org")
        response = await test_client.post(
            "/api/v1/auth/register",
            json={
                "name": "Jane",
                "surname": "Doe",
                "email": "existing@example.org",
                "password": "Password123!",
                "phone": "+905551234568",
            },
        )
        assert response.status_code == 400
        assert "already exists" in response.json()["detail"].lower()

    async def test_login_endpoint_success(
        self, test_client, create_test_user, mock_redis
    ):
        await create_test_user(
            email="test@example.org", password="TestPassword123", is_verified=True
        )
        response = await test_client.post(
            "/api/v1/auth/login",
            json={"email": "test@example.org", "password": "TestPassword123"},
        )
        assert response.status_code == 200
        data = response.json()
        assert "tokens" in data
        assert "access_token" in data["tokens"]
        assert "refresh_token" in data["tokens"]
        assert data["user"]["email"] == "test@example.org"

    async def test_login_endpoint_invalid_credentials(
        self, test_client, create_test_user, mock_redis
    ):
        await create_test_user(
            email="test@example.org", password="CorrectPassword", is_verified=True
        )
        response = await test_client.post(
            "/api/v1/auth/login",
            json={"email": "test@example.org", "password": "WrongPassword"},
        )
        assert response.status_code == 401

    async def test_login_endpoint_unverified_user(
        self, test_client, create_test_user, mock_redis
    ):
        await create_test_user(
            email="test@example.org", password="TestPassword123", is_verified=False
        )
        response = await test_client.post(
            "/api/v1/auth/login",
            json={"email": "test@example.org", "password": "TestPassword123"},
        )
        assert response.status_code == 400
        assert "verified" in response.json()["detail"].lower()

    async def test_verify_email_endpoint(
        self, test_client, create_test_user, mock_redis, mocker
    ):
        await create_test_user(email="test@example.org", is_verified=False)
        mocker.patch(
            "app.services.auth_service.verify_and_consume_otp", return_value=True
        )
        response = await test_client.post(
            "/api/v1/auth/verify-email",
            json={"email": "test@example.org", "otp": "123456"},
        )
        assert response.status_code == 200

    async def test_resend_otp_endpoint(
        self, test_client, create_test_user, mock_redis, mock_sendgrid, mocker
    ):
        await create_test_user(email="test@example.org", is_verified=False)
        mocker.patch("app.services.auth_service.otp_exists", return_value=False)
        response = await test_client.post(
            "/api/v1/auth/resend-otp", json={"email": "test@example.org"}
        )
        assert response.status_code == 200
        assert "OTP sent" in response.json()["message"]

    async def test_forgot_password_endpoint(
        self, test_client, create_test_user, mock_redis, mock_sendgrid, mocker
    ):
        await create_test_user(email="test@example.org", is_verified=True)
        mocker.patch("app.services.auth_service.otp_exists", return_value=False)
        response = await test_client.post(
            "/api/v1/auth/forgot-password", json={"email": "test@example.org"}
        )
        assert response.status_code == 200
        assert "Reset code sent" in response.json()["message"]

    async def test_reset_password_endpoint(
        self, test_client, create_test_user, mock_redis, mocker
    ):
        await create_test_user(
            email="test@example.org", password="OldPassword123", is_verified=True
        )
        mocker.patch(
            "app.services.auth_service.verify_and_consume_otp", return_value=True
        )
        response = await test_client.post(
            "/api/v1/auth/reset-password",
            json={
                "email": "test@example.org",
                "otp": "123456",
                "new_password": "NewPassword123",
            },
        )
        assert response.status_code == 200
        assert "reset successfully" in response.json()["message"].lower()
