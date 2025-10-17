#!/bin/bash

# IPv6 WireGuard Manager - API问题一键修复脚本
# 自动修复常见的API问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "=================================="
echo "IPv6 WireGuard Manager - API问题修复"
echo "=================================="
echo

INSTALL_DIR="/opt/ipv6-wireguard-manager"

# 1. 停止服务
log_info "1. 停止后端服务..."
systemctl stop ipv6-wireguard-manager
log_success "后端服务已停止"

# 2. 修复passlib兼容性问题
log_info "2. 修复passlib兼容性问题..."
cd "$INSTALL_DIR"
source venv/bin/activate

# 升级passlib和argon2
log_info "升级passlib和argon2库..."
pip install --upgrade passlib[argon2] argon2-cffi

log_success "passlib和argon2库升级完成"

# 3. 检查Python依赖
log_info "3. 检查Python依赖..."
pip install -r backend/requirements.txt
log_success "Python依赖检查完成"

# 4. 重启服务
log_info "4. 重启后端服务..."
systemctl start ipv6-wireguard-manager
sleep 5

# 5. 检查服务状态
log_info "5. 检查服务状态..."
if systemctl is-active --quiet ipv6-wireguard-manager; then
    log_success "✓ 后端服务启动成功"
else
    log_error "✗ 后端服务启动失败"
    echo "服务日志："
    journalctl -u ipv6-wireguard-manager --no-pager -l -n 10
    exit 1
fi

# 6. 测试API连接
log_info "6. 测试API连接..."
sleep 3
api_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
if [[ "$api_status" == "200" ]]; then
    log_success "✓ API服务正常 (HTTP $api_status)"
else
    log_warning "⚠ API服务异常 (HTTP $api_status)"
fi

# 7. 测试Web服务
log_info "7. 测试Web服务..."
web_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
if [[ "$web_status" == "200" ]]; then
    log_success "✓ Web服务正常 (HTTP $web_status)"
else
    log_warning "⚠ Web服务异常 (HTTP $web_status)"
fi

echo
echo "=================================="
echo "修复完成！"
echo "=================================="

if [[ "$api_status" == "200" ]] && [[ "$web_status" == "200" ]]; then
    log_success "🎉 所有服务正常运行！"
    echo
    echo "访问地址："
    echo "- Web界面: http://localhost/"
    echo "- API文档: http://localhost:8000/docs"
    echo "- 健康检查: http://localhost:8000/health"
else
    log_warning "⚠ 部分服务仍有问题，请检查日志："
    echo "journalctl -u ipv6-wireguard-manager -f"
fi
