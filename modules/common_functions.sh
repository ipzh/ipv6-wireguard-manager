#!/bin/bash

# 公共函数库
# 提供所有模块共用的基础函数

# =============================================================================
# 全局变量定义区域 - 使用IPV6WGM前缀防止命名冲突
# =============================================================================

# 核心目录变量
declare -g IPV6WGM_CONFIG_DIR="${CONFIG_DIR:-/etc/ipv6-wireguard-manager}"
declare -g IPV6WGM_LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"
declare -g IPV6WGM_LOG_FILE="${LOG_FILE:-$IPV6WGM_LOG_DIR/manager.log}"

# 脚本路径变量
declare -g IPV6WGM_SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)}" || exit
declare -g IPV6WGM_MODULES_DIR="${MODULES_DIR:-$IPV6WGM_SCRIPT_DIR/modules}"

# 兼容性变量（保持向后兼容）
CONFIG_DIR="$IPV6WGM_CONFIG_DIR"
LOG_DIR="$IPV6WGM_LOG_DIR"
LOG_FILE="$IPV6WGM_LOG_FILE"
SCRIPT_DIR="$IPV6WGM_SCRIPT_DIR"
MODULES_DIR="$IPV6WGM_MODULES_DIR"

# 系统变量
declare -g IPV6WGM_USER="${USER:-$(whoami)}"
declare -g IPV6WGM_HOME="${HOME:-/root}"
declare -g IPV6WGM_TEMP_DIR="${TMPDIR:-/tmp}"

# 版本信息
declare -g IPV6WGM_VERSION="1.0.0"
declare -g IPV6WGM_BUILD_DATE="$(date '+%Y-%m-%d')"

# 状态变量
declare -g IPV6WGM_DEBUG_MODE="${DEBUG:-false}"
declare -g IPV6WGM_VERBOSE_MODE="${VERBOSE:-false}"

# 目录初始化状态
declare -g IPV6WGM_DIRS_INITIALIZED=false
declare -g IPV6WGM_LOG_WARNING_SHOWN=false

# =============================================================================
# 变量初始化和管理函数
# =============================================================================

