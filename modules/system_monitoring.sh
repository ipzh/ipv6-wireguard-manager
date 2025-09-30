#!/bin/bash

# IPv6 WireGuard Manager 系统监控模块
# 版本: 1.0.0
# 作者: IPv6 WireGuard Manager Team

# 监控配置
MONITOR_INTERVAL=60  # 监控间隔（秒）
LOG_RETENTION_DAYS=30  # 日志保留天数
ALERT_THRESHOLD_CPU=80  # CPU使用率告警阈值
ALERT_THRESHOLD_MEMORY=85  # 内存使用率告警阈值
ALERT_THRESHOLD_DISK=90  # 磁盘使用率告警阈值

# 监控数据存储
MONITOR_DATA_DIR="/var/lib/ipv6-wireguard-manager/monitoring"
METRICS_FILE="$MONITOR_DATA_DIR/metrics.json"
ALERTS_FILE="$MONITOR_DATA_DIR/alerts.json"

# 初始化监控系统
init_monitoring() {
    log_info "初始化系统监控..."
    
    # 创建监控数据目录
    execute_command "mkdir -p '$MONITOR_DATA_DIR'" "创建监控数据目录" "true"
    
    # 初始化指标文件
    if [[ ! -f "$METRICS_FILE" ]]; then
        cat > "$METRICS_FILE" << 'EOF'
{
    "timestamp": "",
    "system": {
        "cpu_usage": 0,
        "memory_usage": 0,
        "disk_usage": 0,
        "load_average": [0, 0, 0]
    },
    "network": {
        "wireguard_peers": 0,
        "wireguard_traffic": {
            "rx_bytes": 0,
            "tx_bytes": 0
        },
        "bgp_neighbors": 0,
        "bgp_routes": 0
    },
    "services": {
        "ipv6_wireguard_manager": "unknown",
        "wireguard": "unknown",
        "bird": "unknown",
        "nginx": "unknown"
    }
}
EOF
    fi
    
    # 初始化告警文件
    if [[ ! -f "$ALERTS_FILE" ]]; then
        echo "[]" > "$ALERTS_FILE"
    fi
    
    log_success "系统监控初始化完成"
}

# 收集系统指标
collect_system_metrics() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # CPU使用率
    local cpu_usage=$(get_cpu_usage "$@")
    
    # 内存使用率
    local memory_usage=$(get_memory_usage "$@")
    
    # 磁盘使用率
    local disk_usage=$(get_disk_usage "$@")
    
    # 负载平均值
    local load_avg=$(get_load_average "$@")
    
    # WireGuard指标
    local wireguard_peers=$(get_wireguard_peers "$@")
    local wireguard_traffic=$(get_wireguard_traffic "$@")
    
    # BGP指标
    local bgp_neighbors=$(get_bgp_neighbors "$@")
    local bgp_routes=$(get_bgp_routes "$@")
    
    # 服务状态
    local services_status=$(get_services_status "$@")
    
    # 确保目录存在
    mkdir -p "$(dirname "$METRICS_FILE")" 2>/dev/null || true
    
    # 更新指标文件
    cat > "$METRICS_FILE" << EOF
{
    "timestamp": "$timestamp",
    "system": {
        "cpu_usage": $cpu_usage,
        "memory_usage": $memory_usage,
        "disk_usage": $disk_usage,
        "load_average": $load_avg
    },
    "network": {
        "wireguard_peers": $wireguard_peers,
        "wireguard_traffic": $wireguard_traffic,
        "bgp_neighbors": $bgp_neighbors,
        "bgp_routes": $bgp_routes
    },
    "services": $services_status
}
EOF
    
    if command -v log_debug >/dev/null 2>&1; then
        log_debug "系统指标收集完成"
    fi
}

# 获取CPU使用率
get_cpu_usage() {
    if command -v top &> /dev/null; then
        top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}'
    elif command -v vmstat &> /dev/null; then
        vmstat 1 2 | tail -1 | awk '{print 100 - $15}'
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

# 获取负载平均值
get_load_average() {
    if [[ -f /proc/loadavg ]]; then
        local load_avg=$(cat /proc/loadavg | awk '{print $1","$2","$3}')
        echo "[$load_avg]"
    else
        echo "[0,0,0]"
    fi
}

