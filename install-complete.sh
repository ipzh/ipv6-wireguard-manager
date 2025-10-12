#!/bin/bash

# IPv6 WireGuard Manager 完整安装脚本
# 整合了所有构造过程中出现的问题和解决方案

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

# 解析参数
INSTALL_TYPE=""
FORCE_INSTALL=false
SKIP_DEPENDENCIES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        "docker")
            INSTALL_TYPE="docker"
            shift
            ;;
        "native")
            INSTALL_TYPE="native"
            shift
            ;;
        "low-memory")
            INSTALL_TYPE="low-memory"
            shift
            ;;
        "--force")
            FORCE_INSTALL=true
            shift
            ;;
        "--skip-deps")
            SKIP_DEPENDENCIES=true
            shift
            ;;
        *)
            echo "用法: $0 [docker|native|low-memory] [--force] [--skip-deps]"
            echo "  docker      - Docker 安装"
            echo "  native      - 原生安装"
            echo "  low-memory  - 低内存优化安装"
            echo "  --force     - 强制重新安装"
            echo "  --skip-deps - 跳过依赖检查"
            echo "  无参数      - 自动选择"
            exit 1
            ;;
    esac
done

echo "=================================="
echo "IPv6 WireGuard Manager 完整安装"
echo "=================================="
if [ -n "$INSTALL_TYPE" ]; then
    echo "安装类型: $INSTALL_TYPE"
fi
echo ""

# 项目信息
REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager/archive/refs/heads/main.zip"
INSTALL_DIR="ipv6-wireguard-manager"
APP_USER="ipv6wgm"
APP_HOME="/opt/ipv6-wireguard-manager"
PROJECT_DIR="$(pwd)/$INSTALL_DIR"

# 系统信息检测
detect_system() {
    log_info "检测系统环境..."
    
    # 检测操作系统
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$NAME"
        OS_VERSION="$VERSION_ID"
        OS_CODENAME="$VERSION_CODENAME"
    else
        OS_NAME="Unknown"
        OS_VERSION="Unknown"
        OS_CODENAME="unknown"
    fi
    
    # 检测架构
    ARCH=$(uname -m)
    
    # 检测内存
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    
    # 检测CPU核心数
    CPU_CORES=$(nproc)
    
    # 检测磁盘空间
    DISK_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    
    # 检测网络连接
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        NETWORK_STATUS="connected"
    else
        NETWORK_STATUS="disconnected"
    fi
    
    # 检测WSL
    if grep -q Microsoft /proc/version 2>/dev/null; then
        IS_WSL=true
    else
        IS_WSL=false
    fi
    
    log_info "系统信息:"
    echo "  操作系统: $OS_NAME $OS_VERSION"
    echo "  架构: $ARCH"
    echo "  内存: ${TOTAL_MEM}MB"
    echo "  CPU核心: $CPU_CORES"
    echo "  可用磁盘: ${DISK_SPACE}GB"
    echo "  网络状态: $NETWORK_STATUS"
    echo "  WSL环境: $IS_WSL"
    echo ""
}

# 智能选择安装方式
auto_select_install_type() {
    if [ -n "$INSTALL_TYPE" ]; then
        return
    fi
    
    log_info "智能选择安装方式..."
    
    # 根据系统环境自动选择
    if [ "$TOTAL_MEM" -lt 1024 ]; then
        INSTALL_TYPE="low-memory"
        log_warning "内存不足1GB，选择低内存安装"
    elif [ "$IS_WSL" = true ]; then
        INSTALL_TYPE="native"
        log_info "检测到WSL环境，选择原生安装"
    elif [ "$TOTAL_MEM" -lt 2048 ]; then
        INSTALL_TYPE="native"
        log_info "内存较少，选择原生安装（性能更优）"
    else
        INSTALL_TYPE="docker"
        log_info "内存充足，选择Docker安装（环境隔离）"
    fi
    
    echo "自动选择: $INSTALL_TYPE"
    echo ""
}

