#!/bin/bash

# IPv6 WireGuard Manager - Debian 12 API服务修复脚本
# 专门解决Debian 12上的API服务启动问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 配置
INSTALL_DIR="/opt/ipv6-wireguard-manager"
SERVICE_NAME="ipv6-wireguard-manager"
SERVICE_USER="ipv6wgm"
SERVICE_GROUP="ipv6wgm"

log_info "IPv6 WireGuard Manager - Debian 12 API服务修复"
echo ""

# 检查系统版本
check_system() {
    log_info "检查系统版本..."
    if [[ -f /etc/debian_version ]]; then
        local debian_version=$(cat /etc/debian_version)
        log_info "Debian版本: $debian_version"
        if [[ "$debian_version" == "12"* ]]; then
            log_success "✓ 确认是Debian 12系统"
        else
            log_warning "⚠ 不是Debian 12系统，但继续执行修复"
        fi
    else
        log_warning "⚠ 无法确定Debian版本"
    fi
    echo ""
}

# 停止服务
stop_service() {
    log_info "停止服务..."
    systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    sleep 3
    log_success "✓ 服务已停止"
}

# 检查服务日志
check_logs() {
    log_info "检查服务日志..."
    echo "=== 最近的服务日志 ==="
    journalctl -u "$SERVICE_NAME" --no-pager -n 10
    echo ""
}

# 修复Debian 12特定问题
fix_debian12_issues() {
    log_info "修复Debian 12特定问题..."
    
    # 1. 检查并修复Python版本问题
    log_info "检查Python版本..."
    if command -v python3.11 &>/dev/null; then
        log_success "✓ Python 3.11可用"
    else
        log_warning "⚠ Python 3.11不可用，尝试安装..."
        apt-get update
        apt-get install -y python3.11 python3.11-venv python3.11-dev
    fi
    
    # 2. 检查并修复MariaDB问题
    log_info "检查MariaDB状态..."
    if systemctl is-active --quiet mariadb; then
        log_success "✓ MariaDB服务运行中"
    else
        log_warning "⚠ MariaDB服务未运行，尝试启动..."
        systemctl start mariadb
        systemctl enable mariadb
    fi
    
    # 3. 检查并修复PHP-FPM问题
    log_info "检查PHP-FPM状态..."
    if systemctl is-active --quiet php8.2-fpm; then
        log_success "✓ PHP 8.2-FPM服务运行中"
    elif systemctl is-active --quiet php8.1-fpm; then
        log_success "✓ PHP 8.1-FPM服务运行中"
    else
        log_warning "⚠ PHP-FPM服务未运行，尝试启动..."
        systemctl start php8.2-fpm 2>/dev/null || systemctl start php8.1-fpm
    fi
    
    echo ""
}

# 修复权限问题
fix_permissions() {
    log_info "修复权限问题..."
    
    # 创建必要目录
    local directories=(
        "$INSTALL_DIR/uploads"
        "$INSTALL_DIR/logs"
        "$INSTALL_DIR/wireguard"
        "$INSTALL_DIR/wireguard/clients"
        "$INSTALL_DIR/temp"
        "$INSTALL_DIR/backups"
    )
    
    for directory in "${directories[@]}"; do
        if [[ ! -d "$directory" ]]; then
            mkdir -p "$directory"
            log_info "✓ 创建目录: $directory"
        fi
    done
    
    # 设置权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    chmod 755 "$INSTALL_DIR/venv/bin/python"
    chmod 755 "$INSTALL_DIR/venv/bin/uvicorn"
    
    log_success "✓ 权限修复完成"
    echo ""
}

# 修复Python环境
fix_python_environment() {
    log_info "修复Python环境..."
    
    # 切换到安装目录
    cd "$INSTALL_DIR"
    
    # 重新安装关键依赖
    log_info "重新安装关键Python依赖..."
    "$INSTALL_DIR/venv/bin/pip" install --upgrade pip
    "$INSTALL_DIR/venv/bin/pip" install --upgrade fastapi uvicorn sqlalchemy pymysql aiomysql python-dotenv
    
    # 检查依赖
    local critical_packages=("fastapi" "uvicorn" "sqlalchemy" "pymysql" "aiomysql")
    for package in "${critical_packages[@]}"; do
        if "$INSTALL_DIR/venv/bin/python" -c "import $package" 2>/dev/null; then
            log_success "✓ $package 可用"
        else
            log_error "✗ $package 不可用"
            "$INSTALL_DIR/venv/bin/pip" install "$package"
        fi
    done
    
    log_success "✓ Python环境修复完成"
    echo ""
}

# 修复配置文件
fix_configuration() {
    log_info "修复配置文件..."
    
    # 检查环境文件
    if [[ ! -f "$INSTALL_DIR/.env" ]]; then
        log_info "创建环境配置文件..."
        cat > "$INSTALL_DIR/.env" << EOF
# IPv6 WireGuard Manager 环境配置
DATABASE_URL=mysql+pymysql://ipv6wgm:ipv6wgm_password@localhost:3306/ipv6wgm
SECRET_KEY=your-secret-key-here-$(openssl rand -hex 32)
HOST=::
PORT=8000
DEBUG=false
LOG_LEVEL=INFO

# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_NAME=ipv6wgm
DB_USER=ipv6wgm
DB_PASSWORD=ipv6wgm_password

# 安全配置
JWT_SECRET_KEY=your-jwt-secret-key-$(openssl rand -hex 32)
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30

# 文件上传配置
MAX_FILE_SIZE=10485760
UPLOAD_DIR=/opt/ipv6-wireguard-manager/uploads

# WireGuard配置
WIREGUARD_CONFIG_DIR=/opt/ipv6-wireguard-manager/wireguard
WIREGUARD_CLIENTS_DIR=/opt/ipv6-wireguard-manager/wireguard/clients
EOF
        chown "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR/.env"
        chmod 600 "$INSTALL_DIR/.env"
        log_success "✓ 环境配置文件已创建"
    else
        log_success "✓ 环境配置文件已存在"
    fi
    
    echo ""
}

