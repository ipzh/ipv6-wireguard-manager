#!/bin/bash

# 菜单模板模块
# 定义所有菜单的结构和选项

# 主菜单
show_main_menu() {
    local options=(
        "快速安装 - 一键配置所有服务"
        "交互式安装 - 自定义配置安装"
        "服务器管理 - 服务状态管理"
        "客户端管理 - 客户端配置管理"
        "客户端自动安装 - 生成安装链接和远程安装"
        "Web管理界面 - 启动Web管理界面"
        "客户端监控 - 实时监控客户端状态"
        "批量管理 - 批量客户端操作"
        "网络配置 - IPv6前缀和BGP配置"
        "BGP配置管理 - BGP路由配置"
        "防火墙管理 - 防火墙规则管理"
        "系统维护 - 系统状态和日志管理"
        "配置备份/恢复 - 配置备份和恢复"
        "更新检查 - 版本更新检查"
        "下载必需文件 - 下载缺失的文件"
        "安全增强功能 - 安全扫描和增强"
        "用户界面功能 - 界面优化和主题"
        "监控告警功能 - 监控和告警系统"
    )
    
    show_menu "main" "主菜单" "${options[@]}"
}

# 服务器管理菜单
server_management_menu() {
    local options=(
        "查看服务状态 - WireGuard、BIRD等服务状态"
        "启动服务 - 启动相关服务"
        "停止服务 - 停止相关服务"
        "重启服务 - 重启相关服务"
        "重载配置 - 重新加载配置文件"
        "查看服务日志 - 查看服务运行日志"
        "查看系统资源使用 - CPU、内存、磁盘使用情况"
        "查看网络连接 - 网络连接状态和统计"
        "BIRD诊断工具 - BGP路由诊断"
        "WireGuard诊断工具 - VPN连接诊断"
    )
    
    show_menu "server" "服务器管理" "${options[@]}"
}

# 客户端管理菜单
client_management_menu() {
    local options=(
        "添加客户端 - 创建新的客户端配置"
        "删除客户端 - 删除现有客户端"
        "查看客户端列表 - 显示所有客户端"
        "生成客户端配置 - 生成配置文件或QR码"
        "客户端状态查看 - 查看连接状态"
        "批量导入客户端 - 从CSV文件导入"
        "客户端配置修改 - 修改现有配置"
        "客户端数据库管理 - 管理客户端数据库"
    )
    
    show_menu "client" "客户端管理" "${options[@]}"
}

# 客户端自动安装菜单
client_auto_install_menu() {
    local options=(
        "生成安装链接 - 创建客户端安装链接"
        "远程自动安装 - 基于IP/端口/密码的远程安装"
        "安装令牌管理 - 管理安装令牌"
        "安装统计查看 - 查看安装统计信息"
    )
    
    show_menu "client_auto" "客户端自动安装" "${options[@]}"
}

# Web管理界面菜单
web_interface_menu() {
    local options=(
        "安装Web管理服务 - 安装nginx/apache和Web界面"
        "启动Web服务 - 启动Web管理服务"
        "停止Web服务 - 停止Web管理服务"
        "重启Web服务 - 重启Web管理服务"
        "查看Web服务状态 - 检查Web服务状态"
        "配置Web界面 - 设置Web界面参数"
        "访问控制设置 - 配置访问权限"
        "SSL配置 - 配置HTTPS支持"
        "卸载Web管理服务 - 完全移除Web服务"
    )
    
    show_menu "web" "Web管理界面" "${options[@]}"
}

# 客户端监控菜单
client_monitoring_menu() {
    local options=(
        "实时连接监控 - 查看客户端连接状态"
        "连接统计 - 查看连接统计信息"
        "离线警报设置 - 配置离线告警"
        "自动重连设置 - 配置自动重连"
        "监控历史查看 - 查看历史监控数据"
        "监控配置管理 - 管理监控配置"
    )
    
    show_menu "monitoring" "客户端监控" "${options[@]}"
}

