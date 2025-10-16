#!/bin/bash

# IPv6 WireGuard Manager - Debian 12环境修复脚本
# 修复Debian 12上的环境问题：移除Apache，安装PHP-FPM

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

log_section() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

log_info "IPv6 WireGuard Manager - Debian 12环境修复"
echo ""

# 检查系统版本
check_system() {
    log_section "检查系统版本"
    if [[ -f /etc/debian_version ]]; then
        local debian_version=$(cat /etc/debian_version)
        log_info "Debian版本: $debian_version"
        if [[ "$debian_version" == "12"* ]]; then
            log_success "✓ 确认是Debian 12系统"
        else
            log_warning "⚠ 不是Debian 12系统，但继续执行修复"
        fi
    else
        log_error "✗ 无法确定Debian版本"
        exit 1
    fi
    echo ""
}

# 检查当前安装的软件
check_current_software() {
    log_section "检查当前安装的软件"
    
    # 检查Apache
    if command -v apache2 &>/dev/null; then
        log_warning "⚠ 检测到Apache2已安装"
        systemctl status apache2 --no-pager -l | head -5
    elif command -v httpd &>/dev/null; then
        log_warning "⚠ 检测到httpd已安装"
        systemctl status httpd --no-pager -l | head -5
    else
        log_success "✓ 未检测到Apache"
    fi
    
    # 检查Nginx
    if command -v nginx &>/dev/null; then
        log_success "✓ Nginx已安装"
        systemctl status nginx --no-pager -l | head -5
    else
        log_warning "⚠ Nginx未安装"
    fi
    
    # 检查PHP-FPM
    if command -v php-fpm &>/dev/null; then
        log_success "✓ PHP-FPM已安装"
    elif systemctl list-unit-files | grep -q php.*fpm; then
        local php_fpm_service=$(systemctl list-unit-files | grep php.*fpm | head -1 | awk '{print $1}')
        log_info "✓ 发现PHP-FPM服务: $php_fpm_service"
    else
        log_warning "⚠ PHP-FPM未安装"
    fi
    
    echo ""
}

# 停止Apache服务
stop_apache() {
    log_section "停止Apache服务"
    
    # 停止Apache2 (Debian/Ubuntu)
    if systemctl is-active --quiet apache2; then
        log_info "停止Apache2服务..."
        systemctl stop apache2
        systemctl disable apache2
        log_success "✓ Apache2服务已停止并禁用"
    fi
    
    # 停止httpd (CentOS/RHEL)
    if systemctl is-active --quiet httpd; then
        log_info "停止httpd服务..."
        systemctl stop httpd
        systemctl disable httpd
        log_success "✓ httpd服务已停止并禁用"
    fi
    
    echo ""
}

# 卸载Apache
uninstall_apache() {
    log_section "卸载Apache"
    
    # 卸载Apache2 (Debian/Ubuntu)
    if command -v apache2 &>/dev/null; then
        log_info "卸载Apache2..."
        apt-get remove --purge -y apache2 apache2-utils apache2-bin apache2-data
        apt-get autoremove -y
        log_success "✓ Apache2已卸载"
    fi
    
    # 卸载httpd (CentOS/RHEL)
    if command -v httpd &>/dev/null; then
        log_info "卸载httpd..."
        yum remove -y httpd httpd-tools 2>/dev/null || dnf remove -y httpd httpd-tools 2>/dev/null || true
        log_success "✓ httpd已卸载"
    fi
    
    echo ""
}

