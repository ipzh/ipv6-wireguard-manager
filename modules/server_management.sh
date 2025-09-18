#!/bin/bash

# 服务器管理模块
# 提供服务器状态监控、服务控制、日志查看等功能

# 获取脚本目录（如果未定义）
if [[ -z "$SCRIPT_DIR" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# 服务器管理菜单
server_management_menu() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    服务器管理                              ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        # 显示服务状态
        show_service_status
        
        echo -e "${YELLOW}服务器管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看服务状态"
        echo -e "  ${GREEN}2.${NC} 启动服务"
        echo -e "  ${GREEN}3.${NC} 停止服务"
        echo -e "  ${GREEN}4.${NC} 重启服务"
        echo -e "  ${GREEN}5.${NC} 重载配置"
        echo -e "  ${GREEN}6.${NC} 查看服务日志"
        echo -e "  ${GREEN}7.${NC} 查看系统资源使用"
        echo -e "  ${GREEN}8.${NC} 查看网络连接"
        echo -e "  ${GREEN}9.${NC} BIRD诊断工具"
        echo -e "  ${GREEN}10.${NC} WireGuard诊断工具"
        echo -e "  ${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 (0-10): " choice
        
        case "$choice" in
            "1")
                show_service_status
                read -p "按回车键继续..."
                ;;
            "2")
                start_services_manually
                ;;
            "3")
                stop_services_manually
                ;;
            "4")
                restart_services_manually
                ;;
            "5")
                reload_configurations
                ;;
            "6")
                view_service_logs
                ;;
            "7")
                show_system_resources
                ;;
            "8")
                show_network_connections
                ;;
            "9")
                bird_diagnostic_tool
                ;;
            "10")
                # 加载WireGuard诊断模块
                if [[ -f "$SCRIPT_DIR/modules/wireguard_diagnostics.sh" ]]; then
                    source "$SCRIPT_DIR/modules/wireguard_diagnostics.sh"
                    wireguard_diagnostic_tool
                else
                    echo -e "${RED}WireGuard诊断模块不可用${NC}"
                    read -p "按回车键继续..."
                fi
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

# 显示服务状态
show_service_status() {
    echo -e "${CYAN}服务状态:${NC}"
    echo
    
    # WireGuard状态
    if systemctl is-active --quiet wg-quick@wg0; then
        echo -e "  WireGuard: ${GREEN}运行中${NC}"
        local wg_peers=$(wg show wg0 | grep -c "peer:" 2>/dev/null || echo "0")
        echo -e "    连接客户端: $wg_peers"
    else
        echo -e "  WireGuard: ${RED}未运行${NC}"
    fi
    
    # BIRD状态
    if systemctl is-active --quiet bird; then
        echo -e "  BIRD BGP: ${GREEN}运行中${NC}"
    elif systemctl is-active --quiet bird2; then
        echo -e "  BIRD BGP: ${GREEN}运行中${NC}"
    else
        echo -e "  BIRD BGP: ${RED}未运行${NC}"
    fi
    
    # 防火墙状态
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            echo -e "  防火墙 (UFW): ${GREEN}已启用${NC}"
        else
            echo -e "  防火墙 (UFW): ${YELLOW}已禁用${NC}"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if systemctl is-active --quiet firewalld; then
            echo -e "  防火墙 (Firewalld): ${GREEN}已启用${NC}"
        else
            echo -e "  防火墙 (Firewalld): ${YELLOW}已禁用${NC}"
        fi
    else
        echo -e "  防火墙: ${YELLOW}未配置${NC}"
    fi
    
    echo
}

# 手动启动服务
start_services_manually() {
    echo -e "${CYAN}启动服务...${NC}"
    
    # 启动WireGuard
    if systemctl start wg-quick@wg0; then
        echo -e "${GREEN}✓${NC} WireGuard 启动成功"
    else
        echo -e "${RED}✗${NC} WireGuard 启动失败"
    fi
    
    # 启动BIRD
    if systemctl is-active --quiet bird; then
        echo -e "${GREEN}✓${NC} BIRD 已在运行"
    elif systemctl is-active --quiet bird2; then
        echo -e "${GREEN}✓${NC} BIRD2 已在运行"
    else
        echo -e "${CYAN}正在启动BIRD服务...${NC}"
        if systemctl start bird 2>/dev/null; then
            echo -e "${GREEN}✓${NC} BIRD 1.x 启动成功"
        elif systemctl start bird2 2>/dev/null; then
            echo -e "${GREEN}✓${NC} BIRD 2.x 启动成功"
        else
            echo -e "${RED}✗${NC} BIRD 启动失败"
            echo -e "${YELLOW}正在诊断BIRD启动问题...${NC}"
            diagnose_bird_startup_issue
        fi
    fi
    
    read -p "按回车键继续..."
}

