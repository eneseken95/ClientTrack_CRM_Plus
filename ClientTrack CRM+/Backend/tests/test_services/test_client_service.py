import pytest
from fastapi import HTTPException
from app.services import client_service


@pytest.mark.unit
@pytest.mark.asyncio
class TestClientService:
    async def test_create_client_success(
        self, test_db_session, create_test_user, mock_elasticsearch
    ):
        owner = await create_test_user()
        client = await client_service.create_client(
            db=test_db_session,
            name="John",
            surname="Doe",
            email="john.doe@example.org",
            phone="+905559876543",
            company="Acme Corp",
            notes="Test notes",
            source="Website",
            status="Active",
            category="Lead",
            industry="Technology",
            latitude="41.0082",
            longitude="28.9784",
            owner_id=owner.id,
        )
        assert client.id is not None
        assert client.name == "John"
        assert client.email == "john.doe@example.org"
        assert client.owner_id == owner.id

    async def test_create_client_invalid_email(
        self, test_db_session, create_test_user, mock_elasticsearch
    ):
        owner = await create_test_user()
        with pytest.raises(HTTPException) as exc_info:
            await client_service.create_client(
                db=test_db_session,
                name="John",
                surname="Doe",
                email="invalid-email",
                phone="+905559876543",
                company="Acme Corp",
                notes="Test notes",
                source="Website",
                status="Active",
                category="Lead",
                industry="Technology",
                latitude="41.0082",
                longitude="28.9784",
                owner_id=owner.id,
            )
        assert exc_info.value.status_code == 400
        assert "Invalid email format" in str(exc_info.value.detail)

    async def test_create_client_invalid_phone(
        self, test_db_session, create_test_user, mock_elasticsearch
    ):
        owner = await create_test_user()
        with pytest.raises(HTTPException) as exc_info:
            await client_service.create_client(
                db=test_db_session,
                name="John",
                surname="Doe",
                email="john.doe@example.org",
                phone="123",
                company="Acme Corp",
                notes="Test notes",
                source="Website",
                status="Active",
                category="Lead",
                industry="Technology",
                latitude="41.0082",
                longitude="28.9784",
                owner_id=owner.id,
            )
        assert exc_info.value.status_code == 400
        assert "Invalid phone format" in str(exc_info.value.detail)

    async def test_update_client_as_owner(
        self, test_db_session, create_test_user, create_test_client, mock_elasticsearch
    ):
        owner = await create_test_user()
        client = await create_test_client(owner_id=owner.id)
        updated_client = await client_service.update_client(
            db=test_db_session,
            id=client.id,
            current_user=owner,
            company="Updated Company",
            status="Inactive",
        )
        assert updated_client is not None
        assert updated_client.company == "Updated Company"
        assert updated_client.status == "Inactive"

    async def test_update_client_not_owner_forbidden(
        self, test_db_session, create_test_user, create_test_client, mock_elasticsearch
    ):
        owner = await create_test_user(email="owner@example.org")
        other_user = await create_test_user(email="other@example.org")
        client = await create_test_client(owner_id=owner.id)
        result = await client_service.update_client(
            db=test_db_session,
            id=client.id,
            current_user=other_user,
            company="Updated Company",
        )
        assert result is None

    async def test_update_client_invalid_email(
        self, test_db_session, create_test_user, create_test_client, mock_elasticsearch
    ):
        owner = await create_test_user()
        client = await create_test_client(owner_id=owner.id)
        with pytest.raises(HTTPException) as exc_info:
            await client_service.update_client(
                db=test_db_session,
                id=client.id,
                current_user=owner,
                email="invalid-email",
            )
        assert exc_info.value.status_code == 400
        assert "Invalid email format" in str(exc_info.value.detail)

    async def test_update_client_invalid_phone(
        self, test_db_session, create_test_user, create_test_client, mock_elasticsearch
    ):
        owner = await create_test_user()
        client = await create_test_client(owner_id=owner.id)
        with pytest.raises(HTTPException) as exc_info:
            await client_service.update_client(
                db=test_db_session, id=client.id, current_user=owner, phone="123"
            )
        assert exc_info.value.status_code == 400
        assert "Invalid phone format" in str(exc_info.value.detail)

    async def test_delete_client_as_owner(
        self,
        test_db_session,
        create_test_user,
        create_test_client,
        mock_storage,
        mock_elasticsearch,
    ):
        owner = await create_test_user()
        client = await create_test_client(owner_id=owner.id)
        result = await client_service.delete_client(
            db=test_db_session, client_id=client.id, current_user=owner
        )
        assert result is True

    async def test_delete_client_not_owner_forbidden(
        self,
        test_db_session,
        create_test_user,
        create_test_client,
        mock_storage,
        mock_elasticsearch,
    ):
        owner = await create_test_user(email="owner@example.org")
        other_user = await create_test_user(email="other@example.org")
        client = await create_test_client(owner_id=owner.id)
        with pytest.raises(HTTPException) as exc_info:
            await client_service.delete_client(
                db=test_db_session, client_id=client.id, current_user=other_user
            )
        assert exc_info.value.status_code == 403

    async def test_delete_client_not_found(
        self, test_db_session, create_test_user, mock_storage, mock_elasticsearch
    ):
        owner = await create_test_user()
        with pytest.raises(HTTPException) as exc_info:
            await client_service.delete_client(
                db=test_db_session, client_id=99999, current_user=owner
            )
        assert exc_info.value.status_code == 404

    async def test_list_clients(
        self, test_db_session, create_test_user, create_test_client
    ):
        owner = await create_test_user()
        await create_test_client(owner_id=owner.id, email="client1@example.org")
        await create_test_client(owner_id=owner.id, email="client2@example.org")
        items, total = await client_service.list_clients(
            db=test_db_session, user_id=owner.id, page=1, size=10
        )
        assert len(items) == 2
        assert total == 2

    async def test_get_client_by_id(
        self, test_db_session, create_test_user, create_test_client
    ):
        owner = await create_test_user()
        client = await create_test_client(owner_id=owner.id)
        found_client = await client_service.get_client_by_id(
            db=test_db_session, client_id=client.id
        )
        assert found_client is not None
        assert found_client.id == client.id

    async def test_get_client_by_id_not_found(self, test_db_session):
        found_client = await client_service.get_client_by_id(
            db=test_db_session, client_id=99999
        )
        assert found_client is None
