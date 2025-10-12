#!/bin/bash

# IPv6 WireGuard Manager - 智能安装器
# 自动检测系统环境并选择最佳安装方式

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="IPv6 WireGuard Manager"
PROJECT_VERSION="3.0.0"
REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager.git"

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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${CYAN}"
    echo "=========================================="
    echo "  $PROJECT_NAME v$PROJECT_VERSION"
    echo "  智能安装器"
    echo "=========================================="
    echo -e "${NC}"
    echo "🎯 自动检测系统环境并选择最佳安装方式"
    echo "📦 支持 Docker 和原生安装"
    echo "⚡ 优化构建过程，提升安装体验"
    echo ""
}

# 系统检测
detect_system() {
    log_step "检测系统环境..."
    
    # 检测操作系统
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$NAME"
        OS_VERSION="$VERSION_ID"
        OS_ID="$ID"
    else
        log_error "无法检测操作系统"
        exit 1
    fi
    
    # 检测系统架构
    ARCH=$(uname -m)
    
    # 检测系统资源
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    CPU_CORES=$(nproc)
    DISK_AVAIL=$(df -h . | awk 'NR==2 {print $4}')
    
    # 检测网络连接
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        NETWORK_STATUS="connected"
    else
        NETWORK_STATUS="disconnected"
    fi
    
    # 检测已安装的软件
    DOCKER_INSTALLED=false
    DOCKER_COMPOSE_INSTALLED=false
    PYTHON_INSTALLED=false
    NODE_INSTALLED=false
    GIT_INSTALLED=false
    
    if command -v docker >/dev/null 2>&1; then
        DOCKER_INSTALLED=true
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    fi
    
    if command -v docker-compose >/dev/null 2>&1 || docker compose version >/dev/null 2>&1; then
        DOCKER_COMPOSE_INSTALLED=true
    fi
    
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_INSTALLED=true
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    fi
    
    if command -v node >/dev/null 2>&1; then
        NODE_INSTALLED=true
        NODE_VERSION=$(node --version)
    fi
    
    if command -v git >/dev/null 2>&1; then
        GIT_INSTALLED=true
        GIT_VERSION=$(git --version | cut -d' ' -f3)
    fi
    
    # 显示系统信息
    echo "🖥️  系统信息:"
    echo "   操作系统: $OS_NAME $OS_VERSION"
    echo "   架构: $ARCH"
    echo "   内存: ${TOTAL_MEM}MB"
    echo "   CPU核心: $CPU_CORES"
    echo "   可用磁盘: $DISK_AVAIL"
    echo "   网络状态: $NETWORK_STATUS"
    echo ""
    
    echo "📦 已安装软件:"
    echo "   Docker: $([ "$DOCKER_INSTALLED" = true ] && echo "✅ $DOCKER_VERSION" || echo "❌ 未安装")"
    echo "   Docker Compose: $([ "$DOCKER_COMPOSE_INSTALLED" = true ] && echo "✅ 已安装" || echo "❌ 未安装")"
    echo "   Python3: $([ "$PYTHON_INSTALLED" = true ] && echo "✅ $PYTHON_VERSION" || echo "❌ 未安装")"
    echo "   Node.js: $([ "$NODE_INSTALLED" = true ] && echo "✅ $NODE_VERSION" || echo "❌ 未安装")"
    echo "   Git: $([ "$GIT_INSTALLED" = true ] && echo "✅ $GIT_VERSION" || echo "❌ 未安装")"
    echo ""
}

