from app.core.config import settings
import httpx

SUPABASE_URL = settings.SUPABASE_URL
SERVICE_KEY = settings.SUPABASE_SERVICE_KEY


async def upload_file(path: str, file_bytes: bytes, content_type: str, bucket: str):
    url = f"{SUPABASE_URL}/storage/v1/object/{bucket}/{path}"
    headers = {
        "Authorization": f"Bearer {SERVICE_KEY}",
        "Content-Type": content_type,
    }
    timeout = httpx.Timeout(60.0, connect=10.0)
    async with httpx.AsyncClient(timeout=timeout) as client:
        res = await client.put(url, content=file_bytes, headers=headers)
    if res.status_code not in (200, 201):
        raise Exception(f"Upload failed: {res.text}")
    return True


async def generate_signed_url(
    path: str, expires_in: int, bucket: str, retries: int = 3
):
    import asyncio

    url = f"{SUPABASE_URL}/storage/v1/object/sign/{bucket}/{path}"
    headers = {
        "Authorization": f"Bearer {SERVICE_KEY}",
        "Content-Type": "application/json",
    }
    last_error = None
    timeout = httpx.Timeout(30.0, connect=10.0)
    for attempt in range(retries):
        async with httpx.AsyncClient(timeout=timeout) as client:
            res = await client.post(
                url, json={"expiresIn": expires_in}, headers=headers
            )
        if res.status_code == 200:
            signed = res.json().get("signedURL")
            if signed.startswith("/"):
                signed = f"{SUPABASE_URL}/storage/v1{signed}"
            return signed
        last_error = res.text
        if attempt < retries - 1:
            await asyncio.sleep(0.5)
    raise Exception(f"Signed URL error: {last_error}")


async def delete_file(path: str, bucket: str):
    url = f"{SUPABASE_URL}/storage/v1/object/{bucket}/{path}"
    headers = {
        "Authorization": f"Bearer {SERVICE_KEY}",
    }
    timeout = httpx.Timeout(30.0, connect=10.0)
    async with httpx.AsyncClient(timeout=timeout) as client:
        res = await client.delete(url, headers=headers)
    if res.status_code not in (200, 204):

        pass
