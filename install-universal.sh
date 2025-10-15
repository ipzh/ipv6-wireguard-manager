#!/bin/bash

# IPv6 WireGuard Manager 通用安装脚本
# 支持所有主流Linux发行版

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# 默认配置
INSTALL_DIR="/opt/ipv6-wireguard-manager"
INSTALL_TYPE="auto"
SERVICE_USER="ipv6wgm"
SERVICE_GROUP="ipv6wgm"
PYTHON_VERSION="3.11"
NODE_VERSION="18"
POSTGRES_VERSION="15"
REDIS_VERSION="7"

# 系统信息
OS_ID=""
OS_VERSION=""
PACKAGE_MANAGER=""
ARCH=""

# 显示帮助信息
show_help() {
    cat << EOF
IPv6 WireGuard Manager 通用安装脚本

用法: $0 [选项]

选项:
    -d, --dir DIR           安装目录 (默认: /opt/ipv6-wireguard-manager)
    -t, --type TYPE         安装类型 (auto|native|docker|minimal)
    -u, --user USER         服务用户 (默认: ipv6wgm)
    -g, --group GROUP       服务组 (默认: ipv6wgm)
    -p, --python VERSION    Python版本 (默认: 3.11)
    -n, --node VERSION      Node.js版本 (默认: 18)
    --postgres VERSION      PostgreSQL版本 (默认: 15)
    --redis VERSION         Redis版本 (默认: 7)
    --skip-deps            跳过依赖安装
    --skip-db              跳过数据库安装
    --skip-service         跳过服务安装
    --help                 显示此帮助信息

安装类型:
    auto      自动检测最佳安装方式
    native    原生安装 (推荐)
    docker    Docker安装
    minimal   最小化安装 (仅核心功能)

支持的发行版:
    Ubuntu 20.04+, Debian 11+, CentOS 8+, RHEL 8+, 
    Fedora 38+, Arch Linux, openSUSE 15+

示例:
    $0                                    # 自动安装
    $0 -t native -d /opt/my-app          # 原生安装到指定目录
    $0 -t docker                         # Docker安装
    $0 -t minimal --skip-db              # 最小化安装，跳过数据库
EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            -t|--type)
                INSTALL_TYPE="$2"
                shift 2
                ;;
            -u|--user)
                SERVICE_USER="$2"
                shift 2
                ;;
            -g|--group)
                SERVICE_GROUP="$2"
                shift 2
                ;;
            -p|--python)
                PYTHON_VERSION="$2"
                shift 2
                ;;
            -n|--node)
                NODE_VERSION="$2"
                shift 2
                ;;
            --postgres)
                POSTGRES_VERSION="$2"
                shift 2
                ;;
            --redis)
                REDIS_VERSION="$2"
                shift 2
                ;;
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --skip-db)
                SKIP_DB=true
                shift
                ;;
            --skip-service)
                SKIP_SERVICE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检测系统信息
detect_system() {
    log_info "检测系统信息..."
    
    # 检查操作系统
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_ID="$ID"
        OS_VERSION="$VERSION_ID"
    else
        log_error "不支持的操作系统：缺少 /etc/os-release 文件"
        exit 1
    fi
    
    # 检测架构
    ARCH=$(uname -m)
    
    # 检测包管理器
    if command -v apt-get &> /dev/null; then
        PACKAGE_MANAGER="apt"
    elif command -v yum &> /dev/null; then
        PACKAGE_MANAGER="yum"
    elif command -v dnf &> /dev/null; then
        PACKAGE_MANAGER="dnf"
    elif command -v pacman &> /dev/null; then
        PACKAGE_MANAGER="pacman"
    elif command -v zypper &> /dev/null; then
        PACKAGE_MANAGER="zypper"
    else
        log_error "未检测到支持的包管理器"
        exit 1
    fi
    
    log_success "系统信息:"
    log_info "  操作系统: $PRETTY_NAME"
    log_info "  版本: $VERSION_ID"
    log_info "  架构: $ARCH"
    log_info "  包管理器: $PACKAGE_MANAGER"
}

