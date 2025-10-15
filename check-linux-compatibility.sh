#!/bin/bash

# IPv6 WireGuard Manager Linux兼容性检查脚本
# 检查主流Linux发行版的兼容性

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

echo "=========================================="
echo "IPv6 WireGuard Manager Linux兼容性检查"
echo "=========================================="

# 检查操作系统
check_os() {
    log_info "检查操作系统..."
    
    if [[ ! -f /etc/os-release ]]; then
        log_error "不支持的操作系统：缺少 /etc/os-release 文件"
        return 1
    fi
    
    source /etc/os-release
    
    log_info "检测到操作系统: $NAME $VERSION"
    log_info "操作系统ID: $ID"
    log_info "版本ID: $VERSION_ID"
    
    # 检查支持的发行版
    case $ID in
        ubuntu)
            if [[ "$VERSION_ID" == "20.04" || "$VERSION_ID" == "22.04" || "$VERSION_ID" == "24.04" ]]; then
                log_success "Ubuntu $VERSION_ID 完全支持"
            else
                log_warning "Ubuntu $VERSION_ID 可能支持，但未完全测试"
            fi
            ;;
        debian)
            if [[ "$VERSION_ID" == "11" || "$VERSION_ID" == "12" ]]; then
                log_success "Debian $VERSION_ID 完全支持"
            else
                log_warning "Debian $VERSION_ID 可能支持，但未完全测试"
            fi
            ;;
        centos)
            if [[ "$VERSION_ID" == "8" || "$VERSION_ID" == "9" ]]; then
                log_success "CentOS $VERSION_ID 完全支持"
            else
                log_warning "CentOS $VERSION_ID 可能支持，但未完全测试"
            fi
            ;;
        rhel)
            if [[ "$VERSION_ID" == "8" || "$VERSION_ID" == "9" ]]; then
                log_success "RHEL $VERSION_ID 完全支持"
            else
                log_warning "RHEL $VERSION_ID 可能支持，但未完全测试"
            fi
            ;;
        fedora)
            if [[ "$VERSION_ID" == "38" || "$VERSION_ID" == "39" || "$VERSION_ID" == "40" ]]; then
                log_success "Fedora $VERSION_ID 完全支持"
            else
                log_warning "Fedora $VERSION_ID 可能支持，但未完全测试"
            fi
            ;;
        arch)
            log_success "Arch Linux 完全支持"
            ;;
        opensuse*)
            log_success "openSUSE 完全支持"
            ;;
        *)
            log_warning "未识别的发行版: $ID $VERSION_ID"
            log_info "如果使用主流Linux发行版，通常可以正常工作"
            ;;
    esac
    
    return 0
}

# 检查包管理器
check_package_manager() {
    log_info "检查包管理器..."
    
    if command -v apt-get &> /dev/null; then
        log_success "检测到APT包管理器 (Debian/Ubuntu)"
        return 0
    elif command -v yum &> /dev/null; then
        log_success "检测到YUM包管理器 (CentOS/RHEL)"
        return 0
    elif command -v dnf &> /dev/null; then
        log_success "检测到DNF包管理器 (Fedora)"
        return 0
    elif command -v pacman &> /dev/null; then
        log_success "检测到Pacman包管理器 (Arch Linux)"
        return 0
    elif command -v zypper &> /dev/null; then
        log_success "检测到Zypper包管理器 (openSUSE)"
        return 0
    else
        log_error "未检测到支持的包管理器"
        return 1
    fi
}

# 检查系统要求
check_system_requirements() {
    log_info "检查系统要求..."
    
    # 检查内存
    local memory_mb=$(free -m | awk 'NR==2{print $2}')
    log_info "系统内存: ${memory_mb}MB"
    
    if [ "$memory_mb" -lt 512 ]; then
        log_error "系统内存不足，至少需要512MB"
        return 1
    elif [ "$memory_mb" -lt 1024 ]; then
        log_warning "系统内存较少，建议使用低内存安装模式"
    else
        log_success "系统内存充足"
    fi
    
    # 检查磁盘空间
    local disk_space=$(df / | awk 'NR==2{print $4}')
    local disk_space_mb=$((disk_space / 1024))
    log_info "可用磁盘空间: ${disk_space_mb}MB"
    
    if [ "$disk_space_mb" -lt 1024 ]; then
        log_error "磁盘空间不足，至少需要1GB"
        return 1
    elif [ "$disk_space_mb" -lt 2048 ]; then
        log_warning "磁盘空间较少，建议至少2GB"
    else
        log_success "磁盘空间充足"
    fi
    
    # 检查CPU核心数
    local cpu_cores=$(nproc)
    log_info "CPU核心数: $cpu_cores"
    
    if [ "$cpu_cores" -lt 1 ]; then
        log_error "CPU核心数不足"
        return 1
    elif [ "$cpu_cores" -lt 2 ]; then
        log_warning "CPU核心数较少，可能影响性能"
    else
        log_success "CPU核心数充足"
    fi
    
    return 0
}

