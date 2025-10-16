#!/bin/bash

# IPv6 WireGuard Manager - 智能安装脚本
# 支持多种安装方式，自动检测系统环境，去除硬编码
# 企业级VPN管理平台

# 暂时禁用严格错误处理以便调试
# set -e  # 遇到错误立即退出
set -u  # 使用未定义变量时退出
set -o pipefail  # 管道中任何命令失败都会导致整个管道失败

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
NODE_VERSION="18"
PHP_VERSION="8.1"
MYSQL_VERSION="8.0"
POSTGRES_VERSION="15"
REDIS_VERSION="7"

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

# 系统信息检测
detect_system() {
    log_info "检测系统信息..."
    
    # 检查操作系统
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_ID="$ID"
        OS_VERSION="$VERSION_ID"
        OS_NAME="$PRETTY_NAME"
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
    
    # 检测系统资源
    MEMORY_MB=$(free -m | awk 'NR==2{print $2}')
    CPU_CORES=$(nproc)
    DISK_SPACE=$(df / | awk 'NR==2{print $4}')
    DISK_SPACE_MB=$((DISK_SPACE / 1024))
    
    # 检测IPv6支持
    if ping6 -c 1 2001:4860:4860::8888 &> /dev/null 2>&1; then
        IPV6_SUPPORT=true
    else
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
    log_info "  IPv6支持: $([ "$IPV6_SUPPORT" = true ] && echo "是" || echo "否")"
}

# 检查系统要求
check_requirements() {
    log_info "检查系统要求..."
    
    local requirements_ok=true
    local warnings=()
    
    # 检查内存
    if [ "$MEMORY_MB" -lt 512 ]; then
        log_error "系统内存不足，至少需要512MB"
        requirements_ok=false
    elif [ "$MEMORY_MB" -lt 1024 ]; then
        warnings+=("系统内存较少，建议使用最小化安装模式")
    fi
    
    # 检查磁盘空间
    if [ "$DISK_SPACE_MB" -lt 1024 ]; then
        log_error "磁盘空间不足，至少需要1GB"
        requirements_ok=false
    elif [ "$DISK_SPACE_MB" -lt 2048 ]; then
        warnings+=("磁盘空间较少，建议至少2GB")
    fi
    
    # 检查网络连接
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        warnings+=("网络连接可能有问题")
    fi
    
    # 显示警告
    for warning in "${warnings[@]}"; do
        log_warning "$warning"
    done
    
    if [ "$requirements_ok" = false ]; then
        log_error "系统要求检查失败"
        exit 1
    fi
    
    log_success "系统要求检查通过"
}

# 智能推荐安装类型
recommend_install_type() {
    local recommended_type=""
    local reason=""
    
    # 根据系统资源智能推荐
    if [ "$MEMORY_MB" -lt 1024 ]; then
        recommended_type="minimal"
        reason="内存不足1GB，强制最小化安装"
    elif [ "$MEMORY_MB" -lt 2048 ]; then
        recommended_type="minimal"
        reason="内存不足2GB，推荐最小化安装（优化MySQL配置）"
    else
        if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
            recommended_type="docker"
            reason="内存充足且Docker可用，推荐Docker安装（最佳体验）"
        else
            recommended_type="native"
            reason="内存充足但Docker不可用，推荐原生安装（高性能）"
        fi
    fi
    
    echo "$recommended_type|$reason"
}

# 显示安装选项
show_install_options() {
    echo ""
    echo "=========================================="
    echo "🚀 $PROJECT_NAME 安装选项"
    echo "=========================================="
    echo ""
    
    # 获取智能推荐
    local recommended_result=$(recommend_install_type)
    local recommended_type=$(echo "$recommended_result" | cut -d'|' -f1)
    local recommended_reason=$(echo "$recommended_result" | cut -d'|' -f2)
    
    log_info "智能推荐:"
    log_success "  推荐安装方式: $recommended_type"
    log_info "  推荐理由: $recommended_reason"
    echo ""
    
    log_info "安装选项:"
    
    if [ "$MEMORY_MB" -lt 2048 ]; then
        echo "⚠️ 检测到内存不足2GB，推荐使用最小化安装"
        echo ""
        echo "📦 1. 最小化安装 (推荐 - 低内存优化)"
        echo "   ✅ 优点: 资源占用最少、MySQL优化配置、适合低配置服务器"
        echo "   ❌ 缺点: 功能有限、仅核心功能"
        echo "   🎯 适用: 低配置VPS、内存受限环境"
        echo "   💾 内存要求: 512MB+"
        echo "   🗄️ 数据库: MySQL (优化配置)"
        echo ""
        echo "🐳 2. Docker安装 (不推荐 - 内存不足)"
        echo "   ❌ 缺点: 内存占用过高、可能导致系统不稳定"
        echo "   💾 内存要求: 2GB+"
        echo ""
        echo "⚡ 3. 原生安装 (不推荐 - 内存不足)"
        echo "   ❌ 缺点: 内存占用较高、可能导致系统不稳定"
        echo "   💾 内存要求: 1GB+"
    else
        echo "🐳 1. Docker安装 (推荐新手)"
        echo "   ✅ 优点: 环境隔离、易于管理、一键部署"
        echo "   ❌ 缺点: 资源占用较高、性能略有损失"
        echo "   🎯 适用: 测试环境、开发环境、性能要求不高的场景"
        echo "   💾 内存要求: 2GB+"
        echo ""
        echo "⚡ 2. 原生安装 (推荐VPS)"
        echo "   ✅ 优点: 性能最优、资源占用最小、启动快速"
        echo "   ❌ 缺点: 依赖管理复杂、环境配置相对复杂"
        echo "   🎯 适用: 生产环境、VPS部署、高性能场景"
        echo "   💾 内存要求: 1GB+"
        echo ""
        echo "📦 3. 最小化安装 (低内存)"
        echo "   ✅ 优点: 资源占用最少、适合低配置服务器"
        echo "   ❌ 缺点: 功能有限、仅核心功能"
        echo "   🎯 适用: 低配置VPS、测试环境"
        echo "   💾 内存要求: 512MB+"
    fi
    echo ""
    echo "📊 性能对比:"
    echo "   💾 内存占用: Docker 2GB+ vs 原生 1GB+ vs 最小化 512MB+"
    echo "   ⚡ 启动速度: Docker 较慢 vs 原生 快速 vs 最小化 最快"
    echo "   🚀 性能表现: Docker 良好 vs 原生 最优 vs 最小化 基础"
    echo ""
    
    # 检查是否为非交互模式
    if [ ! -t 0 ] || [ "$SILENT" = true ]; then
        log_info "检测到非交互模式，自动选择安装类型..."
        log_info "自动选择的安装类型: $recommended_type"
        log_info "选择理由: $recommended_reason"
        echo "$recommended_type"
        return
    fi
    
    # 5秒倒计时选择
    echo ""
    log_info "5秒后将自动选择推荐方式，按任意键立即选择..."
    echo ""
    
    local choice=""
    local countdown=5
    
    # 倒计时循环
    while [ $countdown -gt 0 ]; do
        printf "\r⏰ 倒计时: %d 秒 (推荐: $recommended_type) " $countdown
        sleep 1
        countdown=$((countdown - 1))
    done
    
    echo ""
    echo ""
    
    # 检查是否有输入
    if read -t 0; then
        echo -n "请选择安装方式 (1-3, 回车使用推荐): "
        read -r choice
    else
        choice=""
    fi
    
    # 如果没有输入或输入为空，使用推荐方式
    if [ -z "$choice" ]; then
        log_info "使用推荐安装方式: $recommended_type"
        echo "$recommended_type"
        return
    fi
    
    case $choice in
        1) echo "docker" ;;
        2) echo "native" ;;
        3) echo "minimal" ;;
        *) 
            log_warning "无效选择，使用自动选择" >&2
            echo "$recommended_type"
            ;;
    esac
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            docker|native|minimal)
                INSTALL_TYPE="$1"
                shift
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
            --user)
                SERVICE_USER="$2"
                shift 2
                ;;
            --group)
                SERVICE_GROUP="$2"
                shift 2
                ;;
            --python)
                PYTHON_VERSION="$2"
                shift 2
                ;;
            --mysql)
                MYSQL_VERSION="$2"
                shift 2
                ;;
            --redis)
                REDIS_VERSION="$2"
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
            --auto)
                SILENT=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                show_version
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 设置默认值
    INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"
    WEB_PORT="${WEB_PORT:-$DEFAULT_PORT}"
    API_PORT="${API_PORT:-$DEFAULT_API_PORT}"
    
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
    
    # 如果没有指定安装类型，自动选择
    if [ -z "$INSTALL_TYPE" ]; then
        # 在非交互模式下直接获取推荐类型
        if [ ! -t 0 ] || [ "$SILENT" = true ]; then
            local recommended_result=$(recommend_install_type)
            INSTALL_TYPE=$(echo "$recommended_result" | cut -d'|' -f1)
            local recommended_reason=$(echo "$recommended_result" | cut -d'|' -f2)
            log_info "检测到非交互模式，自动选择安装类型: $INSTALL_TYPE"
            log_info "选择理由: $recommended_reason"
        else
            INSTALL_TYPE=$(show_install_options)
        fi
    fi
}

