"""Sentinel Backend Configuration"""
from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Optional


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""
    
    # API Settings
    app_name: str = "Sentinel API"
    debug: bool = True
    api_v1_prefix: str = "/api/v1"
    
    # Server Settings
    host: str = "0.0.0.0"
    port: int = 8000
    
    # Finnhub API Settings
    finnhub_api_key: Optional[str] = None
    
    # Redis Settings
    redis_url: str = "redis://localhost:6379"
    
    # WebSocket Settings
    ws_heartbeat_interval: int = 30
    
    # Market Data Settings
    price_update_interval: float = 1.0  # seconds
    
    class Config:
        env_file = ".env"
        extra = "ignore"  # Ignore extra env vars


@lru_cache
def get_settings() -> Settings:
    return Settings()
