#!/bin/bash

# IPv6 WireGuard Manager - 快速API检查脚本
# 一键检查API服务状态和常见问题

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
echo "IPv6 WireGuard Manager - 快速API检查"
echo "=================================="
echo

# 1. 检查服务状态
log_info "1. 检查服务状态..."
if systemctl is-active --quiet nginx; then
    log_success "✓ Nginx运行正常"
else
    log_error "✗ Nginx未运行"
fi

if systemctl is-active --quiet ipv6-wireguard-manager; then
    log_success "✓ 后端服务运行正常"
else
    log_error "✗ 后端服务未运行"
fi

# 2. 检查端口
log_info "2. 检查端口监听..."
if ss -tlnp | grep -q ":80 "; then
    log_success "✓ Web端口80正常监听"
else
    log_error "✗ Web端口80未监听"
fi

if ss -tlnp | grep -q ":8000 "; then
    log_success "✓ API端口8000正常监听"
else
    log_error "✗ API端口8000未监听"
fi

# 3. 测试API连接
log_info "3. 测试API连接..."
api_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
if [[ "$api_status" == "200" ]]; then
    log_success "✓ API健康检查正常"
else
    log_error "✗ API健康检查失败 (HTTP $api_status)"
fi

# 4. 测试Web服务
log_info "4. 测试Web服务..."
web_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
if [[ "$web_status" == "200" ]]; then
    log_success "✓ Web服务正常"
elif [[ "$web_status" == "500" ]]; then
    log_error "✗ Web服务返回500错误"
else
    log_warning "⚠ Web服务异常 (HTTP $web_status)"
fi

# 5. 检查最近错误
log_info "5. 检查最近错误日志..."
recent_errors=$(journalctl -u ipv6-wireguard-manager --no-pager -l -n 10 | grep -i "error\|failed\|exception" | wc -l)
if [[ $recent_errors -gt 0 ]]; then
    log_warning "⚠ 发现 $recent_errors 个错误日志"
    echo "最近的错误："
    journalctl -u ipv6-wireguard-manager --no-pager -l -n 5 | grep -i "error\|failed\|exception" | tail -3
else
    log_success "✓ 无错误日志"
fi

echo
echo "=================================="
echo "检查完成！"
echo "=================================="

# 如果发现问题，提供修复建议
if [[ "$api_status" != "200" ]] || [[ "$web_status" == "500" ]]; then
    echo
    log_warning "发现问题，建议运行以下命令修复："
    echo "1. 升级passlib: cd /opt/ipv6-wireguard-manager && source venv/bin/activate && pip install --upgrade passlib[argon2] argon2-cffi"
    echo "2. 重启服务: systemctl restart ipv6-wireguard-manager"
    echo "3. 重新检查: ./quick_api_check.sh"
fi
