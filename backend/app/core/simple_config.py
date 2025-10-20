"""
简化的配置访问模块
基于SimpleConfigManager提供简单的配置访问接口
"""

import os
from typing import Any, Dict, List, Optional, Union
from pathlib import Path

# 导入简化配置管理器
from fix_config_management import SimpleConfigManager

# 创建全局配置管理器实例
_config_manager = SimpleConfigManager()

def get(key: str, default: Any = None) -> Any:
    """获取配置值"""
    return _config_manager.get(key, default)

def set(key: str, value: Any):
    """设置配置值"""
    _config_manager.set(key, value)

def get_app_name() -> str:
    """获取应用名称"""
    return get("app.name", "IPv6 WireGuard Manager")

def get_app_version() -> str:
    """获取应用版本"""
    return get("app.version", "3.0.0")

def is_debug() -> bool:
    """是否为调试模式"""
    return get("app.debug", False)

def get_environment() -> str:
    """获取运行环境"""
    return get("app.environment", "development")

def get_server_host() -> str:
    """获取服务器主机"""
    return get("server.host", "${SERVER_HOST}")

def get_server_port() -> int:
    """获取服务器端口"""
    return get("server.port", 8000)

def get_database_url() -> str:
    """获取数据库URL"""
    return get("database.url", "mysql://ipv6wgm:password@localhost:3306/ipv6wgm")

def get_database_host() -> str:
    """获取数据库主机"""
    return get("database.host", "localhost")

def get_database_port() -> int:
    """获取数据库端口"""
    return get("database.port", 3306)

def get_database_user() -> str:
    """获取数据库用户名"""
    return get("database.user", "ipv6wgm")

def get_database_password() -> str:
    """获取数据库密码"""
    return get("database.password", "password")

def get_database_name() -> str:
    """获取数据库名称"""
    return get("database.name", "ipv6wgm")

def get_redis_url() -> Optional[str]:
    """获取Redis URL"""
    return get("redis.url")

def get_redis_port() -> int:
    """获取Redis端口"""
    return get("redis.port", 6379)

def get_log_level() -> str:
    """获取日志级别"""
    return get("logging.level", "INFO")

def get_log_file() -> Optional[str]:
    """获取日志文件路径"""
    return get("logging.file")

def get_wireguard_config_dir() -> str:
    """获取WireGuard配置目录"""
    return get("wireguard.config_dir", "/etc/wireguard")

def get_wireguard_clients_dir() -> str:
    """获取WireGuard客户端配置目录"""
    return get("wireguard.clients_dir", "/etc/wireguard/clients")

def is_development() -> bool:
    """是否为开发环境"""
    return get_environment() == "development"

def is_production() -> bool:
    """是否为生产环境"""
    return get_environment() == "production"

def is_testing() -> bool:
    """是否为测试环境"""
    return get_environment() == "testing"

def save_env_variable(key: str, value: Any):
    """保存环境变量"""
    _config_manager.save_env_file(key, value)

def get_all_config() -> Dict[str, Any]:
    """获取所有配置"""
    return _config_manager.get_all_config()

def print_config_summary():
    """打印配置摘要"""
    _config_manager.print_config_summary()

# 导出便捷函数
__all__ = [
    "get", "set",
    "get_app_name", "get_app_version", "is_debug", "get_environment",
    "get_server_host", "get_server_port",
    "get_database_url", "get_database_host", "get_database_port",
    "get_database_user", "get_database_password", "get_database_name",
    "get_redis_url", "get_redis_port",
    "get_log_level", "get_log_file",
    "get_wireguard_config_dir", "get_wireguard_clients_dir",
    "is_development", "is_production", "is_testing",
    "save_env_variable", "get_all_config", "print_config_summary"
]