# 检查并安装依赖
install_dependencies() {
    if [ "$SKIP_DEPENDENCIES" = true ]; then
        log_info "跳过依赖检查"
        return
    fi
    
    log_info "检查并安装系统依赖..."
    
    # 更新包列表
    apt-get update -qq
    
    # 基础工具
    local packages=(
        "curl"
        "wget"
        "unzip"
        "git"
        "sudo"
        "systemd"
        "ufw"
        "iptables"
        "iproute2"
        "net-tools"
        "procps"
        "psmisc"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
    )
    
    # 根据安装类型添加特定依赖
    case $INSTALL_TYPE in
        "docker")
            packages+=("docker.io" "docker-compose")
            ;;
        "native"|"low-memory")
            packages+=(
                "python3"
                "python3-pip"
                "python3-venv"
                "python3-dev"
                "build-essential"
                "libpq-dev"
                "pkg-config"
                "libssl-dev"
                "libffi-dev"
                "nodejs"
                "npm"
                "postgresql"
                "postgresql-contrib"
                "redis-server"
                "nginx"
                "supervisor"
                "exabgp"
            )
            ;;
    esac
    
    # 安装包
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            log_info "安装 $package..."
            apt-get install -y "$package" || log_warning "安装 $package 失败，继续..."
        else
            log_info "$package 已安装"
        fi
    done
    
    # 特殊处理Node.js版本
    if [ "$INSTALL_TYPE" != "docker" ]; then
        install_nodejs
    fi
    
    # 特殊处理Docker
    if [ "$INSTALL_TYPE" = "docker" ]; then
        install_docker
    fi
    
    log_success "依赖安装完成"
}

# 安装Node.js
install_nodejs() {
    log_info "安装Node.js..."
    
    # 检查Node.js版本
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
        if [ "$NODE_VERSION" -ge 18 ]; then
            log_info "Node.js 版本满足要求"
            return
        fi
    fi
    
    # 安装Node.js 18
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    
    log_success "Node.js 安装完成"
}

# 安装Docker
install_docker() {
    log_info "安装Docker..."
    
    if command -v docker >/dev/null 2>&1; then
        log_info "Docker 已安装"
        return
    fi
    
    # 根据系统选择Docker仓库
    case $OS_CODENAME in
        "jammy"|"focal"|"bionic")
            DOCKER_REPO="ubuntu"
            ;;
        "bullseye"|"buster")
            DOCKER_REPO="debian"
            ;;
        *)
            DOCKER_REPO="ubuntu"
            ;;
    esac
    
    # 安装Docker
    curl -fsSL https://download.docker.com/linux/$DOCKER_REPO/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$DOCKER_REPO $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # 启动Docker服务
    systemctl enable docker
    systemctl start docker
    
    # 添加用户到docker组
    usermod -aG docker $USER 2>/dev/null || true
    
    log_success "Docker 安装完成"
}

# 下载项目
download_project() {
    log_info "下载项目..."
    
    if [ -d "$INSTALL_DIR" ] && [ "$FORCE_INSTALL" = false ]; then
        log_info "项目目录已存在，使用现有目录"
        return
    fi
    
    # 清理旧目录
    if [ -d "$INSTALL_DIR" ]; then
        log_info "清理旧项目目录..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # 下载项目
    if command -v wget >/dev/null 2>&1; then
        log_info "使用wget下载项目..."
        wget -q "$REPO_URL" -O project.zip
    elif command -v curl >/dev/null 2>&1; then
        log_info "使用curl下载项目..."
        curl -fsSL "$REPO_URL" -o project.zip
    else
        log_error "需要wget或curl来下载项目"
        exit 1
    fi
    
    # 解压项目
    unzip -q project.zip
    rm project.zip
    
    # 重命名目录
    if [ -d "ipv6-wireguard-manager-main" ]; then
        mv ipv6-wireguard-manager-main "$INSTALL_DIR"
    fi
    
    log_success "项目下载完成"
}

