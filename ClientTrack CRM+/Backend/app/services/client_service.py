from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.config import settings
from app.models.client import Client
from app.repositories import client_repo
from app.services.storage_service import delete_file
from app.services.client_search_service import index_client, delete_client_from_index
from email_validator import validate_email, EmailNotValidError
import re


async def create_client(
    db: AsyncSession,
    *,
    name: str,
    surname: str,
    email: str,
    phone: str,
    company: str,
    notes: str,
    owner_id: int,
    source: str,
    status: str,
    category: str,
    industry: str,
    latitude: str,
    longitude: str
):
    try:
        validate_email(email)
    except EmailNotValidError:
        raise HTTPException(status_code=400, detail="Invalid email format")
    if not re.match(r"^\+?\d{10,15}$", phone):
        raise HTTPException(status_code=400, detail="Invalid phone format")
    client = await client_repo.create(
        db,
        name=name,
        surname=surname,
        email=email,
        phone=phone,
        company=company,
        notes=notes,
        owner_id=owner_id,
        source=source,
        status=status,
        category=category,
        industry=industry,
        latitude=latitude,
        longitude=longitude,
    )
    try:
        index_client(client)
    except Exception:
        pass
    return client


async def update_client(db: AsyncSession, id: int, current_user, **kwargs):
    stmt = select(Client).where(Client.id == id)
    if current_user.role != "admin":
        stmt = stmt.where(Client.owner_id == current_user.id)
    result = await db.execute(stmt)
    client = result.scalar_one_or_none()
    if not client:
        return None
    if client.owner_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Forbidden")
    kwargs.pop("attachments", None)
    if "email" in kwargs and kwargs["email"] is not None:
        try:
            validate_email(kwargs["email"])
        except EmailNotValidError:
            raise HTTPException(status_code=400, detail="Invalid email format")
    if "phone" in kwargs and kwargs["phone"] is not None:
        if not re.match(r"^\+?\d{10,15}$", kwargs["phone"]):
            raise HTTPException(status_code=400, detail="Invalid phone format")
    return await client_repo.update(db, client, **kwargs)


async def delete_client(db: AsyncSession, client_id: int, current_user):
    client = await client_repo.get(db, client_id)
    if not client:
        raise HTTPException(404, "Client not found")
    if client.owner_id != current_user.id:
        raise HTTPException(403, "Forbidden")
    if client.attachments:
        for path in client.attachments:
            try:
                await delete_file(path=path, bucket=settings.SUPABASE_ATTACHMENT_BUCKET)
            except Exception as e:
                pass
    if client.company_logo:
        try:
            await delete_file(
                path=client.company_logo, bucket=settings.SUPABASE_ATTACHMENT_BUCKET
            )
        except Exception as e:
            pass
    try:
        delete_client_from_index(client_id)
    except Exception as e:
        pass
    deleted = await client_repo.delete(db, client_id)
    return deleted


async def list_clients(db: AsyncSession, user_id: int, page: int, size: int):
    if user_id is None:
        return await client_repo.list_paginated_admin(db, page=page, size=size)
    return await client_repo.list_paginated(db, owner_id=user_id, page=page, size=size)


async def get_client_by_id(db: AsyncSession, client_id: int) -> Client | None:
    stmt = select(Client).where(Client.id == client_id)
    result = await db.execute(stmt)
    return result.scalars().first()
