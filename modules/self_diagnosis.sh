#!/bin/bash

# IPv6 WireGuard Manager 自我诊断模块
# 版本: 1.0.0
# 作者: IPv6 WireGuard Manager Team

# 诊断配置
DIAGNOSIS_REPORT_DIR="/var/lib/ipv6-wireguard-manager/diagnosis"
DIAGNOSIS_REPORT_FILE="$DIAGNOSIS_REPORT_DIR/diagnosis_report_$(date +%Y%m%d_%H%M%S).html"

# 诊断结果
DIAGNOSIS_RESULTS=()
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# 初始化诊断系统
init_diagnosis() {
    log_info "初始化自我诊断系统..."
    
    # 创建诊断报告目录
    execute_command "mkdir -p '$DIAGNOSIS_REPORT_DIR'" "创建诊断报告目录" "true"
    
    log_success "自我诊断系统初始化完成"
}

# 系统环境检查
check_system_environment() {
    log_info "检查系统环境..."
    
    # 检查操作系统
    check_operating_system() {
        local os_info=""
        if [[ -f /etc/os-release ]]; then
            os_info=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
        else
            os_info="未知操作系统"
        fi
        
        add_diagnosis_result "操作系统" "$os_info" "info"
    }
    
    # 检查内核版本
    check_kernel_version() {
        local kernel_version=$(uname -r)
        add_diagnosis_result "内核版本" "$kernel_version" "info"
    }
    
    # 检查Bash版本
    check_bash_version() {
        local bash_version=$(bash --version | head -n1)
        local version_num=$(bash --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -n1)
        
        if [[ $(echo "$version_num >= 4.0" | bc -l 2>/dev/null || echo "1") == "1" ]]; then
            add_diagnosis_result "Bash版本" "$bash_version" "pass"
        else
            add_diagnosis_result "Bash版本" "$bash_version (可能不兼容)" "warning"
        fi
    }
    
    # 检查系统资源
    check_system_resources() {
        # 内存检查
        local total_mem=$(free -m | awk 'NR==2{print $2}')
        local available_mem=$(free -m | awk 'NR==2{print $7}')
        local mem_usage=$(( (total_mem - available_mem) * 100 / total_mem ))
        
        if [[ $mem_usage -lt 80 ]]; then
            add_diagnosis_result "内存使用率" "${mem_usage}% (正常)" "pass"
        elif [[ $mem_usage -lt 90 ]]; then
            add_diagnosis_result "内存使用率" "${mem_usage}% (较高)" "warning"
        else
            add_diagnosis_result "内存使用率" "${mem_usage}% (过高)" "fail"
        fi
        
        # 磁盘空间检查
        local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
        if [[ $disk_usage -lt 80 ]]; then
            add_diagnosis_result "磁盘使用率" "${disk_usage}% (正常)" "pass"
        elif [[ $disk_usage -lt 90 ]]; then
            add_diagnosis_result "磁盘使用率" "${disk_usage}% (较高)" "warning"
        else
            add_diagnosis_result "磁盘使用率" "${disk_usage}% (过高)" "fail"
        fi
    }
    
    check_operating_system
    check_kernel_version
    check_bash_version
    check_system_resources
}

# 网络配置检查
check_network_configuration() {
    log_info "检查网络配置..."
    
    # 检查网络接口
    check_network_interfaces() {
        local interfaces=$(ip link show | grep -E "^[0-9]+:" | awk -F': ' '{print $2}' | head -5)
        add_diagnosis_result "网络接口" "$interfaces" "info"
    }
    
    # 检查IP地址配置
    check_ip_addresses() {
        local ipv4_addresses=$(ip -4 addr show | grep inet | awk '{print $2}' | head -3)
        local ipv6_addresses=$(ip -6 addr show | grep inet6 | awk '{print $2}' | head -3)
        
        add_diagnosis_result "IPv4地址" "$ipv4_addresses" "info"
        add_diagnosis_result "IPv6地址" "$ipv6_addresses" "info"
    }
    
    # 检查路由表
    check_routing_table() {
        local default_route=$(ip route | grep default | head -1)
        if [[ -n "$default_route" ]]; then
            add_diagnosis_result "默认路由" "$default_route" "pass"
        else
            add_diagnosis_result "默认路由" "未找到默认路由" "fail"
        fi
    }
    
    # 检查防火墙状态
    check_firewall_status() {
        local firewall_status=""
        
        if command -v ufw &> /dev/null; then
            local ufw_status=$(ufw status | head -1)
            firewall_status="UFW: $ufw_status"
        elif command -v firewall-cmd &> /dev/null; then
            local firewalld_status=$(firewall-cmd --state 2>/dev/null || echo "未知")
            firewall_status="Firewalld: $firewalld_status"
        elif command -v iptables &> /dev/null; then
            local iptables_rules=$(iptables -L | wc -l)
            firewall_status="iptables: $iptables_rules 条规则"
        else
            firewall_status="未检测到防火墙"
        fi
        
        add_diagnosis_result "防火墙状态" "$firewall_status" "info"
    }
    
    check_network_interfaces
    check_ip_addresses
    check_routing_table
    check_firewall_status
}

