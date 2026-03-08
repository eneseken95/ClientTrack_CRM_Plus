import stripe
from fastapi import APIRouter, Request, HTTPException
from app.core.db import SessionLocal
from app.core.config import settings
from app.services import stripe_service

router = APIRouter(prefix="/webhooks", tags=["webhooks"])
stripe.api_key = settings.STRIPE_SECRET_KEY


@router.post("/stripe")
async def stripe_webhook(request: Request):
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, settings.STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid signature")
    async with SessionLocal() as db:
        if event["type"] == "invoice.paid":
            await stripe_service.handle_invoice_paid(db, event["data"]["object"])
        elif event["type"] == "invoice.payment_failed":
            await stripe_service.handle_payment_failed(db, event["data"]["object"])
        elif event["type"] == "customer.subscription.deleted":
            await stripe_service.handle_subscription_deleted(
                db, event["data"]["object"]
            )
    return {"status": "ok"}
