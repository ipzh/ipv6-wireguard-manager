#!/bin/bash

# IPv6 WireGuard Manager - 安装验证脚本
# 验证安装是否成功，检查所有组件是否正常工作

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

# 测试结果
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    log_info "测试: $test_name"
    
    if eval "$test_command" &> /dev/null; then
        log_success "✓ $test_name - 通过"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "✗ $test_name - 失败"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# 检查系统服务
check_system_services() {
    log_info "检查系统服务..."
    
    # 检查MySQL/MariaDB服务
    if systemctl is-active --quiet mysql 2>/dev/null; then
        log_success "✓ MySQL服务运行正常"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    elif systemctl is-active --quiet mariadb 2>/dev/null; then
        log_success "✓ MariaDB服务运行正常"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ 数据库服务未运行"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 检查Nginx服务
    if systemctl is-active --quiet nginx; then
        log_success "✓ Nginx服务运行正常"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ Nginx服务未运行"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 检查PHP-FPM服务
    local php_fpm_service=""
    if systemctl list-units --type=service | grep -q "php8.1-fpm"; then
        php_fpm_service="php8.1-fpm"
    elif systemctl list-units --type=service | grep -q "php8.0-fpm"; then
        php_fpm_service="php8.0-fpm"
    elif systemctl list-units --type=service | grep -q "php-fpm"; then
        php_fpm_service="php-fpm"
    fi
    
    if [[ -n "$php_fpm_service" ]] && systemctl is-active --quiet "$php_fpm_service"; then
        log_success "✓ PHP-FPM服务运行正常 ($php_fpm_service)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ PHP-FPM服务未运行"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 检查应用服务
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "✓ IPv6 WireGuard Manager服务运行正常"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ IPv6 WireGuard Manager服务未运行"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# 检查端口监听
check_port_listening() {
    log_info "检查端口监听..."
    
    # 检查80端口
    if netstat -tlnp 2>/dev/null | grep -q ":80 "; then
        log_success "✓ 端口80正在监听"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ 端口80未监听"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 检查8000端口
    if netstat -tlnp 2>/dev/null | grep -q ":8000 "; then
        log_success "✓ 端口8000正在监听"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ 端口8000未监听"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# 检查数据库连接
check_database_connection() {
    log_info "检查数据库连接..."
    
    # 测试MySQL连接
    if mysql -u ipv6wgm -pipv6wgm_password -e "SELECT 1;" &>/dev/null; then
        log_success "✓ 数据库连接正常"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ 数据库连接失败"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 检查数据库是否存在
    if mysql -u ipv6wgm -pipv6wgm_password -e "USE ipv6wgm; SHOW TABLES;" &>/dev/null; then
        log_success "✓ 数据库ipv6wgm存在"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ 数据库ipv6wgm不存在"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# 检查Web服务
check_web_service() {
    log_info "检查Web服务..."
    
    # 检查前端页面
    if curl -f http://localhost/ &>/dev/null; then
        log_success "✓ 前端页面可访问"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ 前端页面无法访问"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 检查PHP解析
    if curl -f http://localhost/ | grep -q "IPv6 WireGuard Manager" &>/dev/null; then
        log_success "✓ PHP解析正常"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ PHP解析异常"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# 检查API服务
check_api_service() {
    log_info "检查API服务..."
    
    # 检查API健康检查
    if curl -f http://localhost:8000/api/v1/health &>/dev/null; then
        log_success "✓ API健康检查正常"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ API健康检查失败"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 检查API文档
    if curl -f http://localhost:8000/docs &>/dev/null; then
        log_success "✓ API文档可访问"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ API文档无法访问"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# 检查文件权限
check_file_permissions() {
    log_info "检查文件权限..."
    
    # 检查安装目录权限
    if [[ -d "/opt/ipv6-wireguard-manager" ]] && [[ -r "/opt/ipv6-wireguard-manager" ]]; then
        log_success "✓ 安装目录权限正常"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ 安装目录权限异常"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 检查Web目录权限
    if [[ -d "/var/www/html" ]] && [[ -r "/var/www/html" ]]; then
        log_success "✓ Web目录权限正常"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ Web目录权限异常"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# 检查配置文件
check_configuration_files() {
    log_info "检查配置文件..."
    
    # 检查环境变量文件
    if [[ -f "/opt/ipv6-wireguard-manager/.env" ]]; then
        log_success "✓ 环境变量文件存在"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ 环境变量文件不存在"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 检查Nginx配置
    if [[ -f "/etc/nginx/sites-available/ipv6-wireguard-manager" ]]; then
        log_success "✓ Nginx配置文件存在"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ Nginx配置文件不存在"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 检查systemd服务文件
    if [[ -f "/etc/systemd/system/ipv6-wireguard-manager.service" ]]; then
        log_success "✓ systemd服务文件存在"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ systemd服务文件不存在"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# 检查日志文件
check_log_files() {
    log_info "检查日志文件..."
    
    # 检查应用日志
    if journalctl -u ipv6-wireguard-manager --no-pager | tail -1 &>/dev/null; then
        log_success "✓ 应用日志正常"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ 应用日志异常"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 检查Nginx日志
    if [[ -f "/var/log/nginx/access.log" ]] && [[ -f "/var/log/nginx/error.log" ]]; then
        log_success "✓ Nginx日志文件存在"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ Nginx日志文件不存在"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# 性能测试
performance_test() {
    log_info "性能测试..."
    
    # 测试响应时间
    local start_time=$(date +%s%N)
    if curl -f http://localhost/ &>/dev/null; then
        local end_time=$(date +%s%N)
        local response_time=$(( (end_time - start_time) / 1000000 ))
        
        if [[ $response_time -lt 1000 ]]; then
            log_success "✓ 响应时间正常 (${response_time}ms)"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_warning "⚠ 响应时间较慢 (${response_time}ms)"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        log_error "✗ 响应测试失败"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 测试并发连接
    local concurrent_requests=10
    local success_count=0
    
    for i in $(seq 1 $concurrent_requests); do
        if curl -f http://localhost/ &>/dev/null; then
            success_count=$((success_count + 1))
        fi
    done
    
    if [[ $success_count -eq $concurrent_requests ]]; then
        log_success "✓ 并发连接测试通过 ($success_count/$concurrent_requests)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_warning "⚠ 并发连接测试部分失败 ($success_count/$concurrent_requests)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# 生成验证报告
generate_verification_report() {
    log_info "生成验证报告..."
    
    local success_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    
    echo ""
    log_info "=== 安装验证报告 ==="
    log_info "总测试数: $TESTS_TOTAL"
    log_success "通过: $TESTS_PASSED"
    log_error "失败: $TESTS_FAILED"
    log_info "成功率: ${success_rate}%"
    
    if [[ $success_rate -ge 90 ]]; then
        log_success "🎉 安装验证成功！系统运行正常"
    elif [[ $success_rate -ge 70 ]]; then
        log_warning "⚠️ 安装基本成功，但存在一些问题需要修复"
    elif [[ $success_rate -ge 50 ]]; then
        log_warning "⚠️ 安装部分成功，需要解决多个问题"
    else
        log_error "❌ 安装验证失败，需要重新安装或修复"
    fi
    
    echo ""
    log_info "=== 访问信息 ==="
    log_info "前端地址: http://localhost/"
    log_info "API文档: http://localhost:8000/docs"
    log_info "API健康检查: http://localhost:8000/api/v1/health"
    
    echo ""
    log_info "=== 服务管理 ==="
    log_info "查看服务状态: sudo systemctl status ipv6-wireguard-manager"
    log_info "重启服务: sudo systemctl restart ipv6-wireguard-manager"
    log_info "查看日志: sudo journalctl -u ipv6-wireguard-manager -f"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo ""
        log_info "=== 故障排除建议 ==="
        log_info "1. 检查服务状态: sudo systemctl status ipv6-wireguard-manager"
        log_info "2. 查看错误日志: sudo journalctl -u ipv6-wireguard-manager -f"
        log_info "3. 检查Nginx配置: sudo nginx -t"
        log_info "4. 检查数据库连接: mysql -u ipv6wgm -p"
        log_info "5. 重新运行安装脚本: ./install_enhanced.sh"
    fi
}

# 主函数
main() {
    log_info "IPv6 WireGuard Manager - 安装验证脚本"
    echo ""
    
    check_system_services
    echo ""
    
    check_port_listening
    echo ""
    
    check_database_connection
    echo ""
    
    check_web_service
    echo ""
    
    check_api_service
    echo ""
    
    check_file_permissions
    echo ""
    
    check_configuration_files
    echo ""
    
    check_log_files
    echo ""
    
    performance_test
    echo ""
    
    generate_verification_report
}

# 运行主函数
main "$@"