# 服务状态检查
check_service_status() {
    log_info "检查服务状态..."
    
    # 检查IPv6 WireGuard Manager服务
    check_ipv6_wireguard_manager_service() {
        if systemctl is-active --quiet ipv6-wireguard-manager 2>/dev/null; then
            add_diagnosis_result "IPv6 WireGuard Manager" "运行中" "pass"
        elif systemctl is-enabled --quiet ipv6-wireguard-manager 2>/dev/null; then
            add_diagnosis_result "IPv6 WireGuard Manager" "已启用但未运行" "warning"
        else
            add_diagnosis_result "IPv6 WireGuard Manager" "未安装或未启用" "fail"
        fi
    }
    
    # 检查WireGuard服务
    check_wireguard_service() {
        if systemctl is-active --quiet wg-quick@wg0 2>/dev/null; then
            add_diagnosis_result "WireGuard服务" "运行中" "pass"
        elif systemctl is-enabled --quiet wg-quick@wg0 2>/dev/null; then
            add_diagnosis_result "WireGuard服务" "已启用但未运行" "warning"
        else
            add_diagnosis_result "WireGuard服务" "未安装或未启用" "fail"
        fi
    }
    
    # 检查BIRD服务
    check_bird_service() {
        if systemctl is-active --quiet bird 2>/dev/null; then
            add_diagnosis_result "BIRD服务" "运行中" "pass"
        elif systemctl is-active --quiet bird2 2>/dev/null; then
            add_diagnosis_result "BIRD2服务" "运行中" "pass"
        elif systemctl is-enabled --quiet bird 2>/dev/null || systemctl is-enabled --quiet bird2 2>/dev/null; then
            add_diagnosis_result "BIRD服务" "已启用但未运行" "warning"
        else
            add_diagnosis_result "BIRD服务" "未安装或未启用" "info"
        fi
    }
    
    # 检查Nginx服务
    check_nginx_service() {
        if systemctl is-active --quiet nginx 2>/dev/null; then
            add_diagnosis_result "Nginx服务" "运行中" "pass"
        elif systemctl is-enabled --quiet nginx 2>/dev/null; then
            add_diagnosis_result "Nginx服务" "已启用但未运行" "warning"
        else
            add_diagnosis_result "Nginx服务" "未安装或未启用" "info"
        fi
    }
    
    check_ipv6_wireguard_manager_service
    check_wireguard_service
    check_bird_service
    check_nginx_service
}

# WireGuard配置检查
check_wireguard_configuration() {
    log_info "检查WireGuard配置..."
    
    # 检查WireGuard接口
    check_wireguard_interfaces() {
        if command -v wg &> /dev/null; then
            local interfaces=$(wg show interfaces 2>/dev/null || echo "无")
            add_diagnosis_result "WireGuard接口" "$interfaces" "info"
        else
            add_diagnosis_result "WireGuard接口" "WireGuard未安装" "fail"
        fi
    }
    
    # 检查WireGuard对等体
    check_wireguard_peers() {
        if command -v wg &> /dev/null; then
            local peer_count=$(wg show wg0 peers 2>/dev/null | wc -l)
            add_diagnosis_result "WireGuard对等体" "$peer_count 个" "info"
        else
            add_diagnosis_result "WireGuard对等体" "WireGuard未安装" "fail"
        fi
    }
    
    # 检查WireGuard配置文件
    check_wireguard_config_file() {
        if [[ -f /etc/wireguard/wg0.conf ]]; then
            add_diagnosis_result "WireGuard配置文件" "存在" "pass"
        else
            add_diagnosis_result "WireGuard配置文件" "不存在" "fail"
        fi
    }
    
    # 检查WireGuard密钥
    check_wireguard_keys() {
        local private_key_exists="否"
        local public_key_exists="否"
        
        if [[ -f /etc/wireguard/privatekey ]]; then
            private_key_exists="是"
        fi
        
        if [[ -f /etc/wireguard/publickey ]]; then
            public_key_exists="是"
        fi
        
        add_diagnosis_result "WireGuard私钥" "$private_key_exists" "info"
        add_diagnosis_result "WireGuard公钥" "$public_key_exists" "info"
    }
    
    check_wireguard_interfaces
    check_wireguard_peers
    check_wireguard_config_file
    check_wireguard_keys
}

