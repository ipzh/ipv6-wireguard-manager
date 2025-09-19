#!/bin/bash

# 防火墙管理模块
# 提供防火墙规则管理、端口管理、服务管理等功能

# 防火墙管理菜单
firewall_management_menu() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    防火墙管理                              ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        # 显示防火墙状态
        show_firewall_status
        
        echo -e "${YELLOW}防火墙管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看防火墙状态"
        echo -e "  ${GREEN}2.${NC} 启用/禁用防火墙"
        echo -e "  ${GREEN}3.${NC} 查看防火墙规则"
        echo -e "  ${GREEN}4.${NC} 添加防火墙规则"
        echo -e "  ${GREEN}5.${NC} 删除防火墙规则"
        echo -e "  ${GREEN}6.${NC} 端口管理"
        echo -e "  ${GREEN}7.${NC} 服务管理"
        echo -e "  ${GREEN}8.${NC} 防火墙日志"
        echo -e "  ${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 (0-8): " choice
        
        case "$choice" in
            "1")
                show_firewall_status
                read -p "按回车键继续..."
                ;;
            "2")
                toggle_firewall
                ;;
            "3")
                view_firewall_rules
                ;;
            "4")
                add_firewall_rule
                ;;
            "5")
                remove_firewall_rule
                ;;
            "6")
                port_management
                ;;
            "7")
                service_management
                ;;
            "8")
                view_firewall_logs
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 显示防火墙状态
show_firewall_status() {
    echo -e "${CYAN}防火墙状态:${NC}"
    echo
    
    if command -v ufw >/dev/null 2>&1; then
        echo -e "  UFW: $([ "$(ufw status | grep 'Status:' | awk '{print $2}')" == "active" ] && echo -e "${GREEN}已启用${NC}" || echo -e "${RED}已禁用${NC}")"
        local ufw_rules=$(ufw status numbered | grep -c "^\[" 2>/dev/null || echo "0")
        echo -e "    规则数量: $ufw_rules"
    fi
    
    if command -v firewall-cmd >/dev/null 2>&1; then
        if systemctl is-active --quiet firewalld; then
            echo -e "  Firewalld: ${GREEN}已启用${NC}"
            local firewalld_zones=$(firewall-cmd --get-zones 2>/dev/null | wc -w)
            echo -e "    活动区域: $firewalld_zones"
        else
            echo -e "  Firewalld: ${RED}已禁用${NC}"
        fi
    fi
    
    if command -v nft >/dev/null 2>&1; then
        echo -e "  nftables: $([ "$(nft list tables 2>/dev/null | wc -l)" -gt 0 ] && echo -e "${GREEN}已配置${NC}" || echo -e "${YELLOW}未配置${NC}")"
    fi
    
    if command -v iptables >/dev/null 2>&1; then
        local iptables_rules=$(iptables -L | grep -c "^Chain" 2>/dev/null || echo "0")
        echo -e "  iptables: $([ "$iptables_rules" -gt 0 ] && echo -e "${GREEN}已配置${NC}" || echo -e "${YELLOW}未配置${NC}")"
        echo -e "    链数量: $iptables_rules"
    fi
    
    echo
}

# 启用/禁用防火墙
toggle_firewall() {
    echo -e "${CYAN}防火墙控制${NC}"
    echo "1. 启用防火墙"
    echo "2. 禁用防火墙"
    read -p "请选择操作 (1-2): " action
    
    case "$action" in
        "1")
            enable_firewall
            ;;
        "2")
            disable_firewall
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    read -p "按回车键继续..."
}

# 启用防火墙
enable_firewall() {
    if command -v ufw >/dev/null 2>&1; then
        if ufw --force enable; then
            echo -e "${GREEN}✓${NC} UFW 已启用"
        else
            echo -e "${RED}✗${NC} UFW 启用失败"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if systemctl enable firewalld && systemctl start firewalld; then
            echo -e "${GREEN}✓${NC} Firewalld 已启用"
        else
            echo -e "${RED}✗${NC} Firewalld 启用失败"
        fi
    else
        echo -e "${YELLOW}未找到支持的防火墙工具${NC}"
    fi
}

# 禁用防火墙
disable_firewall() {
    if command -v ufw >/dev/null 2>&1; then
        if ufw disable; then
            echo -e "${GREEN}✓${NC} UFW 已禁用"
        else
            echo -e "${RED}✗${NC} UFW 禁用失败"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if systemctl stop firewalld && systemctl disable firewalld; then
            echo -e "${GREEN}✓${NC} Firewalld 已禁用"
        else
            echo -e "${RED}✗${NC} Firewalld 禁用失败"
        fi
    else
        echo -e "${YELLOW}未找到支持的防火墙工具${NC}"
    fi
}

