#!/bin/bash

# 防火墙管理模块
# 负责防火墙规则管理、端口管理、服务管理等防火墙相关功能

# 防火墙配置变量
FIREWALL_CONFIG_DIR="${CONFIG_DIR}/firewall"
FIREWALL_RULES_FILE="${FIREWALL_CONFIG_DIR}/rules.conf"
FIREWALL_LOG_FILE="${LOG_DIR}/firewall.log"

# 支持的防火墙类型
SUPPORTED_FIREWALLS=("ufw" "firewalld" "nftables" "iptables")

# 防火墙状态
FIREWALL_TYPE=""
FIREWALL_STATUS=""
FIREWALL_RULES=()

# 初始化防火墙管理
init_firewall_management() {
    log_info "初始化防火墙管理..."
    
    # 创建配置目录
    mkdir -p "$FIREWALL_CONFIG_DIR"
    
    # 检测防火墙类型
    detect_firewall_type
    
    # 创建防火墙规则文件
    create_firewall_rules_file
    
    # 加载现有规则
    load_firewall_rules
    
    # 自动配置功能端口
    auto_configure_feature_ports
    
    log_info "防火墙管理初始化完成"
}

# 自动配置功能端口
auto_configure_feature_ports() {
    log_info "自动配置功能端口..."
    
    if [[ -n "$FIREWALL_TYPE" ]]; then
        # 开放必需端口
        open_essential_ports
        
        # 根据安装的功能开放相应端口
        if [[ "$INSTALL_WIREGUARD" == "true" ]]; then
            open_wireguard_ports
        fi
        
        if [[ "$INSTALL_BIRD" == "true" ]]; then
            open_bgp_ports
        fi
        
        if [[ "$INSTALL_WEB_INTERFACE" == "true" ]]; then
            open_web_ports
        fi
        
        if [[ "$INSTALL_MONITORING" == "true" ]]; then
            open_monitoring_ports
        fi
        
        if [[ "$INSTALL_CLIENT_AUTO_INSTALL" == "true" ]]; then
            open_api_ports
        fi
        
        log_info "功能端口自动配置完成"
    else
        log_warn "未检测到支持的防火墙类型，跳过端口配置"
    fi
}

# 开放必需端口
open_essential_ports() {
    log_info "开放必需端口..."
    
    local essential_ports=(
        "22/tcp"    # SSH
        "53/udp"    # DNS
        "80/tcp"    # HTTP
        "443/tcp"   # HTTPS
        "123/udp"   # NTP
    )
    
    for port in "${essential_ports[@]}"; do
        add_firewall_rule "allow" "$port" "essential"
    done
}

# 开放WireGuard端口
open_wireguard_ports() {
    log_info "开放WireGuard端口..."
    
    local wireguard_ports=(
        "51820/udp" # WireGuard
    )
    
    for port in "${wireguard_ports[@]}"; do
        add_firewall_rule "allow" "$port" "wireguard"
    done
}

# 开放BGP端口
open_bgp_ports() {
    log_info "开放BGP端口..."
    
    local bgp_ports=(
        "179/tcp"   # BGP
    )
    
    for port in "${bgp_ports[@]}"; do
        add_firewall_rule "allow" "$port" "bgp"
    done
}

# 开放Web管理端口
open_web_ports() {
    log_info "开放Web管理端口..."
    
    local web_ports=(
        "8080/tcp"  # Web管理界面
        "8443/tcp"  # HTTPS Web管理界面
    )
    
    for port in "${web_ports[@]}"; do
        add_firewall_rule "allow" "$port" "web_management"
    done
}

# 开放监控端口
open_monitoring_ports() {
    log_info "开放监控端口..."
    
    local monitoring_ports=(
        "9090/tcp"  # 监控系统
    )
    
    for port in "${monitoring_ports[@]}"; do
        add_firewall_rule "allow" "$port" "monitoring"
    done
}

# 开放API端口
open_api_ports() {
    log_info "开放API端口..."
    
    local api_ports=(
        "3000/tcp"  # API服务
    )
    
    for port in "${api_ports[@]}"; do
        add_firewall_rule "allow" "$port" "api"
    done
}

