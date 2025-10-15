#!/bin/bash

# IPv6 WireGuard Manager - 增强版一键安装脚本
# 支持所有主流Linux发行版，IPv6/IPv4双栈网络
# 企业级VPN管理平台

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# 系统信息检测
detect_system() {
    log_info "检测系统信息..."
    
    # 检查操作系统
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_ID="$ID"
        OS_VERSION="$VERSION_ID"
        OS_NAME="$PRETTY_NAME"
    else
        log_error "不支持的操作系统：缺少 /etc/os-release 文件"
        exit 1
    fi
    
    # 检测架构
    ARCH=$(uname -m)
    
    # 检测包管理器
    if command -v apt-get &> /dev/null; then
        PACKAGE_MANAGER="apt"
    elif command -v yum &> /dev/null; then
        PACKAGE_MANAGER="yum"
    elif command -v dnf &> /dev/null; then
        PACKAGE_MANAGER="dnf"
    elif command -v pacman &> /dev/null; then
        PACKAGE_MANAGER="pacman"
    elif command -v zypper &> /dev/null; then
        PACKAGE_MANAGER="zypper"
    else
        log_error "未检测到支持的包管理器"
        exit 1
    fi
    
    # 检测系统资源
    MEMORY_MB=$(free -m | awk 'NR==2{print $2}')
    CPU_CORES=$(nproc)
    DISK_SPACE=$(df / | awk 'NR==2{print $4}')
    DISK_SPACE_MB=$((DISK_SPACE / 1024))
    
    log_success "系统信息:"
    log_info "  操作系统: $OS_NAME"
    log_info "  版本: $OS_VERSION"
    log_info "  架构: $ARCH"
    log_info "  包管理器: $PACKAGE_MANAGER"
    log_info "  内存: ${MEMORY_MB}MB"
    log_info "  CPU核心: $CPU_CORES"
    log_info "  可用磁盘: ${DISK_SPACE_MB}MB"
}

# 检查系统要求
check_requirements() {
    log_info "检查系统要求..."
    
    local requirements_ok=true
    
    # 检查内存变量是否已设置
    if [ -z "$MEMORY_MB" ] || [ "$MEMORY_MB" -lt 512 ]; then
        log_error "系统内存不足或未正确检测，至少需要512MB"
        requirements_ok=false
    elif [ "$MEMORY_MB" -lt 1024 ]; then
        log_warning "系统内存较少，建议使用低内存安装模式"
    fi
    
    # 检查磁盘空间变量是否已设置
    if [ -z "$DISK_SPACE_MB" ] || [ "$DISK_SPACE_MB" -lt 1024 ]; then
        log_error "磁盘空间不足或未正确检测，至少需要1GB"
        requirements_ok=false
    elif [ "$DISK_SPACE_MB" -lt 2048 ]; then
        log_warning "磁盘空间较少，建议至少2GB"
    fi
    
    # 检查网络连接
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log_warning "网络连接可能有问题"
    fi
    
    # 检查IPv6支持
    if ping6 -c 1 2001:4860:4860::8888 &> /dev/null; then
        log_success "IPv6网络连接正常"
        IPV6_SUPPORT=true
    else
        log_warning "IPv6网络连接不可用（可选）"
        IPV6_SUPPORT=false
    fi
    
    if [ "$requirements_ok" = false ]; then
        log_error "系统要求检查失败"
        exit 1
    fi
    
    log_success "系统要求检查通过"
}

# 自动选择最适合的安装类型
auto_select_install_type() {
    local recommended_type=""
    local reason=""
    
    # 根据系统资源选择最适合的安装方式
    if [ -z "$MEMORY_MB" ] || [ "$MEMORY_MB" -lt 1024 ]; then
        recommended_type="minimal"
        reason="内存不足1GB或未正确检测，推荐最小化安装"
    elif [ "$MEMORY_MB" -lt 2048 ]; then
        if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
            recommended_type="docker"
            reason="内存1-2GB且Docker可用，推荐Docker安装（更稳定）"
        else
            recommended_type="native"
            reason="内存1-2GB但Docker不可用，推荐原生安装"
        fi
    else
        if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
            recommended_type="docker"
            reason="内存充足且Docker可用，推荐Docker安装（最佳体验）"
        else
            recommended_type="native"
            reason="内存充足但Docker不可用，推荐原生安装（高性能）"
        fi
    fi
    
    echo "$recommended_type|$reason"
}

