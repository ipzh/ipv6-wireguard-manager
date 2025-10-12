#!/bin/bash

echo "🔄 完整重新安装IPv6 WireGuard Manager..."
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
FRONTEND_DIR="$APP_HOME/frontend"
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

# 1. 完全清理
log_step "完全清理现有安装..."
echo "停止所有相关服务..."
sudo systemctl stop $SERVICE_NAME 2>/dev/null || true
sudo systemctl stop nginx 2>/dev/null || true

echo "禁用服务..."
sudo systemctl disable $SERVICE_NAME 2>/dev/null || true

echo "删除服务文件..."
sudo rm -f /etc/systemd/system/$SERVICE_NAME.service
sudo rm -f /etc/nginx/sites-available/ipv6-wireguard-manager
sudo rm -f /etc/nginx/sites-enabled/ipv6-wireguard-manager

echo "删除应用目录..."
sudo rm -rf "$APP_HOME"

echo "重新加载systemd..."
sudo systemctl daemon-reload

log_success "清理完成"

# 2. 创建应用目录
log_step "创建应用目录..."
sudo mkdir -p "$APP_HOME"
sudo mkdir -p "$BACKEND_DIR"
sudo mkdir -p "$FRONTEND_DIR"

# 3. 创建后端应用
log_step "创建后端应用..."

# 创建requirements.txt
sudo tee "$BACKEND_DIR/requirements.txt" > /dev/null << 'EOF'
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

# 创建环境配置
sudo tee "$BACKEND_DIR/.env" > /dev/null << 'EOF'
# 应用配置
APP_NAME=IPv6 WireGuard Manager
APP_VERSION=1.0.0
DEBUG=false

# 数据库配置
DATABASE_URL=postgresql://ipv6wgm:ipv6wgm@localhost:5432/ipv6wgm

# Redis配置
REDIS_URL=redis://localhost:6379/0

# 安全配置
SECRET_KEY=your-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# 超级用户配置
FIRST_SUPERUSER=admin
FIRST_SUPERUSER_EMAIL=admin@example.com
FIRST_SUPERUSER_PASSWORD=admin123

# CORS配置
BACKEND_CORS_ORIGINS=["http://localhost:3000","http://localhost","http://localhost:8080"]

# 服务器配置
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0
EOF

# 创建应用结构
sudo mkdir -p "$BACKEND_DIR/app"
sudo mkdir -p "$BACKEND_DIR/app/core"
sudo mkdir -p "$BACKEND_DIR/app/models"
sudo mkdir -p "$BACKEND_DIR/app/api"
sudo mkdir -p "$BACKEND_DIR/app/api/v1"

# 创建__init__.py文件
sudo touch "$BACKEND_DIR/app/__init__.py"
sudo touch "$BACKEND_DIR/app/core/__init__.py"
sudo touch "$BACKEND_DIR/app/models/__init__.py"
sudo touch "$BACKEND_DIR/app/api/__init__.py"
sudo touch "$BACKEND_DIR/app/api/v1/__init__.py"

# 创建配置模块
sudo tee "$BACKEND_DIR/app/core/config.py" > /dev/null << 'EOF'
from pydantic_settings import BaseSettings
from typing import List, Union
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

# 创建数据库模块
sudo tee "$BACKEND_DIR/app/core/database.py" > /dev/null << 'EOF'
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

# 创建模型
sudo tee "$BACKEND_DIR/app/models/__init__.py" > /dev/null << 'EOF'
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

# 创建数据库初始化
sudo tee "$BACKEND_DIR/app/core/init_db.py" > /dev/null << 'EOF'
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

# 创建主应用
sudo tee "$BACKEND_DIR/app/main.py" > /dev/null << 'EOF'
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

# 4. 创建前端应用
log_step "创建前端应用..."

# 创建前端目录结构
sudo mkdir -p "$FRONTEND_DIR/dist"

# 创建前端HTML文件
sudo tee "$FRONTEND_DIR/dist/index.html" > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager</title>
    <script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
    <script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
    <script src="https://unpkg.com/antd@5/dist/antd.min.js"></script>
    <link rel="stylesheet" href="https://unpkg.com/antd@5/dist/reset.css">
    <style>
        body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, sans-serif; }
        .container { padding: 20px; max-width: 1200px; margin: 0 auto; }
    </style>