# 诊断BIRD启动问题
diagnose_bird_startup_issue() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                    BIRD启动问题诊断                          ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    # 使用BIRD配置模块的综合诊断功能
    if [[ -f "$SCRIPT_DIR/modules/bird_config.sh" ]]; then
        source "$SCRIPT_DIR/modules/bird_config.sh"
        
        # 运行综合诊断
        if declare -f diagnose_bird_comprehensive >/dev/null; then
            echo -e "${YELLOW}运行BIRD综合诊断...${NC}"
            diagnose_bird_comprehensive
            return $?
        fi
    fi
    
    # 如果BIRD配置模块不可用，使用基本诊断
    echo -e "${YELLOW}使用基本诊断模式...${NC}"
    
    # 检查BIRD是否安装
    echo -e "${YELLOW}1. 检查BIRD安装状态:${NC}"
    if command -v birdc2 >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} BIRD 2.x 已安装"
        local bird_version="2.x"
        local bird_service="bird2"
    elif command -v birdc >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} BIRD 1.x 已安装"
        local bird_version="1.x"
        local bird_service="bird"
    else
        echo -e "  ${RED}✗${NC} BIRD 未安装"
        echo -e "  ${YELLOW}建议: 安装BIRD以启用BGP功能${NC}"
        return 1
    fi
    
    # 检查配置文件
    echo -e "${YELLOW}2. 检查BIRD配置文件:${NC}"
    local config_file="/etc/bird/bird.conf"
    if [[ -f "$config_file" ]]; then
        echo -e "  ${GREEN}✓${NC} 配置文件存在: $config_file"
        
        # 检查配置文件语法
        if [[ "$bird_version" == "2.x" ]]; then
            if birdc2 configure 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} 配置文件语法正确"
            else
                echo -e "  ${RED}✗${NC} 配置文件语法错误"
                echo -e "  ${YELLOW}建议: 检查配置文件语法${NC}"
                show_bird_config_errors
            fi
        else
            if birdc configure 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} 配置文件语法正确"
            else
                echo -e "  ${RED}✗${NC} 配置文件语法错误"
                echo -e "  ${YELLOW}建议: 检查配置文件语法${NC}"
                show_bird_config_errors
            fi
        fi
    else
        echo -e "  ${RED}✗${NC} 配置文件不存在: $config_file"
        echo -e "  ${YELLOW}建议: 创建BIRD配置文件${NC}"
    fi
    
    # 检查服务状态
    echo -e "${YELLOW}3. 检查BIRD服务状态:${NC}"
    if systemctl is-enabled "$bird_service" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} 服务已启用"
    else
        echo -e "  ${YELLOW}⚠${NC} 服务未启用"
        echo -e "  ${YELLOW}建议: 启用BIRD服务${NC}"
    fi
    
    # 检查服务日志
    echo -e "${YELLOW}4. 检查BIRD服务日志:${NC}"
    local recent_logs=$(journalctl -u "$bird_service" --no-pager -n 10 2>/dev/null)
    if [[ -n "$recent_logs" ]]; then
        echo -e "  ${CYAN}最近的日志:${NC}"
        echo "$recent_logs" | while read line; do
            echo -e "    $line"
        done
    else
        echo -e "  ${YELLOW}⚠${NC} 无日志记录"
    fi
    
    # 检查端口占用
    echo -e "${YELLOW}5. 检查端口占用:${NC}"
    local bird_ports=$(ss -tulpn | grep -E "(179|bgp)" 2>/dev/null)
    if [[ -n "$bird_ports" ]]; then
        echo -e "  ${YELLOW}⚠${NC} BGP端口可能被占用:"
        echo "$bird_ports" | while read line; do
            echo -e "    $line"
        done
    else
        echo -e "  ${GREEN}✓${NC} BGP端口未被占用"
    fi
    
    # 检查权限
    echo -e "${YELLOW}6. 检查文件权限:${NC}"
    local config_dir="/etc/bird"
    if [[ -d "$config_dir" ]]; then
        local perms=$(ls -ld "$config_dir" 2>/dev/null)
        echo -e "  ${CYAN}配置目录权限:${NC} $perms"
        
        if [[ -f "$config_file" ]]; then
            local file_perms=$(ls -l "$config_file" 2>/dev/null)
            echo -e "  ${CYAN}配置文件权限:${NC} $file_perms"
        fi
    fi
    
    # 提供修复建议
    echo
    echo -e "${CYAN}修复建议:${NC}"
    echo -e "  1. 检查配置文件语法: ${YELLOW}birdc configure check${NC}"
    echo -e "  2. 重新加载配置: ${YELLOW}systemctl reload $bird_service${NC}"
    echo -e "  3. 重启服务: ${YELLOW}systemctl restart $bird_service${NC}"
    echo -e "  4. 查看详细日志: ${YELLOW}journalctl -u $bird_service -f${NC}"
    echo -e "  5. 检查配置文件: ${YELLOW}cat $config_file${NC}"
    
    echo
    read -p "按回车键继续..."
}

