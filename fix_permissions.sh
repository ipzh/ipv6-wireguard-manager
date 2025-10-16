#!/bin/bash

# IPv6 WireGuard Manager - 权限修复脚本
# 修复文件权限和目录权限问题

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

log_info "开始修复IPv6 WireGuard Manager权限问题..."

# 停止服务
stop_service() {
    log_info "停止服务..."
    systemctl stop ipv6-wireguard-manager 2>/dev/null || true
    sleep 2
    log_success "✓ 服务已停止"
}

# 检查用户和组
check_user_group() {
    log_info "检查用户和组..."
    
    if id "$SERVICE_USER" &>/dev/null; then
        log_success "✓ 用户 $SERVICE_USER 存在"
    else
        log_error "✗ 用户 $SERVICE_USER 不存在"
        return 1
    fi
    
    if getent group "$SERVICE_GROUP" &>/dev/null; then
        log_success "✓ 组 $SERVICE_GROUP 存在"
    else
        log_warning "⚠ 组 $SERVICE_GROUP 不存在，创建组..."
        groupadd "$SERVICE_GROUP"
        log_success "✓ 组 $SERVICE_GROUP 已创建"
    fi
}

# 修复安装目录权限
fix_install_directory_permissions() {
    log_info "修复安装目录权限..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        # 设置目录所有者
        chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
        log_success "✓ 设置目录所有者: $SERVICE_USER:$SERVICE_GROUP"
        
        # 设置目录权限
        find "$INSTALL_DIR" -type d -exec chmod 755 {} \;
        log_success "✓ 设置目录权限: 755"
        
        # 设置文件权限
        find "$INSTALL_DIR" -type f -exec chmod 644 {} \;
        log_success "✓ 设置文件权限: 644"
        
        # 设置可执行文件权限
        find "$INSTALL_DIR" -name "*.py" -exec chmod 755 {} \;
        find "$INSTALL_DIR" -name "*.sh" -exec chmod 755 {} \;
        find "$INSTALL_DIR/venv/bin" -type f -exec chmod 755 {} \;
        log_success "✓ 设置可执行文件权限: 755"
    else
        log_error "✗ 安装目录不存在: $INSTALL_DIR"
        return 1
    fi
}

# 创建必要的目录
create_necessary_directories() {
    log_info "创建必要的目录..."
    
    local directories=(
        "$INSTALL_DIR/uploads"
        "$INSTALL_DIR/logs"
        "$INSTALL_DIR/temp"
        "$INSTALL_DIR/backups"
        "$INSTALL_DIR/config"
        "$INSTALL_DIR/data"
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
    
    log_success "✓ 所有必要目录已创建并设置权限"
}

# 修复Python虚拟环境权限
fix_venv_permissions() {
    log_info "修复Python虚拟环境权限..."
    
    if [[ -d "$INSTALL_DIR/venv" ]]; then
        chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR/venv"
        chmod -R 755 "$INSTALL_DIR/venv"
        log_success "✓ Python虚拟环境权限已修复"
    else
        log_warning "⚠ Python虚拟环境不存在"
    fi
}

# 修复配置文件权限
fix_config_permissions() {
    log_info "修复配置文件权限..."
    
    local config_files=(
        "$INSTALL_DIR/.env"
        "$INSTALL_DIR/backend/app/core/config_enhanced.py"
    )
    
    for file in "${config_files[@]}"; do
        if [[ -f "$file" ]]; then
            chown "$SERVICE_USER:$SERVICE_GROUP" "$file"
            chmod 644 "$file"
            log_info "✓ 修复配置文件权限: $file"
        fi
    done
    
    log_success "✓ 配置文件权限已修复"
}

# 修复systemd服务文件权限
fix_systemd_permissions() {
    log_info "修复systemd服务文件权限..."
    
    local service_file="/etc/systemd/system/ipv6-wireguard-manager.service"
    
    if [[ -f "$service_file" ]]; then
        chown root:root "$service_file"
        chmod 644 "$service_file"
        log_success "✓ systemd服务文件权限已修复"
    else
        log_warning "⚠ systemd服务文件不存在"
    fi
}

# 修复CLI工具权限
fix_cli_permissions() {
    log_info "修复CLI工具权限..."
    
    local cli_files=(
        "/usr/local/bin/ipv6-wireguard-manager"
        "/usr/bin/ipv6-wireguard-manager"
        "$INSTALL_DIR/ipv6-wireguard-manager"
    )
    
    for file in "${cli_files[@]}"; do
        if [[ -f "$file" ]]; then
            chown root:root "$file"
            chmod 755 "$file"
            log_info "✓ 修复CLI工具权限: $file"
        fi
    done
    
    log_success "✓ CLI工具权限已修复"
}

# 验证权限
verify_permissions() {
    log_info "验证权限设置..."
    
    # 检查安装目录权限
    local install_owner=$(stat -c '%U:%G' "$INSTALL_DIR" 2>/dev/null || echo "unknown")
    if [[ "$install_owner" == "$SERVICE_USER:$SERVICE_GROUP" ]]; then
        log_success "✓ 安装目录所有者正确: $install_owner"
    else
        log_warning "⚠ 安装目录所有者不正确: $install_owner (期望: $SERVICE_USER:$SERVICE_GROUP)"
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
    
    # 检查Python可执行文件权限
    if [[ -f "$INSTALL_DIR/venv/bin/python" ]]; then
        if [[ -x "$INSTALL_DIR/venv/bin/python" ]]; then
            log_success "✓ Python可执行文件权限正确"
        else
            log_warning "⚠ Python可执行文件权限不正确"
        fi
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
    log_info "IPv6 WireGuard Manager - 权限修复脚本"
    echo ""
    
    # 停止服务
    stop_service
    echo ""
    
    # 检查用户和组
    if ! check_user_group; then
        log_error "用户和组检查失败"
        exit 1
    fi
    echo ""
    
    # 修复安装目录权限
    if ! fix_install_directory_permissions; then
        log_error "安装目录权限修复失败"
        exit 1
    fi
    echo ""
    
    # 创建必要的目录
    create_necessary_directories
    echo ""
    
    # 修复Python虚拟环境权限
    fix_venv_permissions
    echo ""
    
    # 修复配置文件权限
    fix_config_permissions
    echo ""
    
    # 修复systemd服务文件权限
    fix_systemd_permissions
    echo ""
    
    # 修复CLI工具权限
    fix_cli_permissions
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
    
    log_success "🎉 权限修复完成！"
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
