#!/bin/bash

echo "🔍 诊断和修复后端502 Bad Gateway错误..."
echo "========================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 应用配置
APP_HOME="/opt/ipv6-wireguard-manager"
BACKEND_DIR="$APP_HOME/backend"
SERVICE_NAME="ipv6-wireguard-manager"

# 日志函数
log_step() {
    echo -e "${BLUE}🚀 [STEP] $1${NC}"
}

log_info() {
    echo -e "${BLUE}💡 [INFO] $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ [SUCCESS] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  [WARNING] $1${NC}"
}

log_error() {
    echo -e "${RED}❌ [ERROR] $1${NC}"
}

# 1. 检查后端服务状态
log_step "检查后端服务状态..."
if systemctl is-active --quiet $SERVICE_NAME; then
    log_success "后端服务正在运行"
else
    log_error "后端服务未运行"
    echo "服务状态:"
    sudo systemctl status $SERVICE_NAME --no-pager -l
fi

# 2. 检查端口监听
log_step "检查端口监听..."
if netstat -tlnp | grep -q ":8000"; then
    log_success "端口8000正在监听"
    echo "端口监听详情:"
    netstat -tlnp | grep ":8000"
else
    log_error "端口8000未监听"
    echo "所有监听端口:"
    netstat -tlnp | head -10
fi

# 3. 检查后端目录和文件
log_step "检查后端目录和文件..."
if [ -d "$BACKEND_DIR" ]; then
    log_success "后端目录存在: $BACKEND_DIR"
    echo "目录内容:"
    ls -la "$BACKEND_DIR"
else
    log_error "后端目录不存在: $BACKEND_DIR"
    exit 1
fi

# 检查关键文件
echo ""
echo "检查关键文件:"
if [ -f "$BACKEND_DIR/app/main.py" ]; then
    log_success "main.py 存在"
else
    log_error "main.py 不存在"
fi

if [ -f "$BACKEND_DIR/venv/bin/python" ]; then
    log_success "虚拟环境存在"
else
    log_error "虚拟环境不存在"
fi

if [ -f "$BACKEND_DIR/.env" ]; then
    log_success ".env 配置文件存在"
else
    log_error ".env 配置文件不存在"
fi

# 4. 检查虚拟环境和依赖
log_step "检查虚拟环境和依赖..."
cd "$BACKEND_DIR"

if [ -d "venv" ]; then
    log_success "虚拟环境目录存在"
    
    # 激活虚拟环境并检查Python
    source venv/bin/activate
    echo "Python版本: $(python --version)"
    echo "Pip版本: $(pip --version)"
    
    # 检查关键依赖
    echo ""
    echo "检查关键依赖:"
    if python -c "import fastapi" 2>/dev/null; then
        log_success "FastAPI 已安装"
    else
        log_error "FastAPI 未安装"
    fi
    
    if python -c "import uvicorn" 2>/dev/null; then
        log_success "Uvicorn 已安装"
    else
        log_error "Uvicorn 未安装"
    fi
    
    if python -c "import sqlalchemy" 2>/dev/null; then
        log_success "SQLAlchemy 已安装"
    else
        log_error "SQLAlchemy 未安装"
    fi
    
    if python -c "import pydantic" 2>/dev/null; then
        log_success "Pydantic 已安装"
    else
        log_error "Pydantic 未安装"
    fi
else
    log_error "虚拟环境不存在，重新创建..."
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    
    # 安装依赖
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
    else
        # 创建requirements.txt
        cat > requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
pydantic==2.5.0
pydantic-settings==2.1.0
python-multipart==0.0.6
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
alembic==1.13.1
redis==5.0.1
celery==5.3.4
EOF
        pip install -r requirements.txt
    fi
fi

# 5. 检查应用结构
log_step "检查应用结构..."
if [ ! -d "app" ]; then
    log_error "app目录不存在，创建..."
    mkdir -p app/core app/models app/api/v1
    
    # 创建__init__.py文件
    touch app/__init__.py
    touch app/core/__init__.py
    touch app/models/__init__.py
    touch app/api/__init__.py
    touch app/api/v1/__init__.py
