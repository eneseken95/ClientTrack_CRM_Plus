from fastapi.encoders import jsonable_encoder
from app.core.redis import redis_client
import logging
import json

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger("cache")
CACHE_TTL = 30


async def get_or_set_cache(key: str, fetch_fn, ttl: int = 60):
    cached = await redis_client.get(key)
    if cached:
        logger.info(f"[CACHE HIT] {key}")
        return json.loads(cached)
    logger.info(f"[CACHE MISS] {key}")
    data = await fetch_fn()
    safe_data = jsonable_encoder(data)
    await redis_client.setex(key, ttl, json.dumps(safe_data))
    logger.info(f"[CACHE SET] {key} (ttl={ttl}s)")
    return safe_data


async def invalidate_pattern(pattern: str):
    keys = await redis_client.keys(pattern)
    if keys:
        await redis_client.delete(*keys)
        logger.info(f"[CACHE INVALIDATE] {pattern} → {len(keys)} keys")
