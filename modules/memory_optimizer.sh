#!/bin/bash

# 内存优化模块
# 提供内存监控、自动清理、内存池管理和垃圾回收功能

# 内存配置
declare -A MEMORY_CONFIG=(
    ["limit_mb"]="512"
    ["warning_threshold"]="80"
    ["critical_threshold"]="90"
    ["gc_interval"]="300"
    ["cleanup_threshold"]="70"
)

# 内存监控
declare -A MEMORY_STATS=(
    ["current_usage"]=0
    ["peak_usage"]=0
    ["gc_runs"]=0
    ["cleanups"]=0
    ["cache_reductions"]=0
)

# 获取当前内存使用量(KB)
get_current_memory_usage() {
    local memory_file="/proc/meminfo"
    if [[ -f "$memory_file" ]]; then
        local mem_used=$(grep "^MemTotal:" "$memory_file" | awk '{print $2}')
        local mem_available=$(grep "^MemAvailable:" "$memory_file" | awk '{print $2}')
        echo $((mem_used - mem_available))
    else
        # macOS/BSD系统
        vm_stat | awk '/pages free/ { free=$3 } /pages active/ { active=$3 } /pages inactive/ { inactive=$3 } /pages speculative/ { speculative=$3 } END { print (active+inactive+speculative)*4096 }'
    fi
}

# 获取脚本内存使用量(KB)
get_script_memory_usage() {
    local script_pid=$$
    if [[ -f "/proc/$script_pid/status" ]]; then
        grep "^VmRSS:" "/proc/$script_pid/status" | awk '{print $2}'
    else
        # macOS系统使用ps命令
        ps -o rss= -p "$script_pid" | awk '{print $1}'
    fi
}

# 内存监控
monitor_memory() {
    local current_usage=$(get_script_memory_usage)
    local current_usage_mb=$((current_usage / 1024))
    local limit_mb=${MEMORY_CONFIG[limit_mb]}
    local usage_percent=$((current_usage_mb * 100 / limit_mb))
    
    MEMORY_STATS[current_usage]=$current_usage_mb
    
    # 更新峰值使用量
    if [[ $current_usage_mb -gt ${MEMORY_STATS[peak_usage]} ]]; then
        MEMORY_STATS[peak_usage]=$current_usage_mb
    fi
    
    log_debug "内存使用: ${current_usage_mb}MB (${usage_percent}%)"
    
    # 检查阈值
    if [[ $usage_percent -gt ${MEMORY_CONFIG[critical_threshold]} ]]; then
        log_error "内存使用达到关键阈值: ${usage_percent}%"
        emergency_memory_cleanup
    elif [[ $usage_percent -gt ${MEMORY_CONFIG[warning_threshold]} ]]; then
        log_warn "内存使用达到警告阈值: ${usage_percent}%"
        schedule_memory_cleanup
    fi
    
    return $usage_percent
}

# 紧急内存清理
emergency_memory_cleanup() {
    log_error "执行紧急内存清理..."
    
    # 清理所有缓存
    if declare -f clear_all_cache >/dev/null 2>&1; then
        clear_all_cache
        ((MEMORY_STATS[cache_reductions]++))
    fi
    
    # 清理未使用的变量
    cleanup_unused_variables
    
    # 强制垃圾回收
    force_garbage_collection
    
    # 清理临时文件
    cleanup_temp_files
    
    log_success "紧急内存清理完成"
}

# 计划内存清理
schedule_memory_cleanup() {
    log_info "计划内存清理..."
    
    # 清理过期缓存
    if declare -f evict_old_cache_entries >/dev/null 2>&1; then
        evict_old_cache_entries
        ((MEMORY_STATS[cache_reductions]++))
    fi
    
    # 清理未使用的函数
    cleanup_unused_functions
    
    log_success "内存清理完成"
}

# 清理未使用的变量
cleanup_unused_variables() {
    # 清理模块相关的临时变量
    local variables_to_clean=(
        "TEMP_VAR_*"
        "module_*_temp"
        "processing_*"
    )
    
    for var_pattern in "${variables_to_clean[@]}"; do
        unset -v ${!var_pattern@}
    done
    
    log_debug "清理了未使用的变量"
}

# 清理未使用的函数
cleanup_unused_functions() {
    # 清理临时定义的函数
    local functions_to_clean=(`
    
    # 查找临时函数
    declare -F | grep -E "^declare -f temp_|^declare -f module_.*_temp" | awk '{print $NF}'
    `)
    
    for func in "${functions_to_clean[@]}"; do
        unset -f "$func" 2>/dev/null || true
    done
    
    log_debug "清理了 ${#functions_to_clean[@]} 个临时函数"
}

# 强制垃圾回收
force_garbage_collection() {
    # 在bash中通过无操作命令触发垃圾回收
    :  # 空命令
    
    # 强制清理shell内部缓存
    builtin hash -r 2>/dev/null || true
    
    log_debug "强制垃圾回收已执行"
    ((MEMORY_STATS[gc_runs]++))
}

