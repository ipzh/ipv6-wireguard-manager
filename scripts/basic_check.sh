#!/bin/bash

# IPv6 WireGuard Manager 基础检查工具 (无需Python包)
# 适用于externally-managed-environment环境

echo "🔍 IPv6 WireGuard Manager 基础检查工具"
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
}

# 检测安装状态
detect_installation_status

# 1. 检查Python进程
echo "=== 1. 检查Python进程 ==="
if pgrep -f "python.*ipv6-wireguard-manager" >/dev/null; then
    PYTHON_COUNT=$(pgrep -f "python.*ipv6-wireguard-manager" | wc -l)
    log_success "IPv6 WireGuard Manager Python进程运行正常 ($PYTHON_COUNT个)"
elif pgrep -f python >/dev/null; then
    log_warning "有Python进程运行，但可能不是IPv6 WireGuard Manager"
else
    log_error "Python进程未运行"
fi

# 2. 检查MySQL进程
echo "=== 2. 检查MySQL进程 ==="
if pgrep -f mysql >/dev/null; then
    MYSQL_COUNT=$(pgrep -f mysql | wc -l)
    log_success "MySQL进程运行正常 ($MYSQL_COUNT个)"
else
    log_error "MySQL进程未运行"
fi

# 3. 检查Nginx进程
echo "=== 3. 检查Nginx进程 ==="
if pgrep -f nginx >/dev/null; then
    NGINX_COUNT=$(pgrep -f nginx | wc -l)
    log_success "Nginx进程运行正常 ($NGINX_COUNT个)"
else
    log_warning "Nginx进程未运行"
fi

# 4. 检查端口监听
echo "=== 4. 检查端口监听 ==="
if netstat -tuln 2>/dev/null | grep -q ":80 "; then
    log_success "端口80正在监听"
else
    log_warning "端口80未监听"
fi

if netstat -tuln 2>/dev/null | grep -q ":8000 "; then
    log_success "端口8000正在监听"
else
    log_error "端口8000未监听"
fi

if netstat -tuln 2>/dev/null | grep -q ":3306 "; then
    log_success "端口3306正在监听"
else
    log_error "端口3306未监听"
fi

# 5. 检查配置文件
echo "=== 5. 检查配置文件 ==="
if [ -f ".env" ]; then
    log_success ".env配置文件存在"
else
    log_error ".env配置文件不存在"
fi

if [ -f "env.local" ]; then
    log_success "env.local配置文件存在"
else
    log_warning "env.local配置文件不存在"
fi

if [ -f "backend/init_database.py" ]; then
    log_success "数据库初始化脚本存在"
else
    log_error "数据库初始化脚本不存在"
fi

# 6. 检查日志目录
echo "=== 6. 检查日志目录 ==="
if [ -d "logs" ]; then
    log_success "日志目录存在"
    
    # 检查日志文件
    if ls logs/*.log >/dev/null 2>&1; then
        LOG_COUNT=$(ls logs/*.log 2>/dev/null | wc -l)
        log_success "找到日志文件 ($LOG_COUNT个)"
    else
        log_warning "未找到日志文件"
    fi
else
    log_error "日志目录不存在"
fi

# 7. 检查环境变量
echo "=== 7. 检查环境变量 ==="
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

# 8. 检查系统资源
echo "=== 8. 检查系统资源 ==="
echo "[INFO] 内存使用情况:"
free -h

echo
echo "[INFO] 磁盘使用情况:"
df -h

echo
echo "[INFO] CPU负载:"
uptime

# 9. 检查网络连接
echo "=== 9. 检查网络连接 ==="
if curl -s --connect-timeout 5 http://localhost/ >/dev/null 2>&1; then
    log_success "Web服务可访问"
else
    log_error "Web服务不可访问"
fi

if curl -s --connect-timeout 5 http://localhost:8000/ >/dev/null 2>&1; then
    log_success "API服务可访问"
else
    log_error "API服务不可访问"
fi

# 10. 生成总结
echo
echo "======================================"
echo "📊 检查总结"
echo "======================================"
echo "✅ 成功项目: $SUCCESSES"
echo "⚠️ 警告项目: $WARNINGS"
echo "❌ 问题项目: $ISSUES"
echo "⚪ 未安装项目: $NOT_INSTALLED"
echo "======================================"

# 生成修复建议
echo
echo "======================================"
echo "🔧 修复建议"
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
elif [ $ISSUES -gt 0 ]; then
    echo "🚨 发现以下问题需要修复:"
    echo "  - 检查服务是否正在运行"
    echo "  - 验证配置文件是否存在"
    echo "  - 确认环境变量已设置"
    echo "  - 检查端口监听状态"
    echo "  - 验证网络连接"
    
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

if [ "$INSTALLATION_STATUS" = "installed" ]; then
    if [ $ISSUES -eq 0 ]; then
        if [ $WARNINGS -eq 0 ]; then
            echo "✅ 所有检查通过，系统运行正常！"
        else
            echo "⚠️ 系统基本正常，但有一些警告建议处理"
        fi
    else
        echo "❌ 发现严重问题，需要修复！"
    fi
fi

echo
echo "[INFO] 基础检查完成！"

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
