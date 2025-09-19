#!/bin/bash

# 网络管理模块
# 提供IPv6前缀管理、BGP邻居配置、路由表查看、网络诊断等功能

# 网络配置菜单
network_config_menu() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    网络配置管理                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}网络配置选项:${NC}"
        echo -e "  ${GREEN}1.${NC} IPv6前缀管理"
        echo -e "  ${GREEN}2.${NC} BGP邻居配置"
        echo -e "  ${GREEN}3.${NC} 路由表查看"
        echo -e "  ${GREEN}4.${NC} 网络接口管理"
        echo -e "  ${GREEN}5.${NC} 网络诊断工具"
        echo -e "  ${GREEN}6.${NC} 查看BGP状态"
        echo -e "  ${GREEN}7.${NC} 网络统计信息"
        echo -e "  ${GREEN}8.${NC} 自定义IPv6段管理"
        echo -e "  ${GREEN}9.${NC} IPv6子网宣告管理"
        echo -e "  ${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 (0-9): " choice
        
        case "$choice" in
            "1")
                ipv6_prefix_management
                ;;
            "2")
                bgp_neighbor_management
                ;;
            "3")
                view_routing_table
                ;;
            "4")
                network_interface_management
                ;;
            "5")
                network_diagnostics
                ;;
            "6")
                view_bgp_status
                ;;
            "7")
                show_network_statistics
                ;;
            "8")
                custom_ipv6_segment_management
                ;;
            "9")
                ipv6_subnet_announcement_management
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

# IPv6前缀管理
ipv6_prefix_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    IPv6前缀管理                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        # 显示当前前缀配置
        echo -e "${CYAN}当前IPv6前缀配置:${NC}"
        if [[ -f /etc/wireguard/wg0.conf ]]; then
            grep "Address" /etc/wireguard/wg0.conf | head -1
        else
            echo "  WireGuard配置未找到"
        fi
        
        echo
        echo -e "${YELLOW}IPv6前缀管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看当前前缀"
        echo -e "  ${GREEN}2.${NC} 添加新前缀"
        echo -e "  ${GREEN}3.${NC} 删除前缀"
        echo -e "  ${GREEN}4.${NC} 修改前缀"
        echo -e "  ${GREEN}5.${NC} 前缀分配统计"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                show_current_prefixes
                ;;
            "2")
                add_ipv6_prefix
                ;;
            "3")
                remove_ipv6_prefix
                ;;
            "4")
                modify_ipv6_prefix
                ;;
            "5")
                show_prefix_statistics
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

# 显示当前前缀
show_current_prefixes() {
    echo -e "${CYAN}当前IPv6前缀配置:${NC}"
    if [[ -f /etc/wireguard/wg0.conf ]]; then
        grep "Address" /etc/wireguard/wg0.conf | while read line; do
            echo "  $line"
        done
    else
        echo "  WireGuard配置未找到"
    fi
    
    echo
    echo -e "${CYAN}BIRD配置中的前缀:${NC}"
    if [[ -f /etc/bird/bird.conf ]]; then
        grep -E "route.*via" /etc/bird/bird.conf | while read line; do
            echo "  $line"
        done
    else
        echo "  BIRD配置未找到"
    fi
    
    read -p "按回车键继续..."
}

