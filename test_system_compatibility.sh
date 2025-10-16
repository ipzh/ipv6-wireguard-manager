#!/bin/bash

# IPv6 WireGuard Manager - 系统兼容性测试脚本
# 测试各种Linux系统的兼容性

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

# 检测系统信息
detect_system_info() {
    log_info "检测系统信息..."
    
    # 操作系统
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_ID="$ID"
        OS_VERSION="$VERSION_ID"
        OS_NAME="$PRETTY_NAME"
    elif [[ -f /etc/redhat-release ]]; then
        OS_ID="rhel"
        OS_VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+' | head -1)
        OS_NAME=$(cat /etc/redhat-release)
    elif [[ -f /etc/debian_version ]]; then
        OS_ID="debian"
        OS_VERSION=$(cat /etc/debian_version)
        OS_NAME="Debian $OS_VERSION"
    elif [[ -f /etc/arch-release ]]; then
        OS_ID="arch"
        OS_VERSION="rolling"
        OS_NAME="Arch Linux"
    elif [[ -f /etc/SuSE-release ]]; then
        OS_ID="opensuse"
        OS_VERSION=$(cat /etc/SuSE-release | grep -oE '[0-9]+\.[0-9]+' | head -1)
        OS_NAME="openSUSE $OS_VERSION"
    else
        OS_ID="unknown"
        OS_VERSION="unknown"
        OS_NAME="Unknown"
    fi
    
    # 架构
    ARCH=$(uname -m)
    
    # 包管理器
    if command -v apt-get &> /dev/null; then
        PACKAGE_MANAGER="apt"
    elif command -v apt &> /dev/null; then
        PACKAGE_MANAGER="apt"
    elif command -v dnf &> /dev/null; then
        PACKAGE_MANAGER="dnf"
    elif command -v yum &> /dev/null; then
        PACKAGE_MANAGER="yum"
    elif command -v pacman &> /dev/null; then
        PACKAGE_MANAGER="pacman"
    elif command -v zypper &> /dev/null; then
        PACKAGE_MANAGER="zypper"
    elif command -v emerge &> /dev/null; then
        PACKAGE_MANAGER="emerge"
    elif command -v apk &> /dev/null; then
        PACKAGE_MANAGER="apk"
    else
        PACKAGE_MANAGER="unknown"
    fi
    
    # 系统资源
    if command -v free &> /dev/null; then
        MEMORY_MB=$(free -m | awk 'NR==2{print $2}')
    else
        MEMORY_MB="unknown"
    fi
    
    if command -v nproc &> /dev/null; then
        CPU_CORES=$(nproc)
    else
        CPU_CORES=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "unknown")
    fi
    
    log_success "系统信息检测完成:"
    log_info "  操作系统: $OS_NAME"
    log_info "  版本: $OS_VERSION"
    log_info "  架构: $ARCH"
    log_info "  包管理器: $PACKAGE_MANAGER"
    log_info "  内存: ${MEMORY_MB}MB"
    log_info "  CPU核心: $CPU_CORES"
}

# 测试基础命令
test_basic_commands() {
    log_info "测试基础命令..."
    
    run_test "bash命令" "command -v bash"
    run_test "curl命令" "command -v curl"
    run_test "wget命令" "command -v wget"
    run_test "git命令" "command -v git"
    run_test "unzip命令" "command -v unzip"
    run_test "tar命令" "command -v tar"
    run_test "gzip命令" "command -v gzip"
}

# 测试包管理器
test_package_manager() {
    log_info "测试包管理器..."
    
    case $PACKAGE_MANAGER in
        "apt")
            run_test "apt-get命令" "command -v apt-get"
            run_test "apt命令" "command -v apt"
            ;;
        "yum")
            run_test "yum命令" "command -v yum"
            ;;
        "dnf")
            run_test "dnf命令" "command -v dnf"
            ;;
        "pacman")
            run_test "pacman命令" "command -v pacman"
            ;;
        "zypper")
            run_test "zypper命令" "command -v zypper"
            ;;
        "emerge")
            run_test "emerge命令" "command -v emerge"
            ;;
        "apk")
            run_test "apk命令" "command -v apk"
            ;;
        *)
            log_warning "未知的包管理器: $PACKAGE_MANAGER"
            ;;
    esac
}

# 测试Python环境
test_python_environment() {
    log_info "测试Python环境..."
    
    run_test "Python3命令" "command -v python3"
    run_test "pip3命令" "command -v pip3"
    
    # 测试Python版本
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
        log_info "检测到Python版本: $PYTHON_VERSION"
        
        # 检查Python版本是否满足要求
        if [[ "$PYTHON_VERSION" > "3.8" ]]; then
            log_success "✓ Python版本满足要求 (>= 3.8)"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_error "✗ Python版本过低 (需要 >= 3.8)"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    fi
}