# 检测防火墙类型
detect_firewall_type() {
    log_info "检测防火墙类型..."
    
    # 检查UFW
    if command -v ufw &> /dev/null; then
        FIREWALL_TYPE="ufw"
        FIREWALL_STATUS=$(ufw status | head -1 | awk '{print $2}')
        log_info "检测到UFW防火墙，状态: $FIREWALL_STATUS"
        return 0
    fi
    
    # 检查firewalld
    if command -v firewall-cmd &> /dev/null; then
        FIREWALL_TYPE="firewalld"
        FIREWALL_STATUS=$(firewall-cmd --state 2>/dev/null || echo "not running")
        log_info "检测到firewalld防火墙，状态: $FIREWALL_STATUS"
        return 0
    fi
    
    # 检查nftables
    if command -v nft &> /dev/null; then
        FIREWALL_TYPE="nftables"
        FIREWALL_STATUS="available"
        log_info "检测到nftables防火墙"
        return 0
    fi
    
    # 检查iptables
    if command -v iptables &> /dev/null; then
        FIREWALL_TYPE="iptables"
        FIREWALL_STATUS="available"
        log_info "检测到iptables防火墙"
        return 0
    fi
    
    log_warn "未检测到支持的防火墙系统"
    FIREWALL_TYPE="none"
    FIREWALL_STATUS="not available"
}

# 创建防火墙规则文件
create_firewall_rules_file() {
    if [[ ! -f "$FIREWALL_RULES_FILE" ]]; then
        cat > "$FIREWALL_RULES_FILE" << EOF
# IPv6 WireGuard Manager 防火墙规则
# 生成时间: $(get_timestamp)
# 防火墙类型: $FIREWALL_TYPE

# 默认规则
DEFAULT_POLICY_INPUT=ACCEPT
DEFAULT_POLICY_FORWARD=ACCEPT
DEFAULT_POLICY_OUTPUT=ACCEPT

# WireGuard规则
WIREGUARD_PORT=51820
WIREGUARD_INTERFACE=wg0

# Web管理规则
WEB_PORT=8080

# 允许的端口
ALLOWED_PORTS=22,80,443,51820,8080

# 允许的服务
ALLOWED_SERVICES=ssh,http,https,wireguard

# 自定义规则
# 格式: action|protocol|port|source|destination|description
# 示例: ALLOW|tcp|80|0.0.0.0/0|0.0.0.0/0|HTTP服务
EOF
        log_info "防火墙规则文件已创建: $FIREWALL_RULES_FILE"
    fi
}

# 加载防火墙规则
load_firewall_rules() {
    if [[ -f "$FIREWALL_RULES_FILE" ]]; then
        source "$FIREWALL_RULES_FILE"
        log_info "防火墙规则已加载"
    fi
}

# 防火墙管理主菜单
firewall_management_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 防火墙管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看防火墙状态"
        echo -e "${GREEN}2.${NC} 管理防火墙规则"
        echo -e "${GREEN}3.${NC} 管理端口"
        echo -e "${GREEN}4.${NC} 管理服务"
        echo -e "${GREEN}5.${NC} 管理区域 (firewalld)"
        echo -e "${GREEN}6.${NC} 查看防火墙日志"
        echo -e "${GREEN}7.${NC} 配置备份"
        echo -e "${GREEN}8.${NC} 配置恢复"
        echo -e "${GREEN}9.${NC} 防火墙诊断"
        echo -e "${GREEN}10.${NC} 安全扫描"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -p "请选择操作 [0-10]: " choice
        
        case $choice in
            1) show_firewall_status ;;
            2) manage_firewall_rules ;;
            3) manage_firewall_ports ;;
            4) manage_firewall_services ;;
            5) manage_firewall_zones ;;
            6) show_firewall_logs ;;
            7) backup_firewall_config ;;
            8) restore_firewall_config ;;
            9) firewall_diagnostics ;;
            10) firewall_security_scan ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 显示防火墙状态
show_firewall_status() {
    log_info "防火墙状态信息:"
    echo "----------------------------------------"
    
    echo "防火墙类型: $FIREWALL_TYPE"
    echo "防火墙状态: $FIREWALL_STATUS"
    echo
    
    case "$FIREWALL_TYPE" in
        "ufw")
            echo "UFW状态:"
            ufw status verbose
            ;;
        "firewalld")
            echo "firewalld状态:"
            firewall-cmd --state
            echo
            echo "活动区域:"
            firewall-cmd --get-active-zones
            echo
            echo "默认区域:"
            firewall-cmd --get-default-zone
            ;;
        "nftables")
            echo "nftables状态:"
            nft list tables 2>/dev/null || echo "没有活动表"
            ;;
        "iptables")
            echo "iptables状态:"
            iptables -L -n | head -20
            ;;
        *)
            echo "未检测到防火墙系统"
            ;;
    esac
}