# 检查系统要求
check_requirements() {
    log_info "检查系统要求..."
    
    # 检查内存
    local memory_mb=$(free -m | awk 'NR==2{print $2}')
    if [ "$memory_mb" -lt 512 ]; then
        log_error "系统内存不足，至少需要512MB"
        exit 1
    fi
    
    # 检查磁盘空间
    local disk_space=$(df / | awk 'NR==2{print $4}')
    local disk_space_mb=$((disk_space / 1024))
    if [ "$disk_space_mb" -lt 1024 ]; then
        log_error "磁盘空间不足，至少需要1GB"
        exit 1
    fi
    
    # 检查网络连接
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log_warning "网络连接可能有问题"
    fi
    
    log_success "系统要求检查通过"
}

# 安装系统依赖
install_system_dependencies() {
    if [[ "$SKIP_DEPS" == true ]]; then
        log_info "跳过系统依赖安装"
        return
    fi
    
    log_info "安装系统依赖..."
    
    case $PACKAGE_MANAGER in
        "apt")
            install_deps_apt
            ;;
        "yum")
            install_deps_yum
            ;;
        "dnf")
            install_deps_dnf
            ;;
        "pacman")
            install_deps_pacman
            ;;
        "zypper")
            install_deps_zypper
            ;;
    esac
}

# APT系统安装依赖
install_deps_apt() {
    log_info "使用APT安装依赖..."
    
    # 更新包列表
    apt-get update -y
    
    # 安装基础依赖
    apt-get install -y \
        curl \
        wget \
        git \
        unzip \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        build-essential \
        libpq-dev \
        python3-dev \
        libffi-dev \
        libssl-dev
    
    # 安装Python
    if ! command -v python$PYTHON_VERSION &> /dev/null; then
        add-apt-repository ppa:deadsnakes/ppa -y
        apt-get update
        apt-get install -y python$PYTHON_VERSION python$PYTHON_VERSION-venv python$PYTHON_VERSION-dev
    fi
    
    # 安装Node.js
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
        apt-get install -y nodejs
    fi
    
    # 安装PostgreSQL
    if [[ "$SKIP_DB" != true ]]; then
        if ! command -v psql &> /dev/null; then
            apt-get install -y postgresql-$POSTGRES_VERSION postgresql-contrib-$POSTGRES_VERSION
        fi
    fi
    
    # 安装Redis
    if ! command -v redis-server &> /dev/null; then
        apt-get install -y redis-server
    fi
    
    # 安装Nginx
    if ! command -v nginx &> /dev/null; then
        apt-get install -y nginx
    fi
    
    # 安装WireGuard
    if ! command -v wg &> /dev/null; then
        apt-get install -y wireguard
    fi
}

# YUM系统安装依赖
install_deps_yum() {
    log_info "使用YUM安装依赖..."
    
    # 更新包列表
    yum update -y
    
    # 安装EPEL仓库
    yum install -y epel-release
    
    # 安装基础依赖
    yum install -y \
        curl \
        wget \
        git \
        unzip \
        ca-certificates \
        gcc \
        gcc-c++ \
        make \
        postgresql-devel \
        python3-devel \
        libffi-devel \
        openssl-devel
    
    # 安装Python
    if ! command -v python3 &> /dev/null; then
        yum install -y python3 python3-pip python3-devel
    fi
    
    # 安装Node.js
    if ! command -v node &> /dev/null; then
        curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash -
        yum install -y nodejs
    fi
    
    # 安装PostgreSQL
    if [[ "$SKIP_DB" != true ]]; then
        if ! command -v psql &> /dev/null; then
            yum install -y postgresql-server postgresql-contrib
        fi
    fi
    
    # 安装Redis
    if ! command -v redis-server &> /dev/null; then
        yum install -y redis
    fi
    
    # 安装Nginx
    if ! command -v nginx &> /dev/null; then
        yum install -y nginx
    fi
    
    # 安装WireGuard
    if ! command -v wg &> /dev/null; then
        yum install -y wireguard-tools
    fi
}

