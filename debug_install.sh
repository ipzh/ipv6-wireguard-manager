#!/bin/bash

# 调试版本安装脚本
# 专门用于调试最小化安装问题

# 禁用严格错误处理以便调试
# set -e
set -u
set -o pipefail

# 基本配置
SCRIPT_VERSION="3.0.0"
PROJECT_NAME="IPv6 WireGuard Manager"
PROJECT_REPO="https://github.com/ipzh/ipv6-wireguard-manager"

# 默认配置
DEFAULT_INSTALL_DIR="/opt/ipv6-wireguard-manager"
DEFAULT_PORT="80"
DEFAULT_API_PORT="8000"
SERVICE_USER="ipv6wgm"
SERVICE_GROUP="ipv6wgm"
PYTHON_VERSION="3.11"
MYSQL_VERSION="8.0"

# 功能开关
SILENT=false
SKIP_DEPS=false
SKIP_SERVICE=false
SKIP_DB=false
DEBUG=false
PRODUCTION=false

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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 检测系统信息
detect_system() {
    log_info "检测系统信息..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$NAME"
        OS_VERSION="$VERSION_ID"
    else
        OS_NAME="Unknown"
        OS_VERSION="Unknown"
    fi
    
    ARCH=$(uname -m)
    MEMORY_MB=$(free -m | awk 'NR==2{print $2}')
    CPU_CORES=$(nproc)
    DISK_AVAILABLE=$(df -m / | awk 'NR==2{print $4}')
    
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
        PACKAGE_MANAGER="unknown"
    fi
    
    log_success "系统信息检测完成"
    log_info "操作系统: $OS_NAME $OS_VERSION"
    log_info "架构: $ARCH"
    log_info "内存: ${MEMORY_MB}MB"
    log_info "CPU核心: $CPU_CORES"
    log_info "可用磁盘: ${DISK_AVAILABLE}MB"
    log_info "包管理器: $PACKAGE_MANAGER"
}

# 智能推荐安装类型
recommend_install_type() {
    local recommended_type=""
    local reason=""
    
    if [ "$MEMORY_MB" -lt 1024 ]; then
        recommended_type="minimal"
        reason="内存不足1GB，强制最小化安装"
    elif [ "$MEMORY_MB" -lt 2048 ]; then
        recommended_type="minimal"
        reason="内存不足2GB，推荐最小化安装（优化MySQL配置）"
    else
        recommended_type="native"
        reason="内存充足，推荐原生安装"
    fi
    
    echo "$recommended_type|$reason"
}

# 解析参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            minimal|native|docker)
                INSTALL_TYPE="$1"
                shift
                ;;
            --dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            --debug)
                DEBUG=true
                shift
                ;;
            --silent)
                SILENT=true
                shift
                ;;
            --skip-deps)
                SKIP_DEPS=true
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
                exit 1
                ;;
        esac
    done
    
    # 设置默认值
    INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"
    
    # 如果没有指定安装类型，自动选择
    if [ -z "$INSTALL_TYPE" ]; then
        if [ ! -t 0 ] || [ "$SILENT" = true ]; then
            local recommended_result=$(recommend_install_type)
            INSTALL_TYPE=$(echo "$recommended_result" | cut -d'|' -f1)
            local recommended_reason=$(echo "$recommended_result" | cut -d'|' -f2)
            log_info "检测到非交互模式，自动选择安装类型: $INSTALL_TYPE"
            log_info "选择理由: $recommended_reason"
        else
            INSTALL_TYPE="minimal"
        fi
    fi
}

# 显示帮助信息
show_help() {
    echo "IPv6 WireGuard Manager 调试安装脚本"
    echo "用法: $0 [选项] [安装类型]"
    echo ""
    echo "安装类型:"
    echo "  minimal    最小化安装（推荐低内存系统）"
    echo "  native     原生安装"
    echo "  docker     Docker安装"
    echo ""
    echo "选项:"
    echo "  --dir DIR     指定安装目录（默认: $DEFAULT_INSTALL_DIR）"
    echo "  --debug       启用调试模式"
    echo "  --silent      静默模式"
    echo "  --skip-deps   跳过系统依赖安装"
    echo "  --skip-service 跳过服务创建"
    echo "  --help        显示此帮助信息"
}

# 最小化安装
run_minimal_installation() {
    log_info "开始最小化安装..."
    log_info "安装目录: $INSTALL_DIR"
    log_info "服务用户: $SERVICE_USER"
    log_info "跳过依赖: $SKIP_DEPS"
    log_info "跳过服务: $SKIP_SERVICE"
    echo ""
    
    # 步骤1: 安装系统依赖
    if [ "$SKIP_DEPS" = false ]; then
        log_step "步骤 1/5: 安装系统依赖"
        install_minimal_dependencies
    else
        log_info "跳过系统依赖安装"
    fi
    
    # 步骤2: 创建服务用户
    log_step "步骤 2/5: 创建服务用户"
    create_service_user
    
    # 步骤3: 下载项目
    log_step "步骤 3/5: 下载项目代码"
    download_project
    
    # 步骤4: 安装Python依赖
    log_step "步骤 4/5: 安装Python依赖"
    install_core_dependencies
    
    # 步骤5: 配置数据库
    log_step "步骤 5/5: 配置数据库"
    configure_minimal_mysql_database
    
    log_success "最小化安装完成！"
}