# 添加IPv6前缀
add_ipv6_prefix() {
    echo -e "${CYAN}添加IPv6前缀${NC}"
    echo "支持的格式: 2001:db8::/48"
    
    read -p "请输入新的IPv6前缀: " new_prefix
    
    if [[ "$new_prefix" =~ ^[0-9a-fA-F:]+/[0-9]+$ ]]; then
        # 添加到WireGuard配置
        if [[ -f /etc/wireguard/wg0.conf ]]; then
            # 检查前缀是否已存在
            if grep -q "$new_prefix" /etc/wireguard/wg0.conf; then
                echo -e "${YELLOW}前缀已存在${NC}"
            else
                # 从前缀中提取服务器地址（使用::1作为服务器地址）
                local network_part=$(echo "$new_prefix" | cut -d'/' -f1)
                if [[ "$network_part" == *"::" ]]; then
                    local server_ipv6="${network_part}1/64"
                elif [[ "$network_part" == *":" ]]; then
                    local server_ipv6="${network_part}1/64"
                else
                    local server_ipv6="${network_part}:1/64"
                fi
                # 添加到Address行
                sed -i "s/Address = /Address = $server_ipv6, /" /etc/wireguard/wg0.conf
                echo -e "${GREEN}✓${NC} 前缀已添加到WireGuard配置"
            fi
        fi
        
        # 添加到BIRD配置
        if [[ -f /etc/bird/bird.conf ]]; then
            # 检查前缀是否已存在
            if grep -q "$new_prefix" /etc/bird/bird.conf; then
                echo -e "${YELLOW}前缀在BIRD配置中已存在${NC}"
            else
                # 添加到静态路由
                sed -i "/route.*via ::1;/a\\    route $new_prefix via ::1;" /etc/bird/bird.conf
                echo -e "${GREEN}✓${NC} 前缀已添加到BIRD配置"
            fi
        fi
        
        echo -e "${GREEN}前缀添加完成${NC}"
    else
        echo -e "${RED}无效的IPv6前缀格式${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 删除IPv6前缀
remove_ipv6_prefix() {
    echo -e "${CYAN}删除IPv6前缀${NC}"
    
    # 显示当前前缀列表
    echo "当前配置的IPv6前缀:"
    if [[ -f /etc/wireguard/wg0.conf ]]; then
        grep "Address" /etc/wireguard/wg0.conf | sed 's/Address = /  /'
    else
        echo "  未找到WireGuard配置"
    fi
    echo
    
    read -p "请输入要删除的IPv6前缀 (格式: 2001:db8::/48): " prefix_to_remove
    
    if [[ "$prefix_to_remove" =~ ^[0-9a-fA-F:]+/[0-9]+$ ]]; then
        # 从WireGuard配置中删除
        if [[ -f /etc/wireguard/wg0.conf ]]; then
            if grep -q "$prefix_to_remove" /etc/wireguard/wg0.conf; then
                # 删除包含该前缀的地址
                local network_part=$(echo "$prefix_to_remove" | cut -d'/' -f1)
                if [[ "$network_part" == *"::" ]]; then
                    local server_ipv6="${network_part}1/64"
                elif [[ "$network_part" == *":" ]]; then
                    local server_ipv6="${network_part}1/64"
                else
                    local server_ipv6="${network_part}:1/64"
                fi
                sed -i "s/, $server_ipv6//g" /etc/wireguard/wg0.conf
                sed -i "s/$server_ipv6, //g" /etc/wireguard/wg0.conf
                echo -e "${GREEN}✓${NC} 前缀已从WireGuard配置中删除"
            else
                echo -e "${YELLOW}前缀在WireGuard配置中不存在${NC}"
            fi
        fi
        
        # 从BIRD配置中删除
        if [[ -f /etc/bird/bird.conf ]]; then
            if grep -q "$prefix_to_remove" /etc/bird/bird.conf; then
                sed -i "/route $prefix_to_remove via ::1;/d" /etc/bird/bird.conf
                echo -e "${GREEN}✓${NC} 前缀已从BIRD配置中删除"
            else
                echo -e "${YELLOW}前缀在BIRD配置中不存在${NC}"
            fi
        fi
        
        echo -e "${GREEN}前缀删除完成${NC}"
    else
        echo -e "${RED}无效的IPv6前缀格式${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 修改IPv6前缀
modify_ipv6_prefix() {
    echo -e "${CYAN}修改IPv6前缀${NC}"
    
    # 显示当前前缀列表
    echo "当前配置的IPv6前缀:"
    if [[ -f /etc/wireguard/wg0.conf ]]; then
        grep "Address" /etc/wireguard/wg0.conf | sed 's/Address = /  /'
    else
        echo "  未找到WireGuard配置"
    fi
    echo
    
    read -p "请输入要修改的旧前缀 (格式: 2001:db8::/48): " old_prefix
    read -p "请输入新的前缀 (格式: 2001:db8:1::/48): " new_prefix
    
    if [[ "$old_prefix" =~ ^[0-9a-fA-F:]+/[0-9]+$ ]] && [[ "$new_prefix" =~ ^[0-9a-fA-F:]+/[0-9]+$ ]]; then
        # 生成旧前缀的服务器地址
        local old_network_part=$(echo "$old_prefix" | cut -d'/' -f1)
        if [[ "$old_network_part" == *"::" ]]; then
            local old_server_ipv6="${old_network_part}1/64"
        elif [[ "$old_network_part" == *":" ]]; then
            local old_server_ipv6="${old_network_part}1/64"
        else
            local old_server_ipv6="${old_network_part}:1/64"
        fi
        
        # 生成新前缀的服务器地址
        local new_network_part=$(echo "$new_prefix" | cut -d'/' -f1)
        if [[ "$new_network_part" == *"::" ]]; then
            local new_server_ipv6="${new_network_part}1/64"
        elif [[ "$new_network_part" == *":" ]]; then
            local new_server_ipv6="${new_network_part}1/64"
        else
            local new_server_ipv6="${new_network_part}:1/64"
        fi
        
        # 在WireGuard配置中修改
        if [[ -f /etc/wireguard/wg0.conf ]]; then
            if grep -q "$old_server_ipv6" /etc/wireguard/wg0.conf; then
                sed -i "s/$old_server_ipv6/$new_server_ipv6/g" /etc/wireguard/wg0.conf
                echo -e "${GREEN}✓${NC} WireGuard配置已更新"
            else
                echo -e "${YELLOW}旧前缀在WireGuard配置中不存在${NC}"
            fi
        fi
        
        # 在BIRD配置中修改
        if [[ -f /etc/bird/bird.conf ]]; then
            if grep -q "$old_prefix" /etc/bird/bird.conf; then
                sed -i "s/route $old_prefix via ::1;/route $new_prefix via ::1;/g" /etc/bird/bird.conf
                echo -e "${GREEN}✓${NC} BIRD配置已更新"
            else
                echo -e "${YELLOW}旧前缀在BIRD配置中不存在${NC}"
            fi
        fi
        
        echo -e "${GREEN}前缀修改完成${NC}"
    else
        echo -e "${RED}无效的IPv6前缀格式${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 显示前缀统计
show_prefix_statistics() {
    echo -e "${CYAN}=== IPv6前缀分配统计 ===${NC}"
    echo
    
    # WireGuard前缀统计
    echo -e "${YELLOW}WireGuard配置中的前缀:${NC}"
    if [[ -f /etc/wireguard/wg0.conf ]]; then
        local wg_count=$(grep -c "Address.*::" /etc/wireguard/wg0.conf 2>/dev/null || echo "0")
        echo "  配置的IPv6地址数量: $wg_count"
        grep "Address" /etc/wireguard/wg0.conf | sed 's/Address = /  - /' 2>/dev/null || echo "  未找到IPv6地址配置"
    else
        echo "  未找到WireGuard配置文件"
    fi
    echo
    
    # BIRD前缀统计
    echo -e "${YELLOW}BIRD配置中的前缀:${NC}"
    if [[ -f /etc/bird/bird.conf ]]; then
        local bird_count=$(grep -c "route.*::" /etc/bird/bird.conf 2>/dev/null || echo "0")
        echo "  宣告的IPv6路由数量: $bird_count"
        grep -E "route.*::" /etc/bird/bird.conf | sed 's/    /  - /' 2>/dev/null || echo "  未找到IPv6路由配置"
    else
        echo "  未找到BIRD配置文件"
    fi
    echo
    
    # 客户端地址池统计
    echo -e "${YELLOW}客户端地址池统计:${NC}"
    local client_db="/etc/ipv6-wireguard/clients.db"
    if [[ -f "$client_db" ]]; then
        local total_clients=$(grep -c "^[^#]" "$client_db" 2>/dev/null || echo "0")
        local ipv6_clients=$(grep -c "::" "$client_db" 2>/dev/null || echo "0")
        echo "  总客户端数量: $total_clients"
        echo "  IPv6客户端数量: $ipv6_clients"
        
        # 显示IPv6地址使用情况
        echo "  IPv6地址使用情况:"
        if [[ $ipv6_clients -gt 0 ]]; then
            grep "::" "$client_db" | cut -d'|' -f5 | head -5 | sed 's/^/    /' 2>/dev/null
            if [[ $ipv6_clients -gt 5 ]]; then
                echo "    ... 还有 $((ipv6_clients - 5)) 个地址"
            fi
        else
            echo "    无IPv6客户端地址"
        fi
    else
        echo "  未找到客户端数据库"
    fi
    
    read -p "按回车键继续..."
}

# BGP邻居管理
bgp_neighbor_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    BGP邻居管理                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}BGP邻居管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看当前邻居"
        echo -e "  ${GREEN}2.${NC} 添加BGP邻居"
        echo -e "  ${GREEN}3.${NC} 删除BGP邻居"
        echo -e "  ${GREEN}4.${NC} 修改邻居配置"
        echo -e "  ${GREEN}5.${NC} 邻居状态检查"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                show_bgp_neighbors
                ;;
            "2")
                add_bgp_neighbor
                ;;
            "3")
                remove_bgp_neighbor
                ;;
            "4")
                modify_bgp_neighbor
                ;;
            "5")
                check_bgp_neighbor_status
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

