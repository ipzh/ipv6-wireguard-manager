$content = @'
#!/bin/bash

# IPv6 WireGuard Manager 一键安装脚本
# 修复了非交互式模式（curl | bash）的问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

echo "=================================="
echo "IPv6 WireGuard Manager 一键安装"
echo "=================================="

# 检查root权限
if [ "$EUID" -ne 0 ]; then
    log_error "请使用root权限运行此脚本"
    exit 1
fi

# 检测系统环境
log_info "检测系统环境..."

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME="$NAME"
    OS_VERSION="$VERSION_ID"
else
    OS_NAME="Unknown"
    OS_VERSION="Unknown"
fi

# 检测内存
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')

# 检测WSL
if grep -q Microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
else
    IS_WSL=false
fi

log_info "系统信息:"
echo "  操作系统: $OS_NAME $OS_VERSION"
echo "  内存: ${TOTAL_MEM}MB"
echo "  WSL环境: $IS_WSL"
echo ""

# 智能选择安装方式
log_info "智能选择安装方式..."

if [ "$TOTAL_MEM" -lt 1024 ]; then
    INSTALL_TYPE="low-memory"
    log_warning "内存不足1GB，选择低内存安装"
elif [ "$IS_WSL" = true ]; then
    INSTALL_TYPE="native"
    log_info "检测到WSL环境，选择原生安装"
elif [ "$TOTAL_MEM" -lt 2048 ]; then
    INSTALL_TYPE="native"
    log_info "内存较少，选择原生安装（性能更优）"
else
    INSTALL_TYPE="docker"
    log_info "内存充足，选择Docker安装（环境隔离）"
fi

log_info "自动选择: $INSTALL_TYPE"
echo ""

# 项目信息
REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager/archive/refs/heads/main.zip"
INSTALL_DIR="ipv6-wireguard-manager"
PROJECT_DIR="$(pwd)/$INSTALL_DIR"

# 下载项目
log_info "下载项目..."

if [ -d "$INSTALL_DIR" ]; then
    log_info "清理旧项目目录..."
    rm -rf "$INSTALL_DIR"
fi

# 下载项目
if command -v wget >/dev/null 2>&1; then
    log_info "使用wget下载项目..."
    wget -q "$REPO_URL" -O project.zip
elif command -v curl >/dev/null 2>&1; then
    log_info "使用curl下载项目..."
    curl -fsSL "$REPO_URL" -o project.zip
else
    log_error "需要wget或curl来下载项目"
    exit 1
fi

# 解压项目
unzip -q project.zip
rm project.zip

# 重命名目录
if [ -d "ipv6-wireguard-manager-main" ]; then
    mv ipv6-wireguard-manager-main "$INSTALL_DIR"
fi

log_success "项目下载完成"

# 执行安装
log_info "执行安装..."

if [ -f "$PROJECT_DIR/install-complete.sh" ]; then
    chmod +x "$PROJECT_DIR/install-complete.sh"
    "$PROJECT_DIR/install-complete.sh" "$INSTALL_TYPE"
else
    log_error "安装脚本不存在"
    exit 1
fi

# 显示安装结果
echo ""
echo "=================================="
echo "安装完成！"
echo "=================================="
echo ""

log_info "服务访问地址:"
echo "  前端界面: http://$(hostname -I | awk '{print $1}')"
echo "  后端API: http://127.0.0.1:8000"
echo "  API文档: http://127.0.0.1:8000/docs"
echo ""

log_info "默认登录信息:"
echo "  用户名: admin"
echo "  密码: admin123"
echo ""

log_success "安装完成！请访问前端界面开始使用。"
'@

# 使用UTF8编码写入文件，确保使用Unix换行符
[System.IO.File]::WriteAllText("install.sh", $content, [System.Text.UTF8Encoding]::new($false))