# 智能选择安装方式
choose_installation_method() {
    log_step "智能选择安装方式..."
    
    # 检查网络连接
    if [ "$NETWORK_STATUS" != "connected" ]; then
        log_error "网络连接异常，无法下载项目"
        exit 1
    fi
    
    # 检查磁盘空间
    DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 90 ]; then
        log_error "磁盘空间不足，请清理磁盘后重试"
        exit 1
    fi
    
    # 智能选择逻辑
    if [ "$TOTAL_MEM" -lt 1024 ]; then
        INSTALL_METHOD="low-memory"
        log_warning "⚠️  内存不足1GB，推荐使用低内存优化安装"
        echo "   预计安装时间: 20-50分钟"
        echo "   将自动创建swap空间和优化构建"
    elif [ "$DOCKER_INSTALLED" = true ] && [ "$DOCKER_COMPOSE_INSTALLED" = true ] && [ "$TOTAL_MEM" -gt 2048 ]; then
        INSTALL_METHOD="docker"
        log_success "推荐使用 Docker 安装（环境完整，内存充足）"
    elif [ "$PYTHON_INSTALLED" = true ] && [ "$NODE_INSTALLED" = true ] && [ "$TOTAL_MEM" -gt 1024 ]; then
        INSTALL_METHOD="native"
        log_success "推荐使用原生安装（依赖完整，性能更优）"
    elif [ "$TOTAL_MEM" -gt 2048 ]; then
        INSTALL_METHOD="docker"
        log_warning "推荐使用 Docker 安装（需要安装 Docker）"
    else
        INSTALL_METHOD="native"
        log_warning "推荐使用原生安装（内存较少，性能更优）"
    fi
    
    echo ""
    echo "🎯 安装方式选择:"
    echo "   1. Docker 安装 - 环境隔离，易于管理"
    echo "   2. 原生安装 - 性能最优，资源占用少"
    echo "   3. 低内存安装 - 专为1GB内存优化"
    echo "   4. 自动选择 - 根据系统环境智能选择"
    echo ""
    
    # 用户选择（支持非交互式模式和倒计时）
    if [ -t 0 ]; then
        # 交互式模式 - 10秒倒计时
        echo "⏰ 10秒后自动选择: $INSTALL_METHOD"
        echo "   如需手动选择，请在倒计时结束前输入数字 (1-4)"
        echo ""
        
        # 倒计时显示函数
        show_countdown() {
            local seconds=10
            while [ $seconds -gt 0 ]; do
                printf "\r⏳ 倒计时: %2d 秒 (自动选择: $INSTALL_METHOD) " $seconds
                sleep 1
                seconds=$((seconds-1))
            done
            echo ""
        }
        
        # 后台运行倒计时
        show_countdown &
        COUNTDOWN_PID=$!
        
        # 使用read的超时功能
        if read -t 10 -p "请选择安装方式 (1/2/3/4): " choice; then
            # 用户输入了选择，停止倒计时
            kill $COUNTDOWN_PID 2>/dev/null || true
            echo ""
            log_info "用户选择: $choice"
        else
            # 超时，使用自动选择
            kill $COUNTDOWN_PID 2>/dev/null || true
            echo ""
            log_info "⏰ 10秒超时，使用自动选择: $INSTALL_METHOD"
            choice=4
        fi
    else
        # 非交互式模式（管道执行）
        log_info "检测到非交互式模式，使用自动选择: $INSTALL_METHOD"
        choice=4
    fi
    
    case $choice in
        1)
            INSTALL_METHOD="docker"
            log_info "用户选择: Docker 安装"
            ;;
        2)
            INSTALL_METHOD="native"
            log_info "用户选择: 原生安装"
            ;;
        3)
            INSTALL_METHOD="low-memory"
            log_info "用户选择: 低内存安装"
            ;;
        4)
            log_info "用户选择: 自动选择 ($INSTALL_METHOD)"
            ;;
        *)
            log_warning "无效选择，使用自动选择 ($INSTALL_METHOD)"
            ;;
    esac
    
    echo ""
}

# 安装Git
install_git() {
    log_info "安装 Git..."
    
    case "$OS_ID" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y git
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y git
            else
                sudo yum install -y git
            fi
            ;;
        alpine)
            sudo apk add --no-cache git
            ;;
        *)
            log_error "不支持的操作系统: $OS_ID"
            exit 1
            ;;
    esac
    
    if command -v git >/dev/null 2>&1; then
        log_success "Git 安装成功"
    else
        log_error "Git 安装失败"
        exit 1
    fi
}

# 下载项目
download_project() {
    log_step "下载项目..."
    
    # 检查Git是否已安装
    if [ "$GIT_INSTALLED" != true ]; then
        log_warning "Git 未安装，正在自动安装..."
        install_git
    fi
    
    # 检查是否已存在项目目录
    if [ -d "ipv6-wireguard-manager" ]; then
        if [ -t 0 ]; then
            # 交互式模式
            log_warning "项目目录已存在，是否重新下载？"
            read -p "输入 y 重新下载，其他键跳过: " reinstall
            if [ "$reinstall" = "y" ] || [ "$reinstall" = "Y" ]; then
                log_info "删除现有项目目录..."
                rm -rf ipv6-wireguard-manager
            else
                log_info "使用现有项目目录"
                cd ipv6-wireguard-manager || exit 1
                log_info "进入项目目录: $(pwd)"
                return 0
            fi
        else
            # 非交互式模式，自动使用现有目录
            log_info "项目目录已存在，使用现有目录"
            cd ipv6-wireguard-manager || exit 1
            log_info "进入项目目录: $(pwd)"
            return 0
        fi
    fi
    
    # 下载项目
    log_info "从 GitHub 下载项目..."
    if git clone "$REPO_URL" ipv6-wireguard-manager; then
        log_success "项目下载成功"
    else
        log_error "项目下载失败"
        exit 1
    fi
    
    # 进入项目目录
    cd ipv6-wireguard-manager || exit 1
    log_info "进入项目目录: $(pwd)"
}

