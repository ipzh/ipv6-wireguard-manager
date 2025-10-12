#!/bin/bash

# IPv6 WireGuard Manager 一键安装脚本
# 支持 Docker 和原生安装，整合了所有问题解决方案

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

# 解析参数
INSTALL_TYPE=""
FORCE_INSTALL=false
SKIP_DEPENDENCIES=false
AUTO_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        "docker")
            INSTALL_TYPE="docker"
            shift
            ;;
        "native")
            INSTALL_TYPE="native"
            shift
            ;;
        "low-memory")
            INSTALL_TYPE="low-memory"
            shift
            ;;
        "--force")
            FORCE_INSTALL=true
            shift
            ;;
        "--skip-deps")
            SKIP_DEPENDENCIES=true
            shift
            ;;
        "--auto")
            AUTO_MODE=true
            shift
            ;;
        *)
            echo "用法: $0 [docker|native|low-memory] [--force] [--skip-deps] [--auto]"
            echo "  docker      - Docker 安装"
            echo "  native      - 原生安装"
            echo "  low-memory  - 低内存优化安装"
            echo "  --force     - 强制重新安装"
            echo "  --skip-deps - 跳过依赖检查"
            echo "  --auto      - 自动模式（非交互式）"
            echo "  无参数      - 自动选择"
            exit 1
            ;;
    esac
done

echo "=================================="
echo "IPv6 WireGuard Manager 一键安装"
echo "=================================="
if [ -n "$INSTALL_TYPE" ]; then
    echo "安装类型: $INSTALL_TYPE"
fi
echo ""

# 项目信息
REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager/archive/refs/heads/main.zip"
INSTALL_DIR="ipv6-wireguard-manager"
APP_USER="ipv6wgm"
APP_HOME="/opt/ipv6-wireguard-manager"
PROJECT_DIR="$(pwd)/$INSTALL_DIR"

# 系统信息检测
detect_system() {
    log_info "检测系统环境..."
    
    # 检测操作系统
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$NAME"
        OS_VERSION="$VERSION_ID"
        OS_CODENAME="$VERSION_CODENAME"
    else
        OS_NAME="Unknown"
        OS_VERSION="Unknown"
        OS_CODENAME="unknown"
    fi
    
    # 检测架构
    ARCH=$(uname -m)
    
    # 检测内存
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    
    # 检测CPU核心数
    CPU_CORES=$(nproc)
    
    # 检测磁盘空间
    DISK_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    
    # 检测网络连接
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        NETWORK_STATUS="connected"
    else
        NETWORK_STATUS="disconnected"
    fi
    
    # 检测WSL
    if grep -q Microsoft /proc/version 2>/dev/null; then
        IS_WSL=true
    else
        IS_WSL=false
    fi
    
    log_info "系统信息:"
    echo "  操作系统: $OS_NAME $OS_VERSION"
    echo "  架构: $ARCH"
    echo "  内存: ${TOTAL_MEM}MB"
    echo "  CPU核心: $CPU_CORES"
    echo "  可用磁盘: ${DISK_SPACE}GB"
    echo "  网络状态: $NETWORK_STATUS"
    echo "  WSL环境: $IS_WSL"
    echo ""
}

# 智能选择安装方式
auto_select_install_type() {
    if [ -n "$INSTALL_TYPE" ]; then
        return
    fi
    
    log_info "智能选择安装方式..."
    
    # 根据系统环境自动选择
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
    
    echo "自动选择: $INSTALL_TYPE"
    echo ""
}

# 显示安装选项
show_install_options() {
    if [ "$AUTO_MODE" = true ]; then
        return
    fi
    
    echo "🎯 安装方式选择:"
    echo "  1. Docker 安装 - 环境隔离，易于管理"
    echo "  2. 原生安装 - 性能最优，资源占用少"
    echo "  3. 低内存安装 - 专为1GB内存优化"
    echo "  4. 自动选择 - 根据系统环境智能选择"
    echo ""
    
    if [ -z "$INSTALL_TYPE" ]; then
        echo "请输入选择 (1-4): "
        read -r choice
        
        case $choice in
            1)
                INSTALL_TYPE="docker"
                ;;
            2)
                INSTALL_TYPE="native"
                ;;
            3)
                INSTALL_TYPE="low-memory"
                ;;
            4|"")
                auto_select_install_type
                ;;
            *)
                log_error "无效选择"
                exit 1
                ;;
        esac
    fi
}

# 检查并安装依赖
install_dependencies() {
    if [ "$SKIP_DEPENDENCIES" = true ]; then
        log_info "跳过依赖检查"
        return
    fi
    
    log_info "检查并安装系统依赖..."
    
    # 更新包列表
    apt-get update -qq
    
    # 基础工具
    local packages=(
        "curl"
        "wget"
        "unzip"
        "git"
        "sudo"
        "systemd"
        "ufw"
        "iptables"
        "iproute2"
        "net-tools"
        "procps"
        "psmisc"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
    )
    
    # 根据安装类型添加特定依赖
    case $INSTALL_TYPE in
        "docker")
            packages+=("docker.io" "docker-compose")
            ;;
        "native"|"low-memory")
            packages+=(
                "python3"
                "python3-pip"
                "python3-venv"
                "python3-dev"
                "build-essential"
                "libpq-dev"
                "pkg-config"
                "libssl-dev"
                "libffi-dev"
                "nodejs"
                "npm"
                "postgresql"
                "postgresql-contrib"
                "redis-server"
                "nginx"
                "supervisor"
                "exabgp"
            )
            ;;
    esac
    
    # 安装包
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            log_info "安装 $package..."
            apt-get install -y "$package" || log_warning "安装 $package 失败，继续..."
        else
            log_info "$package 已安装"
        fi
    done
    
    # 特殊处理Node.js版本
    if [ "$INSTALL_TYPE" != "docker" ]; then
        install_nodejs
    fi
    
    # 特殊处理Docker
    if [ "$INSTALL_TYPE" = "docker" ]; then
        install_docker
    fi
    
    log_success "依赖安装完成"
}

