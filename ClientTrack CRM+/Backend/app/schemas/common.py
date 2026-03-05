from pydantic import BaseModel, ConfigDict


class Message(BaseModel):
    message: str


class PageMeta(BaseModel):
    page: int = 1
    size: int = 20
    total: int


class Paginated(BaseModel):
    model_config = ConfigDict(arbitrary_types_allowed=True)
    items: list
    meta: PageMeta