# 显示版本信息
show_version() {
    echo "$PROJECT_NAME 安装脚本"
    echo "版本: $SCRIPT_VERSION"
    echo "发布日期: $(date +%Y-%m-%d)"
    echo ""
    echo "功能特性:"
    echo "  ✅ 支持所有主流Linux发行版"
    echo "  ✅ IPv6/IPv4双栈网络支持"
    echo "  ✅ 多种安装方式 (Docker/原生/最小化)"
    echo "  ✅ 自动系统检测和配置"
    echo "  ✅ 企业级VPN管理功能"
    echo "  ✅ 完整的监控和日志系统"
    echo ""
    echo "支持的发行版:"
    echo "  • Ubuntu 20.04+"
    echo "  • Debian 11+"
    echo "  • CentOS 8+"
    echo "  • RHEL 8+"
    echo "  • Fedora 38+"
    echo "  • Arch Linux"
    echo "  • openSUSE 15+"
    echo ""
    echo "项目地址: $PROJECT_REPO"
}

# 显示帮助信息
show_help() {
    echo "=========================================="
    echo "$PROJECT_NAME 安装脚本"
    echo "=========================================="
    echo ""
    echo "用法: $0 [选项] [安装类型]"
    echo ""
    echo "安装类型:"
    echo "  docker      Docker安装 (推荐新手)"
    echo "  native      原生安装 (推荐VPS)"
    echo "  minimal     最小化安装 (低内存)"
    echo ""
    echo "选项:"
    echo "  --dir DIR           安装目录 (默认: $DEFAULT_INSTALL_DIR)"
    echo "  --port PORT         Web服务器端口 (默认: $DEFAULT_PORT)"
    echo "  --api-port PORT     API服务器端口 (默认: $DEFAULT_API_PORT)"
    echo "  --user USER         服务用户 (默认: ipv6wgm)"
    echo "  --group GROUP       服务组 (默认: ipv6wgm)"
    echo "  --python VERSION    Python版本 (默认: 3.11)"
    echo "  --mysql VERSION     MySQL版本 (默认: 8.0)"
    echo "  --redis VERSION     Redis版本 (默认: 7)"
    echo "  --silent            静默安装 (无交互)"
    echo "  --performance       启用性能优化"
    echo "  --production        生产环境安装 (包含监控)"
    echo "  --debug             调试模式"
    echo "  --skip-deps         跳过依赖安装"
    echo "  --skip-db           跳过数据库安装"
    echo "  --skip-service      跳过服务安装"
    echo "  --skip-frontend     跳过前端安装"
    echo "  --skip-monitoring   跳过监控配置"
    echo "  --skip-logging      跳过日志配置"
    echo "  --skip-backup       跳过备份配置"
    echo "  --skip-security     跳过安全配置"
    echo "  --skip-optimization 跳过性能优化"
    echo "  --auto              自动选择安装类型"
    echo ""
    echo "可选功能:"
    echo "  --enable-docker     启用Docker支持"
    echo "  --enable-redis      启用Redis缓存"
    echo "  --enable-monitoring 启用系统监控"
    echo "  --enable-logging    启用高级日志"
    echo "  --enable-backup     启用自动备份"
    echo "  --enable-security   启用安全加固"
    echo "  --enable-optimization 启用性能优化"
    echo "  --enable-ssl        启用SSL/TLS"
    echo "  --enable-firewall   启用防火墙配置"
    echo "  --enable-selinux    启用SELinux"
    echo "  --enable-all        启用所有可选功能"
    echo ""
    echo "  --help, -h          显示此帮助信息"
    echo "  --version, -v       显示版本信息"
    echo ""
    echo "示例:"
    echo "  $0                                    # 交互式安装"
    echo "  $0 docker                            # Docker安装"
    echo "  $0 --dir /opt/my-app --port 8080     # 自定义目录和端口"
    echo "  $0 --silent --performance            # 静默安装并优化"
    echo "  $0 --production native               # 生产环境原生安装"
    echo "  $0 --debug minimal                   # 调试模式最小化安装"
    echo "  $0 --enable-all                      # 启用所有可选功能"
    echo "  $0 --production --enable-security    # 生产环境+安全加固"
    echo "  $0 --enable-monitoring --enable-backup # 监控+备份"
    echo "  $0 --enable-ssl --enable-firewall    # SSL+防火墙"
    echo ""
    echo "快速安装:"
    echo "  curl -fsSL $PROJECT_REPO/raw/main/install.sh | bash"
    echo ""
    echo "更多信息:"
    echo "  项目地址: $PROJECT_REPO"
    echo "  问题反馈: $PROJECT_REPO/issues"
}

# 主安装函数
main() {
    echo "=========================================="
    echo "🚀 $PROJECT_NAME 智能安装脚本"
    echo "=========================================="
    echo ""
    log_info "版本: $SCRIPT_VERSION"
    log_info "支持IPv6/IPv4双栈网络"
    log_info "支持多种安装方式"
    echo ""
    
    # 检查root权限
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0 $*"
        exit 1
    fi
    
    # 检测系统信息
    detect_system
    check_requirements
    
    # 解析参数
    parse_arguments "$@"
    
    log_info "安装配置:"
    log_info "  类型: $INSTALL_TYPE"
    log_info "  目录: $INSTALL_DIR"
    log_info "  Web端口: $WEB_PORT"
    log_info "  API端口: $API_PORT"
    log_info "  服务用户: $SERVICE_USER"
    log_info "  Python版本: $PYTHON_VERSION"
    log_info "  Node.js版本: $NODE_VERSION"
    log_info "  静默模式: $SILENT"
    log_info "  性能优化: $PERFORMANCE"
    log_info "  生产环境: $PRODUCTION"
    log_info "  调试模式: $DEBUG"
    echo ""
    
    # 选择安装方式
    case $INSTALL_TYPE in
        "docker")
            log_step "开始Docker安装..."
            run_docker_installation
            ;;
        "native")
            log_step "开始原生安装..."
            run_native_installation
            ;;
        "minimal")
            log_step "开始最小化安装..."
            run_minimal_installation
            ;;
        *)
            log_error "无效的安装类型: $INSTALL_TYPE"
            exit 1
            ;;
    esac
    
    # 显示安装完成信息
    show_installation_complete
}