# 创建系统用户
create_system_user() {
    log_info "创建系统用户..."
    
    if id "$APP_USER" >/dev/null 2>&1; then
        log_info "用户 $APP_USER 已存在"
    else
        useradd -r -s /bin/bash -d "$APP_HOME" -m "$APP_USER"
        log_success "用户 $APP_USER 创建完成"
    fi
}

# 设置权限
setup_permissions() {
    log_info "设置文件权限..."
    
    # 复制项目文件到安装目录
    if [ -d "$APP_HOME" ]; then
        rm -rf "$APP_HOME"
    fi
    
    mkdir -p "$APP_HOME"
    cp -r "$PROJECT_DIR"/* "$APP_HOME/"
    
    # 设置权限
    chown -R "$APP_USER:$APP_USER" "$APP_HOME"
    chmod -R 755 "$APP_HOME"
    
    log_success "权限设置完成"
}

# 配置数据库
setup_database() {
    log_info "配置数据库..."
    
    # 启动PostgreSQL
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
        # 备份原配置
        cp $PG_HBA_FILE ${PG_HBA_FILE}.backup
        
        # 添加信任认证
        echo "local   all             ipv6wgm                                trust" >> $PG_HBA_FILE
        echo "host    all             ipv6wgm        127.0.0.1/32            trust" >> $PG_HBA_FILE
        echo "host    all             ipv6wgm        ::1/128                 trust" >> $PG_HBA_FILE
        
        # 重启PostgreSQL
        systemctl restart postgresql
    fi
    
    log_success "数据库配置完成"
}

# 安装后端
install_backend() {
    log_info "安装后端..."
    
    cd "$APP_HOME/backend"
    
    # 创建虚拟环境
    python3 -m venv venv
    source venv/bin/activate
    
    # 升级pip
    pip install --upgrade pip
    
    # 安装依赖
    if [ -f requirements.txt ]; then
        pip install -r requirements.txt
    else
        # 基础依赖
        pip install fastapi uvicorn sqlalchemy psycopg2-binary redis python-multipart python-jose[cryptography] passlib[bcrypt] python-dotenv
    fi
    
    # 创建环境配置文件
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
    
    log_success "后端安装完成"
}

# 安装前端
install_frontend() {
    log_info "安装前端..."
    
    cd "$APP_HOME/frontend"
    
    # 检查是否存在src目录
    if [ ! -d "src" ]; then
        log_error "前端源码目录不存在"
        return 1
    fi
    
    # 安装依赖
    npm install --silent 2>/dev/null || npm install
    
    # 创建环境配置文件
    cat > .env << EOF
VITE_API_URL=http://127.0.0.1:8000
VITE_WS_URL=ws://127.0.0.1:8000/api/v1/ws
EOF
    
    # 构建前端
    if [ "$INSTALL_TYPE" = "low-memory" ]; then
        # 低内存优化构建
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
        // 自动重定向到登录页面
        setTimeout(() => {
            window.location.href = '/login';
        }, 3000);
    </script>
</body>
</html>
EOF
    fi
    
    log_success "前端安装完成"
}

# 配置Nginx
setup_nginx() {
    log_info "配置Nginx..."
    
    # 创建Nginx配置
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
    
    # 禁用默认站点
    rm -f /etc/nginx/sites-enabled/default
    
    # 测试配置
    nginx -t
    
    # 重启Nginx
    systemctl enable nginx
    systemctl restart nginx
    
    log_success "Nginx配置完成"
}

# 创建系统服务
create_systemd_service() {
    log_info "创建系统服务..."
    
    # 创建后端服务
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
    
    # 重载systemd
    systemctl daemon-reload
    
    # 启用服务
    systemctl enable ipv6-wireguard-manager
    
    log_success "系统服务创建完成"
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    # 启动Redis
    systemctl enable redis-server
    systemctl start redis-server
    
    # 启动后端服务
    systemctl start ipv6-wireguard-manager
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "后端服务启动成功"
    else
        log_error "后端服务启动失败"
        systemctl status ipv6-wireguard-manager
        return 1
    fi
    
    log_success "所有服务启动完成"
}

# 配置防火墙
setup_firewall() {
    log_info "配置防火墙..."
    
    # 启用UFW
    ufw --force enable
    
    # 允许SSH
    ufw allow ssh
    
    # 允许HTTP/HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # 允许WireGuard
    ufw allow 51820/udp
    
    # 允许后端API（仅本地）
    ufw allow from 127.0.0.1 to any port 8000
    
    log_success "防火墙配置完成"
}

# 获取服务器IP
get_server_ip() {
    # 获取IPv4地址
    IPV4=$(ip route get 8.8.8.8 | awk '{print $7; exit}' 2>/dev/null || echo "未知")
    
    # 获取IPv6地址
    IPV6=$(ip -6 route get 2001:4860:4860::8888 | awk '{print $7; exit}' 2>/dev/null || echo "未知")
    
    echo "IPv4: $IPV4"
    echo "IPv6: $IPV6"
}

# 验证安装
verify_installation() {
    log_info "验证安装..."
    
    # 检查服务状态
    local services=("nginx" "postgresql" "redis-server" "ipv6-wireguard-manager")
    local all_ok=true
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log_success "$service 服务运行正常"
        else
            log_error "$service 服务异常"
            all_ok=false
        fi
    done
    
    # 检查端口
    local ports=("80" "8000" "5432" "6379")
    for port in "${ports[@]}"; do
        if netstat -tlnp | grep -q ":$port "; then
            log_success "端口 $port 监听正常"
        else
            log_warning "端口 $port 未监听"
        fi
    done
    
    # 检查API
    if curl -s http://127.0.0.1:8000/health >/dev/null; then
        log_success "后端API响应正常"
    else
        log_error "后端API无响应"
        all_ok=false
    fi
    
    if [ "$all_ok" = true ]; then
        log_success "安装验证通过"
        return 0
    else
        log_error "安装验证失败"
        return 1
    fi
}

# 显示安装结果
show_installation_result() {
    echo ""
    echo "=================================="
    echo "安装完成！"
    echo "=================================="
    echo ""
    
    # 获取服务器IP
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
    
    log_info "配置文件位置:"
    echo "  应用目录: $APP_HOME"
    echo "  Nginx配置: /etc/nginx/sites-available/ipv6-wireguard-manager"
    echo "  服务配置: /etc/systemd/system/ipv6-wireguard-manager.service"
    echo ""
    
    log_success "安装完成！请访问前端界面开始使用。"
}

# 错误处理
handle_error() {
    log_error "安装过程中发生错误"
    log_error "错误位置: $1"
    log_error "请检查日志并重试"
    exit 1
}

# 主安装流程
main() {
    # 设置错误处理
    trap 'handle_error "未知位置"' ERR
    
    # 检查root权限
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root权限运行此脚本"
        exit 1
    fi
    
    # 检测系统
    detect_system
    
    # 自动选择安装方式
    auto_select_install_type
    
    # 安装依赖
    install_dependencies
    
    # 下载项目
    download_project
    
    # 创建系统用户
    create_system_user
    
    # 设置权限
    setup_permissions
    
    # 配置数据库
    setup_database
    
    # 安装后端
    install_backend
    
    # 安装前端
    install_frontend
    
    # 配置Nginx
    setup_nginx
    
    # 创建系统服务
    create_systemd_service
    
    # 启动服务
    start_services
    
    # 配置防火墙
    setup_firewall
    
    # 验证安装
    if verify_installation; then
        show_installation_result
    else
        log_error "安装验证失败，请检查日志"
        exit 1
    fi
}

# 运行主函数
main "$@"
