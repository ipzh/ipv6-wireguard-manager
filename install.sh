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
FRONTEND_DIR="/var/www/html"
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
AUTO_EXIT=false

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
    
    # 检测PHP版本
    detect_php_version() {
        log_info "🔍 检测PHP版本..."
        
        # 检测已安装的PHP版本
        if command -v php &> /dev/null; then
            PHP_VERSION=$(php -v | grep -oP 'PHP \K[0-9]+\.[0-9]+' | head -1)
            log_success "检测到已安装的PHP版本: $PHP_VERSION"
            return 0
        fi
        
        # 检测可用的PHP版本
        case $PACKAGE_MANAGER in
            "apt")
                # 检测可用的PHP版本
                local available_versions=()
                for version in 8.2 8.1 8.0 7.4; do
                    if apt-cache show php$version-fpm &>/dev/null; then
                        available_versions+=($version)
                    fi
                done
                
                if [[ ${#available_versions[@]} -gt 0 ]]; then
                    PHP_VERSION=${available_versions[0]}
                    log_success "检测到可用PHP版本: $PHP_VERSION"
                else
                    PHP_VERSION="8.1"  # 默认版本
                    log_warning "未检测到PHP版本，使用默认版本: $PHP_VERSION"
                fi
                ;;
            "yum"|"dnf")
                # RHEL/CentOS通常使用默认PHP版本
                PHP_VERSION="8.0"  # 默认版本
                log_info "RHEL/CentOS系统，使用默认PHP版本: $PHP_VERSION"
                ;;
            "pacman")
                # Arch Linux通常使用最新版本
                PHP_VERSION="8.2"  # 默认版本
                log_info "Arch Linux系统，使用默认PHP版本: $PHP_VERSION"
                ;;
            *)
                PHP_VERSION="8.1"  # 默认版本
                log_warning "未知系统，使用默认PHP版本: $PHP_VERSION"
                ;;
        esac
        
        log_info "选择的PHP版本: $PHP_VERSION"
    }
    
    # 检测系统资源
    log_info "🔍 检测系统资源..."
    
    # 检测内存大小
    if command -v free &> /dev/null; then
        MEMORY_MB=$(free -m | awk 'NR==2{print $2}')
    elif command -v vm_stat &> /dev/null; then
        # macOS
        MEMORY_MB=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//' | awk '{print int($1/1024/1024*4096)}')
    else
        log_warning "无法检测内存信息，使用默认值"
        MEMORY_MB=2048
    fi
    
    # 验证内存检测结果
    if ! [[ "$MEMORY_MB" =~ ^[0-9]+$ ]] || [ "$MEMORY_MB" -lt 512 ]; then
        log_warning "内存大小检测异常，使用默认值: 2048MB"
        MEMORY_MB=2048
    fi
    
    # 检测CPU核心数
    if command -v nproc &> /dev/null; then
        CPU_CORES=$(nproc)
    elif command -v sysctl &> /dev/null; then
        # macOS
        CPU_CORES=$(sysctl -n hw.ncpu)
    else
        CPU_CORES=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 2)
    fi
    
    # 验证CPU核心数检测结果
    if ! [[ "$CPU_CORES" =~ ^[0-9]+$ ]] || [ "$CPU_CORES" -lt 1 ]; then
        log_warning "CPU核心数检测异常，使用默认值: 2"
        CPU_CORES=2
    fi
    
    # 检测磁盘空间
    if command -v df &> /dev/null; then
        DISK_SPACE=$(df / | awk 'NR==2{print $4}')
        DISK_SPACE_MB=$((DISK_SPACE / 1024))
    else
        log_warning "无法检测磁盘空间，使用默认值"
        DISK_SPACE_MB=10240
    fi
    
    # 验证磁盘空间检测结果
    if ! [[ "$DISK_SPACE_MB" =~ ^[0-9]+$ ]] || [ "$DISK_SPACE_MB" -lt 5120 ]; then
        log_warning "磁盘空间检测异常，使用默认值: 10240MB"
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
    
    # 检测PHP版本
    detect_php_version
    
    log_success "系统信息检测完成:"
    log_info "  操作系统: $OS_NAME"
    log_info "  版本: $OS_VERSION"
    log_info "  架构: $ARCH"
    log_info "  包管理器: $PACKAGE_MANAGER"
    log_info "  PHP版本: $PHP_VERSION"
    log_info "  内存: ${MEMORY_MB}MB"
    log_info "  CPU核心: $CPU_CORES"
    log_info "  可用磁盘: ${DISK_SPACE_MB}MB"
    log_info "  IPv6支持: $IPV6_SUPPORT"
}

# 系统路径检测
detect_system_paths() {
    log_info "检测系统路径..."
    
    # 检测安装目录
    if [[ -d "/opt" ]]; then
        DEFAULT_INSTALL_DIR="/opt/ipv6-wireguard-manager"
    elif [[ -d "/usr/local" ]]; then
        DEFAULT_INSTALL_DIR="/usr/local/ipv6-wireguard-manager"
    else
        DEFAULT_INSTALL_DIR="$HOME/ipv6-wireguard-manager"
    fi
    
    # 检测Web目录
    if [[ -d "/var/www/html" ]]; then
        FRONTEND_DIR="/var/www/html"
    elif [[ -d "/usr/share/nginx/html" ]]; then
        FRONTEND_DIR="/usr/share/nginx/html"
    else
        FRONTEND_DIR="${DEFAULT_INSTALL_DIR}/web"
    fi
    
    # 检测WireGuard配置目录
    if [[ -d "/etc/wireguard" ]]; then
        WIREGUARD_CONFIG_DIR="/etc/wireguard"
    else
        WIREGUARD_CONFIG_DIR="${DEFAULT_INSTALL_DIR}/config/wireguard"
    fi
    
    # 检测Nginx配置目录
    if [[ -d "/etc/nginx/sites-available" ]]; then
        NGINX_CONFIG_DIR="/etc/nginx/sites-available"
    else
        NGINX_CONFIG_DIR="${DEFAULT_INSTALL_DIR}/config/nginx"
    fi
    
    # 检测日志目录
    if [[ -d "/var/log" ]]; then
        LOG_DIR="/var/log/ipv6-wireguard-manager"
    else
        LOG_DIR="${DEFAULT_INSTALL_DIR}/logs"
    fi
    
    # 检测其他目录
    BIN_DIR="/usr/local/bin"
    NGINX_LOG_DIR="/var/log/nginx"
    TEMP_DIR="/tmp/ipv6-wireguard-manager"
    BACKUP_DIR="${DEFAULT_INSTALL_DIR}/backups"
    CACHE_DIR="${DEFAULT_INSTALL_DIR}/cache"
    
    log_success "系统路径检测完成"
    log_info "安装目录: $DEFAULT_INSTALL_DIR"
    log_info "前端目录: $FRONTEND_DIR"
    log_info "WireGuard配置目录: $WIREGUARD_CONFIG_DIR"
    log_info "Nginx配置目录: $NGINX_CONFIG_DIR"
    log_info "日志目录: $LOG_DIR"
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
            --frontend-dir)
                FRONTEND_DIR="$2"
                shift 2
                ;;
            --config-dir)
                WIREGUARD_CONFIG_DIR="$2"
                shift 2
                ;;
            --log-dir)
                LOG_DIR="$2"
                shift 2
                ;;
            --nginx-dir)
                NGINX_CONFIG_DIR="$2"
                shift 2
                ;;
            --systemd-dir)
                SYSTEMD_CONFIG_DIR="$2"
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
            --auto)
                SILENT=true
                AUTO_EXIT=true
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
    echo "  --type TYPE          安装类型 (docker|native|minimal)"
    echo "  --dir DIR            安装目录 (默认: $DEFAULT_INSTALL_DIR)"
    echo "  --frontend-dir DIR   前端Web目录 (默认: $FRONTEND_DIR)"
    echo "  --config-dir DIR     WireGuard配置目录 (默认: $WIREGUARD_CONFIG_DIR)"
    echo "  --log-dir DIR        日志目录 (默认: $LOG_DIR)"
    echo "  --nginx-dir DIR      Nginx配置目录 (默认: $NGINX_CONFIG_DIR)"
    echo "  --systemd-dir DIR    Systemd服务目录 (默认: $SYSTEMD_CONFIG_DIR)"
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
    echo "  --auto               智能安装模式（自动选择参数并退出）"
    echo "  --help, -h           显示帮助信息"
    echo "  --version, -v        显示版本信息"
    echo ""
echo "示例:"
echo "  $0                           # 交互式安装"
echo "  $0 --type docker             # Docker安装"
echo "  $0 --type native             # 原生安装"
echo "  $0 --type minimal            # 最小化安装"
echo "  $0 --silent                  # 静默安装（自动选择安装类型）"
echo "  $0 --auto                    # 智能安装（自动选择参数并退出）"
echo "  $0 --type docker --dir /opt  # Docker安装到指定目录"
echo "  $0 --frontend-dir /var/www   # 自定义前端目录"
echo "  $0 --config-dir /etc/wg      # 自定义WireGuard配置目录"
echo "  $0 --log-dir /var/logs       # 自定义日志目录"
echo ""
echo "路径配置说明:"
echo "  所有路径参数都支持环境变量覆盖，例如:"
echo "  INSTALL_DIR=/custom/path $0"
echo "  FRONTEND_DIR=/var/www $0"
echo "  WIREGUARD_CONFIG_DIR=/etc/wg $0"
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
    echo "docker   - 使用Docker Compose部署（需要docker与docker-compose）"
}