# BGP配置检查
check_bgp_configuration() {
    log_info "检查BGP配置..."
    
    # 检查BIRD状态
    check_bird_status() {
        if command -v birdc &> /dev/null; then
            local bird_status=$(birdc show status 2>/dev/null | head -1 || echo "BIRD未运行")
            add_diagnosis_result "BIRD状态" "$bird_status" "info"
        else
            add_diagnosis_result "BIRD状态" "BIRD未安装" "info"
        fi
    }
    
    # 检查BGP邻居
    check_bgp_neighbors() {
        if command -v birdc &> /dev/null; then
            local neighbor_count=$(birdc show protocols 2>/dev/null | grep -c "BGP" || echo "0")
            add_diagnosis_result "BGP邻居" "$neighbor_count 个" "info"
        else
            add_diagnosis_result "BGP邻居" "BIRD未安装" "info"
        fi
    }
    
    # 检查BGP路由
    check_bgp_routes() {
        if command -v birdc &> /dev/null; then
            local route_count=$(birdc show route count 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
            add_diagnosis_result "BGP路由" "$route_count 条" "info"
        else
            add_diagnosis_result "BGP路由" "BIRD未安装" "info"
        fi
    }
    
    check_bird_status
    check_bgp_neighbors
    check_bgp_routes
}

# 日志文件检查
check_log_files() {
    log_info "检查日志文件..."
    
    # 检查IPv6 WireGuard Manager日志
    check_manager_logs() {
        local log_file="/var/log/ipv6-wireguard-manager/manager.log"
        if [[ -f "$log_file" ]]; then
            local log_size=$(du -h "$log_file" | cut -f1)
            local log_lines=$(wc -l < "$log_file")
            add_diagnosis_result "管理器日志" "存在 (${log_size}, ${log_lines}行)" "pass"
        else
            add_diagnosis_result "管理器日志" "不存在" "warning"
        fi
    }
    
    # 检查系统日志
    check_system_logs() {
        local journalctl_entries=$(journalctl -u ipv6-wireguard-manager --since "1 hour ago" | wc -l)
        add_diagnosis_result "系统日志" "${journalctl_entries} 条记录(最近1小时)" "info"
    }
    
    # 检查WireGuard日志
    check_wireguard_logs() {
        local wg_logs=$(journalctl -u wg-quick@wg0 --since "1 hour ago" | wc -l)
        add_diagnosis_result "WireGuard日志" "${wg_logs} 条记录(最近1小时)" "info"
    }
    
    check_manager_logs
    check_system_logs
    check_wireguard_logs
}

# 添加诊断结果
add_diagnosis_result() {
    local check_name="$1"
    local result="$2"
    local status="$3"
    
    DIAGNOSIS_RESULTS+=("$check_name|$result|$status")
    ((TOTAL_CHECKS++))
    
    case "$status" in
        "pass")
            ((PASSED_CHECKS++))
            log_success "✓ $check_name: $result"
            ;;
        "warning")
            ((WARNING_CHECKS++))
            log_warn "⚠ $check_name: $result"
            ;;
        "fail")
            ((FAILED_CHECKS++))
            log_error "✗ $check_name: $result"
            ;;
        "info")
            log_info "ℹ $check_name: $result"
            ;;
    esac
}

