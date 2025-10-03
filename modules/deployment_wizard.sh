#!/bin/bash

# 部署向导模块
# 提供交互式的部署配置和自动化部署功能

# 部署配置
declare -A DEPLOYMENT_CONFIG=(
    ["environment"]="production"  # production, staging, development
    ["docker_enabled"]="true"
    ["ssl_enabled"]="true"
    ["backup_enabled"]="true"
    ["monitoring_enabled"]="true"
)

# 部署进度跟踪
declare -A DEPLOYMENT_STATUS=(
    ["current_step"]=0
    ["total_steps"]=10
    ["errors"]=0
    ["warnings"]=0
)

# 主部署向导
start_deployment_wizard() {
    log_info "=== IPv6 WireGuard Manager 部署向导 ==="
    echo
    echo "欢迎使用IPv6 WireGuard Manager部署向导！"
    echo "此向导将帮助您完成整个系统的部署配置。"
    echo
    
    # 检查系统环境
    check_deployment_prerequisites
    
    # 收集部署配置
    collect_deployment_config
    
    # 验证配置
    validate_deployment_config
    
    # 执行部署
    execute_deployment
    
    # 部署后验证
    post_deployment_verification
    
    # 生成部署报告
    generate_deployment_report
    
    log_success "部署向导完成！"
}

# 检查部署先决条件
check_deployment_prerequisites() {
    log_info "=== 检查部署先决条件 ==="
    
    DEPLOYMENT_STATUS[current_step]=1
    
    # 检查系统版本
    detect_system_version
    
    # 检查必需的命令
    check_required_commands
    
    # 检查网络连接
    check_network_connectivity
    
    # 检查端口可用性
    check_port_availability
    
    log_success "先决条件检查完成"
}

# 检测系统版本
detect_system_version() {
    log_info "检测系统版本..."
    
    # 获取系统信息
    local os_info=$(uname -a)
    local kernel_version=$(uname -r)
    
    echo "操作系统信息:"
    echo "  - 系统架构: $(uname -m)"
    echo "  - 内核版本: $kernel_version"
    echo "  - 系统信息: $os_info"
    
    # 检查支持的发行版
    detect_linux_distribution
    
    DEPLOYMENT_CONFIG["detected_os"]="$(uname -s)"
    DEPLOYMENT_CONFIG["detected_distro"]="$detected_distro"
}

# 检测Linux发行版
detect_linux_distribution() {
    detected_distro="unknown"
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        detected_distro="$NAME $VERSION"
        log_info "检测到Linux发行版: $detected_distro"
        
        # 检查是否为支持的发行版
        case "$ID" in
            ubuntu|debian|centos|rhel|fedora|arch)
                log_success "✓ 支持的操作系统: $ID"
                ;;
            *)
                log_warn "⚠ 可能不支持的系统: $ID"
                ((DEPLOYMENT_STATUS[warnings]++))
                ;;
        esac
    else
        log_warn "无法检测Linux发行版"
        ((DEPLOYMENT_STATUS[warnings]++))
    fi
}

# 检查必需命令
check_required_commands() {
    log_info "检查必需命令..."
    
    local required_commands=("bash" "curl" "wget" "ip" "iptables" "systemctl")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            log_debug "✓ $cmd 可用"
        else
            missing_commands+=("$cmd")
            log_warn "✗ $cmd 缺失"
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "缺少必需的命令: ${missing_commands[*]}"
        show_command_installation_help "${missing_commands[@]}"
        ((DEPLOYMENT_STATUS[errors]++))
    else
        log_success "✓ 所有必需命令都可用"
    fi
}

# 显示命令安装帮助
show_command_installation_help() {
    local missing_commands=("$@")
    
    echo
    echo "缺失命令安装指南:"
    echo "========================"
    
    for cmd in "${missing_commands[@]}"; do
        case "$cmd" in
            "curl")
                echo "curl: install curl"
                ;;
            "wget")
                echo "wget: install wget"
                ;;
            "iptables")
                echo "iptables: install iptables"
                ;;
            "systemctl")
                echo "systemctl: 确保使用systemd系统"
                ;;
        esac
    done
    
    echo
}

