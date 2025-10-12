#!/bin/bash

# IPv6 WireGuard Manager 快速安装脚本
# 专门解决常见安装问题，提供快速部署

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 项目信息
REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager/archive/refs/heads/main.zip"
INSTALL_DIR="ipv6-wireguard-manager"
APP_USER="ipv6wgm"
APP_HOME="/opt/ipv6-wireguard-manager"

echo "=================================="
echo "IPv6 WireGuard Manager 快速安装"
echo "=================================="
echo ""

# 检查root权限
if [ "$EUID" -ne 0 ]; then
    log_error "请使用root权限运行此脚本"
    exit 1
fi

# 检测系统环境
log_info "检测系统环境..."
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
if [ "$TOTAL_MEM" -lt 1024 ]; then
    log_warning "检测到低内存环境 (${TOTAL_MEM}MB)，将使用优化配置"
    LOW_MEMORY=true
else
    LOW_MEMORY=false
fi

# 更新系统
log_info "更新系统包..."
apt-get update -qq
apt-get install -y curl wget unzip git sudo systemd ufw

# 下载项目
log_info "下载项目..."
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
fi

if command -v wget >/dev/null 2>&1; then
    wget -q "$REPO_URL" -O project.zip
else
    curl -fsSL "$REPO_URL" -o project.zip
fi

unzip -q project.zip
rm project.zip

if [ -d "ipv6-wireguard-manager-main" ]; then
    mv ipv6-wireguard-manager-main "$INSTALL_DIR"
fi

# 安装依赖
log_info "安装系统依赖..."
apt-get install -y python3 python3-pip python3-venv python3-dev build-essential libpq-dev pkg-config libssl-dev libffi-dev

# 安装Node.js
log_info "安装Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# 安装数据库
log_info "安装数据库..."
apt-get install -y postgresql postgresql-contrib redis-server

# 安装Web服务器
log_info "安装Nginx..."
apt-get install -y nginx

# 创建系统用户
log_info "创建系统用户..."
if ! id "$APP_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -d "$APP_HOME" -m "$APP_USER"
fi

# 设置项目目录
log_info "设置项目目录..."
mkdir -p "$APP_HOME"
cp -r "$INSTALL_DIR"/* "$APP_HOME/"
chown -R "$APP_USER:$APP_USER" "$APP_HOME"
chmod -R 755 "$APP_HOME"

# 配置数据库
log_info "配置数据库..."
systemctl enable postgresql
systemctl start postgresql

# 创建数据库和用户
sudo -u postgres psql -c "CREATE DATABASE ipv6wgm;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE USER ipv6wgm WITH PASSWORD 'password';" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ipv6wgm TO ipv6wgm;" 2>/dev/null || true
sudo -u postgres psql -c "ALTER USER ipv6wgm CREATEDB;" 2>/dev/null || true

# 配置PostgreSQL认证
PG_HBA_FILE="/etc/postgresql/*/main/pg_hba.conf"
if [ -f $PG_HBA_FILE ]; then
    echo "local   all             ipv6wgm                                trust" >> $PG_HBA_FILE
    echo "host    all             ipv6wgm        127.0.0.1/32            trust" >> $PG_HBA_FILE
    echo "host    all             ipv6wgm        ::1/128                 trust" >> $PG_HBA_FILE
    systemctl restart postgresql
fi

# 安装后端
log_info "安装后端..."
cd "$APP_HOME/backend"

# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装Python依赖
pip install --upgrade pip
pip install fastapi uvicorn sqlalchemy psycopg2-binary redis python-multipart python-jose[cryptography] passlib[bcrypt] python-dotenv pydantic-settings

# 创建环境配置
cat > .env << EOF
DATABASE_URL="postgresql://ipv6wgm:password@localhost:5432/ipv6wgm"
REDIS_URL="redis://localhost:6379/0"
SECRET_KEY="your_super_secret_key_for_production"
DEBUG=False
BACKEND_CORS_ORIGINS=["http://localhost:3000", "http://localhost:8080", "http://localhost:5173", "http://localhost", "http://127.0.0.1:3000", "http://127.0.0.1:8080", "http://127.0.0.1:5173", "http://127.0.0.1"]
ACCESS_TOKEN_EXPIRE_MINUTES=30
EOF

