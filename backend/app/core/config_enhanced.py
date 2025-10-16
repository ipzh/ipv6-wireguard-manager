"""
增强的配置管理系统
统一配置管理，减少硬编码，增加配置验证
"""
import os
import secrets
from typing import List, Optional, Union
from pathlib import Path

try:
    # Pydantic 2.x
    from pydantic_settings import BaseSettings
    from pydantic import field_validator, Field
except ImportError:
    # Pydantic 1.x fallback
    from pydantic import BaseSettings, validator as field_validator, Field

class SecurityConfig:
    """安全配置类"""
    
    # 密码策略配置
    PASSWORD_MIN_LENGTH = 8
    PASSWORD_REQUIRE_UPPERCASE = True
    PASSWORD_REQUIRE_LOWERCASE = True
    PASSWORD_REQUIRE_DIGITS = True
    PASSWORD_REQUIRE_SPECIAL = True
    PASSWORD_MAX_AGE_DAYS = 90
    
    # API安全配置
    API_RATE_LIMIT_PER_MINUTE = 100
    API_RATE_LIMIT_BURST = 200
    API_KEY_LENGTH = 32
    
    # 会话配置
    SESSION_TIMEOUT_MINUTES = 30
    MAX_LOGIN_ATTEMPTS = 5
    LOCKOUT_DURATION_MINUTES = 15
    
    # 加密配置
    ENCRYPTION_ALGORITHM = "AES-256-GCM"
    HASH_ALGORITHM = "bcrypt"
    HASH_ROUNDS = 12

class PerformanceConfig:
    """性能配置类"""
    
    # 数据库连接池配置
    DB_POOL_SIZE = 10
    DB_MAX_OVERFLOW = 20
    DB_POOL_TIMEOUT = 30
    DB_POOL_RECYCLE = 3600
    DB_POOL_PRE_PING = True
    
    # 缓存配置
    CACHE_DEFAULT_TTL = 300  # 5分钟
    CACHE_MAX_SIZE = 1000
    CACHE_CLEANUP_INTERVAL = 600  # 10分钟
    
    # 异步处理配置
    ASYNC_WORKERS = 4
    ASYNC_QUEUE_SIZE = 1000
    ASYNC_TIMEOUT = 30
    
    # 文件处理配置
    MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
    CHUNK_SIZE = 8192
    UPLOAD_TIMEOUT = 300

class MonitoringConfig:
    """监控配置类"""
    
    # 监控指标配置
    METRICS_ENABLED = True
    METRICS_PORT = 9090
    METRICS_PATH = "/metrics"
    
    # 告警配置
    ALERT_ENABLED = True
    ALERT_EMAIL_ENABLED = False
    ALERT_WEBHOOK_ENABLED = False
    
    # 日志配置
    LOG_LEVEL = "INFO"
    LOG_FORMAT = "json"
    LOG_FILE_MAX_SIZE = 100 * 1024 * 1024  # 100MB
    LOG_FILE_BACKUP_COUNT = 5
    LOG_RETENTION_DAYS = 30

