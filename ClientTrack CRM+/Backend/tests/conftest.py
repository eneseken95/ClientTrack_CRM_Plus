import pytest
import asyncio
from typing import AsyncGenerator
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.pool import StaticPool
from app.main import app
from app.core.db import Base, get_db
from app.models import User, Client, Task, Email


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="function")
async def test_db_engine():
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
        echo=False,
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest.fixture(scope="function")
async def test_db_session(test_db_engine) -> AsyncGenerator[AsyncSession, None]:
    SessionLocal = async_sessionmaker(
        test_db_engine, expire_on_commit=False, class_=AsyncSession
    )
    async with SessionLocal() as session:
        yield session
        await session.rollback()


@pytest.fixture
def mock_redis(mocker):
    mock_client = mocker.AsyncMock()
    mock_client.get = mocker.AsyncMock(return_value=None)
    mock_client.set = mocker.AsyncMock(return_value=True)
    mock_client.setex = mocker.AsyncMock(return_value=True)
    mock_client.delete = mocker.AsyncMock(return_value=1)
    mock_client.exists = mocker.AsyncMock(return_value=0)
    mock_client.incr = mocker.AsyncMock(return_value=1)
    mock_client.expire = mocker.AsyncMock(return_value=True)
    mocker.patch("app.services.cache_service.redis_client", mock_client)
    mocker.patch("app.services.otp_service.redis_client", mock_client)
    mocker.patch("app.services.rate_limit_service.redis_client", mock_client)
    return mock_client


@pytest.fixture
def mock_elasticsearch(mocker):
    mock_client = mocker.MagicMock()
    mock_client.index = mocker.MagicMock(return_value={"result": "created"})
    mock_client.delete = mocker.MagicMock(return_value={"result": "deleted"})
    mock_client.search = mocker.MagicMock(return_value={"hits": {"hits": []}})
    mocker.patch("app.core.elasticsearch.es", mock_client)
    mocker.patch("app.services.client_search_service.es", mock_client)
    return mock_client


@pytest.fixture
def mock_storage(mocker):
    mock_upload = mocker.AsyncMock(return_value={"path": "test/path/file.jpg"})
    mock_delete = mocker.AsyncMock(return_value={"message": "deleted"})
    mock_signed_url = mocker.AsyncMock(
        return_value="https://storage.example.com/signed-url"
    )
    mocker.patch("app.services.storage_service.upload_file", mock_upload)
    mocker.patch("app.services.storage_service.delete_file", mock_delete)
    mocker.patch("app.services.storage_service.generate_signed_url", mock_signed_url)
    return {
        "upload": mock_upload,
        "delete": mock_delete,
        "signed_url": mock_signed_url,
    }


@pytest.fixture
def mock_sendgrid(mocker):
    mock_send = mocker.MagicMock(return_value=None)
    mocker.patch("app.utils.email_sender.sendMailUsingSendGrid", mock_send)
    return mock_send


@pytest.fixture(autouse=True)
def mock_email_validator(mocker):
    def mock_validate(email, **kwargs):
        if "@" not in email or "." not in email.split("@")[1]:
            from email_validator import EmailNotValidError

            raise EmailNotValidError("Invalid email format")
        return True

    mocker.patch(
        "app.services.client_service.validate_email", side_effect=mock_validate
    )
    mocker.patch("app.services.auth_service.validate_email", side_effect=mock_validate)
    return mock_validate


@pytest.fixture
async def test_client(
    test_db_session, mock_redis, mock_elasticsearch, mock_storage, mock_sendgrid
) -> AsyncGenerator[AsyncClient, None]:
    async def override_get_db():
        yield test_db_session

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        yield client
    app.dependency_overrides.clear()


@pytest.fixture
def sample_user_data():
    return {
        "name": "Test",
        "surname": "User",
        "email": "test@example.org",
        "password": "Test123!@#",
        "phone": "+905551234567",
    }


@pytest.fixture
def sample_client_data():
    return {
        "name": "John",
        "surname": "Doe",
        "email": "john.doe@example.org",
        "phone": "+905559876543",
        "company": "Acme Corp",
        "notes": "Test client notes",
        "source": "Website",
        "status": "Active",
        "category": "Lead",
        "industry": "Technology",
        "latitude": "41.0082",
        "longitude": "28.9784",
    }


@pytest.fixture
def sample_task_data():
    return {
        "title": "Follow up call",
        "description": "Call client about proposal",
        "status": "pending",
        "priority": "high",
    }


@pytest.fixture
async def create_test_user(test_db_session):
    from app.repositories import user_repo
    from app.core.security import hash_password

    async def _create_user(**kwargs):
        user_data = {
            "name": kwargs.get("name", "Test"),
            "surname": kwargs.get("surname", "User"),
            "email": kwargs.get("email", "test@example.org"),
            "password_hash": hash_password(kwargs.get("password", "Test123!@#")),
            "phone": kwargs.get("phone", "+905551234567"),
            "is_verified": kwargs.get("is_verified", True),
        }
        return await user_repo.create(test_db_session, **user_data)

    return _create_user


@pytest.fixture
async def create_test_client(test_db_session):
    from app.repositories import client_repo

    async def _create_client(owner_id: int, **kwargs):
        client_data = {
            "name": kwargs.get("name", "John"),
            "surname": kwargs.get("surname", "Doe"),
            "email": kwargs.get("email", "john.doe@example.org"),
            "phone": kwargs.get("phone", "+905559876543"),
            "company": kwargs.get("company", "Acme Corp"),
            "notes": kwargs.get("notes", "Test notes"),
            "source": kwargs.get("source", "Website"),
            "status": kwargs.get("status", "Active"),
            "category": kwargs.get("category", "Lead"),
            "industry": kwargs.get("industry", "Technology"),
            "latitude": kwargs.get("latitude", "41.0082"),
            "longitude": kwargs.get("longitude", "28.9784"),
            "owner_id": owner_id,
        }
        return await client_repo.create(test_db_session, **client_data)

    return _create_client
