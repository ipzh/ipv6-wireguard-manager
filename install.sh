#!/bin/bash

# IPv6 WireGuard Manager - 智能安装脚本
# 支持多种安装方式，自动检测系统环境，增强兼容性
# 企业级VPN管理平台

set -e
set -u
set -o pipefail

# 错误处理函数
handle_error() {
    local exit_code=$?
    local line_number=$1
    log_error "脚本在第 $line_number 行执行失败，退出码: $exit_code"
    log_info "请检查上述错误信息并重试"
    exit $exit_code
}

# 设置错误陷阱
trap 'handle_error $LINENO' ERR

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# 全局变量
SCRIPT_VERSION="3.1.0"
PROJECT_NAME="IPv6 WireGuard Manager"
PROJECT_REPO="https://github.com/ipzh/ipv6-wireguard-manager.git"
DEFAULT_INSTALL_DIR="/opt/ipv6-wireguard-manager"
DEFAULT_PORT="80"
DEFAULT_API_PORT="8000"

# 系统信息
OS_ID=""
OS_VERSION=""
OS_NAME=""
ARCH=""
PACKAGE_MANAGER=""
MEMORY_MB=""
CPU_CORES=""
DISK_SPACE_MB=""
IPV6_SUPPORT=false

# 安装配置
INSTALL_TYPE=""
INSTALL_DIR=""
WEB_PORT=""
API_PORT=""
SERVICE_USER="ipv6wgm"
SERVICE_GROUP="ipv6wgm"
PYTHON_VERSION="3.11"
PHP_VERSION="8.1"
MYSQL_VERSION="8.0"

# 功能开关
SILENT=false
PERFORMANCE=false
PRODUCTION=false
DEBUG=false
SKIP_DEPS=false
SKIP_DB=false
SKIP_SERVICE=false
SKIP_FRONTEND=false

# 系统信息检测
detect_system() {
    log_info "检测系统信息..."
    
    # 检查操作系统
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_ID="$ID"
        OS_VERSION="$VERSION_ID"
        OS_NAME="$PRETTY_NAME"
    elif [[ -f /etc/redhat-release ]]; then
        # 兼容旧版CentOS/RHEL
        OS_ID="rhel"
        OS_VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+' | head -1)
        OS_NAME=$(cat /etc/redhat-release)
    elif [[ -f /etc/debian_version ]]; then
        # 兼容旧版Debian
        OS_ID="debian"
        OS_VERSION=$(cat /etc/debian_version)
        OS_NAME="Debian $OS_VERSION"
    elif [[ -f /etc/arch-release ]]; then
        # Arch Linux
        OS_ID="arch"
        OS_VERSION="rolling"
        OS_NAME="Arch Linux"
    elif [[ -f /etc/SuSE-release ]]; then
        # 旧版openSUSE
        OS_ID="opensuse"
        OS_VERSION=$(cat /etc/SuSE-release | grep -oE '[0-9]+\.[0-9]+' | head -1)
        OS_NAME="openSUSE $OS_VERSION"
    else
        log_error "不支持的操作系统：无法检测系统信息"
        log_info "支持的系统："
        log_info "  - Ubuntu 18.04+"
        log_info "  - Debian 9+"
        log_info "  - CentOS 7+"
        log_info "  - RHEL 7+"
        log_info "  - Fedora 30+"
        log_info "  - Arch Linux"
        log_info "  - openSUSE 15+"
        exit 1
    fi
    
    # 检测架构
    ARCH=$(uname -m)
    
    # 检测包管理器
    if command -v apt-get &> /dev/null; then
        PACKAGE_MANAGER="apt"
    elif command -v apt &> /dev/null; then
        PACKAGE_MANAGER="apt"
    elif command -v dnf &> /dev/null; then
        PACKAGE_MANAGER="dnf"
    elif command -v yum &> /dev/null; then
        PACKAGE_MANAGER="yum"
    elif command -v pacman &> /dev/null; then
        PACKAGE_MANAGER="pacman"
    elif command -v zypper &> /dev/null; then
        PACKAGE_MANAGER="zypper"
    elif command -v emerge &> /dev/null; then
        PACKAGE_MANAGER="emerge"
    elif command -v apk &> /dev/null; then
        PACKAGE_MANAGER="apk"
    else
        log_error "未检测到支持的包管理器"
        log_info "支持的包管理器："
        log_info "  - apt/apt-get (Ubuntu/Debian)"
        log_info "  - yum/dnf (CentOS/RHEL/Fedora)"
        log_info "  - pacman (Arch Linux)"
        log_info "  - zypper (openSUSE)"
        log_info "  - emerge (Gentoo)"
        log_info "  - apk (Alpine Linux)"
        exit 1
    fi
    
    # 检测系统资源
    if command -v free &> /dev/null; then
        MEMORY_MB=$(free -m | awk 'NR==2{print $2}')
    else
        log_warning "无法检测内存信息，使用默认值"
        MEMORY_MB=1024
    fi
    
    if command -v nproc &> /dev/null; then
        CPU_CORES=$(nproc)
    else
        CPU_CORES=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1)
    fi
    
    if command -v df &> /dev/null; then
        DISK_SPACE=$(df / | awk 'NR==2{print $4}')
        DISK_SPACE_MB=$((DISK_SPACE / 1024))
    else
        log_warning "无法检测磁盘空间，使用默认值"
        DISK_SPACE_MB=10240
    fi
    
    # 检测IPv6支持
    if command -v ping6 &> /dev/null; then
        if ping6 -c 1 2001:4860:4860::8888 &> /dev/null 2>&1; then
            IPV6_SUPPORT=true
        else
            IPV6_SUPPORT=false
        fi
    elif command -v ping &> /dev/null; then
        if ping -6 -c 1 2001:4860:4860::8888 &> /dev/null 2>&1; then
            IPV6_SUPPORT=true
        else
            IPV6_SUPPORT=false
        fi
    else
        log_warning "无法检测IPv6支持"
        IPV6_SUPPORT=false
    fi
    
    log_success "系统信息检测完成:"
    log_info "  操作系统: $OS_NAME"
    log_info "  版本: $OS_VERSION"
    log_info "  架构: $ARCH"
    log_info "  包管理器: $PACKAGE_MANAGER"
    log_info "  内存: ${MEMORY_MB}MB"
    log_info "  CPU核心: $CPU_CORES"
    log_info "  可用磁盘: ${DISK_SPACE_MB}MB"
    log_info "  IPv6支持: $IPV6_SUPPORT"
}