# 查看防火墙规则
view_firewall_rules() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    防火墙规则查看                            ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    if command -v ufw >/dev/null 2>&1; then
        echo -e "${CYAN}UFW 规则:${NC}"
        ufw status verbose
        echo
    fi
    
    if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld; then
        echo -e "${CYAN}Firewalld 规则:${NC}"
        firewall-cmd --list-all
        echo
    fi
    
    if command -v iptables >/dev/null 2>&1; then
        echo -e "${CYAN}iptables 规则:${NC}"
        iptables -L -n -v
        echo
    fi
    
    if command -v nft >/dev/null 2>&1; then
        echo -e "${CYAN}nftables 规则:${NC}"
        nft list ruleset 2>/dev/null || echo "  nftables 未配置"
        echo
    fi
    
    read -p "按回车键继续..."
}

# 添加防火墙规则
add_firewall_rule() {
    echo -e "${CYAN}添加防火墙规则${NC}"
    echo "1. 允许端口"
    echo "2. 拒绝端口"
    echo "3. 允许IP"
    echo "4. 拒绝IP"
    read -p "请选择规则类型 (1-4): " rule_type
    
    case "$rule_type" in
        "1")
            add_port_rule "allow"
            ;;
        "2")
            add_port_rule "deny"
            ;;
        "3")
            add_ip_rule "allow"
            ;;
        "4")
            add_ip_rule "deny"
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    read -p "按回车键继续..."
}

# 添加端口规则
add_port_rule() {
    local action="$1"
    read -p "请输入端口号或端口范围 (如: 80 或 80-443): " port
    read -p "请输入协议 (tcp/udp，默认tcp): " protocol
    protocol="${protocol:-tcp}"
    
    if [[ -n "$port" ]]; then
        if command -v ufw >/dev/null 2>&1; then
            if [[ "$action" == "allow" ]]; then
                ufw allow "$port/$protocol"
                echo -e "${GREEN}✓${NC} UFW 规则已添加: 允许 $port/$protocol"
            else
                ufw deny "$port/$protocol"
                echo -e "${GREEN}✓${NC} UFW 规则已添加: 拒绝 $port/$protocol"
            fi
        elif command -v firewall-cmd >/dev/null 2>&1; then
            if [[ "$action" == "allow" ]]; then
                firewall-cmd --permanent --add-port="$port/$protocol"
                firewall-cmd --reload
                echo -e "${GREEN}✓${NC} Firewalld 规则已添加: 允许 $port/$protocol"
            else
                firewall-cmd --permanent --remove-port="$port/$protocol"
                firewall-cmd --reload
                echo -e "${GREEN}✓${NC} Firewalld 规则已添加: 拒绝 $port/$protocol"
            fi
        else
            echo -e "${YELLOW}未找到支持的防火墙工具${NC}"
        fi
    else
        echo -e "${RED}请输入有效的端口${NC}"
    fi
}

# 添加IP规则
add_ip_rule() {
    local action="$1"
    read -p "请输入IP地址或网段: " ip_address
    
    if [[ -n "$ip_address" ]]; then
        if command -v ufw >/dev/null 2>&1; then
            if [[ "$action" == "allow" ]]; then
                ufw allow from "$ip_address"
                echo -e "${GREEN}✓${NC} UFW 规则已添加: 允许来自 $ip_address"
            else
                ufw deny from "$ip_address"
                echo -e "${GREEN}✓${NC} UFW 规则已添加: 拒绝来自 $ip_address"
            fi
        elif command -v firewall-cmd >/dev/null 2>&1; then
            if [[ "$action" == "allow" ]]; then
                firewall-cmd --permanent --add-source="$ip_address"
                firewall-cmd --reload
                echo -e "${GREEN}✓${NC} Firewalld 规则已添加: 允许来自 $ip_address"
            else
                firewall-cmd --permanent --remove-source="$ip_address"
                firewall-cmd --reload
                echo -e "${GREEN}✓${NC} Firewalld 规则已添加: 拒绝来自 $ip_address"
            fi
        else
            echo -e "${YELLOW}未找到支持的防火墙工具${NC}"
        fi
    else
        echo -e "${RED}请输入有效的IP地址${NC}"
    fi
}

