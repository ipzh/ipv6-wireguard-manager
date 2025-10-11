#!/bin/bash

# IPv6 WireGuard Manager 统一安装脚本
# 支持Docker和原生两种安装方式

set -e

echo "=================================="
echo "IPv6 WireGuard Manager 一键安装"
echo "=================================="
echo ""

# 项目信息
REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager.git"
INSTALL_DIR="ipv6-wireguard-manager"

# 检测服务器IP地址
get_server_ip() {
    echo "🌐 检测服务器IP地址..."
    
    # 检测IPv4地址
    PUBLIC_IPV4=""
    LOCAL_IPV4=""
    
    if command -v curl >/dev/null 2>&1; then
        PUBLIC_IPV4=$(curl -s --connect-timeout 5 --max-time 10 \
            https://ipv4.icanhazip.com 2>/dev/null || \
            curl -s --connect-timeout 5 --max-time 10 \
            https://api.ipify.org 2>/dev/null)
    fi
    
    if command -v ip >/dev/null 2>&1; then
        LOCAL_IPV4=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    elif command -v hostname >/dev/null 2>&1; then
        LOCAL_IPV4=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    
    # 检测IPv6地址
    PUBLIC_IPV6=""
    LOCAL_IPV6=""
    
    if command -v curl >/dev/null 2>&1; then
        PUBLIC_IPV6=$(curl -s --connect-timeout 5 --max-time 10 \
            https://ipv6.icanhazip.com 2>/dev/null || \
            curl -s --connect-timeout 5 --max-time 10 \
            https://api64.ipify.org 2>/dev/null)
    fi
    
    if command -v ip >/dev/null 2>&1; then
        LOCAL_IPV6=$(ip -6 route get 2001:4860:4860::8888 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    fi
    
    # 设置IP地址
    if [ -n "$PUBLIC_IPV4" ]; then
        SERVER_IPV4="$PUBLIC_IPV4"
    elif [ -n "$LOCAL_IPV4" ]; then
        SERVER_IPV4="$LOCAL_IPV4"
    else
        SERVER_IPV4="localhost"
    fi
    
    if [ -n "$PUBLIC_IPV6" ]; then
        SERVER_IPV6="$PUBLIC_IPV6"
    elif [ -n "$LOCAL_IPV6" ]; then
        SERVER_IPV6="$LOCAL_IPV6"
    fi
    
    echo "   IPv4: $SERVER_IPV4"
    if [ -n "$SERVER_IPV6" ]; then
        echo "   IPv6: $SERVER_IPV6"
    fi
    echo ""
}

# 显示安装方式选择菜单
show_installation_menu() {
    echo "请选择安装方式："
    echo ""
    echo "🐳 1. Docker安装（推荐新手）"
    echo "   - 优点: 环境隔离，易于管理，支持一键部署"
    echo "   - 缺点: 资源占用较高，性能略有损失"
    echo "   - 适用: 测试环境、开发环境、对性能要求不高的场景"
    echo "   - 内存需求: 2GB+"
    echo ""
    echo "⚡ 2. 原生安装（推荐VPS）"
    echo "   - 优点: 性能最优，资源占用最小，启动速度快"
    echo "   - 缺点: 需要手动管理依赖，环境配置相对复杂"
    echo "   - 适用: 生产环境、VPS部署、对性能要求高的场景"
    echo "   - 内存需求: 1GB+"
    echo ""
    echo "📊 性能对比："
    echo "   - 内存占用: Docker 2GB+ vs 原生 1GB+"
    echo "   - 启动速度: Docker 较慢 vs 原生 快速"
    echo "   - 性能: Docker 良好 vs 原生 最优"
    echo ""
}

# 获取用户选择
get_user_choice() {
    while true; do
        echo -n "请输入选择 (1 或 2): "
        read -r choice
        
        case $choice in
            1)
                INSTALL_TYPE="docker"
                echo ""
                echo "✅ 您选择了 Docker 安装方式"
                echo ""
                break
                ;;
            2)
                INSTALL_TYPE="native"
                echo ""
                echo "✅ 您选择了 原生 安装方式"
                echo ""
                break
                ;;
            *)
                echo "❌ 无效选择，请输入 1 或 2"
                echo ""
                ;;
        esac
    done
}

# 自动选择安装方式
auto_select_installation() {
    echo "🤖 自动检测最佳安装方式..."
    
    # 检测系统资源
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    CPU_CORES=$(nproc)
    
    echo "   系统内存: ${TOTAL_MEM}MB"
    echo "   CPU核心: ${CPU_CORES}"
    
    # 检测是否为VPS环境
    IS_VPS=false
    if [ -f /proc/user_beancounters ] || [ -f /proc/vz/version ]; then
        IS_VPS=true
        echo "   环境类型: VPS/容器"
    else
        echo "   环境类型: 物理机/虚拟机"
    fi
    
    # 自动选择逻辑
    if [ "$TOTAL_MEM" -lt 2048 ]; then
        INSTALL_TYPE="native"
        echo "   选择原因: 内存不足2GB，选择原生安装"
    elif [ "$IS_VPS" = true ] && [ "$TOTAL_MEM" -lt 4096 ]; then
        INSTALL_TYPE="native"
        echo "   选择原因: VPS环境且内存小于4GB，选择原生安装"
    else
        INSTALL_TYPE="docker"
        echo "   选择原因: 资源充足，选择Docker安装"
    fi
    
    echo "   自动选择: $INSTALL_TYPE 安装方式"
    echo ""
}