# 管理防火墙规则
manage_firewall_rules() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 防火墙规则管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看所有规则"
        echo -e "${GREEN}2.${NC} 添加规则"
        echo -e "${GREEN}3.${NC} 删除规则"
        echo -e "${GREEN}4.${NC} 修改规则"
        echo -e "${GREEN}5.${NC} 导入规则"
        echo -e "${GREEN}6.${NC} 导出规则"
        echo -e "${GREEN}7.${NC} 重置规则"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -p "请选择操作 [0-7]: " choice
        
        case $choice in
            1) list_firewall_rules ;;
            2) add_firewall_rule ;;
            3) remove_firewall_rule ;;
            4) modify_firewall_rule ;;
            5) import_firewall_rules ;;
            6) export_firewall_rules ;;
            7) reset_firewall_rules ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 列出防火墙规则
list_firewall_rules() {
    log_info "防火墙规则列表:"
    echo "----------------------------------------"
    
    case "$FIREWALL_TYPE" in
        "ufw")
            ufw status numbered
            ;;
        "firewalld")
            echo "富规则:"
            firewall-cmd --list-rich-rules
            echo
            echo "端口规则:"
            firewall-cmd --list-ports
            echo
            echo "服务规则:"
            firewall-cmd --list-services
            ;;
        "nftables")
            nft list ruleset
            ;;
        "iptables")
            echo "IPv4规则:"
            iptables -L -n -v
            echo
            echo "IPv6规则:"
            ip6tables -L -n -v
            ;;
        *)
            log_info "没有活动的防火墙系统"
            ;;
    esac
}

# 添加防火墙规则
add_firewall_rule() {
    echo -e "${SECONDARY_COLOR}=== 添加防火墙规则 ===${NC}"
    echo
    
    local action=$(show_selection "动作" "ALLOW" "DENY" "REJECT")
    local protocol=$(show_selection "协议" "tcp" "udp" "icmp" "all")
    local port=$(show_input "端口" "")
    local source=$(show_input "源地址" "0.0.0.0/0")
    local destination=$(show_input "目标地址" "0.0.0.0/0")
    local description=$(show_input "描述" "")
    
    if [[ -z "$action" ]] || [[ -z "$protocol" ]]; then
        show_error "动作和协议不能为空"
        return 1
    fi
    
    # 根据防火墙类型添加规则
    case "$FIREWALL_TYPE" in
        "ufw")
            add_ufw_rule "$action" "$protocol" "$port" "$source" "$destination" "$description"
            ;;
        "firewalld")
            add_firewalld_rule "$action" "$protocol" "$port" "$source" "$destination" "$description"
            ;;
        "nftables")
            add_nftables_rule "$action" "$protocol" "$port" "$source" "$destination" "$description"
            ;;
        "iptables")
            add_iptables_rule "$action" "$protocol" "$port" "$source" "$destination" "$description"
            ;;
        *)
            show_error "不支持的防火墙类型: $FIREWALL_TYPE"
            return 1
            ;;
    esac
    
    # 记录规则到文件
    echo "$action|$protocol|$port|$source|$destination|$description|$(get_timestamp)" >> "$FIREWALL_RULES_FILE"
    
    log_info "防火墙规则添加成功"
}

# 添加UFW规则
add_ufw_rule() {
    local action="$1"
    local protocol="$2"
    local port="$3"
    local source="$4"
    local destination="$5"
    local description="$6"
    
    local ufw_cmd="ufw"
    
    # 设置动作
    case "$action" in
        "ALLOW") ufw_cmd="$ufw_cmd allow" ;;
        "DENY") ufw_cmd="$ufw_cmd deny" ;;
        "REJECT") ufw_cmd="$ufw_cmd reject" ;;
    esac
    
    # 添加协议和端口
    if [[ -n "$port" ]]; then
        ufw_cmd="$ufw_cmd $port/$protocol"
    else
        ufw_cmd="$ufw_cmd $protocol"
    fi
    
    # 添加源地址
    if [[ "$source" != "0.0.0.0/0" ]]; then
        ufw_cmd="$ufw_cmd from $source"
    fi
    
    # 添加描述
    if [[ -n "$description" ]]; then
        ufw_cmd="$ufw_cmd comment '$description'"
    fi
    
    # 执行命令
    eval "$ufw_cmd"
}

