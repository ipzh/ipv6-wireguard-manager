#!/bin/bash

# IPv6 WireGuard Manager - WireGuard权限快速修复脚本
# 专门修复WireGuard目录权限问题

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
SERVICE_USER="ipv6wgm"
SERVICE_GROUP="ipv6wgm"

log_info "开始修复WireGuard目录权限问题..."

# 停止服务
stop_service() {
    log_info "停止服务..."
    systemctl stop ipv6-wireguard-manager 2>/dev/null || true
    sleep 2
    log_success "✓ 服务已停止"
}

# 创建WireGuard目录
create_wireguard_directories() {
    log_info "创建WireGuard目录..."
    
    local directories=(
        "$INSTALL_DIR/wireguard"
        "$INSTALL_DIR/wireguard/clients"
        "$INSTALL_DIR/uploads"
        "$INSTALL_DIR/logs"
        "$INSTALL_DIR/temp"
        "$INSTALL_DIR/backups"
    )
    
    for directory in "${directories[@]}"; do
        if [[ ! -d "$directory" ]]; then
            mkdir -p "$directory"
            log_info "✓ 创建目录: $directory"
        else
            log_info "✓ 目录已存在: $directory"
        fi
        
        # 设置目录权限
        chown "$SERVICE_USER:$SERVICE_GROUP" "$directory"
        chmod 755 "$directory"
    done
    
    log_success "✓ WireGuard目录创建完成"
}

# 修复所有权限
fix_all_permissions() {
    log_info "修复所有权限..."
    
    # 设置安装目录权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
    find "$INSTALL_DIR" -type d -exec chmod 755 {} \;
    find "$INSTALL_DIR" -type f -exec chmod 644 {} \;
    find "$INSTALL_DIR" -name "*.py" -exec chmod 755 {} \;
    find "$INSTALL_DIR" -name "*.sh" -exec chmod 755 {} \;
    find "$INSTALL_DIR/venv/bin" -type f -exec chmod 755 {} \;
    
    log_success "✓ 所有权限修复完成"
}

# 验证权限
verify_permissions() {
    log_info "验证权限设置..."
    
    # 检查WireGuard目录
    if [[ -d "$INSTALL_DIR/wireguard" ]]; then
        local wg_owner=$(stat -c '%U:%G' "$INSTALL_DIR/wireguard" 2>/dev/null || echo "unknown")
        if [[ "$wg_owner" == "$SERVICE_USER:$SERVICE_GROUP" ]]; then
            log_success "✓ WireGuard目录权限正确: $wg_owner"
        else
            log_warning "⚠ WireGuard目录权限不正确: $wg_owner"
        fi
    else
        log_warning "⚠ WireGuard目录不存在"
    fi
    
    # 检查uploads目录
    if [[ -d "$INSTALL_DIR/uploads" ]]; then
        local uploads_owner=$(stat -c '%U:%G' "$INSTALL_DIR/uploads" 2>/dev/null || echo "unknown")
        if [[ "$uploads_owner" == "$SERVICE_USER:$SERVICE_GROUP" ]]; then
            log_success "✓ uploads目录权限正确: $uploads_owner"
        else
            log_warning "⚠ uploads目录权限不正确: $uploads_owner"
        fi
    else
        log_warning "⚠ uploads目录不存在"
    fi
}

# 启动服务
start_service() {
    log_info "启动服务..."
    
    systemctl daemon-reload
    systemctl start ipv6-wireguard-manager
    
    sleep 5
    
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "✓ 服务启动成功"
        return 0
    else
        log_error "✗ 服务启动失败"
        return 1
    fi
}

# 显示服务状态
show_service_status() {
    log_info "服务状态:"
    systemctl status ipv6-wireguard-manager --no-pager -l
    echo ""
    
    log_info "最近的服务日志:"
    journalctl -u ipv6-wireguard-manager --no-pager -n 10
    echo ""
}

# 主函数
main() {
    log_info "IPv6 WireGuard Manager - WireGuard权限快速修复脚本"
    echo ""
    
    # 停止服务
    stop_service
    echo ""
    
    # 创建WireGuard目录
    create_wireguard_directories
    echo ""
    
    # 修复所有权限
    fix_all_permissions
    echo ""
    
    # 验证权限
    verify_permissions
    echo ""
    
    # 启动服务
    if ! start_service; then
        log_error "服务启动失败"
        echo ""
        show_service_status
        exit 1
    fi
    echo ""
    
    # 显示服务状态
    show_service_status
    
    log_success "🎉 WireGuard权限修复完成！"
    echo ""
    log_info "访问信息:"
    log_info "  API健康检查: http://localhost:8000/api/v1/health"
    log_info "  API文档: http://localhost:8000/docs"
    log_info "  前端页面: http://localhost/"
    echo ""
    log_info "服务管理:"
    log_info "  查看状态: sudo systemctl status ipv6-wireguard-manager"
    log_info "  查看日志: sudo journalctl -u ipv6-wireguard-manager -f"
    log_info "  使用CLI: ipv6-wireguard-manager status"
}

# 运行主函数
main "$@"
