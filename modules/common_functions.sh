#!/bin/bash

# 公共函数库
# 提供所有模块共用的基础函数

# 设置默认变量（如果未定义）
CONFIG_DIR="${CONFIG_DIR:-/etc/ipv6-wireguard-manager}"
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
SECONDARY_COLOR='\033[0;36m'  # 次要颜色（青色）
NC='\033[0m' # No Color

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
        read -p "$prompt [$default]: " value
        value="${value:-$default}"
    else
        read -p "$prompt: " value
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
        read -p "$prompt [Y/n]: " -n 1 -r
        echo
        # 空输入或Y/y返回0，其他返回1
        [[ -z "$REPLY" || $REPLY =~ ^[Yy]$ ]] && return 0 || return 1
    else
        read -p "$prompt [y/N]: " -n 1 -r
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

# 基本日志函数
log_info() {
    local log_file="${LOG_FILE:-/tmp/manager.log}"
    # 确保日志目录存在
    mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$log_file"
}

log_success() {
    local log_file="${LOG_FILE:-/tmp/manager.log}"
    mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$log_file"
}

log_warn() {
    local log_file="${LOG_FILE:-/tmp/manager.log}"
    mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$log_file"
}

log_error() {
    local log_file="${LOG_FILE:-/tmp/manager.log}"
    mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$log_file"
}

log_debug() {
    if [[ "${LOG_LEVEL:-INFO}" == "DEBUG" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1" | tee -a "$LOG_FILE"
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
TEMP_FILES=()

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
        read -p "$prompt [$default]: " value
        value="${value:-$default}"
    else
        read -p "$prompt: " value
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

# 配置管理优化
load_config() {
    local config_file="${1:-$CONFIG_FILE}"
    
    if [[ ! -f "$config_file" ]]; then
        handle_error "FILE_NOT_FOUND" "配置文件不存在: $config_file" "load_config"
        return 1
    fi
    
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

# 性能优化 - 缓存机制
declare -A CACHE

cached_command() {
    local cache_key="$1"
    local command="$2"
    local ttl="${3:-300}"  # 默认5分钟缓存
    
    # 检查缓存
    if [[ -n "${CACHE[$cache_key]}" ]]; then
        local cached_time="${CACHE[${cache_key}_time]}"
        local current_time=$(date +%s)
        
        if (( current_time - cached_time < ttl )); then
            log_debug "使用缓存结果: $cache_key"
            echo "${CACHE[$cache_key]}"
            return 0
        fi
    fi
    
    # 执行命令并缓存结果
    log_debug "执行命令并缓存: $cache_key"
    local result
    if result=$(eval "$command" 2>/dev/null); then
        CACHE["$cache_key"]="$result"
        CACHE["${cache_key}_time"]=$(date +%s)
        echo "$result"
        return 0
    else
        log_error "命令执行失败: $command"
        return 1
    fi
}

# 清理缓存
clear_cache() {
    CACHE=()
    log_info "缓存已清理"
}

# 获取缓存统计
get_cache_stats() {
    local cache_count=${#CACHE[@]}
    echo "缓存条目数: $((cache_count / 2))"
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
export -f log_info log_success log_warn log_error log_debug log_with_timestamp log_debug_enhanced log_info_enhanced log_warn_enhanced log_error_enhanced
export -f handle_error cleanup_on_exit add_temp_file
export -f sanitize_input validate_username validate_password secure_input
export -f load_config cached_command clear_cache get_cache_stats
