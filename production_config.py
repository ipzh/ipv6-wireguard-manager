#!/usr/bin/env python3
"""
IPv6 WireGuard Manager - 生产环境配置优化
"""

import os
import secrets
import string

def generate_secret_key(length=64):
    """生成安全的密钥"""
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
    return ''.join(secrets.choice(alphabet) for _ in range(length))

def get_secret_key():
    """获取密钥，优先从环境变量，否则生成随机密钥"""
    secret_key = os.getenv('SECRET_KEY')
    if not secret_key:
        secret_key = generate_secret_key()
        print(f"⚠️  警告：未设置SECRET_KEY环境变量，已生成随机密钥")
        print(f"⚠️  请设置环境变量: export secret_key="${API_KEY}"")
    return secret_key

# 生产环境配置
PRODUCTION_CONFIG = {
    # 安全配置
    "SECURITY": {
        "SECRET_KEY": get_secret_key(),
        "ALGORITHM": "HS256",
        "ACCESS_TOKEN_EXPIRE_MINUTES": 30,
        "REFRESH_TOKEN_EXPIRE_DAYS": 30,
    },
    
    # 数据库配置
    "DATABASE": {
        "URL": "mysql://ipv6wgm:password@localhost:${DB_PORT}/ipv6wgm",
        "POOL_SIZE": 10,
        "MAX_OVERFLOW": 20,
        "POOL_TIMEOUT": 30,
        "POOL_RECYCLE": 3600,
    },
    
    # 服务配置
    "SERVICES": {
        "API_HOST": "${SERVER_HOST}",
        "API_PORT": 8000,
        "WEB_PORT": 80,
        "WORKERS": 4,
    },
    
    # 日志配置
    "LOGGING": {
        "LEVEL": "INFO",
        "FORMAT": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        "FILE": "/opt/ipv6-wireguard-manager/logs/app.log",
    },
    
    # 性能配置
    "PERFORMANCE": {
        "CACHE_TTL": 300,
        "MAX_CONNECTIONS": 1000,
        "TIMEOUT": 30,
    }
}

def get_production_config():
    """获取生产环境配置"""
    return PRODUCTION_CONFIG

if __name__ == "__main__":
    import json
    print(json.dumps(PRODUCTION_CONFIG, indent=2))