# 查看BGP邻居
show_bgp_neighbors() {
    echo -e "${CYAN}当前BGP邻居配置:${NC}"
    
    if command -v birdc >/dev/null 2>&1; then
        echo -e "${CYAN}BIRD邻居状态:${NC}"
        birdc show protocols 2>/dev/null | grep -E "BGP|neighbor" || echo "  无BGP邻居配置"
    elif command -v birdc2 >/dev/null 2>&1; then
        echo -e "${CYAN}BIRD2邻居状态:${NC}"
        birdc2 show protocols 2>/dev/null | grep -E "BGP|neighbor" || echo "  无BGP邻居配置"
    else
        echo "  BIRD控制台未找到"
    fi
    
    echo
    echo -e "${CYAN}配置文件中的邻居:${NC}"
    if [[ -f /etc/bird/bird.conf ]]; then
        grep -A 10 "protocol bgp" /etc/bird/bird.conf | while read line; do
            echo "  $line"
        done
    else
        echo "  BIRD配置文件未找到"
    fi
    
    read -p "按回车键继续..."
}

# 查看路由表
view_routing_table() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    路由表查看                              ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${CYAN}IPv4路由表:${NC}"
    ip route show | head -20 | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${CYAN}IPv6路由表:${NC}"
    ip -6 route show | head -20 | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${CYAN}BGP路由表:${NC}"
    if command -v birdc >/dev/null 2>&1; then
        birdc show route 2>/dev/null | head -20 || echo "  BGP路由表为空或BIRD未运行"
    elif command -v birdc2 >/dev/null 2>&1; then
        birdc2 show route 2>/dev/null | head -20 || echo "  BGP路由表为空或BIRD未运行"
    else
        echo "  BIRD控制台未找到"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 网络诊断工具
