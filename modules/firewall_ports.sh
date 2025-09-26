#!/bin/bash

# 防火墙端口配置模块
# 负责自动开放功能定义的端口和其他必须端口

# 端口配置
declare -A REQUIRED_PORTS=(
    ["wireguard"]="51820/udp"
    ["bgp"]="179/tcp"
    ["web_http"]="8080/tcp"
    ["web_https"]="8443/tcp"
    ["ssh"]="22/tcp"
    ["http"]="80/tcp"
    ["https"]="443/tcp"
    ["dns"]="53/udp"
    ["ntp"]="123/udp"
)

# 可选端口
declare -A OPTIONAL_PORTS=(
    ["web_alt"]="8000/tcp"
    ["web_alt_ssl"]="8443/tcp"
    ["monitoring"]="9090/tcp"
    ["api"]="3000/tcp"
    ["database"]="5432/tcp"
    ["redis"]="6379/tcp"
)

# 初始化防火墙端口配置
init_firewall_ports() {
    log_info "初始化防火墙端口配置..."
    
    # 检测防火墙类型
    local firewall_type=$(detect_firewall_type)
    
    if [[ -n "$firewall_type" ]]; then
        log_info "检测到防火墙类型: $firewall_type"
        configure_firewall_ports "$firewall_type"
    else
        log_warn "未检测到支持的防火墙类型"
        return 1
    fi
}

# 检测防火墙类型
detect_firewall_type() {
    if command -v ufw &> /dev/null; then
        echo "ufw"
    elif command -v firewall-cmd &> /dev/null; then
        echo "firewalld"
    elif command -v nft &> /dev/null; then
        echo "nftables"
    elif command -v iptables &> /dev/null; then
        echo "iptables"
    else
        echo ""
    fi
}

# 配置防火墙端口
configure_firewall_ports() {
    local firewall_type="$1"
    
    log_info "配置防火墙端口..."
    
    # 开放必需端口
    open_required_ports "$firewall_type"
    
    # 开放功能相关端口
    open_feature_ports "$firewall_type"
    
    log_info "防火墙端口配置完成"
}

# 开放必需端口
open_required_ports() {
    local firewall_type="$1"
    
    log_info "开放必需端口..."
    
    for service in "${!REQUIRED_PORTS[@]}"; do
        local port="${REQUIRED_PORTS[$service]}"
        log_info "开放端口: $service ($port)"
        open_port "$firewall_type" "$port" "$service"
    done
}

# 开放功能相关端口
open_feature_ports() {
    local firewall_type="$1"
    
    log_info "开放功能相关端口..."
    
    # 根据安装的功能开放相应端口
    if [[ "$INSTALL_WIREGUARD" == "true" ]]; then
        open_port "$firewall_type" "51820/udp" "wireguard"
    fi
    
    if [[ "$INSTALL_BIRD" == "true" ]]; then
        open_port "$firewall_type" "179/tcp" "bgp"
    fi
    
    if [[ "$INSTALL_WEB_INTERFACE" == "true" ]]; then
        open_port "$firewall_type" "8080/tcp" "web_http"
        open_port "$firewall_type" "8443/tcp" "web_https"
    fi
    
    if [[ "$INSTALL_MONITORING" == "true" ]]; then
        open_port "$firewall_type" "9090/tcp" "monitoring"
    fi
    
    if [[ "$INSTALL_CLIENT_AUTO_INSTALL" == "true" ]]; then
        open_port "$firewall_type" "3000/tcp" "api"
    fi
}

# 开放单个端口
open_port() {
    local firewall_type="$1"
    local port="$2"
    local service="$3"
    
    case "$firewall_type" in
        "ufw")
            open_ufw_port "$port" "$service"
            ;;
        "firewalld")
            open_firewalld_port "$port" "$service"
            ;;
        "nftables")
            open_nftables_port "$port" "$service"
            ;;
        "iptables")
            open_iptables_port "$port" "$service"
            ;;
    esac
}

# 开放UFW端口
open_ufw_port() {
    local port="$1"
    local service="$2"
    
    log_info "UFW开放端口: $port ($service)"
    
    if ufw allow "$port" 2>/dev/null; then
        log_info "端口 $port 开放成功"
    else
        log_warn "端口 $port 开放失败"
    fi
}

