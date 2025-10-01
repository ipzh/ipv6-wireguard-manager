#!/bin/bash

# 统一错误处理模块
# 提供标准化的错误处理、日志记录和异常管理功能

# 导入公共函数
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
fi

# =============================================================================
# 错误处理配置
# =============================================================================

# 错误级别定义
declare -g IPV6WGM_ERROR_LEVEL_DEBUG=0
declare -g IPV6WGM_ERROR_LEVEL_INFO=1
declare -g IPV6WGM_ERROR_LEVEL_WARNING=2
declare -g IPV6WGM_ERROR_LEVEL_ERROR=3
declare -g IPV6WGM_ERROR_LEVEL_FATAL=4

# 错误代码定义
declare -A IPV6WGM_ERROR_CODES=(
    ["SUCCESS"]=0
    ["GENERAL_ERROR"]=1
    ["PERMISSION_DENIED"]=2
    ["FILE_NOT_FOUND"]=3
    ["DIRECTORY_NOT_FOUND"]=4
    ["INVALID_ARGUMENT"]=5
    ["CONFIGURATION_ERROR"]=6
    ["NETWORK_ERROR"]=7
    ["DEPENDENCY_MISSING"]=8
    ["VALIDATION_FAILED"]=9
    ["OPERATION_FAILED"]=10
    ["TIMEOUT"]=11
    ["RESOURCE_EXHAUSTED"]=12
    ["UNKNOWN_ERROR"]=99
)

# 错误统计
declare -A IPV6WGM_ERROR_STATS=(
    ["total_errors"]=0
    ["debug_count"]=0
    ["info_count"]=0
    ["warning_count"]=0
    ["error_count"]=0
    ["fatal_count"]=0
)

# 错误日志文件
declare -g IPV6WGM_ERROR_LOG_FILE="${IPV6WGM_LOG_DIR}/error.log"
declare -g IPV6WGM_ERROR_STATS_FILE="${IPV6WGM_LOG_DIR}/error_stats.json"

# =============================================================================
# 错误处理函数
# =============================================================================

# 记录错误
log_error_event() {
    local level="$1"
    local error_code="$2"
    local message="$3"
    local context="${4:-}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 更新错误统计
    case "$level" in
        "DEBUG") IPV6WGM_ERROR_STATS["debug_count"]=$((IPV6WGM_ERROR_STATS["debug_count"] + 1)) ;;
        "INFO") IPV6WGM_ERROR_STATS["info_count"]=$((IPV6WGM_ERROR_STATS["info_count"] + 1)) ;;
        "WARNING") IPV6WGM_ERROR_STATS["warning_count"]=$((IPV6WGM_ERROR_STATS["warning_count"] + 1)) ;;
        "ERROR") IPV6WGM_ERROR_STATS["error_count"]=$((IPV6WGM_ERROR_STATS["error_count"] + 1)) ;;
        "FATAL") IPV6WGM_ERROR_STATS["fatal_count"]=$((IPV6WGM_ERROR_STATS["fatal_count"] + 1)) ;;
    esac
    
    IPV6WGM_ERROR_STATS["total_errors"]=$((IPV6WGM_ERROR_STATS["total_errors"] + 1))
    
    # 格式化错误消息
    local formatted_message="[$timestamp] [$level] [$error_code] $message"
    if [[ -n "$context" ]]; then
        formatted_message="$formatted_message (上下文: $context)"
    fi
    
    # 输出到控制台
    case "$level" in
        "DEBUG") log_debug "$message" ;;
        "INFO") log_info "$message" ;;
        "WARNING") log_warning "$message" ;;
        "ERROR") log_error "$message" ;;
        "FATAL") log_fatal "$message" ;;
    esac
    
    # 记录到错误日志文件
    echo "$formatted_message" >> "$IPV6WGM_ERROR_LOG_FILE"
    
    # 如果是致命错误，立即退出
    if [[ "$level" == "FATAL" ]]; then
        exit "${IPV6WGM_ERROR_CODES[$error_code]:-99}"
    fi
}

