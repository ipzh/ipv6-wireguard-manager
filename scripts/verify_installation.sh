#!/bin/bash

# IPv6 WireGuard Manager - 安装验证脚本
# 用于验证安装后的系统状态和功能

set -euo pipefail

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

# 检查服务状态
check_service_status() {
    log_info "检查服务状态..."
    
    local issues=0
    
    # 检查主服务
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "ipv6-wireguard-manager 服务运行正常"
    else
        log_error "ipv6-wireguard-manager 服务未运行"
        ((issues++))
    fi
    
    # 检查Nginx服务
    if systemctl is-active --quiet nginx; then
        log_success "Nginx 服务运行正常"
    else
        log_warning "Nginx 服务未运行"
        ((issues++))
    fi
    
    # 检查MySQL服务
    if systemctl is-active --quiet mysql || systemctl is-active --quiet mariadb; then
        log_success "数据库服务运行正常"
    else
        log_warning "数据库服务未运行"
        ((issues++))
    fi
    
    return $issues
}

# 检查端口监听
check_port_listening() {
    log_info "检查端口监听状态..."
    
    local issues=0
    
    # 检查API端口
    if netstat -tuln | grep -q ":8000 "; then
        log_success "API端口 8000 正在监听"
    else
        log_error "API端口 8000 未监听"
        ((issues++))
    fi
    
    # 检查Web端口
    if netstat -tuln | grep -q ":80 "; then
        log_success "Web端口 80 正在监听"
    else
        log_warning "Web端口 80 未监听"
        ((issues++))
    fi
    
    # 检查数据库端口
    if netstat -tuln | grep -q ":3306 "; then
        log_success "数据库端口 3306 正在监听"
    else
        log_warning "数据库端口 3306 未监听"
        ((issues++))
    fi
    
    return $issues
}

# 检查文件权限
check_file_permissions() {
    log_info "检查文件权限..."
    
    local issues=0
    
    # 检查安装目录权限
    if [[ -d "/opt/ipv6-wireguard-manager" ]]; then
        local perms=$(stat -c "%a" /opt/ipv6-wireguard-manager)
        if [[ "$perms" == "750" ]]; then
            log_success "安装目录权限正确 (750)"
        else
            log_warning "安装目录权限不正确: $perms (应为 750)"
            ((issues++))
        fi
    fi
    
    # 检查环境文件权限
    if [[ -f "/opt/ipv6-wireguard-manager/.env" ]]; then
        local perms=$(stat -c "%a" /opt/ipv6-wireguard-manager/.env)
        if [[ "$perms" == "600" ]]; then
            log_success "环境文件权限正确 (600)"
        else
            log_warning "环境文件权限不正确: $perms (应为 600)"
            ((issues++))
        fi
    fi
    
    # 检查前端目录权限
    if [[ -d "/var/www/html/ipv6wgm-frontend" ]]; then
        local perms=$(stat -c "%a" /var/www/html/ipv6wgm-frontend)
        if [[ "$perms" == "750" ]]; then
            log_success "前端目录权限正确 (750)"
        else
            log_warning "前端目录权限不正确: $perms (应为 750)"
            ((issues++))
        fi
    fi
    
    return $issues
}

# 检查API健康状态
check_api_health() {
    log_info "检查API健康状态..."
    
    local issues=0
    
    # 检查健康检查端点
    if curl -s -f http://localhost:8000/api/v1/health >/dev/null; then
        log_success "API健康检查通过"
    else
        log_error "API健康检查失败"
        ((issues++))
    fi
    
    # 检查API文档端点
    if curl -s -f http://localhost:8000/docs >/dev/null; then
        log_success "API文档可访问"
    else
        log_warning "API文档不可访问"
        ((issues++))
    fi
    
    return $issues
}

# 检查数据库连接
check_database_connection() {
    log_info "检查数据库连接..."
    
    local issues=0
    
    # 检查数据库连接
    if mysql -u ipv6wgm -p"${DB_PASSWORD:-}" -h localhost -e "SELECT 1;" >/dev/null 2>&1; then
        log_success "数据库连接正常"
    else
        log_error "数据库连接失败"
        ((issues++))
    fi
    
    # 检查数据库表
    if mysql -u ipv6wgm -p"${DB_PASSWORD:-}" -h localhost ipv6wgm -e "SHOW TABLES;" >/dev/null 2>&1; then
        log_success "数据库表存在"
    else
        log_error "数据库表不存在"
        ((issues++))
    fi
    
    return $issues
}

