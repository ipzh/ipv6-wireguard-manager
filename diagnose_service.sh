#!/bin/bash

# IPv6 WireGuard Manager - 服务诊断脚本
# 诊断服务启动失败问题

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
SERVICE_NAME="ipv6-wireguard-manager"

log_info "开始诊断IPv6 WireGuard Manager服务..."

# 检查服务状态
check_service_status() {
    log_info "检查服务状态..."
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        log_success "✓ 服务正在运行"
        return 0
    else
        log_warning "⚠ 服务未运行"
        return 1
    fi
}

# 检查服务配置
check_service_config() {
    log_info "检查服务配置..."
    
    if [[ -f "/etc/systemd/system/$SERVICE_NAME.service" ]]; then
        log_success "✓ 服务配置文件存在"
        echo ""
        log_info "服务配置内容:"
        cat /etc/systemd/system/$SERVICE_NAME.service
        echo ""
    else
        log_error "✗ 服务配置文件不存在"
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
    log_info "测试Python模块导入..."
    if "$INSTALL_DIR/venv/bin/python" -c "import fastapi, uvicorn" &>/dev/null; then
        log_success "✓ 核心模块可导入"
    else
        log_error "✗ 核心模块无法导入"
        return 1
    fi
}

# 检查端口占用
check_port_usage() {
    log_info "检查端口占用..."
    
    if netstat -tlnp 2>/dev/null | grep -q ":8000 "; then
        log_warning "⚠ 端口8000已被占用"
        netstat -tlnp | grep ":8000 "
        return 1
    else
        log_success "✓ 端口8000可用"
        return 0
    fi
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

# 检查环境配置
check_environment_config() {
    log_info "检查环境配置..."
    
    if [[ -f "$INSTALL_DIR/.env" ]]; then
        log_success "✓ 环境配置文件存在"
    else
        log_warning "⚠ 环境配置文件不存在"
        return 1
    fi
    
    # 检查关键配置项
    if grep -q "DATABASE_URL" "$INSTALL_DIR/.env"; then
        log_success "✓ 数据库配置存在"
    else
        log_error "✗ 数据库配置缺失"
        return 1
    fi
}

# 手动测试启动
test_manual_start() {
    log_info "手动测试启动..."
    
    cd "$INSTALL_DIR"
    
    # 激活虚拟环境并测试启动
    if source venv/bin/activate && python -c "from backend.app.main import app; print('应用导入成功')" 2>/dev/null; then
        log_success "✓ 应用可以正常导入"
    else
        log_error "✗ 应用导入失败"
        log_info "详细错误信息:"
        source venv/bin/activate && python -c "from backend.app.main import app" 2>&1 || true
        return 1
    fi
}

# 显示服务日志
show_service_logs() {
    log_info "显示最近的服务日志..."
    echo ""
    journalctl -u $SERVICE_NAME --no-pager -n 20
    echo ""
}

# 修复建议
provide_fix_suggestions() {
    log_info "修复建议:"
    echo ""
    echo "1. 重新安装Python依赖:"
    echo "   cd $INSTALL_DIR && source venv/bin/activate && pip install -r backend/requirements.txt"
    echo ""
    echo "2. 重新创建环境配置:"
    echo "   cp $INSTALL_DIR/.env.example $INSTALL_DIR/.env"
    echo ""
    echo "3. 重新加载systemd配置:"
    echo "   sudo systemctl daemon-reload"
    echo ""
    echo "4. 重启服务:"
    echo "   sudo systemctl restart $SERVICE_NAME"
    echo ""
    echo "5. 查看实时日志:"
    echo "   sudo journalctl -u $SERVICE_NAME -f"
    echo ""
}

# 主函数
main() {
    log_info "IPv6 WireGuard Manager - 服务诊断脚本"
    echo ""
    
    local issues_found=0
    
    # 检查服务状态
    if ! check_service_status; then
        issues_found=$((issues_found + 1))
    fi
    
    echo ""
    
    # 检查服务配置
    if ! check_service_config; then
        issues_found=$((issues_found + 1))
    fi
    
    echo ""
    
    # 检查安装目录
    if ! check_install_directory; then
        issues_found=$((issues_found + 1))
    fi
    
    echo ""
    
    # 检查Python环境
    if ! check_python_environment; then
        issues_found=$((issues_found + 1))
    fi
    
    echo ""
    
    # 检查端口占用
    if ! check_port_usage; then
        issues_found=$((issues_found + 1))
    fi
    
    echo ""
    
    # 检查数据库连接
    if ! check_database_connection; then
        issues_found=$((issues_found + 1))
    fi
    
    echo ""
    
    # 检查环境配置
    if ! check_environment_config; then
        issues_found=$((issues_found + 1))
    fi
    
    echo ""
    
    # 手动测试启动
    if ! test_manual_start; then
        issues_found=$((issues_found + 1))
    fi
    
    echo ""
    
    # 显示服务日志
    show_service_logs
    
    # 总结
    if [[ $issues_found -eq 0 ]]; then
        log_success "🎉 所有检查通过！服务应该可以正常运行。"
        log_info "如果服务仍然无法启动，请查看上面的日志信息。"
    else
        log_error "发现 $issues_found 个问题，需要修复。"
        echo ""
        provide_fix_suggestions
    fi
}

# 运行主函数
main "$@"
