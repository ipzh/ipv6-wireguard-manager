#!/bin/bash

# WireGuard诊断工具模块
# 提供全面的WireGuard问题诊断和修复功能

# WireGuard诊断工具
wireguard_diagnostic_tool() {
    while true; do
        clear
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}                  WireGuard诊断工具                          ${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}WireGuard诊断选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 综合诊断 (推荐)"
        echo -e "  ${GREEN}2.${NC} 配置文件诊断"
        echo -e "  ${GREEN}3.${NC} 服务状态诊断"
        echo -e "  ${GREEN}4.${NC} 网络接口诊断"
        echo -e "  ${GREEN}5.${NC} 防火墙诊断"
        echo -e "  ${GREEN}6.${NC} 自动修复"
        echo -e "  ${GREEN}7.${NC} 查看详细日志"
        echo -e "  ${GREEN}0.${NC} 返回服务器管理"
        echo
        
        read -p "请选择诊断类型 (0-7): " choice
        
        case "$choice" in
            "1")
                diagnose_wireguard_comprehensive
                read -p "按回车键继续..."
                ;;
            "2")
                diagnose_wireguard_config
                read -p "按回车键继续..."
                ;;
            "3")
                diagnose_wireguard_service
                read -p "按回车键继续..."
                ;;
            "4")
                diagnose_wireguard_interface
                read -p "按回车键继续..."
                ;;
            "5")
                diagnose_wireguard_firewall
                read -p "按回车键继续..."
                ;;
            "6")
                auto_fix_wireguard_issues
                read -p "按回车键继续..."
                ;;
            "7")
                show_wireguard_logs
                read -p "按回车键继续..."
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

# WireGuard综合诊断
diagnose_wireguard_comprehensive() {
    echo -e "${CYAN}=== WireGuard综合诊断 ===${NC}"
    echo "开始全面诊断WireGuard配置和服务状态..."
    echo
    
    local total_issues=0
    
    # 配置文件诊断
    diagnose_wireguard_config
    total_issues=$((total_issues + $?))
    echo
    
    # 服务状态诊断
    diagnose_wireguard_service
    total_issues=$((total_issues + $?))
    echo
    
    # 网络接口诊断
    diagnose_wireguard_interface
    total_issues=$((total_issues + $?))
    echo
    
    # 防火墙诊断
    diagnose_wireguard_firewall
    total_issues=$((total_issues + $?))
    echo
    
    # 总结报告
    echo -e "${CYAN}=== 诊断总结 ===${NC}"
    if [[ $total_issues -eq 0 ]]; then
        echo -e "${GREEN}✓ WireGuard综合诊断完成，未发现任何问题${NC}"
        echo -e "${GREEN}WireGuard服务运行正常，可以正常使用VPN功能${NC}"
    else
        echo -e "${RED}✗ WireGuard综合诊断完成，总共发现 $total_issues 个问题${NC}"
        echo -e "${YELLOW}请按照上述诊断结果修复问题后重试${NC}"
        
        echo
        echo -e "${YELLOW}快速修复建议:${NC}"
        echo "1. 如果配置文件错误: 检查配置文件语法和内容"
        echo "2. 如果服务启动失败: 查看系统日志并修复权限问题"
        echo "3. 如果网络接口问题: 检查网络接口配置"
        echo "4. 如果防火墙问题: 检查防火墙规则配置"
    fi
    
    return $total_issues
}