# 检查网络连接
check_network_connectivity() {
    log_info "检查网络连接..."
    
    # 检查本地网络
    if ping -c 1 127.0.0.1 >/dev/null 2>&1; then
        log_success "✓ 本地回环网络正常"
    else
        log_error "✗ 本地回环网络异常"
        ((DEPLOYMENT_STATUS[errors]++))
    fi
    
    # 检查DNS解析
    if nslookup google.com >/dev/null 2>&1; then
        log_success "✓ DNS解析正常"
    else
        log_warn "⚠ DNS解析可能有问题"
        ((DEPLOYMENT_STATUS[warnings]++))
    fi
    
    # 检查外网连接
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_success "✓ 外网连接正常"
    else
        log_warn "⚠ 外网连接可能有问题"
        ((DEPLOYMENT_STATUS[warnings]++))
    fi
}

# 检查端口可用性
check_port_availability() {
    log_info "检查端口可用性..."
    
    local required_ports=(51820 8080 80 443)
    
    for port in "${required_ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep ":$port " >/dev/null; then
            log_warn "⚠ 端口 $port 已被占用"
            ((DEPLOYMENT_STATUS[warnings]++))
        else
            log_success "✓ 端口 $port 可用"
        fi
    done
}

# 收集部署配置
collect_deployment_config() {
    log_info "=== 收集部署配置 ==="
    DEPLOYMENT_STATUS[current_step]=2
    
    # 部署环境选择
    select_deployment_environment
    
    # WireGuard配置
    configure_wireguard_settings
    
    # Web管理配置
    configure_web_settings
    
    # 网络配置
    configure_network_settings
    
    # 安全配置
    configure_security_settings
    
    # 监控配置
    configure_monitoring_settings
    
    log_success "配置收集完成"
}

# 选择部署环境
select_deployment_environment  () {
    echo
    echo "=== 部署环境配置 ==="
    echo
    echo "选择部署环境类型："
    echo "1. 生产环境 (production) - 完整功能，高性能配置"
    echo "2. 测试环境 (staging) - 中等配置，用于测试"
    echo "3. 开发环境 (development) - 最小配置，开发调试"
    echo
    
    while true; do
        read -p "请选择环境类型 [1-3]: " env_choice
        
        case "$env_choice" in
            1)
                DEPLOYMENT_CONFIG["environment"]="production"
                DEPLOYMENT_CONFIG["performance_mode"]="high"
                DEPLOYMENT_CONFIG["debug_mode"]="false"
                echo "✓ 选择生产环境"
                break
                ;;
            2)
                DEPLOYMENT_CONFIG["environment"]="staging"
                DEPLOYMENT_CONFIG["performance_mode"]="medium"
                DEPLOYMENT_CONFIG["debug_mode"]="false"
                echo "✓ 选择测试环境"
                break
                ;;
            3)
                DEPLOYMENT_CONFIG["environment"]="development"
                DEPLOYMENT_CONFIG["performance_mode"]="low"
                DEPLOYMENT_CONFIG["debug_mode"]="true"
                echo "✓ 选择开发环境"
                break
                ;;
            *)
                echo "无效选择，请输入 1、2 或 3"
                ;;
        esac
    done
}

# 配置WireGuard设置
configure_wireguard_settings() {
    echo
    echo "=== WireGuard配置 ==="
    
    # IPv6前缀配置
    read -p "IPv6前缀 (例如: 2001:db8::/64) [自动生成]: " ipv6_prefix
    if [[ -z "$ipv6_prefix" ]]; then
        # 自动生成IPv6前缀
        ipv6_prefix="fd$(openssl rand -hex 3 | colrm 1 2)::/64"
        echo "✓ 自动生成IPv6前缀: $ipv6_prefix"
    fi
    DEPLOYMENT_CONFIG["ipv6_prefix"]="$ipv6_prefix"
    
    # WireGuard端口
    read -p "WireGuard监听端口 [51820]: " wireguard_port
    wireguard_port="${wireguard_port:-51820}"
    DEPLOYMENT_CONFIG["wireguard_port"]="$wireguard_port"
    
    echo "✓ WireGuard配置完成"
}

