"""
精简配置管理
减少复杂的配置加载，使用简化的配置结构
"""
from typing import List, Optional
from pydantic import BaseSettings, Field
import os
from pathlib import Path

class SimplifiedSettings(BaseSettings):
    """精简配置类"""
    
    # 应用基础配置
    APP_NAME: str = "IPv6 WireGuard Manager"
    APP_VERSION: str = "3.1.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "production"
    
    # 服务器配置
    SERVER_HOST: str = "0.0.0.0"
    SERVER_PORT: int = 8000
    
    # 数据库配置
    DATABASE_URL: str = "mysql://ipv6wgm:password@mysql:3306/ipv6wgm"
    
    # 安全配置
    SECRET_KEY: str = "your-secret-key-here"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    
    # CORS配置
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost:80",
        "http://localhost:3000",
        "http://localhost:5173",
        "http://127.0.0.1:80",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5173"
    ]
    
    # WireGuard配置
    WIREGUARD_PORT: int = 51820
    WIREGUARD_INTERFACE: str = "wg0"
    WIREGUARD_NETWORK: str = "10.0.0.0/24"
    WIREGUARD_IPV6_NETWORK: str = "fd00::/64"
    
    # 日志配置
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "json"
    
    # Redis配置
    REDIS_URL: str = "redis://localhost:6379/0"
    USE_REDIS: bool = False
    
    # 路径配置
    INSTALL_DIR: str = "/opt/ipv6-wireguard-manager"
    WIREGUARD_CONFIG_DIR: str = "/etc/wireguard"
    WIREGUARD_CLIENTS_DIR: str = "/etc/wireguard/clients"
    
    class Config:
        env_file = ".env"
        case_sensitive = True

# 创建全局配置实例
settings = SimplifiedSettings()

# 路径配置
class PathConfig:
    """路径配置类"""
    
    def __init__(self):
        self.install_dir = Path(settings.INSTALL_DIR)
        self.wireguard_config_dir = Path(settings.WIREGUARD_CONFIG_DIR)
        self.wireguard_clients_dir = Path(settings.WIREGUARD_CLIENTS_DIR)
        self.logs_dir = self.install_dir / "logs"
        self.cache_dir = self.install_dir / "cache"
        self.backups_dir = self.install_dir / "backups"
    
    def ensure_directories(self):
        """确保目录存在"""
        for path in [
            self.install_dir,
            self.wireguard_config_dir,
            self.wireguard_clients_dir,
            self.logs_dir,
            self.cache_dir,
            self.backups_dir
        ]:
            path.mkdir(parents=True, exist_ok=True)

# 创建路径配置实例
path_config = PathConfig()