# WireGuard配置文件诊断
diagnose_wireguard_config() {
    echo -e "${CYAN}=== WireGuard配置诊断 ===${NC}"
    
    local issues_found=0
    local config_file="/etc/wireguard/wg0.conf"
    
    # 检查配置文件是否存在
    echo -e "${YELLOW}1. 检查WireGuard配置文件...${NC}"
    if [[ -f "$config_file" ]]; then
        echo -e "${GREEN}✓${NC} 配置文件存在: $config_file"
        
        # 检查配置文件权限
        local owner=$(stat -c '%U:%G' "$config_file" 2>/dev/null || echo "unknown")
        if [[ "$owner" == "root:root" ]]; then
            echo -e "${GREEN}✓${NC} 配置文件权限正确 ($owner)"
        else
            echo -e "${RED}✗${NC} 配置文件权限错误 ($owner)"
            issues_found=$((issues_found + 1))
            echo -e "${YELLOW}   建议修复:${NC} sudo chown root:root $config_file"
        fi
        
        # 检查配置文件内容
        echo -e "${YELLOW}2. 检查配置文件内容...${NC}"
        
        # 检查PrivateKey
        if grep -q "PrivateKey" "$config_file"; then
            echo -e "${GREEN}✓${NC} PrivateKey已配置"
        else
            echo -e "${RED}✗${NC} PrivateKey未配置"
            issues_found=$((issues_found + 1))
        fi
        
        # 检查Address
        if grep -q "Address" "$config_file"; then
            echo -e "${GREEN}✓${NC} Address已配置"
        else
            echo -e "${RED}✗${NC} Address未配置"
            issues_found=$((issues_found + 1))
        fi
        
        # 检查ListenPort
        if grep -q "ListenPort" "$config_file"; then
            echo -e "${GREEN}✓${NC} ListenPort已配置"
        else
            echo -e "${RED}✗${NC} ListenPort未配置"
            issues_found=$((issues_found + 1))
        fi
        
        # 检查配置文件语法
        echo -e "${YELLOW}3. 检查配置文件语法...${NC}"
        if wg-quick strip "$config_file" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} 配置文件语法正确"
        else
            echo -e "${RED}✗${NC} 配置文件语法错误"
            issues_found=$((issues_found + 1))
            echo -e "${YELLOW}   建议修复:${NC} 检查配置文件语法"
        fi
        
    else
        echo -e "${RED}✗${NC} 配置文件不存在: $config_file"
        issues_found=$((issues_found + 1))
        echo -e "${YELLOW}   建议修复:${NC} 创建WireGuard配置文件"
    fi
    
    # 总结
    echo
    if [[ $issues_found -eq 0 ]]; then
        echo -e "${GREEN}✓ WireGuard配置诊断完成，未发现问题${NC}"
    else
        echo -e "${RED}✗ WireGuard配置诊断完成，发现 $issues_found 个问题${NC}"
        echo -e "${YELLOW}请按照上述建议修复问题后重试${NC}"
    fi
    
    return $issues_found
}

# WireGuard服务状态诊断
diagnose_wireguard_service() {
    echo -e "${CYAN}=== WireGuard服务诊断 ===${NC}"
    
    local issues_found=0
    
    # 检查服务状态
    echo -e "${YELLOW}1. 检查WireGuard服务状态...${NC}"
    if systemctl is-active wg-quick@wg0 >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} WireGuard服务正在运行"
        
        # 检查服务是否启用
        if systemctl is-enabled wg-quick@wg0 >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} WireGuard服务已启用"
        else
            echo -e "${YELLOW}⚠${NC} WireGuard服务未启用"
            echo -e "${YELLOW}   建议修复:${NC} sudo systemctl enable wg-quick@wg0"
        fi
    else
        echo -e "${RED}✗${NC} WireGuard服务未运行"
        issues_found=$((issues_found + 1))
        
        # 检查服务失败原因
        echo -e "${YELLOW}2. 检查服务失败原因...${NC}"
        local service_status=$(systemctl status wg-quick@wg0 --no-pager -l 2>&1)
        echo "服务状态:"
        echo "$service_status" | head -20
        
        # 检查journal日志
        echo -e "${YELLOW}3. 检查系统日志...${NC}"
        local journal_logs=$(journalctl -u wg-quick@wg0 --no-pager -l --since "5 minutes ago" 2>&1)
        if [[ -n "$journal_logs" ]]; then
            echo "最近的日志:"
            echo "$journal_logs" | tail -10
        else
            echo "没有找到相关日志"
        fi
        
        # 提供修复建议
        echo -e "${YELLOW}   建议修复:${NC}"
        echo "   1. sudo systemctl start wg-quick@wg0"
        echo "   2. sudo journalctl -u wg-quick@wg0 -f  # 查看实时日志"
        echo "   3. 检查配置文件: sudo wg-quick strip /etc/wireguard/wg0.conf"
    fi
    
    # 检查WireGuard工具
    echo -e "${YELLOW}4. 检查WireGuard工具...${NC}"
    if command -v wg >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} WireGuard工具已安装"
    else
        echo -e "${RED}✗${NC} WireGuard工具未安装"
        issues_found=$((issues_found + 1))
        echo -e "${YELLOW}   建议修复:${NC} 安装WireGuard工具"
    fi
    
    # 总结
    echo
    if [[ $issues_found -eq 0 ]]; then
        echo -e "${GREEN}✓ WireGuard服务诊断完成，未发现问题${NC}"
    else
        echo -e "${RED}✗ WireGuard服务诊断完成，发现 $issues_found 个问题${NC}"
        echo -e "${YELLOW}请按照上述建议修复问题后重试${NC}"
    fi
    
    return $issues_found
}