# 选择安装类型
select_install_type() {
    if [[ -n "$INSTALL_TYPE" ]]; then
        log_info "使用指定的安装类型: $INSTALL_TYPE"
        return 0
    fi
    
    if [[ "$SILENT" = true ]]; then
        # 静默模式智能选择
        log_info "检测到非交互模式，智能选择安装类型..."
        
        # 综合评估系统资源
        local score=0
        
        # 内存评分 (0-3分)
        if [[ $MEMORY_MB -ge 4096 ]]; then
            score=$((score + 3))
        elif [[ $MEMORY_MB -ge 2048 ]]; then
            score=$((score + 2))
        elif [[ $MEMORY_MB -ge 1024 ]]; then
            score=$((score + 1))
        fi
        
        # CPU评分 (0-2分)
        if [[ $CPU_CORES -ge 4 ]]; then
            score=$((score + 2))
        elif [[ $CPU_CORES -ge 2 ]]; then
            score=$((score + 1))
        fi
        
        # 磁盘评分 (0-1分)
        if [[ $DISK_SPACE_MB -ge 10240 ]]; then  # 10GB
            score=$((score + 1))
        fi
        
        # 根据评分选择安装类型
        if [[ $score -le 2 ]]; then
            INSTALL_TYPE="minimal"
            log_info "自动选择的安装类型: minimal"
            log_info "选择理由: 系统资源有限（评分: $score/6），推荐最小化安装"
            log_info "优化配置: 禁用Redis、优化MySQL配置、减少并发连接"
            log_info "适用场景: VPS、低配置服务器、测试环境"
        elif [[ $score -le 4 ]]; then
            INSTALL_TYPE="native"
            log_info "自动选择的安装类型: native"
            log_info "选择理由: 系统资源适中（评分: $score/6），推荐原生安装"
            log_info "优化配置: 启用基础功能、平衡性能和资源使用"
            log_info "适用场景: 中等配置服务器、生产环境"
        else
            INSTALL_TYPE="docker"
            log_info "自动选择的安装类型: docker"
            log_info "选择理由: 系统资源充足（评分: $score/6），推荐Docker部署"
            log_info "优化配置: 容器化部署、隔离性更好、易于管理"
            log_info "适用场景: 高配置服务器、企业环境、集群部署"
        fi
        
        # 智能模式下自动设置其他参数
        if [[ "$AUTO_EXIT" = true ]]; then
            # 始终使用默认安装目录
            INSTALL_DIR="$DEFAULT_INSTALL_DIR"
            log_info "使用默认安装目录: $INSTALL_DIR"
            
            # 根据端口占用情况自动设置端口
            if netstat -tuln 2>/dev/null | grep -q ":$DEFAULT_PORT "; then
                WEB_PORT="8080"
                log_info "端口$DEFAULT_PORT已被占用，自动使用端口$WEB_PORT"
            else
                WEB_PORT="$DEFAULT_PORT"
            fi
            
            if netstat -tuln 2>/dev/null | grep -q ":$DEFAULT_API_PORT "; then
                API_PORT="8001"
                log_info "端口$DEFAULT_API_PORT已被占用，自动使用端口$API_PORT"
            else
                API_PORT="$DEFAULT_API_PORT"
            fi
            
            # 根据系统资源自动设置性能参数
            if [[ $MEMORY_MB -lt 4096 ]]; then
                PERFORMANCE=true
                log_info "系统资源有限，启用性能优化模式"
            fi
            
            # 如果是生产环境，自动设置生产模式
            if [[ "$AUTO_EXIT" = true ]] && [[ $MEMORY_MB -gt 4096 ]]; then
                PRODUCTION=true
                log_info "智能模式：自动启用生产环境配置"
            fi
        fi
        
        return 0
    fi
    
    # 交互模式
    log_info "请选择安装类型:"
    echo "1) Docker安装 - 推荐用于生产环境"
    echo "   优点: 完全隔离、易于管理、可移植性强"
    echo "   缺点: 资源占用较高、启动较慢"
    echo "   要求: 内存 ≥ 4GB，磁盘 ≥ 10GB"
    echo ""
    echo "2) 原生安装 - 推荐用于开发环境"
    echo "   优点: 性能最佳、资源占用低、启动快速"
    echo "   缺点: 依赖系统环境、配置复杂"
    echo "   要求: 内存 ≥ 2GB，磁盘 ≥ 5GB"
    echo ""
    echo "3) 最小化安装 - 推荐用于资源受限环境"
    echo "   优点: 资源占用最低、启动最快"
    echo "   缺点: 功能受限、性能一般"
    echo "   要求: 内存 ≥ 1GB，磁盘 ≥ 3GB"
    echo ""
    
    # 根据系统资源智能推荐
    local score=0
    
    # 计算系统评分
    if [[ $MEMORY_MB -ge 4096 ]]; then
        score=$((score + 3))
    elif [[ $MEMORY_MB -ge 2048 ]]; then
        score=$((score + 2))
    elif [[ $MEMORY_MB -ge 1024 ]]; then
        score=$((score + 1))
    fi
    
    if [[ $CPU_CORES -ge 4 ]]; then
        score=$((score + 2))
    elif [[ $CPU_CORES -ge 2 ]]; then
        score=$((score + 1))
    fi
    
    if [[ $DISK_SPACE_MB -ge 10240 ]]; then
        score=$((score + 1))
    fi
    
    # 根据评分推荐
    if [[ $score -le 2 ]]; then
        log_warning "⚠️ 系统资源有限（评分: $score/6），强烈推荐选择最小化安装"
        recommended="3"
    elif [[ $score -le 4 ]]; then
        log_info "💡 系统资源适中（评分: $score/6），推荐选择原生安装"
        recommended="2"
    else
        log_info "💡 系统资源充足（评分: $score/6），推荐选择Docker安装"
        recommended="1"
    fi
    
    echo ""
    read -p "请输入选择 (1-3) [推荐: $recommended]: " choice
    
    case $choice in
        1|"")
            INSTALL_TYPE="docker"
            ;;
        2)
            INSTALL_TYPE="native"
            ;;
        3)
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
    if [[ -z "${INSTALL_DIR:-}" ]]; then
        INSTALL_DIR="$DEFAULT_INSTALL_DIR"
    fi
    
    if [[ -z "${WEB_PORT:-}" ]]; then
        WEB_PORT="$DEFAULT_PORT"
    fi
    
    if [[ -z "${API_PORT:-}" ]]; then
        API_PORT="$DEFAULT_API_PORT"
    fi
    
    # 设置其他变量的默认值
    if [[ -z "${SERVER_HOST:-}" ]]; then
        SERVER_HOST="::"  # 支持IPv6和IPv4的所有接口
    fi
    
    if [[ -z "${LOCAL_HOST:-}" ]]; then
        LOCAL_HOST="::1"  # IPv6本地回环地址，同时支持IPv4和IPv6
    fi
    
    if [[ -z "${DB_PORT:-}" ]]; then
        DB_PORT="3306"
    fi
    
    if [[ -z "${REDIS_PORT:-}" ]]; then
        REDIS_PORT="6379"
    fi
    
    if [[ -z "${DB_USER:-}" ]]; then
        DB_USER="ipv6-wireguard"
    fi
    
    if [[ -z "${DB_PASSWORD:-}" ]]; then
        DB_PASSWORD="ipv6wgm_password"
    fi
    
    if [[ -z "${DB_NAME:-}" ]]; then
        DB_NAME="ipv6wgm"
    fi
}