# 删除防火墙规则
remove_firewall_rule() {
    echo -e "${CYAN}删除防火墙规则${NC}"
    
    if command -v ufw >/dev/null 2>&1; then
        echo -e "${CYAN}当前UFW规则:${NC}"
        ufw status numbered
        echo
        read -p "请输入要删除的规则编号: " rule_num
        
        if [[ "$rule_num" =~ ^[0-9]+$ ]]; then
            if ufw --force delete "$rule_num"; then
                echo -e "${GREEN}✓${NC} 规则已删除"
            else
                echo -e "${RED}✗${NC} 删除失败"
            fi
        else
            echo -e "${RED}请输入有效的规则编号${NC}"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        echo -e "${CYAN}当前Firewalld规则:${NC}"
        firewall-cmd --list-all
        echo
        read -p "请输入要删除的端口 (如: 80/tcp): " port
        read -p "请输入要删除的源IP (可选): " source_ip
        
        if [[ -n "$port" ]]; then
            if [[ -n "$source_ip" ]]; then
                firewall-cmd --permanent --remove-source="$source_ip"
            fi
            firewall-cmd --permanent --remove-port="$port"
            firewall-cmd --reload
            echo -e "${GREEN}✓${NC} 规则已删除"
        else
            echo -e "${RED}请输入有效的端口${NC}"
        fi
    else
        echo -e "${YELLOW}未找到支持的防火墙工具${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 端口管理
port_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    端口管理                                ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}端口管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看开放端口"
        echo -e "  ${GREEN}2.${NC} 开放常用端口"
        echo -e "  ${GREEN}3.${NC} 关闭端口"
        echo -e "  ${GREEN}4.${NC} 端口扫描"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-4): " choice
        
        case "$choice" in
            "1")
                show_open_ports
                ;;
            "2")
                open_common_ports
                ;;
            "3")
                close_port
                ;;
            "4")
                scan_ports
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 查看开放端口
show_open_ports() {
    echo -e "${CYAN}当前开放的端口:${NC}"
    
    if command -v ss >/dev/null 2>&1; then
        ss -tuln | grep LISTEN | while read line; do
            echo "  $line"
        done
    else
        netstat -tuln | grep LISTEN | while read line; do
            echo "  $line"
        done
    fi
    
    echo
    read -p "按回车键继续..."
}

# 开放常用端口
open_common_ports() {
    echo -e "${CYAN}开放常用端口${NC}"
    echo "1. SSH (22/tcp)"
    echo "2. HTTP (80/tcp)"
    echo "3. HTTPS (443/tcp)"
    echo "4. WireGuard (51820/udp)"
    echo "5. BGP (179/tcp)"
    echo "6. 自定义端口"
    read -p "请选择要开放的端口 (1-6): " choice
    
    case "$choice" in
        "1")
            open_port "22" "tcp" "SSH"
            ;;
        "2")
            open_port "80" "tcp" "HTTP"
            ;;
        "3")
            open_port "443" "tcp" "HTTPS"
            ;;
        "4")
            open_port "51820" "udp" "WireGuard"
            ;;
        "5")
            open_port "179" "tcp" "BGP"
            ;;
        "6")
            read -p "请输入端口号: " port
            read -p "请输入协议 (tcp/udp): " protocol
            read -p "请输入描述: " description
            open_port "$port" "$protocol" "$description"
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    read -p "按回车键继续..."
}

# 开放端口
open_port() {
    local port="$1"
    local protocol="$2"
    local description="$3"
    
    if command -v ufw >/dev/null 2>&1; then
        if ufw allow "$port/$protocol"; then
            echo -e "${GREEN}✓${NC} $description ($port/$protocol) 已开放"
        else
            echo -e "${RED}✗${NC} 开放失败"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if firewall-cmd --permanent --add-port="$port/$protocol" && firewall-cmd --reload; then
            echo -e "${GREEN}✓${NC} $description ($port/$protocol) 已开放"
        else
            echo -e "${RED}✗${NC} 开放失败"
        fi
    else
        echo -e "${YELLOW}未找到支持的防火墙工具${NC}"
    fi
}