# 处理文件操作错误
handle_file_error() {
    local operation="$1"
    local file_path="$2"
    local error_code="$3"
    
    case "$error_code" in
        "ENOENT")
            log_error_event "ERROR" "FILE_NOT_FOUND" "文件不存在: $file_path" "操作: $operation"
            ;;
        "EACCES")
            log_error_event "ERROR" "PERMISSION_DENIED" "权限不足，无法访问文件: $file_path" "操作: $operation"
            ;;
        "ENOSPC")
            log_error_event "ERROR" "RESOURCE_EXHAUSTED" "磁盘空间不足: $file_path" "操作: $operation"
            ;;
        "EISDIR")
            log_error_event "ERROR" "INVALID_ARGUMENT" "路径是目录，不是文件: $file_path" "操作: $operation"
            ;;
        *)
            log_error_event "ERROR" "OPERATION_FAILED" "文件操作失败: $operation $file_path" "错误代码: $error_code"
            ;;
    esac
}

# 处理网络操作错误
handle_network_error() {
    local operation="$1"
    local target="$2"
    local error_code="$3"
    
    case "$error_code" in
        "ECONNREFUSED")
            log_error_event "ERROR" "NETWORK_ERROR" "连接被拒绝: $target" "操作: $operation"
            ;;
        "ETIMEDOUT")
            log_error_event "ERROR" "TIMEOUT" "网络超时: $target" "操作: $operation"
            ;;
        "ENETUNREACH")
            log_error_event "ERROR" "NETWORK_ERROR" "网络不可达: $target" "操作: $operation"
            ;;
        "EHOSTUNREACH")
            log_error_event "ERROR" "NETWORK_ERROR" "主机不可达: $target" "操作: $operation"
            ;;
        *)
            log_error_event "ERROR" "NETWORK_ERROR" "网络操作失败: $operation $target" "错误代码: $error_code"
            ;;
    esac
}

# 处理配置错误
handle_config_error() {
    local config_file="$1"
    local error_type="$2"
    local details="$3"
    
    case "$error_type" in
        "syntax")
            log_error_event "ERROR" "CONFIGURATION_ERROR" "配置文件语法错误: $config_file" "详情: $details"
            ;;
        "validation")
            log_error_event "ERROR" "VALIDATION_FAILED" "配置验证失败: $config_file" "详情: $details"
            ;;
        "missing")
            log_error_event "ERROR" "CONFIGURATION_ERROR" "配置文件缺失: $config_file" "详情: $details"
            ;;
        "permission")
            log_error_event "ERROR" "PERMISSION_DENIED" "配置文件权限不足: $config_file" "详情: $details"
            ;;
        *)
            log_error_event "ERROR" "CONFIGURATION_ERROR" "配置错误: $config_file" "类型: $error_type, 详情: $details"
            ;;
    esac
}

# 处理依赖项错误
handle_dependency_error() {
    local dependency="$1"
    local error_type="$2"
    local details="$3"
    
    case "$error_type" in
        "missing")
            log_error_event "ERROR" "DEPENDENCY_MISSING" "依赖项缺失: $dependency" "详情: $details"
            ;;
        "version")
            log_error_event "ERROR" "DEPENDENCY_MISSING" "依赖项版本不兼容: $dependency" "详情: $details"
            ;;
        "installation")
            log_error_event "ERROR" "OPERATION_FAILED" "依赖项安装失败: $dependency" "详情: $details"
            ;;
        *)
            log_error_event "ERROR" "DEPENDENCY_MISSING" "依赖项错误: $dependency" "类型: $error_type, 详情: $details"
            ;;
    esac
}

# =============================================================================
# 异常处理函数
# =============================================================================

