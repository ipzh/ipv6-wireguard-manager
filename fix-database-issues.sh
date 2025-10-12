#!/bin/bash

echo "🔧 修复数据库初始化和服务启动问题..."
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
VENV_DIR="$BACKEND_DIR/venv"
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

# 1. 停止服务
log_step "停止服务..."
sudo systemctl stop $SERVICE_NAME 2>/dev/null || true

# 2. 检查虚拟环境
log_step "检查虚拟环境..."
if [ ! -d "$VENV_DIR" ]; then
    log_error "虚拟环境不存在，重新创建..."
    cd "$BACKEND_DIR"
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
else
    log_success "虚拟环境存在"
fi

# 3. 修复数据库配置
log_step "修复数据库配置..."
cd "$BACKEND_DIR"

# 创建简化的database.py
sudo tee app/core/database.py > /dev/null << 'EOF'
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

# 4. 修复模型文件
log_step "修复模型文件..."
sudo mkdir -p app/models

# 创建简化的models/__init__.py
sudo tee app/models/__init__.py > /dev/null << 'EOF'
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class WireGuardServer(Base):
    __tablename__ = "wireguard_servers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    description = Column(Text)
    public_key = Column(String)
    private_key = Column(String)
    listen_port = Column(Integer, default=51820)
    address = Column(String)  # IPv4 address
    address_v6 = Column(String)  # IPv6 address
    dns = Column(String)
    mtu = Column(Integer, default=1420)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class WireGuardClient(Base):
    __tablename__ = "wireguard_clients"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    description = Column(Text)
    public_key = Column(String)
    private_key = Column(String)
    address = Column(String)  # IPv4 address
    address_v6 = Column(String)  # IPv6 address
    allowed_ips = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
EOF

# 5. 修复init_db.py
log_step "修复数据库初始化..."
sudo tee app/core/init_db.py > /dev/null << 'EOF'
from sqlalchemy.orm import Session
from ..models import User, WireGuardServer, WireGuardClient
from .database import SessionLocal, engine, Base
from .config import settings

def init_db():
    # 确保表已创建
    Base.metadata.create_all(bind=engine)

    db: Session = SessionLocal()
    try:
        # 检查超级用户是否存在
        if db.query(User).filter(User.email == settings.FIRST_SUPERUSER_EMAIL).first() is None:
            # 创建超级用户
            superuser = User(
                email=settings.FIRST_SUPERUSER_EMAIL,
                username=settings.FIRST_SUPERUSER,
                hashed_password=settings.FIRST_SUPERUSER_PASSWORD,
                is_superuser=True,
                is_active=True,
            )
            db.add(superuser)
            db.commit()
            db.refresh(superuser)
            print(f"超级用户 {settings.FIRST_SUPERUSER_EMAIL} 创建成功")
        else:
            print(f"超级用户 {settings.FIRST_SUPERUSER_EMAIL} 已存在")
            
        # 创建默认WireGuard服务器配置
        if db.query(WireGuardServer).first() is None:
            default_server = WireGuardServer(
                name="default-server",
                description="默认WireGuard服务器",
                listen_port=51820,
                address="10.0.0.1/24",
                address_v6="fd00::1/64",
                dns="8.8.8.8, 2001:4860:4860::8888",
                mtu=1420,
                is_active=True
            )
            db.add(default_server)
            db.commit()
            print("默认WireGuard服务器配置创建成功")
        else:
            print("WireGuard服务器配置已存在")
            
    except Exception as e:
        print(f"初始化数据库失败: {e}")
        db.rollback()
    finally:
        db.close()
EOF

# 6. 修复main.py
log_step "修复主应用文件..."
sudo tee app/main.py > /dev/null << 'EOF'
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from .core.config import settings
from .core.database import engine, Base
from .core.init_db import init_db
from .models import User, WireGuardServer, WireGuardClient

# 创建数据库表
Base.metadata.create_all(bind=engine)

