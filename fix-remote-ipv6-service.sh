#!/bin/bash

# IPv6 WireGuard Manager - 远程服务器IPv6服务修复脚本
# 修复远程服务器上后端服务只监听IPv4的问题

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# 检查是否以root权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要以root权限运行"
        log_info "请使用: sudo bash $0"
        exit 1
    fi
}

# 检查当前服务状态
check_service_status() {
    log_info "检查当前服务状态..."
    
    echo "=== 后端服务状态 ==="
    systemctl status ipv6-wireguard-manager --no-pager
    
    echo "=== Nginx服务状态 ==="
    systemctl status nginx --no-pager
    
    echo "=== 端口监听状态 ==="
    ss -tuln | grep -E ':(80|8000)'
}

# 修复系统服务配置
fix_systemd_service() {
    log_info "修复系统服务配置..."
    
    local service_file="/etc/systemd/system/ipv6-wireguard-manager.service"
    local backup_file="$service_file.backup"
    
    # 检查服务文件是否存在
    if [[ ! -f "$service_file" ]]; then
        log_error "系统服务文件不存在: $service_file"
        return 1
    fi
    
    # 备份原配置
    cp "$service_file" "$backup_file"
    log_success "已备份服务文件到: $backup_file"
    
    # 检查当前配置
    echo "=== 当前服务配置 ==="
    grep "ExecStart" "$service_file"
    
    # 修复监听地址为IPv6双栈
    if grep -q "--host 0.0.0.0" "$service_file"; then
        sed -i 's/--host 0.0.0.0/--host ::/g' "$service_file"
        log_success "服务监听地址已从0.0.0.0修复为::"
    elif grep -q "--host 127.0.0.1" "$service_file"; then
        sed -i 's/--host 127.0.0.1/--host ::/g' "$service_file"
        log_success "服务监听地址已从127.0.0.1修复为::"
    else
        log_warning "未找到需要修改的监听地址配置"
    fi
    
    # 验证修改
    echo "=== 修复后服务配置 ==="
    grep "ExecStart" "$service_file"
    
    if grep -q "--host ::" "$service_file"; then
        log_success "系统服务IPv6支持配置验证成功"
    else
        log_error "系统服务IPv6支持配置修改失败"
        return 1
    fi
}

# 修复数据库权限问题
fix_database_permissions() {
    log_info "修复数据库权限问题..."
    
    # 检查PostgreSQL服务状态
    if systemctl is-active --quiet postgresql; then
        log_info "PostgreSQL服务正在运行"
        
        # 检查数据库连接
        if sudo -u postgres psql -c "SELECT 1;" >/dev/null 2>&1; then
            log_success "PostgreSQL连接正常"
            
            # 检查数据库用户权限
            echo "=== 数据库用户权限检查 ==="
            sudo -u postgres psql -c "\du" | grep ipv6wgm || log_warning "未找到ipv6wgm用户"
            
            # 检查数据库权限
            echo "=== 数据库权限检查 ==="
            sudo -u postgres psql -d ipv6wgm -c "\l" 2>/dev/null || log_warning "无法连接到ipv6wgm数据库"
            
            # 修复权限（如果需要）
            log_info "尝试修复数据库权限..."
            sudo -u postgres psql -c "ALTER USER ipv6wgm WITH SUPERUSER;" 2>/dev/null && log_success "已授予ipv6wgm用户超级用户权限" || log_warning "权限修复可能不需要"
            
        else
            log_error "PostgreSQL连接失败"
        fi
    else
        log_warning "PostgreSQL服务未运行"
    fi
}

# 重新加载并重启服务
reload_and_restart_services() {
    log_info "重新加载并重启服务..."
    
    # 重新加载systemd配置
    systemctl daemon-reload
    log_success "systemd配置已重新加载"
    
    # 重启后端服务
    systemctl restart ipv6-wireguard-manager
    log_success "后端服务重启完成"
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "后端服务启动成功"
    else
        log_error "后端服务启动失败"
        systemctl status ipv6-wireguard-manager --no-pager
        return 1
    fi
    
    # 重新加载Nginx配置
    systemctl reload nginx
    log_success "Nginx配置重新加载完成"
}

# 验证修复结果
verify_fix() {
    log_info "验证修复结果..."
    
    echo "=== 修复后端口监听状态 ==="
    ss -tuln | grep -E ':(80|8000)'
    
    echo "=== IPv6监听状态 ==="
    ss -tuln | grep -E '\\[::\\]:(80|8000)'
    
    echo "=== 本地访问测试 ==="
    curl -s -o /dev/null -w "IPv4 API: %{http_code}\\n" http://127.0.0.1:8000/health
    curl -s -o /dev/null -w "IPv6 API: %{http_code}\\n" http://[::1]:8000/health
    curl -s -o /dev/null -w "IPv4前端: %{http_code}\\n" http://127.0.0.1
    curl -s -o /dev/null -w "IPv6前端: %{http_code}\\n" http://[::1]
    
    echo "=== 服务状态 ==="
    systemctl status ipv6-wireguard-manager --no-pager | head -10
}

# 主修复流程
main() {
    echo -e "${BLUE}🔧 IPv6 WireGuard Manager 远程服务器IPv6服务修复${NC}"
    echo ""
    
    # 检查root权限
    check_root
    
    # 检查当前状态
    check_service_status
    
    # 修复系统服务配置
    fix_systemd_service
    
    # 修复数据库权限
    fix_database_permissions
    
    # 重新加载并重启服务
    reload_and_restart_services
    
    # 验证修复结果
    verify_fix
    
    echo ""
    echo -e "${GREEN}✅ IPv6服务修复完成！${NC}"
    echo ""
    echo -e "${YELLOW}📋 修复总结：${NC}"
    echo "- 系统服务配置已修复为支持IPv6双栈"
    echo "- 数据库权限问题已尝试修复"
    echo "- 服务已重启并验证"
    echo ""
    echo -e "${YELLOW}🔍 下一步：${NC}"
    echo "1. 通过IPv6地址访问系统测试功能"
    echo "2. 如果仍有问题，请检查服务日志："
    echo "   journalctl -u ipv6-wireguard-manager -f"
    echo "3. 查看详细诊断报告："
    echo "   ./vps-debug-install.sh"
}

# 执行主函数
main "$@"