# 变量初始化检查函数
ensure_variables() {
    # 如果已经初始化过，直接返回
    if [[ "$IPV6WGM_DIRS_INITIALIZED" == "true" ]]; then
        return 0
    fi
    
    # 检查是否在WSL或Windows环境下
    if [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ -n "${WSLENV:-}" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || ([[ -f /proc/version ]] && grep -qi microsoft /proc/version); then
        # 在WSL/Windows环境下，使用备用目录
        # 仅在未设置时设置变量，避免覆盖已有设置
        IPV6WGM_CONFIG_DIR="${IPV6WGM_CONFIG_DIR:-/tmp/ipv6-wireguard-manager/config}"
        IPV6WGM_LOG_DIR="${IPV6WGM_LOG_DIR:-/tmp/ipv6-wireguard-manager}"
        IPV6WGM_LOG_FILE="${IPV6WGM_LOG_FILE:-$IPV6WGM_LOG_DIR/manager.log}"
        
        # 设置兼容性变量
        export CONFIG_DIR="$IPV6WGM_CONFIG_DIR"
        export LOG_DIR="$IPV6WGM_LOG_DIR"
        export LOG_FILE="$IPV6WGM_LOG_FILE"
        export SCRIPT_DIR="$IPV6WGM_SCRIPT_DIR"
        export MODULES_DIR="$IPV6WGM_MODULES_DIR"
        export SCRIPTS_DIR="$IPV6WGM_SCRIPTS_DIR"
        export EXAMPLES_DIR="$IPV6WGM_EXAMPLES_DIR"
        export DOCS_DIR="$IPV6WGM_DOCS_DIR"
        export CONFIG_FILE="$IPV6WGM_CONFIG_FILE"
    else
        # 在Linux环境下，使用标准目录
        IPV6WGM_CONFIG_DIR="${IPV6WGM_CONFIG_DIR:-/etc/ipv6-wireguard-manager}"
        IPV6WGM_LOG_DIR="${IPV6WGM_LOG_DIR:-/var/log/ipv6-wireguard-manager}"
        IPV6WGM_LOG_FILE="${IPV6WGM_LOG_FILE:-$IPV6WGM_LOG_DIR/manager.log}"
        
        # 设置兼容性变量
        export CONFIG_DIR="$IPV6WGM_CONFIG_DIR"
        export LOG_DIR="$IPV6WGM_LOG_DIR"
        export LOG_FILE="$IPV6WGM_LOG_FILE"
        export SCRIPT_DIR="$IPV6WGM_SCRIPT_DIR"
        export MODULES_DIR="$IPV6WGM_MODULES_DIR"
        export SCRIPTS_DIR="$IPV6WGM_SCRIPTS_DIR"
        export EXAMPLES_DIR="$IPV6WGM_EXAMPLES_DIR"
        export DOCS_DIR="$IPV6WGM_DOCS_DIR"
        export CONFIG_FILE="$IPV6WGM_CONFIG_FILE"
    fi
    
    # 确保必要目录存在
    mkdir -p "$IPV6WGM_CONFIG_DIR" "$IPV6WGM_LOG_DIR" 2>/dev/null || {
        # 如果无法创建标准目录，尝试使用临时目录
        if [[ "$IPV6WGM_CONFIG_DIR" != "/tmp"* ]]; then
            IPV6WGM_CONFIG_DIR="/tmp/ipv6-wireguard-manager/config"
            IPV6WGM_LOG_DIR="/tmp/ipv6-wireguard-manager"
            IPV6WGM_LOG_FILE="$IPV6WGM_LOG_DIR/manager.log"
            
            # 更新兼容性变量
            export CONFIG_DIR="$IPV6WGM_CONFIG_DIR"
            export LOG_DIR="$IPV6WGM_LOG_DIR"
            export LOG_FILE="$IPV6WGM_LOG_FILE"
            
            mkdir -p "$IPV6WGM_CONFIG_DIR" "$IPV6WGM_LOG_DIR" 2>/dev/null || true
        fi
    }
    
    # 检查并设置关键环境变量
    export PATH="$PATH:/usr/local/sbin:/usr/sbin:/sbin"
    
    # 验证关键变量
    if [[ -z "$IPV6WGM_SCRIPT_DIR" ]]; then
        echo "错误: IPV6WGM_SCRIPT_DIR 未定义" >&2
        return 1
    fi
    
    if [[ -z "$IPV6WGM_MODULES_DIR" ]]; then
        echo "错误: IPV6WGM_MODULES_DIR 未定义" >&2
        return 1
    fi
    
    # 初始化缓存相关变量
    if [[ -z "${IPV6WGM_TOTAL_CACHE_HITS:-}" ]]; then
        IPV6WGM_TOTAL_CACHE_HITS=0
    fi
    
    if [[ -z "${IPV6WGM_TOTAL_CACHE_MISSES:-}" ]]; then
        IPV6WGM_TOTAL_CACHE_MISSES=0
    fi
    
    if [[ -z "${IPV6WGM_TOTAL_CACHE_SIZE:-}" ]]; then
        IPV6WGM_TOTAL_CACHE_SIZE=0
    fi
    
    # 初始化兼容性变量
    TOTAL_CACHE_HITS="${IPV6WGM_TOTAL_CACHE_HITS}"
    TOTAL_CACHE_MISSES="${IPV6WGM_TOTAL_CACHE_MISSES}"
    TOTAL_CACHE_SIZE="${IPV6WGM_TOTAL_CACHE_SIZE}"
    
    IPV6WGM_DIRS_INITIALIZED=true
    return 0
}

# 获取变量值函数
get_variable() {
    local var_name="$1"
    local default_value="${2:-}"
    
    if [[ -n "${!var_name:-}" ]]; then
        echo "${!var_name}"
    else
        echo "$default_value"
    fi
}

# 设置变量值函数
set_variable() {
    local var_name="$1"
    local value="$2"
    local export_var="${3:-false}"
    
    if [[ "$export_var" == "true" ]]; then
        export "$var_name"="$value"
    else
        declare -g "$var_name"="$value"
    fi
}

# 颜色定义
declare -g IPV6WGM_COLOR_RED='\033[0;31m'
declare -g IPV6WGM_COLOR_GREEN='\033[0;32m'
declare -g IPV6WGM_COLOR_YELLOW='\033[1;33m'
declare -g IPV6WGM_COLOR_BLUE='\033[0;34m'
declare -g IPV6WGM_COLOR_CYAN='\033[0;36m'
declare -g IPV6WGM_COLOR_PURPLE='\033[0;35m'
declare -g IPV6WGM_COLOR_SECONDARY='\033[0;36m'  # 次要颜色（青色）
declare -g IPV6WGM_COLOR_NC='\033[0m' # No Color

# 兼容性变量
RED="$IPV6WGM_COLOR_RED"
GREEN="$IPV6WGM_COLOR_GREEN"
# YELLOW=  # unused"$IPV6WGM_COLOR_YELLOW"
BLUE="$IPV6WGM_COLOR_BLUE"
# CYAN=  # unused"$IPV6WGM_COLOR_CYAN"
# PURPLE=  # unused"$IPV6WGM_COLOR_PURPLE"
SECONDARY_COLOR="$IPV6WGM_COLOR_SECONDARY"
NC="$IPV6WGM_COLOR_NC"

# 颜色和格式化函数
print_header() {
    local title="$1"
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║$(printf "%*s" $((80 - ${#title})) "$title")║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
}

print_section() {
    local title="$1"
    echo -e "\n${YELLOW}=== $title ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# 用户交互函数
show_input() {
    local prompt="$1"
    local default="$2"
    local value
    
    if [[ -n "$default" ]]; then
        read -rp "$prompt [$default]: " value
        value="${value:-$default}"
    else
        read -rp "$prompt: " value
    fi
    
    echo "$value"
}

show_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# 进度条函数
show_progress() {
    local current=$1
    local total=$2
    local description="$3"
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${CYAN}[${NC}"
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "${CYAN}]${NC} %d%% %s" "$percentage" "$description"
    
    if [[ $current -eq $total ]]; then
        echo
    fi
}

# 确认函数
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    # 简化逻辑，确保默认值处理正确
    if [[ "$default" == "y" ]]; then
        read -rp "$prompt [Y/n]: " -n 1 -r
        echo
        # 空输入或Y/y返回0，其他返回1
        [[ -z "$REPLY" || $REPLY =~ ^[Yy]$ ]] && return 0 || return 1
    else
        read -rp "$prompt [y/N]: " -n 1 -r
        echo
        # 只有Y/y返回0，空输入或其他返回1
        [[ $REPLY =~ ^[Yy]$ ]] && return 0 || return 1
    fi
}

# 输入验证函数
validate_ipv4() {
    local ip="$1"
    
    # 检查基本格式
    if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 1
    fi
    
    # 检查每个部分的数值范围和前导零
    local IFS='.'
    local -a ip_parts=($ip)
    for part in "${ip_parts[@]}"; do
        # 检查是否为空
        if [[ -z "$part" ]]; then
            return 1
        fi
        
        # 检查前导零（除了单独的"0"）
        if [[ ${#part} -gt 1 && ${part:0:1} == "0" ]]; then
            return 1
        fi
        
        # 检查数值范围
        if [[ $part -gt 255 ]]; then
            return 1
        fi
    done
    
    return 0
}

validate_ipv6() {
    local ip="$1"
    
    # 检查是否为空
    if [[ -z "$ip" ]]; then
        return 1
    fi
    
    # 检查基本格式 - 必须包含冒号
    if [[ ! "$ip" =~ : ]]; then
        return 1
    fi
    
    # 检查长度 - IPv6最长39个字符
    if [[ ${#ip} -gt 39 ]]; then
        return 1
    fi
    
    # 检查双冒号数量 - 最多只能有一个
    if [[ $(echo "$ip" | grep -o "::" | wc -l) -gt 1 ]]; then
        return 1
    fi
    
    # 检查特殊地址
    if [[ "$ip" == "::1" ]] || [[ "$ip" == "::" ]]; then
        return 0
    fi
    
    # 使用ip命令验证IPv6地址
    if command -v ip &> /dev/null; then
        if ip -6 addr show dev lo | grep -q "inet6 $ip/"; then
            return 0
        fi
    fi
    
    # 使用ping6验证（如果可用）
    if command -v ping6 &> /dev/null; then
        if ping6 -c 1 -W 1 "$ip" &>/dev/null; then
            return 0
        fi
    fi
    
    # 正则表达式验证 - 更宽松的IPv6验证
    if [[ $ip =~ ^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$ ]] || \
       [[ $ip =~ ^([0-9a-fA-F]{1,4}:)*::([0-9a-fA-F]{1,4}:)*[0-9a-fA-F]{1,4}$ ]] || \
       [[ $ip =~ ^([0-9a-fA-F]{1,4}:)*::([0-9a-fA-F]{1,4}:)*$ ]] || \
       [[ $ip =~ ^::([0-9a-fA-F]{1,4}:)*[0-9a-fA-F]{1,4}$ ]] || \
       [[ $ip =~ ^[0-9a-fA-F]{1,4}(:[0-9a-fA-F]{1,4})*$ ]] || \
       [[ $ip =~ ^[0-9a-fA-F]{1,4}(:[0-9a-fA-F]{1,4})*::[0-9a-fA-F]{1,4}(:[0-9a-fA-F]{1,4})*$ ]]; then
        return 0
    fi
    
    return 1
}

validate_cidr() {
    local cidr="$1"
    if [[ $cidr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        local ip=$(echo "$cidr" | cut -d'/' -f1)
        local mask=$(echo "$cidr" | cut -d'/' -f2)
        if validate_ipv4 "$ip" && [[ $mask -ge 0 && $mask -le 32 ]]; then
            return 0
        fi
    elif [[ $cidr =~ ^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}/[0-9]{1,3}$ ]] || \
          [[ $cidr =~ ^([0-9a-fA-F]{1,4}:)*::([0-9a-fA-F]{1,4}:)*[0-9a-fA-F]{1,4}/[0-9]{1,3}$ ]]; then
        local ip=$(echo "$cidr" | cut -d'/' -f1)
        local mask=$(echo "$cidr" | cut -d'/' -f2)
        if validate_ipv6 "$ip" && [[ $mask -ge 0 && $mask -le 128 ]]; then
            return 0
        fi
    fi
    return 1
}

validate_port() {
    local port="$1"
    if [[ $port =~ ^[0-9]+$ ]] && [[ $port -ge 1 && $port -le 65535 ]]; then
        return 0
    fi
    return 1
}

validate_interface() {
    local interface="$1"
    if [[ $interface =~ ^[a-zA-Z0-9_-]+$ ]] && [[ ${#interface} -le 15 ]]; then
        return 0
    fi
    return 1
}

# 网络工具函数
get_public_ipv4() {
    local ip=""
    local services=(
        "https://ipv4.icanhazip.com"
        "https://api.ipify.org"
        "https://ifconfig.me/ip"
        "https://checkip.amazonaws.com"
    )
    
    for service in "${services[@]}"; do
        if command -v curl &> /dev/null; then
            ip=$(curl -s --connect-timeout 5 --max-time 10 "$service" 2>/dev/null | tr -d '\n\r')
        elif command -v wget &> /dev/null; then
            ip=$(wget -qO- --timeout=10 "$service" 2>/dev/null | tr -d '\n\r')
        fi
        
        if validate_ipv4 "$ip"; then
            echo "$ip"
            return 0
        fi
    done
    
    return 1
}

get_public_ipv6() {
    local ip=""
    local services=(
        "https://ipv6.icanhazip.com"
        "https://api64.ipify.org"
        "https://ifconfig.me/ipv6"
    )
    
    for service in "${services[@]}"; do
        if command -v curl &> /dev/null; then
            ip=$(curl -s --connect-timeout 5 --max-time 10 "$service" 2>/dev/null | tr -d '\n\r')
        elif command -v wget &> /dev/null; then
            ip=$(wget -qO- --timeout=10 "$service" 2>/dev/null | tr -d '\n\r')
        fi
        
        if validate_ipv6 "$ip"; then
            echo "$ip"
            return 0
        fi
    done
    
    return 1
}

get_local_ipv4() {
    local interface="${1:-}"
    if [[ -n "$interface" ]]; then
        ip addr show "$interface" 2>/dev/null | grep -oP 'inet \K[0-9.]+' | head -1
    else
        ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[0-9.]+' | head -1
    fi
}

get_local_ipv6() {
    local interface="${1:-}"
    if [[ -n "$interface" ]]; then
        ip addr show "$interface" 2>/dev/null | grep -oP 'inet6 \K[0-9a-f:]+' | grep -v '^::1$' | grep -v '^fe80:' | head -1
    else
        ip -6 route get 2001:4860:4860::8888 2>/dev/null | grep -oP 'src \K[0-9a-f:]+' | head -1
    fi
}

# 文件操作函数
backup_file() {
    local file="$1"
    local backup_dir="${2:-/var/backups/ipv6-wireguard}"
    
    if [[ -f "$file" ]]; then
        mkdir -p "$backup_dir"
        local backup_file="${backup_dir}/$(basename "$file").$(date +%Y%m%d_%H%M%S).bak"
        cp "$file" "$backup_file"
        log_info "文件已备份: $backup_file"
        echo "$backup_file"
    fi
}

create_temp_file() {
    local prefix="${1:-temp}"
    local suffix="${2:-}"
    mktemp "/tmp/${prefix}.XXXXXX${suffix}"
}

# 字符串处理函数
trim() {
    local var="$1"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}

to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# 数组操作函数
array_contains() {
    local element="$1"
    shift
    local array=("$@")
    
    for item in "${array[@]}"; do
        if [[ "$item" == "$element" ]]; then
            return 0
        fi
    done
    return 1
}

array_join() {
    local delimiter="$1"
    shift
    local array=("$@")
    local result=""
    
    for item in "${array[@]}"; do
        if [[ -z "$result" ]]; then
            result="$item"
        else
            result="${result}${delimiter}${item}"
        fi
    done
    
    echo "$result"
}

# 时间函数
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

get_date() {
    date '+%Y-%m-%d'
}

get_time() {
    date '+%H:%M:%S'
}

# 系统信息函数
get_system_load() {
    if [[ -f /proc/loadavg ]]; then
        cat /proc/loadavg | awk '{print $1}'
    else
        uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ','
    fi
}

get_memory_usage() {
    if command -v free &> /dev/null; then
        free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}'
    else
        echo "0"
    fi
}

get_disk_usage() {
    local path="${1:-/}"
    if command -v df &> /dev/null; then
        df "$path" | tail -1 | awk '{print $5}' | sed 's/%//'
    else
        echo "0"
    fi
}

# 服务管理函数
is_service_running() {
    local service="$1"
    
    if command -v systemctl &> /dev/null; then
        systemctl is-active --quiet "$service"
    elif command -v service &> /dev/null; then
        service "$service" status &> /dev/null
    else
        return 1
    fi
}

start_service() {
    local service="$1"
    
    if command -v systemctl &> /dev/null; then
        systemctl start "$service"
    elif command -v service &> /dev/null; then
        service "$service" start
    else
        log_error "无法启动服务: $service"
        return 1
    fi
}

stop_service() {
    local service="$1"
    
    if command -v systemctl &> /dev/null; then
        systemctl stop "$service"
    elif command -v service &> /dev/null; then
        service "$service" stop
    else
        log_error "无法停止服务: $service"
        return 1
    fi
}

restart_service() {
    local service="$1"
    
    if command -v systemctl &> /dev/null; then
        systemctl restart "$service"
    elif command -v service &> /dev/null; then
        service "$service" restart
    else
        log_error "无法重启服务: $service"
        return 1
    fi
}

enable_service() {
    local service="$1"
    
    if command -v systemctl &> /dev/null; then
        systemctl enable "$service"
    elif command -v chkconfig &> /dev/null; then
        chkconfig "$service" on
    else
        log_warn "无法启用服务: $service"
    fi
}

disable_service() {
    local service="$1"
    
    if command -v systemctl &> /dev/null; then
        systemctl disable "$service"
    elif command -v chkconfig &> /dev/null; then
        chkconfig "$service" off
    else
        log_warn "无法禁用服务: $service"
    fi
}

# 包管理函数
install_package() {
    local package="$1"
    
    case "$PACKAGE_MANAGER" in
        "apt")
            apt-get update && apt-get install -y "$package"
            ;;
        "yum")
            yum install -y "$package"
            ;;
        "dnf")
            dnf install -y "$package"
            ;;
        "pacman")
            pacman -S --noconfirm "$package"
            ;;
        "zypper")
            zypper install -y "$package"
            ;;
        *)
            log_error "不支持的包管理器: $PACKAGE_MANAGER"
            return 1
            ;;
    esac
}

remove_package() {
    local package="$1"
    
    case "$PACKAGE_MANAGER" in
        "apt")
            apt-get remove -y "$package"
            ;;
        "yum")
            yum remove -y "$package"
            ;;
        "dnf")
            dnf remove -y "$package"
            ;;
        "pacman")
            pacman -R --noconfirm "$package"
            ;;
        "zypper")
            zypper remove -y "$package"
            ;;
        *)
            log_error "不支持的包管理器: $PACKAGE_MANAGER"
            return 1
            ;;
    esac
}

# 网络工具函数
test_connectivity() {
    local host="$1"
    local port="${2:-80}"
    local timeout="${3:-5}"
    
    if command -v nc &> /dev/null; then
        nc -z -w"$timeout" "$host" "$port" 2>/dev/null
    elif command -v telnet &> /dev/null; then
        timeout "$timeout" telnet "$host" "$port" 2>/dev/null | grep -q "Connected"
    else
        return 1
    fi
}

# 加密函数
generate_random_string() {
    local length="${1:-32}"
    if command -v openssl &> /dev/null; then
        openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
    else
        cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w "$length" | head -n 1
    fi
}

generate_wireguard_key() {
    if command -v wg &> /dev/null; then
        wg genkey
    else
        log_error "WireGuard工具未安装"
        return 1
    fi
}

generate_wireguard_public_key() {
    local private_key="$1"
    if command -v wg &> /dev/null; then
        echo "$private_key" | wg pubkey
    else
        log_error "WireGuard工具未安装"
        return 1
    fi
}

# 配置管理函数
get_config_value() {
    local key="$1"
    local config_file="${2:-$CONFIG_FILE}"
    
    if [[ -f "$config_file" ]]; then
        grep "^${key}=" "$config_file" | cut -d'=' -f2- | tr -d '"'
    fi
}

set_config_value() {
    local key="$1"
    local value="$2"
    local config_file="${3:-$CONFIG_FILE}"
    
    if [[ -f "$config_file" ]]; then
        if grep -q "^${key}=" "$config_file"; then
            sed -i "s/^${key}=.*/${key}=${value}/" "$config_file"
        else
            echo "${key}=${value}" >> "$config_file"
        fi
    else
        echo "${key}=${value}" > "$config_file"
    fi
}

# 日志目录权限检查和修复函数
check_log_directory_permissions() {
    local log_dir="$1"
    local current_user="$(whoami)"
    local current_group="$(id -gn 2>/dev/null || echo "unknown")"
    
    # 检查目录是否存在
    if [[ ! -d "$log_dir" ]]; then
        echo "目录不存在: $log_dir"
        return 1
    fi
    
    # 检查写权限
    if [[ ! -w "$log_dir" ]]; then
        echo "目录不可写: $log_dir"
        return 1
    fi
    
    # 检查所有者（兼容不同系统）
    local dir_owner="unknown"
    if command -v stat >/dev/null 2>&1; then
        # Linux系统
        if stat -c '%U' "$log_dir" >/dev/null 2>&1; then
            dir_owner="$(stat -c '%U' "$log_dir")"
        # macOS系统
        elif stat -f '%Su' "$log_dir" >/dev/null 2>&1; then
            dir_owner="$(stat -f '%Su' "$log_dir")"
        fi
    fi
    
    # 在Windows环境下或无法获取所有者信息时，跳过所有者检查
    # 对于/tmp等系统目录，只要可写就允许使用
    if [[ "$dir_owner" != "unknown" ]]; then
        # 如果是系统目录（如/tmp），只要可写就允许
        if [[ "$log_dir" == "/tmp" || "$log_dir" == "/var/tmp" ]]; then
            # 系统临时目录，只要可写就允许
            true
        elif [[ "$dir_owner" != "$current_user" && "$current_user" != "root" ]]; then
            echo "目录所有者不匹配: $dir_owner (当前用户: $current_user)"
            return 1
        fi
    fi
    
    echo "目录权限正常: $log_dir"
    return 0
}

# 修复日志目录权限
fix_log_directory_permissions() {
    local log_dir="$1"
    local current_user="$(whoami)"
    
    # 尝试修复权限
    if [[ "$current_user" == "root" ]]; then
        chown -R "$current_user:$current_user" "$log_dir" 2>/dev/null || true
        chmod -R 755 "$log_dir" 2>/dev/null || true
        echo "已修复目录权限: $log_dir"
        return 0
    else
        echo "需要root权限来修复目录权限: $log_dir"
        return 1
    fi
}

# =============================================================================
# 增强的日志系统
# =============================================================================

# 日志级别常量
declare -g IPV6WGM_LOG_LEVELS=("DEBUG" "INFO" "WARN" "ERROR" "FATAL")
declare -g IPV6WGM_LOG_LEVEL="${LOG_LEVEL:-INFO}"

# 日志轮转功能
rotate_logs() {
    local log_file="$1"
    local max_size_mb="${2:-10}"
    local max_files="${3:-5}"
    
    if [[ -f "$log_file" ]]; then
        local size_mb=$(du -m "$log_file" 2>/dev/null | cut -f1 || echo "0")
        if [[ $size_mb -ge $max_size_mb ]]; then
            log_info "日志文件过大 (${size_mb}MB)，开始轮转..."
            
            # 轮转现有日志文件
            for ((i=$max_files-1; i>0; i--)); do
                [[ -f "$log_file.$i" ]] && mv "$log_file.$i" "$log_file.$((i+1))" 2>/dev/null
            done
            
            # 移动当前日志文件
            mv "$log_file" "$log_file.1" 2>/dev/null && touch "$log_file"
            
            # 设置正确的权限
            chmod 644 "$log_file" 2>/dev/null || true
            
            log_info "日志轮转完成"
        fi
    fi
}

# 检查日志级别
check_log_level() {
    local target_level="$1"
    local current_level="$IPV6WGM_LOG_LEVEL"
    
    # 获取级别索引
    local target_index=-1
    local current_index=-1
    
    for i in "${!IPV6WGM_LOG_LEVELS[@]}"; do
        [[ "${IPV6WGM_LOG_LEVELS[$i]}" == "$target_level" ]] && target_index=$i
        [[ "${IPV6WGM_LOG_LEVELS[$i]}" == "$current_level" ]] && current_index=$i
    done
    
    # 如果找不到级别，默认允许
    if [[ $target_index -eq -1 || $current_index -eq -1 ]]; then
        return 0
    fi
    
    # 只有目标级别大于等于当前级别时才输出
    [[ $target_index -ge $current_index ]]
}

# 增强的日志函数
log_with_level() {
    local level="$1"
    local message="$2"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local log_file="$IPV6WGM_LOG_FILE"
    
    # 检查日志级别
    if ! check_log_level "$level"; then
        return 0
    fi
    
    # 确保日志目录存在
    ensure_log_directory "$log_file"
    log_file="${LOG_FILE:-/tmp/manager.log}"
    
    # 日志轮转
    rotate_logs "$log_file"
    
    # 格式化日志消息
    local formatted_message="[$timestamp] [$level] $message"
    
    # 根据级别选择颜色
    local color=""
    case "$level" in
        "DEBUG") color="$PURPLE" ;;
        "INFO")  color="$BLUE" ;;
        "WARN")  color="$YELLOW" ;;
        "ERROR") color="$RED" ;;
        "FATAL") color="$RED" ;;
    esac
    
    # 输出到控制台（带颜色）
    echo -e "${color}[$level]${NC} $message"
    
    # 输出到日志文件（无颜色）
    echo "$formatted_message" >> "$log_file" 2>/dev/null || true
}

