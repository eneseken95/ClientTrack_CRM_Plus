from fastapi import APIRouter, Response, Depends
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
from app.api.deps import get_current_admin

router = APIRouter(tags=["metrics"])


@router.get("/metrics", summary="Prometheus metrics")
def metrics(
    admin=Depends(get_current_admin),
):
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
