#!/bin/bash

# IPv6 WireGuard Manager - IPv6支持修复脚本
# 修复服务只监听IPv4而不监听IPv6的问题

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

# 检查当前监听状态
check_listening_status() {
    log_info "检查当前端口监听状态..."
    
    echo "=== 端口80监听状态 ==="
    ss -tlnp | grep -E ':(80)' || echo "端口80未监听"
    
    echo "=== 端口8000监听状态 ==="
    ss -tlnp | grep -E ':(8000)' || echo "端口8000未监听"
    
    echo "=== 所有监听端口 ==="
    ss -tlnp
}

# 修复后端服务IPv6支持
fix_backend_ipv6() {
    log_info "修复后端服务IPv6支持..."
    
    local config_file="/opt/ipv6-wireguard-manager/backend/app/core/config.py"
    local backup_file="$config_file.backup"
    
    # 检查配置文件是否存在
    if [[ ! -f "$config_file" ]]; then
        log_error "后端配置文件不存在: $config_file"
        return 1
    fi
    
    # 备份原配置
    cp "$config_file" "$backup_file"
    log_info "已备份配置文件到: $backup_file"
    
    # 修改SERVER_HOST为"::"以支持IPv4和IPv6
    if grep -q 'SERVER_HOST: str = "0.0.0.0"' "$config_file"; then
        sed -i 's/SERVER_HOST: str = "0.0.0.0"/SERVER_HOST: str = "::"/' "$config_file"
        log_success "后端服务配置已更新为支持IPv6"
    else
        log_warning "后端服务配置未找到需要修改的内容，可能已支持IPv6"
    fi
    
    # 验证修改
    if grep -q 'SERVER_HOST: str = "::"' "$config_file"; then
        log_success "后端服务IPv6支持配置验证成功"
    else
        log_error "后端服务IPv6支持配置修改失败"
        return 1
    fi
}

# 修复Nginx IPv6支持
fix_nginx_ipv6() {
    log_info "修复Nginx IPv6支持..."
    
    local nginx_config="/etc/nginx/sites-available/ipv6-wireguard-manager"
    
    # 检查Nginx配置文件是否存在
    if [[ ! -f "$nginx_config" ]]; then
        log_error "Nginx配置文件不存在: $nginx_config"
        return 1
    fi
    
    # 备份原配置
    cp "$nginx_config" "$nginx_config.backup"
    log_info "已备份Nginx配置到: $nginx_config.backup"
    
    # 检查是否已配置IPv6监听
    if grep -q 'listen \[::\]:80;' "$nginx_config"; then
        log_info "Nginx已配置IPv6监听"
    else
        # 添加IPv6监听配置
        if grep -q 'listen 80;' "$nginx_config"; then
            sed -i '/listen 80;/a\\tlisten [::]:80;' "$nginx_config"
            log_success "Nginx IPv6监听配置已添加"
        else
            log_error "未找到Nginx监听配置"
            return 1
        fi
    fi
    
    # 检查server_name配置，确保支持IPv6访问
    if ! grep -q 'server_name _;' "$nginx_config"; then
        # 添加默认server_name配置
        sed -i '/listen 80;/i\\tserver_name _;' "$nginx_config"
        log_success "已添加默认server_name配置"
    fi
    
    # 验证配置
    nginx -t
    if [[ $? -eq 0 ]]; then
        log_success "Nginx配置验证成功"
    else
        log_error "Nginx配置验证失败"
        return 1
    fi
}

# 重启服务
restart_services() {
    log_info "重启服务以应用配置更改..."
    
    # 重启后端服务
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        systemctl restart ipv6-wireguard-manager
        log_success "后端服务重启完成"
    else
        log_warning "后端服务未运行，跳过重启"
    fi
    
    # 重新加载Nginx配置
    if systemctl is-active --quiet nginx; then
        systemctl reload nginx
        log_success "Nginx配置重新加载完成"
    else
        log_warning "Nginx服务未运行，跳过重启"
    fi
    
    # 等待服务启动
    sleep 5
}

