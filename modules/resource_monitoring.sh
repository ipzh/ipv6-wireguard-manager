#!/bin/bash

# 资源监控系统
# 监控内存、CPU、磁盘使用情况并提供优化建议

# =============================================================================
# 资源监控配置
# =============================================================================

# 监控阈值
declare -g MEMORY_THRESHOLD="${MEMORY_THRESHOLD:-80}"      # 内存使用率阈值(%)
declare -g CPU_THRESHOLD="${CPU_THRESHOLD:-90}"            # CPU使用率阈值(%)
declare -g DISK_THRESHOLD="${DISK_THRESHOLD:-90}"          # 磁盘使用率阈值(%)
declare -g MONITOR_INTERVAL="${MONITOR_INTERVAL:-60}"      # 监控间隔(秒)

# 监控状态
declare -g MONITORING_ENABLED=false
declare -g MONITOR_PID=""
declare -g LAST_MEMORY_USAGE=0
declare -g LAST_CPU_USAGE=0
declare -g LAST_DISK_USAGE=0

# 监控历史记录
declare -A MEMORY_HISTORY
declare -A CPU_HISTORY
declare -A DISK_HISTORY

# =============================================================================
# 资源获取函数
# =============================================================================

# 获取内存使用率
get_memory_usage() {
    if command -v free >/dev/null 2>&1; then
        local mem_info=$(free -m | grep Mem)
        local total=$(echo "$mem_info" | awk '{print $2}')
        local used=$(echo "$mem_info" | awk '{print $3}')
        local available=$(echo "$mem_info" | awk '{print $7}')
        local usage=$((used * 100 / total))
        
        # 检查内存使用率是否过高
        if [[ $usage -gt 90 ]]; then
            log_warn "内存使用率过高: ${usage}%"
        elif [[ $usage -gt 80 ]]; then
            log_info "内存使用率较高: ${usage}%"
        fi
        
        # 返回JSON格式数据
        if [[ "$1" == "--json" ]]; then
            cat << EOF
{
    "total": $total,
    "used": $used,
    "available": $available,
    "usage_percent": $usage,
    "status": "$(if [[ $usage -gt 90 ]]; then echo "critical"; elif [[ $usage -gt 80 ]]; then echo "warning"; else echo "normal"; fi)"
}
EOF
        else
            echo "$usage"
        fi
    else
        echo "0"
    fi
}

# 获取CPU使用率
get_cpu_usage() {
    if [[ -f /proc/loadavg ]]; then
        local load_1min=$(cat /proc/loadavg | awk '{print $1}')
        local cpu_cores=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo 1)
        local usage=$(echo "scale=0; $load_1min * 100 / $cpu_cores" | bc -l 2>/dev/null || echo "0")
        echo "${usage%.*}"
    else
        echo "0"
    fi
}

# 获取磁盘使用率
get_disk_usage() {
    local path="${1:-/}"
    if command -v df >/dev/null 2>&1; then
        local usage=$(df "$path" | tail -1 | awk '{print $5}' | sed 's/%//')
        echo "$usage"
    else
        echo "0"
    fi
}

# 获取系统负载
get_system_load() {
    if [[ -f /proc/loadavg ]]; then
        cat /proc/loadavg | awk '{print $1}'
    else
        uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ','
    fi
}

# 获取进程信息
get_top_processes() {
    local type="${1:-memory}"  # memory 或 cpu
    local count="${2:-5}"
    
    if command -v ps >/dev/null 2>&1; then
        case "$type" in
            "memory")
                ps -eo pid,user,%mem,%cpu,cmd --sort=-%mem | head -n $((count + 1))
                ;;
            "cpu")
                ps -eo pid,user,%mem,%cpu,cmd --sort=-%cpu | head -n $((count + 1))
                ;;
        esac
    else
        echo "ps命令不可用"
    fi
}

# =============================================================================
# 监控函数
# =============================================================================