# Docker安装
run_docker_installation() {
    log_info "使用Docker安装方式..."
    
    # 检查Docker是否已安装
    if ! command -v docker &> /dev/null; then
        log_info "安装Docker..."
        install_docker
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_info "安装Docker Compose..."
        install_docker_compose
    fi
    
    # 下载项目
    download_project
    
    # 配置Docker环境
    configure_docker_environment
    
    # 启动Docker服务
    start_docker_services
    
    log_success "Docker安装完成"
}

# 原生安装
run_native_installation() {
    log_info "使用原生安装方式..."
    
    # 安装系统依赖
    if [ "$SKIP_DEPS" = false ]; then
        install_system_dependencies
    fi
    
    # 创建服务用户
    create_service_user
    
    # 下载项目
    download_project
    
    # 安装应用依赖
    install_application_dependencies
    
    # 创建环境变量文件
    create_environment_file
    
    # 配置数据库
    if [ "$SKIP_DB" = false ]; then
        configure_database
    fi
    
    # 配置Nginx
    configure_nginx
    
    # 创建系统服务
    if [ "$SKIP_SERVICE" = false ]; then
        create_system_service
    fi
    
    # 启动服务
    start_services
    
    # 运行环境检查
    run_environment_check
    
    log_success "原生安装完成"
}

# 最小化安装
run_minimal_installation() {
    log_info "使用最小化安装方式..."
    log_info "安装目录: $INSTALL_DIR"
    log_info "服务用户: $SERVICE_USER"
    log_info "跳过依赖: $SKIP_DEPS"
    log_info "跳过服务: $SKIP_SERVICE"
    echo ""
    
    # 安装最小系统依赖
    if [ "$SKIP_DEPS" = false ]; then
        log_step "步骤 1/7: 安装系统依赖"
        log_info "开始安装系统依赖..."
        if ! install_minimal_dependencies; then
            log_error "系统依赖安装失败"
            exit 1
        fi
        log_info "系统依赖安装完成"
    else
        log_info "跳过系统依赖安装"
    fi
    
    # 创建服务用户
    log_step "步骤 2/7: 创建服务用户"
    log_info "开始创建服务用户..."
    if ! create_service_user; then
        log_error "创建服务用户失败"
        exit 1
    fi
    log_info "服务用户创建完成"
    
    # 下载项目
    log_step "步骤 3/7: 下载项目代码"
    log_info "开始下载项目代码..."
    if ! download_project; then
        log_error "下载项目代码失败"
        exit 1
    fi
    log_info "项目代码下载完成"
    
    # 安装核心依赖
    log_step "步骤 4/7: 安装Python依赖"
    log_info "开始安装Python依赖..."
    if ! install_core_dependencies; then
        log_error "安装Python依赖失败"
        exit 1
    fi
    log_info "Python依赖安装完成"
    
    # 部署PHP前端（如果启用）
    if [ "$SKIP_FRONTEND" = false ]; then
        log_step "步骤 4.5/7: 部署PHP前端"
        log_info "开始部署PHP前端..."
        if ! deploy_php_frontend; then
            log_error "PHP前端部署失败"
            exit 1
        fi
        log_info "PHP前端部署完成"
    else
        log_info "跳过PHP前端部署"
    fi
    
    # 配置最小化MySQL数据库
    log_step "步骤 5/7: 配置MySQL数据库"
    log_info "开始配置MySQL数据库..."
    if ! configure_minimal_mysql_database; then
        log_error "配置MySQL数据库失败"
        exit 1
    fi
    log_info "MySQL数据库配置完成"
    
    # 创建简单服务
    if [ "$SKIP_SERVICE" = false ]; then
        log_step "步骤 6/7: 创建系统服务"
        log_info "开始创建系统服务..."
        if ! create_simple_service; then
            log_error "创建系统服务失败"
            exit 1
        fi
        log_info "系统服务创建完成"
    else
        log_info "跳过系统服务创建"
    fi
    
    # 启动服务
    log_step "步骤 7/7: 启动服务"
    log_info "开始启动服务..."
    if ! start_minimal_services; then
        log_error "启动服务失败"
        exit 1
    fi
    log_info "服务启动完成"
    
    # 运行环境检查
    log_info "运行最终环境检查..."
    if ! run_environment_check; then
        log_error "环境检查失败"
        exit 1
    fi
    log_info "环境检查完成"
    
    echo ""
    log_success "最小化安装完成！"
}

# 安装Docker
install_docker() {
    case $PACKAGE_MANAGER in
        "apt")
            apt-get update
            apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/$OS_ID/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS_ID $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io
            ;;
        "yum"|"dnf")
            $PACKAGE_MANAGER install -y yum-utils
            $PACKAGE_MANAGER-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            $PACKAGE_MANAGER install -y docker-ce docker-ce-cli containerd.io
            ;;
        "pacman")
            pacman -S --noconfirm docker
            ;;
        "zypper")
            zypper install -y docker
            ;;
    esac
    
    systemctl enable docker
    systemctl start docker
}

# 安装Docker Compose
install_docker_compose() {
    local compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    curl -L "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
}

# 安装系统依赖
install_system_dependencies() {
    log_info "安装系统依赖..."
    
    case $PACKAGE_MANAGER in
        "apt")
            apt-get update
            apt-get install -y python$PYTHON_VERSION python$PYTHON_VERSION-venv python$PYTHON_VERSION-dev python3-pip
            apt-get install -y mysql-server-$MYSQL_VERSION mysql-client-$MYSQL_VERSION
            apt-get install -y redis-server nginx
            apt-get install -y git curl wget build-essential
            ;;
        "yum"|"dnf")
            $PACKAGE_MANAGER install -y python$PYTHON_VERSION python$PYTHON_VERSION-pip python$PYTHON_VERSION-devel
            $PACKAGE_MANAGER install -y mysql-server mysql
            $PACKAGE_MANAGER install -y redis nginx
            $PACKAGE_MANAGER install -y git curl wget gcc gcc-c++ make
            ;;
        "pacman")
            pacman -S --noconfirm python python-pip mysql redis nginx
            pacman -S --noconfirm git curl wget base-devel
            ;;
        "zypper")
            zypper install -y python$PYTHON_VERSION python$PYTHON_VERSION-pip python$PYTHON_VERSION-devel
            zypper install -y mysql mysql-server
            zypper install -y redis nginx
            
            # 检查并禁用apache服务（如果存在）
            if systemctl list-unit-files | grep -q "apache2.service"; then
                log_info "检测到Apache2服务，正在禁用..."
                systemctl stop apache2 2>/dev/null || true
                systemctl disable apache2 2>/dev/null || true
                log_info "Apache2服务已禁用"
            fi
            
            zypper install -y git curl wget gcc gcc-c++ make
            ;;
    esac
}