# 执行Docker安装
install_docker() {
    echo "🐳 开始Docker安装..."
    echo ""
    
    # 检查是否有Docker安装脚本
    if [ -f "install-curl.sh" ]; then
        echo "使用Docker安装脚本..."
        chmod +x install-curl.sh
        ./install-curl.sh --docker-only
    else
        echo "下载Docker安装脚本..."
        curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-curl.sh | bash -s -- --docker-only
    fi
}

# 执行原生安装
install_native() {
    echo "⚡ 开始原生安装..."
    echo ""
    
    # 检查是否有原生安装脚本
    if [ -f "install-vps.sh" ]; then
        echo "使用VPS优化原生安装脚本..."
        chmod +x install-vps.sh
        ./install-vps.sh --native-only
    else
        echo "下载VPS优化原生安装脚本..."
        curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-vps.sh | bash -s -- --native-only
    fi
}

# 显示安装结果
show_installation_result() {
    echo ""
    echo "=================================="
    echo "🎉 安装完成！"
    echo "=================================="
    echo ""
    echo "📋 访问信息："
    echo "   IPv4访问地址："
    if [ -n "$SERVER_IPV4" ] && [ "$SERVER_IPV4" != "localhost" ]; then
        if [ "$INSTALL_TYPE" = "docker" ]; then
            echo "     - 前端界面: http://$SERVER_IPV4:3000"
            echo "     - 后端API: http://$SERVER_IPV4:8000"
            echo "     - API文档: http://$SERVER_IPV4:8000/docs"
        else
            echo "     - 前端界面: http://$SERVER_IPV4"
            echo "     - 后端API: http://$SERVER_IPV4/api"
            echo "     - API文档: http://$SERVER_IPV4/api/docs"
        fi
    else
        if [ "$INSTALL_TYPE" = "docker" ]; then
            echo "     - 前端界面: http://localhost:3000"
            echo "     - 后端API: http://localhost:8000"
            echo "     - API文档: http://localhost:8000/docs"
        else
            echo "     - 前端界面: http://localhost"
            echo "     - 后端API: http://localhost/api"
            echo "     - API文档: http://localhost/api/docs"
        fi
    fi
    
    if [ -n "$SERVER_IPV6" ]; then
        echo "   IPv6访问地址："
        if [ "$INSTALL_TYPE" = "docker" ]; then
            echo "     - 前端界面: http://[$SERVER_IPV6]:3000"
            echo "     - 后端API: http://[$SERVER_IPV6]:8000"
            echo "     - API文档: http://[$SERVER_IPV6]:8000/docs"
        else
            echo "     - 前端界面: http://[$SERVER_IPV6]"
            echo "     - 后端API: http://[$SERVER_IPV6]/api"
            echo "     - API文档: http://[$SERVER_IPV6]/api/docs"
        fi
    fi
    echo ""
    echo "🔑 默认登录信息："
    echo "   用户名: admin"
    echo "   密码: admin123"
    echo ""
    
    if [ "$INSTALL_TYPE" = "docker" ]; then
        echo "🛠️  Docker管理命令："
        echo "   查看状态: docker-compose ps"
        echo "   查看日志: docker-compose logs -f"
        echo "   停止服务: docker-compose down"
        echo "   重启服务: docker-compose restart"
    else
        echo "🛠️  原生服务管理命令："
        echo "   查看状态: sudo systemctl status ipv6-wireguard-manager"
        echo "   查看日志: sudo journalctl -u ipv6-wireguard-manager -f"
        echo "   重启服务: sudo systemctl restart ipv6-wireguard-manager"
    fi
    echo ""
    echo "⚠️  安全提醒："
    echo "   请在生产环境中修改默认密码"
    echo ""
}

# 主函数
main() {
    # 检测IP地址
    get_server_ip
    
    # 检查命令行参数
    if [ "$1" = "--auto" ] || [ "$1" = "-a" ]; then
        # 自动选择安装方式
        auto_select_installation
    elif [ "$1" = "--docker" ] || [ "$1" = "-d" ]; then
        # 强制Docker安装
        INSTALL_TYPE="docker"
        echo "🐳 强制使用Docker安装方式"
        echo ""
    elif [ "$1" = "--native" ] || [ "$1" = "-n" ]; then
        # 强制原生安装
        INSTALL_TYPE="native"
        echo "⚡ 强制使用原生安装方式"
        echo ""
    else
        # 显示菜单让用户选择
        show_installation_menu
        get_user_choice
    fi
    
    # 执行安装
    case $INSTALL_TYPE in
        docker)
            install_docker
            ;;
        native)
            install_native
            ;;
        *)
            echo "❌ 无效的安装类型: $INSTALL_TYPE"
            exit 1
            ;;
    esac
    
    # 显示结果
    show_installation_result
}

# 显示帮助信息
show_help() {
    echo "IPv6 WireGuard Manager 统一安装脚本"
    echo ""
    echo "用法:"
    echo "  $0                    # 交互式选择安装方式"
    echo "  $0 --auto            # 自动选择最佳安装方式"
    echo "  $0 --docker          # 强制使用Docker安装"
    echo "  $0 --native          # 强制使用原生安装"
    echo "  $0 --help            # 显示此帮助信息"
    echo ""
    echo "选项:"
    echo "  --auto, -a           自动检测系统资源并选择最佳安装方式"
    echo "  --docker, -d         强制使用Docker安装方式"
    echo "  --native, -n         强制使用原生安装方式"
    echo "  --help, -h           显示帮助信息"
    echo ""
    echo "示例:"
    echo "  curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash"
    echo "  curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --auto"
    echo "  curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --native"
}

# 检查帮助参数
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

# 运行主函数
main "$@"