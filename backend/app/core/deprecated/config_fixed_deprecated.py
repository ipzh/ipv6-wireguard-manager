"""
修复后的应用配置管理 - 解决重复定义和兼容性问题
"""
from typing import List, Optional, Union
import os
import secrets
from pathlib import Path

try:
    # Pydantic 2.x
    from pydantic_settings import BaseSettings
    from pydantic import field_validator, Field
except ImportError:
    # Pydantic 1.x fallback
    from pydantic import BaseSettings, validator as field_validator, Field

# 获取项目根目录
BASE_DIR = Path(__file__).resolve().parent.parent.parent


class DatabaseConfig:
    """数据库配置类"""
    
    def __init__(self, settings):
        self.settings = settings
    
    @property
    def url(self) -> str:
        """获取数据库URL"""
        return self.settings.DATABASE_URL
    
    @property
    def pool_size(self) -> int:
        """连接池大小"""
        return self.settings.DATABASE_POOL_SIZE
    
    @property
    def max_overflow(self) -> int:
        """最大溢出连接数"""
        return self.settings.DATABASE_MAX_OVERFLOW
    
    @property
    def connect_timeout(self) -> int:
        """连接超时时间"""
        return self.settings.DATABASE_CONNECT_TIMEOUT
    
    @property
    def statement_timeout(self) -> int:
        """语句超时时间"""
        return self.settings.DATABASE_STATEMENT_TIMEOUT
    
    @property
    def idle_in_transaction_timeout(self) -> int:
        """事务中空闲超时时间"""
        return self.settings.DATABASE_IDLE_IN_TRANSACTION_SESSION_TIMEOUT
    
    @property
    def pool_recycle(self) -> int:
        """连接池回收时间"""
        return self.settings.DATABASE_POOL_RECYCLE
    
    @property
    def pool_pre_ping(self) -> bool:
        """连接池预检查"""
        return self.settings.DATABASE_POOL_PRE_PING
    
    @property
    def auto_create_database(self) -> bool:
        """自动创建数据库"""
        return self.settings.AUTO_CREATE_DATABASE


class SecurityConfig:
    """安全配置类"""
    
    def __init__(self, settings):
        self.settings = settings
    
    @property
    def secret_key(self) -> str:
        """密钥"""
        return self.settings.SECRET_KEY
    
    @property
    def algorithm(self) -> str:
        """JWT算法"""
        return self.settings.ALGORITHM
    
    @property
    def access_token_expire_minutes(self) -> int:
        """访问令牌过期时间"""
        return self.settings.ACCESS_TOKEN_EXPIRE_MINUTES
    
    @property
    def refresh_token_expire_days(self) -> int:
        """刷新令牌过期时间"""
        return self.settings.REFRESH_TOKEN_EXPIRE_DAYS
    
    @property
    def password_min_length(self) -> int:
        """密码最小长度"""
        return self.settings.PASSWORD_MIN_LENGTH
    
    @property
    def max_login_attempts(self) -> int:
        """最大登录尝试次数"""
        return self.settings.MAX_LOGIN_ATTEMPTS
    
    @property
    def lockout_duration_minutes(self) -> int:
        """锁定持续时间"""
        return self.settings.LOCKOUT_DURATION_MINUTES