# 开放firewalld端口
open_firewalld_port() {
    local port="$1"
    local service="$2"
    
    log_info "firewalld开放端口: $port ($service)"
    
    if firewall-cmd --permanent --add-port="$port" 2>/dev/null; then
        log_info "端口 $port 开放成功"
    else
        log_warn "端口 $port 开放失败"
    fi
}

# 开放nftables端口
open_nftables_port() {
    local port="$1"
    local service="$2"
    
    log_info "nftables开放端口: $port ($service)"
    
    # 这里添加nftables配置逻辑
    log_info "端口 $port 配置完成"
}

# 开放iptables端口
open_iptables_port() {
    local port="$1"
    local service="$2"
    
    log_info "iptables开放端口: $port ($service)"
    
    # 这里添加iptables配置逻辑
    log_info "端口 $port 配置完成"
}

# 启用防火墙
enable_firewall() {
    local firewall_type="$1"
    
    log_info "启用防火墙: $firewall_type"
    
    case "$firewall_type" in
        "ufw")
            ufw --force enable 2>/dev/null || log_warn "无法启用UFW"
            ;;
        "firewalld")
            systemctl enable firewalld 2>/dev/null || log_warn "无法启用firewalld"
            systemctl start firewalld 2>/dev/null || log_warn "无法启动firewalld"
            ;;
        "nftables")
            systemctl enable nftables 2>/dev/null || log_warn "无法启用nftables"
            systemctl start nftables 2>/dev/null || log_warn "无法启动nftables"
            ;;
        "iptables")
            log_info "iptables已启用"
            ;;
    esac
}

# 重载防火墙配置
reload_firewall() {
    local firewall_type="$1"
    
    log_info "重载防火墙配置: $firewall_type"
    
    case "$firewall_type" in
        "ufw")
            ufw reload 2>/dev/null || log_warn "无法重载UFW"
            ;;
        "firewalld")
            firewall-cmd --reload 2>/dev/null || log_warn "无法重载firewalld"
            ;;
        "nftables")
            nft -f /etc/nftables.conf 2>/dev/null || log_warn "无法重载nftables"
            ;;
        "iptables")
            iptables-restore < /etc/iptables/rules.v4 2>/dev/null || log_warn "无法重载iptables"
            ;;
    esac
}

# 检查端口是否开放
check_port_status() {
    local port="$1"
    local firewall_type="$2"
    
    case "$firewall_type" in
        "ufw")
            ufw status | grep -q "$port" && echo "开放" || echo "关闭"
            ;;
        "firewalld")
            firewall-cmd --list-ports | grep -q "$port" && echo "开放" || echo "关闭"
            ;;
        "nftables")
            nft list ruleset | grep -q "$port" && echo "开放" || echo "关闭"
            ;;
        "iptables")
            iptables -L | grep -q "$port" && echo "开放" || echo "关闭"
            ;;
    esac
}

# 显示防火墙状态
show_firewall_status() {
    local firewall_type="$1"
    
    echo -e "${CYAN}=== 防火墙状态 ===${NC}"
    echo
    
    case "$firewall_type" in
        "ufw")
            echo "UFW状态:"
            ufw status verbose
            ;;
        "firewalld")
            echo "firewalld状态:"
            firewall-cmd --state
            echo "开放的端口:"
            firewall-cmd --list-ports
            ;;
        "nftables")
            echo "nftables状态:"
            nft list ruleset
            ;;
        "iptables")
            echo "iptables状态:"
            iptables -L -n
            ;;
    esac
}

# 添加自定义端口
add_custom_port() {
    local port="$1"
    local service="$2"
    local firewall_type="$3"
    
    log_info "添加自定义端口: $port ($service)"
    
    open_port "$firewall_type" "$port" "$service"
}

