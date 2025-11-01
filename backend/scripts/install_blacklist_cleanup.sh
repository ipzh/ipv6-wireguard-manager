#!/bin/bash
# 令牌黑名单清理服务安装脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
   log_error "此脚本需要root权限运行"
   exit 1
fi

# 项目路径
PROJECT_PATH="/opt/ipv6-wireguard-manager"
BACKEND_PATH="$PROJECT_PATH/backend"
SYSTEMD_PATH="/etc/systemd/system"

# 检查项目路径是否存在
if [ ! -d "$PROJECT_PATH" ]; then
    log_error "项目路径不存在: $PROJECT_PATH"
    exit 1
fi

# 检查后端路径是否存在
if [ ! -d "$BACKEND_PATH" ]; then
    log_error "后端路径不存在: $BACKEND_PATH"
    exit 1
fi

# 检查清理脚本是否存在
CLEANUP_SCRIPT="$BACKEND_PATH/scripts/cleanup_blacklist.py"
if [ ! -f "$CLEANUP_SCRIPT" ]; then
    log_error "清理脚本不存在: $CLEANUP_SCRIPT"
    exit 1
fi

# 确保清理脚本可执行
chmod +x "$CLEANUP_SCRIPT"

# 安装systemd服务
log_info "安装令牌黑名单清理服务..."

# 复制服务文件
cp "$BACKEND_PATH/systemd/wireguard-blacklist-cleanup.service" "$SYSTEMD_PATH/"
cp "$BACKEND_PATH/systemd/wireguard-blacklist-cleanup.timer" "$SYSTEMD_PATH/"

# 重新加载systemd配置
systemctl daemon-reload

# 启用并启动定时器
systemctl enable wireguard-blacklist-cleanup.timer
systemctl start wireguard-blacklist-cleanup.timer

# 检查服务状态
if systemctl is-active --quiet wireguard-blacklist-cleanup.timer; then
    log_info "令牌黑名单清理定时器已成功启动"
else
    log_error "令牌黑名单清理定时器启动失败"
    exit 1
fi

# 显示定时器状态
log_info "定时器状态:"
systemctl list-timers wireguard-blacklist-cleanup.timer --all

# 显示下次执行时间
NEXT_RUN=$(systemctl list-timers wireguard-blacklist-cleanup.timer --next | tail -n 1 | awk '{print $1, $2, $3, $4}')
log_info "下次执行时间: $NEXT_RUN"

# 测试清理脚本
log_info "测试清理脚本..."
sudo -u www-data python3 "$CLEANUP_SCRIPT" --dry-run --verbose

log_info "令牌黑名单清理服务安装完成"
log_info "服务将每天自动运行一次，清理过期的令牌"
log_info "您可以使用以下命令管理服务:"
log_info "  启动: systemctl start wireguard-blacklist-cleanup.timer"
log_info "  停止: systemctl stop wireguard-blacklist-cleanup.timer"
log_info "  重启: systemctl restart wireguard-blacklist-cleanup.timer"
log_info "  状态: systemctl status wireguard-blacklist-cleanup.timer"
log_info "  手动运行: systemctl start wireguard-blacklist-cleanup.service"