# 检查防火墙配置
check_firewall() {
    log_info "检查防火墙配置..."
    
    # 检查ufw状态
    if command -v ufw >/dev/null 2>&1; then
        ufw status | grep -q "Status: active"
        if [[ $? -eq 0 ]]; then
            log_info "UFW防火墙已启用"
            
            # 检查端口是否开放
            if ufw status | grep -q "80/tcp"; then
                log_info "端口80已开放"
            else
                log_warning "端口80未在防火墙中开放"
                log_info "如需开放，请执行: ufw allow 80/tcp"
            fi
            
            if ufw status | grep -q "8000/tcp"; then
                log_info "端口8000已开放"
            else
                log_warning "端口8000未在防火墙中开放"
                log_info "如需开放，请执行: ufw allow 8000/tcp"
            fi
        else
            log_info "UFW防火墙未启用"
        fi
    else
        log_info "UFW防火墙未安装"
    fi
    
    # 检查iptables规则
    if iptables -L 2>/dev/null | grep -q "tcp dpt:80"; then
        log_info "iptables中端口80已配置"
    else
        log_warning "iptables中端口80未配置"
    fi
    
    if iptables -L 2>/dev/null | grep -q "tcp dpt:8000"; then
        log_info "iptables中端口8000已配置"
    else
        log_warning "iptables中端口8000未配置"
    fi
}

# 验证修复结果
verify_fix() {
    log_info "验证IPv6支持修复结果..."
    
    echo "=== 修复后端口监听状态 ==="
    
    # 检查端口80监听
    echo "端口80监听状态:"
    if ss -tlnp | grep -E ':(80)' | grep -q ":::"; then
        log_success "端口80已支持IPv6监听"
    else
        log_warning "端口80未监听IPv6地址"
    fi
    
    # 检查端口8000监听
    echo "端口8000监听状态:"
    if ss -tlnp | grep -E ':(8000)' | grep -q ":::"; then
        log_success "端口8000已支持IPv6监听"
    else
        log_warning "端口8000未监听IPv6地址"
    fi
    
    # 测试本地访问
    echo "=== 本地访问测试 ==="
    
    # 测试IPv4访问
    if curl -f -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/health 2>/dev/null | grep -q "200"; then
        log_success "IPv4本地API访问正常"
    else
        log_error "IPv4本地API访问失败"
    fi
    
    # 测试IPv6本地访问
    if curl -f -s -o /dev/null -w "%{http_code}" http://[::1]:8000/health 2>/dev/null | grep -q "200"; then
        log_success "IPv6本地API访问正常"
    else
        log_warning "IPv6本地API访问失败（可能是IPv6配置问题）"
    fi
    
    # 测试Nginx访问
    if curl -f -s -o /dev/null -w "%{http_code}" http://127.0.0.1 2>/dev/null | grep -q "200"; then
        log_success "IPv4本地前端访问正常"
    else
        log_error "IPv4本地前端访问失败"
    fi
    
    # 获取服务器IP地址信息
    echo "=== 服务器网络信息 ==="
    ip addr show | grep -E "(inet |inet6 )" | grep -v "127.0.0.1" | grep -v "::1"
}

# 显示使用说明
show_usage() {
    echo "IPv6 WireGuard Manager - IPv6支持修复脚本"
    echo ""
    echo "使用方法:"
    echo "  sudo bash $0"
    echo ""
    echo "功能:"
    echo "  1. 修复后端服务支持IPv6监听"
    echo "  2. 修复Nginx支持IPv6监听"
    echo "  3. 检查防火墙配置"
    echo "  4. 验证修复结果"
    echo ""
    echo "注意: 此脚本需要root权限运行"
}

# 主函数
main() {
    echo "========================================"
    echo "IPv6 WireGuard Manager - IPv6支持修复"
    echo "========================================"
    
    # 检查参数
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
    # 检查root权限
    check_root
    
    # 显示当前状态
    check_listening_status
    
    # 修复配置
    fix_backend_ipv6
    fix_nginx_ipv6
    
    # 重启服务
    restart_services
    
    # 检查防火墙
    check_firewall
    
    # 验证修复结果
    verify_fix
    
    echo ""
    log_success "IPv6支持修复完成！"
    echo ""
    echo "下一步操作:"
    echo "1. 使用浏览器访问 http://您的服务器IPv4地址"
    echo "2. 如果服务器有IPv6地址，也可以访问 http://[IPv6地址]"
    echo "3. 如果仍有问题，请检查服务器防火墙和网络配置"
    echo ""
}

# 运行主函数
main "$@"