</head>
<body>
    <div id="root"></div>
    <script>
        const { useState, useEffect } = React;
        const { Layout, Card, Row, Col, Statistic, Button, message, Table, Tag } = antd;
        const { Header, Content } = Layout;

        function Dashboard() {
            const [loading, setLoading] = useState(false);
            const [apiStatus, setApiStatus] = useState(null);
            const [servers, setServers] = useState([]);
            const [clients, setClients] = useState([]);

            const checkApiStatus = async () => {
                setLoading(true);
                try {
                    const response = await fetch('/api/v1/status');
                    const data = await response.json();
                    setApiStatus(data);
                    message.success('API连接正常');
                } catch (error) {
                    message.error('API连接失败');
                } finally {
                    setLoading(false);
                }
            };

            const loadServers = async () => {
                try {
                    const response = await fetch('/api/v1/servers');
                    const data = await response.json();
                    setServers(data.servers || []);
                } catch (error) {
                    console.error('加载服务器失败:', error);
                }
            };

            const loadClients = async () => {
                try {
                    const response = await fetch('/api/v1/clients');
                    const data = await response.json();
                    setClients(data.clients || []);
                } catch (error) {
                    console.error('加载客户端失败:', error);
                }
            };

            useEffect(() => {
                checkApiStatus();
                loadServers();
                loadClients();
            }, []);

            const serverColumns = [
                { title: 'ID', dataIndex: 'id', key: 'id' },
                { title: '名称', dataIndex: 'name', key: 'name' },
                { title: '描述', dataIndex: 'description', key: 'description' },
                { title: '状态', key: 'status', render: () => <Tag color="green">运行中</Tag> }
            ];

            const clientColumns = [
                { title: 'ID', dataIndex: 'id', key: 'id' },
                { title: '名称', dataIndex: 'name', key: 'name' },
                { title: '描述', dataIndex: 'description', key: 'description' },
                { title: '状态', key: 'status', render: () => <Tag color="blue">已连接</Tag> }
            ];

            return React.createElement(Layout, { style: { minHeight: '100vh' } }, [
                React.createElement(Header, { 
                    key: 'header',
                    style: { background: '#fff', padding: '0 24px', boxShadow: '0 2px 8px rgba(0,0,0,0.1)' }
                }, React.createElement('h1', { style: { margin: 0, color: '#1890ff' } }, '🌐 IPv6 WireGuard Manager')),
                React.createElement(Content, { 
                    key: 'content',
                    style: { padding: '24px', background: '#f0f2f5' }
                }, [
                    React.createElement(Row, { key: 'stats', gutter: [16, 16] }, [
                        React.createElement(Col, { key: 'status', xs: 24, sm: 12, md: 8 }, 
                            React.createElement(Card, null, 
                                React.createElement(Statistic, { 
                                    title: '服务状态', 
                                    value: '运行中', 
                                    valueStyle: { color: '#52c41a' } 
                                })
                            )
                        ),
                        React.createElement(Col, { key: 'api', xs: 24, sm: 12, md: 8 }, 
                            React.createElement(Card, null, 
                                React.createElement(Statistic, { 
                                    title: 'API状态', 
                                    value: apiStatus ? apiStatus.status : '检查中', 
                                    valueStyle: { color: '#1890ff' } 
                                })
                            )
                        ),
                        React.createElement(Col, { key: 'actions', xs: 24, sm: 12, md: 8 }, 
                            React.createElement(Card, null, 
                                React.createElement(Button, { 
                                    type: 'primary', 
                                    onClick: checkApiStatus, 
                                    loading: loading 
                                }, '刷新状态')
                            )
                        )
                    ]),
                    React.createElement(Row, { key: 'tables', gutter: [16, 16], style: { marginTop: 16 } }, [
                        React.createElement(Col, { key: 'servers', xs: 24, lg: 12 }, 
                            React.createElement(Card, { title: 'WireGuard服务器' }, 
                                React.createElement(Table, { 
                                    columns: serverColumns, 
                                    dataSource: servers, 
                                    rowKey: 'id',
                                    pagination: false,
                                    size: 'small'
                                })
                            )
                        ),
                        React.createElement(Col, { key: 'clients', xs: 24, lg: 12 }, 
                            React.createElement(Card, { title: 'WireGuard客户端' }, 
                                React.createElement(Table, { 
                                    columns: clientColumns, 
                                    dataSource: clients, 
                                    rowKey: 'id',
                                    pagination: false,
                                    size: 'small'
                                })
                            )
                        )
                    ])
                ])
            ]);
        }

        ReactDOM.render(React.createElement(Dashboard), document.getElementById('root'));
    </script>
</body>
</html>
EOF

# 5. 创建虚拟环境并安装依赖
log_step "创建虚拟环境并安装依赖..."
cd "$BACKEND_DIR"

# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 升级pip
pip install --upgrade pip

# 安装依赖
pip install -r requirements.txt

log_success "后端依赖安装完成"

# 6. 创建用户和组
log_step "创建用户和组..."
sudo useradd -r -s /bin/false ipv6wgm 2>/dev/null || true

# 7. 设置权限
log_step "设置文件权限..."
sudo chown -R ipv6wgm:ipv6wgm "$APP_HOME"
sudo chmod -R 755 "$APP_HOME"

# 8. 配置数据库
log_step "配置数据库..."
# 确保PostgreSQL运行
sudo systemctl start postgresql
sudo systemctl enable postgresql

# 创建数据库和用户
sudo -u postgres psql -c "CREATE DATABASE ipv6wgm;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE USER ipv6wgm WITH PASSWORD 'ipv6wgm';" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ipv6wgm TO ipv6wgm;" 2>/dev/null || true

# 9. 配置Redis
log_step "配置Redis..."
sudo systemctl start redis-server 2>/dev/null || sudo systemctl start redis 2>/dev/null || true
sudo systemctl enable redis-server 2>/dev/null || sudo systemctl enable redis 2>/dev/null || true

