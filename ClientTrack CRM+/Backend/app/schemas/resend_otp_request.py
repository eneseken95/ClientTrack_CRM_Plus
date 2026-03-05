from pydantic import BaseModel, EmailStr


class ResendOTPRequest(BaseModel):
    email: EmailStr
