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
)

# 加载性能配置
load_performance_config() {
    for config_line in "${PERFORMANCE_CONFIG[@]}"; do
        local key="${config_line%%=*}"
        local value="${config_line##*=}"
        export "$key"="$value"
    done
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