# WireGuard网络接口诊断
diagnose_wireguard_interface() {
    echo -e "${CYAN}=== WireGuard网络接口诊断 ===${NC}"
    
    local issues_found=0
    
    # 检查WireGuard接口
    echo -e "${YELLOW}1. 检查WireGuard接口...${NC}"
    if ip link show wg0 >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} WireGuard接口 wg0 存在"
        
        # 检查接口状态
        local wg_status=$(ip link show wg0 | grep -o "state [A-Z]*")
        echo "   状态: $wg_status"
        
        # 检查接口IP地址
        local wg_ip=$(ip addr show wg0 | grep "inet " | head -1)
        if [[ -n "$wg_ip" ]]; then
            echo -e "${GREEN}✓${NC} WireGuard接口有IP地址"
            echo "   $wg_ip"
        else
            echo -e "${RED}✗${NC} WireGuard接口没有IP地址"
            issues_found=$((issues_found + 1))
        fi
    else
        echo -e "${RED}✗${NC} WireGuard接口 wg0 不存在"
        issues_found=$((issues_found + 1))
        echo -e "${YELLOW}   建议修复:${NC} 启动WireGuard服务"
    fi
    
    # 检查内核模块
    echo -e "${YELLOW}2. 检查WireGuard内核模块...${NC}"
    if lsmod | grep -q wireguard; then
        echo -e "${GREEN}✓${NC} WireGuard内核模块已加载"
    else
        echo -e "${RED}✗${NC} WireGuard内核模块未加载"
        issues_found=$((issues_found + 1))
        echo -e "${YELLOW}   建议修复:${NC} sudo modprobe wireguard"
    fi
    
    # 检查端口占用
    echo -e "${YELLOW}3. 检查端口占用...${NC}"
    local wg_port=$(grep "ListenPort" /etc/wireguard/wg0.conf 2>/dev/null | awk '{print $3}')
    if [[ -n "$wg_port" ]]; then
        if ss -uln | grep -q ":$wg_port "; then
            echo -e "${GREEN}✓${NC} WireGuard端口 $wg_port 正在监听"
        else
            echo -e "${RED}✗${NC} WireGuard端口 $wg_port 未监听"
            issues_found=$((issues_found + 1))
        fi
    else
        echo -e "${YELLOW}⚠${NC} 无法确定WireGuard端口"
    fi
    
    # 总结
    echo
    if [[ $issues_found -eq 0 ]]; then
        echo -e "${GREEN}✓ WireGuard网络接口诊断完成，未发现问题${NC}"
    else
        echo -e "${RED}✗ WireGuard网络接口诊断完成，发现 $issues_found 个问题${NC}"
        echo -e "${YELLOW}请按照上述建议修复问题后重试${NC}"
    fi
    
    return $issues_found
}