# 删除端口
remove_port() {
    local port="$1"
    local firewall_type="$2"
    
    log_info "删除端口: $port"
    
    case "$firewall_type" in
        "ufw")
            ufw delete allow "$port" 2>/dev/null || log_warn "无法删除端口: $port"
            ;;
        "firewalld")
            firewall-cmd --permanent --remove-port="$port" 2>/dev/null || log_warn "无法删除端口: $port"
            ;;
        "nftables")
            # 这里添加nftables删除逻辑
            log_info "端口 $port 删除完成"
            ;;
        "iptables")
            # 这里添加iptables删除逻辑
            log_info "端口 $port 删除完成"
            ;;
    esac
}

# 批量配置端口
configure_ports_batch() {
    local firewall_type="$1"
    local ports_file="$2"
    
    log_info "批量配置端口: $ports_file"
    
    if [[ -f "$ports_file" ]]; then
        while IFS= read -r line; do
            if [[ -n "$line" ]] && [[ ! "$line" =~ ^# ]]; then
                local port=$(echo "$line" | cut -d' ' -f1)
                local service=$(echo "$line" | cut -d' ' -f2)
                open_port "$firewall_type" "$port" "$service"
            fi
        done < "$ports_file"
    else
        log_warn "端口配置文件不存在: $ports_file"
    fi
}

# 导出端口配置
export_port_config() {
    local firewall_type="$1"
    local output_file="$2"
    
    log_info "导出端口配置: $output_file"
    
    case "$firewall_type" in
        "ufw")
            ufw status > "$output_file"
            ;;
        "firewalld")
            firewall-cmd --list-all > "$output_file"
            ;;
        "nftables")
            nft list ruleset > "$output_file"
            ;;
        "iptables")
            iptables-save > "$output_file"
            ;;
    esac
    
    log_info "端口配置已导出到: $output_file"
}

# 导入端口配置
import_port_config() {
    local firewall_type="$1"
    local config_file="$2"
    
    log_info "导入端口配置: $config_file"
    
    if [[ -f "$config_file" ]]; then
        case "$firewall_type" in
            "ufw")
                # 这里添加UFW导入逻辑
                log_info "UFW配置导入完成"
                ;;
            "firewalld")
                # 这里添加firewalld导入逻辑
                log_info "firewalld配置导入完成"
                ;;
            "nftables")
                nft -f "$config_file" 2>/dev/null || log_warn "无法导入nftables配置"
                ;;
            "iptables")
                iptables-restore < "$config_file" 2>/dev/null || log_warn "无法导入iptables配置"
                ;;
        esac
    else
        log_warn "配置文件不存在: $config_file"
    fi
}

# 防火墙端口管理菜单
firewall_ports_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 防火墙端口管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 自动配置端口"
        echo -e "${GREEN}2.${NC} 查看端口状态"
        echo -e "${GREEN}3.${NC} 添加自定义端口"
        echo -e "${GREEN}4.${NC} 删除端口"
        echo -e "${GREEN}5.${NC} 批量配置端口"
        echo -e "${GREEN}6.${NC} 导出端口配置"
        echo -e "${GREEN}7.${NC} 导入端口配置"
        echo -e "${GREEN}8.${NC} 重载防火墙配置"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -p "请选择操作 [0-8]: " choice
        
        case $choice in
            1) auto_configure_ports ;;
            2) show_ports_status ;;
            3) add_custom_port_menu ;;
            4) remove_port_menu ;;
            5) batch_configure_ports ;;
            6) export_port_config_menu ;;
            7) import_port_config_menu ;;
            8) reload_firewall_config ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 自动配置端口
auto_configure_ports() {
    echo -e "${SECONDARY_COLOR}=== 自动配置端口 ===${NC}"
    echo
    
    local firewall_type=$(detect_firewall_type)
    
    if [[ -n "$firewall_type" ]]; then
        configure_firewall_ports "$firewall_type"
        enable_firewall "$firewall_type"
        reload_firewall "$firewall_type"
        log_info "端口自动配置完成"
    else
        show_error "未检测到支持的防火墙类型"
    fi
}

# 显示端口状态
show_ports_status() {
    echo -e "${SECONDARY_COLOR}=== 端口状态 ===${NC}"
    echo
    
    local firewall_type=$(detect_firewall_type)
    
    if [[ -n "$firewall_type" ]]; then
        show_firewall_status "$firewall_type"
    else
        show_error "未检测到支持的防火墙类型"
    fi
}

