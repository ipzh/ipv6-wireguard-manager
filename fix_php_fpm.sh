#!/bin/bash

# IPv6 WireGuard Manager - PHP-FPM修复脚本
# 解决PHP-FPM服务启动问题

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

# 检测PHP版本
detect_php_version() {
    if command -v php &> /dev/null; then
        PHP_VERSION=$(php -v | grep -oP 'PHP \K[0-9]+\.[0-9]+' | head -1)
        log_info "检测到PHP版本: $PHP_VERSION"
        echo "$PHP_VERSION"
    else
        log_error "未检测到PHP"
        return 1
    fi
}

# 检测PHP-FPM服务
detect_php_fpm_service() {
    local php_version=$1
    local possible_services=(
        "php${php_version}-fpm"
        "php-fpm"
        "php8.2-fpm"
        "php8.1-fpm"
        "php8.0-fpm"
        "php7.4-fpm"
    )
    
    for service in "${possible_services[@]}"; do
        if systemctl list-unit-files | grep -q "^${service}.service"; then
            log_info "找到PHP-FPM服务: $service"
            echo "$service"
            return 0
        fi
    done
    
    # 尝试从已安装的包中检测
    if command -v apt &> /dev/null; then
        local php_fpm_package=$(dpkg -l | grep php-fpm | head -n 1 | awk '{print $2}')
        if [[ -n "$php_fpm_package" ]]; then
            log_info "从包管理器找到PHP-FPM服务: $php_fpm_package"
            echo "$php_fpm_package"
            return 0
        fi
    elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
        local php_fpm_package=$(rpm -qa | grep php-fpm | head -n 1)
        if [[ -n "$php_fpm_package" ]]; then
            log_info "从包管理器找到PHP-FPM服务: $php_fpm_package"
            echo "$php_fpm_package"
            return 0
        fi
    fi
    
    log_error "无法找到PHP-FPM服务"
    return 1
}

# 安装PHP-FPM
install_php_fpm() {
    log_info "开始安装PHP-FPM..."
    
    if command -v apt &> /dev/null; then
        # Ubuntu/Debian
        log_info "检测到APT包管理器，安装PHP-FPM..."
        apt update
        apt install -y php-fpm php-cli php-curl php-json php-mbstring php-mysql php-xml php-zip
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        log_info "检测到YUM包管理器，安装PHP-FPM..."
        yum install -y php-fpm php-cli php-curl php-json php-mbstring php-mysql php-xml php-zip
    elif command -v dnf &> /dev/null; then
        # Fedora
        log_info "检测到DNF包管理器，安装PHP-FPM..."
        dnf install -y php-fpm php-cli php-curl php-json php-mbstring php-mysql php-xml php-zip
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        log_info "检测到Pacman包管理器，安装PHP-FPM..."
        pacman -S --noconfirm php php-fpm
    elif command -v zypper &> /dev/null; then
        # openSUSE
        log_info "检测到Zypper包管理器，安装PHP-FPM..."
        zypper install -y php php-fpm php-cli php-curl php-json php-mbstring php-mysql php-xml php-zip
    else
        log_error "不支持的包管理器"
        return 1
    fi
    
    log_success "PHP-FPM安装完成"
}

# 启动PHP-FPM服务
start_php_fpm_service() {
    local service_name=$1
    
    log_info "启动PHP-FPM服务: $service_name"
    
    # 启用服务
    systemctl enable "$service_name"
    
    # 启动服务
    if systemctl start "$service_name"; then
        log_success "PHP-FPM服务启动成功"
    else
        log_error "PHP-FPM服务启动失败"
        log_info "尝试手动启动: sudo systemctl start $service_name"
        return 1
    fi
    
    # 检查服务状态
    if systemctl is-active --quiet "$service_name"; then
        log_success "PHP-FPM服务运行正常"
    else
        log_error "PHP-FPM服务未正常运行"
        return 1
    fi
}

# 配置PHP-FPM
configure_php_fpm() {
    local php_version=$1
    
    log_info "配置PHP-FPM..."
    
    # 查找PHP-FPM配置文件
    local php_fpm_conf=""
    local possible_configs=(
        "/etc/php/${php_version}/fpm/pool.d/www.conf"
        "/etc/php-fpm.d/www.conf"
        "/etc/php/php-fpm.d/www.conf"
    )
    
    for config in "${possible_configs[@]}"; do
        if [[ -f "$config" ]]; then
            php_fpm_conf="$config"
            log_info "找到PHP-FPM配置文件: $config"
            break
        fi
    done
    
    if [[ -z "$php_fpm_conf" ]]; then
        log_warning "未找到PHP-FPM配置文件，使用默认配置"
        return 0
    fi
    
    # 备份原配置文件
    cp "$php_fpm_conf" "${php_fpm_conf}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 基本配置优化
    sed -i 's/;listen = \/run\/php\/php.*-fpm.sock/listen = \/run\/php\/php-fpm.sock/' "$php_fpm_conf"
    sed -i 's/pm = dynamic/pm = dynamic/' "$php_fpm_conf"
    sed -i 's/pm.max_children = 5/pm.max_children = 20/' "$php_fpm_conf"
    sed -i 's/pm.start_servers = 2/pm.start_servers = 5/' "$php_fpm_conf"
    sed -i 's/pm.min_spare_servers = 1/pm.min_spare_servers = 2/' "$php_fpm_conf"
    sed -i 's/pm.max_spare_servers = 3/pm.max_spare_servers = 8/' "$php_fpm_conf"
    
    log_success "PHP-FPM配置完成"
}

# 测试PHP-FPM
test_php_fpm() {
    log_info "测试PHP-FPM..."
    
    # 创建测试文件
    local test_file="/var/www/html/test.php"
    echo "<?php phpinfo(); ?>" > "$test_file"
    
    # 测试PHP解析
    if curl -f http://localhost/test.php &> /dev/null; then
        log_success "PHP-FPM测试成功"
        rm -f "$test_file"
        return 0
    else
        log_error "PHP-FPM测试失败"
        rm -f "$test_file"
        return 1
    fi
}

# 主函数
main() {
    log_info "开始修复PHP-FPM服务..."
    
    # 检测PHP版本
    if ! PHP_VERSION=$(detect_php_version); then
        log_error "无法检测PHP版本"
        exit 1
    fi
    
    # 检测PHP-FPM服务
    if ! PHP_FPM_SERVICE=$(detect_php_fpm_service "$PHP_VERSION"); then
        log_warning "未找到PHP-FPM服务，尝试安装..."
        if ! install_php_fpm; then
            log_error "PHP-FPM安装失败"
            exit 1
        fi
        
        # 重新检测服务
        if ! PHP_FPM_SERVICE=$(detect_php_fpm_service "$PHP_VERSION"); then
            log_error "安装后仍无法找到PHP-FPM服务"
            exit 1
        fi
    fi
    
    # 配置PHP-FPM
    configure_php_fpm "$PHP_VERSION"
    
    # 启动PHP-FPM服务
    if ! start_php_fpm_service "$PHP_FPM_SERVICE"; then
        log_error "PHP-FPM服务启动失败"
        exit 1
    fi
    
    # 测试PHP-FPM
    if test_php_fpm; then
        log_success "PHP-FPM修复完成！"
        log_info "服务名称: $PHP_FPM_SERVICE"
        log_info "PHP版本: $PHP_VERSION"
    else
        log_warning "PHP-FPM修复完成，但测试失败"
        log_info "请检查Nginx配置和PHP-FPM配置"
    fi
}

# 运行主函数
main "$@"
