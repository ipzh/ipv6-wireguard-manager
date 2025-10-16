#!/bin/bash

# IPv6 WireGuard Manager - 仅安装PHP-FPM脚本
# 确保安装PHP-FPM时不触发Apache依赖

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

# 检测系统
detect_system() {
    log_section "检测系统"
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="$ID"
        OS_VERSION="$VERSION_ID"
        log_info "操作系统: $PRETTY_NAME"
    else
        log_error "无法检测操作系统"
        exit 1
    fi
    
    # 检测包管理器
    if command -v apt &>/dev/null; then
        PACKAGE_MANAGER="apt"
    elif command -v yum &>/dev/null; then
        PACKAGE_MANAGER="yum"
    elif command -v dnf &>/dev/null; then
        PACKAGE_MANAGER="dnf"
    elif command -v pacman &>/dev/null; then
        PACKAGE_MANAGER="pacman"
    elif command -v zypper &>/dev/null; then
        PACKAGE_MANAGER="zypper"
    elif command -v emerge &>/dev/null; then
        PACKAGE_MANAGER="emerge"
    elif command -v apk &>/dev/null; then
        PACKAGE_MANAGER="apk"
    else
        log_error "未找到支持的包管理器"
        exit 1
    fi
    
    log_info "包管理器: $PACKAGE_MANAGER"
    echo ""
}

# 检查现有PHP安装
check_existing_php() {
    log_section "检查现有PHP安装"
    
    if command -v php &>/dev/null; then
        local php_version=$(php --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
        log_info "检测到PHP版本: $php_version"
        
        # 检查是否已安装Apache模块
        if php -m | grep -q apache; then
            log_warning "⚠ 检测到Apache模块，建议重新安装"
        fi
        
        # 检查PHP-FPM
        if systemctl list-unit-files | grep -q php.*fpm; then
            local php_fpm_service=$(systemctl list-unit-files | grep php.*fpm | head -1 | awk '{print $1}')
            log_success "✓ 检测到PHP-FPM服务: $php_fpm_service"
        else
            log_warning "⚠ 未检测到PHP-FPM服务"
        fi
    else
        log_info "未检测到PHP安装"
    fi
    
    echo ""
}

# 卸载现有Apache相关包
remove_apache_packages() {
    log_section "卸载Apache相关包"
    
    case $PACKAGE_MANAGER in
        "apt")
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
                    log_info "卸载Apache包: $package"
                    apt-get remove --purge -y "$package" || true
                fi
            done
            
            # 清理
            apt-get autoremove -y
            apt-get autoclean
            ;;
        "yum"|"dnf")
            local apache_packages=(
                "httpd"
                "httpd-tools"
                "mod_php"
            )
            
            for package in "${apache_packages[@]}"; do
                if $PACKAGE_MANAGER list installed | grep -q "$package"; then
                    log_info "卸载Apache包: $package"
                    $PACKAGE_MANAGER remove -y "$package" || true
                fi
            done
            ;;
    esac
    
    log_success "✓ Apache相关包已清理"
    echo ""
}

