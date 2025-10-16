#!/bin/bash

# IPv6 WireGuard Manager - 完整功能安装脚本
# 支持所有可选功能的安装和配置
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

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# 全局变量
SCRIPT_VERSION="3.0.0"
PROJECT_NAME="IPv6 WireGuard Manager"
PROJECT_REPO="https://github.com/ipzh/ipv6-wireguard-manager.git"
DEFAULT_INSTALL_DIR="/opt/ipv6-wireguard-manager"
DEFAULT_WEB_DIR="/var/www/ipv6-wireguard-manager"
DEFAULT_WEB_PORT="80"
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
WEB_DIR=""
WEB_PORT=""
API_PORT=""
SERVICE_USER="ipv6wgm"
SERVICE_GROUP="ipv6wgm"
WEB_USER="www-data"

# 版本配置
PYTHON_VERSION="3.11"
PHP_VERSION="8.1"
MYSQL_VERSION="8.0"
REDIS_VERSION="7"
NGINX_VERSION="1.24"

# 功能开关
SILENT=false
PERFORMANCE=false
PRODUCTION=false
DEBUG=false
SKIP_DEPS=false
SKIP_DB=false
SKIP_SERVICE=false
SKIP_FRONTEND=false
SKIP_MONITORING=false
SKIP_LOGGING=false
SKIP_BACKUP=false
SKIP_SECURITY=false
SKIP_OPTIMIZATION=false

# 可选功能
ENABLE_DOCKER=false
ENABLE_REDIS=false
ENABLE_MONITORING=false
ENABLE_LOGGING=false
ENABLE_BACKUP=false
ENABLE_SECURITY=false
ENABLE_OPTIMIZATION=false
ENABLE_SSL=false
ENABLE_FIREWALL=false
ENABLE_SELINUX=false

# 显示帮助信息
show_help() {
    cat << EOF
IPv6 WireGuard Manager - 完整功能安装脚本 v${SCRIPT_VERSION}

用法: $0 [选项]

安装类型:
  --type TYPE          安装类型: native|docker|minimal|full (默认: 自动选择)
  --dir DIR           安装目录 (默认: ${DEFAULT_INSTALL_DIR})
  --web-dir DIR       前端目录 (默认: ${DEFAULT_WEB_DIR})
  --port PORT         Web端口 (默认: ${DEFAULT_WEB_PORT})
  --api-port PORT     API端口 (默认: ${DEFAULT_API_PORT})

版本配置:
  --python-version V  Python版本 (默认: ${PYTHON_VERSION})
  --php-version V     PHP版本 (默认: ${PHP_VERSION})
  --mysql-version V   MySQL版本 (默认: ${MYSQL_VERSION})
  --redis-version V   Redis版本 (默认: ${REDIS_VERSION})
  --nginx-version V   Nginx版本 (默认: ${NGINX_VERSION})

功能开关:
  --silent            静默安装 (无交互)
  --performance       性能优化模式
  --production        生产环境模式
  --debug             调试模式
  --skip-deps         跳过依赖安装
  --skip-db           跳过数据库配置
  --skip-service      跳过服务配置
  --skip-frontend     跳过前端安装
  --skip-monitoring   跳过监控配置
  --skip-logging      跳过日志配置
  --skip-backup       跳过备份配置
  --skip-security     跳过安全配置
  --skip-optimization 跳过性能优化

可选功能:
  --enable-docker     启用Docker支持
  --enable-redis      启用Redis缓存
  --enable-monitoring 启用系统监控
  --enable-logging    启用高级日志
  --enable-backup     启用自动备份
  --enable-security   启用安全加固
  --enable-optimization 启用性能优化
  --enable-ssl        启用SSL/TLS
  --enable-firewall   启用防火墙配置
  --enable-selinux    启用SELinux

其他选项:
  --help              显示此帮助信息
  --version           显示版本信息

示例:
  # 完整安装 (推荐)
  $0 --type full --enable-all

  # 生产环境安装
  $0 --type full --production --enable-security --enable-ssl

  # 开发环境安装
  $0 --type native --debug --enable-monitoring

  # 最小化安装
  $0 --type minimal

  # 静默安装
  $0 --silent --type full

EOF
}