# 安装PHP-FPM
install_php_fpm() {
    log_section "安装PHP-FPM"
    
    # 更新包列表
    log_info "更新包列表..."
    apt-get update
    
    # 检查PHP版本
    if command -v php &>/dev/null; then
        local php_version=$(php --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
        log_info "检测到PHP版本: $php_version"
        
        # 安装对应版本的PHP-FPM
        if [[ "$php_version" == "8.2"* ]]; then
            log_info "安装PHP 8.2-FPM..."
            apt-get install -y php8.2-fpm
        elif [[ "$php_version" == "8.1"* ]]; then
            log_info "安装PHP 8.1-FPM..."
            apt-get install -y php8.1-fpm
        elif [[ "$php_version" == "8.0"* ]]; then
            log_info "安装PHP 8.0-FPM..."
            apt-get install -y php8.0-fpm
        else
            log_info "安装默认PHP-FPM..."
            apt-get install -y php-fpm
        fi
    else
        log_info "PHP未安装，安装PHP 8.2和PHP-FPM..."
        apt-get install -y php8.2 php8.2-fpm php8.2-cli php8.2-curl php8.2-json php8.2-mbstring php8.2-mysql php8.2-xml php8.2-zip
    fi
    
    log_success "✓ PHP-FPM安装完成"
    echo ""
}

# 配置PHP-FPM
configure_php_fpm() {
    log_section "配置PHP-FPM"
    
    # 启动并启用PHP-FPM服务
    local php_fpm_service=""
    
    # 检测PHP-FPM服务名
    if systemctl list-unit-files | grep -q php8.2-fpm; then
        php_fpm_service="php8.2-fpm"
    elif systemctl list-unit-files | grep -q php8.1-fpm; then
        php_fpm_service="php8.1-fpm"
    elif systemctl list-unit-files | grep -q php8.0-fpm; then
        php_fpm_service="php8.0-fpm"
    elif systemctl list-unit-files | grep -q php-fpm; then
        php_fpm_service="php-fpm"
    fi
    
    if [[ -n "$php_fpm_service" ]]; then
        log_info "启动PHP-FPM服务: $php_fpm_service"
        systemctl start "$php_fpm_service"
        systemctl enable "$php_fpm_service"
        
        if systemctl is-active --quiet "$php_fpm_service"; then
            log_success "✓ PHP-FPM服务启动成功"
        else
            log_error "✗ PHP-FPM服务启动失败"
            return 1
        fi
    else
        log_error "✗ 未找到PHP-FPM服务"
        return 1
    fi
    
    echo ""
}

# 确保Nginx正常运行
ensure_nginx_running() {
    log_section "确保Nginx正常运行"
    
    if command -v nginx &>/dev/null; then
        # 启动Nginx
        systemctl start nginx
        systemctl enable nginx
        
        if systemctl is-active --quiet nginx; then
            log_success "✓ Nginx服务运行正常"
        else
            log_error "✗ Nginx服务启动失败"
            return 1
        fi
        
        # 测试Nginx配置
        if nginx -t; then
            log_success "✓ Nginx配置正确"
        else
            log_error "✗ Nginx配置错误"
            return 1
        fi
    else
        log_warning "⚠ Nginx未安装，尝试安装..."
        apt-get install -y nginx
        systemctl start nginx
        systemctl enable nginx
    fi
    
    echo ""
}

# 检查端口冲突
check_port_conflicts() {
    log_section "检查端口冲突"
    
    # 检查80端口
    if netstat -tlnp 2>/dev/null | grep ":80 " &>/dev/null; then
        local port80_process=$(netstat -tlnp 2>/dev/null | grep ":80 " | awk '{print $7}' | cut -d'/' -f1)
        if [[ "$port80_process" == *"nginx"* ]]; then
            log_success "✓ 端口80被Nginx占用（正确）"
        elif [[ "$port80_process" == *"apache"* ]] || [[ "$port80_process" == *"httpd"* ]]; then
            log_error "✗ 端口80仍被Apache占用"
            return 1
        else
            log_warning "⚠ 端口80被其他进程占用: $port80_process"
        fi
    else
        log_warning "⚠ 端口80未被占用"
    fi
    
    echo ""
}

# 验证修复结果
verify_fix() {
    log_section "验证修复结果"
    
    # 检查Apache是否完全移除
    if ! command -v apache2 &>/dev/null && ! command -v httpd &>/dev/null; then
        log_success "✓ Apache已完全移除"
    else
        log_warning "⚠ Apache仍然存在"
    fi
    
    # 检查Nginx是否运行
    if systemctl is-active --quiet nginx; then
        log_success "✓ Nginx正在运行"
    else
        log_error "✗ Nginx未运行"
    fi
    
    # 检查PHP-FPM是否运行
    local php_fpm_running=false
    if systemctl is-active --quiet php8.2-fpm || systemctl is-active --quiet php8.1-fpm || systemctl is-active --quiet php8.0-fpm || systemctl is-active --quiet php-fpm; then
        log_success "✓ PHP-FPM正在运行"
        php_fpm_running=true
    else
        log_error "✗ PHP-FPM未运行"
    fi
    
    # 检查端口
    if netstat -tlnp 2>/dev/null | grep ":80 " &>/dev/null; then
        local port80_process=$(netstat -tlnp 2>/dev/null | grep ":80 " | awk '{print $7}')
        if [[ "$port80_process" == *"nginx"* ]]; then
            log_success "✓ 端口80被Nginx正确占用"
        else
            log_warning "⚠ 端口80被其他进程占用: $port80_process"
        fi
    fi
    
    echo ""
    
    if [[ "$php_fpm_running" == true ]]; then
        log_success "🎉 Debian 12环境修复成功！"
        echo ""
        log_info "修复结果:"
        log_info "  ✓ Apache已移除"
        log_info "  ✓ Nginx正在运行"
        log_info "  ✓ PHP-FPM正在运行"
        echo ""
        log_info "现在可以重新运行系统兼容性测试:"
        log_info "  ./test_system_compatibility.sh"
        echo ""
        log_info "或者继续API服务修复:"
        log_info "  ./fix_debian12_api_service.sh"
    else
        log_error "❌ 环境修复未完全成功"
        return 1
    fi
}

# 主函数
main() {
    # 检查系统版本
    check_system
    
    # 检查当前软件状态
    check_current_software
    
    # 停止Apache
    stop_apache
    
    # 卸载Apache
    uninstall_apache
    
    # 安装PHP-FPM
    install_php_fpm
    
    # 配置PHP-FPM
    configure_php_fpm
    
    # 确保Nginx运行
    ensure_nginx_running
    
    # 检查端口冲突
    check_port_conflicts
    
    # 验证修复结果
    verify_fix
}

# 运行主函数
main "$@"
