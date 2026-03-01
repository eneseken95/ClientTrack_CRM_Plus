from typing import Optional
from datetime import datetime, timezone


def normalize_to_utc(dt: Optional[datetime]):
    if dt is None:
        return None
    if dt.tzinfo is not None:
        return dt.astimezone(timezone.utc)
    return dt.replace(tzinfo=timezone.utc)