# 检查系统要求
check_requirements() {
    log_info "检查系统要求..."
    
    # 检查内存要求
    if [[ $MEMORY_MB -lt 1024 ]]; then
        log_warning "系统内存不足1GB，建议至少2GB内存"
    fi
    
    # 检查磁盘空间要求
    if [[ $DISK_SPACE_MB -lt 2048 ]]; then
        log_warning "可用磁盘空间不足2GB，建议至少5GB"
    fi
    
    # 检查架构支持
    case $ARCH in
        "x86_64"|"amd64")
            log_success "✓ 支持x86_64架构"
            ;;
        "aarch64"|"arm64")
            log_success "✓ 支持ARM64架构"
            ;;
        "armv7l"|"armhf")
            log_success "✓ 支持ARM32架构"
            ;;
        *)
            log_warning "⚠ 未测试的架构: $ARCH"
            ;;
    esac
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --type)
                INSTALL_TYPE="$2"
                shift 2
                ;;
            --dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            --port)
                WEB_PORT="$2"
                shift 2
                ;;
            --api-port)
                API_PORT="$2"
                shift 2
                ;;
            --silent)
                SILENT=true
                shift
                ;;
            --production)
                PRODUCTION=true
                shift
                ;;
            --performance)
                PERFORMANCE=true
                shift
                ;;
            --debug)
                DEBUG=true
                shift
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
            --skip-frontend)
                SKIP_FRONTEND=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                echo "$SCRIPT_VERSION"
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

