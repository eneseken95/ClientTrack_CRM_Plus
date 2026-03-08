from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.services import stripe_service
from app.services.rate_limit_service import rate_limit_or_429
from app.schemas.subscription import (
    CreatePaymentIntentRequest,
    CreatePaymentIntentResponse,
    SubscriptionStatusResponse,
)

router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])


@router.post("/create-payment-intent", response_model=CreatePaymentIntentResponse)
async def create_payment_intent(
    request: CreatePaymentIntentRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    await rate_limit_or_429(
        purpose="payment_intent",
        identifier=str(user.id),
        limit=20,
        window_seconds=60,
    )
    try:
        result = await stripe_service.create_subscription_payment_intent(
            db, user, request.plan_id
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/cancel")
async def cancel_subscription(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    await rate_limit_or_429(
        purpose="cancel_sub",
        identifier=str(user.id),
        limit=5,
        window_seconds=300,
    )
    try:
        await stripe_service.cancel_user_subscription(db, user)
        return {"success": True, "message": "Subscription canceled."}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/status", response_model=SubscriptionStatusResponse)
async def get_subscription_status(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    await rate_limit_or_429(
        purpose="sub_status",
        identifier=str(user.id),
        limit=20,
        window_seconds=60,
    )
    verification = await stripe_service.verify_subscription_with_stripe(db, user)
    return {
        "subscription_status": verification["status"],
        "subscription_plan_id": user.subscription_plan_id,
        "current_period_end": (
            user.current_period_end.isoformat() if user.current_period_end else None
        ),
    }


from app.schemas.subscription import SubscriptionPricesResponse


@router.get("/prices", response_model=SubscriptionPricesResponse)
async def get_subscription_prices(
    db: AsyncSession = Depends(get_db),
):
    prices = await stripe_service.get_subscription_prices()
    return {"prices": prices}