# WireGuard防火墙诊断
diagnose_wireguard_firewall() {
    echo -e "${CYAN}=== WireGuard防火墙诊断 ===${NC}"
    
    local issues_found=0
    local wg_port=$(grep "ListenPort" /etc/wireguard/wg0.conf 2>/dev/null | awk '{print $3}')
    
    # 检查防火墙状态
    echo -e "${YELLOW}1. 检查防火墙状态...${NC}"
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            echo -e "${GREEN}✓${NC} UFW防火墙已启用"
            
            # 检查WireGuard端口规则
            if [[ -n "$wg_port" ]]; then
                if ufw status | grep -q "$wg_port/udp"; then
                    echo -e "${GREEN}✓${NC} WireGuard端口 $wg_port 已开放"
                else
                    echo -e "${RED}✗${NC} WireGuard端口 $wg_port 未开放"
                    issues_found=$((issues_found + 1))
                    echo -e "${YELLOW}   建议修复:${NC} sudo ufw allow $wg_port/udp"
                fi
            fi
        else
            echo -e "${YELLOW}⚠${NC} UFW防火墙未启用"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if systemctl is-active firewalld >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Firewalld防火墙已启用"
            
            # 检查WireGuard端口规则
            if [[ -n "$wg_port" ]]; then
                if firewall-cmd --list-ports | grep -q "$wg_port/udp"; then
                    echo -e "${GREEN}✓${NC} WireGuard端口 $wg_port 已开放"
                else
                    echo -e "${RED}✗${NC} WireGuard端口 $wg_port 未开放"
                    issues_found=$((issues_found + 1))
                    echo -e "${YELLOW}   建议修复:${NC} sudo firewall-cmd --permanent --add-port=$wg_port/udp && sudo firewall-cmd --reload"
                fi
            fi
        else
            echo -e "${YELLOW}⚠${NC} Firewalld防火墙未启用"
        fi
    else
        echo -e "${YELLOW}⚠${NC} 未检测到支持的防火墙"
    fi
    
    # 总结
    echo
    if [[ $issues_found -eq 0 ]]; then
        echo -e "${GREEN}✓ WireGuard防火墙诊断完成，未发现问题${NC}"
    else
        echo -e "${RED}✗ WireGuard防火墙诊断完成，发现 $issues_found 个问题${NC}"
        echo -e "${YELLOW}请按照上述建议修复问题后重试${NC}"
    fi
    
    return $issues_found
}

# WireGuard自动修复
auto_fix_wireguard_issues() {
    echo -e "${CYAN}=== WireGuard自动修复 ===${NC}"
    
    local fixes_applied=0
    
    # 修复配置文件权限
    echo -e "${YELLOW}1. 修复配置文件权限...${NC}"
    if [[ -f "/etc/wireguard/wg0.conf" ]]; then
        if chown root:root /etc/wireguard/wg0.conf && chmod 600 /etc/wireguard/wg0.conf; then
            echo -e "${GREEN}✓${NC} 配置文件权限已修复"
            fixes_applied=$((fixes_applied + 1))
        else
            echo -e "${RED}✗${NC} 配置文件权限修复失败"
        fi
    fi
    
    # 加载WireGuard内核模块
    echo -e "${YELLOW}2. 加载WireGuard内核模块...${NC}"
    if modprobe wireguard 2>/dev/null; then
        echo -e "${GREEN}✓${NC} WireGuard内核模块已加载"
        fixes_applied=$((fixes_applied + 1))
    else
        echo -e "${RED}✗${NC} WireGuard内核模块加载失败"
    fi
    
    # 尝试启动WireGuard服务
    echo -e "${YELLOW}3. 尝试启动WireGuard服务...${NC}"
    if systemctl start wg-quick@wg0 2>/dev/null; then
        echo -e "${GREEN}✓${NC} WireGuard服务启动成功"
        fixes_applied=$((fixes_applied + 1))
    else
        echo -e "${YELLOW}⚠${NC} WireGuard服务启动失败，请检查配置"
    fi
    
    # 总结
    echo
    echo -e "${CYAN}=== 修复总结 ===${NC}"
    echo "已应用 $fixes_applied 个修复"
    
    if [[ $fixes_applied -gt 0 ]]; then
        echo -e "${GREEN}建议重新运行诊断以确认问题已解决${NC}"
    else
        echo -e "${YELLOW}没有应用任何修复，可能需要手动干预${NC}"
    fi
    
    return $fixes_applied
}

# 显示WireGuard日志
show_wireguard_logs() {
    echo -e "${CYAN}=== WireGuard详细日志 ===${NC}"
    
    echo -e "${YELLOW}服务状态:${NC}"
    systemctl status wg-quick@wg0 --no-pager -l
    
    echo
    echo -e "${YELLOW}最近的日志:${NC}"
    journalctl -u wg-quick@wg0 --no-pager -l --since "10 minutes ago"
    
    echo
    echo -e "${YELLOW}实时日志 (按Ctrl+C退出):${NC}"
    echo "正在启动实时日志监控..."
    journalctl -u wg-quick@wg0 -f
}
