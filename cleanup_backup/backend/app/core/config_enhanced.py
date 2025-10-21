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
    APP_VERSION: str = "3.1.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "production"
    
    # 路径配置 - 使用路径配置管理器
    INSTALL_DIR: str = "/opt/ipv6-wireguard-manager"
    
    # API配置
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = Field(default_factory=lambda: secrets.token_urlsafe(64))
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days
    
    # 服务器配置
    SERVER_NAME: Optional[str] = None
    SERVER_HOST: str = "0.0.0.0"
    SERVER_PORT: int = 8000
    
    # 数据库配置 - 强制使用MySQL
    DATABASE_URL: str = Field(default="mysql://ipv6wgm:password@localhost:3306/ipv6wgm")
    # 环境变量支持
    DATABASE_HOST: str = Field(default="localhost")
    DATABASE_PORT: int = Field(default=3306)
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
    # 强制使用异步驱动
    DATABASE_ASYNC_DRIVER: str = Field(default="aiomysql")
    DATABASE_SYNC_DRIVER: str = Field(default="pymysql")
    
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
        "http://localhost:4173",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:5173",
        "http://127.0.0.1:4173",
        "http://[::1]:3000",
        "http://[::1]:8080",
        "http://[::1]:5173",
        "http://[::1]:4173"
    ]
    
    # 文件上传配置
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10MB
    UPLOAD_DIR: str = "uploads"
    ALLOWED_EXTENSIONS: List[str] = [".conf", ".key", ".crt", ".pem", ".txt", ".log"]
    
    # WireGuard配置 - 使用路径配置
    WIREGUARD_PRIVATE_KEY: Optional[str] = None
    WIREGUARD_PUBLIC_KEY: Optional[str] = None
    WIREGUARD_PORT: int = 51820
    WIREGUARD_INTERFACE: str = "wg0"
    WIREGUARD_NETWORK: str = "10.0.0.0/24"
    WIREGUARD_IPV6_NETWORK: str = "fd00::/64"
    
    @property
    def WIREGUARD_CONFIG_DIR(self) -> str:
        """WireGuard配置目录"""
        from .path_config import PathConfig
        path_config = PathConfig(self.INSTALL_DIR)
        return str(path_config.wireguard_config_dir)
    
    @property
    def WIREGUARD_CLIENTS_DIR(self) -> str:
        """WireGuard客户端配置目录"""
        from .path_config import PathConfig
        path_config = PathConfig(self.INSTALL_DIR)
        return str(path_config.wireguard_clients_dir)
    
    @property
    def FRONTEND_DIR(self) -> str:
        """前端Web目录"""
        from .path_config import PathConfig
        path_config = PathConfig(self.INSTALL_DIR)
        return str(path_config.frontend_dir)
    
    @property
    def LOG_FILE(self) -> Optional[str]:
        """日志文件路径"""
        from .path_config import PathConfig
        path_config = PathConfig(self.INSTALL_DIR)
        return str(path_config.logs_dir / "app.log")
    
    @property
    def BACKUP_DIR(self) -> str:
        """备份目录"""
        from .path_config import PathConfig
        path_config = PathConfig(self.INSTALL_DIR)
        return str(path_config.backups_dir)
    
    @property
    def NGINX_CONFIG_DIR(self) -> str:
        """Nginx配置目录"""
        from .path_config import PathConfig
        path_config = PathConfig(self.INSTALL_DIR)
        return str(path_config.nginx_config_dir)
    
    @property
    def NGINX_LOG_DIR(self) -> str:
        """Nginx日志目录"""
        from .path_config import PathConfig
        path_config = PathConfig(self.INSTALL_DIR)
        return str(path_config.nginx_log_dir)
    
    @property
    def SYSTEMD_CONFIG_DIR(self) -> str:
        """Systemd服务配置目录"""
        from .path_config import PathConfig
        path_config = PathConfig(self.INSTALL_DIR)
        return str(path_config.systemd_config_dir)
    
    @property
    def BIN_DIR(self) -> str:
        """二进制文件目录"""
        from .path_config import PathConfig
        path_config = PathConfig(self.INSTALL_DIR)
        return str(path_config.bin_dir)
    
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
    FIRST_SUPERUSER_PASSWORD: str = Field(default_factory=lambda: secrets.token_urlsafe(16))
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
    def validate_superuser_password(cls, v: str) -> str:
        """验证超级用户密码"""
        if v in ["admin123", "admin", "password", "123456", "root"]:
            raise ValueError("不允许使用弱密码，请设置强密码")
        return v
    
    @field_validator("DATABASE_URL")
    @classmethod
    def validate_database_url(cls, v: str) -> str:
        """验证数据库URL格式"""
        if not v.startswith(("mysql://", "mysql+aiomysql://", "mysql+pymysql://")):
            raise ValueError("Only MySQL database is supported")
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
        # 应用环境管理器配置
        self._apply_environment_config()
        # 验证配置完整性
        self._validate_config()
        # 输出自动生成的密钥信息
        self._output_generated_credentials()
    
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
                try:
                    Path(directory).mkdir(parents=True, exist_ok=True)
                except PermissionError as e:
                    # 如果权限不足，记录警告但不中断启动
                    import logging
                    logging.warning(f"无法创建目录 {directory}: {e}")
                    # 尝试使用临时目录作为备选
                    if directory == self.UPLOAD_DIR:
                        # 使用临时目录作为备选，但不直接修改属性
                        temp_upload_dir = "/tmp/ipv6-wireguard-uploads"
                        Path(temp_upload_dir).mkdir(parents=True, exist_ok=True)
                        logging.info(f"使用临时上传目录: {temp_upload_dir}")
                    elif directory == self.WIREGUARD_CONFIG_DIR:
                        # 使用临时目录作为备选
                        temp_config_dir = "/tmp/ipv6-wireguard-config"
                        Path(temp_config_dir).mkdir(parents=True, exist_ok=True)
                        logging.info(f"使用临时WireGuard配置目录: {temp_config_dir}")
                    elif directory == self.WIREGUARD_CLIENTS_DIR:
                        # 使用临时目录作为备选
                        temp_clients_dir = "/tmp/ipv6-wireguard-clients"
                        Path(temp_clients_dir).mkdir(parents=True, exist_ok=True)
                        logging.info(f"使用临时WireGuard客户端目录: {temp_clients_dir}")
    
    def _check_file_permissions(self):
        """检查文件权限"""
        # 检查WireGuard配置目录权限
        wg_config_path = Path(self.WIREGUARD_CONFIG_DIR)
        if wg_config_path.exists():
            if not os.access(wg_config_path, os.R_OK | os.W_OK):
                raise PermissionError(f"Cannot access WireGuard config directory: {self.WIREGUARD_CONFIG_DIR}")
    
    @field_validator("SERVER_PORT", mode="before")
    @classmethod
    def convert_server_port(cls, v):
        """将SERVER_PORT转换为整数"""
        if isinstance(v, str):
            try:
                return int(v)
            except ValueError:
                raise ValueError("SERVER_PORT must be a valid integer")
        return v
    
    @field_validator("METRICS_PORT", mode="before")
    @classmethod
    def convert_metrics_port(cls, v):
        """将METRICS_PORT转换为整数"""
        if isinstance(v, str):
            try:
                return int(v)
            except ValueError:
                raise ValueError("METRICS_PORT must be a valid integer")
        return v
    
    def _validate_network_config(self):
        """验证网络配置"""
        # 确保端口是整数类型，处理可能的字符串类型
        try:
            # 确保端口值转换为整数
            server_port = int(self.SERVER_PORT) if self.SERVER_PORT is not None and isinstance(self.SERVER_PORT, (str, int, float)) else None
            metrics_port = int(self.METRICS_PORT) if self.METRICS_PORT is not None and isinstance(self.METRICS_PORT, (str, int, float)) else None
            
            if server_port is None or metrics_port is None:
                raise ValueError("Server port and metrics port must be valid numbers")
                
        except (ValueError, TypeError):
            raise ValueError("Server port and metrics port must be valid integers")
        
        # 验证端口范围 - 确保比较的是整数
        if not (1 <= server_port <= 65535):
            raise ValueError(f"Server port must be between 1 and 65535, got {server_port}")
        
        if not (1 <= metrics_port <= 65535):
            raise ValueError(f"Metrics port must be between 1 and 65535, got {metrics_port}")
    
    def _output_generated_credentials(self):
        """输出自动生成的凭据信息"""
        import os
        
        # 检查是否通过环境变量设置了密钥和密码
        secret_key_from_env = os.getenv('SECRET_KEY')
        password_from_env = os.getenv('FIRST_SUPERUSER_PASSWORD')
        
        # 如果密钥是自动生成的，输出信息
        if not secret_key_from_env:
            print("=" * 60)
            print("🔑 自动生成的 SECRET_KEY:")
            print(f"   {self.SECRET_KEY}")
            print("=" * 60)
        
        # 如果密码是自动生成的，输出信息
        if not password_from_env:
            print("=" * 60)
            print("🔐 自动生成的超级用户密码:")
            print(f"   用户名: {self.FIRST_SUPERUSER}")
            print(f"   密码: {self.FIRST_SUPERUSER_PASSWORD}")
            print("⚠️  请妥善保存此密码！")
            print("=" * 60)
    
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
