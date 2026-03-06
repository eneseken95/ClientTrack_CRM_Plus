from typing import Optional
import stripe
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timezone
from app.core.config import settings
from app.models.user import User

stripe.api_key = settings.STRIPE_SECRET_KEY


def _get_plan_name_from_price_id(price_id: str) -> Optional[str]:
    price_map = {
        "basic_monthly": settings.STRIPE_PRICE_BASIC_MONTHLY,
        "basic_yearly": settings.STRIPE_PRICE_BASIC_YEARLY,
        "pro_monthly": settings.STRIPE_PRICE_PRO_MONTHLY,
        "pro_yearly": settings.STRIPE_PRICE_PRO_YEARLY,
        "team_monthly": settings.STRIPE_PRICE_TEAM_MONTHLY,
        "team_yearly": settings.STRIPE_PRICE_TEAM_YEARLY,
    }
    for plan, p_id in price_map.items():
        if p_id and p_id.strip() == price_id:
            return plan
    return None

async def verify_subscription_with_stripe(db: AsyncSession, user: User) -> dict:
    if not user.stripe_customer_id:
        if user.subscription_status == "active":
            user.subscription_status = "none"
            user.subscription_plan_id = None
            user.current_period_end = None
            await db.commit()
        return {"status": "none", "valid": True}
    try:
        subscriptions = stripe.Subscription.list(
            customer=user.stripe_customer_id,
            status="active",
            limit=1,
        )
        if subscriptions.data:
            real_sub = subscriptions.data[0]
            real_status = real_sub.status
            real_period_end = datetime.fromtimestamp(
                real_sub.current_period_end, tz=timezone.utc
            )
            price_id = real_sub.items.data[0].price.id if real_sub.items and real_sub.items.data else None
            plan_name = _get_plan_name_from_price_id(price_id) if price_id else real_sub.id
            if (
                user.subscription_status != real_status
                or user.subscription_plan_id != plan_name
            ):
                user.subscription_status = real_status
                user.subscription_plan_id = plan_name
                user.current_period_end = real_period_end
                await db.commit()
            return {"status": real_status, "valid": True}
        else:
            if user.subscription_status == "active":
                user.subscription_status = "none"
                user.subscription_plan_id = None
                user.current_period_end = None
                await db.commit()
            return {"status": "none", "valid": True}
    except Exception:
        return {"status": user.subscription_status, "valid": False}


async def get_or_create_stripe_customer(db: AsyncSession, user: User) -> str:
    if user.stripe_customer_id:
        return user.stripe_customer_id
    customer = stripe.Customer.create(
        email=user.email,
        name=f"{user.name} {user.surname or ''}".strip(),
        metadata={"user_id": str(user.id)},
    )
    user.stripe_customer_id = customer.id
    await db.commit()
    await db.refresh(user)
    return customer.id


async def create_subscription_payment_intent(
    db: AsyncSession, user: User, plan_id: str
) -> dict:
    price_map = {
        "basic_monthly": settings.STRIPE_PRICE_BASIC_MONTHLY,
        "basic_yearly": settings.STRIPE_PRICE_BASIC_YEARLY,
        "pro_monthly": settings.STRIPE_PRICE_PRO_MONTHLY,
        "pro_yearly": settings.STRIPE_PRICE_PRO_YEARLY,
        "team_monthly": settings.STRIPE_PRICE_TEAM_MONTHLY,
        "team_yearly": settings.STRIPE_PRICE_TEAM_YEARLY,
    }
    price_id = price_map.get(plan_id)
    if not price_id:
        raise ValueError(
            f"Invalid plan ID or missing Stripe price ID for plan: {plan_id}"
        )
    price_id = price_id.strip()
    customer_id = await get_or_create_stripe_customer(db, user)
    ephemeral_key = stripe.EphemeralKey.create(
        customer=customer_id,
        stripe_version="2024-06-20",
    )
    subscription = stripe.Subscription.create(
        customer=customer_id,
        items=[{"price": price_id}],
        payment_behavior="default_incomplete",
        payment_settings={"save_default_payment_method": "on_subscription"},
        expand=["latest_invoice.payment_intent"],
    )
    user.subscription_plan_id = plan_id
    user.subscription_status = subscription.status
    if subscription.current_period_end:
        user.current_period_end = datetime.fromtimestamp(
            subscription.current_period_end, tz=timezone.utc
        )
    await db.commit()
    return {
        "payment_intent": subscription.latest_invoice.payment_intent.client_secret,
        "ephemeral_key": ephemeral_key.secret,
        "customer": customer_id,
        "publishable_key": settings.STRIPE_PUBLISHABLE_KEY,
    }


