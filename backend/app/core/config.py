"""
应用配置管理 - 基于统一配置管理器
"""

from typing import List, Optional, Union
import secrets
from .config_manager import (
    config_manager, get_config, set_config, 
    is_development, is_production, is_testing,
    EnvironmentType
)

try:
    from pydantic_settings import BaseSettings
    from pydantic import field_validator, Field
except ImportError:
    from pydantic import BaseSettings, validator as field_validator, Field

class Settings(BaseSettings):
    """应用配置 - 基于统一配置管理器"""
    
    # 应用基础配置
    APP_NAME: str = Field(default="IPv6 WireGuard Manager")
    APP_VERSION: str = Field(default="3.0.0")
    DEBUG: bool = Field(default=False)
    ENVIRONMENT: str = Field(default=EnvironmentType.DEVELOPMENT.value)
    
    # API配置
    API_V1_STR: str = Field(default="/api/v1")
    SECRET_KEY: str = Field(default_factory=lambda: secrets.token_urlsafe(32))
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=60 * 24 * 8)
    
    # 服务器配置
    SERVER_NAME: Optional[str] = Field(default=None)
    SERVER_HOST: str = Field(default="${SERVER_HOST}")
    SERVER_PORT: int = Field(default=8000)
    
    # 数据库配置
    DATABASE_URL: str = Field(default="mysql://ipv6wgm:password@localhost:3306/ipv6wgm")
    DATABASE_HOST: str = Field(default="localhost")
    DATABASE_PORT: int = Field(default=3306)
    DATABASE_USER: str = Field(default="ipv6wgm")
    DATABASE_PASSWORD: str = Field(default="password")
    DATABASE_NAME: str = Field(default="ipv6wgm")
    DATABASE_POOL_SIZE: int = Field(default=10)
    DATABASE_MAX_OVERFLOW: int = Field(default=20)
    DATABASE_CONNECT_TIMEOUT: int = Field(default=30)
    DATABASE_STATEMENT_TIMEOUT: int = Field(default=30000)
    DATABASE_IDLE_IN_TRANSACTION_SESSION_TIMEOUT: int = Field(default=10000)
    DATABASE_POOL_RECYCLE: int = Field(default=3600)
    DATABASE_POOL_PRE_PING: bool = Field(default=True)
    AUTO_CREATE_DATABASE: bool = Field(default=True)
    
    # Redis配置
    REDIS_URL: Optional[str] = Field(default=None)
    REDIS_POOL_SIZE: int = Field(default=10)
    USE_REDIS: bool = Field(default=False)
    
    # 安全配置
    ALGORITHM: str = Field(default="HS256")
    BACKEND_CORS_ORIGINS: List[str] = Field(default=[
        "http://localhost:${FRONTEND_PORT}", 
        "http://localhost:${ADMIN_PORT}", 
        "http://localhost:5173",
        "http://localhost",
        "http://${LOCAL_HOST}:${FRONTEND_PORT}",
        "http://${LOCAL_HOST}:${ADMIN_PORT}", 
        "http://${LOCAL_HOST}:5173",
        "http://${LOCAL_HOST}",
        "http://[::1]:${FRONTEND_PORT}",
        "http://[::1]:${ADMIN_PORT}",
        "http://[::1]:5173",
        "http://[::1]",
        "http://172.16.0.0/12",
        "http://192.168.0.0/16",
        "http://1${SERVER_HOST}/8",
        "http://[fd00::]/8",
        "http://[fe80::]/10",
        "https://localhost:${FRONTEND_PORT}",
        "https://localhost:${ADMIN_PORT}",
        "https://localhost:5173",
        "https://localhost",
        "https://${LOCAL_HOST}:${FRONTEND_PORT}",
        "https://${LOCAL_HOST}:${ADMIN_PORT}",
        "https://${LOCAL_HOST}:5173", 
        "https://${LOCAL_HOST}",
        "https://[::1]:${FRONTEND_PORT}",
        "https://[::1]:${ADMIN_PORT}",
        "https://[::1]:5173",
        "https://[::1]",
        "*"
    ])
    
    # 文件上传配置
    MAX_FILE_SIZE: int = Field(default=10 * 1024 * 1024)
    UPLOAD_DIR: str = Field(default="uploads")
    ALLOWED_EXTENSIONS: List[str] = Field(default=[".conf", ".key", ".crt", ".pem", ".txt", ".log"])
    
    # WireGuard配置
    WIREGUARD_CONFIG_DIR: str = Field(default="/etc/wireguard")
    WIREGUARD_CLIENTS_DIR: str = Field(default="/etc/wireguard/clients")
    
    # 监控配置
    ENABLE_METRICS: bool = Field(default=True)
    METRICS_PORT: int = Field(default=9090)
    ENABLE_HEALTH_CHECK: bool = Field(default=True)
    HEALTH_CHECK_INTERVAL: int = Field(default=30)
    
    # 日志配置
    LOG_LEVEL: str = Field(default="INFO")
    LOG_FORMAT: str = Field(default="json")
    LOG_FILE: Optional[str] = Field(default=None)
    LOG_ROTATION: str = Field(default="1 day")
    LOG_RETENTION: str = Field(default="30 days")
    
    # 性能配置
    MAX_WORKERS: int = Field(default=4)
    WORKER_CLASS: str = Field(default="uvicorn.workers.UvicornWorker")
    KEEP_ALIVE: int = Field(default=2)
    MAX_REQUESTS: int = Field(default=1000)
    MAX_REQUESTS_JITTER: int = Field(default=100)
    
    # 邮件配置
    SMTP_TLS: bool = Field(default=True)
    SMTP_PORT: Optional[int] = Field(default=None)
    SMTP_HOST: Optional[str] = Field(default=None)
    SMTP_USER: Optional[str] = Field(default=None)
    SMTP_PASSWORD: Optional[str] = Field(default=None)
    EMAILS_FROM_EMAIL: Optional[str] = Field(default=None)
    EMAILS_FROM_NAME: Optional[str] = Field(default=None)
    
    # 超级用户配置
    FIRST_SUPERUSER: str = Field(default="admin")
    FIRST_SUPERUSER_PASSWORD: str = Field(default="admin123")
    FIRST_SUPERUSER_EMAIL: str = Field(default="admin@example.com")
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # 从统一配置管理器加载配置
        self._load_from_unified_manager()
    
    def _load_from_unified_manager(self):
        """从统一配置管理器加载配置"""
        # 应用基础配置
        self.APP_NAME = get_config("APP_NAME", self.APP_NAME)
        self.APP_VERSION = get_config("APP_VERSION", self.APP_VERSION)
        self.DEBUG = get_config("DEBUG", self.DEBUG)
        self.ENVIRONMENT = get_config("ENVIRONMENT", self.ENVIRONMENT)
        
        # API配置
        self.API_V1_STR = get_config("API_V1_STR", self.API_V1_STR)
        self.SECRET_KEY = get_config("SECRET_KEY", self.SECRET_KEY)
        self.ACCESS_TOKEN_EXPIRE_MINUTES = get_config("ACCESS_TOKEN_EXPIRE_MINUTES", self.ACCESS_TOKEN_EXPIRE_MINUTES)
        
        # 服务器配置
        self.SERVER_NAME = get_config("SERVER_NAME", self.SERVER_NAME)
        self.SERVER_HOST = get_config("SERVER_HOST", self.SERVER_HOST)
        self.SERVER_PORT = get_config("SERVER_PORT", self.SERVER_PORT)
        
        # 数据库配置
        self.DATABASE_URL = get_config("DATABASE_URL", self.DATABASE_URL)
        self.DATABASE_HOST = get_config("DATABASE_HOST", self.DATABASE_HOST)
        self.DATABASE_PORT = get_config("DATABASE_PORT", self.DATABASE_PORT)
        self.DATABASE_USER = get_config("DATABASE_USER", self.DATABASE_USER)
        self.DATABASE_PASSWORD = get_config("DATABASE_PASSWORD", self.DATABASE_PASSWORD)
        self.DATABASE_NAME = get_config("DATABASE_NAME", self.DATABASE_NAME)
        self.DATABASE_POOL_SIZE = get_config("DATABASE_POOL_SIZE", self.DATABASE_POOL_SIZE)
        self.DATABASE_MAX_OVERFLOW = get_config("DATABASE_MAX_OVERFLOW", self.DATABASE_MAX_OVERFLOW)
        self.DATABASE_CONNECT_TIMEOUT = get_config("DATABASE_CONNECT_TIMEOUT", self.DATABASE_CONNECT_TIMEOUT)
        self.DATABASE_STATEMENT_TIMEOUT = get_config("DATABASE_STATEMENT_TIMEOUT", self.DATABASE_STATEMENT_TIMEOUT)
        self.DATABASE_IDLE_IN_TRANSACTION_SESSION_TIMEOUT = get_config("DATABASE_IDLE_IN_TRANSACTION_SESSION_TIMEOUT", self.DATABASE_IDLE_IN_TRANSACTION_SESSION_TIMEOUT)
        self.DATABASE_POOL_RECYCLE = get_config("DATABASE_POOL_RECYCLE", self.DATABASE_POOL_RECYCLE)
        self.DATABASE_POOL_PRE_PING = get_config("DATABASE_POOL_PRE_PING", self.DATABASE_POOL_PRE_PING)
        self.AUTO_CREATE_DATABASE = get_config("AUTO_CREATE_DATABASE", self.AUTO_CREATE_DATABASE)
        
        # Redis配置
        self.REDIS_URL = get_config("REDIS_URL", self.REDIS_URL)
        self.REDIS_POOL_SIZE = get_config("REDIS_POOL_SIZE", self.REDIS_POOL_SIZE)
        self.USE_REDIS = get_config("USE_REDIS", self.USE_REDIS)
        
        # 安全配置
        self.ALGORITHM = get_config("ALGORITHM", self.ALGORITHM)
        self.BACKEND_CORS_ORIGINS = get_config("BACKEND_CORS_ORIGINS", self.BACKEND_CORS_ORIGINS)
        
        # 文件上传配置
        self.MAX_FILE_SIZE = get_config("MAX_FILE_SIZE", self.MAX_FILE_SIZE)
        self.UPLOAD_DIR = get_config("UPLOAD_DIR", self.UPLOAD_DIR)
        self.ALLOWED_EXTENSIONS = get_config("ALLOWED_EXTENSIONS", self.ALLOWED_EXTENSIONS)
        
        # WireGuard配置
        self.WIREGUARD_CONFIG_DIR = get_config("WIREGUARD_CONFIG_DIR", self.WIREGUARD_CONFIG_DIR)
        self.WIREGUARD_CLIENTS_DIR = get_config("WIREGUARD_CLIENTS_DIR", self.WIREGUARD_CLIENTS_DIR)
        
        # 监控配置
        self.ENABLE_METRICS = get_config("ENABLE_METRICS", self.ENABLE_METRICS)
        self.METRICS_PORT = get_config("METRICS_PORT", self.METRICS_PORT)
        self.ENABLE_HEALTH_CHECK = get_config("ENABLE_HEALTH_CHECK", self.ENABLE_HEALTH_CHECK)
        self.HEALTH_CHECK_INTERVAL = get_config("HEALTH_CHECK_INTERVAL", self.HEALTH_CHECK_INTERVAL)
        
        # 日志配置
        self.LOG_LEVEL = get_config("LOG_LEVEL", self.LOG_LEVEL)
        self.LOG_FORMAT = get_config("LOG_FORMAT", self.LOG_FORMAT)
        self.LOG_FILE = get_config("LOG_FILE", self.LOG_FILE)
        self.LOG_ROTATION = get_config("LOG_ROTATION", self.LOG_ROTATION)
        self.LOG_RETENTION = get_config("LOG_RETENTION", self.LOG_RETENTION)
        
        # 性能配置
        self.MAX_WORKERS = get_config("MAX_WORKERS", self.MAX_WORKERS)
        self.WORKER_CLASS = get_config("WORKER_CLASS", self.WORKER_CLASS)
        self.KEEP_ALIVE = get_config("KEEP_ALIVE", self.KEEP_ALIVE)
        self.MAX_REQUESTS = get_config("MAX_REQUESTS", self.MAX_REQUESTS)
        self.MAX_REQUESTS_JITTER = get_config("MAX_REQUESTS_JITTER", self.MAX_REQUESTS_JITTER)
        
        # 邮件配置
        self.SMTP_TLS = get_config("SMTP_TLS", self.SMTP_TLS)
        self.SMTP_PORT = get_config("SMTP_PORT", self.SMTP_PORT)
        self.SMTP_HOST = get_config("SMTP_HOST", self.SMTP_HOST)
        self.SMTP_USER = get_config("SMTP_USER", self.SMTP_USER)
        self.SMTP_PASSWORD = get_config("SMTP_PASSWORD", self.SMTP_PASSWORD)
        self.EMAILS_FROM_EMAIL = get_config("EMAILS_FROM_EMAIL", self.EMAILS_FROM_EMAIL)
        self.EMAILS_FROM_NAME = get_config("EMAILS_FROM_NAME", self.EMAILS_FROM_NAME)
        
        # 超级用户配置
        self.FIRST_SUPERUSER = get_config("FIRST_SUPERUSER", self.FIRST_SUPERUSER)
        self.FIRST_SUPERUSER_PASSWORD = get_config("FIRST_SUPERUSER_PASSWORD", self.FIRST_SUPERUSER_PASSWORD)
        self.FIRST_SUPERUSER_EMAIL = get_config("FIRST_SUPERUSER_EMAIL", self.FIRST_SUPERUSER_EMAIL)
    
    @field_validator("BACKEND_CORS_ORIGINS", mode="before", check_fields=False)
    @classmethod
    def assemble_cors_origins(cls, v):
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)
    
    def is_development(self) -> bool:
        """判断是否为开发环境"""
        return is_development()
    
    def is_production(self) -> bool:
        """判断是否为生产环境"""
        return is_production()
    
    def is_testing(self) -> bool:
        """判断是否为测试环境"""
        return is_testing()
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        env_file_encoding = "utf-8"
        extra = "ignore"

# 创建全局配置实例
settings = Settings()

# 导出配置实例和便捷函数
__all__ = [
    "settings", "Settings", 
    "get_config", "set_config", 
    "is_development", "is_production", "is_testing"
]