class Settings(BaseSettings):
    """应用配置"""
    
    # 应用基础配置
    APP_NAME: str = "IPv6 WireGuard Manager"
    APP_VERSION: str = "3.0.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "production"
    
    # API配置
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = Field(default_factory=lambda: secrets.token_urlsafe(32))
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30  # 30 days
    
    # 服务器配置
    SERVER_NAME: Optional[str] = None
    SERVER_HOST: str = "0.0.0.0"
    SERVER_PORT: int = 8000
    
    # 数据库配置 - 统一配置，支持多种数据库
    DATABASE_TYPE: str = "mysql"  # mysql, postgresql, sqlite
    DATABASE_URL: str = Field(default="mysql://ipv6wgm:password@localhost:3306/ipv6wgm")
    
    # 数据库连接池配置
    DATABASE_POOL_SIZE: int = 10
    DATABASE_MAX_OVERFLOW: int = 15
    DATABASE_CONNECT_TIMEOUT: int = 30
    DATABASE_STATEMENT_TIMEOUT: int = 30000
    DATABASE_IDLE_IN_TRANSACTION_SESSION_TIMEOUT: int = 10000
    DATABASE_POOL_RECYCLE: int = 3600
    DATABASE_POOL_PRE_PING: bool = True
    AUTO_CREATE_DATABASE: bool = True
    
    # SQLite特定配置
    SQLITE_DATABASE_URL: str = Field(default="sqlite:///./data/ipv6wgm.db")
    USE_SQLITE_FALLBACK: bool = False
    
    # Redis配置（可选）
    REDIS_URL: Optional[str] = None
    REDIS_POOL_SIZE: int = 10
    USE_REDIS: bool = False
    
    # 安全配置
    ALGORITHM: str = "HS256"
    PASSWORD_MIN_LENGTH: int = 8
    MAX_LOGIN_ATTEMPTS: int = 5
    LOCKOUT_DURATION_MINUTES: int = 30
    
    # CORS配置
    BACKEND_CORS_ORIGINS: List[str] = Field(default=[
        # IPv4本地访问
        "http://localhost:3000", 
        "http://localhost:8080", 
        "http://localhost:5173",
        "http://localhost",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080", 
        "http://127.0.0.1:5173",
        "http://127.0.0.1",
        # IPv6本地访问
        "http://[::1]:3000",
        "http://[::1]:8080",
        "http://[::1]:5173",
        "http://[::1]",
        # 内网IPv4支持
        "http://172.16.0.0/12",
        "http://192.168.0.0/16",
        "http://10.0.0.0/8",
        # 内网IPv6支持
        "http://[fd00::]/8",
        "http://[fe80::]/10",
        # HTTPS支持
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
    ])
    
    # 文件上传配置
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10MB
    UPLOAD_DIR: str = "uploads"
    ALLOWED_FILE_TYPES: List[str] = Field(default=[
        "image/jpeg", "image/png", "image/gif",
        "application/pdf", "text/plain",
        "application/json", "text/csv"
    ])
    
    # WireGuard配置
    WIREGUARD_CONFIG_DIR: str = "/etc/wireguard"
    WIREGUARD_CLIENTS_DIR: str = "/etc/wireguard/clients"
    WIREGUARD_INTERFACE: str = "wg0"
    
    # 监控配置
    ENABLE_METRICS: bool = True
    METRICS_PORT: int = 9090
    ENABLE_HEALTH_CHECK: bool = True
    HEALTH_CHECK_INTERVAL: int = 30
    
    # 日志配置
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "json"
    LOG_FILE: Optional[str] = None
    LOG_ROTATION: str = "1 day"
    LOG_RETENTION: str = "30 days"
    LOG_MAX_SIZE: int = 10 * 1024 * 1024  # 10MB
    
    # 性能配置
    MAX_WORKERS: int = 4
    WORKER_CLASS: str = "uvicorn.workers.UvicornWorker"
    KEEP_ALIVE: int = 2
    MAX_REQUESTS: int = 1000
    MAX_REQUESTS_JITTER: int = 100
    
    # 邮件配置
    SMTP_TLS: bool = True
    SMTP_PORT: Optional[int] = None
    SMTP_HOST: Optional[str] = None
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    EMAILS_FROM_EMAIL: Optional[str] = None
    EMAILS_FROM_NAME: Optional[str] = None
    
    # 超级用户配置 - 使用更安全的默认密码
    FIRST_SUPERUSER: str = "admin"
    FIRST_SUPERUSER_PASSWORD: str = Field(default_factory=lambda: secrets.token_urlsafe(16))
    FIRST_SUPERUSER_EMAIL: str = "admin@example.com"
    
    # API限流配置
    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_REQUESTS: int = 100
    RATE_LIMIT_WINDOW: int = 60  # seconds
    
    # 会话配置
    SESSION_SECRET_KEY: str = Field(default_factory=lambda: secrets.token_urlsafe(32))
    SESSION_LIFETIME: int = 3600  # 1 hour
    
    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)
    
    @field_validator("DATABASE_URL", mode="before")
    @classmethod
    def validate_database_url(cls, v: str) -> str:
        """验证数据库URL格式"""
        if not v:
            raise ValueError("数据库URL不能为空")
        
        # 检查URL格式
        if not any(v.startswith(prefix) for prefix in ["mysql://", "postgresql://", "sqlite:///"]):
            raise ValueError("不支持的数据库类型，支持: mysql, postgresql, sqlite")
        
        return v
    
    @field_validator("SECRET_KEY", mode="before")
    @classmethod
    def validate_secret_key(cls, v: str) -> str:
        """验证密钥强度"""
        if len(v) < 32:
            raise ValueError("密钥长度至少32位")
        return v
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        
        # 根据环境设置调试模式
        if self.ENVIRONMENT == "development":
            self.DEBUG = True
            self.LOG_LEVEL = "DEBUG"
        
        # 确保上传目录存在
        upload_path = Path(self.UPLOAD_DIR)
        upload_path.mkdir(parents=True, exist_ok=True)
        
        # 确保日志目录存在
        if self.LOG_FILE:
            log_path = Path(self.LOG_FILE)
            log_path.parent.mkdir(parents=True, exist_ok=True)
    
    @property
    def database(self) -> DatabaseConfig:
        """获取数据库配置"""
        return DatabaseConfig(self)
    
    @property
    def security(self) -> SecurityConfig:
        """获取安全配置"""
        return SecurityConfig(self)
    
    def get_database_url(self, use_sqlite_fallback: bool = False) -> str:
        """获取数据库URL，支持回退到SQLite"""
        if use_sqlite_fallback or self.USE_SQLITE_FALLBACK:
            return self.SQLITE_DATABASE_URL
        return self.DATABASE_URL
    
    def is_development(self) -> bool:
        """是否为开发环境"""
        return self.ENVIRONMENT == "development"
    
    def is_production(self) -> bool:
        """是否为生产环境"""
        return self.ENVIRONMENT == "production"
    
    def is_testing(self) -> bool:
        """是否为测试环境"""
        return self.ENVIRONMENT == "testing"
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        env_file_encoding = "utf-8"
        extra = "ignore"


# 创建全局配置实例
settings = Settings()

# 导出配置对象
__all__ = ["settings", "Settings", "DatabaseConfig", "SecurityConfig"]
