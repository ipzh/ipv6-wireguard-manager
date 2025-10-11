#!/bin/bash

# IPv6 WireGuard Manager VPS快速安装脚本
# 专为VPS环境设计，无需用户交互，自动选择最佳配置

set -e

echo "=================================="
echo "IPv6 WireGuard Manager VPS快速安装"
echo "=================================="
echo ""

# 项目信息
REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager.git"
INSTALL_DIR="ipv6-wireguard-manager"
APP_USER="ipv6wgm"
APP_HOME="/opt/ipv6-wireguard-manager"

# 检测服务器IP地址
get_server_ip() {
    echo "🌐 检测服务器IP地址..."
    
    # 检测IPv4地址
    PUBLIC_IPV4=""
    LOCAL_IPV4=""
    
    if command -v curl >/dev/null 2>&1; then
        PUBLIC_IPV4=$(curl -s --connect-timeout 5 --max-time 10 \
            https://ipv4.icanhazip.com 2>/dev/null || \
            curl -s --connect-timeout 5 --max-time 10 \
            https://api.ipify.org 2>/dev/null)
    fi
    
    if command -v ip >/dev/null 2>&1; then
        LOCAL_IPV4=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    elif command -v hostname >/dev/null 2>&1; then
        LOCAL_IPV4=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    
    # 检测IPv6地址
    PUBLIC_IPV6=""
    LOCAL_IPV6=""
    
    if command -v curl >/dev/null 2>&1; then
        PUBLIC_IPV6=$(curl -s --connect-timeout 5 --max-time 10 \
            https://ipv6.icanhazip.com 2>/dev/null || \
            curl -s --connect-timeout 5 --max-time 10 \
            https://api64.ipify.org 2>/dev/null)
    fi
    
    if command -v ip >/dev/null 2>&1; then
        LOCAL_IPV6=$(ip -6 route get 2001:4860:4860::8888 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    fi
    
    # 设置IP地址
    if [ -n "$PUBLIC_IPV4" ]; then
        SERVER_IPV4="$PUBLIC_IPV4"
    elif [ -n "$LOCAL_IPV4" ]; then
        SERVER_IPV4="$LOCAL_IPV4"
    else
        SERVER_IPV4="localhost"
    fi
    
    if [ -n "$PUBLIC_IPV6" ]; then
        SERVER_IPV6="$PUBLIC_IPV6"
    elif [ -n "$LOCAL_IPV6" ]; then
        SERVER_IPV6="$LOCAL_IPV6"
    fi
    
    echo "   IPv4: $SERVER_IPV4"
    if [ -n "$SERVER_IPV6" ]; then
        echo "   IPv6: $SERVER_IPV6"
    fi
    echo ""
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        if grep -q "CentOS" /etc/redhat-release; then
            OS="centos"
        elif grep -q "Red Hat" /etc/redhat-release; then
            OS="rhel"
        elif grep -q "Fedora" /etc/redhat-release; then
            OS="fedora"
        fi
    elif [ -f /etc/debian_version ]; then
        OS="debian"
    else
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    fi
    echo "检测到操作系统: $OS $OS_VERSION"
}

# 安装最小化依赖
install_minimal_dependencies() {
    echo "📦 安装最小化依赖..."
    
    case $OS in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y \
                git \
                python3 \
                python3-pip \
                python3-venv \
                python3-dev \
                build-essential \
                libpq-dev \
                pkg-config \
                libssl-dev \
                nodejs \
                npm \
                postgresql \
                postgresql-contrib \
                redis-server \
                nginx \
                curl \
                wget
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                PKG_MGR="dnf"
            else
                PKG_MGR="yum"
            fi
            
            sudo $PKG_MGR update -y
            sudo $PKG_MGR install -y \
                git \
                python3 \
                python3-pip \
                python3-devel \
                gcc \
                gcc-c++ \
                make \
                postgresql-devel \
                openssl-devel \
                nodejs \
                npm \
                postgresql-server \
                postgresql-contrib \
                redis \
                nginx \
                curl \
                wget
                
            # 初始化PostgreSQL
            if [ ! -d /var/lib/pgsql/data ]; then
                sudo postgresql-setup initdb
            fi
            ;;
        alpine)
            sudo apk update
            sudo apk add \
                git \
                python3 \
                py3-pip \
                python3-dev \
                build-base \
                postgresql-dev \
                openssl-dev \
                nodejs \
                npm \
                postgresql \
                redis \
                nginx \
                curl \
                wget
            ;;
        *)
            echo "❌ 不支持的操作系统: $OS"
            exit 1
            ;;
    esac
    echo "✅ 依赖安装完成"
}

# 创建应用用户
create_app_user() {
    echo "👤 创建应用用户..."
    
    if ! id "$APP_USER" &>/dev/null; then
        sudo useradd -r -s /bin/false -d "$APP_HOME" -m "$APP_USER"
        echo "✅ 用户 $APP_USER 创建成功"
    else
        echo "✅ 用户 $APP_USER 已存在"
    fi
}

# 下载项目
download_project() {
    echo "📥 下载项目..."
    
    if [ -d "$INSTALL_DIR" ]; then
        echo "⚠️  删除现有目录..."
        rm -rf "$INSTALL_DIR"
    fi
    
    if ! git clone "$REPO_URL" "$INSTALL_DIR"; then
        echo "❌ 下载项目失败"
        exit 1
    fi
    
    # 检查下载是否成功
    if [ ! -d "$INSTALL_DIR" ]; then
        echo "❌ 项目目录未创建"
        exit 1
    fi
    
    # 检查关键目录是否存在
    if [ ! -d "$INSTALL_DIR/backend" ]; then
        echo "❌ 后端目录不存在"
        echo "📁 项目目录内容:"
        ls -la "$INSTALL_DIR"
        exit 1
    fi
    
    if [ ! -d "$INSTALL_DIR/frontend" ]; then
        echo "❌ 前端目录不存在"
        echo "📁 项目目录内容:"
        ls -la "$INSTALL_DIR"
        exit 1
    fi
    
    echo "✅ 项目下载成功"
    echo "📁 项目结构:"
    ls -la "$INSTALL_DIR"
}

# 快速安装后端
install_backend() {
    echo "🐍 安装Python后端..."
    
    # 确保在项目根目录
    if [ ! -d "backend" ]; then
        echo "❌ 不在项目根目录，尝试查找项目目录..."
        if [ -d "$INSTALL_DIR" ]; then
            cd "$INSTALL_DIR"
            echo "✅ 切换到项目目录: $(pwd)"
        else
            echo "❌ 找不到项目目录"
            exit 1
        fi
    fi
    
    # 检查后端目录是否存在
    if [ ! -d "backend" ]; then
        echo "❌ 后端目录不存在"
        echo "📁 当前目录内容:"
        ls -la
        exit 1
    fi
    
    cd backend
    
    # 检查requirements文件是否存在
    if [ ! -f "requirements.txt" ] && [ ! -f "requirements-compatible.txt" ]; then
        echo "❌ requirements文件不存在"
        echo "📁 后端目录内容:"
        ls -la
        exit 1
    fi
    
    # 创建虚拟环境
    python3 -m venv venv
    source venv/bin/activate
    
    # 升级pip
    pip install --upgrade pip
    
    # 安装依赖
    if [ -f "requirements-compatible.txt" ]; then
        echo "📦 使用兼容版本requirements文件..."
        pip install -r requirements-compatible.txt
    else
        echo "📦 使用标准requirements文件..."
        pip install -r requirements.txt
    fi
    
    # 创建环境配置文件
    if [ ! -f .env ]; then
        echo "⚙️  创建环境配置文件..."
        cat > .env << EOF
DATABASE_URL=postgresql://ipv6wgm:password@localhost:5432/ipv6wgm
REDIS_URL=redis://localhost:6379/0
SECRET_KEY=$(openssl rand -hex 32)
DEBUG=false
ALLOWED_HOSTS=localhost,127.0.0.1,$SERVER_IPV4
EOF
        if [ -n "$SERVER_IPV6" ]; then
            echo "ALLOWED_HOSTS=localhost,127.0.0.1,$SERVER_IPV4,[$SERVER_IPV6]" >> .env
        fi
    fi
    
    echo "✅ 后端安装完成"
}

# 快速安装前端
install_frontend() {
    echo "⚛️  安装React前端..."
    echo "   当前目录: $(pwd)"
    
    # 获取项目根目录的绝对路径
    PROJECT_ROOT=""
    if [ -d "$INSTALL_DIR" ]; then
        PROJECT_ROOT=$(realpath "$INSTALL_DIR")
    elif [ -d "../$INSTALL_DIR" ]; then
        PROJECT_ROOT=$(realpath "../$INSTALL_DIR")
    elif [ -d "../../$INSTALL_DIR" ]; then
        PROJECT_ROOT=$(realpath "../../$INSTALL_DIR")
    else
        echo "❌ 找不到项目目录"
        echo "📁 当前目录内容:"
        ls -la
        echo "📁 上级目录内容:"
        ls -la .. 2>/dev/null || echo "无法访问上级目录"
        exit 1
    fi
    
    echo "   项目根目录: $PROJECT_ROOT"
    cd "$PROJECT_ROOT"
    echo "   切换到项目目录: $(pwd)"
    
    # 检查前端目录是否存在
    if [ ! -d "frontend" ]; then
        echo "❌ 前端目录不存在"
        echo "📁 项目目录内容:"
        ls -la
        exit 1
    fi
    
    cd frontend
    
    # 检查package.json是否存在
    if [ ! -f "package.json" ]; then
        echo "❌ package.json 不存在"
        echo "📁 前端目录内容:"
        ls -la
        exit 1
    fi
    
    # 使用构建脚本
    if [ -f "../../scripts/build-frontend.sh" ]; then
        echo "🔨 使用构建脚本..."
        bash ../../scripts/build-frontend.sh
    else
        # 备用构建方法
        echo "📦 安装依赖..."
        echo "   抑制npm废弃警告..."
        npm install --silent 2>/dev/null || npm install
        
        # 检查并安装必要的构建工具
        if ! npx tsc --version >/dev/null 2>&1; then
            echo "📦 安装TypeScript..."
            npm install typescript --save-dev
        fi
        
        if ! npx vite --version >/dev/null 2>&1; then
            echo "📦 安装Vite..."
            npm install vite --save-dev
        fi
        
        # 构建生产版本（增加内存限制）
        echo "🏗️  构建生产版本..."
        echo "   增加Node.js内存限制..."
        if NODE_OPTIONS="--max-old-space-size=4096" npm run build; then
            echo "✅ 构建成功"
        else
            echo "⚠️  使用4GB内存构建失败，尝试2GB..."
            if NODE_OPTIONS="--max-old-space-size=2048" npm run build; then
                echo "✅ 构建成功（使用2GB内存）"
            else
                echo "❌ 构建失败"
                exit 1
            fi
        fi
    fi
    
    echo "✅ 前端安装完成"
}

# 快速配置数据库
setup_database() {
    echo "🗄️  配置数据库..."
    
    case $OS in
        ubuntu|debian|centos|rhel|fedora)
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            ;;
        alpine)
            sudo rc-update add postgresql
            sudo service postgresql start
            ;;
    esac
    
    # 创建数据库和用户
    sudo -u postgres psql << EOF
