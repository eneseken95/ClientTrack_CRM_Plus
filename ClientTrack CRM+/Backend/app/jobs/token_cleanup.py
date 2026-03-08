from app.core.db import SessionLocal
from app.services.auth_service import delete_old_revoked_tokens
import asyncio


async def start_cleanup_loop():
    while True:
        await asyncio.sleep(10)
        try:
            async with SessionLocal() as db:
                deleted = await delete_old_revoked_tokens(db)
        except Exception as e:

            pass