# 设置错误陷阱
set_error_trap() {
    local script_name="${1:-$(basename "$0")}"
    
    # 设置退出陷阱
    trap 'handle_script_exit "$script_name" $?' EXIT
    
    # 设置错误陷阱
    trap 'handle_script_error "$script_name" $? $LINENO' ERR
    
    # 设置中断陷阱
    trap 'handle_script_interrupt "$script_name"' INT TERM
}

# 处理脚本退出
handle_script_exit() {
    local script_name="$1"
    local exit_code="$2"
    
    if [[ $exit_code -ne 0 ]]; then
        log_error_event "ERROR" "OPERATION_FAILED" "脚本异常退出: $script_name" "退出代码: $exit_code"
    else
        log_error_event "INFO" "SUCCESS" "脚本正常退出: $script_name"
    fi
    
    # 保存错误统计
    save_error_stats
}

# 处理脚本错误
handle_script_error() {
    local script_name="$1"
    local error_code="$2"
    local line_number="$3"
    
    log_error_event "ERROR" "OPERATION_FAILED" "脚本执行错误: $script_name" "行号: $line_number, 错误代码: $error_code"
}

# 处理脚本中断
handle_script_interrupt() {
    local script_name="$1"
    
    log_error_event "WARNING" "OPERATION_FAILED" "脚本被中断: $script_name"
    
    # 清理资源
    cleanup_on_interrupt
}

# 清理中断时的资源
cleanup_on_interrupt() {
    log_info "执行中断清理..."
    
    # 清理临时文件
    if [[ -n "${IPV6WGM_TEMP_DIR:-}" ]] && [[ -d "$IPV6WGM_TEMP_DIR" ]]; then
        rm -rf "$IPV6WGM_TEMP_DIR"
        log_info "已清理临时目录: $IPV6WGM_TEMP_DIR"
    fi
    
    # 停止后台进程
    if [[ -n "${IPV6WGM_BACKGROUND_PIDS:-}" ]]; then
        for pid in "${IPV6WGM_BACKGROUND_PIDS[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null
                log_info "已停止后台进程: $pid"
            fi
        done
    fi
    
    log_info "中断清理完成"
}

# =============================================================================
# 错误恢复函数
# =============================================================================

# 尝试恢复文件操作
recover_file_operation() {
    local operation="$1"
    local file_path="$2"
    local max_retries="${3:-3}"
    
    local retry_count=0
    
    while [[ $retry_count -lt $max_retries ]]; do
        case "$operation" in
            "create")
                if mkdir -p "$(dirname "$file_path")" 2>/dev/null; then
                    log_info "成功创建目录: $(dirname "$file_path")"
                    return 0
                fi
                ;;
            "write")
                if touch "$file_path" 2>/dev/null; then
                    log_info "成功创建文件: $file_path"
                    return 0
                fi
                ;;
            "read")
                if [[ -r "$file_path" ]]; then
                    log_info "文件可读: $file_path"
                    return 0
                fi
                ;;
        esac
        
        retry_count=$((retry_count + 1))
        log_warning "重试 $operation 操作 ($retry_count/$max_retries): $file_path"
        smart_sleep "$IPV6WGM_SLEEP_MEDIUM"
    done
    
    log_error_event "ERROR" "OPERATION_FAILED" "文件操作恢复失败: $operation $file_path" "重试次数: $max_retries"
    return 1
}

# 尝试恢复网络操作
recover_network_operation() {
    local operation="$1"
    local target="$2"
    local max_retries="${3:-3}"
    
    local retry_count=0
    
    while [[ $retry_count -lt $max_retries ]]; do
        case "$operation" in
            "ping")
                if ping -c 1 "$target" &>/dev/null; then
                    log_info "网络连接恢复: $target"
                    return 0
                fi
                ;;
            "curl")
                if curl -s --connect-timeout 5 "$target" &>/dev/null; then
                    log_info "HTTP连接恢复: $target"
                    return 0
                fi
                ;;
            "wget")
                if wget --timeout=5 --tries=1 -q "$target" -O /dev/null 2>/dev/null; then
                    log_info "下载连接恢复: $target"
                    return 0
                fi
                ;;
        esac
        
        retry_count=$((retry_count + 1))
        log_warning "重试 $operation 操作 ($retry_count/$max_retries): $target"
        smart_sleep "$IPV6WGM_SLEEP_LONG"
    done
    
    log_error_event "ERROR" "NETWORK_ERROR" "网络操作恢复失败: $operation $target" "重试次数: $max_retries"
    return 1
}