# 获取WireGuard对等体数量
get_wireguard_peers() {
    if command -v wg &> /dev/null; then
        wg show wg0 peers 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

# 获取WireGuard流量统计
get_wireguard_traffic() {
    if command -v wg &> /dev/null; then
        local rx_bytes=$(wg show wg0 transfer 2>/dev/null | awk '{rx+=$2} END {print rx+0}')
        local tx_bytes=$(wg show wg0 transfer 2>/dev/null | awk '{tx+=$3} END {print tx+0}')
        echo "{\"rx_bytes\": $rx_bytes, \"tx_bytes\": $tx_bytes}"
    else
        echo "{\"rx_bytes\": 0, \"tx_bytes\": 0}"
    fi
}

# 获取BGP邻居数量
get_bgp_neighbors() {
    if command -v birdc &> /dev/null; then
        birdc show protocols 2>/dev/null | grep -c "BGP" || echo "0"
    else
        echo "0"
    fi
}

# 获取BGP路由数量
get_bgp_routes() {
    if command -v birdc &> /dev/null; then
        birdc show route count 2>/dev/null | tail -1 | awk '{print $1}' || echo "0"
    else
        echo "0"
    fi
}

# 获取服务状态
get_services_status() {
    local services=("ipv6-wireguard-manager" "wg-quick@wg0" "bird" "nginx")
    local status_json="{"
    
    for service in "${services[@]}"; do
        local status="unknown"
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            status="active"
        elif systemctl is-failed --quiet "$service" 2>/dev/null; then
            status="failed"
        elif systemctl is-enabled --quiet "$service" 2>/dev/null; then
            status="inactive"
        fi
        
        status_json+="\"$service\": \"$status\""
        if [[ "$service" != "${services[-1]}" ]]; then
            status_json+=","
        fi
    done
    
    status_json+="}"
    echo "$status_json"
}

# 检查告警条件
check_alerts() {
    local alerts=()
    
    # 读取当前指标
    if [[ -f "$METRICS_FILE" ]]; then
        local cpu_usage=$(jq -r '.system.cpu_usage' "$METRICS_FILE" 2>/dev/null || echo "0")
        local memory_usage=$(jq -r '.system.memory_usage' "$METRICS_FILE" 2>/dev/null || echo "0")
        local disk_usage=$(jq -r '.system.disk_usage' "$METRICS_FILE" 2>/dev/null || echo "0")
        
        # CPU使用率告警
        if (( $(echo "$cpu_usage > $ALERT_THRESHOLD_CPU" | bc -l) )); then
            alerts+=("{\"type\": \"cpu\", \"level\": \"warning\", \"message\": \"CPU使用率过高: ${cpu_usage}%\", \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}")
        fi
        
        # 内存使用率告警
        if (( $(echo "$memory_usage > $ALERT_THRESHOLD_MEMORY" | bc -l) )); then
            alerts+=("{\"type\": \"memory\", \"level\": \"warning\", \"message\": \"内存使用率过高: ${memory_usage}%\", \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}")
        fi
        
        # 磁盘使用率告警
        if (( $(echo "$disk_usage > $ALERT_THRESHOLD_DISK" | bc -l) )); then
            alerts+=("{\"type\": \"disk\", \"level\": \"critical\", \"message\": \"磁盘使用率过高: ${disk_usage}%\", \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}")
        fi
    fi
    
    # 检查服务状态
    local services_status=$(get_services_status "$@")
    local failed_services=$(echo "$services_status" | jq -r 'to_entries[] | select(.value == "failed") | .key' 2>/dev/null)
    
    if [[ -n "$failed_services" ]]; then
        while IFS= read -r service; do
            alerts+=("{\"type\": \"service\", \"level\": \"critical\", \"message\": \"服务异常: $service\", \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}")
        done <<< "$failed_services"
    fi
    
    # 更新告警文件
    if [[ ${#alerts[@]} -gt 0 ]]; then
        printf '%s\n' "${alerts[@]}" | jq -s '.' > "$ALERTS_FILE"
        
        # 发送告警通知
        for alert in "${alerts[@]}"; do
            local level=$(echo "$alert" | jq -r '.level')
            local message=$(echo "$alert" | jq -r '.message')
            
            case "$level" in
                "warning")
                    log_warn "⚠️  $message"
                    ;;
                "critical")
                    log_error "🚨 $message"
                    ;;
            esac
        done
    else
        echo "[]" > "$ALERTS_FILE"
    fi
}

# 生成监控报告
generate_monitoring_report() {
    local report_file="$MONITOR_DATA_DIR/monitoring_report_$(date +%Y%m%d_%H%M%S).html"
    
    if [[ ! -f "$METRICS_FILE" ]]; then
        log_warn "监控数据文件不存在"
        return 1
    fi
    
    local timestamp=$(jq -r '.timestamp' "$METRICS_FILE")
    local cpu_usage=$(jq -r '.system.cpu_usage' "$METRICS_FILE")
    local memory_usage=$(jq -r '.system.memory_usage' "$METRICS_FILE")
    local disk_usage=$(jq -r '.system.disk_usage' "$METRICS_FILE")
    local wireguard_peers=$(jq -r '.network.wireguard_peers' "$METRICS_FILE")
    local bgp_neighbors=$(jq -r '.network.bgp_neighbors' "$METRICS_FILE")
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>IPv6 WireGuard Manager 监控报告</title>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .metric-card { background-color: #f9f9f9; padding: 15px; border-radius: 5px; border-left: 4px solid #007cba; }
        .metric-value { font-size: 24px; font-weight: bold; color: #007cba; }
        .metric-label { color: #666; margin-top: 5px; }
        .alerts { margin: 20px 0; }
        .alert { padding: 10px; margin: 5px 0; border-radius: 3px; }
        .alert-warning { background-color: #fff3cd; border-left: 4px solid #ffc107; }
        .alert-critical { background-color: #f8d7da; border-left: 4px solid #dc3545; }
    </style>
</head>
<body>
    <div class="header">
        <h1>IPv6 WireGuard Manager 监控报告</h1>
        <p>生成时间: $timestamp</p>
    </div>
    
    <div class="metrics">
        <div class="metric-card">
            <div class="metric-value">${cpu_usage}%</div>
            <div class="metric-label">CPU使用率</div>
        </div>
        <div class="metric-card">
            <div class="metric-value">${memory_usage}%</div>
            <div class="metric-label">内存使用率</div>
        </div>
        <div class="metric-card">
            <div class="metric-value">${disk_usage}%</div>
            <div class="metric-label">磁盘使用率</div>
        </div>
        <div class="metric-card">
            <div class="metric-value">${wireguard_peers}</div>
            <div class="metric-label">WireGuard对等体</div>
        </div>
        <div class="metric-card">
            <div class="metric-value">${bgp_neighbors}</div>
            <div class="metric-label">BGP邻居</div>
        </div>
    </div>
    
    <div class="alerts">
        <h2>告警信息</h2>
        $(if [[ -f "$ALERTS_FILE" ]]; then
            jq -r '.[] | "<div class=\"alert alert-\(.level)\"><strong>\(.type | ascii_upcase):</strong> \(.message)</div>"' "$ALERTS_FILE" 2>/dev/null || echo "<p>无告警信息</p>"
        else
            echo "<p>无告警信息</p>"
        fi)
    </div>
</body>
</html>
EOF
    
    log_success "监控报告已生成: $report_file"
}

# 启动监控服务
start_monitoring() {
    log_info "启动系统监控服务..."
    
    # 初始化监控系统
    init_monitoring
    
    # 创建监控循环
    while true; do
        # 收集系统指标
        collect_system_metrics
        
        # 检查告警条件
        check_alerts
        
        # 等待下次监控
        sleep "$MONITOR_INTERVAL"
    done
}

# 停止监控服务
stop_monitoring() {
    log_info "停止系统监控服务..."
    
    # 查找并终止监控进程
    local pids=$(pgrep -f "system_monitoring.sh")
    if [[ -n "$pids" ]]; then
        echo "$pids" | xargs kill -TERM
        log_success "监控服务已停止"
    else
        log_info "监控服务未运行"
    fi
}

# 显示监控状态
show_monitoring_status() {
    echo -e "${CYAN}=== 系统监控状态 ===${NC}"
    
    if [[ -f "$METRICS_FILE" ]]; then
        local timestamp=$(jq -r '.timestamp' "$METRICS_FILE")
        local cpu_usage=$(jq -r '.system.cpu_usage' "$METRICS_FILE")
        local memory_usage=$(jq -r '.system.memory_usage' "$METRICS_FILE")
        local disk_usage=$(jq -r '.system.disk_usage' "$METRICS_FILE")
        
        echo -e "${GREEN}最后更新: $timestamp${NC}"
        echo -e "${GREEN}CPU使用率: ${cpu_usage}%${NC}"
        echo -e "${GREEN}内存使用率: ${memory_usage}%${NC}"
        echo -e "${GREEN}磁盘使用率: ${disk_usage}%${NC}"
    else
        echo -e "${RED}监控数据不可用${NC}"
    fi
    
    if [[ -f "$ALERTS_FILE" ]]; then
        local alert_count=$(jq '. | length' "$ALERTS_FILE" 2>/dev/null || echo "0")
        if [[ "$alert_count" -gt 0 ]]; then
            echo -e "${RED}活跃告警: $alert_count${NC}"
        else
            echo -e "${GREEN}无活跃告警${NC}"
        fi
    fi
}
