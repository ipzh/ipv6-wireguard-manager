#!/bin/bash

# ================================================================
# 性能监控模块 - 实时系统性能监控和优化
# ================================================================

# 性能监控配置
PERFORMANCE_CONFIG=(
    "CPU_THRESHOLD=80"
    "MEMORY_THRESHOLD=85"
    "DISK_THRESHOLD=90"
    "NETWORK_THRESHOLD=1000000"
    "CHECK_INTERVAL=60"
    "AUTO_OPTIMIZE=true"
    "OPTIMIZATION_LEVEL=moderate"
    "PERFORMANCE_LOG_FILE=${LOG_DIR}/performance.log"
    "OPTIMIZATION_HISTORY_FILE=${CONFIG_DIR}/optimization_history.json"
)

# 性能统计数据
declare -A PERFORMANCE_STATS=(
    ["cpu_usage"]=0
    ["memory_usage"]=0
    ["disk_usage"]=0
    ["network_rx"]=0
    ["network_tx"]=0
    ["cache_hits"]=0
    ["cache_misses"]=0
    ["module_load_time"]=0
    ["optimization_count"]=0
)

# 自动优化规则
declare -A OPTIMIZATION_RULES=(
    ["high_cpu"]="clear_cache restart_lazy_loading"
    ["high_memory"]="gc_collect clear_cache optimize_memory"
    ["high_disk"]="cleanup_temp_files compress_logs"
    ["low_performance"]="enable_performance_mode disable_debug_logging"
)

# 加载性能配置
load_performance_config() {
    for config_line in "${PERFORMANCE_CONFIG[@]}"; do
        local key="${config_line%%=*}"
        local value="${config_line##*=}"
        export "$key"="$value"
    done

    # 创建性能日志目录
    mkdir -p "$(dirname "$PERFORMANCE_LOG_FILE")" 2>/dev/null || true
    mkdir -p "$(dirname "$OPTIMIZATION_HISTORY_FILE")" 2>/dev/null || true
}

# 自动性能优化
auto_optimize_performance() {
    log_info "开始自动性能优化..."

    local optimizations_performed=0
    local optimization_log=""

    # 检查各项性能指标并应用优化
    if ! monitor_cpu_usage; then
        optimization_log+="CPU优化已应用; "
        ((optimizations_performed++))
    fi

    if ! monitor_memory_usage; then
        optimization_log+="内存优化已应用; "
        ((optimizations_performed++))
    fi

    if ! monitor_disk_usage; then
        optimization_log+="磁盘优化已应用; "
        ((optimizations_performed++))
    fi

    if ! monitor_network_usage; then
        optimization_log+="网络优化已应用; "
        ((optimizations_performed++))
    fi

    # 记录优化历史
    if [[ $optimizations_performed -gt 0 ]]; then
        record_optimization "$optimizations_performed" "$optimization_log"
        log_success "自动性能优化完成: $optimizations_performed 项优化"
    else
        log_info "系统性能正常，无需优化"
    fi

    return $optimizations_performed
}

# 执行特定优化操作
execute_optimization() {
    local optimization_type="$1"
    local actions="${OPTIMIZATION_RULES[$optimization_type]}"

    if [[ -z "$actions" ]]; then
        log_warn "未知的优化类型: $optimization_type"
        return 1
    fi

    log_info "执行优化: $optimization_type"

    for action in $actions; do
        case "$action" in
            "clear_cache")
                if command -v clear_all_cache >/dev/null 2>&1; then
                    clear_all_cache
                    log_debug "清除缓存完成"
                elif command -v cache_clear >/dev/null 2>&1; then
                    cache_clear
                    log_debug "清除缓存完成"
                fi
                ;;
            "restart_lazy_loading")
                # 重启懒加载机制
                if command -v restart_lazy_loading >/dev/null 2>&1; then
                    restart_lazy_loading
                fi
                ;;
            "gc_collect")
                # 垃圾回收
                if command -v garbage_collect >/dev/null 2>&1; then
                    garbage_collect
                fi
                ;;
            "optimize_memory")
                if command -v optimize_memory_usage >/dev/null 2>&1; then
                    optimize_memory_usage
                fi
                ;;
            "cleanup_temp_files")
                # 清理临时文件
                find /tmp -type f -name "ipv6wgm_*" -mtime +1 -delete 2>/dev/null || true
                ;;
            "compress_logs")
                # 压缩旧日志
                find "$LOG_DIR" -name "*.log" -mtime +7 -exec gzip {} \; 2>/dev/null || true
                ;;
            "enable_performance_mode")
                export IPV6WGM_PERFORMANCE_MODE=true
                ;;
            "disable_debug_logging")
                export LOG_LEVEL=WARN
                ;;
            *)
                log_warn "未知的优化操作: $action"
                ;;
        esac
    done

    return 0
}