# 批量管理菜单
batch_management_menu() {
    local options=(
        "CSV模板下载 - 下载客户端CSV模板"
        "批量导入客户端 - 从CSV文件批量导入"
        "批量生成配置 - 批量生成客户端配置"
        "批量删除客户端 - 批量删除客户端"
        "批量操作历史 - 查看批量操作历史"
    )
    
    show_menu "batch" "批量管理" "${options[@]}"
}

# 网络配置菜单
network_config_menu() {
    local options=(
        "IPv6前缀管理 - 管理IPv6前缀分配"
        "BGP邻居配置 - 配置BGP邻居"
        "路由表查看 - 查看路由表信息"
        "网络诊断 - 网络连接诊断"
        "接口配置 - 网络接口配置"
        "DNS配置 - DNS服务器配置"
    )
    
    show_menu "network" "网络配置" "${options[@]}"
}

# BGP配置管理菜单
bgp_config_menu() {
    local options=(
        "BGP基本配置 - 配置BGP基本参数"
        "BGP邻居管理 - 管理BGP邻居"
        "路由策略配置 - 配置路由策略"
        "BGP状态查看 - 查看BGP状态"
        "BGP日志查看 - 查看BGP日志"
        "BGP性能监控 - 监控BGP性能"
        "BGP配置备份 - 备份BGP配置"
        "BGP配置恢复 - 恢复BGP配置"
    )
    
    show_menu "bgp" "BGP配置管理" "${options[@]}"
}

# 防火墙管理菜单
firewall_management_menu() {
    local options=(
        "防火墙状态查看 - 查看防火墙状态"
        "规则管理 - 管理防火墙规则"
        "端口管理 - 管理开放端口"
        "服务管理 - 管理防火墙服务"
        "区域管理 - 管理防火墙区域"
        "日志查看 - 查看防火墙日志"
        "配置备份 - 备份防火墙配置"
        "配置恢复 - 恢复防火墙配置"
    )
    
    show_menu "firewall" "防火墙管理" "${options[@]}"
}

# 系统维护菜单
system_maintenance_menu() {
    local options=(
        "系统状态检查 - 全面的系统健康检查"
        "性能监控 - 实时性能监控"
        "日志管理 - 系统日志管理"
        "磁盘空间管理 - 磁盘使用监控"
        "系统更新 - 系统包更新"
        "进程管理 - 进程监控"
        "系统清理 - 临时文件清理"
        "安全扫描 - 安全漏洞扫描"
    )
    
    show_menu "system" "系统维护" "${options[@]}"
}

# 配置备份恢复菜单
backup_restore_menu() {
    local options=(
        "自动备份设置 - 配置自动备份"
        "手动备份 - 立即创建备份"
        "备份列表查看 - 查看所有备份"
        "配置恢复 - 从备份恢复配置"
        "备份清理 - 清理旧备份"
        "备份验证 - 验证备份完整性"
    )
    
    show_menu "backup" "配置备份/恢复" "${options[@]}"
}

# 更新检查菜单
update_check_menu() {
    local options=(
        "检查更新 - 检查可用更新"
        "自动更新设置 - 配置自动更新"
        "更新日志查看 - 查看更新日志"
        "版本信息查看 - 查看版本信息"
        "回滚更新 - 回滚到之前版本"
    )
    
    show_menu "update" "更新检查" "${options[@]}"
}

# 安全增强功能菜单
security_enhancements_menu() {
    local options=(
        "安全扫描 - 执行安全扫描"
        "权限检查 - 检查文件权限"
        "密钥轮换 - 轮换加密密钥"
        "访问控制 - 配置访问控制"
        "审计日志 - 查看审计日志"
        "安全配置 - 安全配置管理"
        "威胁检测 - 威胁检测设置"
    )
    
    show_menu "security" "安全增强功能" "${options[@]}"
}

# 用户界面功能菜单
user_interface_menu() {
    local options=(
        "主题设置 - 更改界面主题"
        "颜色设置 - 配置界面颜色"
        "动画设置 - 配置界面动画"
        "快捷键设置 - 配置快捷键"
        "界面语言 - 设置界面语言"
        "界面布局 - 配置界面布局"
        "用户偏好 - 管理用户偏好"
    )
    
    show_menu "ui" "用户界面功能" "${options[@]}"
}