# 配置Web管理设置
configure_web_settings() {
    echo
    echo "=== Web管理接口配置 ==="
    
    # Web端口
    read -p "Web管理端口 [8080]: " web_port
    web_port="${web_port:-8080}"
    DEPLOYMENT_CONFIG["web_port"]="$web_port"
    
    # SSL配置
    if [[ "${DEPLOYMENT_CONFIG[environment]}" == "production" ]]; then
        echo "检测到生产环境，需要SSL配置"
        
        read -p "是否启用SSL/HTTPS? [y/N]: " ssl_choice
        if [[ "$ssl_choice" =~ ^[Yy]$ ]]; then
            DEPLOYMENT_CONFIG["ssl_enabled"]="true"
            
            read -p "SSL证书文件路径: " ssl_cert_path
            read -p "SSL私钥文件路径: " ssl_key_path
            
            DEPLOYMENT_CONFIG["ssl_cert_path"]="$ssl_cert_path"
            DEPLOYMENT_CONFIG["ssl_key_path"]="$ssl_key_path"
            
            echo "✓ SSL配置完成"
        else
            DEPLOYMENT_CONFIG["ssl_enabled"]="false"
            echo "✓ 跳过SSL配置"
        fi
    else
        DEPLOYMENT_CONFIG["ssl_enabled"]="false"
    fi
    
    echo "✓ Web接口配置完成"
}

# 配置网络安全设置
configure_network_settings() {
    echo
    echo "=== 网络配置 ==="
    
    # 防火墙配置
    read -p "是否配置防火墙规则? [Y/n]: " firewall_choice
    if [[ ! "$firewall_choice" =~ ^[Nn]$ ]]; then
        DEPLOYMENT_CONFIG["firewall_enabled"]="true"
        configure_firewall_settings
    else
        DEPLOYMENT_CONFIG["firewall_enabled"]="false"
    fi
    
    # BGP路由配置（可选）
    if [[ "${DEPLOYMENT_CONFIG[environment]}" == "production" ]]; then
        read -p "是否启用BGP路由? [y/N]: " bgp_choice
        if [[ "$bgp_choice" =~ ^[Yy]$ ]]; then
            DEPLOYMENT_CONFIG["bgp_enabled"]="true"
            configure_bgp_settings
        else
            DEPLOYMENT_CONFIG["bgp_enabled"]="false"
        fi
    else
        DEPLOYMENT_CONFIG["bgp_enabled"]="false"
    fi
    
    echo "✓ 网络配置完成"
}

# 配置防火墙设置
configure_firewall_settings() {
    # 检测可用的防火墙工具
    local firewall_tool="none"
    
    if command -v ufw >/dev/null 2>&1; then
        firewall_tool="ufw"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall_tool="firewalld"
    elif command -v iptables >/dev/null 2>&1; then
        firewall_tool="iptables"
    fi
    
    DEPLOYMENT_CONFIG["firewall_tool"]="$firewall_tool"
    
    if [[ "$firewall_tool" != "none" ]]; then
        echo "✓ 检测到防火墙工具: $firewall_tool"
    else
        echo "⚠ 未检测到防火墙工具"
        ((DEPLOYMENT_STATUS[warnings]++))
    fi
}

# 配置BGP设置
configure_bgp_settings() {
    read -p "BGP AS号: " bgp_as
    read -p "BGP路由器ID: " bgp_router_id
    
    DEPLOYMENT_CONFIG[BGP_AS_NUMBER]="$bgp_as"
    DEPLOYMENT_CONFIG[BGP_ROUTER_ID]="$bgp_router_id"
    
    echo "✓ BGP配置完成"
}

