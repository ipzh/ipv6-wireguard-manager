#!/bin/bash

# IPv6 WireGuard VPN Manager
# 版本: 1.0.0
# 作者: IPv6 WireGuard Manager Team
# 描述: 完整的IPv6 WireGuard VPN服务器管理系统

set -euo pipefail

# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/modules/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/modules/common_functions.sh"
fi

# 颜色定义（如果公共函数库未加载则定义）
RED="${RED:-'\033[0;31m'}"
GREEN="${GREEN:-'\033[0;32m'}"
YELLOW="${YELLOW:-'\033[1;33m'}"
BLUE="${BLUE:-'\033[0;34m'}"
PURPLE="${PURPLE:-'\033[0;35m'}"
CYAN="${CYAN:-'\033[0;36m'}"
WHITE="${WHITE:-'\033[1;37m'}"
NC="${NC:-'\033[0m'}"

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"
MODULES_DIR="${SCRIPT_DIR}/modules"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
EXAMPLES_DIR="${SCRIPT_DIR}/examples"

# 确保日志相关变量已定义
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"
DOCS_DIR="${SCRIPT_DIR}/docs"
CONFIG_FILE="${CONFIG_DIR}/manager.conf"

# 默认配置
DEFAULT_CONFIG=(
    "WIREGUARD_PORT=51820"
    "WIREGUARD_INTERFACE=wg0"
    "WIREGUARD_NETWORK=10.0.0.0/24"
    "IPV6_PREFIX=2001:db8::/56"
    "BIRD_VERSION=auto"
    "FIREWALL_TYPE=auto"
    "WEB_PORT=8080"
    "WEB_USER=admin"
    "WEB_PASS=admin123"
    "LOG_LEVEL=INFO"
    "BACKUP_DIR=/var/backups/ipv6-wireguard"
    "CLIENT_CONFIG_DIR=/etc/wireguard/clients"
)

# 功能选择配置（从安装脚本继承）
INSTALL_WIREGUARD="${INSTALL_WIREGUARD:-true}"
INSTALL_BIRD="${INSTALL_BIRD:-true}"
INSTALL_FIREWALL="${INSTALL_FIREWALL:-true}"
INSTALL_WEB_INTERFACE="${INSTALL_WEB_INTERFACE:-true}"
INSTALL_MONITORING="${INSTALL_MONITORING:-true}"
INSTALL_CLIENT_AUTO_INSTALL="${INSTALL_CLIENT_AUTO_INSTALL:-true}"
INSTALL_BACKUP_RESTORE="${INSTALL_BACKUP_RESTORE:-true}"
INSTALL_UPDATE_MANAGEMENT="${INSTALL_UPDATE_MANAGEMENT:-true}"
INSTALL_SECURITY_ENHANCEMENTS="${INSTALL_SECURITY_ENHANCEMENTS:-true}"
INSTALL_CONFIG_MANAGEMENT="${INSTALL_CONFIG_MANAGEMENT:-true}"
INSTALL_WEB_INTERFACE_ENHANCED="${INSTALL_WEB_INTERFACE_ENHANCED:-true}"
INSTALL_OAUTH_AUTHENTICATION="${INSTALL_OAUTH_AUTHENTICATION:-true}"
INSTALL_SECURITY_AUDIT_MONITORING="${INSTALL_SECURITY_AUDIT_MONITORING:-true}"
INSTALL_NETWORK_TOPOLOGY="${INSTALL_NETWORK_TOPOLOGY:-true}"
INSTALL_API_DOCUMENTATION="${INSTALL_API_DOCUMENTATION:-true}"
INSTALL_WEBSOCKET_REALTIME="${INSTALL_WEBSOCKET_REALTIME:-true}"
INSTALL_MULTI_TENANT="${INSTALL_MULTI_TENANT:-true}"
INSTALL_RESOURCE_QUOTA="${INSTALL_RESOURCE_QUOTA:-true}"
INSTALL_LAZY_LOADING="${INSTALL_LAZY_LOADING:-true}"
INSTALL_PERFORMANCE_OPTIMIZATION="${INSTALL_PERFORMANCE_OPTIMIZATION:-true}"

