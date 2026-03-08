from fastapi import Request
from app.monitoring.metrics import REQUEST_COUNT, REQUEST_LATENCY
from app.monitoring.utils import normalize_path
import time


async def prometheus_middleware(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    path = normalize_path(request.url.path)
    REQUEST_COUNT.labels(request.method, path, response.status_code).inc()
    REQUEST_LATENCY.labels(request.method, path).observe(duration)
    return response
