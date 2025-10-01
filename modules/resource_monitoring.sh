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
declare -g NETWORK_THRESHOLD="${NETWORK_THRESHOLD:-80}"    # 网络使用率阈值(%)
declare -g TEMP_THRESHOLD="${TEMP_THRESHOLD:-80}"          # 温度阈值(°C)
declare -g MONITOR_INTERVAL="${MONITOR_INTERVAL:-60}"      # 监控间隔(秒)

# 告警配置
declare -g ALERT_ENABLED="${ALERT_ENABLED:-true}"          # 启用告警
declare -g EMAIL_ALERTS="${EMAIL_ALERTS:-false}"           # 邮件告警
declare -g WEBHOOK_ALERTS="${WEBHOOK_ALERTS:-false}"       # Webhook告警
declare -g SLACK_ALERTS="${SLACK_ALERTS:-false}"           # Slack告警
declare -g ALERT_COOLDOWN="${ALERT_COOLDOWN:-300}"         # 告警冷却时间(秒)

# 监控状态
declare -g MONITORING_ENABLED=false
declare -g MONITOR_PID=""
declare -g LAST_MEMORY_USAGE=0
declare -g LAST_CPU_USAGE=0
declare -g LAST_DISK_USAGE=0
declare -g LAST_NETWORK_USAGE=0
declare -g LAST_TEMP_USAGE=0

# 告警状态
declare -A ALERT_COOLDOWNS
declare -A ALERT_COUNTS

# 监控历史记录
declare -A MEMORY_HISTORY
declare -A CPU_HISTORY
declare -A DISK_HISTORY
declare -A NETWORK_HISTORY
declare -A TEMP_HISTORY

# 告警配置
declare -g ALERT_EMAIL_RECIPIENTS=""
declare -g ALERT_WEBHOOK_URL=""
declare -g ALERT_SLACK_WEBHOOK=""
declare -g ALERT_SLACK_CHANNEL="#alerts"

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
            find "$log_dir" -name "*.log" -type f -size +100M -print0 | xargs -0 -r truncate -s 0 2>/dev/null || true
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
        
        echo "=== 网络使用情况 ==="
        echo "网络使用率: $(get_network_usage "$@")%"
        echo "网络接口状态:"
        ip -s link show 2>/dev/null || ifconfig 2>/dev/null || echo "无法获取网络信息"
        echo ""
        
        echo "=== 温度监控 ==="
        echo "系统温度: $(get_temperature "$@")°C"
        echo ""
        
        echo "=== 系统健康评分 ==="
        echo "健康评分: $(get_system_health_score)/100"
        echo ""
        
        echo "=== 优化建议 ==="
        get_optimization_suggestions
        echo ""
        
        echo "=== 告警状态 ==="
        show_alert_status
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
        echo "网络使用率: $(get_network_usage "$@")%"
        echo "系统温度: $(get_temperature "$@")°C"
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

# =============================================================================
# 网络监控函数
# =============================================================================

# 获取网络使用率
get_network_usage() {
    local interface="${1:-eth0}"
    local rx_bytes=0
    local tx_bytes=0
    
    if [[ -f "/sys/class/net/$interface/statistics/rx_bytes" ]]; then
        rx_bytes=$(cat "/sys/class/net/$interface/statistics/rx_bytes" 2>/dev/null || echo "0")
        tx_bytes=$(cat "/sys/class/net/$interface/statistics/tx_bytes" 2>/dev/null || echo "0")
    elif command -v ifconfig >/dev/null 2>&1; then
        local stats=$(ifconfig "$interface" 2>/dev/null | grep -E "RX bytes|TX bytes")
        rx_bytes=$(echo "$stats" | grep "RX bytes" | sed 's/.*RX bytes \([0-9]*\).*/\1/')
        tx_bytes=$(echo "$stats" | grep "TX bytes" | sed 's/.*TX bytes \([0-9]*\).*/\1/')
    fi
    
    # 计算总流量（简化计算）
    local total_bytes=$((rx_bytes + tx_bytes))
    local usage=$((total_bytes / 1024 / 1024))  # 转换为MB
    
    if [[ "$1" == "--json" ]]; then
        cat << EOF
{
    "interface": "$interface",
    "rx_bytes": $rx_bytes,
    "tx_bytes": $tx_bytes,
    "total_bytes": $total_bytes,
    "usage_mb": $usage
}
EOF
    else
        echo "$usage"
    fi
}

