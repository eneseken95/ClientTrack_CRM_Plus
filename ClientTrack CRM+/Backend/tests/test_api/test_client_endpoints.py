import pytest


@pytest.mark.integration
@pytest.mark.asyncio
class TestClientEndpoints:
    async def test_create_client_endpoint(
        self, test_client, authenticated_user, mock_elasticsearch
    ):
        user, token = authenticated_user
        response = await test_client.post(
            "/api/v1/clients/",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "name": "John",
                "surname": "Doe",
                "email": "john.doe@example.org",
                "phone": "+905559876543",
                "company": "Acme Corp",
                "notes": "Test notes",
                "source": "Website",
                "status": "Active",
                "category": "Lead",
                "industry": "Technology",
                "latitude": "41.0082",
                "longitude": "28.9784",
            },
        )
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "John"
        assert data["email"] == "john.doe@example.org"
        assert data["company"] == "Acme Corp"

    async def test_create_client_unauthorized(self, test_client, mock_elasticsearch):
        response = await test_client.post(
            "/api/v1/clients/",
            json={
                "name": "John",
                "surname": "Doe",
                "email": "john.doe@example.org",
                "phone": "+905559876543",
                "company": "Acme Corp",
                "notes": "Test notes",
                "source": "Website",
                "status": "Active",
                "category": "Lead",
                "industry": "Technology",
                "latitude": "41.0082",
                "longitude": "28.9784",
            },
        )
        assert response.status_code == 403

    async def test_list_clients_endpoint(
        self, test_client, authenticated_user, create_test_client, mock_redis
    ):
        user, token = authenticated_user
        await create_test_client(owner_id=user.id, email="client1@example.org")
        await create_test_client(owner_id=user.id, email="client2@example.org")
        response = await test_client.get(
            "/api/v1/clients/?page=1&size=10",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "meta" in data
        assert len(data["items"]) == 2
        assert data["meta"]["total"] == 2

    async def test_list_clients_filters_by_owner(
        self,
        test_client,
        create_test_user,
        create_test_client,
        authenticated_user,
        mock_redis,
    ):
        user1, token1 = authenticated_user
        user2 = await create_test_user(email="other@example.org")
        await create_test_client(owner_id=user1.id, email="client1@example.org")
        await create_test_client(owner_id=user2.id, email="client2@example.org")
        response = await test_client.get(
            "/api/v1/clients/", headers={"Authorization": f"Bearer {token1}"}
        )
        assert response.status_code == 200
        data = response.json()
        assert len(data["items"]) == 1

    async def test_update_client_endpoint(
        self,
        test_client,
        authenticated_user,
        create_test_client,
        mock_redis,
        mock_elasticsearch,
    ):
        user, token = authenticated_user
        client = await create_test_client(owner_id=user.id)
        response = await test_client.patch(
            f"/api/v1/clients/patch/{client.id}",
            headers={"Authorization": f"Bearer {token}"},
            json={"company": "Updated Company", "status": "Inactive"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["company"] == "Updated Company"
        assert data["status"] == "Inactive"

    async def test_update_client_forbidden(
        self,
        test_client,
        create_test_user,
        create_test_client,
        authenticated_user,
        mock_redis,
        mock_elasticsearch,
    ):
        user1, token1 = authenticated_user
        user2 = await create_test_user(email="other@example.org")
        client = await create_test_client(owner_id=user2.id)
        response = await test_client.patch(
            f"/api/v1/clients/patch/{client.id}",
            headers={"Authorization": f"Bearer {token1}"},
            json={"company": "Hacked Company"},
        )
        assert response.status_code == 404

    async def test_delete_client_endpoint(
        self,
        test_client,
        authenticated_user,
        create_test_client,
        mock_redis,
        mock_storage,
        mock_elasticsearch,
    ):
        user, token = authenticated_user
        client = await create_test_client(owner_id=user.id)
        response = await test_client.delete(
            f"/api/v1/clients/{client.id}", headers={"Authorization": f"Bearer {token}"}
        )
        assert response.status_code == 200
        assert response.json()["status"] == "deleted"

    async def test_delete_client_forbidden(
        self,
        test_client,
        create_test_user,
        create_test_client,
        authenticated_user,
        mock_redis,
        mock_storage,
        mock_elasticsearch,
    ):
        user1, token1 = authenticated_user
        user2 = await create_test_user(email="other@example.org")
        client = await create_test_client(owner_id=user2.id)
        response = await test_client.delete(
            f"/api/v1/clients/{client.id}",
            headers={"Authorization": f"Bearer {token1}"},
        )
        assert response.status_code == 403

    async def test_get_client_emails_endpoint(
        self, test_client, authenticated_user, create_test_client
    ):
        user, token = authenticated_user
        client = await create_test_client(owner_id=user.id)
        response = await test_client.get(
            f"/api/v1/clients/{client.id}/emails",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        assert isinstance(response.json(), list)

    async def test_upload_company_logo_endpoint(
        self, test_client, authenticated_user, create_test_client, mock_storage
    ):
        user, token = authenticated_user
        client = await create_test_client(owner_id=user.id)
        files = {"file": ("logo.png", b"fake image content", "image/png")}
        response = await test_client.put(
            f"/api/v1/clients/{client.id}/company-logo",
            headers={"Authorization": f"Bearer {token}"},
            files=files,
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert "path" in data or "signed_url" in data

    async def test_get_company_logo_endpoint(
        self, test_client, authenticated_user, create_test_client, mock_storage
    ):
        user, token = authenticated_user
        client = await create_test_client(owner_id=user.id)
        response = await test_client.get(
            f"/api/v1/clients/{client.id}/logo",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        assert "logo" in response.json()

    async def test_delete_company_logo_endpoint(
        self, test_client, authenticated_user, create_test_client, mock_storage
    ):
        user, token = authenticated_user
        client = await create_test_client(owner_id=user.id)
        response = await test_client.delete(
            f"/api/v1/clients/{client.id}/logo",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        assert response.json()["status"] == "deleted"
