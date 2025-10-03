#!/bin/bash

# 统一错误管理模块
# 提供标准化的错误处理、错误分类和恢复机制

# 错误分类定义
declare -A ERROR_TYPES=(
    ["PERMISSION"]="权限相关错误"
    ["NETWORK"]="网络相关错误"  
    ["CONFIG"]="配置相关错误"
    ["SYSTEM"]="系统相关错误"
    ["VALIDATION"]="验证相关错误"
    ["SECURITY"]="安全相关错误"
)

# 错误恢复策略
declare -A RECOVERY_STRATEGIES=(
    ["PERMISSION"]="check_root; check_permissions"
    ["NETWORK"]="restart_network_services; check_connectivity"
    ["CONFIG"]="validate_config; restore_backup"
    ["SYSTEM"]="check_system_resources; restart_services"
    ["VALIDATION"]="validate_inputs; sanitize_data"
    ["SECURITY"]="security_scan; fix_vulnerabilities"
)

# 统一错误处理函数
unified_error_handler() {
    local error_code="$1"
    local error_message="$2"
    local error_type="${3:-SYSTEM}"
    local context="${4:-unknown}"
    local recovery_attempts="${5:-3}"
    
    # 记录错误信息
    log_error_unified "$error_code" "$error_message" "$error_type" "$context"
    
    # 记录错误统计
    ((IPV6WGM_ERROR_STATS["${error_type}_count"]++))
    ((IPV6WGM_ERROR_STATS["total_count"]++))
    
    # 尝试自动恢复
    if [[ "$recovery_attempts" -gt 0 ]]; then
        attempt_error_recovery "$error_type" "$error_message" "$context" "$recovery_attempts"
    fi
    
    # 生成错误报告
    generate_error_report "$error_type" "$error_message" "$context"
    
    return "$error_code"
}

# 记录统一错误信息
log_error_unified() {
    local code="$1"
    local message="$2"
    local type="$3"
    local context="$4"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local sanitized_message=$(sanitize_log_message "$message")
    
    # 输出到控制台
    printf "[%s] [%s] [%s] %s (上下文: %s)\n" \
        "$timestamp" "$type" "$code" "$sanitized_message" "$context"
    
    # 写入错误日志
    local error_log="${IPV6WGM_LOG_DIR}/errors_${type,,}.log"
    echo "[$timestamp] [$code] $sanitized_message (上下文: $context)" >> "$error_log" 2>/dev/null
}

# 尝试错误恢复
attempt_error_recovery() {
    local error_type="$1"
    local error_message="$2"
    local context="$3"
    local attempts="$4"
    
    log_info "尝试自动恢复 $error_type 类型错误 (剩余尝试次数: $attempts)"
    
    # 获取恢复策略
    local strategy="${RECOVERY_STRATEGIES[$error_type]}"
    
    if [[ -n "$strategy" ]]; then
        # 执行恢复策略
        if safe_execute_command "$strategy" >/dev/null 2>&1; then
            log_success "$error_type 类型错误自动恢复成功"
            return 0
        else
            log_warn "$error_type 类型错误自动恢复失败"
            
            # 减少尝试次数并递归重试
            if [[ $attempts -gt 1 ]]; then
                sleep 2
                attempt_error_recovery "$error_type" "$error_message" "$context" $((attempts - 1))
            else
                log_error "$error_type 类型错误自动恢复最终失败，需要人工干预"
            fi
        fi
    else
        log_warn "未找到 $error_type 类型的自动恢复策略"
    fi
    
    return 1
}

# 生成错误报告
generate_error_report() {
    local error_type="$1"
    local error_message="$2"
    local context="$3"
    local report_file="${IPV6WGM_LOG_DIR}/error_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=== IPv6 WireGuard Manager 错误报告 ===="
        echo "生成时间: $(date)"
        echo "错误类型: $error_type"
        echo "错误消息: $(sanitize_log_message "$error_message")"
        echo "错误上下文: $context"
        echo
        
        echo "=== 错误统计 ==="
        echo "总错误数: ${IPV6WGM_ERROR_STATS[total_count]:-0}"
        echo "权限错误: ${IPV6WGM_ERROR_STATS[PERMISSION_count]:-0}"
        echo "网络错误: ${IPV6WGM_ERROR_STATS[NETWORK_count]:-0}"
        echo "配置错误: ${IPV6WGM_ERROR_STATS[CONFIG_count]:-0}"
        echo "系统错误: ${IPV6WGM_ERROR_STATS[SYSTEM_count]:-0}"
        echo "验证错误: ${IPV6WGM_ERROR_STATS[VALIDATION_count]:-0}"
        echo "安全错误: ${IPV6WGM_ERROR_STATS[SECURITY_count]:-0}"
        echo
        
        echo "=== 恢复建议 ==="
        echo "错误类型: ${ERROR_TYPES[$error_type]}"
        echo "建议操作: ${RECOVERY_STRATEGIES[$error_type]}"
        
    } > "$report_file"
    
    log_info "错误报告已生成: $report_file"
}

# 初始化错误管理系统
init_error_management() {
    # 初始化错误统计
    declare -g -A IPV6WGM_ERROR_STATS=(
        ["total_count"]=0
        ["PERMISSION_count"]=0
        ["NETWORK_count"]=0
        ["CONFIG_count"]=0
        ["SYSTEM_count"]=0
        ["VALIDATION_count"]=0
        ["SECURITY_count"]=0
    )
    
    # 创建错误日志目录
    mkdir -p "${IPV6WGM_LOG_DIR}/errors"
    
    log_info "统一错误管理系统已初始化"
}

# 清理过期错误日志
cleanup_error_logs() {
    local retention_days="${ERROR_LOG_RETENTION_DAYS:-7}"
    local error_log_dir="${IPV6WGM_LOG_DIR}/errors"
    
    if [[ -d "$error_log_dir" ]]; then
        find "$error_log_dir" -name "*.log" -mtime +$retention_days -delete 2>/dev/null
        log_info "清理了 $retention_days 天前的错误日志"
    fi
}

# 错误监控和分析
monitor_error_patterns() {
    local error_log="${IPV6WGM_LOG_DIR}/errors/combined.log"
    
    # 合并所有错误日志
    cat "${IPV6WGM_LOG_DIR}"/errors_*.log 2>/dev/null | sort > "$error_log"
    
    # 分析常见错误模式
    local top_errors=$(awk '{count[$0]++} END {for (error in count) print count[error], error}' "$error_log" | sort -nr | head -10)
    
    if [[ -n "$top_errors" ]]; then
        log_info "=== 常见错误模式分析 ==="
        echo "$top_errors"
    fi
}

# 导出函数
export -f unified_error_handler log_error_unified attempt_error_recovery 
export -f generate_error_report init_error_management cleanup_error_logs monitor_error_patterns
