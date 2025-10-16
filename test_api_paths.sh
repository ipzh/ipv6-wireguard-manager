#!/bin/bash

# API路径测试脚本
# 用于测试API路径映射是否正确

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

# 测试API路径
test_api_paths() {
    log_info "=== API路径测试 ==="
    
    local api_port=8000
    local base_url="http://localhost"
    
    # 测试后端直接访问
    log_info "测试后端直接访问..."
    
    # 测试根路径
    if curl -f -s http://127.0.0.1:$api_port/ >/dev/null 2>&1; then
        log_success "✓ 后端根路径访问成功"
        echo "响应: $(curl -s http://127.0.0.1:$api_port/ | head -1)"
    else
        log_error "✗ 后端根路径访问失败"
    fi
    
    # 测试健康检查路径
    if curl -f -s http://127.0.0.1:$api_port/health >/dev/null 2>&1; then
        log_success "✓ 后端健康检查路径访问成功"
        echo "响应: $(curl -s http://127.0.0.1:$api_port/health | head -1)"
    else
        log_error "✗ 后端健康检查路径访问失败"
    fi
    
    # 测试API v1路径
    if curl -f -s http://127.0.0.1:$api_port/api/v1/ >/dev/null 2>&1; then
        log_success "✓ 后端API v1根路径访问成功"
        echo "响应: $(curl -s http://127.0.0.1:$api_port/api/v1/ | head -1)"
    else
        log_error "✗ 后端API v1根路径访问失败"
    fi
    
    # 测试API v1健康检查路径
    if curl -f -s http://127.0.0.1:$api_port/api/v1/health >/dev/null 2>&1; then
        log_success "✓ 后端API v1健康检查路径访问成功"
        echo "响应: $(curl -s http://127.0.0.1:$api_port/api/v1/health | head -1)"
    else
        log_error "✗ 后端API v1健康检查路径访问失败"
    fi
    
    echo ""
    
    # 测试Nginx代理访问
    log_info "测试Nginx代理访问..."
    
    # 测试前端根路径
    if curl -f -s $base_url/ >/dev/null 2>&1; then
        log_success "✓ 前端根路径访问成功"
    else
        log_error "✗ 前端根路径访问失败"
    fi
    
    # 测试API代理路径
    if curl -f -s $base_url/api/health >/dev/null 2>&1; then
        log_success "✓ API代理路径访问成功"
        echo "响应: $(curl -s $base_url/api/health | head -1)"
    else
        log_error "✗ API代理路径访问失败"
        echo "错误详情:"
        curl -v $base_url/api/health 2>&1 | head -10
    fi
    
    echo ""
}

# 测试IPv6连接
test_ipv6_paths() {
    log_info "=== IPv6 API路径测试 ==="
    
    local api_port=8000
    
    # 测试IPv6后端直接访问
    if curl -f -s http://[::1]:$api_port/health >/dev/null 2>&1; then
        log_success "✓ IPv6后端健康检查路径访问成功"
        echo "响应: $(curl -s http://[::1]:$api_port/health | head -1)"
    else
        log_warning "⚠ IPv6后端健康检查路径访问失败"
    fi
    
    if curl -f -s http://[::1]:$api_port/api/v1/health >/dev/null 2>&1; then
        log_success "✓ IPv6后端API v1健康检查路径访问成功"
        echo "响应: $(curl -s http://[::1]:$api_port/api/v1/health | head -1)"
    else
        log_warning "⚠ IPv6后端API v1健康检查路径访问失败"
    fi
    
    echo ""
}

# 显示路径映射信息
show_path_mapping() {
    log_info "=== API路径映射信息 ==="
    
    echo "后端API路径结构:"
    echo "  - 根路径: http://127.0.0.1:8000/"
    echo "  - 健康检查: http://127.0.0.1:8000/health"
    echo "  - API v1根: http://127.0.0.1:8000/api/v1/"
    echo "  - API v1健康: http://127.0.0.1:8000/api/v1/health"
    echo ""
    
    echo "前端访问路径:"
    echo "  - 前端页面: http://localhost/"
    echo "  - API代理: http://localhost/api/health"
    echo ""
    
    echo "Nginx代理映射:"
    echo "  - /api/health → http://backend_api/api/v1/health"
    echo "  - backend_api = [::1]:8000 (IPv6优先) 或 127.0.0.1:8000 (IPv4备选)"
    echo ""
}

# 检查服务状态
check_services() {
    log_info "=== 服务状态检查 ==="
    
    # 检查后端服务
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "✓ 后端服务正在运行"
    else
        log_error "✗ 后端服务未运行"
    fi
    
    # 检查Nginx服务
    if systemctl is-active --quiet nginx; then
        log_success "✓ Nginx服务正在运行"
    else
        log_error "✗ Nginx服务未运行"
    fi
    
    # 检查端口监听
    if netstat -tuln 2>/dev/null | grep -q ":8000 "; then
        log_success "✓ 端口8000正在监听"
    else
        log_error "✗ 端口8000未监听"
    fi
    
    if netstat -tuln 2>/dev/null | grep -q ":80 "; then
        log_success "✓ 端口80正在监听"
    else
        log_error "✗ 端口80未监听"
    fi
    
    echo ""
}

# 主函数
main() {
    echo "IPv6 WireGuard Manager - API路径测试工具"
    echo "=========================================="
    echo ""
    
    check_services
    show_path_mapping
    test_api_paths
    test_ipv6_paths
    
    log_info "测试完成！"
}

# 运行主函数
main "$@"