class Settings(BaseSettings):
    """增强的应用配置"""
    
    # 应用基础配置
    APP_NAME: str = "IPv6 WireGuard Manager"
    APP_VERSION: str = "3.0.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "production"
    
    # API配置
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = Field(default_factory=lambda: secrets.token_urlsafe(32))
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days
    
    # 服务器配置
    SERVER_NAME: Optional[str] = None
    SERVER_HOST: str = "0.0.0.0"
    SERVER_PORT: int = 8000
    
    # 数据库配置
    DATABASE_URL: str = "mysql://ipv6wgm:password@localhost:3306/ipv6wgm"
    DATABASE_POOL_SIZE: int = Field(default=10, ge=1, le=100)
    DATABASE_MAX_OVERFLOW: int = Field(default=20, ge=0, le=200)
    DATABASE_CONNECT_TIMEOUT: int = Field(default=30, ge=5, le=300)
    DATABASE_STATEMENT_TIMEOUT: int = Field(default=30000, ge=1000, le=300000)
    DATABASE_POOL_RECYCLE: int = Field(default=3600, ge=300, le=86400)
    DATABASE_POOL_PRE_PING: bool = True
    AUTO_CREATE_DATABASE: bool = True
    
    # Redis配置
    REDIS_URL: Optional[str] = None
    REDIS_POOL_SIZE: int = Field(default=10, ge=1, le=100)
    USE_REDIS: bool = False
    
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
    ]
    
    # 文件上传配置
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10MB
    UPLOAD_DIR: str = "/opt/ipv6-wireguard-manager/uploads"
    ALLOWED_EXTENSIONS: List[str] = [".conf", ".key", ".crt", ".pem", ".txt", ".log"]
    
    # WireGuard配置
    WIREGUARD_CONFIG_DIR: str = "/etc/wireguard"
    WIREGUARD_CLIENTS_DIR: str = "/etc/wireguard/clients"
    
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
    
    # 超级用户配置
    FIRST_SUPERUSER: str = "admin"
    FIRST_SUPERUSER_PASSWORD: str = "admin123"
    FIRST_SUPERUSER_EMAIL: str = "admin@example.com"
    
    # 配置验证
    @field_validator("SECRET_KEY")
    @classmethod
    def validate_secret_key(cls, v: str) -> str:
        """验证密钥强度"""
        if len(v) < 32:
            raise ValueError("Secret key must be at least 32 characters")
        return v
    
    @field_validator("DATABASE_URL")
    @classmethod
    def validate_database_url(cls, v: str) -> str:
        """验证数据库URL格式"""
        if not v.startswith(("mysql://", "mysql+aiomysql://")):
            raise ValueError("Only MySQL database is supported")
        return v
    
    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        """组装CORS源"""
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)
    
    @field_validator("LOG_LEVEL")
    @classmethod
    def validate_log_level(cls, v: str) -> str:
        """验证日志级别"""
        valid_levels = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
        if v.upper() not in valid_levels:
            raise ValueError(f"Log level must be one of {valid_levels}")
        return v.upper()
    
    @field_validator("ENVIRONMENT")
    @classmethod
    def validate_environment(cls, v: str) -> str:
        """验证环境类型"""
        valid_envs = ["development", "testing", "staging", "production"]
        if v.lower() not in valid_envs:
            raise ValueError(f"Environment must be one of {valid_envs}")
        return v.lower()
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # 应用环境管理器配置
        self._apply_environment_config()
        # 验证配置完整性
        self._validate_config()
    
    def _apply_environment_config(self):
        """应用环境管理器配置"""
        try:
            from .environment import EnvironmentManager
            env_manager = EnvironmentManager()
            env_config = env_manager.get_all_config()
            for key, value in env_config.items():
                if hasattr(self, key) and not hasattr(self.__class__, key):
                    setattr(self, key, value)
        except ImportError:
            pass
    
    def _validate_config(self):
        """验证配置完整性"""
        # 验证必要的目录存在
        self._ensure_directories()
        
        # 验证文件权限
        self._check_file_permissions()
        
        # 验证网络配置
        self._validate_network_config()
    
    def _ensure_directories(self):
        """确保必要的目录存在"""
        directories = [
            self.UPLOAD_DIR,
            self.WIREGUARD_CONFIG_DIR,
            self.WIREGUARD_CLIENTS_DIR,
        ]
        
        for directory in directories:
            if directory:
                Path(directory).mkdir(parents=True, exist_ok=True)
    
    def _check_file_permissions(self):
        """检查文件权限"""
        # 检查WireGuard配置目录权限
        wg_config_path = Path(self.WIREGUARD_CONFIG_DIR)
        if wg_config_path.exists():
            if not os.access(wg_config_path, os.R_OK | os.W_OK):
                raise PermissionError(f"Cannot access WireGuard config directory: {self.WIREGUARD_CONFIG_DIR}")
    
    def _validate_network_config(self):
        """验证网络配置"""
        # 验证端口范围
        if not (1 <= self.SERVER_PORT <= 65535):
            raise ValueError(f"Server port must be between 1 and 65535, got {self.SERVER_PORT}")
        
        if not (1 <= self.METRICS_PORT <= 65535):
            raise ValueError(f"Metrics port must be between 1 and 65535, got {self.METRICS_PORT}")
    
    def get_security_config(self) -> SecurityConfig:
        """获取安全配置"""
        return SecurityConfig()
    
    def get_performance_config(self) -> PerformanceConfig:
        """获取性能配置"""
        return PerformanceConfig()
    
    def get_monitoring_config(self) -> MonitoringConfig:
        """获取监控配置"""
        return MonitoringConfig()
    
    def is_development(self) -> bool:
        """判断是否为开发环境"""
        return self.ENVIRONMENT == "development"
    
    def is_production(self) -> bool:
        """判断是否为生产环境"""
        return self.ENVIRONMENT == "production"
    
    def is_testing(self) -> bool:
        """判断是否为测试环境"""
        return self.ENVIRONMENT == "testing"
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        env_file_encoding = "utf-8"
        extra = "ignore"

# 创建全局配置实例
settings = Settings()

# 导出配置类
__all__ = ["Settings", "SecurityConfig", "PerformanceConfig", "MonitoringConfig", "settings"]