# 显示帮助信息
show_help() {
    echo "IPv6 WireGuard Manager - 智能安装脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --type TYPE          安装类型 (native|minimal)"
    echo "  --dir DIR            安装目录 (默认: $DEFAULT_INSTALL_DIR)"
    echo "  --port PORT          Web端口 (默认: $DEFAULT_PORT)"
    echo "  --api-port PORT      API端口 (默认: $DEFAULT_API_PORT)"
    echo "  --silent             静默安装"
    echo "  --production         生产环境安装"
    echo "  --performance        性能优化安装"
    echo "  --debug              调试模式"
    echo "  --skip-deps          跳过依赖安装"
    echo "  --skip-db            跳过数据库配置"
    echo "  --skip-service       跳过服务创建"
    echo "  --skip-frontend      跳过前端部署"
    echo "  --help, -h           显示帮助信息"
    echo "  --version, -v        显示版本信息"
    echo ""
    echo "示例:"
    echo "  $0 --type minimal --silent"
    echo "  $0 --type native --production --dir /opt/ipv6wgm"
    echo ""
    echo "支持的Linux系统:"
    echo "  - Ubuntu 18.04+"
    echo "  - Debian 9+"
    echo "  - CentOS 7+"
    echo "  - RHEL 7+"
    echo "  - Fedora 30+"
    echo "  - Arch Linux"
    echo "  - openSUSE 15+"
    echo ""
    echo "安装类型说明:"
    echo "  native   - 原生安装，推荐用于生产环境和开发环境"
    echo "  minimal  - 最小化安装，推荐用于资源受限环境"
    echo ""
    echo "注意: Docker安装暂未实现"
}

# 选择安装类型
select_install_type() {
    if [[ -n "$INSTALL_TYPE" ]]; then
        log_info "使用指定的安装类型: $INSTALL_TYPE"
        return 0
    fi
    
    if [[ "$SILENT" = true ]]; then
        # 静默模式自动选择
        if [[ $MEMORY_MB -lt 2048 ]]; then
            INSTALL_TYPE="minimal"
            log_info "检测到非交互模式，自动选择安装类型..."
            log_info "自动选择的安装类型: minimal"
            log_info "选择理由: 内存不足2GB，推荐最小化安装（优化MySQL配置）"
        elif [[ $MEMORY_MB -lt 4096 ]]; then
            INSTALL_TYPE="native"
            log_info "检测到非交互模式，自动选择安装类型..."
            log_info "自动选择的安装类型: native"
            log_info "选择理由: 内存2-4GB，推荐原生安装（平衡性能和资源）"
        else
            INSTALL_TYPE="native"
            log_info "检测到非交互模式，自动选择安装类型..."
            log_info "自动选择的安装类型: native"
            log_info "选择理由: 内存充足，但Docker安装暂未实现，使用原生安装"
        fi
        return 0
    fi
    
    # 交互模式
    log_info "请选择安装类型:"
    echo "1) 原生安装 - 推荐用于生产环境和开发环境"
    echo "   优点: 性能最佳、资源占用低、启动快速"
    echo "   缺点: 依赖系统环境、配置复杂"
    echo "   要求: 内存 ≥ 2GB，磁盘 ≥ 5GB"
    echo ""
    echo "2) 最小化安装 - 推荐用于资源受限环境"
    echo "   优点: 资源占用最低、启动最快"
    echo "   缺点: 功能受限、性能一般"
    echo "   要求: 内存 ≥ 1GB，磁盘 ≥ 3GB"
    echo ""
    echo "注意: Docker安装暂未实现，请选择原生安装或最小化安装"
    echo ""
    
    # 根据系统资源推荐
    if [[ $MEMORY_MB -lt 2048 ]]; then
        log_warning "⚠️ 系统内存不足2GB，强烈推荐选择最小化安装"
        recommended="2"
    else
        log_info "💡 系统内存充足，推荐选择原生安装"
        recommended="1"
    fi
    
    echo ""
    read -p "请输入选择 (1-2) [推荐: $recommended]: " choice
    
    case $choice in
        1|"")
            INSTALL_TYPE="native"
            ;;
        2)
            INSTALL_TYPE="minimal"
            ;;
        *)
            log_error "无效选择: $choice"
            exit 1
            ;;
    esac
    
    log_success "选择的安装类型: $INSTALL_TYPE"
}

# 设置默认值
set_defaults() {
    if [[ -z "$INSTALL_DIR" ]]; then
        INSTALL_DIR="$DEFAULT_INSTALL_DIR"
    fi
    
    if [[ -z "$WEB_PORT" ]]; then
        WEB_PORT="$DEFAULT_PORT"
    fi
    
    if [[ -z "$API_PORT" ]]; then
        API_PORT="$DEFAULT_API_PORT"
    fi
}

