#!/bin/bash

echo "🔧 修复Pydantic验证错误..."
echo "================================"

# 进入后端目录
cd /opt/ipv6-wireguard-manager/backend

# 激活虚拟环境
source venv/bin/activate

echo "🔧 更新配置文件..."
# 创建修复后的config.py
cat > app/core/config.py << 'EOF'
"""
应用配置管理
"""
from typing import List, Optional
try:
    # Pydantic 2.x
    from pydantic_settings import BaseSettings
    from pydantic import field_validator
except ImportError:
    # Pydantic 1.x fallback
    from pydantic import BaseSettings, validator as field_validator
import secrets


class Settings(BaseSettings):
    """应用配置"""
    
    # 应用基础配置
    APP_NAME: str = "IPv6 WireGuard Manager"
    APP_VERSION: str = "3.0.0"
    DEBUG: bool = False
    
    # API配置
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = secrets.token_urlsafe(32)
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days
    
    # 服务器配置
    SERVER_NAME: Optional[str] = None
    SERVER_HOST: str = "0.0.0.0"
    SERVER_PORT: int = 8000
    
    # 数据库配置
    DATABASE_URL: str = "postgresql://ipv6wgm:password@localhost:5432/ipv6wgm"
    DATABASE_POOL_SIZE: int = 20
    DATABASE_MAX_OVERFLOW: int = 30
    
    # Redis配置
    REDIS_URL: str = "redis://localhost:6379/0"
    REDIS_POOL_SIZE: int = 10
    
    # 安全配置
    ALGORITHM: str = "HS256"
    BACKEND_CORS_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:8080"]
    
    # 文件上传配置
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10MB
    UPLOAD_DIR: str = "uploads"
    
    # WireGuard配置
    WIREGUARD_CONFIG_DIR: str = "/etc/wireguard"
    WIREGUARD_CLIENTS_DIR: str = "/etc/wireguard/clients"
    
    # 监控配置
    ENABLE_METRICS: bool = True
    METRICS_PORT: int = 9090
    
    # 日志配置
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "json"
    
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
    
    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: str | List[str]) -> List[str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        # Pydantic 2.x compatibility
        env_file_encoding = "utf-8"
        # Allow extra fields to prevent validation errors
        extra = "ignore"


# 创建全局配置实例
settings = Settings()
EOF

echo "✅ 配置文件已更新"

echo "🔍 测试配置导入..."
python -c "from app.core.config import settings; print('✅ 配置导入成功')"

echo "🔍 测试app导入..."
python -c "from app.main import app; print('✅ app导入成功')"

echo "🗄️  初始化数据库..."
python -c "from app.core.database import engine; from app.models import Base; Base.metadata.create_all(bind=engine); print('✅ 数据库表创建完成')"

echo "🚀 重启服务..."
sudo systemctl restart ipv6-wireguard-manager

# 等待服务启动
sleep 3

echo "🔍 检查服务状态..."
sudo systemctl status ipv6-wireguard-manager --no-pager

echo "🎯 Pydantic验证修复完成！"
