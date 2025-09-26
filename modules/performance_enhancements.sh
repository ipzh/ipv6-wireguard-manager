#!/bin/bash
# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
fi

# IPv6 WireGuard Manager 性能优化模块
# 版本: 1.0.0

# 性能监控配置
PERFORMANCE_MONITORING_ENABLED=true
PERFORMANCE_LOG_FILE="/var/log/ipv6-wireguard-manager/performance.log"
PERFORMANCE_THRESHOLD_CPU=80
PERFORMANCE_THRESHOLD_MEMORY=80
PERFORMANCE_THRESHOLD_DISK=90

# 缓存配置
CACHE_ENABLED=true
CACHE_DEFAULT_TTL=300
CACHE_MAX_SIZE=1000

# 性能统计
declare -A PERFORMANCE_STATS
PERFORMANCE_STATS[total_commands]=0
PERFORMANCE_STATS[cached_hits]=0
PERFORMANCE_STATS[cache_misses]=0
PERFORMANCE_STATS[avg_response_time]=0

# 初始化性能优化模块
init_performance_enhancements() {
    log_info "初始化性能优化模块..."
    
    # 创建性能日志目录
    mkdir -p "$(dirname "$PERFORMANCE_LOG_FILE")"
    
    # 检查系统资源
    check_system_resources
    
    # 初始化缓存
    if [[ "$CACHE_ENABLED" == "true" ]]; then
        init_cache_system
    fi
    
    log_success "性能优化模块初始化完成"
}

# 检查系统资源
check_system_resources() {
    log_info "检查系统资源..."
    
    # 检查CPU使用率
    local cpu_usage=$(get_cpu_usage)
    if (( $(echo "$cpu_usage > $PERFORMANCE_THRESHOLD_CPU" | bc -l) )); then
        log_warn "CPU使用率过高: ${cpu_usage}%"
    fi
    
    # 检查内存使用率
    local memory_usage=$(get_memory_usage)
    if (( $(echo "$memory_usage > $PERFORMANCE_THRESHOLD_MEMORY" | bc -l) )); then
        log_warn "内存使用率过高: ${memory_usage}%"
    fi
    
    # 检查磁盘使用率
    local disk_usage=$(get_disk_usage)
    if (( $(echo "$disk_usage > $PERFORMANCE_THRESHOLD_DISK" | bc -l) )); then
        log_warn "磁盘使用率过高: ${disk_usage}%"
    fi
    
    log_success "系统资源检查完成"
}

# 获取CPU使用率
get_cpu_usage() {
    if command -v top &> /dev/null; then
        top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//'
    elif command -v vmstat &> /dev/null; then
        vmstat 1 2 | tail -1 | awk '{print 100-$15}'
    else
        echo "0"
    fi
}

# 获取内存使用率
get_memory_usage() {
    if command -v free &> /dev/null; then
        free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}'
    else
        echo "0"
    fi
}

# 获取磁盘使用率
get_disk_usage() {
    if command -v df &> /dev/null; then
        df / | tail -1 | awk '{print $5}' | sed 's/%//'
    else
        echo "0"
    fi
}

# 初始化缓存系统
init_cache_system() {
    log_info "初始化缓存系统..."
    
    # 清理过期缓存
    cleanup_expired_cache
    
    log_success "缓存系统初始化完成"
}