# 安装系统依赖
install_system_dependencies() {
    log_info "安装系统依赖..."
    
    case $PACKAGE_MANAGER in
        "apt")
            apt-get update
            apt-get install -y python$PYTHON_VERSION python$PYTHON_VERSION-venv python$PYTHON_VERSION-dev python3-pip
            apt-get install -y mysql-server mysql-client
            apt-get install -y nginx
            apt-get install -y git curl wget build-essential
            ;;
        "yum"|"dnf")
            $PACKAGE_MANAGER install -y python$PYTHON_VERSION python$PYTHON_VERSION-pip python$PYTHON_VERSION-devel
            $PACKAGE_MANAGER install -y mariadb-server mariadb
            $PACKAGE_MANAGER install -y nginx
            $PACKAGE_MANAGER install -y git curl wget gcc gcc-c++ make
            ;;
        "pacman")
            pacman -Sy
            pacman -S --noconfirm python python-pip
            pacman -S --noconfirm mariadb
            pacman -S --noconfirm nginx
            pacman -S --noconfirm git curl wget base-devel
            ;;
        "zypper")
            zypper refresh
            zypper install -y python$PYTHON_VERSION python$PYTHON_VERSION-pip python$PYTHON_VERSION-devel
            zypper install -y mariadb mariadb-server
            zypper install -y nginx
            zypper install -y git curl wget gcc gcc-c++ make
            ;;
        "emerge")
            emerge --sync
            emerge -q dev-lang/python:3.11
            emerge -q dev-db/mariadb
            emerge -q www-servers/nginx
            emerge -q net-misc/curl
            emerge -q app-misc/git
            ;;
        "apk")
            apk update
            apk add python3 py3-pip
            apk add mariadb mariadb-client
            apk add nginx
            apk add curl wget git
            ;;
    esac
}

# 安装PHP和PHP-FPM
install_php() {
    log_info "安装PHP和PHP-FPM..."
    
    case $PACKAGE_MANAGER in
        "apt")
            # 尝试安装指定版本的PHP
            if apt-get install -y php$PHP_VERSION php$PHP_VERSION-fpm php$PHP_VERSION-cli php$PHP_VERSION-curl php$PHP_VERSION-json php$PHP_VERSION-mbstring php$PHP_VERSION-mysql php$PHP_VERSION-xml php$PHP_VERSION-zip 2>/dev/null; then
                log_success "PHP $PHP_VERSION 安装成功"
            else
                # 尝试安装默认PHP版本
                if apt-get install -y php php-fpm php-cli php-curl php-json php-mbstring php-mysql php-xml php-zip 2>/dev/null; then
                    log_success "PHP默认版本安装成功"
                    PHP_VERSION=$(php -v | grep -oP 'PHP \K[0-9]+\.[0-9]+' | head -1)
                else
                    log_error "PHP安装失败"
                    exit 1
                fi
            fi
            ;;
        "yum"|"dnf")
            if $PACKAGE_MANAGER install -y php php-fpm php-cli php-curl php-json php-mbstring php-mysql php-xml php-zip 2>/dev/null; then
                log_success "PHP安装成功"
            else
                log_error "PHP安装失败"
                exit 1
            fi
            ;;
        "pacman")
            if pacman -S --noconfirm php php-fpm 2>/dev/null; then
                log_success "PHP安装成功"
            else
                log_error "PHP安装失败"
                exit 1
            fi
            ;;
        "zypper")
            if zypper install -y php php-fpm php-cli php-curl php-json php-mbstring php-mysql php-xml php-zip 2>/dev/null; then
                log_success "PHP安装成功"
            else
                log_error "PHP安装失败"
                exit 1
            fi
            ;;
        "emerge")
            emerge -q dev-lang/php:8.1
            ;;
        "apk")
            apk add php php-fpm php-cli php-curl php-json php-mbstring php-mysqlnd php-xml php-zip
            ;;
    esac
}

# 创建服务用户
create_service_user() {
    log_info "创建服务用户..."
    
    if ! id "$SERVICE_USER" &>/dev/null; then
        useradd -r -s /bin/false -d "$INSTALL_DIR" "$SERVICE_USER"
        log_success "服务用户 $SERVICE_USER 创建成功"
    else
        log_info "服务用户 $SERVICE_USER 已存在"
    fi
}

# 下载项目
download_project() {
    log_info "下载项目代码..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        log_warning "安装目录已存在，备份现有安装..."
        mv "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    if git clone "$PROJECT_REPO" .; then
        log_success "项目代码下载成功"
    else
        log_error "项目代码下载失败"
        exit 1
    fi
}