# =============================================================================
# 温度监控函数
# =============================================================================

# 获取系统温度
get_temperature() {
    local temp=0
    
    # 尝试从不同位置获取温度
    if [[ -f "/sys/class/thermal/thermal_zone0/temp" ]]; then
        temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "0")
        temp=$((temp / 1000))  # 转换为摄氏度
    elif command -v sensors >/dev/null 2>&1; then
        temp=$(sensors 2>/dev/null | grep -E "Core 0|Package id 0" | head -1 | sed 's/.*+\([0-9]*\)\.[0-9]*°C.*/\1/')
    elif command -v acpi >/dev/null 2>&1; then
        temp=$(acpi -t 2>/dev/null | grep -o '[0-9]*' | head -1)
    fi
    
    if [[ "$1" == "--json" ]]; then
        cat << EOF
{
    "temperature": $temp,
    "threshold": $TEMP_THRESHOLD,
    "status": "$(if [[ $temp -gt $TEMP_THRESHOLD ]]; then echo "warning"; else echo "normal"; fi)"
}
EOF
    else
        echo "$temp"
    fi
}

# =============================================================================
# 告警系统函数
# =============================================================================

# 发送告警
send_alert() {
    local alert_type="$1"
    local message="$2"
    local severity="${3:-warning}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 检查告警冷却时间
    local alert_key="${alert_type}_${severity}"
    local last_alert=${ALERT_COOLDOWNS[$alert_key]:-0}
    local current_time=$(date +%s)
    
    if [[ $((current_time - last_alert)) -lt $ALERT_COOLDOWN ]]; then
        return 0  # 在冷却时间内，跳过告警
    fi
    
    # 更新告警计数和冷却时间
    ALERT_COUNTS[$alert_key]=$((${ALERT_COUNTS[$alert_key]:-0} + 1))
    ALERT_COOLDOWNS[$alert_key]=$current_time
    
    # 记录告警日志
    log_warn "告警 [$severity]: $alert_type - $message"
    
    # 发送邮件告警
    if [[ "$EMAIL_ALERTS" == "true" && -n "$ALERT_EMAIL_RECIPIENTS" ]]; then
        send_email_alert "$alert_type" "$message" "$severity"
    fi
    
    # 发送Webhook告警
    if [[ "$WEBHOOK_ALERTS" == "true" && -n "$ALERT_WEBHOOK_URL" ]]; then
        send_webhook_alert "$alert_type" "$message" "$severity"
    fi
    
    # 发送Slack告警
    if [[ "$SLACK_ALERTS" == "true" && -n "$ALERT_SLACK_WEBHOOK" ]]; then
        send_slack_alert "$alert_type" "$message" "$severity"
    fi
}

# 发送邮件告警
send_email_alert() {
    local alert_type="$1"
    local message="$2"
    local severity="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local subject="[IPv6-WG-Manager] $severity 告警: $alert_type"
    local body="
告警时间: $timestamp
告警类型: $alert_type
严重程度: $severity
告警信息: $message

系统状态:
- 内存使用率: $(get_memory_usage)%
- CPU使用率: $(get_cpu_usage)%
- 磁盘使用率: $(get_disk_usage)%
- 网络使用率: $(get_network_usage)%
- 系统温度: $(get_temperature)°C

请及时处理相关问题。
"
    
    if command -v mail >/dev/null 2>&1; then
        echo "$body" | mail -s "$subject" $ALERT_EMAIL_RECIPIENTS
        log_info "邮件告警已发送"
    else
        log_warn "mail命令不可用，无法发送邮件告警"
    fi
}