# =============================================================================
# 错误统计和报告
# =============================================================================

# 保存错误统计
save_error_stats() {
    if [[ -z "$IPV6WGM_ERROR_STATS_FILE" ]]; then
        return 0
    fi
    
    # 确保目录存在
    mkdir -p "$(dirname "$IPV6WGM_ERROR_STATS_FILE")"
    
    # 生成JSON格式的统计
    cat > "$IPV6WGM_ERROR_STATS_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "total_errors": ${IPV6WGM_ERROR_STATS[total_errors]},
  "error_counts": {
    "debug": ${IPV6WGM_ERROR_STATS[debug_count]},
    "info": ${IPV6WGM_ERROR_STATS[info_count]},
    "warning": ${IPV6WGM_ERROR_STATS[warning_count]},
    "error": ${IPV6WGM_ERROR_STATS[error_count]},
    "fatal": ${IPV6WGM_ERROR_STATS[fatal_count]}
  },
  "error_codes": {
EOF
    
    # 添加错误代码统计
    local first=true
    for code in "${!IPV6WGM_ERROR_CODES[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo "," >> "$IPV6WGM_ERROR_STATS_FILE"
        fi
        echo "    \"$code\": ${IPV6WGM_ERROR_CODES[$code]}" >> "$IPV6WGM_ERROR_STATS_FILE"
    done
    
    cat >> "$IPV6WGM_ERROR_STATS_FILE" << EOF
  }
}
EOF
    
    log_debug "错误统计已保存: $IPV6WGM_ERROR_STATS_FILE"
}

# 获取错误统计
get_error_stats() {
    local stat_type="${1:-all}"
    
    case "$stat_type" in
        "total")
            echo "${IPV6WGM_ERROR_STATS[total_errors]}"
            ;;
        "errors")
            echo "${IPV6WGM_ERROR_STATS[error_count]}"
            ;;
        "warnings")
            echo "${IPV6WGM_ERROR_STATS[warning_count]}"
            ;;
        "fatal")
            echo "${IPV6WGM_ERROR_STATS[fatal_count]}"
            ;;
        "all")
            printf '总错误数: %d\n' "${IPV6WGM_ERROR_STATS[total_errors]}"
            printf '错误: %d\n' "${IPV6WGM_ERROR_STATS[error_count]}"
            printf '警告: %d\n' "${IPV6WGM_ERROR_STATS[warning_count]}"
            printf '致命错误: %d\n' "${IPV6WGM_ERROR_STATS[fatal_count]}"
            ;;
    esac
}

# 清除错误统计
clear_error_stats() {
    IPV6WGM_ERROR_STATS=(
        ["total_errors"]=0
        ["debug_count"]=0
        ["info_count"]=0
        ["warning_count"]=0
        ["error_count"]=0
        ["fatal_count"]=0
    )
    
    log_info "错误统计已清除"
}

# =============================================================================
# 导出函数
# =============================================================================

export -f log_error_event
export -f handle_file_error
export -f handle_network_error
export -f handle_config_error
export -f handle_dependency_error
export -f set_error_trap
export -f handle_script_exit
export -f handle_script_error
export -f handle_script_interrupt
export -f cleanup_on_interrupt
export -f recover_file_operation
export -f recover_network_operation
export -f save_error_stats
export -f get_error_stats
export -f clear_error_stats