# 显示BIRD配置错误
show_bird_config_errors() {
    echo -e "${CYAN}配置错误详情:${NC}"
    
    if command -v birdc2 >/dev/null 2>&1; then
        birdc2 configure 2>&1 | while read line; do
            echo -e "  ${RED}$line${NC}"
        done
    elif command -v birdc >/dev/null 2>&1; then
        birdc configure 2>&1 | while read line; do
            echo -e "  ${RED}$line${NC}"
        done
    fi
}

# 手动停止服务
stop_services_manually() {
    echo -e "${CYAN}停止服务...${NC}"
    
    # 停止WireGuard
    if systemctl stop wg-quick@wg0; then
        echo -e "${GREEN}✓${NC} WireGuard 停止成功"
    else
        echo -e "${RED}✗${NC} WireGuard 停止失败"
    fi
    
    # 停止BIRD
    if systemctl stop bird 2>/dev/null || systemctl stop bird2 2>/dev/null; then
        echo -e "${GREEN}✓${NC} BIRD 停止成功"
    else
        echo -e "${YELLOW}⚠${NC} BIRD 停止失败或未运行"
    fi
    
    read -p "按回车键继续..."
}

# 手动重启服务
restart_services_manually() {
    echo -e "${CYAN}重启服务...${NC}"
    
    # 重启WireGuard
    if systemctl restart wg-quick@wg0; then
        echo -e "${GREEN}✓${NC} WireGuard 重启成功"
    else
        echo -e "${RED}✗${NC} WireGuard 重启失败"
    fi
    
    # 重启BIRD
    echo -e "${CYAN}正在重启BIRD服务...${NC}"
    if systemctl restart bird 2>/dev/null; then
        echo -e "${GREEN}✓${NC} BIRD 1.x 重启成功"
    elif systemctl restart bird2 2>/dev/null; then
        echo -e "${GREEN}✓${NC} BIRD 2.x 重启成功"
    else
        echo -e "${RED}✗${NC} BIRD 重启失败"
        echo -e "${YELLOW}正在诊断BIRD重启问题...${NC}"
        diagnose_bird_startup_issue
    fi
    
    read -p "按回车键继续..."
}

# 重载配置
reload_configurations() {
    echo -e "${CYAN}重载配置...${NC}"
    
    # 重载WireGuard配置
    if wg-quick down wg0 2>/dev/null && wg-quick up wg0 2>/dev/null; then
        echo -e "${GREEN}✓${NC} WireGuard 配置重载成功"
    else
        echo -e "${RED}✗${NC} WireGuard 配置重载失败"
    fi
    
    # 重载BIRD配置
    if command -v birdc >/dev/null 2>&1; then
        if birdc configure 2>/dev/null; then
            echo -e "${GREEN}✓${NC} BIRD 配置重载成功"
        else
            echo -e "${YELLOW}⚠${NC} BIRD 配置重载失败"
        fi
    elif command -v birdc2 >/dev/null 2>&1; then
        if birdc2 configure 2>/dev/null; then
            echo -e "${GREEN}✓${NC} BIRD2 配置重载成功"
        else
            echo -e "${YELLOW}⚠${NC} BIRD2 配置重载失败"
        fi
    else
        echo -e "${YELLOW}⚠${NC} BIRD 控制台未找到"
    fi
    
    read -p "按回车键继续..."
}

