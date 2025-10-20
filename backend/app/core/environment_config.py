"""
环境特定配置加载器
根据当前环境加载相应的配置文件
"""

import os
import json
from typing import Dict, Any, Optional
from pathlib import Path
import logging
from .environment import EnvironmentType, get_env
from .config_manager import config_manager

logger = logging.getLogger(__name__)

class EnvironmentConfigLoader:
    """环境特定配置加载器"""
    
    def __init__(self, config_dir: str = "config"):
        self.config_dir = Path(config_dir)
        self.config_dir.mkdir(exist_ok=True)
        self.environment = get_env("ENVIRONMENT", EnvironmentType.DEVELOPMENT.value)
        
        # 确保环境特定配置文件存在
        self._ensure_config_files()
    
    def _ensure_config_files(self):
        """确保配置文件存在"""
        # 基础配置文件
        base_config_path = self.config_dir / "base.json"
        if not base_config_path.exists():
            self._create_base_config(base_config_path)
        
        # 环境特定配置文件
        for env in EnvironmentType:
            env_config_path = self.config_dir / f"{env.value}.json"
            if not env_config_path.exists():
                self._create_environment_config(env_config_path, env.value)
        
        # 本地配置文件
        local_config_path = self.config_dir / "local.json"
        if not local_config_path.exists():
            self._create_local_config(local_config_path)
    
    def _create_base_config(self, path: Path):
        """创建基础配置文件"""
        base_config = {
            "app": {
                "name": "IPv6 WireGuard Manager",
                "version": "3.0.0"
            },
            "api": {
                "v1_prefix": "/api/v1",
                "token_expire_minutes": 60 * 24 * 8
            },
            "server": {
                "host": "${SERVER_HOST}",
                "port": 8000
            },
            "database": {
                "host": "localhost",
                "port": 3306,
                "user": "ipv6wgm",
                "name": "ipv6wgm",
                "pool_size": 10,
                "max_overflow": 20,
                "connect_timeout": 30,
                "pool_recycle": 3600,
                "pool_pre_ping": True
            },
            "redis": {
                "url": "redis://localhost:${REDIS_PORT}/0",
                "pool_size": 10,
                "enabled": False
            },
            "security": {
                "algorithm": "HS256",
                "cors_origins": [
                    "http://localhost:${FRONTEND_PORT}",
                    "http://localhost:${ADMIN_PORT}",
                    "http://localhost:5173"
                ]
            },
            "upload": {
                "max_file_size": 10485760,  # 10MB
                "directory": "uploads",
                "allowed_extensions": [".conf", ".key", ".crt", ".pem", ".txt", ".log"]
            },
            "wireguard": {
                "config_dir": "/etc/wireguard",
                "clients_dir": "/etc/wireguard/clients"
            },
            "monitoring": {
                "metrics_enabled": True,
                "metrics_port": 9090,
                "health_check_enabled": True,
                "health_check_interval": 30
            },
            "logging": {
                "level": "INFO",
                "format": "json",
                "rotation": "1 day",
                "retention": "30 days"
            },
            "performance": {
                "max_workers": 4,
                "worker_class": "uvicorn.workers.UvicornWorker",
                "keep_alive": 2,
                "max_requests": 1000,
                "max_requests_jitter": 100
            }
        }
        
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(base_config, f, indent=2, ensure_ascii=False)
        
        logger.info(f"已创建基础配置文件: {path}")
    
    def _create_environment_config(self, path: Path, environment: str):
        """创建环境特定配置文件"""
        env_config = {}
        
        if environment == EnvironmentType.DEVELOPMENT.value:
            env_config = {
                "app": {
                    "debug": True
                },
                "database": {
                    "password": "password"
                },
                "logging": {
                    "level": "DEBUG"
                }
            }
        elif environment == EnvironmentType.TESTING.value:
            env_config = {
                "app": {
                    "debug": True
                },
                "database": {
                    "name": "ipv6wgm_test",
                    "password": "test_password"
                },
                "logging": {
                    "level": "DEBUG"
                }
            }
        elif environment == EnvironmentType.STAGING.value:
            env_config = {
                "app": {
                    "debug": False
                },
                "database": {
                    "pool_size": 20,
                    "max_overflow": 40
                },
                "logging": {
                    "level": "INFO"
                }
            }
        elif environment == EnvironmentType.PRODUCTION.value:
            env_config = {
                "app": {
                    "debug": False
                },
                "database": {
                    "pool_size": 50,
                    "max_overflow": 100,
                    "connect_timeout": 60
                },
                "security": {
                    "cors_origins": [
                        "https://yourdomain.com"
                    ]
                },
                "logging": {
                    "level": "WARNING"
                }
            }
        
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(env_config, f, indent=2, ensure_ascii=False)
        
        logger.info(f"已创建环境配置文件: {path} ({environment})")
    
    def _create_local_config(self, path: Path):
        """创建本地配置文件"""
        local_config = {
            "# 注释": "此文件用于本地开发时的配置覆盖，不应提交到版本控制",
            "database": {
                "password": "your_local_password"
            }
        }
        
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(local_config, f, indent=2, ensure_ascii=False)
        
        logger.info(f"已创建本地配置文件: {path}")
    
    def load_config(self) -> Dict[str, Any]:
        """加载配置"""
        config = {}
        
        # 按优先级加载配置文件
        config_files = [
            "base.json",
            f"{self.environment}.json",
            "local.json"
        ]
        
        for config_file in config_files:
            file_path = self.config_dir / config_file
            if file_path.exists():
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        file_config = json.load(f)
                    
                    # 深度合并配置
                    config = self._deep_merge(config, file_config)
                    logger.info(f"已加载配置文件: {config_file}")
                except Exception as e:
                    logger.error(f"加载配置文件失败: {config_file} - {e}")
        
        return config
    
    def _deep_merge(self, base: Dict[str, Any], override: Dict[str, Any]) -> Dict[str, Any]:
        """深度合并字典"""
        result = base.copy()
        
        for key, value in override.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = self._deep_merge(result[key], value)
            else:
                result[key] = value
        
        return result

# 创建全局环境配置加载器实例
env_config_loader = EnvironmentConfigLoader()

# 导出便捷函数
def load_environment_config() -> Dict[str, Any]:
    """加载环境特定配置"""
    return env_config_loader.load_config()

# 导出主要组件
__all__ = [
    "EnvironmentConfigLoader", "env_config_loader",
    "load_environment_config"
]