network_diagnostics() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    网络诊断工具                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}诊断工具选项:${NC}"
        echo -e "  ${GREEN}1.${NC} Ping测试"
        echo -e "  ${GREEN}2.${NC} 网络连通性测试"
        echo -e "  ${GREEN}3.${NC} DNS解析测试"
        echo -e "  ${GREEN}4.${NC} 端口扫描"
        echo -e "  ${GREEN}5.${NC} 网络延迟测试"
        echo -e "  ${GREEN}6.${NC} 路由跟踪"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-6): " choice
        
        case "$choice" in
            "1")
                ping_test
                ;;
            "2")
                connectivity_test
                ;;
            "3")
                dns_test
                ;;
            "4")
                port_scan
                ;;
            "5")
                latency_test
                ;;
            "6")
                traceroute_test
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

# Ping测试
ping_test() {
    echo -e "${CYAN}Ping测试${NC}"
    read -p "请输入要测试的IP地址或域名: " target
    
    if [[ -n "$target" ]]; then
        echo -e "${CYAN}正在测试 $target...${NC}"
        ping -c 4 "$target" 2>/dev/null || echo -e "${RED}Ping测试失败${NC}"
    else
        echo -e "${RED}请输入有效的目标地址${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 网络连通性测试
connectivity_test() {
    echo -e "${CYAN}网络连通性测试${NC}"
    echo "测试常用服务的连通性..."
    
    local targets=("8.8.8.8" "1.1.1.1" "google.com" "cloudflare.com")
    
    for target in "${targets[@]}"; do
        echo -n "测试 $target: "
        if ping -c 1 -W 3 "$target" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ 连通${NC}"
        else
            echo -e "${RED}✗ 不通${NC}"
        fi
    done
    
    read -p "按回车键继续..."
}

# DNS解析测试
dns_test() {
    echo -e "${CYAN}DNS解析测试${NC}"
    read -p "请输入要测试的域名: " domain
    
    if [[ -n "$domain" ]]; then
        echo -e "${CYAN}正在解析 $domain...${NC}"
        nslookup "$domain" 2>/dev/null || echo -e "${RED}DNS解析失败${NC}"
    else
        echo -e "${RED}请输入有效的域名${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 端口扫描
port_scan() {
    echo -e "${CYAN}端口扫描${NC}"
    read -p "请输入要扫描的主机IP: " host
    read -p "请输入要扫描的端口范围 (如: 80-443): " ports
    
    if [[ -n "$host" && -n "$ports" ]]; then
        echo -e "${CYAN}正在扫描 $host:$ports...${NC}"
        if command -v nmap >/dev/null 2>&1; then
            nmap -p "$ports" "$host" 2>/dev/null || echo -e "${RED}端口扫描失败${NC}"
        else
            echo -e "${YELLOW}nmap未安装，使用nc进行简单扫描${NC}"
            nc -zv "$host" "$ports" 2>&1 || echo -e "${RED}端口扫描失败${NC}"
        fi
    else
        echo -e "${RED}请输入有效的主机和端口${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 网络延迟测试
latency_test() {
    echo -e "${CYAN}网络延迟测试${NC}"
    read -p "请输入要测试的目标: " target
    
    if [[ -n "$target" ]]; then
        echo -e "${CYAN}正在测试 $target 的延迟...${NC}"
        ping -c 10 "$target" 2>/dev/null | tail -1 || echo -e "${RED}延迟测试失败${NC}"
    else
        echo -e "${RED}请输入有效的目标地址${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 路由跟踪
traceroute_test() {
    echo -e "${CYAN}路由跟踪${NC}"
    read -p "请输入要跟踪的目标: " target
    
    if [[ -n "$target" ]]; then
        echo -e "${CYAN}正在跟踪到 $target 的路由...${NC}"
        traceroute "$target" 2>/dev/null || echo -e "${RED}路由跟踪失败${NC}"
    else
        echo -e "${RED}请输入有效的目标地址${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 查看BGP状态
view_bgp_status() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    BGP状态查看                              ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    if command -v birdc >/dev/null 2>&1; then
        echo -e "${CYAN}BIRD状态:${NC}"
        birdc show status 2>/dev/null || echo "  BIRD未运行或配置错误"
        
        echo
        echo -e "${CYAN}BGP协议状态:${NC}"
        birdc show protocols 2>/dev/null || echo "  无协议信息"
        
        echo
        echo -e "${CYAN}BGP路由统计:${NC}"
        birdc show route count 2>/dev/null || echo "  无路由统计"
    elif command -v birdc2 >/dev/null 2>&1; then
        echo -e "${CYAN}BIRD2状态:${NC}"
        birdc2 show status 2>/dev/null || echo "  BIRD2未运行或配置错误"
        
        echo
        echo -e "${CYAN}BGP协议状态:${NC}"
        birdc2 show protocols 2>/dev/null || echo "  无协议信息"
        
        echo
        echo -e "${CYAN}BGP路由统计:${NC}"
        birdc2 show route count 2>/dev/null || echo "  无路由统计"
    else
        echo -e "${RED}BIRD控制台未找到${NC}"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 显示网络统计信息
show_network_statistics() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    网络统计信息                            ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${CYAN}网络接口统计:${NC}"
    cat /proc/net/dev | head -2
    cat /proc/net/dev | grep -E "eth|ens|enp|wg" | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${CYAN}连接统计:${NC}"
    ss -s 2>/dev/null || netstat -s 2>/dev/null | head -10
    
    echo
    echo -e "${CYAN}WireGuard统计:${NC}"
    if command -v wg >/dev/null 2>&1; then
        wg show wg0 2>/dev/null | while read line; do
            echo "  $line"
        done
    else
        echo "  WireGuard未安装或未运行"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 网络接口管理
network_interface_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    网络接口管理                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${CYAN}当前网络接口:${NC}"
        ip link show | grep -E "^[0-9]+:" | while read line; do
            echo "  $line"
        done
        
        echo
        echo -e "${YELLOW}接口管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看接口详情"
        echo -e "  ${GREEN}2.${NC} 启用/禁用接口"
        echo -e "  ${GREEN}3.${NC} 配置IP地址"
        echo -e "  ${GREEN}4.${NC} 查看接口统计"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-4): " choice
        
        case "$choice" in
            "1")
                show_interface_details
                ;;
            "2")
                toggle_interface
                ;;
            "3")
                configure_interface_ip
                ;;
            "4")
                show_interface_statistics
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