# DNF系统安装依赖
install_deps_dnf() {
    log_info "使用DNF安装依赖..."
    
    # 更新包列表
    dnf update -y
    
    # 安装基础依赖
    dnf install -y \
        curl \
        wget \
        git \
        unzip \
        ca-certificates \
        gcc \
        gcc-c++ \
        make \
        postgresql-devel \
        python3-devel \
        libffi-devel \
        openssl-devel
    
    # 安装Python
    if ! command -v python3 &> /dev/null; then
        dnf install -y python3 python3-pip python3-devel
    fi
    
    # 安装Node.js
    if ! command -v node &> /dev/null; then
        curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash -
        dnf install -y nodejs
    fi
    
    # 安装PostgreSQL
    if [[ "$SKIP_DB" != true ]]; then
        if ! command -v psql &> /dev/null; then
            dnf install -y postgresql-server postgresql-contrib
        fi
    fi
    
    # 安装Redis
    if ! command -v redis-server &> /dev/null; then
        dnf install -y redis
    fi
    
    # 安装Nginx
    if ! command -v nginx &> /dev/null; then
        dnf install -y nginx
    fi
    
    # 安装WireGuard
    if ! command -v wg &> /dev/null; then
        dnf install -y wireguard-tools
    fi
}

# Pacman系统安装依赖
install_deps_pacman() {
    log_info "使用Pacman安装依赖..."
    
    # 更新包列表
    pacman -Sy
    
    # 安装基础依赖
    pacman -S --noconfirm \
        curl \
        wget \
        git \
        unzip \
        ca-certificates \
        base-devel \
        postgresql-libs \
        libffi \
        openssl
    
    # 安装Python
    if ! command -v python &> /dev/null; then
        pacman -S --noconfirm python python-pip
    fi
    
    # 安装Node.js
    if ! command -v node &> /dev/null; then
        pacman -S --noconfirm nodejs npm
    fi
    
    # 安装PostgreSQL
    if [[ "$SKIP_DB" != true ]]; then
        if ! command -v psql &> /dev/null; then
            pacman -S --noconfirm postgresql
        fi
    fi
    
    # 安装Redis
    if ! command -v redis-server &> /dev/null; then
        pacman -S --noconfirm redis
    fi
    
    # 安装Nginx
    if ! command -v nginx &> /dev/null; then
        pacman -S --noconfirm nginx
    fi
    
    # 安装WireGuard
    if ! command -v wg &> /dev/null; then
        pacman -S --noconfirm wireguard-tools
    fi
}

# Zypper系统安装依赖
install_deps_zypper() {
    log_info "使用Zypper安装依赖..."
    
    # 更新包列表
    zypper refresh
    
    # 安装基础依赖
    zypper install -y \
        curl \
        wget \
        git \
        unzip \
        ca-certificates \
        patterns-devel-C-C++ \
        postgresql-devel \
        python3-devel \
        libffi-devel \
        openssl-devel
    
    # 安装Python
    if ! command -v python3 &> /dev/null; then
        zypper install -y python3 python3-pip python3-devel
    fi
    
    # 安装Node.js
    if ! command -v node &> /dev/null; then
        curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash -
        zypper install -y nodejs
    fi
    
    # 安装PostgreSQL
    if [[ "$SKIP_DB" != true ]]; then
        if ! command -v psql &> /dev/null; then
            zypper install -y postgresql-server postgresql-contrib
        fi
    fi
    
    # 安装Redis
    if ! command -v redis-server &> /dev/null; then
        zypper install -y redis
    fi
    
    # 安装Nginx
    if ! command -v nginx &> /dev/null; then
        zypper install -y nginx
    fi
    
    # 安装WireGuard
    if ! command -v wg &> /dev/null; then
        zypper install -y wireguard-tools
    fi
}

