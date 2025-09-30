#!/bin/bash

# 修复已安装的模块文件
# 将当前项目目录的模块文件复制到安装目录

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
# YELLOW=  # unused'\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
    log_error "此脚本需要以root权限运行"
    log_error "请使用: sudo $0"
    exit 1
fi

# 安装目录
INSTALL_DIR="/opt/ipv6-wireguard-manager"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit

log_info "开始修复已安装的模块文件..."

# 检查安装目录是否存在
if [[ ! -d "$INSTALL_DIR" ]]; then
    log_error "安装目录不存在: $INSTALL_DIR"
    log_error "请先运行安装脚本"
    exit 1
fi

# 检查当前目录是否有模块文件
if [[ ! -d "$CURRENT_DIR/modules" ]]; then
    log_error "当前目录没有modules文件夹: $CURRENT_DIR/modules"
    exit 1
fi

# 备份现有模块
log_info "备份现有模块文件..."
if [[ -d "$INSTALL_DIR/modules" ]]; then
    cp -r "$INSTALL_DIR/modules" "$INSTALL_DIR/modules.backup.$(date +%Y%m%d_%H%M%S)"
    log_success "现有模块已备份"
fi

# 创建模块目录
mkdir -p "$INSTALL_DIR/modules"

# 复制新的模块文件
log_info "复制新的模块文件..."
cp -r "$CURRENT_DIR/modules"/* "$INSTALL_DIR/modules/"
chmod +x "$INSTALL_DIR/modules"/*.sh

# 验证关键模块是否存在
log_info "验证关键模块..."
critical_modules=("common_functions" "variable_management" "function_management" "unified_config" "wireguard_config")

for module in "${critical_modules[@]}"; do
    if [[ -f "$INSTALL_DIR/modules/${module}.sh" ]]; then
        log_success "✓ ${module}.sh 已安装"
    else
        log_error "✗ ${module}.sh 未找到"
    fi
done

# 复制主脚本
log_info "更新主脚本..."
if [[ -f "$CURRENT_DIR/ipv6-wireguard-manager.sh" ]]; then
    cp "$CURRENT_DIR/ipv6-wireguard-manager.sh" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/ipv6-wireguard-manager.sh"
    
    # 更新符号链接
    if [[ -L "/usr/local/bin/ipv6-wireguard-manager" ]]; then
        ln -sf "$INSTALL_DIR/ipv6-wireguard-manager.sh" "/usr/local/bin/ipv6-wireguard-manager"
        log_success "符号链接已更新"
    fi
    
    log_success "主脚本已更新"
else
    log_error "主脚本文件不存在: $CURRENT_DIR/ipv6-wireguard-manager.sh"
fi

# 复制配置文件
log_info "更新配置文件..."
if [[ -d "$CURRENT_DIR/config" ]]; then
    mkdir -p "$INSTALL_DIR/config"
    cp -r "$CURRENT_DIR/config"/* "$INSTALL_DIR/config/"
    log_success "配置文件已更新"
fi

# 复制示例文件
log_info "更新示例文件..."
if [[ -d "$CURRENT_DIR/examples" ]]; then
    mkdir -p "$INSTALL_DIR/examples"
    cp -r "$CURRENT_DIR/examples"/* "$INSTALL_DIR/examples/"
    log_success "示例文件已更新"
fi

# 复制文档文件
log_info "更新文档文件..."
if [[ -d "$CURRENT_DIR/docs" ]]; then
    mkdir -p "$INSTALL_DIR/docs"
    cp -r "$CURRENT_DIR/docs"/* "$INSTALL_DIR/docs/"
    log_success "文档文件已更新"
fi

# 测试修复结果
log_info "测试修复结果..."
if [[ -f "$INSTALL_DIR/modules/common_functions.sh" ]]; then
    log_success "✓ common_functions.sh 修复成功"
else
    log_error "✗ common_functions.sh 修复失败"
fi

# 显示安装信息
log_info "修复完成！"
echo
echo "安装目录: $INSTALL_DIR"
echo "模块目录: $INSTALL_DIR/modules"
echo "主脚本: $INSTALL_DIR/ipv6-wireguard-manager.sh"
echo
echo "现在可以运行:"
echo "  sudo ipv6-wireguard-manager"
echo "  或"
echo "  sudo $INSTALL_DIR/ipv6-wireguard-manager.sh"