# 添加firewalld规则
add_firewalld_rule() {
    local action="$1"
    local protocol="$2"
    local port="$3"
    local source="$4"
    local destination="$5"
    local description="$6"
    
    local firewall_cmd="firewall-cmd --permanent"
    
    # 添加端口规则
    if [[ -n "$port" ]]; then
        firewall_cmd="$firewall_cmd --add-port=$port/$protocol"
    fi
    
    # 添加富规则
    if [[ "$source" != "0.0.0.0/0" ]] || [[ "$destination" != "0.0.0.0/0" ]]; then
        local rich_rule="rule"
        
        case "$action" in
            "ALLOW") rich_rule="$rich_rule action=\"accept\"" ;;
            "DENY") rich_rule="$rich_rule action=\"drop\"" ;;
            "REJECT") rich_rule="$rich_rule action=\"reject\"" ;;
        esac
        
        if [[ "$source" != "0.0.0.0/0" ]]; then
            rich_rule="$rich_rule source address=\"$source\""
        fi
        
        if [[ "$destination" != "0.0.0.0/0" ]]; then
            rich_rule="$rich_rule destination address=\"$destination\""
        fi
        
        if [[ -n "$port" ]]; then
            rich_rule="$rich_rule port protocol=\"$protocol\" port=\"$port\""
        fi
        
        firewall_cmd="$firewall_cmd --add-rich-rule='$rich_rule'"
    fi
    
    # 执行命令
    eval "$firewall_cmd"
    firewall-cmd --reload
}

# 添加nftables规则
add_nftables_rule() {
    local action="$1"
    local protocol="$2"
    local port="$3"
    local source="$4"
    local destination="$5"
    local description="$6"
    
    # 这里可以添加nftables规则添加逻辑
    log_info "nftables规则添加功能待实现"
}

# 添加iptables规则
add_iptables_rule() {
    local action="$1"
    local protocol="$2"
    local port="$3"
    local source="$4"
    local destination="$5"
    local description="$6"
    
    local iptables_cmd="iptables"
    
    # 设置动作
    case "$action" in
        "ALLOW") iptables_cmd="$iptables_cmd -A INPUT -j ACCEPT" ;;
        "DENY") iptables_cmd="$iptables_cmd -A INPUT -j DROP" ;;
        "REJECT") iptables_cmd="$iptables_cmd -A INPUT -j REJECT" ;;
    esac
    
    # 添加协议
    if [[ "$protocol" != "all" ]]; then
        iptables_cmd="$iptables_cmd -p $protocol"
    fi
    
    # 添加端口
    if [[ -n "$port" ]]; then
        iptables_cmd="$iptables_cmd --dport $port"
    fi
    
    # 添加源地址
    if [[ "$source" != "0.0.0.0/0" ]]; then
        iptables_cmd="$iptables_cmd -s $source"
    fi
    
    # 添加目标地址
    if [[ "$destination" != "0.0.0.0/0" ]]; then
        iptables_cmd="$iptables_cmd -d $destination"
    fi
    
    # 添加注释
    if [[ -n "$description" ]]; then
        iptables_cmd="$iptables_cmd -m comment --comment '$description'"
    fi
    
    # 执行命令
    eval "$iptables_cmd"
}

# 删除防火墙规则
remove_firewall_rule() {
    echo -e "${SECONDARY_COLOR}=== 删除防火墙规则 ===${NC}"
    echo
    
    # 显示规则列表
    list_firewall_rules
    echo
    
    local rule_id=$(show_input "要删除的规则ID" "")
    
    if [[ -z "$rule_id" ]]; then
        show_error "规则ID不能为空"
        return 1
    fi
    
    case "$FIREWALL_TYPE" in
        "ufw")
            ufw --force delete "$rule_id"
            ;;
        "firewalld")
            # firewalld规则删除需要更复杂的逻辑
            log_info "firewalld规则删除功能待实现"
            ;;
        "nftables")
            # nftables规则删除需要更复杂的逻辑
            log_info "nftables规则删除功能待实现"
            ;;
        "iptables")
            # iptables规则删除需要更复杂的逻辑
            log_info "iptables规则删除功能待实现"
            ;;
        *)
            show_error "不支持的防火墙类型: $FIREWALL_TYPE"
            return 1
            ;;
    esac
    
    log_info "防火墙规则删除成功"
}