# 监控告警功能菜单
monitoring_alerting_menu() {
    local options=(
        "告警规则配置 - 配置告警规则"
        "告警历史查看 - 查看告警历史"
        "通知方式设置 - 配置通知方式"
        "监控指标设置 - 配置监控指标"
        "告警测试 - 测试告警功能"
        "监控面板 - 查看监控面板"
    )
    
    show_menu "alerting" "监控告警功能" "${options[@]}"
}

# 处理主菜单选择
handle_main_menu_selection() {
    local choice="$1"
    local option="$2"
    
    case $choice in
        1) quick_install ;;
        2) interactive_install ;;
        3) server_management_menu ;;
        4) client_management_menu ;;
        5) client_auto_install_menu ;;
        6) web_interface_menu ;;
        7) client_monitoring_menu ;;
        8) batch_management_menu ;;
        9) network_config_menu ;;
        10) bgp_config_menu ;;
        11) firewall_management_menu ;;
        12) system_maintenance_menu ;;
        13) backup_restore_menu ;;
        14) update_check_menu ;;
        15) download_required_files ;;
        16) security_enhancements_menu ;;
        17) user_interface_menu ;;
        18) monitoring_alerting_menu ;;
        *) show_error "无效选择" ;;
    esac
}

# 处理服务器管理菜单选择
handle_server_menu_selection() {
    local choice="$1"
    local option="$2"
    
    case $choice in
        1) show_service_status ;;
        2) start_services ;;
        3) stop_services ;;
        4) restart_services ;;
        5) reload_configurations ;;
        6) show_service_logs ;;
        7) show_system_resources ;;
        8) show_network_connections ;;
        9) run_bird_diagnostics ;;
        10) run_wireguard_diagnostics ;;
        *) show_error "无效选择" ;;
    esac
}

# 处理客户端管理菜单选择
handle_client_menu_selection() {
    local choice="$1"
    local option="$2"
    
    case $choice in
        1) add_client ;;
        2) remove_client ;;
        3) list_clients ;;
        4) generate_client_config ;;
        5) show_client_status ;;
        6) import_clients_batch ;;
        7) modify_client_config ;;
        8) manage_client_database ;;
        *) show_error "无效选择" ;;
    esac
}

# 处理网络配置菜单选择
handle_network_menu_selection() {
    local choice="$1"
    local option="$2"
    
    case $choice in
        1) manage_ipv6_prefixes ;;
        2) configure_bgp_neighbors ;;
        3) show_routing_table ;;
        4) diagnose_network ;;
        5) configure_interfaces ;;
        6) configure_dns ;;
        *) show_error "无效选择" ;;
    esac
}

# 处理防火墙管理菜单选择
handle_firewall_menu_selection() {
    local choice="$1"
    local option="$2"
    
    case $choice in
        1) show_firewall_status ;;
        2) manage_firewall_rules ;;
        3) manage_firewall_ports ;;
        4) manage_firewall_services ;;
        5) manage_firewall_zones ;;
        6) show_firewall_logs ;;
        7) backup_firewall_config ;;
        8) restore_firewall_config ;;
        *) show_error "无效选择" ;;
    esac
}

# 处理系统维护菜单选择
handle_system_menu_selection() {
    local choice="$1"
    local option="$2"
    
    case $choice in
        1) check_system_status ;;
        2) monitor_system_performance ;;
        3) manage_system_logs ;;
        4) manage_disk_space ;;
        5) update_system_packages ;;
        6) manage_processes ;;
        7) clean_system_temp ;;
        8) run_security_scan ;;
        *) show_error "无效选择" ;;
    esac
}

# 快速安装
quick_install() {
    show_loading "正在执行快速安装..." 3
    
    if check_dependencies; then
        install_dependencies
        configure_wireguard
        configure_bird
        configure_firewall
        start_services
        
        show_success "快速安装完成!"
    else
        show_error "依赖检查失败，无法继续安装"
    fi
    
    read -p "按回车键继续..."
}

