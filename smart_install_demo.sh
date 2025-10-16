#!/bin/bash

# IPv6 WireGuard Manager - 智能安装演示脚本
# 演示智能选择安装类型的功能

set -e

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

log_demo() {
    echo -e "${PURPLE}[DEMO]${NC} $1"
}

log_section() {
    echo -e "${CYAN}=== $1 ===${NC}"
}

# 检测系统资源
detect_system_resources() {
    log_section "系统资源检测"
    
    # 检测内存
    if command -v free &>/dev/null; then
        MEMORY_MB=$(free -m | awk 'NR==2{print $2}')
    else
        MEMORY_MB=1024  # 默认值
    fi
    
    # 检测CPU核心
    if command -v nproc &>/dev/null; then
        CPU_CORES=$(nproc)
    else
        CPU_CORES=1  # 默认值
    fi
    
    # 检测磁盘空间
    if command -v df &>/dev/null; then
        DISK_SPACE_MB=$(df -m / | awk 'NR==2{print $4}')
    else
        DISK_SPACE_MB=1024  # 默认值
    fi
    
    log_info "系统资源信息:"
    log_info "  内存: ${MEMORY_MB}MB"
    log_info "  CPU核心: ${CPU_CORES}核"
    log_info "  可用磁盘空间: ${DISK_SPACE_MB}MB"
    echo ""
}

# 计算系统评分
calculate_system_score() {
    log_section "系统评分计算"
    
    local score=0
    local details=""
    
    # 内存评分 (0-3分)
    if [[ $MEMORY_MB -ge 4096 ]]; then
        score=$((score + 3))
        details+="内存: 3分 (≥4GB) + "
    elif [[ $MEMORY_MB -ge 2048 ]]; then
        score=$((score + 2))
        details+="内存: 2分 (2-4GB) + "
    elif [[ $MEMORY_MB -ge 1024 ]]; then
        score=$((score + 1))
        details+="内存: 1分 (1-2GB) + "
    else
        details+="内存: 0分 (<1GB) + "
    fi
    
    # CPU评分 (0-2分)
    if [[ $CPU_CORES -ge 4 ]]; then
        score=$((score + 2))
        details+="CPU: 2分 (≥4核) + "
    elif [[ $CPU_CORES -ge 2 ]]; then
        score=$((score + 1))
        details+="CPU: 1分 (2-4核) + "
    else
        details+="CPU: 0分 (<2核) + "
    fi
    
    # 磁盘评分 (0-1分)
    if [[ $DISK_SPACE_MB -ge 10240 ]]; then  # 10GB
        score=$((score + 1))
        details+="磁盘: 1分 (≥10GB)"
    else
        details+="磁盘: 0分 (<10GB)"
    fi
    
    log_info "评分详情: $details"
    log_success "系统总评分: $score/6分"
    echo ""
    
    return $score
}

# 智能选择安装类型
smart_select_install_type() {
    local score=$1
    
    log_section "智能选择安装类型"
    
    if [[ $score -le 2 ]]; then
        INSTALL_TYPE="minimal"
        log_warning "⚠️ 系统资源有限（评分: $score/6）"
        log_success "推荐安装类型: minimal"
        log_info "选择理由: 最小化安装，优化资源使用"
        log_info "优化配置:"
        log_info "  - 禁用Redis缓存"
        log_info "  - 优化MySQL配置"
        log_info "  - 减少并发连接数"
        log_info "  - 简化监控功能"
    elif [[ $score -le 4 ]]; then
        INSTALL_TYPE="native"
        log_info "💡 系统资源适中（评分: $score/6）"
        log_success "推荐安装类型: native"
        log_info "选择理由: 原生安装，平衡性能和资源"
        log_info "优化配置:"
        log_info "  - 启用基础功能"
        log_info "  - 适度缓存配置"
        log_info "  - 标准并发连接"
        log_info "  - 基础监控功能"
    else
        INSTALL_TYPE="native"  # 改为native，因为Docker安装尚未实现
        log_success "🎉 系统资源充足（评分: $score/6）"
        log_success "推荐安装类型: native"
        log_info "选择理由: 原生安装，充分利用系统资源"
        log_info "优化配置:"
        log_info "  - 启用所有功能"
        log_info "  - 最大化缓存配置"
        log_info "  - 高并发连接"
        log_info "  - 完整监控功能"
        log_info "  - 性能优化选项"
    fi
    
    echo ""
}

# 显示安装建议
show_installation_suggestions() {
    log_section "安装建议"
    
    echo "根据系统评分，建议使用以下安装命令："
    echo ""
    
    if [[ $score -le 2 ]]; then
        log_demo "低配置服务器安装命令:"
        echo "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --type minimal --silent"
        echo ""
        log_demo "或者使用专门的PHP-FPM安装脚本:"
        echo "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install_php_fpm_only.sh | bash"
    elif [[ $score -le 4 ]]; then
        log_demo "中等配置服务器安装命令:"
        echo "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --type native --silent"
        echo ""
        log_demo "或者使用智能安装:"
        echo "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --silent"
    else
        log_demo "高配置服务器安装命令:"
        echo "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --type native --silent"
        echo ""
        log_demo "或者使用智能安装:"
        echo "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --silent"
    fi
    
    echo ""
    log_info "注意事项:"
    log_info "  - 确保系统已安装必要的依赖"
    log_info "  - 建议在安装前备份重要数据"
    log_info "  - 安装过程中请保持网络连接"
    echo ""
}

# 显示系统兼容性
show_system_compatibility() {
    log_section "系统兼容性检查"
    
    # 检查操作系统
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        log_success "✓ 操作系统: $PRETTY_NAME"
    else
        log_warning "⚠ 无法检测操作系统"
    fi
    
    # 检查包管理器
    if command -v apt &>/dev/null; then
        log_success "✓ 包管理器: APT (Debian/Ubuntu)"
    elif command -v yum &>/dev/null; then
        log_success "✓ 包管理器: YUM (CentOS/RHEL)"
    elif command -v dnf &>/dev/null; then
        log_success "✓ 包管理器: DNF (Fedora)"
    elif command -v pacman &>/dev/null; then
        log_success "✓ 包管理器: Pacman (Arch Linux)"
    elif command -v zypper &>/dev/null; then
        log_success "✓ 包管理器: Zypper (openSUSE)"
    elif command -v emerge &>/dev/null; then
        log_success "✓ 包管理器: Emerge (Gentoo)"
    elif command -v apk &>/dev/null; then
        log_success "✓ 包管理器: APK (Alpine Linux)"
    else
        log_warning "⚠ 未找到支持的包管理器"
    fi
    
    # 检查Python
    if command -v python3 &>/dev/null; then
        local python_version=$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
        log_success "✓ Python版本: $python_version"
    else
        log_warning "⚠ Python3未安装"
    fi
    
    echo ""
}

# 主函数
main() {
    log_demo "IPv6 WireGuard Manager - 智能安装演示"
    echo ""
    log_info "此脚本将演示智能选择安装类型的功能"
    log_info "不会实际安装软件，仅用于演示和测试"
    echo ""
    
    # 检测系统资源
    detect_system_resources
    
    # 计算系统评分
    calculate_system_score
    local score=$?
    
    # 智能选择安装类型
    smart_select_install_type $score
    
    # 显示系统兼容性
    show_system_compatibility
    
    # 显示安装建议
    show_installation_suggestions
    
    log_success "🎉 智能安装演示完成！"
    echo ""
    log_info "如需实际安装，请使用上述建议的安装命令"
}

# 运行主函数
main "$@"
