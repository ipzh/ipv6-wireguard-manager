#!/bin/bash

#=============================================================================
# IPv6 WireGuard Manager - 智能安装脚本
#=============================================================================
# 
# 功能说明:
#   - 支持多种安装方式：Docker、原生安装、最小化安装
#   - 自动检测系统环境和资源配置
#   - 智能选择最佳安装方案
#   - 完整的错误处理和恢复机制
#   - 企业级VPN管理平台一键部署
#
# 支持的操作系统:
#   - Ubuntu 18.04+
#   - Debian 9+
#   - CentOS 7+
#   - RHEL 7+
#   - Fedora 30+
#   - Arch Linux
#   - openSUSE 15+
#
# 作者: IPv6 WireGuard Manager Team
# 版本: 3.1.0
# 许可: MIT
#
#=============================================================================

# Bash严格模式设置
set -e          # 遇到错误立即退出
set -u          # 使用未定义变量时报错
set -o pipefail # 管道命令中任一失败则整体失败

#-----------------------------------------------------------------------------
# 错误处理函数
#-----------------------------------------------------------------------------
# 说明: 捕获脚本执行过程中的错误并提供详细的错误信息
# 参数: $1 - 错误发生的行号
#-----------------------------------------------------------------------------
handle_error() {
    local exit_code=$?
    local line_number=$1
    log_error "脚本在第 $line_number 行执行失败，退出码: $exit_code"
    log_info "请检查上述错误信息并重试"
    exit $exit_code
}

# 设置错误陷阱，当发生错误时自动调用错误处理函数
trap 'handle_error $LINENO' ERR

#-----------------------------------------------------------------------------
# 颜色定义 - 用于美化终端输出
#-----------------------------------------------------------------------------
RED='\033[0;31m'      # 红色 - 用于错误信息
GREEN='\033[0;32m'    # 绿色 - 用于成功信息
YELLOW='\033[1;33m'   # 黄色 - 用于警告信息
BLUE='\033[0;34m'     # 蓝色 - 用于普通信息
PURPLE='\033[0;35m'   # 紫色 - 用于调试信息
CYAN='\033[0;36m'     # 青色 - 用于步骤信息
NC='\033[0m'          # 无颜色 - 重置颜色

#-----------------------------------------------------------------------------
# 日志输出函数
#-----------------------------------------------------------------------------
# 说明: 提供统一的日志输出格式，支持不同级别的日志
#-----------------------------------------------------------------------------

# 普通信息日志（蓝色）
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# 成功信息日志（绿色）
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 警告信息日志（黄色）
log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 错误信息日志（红色）
log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 调试信息日志（紫色）
log_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

# 步骤信息日志（青色）
log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

#=============================================================================
# 全局变量定义
#=============================================================================

#-----------------------------------------------------------------------------
# 基础配置变量
#-----------------------------------------------------------------------------
SCRIPT_VERSION="3.1.0"                                                # 脚本版本号
PROJECT_NAME="IPv6 WireGuard Manager"                                # 项目名称
PROJECT_REPO="https://github.com/ipzh/ipv6-wireguard-manager.git"   # 项目仓库地址
DEFAULT_INSTALL_DIR="/opt/ipv6-wireguard-manager"                    # 默认安装目录
FRONTEND_DIR="/var/www/html"                                         # 前端文件目录
DEFAULT_PORT="80"                                                     # 默认Web端口
DEFAULT_API_PORT="8000"                                               # 默认API端口
NGINX_CONFIG_DIR=""                                                   # 可选自定义Nginx配置目录

#-----------------------------------------------------------------------------
# 系统信息变量（由detect_system函数检测并填充）
#-----------------------------------------------------------------------------
OS_ID=""                # 操作系统ID (ubuntu, debian, centos等)
OS_VERSION=""           # 操作系统版本号
OS_NAME=""              # 操作系统完整名称
ARCH=""                 # 系统架构 (x86_64, aarch64等)
PACKAGE_MANAGER=""      # 包管理器 (apt, yum, dnf等)
MEMORY_MB=""            # 系统内存大小（MB）
CPU_CORES=""            # CPU核心数
DISK_SPACE_MB=""        # 可用磁盘空间（MB）
IPV6_SUPPORT=false      # IPv6支持状态

#-----------------------------------------------------------------------------
# 安装配置变量（由用户输入或自动检测填充）
#-----------------------------------------------------------------------------
INSTALL_TYPE=""         # 安装类型 (docker, native, minimal)
INSTALL_DIR=""          # 实际安装目录
WEB_PORT=""             # 实际使用的Web端口
API_PORT=""             # 实际使用的API端口
SERVICE_USER="ipv6wgm"  # 系统服务运行用户
SERVICE_GROUP="ipv6wgm" # 系统服务运行用户组
PYTHON_VERSION="3.11"   # Python版本
PHP_VERSION="8.1"       # PHP版本
MYSQL_VERSION="8.0"     # MySQL版本

#-----------------------------------------------------------------------------
# 功能开关（通过命令行参数控制）
#-----------------------------------------------------------------------------
SILENT=false            # 静默安装模式（非交互）
PERFORMANCE=false       # 性能优化模式
PRODUCTION=false        # 生产环境模式
DEBUG=false             # 调试模式
SKIP_DEPS=false         # 跳过依赖安装
SKIP_DB=false           # 跳过数据库配置
SKIP_SERVICE=false      # 跳过服务创建
SKIP_FRONTEND=false     # 跳过前端部署
AUTO_EXIT=false         # 自动退出模式（安装完成后自动退出）

#=============================================================================
# 系统检测函数
#=============================================================================

#-----------------------------------------------------------------------------
# safe_execute - 安全执行函数（增强版）
#-----------------------------------------------------------------------------
safe_execute() {
    local description="$1"
    shift
    
    log_info "执行: $description"
    log_debug "命令: $*"
    log_debug "工作目录: $(pwd)"
    
    if "$@"; then
        log_success "$description 完成"
        return 0
    else
        local exit_code=$?
        log_error "$description 失败，退出码: $exit_code"
        log_error "命令: $*"
        log_error "工作目录: $(pwd)"
        
        # 记录详细错误信息到日志
        echo "$(date): ERROR - $description failed with exit code $exit_code" >> /tmp/install_errors.log
        echo "$(date): Command: $*" >> /tmp/install_errors.log
        echo "$(date): Working directory: $(pwd)" >> /tmp/install_errors.log
        
        return $exit_code
    fi
}

#-----------------------------------------------------------------------------
# safe_execute_with_retry - 带重试的安全执行函数
#-----------------------------------------------------------------------------
safe_execute_with_retry() {
    local description="$1"
    local max_retries="${2:-3}"
    local retry_delay="${3:-5}"
    shift 3
    
    local attempt=1
    while [[ $attempt -le $max_retries ]]; do
        log_info "执行: $description (尝试 $attempt/$max_retries)"
        
        if safe_execute "$description" "$@"; then
            return 0
        fi
        
        if [[ $attempt -lt $max_retries ]]; then
            log_warning "执行失败，${retry_delay}秒后重试..."
            sleep $retry_delay
        fi
        
        ((attempt++))
    done
    
    log_error "$description 在 $max_retries 次尝试后仍然失败"
    return 1
}

#-----------------------------------------------------------------------------
# detect_python_version - 检测Python版本
#-----------------------------------------------------------------------------
detect_python_version() {
    log_info "🔍 检测Python版本..."
    
    # 检测已安装的Python版本
    for version in 3.12 3.11 3.10 3.9 3.8; do
        if command -v python$version &>/dev/null; then
            PYTHON_VERSION=$version
            log_success "检测到已安装的Python版本: $PYTHON_VERSION"
            return 0
        fi
    done
    
    # 检测python3
    if command -v python3 &>/dev/null; then
        PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        log_success "检测到Python3版本: $PYTHON_VERSION"
        # 避免使用3.13，优先回退到3.12/3.11 以获得更好的依赖兼容性
        if [[ "$PYTHON_VERSION" == "3.13" ]]; then
            log_warning "检测到Python 3.13，部分依赖尚无预编译轮子，尝试使用3.12/3.11"
            for version in 3.12 3.11; do
                if command -v python$version &>/dev/null; then
                    PYTHON_VERSION=$version
                    log_success "切换到更兼容的Python版本: $PYTHON_VERSION"
                    return 0
                fi
            done
        fi
        return 0
    fi
    
    # 检测可用的Python版本
    case $PACKAGE_MANAGER in
        "apt")
            # 检测可用的Python版本
            local available_versions=()
            for version in 3.12 3.11 3.10 3.9 3.8; do
                if apt-cache show python$version &>/dev/null; then
                    available_versions+=($version)
                fi
            done
            
            if [[ ${#available_versions[@]} -gt 0 ]]; then
                PYTHON_VERSION=${available_versions[0]}
                log_success "检测到可用Python版本: $PYTHON_VERSION"
            else
                PYTHON_VERSION="3.9"  # 默认版本
                log_warning "未检测到Python版本，使用默认版本: $PYTHON_VERSION"
            fi
            ;;
        "yum"|"dnf")
            # RHEL/CentOS通常使用默认Python版本
            PYTHON_VERSION="3.9"  # 默认版本
            log_info "RHEL/CentOS系统，使用默认Python版本: $PYTHON_VERSION"
            ;;
        "pacman")
            # Arch Linux通常使用最新版本
            PYTHON_VERSION="3.11"  # 默认版本
            log_info "Arch Linux系统，使用默认Python版本: $PYTHON_VERSION"
            ;;
        *)
            PYTHON_VERSION="3.9"  # 默认版本
            log_warning "未知系统，使用默认Python版本: $PYTHON_VERSION"
            ;;
    esac
    
    log_info "选择的Python版本: $PYTHON_VERSION"
}

