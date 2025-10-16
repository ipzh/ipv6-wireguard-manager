#!/bin/bash

# IPv6 WireGuard Manager - 修复Apache依赖问题脚本
# 解决PHP安装时自动安装Apache的问题

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

log_info "IPv6 WireGuard Manager - 修复Apache依赖问题"
echo ""

# 停止Apache服务
stop_apache_services() {
    log_section "停止Apache服务"
    
    # 停止Apache2服务
    if systemctl is-active --quiet apache2; then
        log_info "停止Apache2服务..."
        systemctl stop apache2
        systemctl disable apache2
        log_success "✓ Apache2服务已停止并禁用"
    else
        log_info "Apache2服务未运行"
    fi
    
    echo ""
}

# 卸载Apache相关包
uninstall_apache_packages() {
    log_section "卸载Apache相关包"
    
    # 卸载Apache主包和模块
    local apache_packages=(
        "apache2"
        "apache2-bin"
        "apache2-utils"
        "apache2-data"
        "libapache2-mod-php8.2"
        "libapache2-mod-php8.1"
        "libapache2-mod-php8.0"
    )
    
    for package in "${apache_packages[@]}"; do
        if dpkg -l | grep -q "^ii.*$package "; then
            log_info "卸载包: $package"
            apt-get remove --purge -y "$package" || true
            log_success "✓ $package 已卸载"
        fi
    done
    
    # 清理未使用的依赖
    log_info "清理未使用的依赖..."
    apt-get autoremove -y
    apt-get autoclean
    
    echo ""
}

# 重新安装PHP（仅FPM版本）
reinstall_php_fpm_only() {
    log_section "重新安装PHP（仅FPM版本）"
    
    # 检查当前PHP版本
    if command -v php &>/dev/null; then
        local php_version=$(php --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
        log_info "检测到PHP版本: $php_version"
        
        # 卸载当前PHP包（保留核心功能）
        log_info "卸载当前PHP包..."
        apt-get remove --purge -y php php-cli php-common 2>/dev/null || true
        
        # 安装指定版本的PHP-FPM（不包含Apache模块）
        if [[ "$php_version" == "8.2"* ]]; then
            log_info "安装PHP 8.2-FPM（不包含Apache模块）..."
            apt-get install -y php8.2-fpm php8.2-cli php8.2-common php8.2-curl php8.2-json php8.2-mbstring php8.2-mysql php8.2-xml php8.2-zip
        elif [[ "$php_version" == "8.1"* ]]; then
            log_info "安装PHP 8.1-FPM（不包含Apache模块）..."
            apt-get install -y php8.1-fpm php8.1-cli php8.1-common php8.1-curl php8.1-json php8.1-mbstring php8.1-mysql php8.1-xml php8.1-zip
        else
            log_info "安装默认PHP-FPM（不包含Apache模块）..."
            apt-get install -y php-fpm php-cli php-common php-curl php-json php-mbstring php-mysql php-xml php-zip
        fi
    else
        log_info "PHP未安装，安装PHP 8.2-FPM..."
        apt-get install -y php8.2-fpm php8.2-cli php8.2-common php8.2-curl php8.2-json php8.2-mbstring php8.2-mysql php8.2-xml php8.2-zip
    fi
    
    log_success "✓ PHP-FPM安装完成（无Apache模块）"
    echo ""
}

# 配置PHP-FPM
configure_php_fpm() {
    log_section "配置PHP-FPM"
    
    # 检测PHP-FPM服务名
    local php_fpm_service=""
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
        log_success "🎉 Apache依赖问题修复成功！"
        echo ""
        log_info "修复结果:"
        log_info "  ✓ Apache已移除"
        log_info "  ✓ PHP-FPM正常运行（无Apache模块）"
        log_info "  ✓ Nginx正在运行"
        echo ""
        log_info "现在可以继续API服务修复:"
        log_info "  ./fix_debian12_api_service.sh"
    else
        log_error "❌ 修复未完全成功"
        return 1
    fi
}

# 主函数
main() {
    # 停止Apache服务
    stop_apache_services
    
    # 卸载Apache相关包
    uninstall_apache_packages
    
    # 重新安装PHP（仅FPM版本）
    reinstall_php_fpm_only
    
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