# 测试数据库
test_database() {
    log_info "测试数据库..."
    
    # 测试MySQL
    if command -v mysql &> /dev/null; then
        log_success "✓ MySQL客户端已安装"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_warning "✗ MySQL客户端未安装"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 测试MariaDB
    if command -v mariadb &> /dev/null; then
        log_success "✓ MariaDB客户端已安装"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_warning "✗ MariaDB客户端未安装"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# 测试Web服务器
test_web_server() {
    log_info "测试Web服务器..."
    
    # 测试Nginx
    if command -v nginx &> /dev/null; then
        log_success "✓ Nginx已安装"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_warning "✗ Nginx未安装"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 测试Apache
    if command -v apache2 &> /dev/null || command -v httpd &> /dev/null; then
        log_warning "⚠ Apache已安装（可能与Nginx冲突）"
    fi
}

# 测试PHP环境
test_php_environment() {
    log_info "测试PHP环境..."
    
    # 测试PHP
    if command -v php &> /dev/null; then
        log_success "✓ PHP已安装"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        
        # 测试PHP版本
        PHP_VERSION=$(php --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
        log_info "检测到PHP版本: $PHP_VERSION"
        
        # 检查PHP版本是否满足要求
        if [[ "$PHP_VERSION" > "7.4" ]]; then
            log_success "✓ PHP版本满足要求 (>= 7.4)"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_error "✗ PHP版本过低 (需要 >= 7.4)"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    else
        log_warning "✗ PHP未安装"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 测试PHP-FPM
    if command -v php-fpm &> /dev/null; then
        log_success "✓ PHP-FPM已安装"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_warning "✗ PHP-FPM未安装"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# 测试网络
test_network() {
    log_info "测试网络..."
    
    # 测试IPv4连接
    if ping -c 1 8.8.8.8 &> /dev/null; then
        log_success "✓ IPv4网络连接正常"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ IPv4网络连接失败"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 测试IPv6连接
    if command -v ping6 &> /dev/null; then
        if ping6 -c 1 2001:4860:4860::8888 &> /dev/null; then
            log_success "✓ IPv6网络连接正常"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_warning "✗ IPv6网络连接失败"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    elif command -v ping &> /dev/null; then
        if ping -6 -c 1 2001:4860:4860::8888 &> /dev/null; then
            log_success "✓ IPv6网络连接正常"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_warning "✗ IPv6网络连接失败"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        log_warning "✗ 无法测试IPv6连接"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# 测试系统服务
test_system_services() {
    log_info "测试系统服务..."
    
    # 测试systemd
    if command -v systemctl &> /dev/null; then
        log_success "✓ systemd已安装"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_warning "✗ systemd未安装"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 测试服务管理
    if systemctl list-units &> /dev/null; then
        log_success "✓ 服务管理正常"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_warning "✗ 服务管理异常"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# 测试权限
test_permissions() {
    log_info "测试权限..."
    
    # 测试sudo权限
    if sudo -n true &> /dev/null; then
        log_success "✓ 具有sudo权限"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_warning "✗ 无sudo权限或需要密码"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # 测试写入权限
    if touch /tmp/test_write_permission &> /dev/null; then
        log_success "✓ 具有写入权限"
        rm -f /tmp/test_write_permission
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ 无写入权限"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# 生成兼容性报告
generate_compatibility_report() {
    log_info "生成兼容性报告..."
    
    local compatibility_score=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    
    echo ""
    log_info "=== 兼容性测试报告 ==="
    log_info "总测试数: $TESTS_TOTAL"
    log_success "通过: $TESTS_PASSED"
    log_error "失败: $TESTS_FAILED"
    log_info "兼容性评分: ${compatibility_score}%"
    
    if [[ $compatibility_score -ge 90 ]]; then
        log_success "🎉 系统完全兼容！"
    elif [[ $compatibility_score -ge 70 ]]; then
        log_warning "⚠️ 系统基本兼容，但可能需要额外配置"
    elif [[ $compatibility_score -ge 50 ]]; then
        log_warning "⚠️ 系统部分兼容，需要安装缺失的组件"
    else
        log_error "❌ 系统不兼容，需要大量配置工作"
    fi
    
    echo ""
    log_info "=== 建议 ==="
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_info "需要安装的组件："
        
        # 检查缺失的组件
        if ! command -v python3 &> /dev/null; then
            log_info "  - Python 3.8+"
        fi
        
        if ! command -v mysql &> /dev/null && ! command -v mariadb &> /dev/null; then
            log_info "  - MySQL或MariaDB"
        fi
        
        if ! command -v nginx &> /dev/null; then
            log_info "  - Nginx"
        fi
        
        if ! command -v php &> /dev/null; then
            log_info "  - PHP 7.4+"
        fi
        
        if ! command -v php-fpm &> /dev/null; then
            log_info "  - PHP-FPM"
        fi
    fi
    
    echo ""
    log_info "安装命令示例："
    case $PACKAGE_MANAGER in
        "apt")
            log_info "  sudo apt update"
            log_info "  sudo apt install python3 python3-pip mysql-server nginx php php-fpm"
            ;;
        "yum"|"dnf")
            log_info "  sudo $PACKAGE_MANAGER install python3 python3-pip mariadb-server nginx php php-fpm"
            ;;
        "pacman")
            log_info "  sudo pacman -S python python-pip mariadb nginx php php-fpm"
            ;;
        "zypper")
            log_info "  sudo zypper install python3 python3-pip mariadb nginx php php-fpm"
            ;;
        "emerge")
            log_info "  sudo emerge dev-lang/python dev-db/mariadb www-servers/nginx dev-lang/php"
            ;;
        "apk")
            log_info "  sudo apk add python3 py3-pip mariadb nginx php php-fpm"
            ;;
    esac
}

# 主函数
main() {
    log_info "开始系统兼容性测试..."
    echo ""
    
    detect_system_info
    echo ""
    
    test_basic_commands
    echo ""
    
    test_package_manager
    echo ""
    
    test_python_environment
    echo ""
    
    test_database
    echo ""
    
    test_web_server
    echo ""
    
    test_php_environment
    echo ""
    
    test_network
    echo ""
    
    test_system_services
    echo ""
    
    test_permissions
    echo ""
    
    generate_compatibility_report
}

# 运行主函数
main "$@"