# 安装Python依赖
install_python_dependencies() {
    log_info "安装Python依赖..."
    
    cd "$INSTALL_DIR"
    
    # 创建虚拟环境
    python$PYTHON_VERSION -m venv venv
    source venv/bin/activate
    
    # 升级pip
    pip install --upgrade pip
    
    # 安装依赖
    if [[ -f "backend/requirements.txt" ]]; then
        pip install -r backend/requirements.txt
        log_success "Python依赖安装成功"
    else
        log_error "requirements.txt文件不存在"
        exit 1
    fi
}

# 配置数据库
configure_database() {
    log_info "配置数据库..."
    
    # 启动MySQL服务
    case $PACKAGE_MANAGER in
        "apt")
            systemctl start mysql
            systemctl enable mysql
            ;;
        "yum"|"dnf")
            systemctl start mariadb
            systemctl enable mariadb
            ;;
        "pacman")
            systemctl start mariadb
            systemctl enable mariadb
            ;;
        "zypper")
            systemctl start mariadb
            systemctl enable mariadb
            ;;
        "emerge")
            systemctl start mariadb
            systemctl enable mariadb
            ;;
        "apk")
            service mariadb start
            rc-update add mariadb default
            ;;
    esac
    
    # 创建数据库和用户
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mysql -u root -e "CREATE USER IF NOT EXISTS 'ipv6wgm'@'localhost' IDENTIFIED BY 'ipv6wgm_password';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';"
    mysql -u root -e "FLUSH PRIVILEGES;"
    
    log_success "数据库配置完成"
}