# 发送Webhook告警
send_webhook_alert() {
    local alert_type="$1"
    local message="$2"
    local severity="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local payload=$(cat << EOF
{
    "timestamp": "$timestamp",
    "alert_type": "$alert_type",
    "message": "$message",
    "severity": "$severity",
    "system_info": {
        "memory_usage": $(get_memory_usage),
        "cpu_usage": $(get_cpu_usage),
        "disk_usage": $(get_disk_usage),
        "network_usage": $(get_network_usage),
        "temperature": $(get_temperature)
    }
}
EOF
)
    
    if command -v curl >/dev/null 2>&1; then
        curl -X POST -H "Content-Type: application/json" \
             -d "$payload" \
             "$ALERT_WEBHOOK_URL" \
             --connect-timeout 10 \
             --max-time 30 \
             >/dev/null 2>&1
        
        if [[ $? -eq 0 ]]; then
            log_info "Webhook告警已发送"
        else
            log_warn "Webhook告警发送失败"
        fi
    else
        log_warn "curl命令不可用，无法发送Webhook告警"
    fi
}

# 发送Slack告警
send_slack_alert() {
    local alert_type="$1"
    local message="$2"
    local severity="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 根据严重程度设置颜色
    local color="good"
    case "$severity" in
        "critical") color="danger" ;;
        "warning") color="warning" ;;
        "info") color="good" ;;
    esac
    
    local payload=$(cat << EOF
{
    "channel": "$ALERT_SLACK_CHANNEL",
    "username": "IPv6-WG-Manager",
    "icon_emoji": ":warning:",
    "attachments": [
        {
            "color": "$color",
            "title": "$severity 告警: $alert_type",
            "text": "$message",
            "fields": [
                {
                    "title": "时间",
                    "value": "$timestamp",
                    "short": true
                },
                {
                    "title": "内存使用率",
                    "value": "$(get_memory_usage)%",
                    "short": true
                },
                {
                    "title": "CPU使用率",
                    "value": "$(get_cpu_usage)%",
                    "short": true
                },
                {
                    "title": "磁盘使用率",
                    "value": "$(get_disk_usage)%",
                    "short": true
                },
                {
                    "title": "系统温度",
                    "value": "$(get_temperature)°C",
                    "short": true
                }
            ]
        }
    ]
}
EOF
)
    
    if command -v curl >/dev/null 2>&1; then
        curl -X POST -H "Content-Type: application/json" \
             -d "$payload" \
             "$ALERT_SLACK_WEBHOOK" \
             --connect-timeout 10 \
             --max-time 30 \
             >/dev/null 2>&1
        
        if [[ $? -eq 0 ]]; then
            log_info "Slack告警已发送"
        else
            log_warn "Slack告警发送失败"
        fi
    else
        log_warn "curl命令不可用，无法发送Slack告警"
    fi
}

# 检查资源告警
check_resource_alerts() {
    if [[ "$ALERT_ENABLED" != "true" ]]; then
        return 0
    fi
    
    local memory_usage=$(get_memory_usage)
    local cpu_usage=$(get_cpu_usage)
    local disk_usage=$(get_disk_usage)
    local network_usage=$(get_network_usage)
    local temperature=$(get_temperature)
    
    # 检查内存告警
    if [[ $memory_usage -gt $MEMORY_THRESHOLD ]]; then
        send_alert "memory" "内存使用率过高: ${memory_usage}% (阈值: ${MEMORY_THRESHOLD}%)" "warning"
    fi
    
    # 检查CPU告警
    if [[ $cpu_usage -gt $CPU_THRESHOLD ]]; then
        send_alert "cpu" "CPU使用率过高: ${cpu_usage}% (阈值: ${CPU_THRESHOLD}%)" "warning"
    fi
    
    # 检查磁盘告警
    if [[ $disk_usage -gt $DISK_THRESHOLD ]]; then
        send_alert "disk" "磁盘使用率过高: ${disk_usage}% (阈值: ${DISK_THRESHOLD}%)" "critical"
    fi
    
    # 检查网络告警
    if [[ $network_usage -gt $NETWORK_THRESHOLD ]]; then
        send_alert "network" "网络使用率过高: ${network_usage}MB (阈值: ${NETWORK_THRESHOLD}%)" "warning"
    fi
    
    # 检查温度告警
    if [[ $temperature -gt $TEMP_THRESHOLD ]]; then
        send_alert "temperature" "系统温度过高: ${temperature}°C (阈值: ${TEMP_THRESHOLD}°C)" "critical"
    fi
}