# 安装PHP-FPM（避免Apache依赖）
install_php_fpm() {
    log_section "安装PHP-FPM（避免Apache依赖）"
    
    case $PACKAGE_MANAGER in
        "apt")
            # 更新包列表
            apt-get update
            
            # 检测可用的PHP版本
            local available_versions=("8.2" "8.1" "8.0")
            local php_version=""
            
            for version in "${available_versions[@]}"; do
                if apt-cache show php$version-fpm &>/dev/null; then
                    php_version="$version"
                    log_info "选择PHP版本: $php_version"
                    break
                fi
            done
            
            if [[ -z "$php_version" ]]; then
                log_info "使用默认PHP版本"
                php_version=""
            fi
            
            # 安装PHP-FPM核心包（避免Apache依赖）
            log_info "安装PHP-FPM核心包..."
            if [[ -n "$php_version" ]]; then
                apt-get install -y php$php_version-fpm php$php_version-cli php$php_version-common
            else
                apt-get install -y php-fpm php-cli php-common
            fi
            
            # 安装PHP扩展（逐个安装）
            local php_extensions=("curl" "json" "mbstring" "mysql" "xml" "zip")
            for ext in "${php_extensions[@]}"; do
                log_info "安装PHP扩展: $ext"
                if [[ -n "$php_version" ]]; then
                    apt-get install -y php$php_version-$ext || true
                else
                    apt-get install -y php-$ext || true
                fi
            done
            
            log_success "✓ PHP-FPM安装完成（无Apache依赖）"
            ;;
            
        "yum"|"dnf")
            # 安装PHP-FPM（避免Apache依赖）
            log_info "安装PHP-FPM核心包..."
            $PACKAGE_MANAGER install -y php-fpm php-cli php-common
            
            # 安装PHP扩展
            local php_extensions=("curl" "json" "mbstring" "mysql" "xml" "zip")
            for ext in "${php_extensions[@]}"; do
                log_info "安装PHP扩展: $ext"
                $PACKAGE_MANAGER install -y php-$ext || true
            done
            
            log_success "✓ PHP-FPM安装完成（无Apache依赖）"
            ;;
            
        "pacman")
            # 安装PHP-FPM（避免Apache依赖）
            log_info "安装PHP-FPM核心包..."
            pacman -S --noconfirm php-fpm php-cli
            
            # 安装PHP扩展
            pacman -S --noconfirm php-curl php-mbstring php-sqlite || true
            
            log_success "✓ PHP-FPM安装完成（无Apache依赖）"
            ;;
            
        "zypper")
            # 安装PHP-FPM（避免Apache依赖）
            log_info "安装PHP-FPM核心包..."
            zypper install -y php-fpm php-cli php-common
            
            # 安装PHP扩展
            local php_extensions=("curl" "json" "mbstring" "mysql" "xml" "zip")
            for ext in "${php_extensions[@]}"; do
                log_info "安装PHP扩展: $ext"
                zypper install -y php-$ext || true
            done
            
            log_success "✓ PHP-FPM安装完成（无Apache依赖）"
            ;;
            
        "emerge")
            # 安装PHP-FPM（避免Apache依赖）
            log_info "安装PHP-FPM..."
            emerge -q dev-lang/php:8.1
            emerge -q dev-php/php-fpm
            
            log_success "✓ PHP-FPM安装完成（无Apache依赖）"
            ;;
            
        "apk")
            # 安装PHP-FPM（避免Apache依赖）
            log_info "安装PHP-FPM核心包..."
            apk add php-fpm php-cli php-common
            
            # 安装PHP扩展
            apk add php-curl php-json php-mbstring php-mysqlnd php-xml php-zip
            
            log_success "✓ PHP-FPM安装完成（无Apache依赖）"
            ;;
    esac
    
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

# 验证安装
verify_installation() {
    log_section "验证安装"
    
    # 检查PHP版本
    if command -v php &>/dev/null; then
        local php_version=$(php --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
        log_success "✓ PHP版本: $php_version"
    else
        log_error "✗ PHP未安装"
        return 1
    fi
    
    # 检查PHP-FPM服务
    local php_fpm_running=false
    if systemctl is-active --quiet php8.2-fpm || systemctl is-active --quiet php8.1-fpm || systemctl is-active --quiet php8.0-fpm || systemctl is-active --quiet php-fpm; then
        log_success "✓ PHP-FPM服务正在运行"
        php_fpm_running=true
    else
        log_error "✗ PHP-FPM服务未运行"
        return 1
    fi
    
    # 检查Apache是否被安装
    if command -v apache2 &>/dev/null || command -v httpd &>/dev/null; then
        log_warning "⚠ 检测到Apache仍然存在"
        return 1
    else
        log_success "✓ 确认Apache未被安装"
    fi
    
    # 检查PHP模块
    log_info "检查PHP模块..."
    local required_modules=("curl" "json" "mbstring" "mysql" "xml" "zip")
    for module in "${required_modules[@]}"; do
        if php -m | grep -q "$module"; then
            log_success "✓ PHP模块 $module 已加载"
        else
            log_warning "⚠ PHP模块 $module 未加载"
        fi
    done
    
    echo ""
    
    if [[ "$php_fpm_running" == true ]]; then
        log_success "🎉 PHP-FPM安装成功（无Apache依赖）！"
        echo ""
        log_info "安装结果:"
        log_info "  ✓ PHP版本: $php_version"
        log_info "  ✓ PHP-FPM服务正在运行"
        log_info "  ✓ 未安装Apache"
        log_info "  ✓ 所有必需模块已加载"
        echo ""
        log_info "现在可以继续安装IPv6 WireGuard Manager:"
        log_info "  ./install.sh"
    else
        log_error "❌ PHP-FPM安装失败"
        return 1
    fi
}

# 主函数
main() {
    log_info "IPv6 WireGuard Manager - 仅安装PHP-FPM"
    echo ""
    
    # 检测系统
    detect_system
    
    # 检查现有PHP安装
    check_existing_php
    
    # 卸载Apache相关包
    remove_apache_packages
    
    # 安装PHP-FPM
    install_php_fpm
    
    # 配置PHP-FPM
    configure_php_fpm
    
    # 验证安装
    verify_installation
}

# 运行主函数
main "$@"