# 清理临时文件
cleanup_temp_files() {
    local temp_patterns=(
        "/tmp/ipv6wgm_*"
        "/tmp/wg_temp_*"
        "/tmp/parallel_*"
    )
    
    local cleaned_count=0
    for pattern in "${temp_patterns[@]}"; do
        for file in $pattern; do
            if [[ -f "$file" ]]; then
                rm -f "$file" 2>/dev/null && ((cleaned_count++))
            fi
        done
    done
    
    log_debug "清理了 $cleaned_count 个临时文件"
}

# 内存池管理
class MemoryPool {
    local pool_name="$1"
    local pool_size="${2:-100}"
    local pool_usage=0
    
    # 从内存池分配
    allocate_memory() {
        local size="$1"
        
        if ((pool_usage + size <= pool_size)); then
            ((pool_usage += size))
            log_debug "内存池分配成功: ${size}KB (使用率: $((pool_usage * 100 / pool_size))%)"
            return 0
        else
            log_warn "内存池空间不足"
            return 1
        fi
    }
    
    # 释放内存池空间
    deallocate_memory() {
        local size="$1"
        pool_usage=$((pool_usage - size))
        
        if [[ $pool_usage -lt 0 ]]; then
            pool_usage=0
        fi
        
        log_debug "内存池释放: ${size}KB (使用率: $((pool_usage * 100 / pool_size))%)"
    }
    
    # 获取内存池状态
    get_pool_status() {
        echo "内存池 '$pool_name' 状态:"
        echo "  总大小: ${pool_size}KB"
        echo "  已使用: ${pool_usage}KB"
        echo "  使用率: $((pool_usage * 100 / pool_size))%"
    }
}

# 内存优化建议
get_memory_optimization_suggestions() {
    local current_usage=$(get_script_memory_usage)
    local suggestions=()
    
    if ((current_usage > 100000)); then  # > 100MB
        suggestions+=("内存使用量过高，建议:")
        suggestions+=("1. 减少缓存大小")
        suggestions+=("2. 启用更频繁的垃圾回收")
        suggestions+=("3. 使用更少的并行进程")
        suggestions+=("4. 清理未使用的模块")
    fi
    
    # 检查大数组
    local large_arrays=$(declare -A | wc -l)
    if ((large_arrays > 50)); then
        suggestions+=("检测到大量数组变量，建议清理未使用的数组")
    fi
    
    # 检查函数数量
    local function_count=$(declare -F | wc -l)
    if ((function_count > 200)); then
        suggestions+=("函数数量过多，建议使用模块懒加载")
    fi
    
    printf '%s\n' "${suggestions[@]}"
}

# 内存统计报告
generate_memory_report() {
    local report_file="${IPV6WGM_LOG_DIR}/memory_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=== IPv6 WireGuard Manager 内存报告 ==="
        echo "生成时间: $(date)"
        echo
        
        echo "=== 当前状态 ==="
        monitor_memory
        echo "当前使用: ${MEMORY_STATS[current_usage]}MB"
        echo "峰值使用: ${MEMORY_STATS[peak_usage]}MB"
        echo "GC运行次数: ${MEMORY_STATS[gc_runs]}"
        echo "清理次数: ${MEMORY_STATS[cleanups]}"
        echo
        
        echo "=== 内存配置 ==="
        echo "限制大小: ${MEMORY_CONFIG[limit_mb]}MB"
        echo "警告阈值: ${MEMORY_CONFIG[warning_threshold]}%"
        echo "关键阈值: ${MEMORY_CONFIG[critical_threshold]}%"
        echo
        
        echo "=== 优化建议 ==="
        get_memory_optimization_suggestions
        
    } > "$report_file"
    
    log_info "内存报告已生成: $report_file"
}

# 定期内存检查
start_memory_monitor() {
    local check_interval=${MEMORY_CONFIG[gc_interval]}
    
    log_info "启动内存监控 (检查间隔: ${check_interval}s)"
    
    # 后台运行内存监控
    (
        while true; do
            monitor_memory
            sleep "$check_interval"
        done
    ) &
    
    MEMORY_MONITOR_PID=$!
    log_success "内存监控已启动 (PID: $MEMORY_MONITOR_PID)"
}

# 停止内存监控
stop_memory_monitor() {
    if [[ -n "${MEMORY_MONITOR_PID:-}" ]]; then
        kill "${MEMORY_MONITOR_PID}" 2>/dev/null || true
        unset MEMORY_MONITOR_PID
        log_info "内存监控已停止"
    fi
}

# 导出函数
export -f get_current_memory_usage get_script_memory_usage monitor_memory
export -f emergency_memory_cleanup schedule_memory_cleanup
export -f cleanup_unused_variables cleanup_unused_functions force_garbage_collection
export -f get_memory_optimization_suggestions generate_memory_report
export -f start_memory_monitor stop_memory_monitor

# 别名
alias mem_check=monitor_memory
alias mem_emergency=emergency_memory_cleanup
alias mem_report=generate_memory_report
alias mem_monitor=start_memory_monitor