# 安装系统依赖
install_system_dependencies() {
    log_info "安装系统依赖..."
    
    case $PACKAGE_MANAGER in
        "apt")
            apt-get update
            if apt-get install -y python$PYTHON_VERSION python$PYTHON_VERSION-venv python$PYTHON_VERSION-dev python3-pip 2>/dev/null; then
                log_success "Python $PYTHON_VERSION 安装成功"
            else
                log_warning "未找到 Python $PYTHON_VERSION，回退到系统默认Python3"
                apt-get install -y python3 python3-venv python3-dev python3-pip
                PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
            fi
            
            # 安装MySQL/MariaDB
            log_info "安装MySQL/MariaDB..."
            mysql_installed=false
            
            # 智能数据库安装策略
            log_info "🔍 检测最佳数据库安装方案..."
            
            # 检查是否为Debian 12
            if [[ "$OS_ID" == "debian" && "$OS_VERSION" == "12" ]]; then
                log_info "检测到Debian 12，优先使用MariaDB"
                if apt-get install -y mariadb-server mariadb-client 2>/dev/null; then
                    log_success "✅ MariaDB安装成功（Debian 12推荐）"
                    mysql_installed=true
                else
                    log_error "❌ MariaDB安装失败"
                    log_info "💡 请运行MySQL修复脚本: ./fix_mysql_install.sh"
                    exit 1
                fi
            else
                # 多策略数据库安装
                local db_install_success=false
                
                # 策略1: 尝试安装MySQL 8.0
                log_info "尝试安装MySQL 8.0..."
                if apt-get install -y mysql-server-8.0 mysql-client-8.0 2>/dev/null; then
                    log_success "✅ MySQL 8.0安装成功"
                    mysql_installed=true
                    db_install_success=true
                fi
                
                # 策略2: 尝试安装默认MySQL
                if [[ "$db_install_success" = false ]]; then
                    log_info "尝试安装默认MySQL版本..."
                    if apt-get install -y mysql-server mysql-client 2>/dev/null; then
                        log_success "✅ MySQL默认版本安装成功"
                        mysql_installed=true
                        db_install_success=true
                    fi
                fi
                
                # 策略3: 尝试安装MariaDB
                if [[ "$db_install_success" = false ]]; then
                    log_info "尝试安装MariaDB（MySQL替代方案）..."
                    if apt-get install -y mariadb-server mariadb-client 2>/dev/null; then
                        log_success "✅ MariaDB安装成功"
                        mysql_installed=true
                        db_install_success=true
                    fi
                fi
                
                # 策略4: 尝试安装MySQL 5.7
                if [[ "$db_install_success" = false ]]; then
                    log_info "尝试安装MySQL 5.7..."
                    if apt-get install -y mysql-server-5.7 mysql-client-5.7 2>/dev/null; then
                        log_success "✅ MySQL 5.7安装成功"
                        mysql_installed=true
                        db_install_success=true
                    fi
                fi
                
                # 如果所有策略都失败
                if [[ "$db_install_success" = false ]]; then
                    log_error "❌ 无法安装MySQL或MariaDB"
                    log_info "💡 请运行MySQL修复脚本: ./fix_mysql_install.sh"
                    log_info "💡 或手动安装数据库："
                    log_info "  Debian 12: sudo apt-get install mariadb-server"
                    log_info "  其他系统: sudo apt-get install mysql-server"
                    exit 1
                fi
            fi
            
            apt-get install -y nginx
            apt-get install -y git curl wget build-essential net-tools
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
    
    # 首先卸载Apache相关包，避免冲突
    case $PACKAGE_MANAGER in
        "apt")
            local apache_packages=(
                "apache2"
                "apache2-bin"
                "apache2-utils"
                "apache2-data"
                "libapache2-mod-php*"
            )
            
            for package in "${apache_packages[@]}"; do
                if dpkg -l | grep -q "^ii.*$package "; then
                    log_info "卸载Apache包: $package"
                    apt-get remove --purge -y "$package" || true
                fi
            done
            
            # 清理
            apt-get autoremove -y
            apt-get autoclean
            ;;
        "yum"|"dnf")
            local apache_packages=(
                "httpd"
                "httpd-tools"
                "mod_php"
            )
            
            for package in "${apache_packages[@]}"; do
                if $PACKAGE_MANAGER list installed | grep -q "$package"; then
                    log_info "卸载Apache包: $package"
                    $PACKAGE_MANAGER remove -y "$package" || true
                fi
            done
            ;;
    esac
    
    case $PACKAGE_MANAGER in
        "apt")
            # 更新包列表
            apt-get update
            
            # 安装PHP-FPM（避免Apache依赖）
            log_info "安装PHP-FPM（避免Apache依赖）..."
            
            # 智能PHP版本安装策略
            local php_install_success=false
            
            # 策略1: 尝试安装检测到的版本
            if [[ -n "$PHP_VERSION" ]]; then
                log_info "尝试安装PHP $PHP_VERSION-FPM..."
                if apt-get install -y php$PHP_VERSION-fpm php$PHP_VERSION-cli php$PHP_VERSION-common 2>/dev/null; then
                    log_success "✅ PHP $PHP_VERSION-FPM 核心包安装成功"
                    php_install_success=true
                fi
            fi
            
            # 策略2: 尝试安装默认版本
            if [[ "$php_install_success" = false ]]; then
                log_info "尝试安装PHP默认版本..."
                if apt-get install -y php-fpm php-cli php-common 2>/dev/null; then
                    log_success "✅ PHP默认版本-FPM 核心包安装成功"
                    PHP_VERSION=$(php -v | grep -oP 'PHP \K[0-9]+\.[0-9]+' | head -1)
                    php_install_success=true
                fi
            fi
            
            # 策略3: 尝试安装其他可用版本
            if [[ "$php_install_success" = false ]]; then
                log_info "尝试安装其他可用PHP版本..."
                for version in 8.2 8.1 8.0 7.4; do
                    if apt-get install -y php$version-fpm php$version-cli php$version-common 2>/dev/null; then
                        log_success "✅ PHP $version-FPM 核心包安装成功"
                        PHP_VERSION=$version
                        php_install_success=true
                        break
                    fi
                done
            fi
            
            # 如果所有策略都失败
            if [[ "$php_install_success" = false ]]; then
                log_error "❌ PHP-FPM核心包安装失败"
                log_info "💡 请手动安装PHP: sudo apt-get install php-fpm php-cli php-common"
                exit 1
            fi
            
            # 安装PHP扩展（逐个安装，避免触发Apache依赖）
            local php_extensions=("curl" "json" "mbstring" "mysql" "xml" "zip" "pdo" "pdo_mysql" "filter" "openssl")
            for ext in "${php_extensions[@]}"; do
                log_info "安装PHP扩展: $ext"
                
                # 检查扩展是否已存在（内置或已安装）
                if php -m | grep -q "^$ext$"; then
                    log_success "✓ PHP扩展 $ext 已存在"
                    continue
                fi
                
                # 尝试安装特定版本的扩展
                if apt-get install -y php$PHP_VERSION-$ext 2>/dev/null; then
                    log_success "✓ PHP扩展 $ext 安装成功"
                else
                    log_warning "⚠ PHP扩展 $ext 安装失败，尝试默认版本"
                    if apt-get install -y php-$ext 2>/dev/null; then
                        log_success "✓ PHP扩展 $ext (默认版本) 安装成功"
                    else
                        log_warning "⚠ PHP扩展 $ext 安装失败，可能是内置扩展"
                    fi
                fi
            done
            
            log_success "PHP $PHP_VERSION-FPM 安装完成（无Apache依赖）"
            ;;
        "yum"|"dnf")
            # 安装PHP-FPM（避免Apache依赖）
            log_info "安装PHP-FPM（避免Apache依赖）..."
            if $PACKAGE_MANAGER install -y php-fpm php-cli php-common 2>/dev/null; then
                log_success "PHP-FPM核心包安装成功"
                
                # 安装PHP扩展
                local php_extensions=("curl" "json" "mbstring" "mysql" "xml" "zip" "pdo" "pdo_mysql" "filter" "openssl")
                for ext in "${php_extensions[@]}"; do
                    log_info "安装PHP扩展: $ext"
                    $PACKAGE_MANAGER install -y php-$ext 2>/dev/null || true
                done
                
                log_success "PHP-FPM安装完成（无Apache依赖）"
            else
                log_error "PHP-FPM安装失败"
                exit 1
            fi
            ;;
        "pacman")
            # 安装PHP-FPM（避免Apache依赖）
            log_info "安装PHP-FPM（避免Apache依赖）..."
            if pacman -S --noconfirm php-fpm php-cli 2>/dev/null; then
                log_success "PHP-FPM安装成功"
                
                # 安装PHP扩展
                pacman -S --noconfirm php-curl php-mbstring php-pdo php-pdo_mysql 2>/dev/null || true
                
                log_success "PHP-FPM安装完成（无Apache依赖）"
            else
                log_error "PHP-FPM安装失败"
                exit 1
            fi
            ;;
        "zypper")
            log_info "安装PHP-FPM（避免Apache依赖）..."
            if zypper install -y php-fpm php-cli php-common 2>/dev/null; then
                log_success "PHP-FPM核心包安装成功"
                
                # 安装PHP扩展
                local php_extensions=("curl" "json" "mbstring" "mysql" "xml" "zip" "pdo" "pdo_mysql" "filter" "openssl")
                for ext in "${php_extensions[@]}"; do
                    zypper install -y php-$ext 2>/dev/null || true
                done
                
                log_success "PHP-FPM安装完成（无Apache依赖）"
            else
                log_error "PHP-FPM安装失败"
                exit 1
            fi
            ;;
        "emerge")
            # 安装PHP-FPM（避免Apache依赖）
            log_info "安装PHP-FPM（避免Apache依赖）..."
            emerge -q dev-lang/php:8.1
            emerge -q dev-php/php-fpm
            log_success "PHP-FPM安装完成（无Apache依赖）"
            ;;
        "apk")
            # 安装PHP-FPM（避免Apache依赖）
            log_info "安装PHP-FPM（避免Apache依赖）..."
            apk add php-fpm php-cli php-common
            apk add php-curl php-json php-mbstring php-mysqlnd php-xml php-zip php-pdo php-pdo_mysql php-openssl
            log_success "PHP-FPM安装完成（无Apache依赖）"
            ;;
    esac
    
    # 验证PHP安装
    if ! command -v php &>/dev/null; then
        log_error "PHP安装失败"
        exit 1
    fi
    
    # 检查PHP版本兼容性
    local installed_php_version=$(php -v | grep -oP 'PHP \K[0-9]+\.[0-9]+' | head -1)
    if [[ $(printf '%s\n' "8.1" "$installed_php_version" | sort -V | head -n1) != "8.1" ]]; then
        log_warning "PHP版本 $installed_php_version 可能不兼容，建议使用8.1+"
    else
        log_success "PHP版本 $installed_php_version 兼容"
    fi
    
    # 检查必需扩展
    local required_extensions=("session" "json" "mbstring" "filter" "pdo" "pdo_mysql" "curl" "openssl")
    local missing_extensions=()
    
    for ext in "${required_extensions[@]}"; do
        if ! php -m | grep -q "^$ext$"; then
            missing_extensions+=("$ext")
        fi
    done
    
    if [[ ${#missing_extensions[@]} -eq 0 ]]; then
        log_success "所有必需的PHP扩展已安装"
    else
        log_warning "缺少PHP扩展: ${missing_extensions[*]}"
        log_info "尝试安装缺少的扩展..."
        
        case $PACKAGE_MANAGER in
            "apt")
                for ext in "${missing_extensions[@]}"; do
                    if [[ -n "$PHP_VERSION" ]]; then
                        if apt-get install -y "php$PHP_VERSION-$ext" 2>/dev/null; then
                            log_success "✓ PHP扩展 $ext 安装成功"
                        else
                            log_warning "扩展 $ext 安装失败，尝试默认版本"
                            if apt-get install -y "php-$ext" 2>/dev/null; then
                                log_success "✓ PHP扩展 $ext (默认版本) 安装成功"
                            else
                                log_warning "⚠ PHP扩展 $ext 安装失败，可能是内置扩展或不兼容"
                            fi
                        fi
                    else
                        if apt-get install -y "php-$ext" 2>/dev/null; then
                            log_success "✓ PHP扩展 $ext 安装成功"
                        else
                            log_warning "⚠ PHP扩展 $ext 安装失败，可能是内置扩展或不兼容"
                        fi
                    fi
                done
                ;;
            "yum"|"dnf")
                for ext in "${missing_extensions[@]}"; do
                    if $PACKAGE_MANAGER install -y "php-$ext" 2>/dev/null; then
                        log_success "✓ PHP扩展 $ext 安装成功"
                    else
                        log_warning "⚠ PHP扩展 $ext 安装失败，可能是内置扩展或不兼容"
                    fi
                done
                ;;
        esac
        
        # 再次检查扩展是否安装成功
        local still_missing=()
        for ext in "${missing_extensions[@]}"; do
            if ! php -m | grep -q "^$ext$"; then
                still_missing+=("$ext")
            fi
        done
        
        if [[ ${#still_missing[@]} -gt 0 ]]; then
            log_warning "以下扩展可能已内置或不需要单独安装: ${still_missing[*]}"
        else
            log_success "所有必需的PHP扩展现在可用"
        fi
    fi
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
    local python_bin="python$PYTHON_VERSION"
    if ! command -v "$python_bin" &>/dev/null; then
        python_bin="python3"
    fi
    "$python_bin" -m venv venv
    source venv/bin/activate
    
    # 升级pip
    pip install --upgrade pip
    
    # 安装依赖
    if [[ -f "backend/requirements.txt" ]]; then
        pip install -r backend/requirements.txt
        log_success "Python依赖安装成功"
        
        # 安装额外的功能依赖
        log_info "安装增强功能依赖..."
        pip install pytest pytest-cov pytest-xdist pytest-html pytest-mock pytest-asyncio
        pip install flake8 black isort mypy
        log_success "增强功能依赖安装完成"
    elif [[ -f "backend/requirements-simple.txt" ]]; then
        pip install -r backend/requirements-simple.txt
        log_success "Python依赖安装成功（使用简化版本）"
    else
        log_error "requirements.txt文件不存在"
        exit 1
    fi
}

# 配置数据库
configure_database() {
    log_info "配置数据库..."
    
    # 强制使用MySQL/MariaDB，不支持SQLite和PostgreSQL
    log_info "强制使用MySQL数据库，不支持SQLite和PostgreSQL"
    
    # 启动MySQL/MariaDB服务
    case $PACKAGE_MANAGER in
        "apt")
            # 检查是否为Debian 12（使用MariaDB）
            if [[ "$OS_ID" == "debian" && "$OS_VERSION" == "12" ]]; then
                systemctl start mariadb
                systemctl enable mariadb
            else
                systemctl start mysql
                systemctl enable mysql
            fi
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
    
    # 创建数据库和用户（根据数据库类型选择兼容语法）
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    DB_SERVER_VERSION=$(mysql -V 2>/dev/null || true)
    if echo "$DB_SERVER_VERSION" | grep -qi "mariadb"; then
        # MariaDB: 使用 IDENTIFIED BY 语法
        mysql -u root -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';" || \
        mysql -u root -e "ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
        # 追加为127.0.0.1主机的账户，确保TCP访问
        mysql -u root -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASSWORD}';" || \
        mysql -u root -e "ALTER USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASSWORD}';"
    else
        # MySQL: 使用 mysql_native_password 明确插件
        mysql -u root -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';" || \
        mysql -u root -e "ALTER USER '${DB_USER}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';"
        # 追加为127.0.0.1主机的账户，确保TCP访问
        mysql -u root -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';" || \
        mysql -u root -e "ALTER USER '${DB_USER}'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';"
    fi
    mysql -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1';"
    mysql -u root -e "FLUSH PRIVILEGES;"
    
    # 确保数据库用户权限立即生效
    mysql -u root -e "FLUSH PRIVILEGES;"
    
    # 创建环境配置文件
    create_env_config
    
    # 初始化数据库
    initialize_database
    
    log_success "数据库配置完成"
}

# 部署PHP前端
deploy_php_frontend() {
    log_info "部署PHP前端到 $FRONTEND_DIR..."
    
    # 创建前端目录
    if [[ ! -d "$FRONTEND_DIR" ]]; then
        mkdir -p "$FRONTEND_DIR"
    fi
    
    # 复制前端文件到 /var/www/html
    if [[ -d "$INSTALL_DIR/php-frontend" ]]; then
        cp -r "$INSTALL_DIR/php-frontend"/* "$FRONTEND_DIR/"
        log_success "前端文件复制到 $FRONTEND_DIR"
    else
        log_error "前端源码目录不存在: $INSTALL_DIR/php-frontend"
        exit 1
    fi
    
    # 创建日志目录
    mkdir -p "$FRONTEND_DIR/logs"
    touch "$FRONTEND_DIR/logs/error.log"
    touch "$FRONTEND_DIR/logs/access.log"
    touch "$FRONTEND_DIR/logs/debug.log"
    
    # 设置权限
    # 动态检测Web服务用户，兼容不同发行版
    local web_user=""
    local web_group=""
    if id -u www-data >/dev/null 2>&1; then
        web_user="www-data"; web_group="www-data"
    elif id -u nginx >/dev/null 2>&1; then
        web_user="nginx"; web_group="nginx"
    elif id -u apache >/dev/null 2>&1; then
        web_user="apache"; web_group="apache"
    elif id -u http >/dev/null 2>&1; then
        web_user="http"; web_group="http"
    else
        # 回退到服务用户，避免脚本因不存在的用户而失败
        web_user="$SERVICE_USER"; web_group="$SERVICE_GROUP"
        log_warning "未检测到常见Web用户，使用服务用户: ${web_user}:${web_group}"
    fi

    chown -R "$web_user":"$web_group" "$FRONTEND_DIR" 2>/dev/null || true
    chmod -R 755 "$FRONTEND_DIR"
    chmod -R 777 "$FRONTEND_DIR/logs"
    
    # 智能启动PHP-FPM服务
    local php_fpm_service=""
    local service_started=false
    
    case $PACKAGE_MANAGER in
        "apt")
            # 尝试多个可能的服务名
            for service_name in "php$PHP_VERSION-fpm" "php-fpm" "php8.2-fpm" "php8.1-fpm" "php8.0-fpm" "php7.4-fpm"; do
                if systemctl list-unit-files | grep -q "$service_name"; then
                    php_fpm_service="$service_name"
                    break
                fi
            done
            ;;
        "yum"|"dnf"|"pacman"|"zypper"|"emerge"|"apk")
            php_fpm_service="php-fpm"
            ;;
    esac
    
    # 启动PHP-FPM服务
    if [[ -n "$php_fpm_service" ]]; then
        # 检查服务是否存在
        if systemctl list-unit-files | grep -q "$php_fpm_service"; then
            if systemctl start "$php_fpm_service" 2>/dev/null; then
                systemctl enable "$php_fpm_service"
                log_success "✅ PHP-FPM服务启动成功: $php_fpm_service"
                service_started=true
            else
                log_warning "⚠️ PHP-FPM服务 $php_fpm_service 启动失败，尝试其他服务名..."
            fi
        else
            log_warning "⚠️ PHP-FPM服务 $php_fpm_service 不存在，尝试其他服务名..."
        fi
    fi
    
    # 如果启动失败，尝试其他可能的服务名
    if [[ "$service_started" = false ]]; then
        log_warning "⚠️ 尝试其他PHP-FPM服务名..."
        for service_name in "php-fpm" "php8.2-fpm" "php8.1-fpm" "php8.0-fpm" "php7.4-fpm" "php$PHP_VERSION-fpm"; do
            if systemctl list-unit-files | grep -q "$service_name"; then
                if systemctl start "$service_name" 2>/dev/null; then
                    systemctl enable "$service_name"
                    log_success "✅ PHP-FPM服务启动成功: $service_name"
                    service_started=true
                    break
                fi
            fi
        done
    fi
    
    # 如果systemd服务启动失败，尝试使用service命令
    if [[ "$service_started" = false ]]; then
        log_warning "⚠️ 尝试使用service命令启动PHP-FPM..."
        for service_name in "php-fpm" "php8.2-fpm" "php8.1-fpm" "php8.0-fpm" "php7.4-fpm"; do
            if service "$service_name" start 2>/dev/null; then
                log_success "✅ PHP-FPM服务启动成功: $service_name"
                service_started=true
                break
            fi
        done
    fi
    
    # 检查PHP-FPM进程是否运行
    if [[ "$service_started" = false ]]; then
        log_warning "⚠️ 检查PHP-FPM进程状态..."
        if pgrep -f "php-fpm" > /dev/null; then
            log_success "✅ PHP-FPM进程已在运行"
            service_started=true
        else
            # 尝试直接启动PHP-FPM
            log_warning "⚠️ 尝试直接启动PHP-FPM..."
            local php_fpm_bin=""
            for bin_path in "/usr/sbin/php-fpm$PHP_VERSION" "/usr/sbin/php-fpm" "/usr/bin/php-fpm$PHP_VERSION" "/usr/bin/php-fpm"; do
                if [[ -x "$bin_path" ]]; then
                    php_fpm_bin="$bin_path"
                    break
                fi
            done
            
            if [[ -n "$php_fpm_bin" ]]; then
                if "$php_fpm_bin" --daemonize 2>/dev/null; then
                    log_success "✅ PHP-FPM直接启动成功: $php_fpm_bin"
                    service_started=true
                fi
            fi
        fi
    fi
    
    if [[ "$service_started" = false ]]; then
        log_error "❌ PHP-FPM服务启动失败"
        log_info "💡 请手动启动PHP-FPM服务"
        log_info "💡 可能的命令: sudo systemctl start php-fpm 或 sudo service php-fpm start"
        # 不退出，继续执行，因为Nginx配置可能不需要PHP-FPM
    else
        # 验证PHP-FPM是否正常运行
        sleep 2
        if pgrep -f "php-fpm" > /dev/null; then
            log_success "✅ PHP-FPM服务运行正常"
        else
            log_warning "⚠️ PHP-FPM服务启动后未检测到进程"
        fi
    fi
}

# 配置Nginx
configure_nginx() {
    log_info "配置Nginx..."
    
    # 检测PHP-FPM socket路径
    local php_fpm_socket=""
    local possible_sockets=(
        "/var/run/php/php${PHP_VERSION}-fpm.sock"
        "/var/run/php/php-fpm.sock"
        "/run/php/php${PHP_VERSION}-fpm.sock"
        "/run/php/php-fpm.sock"
        "/tmp/php-fpm.sock"
        "/tmp/php-cgi.sock"
    )
    
    for socket_path in "${possible_sockets[@]}"; do
        if [[ -S "$socket_path" ]]; then
            php_fpm_socket="$socket_path"
            log_success "找到PHP-FPM socket: $socket_path"
            break
        fi
    done
    
    # 如果没找到socket文件，使用默认路径
    if [[ -z "${php_fpm_socket:-}" ]]; then
        php_fpm_socket="/var/run/php/php${PHP_VERSION}-fpm.sock"
        log_warning "未检测到PHP-FPM socket，使用默认路径: $php_fpm_socket"
    fi
    
    # 计算Nginx配置路径（兼容不同发行版）
    local nginx_site_name="ipv6-wireguard-manager"
    local nginx_sites_available="/etc/nginx/sites-available"
    local nginx_sites_enabled="/etc/nginx/sites-enabled"
    local nginx_conf_d="/etc/nginx/conf.d"
    local nginx_conf_path=""

    if [[ -d "$nginx_sites_available" ]]; then
        nginx_conf_path="$nginx_sites_available/$nginx_site_name"
    elif [[ -d "$nginx_conf_d" ]]; then
        nginx_conf_path="$nginx_conf_d/${nginx_site_name}.conf"
    elif [[ -d "$NGINX_CONFIG_DIR" ]]; then
        nginx_conf_path="$NGINX_CONFIG_DIR/${nginx_site_name}.conf"
    else
        mkdir -p "$INSTALL_DIR/config/nginx"
        nginx_conf_path="$INSTALL_DIR/config/nginx/${nginx_site_name}.conf"
        log_warning "未找到标准Nginx配置目录，配置将写入: $nginx_conf_path"
    fi

    # 创建Nginx配置
    # IPv6与IPv4上游行（根据IPV6_SUPPORT条件渲染）
    local backend_ipv6_line=""
    if [[ "${IPV6_SUPPORT}" == "true" ]]; then
        backend_ipv6_line="    server [::1]:${API_PORT} max_fails=3 fail_timeout=30s;"
        log_info "使用IPv6上游服务器地址: [::1]:${API_PORT}"
    else
        log_info "未启用IPv6或不可用，跳过IPv6上游配置"
    fi
    # IPv4备选固定为127.0.0.1，避免 ::1 在仅IPv4 环境下失败
    local backend_ipv4_line="    server 127.0.0.1:${API_PORT} backup max_fails=3 fail_timeout=30s;"

    cat > "$nginx_conf_path" << EOF
# 上游服务器组，支持IPv4和IPv6双栈
upstream backend_api {
$( [[ -n "$backend_ipv6_line" ]] && echo "$backend_ipv6_line" )
    # IPv4作为备选
$backend_ipv4_line
    
    # 健康检查
    keepalive 32;
    keepalive_requests 100;
    keepalive_timeout 60s;
}

# PHP-FPM上游配置
upstream php_backend {
    server unix:$php_fpm_socket;
    # 如果使用TCP连接，使用以下配置：
    # server ${LOCAL_HOST}:9000;
}

server {
    listen $WEB_PORT;
    listen [::]:$WEB_PORT;
    server_name _;
    root $FRONTEND_DIR;
    index index.php index.html;
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # 静态文件缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files \$uri =404;
    }
    
    # API代理配置 - 将 /api/* 请求代理到后端，支持IPv4和IPv6双栈
    location /api/ {
        # 定义上游服务器组，支持IPv4和IPv6双栈
        proxy_pass http://backend_api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # 超时设置
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # 错误处理
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_next_upstream_tries 3;
        proxy_next_upstream_timeout 10s;
        
        # CORS头 - 支持环境变量配置
        add_header Access-Control-Allow-Origin "${BACKEND_ALLOWED_ORIGINS:-http://localhost:$WEB_PORT}" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
        
        # 处理预检请求
        if (\$request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "${BACKEND_ALLOWED_ORIGINS:-http://localhost:$WEB_PORT}" always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain charset=UTF-8';
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # PHP文件处理 - 使用动态检测的PHP-FPM socket
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php_backend;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        
        # 超时设置
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_read_timeout 60s;
        
        # 缓冲设置
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
    }
    
    # 前端路由处理 - 支持单页应用路由
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    # 禁止访问敏感文件
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ /(config|logs|backup)/ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # 禁止访问PHP配置文件
    location ~ \.(ini|conf|log)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # 文件上传大小限制
    client_max_body_size 10M;
    
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
}
EOF
    
    # 启用站点（Debian/Ubuntu）或直接使用conf.d（RHEL/CentOS等）
    if [[ -d "$nginx_sites_available" && -d "$nginx_sites_enabled" ]]; then
        ln -sf "$nginx_conf_path" "$nginx_sites_enabled/$nginx_site_name"
        rm -f "$nginx_sites_enabled/default" 2>/dev/null || true
    fi
    
    # 测试配置
    if nginx -t; then
        systemctl restart nginx
        systemctl enable nginx
        log_success "Nginx配置完成 (配置路径: $nginx_conf_path)"
        log_info "使用的PHP-FPM socket: $php_fpm_socket"
        if [[ "${IPV6_SUPPORT}" == "true" ]]; then
            log_info "IPv6上游服务器地址: [::1]:${API_PORT}"
        else
            log_info "IPv6上游服务器地址: 已禁用"
        fi
    else
        log_error "Nginx配置错误"
        exit 1
    fi
}

# Docker安装
install_docker() {
    log_step "开始Docker安装..."
    
    # 检查Docker是否已安装
    if ! command -v docker &> /dev/null; then
        log_info "安装Docker..."
        install_docker_engine
    else
        log_success "Docker已安装"
    fi
    
    # 检查Docker Compose是否已安装
    if ! command -v docker-compose &> /dev/null; then
        log_info "安装Docker Compose..."
        install_docker_compose
    else
        log_success "Docker Compose已安装"
    fi
    
    # 创建安装目录
    mkdir -p "$INSTALL_DIR"
    
    # 下载项目文件
    download_project
    
    # 创建环境配置文件
    create_docker_env_file
    
    # 构建并启动Docker容器
    build_and_start_docker
    
    # 等待服务启动
    wait_for_docker_services
    
    log_success "Docker安装完成"
}

# 安装Docker引擎
install_docker_engine() {
    case $OS_ID in
        "ubuntu")
            # 更新包索引
            apt-get update
            
            # 安装依赖
            apt-get install -y ca-certificates curl gnupg lsb-release
            
            # 添加Docker官方GPG密钥
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # 添加Docker仓库
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # 安装Docker Engine
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            # 启动Docker服务
            systemctl start docker
            systemctl enable docker
            ;;
        "centos"|"rhel"|"fedora")
            # 安装依赖
            yum install -y yum-utils
            
            # 添加Docker仓库
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            
            # 安装Docker Engine
            yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            # 启动Docker服务
            systemctl start docker
            systemctl enable docker
            ;;
        *)
            log_error "不支持的操作系统: $OS_ID"
            exit 1
            ;;
    esac
    
    # 将当前用户添加到docker组
    if [[ -n "$SUDO_USER" ]]; then
        usermod -aG docker "$SUDO_USER"
    else
        usermod -aG docker "$(whoami)"
    fi
    
    log_success "Docker引擎安装完成"
}

# 安装Docker Compose
install_docker_compose() {
    # 下载Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # 添加执行权限
    chmod +x /usr/local/bin/docker-compose
    
    # 创建符号链接
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log_success "Docker Compose安装完成"
}

# 创建Docker环境配置文件
create_docker_env_file() {
    log_info "创建Docker环境配置文件（自动生成模式）..."
    
    # 生成随机密码
    MYSQL_PASSWORD=$(generate_random_string 16)
    MYSQL_ROOT_PASSWORD=$(generate_random_string 20)
    
    # 创建自动生成模式的 .env 文件
    cat > "$INSTALL_DIR/.env" << EOF
# IPv6 WireGuard Manager 环境配置文件
# 自动生成模式 - 系统将自动生成强密码和长密钥

# =============================================================================
# 路径配置
# =============================================================================

# 安装目录
INSTALL_DIR=/opt/ipv6-wireguard-manager

# 前端Web目录
FRONTEND_DIR=/var/www/html

# WireGuard配置目录
WIREGUARD_CONFIG_DIR=/etc/wireguard
WIREGUARD_CLIENTS_DIR=/etc/wireguard/clients

# 日志目录
LOG_DIR=/var/log/ipv6-wireguard-manager
NGINX_LOG_DIR=/var/log/nginx

# Nginx配置目录
NGINX_CONFIG_DIR=/etc/nginx/sites-available

# Systemd服务目录
SYSTEMD_CONFIG_DIR=/etc/systemd/system

# 二进制文件目录
BIN_DIR=/usr/local/bin

# =============================================================================
# 数据库配置
# =============================================================================

# 数据库连接URL
DATABASE_URL=mysql://ipv6wgm:password@localhost:3306/ipv6wgm

# 数据库连接池配置
DATABASE_POOL_SIZE=10
DATABASE_MAX_OVERFLOW=15
DATABASE_CONNECT_TIMEOUT=30
DATABASE_STATEMENT_TIMEOUT=30000
DATABASE_IDLE_IN_TRANSACTION_SESSION_TIMEOUT=10000
DATABASE_POOL_RECYCLE=3600
DATABASE_POOL_PRE_PING=true

# =============================================================================
# API配置
# =============================================================================

# API版本前缀
API_V1_STR=/api/v1

# 安全密钥（留空将自动生成64字符强密钥）
SECRET_KEY=

# 访问令牌过期时间（分钟）
ACCESS_TOKEN_EXPIRE_MINUTES=11520

# =============================================================================
# 服务器配置
# =============================================================================

# 服务器主机和端口
SERVER_HOST=::  # 支持IPv6和IPv4的所有接口
SERVER_PORT=8000

# 本地主机配置
LOCAL_HOST=::1  # IPv6本地回环地址，同时支持IPv4和IPv6

# 服务器名称
SERVER_NAME=localhost

# =============================================================================
# 安全配置
# =============================================================================

# 第一个超级用户（留空将自动生成强密码）
FIRST_SUPERUSER=admin
# 留空将自动生成16字符强密码
FIRST_SUPERUSER_PASSWORD=
FIRST_SUPERUSER_EMAIL=admin@example.com

# 密码策略
PASSWORD_MIN_LENGTH=8
PASSWORD_REQUIRE_UPPERCASE=true
PASSWORD_REQUIRE_LOWERCASE=true
PASSWORD_REQUIRE_NUMBERS=true
PASSWORD_REQUIRE_SPECIAL_CHARS=true

# 会话配置
SESSION_TIMEOUT=1440
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION=15

# =============================================================================
# WireGuard配置
# =============================================================================

# WireGuard端口
WIREGUARD_PORT=51820

# WireGuard接口名称
WIREGUARD_INTERFACE=wg0

# WireGuard网络配置
WIREGUARD_NETWORK=10.0.0.0/24
WIREGUARD_IPV6_NETWORK=fd00::/64

# WireGuard密钥（可选，留空将自动生成）
WIREGUARD_PRIVATE_KEY=
WIREGUARD_PUBLIC_KEY=

# =============================================================================
# 日志配置
# =============================================================================

# 日志级别
LOG_LEVEL=INFO

# 日志格式
LOG_FORMAT=json

# 日志轮转
LOG_ROTATION=1 day
LOG_RETENTION=30 days

# =============================================================================
# SSL/TLS安全配置
# =============================================================================

# SSL验证设置（生产环境必须为true）
API_SSL_VERIFY=true

# CA证书路径（可选，如果系统CA证书路径不同）
API_SSL_CA_PATH=/etc/ssl/certs/ca-certificates.crt

# 开发环境可以设置为false（仅开发环境使用）
# API_SSL_VERIFY=false

# =============================================================================
# 监控配置
# =============================================================================

# 启用指标收集
ENABLE_METRICS=true
METRICS_PORT=9090

# 启用健康检查
ENABLE_HEALTH_CHECK=true
HEALTH_CHECK_INTERVAL=30

# =============================================================================
# 文件上传配置
# =============================================================================

# 最大文件大小（字节）
MAX_FILE_SIZE=10485760

# 上传目录
UPLOAD_DIR=uploads

# 允许的文件扩展名
ALLOWED_EXTENSIONS=.conf,.key,.crt,.pem,.txt,.log

# =============================================================================
# CORS配置
# =============================================================================

# 允许的CORS源（生产环境请指定具体域名，不要使用*）
BACKEND_CORS_ORIGINS=["https://your-domain.com","https://www.your-domain.com"]

# 开发环境可以包含本地地址
# BACKEND_CORS_ORIGINS=["http://localhost:3000","http://localhost:8080","https://your-domain.com"]

# =============================================================================
# Redis配置（可选）
# =============================================================================

# Redis连接URL
REDIS_URL=redis://localhost:6379/0

# 是否使用Redis
USE_REDIS=false

# =============================================================================
# 邮件配置（可选）
# =============================================================================

# SMTP服务器配置
SMTP_TLS=true
SMTP_PORT=587
SMTP_HOST=
SMTP_USER=
SMTP_PASSWORD=

# 邮件发送者
EMAILS_FROM_EMAIL=noreply@example.com
EMAILS_FROM_NAME="IPv6 WireGuard Manager"

# =============================================================================
# 开发配置
# =============================================================================

# 调试模式
DEBUG=false

# 环境类型
ENVIRONMENT=production

# =============================================================================
# Docker配置
# =============================================================================

# MySQL配置
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_VERSION=8.0
MYSQL_PORT=3306

# Web端口
WEB_PORT=$WEB_PORT
WEB_SSL_PORT=443

# API端口
API_PORT=$API_PORT

# Redis端口
REDIS_PORT=6379

# Nginx端口
NGINX_PORT=443
EOF
    
    # 导出环境变量
    export MYSQL_PASSWORD
    export MYSQL_ROOT_PASSWORD
    
    log_success "Docker环境配置文件创建完成（自动生成模式）"
    log_info "系统将自动生成 SECRET_KEY 和 FIRST_SUPERUSER_PASSWORD"
}

# 构建并启动Docker容器
build_and_start_docker() {
    log_info "构建并启动Docker容器..."
    
    cd "$INSTALL_DIR"
    
    # 构建并启动容器
    docker-compose up -d --build
    
    log_success "Docker容器启动完成"
}

# 等待Docker服务启动
wait_for_docker_services() {
    log_info "等待Docker服务启动..."
    
    cd "$INSTALL_DIR"
    
    # 等待MySQL启动
    log_info "等待MySQL启动..."
    while ! docker-compose exec -e MYSQL_PWD=${MYSQL_ROOT_PASSWORD} mysql mysqladmin ping -h"localhost" -u root --silent; do
        sleep 2
    done
    log_success "MySQL已启动"
    
    # 等待后端API启动
    log_info "等待后端API启动..."
    while ! curl -f http://[::1]:$API_PORT/api/v1/health &>/dev/null && ! curl -f http://127.0.0.1:$API_PORT/api/v1/health &>/dev/null; do
        sleep 5
    done
    log_success "后端API已启动"
    
    # 显示自动生成的凭据
    show_auto_generated_credentials
    
    # Docker模式：已启用容器前端，跳过宿主机前端部署
    log_info "Docker模式：使用docker-compose管理前端容器，跳过宿主机前端部署"
}

# 显示自动生成的凭据
show_auto_generated_credentials() {
    log_info "获取自动生成的凭据..."
    
    # 等待后端日志输出凭据信息
    sleep 5
    
    # 从后端容器日志中提取自动生成的凭据
    local backend_logs=$(docker-compose logs backend 2>/dev/null | tail -50)
    
    # 提取 SECRET_KEY
    local secret_key=$(echo "$backend_logs" | grep "自动生成的 SECRET_KEY" -A 1 | tail -1 | sed 's/^[[:space:]]*//')
    
    # 提取超级用户密码
    local admin_password=$(echo "$backend_logs" | grep "密码:" | sed 's/.*密码: *//' | head -1)
    
    if [[ -n "$secret_key" && -n "$admin_password" ]]; then
        echo ""
        log_success "=========================================="
        log_success "🎉 自动生成凭据获取成功！"
        log_success "=========================================="
        echo ""
        log_info "🔑 自动生成的 SECRET_KEY:"
        log_info "   $secret_key"
        echo ""
        log_info "🔐 自动生成的超级用户密码:"
        log_info "   用户名: admin"
        log_info "   密码: $admin_password"
        echo ""
        log_warning "⚠️  请妥善保存这些凭据！"
        log_success "=========================================="
        echo ""
    else
        log_warning "无法从日志中提取自动生成的凭据"
        log_info "请手动查看日志: docker-compose logs backend"
    fi
}

# 生成随机字符串
generate_random_string() {
    local length=${1:-16}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# 创建环境配置文件
create_env_config() {
    log_info "创建环境配置文件..."
    
    # 生成随机密钥
    local secret_key=$(openssl rand -hex 32)
    # 生成超级用户强随机密码
    local admin_password=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-20)
    # 数据库密码与创建用户保持一致，避免不一致导致连接失败
    local database_password="${DB_PASSWORD}"
    
    # 创建.env文件
    cat > "$INSTALL_DIR/.env" << EOF
# Application Settings
APP_NAME="IPv6 WireGuard Manager"
APP_VERSION="3.0.0"
DEBUG=$([ "$DEBUG" = true ] && echo "true" || echo "false")
ENVIRONMENT="$([ "$PRODUCTION" = true ] && echo "production" || echo "development")"

# API Settings
API_V1_STR="/api/v1"
SECRET_KEY="${secret_key}"
ACCESS_TOKEN_EXPIRE_MINUTES=1440

# Server Settings
SERVER_HOST="${SERVER_HOST}"
SERVER_PORT=$API_PORT

# Database Settings - 强制使用MySQL（应用层自动选择驱动，保持基础 mysql://）
DATABASE_URL="mysql://${DB_USER}:${DB_PASSWORD}@127.0.0.1:${DB_PORT}/${DB_NAME}"
DATABASE_HOST="127.0.0.1"  # 强制TCP，避免本地socket/插件差异
DATABASE_PORT=${DB_PORT}
DATABASE_USER=${DB_USER}
DATABASE_PASSWORD="${database_password}"
DATABASE_NAME=${DB_NAME}
AUTO_CREATE_DATABASE=True

# 强制使用MySQL，禁用SQLite和PostgreSQL（驱动由应用自行选择）
DB_TYPE="mysql"
DB_ENGINE="mysql"

# Redis Settings (Optional)
USE_REDIS=False
REDIS_URL="redis://:redis123@${LOCAL_HOST}:${REDIS_PORT}/0"

# CORS Origins
BACKEND_CORS_ORIGINS=["http://${LOCAL_HOST}:$WEB_PORT", "http://localhost:$WEB_PORT", "http://${LOCAL_HOST}", "http://localhost"]

# Logging Settings
LOG_LEVEL="$([ "$DEBUG" = true ] && echo "DEBUG" || echo "INFO")"
LOG_FORMAT="json"

# Superuser Settings (for initial setup)
FIRST_SUPERUSER="admin"
FIRST_SUPERUSER_PASSWORD="${admin_password}"
FIRST_SUPERUSER_EMAIL="admin@example.com"

# Security Settings
PASSWORD_MIN_LENGTH=12
PASSWORD_REQUIRE_UPPERCASE=true
PASSWORD_REQUIRE_LOWERCASE=true
PASSWORD_REQUIRE_NUMBERS=true
PASSWORD_REQUIRE_SPECIAL_CHARS=true
PASSWORD_HISTORY_COUNT=5
PASSWORD_EXPIRY_DAYS=90

# MFA Settings
MFA_TOTP_ISSUER="IPv6 WireGuard Manager"
MFA_BACKUP_CODES_COUNT=10
MFA_SMS_ENABLED=false
MFA_EMAIL_ENABLED=true

# API Security Settings
RATE_LIMIT_REQUESTS_PER_MINUTE=60
RATE_LIMIT_REQUESTS_PER_HOUR=1000
RATE_LIMIT_BURST_LIMIT=10
MAX_REQUEST_SIZE=10485760
MAX_HEADER_SIZE=8192

# Monitoring Settings
PROMETHEUS_ENABLED=true
PROMETHEUS_PORT=9090
HEALTH_CHECK_INTERVAL=30
ALERT_CPU_THRESHOLD=80.0
ALERT_MEMORY_THRESHOLD=85.0
ALERT_DISK_THRESHOLD=90.0

# Logging Settings
LOG_AGGREGATION_ENABLED=true
ELASTICSEARCH_ENABLED=false
ELASTICSEARCH_HOSTS=["localhost:9200"]
LOG_RETENTION_DAYS=30

# Cache Settings
CACHE_BACKEND="memory"
CACHE_MAX_SIZE=1000
CACHE_DEFAULT_TTL=3600
CACHE_COMPRESSION=false

# Compression Settings
RESPONSE_COMPRESSION_ENABLED=true
COMPRESSION_MIN_SIZE=1024
COMPRESSION_MAX_SIZE=10485760
COMPRESSION_LEVEL=6

# Path Configuration (Dynamic)
INSTALL_DIR="$INSTALL_DIR"
FRONTEND_DIR="$FRONTEND_DIR"
WIREGUARD_CONFIG_DIR="$WIREGUARD_CONFIG_DIR"
NGINX_LOG_DIR="$NGINX_LOG_DIR"
NGINX_CONFIG_DIR="$NGINX_CONFIG_DIR"
BIN_DIR="$BIN_DIR"
LOG_DIR="$LOG_DIR"
TEMP_DIR="$TEMP_DIR"
BACKUP_DIR="$BACKUP_DIR"
CACHE_DIR="$CACHE_DIR"

# API Endpoint Configuration (Dynamic)
API_BASE_URL="http://${LOCAL_HOST}:$API_PORT/api/v1"
WEBSOCKET_URL="ws://${LOCAL_HOST}:$API_PORT/ws/"
BACKEND_HOST="${LOCAL_HOST}"
BACKEND_PORT=$API_PORT
FRONTEND_PORT=$WEB_PORT
NGINX_PORT=$WEB_PORT

# Security Configuration (Dynamic)
DEFAULT_USERNAME="admin"
DEFAULT_PASSWORD="${admin_password}"
SESSION_TIMEOUT=1440
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION=15
EOF
    
    # 设置权限
    chown "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR/.env"
    chmod 600 "$INSTALL_DIR/.env"
    
    log_success "环境配置文件创建完成"
}

# 初始化数据库
initialize_database() {
    log_info "初始化数据库和创建超级用户..."
    
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
    # 设置数据库环境变量 - 以基础 mysql:// 提供，应用层自动选择异步驱动
    export DATABASE_URL="mysql://${DB_USER}:${DB_PASSWORD}@127.0.0.1:${DB_PORT}/${DB_NAME}"
    export DB_TYPE="mysql"
    export DB_ENGINE="mysql"
    
    # 检查数据库服务状态
    log_info "检查数据库服务状态..."
    if ! systemctl is-active --quiet mysql && ! systemctl is-active --quiet mariadb; then
        log_warning "数据库服务未运行，尝试启动..."
        if systemctl start mysql 2>/dev/null || systemctl start mariadb 2>/dev/null; then
            log_success "数据库服务启动成功"
            sleep 3  # 等待服务完全启动
        else
            log_error "无法启动数据库服务，请确保MySQL/MariaDB服务正常运行"
            log_error "安装终止，需要MySQL数据库"
            exit 1
        fi
    fi
    
    # 检查数据库连接
    log_info "检查数据库连接..."
    if ! python -c "
import os
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy import text

async def check_connection():
    try:
        # 获取数据库URL并确保使用正确的异步驱动
        db_url = os.environ.get('DATABASE_URL')
        # 规范为 aiomysql 异步驱动
        if db_url.startswith('mysql://'):
            async_db_url = db_url.replace('mysql://', 'mysql+aiomysql://', 1)
        elif db_url.startswith('mysql+pymysql://'):
            async_db_url = db_url.replace('mysql+pymysql://', 'mysql+aiomysql://', 1)
        else:
            async_db_url = db_url
            
        # 使用异步引擎检查连接
        engine = create_async_engine(async_db_url)
        async with engine.begin() as conn:
            result = await conn.execute(text('SELECT 1'))
            print('Database connection successful')
        await engine.dispose()
        return True
    except Exception as e:
        print(f'Database connection failed: {e}')
        # 尝试使用原始URL连接
        try:
            print('Trying with original URL...')
            # 即便原始URL为基础mysql://，依然转换为aiomysql以避免MySQLdb依赖
            fallback_url = db_url.replace('mysql://', 'mysql+aiomysql://', 1) if db_url and db_url.startswith('mysql://') else db_url
            engine = create_async_engine(fallback_url)
            async with engine.begin() as conn:
                result = await conn.execute(text('SELECT 1'))
                print('Database connection successful with original URL')
            await engine.dispose()
            return True
        except Exception as e2:
            print(f'Original URL also failed: {e2}')
            return False

# 运行异步检查
success = asyncio.run(check_connection())
exit(0 if success else 1)
" 2>/dev/null; then
        log_error "数据库连接失败，请检查MySQL配置和用户权限"
        log_error "安装终止，需要有效的MySQL数据库连接"
        exit 1
    fi
    
    # 尝试使用简化的数据库初始化脚本
    if [[ -f "backend/init_database_simple.py" ]]; then
        log_info "使用简化的数据库初始化脚本..."
        if python backend/init_database_simple.py; then
            log_success "数据库初始化成功"
        else
            log_warning "简化数据库初始化脚本失败，尝试标准初始化..."
            initialize_database_standard
        fi
    else
        log_info "使用标准数据库初始化..."
        initialize_database_standard
    fi
    
    log_success "数据库初始化完成"
}

# 标准数据库初始化函数
initialize_database_standard() {
    # 使用基础 mysql://，应用层会自动转换为 mysql+aiomysql://
    export DATABASE_URL="mysql://${DB_USER}:${DB_PASSWORD}@127.0.0.1:${DB_PORT}/${DB_NAME}"
    log_info "使用基础驱动初始化数据库（应用层自动选择异步驱动）: ${DATABASE_URL}"
    
    # 创建一个临时的Python脚本来初始化数据库，避免在python -c中使用__file__
    cat > /tmp/init_db_temp.py << 'EOF'
import asyncio
import sys
import os
from pathlib import Path

# 获取当前脚本所在目录
try:
    script_dir = Path(__file__).parent
except NameError:
    script_dir = Path.cwd()

# 添加backend目录到路径
backend_path = script_dir / "backend"
if backend_path.exists():
    sys.path.insert(0, str(backend_path))

from app.core.database import init_db, get_async_db
from app.core.security_enhanced import init_permissions_and_roles, security_manager
from app.models.models_complete import User, Role, Permission
from app.schemas.user import UserCreate
from app.services.user_service import UserService
from app.core.config_enhanced import settings

async def main():
    print('Starting database initialization with aiomysql driver...')
    print(f'Database URL: {os.environ.get("DATABASE_URL")}')
    try:
        await init_db()
        print('Database tables created successfully')
    except Exception as e:
        print(f'Database initialization failed: {e}')
        print('MySQL数据库初始化失败，请检查数据库配置和权限')
        exit(1)
    
    async for db in get_async_db():
        # 初始化权限和角色
        print('Initializing permissions and roles...')
        try:
            await init_permissions_and_roles(db)
            print('Permissions and roles initialized.')
        except Exception as e:
            print(f'Permissions and roles initialization failed: {e}')
            # 继续执行，这不是致命错误
        
        # 创建超级用户
        user_service = UserService(db)
        existing_superuser = await user_service.get_user_by_username(settings.FIRST_SUPERUSER)
        
        if not existing_superuser:
            print(f'Creating initial superuser: {settings.FIRST_SUPERUSER}...')
            superuser_data = UserCreate(
                username=settings.FIRST_SUPERUSER,
                email=settings.FIRST_SUPERUSER_EMAIL,
                password=settings.FIRST_SUPERUSER_PASSWORD,
                is_active=True,
                is_superuser=True
            )
            try:
                await user_service.create_user(superuser_data)
                print('Initial superuser created successfully.')
            except Exception as e:
                print(f'Failed to create superuser: {e}')
        else:
            print(f'Superuser {settings.FIRST_SUPERUSER} already exists.')
    
    print('Database initialization complete.')

if __name__ == '__main__':
    try:
        asyncio.run(main())
    except Exception as e:
        print(f'Database initialization failed: {e}')
        exit(1)
EOF

    # 执行临时脚本
    python /tmp/init_db_temp.py
    
    # 清理临时文件
    rm -f /tmp/init_db_temp.py
}

# 测试API功能
test_api_functionality() {
    log_info "测试API功能..."
    
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
    # 检查是否有API测试脚本
    if [[ -f "backend/test_api.py" ]]; then
        log_info "运行API测试..."
        python backend/test_api.py
        if [[ $? -eq 0 ]]; then
            log_success "API测试通过"
        else
            log_warning "API测试失败，但继续安装"
        fi
    else
        log_info "API测试脚本不存在，跳过测试"
    fi
}
create_system_service() {
    log_info "创建系统服务..."
    
    cat > /etc/systemd/system/ipv6-wireguard-manager.service << EOF
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target mysql.service mariadb.service mysqld.service
Wants=mysql.service mariadb.service mysqld.service

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
EnvironmentFile=$INSTALL_DIR/.env
ExecStart=$INSTALL_DIR/venv/bin/uvicorn backend.app.main:app --host ${SERVER_HOST} --port $API_PORT --workers 1
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ipv6-wireguard-manager

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable ipv6-wireguard-manager
    
    log_success "系统服务创建完成"
}

# 安装CLI管理工具
install_cli_tool() {
    log_info "安装CLI管理工具..."
    
    # 复制CLI工具到系统路径
    cp "$INSTALL_DIR/ipv6-wireguard-manager" "/usr/local/bin/"
    chmod +x "/usr/local/bin/ipv6-wireguard-manager"
    
    # 创建符号链接（可选）
    ln -sf "/usr/local/bin/ipv6-wireguard-manager" "/usr/bin/ipv6-wireguard-manager" 2>/dev/null || true
    
    log_success "CLI管理工具安装完成"
    log_info "使用方法: ipv6-wireguard-manager help"
}

# 创建必要的目录并设置权限
create_directories_and_permissions() {
    log_info "创建必要的目录并设置权限..."
    
    # 创建必要的目录
    local directories=(
        "$INSTALL_DIR/uploads"
        "$INSTALL_DIR/logs"
        "$INSTALL_DIR/temp"
        "$INSTALL_DIR/backups"
        "$INSTALL_DIR/config"
        "$INSTALL_DIR/data"
        "$INSTALL_DIR/wireguard"
        "$INSTALL_DIR/wireguard/clients"
    )
    
    # 创建 WireGuard 系统配置目录（如果不存在）
    if [[ ! -d "/etc/wireguard" ]]; then
        mkdir -p "/etc/wireguard"
        chmod 700 "/etc/wireguard"
        log_info "✓ 创建 WireGuard 系统配置目录: /etc/wireguard"
    else
        # 确保权限正确
        chmod 700 "/etc/wireguard"
        log_info "✓ 设置 WireGuard 系统配置目录权限: /etc/wireguard"
    fi
    
    for directory in "${directories[@]}"; do
        mkdir -p "$directory"
        chown "$SERVICE_USER:$SERVICE_GROUP" "$directory"
        chmod 755 "$directory"
        log_info "✓ 创建目录: $directory"
    done
    
    # 设置安装目录权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
    find "$INSTALL_DIR" -type d -exec chmod 755 {} \;
    find "$INSTALL_DIR" -type f -exec chmod 644 {} \;
    find "$INSTALL_DIR" -name "*.py" -exec chmod 755 {} \;
    find "$INSTALL_DIR" -name "*.sh" -exec chmod 755 {} \;
    find "$INSTALL_DIR/venv/bin" -type f -exec chmod 755 {} \;
    
    log_success "目录和权限设置完成"
}

# 启动服务 - 增强版
start_services() {
    log_info "启动服务..."
    
    # 创建scripts目录并复制服务检查脚本
    mkdir -p "$INSTALL_DIR/scripts"
    cp -f "$(dirname "$0")/fix_service_startup_check.sh" "$INSTALL_DIR/scripts/" 2>/dev/null || {
        log_warning "无法复制服务检查脚本，将直接创建..."
        cat > "$INSTALL_DIR/scripts/check_api_service.sh" << 'EOF'
#!/bin/bash

# API服务检查脚本
# 用于一键安装后检查API服务的状态和功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置参数
API_PORT=${API_PORT:-8000}
WEB_PORT=${WEB_PORT:-80}
HOSTNAME=${HOSTNAME:-localhost}
INSTALL_DIR=${INSTALL_DIR:-/opt/ipv6-wireguard-manager}

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

# 检查系统服务状态
check_service_status() {
    local service_name=$1
    local service_description=$2
    
    log_info "检查 $service_description 服务状态..."
    
    if systemctl is-active --quiet "$service_name"; then
        log_success "$service_description 服务正在运行"
        return 0
    else
        log_error "$service_description 服务未运行"
        return 1
    fi
}

# 检查端口监听状态
check_port_listening() {
    local port=$1
    local protocol=$2
    local description=$3
    
    log_info "检查 $description 端口 $port ($protocol) 监听状态..."
    
    if netstat -tuln | grep -q ":$port "; then
        log_success "$description 端口 $port ($protocol) 正在监听"
        return 0
    else
        log_error "$description 端口 $port ($protocol) 未监听"
        return 1
    fi
}

# 检查IPv4连接性
check_ipv4_connectivity() {
    local service_name=$1
    local port=$2
    local path=$3
    
    log_info "检查 $service_name IPv4 连接性..."
    
    if curl -4 -s --connect-timeout 5 "http://${LOCAL_HOST}:$port$path" >/dev/null 2>&1; then
        log_success "$service_name IPv4 连接正常"
        return 0
    else
        log_error "$service_name IPv4 连接失败"
        return 1
    fi
}

# 检查IPv6连接性
check_ipv6_connectivity() {
    local service_name=$1
    local port=$2
    local path=$3
    
    log_info "检查 $service_name IPv6 连接性..."
    
    if curl -6 -s --connect-timeout 5 "http://[::1]:$port$path" >/dev/null 2>&1; then
        log_success "$service_name IPv6 连接正常"
        return 0
    else
        log_warning "$service_name IPv6 连接失败 (可能系统不支持IPv6或未启用)"
        return 1
    fi
}

# 检查API健康状态
check_api_health() {
    log_info "检查API健康状态..."
    
    local response=$(curl -s --connect-timeout 10 "http://localhost:$API_PORT/api/v1/health" 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        # 尝试解析JSON响应
        if echo "$response" | grep -q '"status"' 2>/dev/null; then
            local status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
            if [[ "$status" == "healthy" || "$status" == "ok" ]]; then
                log_success "API健康状态: $status"
                return 0
            else
                log_warning "API健康状态: $status"
                return 1
            fi
        else
            log_success "API响应正常 (非标准健康检查端点)"
            return 0
        fi
    else
        log_error "无法获取API健康状态"
        return 1
    fi
}

# 检查API文档可访问性
check_api_docs() {
    log_info "检查API文档可访问性..."
    
    if curl -s --connect-timeout 10 "http://localhost:$API_PORT/docs" | grep -q "swagger" 2>/dev/null; then
        log_success "API文档可正常访问"
        return 0
    else
        log_error "无法访问API文档"
        return 1
    fi
}

# 检查API基本功能
check_api_functionality() {
    log_info "检查API基本功能..."
    
    # 检查API根端点
    local root_response=$(curl -s --connect-timeout 10 "http://localhost:$API_PORT/" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        log_success "API根端点响应正常"
    else
        log_error "API根端点无响应"
        return 1
    fi
    
    # 检查API版本端点
    local version_response=$(curl -s --connect-timeout 10 "http://localhost:$API_PORT/api/v1/" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        log_success "API版本端点响应正常"
    else
        log_warning "API版本端点无响应"
    fi
    
    return 0
}

# 检查API服务日志
check_api_logs() {
    log_info "检查API服务最近的日志..."
    
    local log_lines=10
    local error_count=$(journalctl -u ipv6-wireguard-manager --no-pager -n $log_lines | grep -i "error\|exception\|failed" | wc -l)
    
    if [[ $error_count -eq 0 ]]; then
        log_success "API服务最近 $log_lines 行日志中无错误"
    else
        log_warning "API服务最近 $log_lines 行日志中发现 $error_count 个错误"
        journalctl -u ipv6-wireguard-manager --no-pager -n $log_lines | grep -i "error\|exception\|failed"
    fi
}

# 检查API服务进程状态
check_api_process() {
    log_info "检查API服务进程状态..."
    
    local process_count=$(pgrep -f "uvicorn.*backend.app.main:app" | wc -l)
    
    if [[ $process_count -gt 0 ]]; then
        log_success "API服务进程正在运行 (进程数: $process_count)"
        
        # 检查进程资源使用情况
        local pid=$(pgrep -f "uvicorn.*backend.app.main:app" | head -1)
        if [[ -n "$pid" ]]; then
            local memory=$(ps -p "$pid" -o rss= | tr -d ' ')
            local memory_mb=$((memory / 1024))
            log_info "API服务进程内存使用: ${memory_mb}MB"
        fi
    else
        log_error "未找到API服务进程"
        return 1
    fi
}

# 生成检查报告
generate_report() {
    local total_checks=$1
    local passed_checks=$2
    local failed_checks=$((total_checks - passed_checks))
    
    echo ""
    echo "===================================="
    echo "API服务检查报告"
    echo "===================================="
    echo "总检查项目: $total_checks"
    echo -e "通过检查: ${GREEN}$passed_checks${NC}"
    echo -e "失败检查: ${RED}$failed_checks${NC}"
    
    if [[ $failed_checks -eq 0 ]]; then
        echo ""
        log_success "所有检查通过！API服务运行正常。"
        return 0
    else
        echo ""
        log_warning "部分检查未通过，请检查相关配置和日志。"
        return 1
    fi
}

# 主检查函数
check_api_service() {
    echo "===================================="
    echo "IPv6 WireGuard Manager API服务检查"
    echo "===================================="
    echo ""
    
    local total_checks=0
    local passed_checks=0
    
    # 检查系统服务状态
    ((total_checks++))
    if check_service_status "ipv6-wireguard-manager" "API服务"; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查端口监听状态
    ((total_checks++))
    if check_port_listening "$API_PORT" "tcp" "API服务"; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查IPv4连接性
    ((total_checks++))
    if check_ipv4_connectivity "API服务" "$API_PORT" "/api/v1/health"; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查IPv6连接性
    ((total_checks++))
    if check_ipv6_connectivity "API服务" "$API_PORT" "/api/v1/health"; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查API健康状态
    ((total_checks++))
    if check_api_health; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查API文档可访问性
    ((total_checks++))
    if check_api_docs; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查API基本功能
    ((total_checks++))
    if check_api_functionality; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查API服务进程状态
    ((total_checks++))
    if check_api_process; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查API服务日志
    ((total_checks++))
    if check_api_logs; then
        ((passed_checks++))
    fi
    echo ""
    
    # 生成检查报告
    generate_report $total_checks $passed_checks
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -p, --port PORT      指定API端口 (默认: 8000)"
    echo "  -w, --web-port PORT  指定Web端口 (默认: 80)"
    echo "  -h, --hostname HOST  指定主机名 (默认: localhost)"
    echo "  -i, --install-dir DIR 指定安装目录 (默认: /opt/ipv6-wireguard-manager)"
    echo "  --help               显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                   # 使用默认参数检查"
    echo "  $0 -p 8080           # 指定API端口为8080"
    echo "  $0 -w 8080 -p 8001   # 指定Web端口为8080，API端口为8001"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            API_PORT="$2"
            shift 2
            ;;
        -w|--web-port)
            WEB_PORT="$2"
            shift 2
            ;;
        -h|--hostname)
            HOSTNAME="$2"
            shift 2
            ;;
        -i|--install-dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 运行主函数
main "$@"
EOF
    }
    chmod +x "$INSTALL_DIR/scripts/check_api_service.sh"
    log_success "API服务检查脚本已创建"
    
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
    
    # 检查数据库连接（避免命令行明文密码）
    DB_HOST=$(grep -E '^DATABASE_HOST=' "$INSTALL_DIR/.env" | cut -d'=' -f2 | tr -d '"' || echo "localhost")
    DB_USER=$(grep -E '^DATABASE_USER=' "$INSTALL_DIR/.env" | cut -d'=' -f2 | tr -d '"' || echo "ipv6wgm")
    DB_PASS=$(grep -E '^DATABASE_PASSWORD=' "$INSTALL_DIR/.env" | cut -d'=' -f2 | tr -d '"' || echo "ipv6wgm_password")
    if env MYSQL_PWD="$DB_PASS" mysql -h "$DB_HOST" -u "$DB_USER" -e "SELECT 1;" &>/dev/null; then
        log_success "✓ 数据库连接正常"
    else
        log_error "✗ 数据库连接异常"
        return 1
    fi
    
    # 检查Web服务
    if curl -f http://localhost:$WEB_PORT/ &>/dev/null; then
        log_success "✓ Web服务正常"
    else
        log_error "✗ Web服务异常"
        return 1
    fi
    
    # 检查API服务（带重试机制）
    log_info "等待API服务启动..."
    local api_retry_count=0
    local api_max_retries=15
    local api_retry_delay=5
    
    while [[ $api_retry_count -lt $api_max_retries ]]; do
        # 检查API健康端点
        if curl -f http://[::1]:$API_PORT/api/v1/health &>/dev/null || curl -f http://${LOCAL_HOST}:$API_PORT/api/v1/health &>/dev/null; then
            log_success "✓ API服务正常"
            
            # 运行API功能测试
            test_api_functionality
            
            return 0
        else
            api_retry_count=$((api_retry_count + 1))
            if [[ $api_retry_count -lt $api_max_retries ]]; then
                log_info "API服务未就绪，等待 ${api_retry_delay} 秒后重试... (${api_retry_count}/${api_max_retries})"
                sleep $api_retry_delay
            fi
        fi
    done
    
    log_error "✗ API服务异常（重试 ${api_max_retries} 次后仍无法连接）"
    log_info "请检查服务状态: sudo systemctl status ipv6-wireguard-manager"
    log_info "请查看服务日志: sudo journalctl -u ipv6-wireguard-manager -f"
    log_info "请检查API配置: $INSTALL_DIR/.env"
    return 1
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
    log_info "  API根端点: http://localhost:$API_PORT/"
    echo ""
    
    if [[ "$INSTALL_TYPE" = "docker" ]]; then
        log_info "初始登录信息（自动生成模式）:"
        log_info "  用户名: admin"
        log_info "  密码: 查看上方自动生成的密码"
        log_info "  邮箱: admin@example.com"
        echo ""
        log_warning "⚠️  重要：请立即登录并修改默认密码！"
        log_warning "⚠️  自动生成的密码已显示在上方，请妥善保存！"
        echo ""
        log_info "🔍 如需重新查看自动生成的凭据:"
        log_info "  cd $INSTALL_DIR && docker-compose logs backend | grep '自动生成的'"
        echo ""
    else
        log_info "初始登录信息:"
        log_info "  用户名: admin"
        log_info "  密码: $admin_password"
        log_info "  邮箱: admin@example.com"
        echo ""
        log_warning "⚠️  重要：请立即登录并修改默认密码！"
        log_warning "⚠️  此密码仅显示一次，请妥善保存！"
        echo ""
    fi
    
    if [[ "$INSTALL_TYPE" = "docker" ]]; then
        log_info "Docker服务管理:"
        log_info "  查看容器状态: cd $INSTALL_DIR && docker-compose ps"
        log_info "  启动服务: cd $INSTALL_DIR && docker-compose start"
        log_info "  停止服务: cd $INSTALL_DIR && docker-compose stop"
        log_info "  重启服务: cd $INSTALL_DIR && docker-compose restart"
        log_info "  查看日志: cd $INSTALL_DIR && docker-compose logs -f"
        echo ""
        log_info "数据库管理:"
        log_info "  连接MySQL: cd $INSTALL_DIR && docker-compose exec mysql mysql -u root -p"
        log_info "  备份数据: cd $INSTALL_DIR && docker-compose exec mysql mysqldump -u root -p ipv6wgm > backup.sql"
        echo ""
    else
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
    fi
    
    log_info "配置文件:"
    log_info "  应用配置: $INSTALL_DIR/.env"
    if [[ "$INSTALL_TYPE" = "docker" ]]; then
        log_info "  Docker配置: $INSTALL_DIR/docker-compose.yml"
    else
        log_info "  Nginx配置: /etc/nginx/sites-available/ipv6-wireguard-manager"
        log_info "  服务配置: /etc/systemd/system/ipv6-wireguard-manager.service"
    fi
    echo ""
    
    log_info "API修复功能:"
    log_info "  ✓ 数据库模型已修复（UserRole, RolePermission）"
    log_info "  ✓ API端点导入错误已修复"
    log_info "  ✓ 认证系统已完善"
    log_info "  ✓ 环境配置已优化"
    log_info "  ✓ 数据库初始化已自动化"
    log_info "  ✓ API路径构建器已安装"
    echo ""
    
    log_info "辅助工具:"
    log_info "  系统兼容性测试: ./test_system_compatibility.sh"
    log_info "  安装验证: ./verify_installation.sh"
    log_info "  PHP-FPM修复: ./fix_php_fpm.sh"
    log_info "  API测试: cd $INSTALL_DIR && python backend/test_api.py"
    log_info "  API服务检查: $INSTALL_DIR/scripts/check_api_service.sh"
    echo ""
    
    # 运行API服务检查
    if [[ -f "$INSTALL_DIR/scripts/check_api_service.sh" ]]; then
        log_info "正在运行API服务检查..."
        chmod +x "$INSTALL_DIR/scripts/check_api_service.sh"
        "$INSTALL_DIR/scripts/check_api_service.sh" -p $API_PORT
        echo ""
    fi
    
    log_success "感谢使用IPv6 WireGuard Manager！"
    
    # 如果是自动退出模式，显示简短信息后退出
    if [[ "$AUTO_EXIT" = true ]]; then
        echo ""
        log_info "自动退出模式：安装已完成，脚本将自动退出"
        echo ""
        log_info "快速启动命令:"
        if [[ "$INSTALL_TYPE" = "docker" ]]; then
            log_info "  cd $INSTALL_DIR && docker-compose start"
        else
            log_info "  sudo systemctl start ipv6-wireguard-manager"
        fi
        echo ""
        exit 0
    fi
}

# 主函数
main() {
    log_info "IPv6 WireGuard Manager - 智能安装脚本 v$SCRIPT_VERSION"
    echo ""
    
    # 检测是否通过管道执行（curl ... | bash）
    if [[ -t 0 ]]; then
        # 交互模式 - 终端是TTY
        INTERACTIVE_MODE=true
    else
        # 非交互模式 - 通过管道执行
        INTERACTIVE_MODE=false
        # 自动启用智能安装模式
        if [[ "$AUTO_EXIT" = false ]]; then
            AUTO_EXIT=true
            SILENT=true
            log_info "检测到非交互模式，自动启用智能安装模式..."
        fi
    fi
    
    # 检测系统
    detect_system
    detect_system_paths
    check_requirements
    
    # 解析参数
    parse_arguments "$@"
    
    # 选择安装类型
    select_install_type
    
    # 设置默认值
    set_defaults
    
    # 根据模式显示不同级别的信息
    if [[ "$AUTO_EXIT" = true ]]; then
        log_info "智能安装模式：自动配置参数，安装完成后将自动退出"
        echo ""
        log_info "自动配置的安装参数:"
        log_info "  类型: $INSTALL_TYPE"
        log_info "  目录: $INSTALL_DIR"
        log_info "  Web端口: $WEB_PORT"
        log_info "  API端口: $API_PORT"
        log_info "  性能优化: $PERFORMANCE"
        log_info "  生产模式: $PRODUCTION"
        echo ""
    else
        log_info "安装配置:"
        log_info "  类型: $INSTALL_TYPE"
        log_info "  目录: $INSTALL_DIR"
        log_info "  Web端口: $WEB_PORT"
        log_info "  API端口: $API_PORT"
        log_info "  服务用户: $SERVICE_USER"
        log_info "  Python版本: $PYTHON_VERSION"
        log_info "  PHP版本: $PHP_VERSION"
        echo ""
    fi
    
    # 执行安装
    case $INSTALL_TYPE in
        "docker")
            install_docker
            ;;
        "native")
            if [[ "$AUTO_EXIT" = true ]]; then
                log_step "开始原生安装（智能模式）..."
            else
                log_step "开始原生安装..."
            fi
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
                create_directories_and_permissions
                create_system_service
                install_cli_tool
            fi
            start_services
            ;;
        "minimal")
            if [[ "$AUTO_EXIT" = true ]]; then
                log_step "开始最小化安装（智能模式）..."
            else
                log_step "开始最小化安装..."
            fi
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
                create_directories_and_permissions
                create_system_service
                install_cli_tool
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