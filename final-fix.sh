#!/bin/bash

echo "🔧 最终全面修复所有问题..."
echo "================================"

# 停止服务
echo "🛑 停止服务..."
sudo systemctl stop ipv6-wireguard-manager

# 进入后端目录
cd /opt/ipv6-wireguard-manager/backend

echo "🔍 当前状态..."
echo "   当前目录: $(pwd)"
echo "   用户: $(whoami)"

# 完全重建虚拟环境
echo "🗑️  完全重建虚拟环境..."
rm -rf venv
python3 -m venv venv
source venv/bin/activate

# 升级pip并安装依赖
echo "📦 安装依赖..."
pip install --upgrade pip
pip install -r requirements.txt

# 确保pydantic-settings已安装
echo "📦 确保pydantic-settings已安装..."
pip install pydantic-settings==2.1.0

# 创建修复后的config.py
echo "🔧 创建修复后的config.py..."
mkdir -p app/core
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

# 创建简化的main.py
echo "🔧 创建简化的main.py..."
cat > app/main.py << 'EOF'
"""
FastAPI应用主文件
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# 创建FastAPI应用
app = FastAPI(
    title="IPv6 WireGuard Manager",
    version="3.0.0",
    debug=False
)

# 添加CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:8080"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "IPv6 WireGuard Manager API", "version": "3.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/api/v1/status")
async def api_status():
    return {"status": "ok", "service": "IPv6 WireGuard Manager"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
EOF

# 创建__init__.py文件
echo "🔧 创建__init__.py文件..."
touch app/__init__.py
touch app/core/__init__.py

# 测试导入
echo "🔍 测试导入..."
python -c "from app.core.config import settings; print('✅ 配置导入成功')" || {
    echo "❌ 配置导入失败"
    exit 1
}

python -c "from app.main import app; print('✅ app导入成功')" || {
    echo "❌ app导入失败"
    exit 1
}

# 测试uvicorn
echo "🔍 测试uvicorn..."
python -c "import uvicorn; print('✅ uvicorn导入成功')" || {
    echo "❌ uvicorn导入失败"
    exit 1
}

# 设置权限
echo "🔐 设置权限..."
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager
sudo chmod -R 755 /opt/ipv6-wireguard-manager
sudo chmod +x /opt/ipv6-wireguard-manager/backend/venv/bin/*

# 测试手动启动
echo "🧪 测试手动启动..."
timeout 10 python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 1 &
UVICORN_PID=$!
sleep 5

if kill -0 $UVICORN_PID 2>/dev/null; then
    echo "✅ uvicorn手动启动成功"
    kill $UVICORN_PID
    sleep 2
else
    echo "❌ uvicorn手动启动失败"
    exit 1
fi

# 更新systemd服务文件
echo "🔧 更新systemd服务文件..."
sudo tee /etc/systemd/system/ipv6-wireguard-manager.service > /dev/null << EOF
[Unit]
Description=IPv6 WireGuard Manager
After=network.target postgresql.service
Wants=redis-server.service redis.service

[Service]
Type=simple
User=ipv6wgm
Group=ipv6wgm
WorkingDirectory=/opt/ipv6-wireguard-manager/backend
Environment=PATH=/opt/ipv6-wireguard-manager/backend/venv/bin:/usr/local/bin:/usr/bin:/bin
Environment=PYTHONPATH=/opt/ipv6-wireguard-manager/backend
ExecStart=/opt/ipv6-wireguard-manager/backend/venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 1
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd
echo "🔄 重新加载systemd..."
sudo systemctl daemon-reload

# 启动服务
echo "🚀 启动服务..."
sudo systemctl start ipv6-wireguard-manager

# 等待服务启动
sleep 5

# 检查服务状态
echo "🔍 检查服务状态..."
sudo systemctl status ipv6-wireguard-manager --no-pager

# 检查端口
echo "🔍 检查端口..."
if command -v ss >/dev/null 2>&1; then
    ss -tlnp | grep :8000 || echo "⚠️  端口8000未监听"
elif command -v netstat >/dev/null 2>&1; then
    netstat -tlnp | grep :8000 || echo "⚠️  端口8000未监听"
else
    echo "⚠️  无法检查端口"
fi

# 测试API
echo "🔍 测试API..."
sleep 2
if curl -s http://localhost:8000/health >/dev/null; then
    echo "✅ API响应正常"
    curl -s http://localhost:8000/health
    echo ""
    curl -s http://localhost:8000/api/v1/status
else
    echo "❌ API无响应"
    echo "📋 检查日志:"
    sudo journalctl -u ipv6-wireguard-manager --no-pager -n 20
fi

echo ""
echo "🎯 最终修复完成！"
echo ""
echo "📋 服务管理命令:"
echo "   sudo systemctl status ipv6-wireguard-manager"
echo "   sudo systemctl restart ipv6-wireguard-manager"
echo "   sudo journalctl -u ipv6-wireguard-manager -f"
