#!/bin/bash

# IPv6 WireGuard Manager - API问题一键检查脚本
# 自动诊断和修复API相关问题

set -e
set -u
set -o pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# 全局变量
INSTALL_DIR="/opt/ipv6-wireguard-manager"
FRONTEND_DIR="/var/www/html"
API_PORT="8000"
WEB_PORT="80"

# 检查系统服务状态
check_system_services() {
    log_step "检查系统服务状态..."
    
    # 检查Nginx
    if systemctl is-active --quiet nginx; then
        log_success "✓ Nginx服务正常运行"
    else
        log_error "✗ Nginx服务未运行"
        return 1
    fi
    
    # 检查PHP-FPM
    local php_fpm_service=""
    if systemctl list-units --type=service | grep -q "php8.1-fpm"; then
        php_fpm_service="php8.1-fpm"
    elif systemctl list-units --type=service | grep -q "php8.2-fpm"; then
        php_fpm_service="php8.2-fpm"
    elif systemctl list-units --type=service | grep -q "php-fpm"; then
        php_fpm_service="php-fpm"
    fi
    
    if [[ -n "$php_fpm_service" ]]; then
        if systemctl is-active --quiet "$php_fpm_service"; then
            log_success "✓ PHP-FPM服务正常运行 ($php_fpm_service)"
        else
            log_error "✗ PHP-FPM服务未运行 ($php_fpm_service)"
            return 1
        fi
    else
        log_error "✗ 未找到PHP-FPM服务"
        return 1
    fi
    
    # 检查MySQL/MariaDB
    if systemctl is-active --quiet mysql || systemctl is-active --quiet mariadb; then
        log_success "✓ 数据库服务正常运行"
    else
        log_error "✗ 数据库服务未运行"
        return 1
    fi
    
    return 0
}

# 检查端口监听
check_ports() {
    log_step "检查端口监听状态..."
    
    # 检查Web端口
    if ss -tlnp | grep -q ":$WEB_PORT "; then
        log_success "✓ Web端口 $WEB_PORT 正常监听"
    else
        log_error "✗ Web端口 $WEB_PORT 未监听"
        return 1
    fi
    
    # 检查API端口
    if ss -tlnp | grep -q ":$API_PORT "; then
        log_success "✓ API端口 $API_PORT 正常监听"
    else
        log_error "✗ API端口 $API_PORT 未监听"
        return 1
    fi
    
    return 0
}

# 检查后端API服务
check_backend_api() {
    log_step "检查后端API服务..."
    
    # 检查服务状态
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "✓ 后端服务状态正常"
    else
        log_error "✗ 后端服务未运行"
        return 1
    fi
    
    # 检查服务日志
    log_info "检查后端服务日志..."
    local recent_errors=$(journalctl -u ipv6-wireguard-manager --no-pager -l -n 20 | grep -i "error\|failed\|exception" | wc -l)
    if [[ $recent_errors -gt 0 ]]; then
        log_warning "发现 $recent_errors 个最近的错误日志"
        log_info "最近的错误日志："
        journalctl -u ipv6-wireguard-manager --no-pager -l -n 10 | grep -i "error\|failed\|exception" | tail -5
    else
        log_success "✓ 后端服务日志正常"
    fi
    
    return 0
}

# 测试API连接
test_api_connection() {
    log_step "测试API连接..."
    
    # 测试健康检查端点
    local health_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$API_PORT/health 2>/dev/null || echo "000")
    if [[ "$health_response" == "200" ]]; then
        log_success "✓ API健康检查正常 (HTTP $health_response)"
    else
        log_error "✗ API健康检查失败 (HTTP $health_response)"
        return 1
    fi
    
    # 测试API状态端点
    local status_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$API_PORT/api/v1/health 2>/dev/null || echo "000")
    if [[ "$status_response" == "200" ]]; then
        log_success "✓ API状态检查正常 (HTTP $status_response)"
    else
        log_warning "⚠ API状态检查异常 (HTTP $status_response)"
    fi
    
    return 0
}

# 测试Web服务
test_web_service() {
    log_step "测试Web服务..."
    
    local web_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$WEB_PORT/ 2>/dev/null || echo "000")
    if [[ "$web_response" == "200" ]]; then
        log_success "✓ Web服务正常 (HTTP $web_response)"
    elif [[ "$web_response" == "500" ]]; then
        log_error "✗ Web服务返回500错误"
        return 1
    else
        log_warning "⚠ Web服务异常 (HTTP $web_response)"
        return 1
    fi
    
    return 0
}

# 检查Python依赖
check_python_dependencies() {
    log_step "检查Python依赖..."
    
    if [[ ! -d "$INSTALL_DIR" ]]; then
        log_error "✗ 安装目录不存在: $INSTALL_DIR"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    
    # 检查虚拟环境
    if [[ ! -d "venv" ]]; then
        log_error "✗ Python虚拟环境不存在"
        return 1
    fi
    
    # 激活虚拟环境并检查关键依赖
    source venv/bin/activate
    
    # 检查passlib
    if python -c "import passlib; print('passlib version:', passlib.__version__)" 2>/dev/null; then
        log_success "✓ passlib库正常"
    else
        log_error "✗ passlib库有问题"
        return 1
    fi
    
    # 检查argon2
    if python -c "import argon2; print('argon2 available')" 2>/dev/null; then
        log_success "✓ argon2库正常"
    else
        log_error "✗ argon2库有问题"
        return 1
    fi
    
    # 检查其他关键依赖
    local critical_deps=("fastapi" "uvicorn" "sqlalchemy" "pymysql" "jose")
    for dep in "${critical_deps[@]}"; do
        if python -c "import $dep" 2>/dev/null; then
            log_success "✓ $dep 库正常"
        else
            log_error "✗ $dep 库有问题"
            return 1
        fi
    done
    
    return 0
}

