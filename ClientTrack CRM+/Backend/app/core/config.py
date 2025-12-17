from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import computed_field


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", case_sensitive=False)

    DB_HOST: str
    DB_PORT: int
    DB_NAME: str
    DB_USER: str
    DB_PASS: str
    POSTGRES_EXPORTER_DSN: str

    SECRET_KEY: str
    ALGORITHM: str
    SENDGRID_API_KEY: str
    SENDGRID_SENDER: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int
    REFRESH_TOKEN_EXPIRE_MINUTES: int
    REFRESH_TOKEN_SECRET_KEY: str
    SUPABASE_URL: str
    SUPABASE_SERVICE_KEY: str
    SUPABASE_AVATAR_BUCKET: str
    SUPABASE_ATTACHMENT_BUCKET: str
    APP_LOGO_URL: str
    OPENROUTER_API_KEY: str
    OPENROUTER_MODEL: str
    REDIS_HOST: str
    REDIS_PORT: int
    GRAFANA_USER: str
    GRAFANA_PASSWORD: str
    ELASTICSEARCH_URL: str
    CORS_ORIGINS: str = ""

    @computed_field
    @property
    def DATABASE_URL(self) -> str:
        return f"postgresql+asyncpg://{self.DB_USER}:{self.DB_PASS}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"


settings = Settings()