# 检查资源使用情况
check_resources() {
    local memory_usage=$(get_memory_usage "$@")
    local cpu_usage=$(get_cpu_usage "$@")
    local disk_usage=$(get_disk_usage "$@")
    
    # 记录历史数据
    local timestamp=$(date +%s)
    MEMORY_HISTORY[$timestamp]=$memory_usage
    CPU_HISTORY[$timestamp]=$cpu_usage
    DISK_HISTORY[$timestamp]=$disk_usage
    
    # 检查内存使用
    if [[ $memory_usage -gt $MEMORY_THRESHOLD ]]; then
        log_warn "内存使用率过高: ${memory_usage}% (阈值: ${MEMORY_THRESHOLD}%)"
        log_memory_details
    fi
    
    # 检查CPU使用
    if [[ $cpu_usage -gt $CPU_THRESHOLD ]]; then
        log_warn "CPU使用率过高: ${cpu_usage}% (阈值: ${CPU_THRESHOLD}%)"
        log_cpu_details
    fi
    
    # 检查磁盘使用
    if [[ $disk_usage -gt $DISK_THRESHOLD ]]; then
        log_warn "磁盘使用率过高: ${disk_usage}% (阈值: ${DISK_THRESHOLD}%)"
        log_disk_details
    fi
    
    # 更新最后记录的使用率
    LAST_MEMORY_USAGE=$memory_usage
    LAST_CPU_USAGE=$cpu_usage
    LAST_DISK_USAGE=$disk_usage
}

# 记录内存详细信息
log_memory_details() {
    log_info "内存使用详情:"
    
    if command -v free >/dev/null 2>&1; then
        free -h | while read line; do
            log_info "  $line"
        done
    fi
    
    log_info "内存使用最多的进程:"
    get_top_processes "memory" 5 | while read line; do
        log_info "  $line"
    done
}

# 记录CPU详细信息
log_cpu_details() {
    log_info "CPU使用详情:"
    
    if [[ -f /proc/cpuinfo ]]; then
        local cpu_cores=$(grep -c "^processor" /proc/cpuinfo)
        local cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
        log_info "  CPU核心数: $cpu_cores"
        log_info "  CPU型号: $cpu_model"
    fi
    
    local load_avg=$(get_system_load "$@")
    log_info "  系统负载: $load_avg"
    
    log_info "CPU使用最多的进程:"
    get_top_processes "cpu" 5 | while read line; do
        log_info "  $line"
    done
}

# 记录磁盘详细信息
log_disk_details() {
    log_info "磁盘使用详情:"
    
    if command -v df >/dev/null 2>&1; then
        df -h | while read line; do
            log_info "  $line"
        done
    fi
    
    # 检查大文件
    log_info "查找大文件 (>/tmp):"
    if command -v find >/dev/null 2>&1; then
        find /tmp -type f -size +100M 2>/dev/null | head -10 | while read file; do
            local size=$(du -h "$file" 2>/dev/null | cut -f1)
            log_info "  $file ($size)"
        done
    fi
}

# =============================================================================
# 监控管理函数
# =============================================================================

# 启动资源监控
start_monitoring() {
    if [[ "$MONITORING_ENABLED" == "true" ]]; then
        log_warn "资源监控已在运行"
        return 0
    fi
    
    log_info "启动资源监控 (间隔: ${MONITOR_INTERVAL}秒)"
    
    # 在后台启动监控
    (
        while true; do
            check_resources
            sleep "$MONITOR_INTERVAL"
        done
    ) &
    
    MONITOR_PID=$!
    MONITORING_ENABLED=true
    
    log_success "资源监控已启动 (PID: $MONITOR_PID)"
}

# 停止资源监控
stop_monitoring() {
    if [[ "$MONITORING_ENABLED" != "true" ]]; then
        log_warn "资源监控未运行"
        return 0
    fi
    
    if [[ -n "$MONITOR_PID" ]] && kill -0 "$MONITOR_PID" 2>/dev/null; then
        kill "$MONITOR_PID" 2>/dev/null
        wait "$MONITOR_PID" 2>/dev/null
    fi
    
    MONITORING_ENABLED=false
    MONITOR_PID=""
    
    log_success "资源监控已停止"
}