# 显示版本信息
show_version() {
    echo "${PROJECT_NAME} 安装脚本 v${SCRIPT_VERSION}"
    echo "支持的系统: Ubuntu, Debian, CentOS, RHEL, Fedora, Arch Linux, openSUSE"
    echo "支持的功能: WireGuard, BGP, IPv6, 监控, 日志, 备份, 安全"
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
            --web-dir)
                WEB_DIR="$2"
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
            --python-version)
                PYTHON_VERSION="$2"
                shift 2
                ;;
            --php-version)
                PHP_VERSION="$2"
                shift 2
                ;;
            --mysql-version)
                MYSQL_VERSION="$2"
                shift 2
                ;;
            --redis-version)
                REDIS_VERSION="$2"
                shift 2
                ;;
            --nginx-version)
                NGINX_VERSION="$2"
                shift 2
                ;;
            --silent)
                SILENT=true
                shift
                ;;
            --performance)
                PERFORMANCE=true
                shift
                ;;
            --production)
                PRODUCTION=true
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
            --skip-monitoring)
                SKIP_MONITORING=true
                shift
                ;;
            --skip-logging)
                SKIP_LOGGING=true
                shift
                ;;
            --skip-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --skip-security)
                SKIP_SECURITY=true
                shift
                ;;
            --skip-optimization)
                SKIP_OPTIMIZATION=true
                shift
                ;;
            --enable-docker)
                ENABLE_DOCKER=true
                shift
                ;;
            --enable-redis)
                ENABLE_REDIS=true
                shift
                ;;
            --enable-monitoring)
                ENABLE_MONITORING=true
                shift
                ;;
            --enable-logging)
                ENABLE_LOGGING=true
                shift
                ;;
            --enable-backup)
                ENABLE_BACKUP=true
                shift
                ;;
            --enable-security)
                ENABLE_SECURITY=true
                shift
                ;;
            --enable-optimization)
                ENABLE_OPTIMIZATION=true
                shift
                ;;
            --enable-ssl)
                ENABLE_SSL=true
                shift
                ;;
            --enable-firewall)
                ENABLE_FIREWALL=true
                shift
                ;;
            --enable-selinux)
                ENABLE_SELINUX=true
                shift
                ;;
            --enable-all)
                ENABLE_DOCKER=true
                ENABLE_REDIS=true
                ENABLE_MONITORING=true
                ENABLE_LOGGING=true
                ENABLE_BACKUP=true
                ENABLE_SECURITY=true
                ENABLE_OPTIMIZATION=true
                ENABLE_SSL=true
                ENABLE_FIREWALL=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                log_info "使用 --help 查看帮助信息"
                exit 1
                ;;
        esac
    done
}

# 检测系统信息
detect_system() {
    log_step "检测系统环境..."
    
    # 检测操作系统
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="$ID"
        OS_VERSION="$VERSION_ID"
        OS_NAME="$NAME"
    elif [[ -f /etc/redhat-release ]]; then
        OS_NAME=$(cat /etc/redhat-release)
        if [[ $OS_NAME == *"CentOS"* ]]; then
            OS_ID="centos"
        elif [[ $OS_NAME == *"Red Hat"* ]]; then
            OS_ID="rhel"
        elif [[ $OS_NAME == *"Fedora"* ]]; then
            OS_ID="fedora"
        fi
    elif [[ -f /etc/debian_version ]]; then
        OS_ID="debian"
        OS_VERSION=$(cat /etc/debian_version)
        OS_NAME="Debian"
    else
        log_error "不支持的操作系统"
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
        log_error "不支持的包管理器"
        exit 1
    fi
    
    # 检测系统资源
    MEMORY_MB=$(free -m | awk 'NR==2{print $2}')
    CPU_CORES=$(nproc)
    DISK_SPACE_MB=$(df -m / | awk 'NR==2{print $4}')
    
    # 检测IPv6支持
    if [[ -f /proc/net/if_inet6 ]]; then
        IPV6_SUPPORT=true
    fi
    
    log_success "系统检测完成"
    log_info "操作系统: $OS_NAME $OS_VERSION ($ARCH)"
    log_info "包管理器: $PACKAGE_MANAGER"
    log_info "内存: ${MEMORY_MB}MB"
    log_info "CPU核心: $CPU_CORES"
    log_info "可用磁盘: ${DISK_SPACE_MB}MB"
    log_info "IPv6支持: $([ "$IPV6_SUPPORT" = true ] && echo "是" || echo "否")"
}

# 设置默认值
set_defaults() {
    # 设置安装目录
    if [[ -z "$INSTALL_DIR" ]]; then
        INSTALL_DIR="$DEFAULT_INSTALL_DIR"
    fi
    
    if [[ -z "$WEB_DIR" ]]; then
        WEB_DIR="$DEFAULT_WEB_DIR"
    fi
    
    # 设置端口
    if [[ -z "$WEB_PORT" ]]; then
        WEB_PORT="$DEFAULT_WEB_PORT"
    fi
    
    if [[ -z "$API_PORT" ]]; then
        API_PORT="$DEFAULT_API_PORT"
    fi
    
    # 自动选择安装类型
    if [[ -z "$INSTALL_TYPE" ]]; then
        if [[ $MEMORY_MB -lt 1024 ]]; then
            INSTALL_TYPE="minimal"
            log_info "内存不足1GB，自动选择最小化安装"
        elif [[ $MEMORY_MB -lt 2048 ]]; then
            INSTALL_TYPE="native"
            log_info "内存1-2GB，自动选择原生安装"
        else
            INSTALL_TYPE="full"
            log_info "内存充足，自动选择完整安装"
        fi
    fi
    
    # 生产环境自动启用安全功能
    if [[ "$PRODUCTION" = true ]]; then
        ENABLE_SECURITY=true
        ENABLE_SSL=true
        ENABLE_FIREWALL=true
        ENABLE_BACKUP=true
        ENABLE_MONITORING=true
        ENABLE_LOGGING=true
        log_info "生产环境模式，自动启用安全功能"
    fi
    
    # 性能模式自动启用优化
    if [[ "$PERFORMANCE" = true ]]; then
        ENABLE_OPTIMIZATION=true
        ENABLE_REDIS=true
        ENABLE_MONITORING=true
        log_info "性能模式，自动启用优化功能"
    fi
}

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0 $*"
        exit 1
    fi
}