# 显示接口详情
show_interface_details() {
    local interfaces=()
    
    # 获取网络接口列表
    if command -v ip >/dev/null 2>&1; then
        while IFS= read -r interface; do
            if [[ "$interface" != "lo" ]]; then
                interfaces+=("$interface")
            fi
        done < <(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' 2>/dev/null)
    else
        # 如果ip命令不可用，使用ifconfig
        if command -v ifconfig >/dev/null 2>&1; then
            while IFS= read -r interface; do
                if [[ "$interface" != "lo" ]]; then
                    interfaces+=("$interface")
                fi
            done < <(ifconfig -a | grep -E "^[a-zA-Z]" | awk '{print $1}' | cut -d: -f1 | grep -v '^lo$' 2>/dev/null)
        else
            # 最后的备选方案
            interfaces=("eth0" "ens33" "enp0s3" "wlan0")
        fi
    fi
    
    if [[ ${#interfaces[@]} -eq 0 ]]; then
        echo -e "${RED}错误: 未找到可用的网络接口${NC}"
        read -p "按回车键继续..."
        return 1
    fi
    
    echo -e "${CYAN}可用的网络接口:${NC}"
    for i in "${!interfaces[@]}"; do
        local interface="${interfaces[$i]}"
        local status="未知"
        
        # 检查接口状态
        if command -v ip >/dev/null 2>&1; then
            status=$(ip link show "$interface" 2>/dev/null | grep -o "state [A-Z]*" | cut -d' ' -f2)
        else
            # 如果ip命令不可用，使用ifconfig
            if command -v ifconfig >/dev/null 2>&1; then
                status=$(ifconfig "$interface" 2>/dev/null | grep -o "UP\|DOWN" | head -1)
            fi
        fi
        echo -e "  ${GREEN}$((i+1)).${NC} ${interface} (状态: ${status})"
    done
    
    echo
    read -p "请选择接口编号 (1-${#interfaces[@]}): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#interfaces[@]}" ]]; then
        local selected_interface="${interfaces[$((choice-1))]}"
        echo -e "${CYAN}接口 $selected_interface 详情:${NC}"
        echo
        ip addr show "$selected_interface" 2>/dev/null || echo -e "${RED}接口不存在${NC}"
    else
        echo -e "${RED}无效选择${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 启用/禁用接口
toggle_interface() {
    local interfaces=()
    
    # 获取网络接口列表
    if command -v ip >/dev/null 2>&1; then
        while IFS= read -r interface; do
            if [[ "$interface" != "lo" ]]; then
                interfaces+=("$interface")
            fi
        done < <(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' 2>/dev/null)
    else
        # 如果ip命令不可用，使用ifconfig
        if command -v ifconfig >/dev/null 2>&1; then
            while IFS= read -r interface; do
                if [[ "$interface" != "lo" ]]; then
                    interfaces+=("$interface")
                fi
            done < <(ifconfig -a | grep -E "^[a-zA-Z]" | awk '{print $1}' | cut -d: -f1 | grep -v '^lo$' 2>/dev/null)
        else
            # 最后的备选方案
            interfaces=("eth0" "ens33" "enp0s3" "wlan0")
        fi
    fi
    
    if [[ ${#interfaces[@]} -eq 0 ]]; then
        echo -e "${RED}错误: 未找到可用的网络接口${NC}"
        read -p "按回车键继续..."
        return 1
    fi
    
    echo -e "${CYAN}可用的网络接口:${NC}"
    for i in "${!interfaces[@]}"; do
        local interface="${interfaces[$i]}"
        local status="未知"
        
        # 检查接口状态
        if command -v ip >/dev/null 2>&1; then
            status=$(ip link show "$interface" 2>/dev/null | grep -o "state [A-Z]*" | cut -d' ' -f2)
        else
            # 如果ip命令不可用，使用ifconfig
            if command -v ifconfig >/dev/null 2>&1; then
                status=$(ifconfig "$interface" 2>/dev/null | grep -o "UP\|DOWN" | head -1)
            fi
        fi
        echo -e "  ${GREEN}$((i+1)).${NC} ${interface} (状态: ${status})"
    done
    
    echo
    read -p "请选择接口编号 (1-${#interfaces[@]}): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#interfaces[@]}" ]]; then
        local selected_interface="${interfaces[$((choice-1))]}"
        local current_status=$(ip link show "$selected_interface" 2>/dev/null | grep -o "state [A-Z]*" | cut -d' ' -f2)
        
        echo -e "${CYAN}接口 $selected_interface 当前状态: ${current_status}${NC}"
        echo -e "${YELLOW}操作选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 启用接口 (up)"
        echo -e "  ${GREEN}2.${NC} 禁用接口 (down)"
        echo
        
        read -p "请选择操作 (1-2): " action_choice
        
        case "$action_choice" in
            "1")
                if ip link set "$selected_interface" up 2>/dev/null; then
                    echo -e "${GREEN}✓${NC} 接口 $selected_interface 已启用"
                else
                    echo -e "${RED}✗${NC} 启用失败"
                fi
                ;;
            "2")
                if ip link set "$selected_interface" down 2>/dev/null; then
                    echo -e "${GREEN}✓${NC} 接口 $selected_interface 已禁用"
                else
                    echo -e "${RED}✗${NC} 禁用失败"
                fi
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                ;;
        esac
    else
        echo -e "${RED}无效选择${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 配置接口IP
configure_interface_ip() {
    read -p "请输入接口名称: " interface
    read -p "请输入IP地址 (如: 192.168.1.100/24): " ip_address
    
    if [[ -n "$interface" && -n "$ip_address" ]]; then
        if ip addr add "$ip_address" dev "$interface" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} IP地址已添加到接口 $interface"
        else
            echo -e "${RED}✗${NC} 配置失败"
        fi
    else
        echo -e "${RED}请输入有效的接口名称和IP地址${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 显示接口统计
show_interface_statistics() {
    read -p "请输入接口名称: " interface
    
    if [[ -n "$interface" ]]; then
        echo -e "${CYAN}接口 $interface 统计:${NC}"
        cat /proc/net/dev | grep "$interface" || echo -e "${RED}接口不存在${NC}"
    else
        echo -e "${RED}请输入有效的接口名称${NC}"
    fi
    
    read -p "按回车键继续..."
}
