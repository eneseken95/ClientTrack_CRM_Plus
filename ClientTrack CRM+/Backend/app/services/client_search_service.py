from app.core.elasticsearch import es
from app.search.client_index import CLIENT_INDEX


def index_client(client):
    es.index(
        index=CLIENT_INDEX,
        id=client.id,
        document={
            "id": client.id,
            "name": client.name,
            "surname": client.surname,
            "email": client.email,
            "phone": client.phone,
            "company": client.company,
            "notes": client.notes,
            "owner_id": client.owner_id,
            "company_logo": client.company_logo,
        },
    )


def search_clients(query: str, owner_id: int):
    res = es.search(
        index=CLIENT_INDEX,
        query={
            "bool": {
                "must": [
                    {
                        "multi_match": {
                            "query": query,
                            "fields": [
                                "name^3",
                                "surname^2",
                                "company",
                                "notes",
                                "email",
                            ],
                        }
                    }
                ],
                "filter": [{"term": {"owner_id": owner_id}}],
            }
        },
    )
    return [hit["_source"] for hit in res["hits"]["hits"]]


def delete_client_from_index(client_id: int):
    try:
        es.delete(index=CLIENT_INDEX, id=client_id)
    except Exception as e:

        pass