# 管理防火墙端口
manage_firewall_ports() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 端口管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看开放端口"
        echo -e "${GREEN}2.${NC} 开放端口"
        echo -e "${GREEN}3.${NC} 关闭端口"
        echo -e "${GREEN}4.${NC} 批量开放端口"
        echo -e "${GREEN}5.${NC} 端口扫描"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -p "请选择操作 [0-5]: " choice
        
        case $choice in
            1) list_open_ports ;;
            2) open_port ;;
            3) close_port ;;
            4) batch_open_ports ;;
            5) port_scan ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 列出开放端口
list_open_ports() {
    log_info "开放端口列表:"
    echo "----------------------------------------"
    
    case "$FIREWALL_TYPE" in
        "ufw")
            ufw status | grep -E "(ALLOW|DENY|REJECT)"
            ;;
        "firewalld")
            firewall-cmd --list-ports
            ;;
        "nftables")
            nft list ruleset | grep -E "tcp|udp" | grep -E "dport|sport"
            ;;
        "iptables")
            iptables -L -n | grep -E "tcp|udp" | grep -E "dpt|spt"
            ;;
        *)
            # 使用netstat查看监听端口
            netstat -tuln | grep LISTEN
            ;;
    esac
}

# 开放端口
open_port() {
    echo -e "${SECONDARY_COLOR}=== 开放端口 ===${NC}"
    echo
    
    local port=$(show_input "端口号" "" "validate_port")
    local protocol=$(show_selection "协议" "tcp" "udp" "both")
    local source=$(show_input "源地址" "0.0.0.0/0")
    
    if [[ -z "$port" ]]; then
        show_error "端口号不能为空"
        return 1
    fi
    
    case "$FIREWALL_TYPE" in
        "ufw")
            if [[ "$protocol" == "both" ]]; then
                ufw allow "$port/tcp"
                ufw allow "$port/udp"
            else
                ufw allow "$port/$protocol"
            fi
            ;;
        "firewalld")
            if [[ "$protocol" == "both" ]]; then
                firewall-cmd --permanent --add-port="$port/tcp"
                firewall-cmd --permanent --add-port="$port/udp"
            else
                firewall-cmd --permanent --add-port="$port/$protocol"
            fi
            firewall-cmd --reload
            ;;
        "nftables")
            # nftables端口开放逻辑
            log_info "nftables端口开放功能待实现"
            ;;
        "iptables")
            if [[ "$protocol" == "both" ]]; then
                iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
                iptables -A INPUT -p udp --dport "$port" -j ACCEPT
            else
                iptables -A INPUT -p "$protocol" --dport "$port" -j ACCEPT
            fi
            ;;
        *)
            show_error "不支持的防火墙类型: $FIREWALL_TYPE"
            return 1
            ;;
    esac
    
    log_info "端口开放成功: $port/$protocol"
}

# 关闭端口
close_port() {
    echo -e "${SECONDARY_COLOR}=== 关闭端口 ===${NC}"
    echo
    
    local port=$(show_input "端口号" "" "validate_port")
    local protocol=$(show_selection "协议" "tcp" "udp" "both")
    
    if [[ -z "$port" ]]; then
        show_error "端口号不能为空"
        return 1
    fi
    
    case "$FIREWALL_TYPE" in
        "ufw")
            if [[ "$protocol" == "both" ]]; then
                ufw delete allow "$port/tcp"
                ufw delete allow "$port/udp"
            else
                ufw delete allow "$port/$protocol"
            fi
            ;;
        "firewalld")
            if [[ "$protocol" == "both" ]]; then
                firewall-cmd --permanent --remove-port="$port/tcp"
                firewall-cmd --permanent --remove-port="$port/udp"
            else
                firewall-cmd --permanent --remove-port="$port/$protocol"
            fi
            firewall-cmd --reload
            ;;
        "nftables")
            # nftables端口关闭逻辑
            log_info "nftables端口关闭功能待实现"
            ;;
        "iptables")
            if [[ "$protocol" == "both" ]]; then
                iptables -D INPUT -p tcp --dport "$port" -j ACCEPT
                iptables -D INPUT -p udp --dport "$port" -j ACCEPT
            else
                iptables -D INPUT -p "$protocol" --dport "$port" -j ACCEPT
            fi
            ;;
        *)
            show_error "不支持的防火墙类型: $FIREWALL_TYPE"
            return 1
            ;;
    esac
    
    log_info "端口关闭成功: $port/$protocol"
}