# 重新定义日志函数
# shellcheck disable=SC2317
log_debug() { log_with_level "DEBUG" "$1"; }
log_info() { log_with_level "INFO" "$1"; }
log_warn() { log_with_level "WARN" "$1"; }
log_error() { log_with_level "ERROR" "$1"; }
log_fatal() { log_with_level "FATAL" "$1"; }

# 日志目录管理函数
ensure_log_directory() {
    local log_file="$1"
    local log_dir="$(dirname "$log_file")"
    
    # 如果已经初始化过，直接返回
    if [[ "$IPV6WGM_DIRS_INITIALIZED" == "true" ]]; then
        return 0
    fi
    
    # 检查是否在WSL或Windows环境下
    if [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ -n "${WSLENV:-}" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || ([[ -f /proc/version ]] && grep -qi microsoft /proc/version); then
        # 在WSL/Windows环境下，直接使用备用目录
        log_dir="/tmp/ipv6-wireguard-manager"
        log_file="$log_dir/manager.log"
        export LOG_FILE="$log_file"
        mkdir -p "$log_dir" 2>/dev/null || true
        IPV6WGM_DIRS_INITIALIZED=true
        return 0
    fi
    
    # 如果目录已存在且可写，直接返回
    if [[ -d "$log_dir" && -w "$log_dir" ]]; then
        return 0
    fi
    
    # 如果目录存在但不可写，尝试修复权限
    if [[ -d "$log_dir" && ! -w "$log_dir" ]]; then
        if check_log_directory_permissions "$log_dir" >/dev/null 2>&1; then
            return 0
        else
            echo -e "${YELLOW}[WARN]${NC} 日志目录权限问题: $log_dir" >&2
            if fix_log_directory_permissions "$log_dir" >/dev/null 2>&1; then
                echo -e "${GREEN}[SUCCESS]${NC} 已修复日志目录权限" >&2
                return 0
            else
                echo -e "${YELLOW}[WARN]${NC} 无法修复日志目录权限，将使用备用目录" >&2
            fi
        fi
    fi
    
    # 尝试创建目录
    if mkdir -p "$log_dir" 2>/dev/null; then
        # 设置适当的权限
        chmod 755 "$log_dir" 2>/dev/null || true
        # 如果是root用户，设置正确的所有者
        if [[ "$(whoami)" == "root" ]]; then
            chown root:root "$log_dir" 2>/dev/null || true
        fi
        return 0
    fi
    
    # 如果创建失败，尝试使用备用目录
    local fallback_dirs=(
        "/tmp/ipv6-wireguard-manager"
        "$HOME/.ipv6-wireguard-manager/logs"
        "/var/tmp/ipv6-wireguard-manager"
        "/tmp"
    )
    
    for fallback_dir in "${fallback_dirs[@]}"; do
        if mkdir -p "$fallback_dir" 2>/dev/null && [[ -w "$fallback_dir" ]]; then
            # 更新LOG_FILE为备用路径
            export LOG_FILE="${fallback_dir}/manager.log"
            if [[ "$IPV6WGM_LOG_WARNING_SHOWN" != "true" ]]; then
                echo -e "${YELLOW}[WARN]${NC} 无法创建日志目录 $log_dir，使用备用目录: $fallback_dir" >&2
                IPV6WGM_LOG_WARNING_SHOWN=true
            fi
            IPV6WGM_DIRS_INITIALIZED=true
            return 0
        fi
    done
    
    # 所有备用方案都失败，使用临时文件
    export LOG_FILE="/tmp/manager-$$.log"
    echo -e "${RED}[ERROR]${NC} 无法创建任何日志目录，使用临时文件: $LOG_FILE" >&2
    return 1
}

# 兼容性日志函数（保持向后兼容）
log_success() { log_with_level "INFO" "✓ $1"; }

# =============================================================================
# 标准化错误处理系统
# =============================================================================

# 错误代码常量
declare -g ERROR_CODES=(
    "SUCCESS=0"
    "GENERAL_ERROR=1"
    "PERMISSION_ERROR=101"
    "FILE_NOT_FOUND=102"
    "CONFIG_ERROR=103"
    "NETWORK_ERROR=104"
    "DEPENDENCY_ERROR=105"
    "INVALID_INPUT=106"
    "SERVICE_ERROR=107"
    "TIMEOUT_ERROR=108"
)

# 统一的错误退出函数
exit_with_error() {
    local exit_code="$1"
    local error_message="$2"
    local context="${3:-unknown}"
    local line_number="${4:-$LINENO}"
    
    # 记录错误信息
    log_error "[错误码: $exit_code] $error_message (上下文: $context, 行号: $line_number)"
    
    # 保存错误到错误日志
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] [${FUNCNAME[1]}] [Line: $line_number] $error_message" >> "$IPV6WGM_LOG_DIR/error.log" 2>/dev/null || true
    
    # 根据错误类型提供建议
    case "$exit_code" in
        101)
            log_error "权限不足，请使用sudo或管理员权限运行脚本"
            ;;
        102)
            log_error "文件不存在，请检查路径是否正确"
            ;;
        103)
            log_error "配置错误，请检查配置文件并修复问题"
            ;;
        104)
            log_error "网络连接失败，请检查网络设置"
            ;;
        105)
            log_error "缺少必要依赖，请安装相关软件包"
            ;;
        106)
            log_error "输入参数无效，请检查输入内容"
            ;;
        107)
            log_error "服务操作失败，请检查服务状态"
            ;;
        108)
            log_error "操作超时，请检查系统性能或网络状况"
            ;;
    esac
    
    exit "$exit_code"
}

