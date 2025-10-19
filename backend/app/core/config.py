"""
应用配置管理 - 基于统一配置管理器
"""

from typing import List, Optional
import secrets
from .config_manager import (
    config_manager, get_config, set_config, 
    is_development, is_production, is_testing,
    EnvironmentType
)

try:
    from pydantic_settings import BaseSettings
    from pydantic import field_validator
except ImportError:
    from pydantic import BaseSettings, validator as field_validator

class Settings(BaseSettings):
    """应用配置 - 基于统一配置管理器"""
    
    # 使用统一配置管理器获取配置
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # 从统一配置管理器加载配置
        self._load_from_unified_manager()
    
    def _load_from_unified_manager(self):
        """从统一配置管理器加载配置"""
        # 应用基础配置
        self.APP_NAME = get_config("APP_NAME", "IPv6 WireGuard Manager")
        self.APP_VERSION = get_config("APP_VERSION", "3.0.0")
        self.DEBUG = get_config("DEBUG", False)
        self.ENVIRONMENT = get_config("ENVIRONMENT", EnvironmentType.DEVELOPMENT.value)
        
        # API配置
        self.API_V1_STR = get_config("API_V1_STR", "/api/v1")
        self.SECRET_KEY = get_config("SECRET_KEY", secrets.token_urlsafe(32))
        self.ACCESS_TOKEN_EXPIRE_MINUTES = get_config("ACCESS_TOKEN_EXPIRE_MINUTES", 60 * 24 * 8)
        
        # 服务器配置
        self.SERVER_NAME = get_config("SERVER_NAME", None)
        self.SERVER_HOST = get_config("SERVER_HOST", "0.0.0.0")
        self.SERVER_PORT = get_config("SERVER_PORT", 8000)
        
        # 数据库配置
        self.DATABASE_URL = get_config("DATABASE_URL", "mysql://ipv6wgm:password@localhost:3306/ipv6wgm")
        self.DATABASE_HOST = get_config("DATABASE_HOST", "localhost")
        self.DATABASE_PORT = get_config("DATABASE_PORT", 3306)
        self.DATABASE_USER = get_config("DATABASE_USER", "ipv6wgm")
        self.DATABASE_PASSWORD = get_config("DATABASE_PASSWORD", "password")
        self.DATABASE_NAME = get_config("DATABASE_NAME", "ipv6wgm")
        self.DATABASE_POOL_SIZE = get_config("DATABASE_POOL_SIZE", 10)
        self.DATABASE_MAX_OVERFLOW = get_config("DATABASE_MAX_OVERFLOW", 20)
        self.DATABASE_CONNECT_TIMEOUT = get_config("DATABASE_CONNECT_TIMEOUT", 30)
        self.DATABASE_STATEMENT_TIMEOUT = get_config("DATABASE_STATEMENT_TIMEOUT", 30000)
        self.DATABASE_IDLE_IN_TRANSACTION_SESSION_TIMEOUT = get_config("DATABASE_IDLE_IN_TRANSACTION_SESSION_TIMEOUT", 10000)
        self.DATABASE_POOL_RECYCLE = get_config("DATABASE_POOL_RECYCLE", 3600)
        self.DATABASE_POOL_PRE_PING = get_config("DATABASE_POOL_PRE_PING", True)
        self.AUTO_CREATE_DATABASE = get_config("AUTO_CREATE_DATABASE", True)
        
        # Redis配置
        self.REDIS_URL = get_config("REDIS_URL", None)
        self.REDIS_POOL_SIZE = get_config("REDIS_POOL_SIZE", 10)
        self.USE_REDIS = get_config("USE_REDIS", False)
        
        # 安全配置
        self.ALGORITHM = get_config("ALGORITHM", "HS256")
        self.BACKEND_CORS_ORIGINS = get_config("BACKEND_CORS_ORIGINS", [
            "http://localhost:3000", 
            "http://localhost:8080", 
            "http://localhost:5173",
            "http://localhost",
            "http://127.0.0.1:3000",
            "http://127.0.0.1:8080", 
            "http://127.0.0.1:5173",
            "http://127.0.0.1",
            "http://[::1]:3000",
            "http://[::1]:8080",
            "http://[::1]:5173",
            "http://[::1]",
            "http://172.16.0.0/12",
            "http://192.168.0.0/16",
            "http://10.0.0.0/8",
            "http://[fd00::]/8",
            "http://[fe80::]/10",
            "https://localhost:3000",
            "https://localhost:8080",
            "https://localhost:5173",
            "https://localhost",
            "https://127.0.0.1:3000",
            "https://127.0.0.1:8080",
            "https://127.0.0.1:5173", 
            "https://127.0.0.1",
            "https://[::1]:3000",
            "https://[::1]:8080",
            "https://[::1]:5173",
            "https://[::1]",
            "*"
        ])
        
        # 文件上传配置
        self.MAX_FILE_SIZE = get_config("MAX_FILE_SIZE", 10 * 1024 * 1024)
        self.UPLOAD_DIR = get_config("UPLOAD_DIR", "uploads")
        self.ALLOWED_EXTENSIONS = get_config("ALLOWED_EXTENSIONS", [".conf", ".key", ".crt", ".pem", ".txt", ".log"])
        
        # WireGuard配置
        self.WIREGUARD_CONFIG_DIR = get_config("WIREGUARD_CONFIG_DIR", "/etc/wireguard")
        self.WIREGUARD_CLIENTS_DIR = get_config("WIREGUARD_CLIENTS_DIR", "/etc/wireguard/clients")
        
        # 监控配置
        self.ENABLE_METRICS = get_config("ENABLE_METRICS", True)
        self.METRICS_PORT = get_config("METRICS_PORT", 9090)
        self.ENABLE_HEALTH_CHECK = get_config("ENABLE_HEALTH_CHECK", True)
        self.HEALTH_CHECK_INTERVAL = get_config("HEALTH_CHECK_INTERVAL", 30)
        
        # 日志配置
        self.LOG_LEVEL = get_config("LOG_LEVEL", "INFO")
        self.LOG_FORMAT = get_config("LOG_FORMAT", "json")
        self.LOG_FILE = get_config("LOG_FILE", None)
        self.LOG_ROTATION = get_config("LOG_ROTATION", "1 day")
        self.LOG_RETENTION = get_config("LOG_RETENTION", "30 days")
        
        # 性能配置
        self.MAX_WORKERS = get_config("MAX_WORKERS", 4)
        self.WORKER_CLASS = get_config("WORKER_CLASS", "uvicorn.workers.UvicornWorker")
        self.KEEP_ALIVE = get_config("KEEP_ALIVE", 2)
        self.MAX_REQUESTS = get_config("MAX_REQUESTS", 1000)
        self.MAX_REQUESTS_JITTER = get_config("MAX_REQUESTS_JITTER", 100)
        
        # 邮件配置
        self.SMTP_TLS = get_config("SMTP_TLS", True)
        self.SMTP_PORT = get_config("SMTP_PORT", None)
        self.SMTP_HOST = get_config("SMTP_HOST", None)
        self.SMTP_USER = get_config("SMTP_USER", None)
        self.SMTP_PASSWORD = get_config("SMTP_PASSWORD", None)
        self.EMAILS_FROM_EMAIL = get_config("EMAILS_FROM_EMAIL", None)
        self.EMAILS_FROM_NAME = get_config("EMAILS_FROM_NAME", None)
        
        # 超级用户配置
        self.FIRST_SUPERUSER = get_config("FIRST_SUPERUSER", "admin")
        self.FIRST_SUPERUSER_PASSWORD = get_config("FIRST_SUPERUSER_PASSWORD", "admin123")
        self.FIRST_SUPERUSER_EMAIL = get_config("FIRST_SUPERUSER_EMAIL", "admin@example.com")
    
    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
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