CREATE DATABASE ipv6wgm;
CREATE USER ipv6wgm WITH PASSWORD 'password';
GRANT ALL PRIVILEGES ON DATABASE ipv6wgm TO ipv6wgm;
\q
EOF
    
    # 启动Redis
    case $OS in
        ubuntu|debian|centos|rhel|fedora)
            sudo systemctl start redis
            sudo systemctl enable redis
            ;;
        alpine)
            sudo rc-update add redis
            sudo service redis start
            ;;
    esac
    
    echo "✅ 数据库配置完成"
}

# 快速配置Nginx
setup_nginx() {
    echo "🌐 配置Nginx..."
    
    # 创建简化的Nginx配置
    sudo tee /etc/nginx/sites-available/ipv6-wireguard-manager > /dev/null << EOF
server {
    listen 80;
    server_name _;
    
    # 前端静态文件
    location / {
        root $APP_HOME/frontend/dist;
        try_files \$uri \$uri/ /index.html;
    }
    
    # 后端API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    
    # WebSocket代理
    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF
    
    # 启用站点
    if [ -d /etc/nginx/sites-enabled ]; then
        sudo ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
        sudo rm -f /etc/nginx/sites-enabled/default
    else
        sudo cp /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/conf.d/ipv6-wireguard-manager.conf
    fi
    
    # 测试配置
    sudo nginx -t
    
    # 启动Nginx
    case $OS in
        ubuntu|debian|centos|rhel|fedora)
            sudo systemctl start nginx
            sudo systemctl enable nginx
            ;;
        alpine)
            sudo rc-update add nginx
            sudo service nginx start
            ;;
    esac
    
    echo "✅ Nginx配置完成"
}