# 错误处理函数
handle_error() {
    local error_code="$1"
    local error_message="$2"
    local context="${3:-unknown}"
    local line_number="${4:-$LINENO}"
    
    # 记录错误但不退出
    log_error "[错误码: $error_code] $error_message (上下文: $context, 行号: $line_number)"
    
    # 保存错误到错误日志
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] [${FUNCNAME[1]}] [Line: $line_number] $error_message" >> "$IPV6WGM_LOG_DIR/error.log" 2>/dev/null || true
    
    return "$error_code"
}

# 设置全局错误陷阱
export IPV6WGM_LAST_ERROR=""

function trap_error() {
    local exit_code="$?"
    local command="$BASH_COMMAND"
    local line_number="$LINENO"
    
    if [[ $exit_code -ne 0 && $exit_code -ne 130 ]]; then # 排除Ctrl+C中断
        IPV6WGM_LAST_ERROR="Command '$command' failed at line $line_number with exit code $exit_code"
        log_error "$IPV6WGM_LAST_ERROR"
    fi
}

# 安全执行命令函数
safe_execute() {
    local command="$1"
    local description="${2:-执行命令}"
    local allow_failure="${3:-false}"
    local timeout="${4:-30}"
    
    log_debug "执行命令: $command ($description)"
    
    # 使用超时控制
    if [[ $timeout -gt 0 ]] && command -v timeout >/dev/null 2>&1; then
        if timeout "$timeout" bash -c "$command"; then
            log_success "$description 成功"
            return 0
        else
            local exit_code=$?
            if [[ $exit_code -eq 124 ]]; then
                log_error "$description 超时 (${timeout}秒)"
            else
                log_error "$description 失败 (退出码: $exit_code)"
            fi
            
            if [[ "$allow_failure" == "false" ]]; then
                exit_with_error "$exit_code" "$description 执行失败" "safe_execute"
            else
                log_warn "$description 执行失败，但允许继续 (退出码: $exit_code)"
            fi
            return $exit_code
        fi
    else
        # 不使用超时控制
        if bash -c "$command"; then
            log_success "$description 成功"
            return 0
        else
            local exit_code=$?
            log_error "$description 失败 (退出码: $exit_code)"
            
            if [[ "$allow_failure" == "false" ]]; then
                exit_with_error "$exit_code" "$description 执行失败" "safe_execute"
            else
                log_warn "$description 执行失败，但允许继续 (退出码: $exit_code)"
            fi
            return $exit_code
        fi
    fi
}