# 创建服务用户
create_service_user() {
    log_info "创建服务用户..."
    
    if ! id "$SERVICE_USER" &>/dev/null; then
        useradd -r -s /bin/false -d "$INSTALL_DIR" "$SERVICE_USER"
        log_success "创建用户: $SERVICE_USER"
    else
        log_info "用户已存在: $SERVICE_USER"
    fi
    
    if ! getent group "$SERVICE_GROUP" &>/dev/null; then
        groupadd -r "$SERVICE_GROUP"
        log_success "创建组: $SERVICE_GROUP"
    else
        log_info "组已存在: $SERVICE_GROUP"
    fi
    
    usermod -a -G "$SERVICE_GROUP" "$SERVICE_USER"
}

# 下载和安装应用
install_application() {
    log_info "安装应用程序..."
    
    # 创建安装目录
    mkdir -p "$INSTALL_DIR"
    
    # 下载源码
    if [[ -d ".git" ]]; then
        log_info "使用当前目录的源码"
        cp -r . "$INSTALL_DIR/"
    else
        log_info "下载源码..."
        # 重装时总是重新下载最新代码，不保留旧版本
        if [[ -d "$INSTALL_DIR" && "$(ls -A $INSTALL_DIR 2>/dev/null)" ]]; then
            log_info "目录已存在，备份并重新下载最新代码..."
            mv "$INSTALL_DIR" "$INSTALL_DIR.backup.$(date +%s)"
        fi
        # 直接克隆最新代码
        git clone https://github.com/ipzh/ipv6-wireguard-manager.git "$INSTALL_DIR"
    fi
    
    # 设置权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    
    # 安装后端依赖
    log_info "安装后端依赖..."
    cd "$INSTALL_DIR/backend"
    
    # 检查并安装python3-venv包（如果尚未安装）
    if ! python$PYTHON_VERSION -c "import ensurepip" 2>/dev/null; then
        log_info "安装python3-venv包..."
        case $PACKAGE_MANAGER in
            "apt")
                apt-get install -y python$PYTHON_VERSION-venv
                ;;
            "yum"|"dnf")
                $PACKAGE_MANAGER install -y python$PYTHON_VERSION-venv
                ;;
            "pacman")
                pacman -S --noconfirm python-pip
                ;;
            "zypper")
                zypper install -y python3-pip
                ;;
        esac
    fi
    
    # 创建虚拟环境
    python$PYTHON_VERSION -m venv venv
    source venv/bin/activate
    
    # 安装Python依赖
    pip install --upgrade pip
    pip install -r requirements.txt
    
    # 安装前端依赖
    log_info "安装前端依赖..."
    cd "$INSTALL_DIR/frontend"
    npm install
    
    # 构建前端
    log_info "构建前端..."
    npm run build
    
    log_success "应用程序安装完成"
}

# 配置数据库
configure_database() {
    if [[ "$SKIP_DB" == true ]]; then
        log_info "跳过数据库配置"
        return
    fi
    
    log_info "配置数据库..."
    
    # 启动PostgreSQL
    systemctl enable postgresql
    systemctl start postgresql
    
    # 创建数据库和用户
    sudo -u postgres psql -c "CREATE DATABASE ipv6wgm;" 2>/dev/null || true
    sudo -u postgres psql -c "CREATE USER ipv6wgm WITH PASSWORD 'password';" 2>/dev/null || true
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ipv6wgm TO ipv6wgm;" 2>/dev/null || true
    
    # 启动Redis
    systemctl enable redis
    systemctl start redis
    
    log_success "数据库配置完成"
}

# 配置Nginx
configure_nginx() {
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
        try_files $uri $uri/ /index.html;
    }
    
    # 后端API
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # WebSocket支持
    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
    
    # 启用站点
    ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
    
    # 测试配置
    nginx -t
    
    # 重启Nginx
    systemctl enable nginx
    systemctl restart nginx
    
    log_success "Nginx配置完成"
}