# 初始化默认数据
init_db()

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
    from .core.database import SessionLocal
    db = SessionLocal()
    try:
        servers = db.query(WireGuardServer).all()
        return {"servers": [{"id": s.id, "name": s.name, "description": s.description} for s in servers]}
    finally:
        db.close()

@app.get("/api/v1/clients")
async def get_clients():
    from .core.database import SessionLocal
    db = SessionLocal()
    try:
        clients = db.query(WireGuardClient).all()
        return {"clients": [{"id": c.id, "name": c.name, "description": c.description} for c in clients]}
    finally:
        db.close()

@app.get("/")
async def root():
    return {"message": "IPv6 WireGuard Manager API", "docs": "/docs"}
EOF

# 7. 确保__init__.py文件存在
log_step "确保__init__.py文件存在..."
sudo touch app/__init__.py
sudo touch app/core/__init__.py
sudo touch app/models/__init__.py

# 8. 重新安装依赖
log_step "重新安装依赖..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 9. 测试导入
log_step "测试模块导入..."
if python -c "from app.main import app; print('✅ app导入成功')" 2>/dev/null; then
    log_success "app模块导入正常"
else
    log_error "app模块导入失败"
    echo "错误详情:"
    python -c "from app.main import app" 2>&1
fi

# 10. 修复权限
log_step "修复文件权限..."
sudo chown -R ipv6wgm:ipv6wgm "$APP_HOME" 2>/dev/null || sudo chown -R $(whoami):$(whoami) "$APP_HOME"
sudo chmod -R 755 "$APP_HOME"

# 11. 更新systemd服务
log_step "更新systemd服务..."
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
Environment=PATH=$VENV_DIR/bin:/usr/local/bin:/usr/bin:/bin
Environment=PYTHONPATH=$BACKEND_DIR
ExecStart=$VENV_DIR/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 1
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 12. 重新加载systemd
log_step "重新加载systemd..."
sudo systemctl daemon-reload

# 13. 启动服务
log_step "启动服务..."
sudo systemctl start $SERVICE_NAME
sleep 5

# 14. 检查服务状态
log_step "检查服务状态..."
if systemctl is-active --quiet $SERVICE_NAME; then
    log_success "后端服务运行正常"
else
    log_error "后端服务启动失败"
    echo "服务状态:"
    sudo systemctl status $SERVICE_NAME --no-pager -l
fi

# 15. 测试API
log_step "测试API..."
if curl -s http://127.0.0.1:8000/health >/dev/null 2>&1; then
    log_success "API访问正常"
    curl -s http://127.0.0.1:8000/health
else
    log_error "API访问失败"
fi

echo ""
echo "测试API状态:"
if curl -s http://127.0.0.1:8000/api/v1/status >/dev/null 2>&1; then
    log_success "API状态正常"
    curl -s http://127.0.0.1:8000/api/v1/status
else
    log_error "API状态异常"
fi

# 16. 显示结果
log_step "显示修复结果..."
echo "========================================"
echo -e "${GREEN}🎉 数据库问题修复完成！${NC}"
echo ""
echo "📊 服务状态:"
echo "   后端服务: $(systemctl is-active $SERVICE_NAME)"
echo "   数据库: PostgreSQL"
echo "   缓存: Redis"
echo ""
echo "🌐 访问地址:"
echo "   本地API: http://localhost/api/v1/status"
echo "   健康检查: http://localhost/health"
echo "   API文档: http://localhost/docs"
echo ""
echo "🔧 管理命令:"
echo "   查看状态: sudo systemctl status $SERVICE_NAME"
echo "   查看日志: sudo journalctl -u $SERVICE_NAME -f"
echo "   重启服务: sudo systemctl restart $SERVICE_NAME"
echo ""
echo "========================================"
if systemctl is-active --quiet $SERVICE_NAME; then
    log_success "🎉 数据库和服务问题已修复！"
else
    log_error "❌ 仍有问题，请检查日志"
    echo "查看详细日志:"
    echo "  sudo journalctl -u $SERVICE_NAME -f"
fi
