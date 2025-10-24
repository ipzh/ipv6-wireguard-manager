#!/bin/bash

# IPv6 WireGuard Manager 智能检查工具
# 能够区分系统未安装、部分安装、完全安装等状态

echo "🔍 IPv6 WireGuard Manager 智能检查工具"
echo "======================================"
echo "检查时间: $(date)"
echo "系统平台: $(uname -a)"
echo "======================================"
echo

# 检查计数器
ISSUES=0
WARNINGS=0
SUCCESSES=0
NOT_INSTALLED=0

# 状态标志
INSTALLATION_STATUS="unknown"
PROJECT_DIR=""

# 日志函数
log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[SUCCESS] ✓ $1"
    SUCCESSES=$((SUCCESSES + 1))
}

log_warning() {
    echo "[WARNING] ⚠️ $1"
    WARNINGS=$((WARNINGS + 1))
}

log_error() {
    echo "[ERROR] ✗ $1"
    ISSUES=$((ISSUES + 1))
}

log_not_installed() {
    echo "[NOT_INSTALLED] ⚪ $1"
    NOT_INSTALLED=$((NOT_INSTALLED + 1))
}

# 检测项目安装状态
detect_installation_status() {
    echo "=== 检测安装状态 ==="
    
    # 检查常见的安装目录
    POSSIBLE_DIRS=(
        "/opt/ipv6-wireguard-manager"
        "/usr/local/ipv6-wireguard-manager"
        "/home/*/ipv6-wireguard-manager"
        "./ipv6-wireguard-manager"
        "."
    )
    
    for dir_pattern in "${POSSIBLE_DIRS[@]}"; do
        for dir in $dir_pattern; do
            if [ -d "$dir" ] && [ -f "$dir/backend/init_database.py" ]; then
                PROJECT_DIR="$dir"
                INSTALLATION_STATUS="installed"
                log_success "找到项目目录: $dir"
                break 2
            fi
        done
    done
    
    if [ "$INSTALLATION_STATUS" != "installed" ]; then
        INSTALLATION_STATUS="not_installed"
        log_not_installed "项目未安装或不在标准目录"
        return
    fi
    
    # 检查关键文件
    if [ -f "$PROJECT_DIR/.env" ]; then
        log_success "环境配置文件存在"
    else
        log_warning "环境配置文件不存在"
    fi
    
    if [ -f "$PROJECT_DIR/env.local" ]; then
        log_success "本地配置文件存在"
    else
        log_warning "本地配置文件不存在"
    fi
    
    if [ -d "$PROJECT_DIR/logs" ]; then
        log_success "日志目录存在"
    else
        log_warning "日志目录不存在"
    fi
}

# 检查服务状态
check_services() {
    echo "=== 检查服务状态 ==="
    
    if [ "$INSTALLATION_STATUS" = "not_installed" ]; then
        log_not_installed "跳过服务检查（项目未安装）"
        return
    fi
    
    # 检查Python进程
    if pgrep -f "python.*ipv6-wireguard-manager" >/dev/null; then
        PYTHON_COUNT=$(pgrep -f "python.*ipv6-wireguard-manager" | wc -l)
        log_success "IPv6 WireGuard Manager Python进程运行正常 ($PYTHON_COUNT个)"
    elif pgrep -f python >/dev/null; then
        log_warning "有Python进程运行，但可能不是IPv6 WireGuard Manager"
    else
        log_error "Python进程未运行"
    fi
    
    # 检查MySQL进程
    if pgrep -f mysql >/dev/null; then
        MYSQL_COUNT=$(pgrep -f mysql | wc -l)
        log_success "MySQL进程运行正常 ($MYSQL_COUNT个)"
    else
        log_error "MySQL进程未运行"
    fi
    
    # 检查Nginx进程
    if pgrep -f nginx >/dev/null; then
        NGINX_COUNT=$(pgrep -f nginx | wc -l)
        log_success "Nginx进程运行正常 ($NGINX_COUNT个)"
    else
        log_warning "Nginx进程未运行"
    fi
}

# 检查端口监听
check_ports() {
    echo "=== 检查端口监听 ==="
    
    if [ "$INSTALLATION_STATUS" = "not_installed" ]; then
        log_not_installed "跳过端口检查（项目未安装）"
        return
    fi
    
    # 检查端口80
    if netstat -tuln 2>/dev/null | grep -q ":80 "; then
        log_success "端口80正在监听"
    else
        log_warning "端口80未监听"
    fi
    
    # 检查端口8000
    if netstat -tuln 2>/dev/null | grep -q ":8000 "; then
        log_success "端口8000正在监听"
    else
        log_error "端口8000未监听"
    fi
    
    # 检查端口3306
    if netstat -tuln 2>/dev/null | grep -q ":3306 "; then
        log_success "端口3306正在监听"
    else
        log_error "端口3306未监听"
    fi
}

# 检查环境变量
check_environment() {
    echo "=== 检查环境变量 ==="
    
    if [ "$INSTALLATION_STATUS" = "not_installed" ]; then
        log_not_installed "跳过环境变量检查（项目未安装）"
        return
    fi
    
    if [ -n "$DATABASE_URL" ]; then
        log_success "DATABASE_URL环境变量已设置"
    else
        log_error "DATABASE_URL环境变量未设置"
    fi
    
    if [ -n "$SERVER_HOST" ]; then
        log_success "SERVER_HOST环境变量已设置"
    else
        log_warning "SERVER_HOST环境变量未设置"
    fi
    
    if [ -n "$SERVER_PORT" ]; then
        log_success "SERVER_PORT环境变量已设置"
    else
        log_warning "SERVER_PORT环境变量未设置"
    fi
}