# 更新系统包
update_system() {
    log_step "更新系统包..."
    
    case $PACKAGE_MANAGER in
        "apt")
            apt-get update -y
            apt-get upgrade -y
            ;;
        "yum")
            yum update -y
            ;;
        "dnf")
            dnf update -y
            ;;
        "pacman")
            pacman -Syu --noconfirm
            ;;
        "zypper")
            zypper refresh
            zypper update -y
            ;;
    esac
    
    log_success "系统包更新完成"
}

# 安装基础依赖
install_base_dependencies() {
    log_step "安装基础依赖..."
    
    case $PACKAGE_MANAGER in
        "apt")
            apt-get install -y \
                curl wget git unzip \
                build-essential software-properties-common \
                apt-transport-https ca-certificates gnupg lsb-release
            ;;
        "yum")
            yum install -y \
                curl wget git unzip \
                gcc gcc-c++ make \
                yum-utils device-mapper-persistent-data lvm2
            ;;
        "dnf")
            dnf install -y \
                curl wget git unzip \
                gcc gcc-c++ make \
                dnf-plugins-core
            ;;
        "pacman")
            pacman -S --noconfirm \
                curl wget git unzip \
                base-devel
            ;;
        "zypper")
            zypper install -y \
                curl wget git unzip \
                gcc gcc-c++ make \
                patterns-devel-C-C++
            ;;
    esac
    
    log_success "基础依赖安装完成"
}

# 安装Python
install_python() {
    log_step "安装Python $PYTHON_VERSION..."
    
    case $PACKAGE_MANAGER in
        "apt")
            add-apt-repository ppa:deadsnakes/ppa -y
            apt-get update
            apt-get install -y \
                python$PYTHON_VERSION \
                python$PYTHON_VERSION-venv \
                python$PYTHON_VERSION-dev \
                python3-pip
            ;;
        "yum"|"dnf")
            $PACKAGE_MANAGER install -y \
                python$PYTHON_VERSION \
                python$PYTHON_VERSION-pip \
                python$PYTHON_VERSION-devel
            ;;
        "pacman")
            pacman -S --noconfirm python python-pip
            ;;
        "zypper")
            zypper install -y python3 python3-pip python3-devel
            ;;
    esac
    
    log_success "Python安装完成"
}

# 安装PHP
install_php() {
    log_step "安装PHP $PHP_VERSION..."
    
    case $PACKAGE_MANAGER in
        "apt")
            apt-get install -y \
                php$PHP_VERSION \
                php$PHP_VERSION-fpm \
                php$PHP_VERSION-cli \
                php$PHP_VERSION-curl \
                php$PHP_VERSION-json \
                php$PHP_VERSION-mbstring \
                php$PHP_VERSION-mysql \
                php$PHP_VERSION-xml \
                php$PHP_VERSION-zip
            ;;
        "yum"|"dnf")
            $PACKAGE_MANAGER install -y \
                php \
                php-fpm \
                php-cli \
                php-curl \
                php-json \
                php-mbstring \
                php-mysql \
                php-xml \
                php-zip
            ;;
        "pacman")
            pacman -S --noconfirm php php-fpm
            ;;
        "zypper")
            zypper install -y php8 php8-fpm
            ;;
    esac
    
    log_success "PHP安装完成"
}

# 安装MySQL
install_mysql() {
    log_step "安装MySQL $MYSQL_VERSION..."
    
    case $PACKAGE_MANAGER in
        "apt")
            # 安装MySQL
            apt-get install -y mysql-server-$MYSQL_VERSION mysql-client-$MYSQL_VERSION
            ;;
        "yum"|"dnf")
            $PACKAGE_MANAGER install -y mysql-server mysql
            ;;
        "pacman")
            pacman -S --noconfirm mysql
            ;;
        "zypper")
            zypper install -y mysql-server mysql
            ;;
    esac
    
    # 启动MySQL服务
    systemctl start mysql
    systemctl enable mysql
    
    log_success "MySQL安装完成"
}