# 执行安装
execute_installation() {
    log_step "执行安装..."
    
    # 调试信息
    log_info "当前目录: $(pwd)"
    log_info "安装方式: $INSTALL_METHOD"
    log_info "检查文件: install-robust.sh"
    if [ -f "install-robust.sh" ]; then
        log_info "✅ install-robust.sh 存在"
    else
        log_info "❌ install-robust.sh 不存在"
        log_info "当前目录文件列表:"
        ls -la
    fi
    
    case $INSTALL_METHOD in
        "docker")
            log_info "使用 Docker 安装..."
            if [ -f "install-robust.sh" ]; then
                bash install-robust.sh docker
            else
                log_error "Docker 安装脚本不存在"
                exit 1
            fi
            ;;
        "native")
            log_info "使用原生安装..."
            if [ -f "install-robust.sh" ]; then
                bash install-robust.sh native
            else
                log_error "原生安装脚本不存在"
                exit 1
            fi
            ;;
        "low-memory")
            log_info "使用低内存优化安装..."
            if [ -f "install-robust.sh" ]; then
                bash install-robust.sh low-memory
            else
                log_error "安装脚本不存在"
                exit 1
            fi
            ;;
        *)
            log_error "未知的安装方式: $INSTALL_METHOD"
            exit 1
            ;;
    esac
}

# 验证安装
verify_installation() {
    log_step "验证安装..."
    
    # 检查服务状态
    if [ "$INSTALL_METHOD" = "docker" ]; then
        if docker ps | grep -q "ipv6-wireguard"; then
            log_success "Docker 服务运行正常"
        else
            log_warning "Docker 服务可能未正常启动"
        fi
    else
        # 检查原生服务
        if systemctl is-active --quiet ipv6-wireguard-backend; then
            log_success "后端服务运行正常"
        else
            log_warning "后端服务可能未正常启动"
        fi
        
        if systemctl is-active --quiet ipv6-wireguard-frontend; then
            log_success "前端服务运行正常"
        else
            log_warning "前端服务可能未正常启动"
        fi
    fi
    
    # 获取访问地址
    get_access_urls
}

# 获取访问地址
get_access_urls() {
    log_step "获取访问地址..."
    
    # 获取公网IP
    PUBLIC_IPV4=$(curl -s -4 ifconfig.me 2>/dev/null || echo "localhost")
    PUBLIC_IPV6=$(curl -s -6 ifconfig.me 2>/dev/null || echo "")
    
    # 获取内网IP
    LOCAL_IPV4=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
    LOCAL_IPV6=$(ip -6 route get 2001:4860:4860::8888 | awk '{print $7; exit}' 2>/dev/null || echo "")
    
    echo ""
    echo -e "${GREEN}🎉 安装完成！${NC}"
    echo ""
    echo "🌐 访问地址:"
    echo "   前端界面:"
    echo "     IPv4: http://$PUBLIC_IPV4:3000"
    echo "     IPv4 (本地): http://$LOCAL_IPV4:3000"
    if [ -n "$PUBLIC_IPV6" ] && [ "$PUBLIC_IPV6" != "localhost" ]; then
        echo "     IPv6: http://[$PUBLIC_IPV6]:3000"
    fi
    if [ -n "$LOCAL_IPV6" ] && [ "$LOCAL_IPV6" != "localhost" ]; then
        echo "     IPv6 (本地): http://[$LOCAL_IPV6]:3000"
    fi
    echo ""
    echo "🔧 管理命令:"
    if [ "$INSTALL_METHOD" = "docker" ]; then
        echo "   查看日志: docker-compose logs -f"
        echo "   重启服务: docker-compose restart"
        echo "   停止服务: docker-compose down"
    else
        echo "   查看后端日志: journalctl -u ipv6-wireguard-backend -f"
        echo "   查看前端日志: journalctl -u ipv6-wireguard-frontend -f"
        echo "   重启服务: systemctl restart ipv6-wireguard-backend ipv6-wireguard-frontend"
    fi
    echo ""
    echo "📚 更多信息:"
    echo "   项目文档: https://github.com/ipzh/ipv6-wireguard-manager"
    echo "   问题反馈: https://github.com/ipzh/ipv6-wireguard-manager/issues"
    echo ""
}

# 主函数
main() {
    # 检查是否为管道执行模式
    if [ ! -t 0 ]; then
        log_info "检测到管道执行模式，使用自动安装..."
        # 直接执行自动安装逻辑
        show_welcome
        detect_system
        choose_installation_method
        download_project
        execute_installation
        verify_installation
        return
    fi
    
    # 交互式模式
    show_welcome
    detect_system
    choose_installation_method
    download_project
    execute_installation
    verify_installation
}

# 错误处理
trap 'log_error "安装过程中发生错误，请检查日志"; exit 1' ERR

# 执行主函数
main "$@"