# 测试应用启动
test_application() {
    log_info "测试应用启动..."
    
    # 切换到安装目录
    cd "$INSTALL_DIR"
    
    # 设置环境变量
    export PYTHONPATH="$INSTALL_DIR"
    
    # 测试导入
    log_info "测试应用导入..."
    if "$INSTALL_DIR/venv/bin/python" -c "
import sys
sys.path.insert(0, '$INSTALL_DIR')
try:
    from backend.app.main import app
    print('✓ 主应用导入成功')
except Exception as e:
    print(f'✗ 主应用导入失败: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
" 2>&1; then
        log_success "✓ 应用导入测试通过"
    else
        log_error "✗ 应用导入测试失败"
        return 1
    fi
    
    # 测试配置文件
    log_info "测试配置文件..."
    if "$INSTALL_DIR/venv/bin/python" -c "
import sys
sys.path.insert(0, '$INSTALL_DIR')
try:
    from backend.app.core.config_enhanced import settings
    print('✓ 配置文件导入成功')
except Exception as e:
    print(f'✗ 配置文件导入失败: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
" 2>&1; then
        log_success "✓ 配置文件测试通过"
    else
        log_error "✗ 配置文件测试失败"
        return 1
    fi
    
    echo ""
    return 0
}

# 修复服务配置
fix_service_config() {
    log_info "修复服务配置..."
    
    # 重新加载systemd
    systemctl daemon-reload
    
    # 检查服务文件
    local service_file="/etc/systemd/system/$SERVICE_NAME.service"
    if [[ -f "$service_file" ]]; then
        log_success "✓ 服务文件存在"
        
        # 显示服务文件内容
        echo "=== 服务文件内容 ==="
        cat "$service_file"
        echo ""
    else
        log_error "✗ 服务文件不存在"
        return 1
    fi
    
    echo ""
}

# 启动服务
start_service() {
    log_info "启动服务..."
    
    systemctl start "$SERVICE_NAME"
    sleep 5
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_success "✓ 服务启动成功"
        return 0
    else
        log_error "✗ 服务启动失败"
        return 1
    fi
}

# 验证服务
verify_service() {
    log_info "验证服务..."
    
    # 检查服务状态
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_success "✓ 服务正在运行"
    else
        log_error "✗ 服务未运行"
        return 1
    fi
    
    # 检查端口
    sleep 3
    if netstat -tlnp 2>/dev/null | grep ":8000 " &>/dev/null; then
        log_success "✓ 端口8000正在监听"
    else
        log_warning "⚠ 端口8000未监听，等待服务完全启动..."
        sleep 5
        if netstat -tlnp 2>/dev/null | grep ":8000 " &>/dev/null; then
            log_success "✓ 端口8000正在监听"
        else
            log_error "✗ 端口8000仍未监听"
            return 1
        fi
    fi
    
    # 测试API连接
    sleep 3
    if curl -f http://localhost:8000/api/v1/health &>/dev/null; then
        log_success "✓ API健康检查通过"
    else
        log_warning "⚠ API健康检查失败，但服务可能正在启动中"
    fi
    
    return 0
}

# 显示最终状态
show_final_status() {
    log_info "最终状态检查..."
    
    echo "=== 服务状态 ==="
    systemctl status "$SERVICE_NAME" --no-pager -l
    echo ""
    
    echo "=== 端口监听 ==="
    netstat -tlnp | grep -E ":(80|8000) " || echo "未检测到相关端口监听"
    echo ""
    
    echo "=== 最近日志 ==="
    journalctl -u "$SERVICE_NAME" --no-pager -n 5
    echo ""
}

# 主函数
main() {
    # 检查系统
    check_system
    
    # 停止服务
    stop_service
    
    # 检查日志
    check_logs
    
    # 修复Debian 12特定问题
    fix_debian12_issues
    
    # 修复权限
    fix_permissions
    
    # 修复Python环境
    fix_python_environment
    
    # 修复配置文件
    fix_configuration
    
    # 测试应用
    if ! test_application; then
        log_error "应用测试失败，请检查错误信息"
        return 1
    fi
    
    # 修复服务配置
    fix_service_config
    
    # 启动服务
    if ! start_service; then
        log_error "服务启动失败"
        show_final_status
        return 1
    fi
    
    # 验证服务
    if verify_service; then
        log_success "🎉 Debian 12 API服务修复成功！"
        echo ""
        log_info "访问信息:"
        log_info "  API健康检查: http://localhost:8000/api/v1/health"
        log_info "  API文档: http://localhost:8000/docs"
        log_info "  前端页面: http://localhost/"
        echo ""
        log_info "管理命令:"
        log_info "  查看状态: sudo systemctl status $SERVICE_NAME"
        log_info "  查看日志: sudo journalctl -u $SERVICE_NAME -f"
        log_info "  重启服务: sudo systemctl restart $SERVICE_NAME"
    else
        log_error "❌ 服务验证失败"
        show_final_status
        return 1
    fi
}

# 运行主函数
main "$@"