# 日志函数增强
log_with_timestamp() {
    local level="$1"
    local message="$2"
    local timestamp=$(get_timestamp)
    echo -e "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_debug_enhanced() {
    if [[ "${LOG_LEVEL:-INFO}" == "DEBUG" ]]; then
        log_with_timestamp "DEBUG" "$1"
    fi
}

log_info_enhanced() {
    log_with_timestamp "INFO" "$1"
}

log_warn_enhanced() {
    log_with_timestamp "WARN" "$1"
}

log_error_enhanced() {
    log_with_timestamp "ERROR" "$1"
}

# 错误处理函数
handle_error() {
    local exit_code="$1"
    local error_message="$2"
    local line_number="$3"
    
    log_error_enhanced "错误发生在第 $line_number 行: $error_message (退出码: $exit_code)"
    
    # 可以在这里添加错误报告、清理等逻辑
    if [[ "${SEND_ERROR_REPORTS:-false}" == "true" ]]; then
        send_error_report "$error_message" "$line_number" "$exit_code"
    fi
}

# 清理函数
cleanup_on_exit() {
    local exit_code="$?"
    
    # 清理临时文件
    if [[ -n "${TEMP_FILES:-}" ]]; then
        for temp_file in "${TEMP_FILES[@]}"; do
            if [[ -f "$temp_file" ]]; then
                rm -f "$temp_file"
            fi
        done
    fi
    
    # 记录退出
    if [[ $exit_code -ne 0 ]]; then
        log_error_enhanced "脚本异常退出，退出码: $exit_code"
    else
        log_info_enhanced "脚本正常退出"
    fi
}