# 显示安装选项
show_install_options() {
    echo ""
    echo "=========================================="
    echo "🚀 IPv6 WireGuard Manager 安装选项"
    echo "=========================================="
    echo ""
    
    log_info "检测到的系统信息:"
    log_info "  操作系统: $OS_NAME"
    log_info "  内存: ${MEMORY_MB}MB"
    log_info "  CPU核心: $CPU_CORES"
    log_info "  IPv6支持: $([ "$IPV6_SUPPORT" = true ] && echo "是" || echo "否")"
    echo ""
    
    # 获取推荐安装方式
    local recommended_result=$(auto_select_install_type)
    local recommended_type=$(echo "$recommended_result" | cut -d'|' -f1)
    local recommended_reason=$(echo "$recommended_result" | cut -d'|' -f2)
    
    log_info "智能推荐:"
    log_success "  推荐安装方式: $recommended_type"
    log_info "  推荐理由: $recommended_reason"
    echo ""
    
    log_info "安装选项:"
    echo "🐳 1. Docker安装 (推荐新手)"
    echo "   ✅ 优点: 环境隔离、易于管理、一键部署"
    echo "   ❌ 缺点: 资源占用较高、性能略有损失"
    echo "   🎯 适用: 测试环境、开发环境、性能要求不高的场景"
    echo "   💾 内存要求: 2GB+"
    echo ""
    echo "⚡ 2. 原生安装 (推荐VPS)"
    echo "   ✅ 优点: 性能最优、资源占用最小、启动快速"
    echo "   ❌ 缺点: 依赖管理复杂、环境配置相对复杂"
    echo "   🎯 适用: 生产环境、VPS部署、高性能场景"
    echo "   💾 内存要求: 1GB+"
    echo ""
    echo "📦 3. 最小化安装 (低内存)"
    echo "   ✅ 优点: 资源占用最少、适合低配置服务器"
    echo "   ❌ 缺点: 功能有限、仅核心功能"
    echo "   🎯 适用: 低配置VPS、测试环境"
    echo "   💾 内存要求: 512MB+"
    echo ""
    echo "📊 性能对比:"
    echo "   💾 内存占用: Docker 2GB+ vs 原生 1GB+ vs 最小化 512MB+"
    echo "   ⚡ 启动速度: Docker 较慢 vs 原生 快速 vs 最小化 最快"
    echo "   🚀 性能表现: Docker 良好 vs 原生 最优 vs 最小化 基础"
    echo ""
    
    # 检查是否为非交互模式
    if [ ! -t 0 ] || [ "$1" = "--auto" ]; then
        log_info "检测到非交互模式，自动选择安装类型..."
        local auto_result=$(auto_select_install_type)
        local auto_type=$(echo "$auto_result" | cut -d'|' -f1)
        local auto_reason=$(echo "$auto_result" | cut -d'|' -f2)
        log_info "自动选择的安装类型: $auto_type"
        log_info "选择理由: $auto_reason"
        echo "$auto_type"
        return
    fi
    
    # 5秒倒计时选择
    echo ""
    log_info "5秒后将自动选择推荐方式，按任意键立即选择..."
    echo ""
    
    local choice=""
    local countdown=5
    
    # 倒计时循环
    while [ $countdown -gt 0 ]; do
        printf "\r⏰ 倒计时: %d 秒 (推荐: $recommended_type) " $countdown
        sleep 1
        countdown=$((countdown - 1))
    done
    
    echo ""
    echo ""
    
    # 检查是否有输入
    if read -t 0; then
        echo -n "请选择安装方式 (1-3, 回车使用推荐): "
        read -r choice
    else
        choice=""
    fi
    
    # 如果没有输入或输入为空，使用推荐方式
    if [ -z "$choice" ]; then
        log_info "使用推荐安装方式: $recommended_type"
        echo "$recommended_type"
        return
    fi
    
    case $choice in
        1) echo "docker" ;;
        2) echo "native" ;;
        3) echo "minimal" ;;
        *) 
            log_warning "无效选择，使用自动选择" >&2
            auto_select_install_type
            ;;
    esac
}