# 显示告警状态
show_alert_status() {
    echo "告警配置:"
    echo "  启用状态: $ALERT_ENABLED"
    echo "  邮件告警: $EMAIL_ALERTS"
    echo "  Webhook告警: $WEBHOOK_ALERTS"
    echo "  Slack告警: $SLACK_ALERTS"
    echo "  冷却时间: ${ALERT_COOLDOWN}秒"
    echo ""
    
    if [[ ${#ALERT_COUNTS[@]} -gt 0 ]]; then
        echo "告警统计:"
        for alert_key in "${!ALERT_COUNTS[@]}"; do
            echo "  $alert_key: ${ALERT_COUNTS[$alert_key]} 次"
        done
    else
        echo "暂无告警记录"
    fi
}

# 配置告警设置
configure_alerts() {
    echo -e "${SECONDARY_COLOR}=== 配置告警设置 ===${NC}"
    echo
    
    # 基本告警设置
    ALERT_ENABLED=$(show_selection "启用告警" "true" "false")
    ALERT_COOLDOWN=$(show_input "告警冷却时间(秒)" "$ALERT_COOLDOWN")
    
    # 阈值设置
    MEMORY_THRESHOLD=$(show_input "内存使用率阈值(%)" "$MEMORY_THRESHOLD")
    CPU_THRESHOLD=$(show_input "CPU使用率阈值(%)" "$CPU_THRESHOLD")
    DISK_THRESHOLD=$(show_input "磁盘使用率阈值(%)" "$DISK_THRESHOLD")
    NETWORK_THRESHOLD=$(show_input "网络使用率阈值(%)" "$NETWORK_THRESHOLD")
    TEMP_THRESHOLD=$(show_input "温度阈值(°C)" "$TEMP_THRESHOLD")
    
    # 邮件告警设置
    EMAIL_ALERTS=$(show_selection "启用邮件告警" "true" "false")
    if [[ "$EMAIL_ALERTS" == "true" ]]; then
        ALERT_EMAIL_RECIPIENTS=$(show_input "邮件接收者(用逗号分隔)" "$ALERT_EMAIL_RECIPIENTS")
    fi
    
    # Webhook告警设置
    WEBHOOK_ALERTS=$(show_selection "启用Webhook告警" "true" "false")
    if [[ "$WEBHOOK_ALERTS" == "true" ]]; then
        ALERT_WEBHOOK_URL=$(show_input "Webhook URL" "$ALERT_WEBHOOK_URL")
    fi
    
    # Slack告警设置
    SLACK_ALERTS=$(show_selection "启用Slack告警" "true" "false")
    if [[ "$SLACK_ALERTS" == "true" ]]; then
        ALERT_SLACK_WEBHOOK=$(show_input "Slack Webhook URL" "$ALERT_SLACK_WEBHOOK")
        ALERT_SLACK_CHANNEL=$(show_input "Slack频道" "$ALERT_SLACK_CHANNEL")
    fi
    
    # 保存配置
    save_alert_config
    
    show_success "告警配置已更新"
}

# 保存告警配置
save_alert_config() {
    local config_file="${CONFIG_DIR}/alert_config.conf"
    
    cat > "$config_file" << EOF
# 告警配置
ALERT_ENABLED="$ALERT_ENABLED"
EMAIL_ALERTS="$EMAIL_ALERTS"
WEBHOOK_ALERTS="$WEBHOOK_ALERTS"
SLACK_ALERTS="$SLACK_ALERTS"
ALERT_COOLDOWN=$ALERT_COOLDOWN

# 监控阈值
MEMORY_THRESHOLD=$MEMORY_THRESHOLD
CPU_THRESHOLD=$CPU_THRESHOLD
DISK_THRESHOLD=$DISK_THRESHOLD
NETWORK_THRESHOLD=$NETWORK_THRESHOLD
TEMP_THRESHOLD=$TEMP_THRESHOLD

# 告警配置
ALERT_EMAIL_RECIPIENTS="$ALERT_EMAIL_RECIPIENTS"
ALERT_WEBHOOK_URL="$ALERT_WEBHOOK_URL"
ALERT_SLACK_WEBHOOK="$ALERT_SLACK_WEBHOOK"
ALERT_SLACK_CHANNEL="$ALERT_SLACK_CHANNEL"
EOF
    
    log_debug "告警配置文件已保存: $config_file"
}

# 加载告警配置
load_alert_config() {
    local config_file="${CONFIG_DIR}/alert_config.conf"
    
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        log_debug "告警配置已加载: $config_file"
    else
        log_info "告警配置文件不存在，使用默认配置"
    fi
}

# 监控管理菜单
monitoring_management_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 监控管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看系统资源状态"
        echo -e "${GREEN}2.${NC} 启动实时监控"
        echo -e "${GREEN}3.${NC} 生成监控报告"
        echo -e "${GREEN}4.${NC} 配置告警设置"
        echo -e "${GREEN}5.${NC} 查看告警状态"
        echo -e "${GREEN}6.${NC} 测试告警功能"
        echo -e "${GREEN}7.${NC} 启动后台监控"
        echo -e "${GREEN}8.${NC} 停止后台监控"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -rp "请选择操作 [0-8]: " choice
        
        case $choice in
            1) get_current_resources ;;
            2) start_realtime_monitoring ;;
            3) generate_resource_report ;;
            4) configure_alerts ;;
            5) show_alert_status ;;
            6) test_alert_system ;;
            7) start_background_monitoring ;;
            8) stop_background_monitoring ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 测试告警系统