# 管理防火墙服务
manage_firewall_services() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 服务管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看允许的服务"
        echo -e "${GREEN}2.${NC} 添加服务"
        echo -e "${GREEN}3.${NC} 删除服务"
        echo -e "${GREEN}4.${NC} 服务状态检查"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -p "请选择操作 [0-4]: " choice
        
        case $choice in
            1) list_allowed_services ;;
            2) add_service ;;
            3) remove_service ;;
            4) check_service_status ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 列出允许的服务
list_allowed_services() {
    log_info "允许的服务列表:"
    echo "----------------------------------------"
    
    case "$FIREWALL_TYPE" in
        "ufw")
            ufw status | grep -E "ALLOW.*tcp|ALLOW.*udp"
            ;;
        "firewalld")
            firewall-cmd --list-services
            ;;
        "nftables")
            nft list ruleset | grep -E "tcp|udp"
            ;;
        "iptables")
            iptables -L -n | grep -E "tcp|udp"
            ;;
        *)
            log_info "当前防火墙类型不支持服务管理"
            ;;
    esac
}

# 添加服务
add_service() {
    echo -e "${SECONDARY_COLOR}=== 添加服务 ===${NC}"
    echo
    
    local service=$(show_input "服务名称" "")
    
    if [[ -z "$service" ]]; then
        show_error "服务名称不能为空"
        return 1
    fi
    
    case "$FIREWALL_TYPE" in
        "ufw")
            ufw allow "$service"
            ;;
        "firewalld")
            firewall-cmd --permanent --add-service="$service"
            firewall-cmd --reload
            ;;
        "nftables")
            # nftables服务添加逻辑
            log_info "nftables服务添加功能待实现"
            ;;
        "iptables")
            # iptables服务添加逻辑
            log_info "iptables服务添加功能待实现"
            ;;
        *)
            show_error "不支持的防火墙类型: $FIREWALL_TYPE"
            return 1
            ;;
    esac
    
    log_info "服务添加成功: $service"
}

# 删除服务
remove_service() {
    echo -e "${SECONDARY_COLOR}=== 删除服务 ===${NC}"
    echo
    
    local service=$(show_input "服务名称" "")
    
    if [[ -z "$service" ]]; then
        show_error "服务名称不能为空"
        return 1
    fi
    
    case "$FIREWALL_TYPE" in
        "ufw")
            ufw delete allow "$service"
            ;;
        "firewalld")
            firewall-cmd --permanent --remove-service="$service"
            firewall-cmd --reload
            ;;
        "nftables")
            # nftables服务删除逻辑
            log_info "nftables服务删除功能待实现"
            ;;
        "iptables")
            # iptables服务删除逻辑
            log_info "iptables服务删除功能待实现"
            ;;
        *)
            show_error "不支持的防火墙类型: $FIREWALL_TYPE"
            return 1
            ;;
    esac
    
    log_info "服务删除成功: $service"
}

# 管理防火墙区域 (firewalld)
manage_firewall_zones() {
    if [[ "$FIREWALL_TYPE" != "firewalld" ]]; then
        show_error "只有firewalld支持区域管理"
        return 1
    fi
    
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 区域管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看所有区域"
        echo -e "${GREEN}2.${NC} 查看活动区域"
        echo -e "${GREEN}3.${NC} 设置默认区域"
        echo -e "${GREEN}4.${NC} 添加区域"
        echo -e "${GREEN}5.${NC} 删除区域"
        echo -e "${GREEN}6.${NC} 区域配置"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -p "请选择操作 [0-6]: " choice
        
        case $choice in
            1) list_all_zones ;;
            2) list_active_zones ;;
            3) set_default_zone ;;
            4) add_zone ;;
            5) remove_zone ;;
            6) configure_zone ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 列出所有区域
list_all_zones() {
    log_info "所有区域列表:"
    echo "----------------------------------------"
    firewall-cmd --get-zones
}

# 列出活动区域
list_active_zones() {
    log_info "活动区域列表:"
    echo "----------------------------------------"
    firewall-cmd --get-active-zones
}

# 设置默认区域
set_default_zone() {
    echo -e "${SECONDARY_COLOR}=== 设置默认区域 ===${NC}"
    echo
    
    local zone=$(show_input "区域名称" "")
    
    if [[ -z "$zone" ]]; then
        show_error "区域名称不能为空"
        return 1
    fi
    
    firewall-cmd --set-default-zone="$zone"
    log_info "默认区域设置成功: $zone"
}