# 交互式安装
interactive_install() {
    show_info "开始交互式安装..."
    
    # 获取用户配置
    get_user_config
    
    # 执行安装
    quick_install
    
    show_success "交互式安装完成!"
    read -p "按回车键继续..."
}

# 获取用户配置
get_user_config() {
    show_info "请输入配置信息:"
    
    WIREGUARD_PORT=$(show_input "WireGuard端口" "51820" "validate_port")
    WIREGUARD_INTERFACE=$(show_input "WireGuard接口名" "wg0" "validate_interface")
    WIREGUARD_NETWORK=$(show_input "IPv4网络" "10.0.0.0/24" "validate_cidr")
    IPV6_PREFIX=$(show_input "IPv6前缀" "2001:db8::/56" "validate_cidr")
    
    local bird_options=("auto" "1.x" "2.x" "3.x")
    BIRD_VERSION=$(show_selection "BIRD版本" "${bird_options[@]}")
    
    local firewall_options=("auto" "ufw" "firewalld" "nftables" "iptables")
    FIREWALL_TYPE=$(show_selection "防火墙类型" "${firewall_options[@]}")
    
    WEB_PORT=$(show_input "Web管理端口" "8080" "validate_port")
    WEB_USER=$(show_input "Web管理用户名" "admin")
    WEB_PASS=$(show_password_input "Web管理密码" "确认密码")
    
    # 保存配置
    save_config
    
    show_success "配置已保存"
}

# 下载必需文件
download_required_files() {
    show_loading "正在下载必需文件..." 2
    
    local files=(
        "https://raw.githubusercontent.com/example/wireguard-config/master/templates/bird.conf"
        "https://raw.githubusercontent.com/example/wireguard-config/master/templates/wireguard.conf"
        "https://raw.githubusercontent.com/example/wireguard-config/master/scripts/client-installer.sh"
    )
    
    for file_url in "${files[@]}"; do
        local filename=$(basename "$file_url")
        show_info "下载: $filename"
        
        if curl -s -o "${SCRIPTS_DIR}/$filename" "$file_url"; then
            show_success "下载成功: $filename"
        else
            show_error "下载失败: $filename"
        fi
    done
    
    show_success "文件下载完成!"
    read -p "按回车键继续..."
}

# 显示服务状态
show_service_status() {
    show_info "检查服务状态..."
    
    local services=("wireguard" "bird" "bird6" "nginx" "apache2")
    
    for service in "${services[@]}"; do
        if is_service_running "$service"; then
            show_success "$service: 运行中"
        else
            show_warning "$service: 未运行"
        fi
    done
    
    read -p "按回车键继续..."
}

# 启动服务
start_services() {
    if show_confirm "确认启动所有服务"; then
        show_loading "正在启动服务..." 2
        
        local services=("wireguard" "bird" "bird6")
        
        for service in "${services[@]}"; do
            if start_service "$service"; then
                show_success "服务启动成功: $service"
            else
                show_error "服务启动失败: $service"
            fi
        done
    fi
    
    read -p "按回车键继续..."
}

# 停止服务
stop_services() {
    if show_confirm "确认停止所有服务"; then
        show_loading "正在停止服务..." 2
        
        local services=("wireguard" "bird" "bird6")
        
        for service in "${services[@]}"; do
            if stop_service "$service"; then
                show_success "服务停止成功: $service"
            else
                show_error "服务停止失败: $service"
            fi
        done
    fi
    
    read -p "按回车键继续..."
}

# 重启服务
restart_services() {
    if show_confirm "确认重启所有服务"; then
        show_loading "正在重启服务..." 2
        
        local services=("wireguard" "bird" "bird6")
        
        for service in "${services[@]}"; do
            if restart_service "$service"; then
                show_success "服务重启成功: $service"
            else
                show_error "服务重启失败: $service"
            fi
        done
    fi
    
    read -p "按回车键继续..."
}