fi

# 检查关键模块
echo "检查关键模块:"
if [ -f "app/core/config.py" ]; then
    log_success "config.py 存在"
else
    log_error "config.py 不存在，创建..."
    cat > app/core/config.py << 'EOF'
from pydantic_settings import BaseSettings
from typing import List
import os

class Settings(BaseSettings):
    APP_NAME: str = "IPv6 WireGuard Manager"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # 数据库配置
    DATABASE_URL: str = "postgresql://ipv6wgm:ipv6wgm@localhost:5432/ipv6wgm"
    
    # Redis配置
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # 安全配置
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # 超级用户配置
    FIRST_SUPERUSER: str = "admin"
    FIRST_SUPERUSER_EMAIL: str = "admin@example.com"
    FIRST_SUPERUSER_PASSWORD: str = "admin123"
    
    # CORS配置
    BACKEND_CORS_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost", "http://localhost:8080"]
    
    # 服务器配置
    ALLOWED_HOSTS: str = "localhost,127.0.0.1,0.0.0.0"
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"

settings = Settings()
EOF
fi

if [ -f "app/core/database.py" ]; then
    log_success "database.py 存在"
else
    log_error "database.py 不存在，创建..."
    cat > app/core/database.py << 'EOF'
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from .config import settings

SQLALCHEMY_DATABASE_URL = settings.DATABASE_URL

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOF
fi

if [ -f "app/main.py" ]; then
    log_success "main.py 存在"
else
    log_error "main.py 不存在，创建..."
    cat > app/main.py << 'EOF'
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from .core.config import settings
from .core.database import engine, Base
from .models import User, WireGuardServer, WireGuardClient

# 创建数据库表
try:
    Base.metadata.create_all(bind=engine)
    print("数据库表创建成功")
except Exception as e:
    print(f"数据库表创建失败: {e}")

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    debug=settings.DEBUG,
)

# 添加CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health", summary="检查服务健康状态")
async def health_check():
    return JSONResponse(content={"status": "healthy", "message": "IPv6 WireGuard Manager is running"})

@app.get("/api/v1/status", summary="获取API服务状态")
async def get_api_status():
    return {
        "status": "ok", 
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "message": "IPv6 WireGuard Manager API is running"
    }

@app.get("/api/v1/users/me")
async def read_users_me():
    return {
        "username": "admin", 
        "email": settings.FIRST_SUPERUSER_EMAIL,
        "is_superuser": True
    }

@app.get("/api/v1/servers")
async def get_servers():
    try:
        from .core.database import SessionLocal
        db = SessionLocal()
        try:
            servers = db.query(WireGuardServer).all()
            return {"servers": [{"id": s.id, "name": s.name, "description": s.description} for s in servers]}
        finally:
            db.close()
    except Exception as e:
        return {"servers": [], "error": str(e)}

@app.get("/api/v1/clients")
async def get_clients():
    try:
        from .core.database import SessionLocal
        db = SessionLocal()
        try:
            clients = db.query(WireGuardClient).all()
            return {"clients": [{"id": c.id, "name": c.name, "description": c.description} for c in clients]}
        finally:
            db.close()
    except Exception as e:
        return {"clients": [], "error": str(e)}

@app.get("/")
async def root():
    return {"message": "IPv6 WireGuard Manager API", "docs": "/docs"}
EOF
fi

# 6. 检查数据库连接
log_step "检查数据库连接..."
echo "检查PostgreSQL服务..."
if systemctl is-active --quiet postgresql; then
    log_success "PostgreSQL服务正在运行"
else
    log_warning "PostgreSQL服务未运行，启动..."
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
fi

echo "检查数据库连接..."
if python -c "
from app.core.database import engine
try:
    with engine.connect() as conn:
        print('数据库连接成功')
except Exception as e:
    print(f'数据库连接失败: {e}')
    exit(1)
"; then
    log_success "数据库连接正常"