# 获取监控状态
get_monitoring_status() {
    echo "资源监控状态:"
    echo "- 监控状态: $MONITORING_ENABLED"
    echo "- 监控PID: $MONITOR_PID"
    echo "- 监控间隔: ${MONITOR_INTERVAL}秒"
    echo "- 内存阈值: ${MEMORY_THRESHOLD}%"
    echo "- CPU阈值: ${CPU_THRESHOLD}%"
    echo "- 磁盘阈值: ${DISK_THRESHOLD}%"
}

# 获取当前资源使用情况
get_current_resources() {
    local memory_usage=$(get_memory_usage "$@")
    local cpu_usage=$(get_cpu_usage "$@")
    local disk_usage=$(get_disk_usage "$@")
    local load_avg=$(get_system_load "$@")
    
    echo "当前资源使用情况:"
    echo "- 内存使用率: ${memory_usage}%"
    echo "- CPU使用率: ${cpu_usage}%"
    echo "- 磁盘使用率: ${disk_usage}%"
    echo "- 系统负载: $load_avg"
}

# =============================================================================
# 性能优化函数
# =============================================================================

# 内存优化
optimize_memory() {
    log_info "开始内存优化..."
    
    # 清理缓存
    if [[ $EUID -eq 0 ]]; then
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
        log_success "已清理系统缓存"
    else
        log_warn "需要root权限来清理系统缓存"
    fi
    
    # 清理临时文件
    if command -v find >/dev/null 2>&1; then
        local temp_files=$(find /tmp -type f -mtime +7 2>/dev/null | wc -l)
        if [[ $temp_files -gt 0 ]]; then
            find /tmp -type f -mtime +7 -delete 2>/dev/null || true
            log_success "已清理 $temp_files 个临时文件"
        fi
    fi
    
    # 清理日志文件
    cleanup_log_files
    
    log_success "内存优化完成"
}

# 清理日志文件
cleanup_log_files() {
    local log_dir="$IPV6WGM_LOG_DIR"
    local cleaned_count=0
    
    if [[ -d "$log_dir" ]]; then
        # 清理旧日志文件
        if command -v find >/dev/null 2>&1; then
            cleaned_count=$(find "$log_dir" -name "*.log.*" -mtime +7 -delete 2>/dev/null | wc -l)
        fi
        
        # 截断大日志文件
        if command -v find >/dev/null 2>&1; then
            find "$log_dir" -name "*.log" -type f -size +100M -exec truncate -s 0 {} \; 2>/dev/null || true
        fi
    fi
    
    if [[ $cleaned_count -gt 0 ]]; then
        log_info "已清理 $cleaned_count 个旧日志文件"
    fi
}

# 系统优化建议
get_optimization_suggestions() {
    local memory_usage=$(get_memory_usage "$@")
    local cpu_usage=$(get_cpu_usage "$@")
    local disk_usage=$(get_disk_usage "$@")
    
    echo "系统优化建议:"
    
    if [[ $memory_usage -gt 80 ]]; then
        echo "- 内存使用率过高 (${memory_usage}%)，建议:"
        echo "  * 关闭不必要的服务"
        echo "  * 增加交换空间"
        echo "  * 优化应用程序内存使用"
    fi
    
    if [[ $cpu_usage -gt 80 ]]; then
        echo "- CPU使用率过高 (${cpu_usage}%)，建议:"
        echo "  * 检查CPU密集型进程"
        echo "  * 优化算法和数据结构"
        echo "  * 考虑负载均衡"
    fi
    
    if [[ $disk_usage -gt 80 ]]; then
        echo "- 磁盘使用率过高 (${disk_usage}%)，建议:"
        echo "  * 清理临时文件"
        echo "  * 压缩旧日志文件"
        echo "  * 删除不需要的文件"
    fi
}

