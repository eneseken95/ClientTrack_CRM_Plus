from fastapi import HTTPException
from app.core.redis import redis_client


async def rate_limit_or_429(
    *,
    purpose: str,
    identifier: str,
    limit: int,
    window_seconds: int,
):
    key = f"rl:{purpose}:{identifier}"
    current = await redis_client.incr(key)
    ttl = await redis_client.ttl(key)
    if ttl == -1:
        await redis_client.expire(key, window_seconds)
    if current > limit:
        raise HTTPException(
            status_code=429, detail="Too many requests. Please try again later."
        )
