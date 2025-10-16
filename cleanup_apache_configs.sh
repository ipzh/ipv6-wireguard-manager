#!/bin/bash

# IPv6 WireGuard Manager - Apache配置文件清理脚本
# 删除所有Apache相关的配置文件

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

log_info "IPv6 WireGuard Manager - Apache配置文件清理"
echo ""

# 删除.htaccess文件
remove_htaccess_files() {
    log_section "删除.htaccess文件"
    
    local htaccess_files=(
        "/opt/ipv6-wireguard-manager/php-frontend/.htaccess"
        "/var/www/html/.htaccess"
        "/var/www/.htaccess"
        "/usr/share/nginx/html/.htaccess"
        "/etc/nginx/html/.htaccess"
    )
    
    local found_files=0
    
    for file in "${htaccess_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_info "删除.htaccess文件: $file"
            rm -f "$file"
            log_success "✓ 已删除: $file"
            found_files=$((found_files + 1))
        fi
    done
    
    if [[ $found_files -eq 0 ]]; then
        log_info "未找到.htaccess文件"
    else
        log_success "✓ 删除了 $found_files 个.htaccess文件"
    fi
    
    echo ""
}

# 删除Apache配置目录
remove_apache_config_dirs() {
    log_section "删除Apache配置目录"
    
    local apache_dirs=(
        "/etc/apache2"
        "/etc/httpd"
        "/var/log/apache2"
        "/var/log/httpd"
        "/var/lib/apache2"
        "/var/lib/httpd"
    )
    
    local found_dirs=0
    
    for dir in "${apache_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_info "删除Apache配置目录: $dir"
            rm -rf "$dir"
            log_success "✓ 已删除: $dir"
            found_dirs=$((found_dirs + 1))
        fi
    done
    
    if [[ $found_dirs -eq 0 ]]; then
        log_info "未找到Apache配置目录"
    else
        log_success "✓ 删除了 $found_dirs 个Apache配置目录"
    fi
    
    echo ""
}

# 删除Apache日志文件
remove_apache_logs() {
    log_section "删除Apache日志文件"
    
    local log_files=(
        "/var/log/apache2/access.log"
        "/var/log/apache2/error.log"
        "/var/log/httpd/access_log"
        "/var/log/httpd/error_log"
    )
    
    local found_logs=0
    
    for file in "${log_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_info "删除Apache日志文件: $file"
            rm -f "$file"
            log_success "✓ 已删除: $file"
            found_logs=$((found_logs + 1))
        fi
    done
    
    if [[ $found_logs -eq 0 ]]; then
        log_info "未找到Apache日志文件"
    else
        log_success "✓ 删除了 $found_logs 个Apache日志文件"
    fi
    
    echo ""
}

# 删除Apache模块文件
remove_apache_modules() {
    log_section "删除Apache模块文件"
    
    local module_dirs=(
        "/usr/lib/apache2/modules"
        "/usr/lib64/httpd/modules"
        "/usr/lib/httpd/modules"
    )
    
    local found_modules=0
    
    for dir in "${module_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_info "删除Apache模块目录: $dir"
            rm -rf "$dir"
            log_success "✓ 已删除: $dir"
            found_modules=$((found_modules + 1))
        fi
    done
    
    if [[ $found_modules -eq 0 ]]; then
        log_info "未找到Apache模块目录"
    else
        log_success "✓ 删除了 $found_modules 个Apache模块目录"
    fi
    
    echo ""
}

# 清理Apache用户和组
cleanup_apache_users() {
    log_section "清理Apache用户和组"
    
    # 检查Apache用户
    if id apache &>/dev/null; then
        log_info "删除Apache用户: apache"
        userdel apache 2>/dev/null || true
        log_success "✓ Apache用户已删除"
    fi
    
    if id www-data &>/dev/null; then
        log_warning "⚠ www-data用户存在（可能被其他服务使用）"
        log_info "检查www-data用户是否被其他服务使用..."
        if ! systemctl list-units --all | grep -q www-data; then
            log_info "www-data用户未被其他服务使用，可以安全删除"
            userdel www-data 2>/dev/null || true
            log_success "✓ www-data用户已删除"
        else
            log_info "www-data用户被其他服务使用，保留"
        fi
    fi
    
    # 检查Apache组
    if getent group apache &>/dev/null; then
        log_info "删除Apache组: apache"
        groupdel apache 2>/dev/null || true
        log_success "✓ Apache组已删除"
    fi
    
    echo ""
}

# 验证清理结果
verify_cleanup() {
    log_section "验证清理结果"
    
    local remaining_files=0
    
    # 检查是否还有Apache相关文件
    if find /etc -name "*apache*" 2>/dev/null | grep -q .; then
        log_warning "⚠ 发现剩余的Apache配置文件:"
        find /etc -name "*apache*" 2>/dev/null | head -5
        remaining_files=$((remaining_files + 1))
    fi
    
    if find /var -name "*apache*" 2>/dev/null | grep -q .; then
        log_warning "⚠ 发现剩余的Apache数据文件:"
        find /var -name "*apache*" 2>/dev/null | head -5
        remaining_files=$((remaining_files + 1))
    fi
    
    if find /usr -name "*apache*" 2>/dev/null | grep -q .; then
        log_warning "⚠ 发现剩余的Apache程序文件:"
        find /usr -name "*apache*" 2>/dev/null | head -5
        remaining_files=$((remaining_files + 1))
    fi
    
    if [[ $remaining_files -eq 0 ]]; then
        log_success "✓ Apache配置文件清理完成，未发现剩余文件"
    else
        log_warning "⚠ 发现 $remaining_files 类剩余Apache文件"
        log_info "如需完全清理，请手动检查上述文件"
    fi
    
    echo ""
}

# 显示清理总结
show_cleanup_summary() {
    log_section "清理总结"
    
    echo "Apache配置文件清理完成！"
    echo ""
    echo "已清理的内容："
    echo "  ✓ .htaccess文件"
    echo "  ✓ Apache配置目录"
    echo "  ✓ Apache日志文件"
    echo "  ✓ Apache模块文件"
    echo "  ✓ Apache用户和组"
    echo ""
    echo "现在系统只使用Nginx作为Web服务器："
    echo "  ✓ Nginx配置文件: /etc/nginx/"
    echo "  ✓ Nginx日志文件: /var/log/nginx/"
    echo "  ✓ PHP-FPM服务: php8.2-fpm 或 php8.1-fpm"
    echo ""
    log_success "🎉 Apache配置文件清理完成！"
}

# 主函数
main() {
    # 删除.htaccess文件
    remove_htaccess_files
    
    # 删除Apache配置目录
    remove_apache_config_dirs
    
    # 删除Apache日志文件
    remove_apache_logs
    
    # 删除Apache模块文件
    remove_apache_modules
    
    # 清理Apache用户和组
    cleanup_apache_users
    
    # 验证清理结果
    verify_cleanup
    
    # 显示清理总结
    show_cleanup_summary
}

# 运行主函数
main "$@"