# 记录优化历史
record_optimization() {
    local optimizations_count="$1"
    local optimization_details="$2"

    local history_entry=$(cat << EOF
{
    "timestamp": "$(date -Iseconds)",
    "optimizations_count": $optimizations_count,
    "details": "$optimization_details",
    "system_metrics": {
        "cpu_usage": "${PERFORMANCE_STATS[cpu_usage]}",
        "memory_usage": "${PERFORMANCE_STATS[memory_usage]}",
        "cache_hits": "${PERFORMANCE_STATS[cache_hits]}",
        "cache_misses": "${PERFORMANCE_STATS[cache_misses]}"
    }
}
EOF
    )

    # 追加到历史文件
    if [[ -f "$OPTIMIZATION_HISTORY_FILE" ]]; then
        # 使用jq追加记录（如果可用）
        if command -v jq >/dev/null 2>&1; then
            jq --argjson entry "$history_entry" '.optimizations += [$entry]' "$OPTIMIZATION_HISTORY_FILE" > "${OPTIMIZATION_HISTORY_FILE}.tmp" && mv "${OPTIMIZATION_HISTORY_FILE}.tmp" "$OPTIMIZATION_HISTORY_FILE"
        else
            # 简单追加
            echo "$history_entry" >> "$OPTIMIZATION_HISTORY_FILE"
        fi
    else
        # 创建新文件
        echo '{
    "optimizations": [
        '"$history_entry"'
    ]
}' > "$OPTIMIZATION_HISTORY_FILE"
    fi

    PERFORMANCE_STATS[optimization_count]=$((PERFORMANCE_STATS[optimization_count] + optimizations_performed))
}

# CPU使用率监控
monitor_cpu_usage() {
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100-$1}')
    cpu_usage=${cpu_usage%.*}  # 转换为整数
    
    if [[ $cpu_usage -gt $CPU_THRESHOLD ]]; then
        log_warn "CPU使用率过高: ${cpu_usage}% (阈值: ${CPU_THRESHOLD}%)"
        return 1
    fi
    
    log_debug "CPU使用率正常: ${cpu_usage}%"
    return 0
}

# 内存使用监控
monitor_memory_usage() {
    local memory_usage
    memory_usage=$(free | grep Mem | awk '{printf "%.0f", ($3/$2)*100}')
    
    if [[ $memory_usage -gt $MEMORY_THRESHOLD ]]; then
        log_warn "内存使用率过高: ${memory_usage}% (阈值: ${MEMORY_THRESHOLD}%)"
        return 1
    fi
    
    log_debug "内存使用率正常: ${memory_usage}%"
    return 0
}

# 磁盘使用监控
monitor_disk_usage() {
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [[ $disk_usage -gt $DISK_THRESHOLD ]]; then
        log_warn "磁盘使用率过高: ${disk_usage}% (阈值: ${DISK_THRESHOLD}%)"
        return 1
    fi
    
    log_debug "磁盘使用率正常: ${disk_usage}%"
    return 0
}

# 网络流量监控
monitor_network_traffic() {
    local net_trans current_time
    
    # 获取当前时间
    current_time=$(date +%s)
    
    # 获取网络统计
    if [[ -f /proc/net/dev ]]; then
        net_trans=$(cat /proc/net/dev | while read line; do
            if [[ "$line" =~ ^[[:space:]]*[a-zA-Z0-9:]+[[:space:]]+[0-9]+ ]]; then
                echo "$line" | awk '{print $2+$10}'
            fi
        done | paste -sd+ | bc)
        
        # 检查是否超出阈值
        if [[ $net_trans -gt $NETWORK_THRESHOLD ]]; then
            log_warn "网络流量异常: ${net_trans} 字节"
            return 1
        fi
        
        log_debug "网络流量正常: ${net_trans} 字节"
    fi
    
    return 0
}