# 查看服务日志
view_service_logs() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    服务日志查看                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}日志查看选项:${NC}"
        echo -e "  ${GREEN}1.${NC} WireGuard 日志"
        echo -e "  ${GREEN}2.${NC} BIRD 日志"
        echo -e "  ${GREEN}3.${NC} 系统日志"
        echo -e "  ${GREEN}4.${NC} 防火墙日志"
        echo -e "  ${GREEN}5.${NC} 实时日志监控"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择 (0-5): " choice
        
        case "$choice" in
            "1")
                echo -e "${CYAN}WireGuard 日志 (最近50行):${NC}"
                journalctl -u wg-quick@wg0 -n 50 --no-pager
                read -p "按回车键继续..."
                ;;
            "2")
                echo -e "${CYAN}BIRD 日志 (最近50行):${NC}"
                if [[ -f /var/log/bird/bird.log ]]; then
                    tail -50 /var/log/bird/bird.log
                else
                    journalctl -u bird -n 50 --no-pager 2>/dev/null || journalctl -u bird2 -n 50 --no-pager 2>/dev/null || echo "BIRD 日志未找到"
                fi
                read -p "按回车键继续..."
                ;;
            "3")
                echo -e "${CYAN}系统日志 (最近50行):${NC}"
                journalctl -n 50 --no-pager
                read -p "按回车键继续..."
                ;;
            "4")
                echo -e "${CYAN}防火墙日志:${NC}"
                if command -v ufw >/dev/null 2>&1; then
                    ufw status verbose
                elif command -v firewall-cmd >/dev/null 2>&1; then
                    firewall-cmd --list-all
                else
                    iptables -L -n
                fi
                read -p "按回车键继续..."
                ;;
            "5")
                echo -e "${CYAN}实时日志监控 (按 Ctrl+C 退出):${NC}"
                journalctl -f
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

# 显示系统资源使用
show_system_resources() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    系统资源使用                            ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # CPU使用率
    echo -e "${CYAN}CPU 使用率:${NC}"
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | while read cpu; do
        echo "  CPU: ${cpu}%"
    done
    
    # 内存使用
    echo -e "${CYAN}内存使用:${NC}"
    free -h | grep -E "Mem|Swap" | while read line; do
        echo "  $line"
    done
    
    # 磁盘使用
    echo -e "${CYAN}磁盘使用:${NC}"
    df -h | grep -E "/$|/var|/etc" | while read line; do
        echo "  $line"
    done
    
    # 网络接口统计
    echo -e "${CYAN}网络接口统计:${NC}"
    if command -v wg >/dev/null 2>&1; then
        wg show wg0 2>/dev/null | while read line; do
            echo "  $line"
        done
    fi
    
    # 进程信息
    echo -e "${CYAN}相关进程:${NC}"
    ps aux | grep -E "wireguard|bird|wg-quick" | grep -v grep | while read line; do
        echo "  $line"
    done
    
    echo
    read -p "按回车键继续..."
}

# 显示网络连接
show_network_connections() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    网络连接状态                            ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # WireGuard接口信息
    echo -e "${CYAN}WireGuard 接口信息:${NC}"
    if command -v wg >/dev/null 2>&1; then
        wg show wg0 2>/dev/null || echo "  WireGuard 接口未配置或未运行"
    else
        echo "  WireGuard 工具未安装"
    fi
    
    echo
    
    # 网络接口状态
    echo -e "${CYAN}网络接口状态:${NC}"
    ip addr show | grep -E "inet|inet6" | while read line; do
        echo "  $line"
    done
    
    echo
    
    # 路由表
    echo -e "${CYAN}IPv6 路由表:${NC}"
    ip -6 route show | head -20 | while read line; do
        echo "  $line"
    done
    
    echo
    
    # 活动连接
    echo -e "${CYAN}活动连接 (UDP):${NC}"
    ss -uln | grep -E ":51820|:179" | while read line; do
        echo "  $line"
    done
    
    echo
    read -p "按回车键继续..."
}