# 配置安全设置
configure_security_settings() {
    echo
    echo "=== 安全配置 ==="
    
    # API设置
    read -p "启用API访问? [Y/n]: " api_choice
    if [[ ! "$api_choice" =~ ^[Nn]$ ]]; then
        DEPLOYMENT_CONFIG["api_enabled"]="true"
        
        # API认证
        read -p "API密钥 (自动生成): " api_key
        if [[ -z "$api_key" ]]; then
            api_key=$(openssl rand -base64 32 | tr -d "=+/")
            echo "✓ 自动生成API密钥"
        fi
        DEPLOYMENT_CONFIG["api_key"]="$api_key"
    else
        DEPLOYMENT_CONFIG["api_enabled"]="false"
    fi
    
    # 访问控制
    read -p "允许的IP范围 (示例: 192.168.1.0/24), 空=无限制: " allowed_ips
    DEPLOYMENT_CONFIG["allowed_ips"]="$allowed_ips"
    
    echo "✓ 安全配置完成"
}

# 配置监控设置
configure_monitoring_settings() {
    echo
    echo "=== 监控配置 ==="
    
    if [[ "${DEPLOYMENT_CONFIG[environment]}" != "development" ]]; then
        read -p "启用监控告警? [Y/n]: " monitoring_choice
        if [[ ! "$monitoring_choice" =~ ^[Nn]$ ]]; then
            DEPLOYMENT_CONFIG["monitoring_enabled"]="true"
            
            # 告警配置
            read -p "告警邮箱 (可选): " alert_email
            DEPLOYMENT_CONFIG["alert_email"]="$alert_email"
            
            echo "✓ 监控配置完成"
        else
            DEPLOYMENT_CONFIG["monitoring_enabled"]="false"
        fi
    else
        DEPLOYMENT_CONFIG["monitoring_enabled"]="false"
    fi
}

# 验证部署配置
validate_deployment_config() {
    log_info "=== 验证部署配置 ==="
    DEPLOYMENT_STATUS[current_step]=3
    
    local validation_passed=true
    
    # 验证IPv6前缀
    if [[ ! "${DEPLOYMENT_CONFIG[ipv6_prefix]}" =~ ^[0-9a-f:]+/[0-9]+$ ]]; then
        log_error "无效的IPv6 prefix格式"
        validation_passed=false
    fi
    
    # 验证端口范围
    if [[ "${DEPLOYMENT_CONFIG[wireguard_port]}" -lt 1024 || "${DEPLOYMENT_CONFIG[wireguard_port]}" -gt 65535 ]]; then
        log_error "WireGuard端口号必须在1024-65535范围内"
        validation_passed=false
    fi
    
    # 验证SSL配置
    if [[ "${DEPLOYMENT_CONFIG[ssl_enabled]}" == "true" ]]; then
        if [[ ! -f "${DEPLOYMENT_CONFIG[ssl_cert_path]}" ]]; then
            log_error "SSL证书文件不存在: ${DEPLOYMENT_CONFIG[ssl_cert_path]}"
            validation_passed=false
        fi
        if [[ ! -f "${DEPLOYMENT_CONFIG[ssl_key_path]}" ]]; then
            log_error "SSL私钥文件不存在: ${DEPLOYMENT_CONFIG[ssl_key_path]}"
            validation_passed=false
        fi
    fi
    
    if [[ "$validation_passed" == "true" ]]; then
        log_success "配置验证通过"
        return 0
    else
        log_error "配置验证失败"
        ((DEPLOYMENT_STATUS[errors]++))
        return 1
    fi
}

# 执行部署
execute_deployment() {
    log_info "=== 执行部署 ==="
    
    echo "是否开始安装部署? [Y/n]: "
    read -p "按回车继续，或输入 'n' 取消: " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        log_info "部署已取消"
        exit 0
    fi
    
    log_info "开始自动部署..."
    
    # 部署步骤
    install_dependencies
    configure_system
    setup_wireguard
    setup_web_interface
    configure_monitoring
    setup_cron_jobs
    
    log_success "部署执行完成"
}

