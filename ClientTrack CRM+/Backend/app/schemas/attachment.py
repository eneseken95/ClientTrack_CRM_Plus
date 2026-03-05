from pydantic import BaseModel


class DeleteAttachmentRequest(BaseModel):
    path: str