# 生成诊断报告
generate_diagnosis_report() {
    log_info "生成诊断报告..."
    
    local report_file="$DIAGNOSIS_REPORT_FILE"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>IPv6 WireGuard Manager 诊断报告</title>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .summary { background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .check-item { margin: 10px 0; padding: 10px; border-left: 4px solid #ccc; }
        .check-pass { border-left-color: #4CAF50; background-color: #f1f8e9; }
        .check-warning { border-left-color: #ff9800; background-color: #fff3e0; }
        .check-fail { border-left-color: #f44336; background-color: #ffebee; }
        .check-info { border-left-color: #2196F3; background-color: #e3f2fd; }
        .status-icon { font-weight: bold; }
        .pass { color: #4CAF50; }
        .warning { color: #ff9800; }
        .fail { color: #f44336; }
        .info { color: #2196F3; }
    </style>
</head>
<body>
    <div class="header">
        <h1>IPv6 WireGuard Manager 诊断报告</h1>
        <p>生成时间: $timestamp</p>
    </div>
    
    <div class="summary">
        <h2>诊断摘要</h2>
        <p><strong>总检查项:</strong> $TOTAL_CHECKS</p>
        <p><strong>通过:</strong> $PASSED_CHECKS</p>
        <p><strong>警告:</strong> $WARNING_CHECKS</p>
        <p><strong>失败:</strong> $FAILED_CHECKS</p>
    </div>
    
    <h2>详细检查结果</h2>
EOF
    
    # 添加检查结果
    for result in "${DIAGNOSIS_RESULTS[@]}"; do
        IFS='|' read -r check_name result_text status <<< "$result"
        
        local status_class=""
        local status_icon=""
        
        case "$status" in
            "pass")
                status_class="check-pass"
                status_icon="✓"
                ;;
            "warning")
                status_class="check-warning"
                status_icon="⚠"
                ;;
            "fail")
                status_class="check-fail"
                status_icon="✗"
                ;;
            "info")
                status_class="check-info"
                status_icon="ℹ"
                ;;
        esac
        
        cat >> "$report_file" << EOF
    <div class="check-item $status_class">
        <span class="status-icon $status">$status_icon</span>
        <strong>$check_name:</strong> $result_text
    </div>
EOF
    done
    
    cat >> "$report_file" << EOF
</body>
</html>
EOF
    
    log_success "诊断报告已生成: $report_file"
}

# 运行完整诊断
run_full_diagnosis() {
    log_info "开始完整系统诊断..."
    
    # 初始化诊断系统
    init_diagnosis
    
    # 执行各项检查
    check_system_environment
    check_network_configuration
    check_service_status
    check_wireguard_configuration
    check_bgp_configuration
    check_log_files
    
    # 生成诊断报告
    generate_diagnosis_report
    
    # 显示诊断结果摘要
    echo
    echo -e "${GREEN}=== 诊断结果摘要 ===${NC}"
    echo -e "${GREEN}总检查项: $TOTAL_CHECKS${NC}"
    echo -e "${GREEN}通过: $PASSED_CHECKS${NC}"
    echo -e "${YELLOW}警告: $WARNING_CHECKS${NC}"
    echo -e "${RED}失败: $FAILED_CHECKS${NC}"
    
    if [[ $FAILED_CHECKS -eq 0 && $WARNING_CHECKS -eq 0 ]]; then
        echo -e "${GREEN}🎉 系统状态良好！${NC}"
    elif [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  系统基本正常，但有 $WARNING_CHECKS 个警告${NC}"
    else
        echo -e "${RED}🚨 系统存在问题，需要修复 $FAILED_CHECKS 个错误${NC}"
    fi
}

# 快速诊断
run_quick_diagnosis() {
    log_info "开始快速诊断..."
    
    # 检查关键服务
    local critical_issues=0
    
    if ! systemctl is-active --quiet ipv6-wireguard-manager 2>/dev/null; then
        log_error "IPv6 WireGuard Manager服务未运行"
        ((critical_issues++))
    fi
    
    if ! systemctl is-active --quiet wg-quick@wg0 2>/dev/null; then
        log_warn "WireGuard服务未运行"
    fi
    
    if [[ $critical_issues -eq 0 ]]; then
        log_success "快速诊断通过，系统基本正常"
    else
        log_error "快速诊断发现 $critical_issues 个关键问题"
    fi
}
