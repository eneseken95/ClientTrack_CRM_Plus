import pytest
from app.repositories import client_repo


@pytest.mark.unit
@pytest.mark.asyncio
class TestClientRepo:
    async def test_create_client(self, test_db_session, create_test_user):
        owner = await create_test_user()
        client = await client_repo.create(
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
        assert client.surname == "Doe"
        assert client.email == "john.doe@example.org"
        assert client.company == "Acme Corp"
        assert client.owner_id == owner.id

    async def test_get_client(
        self, test_db_session, create_test_user, create_test_client
    ):
        owner = await create_test_user()
        created_client = await create_test_client(owner_id=owner.id)
        found_client = await client_repo.get(test_db_session, created_client.id)
        assert found_client is not None
        assert found_client.id == created_client.id
        assert found_client.email == created_client.email

    async def test_get_client_not_found(self, test_db_session):
        client = await client_repo.get(test_db_session, 99999)
        assert client is None

    async def test_list_paginated(
        self, test_db_session, create_test_user, create_test_client
    ):
        owner = await create_test_user()
        await create_test_client(owner_id=owner.id, email="client1@example.org")
        await create_test_client(owner_id=owner.id, email="client2@example.org")
        await create_test_client(owner_id=owner.id, email="client3@example.org")
        items, total = await client_repo.list_paginated(
            test_db_session, owner_id=owner.id, page=1, size=2
        )
        assert len(items) == 2
        assert total == 3

    async def test_list_paginated_filters_by_owner(
        self, test_db_session, create_test_user, create_test_client
    ):
        owner1 = await create_test_user(email="owner1@example.org")
        owner2 = await create_test_user(email="owner2@example.org")
        await create_test_client(owner_id=owner1.id, email="client1@example.org")
        await create_test_client(owner_id=owner1.id, email="client2@example.org")
        await create_test_client(owner_id=owner2.id, email="client3@example.org")
        items, total = await client_repo.list_paginated(
            test_db_session, owner_id=owner1.id, page=1, size=10
        )
        assert len(items) == 2
        assert total == 2
        assert all(c.owner_id == owner1.id for c in items)

    async def test_update_client(
        self, test_db_session, create_test_user, create_test_client
    ):
        owner = await create_test_user()
        client = await create_test_client(owner_id=owner.id)
        updated_client = await client_repo.update(
            test_db_session, client, company="New Company Name", status="Inactive"
        )
        assert updated_client.id == client.id
        assert updated_client.company == "New Company Name"
        assert updated_client.status == "Inactive"
        assert updated_client.email == client.email

    async def test_update_client_with_none_values(
        self, test_db_session, create_test_user, create_test_client
    ):
        owner = await create_test_user()
        client = await create_test_client(owner_id=owner.id, company="Original Company")
        updated_client = await client_repo.update(
            test_db_session, client, company=None, status="Active"
        )
        assert updated_client.company == "Original Company"
        assert updated_client.status == "Active"

    async def test_delete_client(
        self, test_db_session, create_test_user, create_test_client
    ):
        owner = await create_test_user()
        client = await create_test_client(owner_id=owner.id)
        client_id = client.id
        result = await client_repo.delete(test_db_session, client_id)
        assert result is True
        deleted_client = await client_repo.get(test_db_session, client_id)
        assert deleted_client is None

    async def test_delete_client_not_found(self, test_db_session):
        result = await client_repo.delete(test_db_session, 99999)
        assert result is False

    async def test_list_paginated_admin(
        self, test_db_session, create_test_user, create_test_client
    ):
        owner1 = await create_test_user(email="owner1@example.org")
        owner2 = await create_test_user(email="owner2@example.org")
        await create_test_client(owner_id=owner1.id, email="client1@example.org")
        await create_test_client(owner_id=owner1.id, email="client2@example.org")
        await create_test_client(owner_id=owner2.id, email="client3@example.org")
        items, total = await client_repo.list_paginated_admin(
            test_db_session, page=1, size=10
        )
        assert len(items) == 3
        assert total == 3