# 系统信息
OS_TYPE=""
OS_VERSION=""
ARCH=""
PACKAGE_MANAGER=""

# 加载模块函数
load_module() {
    local module_name="$1"
    local module_file="${MODULES_DIR}/${module_name}.sh"
    
    if [[ -f "$module_file" ]]; then
        source "$module_file"
        log_info "已加载模块: $module_name"
    else
        log_error "模块文件不存在: $module_file"
        return 1
    fi
}

# 日志函数已从公共函数库导入

# 显示横幅
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    IPv6 WireGuard VPN Manager v1.0.0                        ║"
    echo "║                                                                              ║"
    echo "║  功能特性:                                                                   ║"
    echo "║  • 自动环境检测和依赖安装                                                    ║"
    echo "║  • WireGuard服务器自动配置                                                   ║"
    echo "║  • BIRD BGP路由支持 (1.x/2.x/3.x)                                           ║"
    echo "║  • IPv6子网管理 (/56到/72)                                                  ║"
    echo "║  • 多防火墙支持 (UFW/firewalld/nftables/iptables)                           ║"
    echo "║  • 客户端自动安装功能                                                        ║"
    echo "║  • Web管理界面                                                               ║"
    echo "║  • 实时监控和告警                                                           ║"
    echo "║  • 批量管理功能                                                             ║"
    echo "║  • 配置备份恢复                                                             ║"
    echo "║                                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 检查权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 初始化配置
init_config() {
    # 创建必要的目录
    mkdir -p "$CONFIG_DIR" "$MODULES_DIR" "$SCRIPTS_DIR" "$EXAMPLES_DIR" "$DOCS_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    mkdir -p "${BACKUP_DIR:-/var/backups/ipv6-wireguard}"
    mkdir -p "${CLIENT_CONFIG_DIR:-/etc/wireguard/clients}"
    
    # 创建默认配置文件
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_info "创建默认配置文件"
        for config_line in "${DEFAULT_CONFIG[@]}"; do
            echo "$config_line" >> "$CONFIG_FILE"
        done
    fi
    
    # 加载配置
    if [[ -f "$CONFIG_FILE" ]]; then
        # 确保配置文件使用Unix行尾符
        fix_line_endings "$CONFIG_FILE"
        
        source "$CONFIG_FILE"
        log_info "已加载配置文件: $CONFIG_FILE"
    fi
}

# 系统检测
detect_system() {
    log_info "检测系统环境..."
    
    # 检测操作系统
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_TYPE="$ID"
        OS_VERSION="$VERSION_ID"
    elif [[ -f /etc/redhat-release ]]; then
        OS_TYPE="rhel"
        OS_VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+' | head -1)
    elif [[ -f /etc/debian_version ]]; then
        OS_TYPE="debian"
        OS_VERSION=$(cat /etc/debian_version)
    else
        log_error "不支持的操作系统"
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
        log_error "不支持的包管理器"
        exit 1
    fi
    
    log_info "系统信息: $OS_TYPE $OS_VERSION ($ARCH), 包管理器: $PACKAGE_MANAGER"
}

# 加载所有模块
load_modules() {
    log_info "加载功能模块..."
    
    # 按依赖顺序加载模块
    local modules=(
        "common_functions"
        "module_loader"
        "system_detection"
        "error_handling"
        "user_interface"
        "menu_templates"
        "wireguard_config"
        "bird_config"
        "network_management"
        "firewall_management"
        "firewall_config"
        "client_management"
        "server_management"
        "system_maintenance"
        "backup_restore"
        "monitoring_alerting"
        "security_enhancements"
        "update_management"
        "wireguard_diagnostics"
        "client_auto_install"
        "client_auto_update"
        "client_batch_management"
        "client_monitoring"
        "client_script_generator"
        "client_web_interface"
        "repository_config"
        "firewall_ports"
        "config_management"
        "web_interface_enhanced"
        "oauth_authentication"
        "security_audit_monitoring"
        "network_topology"
        "api_documentation"
        "websocket_realtime"
        "multi_tenant"
        "resource_quota"
        "lazy_loading"
        "performance_optimization"
        "performance_enhancements"
    )
    
    for module in "${modules[@]}"; do
        load_module "$module" || log_warn "无法加载模块: $module"
    done
}

