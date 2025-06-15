# backend/app/config.py
from pydantic_settings import BaseSettings
from typing import List
import os


class Settings(BaseSettings):
    """アプリケーション設定"""
    
    # 基本設定
    APP_NAME: str = "Research Lab Finder"
    APP_VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    
    # データベース設定
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/research_lab_finder"
    
    # OpenAI設定
    OPENAI_API_KEY: str
    OPENAI_MODEL: str = "text-embedding-3-small"
    EMBEDDING_DIMENSION: int = 1536
    
    # CORS設定
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",  # React開発サーバー
        "http://127.0.0.1:3000",
        "http://frontend:3000",   # Docker内部通信
    ]
    
    # 検索設定
    DEFAULT_SEARCH_LIMIT: int = 20
    MAX_SEARCH_LIMIT: int = 100
    MIN_SIMILARITY_THRESHOLD: float = 0.5
    
    # API設定
    API_V1_STR: str = "/api"
    
    # ログ設定
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# 設定インスタンス
settings = Settings()

# 環境別設定の調整
if settings.ENVIRONMENT == "production":
    settings.DEBUG = False
    settings.LOG_LEVEL = "WARNING"
elif settings.ENVIRONMENT == "testing":
    settings.DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/research_lab_finder_test"