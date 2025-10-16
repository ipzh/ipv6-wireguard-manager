#!/bin/bash

# IPv6 WireGuard Manager - 智能安装启动器
# 一键智能安装，自动配置参数并退出

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# 显示欢迎信息
echo ""
log_success "IPv6 WireGuard Manager - 智能安装启动器"
echo ""
log_info "此脚本将自动执行以下操作："
log_info "1. 检测系统环境和资源"
log_info "2. 根据系统资源自动选择最佳安装类型"
log_info "3. 自动配置安装参数（端口、目录等）"
log_info "4. 执行安装并自动退出"
echo ""
log_warning "注意：安装过程可能需要几分钟，请耐心等待"
echo ""

# 询问用户是否继续
read -p "是否继续智能安装？(y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "安装已取消"
    exit 0
fi

# 执行智能安装
log_info "开始智能安装..."
echo ""

# 调用主安装脚本并传递--auto参数
exec "$SCRIPT_DIR/install.sh" --auto