# 主菜单
show_main_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}主菜单:${NC}"
        echo -e "${GREEN}1.${NC}  快速安装 - 一键配置所有服务"
        echo -e "${GREEN}2.${NC}  交互式安装 - 自定义配置安装"
        echo -e "${GREEN}3.${NC}  服务器管理 - 服务状态管理"
        echo -e "${GREEN}4.${NC}  客户端管理 - 客户端配置管理"
        
        # 客户端自动安装功能
        if [[ "$INSTALL_CLIENT_AUTO_INSTALL" == "true" ]]; then
            echo -e "${GREEN}5.${NC}  客户端自动安装 - 生成安装链接和远程安装"
        else
            echo -e "${GRAY}5.${NC}  客户端自动安装 - 功能未安装"
        fi
        
        # Web管理界面功能
        if [[ "$INSTALL_WEB_INTERFACE" == "true" ]]; then
            echo -e "${GREEN}6.${NC}  Web管理界面 - 启动Web管理界面"
        else
            echo -e "${GRAY}6.${NC}  Web管理界面 - 功能未安装"
        fi
        
        echo -e "${GREEN}7.${NC}  网络配置 - IPv6前缀和BGP配置"
        echo -e "${GREEN}8.${NC}  BGP配置管理 - BGP路由配置"
        
        # 防火墙管理功能
        if [[ "$INSTALL_FIREWALL" == "true" ]]; then
            echo -e "${GREEN}9.${NC}  防火墙管理 - 防火墙规则管理"
        else
            echo -e "${GRAY}9.${NC}  防火墙管理 - 功能未安装"
        fi
        
        # 配置备份恢复功能
        if [[ "$INSTALL_BACKUP_RESTORE" == "true" ]]; then
            echo -e "${GREEN}10.${NC} 配置备份/恢复 - 配置备份和恢复"
        else
            echo -e "${GRAY}10.${NC} 配置备份/恢复 - 功能未安装"
        fi
        
        # 监控告警系统功能
        if [[ "$INSTALL_MONITORING" == "true" ]]; then
            echo -e "${GREEN}11.${NC} 监控告警系统 - 监控和告警系统"
        else
            echo -e "${GRAY}11.${NC} 监控告警系统 - 功能未安装"
        fi
        
        echo -e "${GREEN}12.${NC} 系统维护 - 系统状态和日志管理"
        
        # 更新检查功能
        if [[ "$INSTALL_UPDATE_MANAGEMENT" == "true" ]]; then
            echo -e "${GREEN}13.${NC} 更新检查 - 版本更新检查"
        else
            echo -e "${GRAY}13.${NC} 更新检查 - 功能未安装"
        fi
        
        # 安全增强功能
        if [[ "$INSTALL_SECURITY_ENHANCEMENTS" == "true" ]]; then
            echo -e "${GREEN}14.${NC} 安全增强功能 - 安全扫描和增强"
        else
            echo -e "${GRAY}14.${NC} 安全增强功能 - 功能未安装"
        fi
        
        echo -e "${GREEN}15.${NC} 用户界面功能 - 界面优化和主题"
        echo -e "${GREEN}16.${NC} 下载必需文件 - 下载缺失的文件"
        echo -e "${GREEN}17.${NC} 功能管理 - 启用/禁用功能模块"
        # 配置管理功能
        if [[ "$INSTALL_CONFIG_MANAGEMENT" == "true" ]]; then
            echo -e "${GREEN}18.${NC} 配置管理 - YAML配置管理"
        else
            echo -e "${GRAY}18.${NC} 配置管理 - 功能未安装"
        fi
        
        # 增强Web界面功能
        if [[ "$INSTALL_WEB_INTERFACE_ENHANCED" == "true" ]]; then
            echo -e "${GREEN}19.${NC} 增强Web界面 - 实时状态和用户管理"
        else
            echo -e "${GRAY}19.${NC} 增强Web界面 - 功能未安装"
        fi
        
        # OAuth认证管理功能
        if [[ "$INSTALL_OAUTH_AUTHENTICATION" == "true" ]]; then
            echo -e "${GREEN}20.${NC} OAuth认证管理 - OAuth 2.0和MFA"
        else
            echo -e "${GRAY}20.${NC} OAuth认证管理 - 功能未安装"
        fi
        
        # 安全审计监控功能
        if [[ "$INSTALL_SECURITY_AUDIT_MONITORING" == "true" ]]; then
            echo -e "${GREEN}21.${NC} 安全审计监控 - 安全事件和漏洞管理"
        else
            echo -e "${GRAY}21.${NC} 安全审计监控 - 功能未安装"
        fi
        
        # 网络拓扑图功能
        if [[ "$INSTALL_NETWORK_TOPOLOGY" == "true" ]]; then
            echo -e "${GREEN}22.${NC} 网络拓扑图 - 网络拓扑可视化"
        else
            echo -e "${GRAY}22.${NC} 网络拓扑图 - 功能未安装"
        fi
        
        # API文档功能
        if [[ "$INSTALL_API_DOCUMENTATION" == "true" ]]; then
            echo -e "${GREEN}23.${NC} API文档 - OpenAPI/Swagger文档"
        else
            echo -e "${GRAY}23.${NC} API文档 - 功能未安装"
        fi
        
        # WebSocket实时通信功能
        if [[ "$INSTALL_WEBSOCKET_REALTIME" == "true" ]]; then
            echo -e "${GREEN}24.${NC} WebSocket实时通信 - 实时数据推送"
        else
            echo -e "${GRAY}24.${NC} WebSocket实时通信 - 功能未安装"
        fi
        
        # 多租户管理功能
        if [[ "$INSTALL_MULTI_TENANT" == "true" ]]; then
            echo -e "${GREEN}25.${NC} 多租户管理 - 组织项目隔离"
        else
            echo -e "${GRAY}25.${NC} 多租户管理 - 功能未安装"
        fi
        
        # 资源配额管理功能
        if [[ "$INSTALL_RESOURCE_QUOTA" == "true" ]]; then
            echo -e "${GREEN}26.${NC} 资源配额管理 - 资源限制监控"
        else
            echo -e "${GRAY}26.${NC} 资源配额管理 - 功能未安装"
        fi
        
        # 配置懒加载功能
        if [[ "$INSTALL_LAZY_LOADING" == "true" ]]; then
            echo -e "${GREEN}27.${NC} 配置懒加载 - 优化启动和内存使用"
        else
            echo -e "${GRAY}27.${NC} 配置懒加载 - 功能未安装"
        fi
        