# 安装Nginx
install_nginx() {
    log_step "安装Nginx $NGINX_VERSION..."
    
    case $PACKAGE_MANAGER in
        "apt")
            apt-get install -y nginx
            ;;
        "yum"|"dnf")
            $PACKAGE_MANAGER install -y nginx
            ;;
        "pacman")
            pacman -S --noconfirm nginx
            ;;
        "zypper")
            zypper install -y nginx
            ;;
    esac
    
    log_success "Nginx安装完成"
}

# 安装Redis (可选)
install_redis() {
    if [[ "$ENABLE_REDIS" = true ]]; then
        log_step "安装Redis $REDIS_VERSION..."
        
        case $PACKAGE_MANAGER in
            "apt")
                apt-get install -y redis-server
                ;;
            "yum"|"dnf")
                $PACKAGE_MANAGER install -y redis
                ;;
            "pacman")
                pacman -S --noconfirm redis
                ;;
            "zypper")
                zypper install -y redis
                ;;
        esac
        
        # 启动Redis服务
        systemctl start redis
        systemctl enable redis
        
        log_success "Redis安装完成"
    fi
}

# 安装Docker (可选)
install_docker() {
    if [[ "$ENABLE_DOCKER" = true ]]; then
        log_step "安装Docker..."
        
        case $PACKAGE_MANAGER in
            "apt")
                # 添加Docker官方GPG密钥
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                
                # 添加Docker仓库
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                
                apt-get update
                apt-get install -y docker-ce docker-ce-cli containerd.io
                ;;
            "yum"|"dnf")
                # 添加Docker仓库
                $PACKAGE_MANAGER config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                $PACKAGE_MANAGER install -y docker-ce docker-ce-cli containerd.io
                ;;
            "pacman")
                pacman -S --noconfirm docker
                ;;
            "zypper")
                zypper install -y docker
                ;;
        esac
        
        # 启动Docker服务
        systemctl start docker
        systemctl enable docker
        
        log_success "Docker安装完成"
    fi
}

# 创建用户和组
create_users() {
    log_step "创建系统用户..."
    
    # 创建服务用户
    if ! id "$SERVICE_USER" &>/dev/null; then
        useradd -r -s /bin/false -d "$INSTALL_DIR" "$SERVICE_USER"
        log_success "创建用户: $SERVICE_USER"
    else
        log_info "用户已存在: $SERVICE_USER"
    fi
    
    # 创建Web用户 (如果不存在)
    if ! id "$WEB_USER" &>/dev/null; then
        useradd -r -s /bin/false -d "$WEB_DIR" "$WEB_USER"
        log_success "创建用户: $WEB_USER"
    else
        log_info "用户已存在: $WEB_USER"
    fi
}

# 创建目录结构
create_directories() {
    log_step "创建目录结构..."
    
    # 创建安装目录
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$WEB_DIR"
    mkdir -p "$INSTALL_DIR/logs"
    mkdir -p "$INSTALL_DIR/backups"
    mkdir -p "$INSTALL_DIR/config"
    mkdir -p "$INSTALL_DIR/scripts"
    
    # 设置权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
    chown -R "$WEB_USER:$WEB_USER" "$WEB_DIR"
    chmod 755 "$INSTALL_DIR"
    chmod 755 "$WEB_DIR"
    
    log_success "目录结构创建完成"
}

# 下载项目代码
download_project() {
    log_step "下载项目代码..."
    
    # 克隆项目
    if [[ -d "$INSTALL_DIR/.git" ]]; then
        log_info "项目已存在，更新代码..."
        cd "$INSTALL_DIR"
        git pull origin main
    else
        log_info "克隆项目代码..."
        git clone "$PROJECT_REPO" "$INSTALL_DIR"
    fi
    
    # 设置权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
    
    log_success "项目代码下载完成"
}

# 安装Python依赖
install_python_dependencies() {
    log_step "安装Python依赖..."
    
    cd "$INSTALL_DIR"
    
    # 创建虚拟环境
    python$PYTHON_VERSION -m venv venv
    source venv/bin/activate
    
    # 升级pip
    pip install --upgrade pip
    
    # 安装依赖
    if [[ -f "backend/requirements.txt" ]]; then
        pip install -r backend/requirements.txt
    fi
    
    # 如果启用Redis，安装Redis依赖
    if [[ "$ENABLE_REDIS" = true ]]; then
        pip install redis aioredis
    fi
    
    log_success "Python依赖安装完成"
}