# 检查数据库连接
check_database_connection() {
    log_step "检查数据库连接..."
    
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
    # 测试数据库连接
    if python -c "
import asyncio
from app.core.database import get_db
from app.core.config_enhanced import settings

async def test_db():
    try:
        async with get_db() as db:
            result = await db.execute('SELECT 1')
            print('Database connection successful')
            return True
    except Exception as e:
        print(f'Database connection failed: {e}')
        return False

asyncio.run(test_db())
" 2>/dev/null; then
        log_success "✓ 数据库连接正常"
    else
        log_error "✗ 数据库连接失败"
        return 1
    fi
    
    return 0
}

# 检查文件权限
check_file_permissions() {
    log_step "检查文件权限..."
    
    # 检查后端目录权限
    if [[ -d "$INSTALL_DIR" ]]; then
        local backend_owner=$(stat -c '%U:%G' "$INSTALL_DIR" 2>/dev/null || echo "unknown")
        if [[ "$backend_owner" == "ipv6wgm:ipv6wgm" ]]; then
            log_success "✓ 后端目录权限正确 ($backend_owner)"
        else
            log_warning "⚠ 后端目录权限异常 ($backend_owner)"
        fi
    fi
    
    # 检查前端目录权限
    if [[ -d "$FRONTEND_DIR" ]]; then
        local frontend_owner=$(stat -c '%U:%G' "$FRONTEND_DIR" 2>/dev/null || echo "unknown")
        if [[ "$frontend_owner" == "www-data:www-data" ]]; then
            log_success "✓ 前端目录权限正确 ($frontend_owner)"
        else
            log_warning "⚠ 前端目录权限异常 ($frontend_owner)"
        fi
    fi
    
    return 0
}

# 自动修复常见问题
auto_fix_issues() {
    log_step "尝试自动修复问题..."
    
    # 修复passlib兼容性问题
    log_info "检查并修复passlib兼容性问题..."
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
    # 升级passlib和argon2
    pip install --upgrade passlib[argon2] argon2-cffi 2>/dev/null || {
        log_warning "passlib升级失败，尝试重新安装..."
        pip uninstall -y passlib argon2-cffi 2>/dev/null || true
        pip install passlib[argon2] argon2-cffi
    }
    
    # 重启后端服务
    log_info "重启后端服务..."
    systemctl restart ipv6-wireguard-manager
    sleep 3
    
    # 检查服务是否正常启动
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "✓ 后端服务重启成功"
    else
        log_error "✗ 后端服务重启失败"
        return 1
    fi
    
    return 0
}

# 生成诊断报告
generate_report() {
    log_step "生成诊断报告..."
    
    local report_file="/tmp/api_diagnosis_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "IPv6 WireGuard Manager - API诊断报告"
        echo "生成时间: $(date)"
        echo "=================================="
        echo
        
        echo "系统信息:"
        echo "- 操作系统: $(lsb_release -d 2>/dev/null | cut -f2 || uname -a)"
        echo "- 内存使用: $(free -h | grep Mem | awk '{print $3"/"$2}')"
        echo "- 磁盘使用: $(df -h / | tail -1 | awk '{print $3"/"$2" ("$5")"}')"
        echo
        
        echo "服务状态:"
        systemctl status nginx --no-pager -l | head -3
        systemctl status ipv6-wireguard-manager --no-pager -l | head -3
        echo
        
        echo "端口监听:"
        ss -tlnp | grep -E ":(80|8000) "
        echo
        
        echo "最近错误日志:"
        journalctl -u ipv6-wireguard-manager --no-pager -l -n 10 | grep -i "error\|failed\|exception" || echo "无错误日志"
        
    } > "$report_file"
    
    log_success "诊断报告已生成: $report_file"
    return 0
}

# 主函数
main() {
    echo "=================================="
    echo "IPv6 WireGuard Manager - API问题检查"
    echo "=================================="
    echo
    
    local issues_found=0
    
    # 执行各项检查
    check_system_services || ((issues_found++))
    echo
    
    check_ports || ((issues_found++))
    echo
    
    check_backend_api || ((issues_found++))
    echo
    
    test_api_connection || ((issues_found++))
    echo
    
    test_web_service || ((issues_found++))
    echo
    
    check_python_dependencies || ((issues_found++))
    echo
    
    check_database_connection || ((issues_found++))
    echo
    
    check_file_permissions || ((issues_found++))
    echo
    
    # 生成报告
    generate_report
    echo
    
    # 总结
    if [[ $issues_found -eq 0 ]]; then
        log_success "🎉 所有检查通过！API服务运行正常。"
        exit 0
    else
        log_warning "⚠ 发现 $issues_found 个问题，尝试自动修复..."
        echo
        
        if auto_fix_issues; then
            log_success "🔧 自动修复完成，请重新运行检查脚本验证"
        else
            log_error "❌ 自动修复失败，请手动检查上述问题"
        fi
        
        exit 1
    fi
}

# 运行主函数
main "$@"