# 检查网络连接
check_network() {
    echo "=== 检查网络连接 ==="
    
    if [ "$INSTALLATION_STATUS" = "not_installed" ]; then
        log_not_installed "跳过网络检查（项目未安装）"
        return
    fi
    
    # 检查Web服务
    if curl -s --connect-timeout 5 http://localhost/ >/dev/null 2>&1; then
        log_success "Web服务可访问"
    else
        log_error "Web服务不可访问"
    fi
    
    # 检查API服务
    if curl -s --connect-timeout 5 http://localhost:8000/ >/dev/null 2>&1; then
        log_success "API服务可访问"
    else
        log_error "API服务不可访问"
    fi
}

# 检查系统资源
check_system_resources() {
    echo "=== 检查系统资源 ==="
    
    # 内存检查
    MEMORY_TOTAL=$(free -m | awk 'NR==2{print $2}')
    MEMORY_USED=$(free -m | awk 'NR==2{print $3}')
    MEMORY_PERCENT=$((MEMORY_USED * 100 / MEMORY_TOTAL))
    
    echo "[INFO] 内存使用情况:"
    free -h
    
    if [ $MEMORY_PERCENT -gt 90 ]; then
        log_error "内存使用率过高: ${MEMORY_PERCENT}%"
    elif [ $MEMORY_PERCENT -gt 80 ]; then
        log_warning "内存使用率较高: ${MEMORY_PERCENT}%"
    else
        log_success "内存使用率正常: ${MEMORY_PERCENT}%"
    fi
    
    # 磁盘检查
    echo
    echo "[INFO] 磁盘使用情况:"
    df -h
    
    # CPU负载
    echo
    echo "[INFO] CPU负载:"
    uptime
}

# 生成安装建议
generate_installation_advice() {
    echo
    echo "======================================"
    echo "🔧 安装和修复建议"
    echo "======================================"
    
    if [ "$INSTALLATION_STATUS" = "not_installed" ]; then
        echo "📦 系统未安装IPv6 WireGuard Manager"
        echo
        echo "安装步骤："
        echo "1. 克隆项目仓库："
        echo "   git clone https://github.com/ipzh/ipv6-wireguard-manager.git"
        echo "   cd ipv6-wireguard-manager"
        echo
        echo "2. 运行安装脚本："
        echo "   chmod +x install.sh"
        echo "   sudo ./install.sh"
        echo
        echo "3. 或者使用一键安装："
        echo "   curl -s https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | sudo bash"
        echo
        echo "4. 安装完成后重新运行检查工具"
        return
    fi
    
    # 已安装但有问题的情况
    if [ $ISSUES -gt 0 ]; then
        echo "🚨 发现以下问题需要修复:"
        
        if [ $ISSUES -gt 0 ]; then
            echo "  - 检查服务是否正在运行"
            echo "  - 验证配置文件是否存在"
            echo "  - 确认环境变量已设置"
            echo "  - 检查端口监听状态"
            echo "  - 验证网络连接"
        fi
        
        echo
        echo "修复步骤："
        echo "1. 启动MySQL服务："
        echo "   sudo systemctl start mysql"
        echo "   sudo systemctl enable mysql"
        echo
        echo "2. 启动IPv6 WireGuard Manager服务："
        echo "   sudo systemctl start ipv6-wireguard-manager"
        echo "   sudo systemctl enable ipv6-wireguard-manager"
        echo
        echo "3. 检查服务状态："
        echo "   sudo systemctl status ipv6-wireguard-manager"
        echo
        echo "4. 查看日志："
        echo "   sudo journalctl -u ipv6-wireguard-manager -f"
    fi
    
    if [ $WARNINGS -gt 0 ]; then
        echo
        echo "⚠️ 发现以下警告:"
        echo "  - 建议检查Nginx服务状态"
        echo "  - 建议设置SERVER_HOST环境变量"
        echo "  - 建议创建env.local配置文件"
    fi
}

# 主检查流程
main() {
    # 检测安装状态
    detect_installation_status
    
    # 根据安装状态执行不同的检查
    if [ "$INSTALLATION_STATUS" = "installed" ]; then
        check_services
        check_ports
        check_environment
        check_network
    fi
    
    # 系统资源检查（总是执行）
    check_system_resources
    
    # 生成总结
    echo
    echo "======================================"
    echo "📊 检查总结"
    echo "======================================"
    echo "✅ 成功项目: $SUCCESSES"
    echo "⚠️ 警告项目: $WARNINGS"
    echo "❌ 问题项目: $ISSUES"
    echo "⚪ 未安装项目: $NOT_INSTALLED"
    echo "======================================"
    
    # 生成建议
    generate_installation_advice
    
    echo
    echo "[INFO] 智能检查完成！"
    
    # 返回退出码
    if [ "$INSTALLATION_STATUS" = "not_installed" ]; then
        exit 3  # 未安装
    elif [ $ISSUES -gt 0 ]; then
        exit 1  # 有问题
    elif [ $WARNINGS -gt 0 ]; then
        exit 2  # 有警告
    else
        exit 0  # 一切正常
    fi
}

# 运行主函数
main "$@"