# 关闭端口
close_port() {
    read -p "请输入要关闭的端口: " port
    read -p "请输入协议 (tcp/udp): " protocol
    
    if [[ -n "$port" && -n "$protocol" ]]; then
        if command -v ufw >/dev/null 2>&1; then
            if ufw deny "$port/$protocol"; then
                echo -e "${GREEN}✓${NC} 端口 $port/$protocol 已关闭"
            else
                echo -e "${RED}✗${NC} 关闭失败"
            fi
        elif command -v firewall-cmd >/dev/null 2>&1; then
            if firewall-cmd --permanent --remove-port="$port/$protocol" && firewall-cmd --reload; then
                echo -e "${GREEN}✓${NC} 端口 $port/$protocol 已关闭"
            else
                echo -e "${RED}✗${NC} 关闭失败"
            fi
        else
            echo -e "${YELLOW}未找到支持的防火墙工具${NC}"
        fi
    else
        echo -e "${RED}请输入有效的端口和协议${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 端口扫描
scan_ports() {
    read -p "请输入要扫描的主机IP (默认本机): " host
    host="${host:-127.0.0.1}"
    
    echo -e "${CYAN}正在扫描 $host 的端口...${NC}"
    
    if command -v nmap >/dev/null 2>&1; then
        nmap -sT -O "$host" 2>/dev/null || echo -e "${RED}端口扫描失败${NC}"
    else
        echo -e "${YELLOW}nmap未安装，使用nc进行简单扫描${NC}"
        for port in 22 80 443 8080 3306 5432; do
            if nc -z "$host" "$port" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} 端口 $port 开放"
            else
                echo -e "${RED}✗${NC} 端口 $port 关闭"
            fi
        done
    fi
    
    read -p "按回车键继续..."
}

# 服务管理
service_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    服务管理                                ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}服务管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看服务状态"
        echo -e "  ${GREEN}2.${NC} 启动服务"
        echo -e "  ${GREEN}3.${NC} 停止服务"
        echo -e "  ${GREEN}4.${NC} 重启服务"
        echo -e "  ${GREEN}5.${NC} 启用/禁用服务"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                show_service_status
                ;;
            "2")
                start_service
                ;;
            "3")
                stop_service
                ;;
            "4")
                restart_service
                ;;
            "5")
                toggle_service
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 启动服务
start_service() {
    read -p "请输入服务名称: " service_name
    
    if [[ -n "$service_name" ]]; then
        if systemctl start "$service_name"; then
            echo -e "${GREEN}✓${NC} 服务 $service_name 已启动"
        else
            echo -e "${RED}✗${NC} 服务启动失败"
        fi
    else
        echo -e "${RED}请输入有效的服务名称${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 停止服务
stop_service() {
    read -p "请输入服务名称: " service_name
    
    if [[ -n "$service_name" ]]; then
        if systemctl stop "$service_name"; then
            echo -e "${GREEN}✓${NC} 服务 $service_name 已停止"
        else
            echo -e "${RED}✗${NC} 服务停止失败"
        fi
    else
        echo -e "${RED}请输入有效的服务名称${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 重启服务
restart_service() {
    read -p "请输入服务名称: " service_name
    
    if [[ -n "$service_name" ]]; then
        if systemctl restart "$service_name"; then
            echo -e "${GREEN}✓${NC} 服务 $service_name 已重启"
        else
            echo -e "${RED}✗${NC} 服务重启失败"
        fi
    else
        echo -e "${RED}请输入有效的服务名称${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 启用/禁用服务
toggle_service() {
    read -p "请输入服务名称: " service_name
    read -p "操作 (enable/disable): " action
    
    if [[ -n "$service_name" && -n "$action" ]]; then
        if [[ "$action" == "enable" || "$action" == "disable" ]]; then
            if systemctl "$action" "$service_name"; then
                echo -e "${GREEN}✓${NC} 服务 $service_name 已$action"
            else
                echo -e "${RED}✗${NC} 操作失败"
            fi
        else
            echo -e "${RED}无效操作，请使用 enable 或 disable${NC}"
        fi
    else
        echo -e "${RED}请输入有效的服务名称和操作${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 查看防火墙日志
view_firewall_logs() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    防火墙日志                                ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${CYAN}系统日志中的防火墙信息:${NC}"
    journalctl -u firewalld -n 50 --no-pager 2>/dev/null || echo "  无Firewalld日志"
    
    echo
    echo -e "${CYAN}内核日志中的防火墙信息:${NC}"
    dmesg | grep -i "firewall\|iptables\|ufw" | tail -20 || echo "  无防火墙内核日志"
    
    echo
    echo -e "${CYAN}系统日志中的网络连接:${NC}"
    journalctl | grep -i "connection\|refused\|timeout" | tail -10 || echo "  无网络连接日志"
    
    echo
    read -p "按回车键继续..."
}