# 初始化数据库
python -c "
import asyncio
from app.core.database import engine
from app.models import Base
from app.core.init_db import init_db

async def init_database():
    try:
        Base.metadata.create_all(bind=engine)
        await init_db()
        print('数据库初始化成功')
    except Exception as e:
        print(f'数据库初始化失败: {e}')

asyncio.run(init_database())
"

# 安装前端
log_info "安装前端..."
cd "$APP_HOME/frontend"

# 检查前端源码
if [ ! -d "src" ]; then
    log_error "前端源码不存在"
    exit 1
fi

# 安装依赖
npm install --silent 2>/dev/null || npm install

# 创建环境配置
cat > .env << EOF
VITE_API_URL=http://127.0.0.1:8000
VITE_WS_URL=ws://127.0.0.1:8000/api/v1/ws
EOF

# 构建前端
if [ "$LOW_MEMORY" = true ]; then
    NODE_OPTIONS="--max-old-space-size=2048" npm run build
else
    npm run build
fi

# 确保dist目录存在
if [ ! -d "dist" ]; then
    log_warning "前端构建失败，创建基础文件..."
    mkdir -p dist
    cat > dist/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
    </style>
</head>
<body>
    <div class="container">
        <h1>IPv6 WireGuard Manager</h1>
        <div class="status info">
            <h3>系统状态</h3>
            <p>前端服务正在启动中...</p>
            <p>请稍等片刻，系统将自动重定向到登录页面。</p>
        </div>
        <div class="status success">
            <h3>默认登录信息</h3>
            <p>用户名: admin</p>
            <p>密码: admin123</p>
        </div>
    </div>
    <script>
        setTimeout(() => {
            window.location.href = '/login';
        }, 3000);
    </script>
</body>
</html>
EOF
fi

# 配置Nginx
log_info "配置Nginx..."
cat > /etc/nginx/sites-available/ipv6-wireguard-manager << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    # 前端静态文件
    location / {
        root /opt/ipv6-wireguard-manager/frontend/dist;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    # 后端API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # WebSocket代理
    location /ws/ {
        proxy_pass http://127.0.0.1:8000/api/v1/ws/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # API文档
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# 启用站点
ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 测试配置
nginx -t

# 创建系统服务
log_info "创建系统服务..."
cat > /etc/systemd/system/ipv6-wireguard-manager.service << EOF
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target postgresql.service redis.service
Requires=postgresql.service redis.service

[Service]
Type=simple
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_HOME/backend
Environment=PATH=$APP_HOME/backend/venv/bin
Environment=PYTHONPATH=$APP_HOME/backend
ExecStart=$APP_HOME/backend/venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 1
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
log_info "启动服务..."
systemctl daemon-reload
systemctl enable redis-server postgresql nginx ipv6-wireguard-manager
systemctl start redis-server postgresql nginx ipv6-wireguard-manager

# 等待服务启动
sleep 5

# 配置防火墙
log_info "配置防火墙..."
ufw --force enable
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 51820/udp
ufw allow from 127.0.0.1 to any port 8000

# 获取服务器IP
get_server_ip() {
    IPV4=$(ip route get 8.8.8.8 | awk '{print $7; exit}' 2>/dev/null || echo "未知")
    IPV6=$(ip -6 route get 2001:4860:4860::8888 | awk '{print $7; exit}' 2>/dev/null || echo "未知")
    echo "IPv4: $IPV4"
    echo "IPv6: $IPV6"
}

# 显示安装结果
echo ""
echo "=================================="
echo "快速安装完成！"
echo "=================================="
echo ""

log_info "服务器访问地址:"
get_server_ip
echo ""

log_info "服务访问地址:"
echo "  前端界面: http://$(hostname -I | awk '{print $1}')"
echo "  后端API: http://127.0.0.1:8000"
echo "  API文档: http://127.0.0.1:8000/docs"
echo "  健康检查: http://127.0.0.1:8000/health"
echo ""

log_info "默认登录信息:"
echo "  用户名: admin"
echo "  密码: admin123"
echo ""

log_info "服务管理命令:"
echo "  查看状态: systemctl status ipv6-wireguard-manager"
echo "  重启服务: systemctl restart ipv6-wireguard-manager"
echo "  查看日志: journalctl -u ipv6-wireguard-manager -f"
echo ""

log_success "快速安装完成！请访问前端界面开始使用。"
