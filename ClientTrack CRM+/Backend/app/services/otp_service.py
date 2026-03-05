from app.core.redis import redis_client
from app.core.security import hash_otp, verify_otp
OTP_TTL_SECONDS = 300


def _key(purpose: str, email: str) -> str:
    return f"otp:{purpose}:{email}"


async def store_otp(purpose: str, email: str, raw_otp: str):
    hashed = hash_otp(raw_otp)
    await redis_client.setex(_key(purpose, email), OTP_TTL_SECONDS, hashed)


async def verify_and_consume_otp(purpose: str, email: str, raw_otp: str) -> bool:
    key = _key(purpose, email)
    stored = await redis_client.get(key)
    if not stored:
        return False
    if not verify_otp(raw_otp, stored):
        return False
    await redis_client.delete(key)
    return True


async def otp_exists(purpose: str, email: str) -> bool:
    return bool(await redis_client.exists(_key(purpose, email)))