# 安装Node.js
install_nodejs() {
    log_info "安装Node.js..."
    
    # 检查Node.js版本
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
        if [ "$NODE_VERSION" -ge 18 ]; then
            log_info "Node.js 版本满足要求"
            return
        fi
    fi
    
    # 安装Node.js 18
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    
    log_success "Node.js 安装完成"
}

# 安装Docker
install_docker() {
    log_info "安装Docker..."
    
    if command -v docker >/dev/null 2>&1; then
        log_info "Docker 已安装"
        return
    fi
    
    # 根据系统选择Docker仓库
    case $OS_CODENAME in
        "jammy"|"focal"|"bionic")
            DOCKER_REPO="ubuntu"
            ;;
        "bullseye"|"buster")
            DOCKER_REPO="debian"
            ;;
        *)
            DOCKER_REPO="ubuntu"
            ;;
    esac
    
    # 安装Docker
    curl -fsSL https://download.docker.com/linux/$DOCKER_REPO/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$DOCKER_REPO $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # 启动Docker服务
    systemctl enable docker
    systemctl start docker
    
    # 添加用户到docker组
    usermod -aG docker $USER 2>/dev/null || true
    
    log_success "Docker 安装完成"
}

# 下载项目
download_project() {
    log_info "下载项目..."
    
    if [ -d "$INSTALL_DIR" ] && [ "$FORCE_INSTALL" = false ]; then
        log_info "项目目录已存在，使用现有目录"
        return
    fi
    
    # 清理旧目录
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
}

# 执行安装
execute_installation() {
    log_info "执行安装..."
    
    # 根据安装类型执行相应的安装脚本
    case $INSTALL_TYPE in
        "docker")
            if [ -f "$PROJECT_DIR/install-complete.sh" ]; then
                chmod +x "$PROJECT_DIR/install-complete.sh"
                "$PROJECT_DIR/install-complete.sh" docker
            else
                log_error "安装脚本不存在"
                exit 1
            fi
            ;;
        "native"|"low-memory")
            if [ -f "$PROJECT_DIR/install-complete.sh" ]; then
                chmod +x "$PROJECT_DIR/install-complete.sh"
                "$PROJECT_DIR/install-complete.sh" "$INSTALL_TYPE"
            else
                log_error "安装脚本不存在"
                exit 1
            fi
            ;;
        *)
            log_error "未知的安装类型: $INSTALL_TYPE"
            exit 1
            ;;
    esac
}

# 获取服务器IP
get_server_ip() {
    # 获取IPv4地址
    IPV4=$(ip route get 8.8.8.8 | awk '{print $7; exit}' 2>/dev/null || echo "未知")
    
    # 获取IPv6地址
    IPV6=$(ip -6 route get 2001:4860:4860::8888 | awk '{print $7; exit}' 2>/dev/null || echo "未知")
    
    echo "IPv4: $IPV4"
    echo "IPv6: $IPV6"
}

# 显示安装结果
show_installation_result() {
    echo ""
    echo "=================================="
    echo "安装完成！"
    echo "=================================="
    echo ""
    
    # 获取服务器IP
    log_info "服务器访问地址:"
    get_server_ip
    echo ""
    
    log_info "服务访问地址:"
    echo "  前端界面: http://$(hostname -I | awk '{print $1}')"
    echo "  后端API: http://127.0.0.1:8000"
    echo "  API文档: http://127.0.0.1:8000/docs"
    echo "  健康检查: http://127.0.0.1:8000/health"
    echo ""
    
    log_info "默认登录信息:"
    echo "  用户名: admin"
    echo "  密码: admin123"
    echo ""
    
    log_info "服务管理命令:"
    echo "  查看状态: systemctl status ipv6-wireguard-manager"
    echo "  重启服务: systemctl restart ipv6-wireguard-manager"
    echo "  查看日志: journalctl -u ipv6-wireguard-manager -f"
    echo ""
    
    log_info "问题修复:"
    echo "  如果遇到问题，请运行: ./fix-installation-issues.sh"
    echo ""
    
    log_success "安装完成！请访问前端界面开始使用。"
}

# 错误处理
handle_error() {
    log_error "安装过程中发生错误"
    log_error "错误位置: $1"
    log_error "请运行修复脚本: ./fix-installation-issues.sh"
    exit 1
}

# 主安装流程
main() {
    # 设置错误处理
    trap 'handle_error "未知位置"' ERR
    
    # 检查root权限
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root权限运行此脚本"
        exit 1
    fi
    
    # 检测系统
    detect_system
    
    # 显示安装选项
    show_install_options
    
    # 自动选择安装方式
    auto_select_install_type
    
    # 安装依赖
    install_dependencies
    
    # 下载项目
    download_project
    
    # 执行安装
    execute_installation
    
    # 显示安装结果
    show_installation_result
}

# 运行主函数
main "$@"