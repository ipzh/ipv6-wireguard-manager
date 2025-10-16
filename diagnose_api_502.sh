#!/bin/bash

# API 502错误诊断脚本
# 用于诊断和修复API连接问题

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

# 检查系统信息
check_system_info() {
    log_info "=== 系统信息检查 ==="
    echo "操作系统: $(uname -a)"
    echo "当前用户: $(whoami)"
    echo "当前目录: $(pwd)"
    echo ""
}

# 检查服务状态
check_service_status() {
    log_info "=== 服务状态检查 ==="
    
    # 检查IPv6 WireGuard Manager服务
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "✓ IPv6 WireGuard Manager服务正在运行"
    else
        log_error "✗ IPv6 WireGuard Manager服务未运行"
        echo "服务状态:"
        systemctl status ipv6-wireguard-manager --no-pager -l
    fi
    
    # 检查Nginx服务
    if systemctl is-active --quiet nginx; then
        log_success "✓ Nginx服务正在运行"
    else
        log_error "✗ Nginx服务未运行"
    fi
    
    # 检查PHP-FPM服务
    if systemctl is-active --quiet php8.2-fpm; then
        log_success "✓ PHP-FPM服务正在运行"
    else
        log_warning "⚠ PHP-FPM服务未运行"
    fi
    
    echo ""
}

# 检查端口监听
check_port_listening() {
    log_info "=== 端口监听检查 ==="
    
    # 检查API端口
    if netstat -tuln 2>/dev/null | grep -q ":8000 "; then
        log_success "✓ 端口8000正在监听"
        echo "监听详情:"
        netstat -tuln | grep ":8000 "
    else
        log_error "✗ 端口8000未监听"
    fi
    
    # 检查Web端口
    if netstat -tuln 2>/dev/null | grep -q ":80 "; then
        log_success "✓ 端口80正在监听"
    else
        log_error "✗ 端口80未监听"
    fi
    
    echo ""
}

# 检查API直接连接
check_api_direct() {
    log_info "=== API直接连接测试（双栈支持） ==="
    
    # 测试IPv6连接
    if curl -f -s http://[::1]:8000/api/v1/health >/dev/null 2>&1; then
        log_success "✓ API IPv6连接成功"
        echo "IPv6 API响应:"
        curl -s http://[::1]:8000/api/v1/health | head -3
    else
        log_warning "⚠ API IPv6连接失败"
    fi
    
    # 测试IPv4连接
    if curl -f -s http://127.0.0.1:8000/api/v1/health >/dev/null 2>&1; then
        log_success "✓ API IPv4连接成功"
        echo "IPv4 API响应:"
        curl -s http://127.0.0.1:8000/api/v1/health | head -3
    else
        log_warning "⚠ API IPv4连接失败"
    fi
    
    # 如果都失败，显示详细错误
    if ! curl -f -s http://[::1]:8000/api/v1/health >/dev/null 2>&1 && ! curl -f -s http://127.0.0.1:8000/api/v1/health >/dev/null 2>&1; then
        log_error "✗ API双栈连接都失败"
        echo "IPv6连接详情:"
        curl -v http://[::1]:8000/api/v1/health 2>&1 | head -5
        echo "IPv4连接详情:"
        curl -v http://127.0.0.1:8000/api/v1/health 2>&1 | head -5
    fi
    
    echo ""
}

# 检查Nginx配置
check_nginx_config() {
    log_info "=== Nginx配置检查 ==="
    
    # 检查配置文件语法
    if nginx -t 2>/dev/null; then
        log_success "✓ Nginx配置语法正确"
    else
        log_error "✗ Nginx配置语法错误"
        nginx -t
    fi
    
    # 检查站点配置
    if [[ -f /etc/nginx/sites-available/ipv6-wireguard-manager ]]; then
        log_success "✓ 站点配置文件存在"
        echo "关键配置:"
        grep -E "(root|proxy_pass|listen|upstream)" /etc/nginx/sites-available/ipv6-wireguard-manager
        echo ""
        echo "双栈配置检查:"
        if grep -q "upstream backend_api" /etc/nginx/sites-available/ipv6-wireguard-manager; then
            log_success "✓ 发现upstream配置"
            grep -A 10 "upstream backend_api" /etc/nginx/sites-available/ipv6-wireguard-manager
        else
            log_warning "⚠ 未发现upstream配置"
        fi
    else
        log_error "✗ 站点配置文件不存在"
    fi
    
    echo ""
}

# 检查文件权限
check_file_permissions() {
    log_info "=== 文件权限检查 ==="
    
    local install_dir="/opt/ipv6-wireguard-manager"
    
    if [[ -d "$install_dir" ]]; then
        log_success "✓ 安装目录存在: $install_dir"
        
        # 检查前端目录
        if [[ -d "$install_dir/php-frontend" ]]; then
            log_success "✓ 前端目录存在"
            echo "前端目录权限:"
            ls -la "$install_dir/php-frontend" | head -5
        else
            log_error "✗ 前端目录不存在"
        fi
        
        # 检查后端目录
        if [[ -d "$install_dir/backend" ]]; then
            log_success "✓ 后端目录存在"
        else
            log_error "✗ 后端目录不存在"
        fi
    else
        log_error "✗ 安装目录不存在: $install_dir"
    fi
    
    echo ""
}

# 检查日志
check_logs() {
    log_info "=== 日志检查 ==="
    
    # 检查Nginx错误日志
    if [[ -f /var/log/nginx/error.log ]]; then
        log_info "Nginx错误日志 (最近10行):"
        tail -10 /var/log/nginx/error.log
    fi
    
    echo ""
    
    # 检查应用日志
    log_info "应用服务日志 (最近10行):"
    journalctl -u ipv6-wireguard-manager --no-pager -l -n 10
    
    echo ""
}

# 测试API代理
test_api_proxy() {
    log_info "=== API代理测试 ==="
    
    # 测试通过Nginx代理的API
    if curl -f -s http://localhost/api/health >/dev/null 2>&1; then
        log_success "✓ API代理连接成功"
        echo "代理API响应:"
        curl -s http://localhost/api/health | head -3
    else
        log_error "✗ API代理连接失败"
        echo "代理连接详情:"
        curl -v http://localhost/api/health 2>&1 | head -10
    fi
    
    echo ""
}

# 修复建议
provide_fixes() {
    log_info "=== 修复建议 ==="
    
    echo "如果发现问题的修复步骤:"
    echo ""
    echo "1. 重启服务:"
    echo "   sudo systemctl restart ipv6-wireguard-manager"
    echo "   sudo systemctl restart nginx"
    echo ""
    echo "2. 检查配置:"
    echo "   sudo nginx -t"
    echo "   sudo systemctl status ipv6-wireguard-manager"
    echo ""
    echo "3. 重新安装:"
    echo "   cd /opt/ipv6-wireguard-manager"
    echo "   sudo ./install.sh"
    echo ""
    echo "4. 手动测试:"
    echo "   curl http://127.0.0.1:8000/api/v1/health"
    echo "   curl http://localhost/api/health"
    echo ""
}

# 主函数
main() {
    echo "IPv6 WireGuard Manager - API 502错误诊断工具"
    echo "=============================================="
    echo ""
    
    check_system_info
    check_service_status
    check_port_listening
    check_api_direct
    check_nginx_config
    check_file_permissions
    check_logs
    test_api_proxy
    provide_fixes
    
    log_info "诊断完成！"
}

# 运行主函数
main "$@"
