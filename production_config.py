#!/usr/bin/env python3
"""
IPv6 WireGuard Manager - 生产环境配置优化
"""

# 生产环境配置
PRODUCTION_CONFIG = {
    # 安全配置
    "SECURITY": {
        "SECRET_KEY": "your-super-secret-key-change-this-in-production",
        "ALGORITHM": "HS256",
        "ACCESS_TOKEN_EXPIRE_MINUTES": 30,
        "REFRESH_TOKEN_EXPIRE_DAYS": 30,
    },
    
    # 数据库配置
    "DATABASE": {
        "URL": "mysql://ipv6wgm:password@localhost:3306/ipv6wgm",
        "POOL_SIZE": 10,
        "MAX_OVERFLOW": 20,
        "POOL_TIMEOUT": 30,
        "POOL_RECYCLE": 3600,
    },
    
    # 服务配置
    "SERVICES": {
        "API_HOST": "0.0.0.0",
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