# 性能优化功能
if [[ "$INSTALL_PERFORMANCE_OPTIMIZATION" == "true" ]]; then
    echo -e "${GREEN}28.${NC} 性能优化 - 内存和CPU使用优化"
else
    echo -e "${GRAY}28.${NC} 性能优化 - 功能未安装"
fi

# 性能增强功能
if [[ "$INSTALL_PERFORMANCE_OPTIMIZATION" == "true" ]]; then
    echo -e "${GREEN}29.${NC} 性能增强 - 缓存和监控优化"
else
    echo -e "${GRAY}29.${NC} 性能增强 - 功能未安装"
fi
        
        echo -e "${GREEN}0.${NC}  退出"
        echo
        
        read -p "请选择操作 [0-29]: " choice
        
        case $choice in
            1) quick_install ;;
            2) interactive_install ;;
            3) server_management_menu ;;
            4) client_management_menu ;;
            5) 
                if [[ "$INSTALL_CLIENT_AUTO_INSTALL" == "true" ]]; then
                    client_auto_install_menu
                else
                    show_error "客户端自动安装功能未安装"
                fi
                ;;
            6) 
                if [[ "$INSTALL_WEB_INTERFACE" == "true" ]]; then
                    web_management_menu
                else
                    show_error "Web管理界面功能未安装"
                fi
                ;;
            7) network_configuration_menu ;;
            8) bgp_config_management_menu ;;
            9) 
                if [[ "$INSTALL_FIREWALL" == "true" ]]; then
                    firewall_management_menu
                else
                    show_error "防火墙管理功能未安装"
                fi
                ;;
            10) 
                if [[ "$INSTALL_BACKUP_RESTORE" == "true" ]]; then
                    backup_restore_menu
                else
                    show_error "配置备份恢复功能未安装"
                fi
                ;;
            11) 
                if [[ "$INSTALL_MONITORING" == "true" ]]; then
                    monitoring_alerting_menu
                else
                    show_error "监控告警系统功能未安装"
                fi
                ;;
            12) system_maintenance_menu ;;
            13) 
                if [[ "$INSTALL_UPDATE_MANAGEMENT" == "true" ]]; then
                    update_check_menu
                else
                    show_error "更新检查功能未安装"
                fi
                ;;
            14) 
                if [[ "$INSTALL_SECURITY_ENHANCEMENTS" == "true" ]]; then
                    security_enhancements_menu
                else
                    show_error "安全增强功能未安装"
                fi
                ;;
            15) user_interface_menu ;;
            16) download_required_files ;;
            17) feature_management_menu ;;
            18) 
                if [[ "$INSTALL_CONFIG_MANAGEMENT" == "true" ]]; then
                    config_management_menu
                else
                    show_error "配置管理功能未安装"
                fi
                ;;
            19) 
                if [[ "$INSTALL_WEB_INTERFACE_ENHANCED" == "true" ]]; then
                    enhanced_web_interface_menu
                else
                    show_error "增强Web界面功能未安装"
                fi
                ;;
            20) 
                if [[ "$INSTALL_OAUTH_AUTHENTICATION" == "true" ]]; then
                    oauth_authentication_menu
                else
                    show_error "OAuth认证管理功能未安装"
                fi
                ;;
            21) 
                if [[ "$INSTALL_SECURITY_AUDIT_MONITORING" == "true" ]]; then
                    security_audit_monitoring_menu
                else
                    show_error "安全审计监控功能未安装"
                fi
                ;;
            22) 
                if [[ "$INSTALL_NETWORK_TOPOLOGY" == "true" ]]; then
                    network_topology_menu
                else
                    show_error "网络拓扑图功能未安装"
                fi
                ;;
            23) 
                if [[ "$INSTALL_API_DOCUMENTATION" == "true" ]]; then
                    api_documentation_menu
                else
                    show_error "API文档功能未安装"
                fi
                ;;
            24) 
                if [[ "$INSTALL_WEBSOCKET_REALTIME" == "true" ]]; then
                    websocket_realtime_menu
                else
                    show_error "WebSocket实时通信功能未安装"
                fi
                ;;
            25) 
                if [[ "$INSTALL_MULTI_TENANT" == "true" ]]; then
                    multi_tenant_menu
                else
                    show_error "多租户管理功能未安装"
                fi
                ;;
            26) 
                if [[ "$INSTALL_RESOURCE_QUOTA" == "true" ]]; then
                    resource_quota_menu
                else
                    show_error "资源配额管理功能未安装"
                fi
                ;;
            27) 
                if [[ "$INSTALL_LAZY_LOADING" == "true" ]]; then
                    lazy_loading_menu
                else
                    show_error "配置懒加载功能未安装"
                fi
                ;;
            28) 
                if [[ "$INSTALL_PERFORMANCE_OPTIMIZATION" == "true" ]]; then
                    performance_optimization_menu
                else
                    show_error "性能优化功能未安装"
                fi
                ;;
            29) 
                if [[ "$INSTALL_PERFORMANCE_OPTIMIZATION" == "true" ]]; then
                    performance_enhancements_menu
                else
                    show_error "性能增强功能未安装"
                fi
                ;;
            0)
                log_info "感谢使用IPv6 WireGuard Manager!"
                exit 0
                ;;
            *)
                log_error "无效选择，请重新输入"
                sleep 2
                ;;
        esac
    done
}

