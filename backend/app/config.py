import os
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional

class Settings(BaseSettings):
    PROJECT_NAME: str = "Expenso AI Backend"
    API_V1_STR: str = "/api/v1"
    
    # JWT Settings
    JWT_SECRET: str = "expenso-super-secret-key-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 day for easier development
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    
    # Google OAuth
    GOOGLE_CLIENT_ID: Optional[str] = None
    
    # AI / Gemini API
    GEMINI_API_KEY: Optional[str] = os.getenv("GEMINI_API_KEY")
    
    # Dev & Testing Settings
    DEV_MODE: bool = True
    DATABASE_URL: str = "sqlite:///./data/backend.db"

    model_config = SettingsConfigDict(case_sensitive=True, env_file=".env")

settings = Settings()