# 配置数据库
configure_database() {
    if [[ "$SKIP_DB" = true ]]; then
        log_info "跳过数据库配置"
        return
    fi
    
    log_step "配置数据库..."
    
    # 创建数据库和用户
    mysql -u root -e "
CREATE DATABASE IF NOT EXISTS ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'ipv6wgm'@'localhost' IDENTIFIED BY 'ipv6wgm_password_$(date +%s)';
GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';
FLUSH PRIVILEGES;
"
    
    # 创建环境变量文件
    cat > "$INSTALL_DIR/.env" << EOF
DATABASE_URL=mysql://ipv6wgm:ipv6wgm_password_$(date +%s)@localhost:3306/ipv6wgm
SECRET_KEY=$(openssl rand -hex 32)
DEBUG=$([ "$DEBUG" = true ] && echo "true" || echo "false")
LOG_LEVEL=$([ "$DEBUG" = true ] && echo "DEBUG" || echo "INFO")
API_PORT=$API_PORT
WEB_PORT=$WEB_PORT
EOF
    
    # 初始化数据库
    cd "$INSTALL_DIR"
    source venv/bin/activate
    python -c "
from backend.app.core.database import init_db
import asyncio
asyncio.run(init_db())
print('数据库初始化完成')
"
    
    log_success "数据库配置完成"
}

# 部署前端
deploy_frontend() {
    if [[ "$SKIP_FRONTEND" = true ]]; then
        log_info "跳过前端部署"
        return
    fi
    
    log_step "部署前端..."
    
    # 复制前端文件
    if [[ -d "$INSTALL_DIR/php-frontend" ]]; then
        cp -r "$INSTALL_DIR/php-frontend"/* "$WEB_DIR/"
    else
        log_error "前端目录不存在"
        exit 1
    fi
    
    # 配置前端
    cat > "$WEB_DIR/config/config.php" << EOF
<?php
// 应用配置
define('APP_NAME', 'IPv6 WireGuard Manager');
define('APP_VERSION', '3.0.0');
define('APP_DEBUG', $([ "$DEBUG" = true ] && echo "true" || echo "false"));

// API配置
define('API_BASE_URL', 'http://localhost:$API_PORT/api/v1');
define('API_TIMEOUT', 30);

// 会话配置
define('SESSION_LIFETIME', 3600);

// 分页配置
define('DEFAULT_PAGE_SIZE', 20);
define('MAX_PAGE_SIZE', 100);

// 安全配置
define('CSRF_TOKEN_NAME', '_token');
define('PASSWORD_MIN_LENGTH', 8);

// 错误处理
if (APP_DEBUG) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
} else {
    error_reporting(0);
    ini_set('display_errors', 0);
}

// 时区设置
date_default_timezone_set('Asia/Shanghai');

// 字符编码
mb_internal_encoding('UTF-8');
mb_http_output('UTF-8');
?>
EOF
    
    # 设置权限
    chown -R "$WEB_USER:$WEB_USER" "$WEB_DIR"
    chmod -R 755 "$WEB_DIR"
    
    log_success "前端部署完成"
}

# 配置Nginx
configure_nginx() {
    log_step "配置Nginx..."
    
    # 创建Nginx配置
    cat > /etc/nginx/sites-available/ipv6-wireguard-manager << EOF
# IPv6 WireGuard Manager - Nginx配置文件
# 支持IPv4和IPv6双栈访问

# 上游服务器配置
upstream php_backend {
    server unix:/var/run/php/php$PHP_VERSION-fpm.sock;
}

# 主服务器配置
server {
    # IPv4和IPv6双栈监听
    listen $WEB_PORT;
    listen [::]:$WEB_PORT;
    
    # 服务器名称
    server_name ipv6-wireguard-manager.local localhost;
    
    # 网站根目录
    root $WEB_DIR;
    index index.php index.html index.htm;
    
    # 字符集
    charset utf-8;
    
    # 日志配置
    access_log /var/log/nginx/ipv6-wireguard-manager_access.log;
    error_log /var/log/nginx/ipv6-wireguard-manager_error.log;
    
    # 安全头设置
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # 客户端最大上传大小
    client_max_body_size 10M;
    
    # 超时设置
    client_body_timeout 60s;
    client_header_timeout 60s;
    keepalive_timeout 65s;
    send_timeout 60s;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # 禁止访问敏感文件
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ /\.(htaccess|htpasswd|env|log|ini|conf)\$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # 主要位置配置
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    # PHP处理
    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass php_backend;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        
        # 超时设置
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_read_timeout 60s;
        
        # 缓冲区设置
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
    }
    
    # API代理配置
    location /api/ {
        proxy_pass http://127.0.0.1:$API_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # 缓冲区设置
        proxy_buffering on;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }
    
    # WebSocket代理配置
    location /ws/ {
        proxy_pass http://127.0.0.1:$API_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket超时设置
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }
    
    # 健康检查端点
    location /health {
        access_log off;
        return 200 "healthy\\n";
        add_header Content-Type text/plain;
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
    systemctl restart nginx
    systemctl enable nginx
    
    log_success "Nginx配置完成"
}

# 创建系统服务
create_systemd_service() {
    if [[ "$SKIP_SERVICE" = true ]]; then
        log_info "跳过服务配置"
        return
    fi
    
    log_step "创建系统服务..."
    
    # 创建后端服务
    cat > /etc/systemd/system/ipv6-wireguard-manager.service << EOF
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target mysql.service
Wants=mysql.service

[Service]
Type=exec
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
ExecStart=$INSTALL_DIR/venv/bin/uvicorn app.main:app --host :: --port $API_PORT --workers 4
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ipv6-wireguard-manager

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载systemd
    systemctl daemon-reload
    systemctl enable ipv6-wireguard-manager
    systemctl start ipv6-wireguard-manager
    
    log_success "系统服务创建完成"
}

# 配置监控 (可选)
configure_monitoring() {
    if [[ "$ENABLE_MONITORING" = true ]]; then
        log_step "配置系统监控..."
        
        # 安装监控工具
        case $PACKAGE_MANAGER in
            "apt")
                apt-get install -y htop iotop nethogs
                ;;
            "yum"|"dnf")
                $PACKAGE_MANAGER install -y htop iotop nethogs
                ;;
            "pacman")
                pacman -S --noconfirm htop iotop nethogs
                ;;
            "zypper")
                zypper install -y htop iotop nethogs
                ;;
        esac
        
        # 创建监控脚本
        cat > "$INSTALL_DIR/scripts/monitor.sh" << 'EOF'
#!/bin/bash
# 系统监控脚本

LOG_FILE="/var/log/ipv6-wireguard-manager/monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# CPU使用率
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')

# 内存使用率
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.2f"), $3/$2 * 100.0}')

# 磁盘使用率
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')

# 网络流量
NETWORK_IN=$(cat /proc/net/dev | grep eth0 | awk '{print $2}')
NETWORK_OUT=$(cat /proc/net/dev | grep eth0 | awk '{print $10}')

# 记录日志
echo "$DATE,CPU:$CPU_USAGE%,MEMORY:$MEMORY_USAGE%,DISK:$DISK_USAGE%,NET_IN:$NETWORK_IN,NET_OUT:$NETWORK_OUT" >> $LOG_FILE
EOF
        
        chmod +x "$INSTALL_DIR/scripts/monitor.sh"
        
        # 创建定时任务
        echo "*/5 * * * * $INSTALL_DIR/scripts/monitor.sh" | crontab -u "$SERVICE_USER" -
        
        log_success "监控配置完成"
    fi
}