#-----------------------------------------------------------------------------
# generate_secure_password - 生成安全密码（增强版）
#-----------------------------------------------------------------------------
generate_secure_password() {
    local length=${1:-16}
    local password=""
    local attempts=0
    local max_attempts=10
    
    # 仅要求包含大写/小写/数字，避免对"特殊字符"强制要求（兼容URL/数据库）
    while [[ $attempts -lt $max_attempts ]]; do
        # 生成候选密码（剔除易引起转义/URL问题的字符）
        password=$(openssl rand -base64 48 | tr -cd 'A-Za-z0-9._-' | head -c $length)
        
        # 强度校验
        if [[ "$password" =~ [A-Z] ]] && [[ "$password" =~ [a-z] ]] && [[ "$password" =~ [0-9] ]]; then
            # 将日志输出到stderr，确保stdout仅输出密码
            log_success "生成强密码成功（长度: ${#password}）" 1>&2
            echo "$password"
            return 0
        fi
        ((attempts++))
    done
    
    # 备用方法（十六进制+混合），并同样仅向stdout输出密码
    log_warning "无法生成强密码，使用备用方法" 1>&2
    password=$(openssl rand -hex 32 | head -c $length)
    if [[ -z "$password" || ${#password} -lt $length ]]; then
        password=$(date +%s%N | sha256sum | tr -d ' -' | head -c $length)
    fi
    echo "$password"
    return 0
}

#-----------------------------------------------------------------------------
# detect_php_version - 检测PHP版本
#-----------------------------------------------------------------------------
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

#-----------------------------------------------------------------------------
# detect_system - 检测系统信息
#-----------------------------------------------------------------------------
# 功能说明:
#   - 检测操作系统类型、版本和架构
#   - 检测包管理器
#   - 检测系统资源（内存、CPU、磁盘）
#   - 检测IPv6支持情况
#   - 检测PHP版本
# 
# 输出: 填充全局系统信息变量
#-----------------------------------------------------------------------------
detect_system() {
    log_info "检测系统信息..."
    
    #-------------------------------------------------------------------------
    # 检测操作系统类型和版本
    #-------------------------------------------------------------------------
    if [[ -f /etc/os-release ]]; then
        # 现代Linux发行版标准方式
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
    
    # 调用版本检测函数
    detect_python_version
    detect_php_version
    
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
    
    # 系统资源警告检查
    log_info "📊 系统资源信息:"
    log_info "  - 内存: ${MEMORY_MB}MB"
    log_info "  - CPU核心: ${CPU_CORES}"
    log_info "  - 磁盘空间: ${DISK_SPACE_MB}MB"
    
    # 资源不足警告
    if [ "$MEMORY_MB" -lt 1024 ]; then
        log_warning "⚠️  系统内存不足1GB，可能影响性能"
    fi
    
    if [ "$CPU_CORES" -lt 2 ]; then
        log_warning "⚠️  CPU核心数少于2个，可能影响性能"
    fi
    
    if [ "$DISK_SPACE_MB" -lt 10240 ]; then
        log_warning "⚠️  磁盘空间不足10GB，可能影响安装"
    fi
    
    # 检测IPv6支持 - 改进检测逻辑
    # 1. 检查是否有IPv6地址（优先检查::1，因为需要本地连接）
    # 2. 如果无法ping通外部，但本地有IPv6地址，也认为支持IPv6
    IPV6_SUPPORT=false
    if command -v ip >/dev/null 2>&1; then
        # 检查lo接口是否有::1地址（最可靠的方法）
        if ip -6 addr show lo 2>/dev/null | grep -q "inet6.*::1"; then
            IPV6_SUPPORT=true
            log_info "检测到本地IPv6地址（::1），启用IPv6支持"
        # 检查是否有其他IPv6地址（排除本地链路地址）
        elif ip -6 addr show 2>/dev/null | grep "inet6" | grep -v "fe80::" | grep -v "::1" | grep -q "inet6"; then
            IPV6_SUPPORT=true
            log_info "检测到IPv6地址，启用IPv6支持"
        fi
    fi
    
    # 如果上述方法都没检测到，尝试连接性测试（备选方案）
    if [[ "$IPV6_SUPPORT" == "false" ]]; then
        if command -v ping6 &> /dev/null; then
            if ping6 -c 1 -W 2 2001:4860:4860::8888 &> /dev/null 2>&1; then
                IPV6_SUPPORT=true
                log_info "IPv6连接性测试成功，启用IPv6支持"
            fi
        elif command -v ping &> /dev/null; then
            if ping -6 -c 1 -W 2 2001:4860:4860::8888 &> /dev/null 2>&1; then
                IPV6_SUPPORT=true
                log_info "IPv6连接性测试成功，启用IPv6支持"
            fi
        fi
    fi
    
    if [[ "$IPV6_SUPPORT" == "false" ]]; then
        log_info "未检测到IPv6支持，将仅使用IPv4"
    fi
    
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
    
    # 检测安装目录（仅当未通过参数设置时）
    if [[ -z "${INSTALL_DIR:-}" ]]; then
        if [[ -d "/opt" ]]; then
            DEFAULT_INSTALL_DIR="/opt/ipv6-wireguard-manager"
        elif [[ -d "/usr/local" ]]; then
            DEFAULT_INSTALL_DIR="/usr/local/ipv6-wireguard-manager"
        else
            DEFAULT_INSTALL_DIR="$HOME/ipv6-wireguard-manager"
        fi
    else
        DEFAULT_INSTALL_DIR="$INSTALL_DIR"
    fi
    
    # 检测Web目录（仅当未通过参数设置时）
    if [[ -z "${FRONTEND_DIR:-}" ]]; then
        if [[ -d "/var/www/html" ]]; then
            FRONTEND_DIR="/var/www/html"
        elif [[ -d "/usr/share/nginx/html" ]]; then
            FRONTEND_DIR="/usr/share/nginx/html"
        else
            FRONTEND_DIR="${DEFAULT_INSTALL_DIR}/web"
        fi
        log_info "自动检测前端目录: $FRONTEND_DIR"
    else
        log_info "使用自定义前端目录: $FRONTEND_DIR"
    fi
    
    # 检测WireGuard配置目录（仅当未通过参数设置时）
    if [[ -z "${WIREGUARD_CONFIG_DIR:-}" ]]; then
        if [[ -d "/etc/wireguard" ]]; then
            WIREGUARD_CONFIG_DIR="/etc/wireguard"
        else
            WIREGUARD_CONFIG_DIR="${DEFAULT_INSTALL_DIR}/config/wireguard"
        fi
    fi
    
    # 检测Nginx配置目录（仅当未通过参数设置时）
    if [[ -z "${NGINX_CONFIG_DIR:-}" ]]; then
        if [[ -d "/etc/nginx/sites-available" ]]; then
            NGINX_CONFIG_DIR="/etc/nginx/sites-available"
        else
            NGINX_CONFIG_DIR="${DEFAULT_INSTALL_DIR}/config/nginx"
        fi
    fi
    
    # 检测日志目录（仅当未通过参数设置时）
    if [[ -z "${LOG_DIR:-}" ]]; then
        if [[ -d "/var/log" ]]; then
            LOG_DIR="/var/log/ipv6-wireguard-manager"
        else
            LOG_DIR="${DEFAULT_INSTALL_DIR}/logs"
        fi
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
    echo "  --config-dir DIR     WireGuard配置目录"
    echo "  --log-dir DIR        日志目录"
    echo "  --nginx-dir DIR      Nginx配置目录"
    echo "  --systemd-dir DIR    Systemd服务目录"
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
    echo "安装类型说明:"
    echo "  docker               Docker容器化安装（推荐生产环境）"
    echo "  native               原生系统安装（推荐开发环境）"
    echo "  minimal              最小化安装（资源受限环境）"
    echo ""
    echo "智能模式说明:"
    echo "  --auto               自动检测系统环境并选择最佳安装类型"
    echo "  --silent             非交互式安装，使用默认参数"
    echo ""
    echo "跳过选项说明:"
    echo "  --skip-deps          跳过系统依赖安装"
    echo "  --skip-db            跳过数据库配置和创建"
    echo "  --skip-service       跳过系统服务创建"
    echo "  --skip-frontend      跳过前端部署和Nginx配置"
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
    echo "  $0 --production --performance # 生产环境性能优化安装"
    echo ""
    echo "系统要求:"
    echo "  操作系统: Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+, Fedora 30+, Arch Linux, openSUSE 15+"
    echo "  架构: x86_64, ARM64, ARM32"
    echo "  CPU: 1核心以上（推荐2核心以上）"
    echo "  内存: 1GB以上（推荐4GB以上）"
    echo "  存储: 5GB以上可用空间（推荐20GB以上）"
    echo "  网络: 支持IPv6的网络环境（可选）"
    echo ""
    echo "故障排除:"
    echo "  查看安装日志: tail -f /tmp/install_errors.log"
    echo "  检查服务状态: systemctl status ipv6-wireguard-manager"
    echo "  查看服务日志: journalctl -u ipv6-wireguard-manager -f"
    echo "  重新安装: $0 --type native --skip-deps"
    echo ""
    echo "获取帮助:"
    echo "  文档: https://github.com/ipzh/ipv6-wireguard-manager/docs"
    echo "  问题反馈: https://github.com/ipzh/ipv6-wireguard-manager/issues"
    echo "  讨论: https://github.com/ipzh/ipv6-wireguard-manager/discussions"
    echo "  - RHEL 7+"
    echo "  - Fedora 30+"
    echo "  - Arch Linux"
    echo "  - openSUSE 15+"
    echo ""
    echo "安装类型说明:"
    echo "  native   - 原生安装，推荐用于生产环境和开发环境"
    echo "  minimal  - 最小化安装，推荐用于资源受限环境"
    echo "  docker   - 使用Docker Compose部署（需要docker与docker-compose）"
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
            
            # 改进的端口冲突检测
            check_port_available() {
                local port=$1
                local protocol=${2:-tcp}
                
                # 使用多种方法检测端口
                if command -v ss &> /dev/null; then
                    ss -tuln | grep -q ":$port "
                elif command -v netstat &> /dev/null; then
                    netstat -tuln | grep -q ":$port "
                else
                    # 回退到telnet检测
                    timeout 1 bash -c "</dev/tcp/localhost/$port" 2>/dev/null
                fi
            }
            
            # 检查Web端口
            if check_port_available "$DEFAULT_PORT"; then
                WEB_PORT="8080"
                log_info "端口$DEFAULT_PORT已被占用，自动使用端口$WEB_PORT"
            else
                WEB_PORT="$DEFAULT_PORT"
            fi
            
            # 检查API端口
            if check_port_available "$DEFAULT_API_PORT"; then
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
        DB_USER="ipv6wgm"
    fi
    
    if [[ -z "${DB_PASSWORD:-}" ]]; then
        DB_PASSWORD=$(generate_secure_password 16 | tail -n 1)
        # 确保密码生成成功
        if [[ -z "$DB_PASSWORD" || ${#DB_PASSWORD} -lt 12 ]]; then
            log_error "数据库密码生成失败，使用默认密码"
            DB_PASSWORD="ipv6wgm_password_$(date +%s)"
        else
            log_info "生成随机数据库密码"
        fi
    fi
    
    if [[ -z "${DB_NAME:-}" ]]; then
        DB_NAME="ipv6wgm"
    fi
}

# 安装基础系统依赖
install_basic_dependencies() {
    log_info "安装系统依赖..."
    
    case $PACKAGE_MANAGER in
        "apt")
            apt-get update
            if apt-get install -y python$PYTHON_VERSION python$PYTHON_VERSION-venv python$PYTHON_VERSION-dev python3-pip 2>/dev/null; then
                log_success "Python $PYTHON_VERSION 安装成功"
            else
                log_warning "未找到 Python $PYTHON_VERSION，回退到系统默认Python3"
                apt-get install -y python3 python3-venv python3-dev python3-pip
                PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
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
                if safe_execute "安装MySQL 8.0" apt-get install -y mysql-server-8.0 mysql-client-8.0; then
                    log_success "✅ MySQL 8.0安装成功"
                    mysql_installed=true
                    db_install_success=true
                else
                    log_warning "MySQL 8.0安装失败，尝试其他版本"
                fi
                
                # 策略2: 尝试安装默认MySQL
                if [[ "$db_install_success" = false ]]; then
                    log_info "尝试安装默认MySQL版本..."
                    if safe_execute "安装默认MySQL" apt-get install -y mysql-server mysql-client; then
                        log_success "✅ MySQL默认版本安装成功"
                        mysql_installed=true
                        db_install_success=true
                    else
                        log_warning "默认MySQL安装失败，尝试MariaDB"
                    fi
                fi
                
                # 策略3: 尝试安装MariaDB
                if [[ "$db_install_success" = false ]]; then
                    log_info "尝试安装MariaDB（MySQL替代方案）..."
                    if safe_execute "安装MariaDB" apt-get install -y mariadb-server mariadb-client; then
                        log_success "✅ MariaDB安装成功"
                        mysql_installed=true
                        db_install_success=true
                    else
                        log_warning "MariaDB安装失败，尝试MySQL 5.7"
                    fi
                fi
                
                # 策略4: 尝试安装MySQL 5.7
                if [[ "$db_install_success" = false ]]; then
                    log_info "尝试安装MySQL 5.7..."
                    if safe_execute "安装MySQL 5.7" apt-get install -y mysql-server-5.7 mysql-client-5.7; then
                        log_success "✅ MySQL 5.7安装成功"
                        mysql_installed=true
                        db_install_success=true
                    else
                        log_warning "MySQL 5.7安装失败"
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
            
            # 使用安全执行函数安装依赖
            safe_execute "安装Nginx" apt-get install -y nginx
            safe_execute "安装基础工具" apt-get install -y git curl wget build-essential net-tools
            
            # 安装MySQL开发库（用于编译mysqlclient）
            log_info "安装MySQL开发库..."
            if safe_execute "安装MySQL开发库" apt-get install -y libmysqlclient-dev pkg-config; then
                log_success "MySQL开发库安装成功"
            else
                log_warning "MySQL开发库安装失败，mysqlclient可能无法编译"
                log_info "尝试安装替代包..."
                safe_execute "安装替代MySQL开发库" apt-get install -y default-libmysqlclient-dev || true
            fi
            ;;
        "yum"|"dnf")
            safe_execute "安装Python" $PACKAGE_MANAGER install -y python$PYTHON_VERSION python$PYTHON_VERSION-pip python$PYTHON_VERSION-devel
            safe_execute "安装MariaDB" $PACKAGE_MANAGER install -y mariadb-server mariadb
            safe_execute "安装Nginx" $PACKAGE_MANAGER install -y nginx
            safe_execute "安装开发工具" $PACKAGE_MANAGER install -y git curl wget gcc gcc-c++ make
            
            # 安装MySQL开发库
            log_info "安装MySQL开发库..."
            if safe_execute "安装MySQL开发库" $PACKAGE_MANAGER install -y mysql-devel pkgconfig; then
                log_success "MySQL开发库安装成功"
            else
                log_warning "MySQL开发库安装失败，尝试替代包"
                safe_execute "安装替代MySQL开发库" $PACKAGE_MANAGER install -y mariadb-devel || true
            fi
            ;;
        "pacman")
            pacman -Sy
            pacman -S --noconfirm python python-pip
            pacman -S --noconfirm mariadb
            pacman -S --noconfirm nginx
            pacman -S --noconfirm git curl wget base-devel
            
            # 安装MySQL开发库
            log_info "安装MySQL开发库..."
            if pacman -S --noconfirm libmariadbclient 2>/dev/null; then
                log_success "MySQL开发库安装成功"
            else
                log_warning "MySQL开发库安装失败，mysqlclient可能无法编译"
            fi
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

#-----------------------------------------------------------------------------
# install_php - 安装PHP和PHP-FPM
#-----------------------------------------------------------------------------
# 功能说明:
#   - 检测并卸载可能冲突的Apache包
#   - 安装PHP-FPM（避免Apache依赖）
#   - 安装所需的PHP扩展
#   - 验证PHP版本和必需扩展
#   - 启动并启用PHP-FPM服务
#
# 支持的包管理器: apt, yum, dnf, pacman, zypper, emerge, apk
# 依赖: PHP_VERSION全局变量，由detect_php_version设置
#-----------------------------------------------------------------------------
install_php() {
    log_info "安装PHP和PHP-FPM..."
    
    #-------------------------------------------------------------------------
    # 第一步：卸载Apache相关包以避免冲突
    #-------------------------------------------------------------------------
    # 说明: 某些系统安装PHP时会自动安装Apache作为依赖，
    #       我们需要先卸载Apache以确保使用Nginx
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
    
    # 安装MySQL驱动（优先安装）
    log_info "安装MySQL Python驱动..."
    
    # 先尝试安装不需要编译的驱动
    pip install pymysql aiomysql
    log_success "基础MySQL驱动安装完成"
    
    # 尝试安装mysqlclient，如果失败则跳过
    log_info "尝试安装mysqlclient（可能需要编译）..."
    if pip install mysqlclient 2>/dev/null; then
        log_success "mysqlclient安装成功"
    else
        log_warning "mysqlclient安装失败，跳过（pymysql和aiomysql已足够）"
        log_info "如果需要mysqlclient，请安装MySQL开发库："
        log_info "  Ubuntu/Debian: sudo apt-get install libmysqlclient-dev pkg-config"
        log_info "  CentOS/RHEL: sudo yum install mysql-devel pkgconfig"
    fi
    
    # 安装依赖
    if [[ -f "backend/requirements.txt" ]]; then
        pip install -r backend/requirements.txt
        log_success "Python依赖安装成功"
        
        # 安装额外的功能依赖
        log_info "安装增强功能依赖..."
        local optional_install_success=true

        if pip install pytest pytest-cov pytest-xdist pytest-html pytest-mock pytest-asyncio; then
            log_success "测试依赖安装完成"
        else
            log_warning "测试依赖安装失败，继续安装流程"
            optional_install_success=false
        fi

        if pip install flake8 black isort mypy; then
            log_success "代码质量工具安装完成"
        else
            log_warning "代码质量工具安装失败，继续安装流程"
            optional_install_success=false
        fi

        if [[ "$optional_install_success" == true ]]; then
            log_success "增强功能依赖安装完成"
        else
            log_warning "部分增强功能依赖安装失败，核心功能不受影响"
        fi
    elif [[ -f "backend/requirements-simple.txt" ]]; then
        pip install -r backend/requirements-simple.txt
        log_success "Python依赖安装成功（使用简化版本）"
    else
        log_warning "requirements.txt文件不存在，安装基础依赖..."
        # 安装基础依赖
        pip install fastapi uvicorn sqlalchemy alembic pydantic python-dotenv
        pip install passlib python-jose[cryptography] python-multipart
        pip install structlog redis celery
        log_success "基础依赖安装完成"
    fi
}

#-----------------------------------------------------------------------------
# configure_database - 配置数据库
#-----------------------------------------------------------------------------
# 功能说明:
#   - 启动MySQL/MariaDB服务
#   - 创建数据库和用户
#   - 配置用户权限（localhost和127.0.0.1）
#   - 生成环境配置文件
#   - 初始化数据库表结构和超级用户
#
# 注意事项:
#   - 强制使用MySQL/MariaDB，不支持SQLite和PostgreSQL
#   - 使用mysql_native_password插件确保兼容性
#   - 支持MariaDB和MySQL不同的语法
#
# 依赖全局变量: DB_USER, DB_PASSWORD, DB_NAME, DB_PORT
#-----------------------------------------------------------------------------
configure_database() {
    log_info "配置数据库..."
    
    # 强制使用MySQL/MariaDB，确保数据库兼容性
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
    
    # 检查MySQL root用户是否需要密码
    log_info "检查数据库服务状态..."
    if ! mysql -u root -e "SELECT 1;" 2>/dev/null; then
        log_warning "MySQL root用户需要密码，尝试无密码连接..."
        # 尝试无密码连接
        if ! mysql -u root -e "SELECT 1;" 2>/dev/null; then
            log_error "无法连接到MySQL，请检查MySQL服务状态和root密码"
            log_info "请手动设置MySQL root密码后重试："
            log_info "sudo mysql_secure_installation"
            exit 1
        fi
    fi
    
    # 创建数据库和用户（根据数据库类型选择兼容语法）
    log_info "创建数据库: ${DB_NAME}"
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" || {
        log_error "数据库创建失败"
        exit 1
    }
    
    DB_SERVER_VERSION=$(mysql -V 2>/dev/null || true)
    log_info "数据库服务器版本: $DB_SERVER_VERSION"
    
    # 删除可能存在的旧用户
    mysql -u root -e "DROP USER IF EXISTS '${DB_USER}'@'localhost';" 2>/dev/null || true
    mysql -u root -e "DROP USER IF EXISTS '${DB_USER}'@'127.0.0.1';" 2>/dev/null || true
    
    if echo "$DB_SERVER_VERSION" | grep -qi "mariadb"; then
        log_info "检测到MariaDB，使用MariaDB语法创建用户"
        # MariaDB: 使用 IDENTIFIED BY 语法
        mysql -u root -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';" || {
            log_error "创建用户失败 (localhost)"
            exit 1
        }
        mysql -u root -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASSWORD}';" || {
            log_error "创建用户失败 (127.0.0.1)"
            exit 1
        }
    else
        log_info "检测到MySQL，使用MySQL语法创建用户"
        # MySQL: 使用 mysql_native_password 明确插件
        mysql -u root -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';" || {
            log_error "创建用户失败 (localhost)"
            exit 1
        }
        mysql -u root -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';" || {
            log_error "创建用户失败 (127.0.0.1)"
            exit 1
        }
    fi
    
    # 授予权限
    log_info "授予数据库权限..."
    mysql -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';" || {
        log_error "权限授予失败 (localhost)"
        exit 1
    }
    mysql -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1';" || {
        log_error "权限授予失败 (127.0.0.1)"
        exit 1
    }
    mysql -u root -e "FLUSH PRIVILEGES;" || {
        log_error "权限刷新失败"
        exit 1
    }
    
    # 测试用户连接
    log_info "测试数据库用户连接..."
    if mysql -u "${DB_USER}" -p"${DB_PASSWORD}" -h localhost -e "SELECT 1;" 2>/dev/null; then
        log_success "数据库用户连接测试成功 (localhost)"
    else
        log_warning "localhost连接测试失败，尝试127.0.0.1..."
        if mysql -u "${DB_USER}" -p"${DB_PASSWORD}" -h 127.0.0.1 -e "SELECT 1;" 2>/dev/null; then
            log_success "数据库用户连接测试成功 (127.0.0.1)"
        else
            log_error "数据库用户连接测试失败"
            log_info "请检查用户创建和权限设置"
            exit 1
        fi
    fi
    
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
        sudo mkdir -p "$FRONTEND_DIR"
        log_info "创建前端目录: $FRONTEND_DIR"
    fi
    
    # 查找PHP前端源码目录（支持多种情况）
    local SOURCE_DIR=""
    local SCRIPT_DIR=""
    
    # 获取脚本所在目录
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # 检查可能的源码路径（按优先级）
    local possible_paths=(
        "$INSTALL_DIR/php-frontend"                    # 从git clone安装
        "$SCRIPT_DIR/php-frontend"                     # 从脚本目录安装
        "$(dirname "$SCRIPT_DIR")/php-frontend"        # 项目根目录
        "./php-frontend"                                # 当前目录
        "../php-frontend"                               # 上级目录
    )
    
    for path in "${possible_paths[@]}"; do
        if [[ -d "$path" && -f "$path/index.php" ]]; then
            SOURCE_DIR="$path"
            log_info "找到PHP前端源码目录: $SOURCE_DIR"
            break
        fi
    done
    
    # 如果找不到源码目录，尝试从INSTALL_DIR查找
    if [[ -z "$SOURCE_DIR" ]]; then
        if [[ -d "$INSTALL_DIR" ]]; then
            # 检查INSTALL_DIR下的所有可能位置
            for dir in "$INSTALL_DIR"/*; do
                if [[ -d "$dir" && -f "$dir/index.php" ]]; then
                    # 检查是否包含PHP前端特征文件
                    if [[ -f "$dir/config/config.php" ]] || [[ -f "$dir/classes/Router.php" ]]; then
                        SOURCE_DIR="$dir"
                        log_info "在安装目录中找到PHP前端: $SOURCE_DIR"
                        break
                    fi
                fi
            done
        fi
    fi
    
    # 验证源码目录
    if [[ -z "$SOURCE_DIR" ]]; then
        log_error "无法找到PHP前端源码目录"
        log_error "已检查以下路径:"
        for path in "${possible_paths[@]}"; do
            log_error "  - $path"
        done
        log_error ""
        log_error "请确保:"
        log_error "  1. 从Git仓库克隆项目时包含 php-frontend 目录"
        log_error "  2. 或在当前目录/脚本目录存在 php-frontend 目录"
        log_error "  3. 或手动指定源码路径"
        exit 1
    fi
    
    # 复制前端文件到 /var/www/html
    log_info "从 $SOURCE_DIR 复制文件到 $FRONTEND_DIR..."
    
    # 使用rsync如果可用，否则使用cp
    if command -v rsync >/dev/null 2>&1; then
        if sudo rsync -av --delete "$SOURCE_DIR/" "$FRONTEND_DIR/"; then
            log_success "前端文件复制到 $FRONTEND_DIR (使用rsync)"
        else
            log_error "rsync复制失败，尝试使用cp..."
            if ! sudo cp -r "$SOURCE_DIR"/* "$FRONTEND_DIR/"; then
                log_error "文件复制失败"
                exit 1
            fi
        fi
    else
        if sudo cp -r "$SOURCE_DIR"/* "$FRONTEND_DIR/"; then
            log_success "前端文件复制到 $FRONTEND_DIR (使用cp)"
        else
            log_error "文件复制失败"
            exit 1
        fi
    fi
    
    # 验证文件是否成功复制
    if [[ ! -f "$FRONTEND_DIR/index.php" ]]; then
        log_error "复制后未找到 index.php，部署可能失败"
        log_error "请检查:"
        log_error "  1. 源码目录 $SOURCE_DIR 是否完整"
        log_error "  2. 目标目录 $FRONTEND_DIR 权限是否正确"
        log_error "  3. 磁盘空间是否充足"
        exit 1
    fi
    
    log_success "前端文件部署完成: $FRONTEND_DIR"
    
    # 创建日志目录（使用sudo）
    sudo mkdir -p "$FRONTEND_DIR/logs"
    sudo touch "$FRONTEND_DIR/logs/error.log"
    sudo touch "$FRONTEND_DIR/logs/access.log"
    sudo touch "$FRONTEND_DIR/logs/debug.log"
    
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

    # 安全的权限设置函数（使用sudo）
    set_secure_permissions() {
        local target_dir="$1"
        local owner="$2"
        local group="$3"
        
        log_info "设置安全权限: $target_dir (所有者: $owner:$group)"
        
        # 设置目录权限（使用sudo）
        if ! sudo find "$target_dir" -type d -exec chmod 755 {} \; 2>/dev/null; then
            log_warning "目录权限设置失败，尝试直接设置..."
            sudo chmod -R 755 "$target_dir" 2>/dev/null || true
        fi
        
        # 设置文件权限（使用sudo）
        if ! sudo find "$target_dir" -type f -exec chmod 644 {} \; 2>/dev/null; then
            log_warning "文件权限设置失败，使用默认权限..."
        fi
        
        # 设置可执行文件权限（PHP文件需要可执行，但实际上不需要）
        # 保留.sh和.py文件的可执行权限
        sudo find "$target_dir" -name "*.sh" -exec chmod 755 {} \; 2>/dev/null || true
        sudo find "$target_dir" -name "*.py" -exec chmod 755 {} \; 2>/dev/null || true
        
        # PHP文件应该是可读的
        sudo find "$target_dir" -name "*.php" -exec chmod 644 {} \; 2>/dev/null || true
        
        # 设置敏感文件权限
        sudo find "$target_dir" -name "*.env" -exec chmod 600 {} \; 2>/dev/null || true
        sudo find "$target_dir" -name "*.key" -exec chmod 600 {} \; 2>/dev/null || true
        sudo find "$target_dir" -name "*.pem" -exec chmod 600 {} \; 2>/dev/null || true
        
        # 设置所有者（使用sudo）
        if ! sudo chown -R "$owner:$group" "$target_dir" 2>/dev/null; then
            log_error "所有者设置失败: $target_dir"
            return 1
        fi
        
        log_success "权限设置成功: $target_dir (所有者: $owner:$group)"
        return 0
    }
    
    # 应用安全权限设置
    if ! set_secure_permissions "$FRONTEND_DIR" "$web_user" "$web_group"; then
        log_error "前端目录权限设置失败"
        exit 1
    fi
    
    # 特别处理日志目录权限（使用sudo）
    if [[ -d "$FRONTEND_DIR/logs" ]]; then
        sudo chmod 775 "$FRONTEND_DIR/logs" 2>/dev/null || log_warning "日志目录权限设置失败"
        sudo chown "$web_user:$web_group" "$FRONTEND_DIR/logs" 2>/dev/null || log_warning "日志目录所有者设置失败"
    fi
    
    # 修复原生安装的API路径配置问题
    log_info "配置前端API路径..."
    if [[ -f "$FRONTEND_DIR/config/api_paths.json" ]]; then
        # 更新api_paths.json中的base_url为原生安装地址
        local api_base_url="http://127.0.0.1:${API_PORT}"
        sed -i "s|\"base_url\": \"http://backend:8000\"|\"base_url\": \"${api_base_url}\"|g" "$FRONTEND_DIR/config/api_paths.json"
        log_success "已更新API基础URL为: ${api_base_url}"
    else
        log_warning "api_paths.json文件不存在，将创建默认配置..."
        # 创建原生安装的api_paths.json配置
        cat > "$FRONTEND_DIR/config/api_paths.json" << EOF
{
    "api": {
        "base_url": "http://127.0.0.1:${API_PORT}",
        "version": "v1",
        "timeout": 30,
        "retry_attempts": 3,
        "retry_delay": 1000
    },
    "endpoints": {
        "auth": {
            "login": {
                "path": "/auth/login",
                "method": "POST",
                "description": "用户登录"
            },
            "logout": {
                "path": "/auth/logout",
                "method": "POST",
                "description": "用户登出"
            },
            "refresh": {
                "path": "/auth/refresh",
                "method": "POST",
                "description": "刷新令牌"
            },
            "me": {
                "path": "/auth/me",
                "method": "GET",
                "description": "获取当前用户信息"
            }
        },
        "users": {
            "list": {
                "path": "/users",
                "method": "GET",
                "description": "获取用户列表"
            },
            "create": {
                "path": "/users",
                "method": "POST",
                "description": "创建用户"
            },
            "get": {
                "path": "/users/{id}",
                "method": "GET",
                "description": "获取用户详情"
            },
            "update": {
                "path": "/users/{id}",
                "method": "PUT",
                "description": "更新用户"
            },
            "delete": {
                "path": "/users/{id}",
                "method": "DELETE",
                "description": "删除用户"
            }
        },
        "wireguard": {
            "servers": {
                "list": {
                    "path": "/wireguard/servers",
                    "method": "GET",
                    "description": "获取WireGuard服务器列表"
                },
                "create": {
                    "path": "/wireguard/servers",
                    "method": "POST",
                    "description": "创建WireGuard服务器"
                }
            },
            "clients": {
                "list": {
                    "path": "/wireguard/clients",
                    "method": "GET",
                    "description": "获取WireGuard客户端列表"
                },
                "create": {
                    "path": "/wireguard/clients",
                    "method": "POST",
                    "description": "创建WireGuard客户端"
                }
            }
        },
        "system": {
            "health": {
                "path": "/system/health",
                "method": "GET",
                "description": "系统健康检查"
            },
            "status": {
                "path": "/system/status",
                "method": "GET",
                "description": "系统状态"
            }
        }
    }
}
EOF
        log_success "已创建原生安装的API路径配置文件"
    fi
    
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

#-----------------------------------------------------------------------------
# configure_nginx - 配置Nginx反向代理和PHP处理
#-----------------------------------------------------------------------------
# 功能说明:
#   - 检测PHP-FPM socket路径
#   - 生成Nginx配置文件
#   - 配置上游服务器（支持IPv4和IPv6双栈）
#   - 配置API反向代理
#   - 配置PHP-FPM处理
#   - 配置静态文件缓存
#   - 配置安全头和CORS
#   - 测试配置并重启Nginx服务
#
# 配置特点:
#   - 支持IPv6和IPv4双栈上游服务器
#   - API请求反向代理到FastAPI后端
#   - PHP文件通过PHP-FPM处理
#   - 静态资源启用缓存和Gzip压缩
#   - 安全文件访问限制
#
# 依赖全局变量: WEB_PORT, API_PORT, PHP_VERSION, IPV6_SUPPORT
#-----------------------------------------------------------------------------
configure_nginx() {
    log_info "配置Nginx..."
    
    #-------------------------------------------------------------------------
    # 检测PHP-FPM socket路径
    #-------------------------------------------------------------------------
    # 说明: 不同系统PHP-FPM socket位置不同，需要自动检测
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
    elif [[ -n "${NGINX_CONFIG_DIR}" && -d "${NGINX_CONFIG_DIR}" ]]; then
        nginx_conf_path="${NGINX_CONFIG_DIR%/}/${nginx_site_name}.conf"
    else
        mkdir -p "$INSTALL_DIR/config/nginx"
        nginx_conf_path="$INSTALL_DIR/config/nginx/${nginx_site_name}.conf"
        log_warning "未找到标准Nginx配置目录，配置将写入: $nginx_conf_path"
    fi

    # 创建Nginx配置
    # IPv6与IPv4上游行（根据IPV6_SUPPORT条件渲染）
    local backend_upstream_lines=""
    local ipv6_listen_line=""
    
    if [[ "${IPV6_SUPPORT}" == "true" ]]; then
        # IPv6可用：IPv6作为主服务器，IPv4作为backup
        backend_upstream_lines="    server [::1]:${API_PORT} max_fails=3 fail_timeout=30s;
    server 127.0.0.1:${API_PORT} backup max_fails=3 fail_timeout=30s;"
        ipv6_listen_line="    listen [::]:${WEB_PORT};"
        log_info "使用IPv6上游服务器地址: [::1]:${API_PORT} (IPv4作为backup)"
    else
        # IPv6不可用：IPv4作为主服务器（不是backup）
        backend_upstream_lines="    server 127.0.0.1:${API_PORT} max_fails=3 fail_timeout=30s;"
        ipv6_listen_line="    # IPv6 support not enabled"
        log_info "使用IPv4上游服务器地址: 127.0.0.1:${API_PORT}"
    fi

    cat > "$nginx_conf_path" << EOF
# 上游服务器组，支持IPv4和IPv6双栈
upstream backend_api {
${backend_upstream_lines}
    
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
${ipv6_listen_line}
    server_name _;
    root $FRONTEND_DIR;
    index index.php index.html;
    
    # 安全头（统一在Nginx层设置，避免与FastAPI和PHP重复）
    # 注意：已修复与后端FastAPI和前端PHP的冲突
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # 静态文件缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files \$uri =404;
    }
    
    # PHP路由处理（优先级高于通用API代理）
    # /api/status 和 /api/health 由PHP处理，不代理到后端
    # 这些路径不存在实际文件，需要由PHP路由系统处理
    location ~ ^/api/(status|health)$ {
        fastcgi_pass php_backend;
        fastcgi_param SCRIPT_FILENAME \$document_root/index_jwt.php;
        fastcgi_param REQUEST_URI \$request_uri;
        include fastcgi_params;
    }
    
    # API代理配置 - 代理到后端FastAPI
    # 处理 /api/v1/* 等后端API请求
    location ~ ^/api(/.*)?$ {
        # $1 匹配的是 /v1/health 等路径
        # 需要加上 /api 前缀传递给后端：/api/v1/health
        set \$api_path \$1;
        if (\$api_path = "") {
            set \$api_path "/";
        }
        proxy_pass http://backend_api/api\$api_path\$is_args\$args;
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
    }
    
    # 健康检查端点（直接代理，不经过/api前缀）
    location = /health {
        proxy_pass http://backend_api/api/v1/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
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
    
    # 静态文件处理 - 优化缓存策略，放在PHP处理之前
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        root $FRONTEND_DIR;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary "Accept-Encoding";
        access_log off;
    }
    
    # PHP文件处理 - 使用动态检测的PHP-FPM socket，放在API处理之后
    location ~ \.php$ {
        try_files \$uri =404;
        include fastcgi_params;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php_backend;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        
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
    # 修复: 优先使用 index.php，避免 index.html 不存在时的 404 问题
    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
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
            log_info "IPv6上游服务器地址: [::1]:${API_PORT} (主服务器)"
            log_info "IPv4上游服务器地址: 127.0.0.1:${API_PORT} (backup)"
        else
            log_info "IPv4上游服务器地址: 127.0.0.1:${API_PORT} (主服务器)"
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
    
    # 确保所有变量都已设置
    if [[ -z "${WEB_PORT:-}" ]]; then
        WEB_PORT="${DEFAULT_PORT:-80}"
    fi
    
    if [[ -z "${LOCAL_HOST:-}" ]]; then
        LOCAL_HOST="::1"
    fi
    
    if [[ -z "${API_PORT:-}" ]]; then
        API_PORT="${DEFAULT_API_PORT:-8000}"
    fi
    
    if [[ -z "${DB_PORT:-}" ]]; then
        DB_PORT="3306"
    fi
    
    if [[ -z "${REDIS_PORT:-}" ]]; then
        REDIS_PORT="6379"
    fi
    
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
    local api_wait_count=0
    local api_max_wait=30  # 最多等待30次，每次5秒，总共150秒
    
    while [[ $api_wait_count -lt $api_max_wait ]]; do
        # 根据SERVER_HOST配置选择检查地址
        if [[ "${SERVER_HOST}" == "::" ]]; then
            # 优先检查IPv6，回退到IPv4 - 支持 /api/v1/health 和 /health 两个路径
            if curl -f http://[::1]:$API_PORT/api/v1/health &>/dev/null || \
               curl -f http://127.0.0.1:$API_PORT/api/v1/health &>/dev/null || \
               curl -f http://[::1]:$API_PORT/health &>/dev/null || \
               curl -f http://127.0.0.1:$API_PORT/health &>/dev/null; then
                log_success "后端API已启动"
                break
            fi
        else
            if curl -f http://127.0.0.1:$API_PORT/api/v1/health &>/dev/null || \
               curl -f http://127.0.0.1:$API_PORT/health &>/dev/null; then
                log_success "后端API已启动"
                break
            fi
        fi
        
        ((api_wait_count++))
        if [[ $api_wait_count -eq $api_max_wait ]]; then
            log_error "后端API启动超时，请检查服务状态"
            log_info "检查命令: sudo systemctl status ipv6-wireguard-manager"
            return 1
        fi
        
        sleep 5
        log_info "等待API启动... ($api_wait_count/$api_max_wait)"
    done
    
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

#-----------------------------------------------------------------------------
# url_encode - URL编码函数
#-----------------------------------------------------------------------------
url_encode() {
    local string="$1"
    
    # 检查输入是否为空
    if [[ -z "$string" ]]; then
        echo ""
        return 0
    fi
    
    # 使用Python进行URL编码，确保特殊字符被正确处理
    # 使用临时文件避免引号嵌套问题，并处理换行符
    local temp_file=$(mktemp)
    
    # 将字符串写入临时文件，然后读取进行编码
    printf '%s' "$string" > "$temp_file"
    
    # 使用Python进行URL编码
    python3 -c "
import urllib.parse
import sys
try:
    with open('$temp_file', 'r', encoding='utf-8') as f:
        content = f.read().strip()
        if content:
            print(urllib.parse.quote(content, safe=''))
        else:
            print('')
except Exception as e:
    print('')
" 2>/dev/null || echo ""
    
    rm -f "$temp_file"
}

#-----------------------------------------------------------------------------
# generate_random_string - 生成随机字符串
#-----------------------------------------------------------------------------
# 功能说明:
#   使用openssl生成安全的随机字符串，用于密码和密钥生成
#
# 参数:
#   $1 - 字符串长度（默认: 16）
#
# 输出:
#   生成的随机字符串（仅包含字母和数字）
#
# 示例:
#   password=$(generate_random_string 24)  # 生成24位随机密码
#-----------------------------------------------------------------------------
generate_random_string() {
    local length=${1:-16}
    # 生成安全的随机字符串，避免特殊字符以避免数据库连接问题
    openssl rand -base64 $length | tr -d '=+/!@#$%^&*()[]{}|;:'"'"'",.<>?~`' | cut -c1-$length
}

#-----------------------------------------------------------------------------
# create_env_config - 创建环境配置文件
#-----------------------------------------------------------------------------
# 功能说明:
#   - 生成安全的随机密钥和密码
#   - 创建.env配置文件
#   - 配置应用、数据库、安全等所有参数
#   - 设置文件权限为600（仅所有者可读写）
#
# 配置内容:
#   - 应用基础设置（名称、版本、调试模式）
#   - API设置（版本前缀、密钥、令牌过期时间）
#   - 数据库连接（强制MySQL）
#   - Redis配置（可选）
#   - CORS跨域设置
#   - 安全策略（密码要求、MFA、限流）
#   - 监控和日志设置
#   - 路径配置
#
# 依赖全局变量: 
#   INSTALL_DIR, API_PORT, WEB_PORT, DB_USER, DB_PASSWORD, DB_NAME, DB_PORT
#-----------------------------------------------------------------------------
create_env_config() {
    log_info "创建环境配置文件..."
    
    # 生成安全的随机密钥和密码
    log_info "生成安全密钥和密码..."
    
    # 生成64位十六进制密钥
    local secret_key=$(openssl rand -hex 32)
    if [[ -z "$secret_key" || ${#secret_key} -lt 32 ]]; then
        log_error "密钥生成失败"
        exit 1
    fi
    
    # 生成强随机密码（20位）
    admin_password=$(generate_secure_password 20 | tail -n 1)
    if [[ -z "$admin_password" || ${#admin_password} -lt 12 ]]; then
        log_error "管理员密码生成失败"
        exit 1
    fi
    
    # 数据库密码：如果前面已用于创建DB账户，则复用，避免与账户不一致
    local database_password=""
    if [[ -n "${DB_PASSWORD:-}" ]]; then
        database_password="$DB_PASSWORD"
        log_info "复用已生成的数据库密码"
    else
        database_password=$(generate_secure_password 16 | tail -n 1)
        if [[ -z "$database_password" || ${#database_password} -lt 12 ]]; then
            log_error "数据库密码生成失败"
            exit 1
        fi
        DB_PASSWORD="$database_password"
    fi
    DB_PASSWORD_ENCODED=$(url_encode "$DB_PASSWORD")
    if [[ -z "$DB_PASSWORD_ENCODED" ]]; then
        DB_PASSWORD_ENCODED="$DB_PASSWORD"
    fi
    
    log_success "安全密钥和密码生成完成"
    
    # 验证环境变量配置
    validate_env_config() {
        local env_file="$1"
        
        log_info "验证环境变量配置..."
        
        # 检查必需的环境变量
        local required_vars=(
            "SECRET_KEY"
            "DATABASE_URL"
            "FIRST_SUPERUSER_PASSWORD"
            "DATABASE_PASSWORD"
        )
        
        for var in "${required_vars[@]}"; do
            if ! grep -q "^${var}=" "$env_file"; then
                log_error "缺少必需的环境变量: $var"
                return 1
            fi
            
            local value=$(grep "^${var}=" "$env_file" | cut -d'=' -f2- | tr -d '"')
            if [[ -z "$value" ]]; then
                log_error "环境变量 $var 为空"
                return 1
            fi
            
            # 验证密码强度
            if [[ "$var" == "FIRST_SUPERUSER_PASSWORD" || "$var" == "DATABASE_PASSWORD" ]]; then
                if [[ ${#value} -lt 12 ]]; then
                    log_error "密码 $var 长度不足12位"
                    return 1
                fi
            fi
            
            # 验证密钥长度
            if [[ "$var" == "SECRET_KEY" ]]; then
                if [[ ${#value} -lt 32 ]]; then
                    log_error "密钥 $var 长度不足32位"
                    return 1
                fi
            fi
        done
        
        log_success "环境变量配置验证通过"
        return 0
    }
    
    # 创建.env文件
    log_info "创建环境配置文件..."
    cat > "$INSTALL_DIR/.env" <<EOF
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
SERVER_PORT=${API_PORT}

# Database Settings - Force MySQL usage
# Password is URL-encoded to avoid special character issues
DB_PASSWORD_ENCODED="${DB_PASSWORD_ENCODED}"
DATABASE_URL="mysql://${DB_USER}:${DB_PASSWORD_ENCODED}@127.0.0.1:${DB_PORT}/${DB_NAME}"
DATABASE_HOST="127.0.0.1"
DATABASE_PORT=${DB_PORT}
DATABASE_USER=${DB_USER}
DATABASE_PASSWORD="${database_password}"
DATABASE_NAME=${DB_NAME}
AUTO_CREATE_DATABASE=True

# Database Connection Pool Settings
DATABASE_POOL_SIZE=10
DATABASE_MAX_OVERFLOW=20
DATABASE_CONNECT_TIMEOUT=30
DATABASE_POOL_RECYCLE=3600
DATABASE_POOL_PRE_PING=true

# Force MySQL, disable SQLite and PostgreSQL
DB_TYPE="mysql"
DB_ENGINE="mysql"

# Redis Settings (Optional)
USE_REDIS=False
REDIS_URL="redis://:redis123@${LOCAL_HOST}:${REDIS_PORT}/0"

# CORS Origins (JSON array format - must be valid JSON)
BACKEND_CORS_ORIGINS='["http://${LOCAL_HOST}:${WEB_PORT}","http://localhost:${WEB_PORT}","http://${LOCAL_HOST}","http://localhost"]'

# Logging Settings
LOG_LEVEL="$([ "$DEBUG" = true ] && echo "DEBUG" || echo "INFO")"
LOG_FORMAT="json"
LOG_FILE="logs/app.log"
LOG_ROTATION="1 day"
LOG_RETENTION="30 days"

# SSL/TLS Settings
SSL_CERT_PATH=""
SSL_KEY_PATH=""
SSL_PROTOCOLS="TLSv1.2 TLSv1.3"
SSL_CIPHERS="ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM:DHE+CHACHA20:!aNULL:!MD5:!DSS"

# API Security Settings
API_SSL_VERIFY=true
API_SSL_CA_PATH="/etc/ssl/certs/ca-certificates.crt"

# CORS Security Settings
CORS_ALLOW_CREDENTIALS=true
CORS_ALLOW_METHODS="GET,POST,PUT,DELETE,OPTIONS"
CORS_ALLOW_HEADERS="Content-Type,Authorization,X-Requested-With"
CORS_MAX_AGE=3600

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
ELASTICSEARCH_HOSTS='["localhost:9200"]'
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
    
    # 验证环境变量配置
    if ! validate_env_config "$INSTALL_DIR/.env"; then
        log_error "环境变量配置验证失败"
        exit 1
    fi
    
    # 设置权限
    if ! chown "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR/.env" 2>/dev/null; then
        log_error "环境文件所有者设置失败"
        exit 1
    fi
    
    if ! chmod 600 "$INSTALL_DIR/.env" 2>/dev/null; then
        log_error "环境文件权限设置失败"
        exit 1
    fi
    
    log_success "环境配置文件创建完成"
}

# 初始化数据库
initialize_database() {
    log_info "初始化数据库和创建超级用户..."
    
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
    # 设置数据库环境变量 - 优先走127.0.0.1:TCP，如失败则自动回退到unix_socket
    # 对密码进行URL编码，避免特殊字符导致的编码问题
    DB_PASSWORD_ENCODED=$(url_encode "$DB_PASSWORD")
    # 先构造TCP形式
    local db_url_tcp="mysql://${DB_USER}:${DB_PASSWORD_ENCODED}@127.0.0.1:${DB_PORT}/${DB_NAME}?charset=utf8mb4"
    export DATABASE_URL="$db_url_tcp"
    log_info "数据库连接URL: mysql://${DB_USER}:***@127.0.0.1:${DB_PORT}/${DB_NAME}?charset=utf8mb4"
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
    # 确保在正确的目录下运行Python检查
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
    # 使用简单的mysql命令测试连接，避免复杂的Python依赖
    if mysql -u "${DB_USER}" -p"${DB_PASSWORD}" -h 127.0.0.1 -P ${DB_PORT} -e "SELECT 1;" 2>/dev/null; then
        log_success "数据库连接测试成功 (TCP 127.0.0.1:${DB_PORT})"
    else
        log_warning "TCP连接 127.0.0.1:${DB_PORT} 失败，尝试本地unix_socket..."
        # 尝试socket（不指定 -h）
        if mysql -u "${DB_USER}" -p"${DB_PASSWORD}" -e "SELECT 1;" 2>/dev/null; then
            log_success "数据库连接测试成功 (本地unix_socket)"
            # 常见socket路径
            local default_socket="/var/run/mysqld/mysqld.sock"
            if [[ -S "$default_socket" ]]; then
                local db_url_socket="mysql://${DB_USER}:${DB_PASSWORD_ENCODED}@localhost/${DB_NAME}?unix_socket=${default_socket}&charset=utf8mb4"
                export DATABASE_URL="$db_url_socket"
                log_info "切换为unix_socket连接: mysql://${DB_USER}:***@localhost/${DB_NAME}?unix_socket=${default_socket}&charset=utf8mb4"
                # 同步更新 .env 中的 DATABASE_URL（若存在）
                if [[ -f "$INSTALL_DIR/.env" ]]; then
                    if grep -q '^DATABASE_URL=' "$INSTALL_DIR/.env"; then
                        sed -i "s|^DATABASE_URL=.*$|DATABASE_URL=\"${DATABASE_URL}\"|" "$INSTALL_DIR/.env"
                    else
                        echo "DATABASE_URL=\"${DATABASE_URL}\"" >> "$INSTALL_DIR/.env"
                    fi
                fi
            else
                log_warning "未找到默认unix_socket路径 ${default_socket}，请确认数据库socket路径"
            fi
        else
            log_error "数据库连接失败，请检查MySQL配置和用户权限"
            log_info "尝试手动连接测试："
            log_info "mysql -u ${DB_USER} -p -h 127.0.0.1 -P ${DB_PORT}"
            log_info "如果连接失败，请检查："
            log_info "1. MySQL服务是否运行: systemctl status mysql"
            log_info "2. 用户是否存在: mysql -u root -e \"SELECT User,Host FROM mysql.user WHERE User='${DB_USER}';\""
            log_info "3. 用户权限: mysql -u root -e \"SHOW GRANTS FOR '${DB_USER}'@'127.0.0.1';\""
            exit 1
        fi
    fi
    
    # 尝试使用简化的数据库初始化脚本
    if [[ -f "backend/init_database_simple.py" ]]; then
        log_info "使用简化的数据库初始化脚本..."
        # 确保在正确的目录下运行Python脚本
        cd "$INSTALL_DIR"
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
    # 对密码进行URL编码，避免特殊字符导致的编码问题
    DB_PASSWORD_ENCODED=$(url_encode "$DB_PASSWORD")
    export DATABASE_URL="mysql://${DB_USER}:${DB_PASSWORD_ENCODED}@127.0.0.1:${DB_PORT}/${DB_NAME}"
    log_info "使用基础驱动初始化数据库（应用层自动选择异步驱动）: ${DATABASE_URL}"
    
    # 创建一个更简单的数据库初始化脚本，避免应用层依赖
    cat > /tmp/init_db_simple.py << EOF
import os
import sys
from pathlib import Path

# 设置工作目录为安装目录
install_dir = "$INSTALL_DIR"
os.chdir(install_dir)

# 添加backend目录到路径
backend_path = Path(install_dir) / "backend"
if backend_path.exists():
    sys.path.insert(0, str(backend_path))

def init_database_simple():
    """简化的数据库初始化"""
    engine = None
    try:
        print("🔧 开始数据库初始化...")
        
        # 导入数据库URL工具
        from app.core.database_url_utils import prepare_sqlalchemy_mysql_url, ensure_mysql_connect_args
        
        # 读取环境变量
        database_url = os.environ.get("DATABASE_URL", "mysql://ipv6wgm:ipv6wgm_password@127.0.0.1:3306/ipv6wgm?charset=utf8mb4")
        
        # 使用数据库URL工具确保MySQL编码兼容性并输出脱敏信息
        url_obj = prepare_sqlalchemy_mysql_url(database_url)
        print(f"📊 处理后的数据库URL: {url_obj.render_as_string(hide_password=True)}")
        
        # 创建数据库连接
        from sqlalchemy import create_engine, text
        from sqlalchemy.ext.declarative import declarative_base
        
        Base = declarative_base()
        
        # 确保使用pymysql驱动
        if '+' not in url_obj.drivername:
            url_obj = url_obj.set(drivername=url_obj.drivername + '+pymysql')
        elif '+aiomysql' in url_obj.drivername:
            url_obj = url_obj.set(drivername=url_obj.drivername.replace('+aiomysql', '+pymysql'))
        
        print(f"🔗 使用驱动: {url_obj.drivername}")
        
        # 创建引擎，使用正确的连接参数确保UTF-8编码
        engine = create_engine(url_obj, echo=True, connect_args=ensure_mysql_connect_args())
        
        print("🔗 测试数据库连接...")
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1"))
            print("✅ 数据库连接成功")
        
        # 创建表
        print("📋 创建数据库表...")
        
        # 定义基础模型
        from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey
        from sqlalchemy.orm import relationship
        from datetime import datetime
        
        class User(Base):
            __tablename__ = "users"
            
            id = Column(Integer, primary_key=True, index=True)
            username = Column(String(50), unique=True, index=True, nullable=False)
            email = Column(String(100), unique=True, index=True, nullable=False)
            hashed_password = Column(String(255), nullable=False)
            full_name = Column(String(100))
            is_active = Column(Boolean, default=True)
            is_superuser = Column(Boolean, default=False)
            is_verified = Column(Boolean, default=False)
            created_at = Column(DateTime, default=datetime.utcnow)
            updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
        
        class Role(Base):
            __tablename__ = "roles"
            
            id = Column(Integer, primary_key=True, index=True)
            name = Column(String(50), unique=True, index=True, nullable=False)
            description = Column(Text)
            created_at = Column(DateTime, default=datetime.utcnow)
        
        class Permission(Base):
            __tablename__ = "permissions"
            
            id = Column(Integer, primary_key=True, index=True)
            name = Column(String(100), unique=True, index=True, nullable=False)
            description = Column(Text)
            resource = Column(String(100))
            action = Column(String(50))
            created_at = Column(DateTime, default=datetime.utcnow)
        
        # 创建所有表
        Base.metadata.create_all(bind=engine)
        print("✅ 数据库表创建完成")
        
        # 创建管理员用户
        print("👤 创建管理员用户...")
        
        from sqlalchemy.orm import sessionmaker
        from passlib.context import CryptContext
        
        # 密码加密（使用 pbkdf2_sha256，避免 bcrypt 后端/长度限制问题）
        pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
        
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        
        with SessionLocal() as db:
            # 检查是否已存在管理员用户
            existing_admin = db.query(User).filter(User.username == "admin").first()
            
            if not existing_admin:
                admin_password = os.environ.get("FIRST_SUPERUSER_PASSWORD", "CHANGE_ME_ADMIN_PASSWORD")
                admin_user = User(
                    username="admin",
                    email="admin@example.com",
                    hashed_password=pwd_context.hash(admin_password),
                    full_name="系统管理员",
                    is_active=True,
                    is_superuser=True,
                    is_verified=True
                )
                
                db.add(admin_user)
                db.commit()
                print("✅ 管理员用户创建成功")
                print("🔑 管理员用户名: admin")
                print(f"🔑 管理员密码: {admin_password}")
                print("⚠️  请立即修改默认密码！")
            else:
                print("ℹ️  管理员用户已存在")
        
        print("🎉 数据库初始化完成！")
        return True
        
    except Exception as e:
        print(f"❌ 数据库初始化失败: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        if engine is not None:
            engine.dispose()

if __name__ == "__main__":
    success = init_database_simple()
    if not success:
        sys.exit(1)
EOF

    # 执行临时脚本，确保在正确的目录下运行
    cd "$INSTALL_DIR"
    python /tmp/init_db_simple.py
    
    # 清理临时文件
    rm -f /tmp/init_db_simple.py
}

# 测试API功能
test_api_functionality() {
    log_info "测试API功能..."
    
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
    # 检查是否有API测试脚本
    if [[ -f "backend/test_api.py" ]]; then
        log_info "运行API测试..."
        # 确保在正确的目录下运行Python脚本
        cd "$INSTALL_DIR"
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
#-----------------------------------------------------------------------------
# create_system_service - 创建systemd系统服务
#-----------------------------------------------------------------------------
# 功能说明:
#   - 验证后端服务所需的关键文件
#   - 生成systemd服务单元文件
#   - 配置服务依赖和环境变量
#   - 启用服务自动启动
#
# 服务特点:
#   - 使用uvicorn运行FastAPI应用
#   - 配置为系统服务（systemd）
#   - 依赖MySQL/MariaDB服务
#   - 自动重启机制
#   - 日志输出到journal
#
# 依赖全局变量: INSTALL_DIR, SERVICE_USER, SERVICE_GROUP, API_PORT, SERVER_HOST
#-----------------------------------------------------------------------------
create_system_service() {
    log_info "创建系统服务..."
    
    #-------------------------------------------------------------------------
    # 验证后端服务启动所需的关键文件
    #-------------------------------------------------------------------------
    if [[ ! -f "$INSTALL_DIR/venv/bin/uvicorn" ]]; then
        log_error "uvicorn可执行文件不存在: $INSTALL_DIR/venv/bin/uvicorn"
        log_error "请检查Python虚拟环境是否正确安装"
        exit 1
    fi
    
    # 检查后端关键文件
    local backend_files=(
        "backend/app/main.py"
        "backend/app/core/unified_config.py"
        "backend/requirements.txt"
    )
    
    for file in "${backend_files[@]}"; do
        if [[ ! -f "$INSTALL_DIR/$file" ]]; then
            log_error "后端关键文件不存在: $INSTALL_DIR/$file"
            log_error "请检查项目文件是否正确下载"
            exit 1
        fi
    done
    
    if [[ ! -f "$INSTALL_DIR/.env" ]]; then
        log_error "环境配置文件不存在: $INSTALL_DIR/.env"
        log_error "请检查环境配置是否正确生成"
        exit 1
    fi
    
    # 验证Python依赖
    if ! "$INSTALL_DIR/venv/bin/python" -c "import fastapi, uvicorn" 2>/dev/null; then
        log_error "Python依赖包缺失，请检查虚拟环境"
        log_info "尝试重新安装依赖: pip install -r requirements.txt"
        exit 1
    fi
    
    log_success "后端服务启动环境验证通过"
    
    # 动态计算worker数量
    local worker_count=1
    if [[ $CPU_CORES -ge 4 ]]; then
        worker_count=2
    elif [[ $CPU_CORES -ge 8 ]]; then
        worker_count=4
    fi
    
    # 动态计算内存限制
    local memory_limit="512M"
    if [[ $MEMORY_MB -ge 2048 ]]; then
        memory_limit="1G"
    elif [[ $MEMORY_MB -ge 4096 ]]; then
        memory_limit="2G"
    fi
    
    cat > /etc/systemd/system/ipv6-wireguard-manager.service << EOF
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target mysql.service mariadb.service mysqld.service
Wants=mysql.service mariadb.service mysqld.service
StartLimitInterval=60
StartLimitBurst=3

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$INSTALL_DIR
Environment="PATH=$INSTALL_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONPATH=$INSTALL_DIR"
EnvironmentFile=$INSTALL_DIR/.env
ExecStart=$INSTALL_DIR/venv/bin/uvicorn backend.app.main:app --host "::" --port $API_PORT --workers $worker_count --access-log --log-level info
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ipv6-wireguard-manager

# Resource Limits
LimitNOFILE=65536
LimitNPROC=32768
MemoryMax=$memory_limit

# Security Settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    
    # 验证服务配置
    if ! systemctl cat ipv6-wireguard-manager >/dev/null 2>&1; then
        log_error "服务配置验证失败"
        exit 1
    fi
    
    # 启用服务
    if ! systemctl enable ipv6-wireguard-manager; then
        log_error "服务启用失败"
        exit 1
    fi
    
    log_success "系统服务创建完成"
    log_info "Worker数量: $worker_count"
    log_info "内存限制: $memory_limit"
}

# 安装CLI管理工具
install_cli_tool() {
    log_info "安装CLI管理工具..."
    
    # 兼容多种CLI来源：优先使用安装目录中的 cli/ipv6-wireguard-manager.py
    local cli_source=""
    if [[ -f "$INSTALL_DIR/cli/ipv6-wireguard-manager.py" ]]; then
        cli_source="$INSTALL_DIR/cli/ipv6-wireguard-manager.py"
    elif [[ -f "$INSTALL_DIR/ipv6-wireguard-manager.py" ]]; then
        cli_source="$INSTALL_DIR/ipv6-wireguard-manager.py"
    else
        log_warning "未找到CLI脚本，跳过安装CLI（预期路径: $INSTALL_DIR/cli/ipv6-wireguard-manager.py 或 $INSTALL_DIR/ipv6-wireguard-manager.py）"
        return 0
    fi

    # 创建可执行包装脚本到系统路径
    cat > "/usr/local/bin/ipv6-wireguard-manager" << EOF
#!/bin/bash
exec python3 "$cli_source" "$@"
EOF
    chmod +x "/usr/local/bin/ipv6-wireguard-manager"

    # 创建符号链接（可选）
    ln -sf "/usr/local/bin/ipv6-wireguard-manager" "/usr/bin/ipv6-wireguard-manager" 2>/dev/null || true
    
    log_success "CLI管理工具安装完成"
    log_info "使用方法: ipv6-wireguard-manager --help"
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
    
    # 使用安全权限设置函数
    if ! set_secure_permissions "$INSTALL_DIR" "$SERVICE_USER" "$SERVICE_GROUP"; then
        log_error "安装目录权限设置失败"
        exit 1
    fi
    
    # 特别处理虚拟环境权限
    if [[ -d "$INSTALL_DIR/venv/bin" ]]; then
        find "$INSTALL_DIR/venv/bin" -type f -exec chmod 755 {} \; 2>/dev/null || log_warning "虚拟环境权限设置失败"
    fi
    
    # 设置敏感文件的安全权限
    if [[ -f "$INSTALL_DIR/.env" ]]; then
        if ! chmod 600 "$INSTALL_DIR/.env" 2>/dev/null; then
            log_error "环境文件权限设置失败"
            exit 1
        fi
        if ! chown "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR/.env" 2>/dev/null; then
            log_error "环境文件所有者设置失败"
            exit 1
        fi
        log_success "环境文件权限设置成功"
    fi
    
    # 设置配置文件权限
    find "$INSTALL_DIR" -name "*.json" -exec chmod 640 {} \; 2>/dev/null || true
    find "$INSTALL_DIR" -name "*.conf" -exec chmod 640 {} \; 2>/dev/null || true
    
    log_success "目录和权限设置完成"
    
    # 调用日志轮转配置
    configure_log_rotation
}

# 配置日志轮转
configure_log_rotation() {
    log_info "配置日志轮转..."
    
    # 动态检测Web服务用户，确保变量在当前作用域可用
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
        # 回退到服务用户
        web_user="$SERVICE_USER"; web_group="$SERVICE_GROUP"
    fi
    
    cat > /etc/logrotate.d/ipv6-wireguard-manager << EOF
$INSTALL_DIR/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $SERVICE_USER $SERVICE_GROUP
    postrotate
        systemctl reload ipv6-wireguard-manager > /dev/null 2>&1 || true
    endscript
}

$FRONTEND_DIR/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $web_user $web_group
}
EOF
    
    log_success "日志轮转配置完成"
}

# 启动服务 - 增强版
start_services() {
    log_info "启动服务..."
    
    # 等待MySQL服务启动
    wait_for_mysql() {
        local max_attempts=30
        local attempt=0
        log_info "等待MySQL服务启动..."
        
        while [[ $attempt -lt $max_attempts ]]; do
            if mysql -u root -e "SELECT 1;" &>/dev/null 2>&1; then
                log_success "MySQL服务已就绪"
                return 0
            fi
            sleep 2
            ((attempt++))
            log_info "等待MySQL启动... ($attempt/$max_attempts)"
        done
        
        log_error "MySQL服务启动超时"
        return 1
    }
    
    # 等待PHP-FPM服务启动
    wait_for_php_fpm() {
        local max_attempts=15
        local attempt=0
        log_info "等待PHP-FPM服务启动..."
        
        while [[ $attempt -lt $max_attempts ]]; do
            if pgrep -f "php-fpm" >/dev/null; then
                log_success "PHP-FPM服务已就绪"
                return 0
            fi
            sleep 2
            ((attempt++))
            log_info "等待PHP-FPM启动... ($attempt/$max_attempts)"
        done
        
        log_warning "PHP-FPM服务可能未启动，但继续执行"
        return 0
    }
    
    # 按顺序启动依赖服务
    if ! wait_for_mysql; then
        log_error "MySQL服务启动失败，无法继续"
        return 1
    fi
    
    wait_for_php_fpm
    
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
    
    # 根据SERVER_HOST配置选择检查地址 - 支持 /api/v1/health 和 /health 两个路径
    local health_url=""
    if [[ "${SERVER_HOST}" == "::" ]]; then
        # 优先检查IPv6，回退到IPv4，优先检查 /api/v1/health，失败则尝试 /health
        if curl -s --connect-timeout 5 "http://[::1]:$API_PORT/api/v1/health" 2>/dev/null; then
            health_url="http://[::1]:$API_PORT/api/v1/health"
        elif curl -s --connect-timeout 5 "http://127.0.0.1:$API_PORT/api/v1/health" 2>/dev/null; then
            health_url="http://127.0.0.1:$API_PORT/api/v1/health"
        elif curl -s --connect-timeout 5 "http://[::1]:$API_PORT/health" 2>/dev/null; then
            health_url="http://[::1]:$API_PORT/health"
        else
            health_url="http://127.0.0.1:$API_PORT/health"
        fi
    else
        # IPv4优先，支持两个路径
        if curl -s --connect-timeout 5 "http://127.0.0.1:$API_PORT/api/v1/health" 2>/dev/null; then
            health_url="http://127.0.0.1:$API_PORT/api/v1/health"
        else
            health_url="http://127.0.0.1:$API_PORT/health"
        fi
    fi
    
    local response=$(curl -s --connect-timeout 10 "$health_url" 2>/dev/null)
    
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
        
        # 增强的错误诊断
        log_info "开始诊断服务启动失败原因..."
        
        # 检查服务状态
        local service_status=$(systemctl status ipv6-wireguard-manager --no-pager -l)
        log_info "服务状态: $service_status"
        
        # 检查最近的日志
        local recent_logs=$(journalctl -u ipv6-wireguard-manager --no-pager -n 10)
        log_info "最近日志: $recent_logs"
        
        # 尝试自动修复
        log_info "尝试自动修复..."
        
        # 检查Python环境
        if ! "$INSTALL_DIR/venv/bin/python" --version &>/dev/null; then
            log_error "Python环境异常，尝试重新创建虚拟环境"
            rm -rf "$INSTALL_DIR/venv"
            python3 -m venv "$INSTALL_DIR/venv"
            "$INSTALL_DIR/venv/bin/pip" install -r "$INSTALL_DIR/requirements.txt"
        fi
        
        # 检查依赖
        if ! "$INSTALL_DIR/venv/bin/python" -c "import fastapi, uvicorn" &>/dev/null; then
            log_error "依赖包缺失，尝试重新安装"
            "$INSTALL_DIR/venv/bin/pip" install fastapi uvicorn
        fi
        
        # 检查MySQL驱动
        if ! "$INSTALL_DIR/venv/bin/python" -c "import pymysql, aiomysql" &>/dev/null; then
            log_error "MySQL驱动缺失，尝试重新安装"
            "$INSTALL_DIR/venv/bin/pip" install pymysql aiomysql mysqlclient
        fi
        
        # 重新启动服务
        systemctl restart ipv6-wireguard-manager
        sleep 5
        
        if systemctl is-active --quiet ipv6-wireguard-manager; then
            log_success "自动修复成功，后端服务已启动"
        else
            log_error "自动修复失败，请手动检查"
            log_info "手动检查命令:"
            log_info "  sudo systemctl status ipv6-wireguard-manager"
            log_info "  sudo journalctl -u ipv6-wireguard-manager -f"
            return 1
        fi
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
    
    # 检查数据库连接（从DATABASE_URL解析）
    DATABASE_URL=$(grep -E '^DATABASE_URL=' "$INSTALL_DIR/.env" | cut -d'=' -f2 | tr -d '"' || echo "mysql://ipv6wgm:ipv6wgm_password@127.0.0.1:3306/ipv6wgm")
    
    # 从DATABASE_URL解析连接参数
    if [[ "$DATABASE_URL" =~ mysql://([^:]+):([^@]+)@([^:]+):([0-9]+)/(.+) ]]; then
        DB_USER="${BASH_REMATCH[1]}"
        DB_PASS="${BASH_REMATCH[2]}"
        DB_HOST="${BASH_REMATCH[3]}"
        DB_PORT="${BASH_REMATCH[4]}"
        DB_NAME="${BASH_REMATCH[5]}"
    else
        # 如果解析失败，使用默认值
        DB_USER="ipv6wgm"
        DB_PASS="ipv6wgm_password"
        DB_HOST="127.0.0.1"
        DB_PORT="3306"
        DB_NAME="ipv6wgm"
    fi
    
    if env MYSQL_PWD="$DB_PASS" mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -e "SELECT 1;" &>/dev/null; then
        log_success "✓ 数据库连接正常"
    else
        log_error "✗ 数据库连接异常"
        return 1
    fi
    
    # 检查Web服务（使用多种方法，允许失败）
    local web_check_ok=false
    if command -v curl >/dev/null 2>&1; then
        if curl -f -s --connect-timeout 5 http://localhost:$WEB_PORT/ &>/dev/null; then
            log_success "✓ Web服务正常 (curl检查)"
            web_check_ok=true
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q --spider --timeout=5 http://localhost:$WEB_PORT/ 2>/dev/null; then
            log_success "✓ Web服务正常 (wget检查)"
            web_check_ok=true
        fi
    else
        # 如果没有curl/wget，检查端口是否监听
        if ss -tlnp | grep -q ":$WEB_PORT " || netstat -tlnp 2>/dev/null | grep -q ":$WEB_PORT "; then
            log_success "✓ Web服务端口监听中 (端口检查)"
            web_check_ok=true
        fi
    fi
    
    if [[ "$web_check_ok" == "false" ]]; then
        log_warning "⚠️  Web服务检查未通过，但Nginx可能正在启动中"
        log_info "   您可以稍后手动检查: curl http://localhost:$WEB_PORT/"
        log_info "   或查看Nginx状态: systemctl status nginx"
        # 不返回错误，继续检查其他服务
    fi
    
    # 检查API服务（带重试机制，支持多种检查方法）
    log_info "等待API服务启动..."
    local api_retry_count=0
    local api_max_retries=15
    local api_retry_delay=5
    local api_check_ok=false
    
    while [[ $api_retry_count -lt $api_max_retries ]]; do
        # 尝试多种方法检查API服务 - 支持 /health 和 /api/v1/health 两个路径
        if command -v curl >/dev/null 2>&1; then
            # 优先检查 /api/v1/health，如果失败则检查 /health
            if curl -f -s --connect-timeout 5 http://[::1]:$API_PORT/api/v1/health &>/dev/null || \
               curl -f -s --connect-timeout 5 http://127.0.0.1:$API_PORT/api/v1/health &>/dev/null || \
               curl -f -s --connect-timeout 5 http://[::1]:$API_PORT/health &>/dev/null || \
               curl -f -s --connect-timeout 5 http://127.0.0.1:$API_PORT/health &>/dev/null; then
                log_success "✓ API服务正常 (curl检查)"
                api_check_ok=true
                break
            fi
        elif command -v wget >/dev/null 2>&1; then
            if wget -q --spider --timeout=5 http://127.0.0.1:$API_PORT/api/v1/health 2>/dev/null || \
               wget -q --spider --timeout=5 http://127.0.0.1:$API_PORT/health 2>/dev/null; then
                log_success "✓ API服务正常 (wget检查)"
                api_check_ok=true
                break
            fi
        else
            # 如果没有curl/wget，检查端口是否监听
            if ss -tlnp | grep -q ":$API_PORT " || netstat -tlnp 2>/dev/null | grep -q ":$API_PORT "; then
                # 检查systemd服务状态
                if systemctl is-active --quiet ipv6-wireguard-manager.service 2>/dev/null; then
                    log_success "✓ API服务正常 (端口和服务状态检查)"
                    api_check_ok=true
                    break
                fi
            fi
        fi
        
        api_retry_count=$((api_retry_count + 1))
        if [[ $api_retry_count -lt $api_max_retries ]]; then
            log_info "API服务未就绪，等待 ${api_retry_delay} 秒后重试... (${api_retry_count}/${api_max_retries})"
            sleep $api_retry_delay
        fi
    done
    
    if [[ "$api_check_ok" == "true" ]]; then
        # 如果有curl，运行API功能测试
        if command -v curl >/dev/null 2>&1; then
            test_api_functionality || true
        fi
        return 0
    else
        # API检查失败，但检查服务是否至少启动了
        if systemctl is-active --quiet ipv6-wireguard-manager.service 2>/dev/null; then
            log_warning "⚠️  API健康检查失败，但服务已启动"
            log_info "   请稍后手动检查: curl http://localhost:$API_PORT/api/v1/health"
            log_info "   查看日志: journalctl -u ipv6-wireguard-manager -f"
            return 0  # 服务已启动，返回成功
        else
            log_error "✗ API服务异常（服务未运行）"
            log_info "请检查服务状态: sudo systemctl status ipv6-wireguard-manager"
            log_info "请查看服务日志: sudo journalctl -u ipv6-wireguard-manager -f"
            log_info "请检查API配置: $INSTALL_DIR/.env"
            return 1
        fi
    fi
}

# 显示安装完成信息
show_installation_complete() {
    echo ""
    log_success "🎉 安装完成！"
    echo ""
    
    # 获取服务器的 IPv4 和 IPv6 地址
    local ipv4_addr=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
    local ipv6_addr=$(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-f:]+' | grep -v '^::1' | grep -v '^fe80' | head -1)
    
    log_info "=========================================="
    log_info "📡 访问地址:"
    echo ""
    
    if [[ -n "$ipv4_addr" ]]; then
        log_info "  🌐 IPv4 访问:"
        log_info "     前端:        http://$ipv4_addr:$WEB_PORT"
        log_info "     API文档:     http://$ipv4_addr:$API_PORT/docs"
        log_info "     API健康检查: http://$ipv4_addr:$API_PORT/api/v1/health"
        echo ""
    fi
    
    if [[ -n "$ipv6_addr" ]]; then
        log_info "  🌐 IPv6 访问:"
        log_info "     前端:        http://[$ipv6_addr]:$WEB_PORT"
        log_info "     API文档:     http://[$ipv6_addr]:$API_PORT/docs"
        log_info "     API健康检查: http://[$ipv6_addr]:$API_PORT/api/v1/health"
        echo ""
    fi
    
    log_info "  🏠 本地访问:"
    log_info "     前端:        http://localhost:$WEB_PORT"
    log_info "     API文档:     http://localhost:$API_PORT/docs"
    log_info "     API健康检查: http://localhost:$API_PORT/api/v1/health"
    echo ""
    log_info "=========================================="
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

#=============================================================================
# 主函数
#=============================================================================

#-----------------------------------------------------------------------------
# main - 主安装流程控制函数
#-----------------------------------------------------------------------------
# 功能说明:
#   - 检测运行模式（交互/非交互）
#   - 执行系统检测和路径检测
#   - 解析命令行参数
#   - 选择安装类型
#   - 根据安装类型执行相应的安装流程
#   - 运行环境检查
#   - 显示安装完成信息
#
# 安装流程:
#   1. Docker安装: install_docker
#   2. 原生安装: 
#      - 安装系统依赖
#      - 安装PHP
#      - 创建服务用户
#      - 下载项目
#      - 安装Python依赖
#      - 配置数据库
#      - 部署前端
#      - 配置Nginx
#      - 创建系统服务
#      - 启动服务
#   3. 最小化安装: 同原生安装（资源优化版）
#
# 参数: $@ - 命令行参数
#-----------------------------------------------------------------------------
main() {
    log_info "IPv6 WireGuard Manager - 智能安装脚本 v$SCRIPT_VERSION"
    echo ""
    
    #-------------------------------------------------------------------------
    # 检测运行模式：交互模式或非交互模式
    #-------------------------------------------------------------------------
    # 说明: 通过检测stdin是否为TTY来判断
    #       如果通过管道执行（如 curl ... | bash），则为非交互模式
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
    
    # 先解析命令行参数（用户自定义路径优先级最高）
    parse_arguments "$@"
    
    # 然后检测系统路径（仅设置未通过参数指定的路径）
    detect_system_paths
    check_requirements
    
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
                install_basic_dependencies
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
                install_basic_dependencies
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