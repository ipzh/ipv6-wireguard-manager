"""
应用配置管理
"""
from typing import List, Optional
try:
    # Pydantic 2.x
    from pydantic_settings import BaseSettings
    from pydantic import field_validator
except ImportError:
    # Pydantic 1.x fallback
    from pydantic import BaseSettings, validator as field_validator
import secrets


class Settings(BaseSettings):
    """应用配置"""
    
    # 应用基础配置
    APP_NAME: str = "IPv6 WireGuard Manager"
    APP_VERSION: str = "3.0.0"
    DEBUG: bool = False
    
    # API配置
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = secrets.token_urlsafe(32)
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days
    
    # 服务器配置
    SERVER_NAME: Optional[str] = None
    SERVER_HOST: str = "0.0.0.0"
    SERVER_PORT: int = 8000
    
    # 数据库配置
    DATABASE_URL: str = "sqlite:///./ipv6_wireguard.db"
    DATABASE_POOL_SIZE: int = 20
    DATABASE_MAX_OVERFLOW: int = 30
    DATABASE_CONNECT_TIMEOUT: int = 30
    DATABASE_STATEMENT_TIMEOUT: int = 30000
    DATABASE_IDLE_IN_TRANSACTION_SESSION_TIMEOUT: int = 10000
    
    # Redis配置
    REDIS_URL: str = "redis://localhost:6379/0"
    REDIS_POOL_SIZE: int = 10
    
    # 安全配置
    ALGORITHM: str = "HS256"
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost:3000", 
        "http://localhost:8080", 
        "http://localhost:5173",
        "http://localhost",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080", 
        "http://127.0.0.1:5173",
        "http://127.0.0.1"
    ]
    
    # 文件上传配置
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10MB
    UPLOAD_DIR: str = "uploads"
    
    # WireGuard配置
    WIREGUARD_CONFIG_DIR: str = "/etc/wireguard"
    WIREGUARD_CLIENTS_DIR: str = "/etc/wireguard/clients"
    
    # 监控配置
    ENABLE_METRICS: bool = True
    METRICS_PORT: int = 9090
    
    # 日志配置
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "json"
    
    # 邮件配置
    SMTP_TLS: bool = True
    SMTP_PORT: Optional[int] = None
    SMTP_HOST: Optional[str] = None
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    EMAILS_FROM_EMAIL: Optional[str] = None
    EMAILS_FROM_NAME: Optional[str] = None
    
    # 超级用户配置
    FIRST_SUPERUSER: str = "admin"
    FIRST_SUPERUSER_PASSWORD: str = "admin123"
    FIRST_SUPERUSER_EMAIL: str = "admin@example.com"
    
    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: str | List[str]) -> List[str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        # Pydantic 2.x compatibility
        env_file_encoding = "utf-8"
        # Allow extra fields to prevent validation errors
        extra = "ignore"


# 创建全局配置实例
settings = Settings()