# 安装最小依赖（包括PHP和MySQL）
install_minimal_dependencies() {
    log_info "安装最小依赖（包括PHP和MySQL）..."
    
    case $PACKAGE_MANAGER in
        "apt")
            apt-get update
            apt-get install -y python$PYTHON_VERSION python$PYTHON_VERSION-venv python3-pip
            # 尝试安装MySQL，支持多种包名
            log_info "尝试安装MySQL..."
            mysql_installed=false
            
            # 尝试MySQL 8.0特定版本
            if apt-get install -y mysql-server-$MYSQL_VERSION mysql-client-$MYSQL_VERSION 2>/dev/null; then
                log_success "MySQL $MYSQL_VERSION 安装成功"
                mysql_installed=true
            # 尝试默认MySQL包
            elif apt-get install -y mysql-server mysql-client 2>/dev/null; then
                log_success "MySQL默认版本安装成功"
                mysql_installed=true
            # 尝试MariaDB作为替代
            elif apt-get install -y mariadb-server mariadb-client 2>/dev/null; then
                log_success "MariaDB安装成功（MySQL替代方案）"
                mysql_installed=true
            # 尝试MySQL 5.7
            elif apt-get install -y mysql-server-5.7 mysql-client-5.7 2>/dev/null; then
                log_success "MySQL 5.7安装成功"
                mysql_installed=true
            else
                log_error "无法安装MySQL或MariaDB"
                log_info "请手动安装数据库："
                log_info "  Ubuntu/Debian: sudo apt-get install mariadb-server"
                log_info "  或者: sudo apt-get install mysql-server"
                exit 1
            fi
            
            # 安装PHP和PHP-FPM
            log_info "安装PHP和PHP-FPM..."
            
            # 首先尝试安装指定版本的PHP
            php_installed=false
            if apt-get install -y php$PHP_VERSION php$PHP_VERSION-fpm php$PHP_VERSION-cli php$PHP_VERSION-curl php$PHP_VERSION-json php$PHP_VERSION-mbstring php$PHP_VERSION-mysql php$PHP_VERSION-xml php$PHP_VERSION-zip; then
                log_success "PHP $PHP_VERSION 安装成功"
                php_installed=true
            else
                log_warning "PHP $PHP_VERSION 安装失败，尝试安装默认PHP版本..."
                
                # 尝试安装默认PHP版本
                if apt-get install -y php php-fpm php-cli php-curl php-json php-mbstring php-mysql php-xml php-zip; then
                    log_success "PHP默认版本安装成功"
                    # 更新PHP_VERSION变量为实际安装的版本
                    PHP_VERSION=$(php -v | grep -oP 'PHP \K[0-9]+\.[0-9]+' | head -1)
                    log_info "检测到PHP版本: $PHP_VERSION"
                    php_installed=true
                else
                    # 尝试查找可用的PHP版本
                    log_info "查找可用的PHP版本..."
                    available_versions=$(apt-cache search ^php[0-9]+\.[0-9]+$ | grep -oP 'php\K[0-9]+\.[0-9]+' | sort -V | tail -5)
                    
                    if [[ -n "$available_versions" ]]; then
                        log_info "可用的PHP版本: $available_versions"
                        for version in $available_versions; do
                            log_info "尝试安装PHP $version..."
                            if apt-get install -y php$version php$version-fpm php$version-cli php$version-curl php$version-json php$version-mbstring php$version-mysql php$version-xml php$version-zip; then
                                log_success "PHP $version 安装成功"
                                PHP_VERSION=$version
                                php_installed=true
                                break
                            fi
                        done
                    fi
                fi
            fi
            
            if [[ "$php_installed" = false ]]; then
                log_error "无法安装PHP，请检查软件源或手动安装"
                log_info "手动安装命令："
                log_info "  Ubuntu/Debian: sudo apt-get install php php-fpm"
                log_info "  或者添加PHP软件源："
                log_info "  sudo apt-get install software-properties-common"
                log_info "  sudo add-apt-repository ppa:ondrej/php"
                log_info "  sudo apt-get update"
                exit 1
            fi
            
            # 确保只安装nginx，不安装apache
            apt-get install -y nginx
            
            # 检查并禁用apache服务（如果存在）
            if systemctl list-unit-files | grep -q "apache2.service"; then
                log_info "检测到Apache2服务，正在禁用..."
                systemctl stop apache2 2>/dev/null || true
                systemctl disable apache2 2>/dev/null || true
                log_info "Apache2服务已禁用"
            fi
            
            apt-get install -y git curl wget
            ;;
        "yum"|"dnf")
            $PACKAGE_MANAGER install -y python$PYTHON_VERSION python$PYTHON_VERSION-pip
            $PACKAGE_MANAGER install -y mysql-server mysql
            
            # 安装PHP和PHP-FPM
            log_info "安装PHP和PHP-FPM..."
            if $PACKAGE_MANAGER install -y php php-fpm php-cli php-curl php-json php-mbstring php-mysql php-xml php-zip; then
                log_success "PHP安装成功"
            else
                log_error "PHP安装失败"
                log_info "请手动安装PHP："
                log_info "  CentOS/RHEL: sudo yum install php php-fpm"
                exit 1
            fi
            
            $PACKAGE_MANAGER install -y nginx
            
            # 检查并禁用apache服务（如果存在）
            if systemctl list-unit-files | grep -q "httpd.service"; then
                log_info "检测到Apache(httpd)服务，正在禁用..."
                systemctl stop httpd 2>/dev/null || true
                systemctl disable httpd 2>/dev/null || true
                log_info "Apache(httpd)服务已禁用"
            fi
            
            $PACKAGE_MANAGER install -y git curl wget gcc gcc-c++ make
            ;;
        "pacman")
            pacman -S --noconfirm python python-pip mysql nginx
            
            # 检查并禁用apache服务（如果存在）
            if systemctl list-unit-files | grep -q "httpd.service"; then
                log_info "检测到Apache(httpd)服务，正在禁用..."
                systemctl stop httpd 2>/dev/null || true
                systemctl disable httpd 2>/dev/null || true
                log_info "Apache(httpd)服务已禁用"
            fi
            
            # 安装PHP和PHP-FPM
            log_info "安装PHP和PHP-FPM..."
            if pacman -S --noconfirm php php-fpm; then
                log_success "PHP安装成功"
            else
                log_error "PHP安装失败"
                log_info "请手动安装PHP："
                log_info "  Arch Linux: sudo pacman -S php php-fpm"
                exit 1
            fi
            
            pacman -S --noconfirm git curl wget
            ;;
        "zypper")
            zypper install -y python$PYTHON_VERSION python$PYTHON_VERSION-pip
            zypper install -y mysql mysql-server
            
            # 安装PHP和PHP-FPM
            log_info "安装PHP和PHP-FPM..."
            if zypper install -y php php-fpm php-cli php-curl php-json php-mbstring php-mysql php-xml php-zip; then
                log_success "PHP安装成功"
            else
                log_error "PHP安装失败"
                log_info "请手动安装PHP："
                log_info "  openSUSE: sudo zypper install php php-fpm"
                exit 1
            fi
            
            zypper install -y nginx
            zypper install -y git curl wget
            ;;
    esac
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
        groupadd "$SERVICE_GROUP"
        log_success "创建组: $SERVICE_GROUP"
    else
        log_info "组已存在: $SERVICE_GROUP"
    fi
}