# WireGuard连接监控
monitor_wireguard_connections() {
    local interface="$1"
    if [[ -z "$interface" ]]; then
        interface="wg0"  # 默认接口
    fi
    
    # 检查WireGuard接口状态
    if wg show "$interface" &>/dev/null; then
        local peer_count
        peer_count=$(wg show "$interface" | grep -c "peer:")
        
        log_debug "WireGuard接口 $interface 连接正常，对等节点数量: $peer_count"
        return 0
    else
        log_error "WireGuard接口 $interface 未运行"
        return 1
    fi
}

# 系统资源优化建议
get_optimization_suggestions() {
    local suggestions=()
    
    # 检查内存使用
    if ! monitor_memory_usage; then
        suggestions+=("清理内存缓存: sync && echo 3 > /proc/sys/vm/drop_caches")
        suggestions+=("重启内存密集型服务")
    fic
    
    # 检查CPU使用
    if ! monitor_cpu_usage; then
        suggestions+=("关闭不必要的服务")
        suggestions+=("优化CPU密集型任务")
    fi
    
    # 检查磁盘使用
    if ! monitor_disk_usage; then
        suggestions+=("清理临时文件")
        suggestions+=:"清理日志文件")
        suggestions+=("清理缓存文件")
    fi
    
    # 返回建议
    printf '%s\n' "${suggestions[@]}"
}

# 自动优化系统
auto_optimize_system() {
    log_info "开始自动系统优化..."
    
    local optimizations=(
        "sync"
        "echo 3 > /proc/sys/vm/drop_caches"
        "find /tmp -type f -atime +7 -delete"
        "find /var/log -name \"*.log\" -mtime +30 -delete"
    )
    
    for optimization in "${optimizations[@]}"; do
        if safe_execute_command "$optimization"; then
            log_debug "优化命令执行成功: ${optimization}"
        else
            log_warn "优化命令执行失败: ${optimization}"
        fi
    done
    
    log_success "自动系统优化完成"
}

# 性能报告生成
generate_performance_report() {
    local report_file="/tmp/ipv6-wg-performance-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "=== IPv6-WireGuard 性能监控报告 ==="
        echo "生成时间: $(date)"
        echo "系统信息: $(uname -a)"
        echo
        
        echo "=== CPU 信息 ==="
        cat /proc/cpuinfo | grep -E "processor|model|cpu MHZ"
        echo
        
        echo "=== 内存信息 ==="
        free -h
        echo
        
        echo "=== 磁盘使用 ==="
        df -h
        echo
        
        echo "=== 网络状态 ==="
        ip addr show
        echo
        
        echo "=== WireGuard状态 ==="
        wg show 2>/dev/null || echo "WireGuard未运行"
        echo
        
        echo "=== 系统负载 ==="
        uptime
        echo
        
        echo "=== 运行中的服务 ==="
        systemctl list-units --type=service --state=running | grep -E "(wireguard|bird)"
        
    } > "$report_file"
    
    log_success "性能报告已生成: $report_file"
    echo "$report_file"
}

# 启动性能监控
start_performance_monitoring() {
    load_performance_config
    
    log_info "启动性能监控系统 (间隔: ${CHECK_INTERVAL}秒)"
    
    while true; do
        monitor_cpu_usage
        monitor_memory_usage
        monitor_disk_usage
        monitor_network_traffic
        monitor_wireguard_connections
        
        sleep "$CHECK_INTERVAL"
    done
}

# 导出函数
export -f monitor_cpu_usage monitor_memory_usage monitor_disk_usage
export -f monitor_network_traffic monitor_wireguard_connections
export -f get_optimization_suggestions auto_optimize_system
export -f generate_performance_report start_performance_monitoring
export -f load_performance_config

# 函数别名
alias cpu_check=monitor_cpu_usage
alias mem_check=monitor_memory_usage
alias disk_check=monitor_disk_usage
alias net_check=monitor_network_traffic
alias perf_report=generate_performance_report
alias auto_optimize=auto_optimize_system