# 设置清理陷阱
trap cleanup_on_exit EXIT

# 初始化临时文件数组
declare -a IPV6WGM_TEMP_FILES=()
TEMP_FILES=()  # 兼容性变量

# 添加临时文件到清理列表
add_temp_file() {
    local file="$1"
    TEMP_FILES+=("$file")
}

# 输入验证和清理
sanitize_input() {
    local input="$1"
    
    # 移除危险字符
    input=$(echo "$input" | sed 's/[;&|`$(){}[\]<>]/_/g')
    
    # 限制长度
    if [[ ${#input} -gt 255 ]]; then
        input="${input:0:255}"
    fi
    
    echo "$input"
}

# 验证用户名
validate_username() {
    local username="$1"
    
    # 检查长度
    if [[ ${#username} -lt 3 || ${#username} -gt 20 ]]; then
        return 1
    fi
    
    # 检查字符
    if [[ ! "$username" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 1
    fi
    
    return 0
}

# 验证密码强度
validate_password() {
    local password="$1"
    
    # 检查长度
    if [[ ${#password} -lt 8 ]]; then
        return 1
    fi
    
    # 检查复杂度
    if [[ ! "$password" =~ [A-Z] ]] || [[ ! "$password" =~ [a-z] ]] || [[ ! "$password" =~ [0-9] ]]; then
        return 1
    fi
    
    return 0
}

# 安全输入函数
secure_input() {
    local prompt="$1"
    local default="$2"
    local value
    
    if [[ -n "$default" ]]; then
        read -rp "$prompt [$default]: " value
        value="${value:-$default}"
    else
        read -rp "$prompt: " value
    fi
    
    # 输入验证和清理
    value=$(sanitize_input "$value")
    echo "$value"
}

# 统一错误处理函数
handle_error() {
    local error_code="$1"
    local error_message="$2"
    local context="${3:-未知}"
    
    log_error "错误 [$error_code]: $error_message (上下文: $context)"
    
    case $error_code in
        PERMISSION_DENIED) 
            log_error "权限不足，请检查文件权限或使用sudo"
            return 101
            ;;
        FILE_NOT_FOUND) 
            log_error "文件不存在，请检查路径是否正确"
            return 102
            ;;
        NETWORK_ERROR) 
            log_error "网络连接失败，请检查网络设置"
            return 103
            ;;
        CONFIG_ERROR)
            log_error "配置错误，请检查配置文件"
            return 104
            ;;
        DEPENDENCY_MISSING)
            log_error "缺少必要依赖，请安装相关软件包"
            return 105
            ;;
        SERVICE_ERROR)
            log_error "服务操作失败，请检查服务状态"
            return 106
            ;;
        *) 
            log_error "未知错误"
            return 1
            ;;
    esac
}

# 修复文件行尾符
fix_line_endings() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    # 转换Windows行尾符为Unix行尾符
    if command -v sed &> /dev/null; then
        sed -i 's/\r$//' "$file" 2>/dev/null || true
    elif command -v tr &> /dev/null; then
        tr -d '\r' < "$file" > "${file}.tmp" && mv "${file}.tmp" "$file" 2>/dev/null || true
    elif command -v dos2unix &> /dev/null; then
        dos2unix "$file" 2>/dev/null || true
    else
        # 使用Python作为最后的回退方案
        python3 -c "
import sys
with open('$file', 'rb') as f:
    content = f.read()
content = content.replace(b'\r\n', b'\n').replace(b'\r', b'\n')
with open('$file', 'wb') as f:
    f.write(content)
" 2>/dev/null || true
    fi
}

# 配置管理优化
load_config() {
    local config_file="${1:-$CONFIG_FILE}"
    
    if [[ ! -f "$config_file" ]]; then
        handle_error "FILE_NOT_FOUND" "配置文件不存在: $config_file" "load_config"
        return 1
    fi
    
    # 确保配置文件使用Unix行尾符
    fix_line_endings "$config_file"
    
    log_info "加载配置文件: $config_file"
    
    # 安全地加载配置
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        [[ $key =~ ^# ]] || [[ -z $key ]] && continue
        
        # 清理键名和值
        key=$(echo "$key" | trim)
        value=$(echo "$value" | trim)
        
        # 验证配置键名
        if [[ ! $key =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
            log_warn "无效的配置键名: $key"
            continue
        fi
        
        # 设置配置变量
        declare -g "$key"="$value"
        log_debug "设置配置: $key=$value"
    done < "$config_file"
    
    log_success "配置文件加载完成"
}

# =============================================================================
# 性能优化 - 增强缓存机制
# =============================================================================

# 缓存系统
declare -A CACHE
declare -A CACHE_TIMES
declare -A CACHE_HITS
declare -A CACHE_MISSES

# 缓存统计
declare -g TOTAL_CACHE_HITS=0
declare -g TOTAL_CACHE_MISSES=0
declare -g TOTAL_CACHE_SIZE=0

# 增强的命令缓存函数
cached_command() {
    local cache_key="$1"
    local command="$2"
    local ttl="${3:-300}"  # 默认5分钟缓存
    local force_refresh="${4:-false}"
    
    # 检查是否强制刷新
    if [[ "$force_refresh" == "true" ]]; then
        unset CACHE[$cache_key]
        unset CACHE_TIMES[$cache_key]
    fi
    
    # 检查缓存
    if [[ -n "${CACHE[$cache_key]}" ]]; then
        local cached_time="${CACHE_TIMES[$cache_key]}"
        local current_time=$(date +%s)
        
        if (( current_time - cached_time < ttl )); then
            CACHE_HITS[$cache_key]=$((${CACHE_HITS[$cache_key]:-0} + 1))
            IPV6WGM_TOTAL_CACHE_HITS=$((IPV6WGM_TOTAL_CACHE_HITS + 1))
            TOTAL_CACHE_HITS=$((TOTAL_CACHE_HITS + 1))  # 兼容性变量
            log_debug "使用缓存结果: $cache_key (命中次数: ${CACHE_HITS[$cache_key]})"
            echo "${CACHE[$cache_key]}"
            return 0
        else
            log_debug "缓存过期: $cache_key"
        fi
    fi
    
    # 执行命令并缓存结果
    log_debug "执行命令并缓存: $cache_key"
    local result
    local start_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    if result=$(eval "$command" 2>/dev/null); then
        local end_time=$(date +%s%3N 2>/dev/null || date +%s)
        local execution_time=$((end_time - start_time))
        
        CACHE[$cache_key]="$result"
        CACHE_TIMES[$cache_key]=$(date +%s)
        CACHE_MISSES[$cache_key]=$((${CACHE_MISSES[$cache_key]:-0} + 1))
        IPV6WGM_TOTAL_CACHE_MISSES=$((IPV6WGM_TOTAL_CACHE_MISSES + 1))
        IPV6WGM_TOTAL_CACHE_SIZE=$((IPV6WGM_TOTAL_CACHE_SIZE + 1))
        TOTAL_CACHE_MISSES=$((TOTAL_CACHE_MISSES + 1))  # 兼容性变量
        TOTAL_CACHE_SIZE=$((TOTAL_CACHE_SIZE + 1))  # 兼容性变量
        
        log_debug "命令执行成功: $cache_key (耗时: ${execution_time}ms)"
        echo "$result"
        return 0
    else
        log_error "命令执行失败: $command"
        return 1
    fi
}

# 智能缓存函数（自动生成缓存键）
smart_cached_command() {
    local command="$1"
    local ttl="${2:-300}"
    local cache_key="cmd_$(echo "$command" | md5sum | cut -d' ' -f1)"
    
    cached_command "$cache_key" "$command" "$ttl"
}

# 缓存预热
warm_cache() {
    local commands=("$@")
    local success_count=0
    local failed_count=0
    
    log_info "开始缓存预热..."
    
    for cmd in "${commands[@]}"; do
        local cache_key="warm_$(echo "$cmd" | md5sum | cut -d' ' -f1)"
        if cached_command "$cache_key" "$cmd" 3600; then
            ((success_count++))
        else
            ((failed_count++))
        fi
    done
    
    log_info "缓存预热完成: 成功 $success_count, 失败 $failed_count"
}

# 清理过期缓存
cleanup_expired_cache() {
    local current_time=$(date +%s)
    local cleaned_count=0
    
    for key in "${!CACHE_TIMES[@]}"; do
        local cached_time="${CACHE_TIMES[$key]}"
        local ttl="${CACHE_TTL[$key]:-300}"
        
        if (( current_time - cached_time > ttl )); then
            unset CACHE[$key]
            unset CACHE_TIMES[$key]
            unset CACHE_HITS[$key]
            unset CACHE_MISSES[$key]
            ((cleaned_count++))
        fi
    done
    
    if [[ $cleaned_count -gt 0 ]]; then
        log_info "清理了 $cleaned_count 个过期缓存条目"
    fi
}

# 清理所有缓存
clear_cache() {
    IPV6WGM_CACHE=()
    IPV6WGM_CACHE_TIMES=()
    CACHE=()  # 兼容性变量
    CACHE_TIMES=()  # 兼容性变量
    CACHE_HITS=()
    CACHE_MISSES=()
    TOTAL_CACHE_HITS=0
    TOTAL_CACHE_MISSES=0
    TOTAL_CACHE_SIZE=0
    
    log_info "所有缓存已清理"
}

# 获取缓存统计
get_cache_stats() {
    local cache_count=${#CACHE[@]}
    local total_requests=$((TOTAL_CACHE_HITS + TOTAL_CACHE_MISSES))
    local hit_rate=0
    
    if [[ $total_requests -gt 0 ]]; then
        hit_rate=$((TOTAL_CACHE_HITS * 100 / total_requests))
    fi
    
    echo "缓存统计信息:"
    echo "- 缓存条目数: $cache_count"
    echo "- 总请求数: $total_requests"
    echo "- 缓存命中: $TOTAL_CACHE_HITS"
    echo "- 缓存未命中: $TOTAL_CACHE_MISSES"
    echo "- 命中率: ${hit_rate}%"
    echo "- 缓存大小: $TOTAL_CACHE_SIZE"
}

# 获取缓存详细信息
get_cache_details() {
    echo "缓存详细信息:"
    for key in "${!CACHE[@]}"; do
        local hits="${CACHE_HITS[$key]:-0}"
        local misses="${CACHE_MISSES[$key]:-0}"
        local cached_time="${CACHE_TIMES[$key]:-0}"
        local age=$(( $(date +%s) - cached_time ))
        
        echo "- $key: 命中 $hits 次, 未命中 $misses 次, 年龄 ${age}秒"
    done
}

# =============================================================================
# 配置验证函数
# =============================================================================

# 配置项验证
validate_config_item() {
    local key="$1"
    local value="$2"
    local type="$3"
    
    # 如果值为空，返回失败
    if [[ -z "$value" ]]; then
        return 1
    fi
    
    case "$type" in
        "port")
            if [[ ! $value =~ ^[0-9]+$ ]]; then
                return 1
            fi
            if [[ $value -lt 1 || $value -gt 65535 ]]; then
                return 1
            fi
            ;;
        "ip")
            # 简化的IP验证
            if [[ $value =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                return 0
            elif [[ $value =~ ^[0-9a-fA-F:]+$ ]]; then
                return 0
            else
                return 1
            fi
            ;;
        "boolean")
            if [[ ! $value =~ ^(true|false|yes|no|1|0)$ ]]; then
                return 1
            fi
            ;;
        "path")
            # 对于路径，只检查格式，不检查是否存在
            if [[ $value =~ ^/ ]]; then
                return 0
            else
                return 1
            fi
            ;;
        "string")
            # 字符串类型，只要不为空就通过
            return 0
            ;;
        *)
            # 未知类型，默认通过
            return 0
            ;;
    esac
    
    return 0
}

# 配置文件格式验证
validate_config_format() {
    local config_file="$1"
    
    # 检查配置文件是否存在
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    # 检查配置语法
    local invalid_lines=$(grep -vE '^(#.*)?$|^[A-Za-z0-9_]+=[^=]*$' "$config_file" 2>/dev/null | wc -l)
    if [[ $invalid_lines -gt 0 ]]; then
        return 1
    fi
    
    return 0
}

# 统一的命令执行函数
execute_command() {
    local command="$1"
    local description="$2"
    local allow_failure="${3:-false}"
    local timeout="${4:-300}"  # 默认5分钟超时
    
    log_info "${description}..."
    
    # 使用timeout命令限制执行时间
    if command -v timeout >/dev/null 2>&1; then
        if timeout "$timeout" bash -c "$command"; then
            log_success "${description}完成"
            return 0
        else
            local exit_code=$?
            if [[ "$allow_failure" == "true" ]]; then
                log_warn "${description}执行失败，继续执行 (退出码: $exit_code)"
                return 1
            else
                log_error "${description}执行失败: 命令 '${command}' 返回非零状态 (退出码: $exit_code)"
                exit 1
            fi
        fi
    else
        # 如果没有timeout命令，直接执行
        if eval "$command"; then
            log_success "${description}完成"
            return 0
        else
            local exit_code=$?
            if [[ "$allow_failure" == "true" ]]; then
                log_warn "${description}执行失败，继续执行 (退出码: $exit_code)"
                return 1
            else
                log_error "${description}执行失败: 命令 '${command}' 返回非零状态 (退出码: $exit_code)"
                exit 1
            fi
        fi
    fi
}

# 安全权限设置函数
secure_permissions() {
    local target_path="$1"
    local mode="$2"
    local user="${3:-root}"
    local group="${4:-root}"
    
    if [[ ! -e "$target_path" ]]; then
        log_warn "目标路径不存在: $target_path"
        return 1
    fi
    
    execute_command "chown -R '${user}:${group}' '$target_path'" "设置 $target_path 的所有者" "true"
    execute_command "chmod -R '$mode' '$target_path'" "设置 $target_path 的权限" "true"
    
    # 对于配置文件等敏感内容，额外限制权限
    if [[ "$target_path" == *"config"* || "$target_path" == *".key" ]]; then
        execute_command "find '$target_path' -type f \\( -name '*.conf' -o -name '*.key' -o -name '*.pem' \\) -exec chmod 600 {} \\;" "设置敏感文件权限" "true"
    fi
    
    log_info "已设置 $target_path 的安全权限（$mode, ${user}:${group}）"
    return 0
}

# 懒加载机制
lazy_load() {
    local module_name="$1"
    local module_path="${MODULES_DIR:-/opt/ipv6-wireguard-manager/modules}/${module_name}.sh"
    
    if [[ ! -f "$module_path" ]]; then
        log_error "懒加载失败: 模块文件不存在 $module_path"
        return 1
    fi
    
    # 检查模块是否已加载
    if declare -f "module_${module_name}_loaded" >/dev/null 2>&1 && "module_${module_name}_loaded"; then
        return 0
    fi
    
    log_debug "懒加载模块: $module_name"
    source "$module_path"
    
    # 标记模块已加载
    eval "function module_${module_name}_loaded() { return 0; }"
    return 0
}

# 统一的依赖安装函数
install_dependency() {
    local package_name="$1"
    local package_description="${2:-$package_name}"
    local allow_failure="${3:-false}"
    
    # 检查是否已安装
    if command -v "$package_name" &> /dev/null; then
        log_info "${package_description}已安装，跳过"
        return 0
    fi
    
    log_info "安装${package_description}..."
    local os_type="$(detect_os)"
    
    case "$os_type" in
        "ubuntu"|"debian")
            execute_command "apt-get update -qq" "更新包列表" "false"
            execute_command "apt-get install -y $package_name" "安装${package_description}" "$allow_failure"
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            execute_command "yum install -y $package_name" "安装${package_description}" "$allow_failure"
            ;;
        "fedora")
            execute_command "dnf install -y $package_name" "安装${package_description}" "$allow_failure"
            ;;
        "arch")
            execute_command "pacman -S --noconfirm $package_name" "安装${package_description}" "$allow_failure"
            ;;
        "opensuse")
            execute_command "zypper install -y $package_name" "安装${package_description}" "$allow_failure"
            ;;
        *)
            log_error "不支持的包管理器: $os_type"
            return 1
            ;;
    esac
    
    # 验证安装结果
    if command -v "$package_name" &> /dev/null; then
        log_success "${package_description}安装成功"
        return 0
    else
        if [[ "$allow_failure" == "true" ]]; then
            log_warn "${package_description}安装失败，但允许继续"
            return 1
        else
            log_error "${package_description}安装失败"
            return 1
        fi
    fi
}

