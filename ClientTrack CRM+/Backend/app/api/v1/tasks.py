from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.core.config import settings
from app.api.deps import get_current_user
from app.schemas.task import TaskCreate, TaskOut, TaskUpdate
from app.services import task_service
from app.services.cache_service import get_or_set_cache, invalidate_pattern
from app.services.storage_service import generate_signed_url

router = APIRouter(prefix="/tasks", tags=["tasks"])


async def convert_task_urls(task_dict: dict) -> dict:
    if task_dict.get("client_logo"):
        try:
            task_dict["client_logo"] = await generate_signed_url(
                path=task_dict["client_logo"],
                expires_in=3600,
                bucket=settings.SUPABASE_ATTACHMENT_BUCKET,
            )
        except:
            pass
    return task_dict


@router.post("", response_model=TaskOut)
async def create_task(
    data: TaskCreate, db: AsyncSession = Depends(get_db), user=Depends(get_current_user)
):
    await invalidate_pattern(f"cache:tasks:{user.id}*")
    obj = await task_service.create_task(db, data, user.id)
    task_dict = TaskOut.model_validate(obj).model_dump()
    await convert_task_urls(task_dict)
    return task_dict


@router.get("", response_model=list[TaskOut])
async def list_tasks(
    db: AsyncSession = Depends(get_db), user=Depends(get_current_user)
):
    cache_key = f"cache:tasks:{user.id}"

    async def fetch():
        tasks = await task_service.list_tasks(db, user.id)
        task_dicts = [TaskOut.model_validate(t).model_dump() for t in tasks]
        for task_dict in task_dicts:
            await convert_task_urls(task_dict)
        return task_dicts

    data = await get_or_set_cache(cache_key, fetch)
    return [TaskOut(**t) for t in data]


@router.get("/client/{client_id}", response_model=list[TaskOut])
async def list_client_tasks(
    client_id: int, db: AsyncSession = Depends(get_db), user=Depends(get_current_user)
):
    cache_key = f"cache:tasks_client:{user.id}:{client_id}"

    async def fetch():
        tasks = await task_service.list_client_tasks(db, user.id, client_id)
        task_dicts = [TaskOut.model_validate(t).model_dump() for t in tasks]
        for task_dict in task_dicts:
            await convert_task_urls(task_dict)
        return task_dicts

    data = await get_or_set_cache(cache_key, fetch)
    return [TaskOut(**t) for t in data]


@router.patch("/{task_id}", response_model=TaskOut)
async def update_task(
    task_id: int,
    data: TaskUpdate,
    db: AsyncSession = Depends(get_db),
    user=Depends(get_current_user),
):
    task = await task_service.update_task(db, task_id, user.id, data)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    await invalidate_pattern(f"cache:tasks:{user.id}*")
    await invalidate_pattern(f"cache:tasks_client:{user.id}*")
    task_dict = TaskOut.model_validate(task).model_dump()
    await convert_task_urls(task_dict)
    return task_dict


@router.delete("/{task_id}")
async def delete_task(
    task_id: int, db: AsyncSession = Depends(get_db), user=Depends(get_current_user)
):
    ok = await task_service.delete_task(db, task_id, user.id)
    if not ok:
        raise HTTPException(status_code=404, detail="Task not found")
    await invalidate_pattern(f"cache:tasks:{user.id}*")
    await invalidate_pattern(f"cache:tasks_client:{user.id}*")
    return {"message": "Task deleted"}