# 获取系统健康评分
get_system_health_score() {
    local score=100
    local mem_usage=$(get_memory_usage "$@")
    local cpu_usage=$(get_cpu_usage "$@")
    local disk_usage=$(get_disk_usage "$@")
    
    # 内存评分
    if [[ $mem_usage -gt 90 ]]; then
        score=$((score - 30))
    elif [[ $mem_usage -gt 80 ]]; then
        score=$((score - 15))
    elif [[ $mem_usage -gt 70 ]]; then
        score=$((score - 5))
    fi
    
    # CPU评分
    if [[ $cpu_usage -gt 90 ]]; then
        score=$((score - 30))
    elif [[ $cpu_usage -gt 80 ]]; then
        score=$((score - 15))
    elif [[ $cpu_usage -gt 70 ]]; then
        score=$((score - 5))
    fi
    
    # 磁盘评分
    if [[ $disk_usage -gt 90 ]]; then
        score=$((score - 30))
    elif [[ $disk_usage -gt 80 ]]; then
        score=$((score - 15))
    elif [[ $disk_usage -gt 70 ]]; then
        score=$((score - 5))
    fi
    
    # 确保分数不为负数
    if [[ $score -lt 0 ]]; then
        score=0
    fi
    
    echo "$score"
}

# 生成资源监控报告
generate_resource_report() {
    local report_file="${1:-/tmp/resource_report_$(date +%Y%m%d_%H%M%S).txt}"
    
    {
        echo "=== IPv6 WireGuard Manager 资源监控报告 ==="
        echo "生成时间: $(date)"
        echo ""
        
        echo "=== 内存使用情况 ==="
        echo "内存使用率: $(get_memory_usage "$@")%"
        if command -v free &> /dev/null; then
            free -h
        fi
        echo ""
        
        echo "=== CPU使用情况 ==="
        echo "CPU使用率: $(get_cpu_usage "$@")%"
        echo "负载平均值: $(cat /proc/loadavg 2>/dev/null || echo "无法获取")"
        echo ""
        
        echo "=== 磁盘使用情况 ==="
        echo "磁盘使用率: $(get_disk_usage "$@")%"
        echo "磁盘空间:"
        df -h 2>/dev/null || echo "无法获取磁盘信息"
        echo ""
        
        echo "=== 系统健康评分 ==="
        echo "健康评分: $(get_system_health_score)/100"
        echo ""
        
        echo "=== 优化建议 ==="
        get_optimization_suggestions
        echo ""
        
        echo "=== 进程信息 ==="
        if command -v ps &> /dev/null; then
            echo "内存占用前5的进程:"
            ps aux --sort=-%mem | head -6
            echo ""
            echo "CPU占用前5的进程:"
            ps aux --sort=-%cpu | head -6
        fi
        
    } > "$report_file"
    
    log_info "资源监控报告已生成: $report_file"
    echo "$report_file"
}

# 实时资源监控
start_realtime_monitoring() {
    local interval="${1:-5}"
    
    log_info "启动实时资源监控，间隔: ${interval}秒"
    
    while true; do
        clear
        echo "=== IPv6 WireGuard Manager 实时资源监控 ==="
        echo "时间: $(date)"
        echo "按 Ctrl+C 停止监控"
        echo ""
        
        echo "内存使用率: $(get_memory_usage "$@")%"
        echo "CPU使用率: $(get_cpu_usage "$@")%"
        echo "磁盘使用率: $(get_disk_usage "$@")%"
        echo "系统健康评分: $(get_system_health_score)/100"
        echo ""
        
        if command -v free &> /dev/null; then
            echo "内存详情:"
            free -h
            echo ""
        fi
        
        if command -v ps &> /dev/null; then
            echo "内存占用前5的进程:"
            ps aux --sort=-%mem | head -6
            echo ""
        fi
        
        sleep "$interval"
    done
}

# 导出函数
export -f get_memory_usage get_cpu_usage get_disk_usage get_system_load get_top_processes
export -f check_resources log_memory_details log_cpu_details log_disk_details
export -f start_monitoring stop_monitoring get_monitoring_status get_current_resources
export -f optimize_memory cleanup_log_files get_optimization_suggestions
export -f get_system_health_score generate_resource_report start_realtime_monitoring