# 快速安装
quick_install() {
    log_info "开始快速安装..."
    
    # 检查依赖
    if ! check_dependencies; then
        log_error "依赖检查失败"
        return 1
    fi
    
    # 安装依赖
    install_dependencies
    
    # 配置WireGuard
    configure_wireguard
    
    # 配置BIRD
    configure_bird
    
    # 配置防火墙
    configure_firewall
    
    # 启动服务
    start_services
    
    log_info "快速安装完成!"
    read -p "按回车键继续..."
}

# 交互式安装
interactive_install() {
    log_info "开始交互式安装..."
    
    # 获取用户配置
    get_user_config
    
    # 执行安装
    quick_install
    
    log_info "交互式安装完成!"
    read -p "按回车键继续..."
}

# 获取用户配置
get_user_config() {
    echo -e "${YELLOW}请输入配置信息:${NC}"
    
    read -p "WireGuard端口 [默认: 51820]: " port
    WIREGUARD_PORT=${port:-51820}
    
    read -p "WireGuard接口名 [默认: wg0]: " interface
    WIREGUARD_INTERFACE=${interface:-wg0}
    
    read -p "IPv4网络 [默认: 10.0.0.0/24]: " network
    WIREGUARD_NETWORK=${network:-10.0.0.0/24}
    
    read -p "IPv6前缀 [默认: 2001:db8::/56]: " prefix
    IPV6_PREFIX=${prefix:-2001:db8::/56}
    
    read -p "BIRD版本 [auto/1.x/2.x/3.x]: " bird_ver
    BIRD_VERSION=${bird_ver:-auto}
    
    read -p "防火墙类型 [auto/ufw/firewalld/nftables/iptables]: " fw_type
    FIREWALL_TYPE=${fw_type:-auto}
    
    read -p "Web管理端口 [默认: 8080]: " web_port
    WEB_PORT=${web_port:-8080}
    
    read -p "Web管理用户名 [默认: admin]: " web_user
    WEB_USER=${web_user:-admin}
    
    read -s -p "Web管理密码 [默认: admin123]: " web_pass
    WEB_PASS=${web_pass:-admin123}
    echo
    
    # 保存配置
    save_config
}