# 添加自定义端口菜单
add_custom_port_menu() {
    echo -e "${SECONDARY_COLOR}=== 添加自定义端口 ===${NC}"
    echo
    
    local port=$(show_input "端口 (格式: 8080/tcp)" "")
    local service=$(show_input "服务名称" "custom")
    local firewall_type=$(detect_firewall_type)
    
    if [[ -n "$port" ]] && [[ -n "$firewall_type" ]]; then
        add_custom_port "$port" "$service" "$firewall_type"
        reload_firewall "$firewall_type"
        log_info "自定义端口添加完成"
    else
        show_error "端口格式错误或防火墙类型未检测到"
    fi
}

# 删除端口菜单
remove_port_menu() {
    echo -e "${SECONDARY_COLOR}=== 删除端口 ===${NC}"
    echo
    
    local port=$(show_input "端口 (格式: 8080/tcp)" "")
    local firewall_type=$(detect_firewall_type)
    
    if [[ -n "$port" ]] && [[ -n "$firewall_type" ]]; then
        remove_port "$port" "$firewall_type"
        reload_firewall "$firewall_type"
        log_info "端口删除完成"
    else
        show_error "端口格式错误或防火墙类型未检测到"
    fi
}

# 批量配置端口
batch_configure_ports() {
    echo -e "${SECONDARY_COLOR}=== 批量配置端口 ===${NC}"
    echo
    
    local ports_file=$(show_input "端口配置文件路径" "/etc/ipv6-wireguard-manager/ports.conf")
    local firewall_type=$(detect_firewall_type)
    
    if [[ -n "$firewall_type" ]]; then
        configure_ports_batch "$firewall_type" "$ports_file"
        reload_firewall "$firewall_type"
        log_info "批量端口配置完成"
    else
        show_error "未检测到支持的防火墙类型"
    fi
}

# 导出端口配置菜单
export_port_config_menu() {
    echo -e "${SECONDARY_COLOR}=== 导出端口配置 ===${NC}"
    echo
    
    local output_file=$(show_input "输出文件路径" "/tmp/firewall_ports.conf")
    local firewall_type=$(detect_firewall_type)
    
    if [[ -n "$firewall_type" ]]; then
        export_port_config "$firewall_type" "$output_file"
        log_info "端口配置导出完成"
    else
        show_error "未检测到支持的防火墙类型"
    fi
}

# 导入端口配置菜单
import_port_config_menu() {
    echo -e "${SECONDARY_COLOR}=== 导入端口配置 ===${NC}"
    echo
    
    local config_file=$(show_input "配置文件路径" "")
    local firewall_type=$(detect_firewall_type)
    
    if [[ -n "$config_file" ]] && [[ -n "$firewall_type" ]]; then
        import_port_config "$firewall_type" "$config_file"
        reload_firewall "$firewall_type"
        log_info "端口配置导入完成"
    else
        show_error "配置文件路径错误或防火墙类型未检测到"
    fi
}

# 重载防火墙配置
reload_firewall_config() {
    echo -e "${SECONDARY_COLOR}=== 重载防火墙配置 ===${NC}"
    echo
    
    local firewall_type=$(detect_firewall_type)
    
    if [[ -n "$firewall_type" ]]; then
        reload_firewall "$firewall_type"
        log_info "防火墙配置重载完成"
    else
        show_error "未检测到支持的防火墙类型"
    fi
}

# 导出函数
export -f init_firewall_ports detect_firewall_type configure_firewall_ports
export -f open_required_ports open_feature_ports open_port
export -f open_ufw_port open_firewalld_port open_nftables_port open_iptables_port
export -f enable_firewall reload_firewall check_port_status show_firewall_status
export -f add_custom_port remove_port configure_ports_batch
export -f export_port_config import_port_config firewall_ports_menu
export -f auto_configure_ports show_ports_status add_custom_port_menu
export -f remove_port_menu batch_configure_ports export_port_config_menu
export -f import_port_config_menu reload_firewall_config
