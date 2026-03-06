from fastapi import HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.config import settings
from app.services import client_service
from app.services.client_service import get_client_by_id
from app.services.storage_service import upload_file, generate_signed_url, delete_file

MAX_ATTACHMENTS = 20


async def upload_and_attach(
    db: AsyncSession, client_id: int, file: UploadFile, current_user
):
    client = await get_client_by_id(db, client_id)
    if not client:
        raise HTTPException(404, "Client not found")
    if client.owner_id != current_user.id:
        raise HTTPException(403, "Forbidden")
    existing = client.attachments or []
    if len(existing) >= MAX_ATTACHMENTS:
        raise HTTPException(400, "Maximum attachments allowed")
    file_bytes = await file.read()
    content_type = file.content_type
    filename = file.filename
    file_size = len(file_bytes)
    path = f"attachments/{client_id}/{file.filename}"
    await upload_file(
        path=path,
        file_bytes=file_bytes,
        content_type=content_type,
        bucket=settings.SUPABASE_ATTACHMENT_BUCKET,
    )
    import datetime

    attachment_metadata = {
        "path": path,
        "fileName": filename,
        "fileSize": file_size,
        "uploadedAt": datetime.datetime.now().isoformat(),
    }
    client.attachments = existing + [attachment_metadata]
    await db.commit()
    await db.refresh(client)
    signed_url = await generate_signed_url(
        path=path,
        expires_in=30,
        bucket=settings.SUPABASE_ATTACHMENT_BUCKET,
    )
    return signed_url


async def get_all_attachments(db: AsyncSession, client_id: int, current_user):
    client = await get_client_by_id(db, client_id)
    if not client:
        raise HTTPException(404, "Client not found")
    if client.owner_id != current_user.id:
        raise HTTPException(403, "Forbidden")
    attachments = client.attachments or []
    result = []
    for idx, attachment_data in enumerate(attachments):
        try:
            if isinstance(attachment_data, str):
                path = attachment_data
                filename = path.split("/")[-1]
                file_size = 0
                uploaded_at = "Unknown"
            else:
                path = attachment_data.get("path")
                filename = attachment_data.get("fileName", "")
                file_size = attachment_data.get("fileSize", 0)
                uploaded_at = attachment_data.get("uploadedAt", "Unknown")
                if not path and filename:
                    path = f"attachments/{client_id}/{filename}"
            if not path:
                continue
            signed_url = await generate_signed_url(
                path=path, expires_in=3600, bucket=settings.SUPABASE_ATTACHMENT_BUCKET
            )
            result.append(
                {
                    "id": idx + 1,
                    "fileName": filename or path.split("/")[-1],
                    "fileSize": file_size,
                    "fileUrl": signed_url,
                    "uploadedAt": uploaded_at,
                    "path": path,
                }
            )
        except Exception as e:
            continue
    return result


async def delete_attachment(db: AsyncSession, client_id: int, path: str, current_user):
    client = await get_client_by_id(db, client_id)
    if not client:
        raise HTTPException(404, "Client not found")
    if client.owner_id != current_user.id:
        raise HTTPException(403, "Forbidden")
    attachments = client.attachments or []
    found = False
    for att in attachments:
        if isinstance(att, str):
            if att == path:
                found = True
                break
        elif isinstance(att, dict):
            if att.get("path") == path:
                found = True
                break
    if not found:
        raise HTTPException(404, "Attachment not found")
    try:
        await delete_file(
            path=path,
            bucket=settings.SUPABASE_ATTACHMENT_BUCKET,
        )
    except Exception:
        pass
    new_attachments = []
    for att in attachments:
        if isinstance(att, str):
            if att != path:
                new_attachments.append(att)
        elif isinstance(att, dict):
            if att.get("path") != path:
                new_attachments.append(att)
        else:
            new_attachments.append(att)
    client.attachments = new_attachments
    await db.commit()
    await db.refresh(client)
    return True


async def upload_company_logo(db, client_id, file, current_user):
    client = await client_service.get_client_by_id(db, client_id)
    if not client:
        raise HTTPException(404, "Client not found")
    if client.owner_id != current_user.id:
        raise HTTPException(403, "Forbidden")
    path = f"company_logos/{client_id}/{file.filename}"
    file_bytes = await file.read()
    content_type = file.content_type or "application/octet-stream"
    if client.company_logo:
        try:
            await delete_file(
                path=client.company_logo, bucket=settings.SUPABASE_ATTACHMENT_BUCKET
            )
        except Exception as exc:
            pass
    await upload_file(
        path=path,
        file_bytes=file_bytes,
        content_type=content_type,
        bucket=settings.SUPABASE_ATTACHMENT_BUCKET,
    )
    client.company_logo = path
    await db.commit()
    await db.refresh(client)
    signed_url = await generate_signed_url(
        path=path, expires_in=30, bucket=settings.SUPABASE_ATTACHMENT_BUCKET
    )
    return {"status": "ok", "path": path, "signed_url": signed_url}


async def get_company_logo(db, client_id, current_user):
    client = await client_service.get_client_by_id(db, client_id)
    if not client:
        raise HTTPException(404, "Client not found")
    if client.owner_id != current_user.id:
        raise HTTPException(403, "Forbidden")
    if not client.company_logo:
        return None
    signed_url = await generate_signed_url(
        path=client.company_logo,
        expires_in=3600,
        bucket=settings.SUPABASE_ATTACHMENT_BUCKET,
    )
    return signed_url


async def delete_company_logo(db, client_id, current_user):
    client = await client_service.get_client_by_id(db, client_id)
    if not client:
        raise HTTPException(404, "Client not found")
    if client.owner_id != current_user.id:
        raise HTTPException(403, "Forbidden")
    if not client.company_logo:
        return
    await delete_file(
        path=client.company_logo, bucket=settings.SUPABASE_ATTACHMENT_BUCKET
    )
    client.company_logo = None
    await db.commit()