# 配置日志 (可选)
configure_logging() {
    if [[ "$ENABLE_LOGGING" = true ]]; then
        log_step "配置高级日志..."
        
        # 创建日志目录
        mkdir -p /var/log/ipv6-wireguard-manager
        chown -R "$SERVICE_USER:$SERVICE_GROUP" /var/log/ipv6-wireguard-manager
        
        # 配置日志轮转
        cat > /etc/logrotate.d/ipv6-wireguard-manager << EOF
/var/log/ipv6-wireguard-manager/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 $SERVICE_USER $SERVICE_GROUP
    postrotate
        systemctl reload ipv6-wireguard-manager
    endscript
}
EOF
        
        log_success "日志配置完成"
    fi
}

# 配置备份 (可选)
configure_backup() {
    if [[ "$ENABLE_BACKUP" = true ]]; then
        log_step "配置自动备份..."
        
        # 创建备份脚本
        cat > "$INSTALL_DIR/scripts/backup.sh" << EOF
#!/bin/bash
# 自动备份脚本

BACKUP_DIR="$INSTALL_DIR/backups"
DATE=\$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_\$DATE.tar.gz"

# 创建备份
tar -czf "\$BACKUP_DIR/\$BACKUP_FILE" -C "$INSTALL_DIR" .

# 删除7天前的备份
find "\$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +7 -delete

# 记录日志
echo "\$(date '+%Y-%m-%d %H:%M:%S') - 备份完成: \$BACKUP_FILE" >> /var/log/ipv6-wireguard-manager/backup.log
EOF
        
        chmod +x "$INSTALL_DIR/scripts/backup.sh"
        
        # 创建定时任务 (每天凌晨2点备份)
        echo "0 2 * * * $INSTALL_DIR/scripts/backup.sh" | crontab -u "$SERVICE_USER" -
        
        log_success "备份配置完成"
    fi
}

