from fastapi import FastAPI, APIRouter
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.core.config import settings
from app.api.v1 import auth as auth_router
from app.api.v1 import clients as clients_router
from app.api.v1 import admin as admin_router
from app.api.v1 import user as user_router
from app.api.v1 import tasks as tasks_router
from app.api.v1 import emails as emails_router
from app.api.v1 import subscriptions as subscriptions_router
from app.api.v1 import webhooks as webhooks_router
from app.api.v1 import client_search as client_search_router
from app.jobs.token_cleanup import start_cleanup_loop
from app.jobs.task_reminder import start_scheduler
from app.jobs.es_bootstrap import ensure_client_index
from app.monitoring.middleware import prometheus_middleware
from app.monitoring.router import router as metrics_router
from app.middleware.rate_limit import GlobalRateLimitMiddleware
import asyncio


@asynccontextmanager
async def lifespan(app: FastAPI):
    ensure_client_index()
    asyncio.create_task(start_cleanup_loop())
    start_scheduler()
    yield


app = FastAPI(
    title="ClientTrack CRM+",
    description="",
    lifespan=lifespan,
)
app.add_middleware(GlobalRateLimitMiddleware, requests_per_minute=60)
app.middleware("http")(prometheus_middleware)
origins = [o.strip() for o in settings.CORS_ORIGINS.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(metrics_router)
api_v1 = APIRouter(prefix="/api/v1")
api_v1.include_router(auth_router.router)
api_v1.include_router(user_router.router)
api_v1.include_router(admin_router.router)
api_v1.include_router(clients_router.router)
api_v1.include_router(client_search_router.router)
api_v1.include_router(tasks_router.router)
api_v1.include_router(emails_router.router)
api_v1.include_router(subscriptions_router.router)
api_v1.include_router(webhooks_router.router)
app.include_router(api_v1)
