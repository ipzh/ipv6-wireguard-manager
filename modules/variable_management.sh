#!/bin/bash

# 变量管理系统
# 提供统一的变量定义、验证和管理功能

# =============================================================================
# 全局变量定义区域 - 使用IPV6WGM_前缀规范
# =============================================================================

# 核心目录变量
declare -g IPV6WGM_CONFIG_DIR="${IPV6WGM_CONFIG_DIR:-/etc/ipv6-wireguard-manager}"
declare -g IPV6WGM_LOG_DIR="${IPV6WGM_LOG_DIR:-/var/log/ipv6-wireguard-manager}"
declare -g IPV6WGM_LOG_FILE="${IPV6WGM_LOG_FILE:-$IPV6WGM_LOG_DIR/manager.log}"
declare -g IPV6WGM_TEMP_DIR="${IPV6WGM_TEMP_DIR:-/tmp/ipv6-wireguard-manager}"

# 脚本路径变量
declare -g IPV6WGM_SCRIPT_DIR="${IPV6WGM_SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)}"
declare -g IPV6WGM_MODULES_DIR="${IPV6WGM_MODULES_DIR:-$IPV6WGM_SCRIPT_DIR/modules}"
declare -g IPV6WGM_BIN_DIR="${IPV6WGM_BIN_DIR:-/usr/local/bin}"

# 系统变量
declare -g IPV6WGM_USER="${IPV6WGM_USER:-$(whoami)}"
declare -g IPV6WGM_HOME="${IPV6WGM_HOME:-/root}"
declare -g IPV6WGM_OS_TYPE="${IPV6WGM_OS_TYPE:-unknown}"
declare -g IPV6WGM_ARCH="${IPV6WGM_ARCH:-$(uname -m)}"

# 版本信息
declare -g IPV6WGM_VERSION="${IPV6WGM_VERSION:-1.0.0}"
declare -g IPV6WGM_BUILD_DATE="${IPV6WGM_BUILD_DATE:-$(date +%Y-%m-%d)}"

# 功能开关
declare -g IPV6WGM_DEBUG="${IPV6WGM_DEBUG:-false}"
declare -g IPV6WGM_VERBOSE="${IPV6WGM_VERBOSE:-false}"
declare -g IPV6WGM_DRY_RUN="${IPV6WGM_DRY_RUN:-false}"

# 日志级别
declare -g IPV6WGM_LOG_LEVEL="${IPV6WGM_LOG_LEVEL:-INFO}"
declare -g IPV6WGM_LOG_MAX_SIZE="${IPV6WGM_LOG_MAX_SIZE:-10485760}"  # 10MB
declare -g IPV6WGM_LOG_MAX_FILES="${IPV6WGM_LOG_MAX_FILES:-5}"

# 缓存配置
declare -g IPV6WGM_CACHE_TTL="${IPV6WGM_CACHE_TTL:-300}"  # 5分钟
declare -g IPV6WGM_CACHE_MAX_SIZE="${IPV6WGM_CACHE_MAX_SIZE:-100}"

# 网络配置
declare -g IPV6WGM_WIREGUARD_PORT="${IPV6WGM_WIREGUARD_PORT:-51820}"
declare -g IPV6WGM_WEB_PORT="${IPV6WGM_WEB_PORT:-8080}"
declare -g IPV6WGM_IPV6_PREFIX="${IPV6WGM_IPV6_PREFIX:-2001:db8::/64}"

# 兼容性变量（保持向后兼容）
CONFIG_DIR="$IPV6WGM_CONFIG_DIR"
LOG_DIR="$IPV6WGM_LOG_DIR"
LOG_FILE="$IPV6WGM_LOG_FILE"
SCRIPT_DIR="$IPV6WGM_SCRIPT_DIR"
MODULES_DIR="$IPV6WGM_MODULES_DIR"
BIN_DIR="$IPV6WGM_BIN_DIR"

# =============================================================================
# 变量管理函数
# =============================================================================

# 确保所有必要变量已定义
ensure_variables() {
    local missing_vars=()
    
    # 检查核心变量
    local required_vars=(
        "IPV6WGM_CONFIG_DIR"
        "IPV6WGM_LOG_DIR"
        "IPV6WGM_SCRIPT_DIR"
        "IPV6WGM_MODULES_DIR"
        "IPV6WGM_VERSION"
    )
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "缺少必要的变量: ${missing_vars[*]}"
        return 1
    fi
    
    # 确保目录存在
    local required_dirs=(
        "$IPV6WGM_CONFIG_DIR"
        "$IPV6WGM_LOG_DIR"
        "$IPV6WGM_TEMP_DIR"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" 2>/dev/null || {
                log_warn "无法创建目录: $dir"
                # 尝试使用备用目录
                case "$dir" in
                    "$IPV6WGM_LOG_DIR")
                        IPV6WGM_LOG_DIR="/tmp/ipv6-wireguard-manager/logs"
                        LOG_DIR="$IPV6WGM_LOG_DIR"
                        mkdir -p "$IPV6WGM_LOG_DIR" 2>/dev/null || true
                        ;;
                esac
            }
        fi
    done
    
    return 0
}

