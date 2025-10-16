#!/bin/bash

# IPv6 WireGuard Manager - API服务检查脚本
# 检查API服务状态和连接

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

# 默认API端口
API_PORT=${API_PORT:-8000}

# 检查服务状态
check_service_status() {
    log_info "检查systemd服务状态..."
    
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "✓ IPv6 WireGuard Manager服务正在运行"
    else
        log_error "✗ IPv6 WireGuard Manager服务未运行"
        return 1
    fi
    
    if systemctl is-enabled --quiet ipv6-wireguard-manager; then
        log_success "✓ IPv6 WireGuard Manager服务已启用"
    else
        log_warning "⚠ IPv6 WireGuard Manager服务未启用"
    fi
}

# 检查端口监听
check_port_listening() {
    log_info "检查端口监听状态..."
    
    if netstat -tlnp 2>/dev/null | grep -q ":$API_PORT "; then
        log_success "✓ 端口 $API_PORT 正在监听"
    else
        log_error "✗ 端口 $API_PORT 未监听"
        return 1
    fi
}

# 检查API健康状态
check_api_health() {
    log_info "检查API健康状态..."
    
    local retry_count=0
    local max_retries=5
    local retry_delay=2
    
    while [[ $retry_count -lt $max_retries ]]; do
        if curl -f http://localhost:$API_PORT/api/v1/health &>/dev/null; then
            log_success "✓ API健康检查通过"
            return 0
        else
            retry_count=$((retry_count + 1))
            if [[ $retry_count -lt $max_retries ]]; then
                log_info "API未就绪，等待 ${retry_delay} 秒后重试... (${retry_count}/${max_retries})"
                sleep $retry_delay
            fi
        fi
    done
    
    log_error "✗ API健康检查失败"
    return 1
}

# 检查API文档
check_api_docs() {
    log_info "检查API文档..."
    
    if curl -f http://localhost:$API_PORT/docs &>/dev/null; then
        log_success "✓ API文档可访问"
    else
        log_warning "⚠ API文档无法访问"
    fi
}

# 检查API响应
check_api_response() {
    log_info "检查API响应..."
    
    local response=$(curl -s http://localhost:$API_PORT/api/v1/health 2>/dev/null)
    if [[ -n "$response" ]]; then
        log_success "✓ API响应正常"
        log_info "响应内容: $response"
    else
        log_error "✗ API无响应"
        return 1
    fi
}

# 显示服务日志
show_service_logs() {
    log_info "显示最近的服务日志..."
    echo ""
    journalctl -u ipv6-wireguard-manager --no-pager -n 20
    echo ""
}

# 显示网络连接
show_network_connections() {
    log_info "显示网络连接..."
    echo ""
    netstat -tlnp | grep -E ":(80|8000) "
    echo ""
}

# 重启服务
restart_service() {
    log_info "重启IPv6 WireGuard Manager服务..."
    
    systemctl restart ipv6-wireguard-manager
    sleep 3
    
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "✓ 服务重启成功"
    else
        log_error "✗ 服务重启失败"
        return 1
    fi
}

# 主函数
main() {
    log_info "IPv6 WireGuard Manager - API服务检查"
    echo ""
    
    # 检查服务状态
    if ! check_service_status; then
        log_error "服务未运行，尝试重启..."
        if restart_service; then
            log_info "服务重启成功，继续检查..."
        else
            log_error "服务重启失败，请检查配置"
            exit 1
        fi
    fi
    
    echo ""
    
    # 检查端口监听
    if ! check_port_listening; then
        log_error "端口未监听，请检查服务配置"
        exit 1
    fi
    
    echo ""
    
    # 检查API健康状态
    if ! check_api_health; then
        log_error "API健康检查失败"
        echo ""
        show_service_logs
        exit 1
    fi
    
    echo ""
    
    # 检查API文档
    check_api_docs
    
    echo ""
    
    # 检查API响应
    check_api_response
    
    echo ""
    log_success "🎉 API服务检查完成！"
    echo ""
    log_info "访问信息:"
    log_info "  API健康检查: http://localhost:$API_PORT/api/v1/health"
    log_info "  API文档: http://localhost:$API_PORT/docs"
    log_info "  前端页面: http://localhost/"
}

# 处理命令行参数
case "${1:-}" in
    --restart)
        restart_service
        ;;
    --logs)
        show_service_logs
        ;;
    --network)
        show_network_connections
        ;;
    --help|-h)
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  --restart    重启服务"
        echo "  --logs       显示服务日志"
        echo "  --network    显示网络连接"
        echo "  --help, -h   显示帮助信息"
        ;;
    *)
        main
        ;;
esac
