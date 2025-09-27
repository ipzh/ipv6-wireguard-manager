#!/bin/bash

# 标准化导入模板
# 版本: 1.0.0
# 描述: 所有脚本应使用此模板进行标准化导入

set -euo pipefail

# 统一的导入机制
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${MODULES_DIR:-${SCRIPT_DIR}/modules}"

# 导入公共函数库
if [[ -f "${MODULES_DIR}/common_functions.sh" ]]; then
    source "${MODULES_DIR}/common_functions.sh"
    # 验证导入是否成功
    if ! command -v log_info &> /dev/null; then
        echo -e "${RED}错误: 公共函数库导入失败，log_info函数不可用${NC}" >&2
        exit 1
    fi
else
    echo -e "${RED}错误: 公共函数库文件不存在: ${MODULES_DIR}/common_functions.sh${NC}" >&2
    exit 1
fi

# 导入模块加载器
if [[ -f "${MODULES_DIR}/module_loader.sh" ]]; then
    source "${MODULES_DIR}/module_loader.sh"
    log_info "模块加载器已导入"
else
    log_error "模块加载器文件不存在: ${MODULES_DIR}/module_loader.sh"
    exit 1
fi

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
    local module_path="${MODULES_DIR}/${module_name}.sh"
    
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

# 统一的配置管理机制
load_config() {
    local config_file="$1"
    local config_dir="$(dirname "$config_file")"
    
    # 确保配置目录存在
    execute_command "mkdir -p '$config_dir'" "创建配置目录" "true"
    
    # 如果配置文件不存在，创建默认配置
    if [[ ! -f "$config_file" ]]; then
        create_default_config "$config_file"
    fi
    
    # 加载配置文件
    source "$config_file"
    log_info "配置文件已加载: $config_file"
}

# 创建默认配置文件
create_default_config() {
    local config_file="$1"
    cat > "$config_file" << 'EOF'
# IPv6 WireGuard Manager 配置文件
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')

# 基本配置
INSTALL_DIR="/opt/ipv6-wireguard-manager"
CONFIG_DIR="/etc/ipv6-wireguard-manager"
LOG_DIR="/var/log/ipv6-wireguard-manager"
LOG_FILE="${LOG_DIR}/manager.log"
LOG_LEVEL="INFO"

# 功能开关
INSTALL_WIREGUARD="true"
INSTALL_BIRD="true"
INSTALL_FIREWALL="true"
INSTALL_WEB_INTERFACE="true"
INSTALL_MONITORING="true"

# 安全配置
SECURE_PERMISSIONS="true"
AUTO_UPDATE="false"
BACKUP_ENABLED="true"

# 性能配置
LAZY_LOADING="true"
CACHE_ENABLED="true"
CACHE_TTL="300"
EOF
    
    # 替换时间戳
    sed -i "s/\$(date[^)]*)/$(date '+%Y-%m-%d %H:%M:%S')/g" "$config_file"
    
    log_info "默认配置文件已创建: $config_file"
}

# 错误处理函数
handle_error() {
    local error_code="$1"
    local error_message="$2"
    local function_name="${3:-unknown}"
    
    log_error "错误 [$error_code] 在函数 $function_name: $error_message"
    
    # 根据错误代码进行不同的处理
    case "$error_code" in
        "FILE_NOT_FOUND")
            log_error "文件不存在，请检查路径是否正确"
            ;;
        "PERMISSION_DENIED")
            log_error "权限不足，请使用sudo运行"
            ;;
        "NETWORK_ERROR")
            log_error "网络错误，请检查网络连接"
            ;;
        "DEPENDENCY_MISSING")
            log_error "依赖缺失，请安装必要的软件包"
            ;;
        *)
            log_error "未知错误: $error_code"
            ;;
    esac
    
    return 1
}

# 清理函数
cleanup() {
    local exit_code=$?
    log_info "执行清理操作..."
    
    # 清理临时文件
    if [[ -n "${TEMP_FILES:-}" ]]; then
        for temp_file in $TEMP_FILES; do
            if [[ -f "$temp_file" ]]; then
                rm -f "$temp_file"
                log_debug "已清理临时文件: $temp_file"
            fi
        done
    fi
    
    # 恢复信号处理
    trap - EXIT INT TERM
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "脚本异常退出，退出码: $exit_code"
    fi
    
    exit $exit_code
}

# 设置信号处理
trap cleanup EXIT INT TERM

# 初始化日志
log_info "脚本开始执行: $(basename "${BASH_SOURCE[0]}")"
log_info "工作目录: $SCRIPT_DIR"
log_info "模块目录: $MODULES_DIR"