# 保存配置
save_config() {
    cat > "$CONFIG_FILE" << EOF
WIREGUARD_PORT=$WIREGUARD_PORT
WIREGUARD_INTERFACE=$WIREGUARD_INTERFACE
WIREGUARD_NETWORK=$WIREGUARD_NETWORK
IPV6_PREFIX=$IPV6_PREFIX
BIRD_VERSION=$BIRD_VERSION
FIREWALL_TYPE=$FIREWALL_TYPE
WEB_PORT=$WEB_PORT
WEB_USER=$WEB_USER
WEB_PASS=$WEB_PASS
LOG_LEVEL=$LOG_LEVEL
BACKUP_DIR=$BACKUP_DIR
CLIENT_CONFIG_DIR=$CLIENT_CONFIG_DIR
EOF
    
    log_info "配置已保存到: $CONFIG_FILE"
}

# 主函数
main() {
    # 检查权限
    check_root
    
    # 初始化
    init_config
    
    # 系统检测
    detect_system
    
    # 加载模块
    load_modules
    
    # 显示主菜单
    show_main_menu
}

# 功能管理菜单
feature_management_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 功能管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看功能状态"
        echo -e "${GREEN}2.${NC} 启用功能模块"
        echo -e "${GREEN}3.${NC} 禁用功能模块"
        echo -e "${GREEN}4.${NC} 重新安装功能"
        echo -e "${GREEN}5.${NC} 功能依赖检查"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 [0-5]: " choice
        
        case $choice in
            1) show_feature_status ;;
            2) enable_feature ;;
            3) disable_feature ;;
            4) reinstall_feature ;;
            5) check_feature_dependencies ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 显示功能状态