# 清理过期缓存
cleanup_expired_cache() {
    local current_time=$(date +%s)
    local expired_keys=()
    
    for key in "${!CACHE[@]}"; do
        if [[ "$key" =~ _time$ ]]; then
            local cache_key="${key%_time}"
            local cached_time="${CACHE[$key]}"
            
            if (( current_time - cached_time > CACHE_DEFAULT_TTL )); then
                expired_keys+=("$cache_key" "$key")
            fi
        fi
    done
    
    for key in "${expired_keys[@]}"; do
        unset CACHE["$key"]
    done
    
    if [[ ${#expired_keys[@]} -gt 0 ]]; then
        log_info "清理了 ${#expired_keys[@]} 个过期缓存条目"
    fi
}

# 智能缓存命令
smart_cached_command() {
    local cache_key="$1"
    local command="$2"
    local ttl="${3:-$CACHE_DEFAULT_TTL}"
    local force_refresh="${4:-false}"
    
    # 检查缓存是否启用
    if [[ "$CACHE_ENABLED" != "true" ]]; then
        eval "$command"
        return $?
    fi
    
    # 检查缓存大小限制
    if [[ ${#CACHE[@]} -gt $CACHE_MAX_SIZE ]]; then
        cleanup_expired_cache
    fi
    
    # 强制刷新
    if [[ "$force_refresh" == "true" ]]; then
        unset CACHE["$cache_key"]
        unset CACHE["${cache_key}_time"]
    fi
    
    # 检查缓存
    if [[ -n "${CACHE[$cache_key]}" ]]; then
        local cached_time="${CACHE[${cache_key}_time]}"
        local current_time=$(date +%s)
        
        if (( current_time - cached_time < ttl )); then
            PERFORMANCE_STATS[cached_hits]=$((PERFORMANCE_STATS[cached_hits] + 1))
            log_debug "缓存命中: $cache_key"
            echo "${CACHE[$cache_key]}"
            return 0
        fi
    fi
    
    # 执行命令并缓存结果
    PERFORMANCE_STATS[cache_misses]=$((PERFORMANCE_STATS[cache_misses] + 1))
    PERFORMANCE_STATS[total_commands]=$((PERFORMANCE_STATS[total_commands] + 1))
    
    local start_time=$(date +%s.%N)
    local result
    if result=$(eval "$command" 2>/dev/null); then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l)
        
        # 更新平均响应时间
        update_avg_response_time "$duration"
        
        # 缓存结果
        CACHE["$cache_key"]="$result"
        CACHE["${cache_key}_time"]=$(date +%s)
        
        log_debug "命令执行并缓存: $cache_key (耗时: ${duration}s)"
        echo "$result"
    else
        handle_error "COMMAND_ERROR" "命令执行失败: $command" "smart_cached_command"
        return 1
    fi
}

# 更新平均响应时间
update_avg_response_time() {
    local duration="$1"
    local current_avg="${PERFORMANCE_STATS[avg_response_time]}"
    local total_commands="${PERFORMANCE_STATS[total_commands]}"
    
    if [[ "$current_avg" == "0" ]]; then
        PERFORMANCE_STATS[avg_response_time]="$duration"
    else
        local new_avg=$(echo "scale=3; ($current_avg * ($total_commands - 1) + $duration) / $total_commands" | bc -l)
        PERFORMANCE_STATS[avg_response_time]="$new_avg"
    fi
}

# 性能监控
start_performance_monitoring() {
    if [[ "$PERFORMANCE_MONITORING_ENABLED" != "true" ]]; then
        return 0
    fi
    
    log_info "启动性能监控..."
    
    # 创建性能监控脚本
    cat > "/tmp/performance_monitor.sh" << 'EOF'
#!/bin/bash

PERFORMANCE_LOG_FILE="/var/log/ipv6-wireguard-manager/performance.log"
PERFORMANCE_THRESHOLD_CPU=80
PERFORMANCE_THRESHOLD_MEMORY=80
PERFORMANCE_THRESHOLD_DISK=90

while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 获取系统指标
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' 2>/dev/null || echo "0")
    memory_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}' 2>/dev/null || echo "0")
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//' 2>/dev/null || echo "0")
    
    # 记录性能数据
    echo "$timestamp,CPU:$cpu_usage%,MEM:$memory_usage%,DISK:$disk_usage%" >> "$PERFORMANCE_LOG_FILE"
    
    # 检查阈值
    if (( $(echo "$cpu_usage > $PERFORMANCE_THRESHOLD_CPU" | bc -l) )); then
        echo "$timestamp,WARNING,CPU使用率过高: ${cpu_usage}%" >> "$PERFORMANCE_LOG_FILE"
    fi
    
    if (( $(echo "$memory_usage > $PERFORMANCE_THRESHOLD_MEMORY" | bc -l) )); then
        echo "$timestamp,WARNING,内存使用率过高: ${memory_usage}%" >> "$PERFORMANCE_LOG_FILE"
    fi
    
    if (( $(echo "$disk_usage > $PERFORMANCE_THRESHOLD_DISK" | bc -l) )); then
        echo "$timestamp,WARNING,磁盘使用率过高: ${disk_usage}%" >> "$PERFORMANCE_LOG_FILE"
    fi
    
    sleep 60
done
EOF
    
    chmod +x "/tmp/performance_monitor.sh"
    nohup "/tmp/performance_monitor.sh" > /dev/null 2>&1 &
    
    log_success "性能监控已启动"
}

# 停止性能监控
stop_performance_monitoring() {
    log_info "停止性能监控..."
    
    pkill -f "performance_monitor.sh" 2>/dev/null || true
    rm -f "/tmp/performance_monitor.sh"
    
    log_success "性能监控已停止"
}

# 获取性能统计
get_performance_stats() {
    echo "=== 性能统计 ==="
    echo "总命令数: ${PERFORMANCE_STATS[total_commands]}"
    echo "缓存命中: ${PERFORMANCE_STATS[cached_hits]}"
    echo "缓存未命中: ${PERFORMANCE_STATS[cache_misses]}"
    echo "平均响应时间: ${PERFORMANCE_STATS[avg_response_time]}s"
    
    if [[ ${PERFORMANCE_STATS[total_commands]} -gt 0 ]]; then
        local hit_rate=$(echo "scale=2; ${PERFORMANCE_STATS[cached_hits]} * 100 / ${PERFORMANCE_STATS[total_commands]}" | bc -l)
        echo "缓存命中率: ${hit_rate}%"
    fi
    
    echo "缓存条目数: $(get_cache_stats)"
    echo "系统资源:"
    echo "  CPU使用率: $(get_cpu_usage)%"
    echo "  内存使用率: $(get_memory_usage)%"
    echo "  磁盘使用率: $(get_disk_usage)%"
}

# 性能优化建议
get_performance_recommendations() {
    echo "=== 性能优化建议 ==="
    
    local cpu_usage=$(get_cpu_usage)
    local memory_usage=$(get_memory_usage)
    local disk_usage=$(get_disk_usage)
    
    if (( $(echo "$cpu_usage > 70" | bc -l) )); then
        echo "⚠️  CPU使用率较高 (${cpu_usage}%)，建议："
        echo "   - 优化脚本执行效率"
        echo "   - 减少不必要的系统调用"
        echo "   - 使用缓存机制"
    fi
    
    if (( $(echo "$memory_usage > 70" | bc -l) )); then
        echo "⚠️  内存使用率较高 (${memory_usage}%)，建议："
        echo "   - 清理不必要的变量"
        echo "   - 优化数据结构"
        echo "   - 定期清理缓存"
    fi
    
    if (( $(echo "$disk_usage > 80" | bc -l) )); then
        echo "⚠️  磁盘使用率较高 (${disk_usage}%)，建议："
        echo "   - 清理日志文件"
        echo "   - 删除临时文件"
        echo "   - 压缩备份文件"
    fi
    
    local hit_rate=0
    if [[ ${PERFORMANCE_STATS[total_commands]} -gt 0 ]]; then
        hit_rate=$(echo "scale=2; ${PERFORMANCE_STATS[cached_hits]} * 100 / ${PERFORMANCE_STATS[total_commands]}" | bc -l)
    fi
    
    if (( $(echo "$hit_rate < 50" | bc -l) )); then
        echo "💡 缓存命中率较低 (${hit_rate}%)，建议："
        echo "   - 增加缓存TTL时间"
        echo "   - 优化缓存键名策略"
        echo "   - 检查缓存清理策略"
    fi
}

# 性能优化菜单
performance_enhancements_menu() {
    echo -e "${SECONDARY_COLOR}=== 性能优化管理 ===${NC}"
    echo "1. 查看性能统计"
    echo "2. 查看性能建议"
    echo "3. 清理缓存"
    echo "4. 启动性能监控"
    echo "5. 停止性能监控"
    echo "6. 系统资源检查"
    echo "0. 返回主菜单"
    read -p "请选择操作 [0-6]: " choice
    
    case $choice in
        1)
            get_performance_stats
            ;;
        2)
            get_performance_recommendations
            ;;
        3)
            clear_cache
            ;;
        4)
            start_performance_monitoring
            ;;
        5)
            stop_performance_monitoring
            ;;
        6)
            check_system_resources
            ;;
        0)
            return
            ;;
        *)
            show_error "无效选择"
            ;;
    esac
}

# 导出函数
export -f init_performance_enhancements
export -f check_system_resources
export -f get_cpu_usage get_memory_usage get_disk_usage
export -f smart_cached_command
export -f start_performance_monitoring stop_performance_monitoring
export -f get_performance_stats get_performance_recommendations
export -f performance_enhancements_menu
