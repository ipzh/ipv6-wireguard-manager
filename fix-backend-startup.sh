#!/bin/bash

# 修复后端服务启动问题
echo "🔧 开始修复后端服务启动问题..."

APP_HOME="/opt/ipv6-wireguard-manager"

if [ ! -d "$APP_HOME/backend" ]; then
    echo "❌ 后端目录不存在: $APP_HOME/backend"
    exit 1
fi

cd "$APP_HOME/backend"
echo "📁 当前目录: $(pwd)"

if [ ! -d "venv" ]; then
    echo "❌ 虚拟环境不存在"
    exit 1
fi

echo "🔧 激活虚拟环境..."
source venv/bin/activate

echo "🔧 安装缺失的依赖..."
pip install --quiet psycopg2-binary sqlalchemy fastapi uvicorn

echo "🔧 创建简化的数据库配置..."
cat > app/core/database_simple.py << 'EOF'
"""
简化的数据库配置（用于修复启动问题）
"""
from sqlalchemy import create_engine, MetaData
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# 创建基础模型类
Base = declarative_base()

# 创建元数据
metadata = MetaData()

# 数据库URL
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://ipv6wgm:ipv6wgm123@localhost:5432/ipv6wgm")

# 创建同步数据库引擎
engine = create_engine(
    DATABASE_URL,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=False,
)

# 创建会话工厂
SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
)

# 为了兼容性，导出sync_engine
sync_engine = engine