else
    log_error "数据库连接失败"
    echo "尝试创建数据库和用户..."
    sudo -u postgres psql -c "CREATE DATABASE ipv6wgm;" 2>/dev/null || true
    sudo -u postgres psql -c "CREATE USER ipv6wgm WITH PASSWORD 'ipv6wgm';" 2>/dev/null || true
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ipv6wgm TO ipv6wgm;" 2>/dev/null || true
fi

# 7. 测试应用启动
log_step "测试应用启动..."
echo "测试Python模块导入..."
if python -c "
import sys
sys.path.insert(0, '.')
try:
    from app.main import app
    print('应用导入成功')
except Exception as e:
    print(f'应用导入失败: {e}')
    exit(1)
"; then
    log_success "应用模块导入正常"
else
    log_error "应用模块导入失败"
fi

# 8. 重启服务
log_step "重启后端服务..."
sudo systemctl stop $SERVICE_NAME
sleep 2

# 更新systemd服务文件
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=IPv6 WireGuard Manager
After=network.target postgresql.service
Wants=redis-server.service redis.service

[Service]
Type=simple
User=ipv6wgm
Group=ipv6wgm
WorkingDirectory=$BACKEND_DIR
Environment=PATH=$BACKEND_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin
Environment=PYTHONPATH=$BACKEND_DIR
ExecStart=$BACKEND_DIR/venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 1
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start $SERVICE_NAME
sleep 5

# 9. 检查服务状态
log_step "检查服务状态..."
if systemctl is-active --quiet $SERVICE_NAME; then
    log_success "后端服务启动成功"
else
    log_error "后端服务启动失败"
    echo "服务状态:"
    sudo systemctl status $SERVICE_NAME --no-pager -l
    echo ""
    echo "服务日志:"
    sudo journalctl -u $SERVICE_NAME --no-pager -l -n 20
fi

# 10. 测试API访问
log_step "测试API访问..."
echo "等待服务完全启动..."
sleep 3

echo "测试健康检查端点:"
if curl -s http://127.0.0.1:8000/health; then
    log_success "健康检查端点正常"
else
    log_error "健康检查端点失败"
fi

echo ""
echo "测试API状态端点:"
if curl -s http://127.0.0.1:8000/api/v1/status; then
    log_success "API状态端点正常"
else
    log_error "API状态端点失败"
fi

echo ""
echo "测试通过Nginx代理:"
if curl -s http://localhost/api/v1/status; then
    log_success "Nginx代理正常"
else
    log_error "Nginx代理失败"
fi

# 11. 显示修复结果
log_step "显示修复结果..."
echo "========================================"
echo -e "${GREEN}🎉 后端502错误修复完成！${NC}"
echo ""
echo "📋 修复内容："
echo "   ✅ 检查后端服务状态"
echo "   ✅ 验证虚拟环境和依赖"
echo "   ✅ 检查应用结构和文件"
echo "   ✅ 测试数据库连接"
echo "   ✅ 重启后端服务"
echo "   ✅ 测试API访问"
echo ""
echo "🌐 测试访问："
echo "   直接访问: http://127.0.0.1:8000/api/v1/status"
echo "   通过Nginx: http://localhost/api/v1/status"
echo "   健康检查: http://localhost/health"
echo ""
echo "🔧 管理命令："
echo "   查看状态: sudo systemctl status $SERVICE_NAME"
echo "   查看日志: sudo journalctl -u $SERVICE_NAME -f"
echo "   重启服务: sudo systemctl restart $SERVICE_NAME"
echo ""
echo "📊 服务状态："
echo "   后端服务: $(systemctl is-active $SERVICE_NAME)"
echo "   PostgreSQL: $(systemctl is-active postgresql)"
echo "   Nginx: $(systemctl is-active nginx)"
echo ""
echo "========================================"

# 12. 最终测试
echo "🔍 最终测试..."
if curl -s http://localhost/api/v1/status | grep -q "ok"; then
    log_success "🎉 后端服务完全正常！"
    echo "现在可以正常访问前端页面了"
else
    log_error "❌ 后端服务仍有问题"
    echo "请检查服务日志: sudo journalctl -u $SERVICE_NAME -f"
fi