# 安装依赖
install_dependencies() {
    log_info "安装系统依赖..."
    
    # 更新包管理器
    if command -v apt >/dev/null 2>&1; then
        apt update
        apt install -y wireguard curl wget iptables nginx
    elif command -v yum >/dev/null 2>&1; then
        yum update -y
        yum install -y wireguard-tools curl wget iptables nginx
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Syu
        pacman -S wireguard-tools curl wget iptables nginx
    fi
    
    log_success "依赖安装完成"
}

# 配置系统
configure_system() {
    log_info "配置系统设置..."
    
    # 启用IP转发
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.forwarding = 1" >> /etc/sysctl.conf
    sysctl -p
    
    # 创建必要的目录
    mkdir -p /etc/wireguard
    mkdir -p /var/log/ipv6-wireguard-manager
    mkdir -p /var/lib/ipv6-wireguard-manager
    
    log_success "系统配置完成"
}

# 设置WireGuard
setup_wireguard() {
    log_info "配置WireGuard..."
    
    # 生成密钥
    local private_key=$(wg genkey)
    local public_key=$(echo "$private_key" | wg pubkey)
    
    # 创建基础配置
    cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $private_key
Address = ${DEPLOYMENT_CONFIG[ipv6_prefix]//\/64/\/128}
ListenPort = ${DEPLOYMENT_CONFIG[wireguard_port]}
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF
    
    log_success "WireGuard配置完成"
}

# 设置Web界面
setup_web_interface() {
    log_info "配置Web管理界面..."
    
    # 创建Nginx配置
    cat > /etc/nginx/sites-available/ipv6-wireguard-manager << EOF
server {
    listen ${DEPLOYMENT_CONFIG[web_port]};
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # 启用站点
    ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
    
    # 启动服务
    systemctl enable nginx
    systemctl start nginx
    
    log_success "Web界面配置完成"
}

# 配置监控
configure_monitoring() {
    if [[ "${DEPLOYMENT_CONFIG[monitoring_enabled]}" == "true" ]]; then
        log_info "配置监控告警..."
        
        # 创建监控脚本
        setup_monitoring_scripts
        
        log_success "监控配置完成"
    fi
}

# 设置监控脚本
setup_monitoring_scripts() {
    cat > /usr/local/bin/wg-monitor.sh << 'EOF'
#!/bin/bash
# WireGuard监控脚本

SOURCE_DIR="/opt/ipv6-wireguard-manager"
source "$SOURCE_DIR/modules/common_functions.sh"

# 检查WireGuard状态
check_wireguard_status() {
    if ! systemctl is-active --quiet wg-quick@wg0; then
        log_error "WireGuard服务未运行"
        return 1
    fi
    return 0
}

# 检查连接数
check_client_connections() {
    local peer_count=$(wg show wg0 peers | wc -l)
    if [[ $peer_count -gt 100 ]]; then
        log_warn "客户端连接数过多: $peer_count"
    fi
}

# 主要监控逻辑
main() {
    check_wireguard_status || exit 1
    check_client_connections
}

main
EOF

    chmod +x /usr/local/bin/wg-monitor.sh
    
    # 设置cron任务
    echo "*/5 * * * * /usr/local/bin/wg-monitor.sh" >> /var/spool/cron/root
}

# 设置定时任务
setup_cron_jobs() {
    log_info "设置定时任务..."
    
    # 创建备份脚本
    cat > /usr/local/bin/wg-backup.sh << 'EOF'
#!/bin/bash
# WireGuard配置备份脚本

BACKUP_DIR="/var/backups/wireguard"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# 备份WireGuard配置
cp /etc/wireguard/wg0.conf "$BACKUP_DIR/wg0_$DATE.conf"

# 清理旧备份（保留30天）
find "$BACKUP_DIR" -name "wg0_*.conf" -mtime +30 -delete

echo "WireGuard配置已备份: $DATE"
EOF

    chmod +x /usr/local/bin/wg-backup.sh
    
    # 每天2点自动备份
    echo "0 2 * * * /usr/local/bin/wg-backup.sh" >> /var/spool/cron/root
    
    log_success "定时任务设置完成"
}

# 部署后验证
post_deployment_verification() {
    log_info "=== 部署后验证 ==="
    
    # 检查服务状态
    verify_service_status
    
    # 检查端口监听
    verify_port_listening
    
    # 检查配置文件
    verify_configuration_files
    
    log_success "部署验证完成"
}

# 验证服务状态
verify_service_status() {
    if systemctl is-active --quiet wg-quick@wg0; then
        log_success "✓ WireGuard服务运行正常"
    else
        log_error "✗ WireGuard服务异常"
        ((DEPLOYMENT_STATUS[errors]++))
    fi
    
    if systemctl is-active --quiet nginx; then
        log_success "✓ Nginx服务运行正常"
    else
        log_error "✗ Nginx服务异常"
        ((DEPLOYMENT_STATUS[errors]++))
    fi
}

# 验证端口监听
verify_port_listening() {
    if netstat -tuln | grep ":${DEPLOYMENT_CONFIG[wireguard_port]} " >/dev/null; then
        log_success "✓ WireGuard端口监听正常"
    else
        log_error "✗ WireGuard端口未监听"
        ((DEPLOYMENT_STATUS[errors]++))
    fi
    
    if netstat -tuln | grep ":${DEPLOYMENT_CONFIG[web_port]} " >/dev/null; then
        log_success "✓ Web端口监听正常"
    else
        log_error "✗ Web端口未监听"
        ((DEPLOYMENT_STATUS[errors]++))
    fi
}

# 验证配置文件
verify_configuration_files() {
    local config_files=(
        "/etc/wireguard/wg0.conf"
        "/etc/nginx/sites-enabled/ipv6-wireguard-manager"
    )
    
    for file in "${config_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "✓ 配置文件存在: $file"
        else
            log_error "✗ 配置文件缺失: $file"
            ((DEPLOYMENT_STATUS[errors]++))
        fi
    done
}

# 生成部署报告
generate_deployment_report() {
    log_info "生成部署报告..."
    
    local report_file="${IPV6WGM_LOG_DIR}/deployment_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=== IPv6 WireGuard Manager 部署报告 ==="
        echo "部署时间: $(date)"
        echo "执行环境: ${DEPLOYMENT_CONFIG[environment]}"
        echo "检测系统: ${DEPLOYMENT_CONFIG[detected_distro]}"
        echo ""
        
        echo "=== 部署配置 ==="
        for key in "${!DEPLOYMENT_CONFIG[@]}"; do
            echo "$key: ${DEPLOYMENT_CONFIG[$key]}"
        done
        echo ""
        
        echo "=== 部署状态 ==="
        echo "错误数量: ${DEPLOYMENT_STATUS[errors]}"
        echo "警告数量: ${DEPLOYMENT_STATUS[warnings]}"
        echo ""
        
        echo "=== 访问信息 ==="
        echo "Web管理界面: http://$(hostname -I | awk '{print $1}'):${DEPLOYMENT_CONFIG[web_port]}"
        echo "WireGuard端口: ${DEPLOYMENT_CONFIG[wireguard_port]}"
        echo "IPv6前缀: ${DEPLOYMENT_CONFIG[ipv6_prefix]}"
        echo ""
        
        echo "=== 后续步骤 ==="
        echo "1. 通过Web界面添加客户端"
        echo "2. 配置客户端连接"
        echo "3. 测试网络连接"
        echo "4. 设置监控告警"
        
    } > "$report_file"
    
    log_success "部署报告已生成: $report_file"
    
    # 显示重要信息
    echo
    echo "🎉 部署完成！重要信息："
    echo "=========================="
    echo "Web管理地址: http://$(hostname -I | awk '{print $1}'):${DEPLOYMENT_CONFIG[web_port]}"
    echo "配置文件: /etc/wireguard/wg0.conf"
    echo "日志目录: /var/log/ipv6-wireguard-manager"
    echo "部署报告: $report_file"
    echo
}

# 导出函数
export -f start_deployment_wizard detect_system_version check_deployment_prerequisites
export -f collect_deployment_config validate_deployment_config execute_deployment
export -f generate_deployment_report

# 别名
alias deploy_wizard=start_deployment_wizard
alias auto_deploy=start_deployment_wizard