# 重载配置
reload_configurations() {
    if show_confirm "确认重载所有配置"; then
        show_loading "正在重载配置..." 2
        
        # 重载WireGuard配置
        if command -v wg &> /dev/null; then
            wg-quick down wg0 2>/dev/null || true
            wg-quick up wg0 2>/dev/null || true
            show_success "WireGuard配置已重载"
        fi
        
        # 重载BIRD配置
        if is_service_running "bird"; then
            birdc configure 2>/dev/null || true
            show_success "BIRD配置已重载"
        fi
        
        show_success "配置重载完成!"
    fi
    
    read -p "按回车键继续..."
}

# 显示服务日志
show_service_logs() {
    local services=("wireguard" "bird" "bird6" "nginx" "apache2")
    local selected_service=$(show_selection "选择服务" "${services[@]}")
    
    if [[ -n "$selected_service" ]]; then
        show_info "显示 $selected_service 日志:"
        echo "----------------------------------------"
        
        case "$selected_service" in
            "wireguard")
                journalctl -u wg-quick@wg0 -n 50 --no-pager
                ;;
            "bird"|"bird6")
                journalctl -u "$selected_service" -n 50 --no-pager
                ;;
            "nginx"|"apache2")
                tail -n 50 "/var/log/$selected_service/error.log" 2>/dev/null || echo "日志文件不存在"
                ;;
        esac
    fi
    
    read -p "按回车键继续..."
}

# 显示系统资源
show_system_resources() {
    show_info "系统资源使用情况:"
    echo "----------------------------------------"
    echo "CPU使用率: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
    echo "内存使用率: $(get_memory_usage)%"
    echo "磁盘使用率: $(get_disk_usage)%"
    echo "系统负载: $(get_system_load)"
    echo "运行时间: $(uptime -p)"
    echo "----------------------------------------"
    
    read -p "按回车键继续..."
}

# 显示网络连接
show_network_connections() {
    show_info "网络连接状态:"
    echo "----------------------------------------"
    netstat -tuln | head -20
    echo "----------------------------------------"
    
    read -p "按回车键继续..."
}

# 运行BIRD诊断
run_bird_diagnostics() {
    show_loading "正在运行BIRD诊断..." 2
    
    if command -v birdc &> /dev/null; then
        show_info "BIRD状态:"
        birdc show status 2>/dev/null || show_error "无法获取BIRD状态"
        
        echo
        show_info "BGP邻居:"
        birdc show protocols 2>/dev/null || show_error "无法获取BGP邻居信息"
        
        echo
        show_info "路由表:"
        birdc show route 2>/dev/null || show_error "无法获取路由表"
    else
        show_error "BIRD客户端未安装"
    fi
    
    read -p "按回车键继续..."
}

# 运行WireGuard诊断
run_wireguard_diagnostics() {
    show_loading "正在运行WireGuard诊断..." 2
    
    if command -v wg &> /dev/null; then
        show_info "WireGuard接口:"
        wg show 2>/dev/null || show_error "无法获取WireGuard接口信息"
        
        echo
        show_info "WireGuard统计:"
        wg show wg0 transfer 2>/dev/null || show_error "无法获取WireGuard统计"
    else
        show_error "WireGuard工具未安装"
    fi
    
    read -p "按回车键继续..."
}

# 导出函数
export -f show_main_menu server_management_menu client_management_menu
export -f client_auto_install_menu web_interface_menu client_monitoring_menu
export -f batch_management_menu network_config_menu bgp_config_menu
export -f firewall_management_menu system_maintenance_menu backup_restore_menu
export -f update_check_menu security_enhancements_menu user_interface_menu
export -f monitoring_alerting_menu handle_main_menu_selection handle_server_menu_selection
export -f handle_client_menu_selection handle_network_menu_selection
export -f handle_firewall_menu_selection handle_system_menu_selection
export -f quick_install interactive_install get_user_config download_required_files
export -f show_service_status start_services stop_services restart_services
export -f reload_configurations show_service_logs show_system_resources
export -f show_network_connections run_bird_diagnostics run_wireguard_diagnostics