# 安装最小依赖
install_minimal_dependencies() {
    log_info "安装最小依赖..."
    
    case $PACKAGE_MANAGER in
        "apt")
            log_info "使用APT包管理器..."
            apt-get update
            apt-get install -y python$PYTHON_VERSION python$PYTHON_VERSION-venv python3-pip
            if ! apt-get install -y mysql-server-$MYSQL_VERSION mysql-client-$MYSQL_VERSION 2>/dev/null; then
                log_info "MySQL $MYSQL_VERSION 不可用，安装默认版本..."
                apt-get install -y mysql-server mysql-client
            fi
            apt-get install -y nginx git curl wget
            ;;
        "yum"|"dnf")
            log_info "使用YUM/DNF包管理器..."
            $PACKAGE_MANAGER install -y python$PYTHON_VERSION python$PYTHON_VERSION-pip
            $PACKAGE_MANAGER install -y mysql-server mysql nginx git curl wget
            ;;
        "pacman")
            log_info "使用Pacman包管理器..."
            pacman -S --noconfirm python python-pip mysql nginx git curl wget
            ;;
        "zypper")
            log_info "使用Zypper包管理器..."
            zypper install -y python$PYTHON_VERSION python$PYTHON_VERSION-pip
            zypper install -y mysql mysql-server nginx git curl wget
            ;;
        *)
            log_error "不支持的包管理器: $PACKAGE_MANAGER"
            exit 1
            ;;
    esac
    
    log_success "系统依赖安装完成"
}

# 创建服务用户
create_service_user() {
    log_info "创建服务用户..."
    
    if ! id "$SERVICE_USER" &>/dev/null; then
        useradd -r -s /bin/false -d "$INSTALL_DIR" "$SERVICE_USER"
        log_info "用户 $SERVICE_USER 创建成功"
    else
        log_info "用户 $SERVICE_USER 已存在"
    fi
    
    if ! getent group "$SERVICE_GROUP" &>/dev/null; then
        groupadd -r "$SERVICE_GROUP"
        log_info "组 $SERVICE_GROUP 创建成功"
    else
        log_info "组 $SERVICE_GROUP 已存在"
    fi
    
    log_success "服务用户创建完成"
}

# 下载项目
download_project() {
    log_info "下载项目源码..."
    
    mkdir -p "$INSTALL_DIR"
    
    if [[ -d "$INSTALL_DIR" && "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]]; then
        log_info "目录已存在，备份旧版本..."
        mv "$INSTALL_DIR" "$INSTALL_DIR.backup.$(date +%s)"
        mkdir -p "$INSTALL_DIR"
    fi
    
    git clone "$PROJECT_REPO" "$INSTALL_DIR"
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    
    log_success "项目下载完成"
}

# 安装核心依赖
install_core_dependencies() {
    log_info "安装Python依赖..."
    
    cd "$INSTALL_DIR/backend"
    
    python$PYTHON_VERSION -m venv venv
    source venv/bin/activate
    
    pip install --upgrade pip
    pip install -r requirements-minimal.txt
    
    log_success "Python依赖安装完成"
}

# 配置MySQL数据库
configure_minimal_mysql_database() {
    log_info "配置MySQL数据库..."
    
    systemctl enable mysql
    systemctl start mysql
    sleep 5
    
    mysql -e "CREATE DATABASE IF NOT EXISTS ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || log_info "数据库已存在"
    mysql -e "CREATE USER IF NOT EXISTS '$SERVICE_USER'@'localhost' IDENTIFIED BY 'password';" 2>/dev/null || log_info "用户已存在"
    mysql -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO '$SERVICE_USER'@'localhost';" 2>/dev/null || log_info "权限已设置"
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || log_info "权限刷新完成"
    
    cd "$INSTALL_DIR/backend"
    source venv/bin/activate
    
    cat > .env << EOF
DATABASE_URL=mysql://$SERVICE_USER:password@localhost:3306/ipv6wgm
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
SECRET_KEY=$(openssl rand -hex 32)
DATABASE_POOL_SIZE=5
DATABASE_MAX_OVERFLOW=10
MAX_WORKERS=2
EOF
    
    python scripts/init_database_mysql.py
    
    log_success "MySQL数据库配置完成"
}

# 主函数
main() {
    echo "=========================================="
    echo "🚀 $PROJECT_NAME 调试安装脚本"
    echo "=========================================="
    echo ""
    
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0 $*"
        exit 1
    fi
    
    detect_system
    parse_arguments "$@"
    
    log_info "安装配置:"
    log_info "  类型: $INSTALL_TYPE"
    log_info "  目录: $INSTALL_DIR"
    log_info "  调试: $DEBUG"
    echo ""
    
    case $INSTALL_TYPE in
        "minimal")
            run_minimal_installation
            ;;
        *)
            log_error "不支持的安装类型: $INSTALL_TYPE"
            exit 1
            ;;
    esac
    
    echo ""
    log_success "安装完成！"
    log_info "安装目录: $INSTALL_DIR"
    log_info "服务用户: $SERVICE_USER"
}

# 运行主函数
main "$@"
