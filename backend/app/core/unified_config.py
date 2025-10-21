"""
简化的配置管理模块
统一所有配置管理，减少复杂性
"""
import os
import secrets
from typing import List, Optional, Union, Dict, Any
from pathlib import Path
from .path_config import PathConfig

try:
    # Pydantic 2.x
    from pydantic_settings import BaseSettings
    from pydantic import field_validator, Field
except ImportError:
    try:
        # Pydantic 1.x fallback
        from pydantic import BaseSettings, validator as field_validator, Field
    except ImportError:
        # 最后的fallback
        from pydantic import BaseSettings, Field
        def field_validator(*args, **kwargs):
            def decorator(func):
                return func
            return decorator

class UnifiedSettings(BaseSettings):
    """统一的配置管理类"""
    
    # 应用基础配置
    APP_NAME: str = "IPv6 WireGuard Manager"
    APP_VERSION: str = "3.1.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "production"
    
    # 路径配置 - 使用环境变量，支持Docker和本地部署
    INSTALL_DIR: str = Field(default="/opt/ipv6-wireguard-manager")
    WIREGUARD_CONFIG_DIR: str = Field(default="/etc/wireguard")
    WIREGUARD_CLIENTS_DIR: str = Field(default="/etc/wireguard/clients")
    FRONTEND_DIR: str = Field(default="/var/www/html")
    NGINX_CONFIG_DIR: str = Field(default="/etc/nginx/sites-available")
    NGINX_LOG_DIR: str = Field(default="/var/log/nginx")
    SYSTEMD_CONFIG_DIR: str = Field(default="/etc/systemd/system")
    BIN_DIR: str = Field(default="/usr/local/bin")
    
    # API配置
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = Field(default_factory=lambda: secrets.token_urlsafe(32))
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=60 * 24 * 8, ge=1, le=525600)  # 8 days, max 1 year
    
    # 服务器配置
    SERVER_NAME: Optional[str] = None
    SERVER_HOST: str = "${SERVER_HOST}"
    SERVER_PORT: int = Field(default=8000, ge=1, le=65535)
    
    # 数据库配置
    DATABASE_URL: str = Field(default="mysql://ipv6wgm:password@mysql:3306/ipv6wgm")
    DATABASE_HOST: str = Field(default="localhost")
    DATABASE_PORT: int = Field(default=3306, ge=1, le=65535)
    DATABASE_USER: str = Field(default="ipv6wgm")
    DATABASE_PASSWORD: str = Field(default="password")
    DATABASE_NAME: str = Field(default="ipv6wgm")
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
        "https://[::1]"
    ]
    
    # 文件上传配置
    MAX_FILE_SIZE: int = Field(default=10 * 1024 * 1024, ge=1024, le=100 * 1024 * 1024)  # 10MB, max 100MB
    UPLOAD_DIR: str = "uploads"
    ALLOWED_EXTENSIONS: List[str] = [".conf", ".key", ".crt", ".pem", ".txt", ".log"]
    
    # WireGuard配置
    WIREGUARD_PRIVATE_KEY: Optional[str] = None
    WIREGUARD_PUBLIC_KEY: Optional[str] = None
    WIREGUARD_PORT: int = Field(default=51820, ge=1024, le=65535)
    WIREGUARD_INTERFACE: str = "wg0"
    WIREGUARD_NETWORK: str = "10.0.0.0/24"
    WIREGUARD_IPV6_NETWORK: str = "fd00::/64"
    
    # 监控配置
    ENABLE_METRICS: bool = True
    METRICS_PORT: int = Field(default=9090, ge=1024, le=65535)
    ENABLE_HEALTH_CHECK: bool = True
    HEALTH_CHECK_INTERVAL: int = Field(default=30, ge=5, le=300)
    
    # 日志配置
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "json"
    LOG_FILE: Optional[str] = None
    LOG_ROTATION: str = "1 day"
    LOG_RETENTION: str = "30 days"
    
    # 性能配置
    MAX_WORKERS: int = Field(default=4, ge=1, le=32)
    WORKER_CLASS: str = "uvicorn.workers.UvicornWorker"
    KEEP_ALIVE: int = Field(default=2, ge=1, le=60)
    MAX_REQUESTS: int = Field(default=1000, ge=100, le=10000)
    MAX_REQUESTS_JITTER: int = Field(default=100, ge=0, le=1000)
    
    # 邮件配置
    SMTP_TLS: bool = True
    SMTP_PORT: Optional[int] = Field(default=None, ge=1, le=65535)
    SMTP_HOST: Optional[str] = None
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    EMAILS_FROM_EMAIL: Optional[str] = None
    EMAILS_FROM_NAME: Optional[str] = None
    
    # 超级用户配置
    FIRST_SUPERUSER: str = "admin"
    FIRST_SUPERUSER_PASSWORD: Optional[str] = None  # 必须通过环境变量设置
    FIRST_SUPERUSER_EMAIL: str = "admin@example.com"
    
    # 配置验证
    @field_validator("SECRET_KEY")
    @classmethod
    def validate_secret_key(cls, v: str) -> str:
        """验证密钥强度"""
        if len(v) < 32:
            raise ValueError("Secret key must be at least 32 characters")
        return v
    
    @field_validator("FIRST_SUPERUSER_PASSWORD")
    @classmethod
    def validate_superuser_password(cls, v: Optional[str]) -> str:
        """验证超级用户密码"""
        if v is None:
            # 生成随机密码
            import secrets
            import string
            alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
            v = ''.join(secrets.choice(alphabet) for _ in range(16))
            print(f"⚠️  警告：未设置FIRST_SUPERUSER_PASSWORD环境变量，已生成随机密码: {v}")
            print(f"⚠️  请立即修改此密码！")
        elif v in ["admin123", "admin", "password", "123456", "root"]:
            raise ValueError("不允许使用弱密码，请设置强密码")
        return v
    
    @field_validator("DATABASE_URL")
    @classmethod
    def validate_database_url(cls, v: str) -> str:
        """验证数据库URL格式 - 仅支持mysql://前缀"""
        if not v.startswith("mysql://"):
            raise ValueError("仅支持mysql://前缀的数据库URL，其他格式将在连接层统一转换")
        return v
    
    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        """组装CORS源"""
        if isinstance(v, str) and not v.startswith("["):
            origins = [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            origins = v
        else:
            raise ValueError(v)
        
        # 验证CORS源安全性
        cls._validate_cors_origins(origins)
        return origins
    
    @classmethod
    def _validate_cors_origins(cls, origins: List[str]):
        """验证CORS源的安全性"""
        # 检查是否包含通配符
        if "*" in origins:
            import os
            environment = os.getenv("ENVIRONMENT", "development")
            if environment == "production":
                raise ValueError("生产环境不允许使用CORS通配符 '*'，请指定具体的域名")
            else:
                import logging
                logging.warning("开发环境使用CORS通配符 '*'，生产环境请指定具体域名")
        
        # 检查是否有不安全的HTTP源（生产环境）
        import os
        environment = os.getenv("ENVIRONMENT", "development")
        if environment == "production":
            for origin in origins:
                if origin.startswith("http://") and not origin.startswith("http://localhost") and not origin.startswith("http://${LOCAL_HOST}"):
                    raise ValueError(f"生产环境不允许使用不安全的HTTP源: {origin}")
    
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
        # 初始化路径配置
        self.path_config = PathConfig(self.INSTALL_DIR)
        # 验证配置完整性
        self._validate_config()
    
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
                try:
                    Path(directory).mkdir(parents=True, exist_ok=True)
                except PermissionError as e:
                    # 如果权限不足，记录警告但不中断启动
                    import logging
                    logging.warning(f"无法创建目录 {directory}: {e}")
                    # 尝试使用临时目录作为备选
                    if directory == self.UPLOAD_DIR:
                        self.UPLOAD_DIR = "/tmp/ipv6-wireguard-uploads"
                        Path(self.UPLOAD_DIR).mkdir(parents=True, exist_ok=True)
                    elif directory == self.WIREGUARD_CONFIG_DIR:
                        self.WIREGUARD_CONFIG_DIR = "/tmp/ipv6-wireguard-config"
                        Path(self.WIREGUARD_CONFIG_DIR).mkdir(parents=True, exist_ok=True)
                    elif directory == self.WIREGUARD_CLIENTS_DIR:
                        self.WIREGUARD_CLIENTS_DIR = "/tmp/ipv6-wireguard-clients"
                        Path(self.WIREGUARD_CLIENTS_DIR).mkdir(parents=True, exist_ok=True)
    
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
settings = UnifiedSettings()

# 导出配置类
__all__ = ["UnifiedSettings", "settings"]