# 解析命令行参数
parse_arguments() {
    local install_type=""
    local install_dir="/opt/ipv6-wireguard-manager"
    local port="80"
    local silent=false
    local performance=false
    local production=false
    local debug=false
    local skip_deps=false
    local skip_db=false
    local skip_service=false
    
    # 检查是否通过管道执行（curl | bash）
    local is_piped=false
    if [ ! -t 0 ]; then
        is_piped=true
        # 如果是管道执行，检查是否有参数通过bash -s传递
        if [ $# -gt 0 ]; then
            # 重新解析参数（bash -s传递的参数）
            set -- $@
        fi
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            docker|native|minimal)
                install_type="$1"
                shift
                ;;
            --dir)
                install_dir="$2"
                shift 2
                ;;
            --port)
                port="$2"
                shift 2
                ;;
            --silent)
                silent=true
                shift
                ;;
            --performance)
                performance=true
                shift
                ;;
            --production)
                production=true
                shift
                ;;
            --debug)
                debug=true
                shift
                ;;
            --skip-deps)
                skip_deps=true
                shift
                ;;
            --skip-db)
                skip_db=true
                shift
                ;;
            --skip-service)
                skip_service=true
                shift
                ;;
            --auto)
                silent=true
                shift
                ;;
            --help|-h)
                show_help
                return 2
                ;;
            --version|-v)
                show_version
                return 2
                ;;
            *)
                # 如果是管道执行且第一个参数不是选项，可能是安装类型
                if [ "$is_piped" = true ] && [ -z "$install_type" ] && [[ "$1" =~ ^(docker|native|minimal)$ ]]; then
                    install_type="$1"
                    shift
                else
                    log_error "未知选项: $1"
                    show_help
                    return 1
                fi
                ;;
        esac
    done
    
    # 如果没有指定安装类型，自动选择
    if [ -z "$install_type" ]; then
        if [ "$silent" = true ] || [ "$is_piped" = true ] || [ ! -t 0 ]; then
            # 在管道模式下，将日志信息重定向到stderr，避免污染返回值
            log_info "自动选择安装类型..." >&2
            local auto_result=$(auto_select_install_type)
            install_type=$(echo "$auto_result" | cut -d'|' -f1)
            local auto_reason=$(echo "$auto_result" | cut -d'|' -f2)
            log_info "选择的安装类型: $install_type" >&2
            log_info "选择理由: $auto_reason" >&2
        else
            install_type=$(show_install_options)
        fi
    fi
    
    echo "$install_type|$install_dir|$port|$silent|$performance|$production|$debug|$skip_deps|$skip_db|$skip_service"
    return 0
}

# 显示版本信息
show_version() {
    echo "IPv6 WireGuard Manager 安装脚本"
    echo "版本: 3.0.0"
    echo "发布日期: $(date +%Y-%m-%d)"
    echo ""
    echo "功能特性:"
    echo "  ✅ 支持所有主流Linux发行版"
    echo "  ✅ IPv6/IPv4双栈网络支持"
    echo "  ✅ 多种安装方式 (Docker/原生/最小化)"
    echo "  ✅ 自动系统检测和配置"
    echo "  ✅ 企业级VPN管理功能"
    echo "  ✅ 完整的监控和日志系统"
    echo ""
    echo "支持的发行版:"
    echo "  • Ubuntu 20.04+"
    echo "  • Debian 11+"
    echo "  • CentOS 8+"
    echo "  • RHEL 8+"
    echo "  • Fedora 38+"
    echo "  • Arch Linux"
    echo "  • openSUSE 15+"
    echo ""
    echo "项目地址: https://github.com/ipzh/ipv6-wireguard-manager"
}

# 显示帮助信息
show_help() {
    echo "=========================================="
    echo "IPv6 WireGuard Manager 安装脚本"
    echo "=========================================="
    echo ""
    echo "用法: $0 [选项] [安装类型]"
    echo ""
    echo "安装类型:"
    echo "  docker      Docker安装 (推荐新手)"
    echo "  native      原生安装 (推荐VPS)"
    echo "  minimal     最小化安装 (低内存)"
    echo ""
    echo "选项:"
    echo "  --dir DIR       安装目录 (默认: /opt/ipv6-wireguard-manager)"
    echo "  --port PORT     Web服务器端口 (默认: 80)"
    echo "  --silent        静默安装 (无交互)"
    echo "  --performance   启用性能优化"
    echo "  --production    生产环境安装 (包含监控)"
    echo "  --debug         调试模式"
    echo "  --skip-deps     跳过依赖安装"
    echo "  --skip-db       跳过数据库安装"
    echo "  --skip-service  跳过服务安装"
    echo "  --auto          自动选择安装类型"
    echo "  --help, -h      显示此帮助信息"
    echo "  --version, -v   显示版本信息"
    echo ""
    echo "示例:"
    echo "  $0                                    # 交互式安装"
    echo "  $0 docker                            # Docker安装"
    echo "  $0 --dir /opt/my-app --port 8080     # 自定义目录和端口"
    echo "  $0 --silent --performance            # 静默安装并优化"
    echo "  $0 --production native               # 生产环境原生安装"
    echo "  $0 --debug minimal                   # 调试模式最小化安装"
    echo ""
    echo "快速安装:"
    echo "  curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash"
    echo ""
    echo "更多信息:"
    echo "  项目地址: https://github.com/ipzh/ipv6-wireguard-manager"
    echo "  问题反馈: https://github.com/ipzh/ipv6-wireguard-manager/issues"
}