# 统一的Python依赖安装函数
install_python_dependency() {
    local package_name="$1"
    local description="${2:-$package_name}"
    local allow_failure="${3:-true}"
    
    if ! command -v python3 &> /dev/null; then
        log_warn "Python3未安装，${description}功能可能无法正常工作"
        return 1
    fi
    
    if command -v pip3 &> /dev/null; then
        execute_command "pip3 install $package_name" "安装Python依赖: $description" "$allow_failure"
    else
        log_warn "pip3未安装，无法安装Python依赖: $description"
        return 1
    fi
}

# 操作系统检测函数
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            "ubuntu"|"debian")
                echo "ubuntu"
                ;;
            "centos"|"rhel"|"rocky"|"almalinux")
                echo "centos"
                ;;
            "fedora")
                echo "fedora"
                ;;
            "arch")
                echo "arch"
                ;;
            "opensuse"*)
                echo "opensuse"
                ;;
            *)
                echo "unknown"
                ;;
        esac
    else
        echo "unknown"
    fi
}

# 导出函数供其他模块使用
export -f print_header print_section print_success print_error print_warning print_info show_input show_success
export -f show_progress confirm validate_ipv4 validate_ipv6 validate_cidr validate_port validate_interface
export -f get_public_ipv4 get_public_ipv6 get_local_ipv4 get_local_ipv6
export -f backup_file create_temp_file trim to_lower to_upper
export -f array_contains array_join get_timestamp get_date get_time
export -f get_system_load get_memory_usage get_disk_usage
export -f is_service_running start_service stop_service restart_service enable_service disable_service
export -f install_package remove_package test_connectivity
export -f generate_random_string generate_wireguard_key generate_wireguard_public_key
export -f get_config_value set_config_value
export -f log_info log_success log_warn log_error log_debug log_fatal log_with_level rotate_logs check_log_level
export -f ensure_log_directory check_log_directory_permissions fix_log_directory_permissions
export -f exit_with_error handle_error trap_error safe_execute
export -f ensure_variables get_variable set_variable
export -f handle_error cleanup_on_exit add_temp_file
export -f sanitize_input validate_username validate_password secure_input
export -f fix_line_endings load_config cached_command smart_cached_command warm_cache cleanup_expired_cache clear_cache get_cache_stats get_cache_details validate_config_item validate_config_format
export -f execute_command secure_permissions lazy_load install_dependency install_python_dependency detect_os