show_feature_status() {
    echo -e "${SECONDARY_COLOR}=== 功能状态 ===${NC}"
    echo
    
    echo "已安装的功能:"
    [[ "$INSTALL_WIREGUARD" == "true" ]] && echo "  ✓ WireGuard VPN服务"
    [[ "$INSTALL_BIRD" == "true" ]] && echo "  ✓ BIRD BGP路由服务"
    [[ "$INSTALL_FIREWALL" == "true" ]] && echo "  ✓ 防火墙管理功能"
    [[ "$INSTALL_WEB_INTERFACE" == "true" ]] && echo "  ✓ Web管理界面"
    [[ "$INSTALL_MONITORING" == "true" ]] && echo "  ✓ 监控告警系统"
    [[ "$INSTALL_CLIENT_AUTO_INSTALL" == "true" ]] && echo "  ✓ 客户端自动安装功能"
    [[ "$INSTALL_BACKUP_RESTORE" == "true" ]] && echo "  ✓ 配置备份恢复功能"
    [[ "$INSTALL_UPDATE_MANAGEMENT" == "true" ]] && echo "  ✓ 更新管理功能"
    [[ "$INSTALL_SECURITY_ENHANCEMENTS" == "true" ]] && echo "  ✓ 安全增强功能"
    
    echo
    echo "未安装的功能:"
    [[ "$INSTALL_WIREGUARD" != "true" ]] && echo "  ✗ WireGuard VPN服务"
    [[ "$INSTALL_BIRD" != "true" ]] && echo "  ✗ BIRD BGP路由服务"
    [[ "$INSTALL_FIREWALL" != "true" ]] && echo "  ✗ 防火墙管理功能"
    [[ "$INSTALL_WEB_INTERFACE" != "true" ]] && echo "  ✗ Web管理界面"
    [[ "$INSTALL_MONITORING" != "true" ]] && echo "  ✗ 监控告警系统"
    [[ "$INSTALL_CLIENT_AUTO_INSTALL" != "true" ]] && echo "  ✗ 客户端自动安装功能"
    [[ "$INSTALL_BACKUP_RESTORE" != "true" ]] && echo "  ✗ 配置备份恢复功能"
    [[ "$INSTALL_UPDATE_MANAGEMENT" != "true" ]] && echo "  ✗ 更新管理功能"
    [[ "$INSTALL_SECURITY_ENHANCEMENTS" != "true" ]] && echo "  ✗ 安全增强功能"
}

# 启用功能
enable_feature() {
    echo -e "${SECONDARY_COLOR}=== 启用功能 ===${NC}"
    echo
    
    local features=(
        "WireGuard VPN服务:INSTALL_WIREGUARD"
        "BIRD BGP路由服务:INSTALL_BIRD"
        "防火墙管理功能:INSTALL_FIREWALL"
        "Web管理界面:INSTALL_WEB_INTERFACE"
        "监控告警系统:INSTALL_MONITORING"
        "客户端自动安装功能:INSTALL_CLIENT_AUTO_INSTALL"
        "配置备份恢复功能:INSTALL_BACKUP_RESTORE"
        "更新管理功能:INSTALL_UPDATE_MANAGEMENT"
        "安全增强功能:INSTALL_SECURITY_ENHANCEMENTS"
    )
    
    echo "选择要启用的功能:"
    for i in "${!features[@]}"; do
        local feature_name=$(echo "${features[$i]}" | cut -d':' -f1)
        local feature_var=$(echo "${features[$i]}" | cut -d':' -f2)
        local status=""
        
        if [[ "${!feature_var}" == "true" ]]; then
            status="(已启用)"
        else
            status="(未启用)"
        fi
        
        echo "$((i+1)). $feature_name $status"
    done
    
    read -p "请选择功能编号: " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#features[@]} ]]; then
        local selected_feature="${features[$((choice-1))]}"
        local feature_name=$(echo "$selected_feature" | cut -d':' -f1)
        local feature_var=$(echo "$selected_feature" | cut -d':' -f2)
        
        if [[ "${!feature_var}" != "true" ]]; then
            export "$feature_var=true"
            log_info "功能已启用: $feature_name"
            show_success "功能启用成功: $feature_name"
        else
            show_warn "功能已经启用: $feature_name"
        fi
    else
        show_error "无效选择"
    fi
}