# 主安装函数
main() {
    # 检查是否为管道执行
    local is_piped=false
    if [ ! -t 0 ]; then
        is_piped=true
        log_info "检测到管道执行模式，跳过root权限检查"
    else
        # 检查root权限（仅交互模式）
        if [[ $EUID -ne 0 ]]; then
            log_error "此脚本需要root权限运行"
            log_info "请使用: sudo $0 $*"
            exit 1
        fi
    fi
    
    # 解析参数
    local args
    args=$(parse_arguments "$@")
    local parse_result=$?
    
    # 检查参数解析结果
    if [ $parse_result -eq 2 ]; then
        # 帮助或版本信息已显示，直接退出
        exit 0
    elif [ $parse_result -ne 0 ]; then
        # 参数解析错误
        exit 1
    fi
    
    # 显示脚本信息（仅在正常安装模式下）
    echo "=========================================="
    echo "🚀 IPv6 WireGuard Manager 增强版安装脚本"
    echo "=========================================="
    echo ""
    log_info "版本: 3.0.0"
    log_info "所有FastAPI依赖注入问题已解决"
    log_info "支持IPv6/IPv4双栈网络"
    echo ""
    
    # 检测系统信息
    detect_system
    check_requirements
    
    IFS='|' read -r install_type install_dir port silent performance production debug skip_deps skip_db skip_service <<< "$args"
    
    log_info "安装配置:"
    log_info "  类型: $install_type"
    log_info "  目录: $install_dir"
    log_info "  端口: $port"
    log_info "  静默: $silent"
    log_info "  性能优化: $performance"
    log_info "  生产环境: $production"
    log_info "  调试模式: $debug"
    echo ""
    
    # 选择安装方式
    case $install_type in
        "docker")
            log_step "开始Docker安装..."
            run_docker_installation "$install_dir" "$port" "$silent" "$performance" "$production" "$debug"
            ;;
        "native")
            log_step "开始原生安装..."
            run_native_installation "$install_dir" "$port" "$silent" "$performance" "$production" "$debug" "$skip_deps" "$skip_db" "$skip_service"
            ;;
        "minimal")
            log_step "开始最小化安装..."
            run_minimal_installation "$install_dir" "$port" "$silent" "$debug" "$skip_deps" "$skip_db" "$skip_service"
            ;;
        *)
            log_error "无效的安装类型: $install_type"
            exit 1
            ;;
    esac
    
    # 显示安装完成信息
    show_installation_complete "$install_dir" "$port"
}

# Docker安装
run_docker_installation() {
    local install_dir="$1"
    local port="$2"
    local silent="$3"
    local performance="$4"
    local production="$5"
    local debug="$6"
    
    log_info "使用通用安装脚本进行Docker安装..."
    
    # 构建参数（使用正确的格式：-t docker）
    local complete_args="-t docker"
    [ "$install_dir" != "/opt/ipv6-wireguard-manager" ] && complete_args="$complete_args --dir $install_dir"
    [ "$port" != "80" ] && complete_args="$complete_args --port $port"
    [ "$silent" = true ] && complete_args="$complete_args --silent"
    [ "$performance" = true ] && complete_args="$complete_args --performance"
    [ "$production" = true ] && complete_args="$complete_args --production"
    [ "$debug" = true ] && complete_args="$complete_args --debug"
    
    # 检查是否为管道执行模式，如果是则使用sudo
    if [ ! -t 0 ]; then
        log_info "检测到管道执行模式，自动使用sudo权限..."
        # 下载并运行安装脚本（使用sudo）
        curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-universal.sh | sudo bash -s -- $complete_args
    else
        log_info "Docker安装参数: $complete_args"
        # 下载并运行安装脚本
        curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-universal.sh | bash -s -- $complete_args
    fi
}