# 配置安全 (可选)
configure_security() {
    if [[ "$ENABLE_SECURITY" = true ]]; then
        log_step "配置安全加固..."
        
        # 配置防火墙
        if [[ "$ENABLE_FIREWALL" = true ]]; then
            case $PACKAGE_MANAGER in
                "apt")
                    apt-get install -y ufw
                    ufw --force enable
                    ufw allow ssh
                    ufw allow $WEB_PORT
                    ufw allow $API_PORT
                    ;;
                "yum"|"dnf")
                    $PACKAGE_MANAGER install -y firewalld
                    systemctl start firewalld
                    systemctl enable firewalld
                    firewall-cmd --permanent --add-service=ssh
                    firewall-cmd --permanent --add-port=$WEB_PORT/tcp
                    firewall-cmd --permanent --add-port=$API_PORT/tcp
                    firewall-cmd --reload
                    ;;
            esac
        fi
        
        # 配置SELinux (如果启用)
        if [[ "$ENABLE_SELINUX" = true ]]; then
            if command -v setsebool &> /dev/null; then
                setsebool -P httpd_can_network_connect 1
                setsebool -P httpd_can_network_connect_db 1
            fi
        fi
        
        # 配置SSL (如果启用)
        if [[ "$ENABLE_SSL" = true ]]; then
            log_info "SSL配置需要手动完成"
            log_info "请使用Let's Encrypt或其他SSL证书"
        fi
        
        log_success "安全配置完成"
    fi
}

# 性能优化 (可选)
configure_optimization() {
    if [[ "$ENABLE_OPTIMIZATION" = true ]]; then
        log_step "配置性能优化..."
        
        # 优化MySQL配置
        if [[ -f /etc/mysql/mysql.conf.d/mysqld.cnf ]]; then
            cat >> /etc/mysql/mysql.conf.d/mysqld.cnf << EOF

# IPv6 WireGuard Manager 优化配置
[mysqld]
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
query_cache_size = 32M
query_cache_type = 1
max_connections = 200
EOF
        fi
        
        # 优化PHP配置
        if [[ -f /etc/php/$PHP_VERSION/fpm/php.ini ]]; then
            sed -i 's/memory_limit = 128M/memory_limit = 256M/' /etc/php/$PHP_VERSION/fpm/php.ini
            sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/$PHP_VERSION/fpm/php.ini
            sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 10M/' /etc/php/$PHP_VERSION/fpm/php.ini
        fi
        
        # 优化Nginx配置
        if [[ -f /etc/nginx/nginx.conf ]]; then
            sed -i 's/worker_processes auto;/worker_processes '"$CPU_CORES"';/' /etc/nginx/nginx.conf
            sed -i 's/worker_connections 768;/worker_connections 1024;/' /etc/nginx/nginx.conf
        fi
        
        # 重启服务
        systemctl restart mysql
        systemctl restart php$PHP_VERSION-fpm
        systemctl restart nginx
        
        log_success "性能优化完成"
    fi
}

# 创建管理脚本
create_management_script() {
    log_step "创建管理脚本..."
    
    cat > /usr/local/bin/ipv6-wireguard-manager << EOF
#!/bin/bash
# IPv6 WireGuard Manager 管理脚本

case "\$1" in
    start)
        systemctl start ipv6-wireguard-manager
        systemctl start nginx
        systemctl start php$PHP_VERSION-fpm
        echo "✅ 服务已启动"
        ;;
    stop)
        systemctl stop ipv6-wireguard-manager
        systemctl stop nginx
        systemctl stop php$PHP_VERSION-fpm
        echo "✅ 服务已停止"
        ;;
    restart)
        systemctl restart ipv6-wireguard-manager
        systemctl restart nginx
        systemctl restart php$PHP_VERSION-fpm
        echo "✅ 服务已重启"
        ;;
    status)
        echo "后端服务状态:"
        systemctl status ipv6-wireguard-manager --no-pager
        echo ""
        echo "Nginx服务状态:"
        systemctl status nginx --no-pager
        echo ""
        echo "PHP-FPM服务状态:"
        systemctl status php$PHP_VERSION-fpm --no-pager
        ;;
    logs)
        journalctl -u ipv6-wireguard-manager -f
        ;;
    update)
        echo "🔄 更新系统..."
        cd $INSTALL_DIR
        git pull origin main
        source venv/bin/activate
        pip install -r backend/requirements.txt
        systemctl restart ipv6-wireguard-manager
        echo "✅ 系统更新完成"
        ;;
    backup)
        echo "📦 创建备份..."
        $INSTALL_DIR/scripts/backup.sh
        echo "✅ 备份创建完成"
        ;;
    monitor)
        echo "📊 系统监控信息:"
        echo "CPU使用率: \$(top -bn1 | grep "Cpu(s)" | awk '{print \$2}')"
        echo "内存使用率: \$(free | grep Mem | awk '{printf("%.2f"), \$3/\$2 * 100.0}')%"
        echo "磁盘使用率: \$(df -h / | awk 'NR==2{print \$5}')"
        ;;
    *)
        echo "用法: \$0 {start|stop|restart|status|logs|update|backup|monitor}"
        echo ""
        echo "命令说明:"
        echo "  start    - 启动所有服务"
        echo "  stop     - 停止所有服务"
        echo "  restart  - 重启所有服务"
        echo "  status   - 查看服务状态"
        echo "  logs     - 查看后端日志"
        echo "  update   - 更新系统"
        echo "  backup   - 创建备份"
        echo "  monitor  - 查看系统监控"
        exit 1
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/ipv6-wireguard-manager
    
    log_success "管理脚本创建完成"
}