# 获取变量值
get_variable() {
    local var_name="$1"
    local default_value="${2:-}"
    
    if [[ -n "${!var_name:-}" ]]; then
        echo "${!var_name}"
    else
        echo "$default_value"
    fi
}

# 设置变量值
set_variable() {
    local var_name="$1"
    local value="$2"
    local export_flag="${3:-false}"
    
    if [[ "$export_flag" == "true" ]]; then
        declare -g "$var_name"="$value"
        export "$var_name"
    else
        declare -g "$var_name"="$value"
    fi
}

# 验证变量值
validate_variable() {
    local var_name="$1"
    local value="$2"
    local type="${3:-string}"
    
    case "$type" in
        "directory")
            if [[ -d "$value" ]]; then
                return 0
            else
                log_error "目录不存在: $value"
                return 1
            fi
            ;;
        "file")
            if [[ -f "$value" ]]; then
                return 0
            else
                log_error "文件不存在: $value"
                return 1
            fi
            ;;
        "port")
            if [[ "$value" =~ ^[0-9]+$ ]] && [[ $value -ge 1 && $value -le 65535 ]]; then
                return 0
            else
                log_error "无效端口号: $value"
                return 1
            fi
            ;;
        "ipv6")
            if [[ "$value" =~ ^[0-9a-fA-F:]+$ ]]; then
                return 0
            else
                log_error "无效IPv6地址: $value"
                return 1
            fi
            ;;
        "boolean")
            if [[ "$value" =~ ^(true|false|yes|no|1|0)$ ]]; then
                return 0
            else
                log_error "无效布尔值: $value"
                return 1
            fi
            ;;
        "string")
            if [[ -n "$value" ]]; then
                return 0
            else
                log_error "字符串不能为空: $value"
                return 1
            fi
            ;;
        *)
            return 0
            ;;
    esac
}

# 列出所有IPV6WGM_变量
list_ipv6wgm_variables() {
    local prefix="${1:-IPV6WGM_}"
    
    echo "=== IPV6WGM 变量列表 ==="
    for var in $(declare -p | grep "^declare -g IPV6WGM_" | cut -d' ' -f3 | cut -d'=' -f1); do
        local value="${!var}"
        echo "$var = $value"
    done
}

# 导出变量到环境
export_ipv6wgm_variables() {
    local prefix="${1:-IPV6WGM_}"
    
    for var in $(declare -p | grep "^declare -g IPV6WGM_" | cut -d' ' -f3 | cut -d'=' -f1); do
        export "$var"
    done
}

# 从配置文件加载变量
load_variables_from_config() {
    local config_file="${1:-$IPV6WGM_CONFIG_DIR/manager.conf}"
    
    if [[ ! -f "$config_file" ]]; then
        log_warn "配置文件不存在: $config_file"
        return 1
    fi
    
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        
        # 移除前后空格
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # 如果变量名以IPV6WGM_开头，则设置
        if [[ "$key" =~ ^IPV6WGM_ ]]; then
            set_variable "$key" "$value" "true"
        fi
    done < "$config_file"
    
    log_info "从配置文件加载变量: $config_file"
    return 0
}

# 保存变量到配置文件
save_variables_to_config() {
    local config_file="${1:-$IPV6WGM_CONFIG_DIR/manager.conf}"
    local backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 备份原配置文件
    if [[ -f "$config_file" ]]; then
        cp "$config_file" "$backup_file"
    fi
    
    # 创建新配置文件
    {
        echo "# IPv6 WireGuard Manager 配置文件"
        echo "# 生成时间: $(date)"
        echo ""
        
        for var in $(declare -p | grep "^declare -g IPV6WGM_" | cut -d' ' -f3 | cut -d'=' -f1 | sort); do
            local value="${!var}"
            echo "$var=$value"
        done
    } > "$config_file"
    
    log_info "变量已保存到配置文件: $config_file"
    return 0
}

# 变量初始化
init_variables() {
    # 确保基本变量
    ensure_variables || return 1
    
    # 尝试从配置文件加载
    load_variables_from_config 2>/dev/null || true
    
    # 导出变量
    export_ipv6wgm_variables
    
    log_info "变量系统初始化完成"
    return 0
}

# 导出函数
export -f ensure_variables
export -f get_variable
export -f set_variable
export -f validate_variable
export -f list_ipv6wgm_variables
export -f export_ipv6wgm_variables
export -f load_variables_from_config
export -f save_variables_to_config
export -f init_variables