# 原生安装
run_native_installation() {
    local install_dir="$1"
    local port="$2"
    local silent="$3"
    local performance="$4"
    local production="$5"
    local debug="$6"
    local skip_deps="$7"
    local skip_db="$8"
    local skip_service="$9"
    
    log_info "使用通用安装脚本进行原生安装..."
    
    # 构建参数（使用正确的格式：-t native）
    local complete_args="-t native"
    [ "$install_dir" != "/opt/ipv6-wireguard-manager" ] && complete_args="$complete_args --dir $install_dir"
    [ "$port" != "80" ] && complete_args="$complete_args --port $port"
    [ "$silent" = true ] && complete_args="$complete_args --silent"
    [ "$performance" = true ] && complete_args="$complete_args --performance"
    [ "$production" = true ] && complete_args="$complete_args --production"
    [ "$debug" = true ] && complete_args="$complete_args --debug"
    [ "$skip_deps" = true ] && complete_args="$complete_args --skip-deps"
    [ "$skip_db" = true ] && complete_args="$complete_args --skip-db"
    [ "$skip_service" = true ] && complete_args="$complete_args --skip-service"
    
    # 检查是否为管道执行模式，如果是则使用sudo
    if [ ! -t 0 ]; then
        log_info "检测到管道执行模式，自动使用sudo权限..."
        # 下载并运行安装脚本（使用sudo）
        curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-universal.sh | sudo bash -s -- $complete_args
    else
        # 下载并运行安装脚本
        curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-universal.sh | bash -s -- $complete_args
    fi
}

# 最小化安装
run_minimal_installation() {
    local install_dir="$1"
    local port="$2"
    local silent="$3"
    local debug="$4"
    local skip_deps="$5"
    local skip_db="$6"
    local skip_service="$7"
    
    log_info "使用通用安装脚本进行最小化安装..."
    
    # 构建参数（使用正确的格式：-t minimal）
    local complete_args="-t minimal"
    [ "$install_dir" != "/opt/ipv6-wireguard-manager" ] && complete_args="$complete_args --dir $install_dir"
    [ "$port" != "80" ] && complete_args="$complete_args --port $port"
    [ "$silent" = true ] && complete_args="$complete_args --silent"
    [ "$debug" = true ] && complete_args="$complete_args --debug"
    [ "$skip_deps" = true ] && complete_args="$complete_args --skip-deps"
    [ "$skip_db" = true ] && complete_args="$complete_args --skip-db"
    [ "$skip_service" = true ] && complete_args="$complete_args --skip-service"
    
    # 检查是否为管道执行模式，如果是则使用sudo
    if [ ! -t 0 ]; then
        log_info "检测到管道执行模式，自动使用sudo权限..."
        # 下载并运行安装脚本（使用sudo）
        curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-universal.sh | sudo bash -s -- $complete_args
    else
        # 下载并运行安装脚本
        curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-universal.sh | bash -s -- $complete_args
    fi
}

# 显示安装完成信息
show_installation_complete() {
    local install_dir="$1"
    local port="$2"
    
    echo ""
    echo "=========================================="
    echo "🎉 IPv6 WireGuard Manager 安装完成！"
    echo "=========================================="
    echo ""
    log_success "安装成功完成！"
    echo ""
    log_info "安装信息:"
    log_info "  安装目录: $install_dir"
    log_info "  访问端口: $port"
    log_info "  操作系统: $OS_NAME"
    echo ""
    log_info "访问地址:"
    log_info "  前端界面: http://localhost:$port"
    log_info "  API文档: http://localhost:$port/api/v1/docs"
    log_info "  健康检查: http://localhost:8000/health"
    echo ""
    log_info "管理命令:"
    log_info "  启动服务: systemctl start ipv6-wireguard-manager"
    log_info "  停止服务: systemctl stop ipv6-wireguard-manager"
    log_info "  重启服务: systemctl restart ipv6-wireguard-manager"
    log_info "  查看状态: systemctl status ipv6-wireguard-manager"
    log_info "  查看日志: journalctl -u ipv6-wireguard-manager -f"
    echo ""
    log_info "默认登录信息:"
    log_info "  用户名: admin"
    log_info "  密码: admin123"
    echo ""
    log_info "更多信息:"
    log_info "  项目地址: https://github.com/ipzh/ipv6-wireguard-manager"
    log_info "  问题反馈: https://github.com/ipzh/ipv6-wireguard-manager/issues"
    echo ""
}

# Run main function
main "$@"