# 查看防火墙日志
show_firewall_logs() {
    log_info "防火墙日志:"
    echo "----------------------------------------"
    
    case "$FIREWALL_TYPE" in
        "ufw")
            journalctl -u ufw -f --no-pager | tail -50
            ;;
        "firewalld")
            journalctl -u firewalld -f --no-pager | tail -50
            ;;
        "nftables")
            journalctl -u nftables -f --no-pager | tail -50
            ;;
        "iptables")
            # iptables日志通常在系统日志中
            journalctl | grep -i iptables | tail -50
            ;;
        *)
            log_info "无法获取防火墙日志"
            ;;
    esac
}

# 防火墙配置备份
backup_firewall_config() {
    log_info "备份防火墙配置..."
    
    local backup_dir="${BACKUP_DIR}/firewall"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${backup_dir}/firewall_config_${timestamp}.tar.gz"
    
    mkdir -p "$backup_dir"
    
    case "$FIREWALL_TYPE" in
        "ufw")
            ufw status > "${backup_dir}/ufw_status_${timestamp}.txt"
            ;;
        "firewalld")
            firewall-cmd --list-all > "${backup_dir}/firewalld_config_${timestamp}.txt"
            ;;
        "nftables")
            nft list ruleset > "${backup_dir}/nftables_rules_${timestamp}.txt"
            ;;
        "iptables")
            iptables-save > "${backup_dir}/iptables_rules_${timestamp}.txt"
            ip6tables-save > "${backup_dir}/ip6tables_rules_${timestamp}.txt"
            ;;
    esac
    
    # 备份配置文件
    tar -czf "$backup_file" -C "$FIREWALL_CONFIG_DIR" . 2>/dev/null
    
    log_info "防火墙配置备份成功: $backup_file"
}

# 防火墙配置恢复
restore_firewall_config() {
    echo -e "${SECONDARY_COLOR}=== 恢复防火墙配置 ===${NC}"
    echo
    
    local backup_file=$(show_input "备份文件路径" "")
    
    if [[ -z "$backup_file" ]] || [[ ! -f "$backup_file" ]]; then
        show_error "备份文件不存在"
        return 1
    fi
    
    # 备份当前配置
    backup_firewall_config
    
    # 恢复配置
    tar -xzf "$backup_file" -C "$FIREWALL_CONFIG_DIR" 2>/dev/null
    
    log_info "防火墙配置恢复成功"
}

# 防火墙诊断
firewall_diagnostics() {
    log_info "防火墙诊断:"
    echo "----------------------------------------"
    
    # 检查防火墙状态
    echo "防火墙状态检查:"
    show_firewall_status
    echo
    
    # 检查端口连通性
    echo "端口连通性检查:"
    local test_ports=("22" "80" "443" "51820")
    for port in "${test_ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            show_success "端口 $port 正在监听"
        else
            show_warning "端口 $port 未监听"
        fi
    done
    echo
    
    # 检查规则数量
    echo "规则数量统计:"
    case "$FIREWALL_TYPE" in
        "ufw")
            local rule_count=$(ufw status | grep -c "ALLOW\|DENY\|REJECT")
            echo "UFW规则数量: $rule_count"
            ;;
        "firewalld")
            local port_count=$(firewall-cmd --list-ports | wc -w)
            local service_count=$(firewall-cmd --list-services | wc -w)
            echo "firewalld端口规则: $port_count"
            echo "firewalld服务规则: $service_count"
            ;;
        "nftables")
            local rule_count=$(nft list ruleset | grep -c "chain")
            echo "nftables链数量: $rule_count"
            ;;
        "iptables")
            local rule_count=$(iptables -L | grep -c "Chain")
            echo "iptables链数量: $rule_count"
            ;;
    esac
}