# 下载项目
download_project() {
    log_info "下载项目源码..."
    
    # 创建安装目录
    mkdir -p "$INSTALL_DIR"
    
    # 如果目录已存在且有内容，备份
    if [[ -d "$INSTALL_DIR" && "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]]; then
        log_info "目录已存在，备份旧版本..."
        mv "$INSTALL_DIR" "$INSTALL_DIR.backup.$(date +%s)"
        mkdir -p "$INSTALL_DIR"
    fi
    
    # 克隆项目
    git clone "$PROJECT_REPO" "$INSTALL_DIR"
    
    # 设置权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    
    log_success "项目下载完成"
}

# 安装应用依赖
install_application_dependencies() {
    log_info "安装应用依赖..."
    
    # 安装后端依赖
    cd "$INSTALL_DIR/backend"
    
    # 创建虚拟环境
    python$PYTHON_VERSION -m venv venv
    source venv/bin/activate
    
    # 安装Python依赖
    pip install --upgrade pip
    pip install -r requirements.txt
    
    # 前端已迁移到PHP，不再需要npm构建
    
    log_success "应用依赖安装完成"
}

# 构建前端
# 前端已迁移到PHP，不再需要构建函数

# 部署PHP前端
deploy_php_frontend() {
    log_info "部署PHP前端文件..."
    
    # 检查PHP前端目录是否存在
    local php_frontend_dir="$INSTALL_DIR/php-frontend"
    if [[ ! -d "$php_frontend_dir" ]]; then
        log_error "PHP前端目录不存在: $php_frontend_dir"
        log_info "请确保项目已正确下载"
        return 1
    fi
    
    # 创建Web目录
    local web_dir="/var/www/html"
    if [[ ! -d "$web_dir" ]]; then
        log_info "创建Web目录: $web_dir"
        mkdir -p "$web_dir"
    fi
    
    # 复制PHP前端文件
    log_info "复制PHP前端文件到Web目录..."
    cp -r "$php_frontend_dir"/* "$web_dir/"
    
    # 创建配置文件
    log_info "创建前端配置文件..."
    mkdir -p "$web_dir/config"
    cat > "$web_dir/config/config.php" << EOF
<?php
// 应用配置
define('APP_NAME', 'IPv6 WireGuard Manager');
define('APP_VERSION', '3.0.0');
define('APP_DEBUG', false);

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
error_reporting(0);
ini_set('display_errors', 0);

// 时区设置
date_default_timezone_set('Asia/Shanghai');

// 字符编码
mb_internal_encoding('UTF-8');
mb_http_output('UTF-8');
?>
EOF
    
    # 设置权限
    chown -R "www-data:www-data" "$web_dir"
    chmod -R 755 "$web_dir"
    
    # 启动PHP-FPM服务
    log_info "启动PHP-FPM服务..."
    
    # 检测PHP-FPM服务名称
    php_fpm_service=""
    if systemctl list-units --type=service | grep -q "php$PHP_VERSION-fpm"; then
        php_fpm_service="php$PHP_VERSION-fpm"
    elif systemctl list-units --type=service | grep -q "php-fpm"; then
        php_fpm_service="php-fpm"
    elif systemctl list-units --type=service | grep -q "php${PHP_VERSION/./}-fpm"; then
        php_fpm_service="php${PHP_VERSION/./}-fpm"
    else
        log_error "无法找到PHP-FPM服务"
        return 1
    fi
    
    if systemctl is-active --quiet $php_fpm_service 2>/dev/null; then
        log_info "PHP-FPM服务已在运行"
    else
        systemctl enable $php_fpm_service
        systemctl start $php_fpm_service
        if systemctl is-active --quiet $php_fpm_service; then
            log_success "PHP-FPM服务启动成功"
        else
            log_error "PHP-FPM服务启动失败"
            return 1
        fi
    fi
    
    log_success "PHP前端部署完成"
    return 0
}

# 创建环境变量文件
create_environment_file() {
    log_info "创建环境变量文件..."
    
    cd "$INSTALL_DIR/backend"
    
    # 使用环境配置生成器
    if [ -f "scripts/generate_environment.py" ]; then
        log_info "使用智能环境配置生成器..."
        python scripts/generate_environment.py --mode native --output .env --show-config
    else
        # 回退到手动配置
        log_info "使用手动环境配置..."
        cat > .env << EOF
# 数据库配置
DATABASE_URL=mysql://$SERVICE_USER:password@localhost:3306/ipv6wgm
REDIS_URL=redis://localhost:6379/0
USE_SQLITE_FALLBACK=false
AUTO_CREATE_DATABASE=true

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=$API_PORT
DEBUG=$DEBUG

# 安全配置
SECRET_KEY=$(openssl rand -hex 32)
ACCESS_TOKEN_EXPIRE_MINUTES=10080

# 日志配置
LOG_LEVEL=info
LOG_FILE=
LOG_ROTATION=1 day
LOG_RETENTION=30 days

# 性能配置
MAX_WORKERS=4
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=30
DATABASE_POOL_RECYCLE=3600
DATABASE_POOL_PRE_PING=true

# 监控配置
ENABLE_HEALTH_CHECK=true
HEALTH_CHECK_INTERVAL=30
EOF
    fi
    
    # 设置权限
    chown "$SERVICE_USER:$SERVICE_GROUP" .env
    chmod 600 .env
    
    log_success "环境变量文件创建完成"
}

# 安装核心依赖
install_core_dependencies() {
    log_info "安装核心依赖..."
    
    cd "$INSTALL_DIR/backend" || {
        log_error "无法进入后端目录: $INSTALL_DIR/backend"
        exit 1
    }
    
    # 创建虚拟环境
    log_info "创建Python虚拟环境..."
    if ! python$PYTHON_VERSION -m venv venv; then
        log_error "创建虚拟环境失败"
        exit 1
    fi
    
    # 激活虚拟环境
    source venv/bin/activate || {
        log_error "激活虚拟环境失败"
        exit 1
    }
    
    # 安装核心Python依赖
    log_info "升级pip..."
    if ! pip install --upgrade pip; then
        log_error "升级pip失败"
        exit 1
    fi
    
    log_info "安装Python依赖包..."
    if ! pip install -r requirements-minimal.txt; then
        log_error "安装Python依赖失败，尝试单独安装关键依赖..."
        
        # 尝试单独安装关键依赖
        key_packages=(
            "fastapi==0.104.1"
            "uvicorn[standard]==0.24.0"
            "pydantic==2.5.0"
            "pydantic-settings==2.1.0"
            "sqlalchemy==2.0.23"
            "pymysql==1.1.0"
            "python-dotenv==1.0.0"
            "python-jose[cryptography]>=3.3.0"
            "passlib[bcrypt]>=1.7.4"
            "python-multipart>=0.0.6"
            "click==8.1.7"
            "cryptography>=41.0.0,<47.0.0"
            "psutil==5.9.6"
            "email-validator==2.1.0"
        )
        
        for package in "${key_packages[@]}"; do
            log_info "安装: $package"
            if pip install "$package"; then
                log_success "$package 安装成功"
            else
                log_warning "$package 安装失败，继续下一个"
            fi
        done
        
        # 验证关键依赖
        log_info "验证关键依赖..."
        if python -c "import fastapi, uvicorn, pydantic, sqlalchemy, pymysql, dotenv" 2>/dev/null; then
            log_success "关键依赖验证通过"
        else
            log_error "关键依赖验证失败"
            exit 1
        fi
    fi
    
    log_success "核心依赖安装完成"
}

# 配置数据库
configure_database() {
    log_info "配置数据库..."
    
    # 启动MySQL
    systemctl enable mysql
    systemctl start mysql
    
    # 等待MySQL启动
    sleep 5
    
    # 创建数据库和用户
    mysql -e "CREATE DATABASE IF NOT EXISTS ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || log_info "数据库ipv6wgm已存在"
    mysql -e "CREATE USER IF NOT EXISTS '$SERVICE_USER'@'localhost' IDENTIFIED BY 'password';" 2>/dev/null || log_info "用户$SERVICE_USER已存在"
    mysql -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO '$SERVICE_USER'@'localhost';" 2>/dev/null || log_info "权限已设置"
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || log_info "权限刷新完成"
    
    # 启动Redis
    systemctl enable redis-server
    systemctl start redis-server
    
    # 等待Redis启动
    sleep 3
    
    # 初始化数据库
    cd "$INSTALL_DIR/backend"
    python scripts/init_database_mysql.py
    
    log_success "数据库配置完成"
}

# 配置最小化MySQL数据库（低内存优化）
configure_minimal_mysql_database() {
    log_info "配置最小化MySQL数据库（低内存优化）..."
    
    # 检测数据库服务名称
    log_info "检测数据库服务..."
    
    # 尝试多种检测方法
    if systemctl list-unit-files | grep -q "mysql.service" && systemctl is-enabled mysql.service 2>/dev/null; then
        DB_SERVICE="mysql"
        DB_COMMAND="mysql"
        log_info "检测到MySQL服务"
    elif systemctl list-unit-files | grep -q "mariadb.service" && systemctl is-enabled mariadb.service 2>/dev/null; then
        DB_SERVICE="mariadb"
        DB_COMMAND="mysql"  # MariaDB也使用mysql命令
        log_info "检测到MariaDB服务"
    elif systemctl is-enabled mysql.service 2>/dev/null; then
        DB_SERVICE="mysql"
        DB_COMMAND="mysql"
        log_info "检测到MySQL服务（通过is-enabled）"
    elif systemctl is-enabled mariadb.service 2>/dev/null; then
        DB_SERVICE="mariadb"
        DB_COMMAND="mysql"
        log_info "检测到MariaDB服务（通过is-enabled）"
    elif systemctl status mysql.service 2>/dev/null | grep -q "Active:"; then
        DB_SERVICE="mysql"
        DB_COMMAND="mysql"
        log_info "检测到MySQL服务（通过status）"
    elif systemctl status mariadb.service 2>/dev/null | grep -q "Active:"; then
        DB_SERVICE="mariadb"
        DB_COMMAND="mysql"
        log_info "检测到MariaDB服务（通过status）"
    else
        log_error "未找到MySQL或MariaDB服务"
        log_info "尝试手动启动服务..."
        
        # 尝试启动MySQL
        if systemctl start mysql.service 2>/dev/null; then
            DB_SERVICE="mysql"
            DB_COMMAND="mysql"
            log_info "成功启动MySQL服务"
        # 尝试启动MariaDB
        elif systemctl start mariadb.service 2>/dev/null; then
            DB_SERVICE="mariadb"
            DB_COMMAND="mysql"
            log_info "成功启动MariaDB服务"
        else
            log_error "无法启动MySQL或MariaDB服务"
            log_info "请检查数据库安装状态："
            log_info "  systemctl status mysql"
            log_info "  systemctl status mariadb"
            log_info "  dpkg -l | grep mysql"
            log_info "  dpkg -l | grep mariadb"
            exit 1
        fi
    fi
    
    log_info "检测到数据库服务: $DB_SERVICE"
    
    # 启动数据库服务
    log_info "启动$DB_SERVICE服务..."
    if ! systemctl enable $DB_SERVICE; then
        log_error "启用$DB_SERVICE服务失败"
        exit 1
    fi
    
    if ! systemctl start $DB_SERVICE; then
        log_error "启动$DB_SERVICE服务失败"
        exit 1
    fi
    
    # 等待数据库启动
    log_info "等待$DB_SERVICE服务启动..."
    sleep 5
    
    # 检查数据库是否正常运行
    if ! systemctl is-active --quiet $DB_SERVICE; then
        log_error "$DB_SERVICE服务未正常运行"
        exit 1
    fi
    
    # 创建数据库和用户
    log_info "创建数据库和用户..."
    $DB_COMMAND -e "CREATE DATABASE IF NOT EXISTS ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || log_info "数据库ipv6wgm已存在"
    $DB_COMMAND -e "CREATE USER IF NOT EXISTS '$SERVICE_USER'@'localhost' IDENTIFIED BY 'password';" 2>/dev/null || log_info "用户$SERVICE_USER已存在"
    $DB_COMMAND -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO '$SERVICE_USER'@'localhost';" 2>/dev/null || log_info "权限已设置"
    $DB_COMMAND -e "FLUSH PRIVILEGES;" 2>/dev/null || log_info "权限刷新完成"
    
    # 优化数据库配置以节省内存
    log_info "优化数据库配置以节省内存..."
    
    # 根据数据库类型选择配置路径
    if [ "$DB_SERVICE" = "mysql" ]; then
        CONFIG_DIR="/etc/mysql/mysql.conf.d"
    else
        CONFIG_DIR="/etc/mysql/conf.d"
    fi
    
    # 确保配置目录存在
    mkdir -p "$CONFIG_DIR"
    
    cat > "$CONFIG_DIR/99-low-memory.cnf" << EOF
[mysqld]
# 低内存优化配置
innodb_buffer_pool_size = 64M
innodb_log_buffer_size = 8M
innodb_log_file_size = 16M
key_buffer_size = 16M
max_connections = 50
thread_cache_size = 4
query_cache_size = 8M
tmp_table_size = 16M
max_heap_table_size = 16M
sort_buffer_size = 256K
read_buffer_size = 128K
read_rnd_buffer_size = 256K
join_buffer_size = 128K
EOF
    
    # 重启数据库应用配置
    log_info "重启$DB_SERVICE应用配置..."
    if ! systemctl restart $DB_SERVICE; then
        log_error "重启$DB_SERVICE失败"
        exit 1
    fi
    sleep 3
    
    # 检查数据库是否正常运行
    if ! systemctl is-active --quiet $DB_SERVICE; then
        log_error "$DB_SERVICE重启后未正常运行"
        exit 1
    fi
    
    cd "$INSTALL_DIR/backend" || {
        log_error "无法进入后端目录: $INSTALL_DIR/backend"
        exit 1
    }
    
    source venv/bin/activate || {
        log_error "激活虚拟环境失败"
        exit 1
    }
    
    # 创建环境变量文件（低内存优化）
    log_info "创建环境变量文件..."
    
    # 使用环境配置生成器
    if [ -f "scripts/generate_environment.py" ]; then
        log_info "使用智能环境配置生成器（低内存优化）..."
        python scripts/generate_environment.py --mode minimal --profile low_memory --output .env --show-config
    else
        # 回退到手动配置
        log_info "使用手动环境配置（低内存优化）..."
        cat > .env << EOF
# 数据库配置 - 低内存优化
DATABASE_URL=mysql://$SERVICE_USER:password@localhost:3306/ipv6wgm
AUTO_CREATE_DATABASE=true

# Redis配置 - 低内存优化（禁用）
USE_REDIS=false
REDIS_URL=

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=$API_PORT
DEBUG=$DEBUG

# 安全配置
SECRET_KEY=$(openssl rand -hex 32)
ACCESS_TOKEN_EXPIRE_MINUTES=10080

# 性能配置 - 低内存优化
DATABASE_POOL_SIZE=5
DATABASE_MAX_OVERFLOW=10
MAX_WORKERS=2
EOF
    fi
    
    # 初始化数据库
    log_info "初始化数据库..."
    if ! python scripts/init_database_mysql.py; then
        log_error "数据库初始化失败"
        exit 1
    fi
    
    log_success "最小化MySQL数据库配置完成"
}

# 配置Nginx
configure_nginx() {
    log_info "配置Nginx..."
    
    # 禁用默认站点
    log_info "禁用Nginx默认站点..."
    rm -f /etc/nginx/sites-enabled/default
    
    # 检测PHP-FPM socket路径
    php_fpm_socket=""
    if [[ -f "/var/run/php/php$PHP_VERSION-fpm.sock" ]]; then
        php_fpm_socket="/var/run/php/php$PHP_VERSION-fpm.sock"
    elif [[ -f "/var/run/php/php-fpm.sock" ]]; then
        php_fpm_socket="/var/run/php/php-fpm.sock"
    elif [[ -f "/run/php/php$PHP_VERSION-fpm.sock" ]]; then
        php_fpm_socket="/run/php/php$PHP_VERSION-fpm.sock"
    elif [[ -f "/run/php/php-fpm.sock" ]]; then
        php_fpm_socket="/run/php/php-fpm.sock"
    elif [[ -f "/var/run/php-fpm/php-fpm.sock" ]]; then
        php_fpm_socket="/var/run/php-fpm/php-fpm.sock"
    else
        # 尝试查找任何PHP-FPM socket文件
        php_fpm_socket=$(find /var/run /run -name "php*-fpm.sock" 2>/dev/null | head -1)
        if [[ -z "$php_fpm_socket" ]]; then
            log_warning "未找到PHP-FPM socket文件，使用默认路径"
            php_fpm_socket="/var/run/php/php$PHP_VERSION-fpm.sock"
        fi
    fi
    
    log_info "使用PHP-FPM socket: $php_fpm_socket"
    
    # 创建Nginx配置
    log_info "创建项目Nginx配置..."
    cat > /etc/nginx/sites-available/ipv6-wireguard-manager << EOF
server {
    listen $WEB_PORT;
    listen [::]:$WEB_PORT;
    server_name _;
    
    # 网站根目录
    root /var/www/html;
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
    
    # 客户端最大上传大小
    client_max_body_size 10M;
    
    # 超时设置
    client_body_timeout 60s;
    client_header_timeout 60s;
    keepalive_timeout 65s;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
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
    
    # PHP文件处理
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:$php_fpm_socket;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # 后端API
    location /api/ {
        proxy_pass http://127.0.0.1:$API_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 添加CORS头
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization";
        
        # 处理预检请求
        if (\$request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization";
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain; charset=utf-8';
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # WebSocket支持
    location /ws/ {
        proxy_pass http://127.0.0.1:$API_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:$API_PORT/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # 默认路由处理
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
}
EOF
    
    # 启用站点
    log_info "启用项目站点..."
    ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
    
    # 测试配置
    log_info "测试Nginx配置..."
    if nginx -t; then
        log_success "Nginx配置语法正确"
    else
        log_error "Nginx配置语法错误"
        exit 1
    fi
    
    # 启动和启用Nginx
    log_info "启动Nginx服务..."
    systemctl enable nginx
    systemctl restart nginx
    
    # 检查服务状态
    if systemctl is-active --quiet nginx; then
        log_success "Nginx服务启动成功"
    else
        log_error "Nginx服务启动失败"
        exit 1
    fi
    
    log_success "Nginx配置完成"
}

# 创建系统服务
create_system_service() {
    log_info "创建系统服务..."
    
    # 创建systemd服务文件
    cat > /etc/systemd/system/ipv6-wireguard-manager.service << EOF
[Unit]
Description=IPv6 WireGuard Manager
After=network.target mysql.service redis-server.service
Wants=mysql.service redis-server.service

[Service]
Type=exec
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$INSTALL_DIR/backend
Environment=PATH=$INSTALL_DIR/backend/venv/bin
ExecStart=$INSTALL_DIR/backend/venv/bin/uvicorn app.main:app --host :: --port $API_PORT --workers 4
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载systemd
    systemctl daemon-reload
    systemctl enable ipv6-wireguard-manager
    
    log_success "系统服务创建完成"
}

# 创建简单服务
create_simple_service() {
    log_info "创建简单服务..."
    
    # 创建简单的systemd服务文件
    log_info "创建systemd服务文件..."
    cat > /etc/systemd/system/ipv6-wireguard-manager.service << EOF
[Unit]
Description=IPv6 WireGuard Manager (Minimal)
After=network.target mysql.service mariadb.service

[Service]
Type=exec
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$INSTALL_DIR/backend
Environment=PATH=$INSTALL_DIR/backend/venv/bin
ExecStart=$INSTALL_DIR/backend/venv/bin/uvicorn app.main:app --host :: --port $API_PORT --workers 2
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    if [ ! -f /etc/systemd/system/ipv6-wireguard-manager.service ]; then
        log_error "创建服务文件失败"
        exit 1
    fi
    
    # 重新加载systemd
    log_info "重新加载systemd配置..."
    if ! systemctl daemon-reload; then
        log_error "重新加载systemd配置失败"
        exit 1
    fi
    
    if ! systemctl enable ipv6-wireguard-manager; then
        log_error "启用服务失败"
        exit 1
    fi
    
    log_success "简单服务创建完成"
}

# 配置Docker环境
configure_docker_environment() {
    log_info "配置Docker环境..."
    
    cd "$INSTALL_DIR"
    
    # 根据内存选择Docker配置
    if [ "$MEMORY_MB" -lt 2048 ]; then
        log_info "检测到低内存环境，使用低内存优化配置"
        # 使用低内存Docker配置
        if [ -f docker-compose.low-memory.yml ]; then
            cp docker-compose.low-memory.yml docker-compose.yml
        fi
        
        # 创建环境变量文件（低内存优化）
        if [ -f "backend/scripts/generate_environment.py" ]; then
            log_info "使用智能环境配置生成器（Docker低内存优化）..."
            cd backend
            python scripts/generate_environment.py --mode docker --profile low_memory --output ../.env --show-config
            cd ..
        else
            cat > .env << EOF
# 数据库配置 - 低内存优化
DATABASE_URL=mysql://$SERVICE_USER:password@mysql:3306/ipv6wgm

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=$API_PORT
DEBUG=$DEBUG

# 安全配置
SECRET_KEY=$(openssl rand -hex 32)
ACCESS_TOKEN_EXPIRE_MINUTES=10080

# 性能配置 - 低内存优化
DATABASE_POOL_SIZE=5
DATABASE_MAX_OVERFLOW=10
MAX_WORKERS=2
EOF
        fi
    else
        # 创建环境变量文件（标准配置）
        if [ -f "backend/scripts/generate_environment.py" ]; then
            log_info "使用智能环境配置生成器（Docker标准配置）..."
            cd backend
            python scripts/generate_environment.py --mode docker --profile standard --output ../.env --show-config
            cd ..
        else
            cat > .env << EOF
# 数据库配置
DATABASE_URL=mysql://$SERVICE_USER:password@mysql:3306/ipv6wgm
REDIS_URL=redis://redis:6379/0

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=$API_PORT
DEBUG=$DEBUG

# 安全配置
SECRET_KEY=$(openssl rand -hex 32)
ACCESS_TOKEN_EXPIRE_MINUTES=10080
EOF
        fi
    fi
    
    # 修改docker-compose.yml中的端口配置
    if [ -f docker-compose.yml ]; then
        sed -i "s/80:80/$WEB_PORT:80/g" docker-compose.yml
        sed -i "s/8000:8000/$API_PORT:8000/g" docker-compose.yml
    fi
    
    log_success "Docker环境配置完成"
}

# 启动Docker服务
start_docker_services() {
    log_info "启动Docker服务..."
    
    cd "$INSTALL_DIR"
    
    # 启动服务
    docker-compose up -d
    
    # 等待服务启动
    sleep 10
    
    # 检查服务状态
    docker-compose ps
    
    log_success "Docker服务启动完成"
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    # 启动应用服务
    systemctl start ipv6-wireguard-manager
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    systemctl status ipv6-wireguard-manager --no-pager
    
    log_success "服务启动完成"
}

# 启动最小服务
start_minimal_services() {
    log_info "启动最小服务..."
    
    # 启动应用服务
    log_info "启动IPv6 WireGuard Manager服务..."
    if ! systemctl start ipv6-wireguard-manager; then
        log_error "启动服务失败"
        log_info "查看服务日志:"
        journalctl -u ipv6-wireguard-manager --no-pager -n 20
        exit 1
    fi
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 5
    
    # 检查服务状态
    if ! systemctl is-active --quiet ipv6-wireguard-manager; then
        log_error "服务启动后未正常运行"
        log_info "查看服务状态:"
        systemctl status ipv6-wireguard-manager --no-pager
        log_info "查看服务日志:"
        journalctl -u ipv6-wireguard-manager --no-pager -n 20
        exit 1
    fi
    
    log_info "服务状态:"
    systemctl status ipv6-wireguard-manager --no-pager
    
    log_success "最小服务启动完成"
}

# 运行环境检查
run_environment_check() {
    log_info "运行环境检查..."
    
    cd "$INSTALL_DIR/backend" || {
        log_error "无法进入后端目录: $INSTALL_DIR/backend"
        exit 1
    }
    
    # 激活虚拟环境并运行检查
    if [ -f "venv/bin/activate" ]; then
        log_info "激活虚拟环境并运行环境检查..."
        source venv/bin/activate || {
            log_error "激活虚拟环境失败"
            exit 1
        }
        
        if ! python scripts/check_environment.py; then
            log_error "环境检查失败"
            exit 1
        fi
    else
        log_warning "虚拟环境不存在，跳过环境检查"
    fi
}

# 显示安装完成信息
show_installation_complete() {
    echo ""
    echo "=========================================="
    echo "🎉 $PROJECT_NAME 安装完成！"
    echo "=========================================="
    echo ""
    log_success "安装成功完成！"
    echo ""
    log_info "安装信息:"
    log_info "  安装类型: $INSTALL_TYPE"
    log_info "  安装目录: $INSTALL_DIR"
    log_info "  Web端口: $WEB_PORT"
    log_info "  API端口: $API_PORT"
    log_info "  服务用户: $SERVICE_USER"
    log_info "  操作系统: $OS_NAME"
    echo ""
    log_info "访问地址:"
    
    # 获取本机IP地址
    get_local_ips() {
        local ipv4_ips=()
        local ipv6_ips=()
        
        # 获取IPv4地址 - 改进的获取方法
        log_info "   正在获取IPv4地址..."
        
        # 方法1: 使用ip命令获取所有IPv4地址
        if command -v ip &> /dev/null; then
            while IFS= read -r line; do
                if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $line != "127.0.0.1" ]]; then
                    ipv4_ips+=("$line")
                    log_info "     ✅ 发现IPv4地址: $line"
                fi
            done < <(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null)
        else
            log_warning "     ip命令不可用"
        fi
        
        # 方法2: 如果ip命令失败，尝试ifconfig
        if [ ${#ipv4_ips[@]} -eq 0 ] && command -v ifconfig &> /dev/null; then
            log_info "    尝试使用ifconfig获取IPv4地址..."
            while IFS= read -r line; do
                if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $line != "127.0.0.1" ]]; then
                    ipv4_ips+=("$line")
                    log_info "     ✅ 发现IPv4地址: $line"
                fi
            done < <(ifconfig 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1')
        fi
        
        # 方法3: 如果还是失败，尝试hostname -I
        if [ ${#ipv4_ips[@]} -eq 0 ]; then
            log_info "    尝试使用hostname -I获取IPv4地址..."
            while IFS= read -r line; do
                if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $line != "127.0.0.1" ]]; then
                    ipv4_ips+=("$line")
                    log_info "     ✅ 发现IPv4地址: $line"
                fi
            done < <(hostname -I 2>/dev/null | tr ' ' '\n' | grep -v '127.0.0.1')
        fi
        
        if [ ${#ipv4_ips[@]} -eq 0 ]; then
            log_warning "     ⚠️  未发现IPv4地址"
        fi
        
        # 获取IPv6地址 - 改进的获取方法
        log_info "   正在获取IPv6地址..."
        
        # 方法1: 使用ip命令获取所有IPv6地址
        if command -v ip &> /dev/null; then
            while IFS= read -r line; do
                # 提取IPv6地址（去除前缀部分）
                ipv6_addr=$(echo "$line" | cut -d'/' -f1)
                if [[ $ipv6_addr =~ ^[0-9a-fA-F:]+$ ]] && [[ $ipv6_addr != "::1" ]] && [[ ! $ipv6_addr =~ ^fe80: ]]; then
                    ipv6_ips+=("$ipv6_addr")
                    log_info "     ✅ 发现IPv6地址: $ipv6_addr"
                fi
            done < <(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+/[0-9]+' 2>/dev/null | grep -v '::1' | grep -v '^fe80:')
        else
            log_warning "     ip命令不可用"
        fi
        
        # 方法2: 如果ip命令失败，尝试ifconfig
        if [ ${#ipv6_ips[@]} -eq 0 ] && command -v ifconfig &> /dev/null; then
            log_info "    尝试使用ifconfig获取IPv6地址..."
            while IFS= read -r line; do
                # 提取IPv6地址（去除前缀部分）
                ipv6_addr=$(echo "$line" | cut -d'/' -f1)
                if [[ $ipv6_addr =~ ^[0-9a-fA-F:]+$ ]] && [[ $ipv6_addr != "::1" ]] && [[ ! $ipv6_addr =~ ^fe80: ]]; then
                    ipv6_ips+=("$ipv6_addr")
                    log_info "     ✅ 发现IPv6地址: $ipv6_addr"
                fi
            done < <(ifconfig 2>/dev/null | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+/[0-9]+' | grep -v '::1' | grep -v '^fe80:')
        fi
        
        if [ ${#ipv6_ips[@]} -eq 0 ]; then
            log_warning "     ⚠️  未发现IPv6地址"
        fi
        
        # 显示访问地址
        log_info "  📱 本地访问:"
        log_info "    前端界面: http://localhost:$WEB_PORT"
        log_info "    API文档: http://localhost:$WEB_PORT/api/v1/docs"
        log_info "    健康检查: http://localhost:$API_PORT/health"
        
        if [ ${#ipv4_ips[@]} -gt 0 ]; then
            log_info "  🌐 IPv4访问:"
            for ip in "${ipv4_ips[@]}"; do
                log_info "    前端界面: http://$ip:$WEB_PORT"
                log_info "    API文档: http://$ip:$WEB_PORT/api/v1/docs"
                log_info "    健康检查: http://$ip:$API_PORT/health"
            done
        fi
        
        if [ ${#ipv6_ips[@]} -gt 0 ]; then
            log_info "  🔗 IPv6访问:"
            for ip in "${ipv6_ips[@]}"; do
                log_info "    前端界面: http://[$ip]:$WEB_PORT"
                log_info "    API文档: http://[$ip]:$WEB_PORT/api/v1/docs"
                log_info "    健康检查: http://[$ip]:$API_PORT/health"
            done
        fi
    }
    
    get_local_ips
    echo ""
    log_info "管理命令:"
    log_info "  启动服务: systemctl start ipv6-wireguard-manager"
    log_info "  停止服务: systemctl stop ipv6-wireguard-manager"
    log_info "  重启服务: systemctl restart ipv6-wireguard-manager"
    log_info "  查看状态: systemctl status ipv6-wireguard-manager"
    log_info "  查看日志: journalctl -u ipv6-wireguard-manager -f"
    echo ""
    log_info "默认登录信息:"
    log_info "  用户名: admin"
    log_info "  密码: admin123"
    echo ""
    log_info "更多信息:"
    log_info "  项目地址: $PROJECT_REPO"
    log_info "  问题反馈: $PROJECT_REPO/issues"
    echo ""
}

# Run main function
main "$@"