test_alert_system() {
    echo -e "${SECONDARY_COLOR}=== 测试告警系统 ===${NC}"
    echo
    
    echo "测试邮件告警..."
    send_alert "test" "这是一条测试告警消息" "info"
    
    echo "测试Webhook告警..."
    send_webhook_alert "test" "这是一条测试Webhook告警" "info"
    
    echo "测试Slack告警..."
    send_slack_alert "test" "这是一条测试Slack告警" "info"
    
    show_success "告警系统测试完成"
}

# 启动后台监控
start_background_monitoring() {
    if [[ "$MONITORING_ENABLED" == "true" ]]; then
        show_warn "监控已在运行中"
        return 0
    fi
    
    log_info "启动后台监控服务..."
    
    # 加载告警配置
    load_alert_config
    
    # 启动监控循环
    (
        while true; do
            check_resource_alerts
            sleep "$MONITOR_INTERVAL"
        done
    ) &
    
    MONITOR_PID=$!
    MONITORING_ENABLED=true
    
    # 保存PID
    echo "$MONITOR_PID" > "${CONFIG_DIR}/monitor.pid"
    
    show_success "后台监控已启动 (PID: $MONITOR_PID)"
}

# 停止后台监控
stop_background_monitoring() {
    if [[ "$MONITORING_ENABLED" != "true" ]]; then
        show_warn "监控未运行"
        return 0
    fi
    
    log_info "停止后台监控服务..."
    
    if [[ -n "$MONITOR_PID" ]]; then
        kill "$MONITOR_PID" 2>/dev/null
        MONITOR_PID=""
    fi
    
    # 清理PID文件
    rm -f "${CONFIG_DIR}/monitor.pid"
    
    MONITORING_ENABLED=false
    
    show_success "后台监控已停止"
}

# 导出函数
export -f get_memory_usage get_cpu_usage get_disk_usage get_system_load get_top_processes
export -f check_resources log_memory_details log_cpu_details log_disk_details
export -f start_monitoring stop_monitoring get_monitoring_status get_current_resources
export -f optimize_memory cleanup_log_files get_optimization_suggestions
export -f get_system_health_score generate_resource_report start_realtime_monitoring
export -f get_network_usage get_temperature send_alert send_email_alert send_webhook_alert
export -f send_slack_alert check_resource_alerts show_alert_status configure_alerts
export -f save_alert_config load_alert_config monitoring_management_menu
export -f test_alert_system start_background_monitoring stop_background_monitoring