# 防火墙安全扫描
firewall_security_scan() {
    log_info "防火墙安全扫描:"
    echo "----------------------------------------"
    
    # 检查开放的危险端口
    echo "危险端口检查:"
    local dangerous_ports=("21" "23" "135" "139" "445" "1433" "3389")
    for port in "${dangerous_ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            show_warning "发现危险端口开放: $port"
        fi
    done
    echo
    
    # 检查SSH配置
    echo "SSH安全检查:"
    if netstat -tuln | grep -q ":22 "; then
        show_success "SSH服务正在运行"
        # 可以添加更多SSH安全检查
    else
        show_warning "SSH服务未运行"
    fi
    echo
    
    # 检查防火墙日志中的异常
    echo "异常连接检查:"
    if [[ -f "/var/log/auth.log" ]]; then
        local failed_attempts=$(grep "Failed password" /var/log/auth.log | wc -l)
        if [[ $failed_attempts -gt 100 ]]; then
            show_warning "发现大量SSH登录失败尝试: $failed_attempts"
        else
            show_success "SSH登录失败次数正常: $failed_attempts"
        fi
    fi
}

# 批量开放端口
batch_open_ports() {
    echo -e "${SECONDARY_COLOR}=== 批量开放端口 ===${NC}"
    echo
    
    local ports=$(show_input "端口列表 (用逗号分隔)" "")
    
    if [[ -z "$ports" ]]; then
        show_error "端口列表不能为空"
        return 1
    fi
    
    IFS=',' read -ra port_array <<< "$ports"
    
    for port in "${port_array[@]}"; do
        port=$(trim "$port")
        if validate_port "$port"; then
            open_port "$port" "tcp" "0.0.0.0/0"
        else
            show_warning "无效端口: $port"
        fi
    done
    
    log_info "批量端口开放完成"
}

# 端口扫描
port_scan() {
    echo -e "${SECONDARY_COLOR}=== 端口扫描 ===${NC}"
    echo
    
    local target=$(show_input "目标IP地址" "")
    local port_range=$(show_input "端口范围 (如: 1-1000)" "1-1000")
    
    if [[ -z "$target" ]]; then
        show_error "目标IP地址不能为空"
        return 1
    fi
    
    log_info "扫描目标: $target, 端口范围: $port_range"
    
    if command -v nmap &> /dev/null; then
        nmap -p "$port_range" "$target"
    else
        # 使用简单的端口扫描
        local start_port=$(echo "$port_range" | cut -d'-' -f1)
        local end_port=$(echo "$port_range" | cut -d'-' -f2)
        
        for ((port=start_port; port<=end_port; port++)); do
            if timeout 1 bash -c "</dev/tcp/$target/$port" 2>/dev/null; then
                show_success "端口 $port 开放"
            fi
        done
    fi
}

# 检查服务状态
check_service_status() {
    log_info "服务状态检查:"
    echo "----------------------------------------"
    
    local services=("ssh" "http" "https" "dns" "ntp")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            show_success "$service: 运行中"
        else
            show_warning "$service: 未运行"
        fi
    done
}

# 修改防火墙规则
modify_firewall_rule() {
    log_info "防火墙规则修改功能待实现"
}

# 导入防火墙规则
import_firewall_rules() {
    log_info "防火墙规则导入功能待实现"
}

# 导出防火墙规则
export_firewall_rules() {
    log_info "防火墙规则导出功能待实现"
}

# 重置防火墙规则
reset_firewall_rules() {
    if show_confirm "确认重置所有防火墙规则"; then
        case "$FIREWALL_TYPE" in
            "ufw")
                ufw --force reset
                ;;
            "firewalld")
                firewall-cmd --reload
                ;;
            "nftables")
                nft flush ruleset
                ;;
            "iptables")
                iptables -F
                iptables -X
                iptables -t nat -F
                iptables -t nat -X
                ;;
        esac
        
        log_info "防火墙规则重置成功"
    fi
}

# 添加区域
add_zone() {
    log_info "添加区域功能待实现"
}

# 删除区域
remove_zone() {
    log_info "删除区域功能待实现"
}

# 配置区域
configure_zone() {
    log_info "配置区域功能待实现"
}

# 导出函数
export -f init_firewall_management detect_firewall_type create_firewall_rules_file
export -f load_firewall_rules firewall_management_menu show_firewall_status
export -f manage_firewall_rules list_firewall_rules add_firewall_rule remove_firewall_rule
export -f add_ufw_rule add_firewalld_rule add_nftables_rule add_iptables_rule
export -f manage_firewall_ports list_open_ports open_port close_port batch_open_ports port_scan
export -f manage_firewall_services list_allowed_services add_service remove_service check_service_status
export -f manage_firewall_zones list_all_zones list_active_zones set_default_zone
export -f show_firewall_logs backup_firewall_config restore_firewall_config
export -f firewall_diagnostics firewall_security_scan