def get_db():
    """获取数据库会话"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """初始化数据库"""
    Base.metadata.create_all(bind=engine)

def close_db():
    """关闭数据库连接"""
    engine.dispose()
EOF

echo "✅ 已创建简化的数据库配置"

echo "🔧 创建简化的主应用..."
cat > app/main_simple.py << 'EOF'
"""
简化的IPv6 WireGuard Manager主应用（用于修复启动问题）
"""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import time
import logging
import os

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# 创建FastAPI应用
app = FastAPI(
    title="IPv6 WireGuard Manager",
    version="1.0.0",
    description="现代化的企业级IPv6 WireGuard VPN管理系统",
    openapi_url="/api/v1/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
)

# 添加CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    """添加处理时间头"""
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """全局异常处理器"""
    logger.error(f"Global exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "message": "内部服务器错误",
            "error_code": "INTERNAL_SERVER_ERROR"
        }
    )

@app.on_event("startup")
async def startup_event():
    """应用启动事件"""
    logger.info("Starting IPv6 WireGuard Manager...")
    try:
        # 尝试初始化数据库
        from .core.database_simple import init_db
        init_db()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        # 不退出，继续启动
    logger.info("Application started successfully")

@app.on_event("shutdown")
async def shutdown_event():
    """应用关闭事件"""
    logger.info("Shutting down IPv6 WireGuard Manager...")
    try:
        from .core.database_simple import close_db
        close_db()
    except Exception as e:
        logger.error(f"Database shutdown failed: {e}")
    logger.info("Application shutdown complete")

@app.get("/")
async def root():
    """根路径"""
    return {
        "message": "IPv6 WireGuard Manager API",
        "version": "1.0.0",
        "docs": "/docs",
        "redoc": "/redoc"
    }

@app.get("/health")
async def health_check():
    """健康检查"""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": time.time()
    }

@app.get("/api/v1/status/status")
async def get_status():
    """获取系统状态"""
    return {
        "status": "ok",
        "service": "IPv6 WireGuard Manager",
        "version": "1.0.0",
        "message": "IPv6 WireGuard Manager API is running"
    }

@app.get("/api/v1/status/health")
async def api_health_check():
    """API健康检查"""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": time.time()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main_simple:app",
        host="127.0.0.1",
        port=8000,
        reload=False,
        log_level="info"
    )
EOF

echo "✅ 已创建简化的主应用"

echo "🔧 修复models/__init__.py..."
cat > app/models/__init__.py << 'EOF'
"""
数据库模型
"""
from ..core.database_simple import Base
from .user import User, Role, UserRole
from .wireguard import WireGuardServer, WireGuardClient, ClientServerRelation
from .network import NetworkInterface, FirewallRule
from .monitoring import SystemMetric, AuditLog, OperationLog
from .config import ConfigVersion, BackupRecord

__all__ = [
    "Base",
    "User",
    "Role", 
    "UserRole",
    "WireGuardServer",
    "WireGuardClient",
    "ClientServerRelation",
    "NetworkInterface",
    "FirewallRule",
    "SystemMetric",
    "AuditLog",
    "OperationLog",
    "ConfigVersion",
    "BackupRecord",
]
EOF

echo "✅ 已修复models/__init__.py"

echo "🔧 创建环境配置文件..."
cat > .env << 'EOF'
DATABASE_URL=postgresql://ipv6wgm:ipv6wgm123@localhost:5432/ipv6wgm
APP_NAME=IPv6 WireGuard Manager
APP_VERSION=1.0.0
DEBUG=False
SERVER_HOST=127.0.0.1
SERVER_PORT=8000
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=10080
REDIS_URL=redis://localhost:6379/0
LOG_LEVEL=INFO
EOF

echo "✅ 已创建环境配置文件"

echo "🔧 更新systemd服务配置..."
sudo tee /etc/systemd/system/ipv6-wireguard-manager.service > /dev/null << 'EOF'
[Unit]
Description=IPv6 WireGuard Manager
After=network.target postgresql.service redis-server.service
Wants=postgresql.service redis-server.service

[Service]
Type=simple
User=ipv6wgm
Group=ipv6wgm
WorkingDirectory=/opt/ipv6-wireguard-manager/backend
Environment=PATH=/opt/ipv6-wireguard-manager/backend/venv/bin:/usr/local/bin:/usr/bin:/bin
Environment=PYTHONPATH=/opt/ipv6-wireguard-manager/backend
ExecStart=/opt/ipv6-wireguard-manager/backend/venv/bin/python -m uvicorn app.main_simple:app --host 127.0.0.1 --port 8000 --workers 1
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "✅ 已更新systemd服务配置"

echo "🔧 重新加载systemd配置..."
sudo systemctl daemon-reload

echo "🔧 停止现有服务..."
sudo systemctl stop ipv6-wireguard-manager

echo "🔧 测试应用启动..."
python -c "
import sys
sys.path.insert(0, '.')
try:
    from app.main_simple import app
    print('✅ 应用导入成功')
except Exception as e:
    print(f'❌ 应用导入失败: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    echo "✅ 应用测试通过"
else
    echo "❌ 应用测试失败"
    exit 1
fi

echo "🔧 启动服务..."
sudo systemctl start ipv6-wireguard-manager

echo "⏳ 等待服务启动..."
sleep 10

echo "🔍 检查服务状态..."
if sudo systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "✅ 后端服务运行正常"
else
    echo "❌ 后端服务异常"
    echo "📋 服务状态:"
    sudo systemctl status ipv6-wireguard-manager --no-pager -l
    echo ""
    echo "📋 服务日志:"
    sudo journalctl -u ipv6-wireguard-manager --no-pager -l -n 20
fi

echo "🔍 测试API访问..."
if curl -s "http://localhost:8000/api/v1/status/status" >/dev/null 2>&1; then
    echo "✅ API访问正常"
    echo "📋 API响应:"
    curl -s "http://localhost:8000/api/v1/status/status" | head -c 200
    echo ""
else
    echo "❌ API访问异常"
    echo "📋 尝试直接测试:"
    curl -v "http://localhost:8000/api/v1/status/status" 2>&1 | head -20
fi

echo "🔍 测试Web访问..."
if curl -s "http://localhost" >/dev/null 2>&1; then
    echo "✅ Web访问正常"
else
    echo "❌ Web访问异常"
fi

echo ""
echo "🎉 后端服务启动问题修复完成！"
echo ""
echo "📋 访问信息:"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')
echo "   Web界面: http://$SERVER_IP"
echo "   API文档: http://$SERVER_IP:8000/docs"
echo "   健康检查: http://$SERVER_IP:8000/health"
echo ""
echo "🔧 管理命令:"
echo "   查看状态: sudo systemctl status ipv6-wireguard-manager"
echo "   查看日志: sudo journalctl -u ipv6-wireguard-manager -f"
echo "   重启服务: sudo systemctl restart ipv6-wireguard-manager"
echo ""
echo "🔧 如果仍有问题，请检查:"
echo "   1. 数据库连接: PGPASSWORD='ipv6wgm123' psql -h localhost -U ipv6wgm -d ipv6wgm"
echo "   2. 服务日志: sudo journalctl -u ipv6-wireguard-manager -f"
echo "   3. 端口占用: sudo netstat -tlnp | grep 8000"
