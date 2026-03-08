from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.core.config import settings
from app.api.deps import get_current_admin
from app.schemas.user import UserOut
from app.schemas.client import ClientOut
from app.schemas.common import Paginated, PageMeta
from app.services import auth_service, client_service, user_service
from app.services.storage_service import generate_signed_url

router = APIRouter(prefix="/admin", tags=["users / admin"])


@router.get("/users", response_model=list[UserOut])
async def list_users(
    db: AsyncSession = Depends(get_db), admin=Depends(get_current_admin)
):
    users = await auth_service.admin_list_users(db)
    for u in users:
        if u.avatar_path:
            u.avatar_url = await generate_signed_url(
                u.avatar_path, expires_in=30, bucket=settings.SUPABASE_AVATAR_BUCKET
            )
        else:
            u.avatar_url = None
    return [UserOut.model_validate(u) for u in users]


@router.get("/user/{user_id}", response_model=Paginated)
async def admin_list_user_clients(
    user_id: int,
    page: int = 1,
    size: int = 20,
    db: AsyncSession = Depends(get_db),
    _=Depends(get_current_admin),
):
    items, total = await client_service.list_clients(db, user_id, page, size)
    client_dicts = [ClientOut.model_validate(i).model_dump() for i in items]
    from app.api.v1.clients import convert_client_urls

    for client_dict in client_dicts:
        await convert_client_urls(client_dict)
    return Paginated(
        items=[ClientOut(**i) for i in client_dicts],
        meta=PageMeta(page=page, size=size, total=total),
    )


@router.delete("/users/{user_id}")
async def delete_user(
    user_id: int, db: AsyncSession = Depends(get_db), admin=Depends(get_current_admin)
):
    if user_id == admin.id:
        raise HTTPException(
            status_code=400, detail="Admin cannot delete their own account"
        )
    ok = await user_service.admin_delete_user_and_files(db, user_id)
    if not ok:
        raise HTTPException(404, "User not found")
    return {"message": "User and all related data deleted successfully"}