# 显示安装完成信息
show_completion_info() {
    log_success "🎉 安装完成！"
    
    echo ""
    echo "=========================================="
    echo "📋 安装信息:"
    echo "   后端目录: $INSTALL_DIR"
    echo "   前端目录: $WEB_DIR"
    echo "   Web端口: $WEB_PORT"
    echo "   API端口: $API_PORT"
    echo "   数据库: MySQL $MYSQL_VERSION"
    echo "   PHP版本: $PHP_VERSION"
    echo "   Python版本: $PYTHON_VERSION"
    echo ""
    echo "🌐 访问地址:"
    echo "   IPv4: http://localhost:$WEB_PORT/"
    echo "   IPv6: http://[::1]:$WEB_PORT/"
    echo "   API文档: http://localhost:$API_PORT/docs"
    echo "   健康检查: http://localhost:$API_PORT/health"
    echo ""
    echo "🔧 管理命令:"
    echo "   启动服务: ipv6-wireguard-manager start"
    echo "   停止服务: ipv6-wireguard-manager stop"
    echo "   重启服务: ipv6-wireguard-manager restart"
    echo "   查看状态: ipv6-wireguard-manager status"
    echo "   查看日志: ipv6-wireguard-manager logs"
    echo "   更新系统: ipv6-wireguard-manager update"
    echo "   创建备份: ipv6-wireguard-manager backup"
    echo "   系统监控: ipv6-wireguard-manager monitor"
    echo ""
    echo "👤 默认账户:"
    echo "   用户名: admin"
    echo "   密码: admin123"
    echo ""
    
    if [[ "$ENABLE_SSL" = true ]]; then
        echo "🔒 SSL配置:"
        echo "   请手动配置SSL证书"
        echo "   推荐使用Let's Encrypt"
    fi
    
    if [[ "$ENABLE_FIREWALL" = true ]]; then
        echo "🛡️ 防火墙:"
        echo "   防火墙已启用"
        echo "   已开放端口: $WEB_PORT, $API_PORT"
    fi
    
    echo ""
    echo "✅ 安装完成！现在可以通过浏览器访问系统了。"
}

# 主安装流程
main() {
    echo "=========================================="
    echo "🚀 IPv6 WireGuard Manager 完整安装脚本"
    echo "=========================================="
    echo ""
    
    # 解析参数
    parse_arguments "$@"
    
    # 检查root权限
    check_root "$@"
    
    # 检测系统
    detect_system
    
    # 设置默认值
    set_defaults
    
    # 显示安装配置
    log_info "安装配置:"
    log_info "  安装类型: $INSTALL_TYPE"
    log_info "  后端目录: $INSTALL_DIR"
    log_info "  前端目录: $WEB_DIR"
    log_info "  Web端口: $WEB_PORT"
    log_info "  API端口: $API_PORT"
    log_info "  Python版本: $PYTHON_VERSION"
    log_info "  PHP版本: $PHP_VERSION"
    log_info "  MySQL版本: $MYSQL_VERSION"
    echo ""
    
    # 确认安装
    if [[ "$SILENT" = false ]]; then
        read -p "是否继续安装? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "安装已取消"
            exit 0
        fi
    fi
    
    # 开始安装
    log_step "开始安装..."
    
    # 更新系统
    update_system
    
    # 安装基础依赖
    install_base_dependencies
    
    # 安装Python
    install_python
    
    # 安装PHP
    install_php
    
    # 安装MySQL
    install_mysql
    
    # 安装Nginx
    install_nginx
    
    # 安装Redis (可选)
    install_redis
    
    # 安装Docker (可选)
    install_docker
    
    # 创建用户
    create_users
    
    # 创建目录
    create_directories
    
    # 下载项目
    download_project
    
    # 安装Python依赖
    install_python_dependencies
    
    # 配置数据库
    configure_database
    
    # 部署前端
    deploy_frontend
    
    # 配置Nginx
    configure_nginx
    
    # 创建系统服务
    create_systemd_service
    
    # 配置监控 (可选)
    configure_monitoring
    
    # 配置日志 (可选)
    configure_logging
    
    # 配置备份 (可选)
    configure_backup
    
    # 配置安全 (可选)
    configure_security
    
    # 性能优化 (可选)
    configure_optimization
    
    # 创建管理脚本
    create_management_script
    
    # 显示完成信息
    show_completion_info
}

# 运行主函数
main "$@"