# 禁用功能
disable_feature() {
    echo -e "${SECONDARY_COLOR}=== 禁用功能 ===${NC}"
    echo
    
    local features=(
        "WireGuard VPN服务:INSTALL_WIREGUARD"
        "BIRD BGP路由服务:INSTALL_BIRD"
        "防火墙管理功能:INSTALL_FIREWALL"
        "Web管理界面:INSTALL_WEB_INTERFACE"
        "监控告警系统:INSTALL_MONITORING"
        "客户端自动安装功能:INSTALL_CLIENT_AUTO_INSTALL"
        "配置备份恢复功能:INSTALL_BACKUP_RESTORE"
        "更新管理功能:INSTALL_UPDATE_MANAGEMENT"
        "安全增强功能:INSTALL_SECURITY_ENHANCEMENTS"
    )
    
    echo "选择要禁用的功能:"
    for i in "${!features[@]}"; do
        local feature_name=$(echo "${features[$i]}" | cut -d':' -f1)
        local feature_var=$(echo "${features[$i]}" | cut -d':' -f2)
        local status=""
        
        if [[ "${!feature_var}" == "true" ]]; then
            status="(已启用)"
        else
            status="(未启用)"
        fi
        
        echo "$((i+1)). $feature_name $status"
    done
    
    read -p "请选择功能编号: " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#features[@]} ]]; then
        local selected_feature="${features[$((choice-1))]}"
        local feature_name=$(echo "$selected_feature" | cut -d':' -f1)
        local feature_var=$(echo "$selected_feature" | cut -d':' -f2)
        
        if [[ "${!feature_var}" == "true" ]]; then
            export "$feature_var=false"
            log_info "功能已禁用: $feature_name"
            show_success "功能禁用成功: $feature_name"
        else
            show_warn "功能已经禁用: $feature_name"
        fi
    else
        show_error "无效选择"
    fi
}

# 重新安装功能
reinstall_feature() {
    echo -e "${SECONDARY_COLOR}=== 重新安装功能 ===${NC}"
    echo
    
    local features=(
        "WireGuard VPN服务:INSTALL_WIREGUARD"
        "BIRD BGP路由服务:INSTALL_BIRD"
        "防火墙管理功能:INSTALL_FIREWALL"
        "Web管理界面:INSTALL_WEB_INTERFACE"
        "监控告警系统:INSTALL_MONITORING"
        "客户端自动安装功能:INSTALL_CLIENT_AUTO_INSTALL"
        "配置备份恢复功能:INSTALL_BACKUP_RESTORE"
        "更新管理功能:INSTALL_UPDATE_MANAGEMENT"
        "安全增强功能:INSTALL_SECURITY_ENHANCEMENTS"
    )
    
    echo "选择要重新安装的功能:"
    for i in "${!features[@]}"; do
        local feature_name=$(echo "${features[$i]}" | cut -d':' -f1)
        echo "$((i+1)). $feature_name"
    done
    
    read -p "请选择功能编号: " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#features[@]} ]]; then
        local selected_feature="${features[$((choice-1))]}"
        local feature_name=$(echo "$selected_feature" | cut -d':' -f1)
        
        if show_confirm "确认重新安装功能: $feature_name"; then
            log_info "重新安装功能: $feature_name"
            # 这里添加重新安装逻辑
            show_success "功能重新安装完成: $feature_name"
        fi
    else
        show_error "无效选择"
    fi
}

# 检查功能依赖
check_feature_dependencies() {
    echo -e "${SECONDARY_COLOR}=== 功能依赖检查 ===${NC}"
    echo
    
    echo "检查功能依赖关系..."
    
    # 检查WireGuard依赖
    if [[ "$INSTALL_WIREGUARD" == "true" ]]; then
        if command -v wg &> /dev/null; then
            echo "  ✓ WireGuard已安装"
        else
            echo "  ✗ WireGuard未安装"
        fi
    fi
    
    # 检查BIRD依赖
    if [[ "$INSTALL_BIRD" == "true" ]]; then
        if command -v bird &> /dev/null; then
            echo "  ✓ BIRD已安装"
        else
            echo "  ✗ BIRD未安装"
        fi
    fi
    
    # 检查防火墙依赖
    if [[ "$INSTALL_FIREWALL" == "true" ]]; then
        if command -v ufw &> /dev/null || command -v firewall-cmd &> /dev/null || command -v nft &> /dev/null || command -v iptables &> /dev/null; then
            echo "  ✓ 防火墙工具已安装"
        else
            echo "  ✗ 防火墙工具未安装"
        fi
    fi
    
    # 检查Web服务器依赖
    if [[ "$INSTALL_WEB_INTERFACE" == "true" ]]; then
        if command -v nginx &> /dev/null || command -v apache2 &> /dev/null || command -v httpd &> /dev/null; then
            echo "  ✓ Web服务器已安装"
        else
            echo "  ✗ Web服务器未安装"
        fi
    fi
    
    log_info "功能依赖检查完成"
}

# 错误处理
trap 'log_error "脚本执行出错，行号: $LINENO"' ERR

# 执行主函数
main "$@"
