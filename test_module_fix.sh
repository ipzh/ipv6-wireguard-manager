#!/bin/bash

# 测试模块修复脚本（不需要root权限）

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 安装目录
INSTALL_DIR="/opt/ipv6-wireguard-manager"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info "检查模块文件状态..."

# 检查安装目录是否存在
if [[ ! -d "$INSTALL_DIR" ]]; then
    log_error "安装目录不存在: $INSTALL_DIR"
    log_info "请先运行安装脚本"
    exit 1
fi

# 检查当前目录是否有模块文件
if [[ ! -d "$CURRENT_DIR/modules" ]]; then
    log_error "当前目录没有modules文件夹: $CURRENT_DIR/modules"
    exit 1
fi

log_info "当前项目模块文件:"
ls -la "$CURRENT_DIR/modules/" | head -10

log_info "已安装的模块文件:"
ls -la "$INSTALL_DIR/modules/" | head -10

# 检查关键模块
log_info "检查关键模块文件..."
critical_modules=("common_functions" "variable_management" "function_management" "unified_config" "wireguard_config")

for module in "${critical_modules[@]}"; do
    if [[ -f "$CURRENT_DIR/modules/${module}.sh" ]]; then
        log_success "✓ 当前项目有 ${module}.sh"
    else
        log_error "✗ 当前项目缺少 ${module}.sh"
    fi
    
    if [[ -f "$INSTALL_DIR/modules/${module}.sh" ]]; then
        log_success "✓ 已安装 ${module}.sh"
    else
        log_warn "✗ 已安装版本缺少 ${module}.sh"
    fi
done

# 检查主脚本
log_info "检查主脚本..."
if [[ -f "$CURRENT_DIR/ipv6-wireguard-manager.sh" ]]; then
    log_success "✓ 当前项目有主脚本"
else
    log_error "✗ 当前项目缺少主脚本"
fi

if [[ -f "$INSTALL_DIR/ipv6-wireguard-manager.sh" ]]; then
    log_success "✓ 已安装主脚本"
else
    log_error "✗ 已安装版本缺少主脚本"
fi

# 检查符号链接
log_info "检查符号链接..."
if [[ -L "/usr/local/bin/ipv6-wireguard-manager" ]]; then
    log_success "✓ 符号链接存在"
    log_info "符号链接指向: $(readlink /usr/local/bin/ipv6-wireguard-manager)"
else
    log_warn "✗ 符号链接不存在"
fi

log_info "修复建议:"
echo "1. 运行: sudo bash fix_installed_modules.sh"
echo "2. 或者重新安装: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash"