# 检查网络支持
check_network_support() {
    log_info "检查网络支持..."
    
    # 检查IPv4支持
    if ping -c 1 8.8.8.8 &> /dev/null; then
        log_success "IPv4网络连接正常"
    else
        log_warning "IPv4网络连接可能有问题"
    fi
    
    # 检查IPv6支持
    if ping6 -c 1 2001:4860:4860::8888 &> /dev/null; then
        log_success "IPv6网络连接正常"
    else
        log_warning "IPv6网络连接不可用（可选）"
    fi
    
    # 检查端口可用性
    local ports=(80 8000 5432 6379)
    for port in "${ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            log_warning "端口 $port 已被占用"
        else
            log_success "端口 $port 可用"
        fi
    done
    
    return 0
}

# 检查必需的命令
check_required_commands() {
    log_info "检查必需的命令..."
    
    local commands=("curl" "wget" "git" "unzip")
    local missing_commands=()
    
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            log_success "$cmd 已安装"
        else
            log_warning "$cmd 未安装"
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        log_info "缺少的命令将在安装过程中自动安装"
    fi
    
    return 0
}

# 检查Docker支持
check_docker_support() {
    log_info "检查Docker支持..."
    
    if command -v docker &> /dev/null; then
        log_success "Docker已安装"
        if command -v docker-compose &> /dev/null; then
            log_success "Docker Compose已安装"
        else
            log_warning "Docker Compose未安装"
        fi
    else
        log_info "Docker未安装，将在需要时自动安装"
    fi
    
    return 0
}

# 生成兼容性报告
generate_compatibility_report() {
    log_info "生成兼容性报告..."
    
    source /etc/os-release
    
    cat > /tmp/linux-compatibility-report.txt << EOF
IPv6 WireGuard Manager Linux兼容性报告
=====================================

检查时间: $(date)
操作系统: $NAME $VERSION
系统ID: $ID $VERSION_ID

系统要求检查:
- 内存: $(free -m | awk 'NR==2{print $2}')MB
- 磁盘空间: $(($(df / | awk 'NR==2{print $4}') / 1024))MB
- CPU核心: $(nproc)个

包管理器支持:
$(if command -v apt-get &> /dev/null; then echo "- APT (Debian/Ubuntu): 支持"; fi)
$(if command -v yum &> /dev/null; then echo "- YUM (CentOS/RHEL): 支持"; fi)
$(if command -v dnf &> /dev/null; then echo "- DNF (Fedora): 支持"; fi)
$(if command -v pacman &> /dev/null; then echo "- Pacman (Arch): 支持"; fi)
$(if command -v zypper &> /dev/null; then echo "- Zypper (openSUSE): 支持"; fi)

网络支持:
- IPv4: $(ping -c 1 8.8.8.8 &> /dev/null && echo "支持" || echo "不支持")
- IPv6: $(ping6 -c 1 2001:4860:4860::8888 &> /dev/null && echo "支持" || echo "不支持")

Docker支持:
- Docker: $(command -v docker &> /dev/null && echo "已安装" || echo "未安装")
- Docker Compose: $(command -v docker-compose &> /dev/null && echo "已安装" || echo "未安装")

推荐安装方式:
$(if [ $(free -m | awk 'NR==2{print $2}') -lt 1024 ]; then echo "- 低内存模式"; else echo "- 标准模式"; fi)
$(if command -v docker &> /dev/null; then echo "- Docker部署"; else echo "- 原生部署"; fi)

注意事项:
- 确保防火墙允许端口 80, 8000, 5432, 6379
- 建议使用root权限运行安装脚本
- 生产环境建议配置SSL证书
EOF

    log_success "兼容性报告已生成: /tmp/linux-compatibility-report.txt"
}

# 主函数
main() {
    local all_checks_passed=true
    
    if ! check_os; then
        all_checks_passed=false
    fi
    
    if ! check_package_manager; then
        all_checks_passed=false
    fi
    
    if ! check_system_requirements; then
        all_checks_passed=false
    fi
    
    if ! check_network_support; then
        all_checks_passed=false
    fi
    
    if ! check_required_commands; then
        all_checks_passed=false
    fi
    
    check_docker_support
    
    generate_compatibility_report
    
    echo ""
    echo "=========================================="
    if [ "$all_checks_passed" = true ]; then
        log_success "Linux兼容性检查通过！"
        echo ""
        echo "🎯 推荐安装命令："
        echo "  curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash"
        echo ""
        echo "📋 详细报告："
        echo "  cat /tmp/linux-compatibility-report.txt"
    else
        log_error "Linux兼容性检查未通过！"
        echo ""
        echo "⚠️  请解决上述问题后重新运行检查"
        echo ""
        echo "📋 详细报告："
        echo "  cat /tmp/linux-compatibility-report.txt"
    fi
    echo "=========================================="
}

# 运行主函数
main "$@"