async def get_subscription_status(user: User) -> dict:
    return {
        "subscription_status": user.subscription_status or "none",
        "subscription_plan_id": user.subscription_plan_id,
        "current_period_end": (
            user.current_period_end.isoformat() if user.current_period_end else None
        ),
    }


async def handle_invoice_paid(db: AsyncSession, invoice: dict):
    customer_id = invoice.get("customer")
    if not customer_id:
        return
    result = await db.execute(
        select(User).where(User.stripe_customer_id == customer_id)
    )
    user = result.scalar_one_or_none()
    if not user:
        return
    subscription_id = invoice.get("subscription")
    if subscription_id:
        sub = stripe.Subscription.retrieve(subscription_id)
        user.subscription_status = "active"
        price_id = sub.items.data[0].price.id if sub.items and sub.items.data else None
        plan_name = _get_plan_name_from_price_id(price_id) if price_id else subscription_id
        user.subscription_plan_id = plan_name
        user.current_period_end = datetime.fromtimestamp(
            sub.current_period_end, tz=timezone.utc
        )
    else:
        user.subscription_status = "active"
    await db.commit()


async def handle_subscription_deleted(db: AsyncSession, subscription: dict):
    customer_id = subscription.get("customer")
    if not customer_id:
        return
    result = await db.execute(
        select(User).where(User.stripe_customer_id == customer_id)
    )
    user = result.scalar_one_or_none()
    if not user:
        return
    user.subscription_status = "canceled"
    user.subscription_plan_id = None
    user.current_period_end = None
    await db.commit()


async def handle_payment_failed(db: AsyncSession, invoice: dict):
    customer_id = invoice.get("customer")
    if not customer_id:
        return
    result = await db.execute(
        select(User).where(User.stripe_customer_id == customer_id)
    )
    user = result.scalar_one_or_none()
    if not user:
        return
    user.subscription_status = "past_due"
    await db.commit()


async def cancel_user_subscription(db: AsyncSession, user: User):
    if not user.stripe_customer_id:
        return
    try:
        subscriptions = stripe.Subscription.list(
            customer=user.stripe_customer_id,
            status="active",
            limit=10,
        )
        for sub in subscriptions.data:
            stripe.Subscription.cancel(sub.id)

        user.subscription_status = "canceled"
        user.subscription_plan_id = None
        user.current_period_end = None
        await db.commit()
    except stripe.error.StripeError:
        pass


_price_cache = None
_price_cache_time = 0


async def get_subscription_prices() -> list[dict]:
    global _price_cache, _price_cache_time
    import time

    current_time = time.time()
    if _price_cache and (current_time - _price_cache_time) < 3600:
        return _price_cache
    price_map = {
        "basic_monthly": settings.STRIPE_PRICE_BASIC_MONTHLY,
        "basic_yearly": settings.STRIPE_PRICE_BASIC_YEARLY,
        "pro_monthly": settings.STRIPE_PRICE_PRO_MONTHLY,
        "pro_yearly": settings.STRIPE_PRICE_PRO_YEARLY,
        "team_monthly": settings.STRIPE_PRICE_TEAM_MONTHLY,
        "team_yearly": settings.STRIPE_PRICE_TEAM_YEARLY,
    }
    prices = []
    for plan_id, stripe_price_id in price_map.items():
        if not stripe_price_id:
            continue
        stripe_price_id = stripe_price_id.strip()
        try:
            import asyncio

            price_obj = await asyncio.to_thread(stripe.Price.retrieve, stripe_price_id)
            if price_obj.unit_amount:
                amount_dollars = price_obj.unit_amount / 100.0
                if amount_dollars.is_integer():
                    price_str = str(int(amount_dollars))
                else:
                    price_str = f"{amount_dollars:.2f}"
            else:
                price_str = "0"
            prices.append({"plan_id": plan_id, "price_string": price_str})
        except Exception as e:
            pass
    _price_cache = prices
    _price_cache_time = current_time
    return prices