# 部署PHP前端
deploy_php_frontend() {
    log_info "部署PHP前端..."
    
    # 创建Web目录
    local web_dir="/var/www/html"
    if [[ ! -d "$web_dir" ]]; then
        mkdir -p "$web_dir"
    fi
    
    # 复制PHP前端文件
    cp -r "$INSTALL_DIR/php-frontend"/* "$web_dir/"
    
    # 设置权限
    chown -R www-data:www-data "$web_dir"
    chmod -R 755 "$web_dir"
    
    # 启动PHP-FPM服务
    local php_fpm_service=""
    case $PACKAGE_MANAGER in
        "apt")
            php_fpm_service="php$PHP_VERSION-fpm"
            ;;
        "yum"|"dnf"|"pacman"|"zypper"|"emerge"|"apk")
            php_fpm_service="php-fpm"
            ;;
    esac
    
    if systemctl start "$php_fpm_service" 2>/dev/null; then
        systemctl enable "$php_fpm_service"
        log_success "PHP-FPM服务启动成功"
    else
        log_error "PHP-FPM服务启动失败"
        exit 1
    fi
}

# 配置Nginx
configure_nginx() {
    log_info "配置Nginx..."
    
    # 创建Nginx配置
    cat > /etc/nginx/sites-available/ipv6-wireguard-manager << EOF
server {
    listen 80;
    listen [::]:80;
    server_name _;
    root /var/www/html;
    index index.php index.html;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location /api/ {
        proxy_pass http://127.0.0.1:$API_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # 启用站点
    ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # 测试配置
    if nginx -t; then
        systemctl restart nginx
        systemctl enable nginx
        log_success "Nginx配置完成"
    else
        log_error "Nginx配置错误"
        exit 1
    fi
}

# 创建系统服务
create_system_service() {
    log_info "创建系统服务..."
    
    cat > /etc/systemd/system/ipv6-wireguard-manager.service << EOF
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target mysql.service

[Service]
Type=exec
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
ExecStart=$INSTALL_DIR/venv/bin/uvicorn backend.app.main:app --host :: --port $API_PORT
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable ipv6-wireguard-manager
    
    log_success "系统服务创建完成"
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    # 启动后端服务
    systemctl start ipv6-wireguard-manager
    
    # 检查服务状态
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "后端服务启动成功"
    else
        log_error "后端服务启动失败"
        exit 1
    fi
}

# 运行环境检查
run_environment_check() {
    log_info "运行环境检查..."
    
    # 检查Python环境
    if python$PYTHON_VERSION --version &>/dev/null; then
        log_success "✓ Python环境正常"
    else
        log_error "✗ Python环境异常"
        return 1
    fi
    
    # 检查数据库连接
    if mysql -u ipv6wgm -pipv6wgm_password -e "SELECT 1;" &>/dev/null; then
        log_success "✓ 数据库连接正常"
    else
        log_error "✗ 数据库连接异常"
        return 1
    fi
    
    # 检查Web服务
    if curl -f http://localhost/ &>/dev/null; then
        log_success "✓ Web服务正常"
    else
        log_error "✗ Web服务异常"
        return 1
    fi
    
    # 检查API服务
    if curl -f http://localhost:$API_PORT/api/v1/health &>/dev/null; then
        log_success "✓ API服务正常"
    else
        log_error "✗ API服务异常"
        return 1
    fi
    
    return 0
}

# 显示安装完成信息
show_installation_complete() {
    echo ""
    log_success "🎉 安装完成！"
    echo ""
    log_info "访问地址:"
    log_info "  前端: http://localhost:$WEB_PORT"
    log_info "  API文档: http://localhost:$API_PORT/docs"
    log_info "  API健康检查: http://localhost:$API_PORT/api/v1/health"
    echo ""
    log_info "服务管理:"
    log_info "  启动服务: sudo systemctl start ipv6-wireguard-manager"
    log_info "  停止服务: sudo systemctl stop ipv6-wireguard-manager"
    log_info "  重启服务: sudo systemctl restart ipv6-wireguard-manager"
    log_info "  查看状态: sudo systemctl status ipv6-wireguard-manager"
    echo ""
    log_info "日志查看:"
    log_info "  应用日志: sudo journalctl -u ipv6-wireguard-manager -f"
    log_info "  Nginx日志: sudo tail -f /var/log/nginx/access.log"
    echo ""
    log_info "配置文件:"
    log_info "  应用配置: $INSTALL_DIR/.env"
    log_info "  Nginx配置: /etc/nginx/sites-available/ipv6-wireguard-manager"
    log_info "  服务配置: /etc/systemd/system/ipv6-wireguard-manager.service"
    echo ""
    log_info "辅助工具:"
    log_info "  系统兼容性测试: ./test_system_compatibility.sh"
    log_info "  安装验证: ./verify_installation.sh"
    log_info "  PHP-FPM修复: ./fix_php_fpm.sh"
    echo ""
    log_success "感谢使用IPv6 WireGuard Manager！"
}

# 主函数
main() {
    log_info "IPv6 WireGuard Manager - 智能安装脚本 v$SCRIPT_VERSION"
    echo ""
    
    # 检测系统
    detect_system
    check_requirements
    
    # 解析参数
    parse_arguments "$@"
    
    # 选择安装类型
    select_install_type
    
    # 设置默认值
    set_defaults
    
    log_info "安装配置:"
    log_info "  类型: $INSTALL_TYPE"
    log_info "  目录: $INSTALL_DIR"
    log_info "  Web端口: $WEB_PORT"
    log_info "  API端口: $API_PORT"
    log_info "  服务用户: $SERVICE_USER"
    log_info "  Python版本: $PYTHON_VERSION"
    log_info "  PHP版本: $PHP_VERSION"
    echo ""
    
    # 执行安装
    case $INSTALL_TYPE in
        "docker")
            log_error "Docker安装暂未实现，请使用原生安装或最小化安装"
            exit 1
            ;;
        "native")
            log_step "开始原生安装..."
            if [[ "$SKIP_DEPS" = false ]]; then
                install_system_dependencies
                install_php
            fi
            create_service_user
            download_project
            install_python_dependencies
            if [[ "$SKIP_DB" = false ]]; then
                configure_database
            fi
            if [[ "$SKIP_FRONTEND" = false ]]; then
                deploy_php_frontend
                configure_nginx
            fi
            if [[ "$SKIP_SERVICE" = false ]]; then
                create_system_service
            fi
            start_services
            ;;
        "minimal")
            log_step "开始最小化安装..."
            if [[ "$SKIP_DEPS" = false ]]; then
                install_system_dependencies
                install_php
            fi
            create_service_user
            download_project
            install_python_dependencies
            if [[ "$SKIP_DB" = false ]]; then
                configure_database
            fi
            if [[ "$SKIP_FRONTEND" = false ]]; then
                deploy_php_frontend
                configure_nginx
            fi
            if [[ "$SKIP_SERVICE" = false ]]; then
                create_system_service
            fi
            start_services
            ;;
        *)
            log_error "无效的安装类型: $INSTALL_TYPE"
            exit 1
            ;;
    esac
    
    # 运行环境检查
    if run_environment_check; then
        show_installation_complete
    else
        log_error "环境检查失败，请检查安装日志"
        exit 1
    fi
}

# 运行主函数
main "$@"