# 创建简化的systemd服务
create_systemd_service() {
    echo "⚙️  创建systemd服务..."
    
    sudo tee /etc/systemd/system/ipv6-wireguard-manager.service > /dev/null << EOF
[Unit]
Description=IPv6 WireGuard Manager
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_HOME/backend
Environment=PATH=$APP_HOME/backend/venv/bin
ExecStart=$APP_HOME/backend/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 1
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    # 启动服务
    sudo systemctl daemon-reload
    sudo systemctl enable ipv6-wireguard-manager
    sudo systemctl start ipv6-wireguard-manager
    
    echo "✅ systemd服务创建完成"
}

# 设置权限
setup_permissions() {
    echo "🔐 设置权限..."
    
    # 移动应用到系统目录
    sudo mv "$INSTALL_DIR" "$APP_HOME"
    sudo chown -R "$APP_USER:$APP_USER" "$APP_HOME"
    
    # 设置目录权限
    sudo chmod 755 "$APP_HOME"
    sudo chmod -R 644 "$APP_HOME"/*
    sudo chmod -R 755 "$APP_HOME"/backend/venv
    sudo chmod -R 755 "$APP_HOME"/frontend/dist
    
    echo "✅ 权限设置完成"
}

# 快速初始化数据库
init_database() {
    echo "🗄️  初始化数据库..."
    
    cd "$APP_HOME/backend"
    source venv/bin/activate
    
    # 运行数据库迁移
    python -c "
from app.core.database import engine
from app.models import Base
Base.metadata.create_all(bind=engine)
print('数据库表创建完成')
"
    
    # 初始化默认数据
    python -c "
from app.core.init_db import init_db
init_db()
print('默认数据初始化完成')
"
    
    echo "✅ 数据库初始化完成"
}

# 验证安装
verify_installation() {
    echo "🔍 验证安装..."
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    if sudo systemctl is-active --quiet ipv6-wireguard-manager; then
        echo "✅ 后端服务运行正常"
    else
        echo "❌ 后端服务异常"
        sudo systemctl status ipv6-wireguard-manager
    fi
    
    if sudo systemctl is-active --quiet nginx; then
        echo "✅ Nginx服务运行正常"
    else
        echo "❌ Nginx服务异常"
        sudo systemctl status nginx
    fi
    
    # 测试HTTP访问
    if curl -s "http://localhost" >/dev/null 2>&1; then
        echo "✅ Web服务访问正常"
    else
        echo "❌ Web服务访问异常"
    fi
}

# 显示安装结果
show_result() {
    echo ""
    echo "=================================="
    echo "🎉 VPS快速安装完成！"
    echo "=================================="
    echo ""
    echo "📋 访问信息："
    echo "   IPv4访问地址："
    if [ -n "$SERVER_IPV4" ] && [ "$SERVER_IPV4" != "localhost" ]; then
        echo "     - 前端界面: http://$SERVER_IPV4"
        echo "     - 后端API: http://$SERVER_IPV4/api"
        echo "     - API文档: http://$SERVER_IPV4/api/docs"
    else
        echo "     - 前端界面: http://localhost"
        echo "     - 后端API: http://localhost/api"
        echo "     - API文档: http://localhost/api/docs"
    fi
    
    if [ -n "$SERVER_IPV6" ]; then
        echo "   IPv6访问地址："
        echo "     - 前端界面: http://[$SERVER_IPV6]"
        echo "     - 后端API: http://[$SERVER_IPV6]/api"
        echo "     - API文档: http://[$SERVER_IPV6]/api/docs"
    fi
    echo ""
    echo "🔑 默认登录信息："
    echo "   用户名: admin"
    echo "   密码: admin123"
    echo ""
    echo "🛠️  管理命令："
    echo "   查看状态: sudo systemctl status ipv6-wireguard-manager"
    echo "   查看日志: sudo journalctl -u ipv6-wireguard-manager -f"
    echo "   重启服务: sudo systemctl restart ipv6-wireguard-manager"
    echo ""
    echo "📁 安装位置："
    echo "   应用目录: $APP_HOME"
    echo "   配置文件: $APP_HOME/backend/.env"
    echo ""
    echo "💡 VPS优化特性："
    echo "   - 单进程运行，减少内存占用"
    echo "   - 最小化依赖安装"
    echo "   - 优化的Nginx配置"
    echo "   - 自动开机启动"
    echo "   - 无需用户交互"
    echo ""
}

# 主函数
main() {
    echo "🚀 开始VPS快速安装..."
    echo "   安装方式: 原生安装（VPS优化）"
    echo "   无需用户交互，自动完成所有配置"
    echo ""
    
    # 检测IP地址
    get_server_ip
    
    # 检测操作系统
    detect_os
    
    # 安装最小化依赖
    install_minimal_dependencies
    
    # 创建应用用户
    create_app_user
    
    # 下载项目
    download_project
    
    # 安装后端
    install_backend
    
    # 安装前端
    install_frontend
    
    # 配置数据库
    setup_database
    
    # 配置Nginx
    setup_nginx
    
    # 创建systemd服务
    create_systemd_service
    
    # 设置权限
    setup_permissions
    
    # 初始化数据库
    init_database
    
    # 验证安装
    verify_installation
    
    # 显示结果
    show_result
}

# 运行主函数
main "$@"
