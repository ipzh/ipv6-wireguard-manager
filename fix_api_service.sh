#!/bin/bash

# IPv6 WireGuard Manager - API服务修复脚本
# 修复API服务启动和连接问题

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

# 默认配置
INSTALL_DIR="/opt/ipv6-wireguard-manager"
API_PORT="8000"
SERVICE_USER="ipv6wgm"

log_info "开始修复API服务问题..."

# 检查服务状态
check_service_status() {
    log_info "检查服务状态..."
    
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "✓ 服务正在运行"
        return 0
    else
        log_warning "⚠ 服务未运行"
        return 1
    fi
}

# 检查安装目录
check_install_directory() {
    log_info "检查安装目录..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        log_success "✓ 安装目录存在: $INSTALL_DIR"
    else
        log_error "✗ 安装目录不存在: $INSTALL_DIR"
        return 1
    fi
    
    if [[ -f "$INSTALL_DIR/backend/app/main.py" ]]; then
        log_success "✓ 后端应用文件存在"
    else
        log_error "✗ 后端应用文件不存在"
        return 1
    fi
    
    if [[ -d "$INSTALL_DIR/venv" ]]; then
        log_success "✓ Python虚拟环境存在"
    else
        log_error "✗ Python虚拟环境不存在"
        return 1
    fi
}

# 检查Python环境
check_python_environment() {
    log_info "检查Python环境..."
    
    if [[ -f "$INSTALL_DIR/venv/bin/python" ]]; then
        log_success "✓ Python可执行文件存在"
    else
        log_error "✗ Python可执行文件不存在"
        return 1
    fi
    
    if [[ -f "$INSTALL_DIR/venv/bin/uvicorn" ]]; then
        log_success "✓ Uvicorn可执行文件存在"
    else
        log_error "✗ Uvicorn可执行文件不存在"
        return 1
    fi
    
    # 测试Python导入
    if "$INSTALL_DIR/venv/bin/python" -c "import fastapi" &>/dev/null; then
        log_success "✓ FastAPI模块可导入"
    else
        log_error "✗ FastAPI模块无法导入"
        return 1
    fi
}

# 检查配置文件
check_configuration() {
    log_info "检查配置文件..."
    
    if [[ -f "$INSTALL_DIR/.env" ]]; then
        log_success "✓ 环境配置文件存在"
    else
        log_warning "⚠ 环境配置文件不存在，创建默认配置..."
        create_default_config
    fi
    
    if [[ -f "/etc/systemd/system/ipv6-wireguard-manager.service" ]]; then
        log_success "✓ systemd服务文件存在"
    else
        log_error "✗ systemd服务文件不存在"
        return 1
    fi
}

# 创建默认配置
create_default_config() {
    log_info "创建默认环境配置..."
    
    cat > "$INSTALL_DIR/.env" << EOF
# IPv6 WireGuard Manager - 环境配置
APP_NAME="IPv6 WireGuard Manager"
APP_VERSION="3.1.0"
DEBUG=false
APP_ENV=production

# 数据库配置
DATABASE_URL="mysql+pymysql://ipv6wgm:ipv6wgm_password@localhost:3306/ipv6wgm"
DB_HOST="localhost"
DB_PORT=3306
DB_NAME="ipv6wgm"
DB_USER="ipv6wgm"
DB_PASS="ipv6wgm_password"

# 安全配置
SECRET_KEY="$(openssl rand -hex 32)"
JWT_SECRET_KEY="$(openssl rand -hex 32)"

# 服务器配置
HOST="::"
PORT=8000
EOF
    
    log_success "✓ 默认配置文件已创建"
}

# 检查数据库连接
check_database_connection() {
    log_info "检查数据库连接..."
    
    if mysql -u ipv6wgm -pipv6wgm_password -e "SELECT 1;" &>/dev/null; then
        log_success "✓ 数据库连接正常"
    else
        log_error "✗ 数据库连接失败"
        return 1
    fi
}

# 重启服务
restart_service() {
    log_info "重启API服务..."
    
    # 停止服务
    systemctl stop ipv6-wireguard-manager
    
    # 等待服务完全停止
    sleep 2
    
    # 重新加载systemd配置
    systemctl daemon-reload
    
    # 启动服务
    systemctl start ipv6-wireguard-manager
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "✓ 服务重启成功"
    else
        log_error "✗ 服务重启失败"
        return 1
    fi
}

# 测试API连接
test_api_connection() {
    log_info "测试API连接..."
    
    local retry_count=0
    local max_retries=10
    local retry_delay=3
    
    while [[ $retry_count -lt $max_retries ]]; do
        if curl -f http://localhost:$API_PORT/api/v1/health &>/dev/null; then
            log_success "✓ API连接测试成功"
            return 0
        else
            retry_count=$((retry_count + 1))
            if [[ $retry_count -lt $max_retries ]]; then
                log_info "API未就绪，等待 ${retry_delay} 秒后重试... (${retry_count}/${max_retries})"
                sleep $retry_delay
            fi
        fi
    done
    
    log_error "✗ API连接测试失败"
    return 1
}

# 显示诊断信息
show_diagnostics() {
    log_info "显示诊断信息..."
    echo ""
    
    log_info "服务状态:"
    systemctl status ipv6-wireguard-manager --no-pager -l
    
    echo ""
    log_info "最近的服务日志:"
    journalctl -u ipv6-wireguard-manager --no-pager -n 20
    
    echo ""
    log_info "端口监听状态:"
    netstat -tlnp | grep -E ":(80|8000) "
    
    echo ""
    log_info "进程信息:"
    ps aux | grep -E "(uvicorn|ipv6-wireguard)" | grep -v grep
}

# 主函数
main() {
    log_info "IPv6 WireGuard Manager - API服务修复脚本"
    echo ""
    
    # 检查安装目录
    if ! check_install_directory; then
        log_error "安装目录检查失败"
        exit 1
    fi
    
    echo ""
    
    # 检查Python环境
    if ! check_python_environment; then
        log_error "Python环境检查失败"
        exit 1
    fi
    
    echo ""
    
    # 检查配置文件
    if ! check_configuration; then
        log_error "配置文件检查失败"
        exit 1
    fi
    
    echo ""
    
    # 检查数据库连接
    if ! check_database_connection; then
        log_error "数据库连接检查失败"
        exit 1
    fi
    
    echo ""
    
    # 重启服务
    if ! restart_service; then
        log_error "服务重启失败"
        echo ""
        show_diagnostics
        exit 1
    fi
    
    echo ""
    
    # 测试API连接
    if ! test_api_connection; then
        log_error "API连接测试失败"
        echo ""
        show_diagnostics
        exit 1
    fi
    
    echo ""
    log_success "🎉 API服务修复完成！"
    echo ""
    log_info "访问信息:"
    log_info "  API健康检查: http://localhost:$API_PORT/api/v1/health"
    log_info "  API文档: http://localhost:$API_PORT/docs"
    log_info "  前端页面: http://localhost/"
    echo ""
    log_info "服务管理:"
    log_info "  查看状态: sudo systemctl status ipv6-wireguard-manager"
    log_info "  查看日志: sudo journalctl -u ipv6-wireguard-manager -f"
    log_info "  重启服务: sudo systemctl restart ipv6-wireguard-manager"
}

# 运行主函数
main "$@"
