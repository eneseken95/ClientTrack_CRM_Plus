from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.services.client_search_service import search_clients

router = APIRouter(prefix="/search", tags=["search"])


@router.get("/clients")
async def search_client_api(q: str, current_user=Depends(get_current_user)):
    return search_clients(q, current_user.id)