# 创建系统服务
create_system_service() {
    if [[ "$SKIP_SERVICE" == true ]]; then
        log_info "跳过系统服务创建"
        return
    fi
    
    log_info "创建系统服务..."
    
    # 创建systemd服务文件
    cat > /etc/systemd/system/ipv6-wireguard-manager.service << EOF
[Unit]
Description=IPv6 WireGuard Manager
After=network.target postgresql.service redis.service
Wants=postgresql.service redis.service

[Service]
Type=exec
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$INSTALL_DIR/backend
Environment=PATH=$INSTALL_DIR/backend/venv/bin
ExecStart=$INSTALL_DIR/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载systemd
    systemctl daemon-reload
    
    # 启用服务
    systemctl enable ipv6-wireguard-manager
    
    log_success "系统服务创建完成"
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    # 启动应用服务
    systemctl start ipv6-wireguard-manager
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "服务启动成功"
    else
        log_error "服务启动失败"
        systemctl status ipv6-wireguard-manager
        exit 1
    fi
}

# 验证安装
verify_installation() {
    log_info "验证安装..."
    
    # 检查服务状态
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "应用服务运行正常"
    else
        log_error "应用服务未运行"
        return 1
    fi
    
    # 检查端口监听
    if netstat -tuln | grep -q ":8000 "; then
        log_success "后端端口8000监听正常"
    else
        log_error "后端端口8000未监听"
        return 1
    fi
    
    if netstat -tuln | grep -q ":80 "; then
        log_success "前端端口80监听正常"
    else
        log_error "前端端口80未监听"
        return 1
    fi
    
    # 测试API连接
    if curl -f http://localhost:8000/health &> /dev/null; then
        log_success "API连接正常"
    else
        log_warning "API连接测试失败"
    fi
    
    # 测试前端访问
    if curl -f http://localhost/ &> /dev/null; then
        log_success "前端访问正常"
    else
        log_warning "前端访问测试失败"
    fi
    
    log_success "安装验证完成"
}

# 显示安装信息
show_installation_info() {
    echo ""
    echo "=========================================="
    echo "✅ IPv6 WireGuard Manager 安装完成！"
    echo "=========================================="
    echo ""
    echo "📋 安装信息："
    echo "  安装目录: $INSTALL_DIR"
    echo "  服务用户: $SERVICE_USER"
    echo "  操作系统: $PRETTY_NAME"
    echo "  包管理器: $PACKAGE_MANAGER"
    echo ""
    echo "🌐 访问地址："
    echo "  前端界面: http://localhost"
    echo "  API文档: http://localhost/api/v1/docs"
    echo "  健康检查: http://localhost:8000/health"
    echo ""
    echo "🔧 管理命令："
    echo "  启动服务: systemctl start ipv6-wireguard-manager"
    echo "  停止服务: systemctl stop ipv6-wireguard-manager"
    echo "  重启服务: systemctl restart ipv6-wireguard-manager"
    echo "  查看状态: systemctl status ipv6-wireguard-manager"
    echo "  查看日志: journalctl -u ipv6-wireguard-manager -f"
    echo ""
    echo "📋 默认登录信息："
    echo "  用户名: admin"
    echo "  密码: admin123"
    echo ""
    echo "📚 更多信息："
    echo "  项目文档: https://github.com/ipzh/ipv6-wireguard-manager"
    echo "  问题反馈: https://github.com/ipzh/ipv6-wireguard-manager/issues"
    echo ""
}

# 主函数
main() {
    echo "=========================================="
    echo "IPv6 WireGuard Manager 通用安装脚本"
    echo "=========================================="
    
    # 检查root权限
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        exit 1
    fi
    
    # 解析参数
    parse_args "$@"
    
    # 显示配置
    log_info "安装配置:"
    log_info "  安装目录: $INSTALL_DIR"
    log_info "  安装类型: $INSTALL_TYPE"
    log_info "  服务用户: $SERVICE_USER"
    log_info "  服务组: $SERVICE_GROUP"
    log_info "  Python版本: $PYTHON_VERSION"
    log_info "  Node.js版本: $NODE_VERSION"
    
    # 执行安装步骤
    detect_system
    check_requirements
    install_system_dependencies
    create_service_user
    install_application
    configure_database
    configure_nginx
    create_system_service
    start_services
    verify_installation
    show_installation_info
    
    log_success "安装完成！"
}

# 运行主函数
main "$@"
