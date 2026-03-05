from typing import Optional
from pydantic import BaseModel, Field


class CreatePaymentIntentRequest(BaseModel):
    plan_id: str = Field(
        ...,
        description="The ID of the plan to subscribe to, e.g., 'pro_monthly', 'team_yearly'",
    )


class CreatePaymentIntentResponse(BaseModel):
    payment_intent: str
    ephemeral_key: str
    customer: str
    publishable_key: str


class SubscriptionStatusResponse(BaseModel):
    subscription_status: str
    subscription_plan_id: Optional[str] = None
    current_period_end: Optional[str] = None


class SubscriptionPriceItem(BaseModel):
    plan_id: str
    price_string: str


class SubscriptionPricesResponse(BaseModel):
    prices: list[SubscriptionPriceItem]