# BIRD诊断工具
bird_diagnostic_tool() {
    while true; do
        clear
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}                    BIRD诊断工具                              ${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}BIRD诊断选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 综合诊断 (推荐)"
        echo -e "  ${GREEN}2.${NC} 安装诊断"
        echo -e "  ${GREEN}3.${NC} 配置诊断"
        echo -e "  ${GREEN}4.${NC} 服务诊断"
        echo -e "  ${GREEN}5.${NC} 网络诊断"
        echo -e "  ${GREEN}6.${NC} 自动修复"
        echo -e "  ${GREEN}7.${NC} 查看配置错误详情"
        echo -e "  ${GREEN}0.${NC} 返回服务器管理"
        echo
        
        read -p "请选择诊断类型 (0-7): " choice
        
        case "$choice" in
            "1")
                echo -e "${CYAN}运行BIRD综合诊断...${NC}"
                if [[ -f "$SCRIPT_DIR/modules/bird_config.sh" ]]; then
                    source "$SCRIPT_DIR/modules/bird_config.sh"
                    if declare -f diagnose_bird_comprehensive >/dev/null; then
                        diagnose_bird_comprehensive
                    else
                        echo -e "${RED}BIRD配置模块不可用${NC}"
                    fi
                else
                    echo -e "${RED}BIRD配置模块文件不存在${NC}"
                fi
                read -p "按回车键继续..."
                ;;
            "2")
                echo -e "${CYAN}运行BIRD安装诊断...${NC}"
                if [[ -f "$SCRIPT_DIR/modules/bird_config.sh" ]]; then
                    source "$SCRIPT_DIR/modules/bird_config.sh"
                    if declare -f diagnose_bird_installation >/dev/null; then
                        diagnose_bird_installation
                    else
                        echo -e "${RED}BIRD配置模块不可用${NC}"
                    fi
                else
                    echo -e "${RED}BIRD配置模块文件不存在${NC}"
                fi
                read -p "按回车键继续..."
                ;;
            "3")
                echo -e "${CYAN}运行BIRD配置诊断...${NC}"
                if [[ -f "$SCRIPT_DIR/modules/bird_config.sh" ]]; then
                    source "$SCRIPT_DIR/modules/bird_config.sh"
                    if declare -f diagnose_bird_configuration >/dev/null; then
                        diagnose_bird_configuration
                    else
                        echo -e "${RED}BIRD配置模块不可用${NC}"
                    fi
                else
                    echo -e "${RED}BIRD配置模块文件不存在${NC}"
                fi
                read -p "按回车键继续..."
                ;;
            "4")
                echo -e "${CYAN}运行BIRD服务诊断...${NC}"
                if [[ -f "$SCRIPT_DIR/modules/bird_config.sh" ]]; then
                    source "$SCRIPT_DIR/modules/bird_config.sh"
                    if declare -f diagnose_bird_service >/dev/null; then
                        diagnose_bird_service
                    else
                        echo -e "${RED}BIRD配置模块不可用${NC}"
                    fi
                else
                    echo -e "${RED}BIRD配置模块文件不存在${NC}"
                fi
                read -p "按回车键继续..."
                ;;
            "5")
                echo -e "${CYAN}运行BIRD网络诊断...${NC}"
                if [[ -f "$SCRIPT_DIR/modules/bird_config.sh" ]]; then
                    source "$SCRIPT_DIR/modules/bird_config.sh"
                    if declare -f diagnose_bird_network >/dev/null; then
                        diagnose_bird_network
                    else
                        echo -e "${RED}BIRD配置模块不可用${NC}"
                    fi
                else
                    echo -e "${RED}BIRD配置模块文件不存在${NC}"
                fi
                read -p "按回车键继续..."
                ;;
            "6")
                echo -e "${CYAN}运行BIRD自动修复...${NC}"
                if [[ -f "$SCRIPT_DIR/modules/bird_config.sh" ]]; then
                    source "$SCRIPT_DIR/modules/bird_config.sh"
                    if declare -f auto_fix_bird_issues >/dev/null; then
                        auto_fix_bird_issues
                    else
                        echo -e "${RED}BIRD配置模块不可用${NC}"
                    fi
                else
                    echo -e "${RED}BIRD配置模块文件不存在${NC}"
                fi
                read -p "按回车键继续..."
                ;;
            "7")
                echo -e "${CYAN}查看BIRD配置错误详情...${NC}"
                if [[ -f "$SCRIPT_DIR/modules/bird_config.sh" ]]; then
                    source "$SCRIPT_DIR/modules/bird_config.sh"
                    if declare -f show_bird_config_errors >/dev/null; then
                        show_bird_config_errors
                    else
                        echo -e "${RED}BIRD配置模块不可用${NC}"
                    fi
                else
                    echo -e "${RED}BIRD配置模块文件不存在${NC}"
                fi
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