# 检查Web界面访问
check_web_interface() {
    log_info "检查Web界面访问..."
    
    local issues=0
    
    # 检查主页访问
    if curl -s -f http://localhost/ >/dev/null; then
        log_success "Web界面可访问"
    else
        log_error "Web界面不可访问"
        ((issues++))
    fi
    
    # 检查API代理
    if curl -s -f http://localhost/api/v1/health >/dev/null; then
        log_success "API代理工作正常"
    else
        log_warning "API代理可能有问题"
        ((issues++))
    fi
    
    return $issues
}

# 检查系统资源
check_system_resources() {
    log_info "检查系统资源..."
    
    local issues=0
    
    # 检查内存使用
    local mem_usage=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    if (( $(echo "$mem_usage < 90" | bc -l) )); then
        log_success "内存使用正常: ${mem_usage}%"
    else
        log_warning "内存使用过高: ${mem_usage}%"
        ((issues++))
    fi
    
    # 检查磁盘空间
    local disk_usage=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    if [[ $disk_usage -lt 90 ]]; then
        log_success "磁盘空间充足: ${disk_usage}%"
    else
        log_warning "磁盘空间不足: ${disk_usage}%"
        ((issues++))
    fi
    
    # 检查CPU负载
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    if (( $(echo "$load_avg < 2.0" | bc -l) )); then
        log_success "CPU负载正常: $load_avg"
    else
        log_warning "CPU负载过高: $load_avg"
        ((issues++))
    fi
    
    return $issues
}

# 检查日志文件
check_log_files() {
    log_info "检查日志文件..."
    
    local issues=0
    
    # 检查应用日志
    if [[ -f "/opt/ipv6-wireguard-manager/logs/app.log" ]]; then
        log_success "应用日志文件存在"
    else
        log_warning "应用日志文件不存在"
        ((issues++))
    fi
    
    # 检查错误日志
    if [[ -f "/opt/ipv6-wireguard-manager/logs/error.log" ]]; then
        log_success "错误日志文件存在"
    else
        log_warning "错误日志文件不存在"
        ((issues++))
    fi
    
    # 检查系统日志
    if journalctl -u ipv6-wireguard-manager --no-pager -n 1 >/dev/null 2>&1; then
        log_success "系统日志正常"
    else
        log_warning "系统日志可能有问题"
        ((issues++))
    fi
    
    return $issues
}

# 生成验证报告
generate_verification_report() {
    local total_issues=$1
    
    echo ""
    echo "=========================================="
    echo "安装验证报告"
    echo "=========================================="
    echo "验证时间: $(date)"
    echo "总问题数: $total_issues"
    echo ""
    
    if [[ $total_issues -eq 0 ]]; then
        log_success "所有检查通过！系统安装完整且运行正常。"
        echo ""
        echo "系统状态:"
        echo "- 所有服务运行正常"
        echo "- 端口监听正常"
        echo "- 文件权限正确"
        echo "- API健康检查通过"
        echo "- 数据库连接正常"
        echo "- Web界面可访问"
        echo "- 系统资源充足"
        echo "- 日志文件正常"
    else
        log_error "发现 $total_issues 个问题需要修复"
        echo ""
        echo "建议:"
        echo "1. 检查服务状态: systemctl status ipv6-wireguard-manager"
        echo "2. 查看服务日志: journalctl -u ipv6-wireguard-manager -f"
        echo "3. 检查配置文件: /opt/ipv6-wireguard-manager/.env"
        echo "4. 重新启动服务: systemctl restart ipv6-wireguard-manager"
    fi
    
    echo "=========================================="
}

# 主函数
main() {
    log_info "开始安装验证..."
    
    local total_issues=0
    
    # 检查服务状态
    if ! check_service_status; then
        ((total_issues++))
    fi
    
    # 检查端口监听
    if ! check_port_listening; then
        ((total_issues++))
    fi
    
    # 检查文件权限
    if ! check_file_permissions; then
        ((total_issues++))
    fi
    
    # 检查API健康状态
    if ! check_api_health; then
        ((total_issues++))
    fi
    
    # 检查数据库连接
    if ! check_database_connection; then
        ((total_issues++))
    fi
    
    # 检查Web界面访问
    if ! check_web_interface; then
        ((total_issues++))
    fi
    
    # 检查系统资源
    if ! check_system_resources; then
        ((total_issues++))
    fi
    
    # 检查日志文件
    if ! check_log_files; then
        ((total_issues++))
    fi
    
    # 生成验证报告
    generate_verification_report $total_issues
    
    if [[ $total_issues -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# 运行主函数
main "$@"
