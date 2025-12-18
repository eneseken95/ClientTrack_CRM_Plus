from .config import settings
from datetime import datetime, timedelta, timezone
from uuid import uuid4
from jose import jwt
from passlib.context import CryptContext
import hashlib
import hmac

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
pwd_otp_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(raw: str) -> str:
    return pwd_context.hash(raw)


def hash_otp(otp: str) -> str:
    return pwd_otp_context.hash(otp)


def verify_password(raw: str, hashed: str) -> bool:
    return pwd_context.verify(raw, hashed)


def verify_otp(plain_otp: str, hashed_otp: str) -> bool:
    return pwd_otp_context.verify(plain_otp, hashed_otp)


def create_access_token(sub: str, minutes: int | None = None) -> str:
    now = datetime.now(timezone.utc)
    exp = now + timedelta(minutes=minutes or settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {
        "sub": sub,
        "type": "access",
        "iat": int(now.timestamp()),
        "exp": int(exp.timestamp()),
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_refresh_token(sub: str, minutes: int | None = None):
    now = datetime.now(timezone.utc)
    exp = now + timedelta(minutes=minutes or settings.REFRESH_TOKEN_EXPIRE_MINUTES)
    jti = str(uuid4())
    payload = {
        "sub": sub,
        "type": "refresh",
        "jti": jti,
        "iat": int(now.timestamp()),
        "exp": int(exp.timestamp()),
    }
    token = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return token, jti, exp


def hash_refresh_token(token: str) -> str:
    secret = settings.REFRESH_TOKEN_SECRET_KEY.encode()
    return hmac.new(secret, token.encode(), hashlib.sha256).hexdigest()