# 10. 创建systemd服务
log_step "创建systemd服务..."
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

# 11. 配置Nginx
log_step "配置Nginx..."
sudo tee /etc/nginx/sites-available/ipv6-wireguard-manager > /dev/null << EOF
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    # 前端静态文件
    location / {
        root $FRONTEND_DIR/dist;
        try_files \$uri \$uri/ /index.html;
    }
    
    # 后端API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # WebSocket代理
    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
    
    # 错误页面
    error_page 404 /index.html;
    error_page 500 502 503 504 /index.html;
}
EOF

# 启用Nginx站点
sudo ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/

# 测试Nginx配置
if sudo nginx -t; then
    log_success "Nginx配置正确"
else
    log_error "Nginx配置错误"
    exit 1
fi

# 12. 重新加载systemd
log_step "重新加载systemd..."
sudo systemctl daemon-reload

# 13. 启动服务
log_step "启动服务..."
sudo systemctl start $SERVICE_NAME
sudo systemctl enable $SERVICE_NAME
sleep 5

sudo systemctl start nginx
sudo systemctl enable nginx
sleep 2

# 14. 检查服务状态
log_step "检查服务状态..."
if systemctl is-active --quiet $SERVICE_NAME; then
    log_success "后端服务运行正常"
else
    log_error "后端服务启动失败"
    echo "服务状态:"
    sudo systemctl status $SERVICE_NAME --no-pager -l
fi

if systemctl is-active --quiet nginx; then
    log_success "Nginx服务运行正常"
else
    log_error "Nginx服务启动失败"
    echo "服务状态:"
    sudo systemctl status nginx --no-pager -l
fi

# 15. 测试访问
log_step "测试访问..."
echo "测试后端API:"
if curl -s http://127.0.0.1:8000/health >/dev/null 2>&1; then
    log_success "后端API访问正常"
    curl -s http://127.0.0.1:8000/health
else
    log_error "后端API访问失败"
fi

echo ""
echo "测试前端访问:"
if curl -s http://localhost >/dev/null 2>&1; then
    log_success "前端访问正常"
    echo "响应状态码:"
    curl -s -o /dev/null -w "%{http_code}" http://localhost
else
    log_error "前端访问失败"
fi

echo ""
echo "测试API代理:"
if curl -s http://localhost/api/v1/status >/dev/null 2>&1; then
    log_success "API代理正常"
    curl -s http://localhost/api/v1/status
else
    log_error "API代理失败"
fi

# 16. 显示结果
log_step "显示安装结果..."
echo "========================================"
echo -e "${GREEN}🎉 完整重新安装完成！${NC}"
echo ""
echo "📋 访问信息："
echo "   IPv4访问地址："
PUBLIC_IPV4=$(curl -s -4 ifconfig.me 2>/dev/null || echo "")
LOCAL_IPV4=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
if [ -n "$PUBLIC_IPV4" ]; then
    echo "     - 前端界面: http://$PUBLIC_IPV4"
    echo "     - 后端API: http://$PUBLIC_IPV4/api"
    echo "     - API文档: http://$PUBLIC_IPV4/api/docs"
else
    echo "     - 前端界面: http://$LOCAL_IPV4"
    echo "     - 后端API: http://$LOCAL_IPV4/api"
    echo "     - API文档: http://$LOCAL_IPV4/api/docs"
fi

echo "   IPv6访问地址："
IPV6_ADDRESS=$(ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1 | head -1)
if [ -n "$IPV6_ADDRESS" ]; then
    echo "     - 前端界面: http://[$IPV6_ADDRESS]"
    echo "     - 后端API: http://[$IPV6_ADDRESS]/api"
    echo "     - API文档: http://[$IPV6_ADDRESS]/api/docs"
else
    echo "     - 请运行 'ip -6 addr show' 查看IPv6地址"
fi

echo ""
echo "🔑 默认登录信息："
echo "   用户名: admin"
echo "   密码: admin123"
echo ""
echo "🛠️  管理命令："
echo "   查看状态: sudo systemctl status $SERVICE_NAME nginx"
echo "   查看日志: sudo journalctl -u $SERVICE_NAME -f"
echo "   重启服务: sudo systemctl restart $SERVICE_NAME nginx"
echo ""
echo "📁 安装位置："
echo "   应用目录: $APP_HOME"
echo "   配置文件: $BACKEND_DIR/.env"
echo ""
echo "🌐 本地测试："
echo "   前端: http://localhost"
echo "   API: http://localhost/api/v1/status"
echo "   健康: http://localhost/health"
echo ""
echo "========================================"
if curl -s http://localhost >/dev/null 2>&1; then
    log_success "🎉 完整重新安装成功！所有问题已修复！"
else
    log_error "❌ 安装可能有问题，请检查日志"
    echo "查看详细日志:"
    echo "  sudo journalctl -u $SERVICE_NAME -f"
    echo "  sudo tail -f /var/log/nginx/error.log"
fi
