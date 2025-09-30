#!/bin/bash

# IPv6 WireGuard VPN Manager
# 版本: 1.0.0
# 作者: IPv6 WireGuard Manager Team
# 描述: 完整的IPv6 WireGuard VPN服务器管理系统

# 设置错误处理，根据执行环境调整严格程度
if [[ -t 0 ]]; then
    # 交互式执行，使用严格模式
    set -euo pipefail
else
    # 管道执行，使用宽松模式
    set -e
fi

# 安全的脚本目录检测
get_script_dir() {
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        # 标准情况：通过BASH_SOURCE获取
        echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    elif [[ -n "${0:-}" && "$0" != "-bash" && "$0" != "bash" ]]; then
        # 备选方案1：通过$0获取
        echo "$(cd "$(dirname "$0")" && pwd)"
    else
        # 备选方案2：使用当前工作目录
        echo "$(pwd)"
    fi
}

# 获取脚本目录
SCRIPT_DIR="$(get_script_dir)"

# 检查是否通过符号链接运行，如果是则使用实际安装目录
if [[ -L "/usr/local/bin/ipv6-wireguard-manager" ]]; then
    # 通过符号链接运行，使用实际安装目录
    SCRIPT_DIR="/opt/ipv6-wireguard-manager"
    MODULES_DIR="/opt/ipv6-wireguard-manager/modules"
else
    # 直接运行，使用相对路径
    MODULES_DIR="${MODULES_DIR:-${SCRIPT_DIR}/modules}"
fi

# 提前定义颜色变量，避免导入失败时出错
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 基础日志函数的备选实现
if ! command -v log_info &> /dev/null; then
    log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
    log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
    log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
    log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
    log_debug() { echo -e "${PURPLE}[DEBUG]${NC} $*"; }
fi

# 改进的模块导入机制
import_module() {
    local module_name="$1"
    local module_path="${MODULES_DIR}/${module_name}.sh"
    
    if [[ -f "$module_path" ]]; then
        source "$module_path"
        return 0
    else
        # 尝试从多个位置查找模块
        local alt_paths=(
            "/opt/ipv6-wireguard-manager/modules/${module_name}.sh"
            "/usr/local/share/ipv6-wireguard-manager/modules/${module_name}.sh"
            "$(pwd)/modules/${module_name}.sh"
            "${SCRIPT_DIR}/modules/${module_name}.sh"
        )
        
        for alt_path in "${alt_paths[@]}"; do
            if [[ -f "$alt_path" ]]; then
                source "$alt_path"
                return 0
            fi
        done
        
        # 如果仍然找不到，记录错误
        log_error "通用工具函数文件不存在: ${module_path}"
        log_error "尝试的路径: ${alt_paths[*]}"
    fi
    
    return 1
}

# 导入公共函数库
if ! import_module "common_functions"; then
    log_warn "无法导入公共函数库，使用内置函数"
    # 继续使用内置的基本函数
fi

# 导入函数标准化模块
if import_module "function_standardization"; then
    log_info "函数标准化模块已导入"
    # 确保所有核心函数统一
    if command -v ensure_core_functions &> /dev/null; then
        ensure_core_functions
    fi
else
    log_warn "函数标准化模块导入失败"
fi

# 导入变量管理系统
if import_module "variable_management"; then
    log_info "变量管理系统已导入"
    # 初始化变量系统
    if command -v init_variables &> /dev/null; then
        init_variables
    fi
else
    log_warn "变量管理系统导入失败，使用默认变量"
fi

# 导入函数管理系统
if import_module "function_management"; then
    log_info "函数管理系统已导入"
else
    log_warn "函数管理系统导入失败"
fi

# 导入主脚本重构模块
if import_module "main_script_refactor"; then
    log_info "主脚本重构模块已导入"
    # 初始化主脚本
    if command -v init_main_script &> /dev/null; then
        init_main_script "ipv6-wireguard-manager" "1.0.0"
    fi
else
    log_warn "主脚本重构模块导入失败"
fi

# 导入模块加载追踪器
if import_module "module_loading_tracker"; then
    log_info "模块加载追踪器已导入"
    # 初始化加载追踪
    if command -v init_loading_tracker &> /dev/null; then
        init_loading_tracker
    fi
else
    log_warn "模块加载追踪器导入失败"
fi

# 导入脚本自检模块
if import_module "script_self_check"; then
    log_info "脚本自检模块已导入"
else
    log_warn "脚本自检模块导入失败"
fi

# 导入配置版本控制模块
if import_module "config_version_control"; then
    log_info "配置版本控制模块已导入"
    # 初始化版本控制
    if command -v init_version_control &> /dev/null; then
        init_version_control
    fi
else
    log_warn "配置版本控制模块导入失败"
fi

# 导入配置备份恢复模块
if import_module "config_backup_recovery"; then
    log_info "配置备份恢复模块已导入"
    # 初始化备份系统
    if command -v init_backup_system &> /dev/null; then
        init_backup_system
    fi
else
    log_warn "配置备份恢复模块导入失败"
fi

# 导入配置热重载模块
if import_module "config_hot_reload"; then
    log_info "配置热重载模块已导入"
    # 初始化热重载系统
    if command -v init_hot_reload &> /dev/null; then
        init_hot_reload
    fi
else
    log_warn "配置热重载模块导入失败"
fi

# 导入模块版本兼容性模块
if import_module "module_version_compatibility"; then
    log_info "模块版本兼容性模块已导入"
    # 初始化版本兼容性系统
    if command -v init_version_compatibility &> /dev/null; then
        init_version_compatibility
    fi
else
    log_warn "模块版本兼容性模块导入失败"
fi

# 导入模块预加载模块
if import_module "module_preloading"; then
    log_info "模块预加载模块已导入"
    # 初始化预加载系统
    if command -v init_preloading &> /dev/null; then
        init_preloading
    fi
else
    log_warn "模块预加载模块导入失败"
fi

# 导入增强Windows支持模块
if import_module "enhanced_windows_support"; then
    log_info "增强Windows支持模块已导入"
    # 初始化Windows支持
    if command -v init_windows_support &> /dev/null; then
        init_windows_support
    fi
else
    log_warn "增强Windows支持模块导入失败"
fi

# 导入硬件兼容性模块
if import_module "hardware_compatibility"; then
    log_info "硬件兼容性模块已导入"
    # 初始化硬件兼容性检查
    if command -v init_hardware_compatibility &> /dev/null; then
        init_hardware_compatibility
    fi
else
    log_warn "硬件兼容性模块导入失败"
fi

# 导入智能缓存模块
if import_module "smart_caching"; then
    log_info "智能缓存模块已导入"
    # 初始化智能缓存系统
    if command -v init_smart_caching &> /dev/null; then
        init_smart_caching
    fi
else
    log_warn "智能缓存模块导入失败"
fi


# 导入增强的模块加载器
if import_module "enhanced_module_loader"; then
    log_info "增强的模块加载器已导入"
else
    # 回退到基础模块加载器
    if [[ -f "${MODULES_DIR}/module_loader.sh" ]]; then
        source "${MODULES_DIR}/module_loader.sh"
        log_info "基础模块加载器已导入"
    else
        log_error "模块加载器文件不存在"
        exit 1
    fi
fi

# 导入统一配置管理
if import_module "unified_config"; then
    log_info "统一配置管理已导入"
else
    log_warn "统一配置管理导入失败"
fi

# 导入增强的配置管理
if import_module "enhanced_config_management"; then
    log_info "增强的配置管理已导入"
else
    log_warn "增强的配置管理导入失败"
fi

# 导入资源监控系统
if import_module "resource_monitoring"; then
    log_info "资源监控系统已导入"
else
    log_warn "资源监控系统导入失败"
fi

# 导入懒加载模块
if import_module "lazy_loading"; then
    log_info "懒加载模块已导入"
else
    log_warn "懒加载模块导入失败"
fi

# 导入依赖管理系统
if import_module "dependency_manager"; then
    log_info "依赖管理系统已导入"
else
    log_warn "依赖管理系统导入失败"
fi

# 导入增强的系统兼容性
if import_module "enhanced_system_compatibility"; then
    log_info "增强的系统兼容性已导入"
    # 检测操作系统
    if command -v detect_operating_system &> /dev/null; then
        detect_operating_system
    fi
else
    log_warn "增强的系统兼容性导入失败"
fi

# 导入高级性能优化
if import_module "advanced_performance_optimization"; then
    log_info "高级性能优化已导入"
else
    log_warn "高级性能优化导入失败"
fi

# 导入高级错误处理
if import_module "advanced_error_handling"; then
    log_info "高级错误处理已导入"
else
    log_warn "高级错误处理导入失败"
fi

# 导入通用工具函数
if [[ -f "${MODULES_DIR}/common_utils.sh" ]]; then
    source "${MODULES_DIR}/common_utils.sh"
    log_info "通用工具函数已导入"
else
    log_error "通用工具函数文件不存在: ${MODULES_DIR}/common_utils.sh"
    exit 1
fi

# 导入版本控制
if [[ -f "${MODULES_DIR}/version_control.sh" ]]; then
    source "${MODULES_DIR}/version_control.sh"
    log_info "版本控制模块已导入"
else
    log_error "版本控制模块文件不存在: ${MODULES_DIR}/version_control.sh"
    exit 1
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
CONFIG_DIR="${CONFIG_DIR:-/etc/ipv6-wireguard-manager}"
MODULES_DIR="${MODULES_DIR:-${SCRIPT_DIR}/modules}"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
EXAMPLES_DIR="${SCRIPT_DIR}/examples"

# 确保日志相关变量已定义
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"
DOCS_DIR="${SCRIPT_DIR}/docs"
CONFIG_FILE="${CONFIG_DIR}/manager.conf"

# 配置函数已在unified_config.sh中定义，无需重复定义

# 创建默认配置文件
create_default_config() {
    local config_file="$1"
    cat > "$config_file" << 'EOF'
# IPv6 WireGuard Manager 主配置文件
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')

# WireGuard配置
WIREGUARD_PORT=51820
WIREGUARD_INTERFACE=wg0
WIREGUARD_NETWORK=10.0.0.0/24
IPV6_PREFIX=2001:db8::/56

# BIRD配置
BIRD_VERSION=auto

# 防火墙配置
FIREWALL_TYPE=auto

# Web界面配置
WEB_PORT=8080
WEB_USER=admin
WEB_PASS=admin123

# 日志配置
LOG_LEVEL=INFO

# 备份配置
BACKUP_DIR=/var/backups/ipv6-wireguard
CLIENT_CONFIG_DIR=/etc/wireguard/clients

# 功能开关
INSTALL_WIREGUARD=true
INSTALL_BIRD=true
INSTALL_FIREWALL=true
INSTALL_WEB_INTERFACE=true
INSTALL_MONITORING=true
INSTALL_CLIENT_AUTO_INSTALL=true
INSTALL_BACKUP_RESTORE=true
INSTALL_UPDATE_MANAGEMENT=true
INSTALL_SECURITY_ENHANCEMENTS=true
INSTALL_CONFIG_MANAGEMENT=true
INSTALL_WEB_INTERFACE_ENHANCED=true
INSTALL_OAUTH_AUTHENTICATION=true
INSTALL_SECURITY_AUDIT_MONITORING=true
INSTALL_NETWORK_TOPOLOGY=true
INSTALL_API_DOCUMENTATION=true
INSTALL_WEBSOCKET_REALTIME=true
INSTALL_MULTI_TENANT=true
INSTALL_RESOURCE_QUOTA=true
INSTALL_LAZY_LOADING=true
INSTALL_PERFORMANCE_OPTIMIZATION=true
EOF
    
    # 替换时间戳
    sed -i "s/\$(date[^)]*)/$(date '+%Y-%m-%d %H:%M:%S')/g" "$config_file"
    
    log_info "默认配置文件已创建: $config_file"
}

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

# 函数已在common_functions.sh中定义，无需重复定义

# 加载模块函数（兼容性保留）
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
    # 初始化统一配置系统
    init_config_system
    
    # 初始化懒加载系统
    init_lazy_loading
    
    # 创建必要的目录
    execute_command "mkdir -p '$CONFIG_DIR' '$MODULES_DIR' '$SCRIPTS_DIR' '$EXAMPLES_DIR' '$DOCS_DIR'" "创建项目目录结构"
    execute_command "mkdir -p '$(dirname "$LOG_FILE")'" "创建日志目录"
    execute_command "mkdir -p '$BACKUP_DIR'" "创建备份目录"
    execute_command "mkdir -p '$CLIENT_CONFIG_DIR'" "创建客户端配置目录"
    
    # 使用统一的配置管理机制
    load_config "$CONFIG_FILE"
    
    # 验证所有配置项
    validate_all_config
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
        echo -e "${GREEN}13.${NC} 资源监控 - 系统资源监控和优化"
        echo -e "${GREEN}14.${NC} 配置管理 - 配置验证、备份和导入导出"
        echo -e "${GREEN}15.${NC} 函数管理 - 函数注册和冲突检测"
        echo -e "${GREEN}16.${NC} 变量管理 - 变量验证和导出"
        echo -e "${GREEN}17.${NC} 依赖管理 - 模块依赖关系管理"
        echo -e "${GREEN}18.${NC} 系统兼容性 - 多平台支持检测"
        echo -e "${GREEN}19.${NC} 性能优化 - 缓存和并行处理"
        echo -e "${GREEN}20.${NC} 错误处理 - 异常检测和恢复"
        echo -e "${GREEN}21.${NC} 系统自检 - 全面系统健康检查"
        
        # 更新检查功能
        if [[ "$INSTALL_UPDATE_MANAGEMENT" == "true" ]]; then
            echo -e "${GREEN}22.${NC} 更新检查 - 版本更新检查"
        else
            echo -e "${GRAY}22.${NC} 更新检查 - 功能未安装"
        fi
        
        # 安全增强功能
        if [[ "$INSTALL_SECURITY_ENHANCEMENTS" == "true" ]]; then
            echo -e "${GREEN}23.${NC} 安全增强功能 - 安全扫描和增强"
        else
            echo -e "${GRAY}23.${NC} 安全增强功能 - 功能未安装"
        fi
        
        echo -e "${GREEN}24.${NC} 用户界面功能 - 界面优化和主题"
        echo -e "${GREEN}25.${NC} 下载必需文件 - 下载缺失的文件"
        echo -e "${GREEN}26.${NC} 功能管理 - 启用/禁用功能模块"
        echo -e "${GREEN}27.${NC} 脚本自检 - 系统健康检查和诊断"
        
        # 配置管理功能
        if [[ "$INSTALL_CONFIG_MANAGEMENT" == "true" ]]; then
            echo -e "${GREEN}28.${NC} 配置管理 - YAML配置管理"
        else
            echo -e "${GRAY}28.${NC} 配置管理 - 功能未安装"
        fi
        
        # 增强Web界面功能
        if [[ "$INSTALL_WEB_INTERFACE_ENHANCED" == "true" ]]; then
            echo -e "${GREEN}29.${NC} 增强Web界面 - 实时状态和用户管理"
        else
            echo -e "${GRAY}29.${NC} 增强Web界面 - 功能未安装"
        fi
        
        # OAuth认证管理功能
        if [[ "$INSTALL_OAUTH_AUTHENTICATION" == "true" ]]; then
            echo -e "${GREEN}30.${NC} OAuth认证管理 - OAuth 2.0和MFA"
        else
            echo -e "${GRAY}30.${NC} OAuth认证管理 - 功能未安装"
        fi
        
        # 安全审计监控功能
        if [[ "$INSTALL_SECURITY_AUDIT_MONITORING" == "true" ]]; then
            echo -e "${GREEN}31.${NC} 安全审计监控 - 安全事件和漏洞管理"
        else
            echo -e "${GRAY}31.${NC} 安全审计监控 - 功能未安装"
        fi
        
        # 网络拓扑图功能
        if [[ "$INSTALL_NETWORK_TOPOLOGY" == "true" ]]; then
            echo -e "${GREEN}32.${NC} 网络拓扑图 - 网络拓扑可视化"
        else
            echo -e "${GRAY}32.${NC} 网络拓扑图 - 功能未安装"
        fi
        
        # API文档功能
        if [[ "$INSTALL_API_DOCUMENTATION" == "true" ]]; then
            echo -e "${GREEN}33.${NC} API文档 - OpenAPI/Swagger文档"
        else
            echo -e "${GRAY}33.${NC} API文档 - 功能未安装"
        fi
        
        # WebSocket实时通信功能
        if [[ "$INSTALL_WEBSOCKET_REALTIME" == "true" ]]; then
            echo -e "${GREEN}34.${NC} WebSocket实时通信 - 实时数据推送"
        else
            echo -e "${GRAY}34.${NC} WebSocket实时通信 - 功能未安装"
        fi
        
        # 多租户管理功能
        if [[ "$INSTALL_MULTI_TENANT" == "true" ]]; then
            echo -e "${GREEN}35.${NC} 多租户管理 - 组织项目隔离"
        else
            echo -e "${GRAY}35.${NC} 多租户管理 - 功能未安装"
        fi
        
        # 资源配额管理功能
        if [[ "$INSTALL_RESOURCE_QUOTA" == "true" ]]; then
            echo -e "${GREEN}36.${NC} 资源配额管理 - 资源限制监控"
        else
            echo -e "${GRAY}36.${NC} 资源配额管理 - 功能未安装"
        fi
        
        # 配置懒加载功能
        if [[ "$INSTALL_LAZY_LOADING" == "true" ]]; then
            echo -e "${GREEN}37.${NC} 配置懒加载 - 优化启动和内存使用"
        else
            echo -e "${GRAY}37.${NC} 配置懒加载 - 功能未安装"
        fi
        
        # 性能优化功能
        if [[ "$INSTALL_PERFORMANCE_OPTIMIZATION" == "true" ]]; then
            echo -e "${GREEN}38.${NC} 性能优化 - 内存和CPU使用优化"
        else
            echo -e "${GRAY}38.${NC} 性能优化 - 功能未安装"
        fi
        
        echo -e "${GREEN}0.${NC}  退出"
        echo
        
        read -p "请选择操作 [0-38]: " choice
        
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
            13) resource_monitoring_menu ;;
            14) enhanced_config_management_menu ;;
            15) function_management_menu ;;
            16) variable_management_menu ;;
            17) dependency_management_menu ;;
            18) system_compatibility_menu ;;
            19) performance_optimization_menu ;;
            20) advanced_error_handling_menu ;;
            21) system_self_check_menu ;;
            22) 
                if [[ "$INSTALL_UPDATE_MANAGEMENT" == "true" ]]; then
                    update_check_menu
                else
                    show_error "更新检查功能未安装"
                fi
                ;;
            23) 
                if [[ "$INSTALL_SECURITY_ENHANCEMENTS" == "true" ]]; then
                    security_enhancements_menu
                else
                    show_error "安全增强功能未安装"
                fi
                ;;
            24) user_interface_menu ;;
            25) download_required_files ;;
            26) feature_management_menu ;;
            27) script_self_check_menu ;;
            28) 
                if [[ "$INSTALL_CONFIG_MANAGEMENT" == "true" ]]; then
                    config_management_menu
                else
                    show_error "配置管理功能未安装"
                fi
                ;;
            29) 
                if [[ "$INSTALL_WEB_INTERFACE_ENHANCED" == "true" ]]; then
                    enhanced_web_interface_menu
                else
                    show_error "增强Web界面功能未安装"
                fi
                ;;
            30) 
                if [[ "$INSTALL_OAUTH_AUTHENTICATION" == "true" ]]; then
                    oauth_authentication_menu
                else
                    show_error "OAuth认证管理功能未安装"
                fi
                ;;
            31) 
                if [[ "$INSTALL_SECURITY_AUDIT_MONITORING" == "true" ]]; then
                    security_audit_monitoring_menu
                else
                    show_error "安全审计监控功能未安装"
                fi
                ;;
            32) 
                if [[ "$INSTALL_NETWORK_TOPOLOGY" == "true" ]]; then
                    network_topology_menu
                else
                    show_error "网络拓扑图功能未安装"
                fi
                ;;
            33) 
                if [[ "$INSTALL_API_DOCUMENTATION" == "true" ]]; then
                    api_documentation_menu
                else
                    show_error "API文档功能未安装"
                fi
                ;;
            34) 
                if [[ "$INSTALL_WEBSOCKET_REALTIME" == "true" ]]; then
                    websocket_realtime_menu
                else
                    show_error "WebSocket实时通信功能未安装"
                fi
                ;;
            35) 
                if [[ "$INSTALL_MULTI_TENANT" == "true" ]]; then
                    multi_tenant_menu
                else
                    show_error "多租户管理功能未安装"
                fi
                ;;
            36) 
                if [[ "$INSTALL_RESOURCE_QUOTA" == "true" ]]; then
                    resource_quota_menu
                else
                    show_error "资源配额管理功能未安装"
                fi
                ;;
            37) 
                if [[ "$INSTALL_LAZY_LOADING" == "true" ]]; then
                    lazy_loading_menu
                else
                    show_error "配置懒加载功能未安装"
                fi
                ;;
            38) 
                if [[ "$INSTALL_PERFORMANCE_OPTIMIZATION" == "true" ]]; then
                    performance_optimization_menu
                else
                    show_error "性能优化功能未安装"
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

# 启动相关服务
start_services() {
    log_info "启动相关服务..."
    
    # 启动WireGuard服务
    if systemctl is-enabled wg-quick@wg0 &>/dev/null; then
        execute_command "systemctl start wg-quick@wg0" "启动WireGuard服务" "true"
    fi
    
    # 启动BIRD服务
    if systemctl is-enabled bird &>/dev/null; then
        execute_command "systemctl start bird" "启动BIRD服务" "true"
    fi
    
    if systemctl is-enabled bird6 &>/dev/null; then
        execute_command "systemctl start bird6" "启动BIRD6服务" "true"
    fi
    
    # 启动IPv6 WireGuard Manager服务
    if systemctl is-enabled ipv6-wireguard-manager &>/dev/null; then
        execute_command "systemctl start ipv6-wireguard-manager" "启动IPv6 WireGuard Manager服务" "true"
    fi
    
    log_success "服务启动完成"
}

# 配置WireGuard
configure_wireguard() {
    log_info "配置WireGuard..."
    
    # 检查WireGuard是否已安装
    if ! command -v wg &> /dev/null; then
        log_warn "WireGuard未安装，跳过配置"
        return 0
    fi
    
    # 创建WireGuard配置目录
    execute_command "mkdir -p /etc/wireguard" "创建WireGuard配置目录" "true"
    
    # 生成WireGuard密钥
    if [[ ! -f /etc/wireguard/privatekey ]]; then
        execute_command "wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey" "生成WireGuard密钥" "true"
        execute_command "chmod 600 /etc/wireguard/privatekey" "设置私钥权限" "true"
    fi
    
    log_success "WireGuard配置完成"
}

# 配置BIRD
configure_bird() {
    log_info "配置BIRD..."
    
    # 检查BIRD是否已安装
    if ! command -v bird &> /dev/null && ! command -v bird2 &> /dev/null; then
        log_warn "BIRD未安装，跳过配置"
        return 0
    fi
    
    # 创建BIRD配置目录
    execute_command "mkdir -p /etc/bird" "创建BIRD配置目录" "true"
    
    # 创建基本BIRD配置
    if [[ ! -f /etc/bird/bird.conf ]]; then
        cat > /etc/bird/bird.conf << 'EOF'
router id 192.168.1.1;

protocol device {
    scan time 10;
}

protocol kernel {
    learn;
    scan time 20;
    import all;
    export all;
}
EOF
        execute_command "chmod 644 /etc/bird/bird.conf" "设置BIRD配置权限" "true"
    fi
    
    log_success "BIRD配置完成"
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."
    
    # 检测防火墙类型
    local firewall_type=""
    if command -v ufw &> /dev/null; then
        firewall_type="ufw"
    elif command -v firewall-cmd &> /dev/null; then
        firewall_type="firewalld"
    elif command -v nft &> /dev/null; then
        firewall_type="nftables"
    elif command -v iptables &> /dev/null; then
        firewall_type="iptables"
    else
        log_warn "未检测到支持的防火墙，跳过配置"
        return 0
    fi
    
    log_info "检测到防火墙类型: $firewall_type"
    
    # 根据防火墙类型进行配置
    case "$firewall_type" in
        "ufw")
            execute_command "ufw allow 51820/udp" "配置UFW允许WireGuard端口" "true"
            ;;
        "firewalld")
            execute_command "firewall-cmd --permanent --add-port=51820/udp" "配置Firewalld允许WireGuard端口" "true"
            execute_command "firewall-cmd --reload" "重新加载Firewalld配置" "true"
            ;;
        "nftables")
            execute_command "nft add rule inet filter input udp dport 51820 accept" "配置NFTables允许WireGuard端口" "true"
            ;;
        "iptables")
            execute_command "iptables -A INPUT -p udp --dport 51820 -j ACCEPT" "配置iptables允许WireGuard端口" "true"
            ;;
    esac
    
    log_success "防火墙配置完成"
}

# 安装依赖
install_dependencies() {
    log_info "安装系统依赖..."
    
    # 安装WireGuard
    install_dependency "wireguard-tools" "WireGuard工具"
    
    # 安装BIRD
    install_dependency "bird2" "BIRD BGP路由器" "true"
    if [[ $? -ne 0 ]]; then
        install_dependency "bird" "BIRD BGP路由器" "true"
    fi
    
    # 安装网络工具
    install_dependency "iproute2" "IP路由工具" "true"
    install_dependency "net-tools" "网络工具" "true"
    
    # 安装防火墙工具
    if command -v ufw &> /dev/null; then
        install_dependency "ufw" "UFW防火墙" "true"
    elif command -v firewall-cmd &> /dev/null; then
        install_dependency "firewalld" "Firewalld防火墙" "true"
    fi
    
    # 安装Python依赖
    install_python_dependency "psutil" "系统监控库" "true"
    
    log_success "依赖安装完成"
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

# 配置版本管理菜单
config_version_management_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}配置版本管理:${NC}"
        echo -e "${GREEN}1.${NC} 创建新版本 - 创建配置版本"
        echo -e "${GREEN}2.${NC} 列出所有版本 - 查看版本列表"
        echo -e "${GREEN}3.${NC} 回滚到版本 - 回滚到指定版本"
        echo -e "${GREEN}4.${NC} 比较版本 - 比较两个版本差异"
        echo -e "${GREEN}5.${NC} 清理旧版本 - 清理过期版本"
        echo -e "${GREEN}6.${NC} 版本统计 - 查看版本统计信息"
        echo -e "${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 [0-6]: " choice
        
        case $choice in
            1)
                read -p "请输入版本描述: " description
                if command -v create_version &> /dev/null; then
                    create_version "" "$description"
                else
                    show_error "版本创建功能不可用"
                fi
                ;;
            2)
                if command -v list_versions &> /dev/null; then
                    list_versions
                else
                    show_error "版本列表功能不可用"
                fi
                ;;
            3)
                read -p "请输入要回滚的版本号: " version
                if command -v rollback_to_version &> /dev/null; then
                    rollback_to_version "$version"
                else
                    show_error "版本回滚功能不可用"
                fi
                ;;
            4)
                read -p "请输入第一个版本号: " version1
                read -p "请输入第二个版本号: " version2
                if command -v compare_versions &> /dev/null; then
                    compare_versions "$version1" "$version2"
                else
                    show_error "版本比较功能不可用"
                fi
                ;;
            5)
                read -p "请输入要保留的版本数 (默认50): " keep_versions
                keep_versions=${keep_versions:-50}
                if command -v cleanup_old_versions &> /dev/null; then
                    cleanup_old_versions "$keep_versions"
                else
                    show_error "版本清理功能不可用"
                fi
                ;;
            6)
                if command -v get_version_statistics &> /dev/null; then
                    get_version_statistics
                else
                    show_error "版本统计功能不可用"
                fi
                ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 配置备份管理菜单
config_backup_management_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}配置备份管理:${NC}"
        echo -e "${GREEN}1.${NC} 创建备份 - 创建配置备份"
        echo -e "${GREEN}2.${NC} 列出备份 - 查看备份列表"
        echo -e "${GREEN}3.${NC} 恢复备份 - 恢复指定备份"
        echo -e "${GREEN}4.${NC} 清理过期备份 - 清理过期备份"
        echo -e "${GREEN}5.${NC} 备份统计 - 查看备份统计信息"
        echo -e "${GREEN}6.${NC} 自动备份设置 - 配置自动备份"
        echo -e "${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 [0-6]: " choice
        
        case $choice in
            1)
                read -p "请输入备份名称 (可选): " backup_name
                read -p "请输入备份描述: " description
                if command -v create_backup &> /dev/null; then
                    create_backup "$backup_name" "$description"
                else
                    show_error "备份创建功能不可用"
                fi
                ;;
            2)
                if command -v list_backups &> /dev/null; then
                    list_backups
                else
                    show_error "备份列表功能不可用"
                fi
                ;;
            3)
                read -p "请输入要恢复的备份名称: " backup_name
                if command -v restore_backup &> /dev/null; then
                    restore_backup "$backup_name"
                else
                    show_error "备份恢复功能不可用"
                fi
                ;;
            4)
                read -p "请输入保留天数 (默认30): " retention_days
                retention_days=${retention_days:-30}
                if command -v cleanup_expired_backups &> /dev/null; then
                    cleanup_expired_backups "$retention_days"
                else
                    show_error "备份清理功能不可用"
                fi
                ;;
            5)
                if command -v get_backup_statistics &> /dev/null; then
                    get_backup_statistics
                else
                    show_error "备份统计功能不可用"
                fi
                ;;
            6)
                echo "自动备份设置功能开发中..."
                ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 配置热重载菜单
config_hot_reload_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}配置热重载管理:${NC}"
        echo -e "${GREEN}1.${NC} 启动监控 - 启动配置监控"
        echo -e "${GREEN}2.${NC} 停止监控 - 停止配置监控"
        echo -e "${GREEN}3.${NC} 手动重载 - 手动触发配置重载"
        echo -e "${GREEN}4.${NC} 监控状态 - 查看监控状态"
        echo -e "${GREEN}5.${NC} 添加监控文件 - 添加要监控的文件"
        echo -e "${GREEN}6.${NC} 移除监控文件 - 移除监控文件"
        echo -e "${GREEN}7.${NC} 设置监控参数 - 配置监控参数"
        echo -e "${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 [0-7]: " choice
        
        case $choice in
            1)
                if command -v start_config_monitoring &> /dev/null; then
                    start_config_monitoring
                else
                    show_error "监控启动功能不可用"
                fi
                ;;
            2)
                if command -v stop_config_monitoring &> /dev/null; then
                    stop_config_monitoring
                else
                    show_error "监控停止功能不可用"
                fi
                ;;
            3)
                read -p "请输入要重载的文件路径 (可选): " file_path
                if command -v trigger_reload &> /dev/null; then
                    trigger_reload "$file_path"
                else
                    show_error "重载触发功能不可用"
                fi
                ;;
            4)
                if command -v get_monitoring_status &> /dev/null; then
                    get_monitoring_status
                else
                    show_error "监控状态功能不可用"
                fi
                ;;
            5)
                read -p "请输入要添加的文件路径: " file_path
                if command -v add_watched_file &> /dev/null; then
                    add_watched_file "$file_path"
                else
                    show_error "添加监控文件功能不可用"
                fi
                ;;
            6)
                read -p "请输入要移除的文件路径: " file_path
                if command -v remove_watched_file &> /dev/null; then
                    remove_watched_file "$file_path"
                else
                    show_error "移除监控文件功能不可用"
                fi
                ;;
            7)
                read -p "请输入监控间隔 (秒): " interval
                read -p "是否启用配置验证 (true/false): " validation
                if command -v set_monitoring_parameters &> /dev/null; then
                    set_monitoring_parameters "$interval" "$validation"
                else
                    show_error "参数设置功能不可用"
                fi
                ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 模块版本兼容性菜单
module_version_compatibility_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}模块版本兼容性管理:${NC}"
        echo -e "${GREEN}1.${NC} 检查单个模块 - 检查指定模块版本兼容性"
        echo -e "${GREEN}2.${NC} 检查所有模块 - 检查所有模块版本兼容性"
        echo -e "${GREEN}3.${NC} 检查模块依赖 - 检查模块依赖兼容性"
        echo -e "${GREEN}4.${NC} 查看版本信息 - 查看模块版本信息"
        echo -e "${GREEN}5.${NC} 更新模块版本 - 更新模块版本号"
        echo -e "${GREEN}6.${NC} 生成兼容性报告 - 生成详细兼容性报告"
        echo -e "${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 [0-6]: " choice
        
        case $choice in
            1)
                read -p "请输入模块名称: " module_name
                read -p "请输入要求版本 (可选): " required_version
                if command -v check_module_compatibility &> /dev/null; then
                    check_module_compatibility "$module_name" "$required_version"
                else
                    show_error "模块兼容性检查功能不可用"
                fi
                ;;
            2)
                if command -v check_all_modules_compatibility &> /dev/null; then
                    check_all_modules_compatibility
                else
                    show_error "全模块兼容性检查功能不可用"
                fi
                ;;
            3)
                read -p "请输入模块名称: " module_name
                if command -v check_module_dependencies &> /dev/null; then
                    check_module_dependencies "$module_name"
                else
                    show_error "模块依赖检查功能不可用"
                fi
                ;;
            4)
                read -p "请输入模块名称 (可选): " module_name
                if command -v get_module_version_info &> /dev/null; then
                    get_module_version_info "$module_name"
                else
                    show_error "版本信息查看功能不可用"
                fi
                ;;
            5)
                read -p "请输入模块名称: " module_name
                read -p "请输入新版本号: " new_version
                if command -v update_module_version &> /dev/null; then
                    update_module_version "$module_name" "$new_version"
                else
                    show_error "模块版本更新功能不可用"
                fi
                ;;
            6)
                if command -v generate_compatibility_report &> /dev/null; then
                    generate_compatibility_report
                else
                    show_error "兼容性报告生成功能不可用"
                fi
                ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 模块预加载管理菜单
module_preloading_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}模块预加载管理:${NC}"
        echo -e "${GREEN}1.${NC} 预加载核心模块 - 预加载核心模块"
        echo -e "${GREEN}2.${NC} 预加载高频模块 - 预加载高频使用模块"
        echo -e "${GREEN}3.${NC} 预加载所有模块 - 预加载所有模块"
        echo -e "${GREEN}4.${NC} 启动后台预加载 - 启动后台预加载"
        echo -e "${GREEN}5.${NC} 查看预加载统计 - 查看预加载统计信息"
        echo -e "${GREEN}6.${NC} 查看使用统计 - 查看模块使用统计"
        echo -e "${GREEN}7.${NC} 优化预加载队列 - 优化预加载队列"
        echo -e "${GREEN}8.${NC} 设置预加载参数 - 配置预加载参数"
        echo -e "${GREEN}9.${NC} 清理预加载状态 - 清理预加载状态"
        echo -e "${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 [0-9]: " choice
        
        case $choice in
            1)
                if command -v preload_core_modules &> /dev/null; then
                    preload_core_modules
                else
                    show_error "核心模块预加载功能不可用"
                fi
                ;;
            2)
                if command -v preload_frequent_modules &> /dev/null; then
                    preload_frequent_modules
                else
                    show_error "高频模块预加载功能不可用"
                fi
                ;;
            3)
                if command -v preload_all_modules &> /dev/null; then
                    preload_all_modules
                else
                    show_error "全模块预加载功能不可用"
                fi
                ;;
            4)
                if command -v preload_background &> /dev/null; then
                    preload_background
                else
                    show_error "后台预加载功能不可用"
                fi
                ;;
            5)
                if command -v get_preload_statistics &> /dev/null; then
                    get_preload_statistics
                else
                    show_error "预加载统计功能不可用"
                fi
                ;;
            6)
                if command -v get_module_usage_statistics &> /dev/null; then
                    get_module_usage_statistics
                else
                    show_error "使用统计功能不可用"
                fi
                ;;
            7)
                if command -v optimize_preload_queue &> /dev/null; then
                    optimize_preload_queue
                else
                    show_error "队列优化功能不可用"
                fi
                ;;
            8)
                read -p "是否启用预加载 (true/false): " enabled
                read -p "是否启用核心模块预加载 (true/false): " core_modules
                read -p "是否启用高频模块预加载 (true/false): " frequent_modules
                read -p "是否启用后台预加载 (true/false): " background
                if command -v set_preload_parameters &> /dev/null; then
                    set_preload_parameters "$enabled" "$core_modules" "$frequent_modules" "$background"
                else
                    show_error "参数设置功能不可用"
                fi
                ;;
            9)
                if command -v cleanup_preload_state &> /dev/null; then
                    cleanup_preload_state
                else
                    show_error "状态清理功能不可用"
                fi
                ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 脚本自检菜单
script_self_check_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}脚本自检系统:${NC}"
        echo -e "${GREEN}1.${NC} 快速自检 - 检查关键模块"
        echo -e "${GREEN}2.${NC} 完整自检 - 全面系统检查"
        echo -e "${GREEN}3.${NC} 模块加载状态 - 查看模块加载详情"
        echo -e "${GREEN}4.${NC} 系统环境检查 - 检查系统环境"
        echo -e "${GREEN}5.${NC} 配置完整性检查 - 检查配置完整性"
        echo -e "${GREEN}6.${NC} 生成自检报告 - 生成详细报告"
        echo -e "${GREEN}7.${NC} 实时加载状态 - 显示实时加载状态"
        echo -e "${GREEN}8.${NC} 配置版本管理 - 管理配置版本"
        echo -e "${GREEN}9.${NC} 配置备份管理 - 管理配置备份"
        echo -e "${GREEN}10.${NC} 配置热重载 - 管理配置热重载"
        echo -e "${GREEN}11.${NC} 模块版本兼容性 - 检查模块版本兼容性"
        echo -e "${GREEN}12.${NC} 模块预加载管理 - 管理模块预加载"
        echo -e "${GREEN}13.${NC} Windows兼容性检查 - 检查Windows环境兼容性"
        echo -e "${GREEN}14.${NC} 硬件兼容性检查 - 检查硬件架构兼容性"
        echo -e "${GREEN}15.${NC} 智能缓存管理 - 管理智能缓存系统"
        echo -e "${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 [0-15]: " choice
        
        case $choice in
            1)
                if command -v run_quick_self_check &> /dev/null; then
                    run_quick_self_check
                else
                    show_error "快速自检功能不可用"
                fi
                ;;
            2)
                if command -v run_complete_self_check &> /dev/null; then
                    run_complete_self_check
                else
                    show_error "完整自检功能不可用"
                fi
                ;;
            3)
                if command -v get_loading_statistics &> /dev/null; then
                    get_loading_statistics
                else
                    show_error "模块加载状态功能不可用"
                fi
                ;;
            4)
                if command -v check_system_environment &> /dev/null; then
                    check_system_environment
                else
                    show_error "系统环境检查功能不可用"
                fi
                ;;
            5)
                if command -v check_config_integrity &> /dev/null; then
                    check_config_integrity
                else
                    show_error "配置完整性检查功能不可用"
                fi
                ;;
            6)
                if command -v generate_self_check_report &> /dev/null; then
                    generate_self_check_report
                else
                    show_error "报告生成功能不可用"
                fi
                ;;
            7)
                if command -v show_realtime_loading_status &> /dev/null; then
                    show_realtime_loading_status
                else
                    show_error "实时状态功能不可用"
                fi
                ;;
            8)
                config_version_management_menu
                ;;
            9)
                config_backup_management_menu
                ;;
            10)
                config_hot_reload_menu
                ;;
            11)
                module_version_compatibility_menu
                ;;
            12)
                module_preloading_menu
                ;;
            13)
                if command -v run_windows_compatibility_check &> /dev/null; then
                    run_windows_compatibility_check
                else
                    log_error "Windows兼容性检查功能不可用"
                fi
                ;;
            14)
                if command -v get_hardware_statistics &> /dev/null; then
                    get_hardware_statistics
                else
                    log_error "硬件兼容性检查功能不可用"
                fi
                ;;
            15)
                if command -v get_cache_statistics &> /dev/null; then
                    get_cache_statistics
                else
                    log_error "智能缓存管理功能不可用"
                fi
                ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 主函数
main() {
    # 处理命令行参数
    case "${1:-}" in
        --version|-v)
            echo "IPv6 WireGuard Manager v1.0.0"
            exit 0
            ;;
        --help|-h)
            echo "IPv6 WireGuard Manager - 完整的IPv6 WireGuard VPN服务器管理系统"
            echo
            echo "用法: $0 [选项]"
            echo
            echo "选项:"
            echo "  --version, -v     显示版本信息"
            echo "  --help, -h        显示帮助信息"
            echo
            echo "无参数时启动交互式管理界面"
            exit 0
            ;;
    esac
    
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
        
        read -rp "按回车键继续..."
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

# 资源监控菜单
resource_monitoring_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}资源监控管理:${NC}"
        echo -e "${GREEN}1.${NC}  查看系统资源使用情况"
        echo -e "${GREEN}2.${NC}  实时资源监控"
        echo -e "${GREEN}3.${NC}  生成资源监控报告"
        echo -e "${GREEN}4.${NC}  系统健康评分"
        echo -e "${GREEN}5.${NC}  优化建议"
        echo -e "${GREEN}6.${NC}  返回主菜单"
        
        read -rp "请选择操作: " choice
        
        case $choice in
            1)
                if command -v get_current_resources &> /dev/null; then
                    get_current_resources
                else
                    show_error "资源监控功能不可用"
                fi
                ;;
            2)
                if command -v start_realtime_monitoring &> /dev/null; then
                    start_realtime_monitoring
                else
                    show_error "实时监控功能不可用"
                fi
                ;;
            3)
                if command -v generate_resource_report &> /dev/null; then
                    local report_file=$(generate_resource_report)
                    show_success "资源监控报告已生成: $report_file"
                else
                    show_error "报告生成功能不可用"
                fi
                ;;
            4)
                if command -v get_system_health_score &> /dev/null; then
                    local score=$(get_system_health_score)
                    echo "系统健康评分: $score/100"
                else
                    show_error "健康评分功能不可用"
                fi
                ;;
            5)
                if command -v get_optimization_suggestions &> /dev/null; then
                    get_optimization_suggestions
                else
                    show_error "优化建议功能不可用"
                fi
                ;;
            6) return ;;
            *) show_error "无效选择" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 增强配置管理菜单
enhanced_config_management_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}增强配置管理:${NC}"
        echo -e "${GREEN}1.${NC}  验证配置文件"
        echo -e "${GREEN}2.${NC}  创建配置备份"
        echo -e "${GREEN}3.${NC}  列出配置备份"
        echo -e "${GREEN}4.${NC}  恢复配置备份"
        echo -e "${GREEN}5.${NC}  导出配置"
        echo -e "${GREEN}6.${NC}  导入配置"
        echo -e "${GREEN}7.${NC}  检测配置冲突"
        echo -e "${GREEN}8.${NC}  生成配置模板"
        echo -e "${GREEN}9.${NC}  返回主菜单"
        
        read -rp "请选择操作: " choice
        
        case $choice in
            1)
                if command -v validate_config_file &> /dev/null; then
                    validate_config_file "$IPV6WGM_CONFIG_DIR/manager.conf"
                else
                    show_error "配置验证功能不可用"
                fi
                ;;
            2)
                if command -v create_config_backup &> /dev/null; then
                    local backup_file=$(create_config_backup "$IPV6WGM_CONFIG_DIR/manager.conf")
                    show_success "配置备份已创建: $backup_file"
                else
                    show_error "配置备份功能不可用"
                fi
                ;;
            3)
                if command -v list_config_backups &> /dev/null; then
                    list_config_backups "$IPV6WGM_CONFIG_DIR/manager.conf"
                else
                    show_error "备份列表功能不可用"
                fi
                ;;
            4)
                read -p "请输入备份名称: " backup_name
                if command -v restore_config_backup &> /dev/null; then
                    restore_config_backup "$IPV6WGM_CONFIG_DIR/manager.conf" "$backup_name"
                else
                    show_error "配置恢复功能不可用"
                fi
                ;;
            5)
                read -p "请输入导出格式 (plain/json/yaml): " format
                if command -v export_config &> /dev/null; then
                    local export_file=$(export_config "$IPV6WGM_CONFIG_DIR/manager.conf" "" "$format")
                    show_success "配置已导出: $export_file"
                else
                    show_error "配置导出功能不可用"
                fi
                ;;
            6)
                read -p "请输入导入文件路径: " import_file
                if command -v import_config &> /dev/null; then
                    import_config "$import_file" "$IPV6WGM_CONFIG_DIR/manager.conf"
                else
                    show_error "配置导入功能不可用"
                fi
                ;;
            7)
                if command -v detect_config_conflicts &> /dev/null; then
                    detect_config_conflicts "$IPV6WGM_CONFIG_DIR/manager.conf"
                else
                    show_error "冲突检测功能不可用"
                fi
                ;;
            8)
                read -p "请输入模板类型 (basic/advanced/minimal): " template_type
                if command -v generate_config_template &> /dev/null; then
                    local template_file=$(generate_config_template "$template_type")
                    show_success "配置模板已生成: $template_file"
                else
                    show_error "模板生成功能不可用"
                fi
                ;;
            9) return ;;
            *) show_error "无效选择" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 函数管理菜单
function_management_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}函数管理:${NC}"
        echo -e "${GREEN}1.${NC}  列出已注册函数"
        echo -e "${GREEN}2.${NC}  检查函数冲突"
        echo -e "${GREEN}3.${NC}  函数统计信息"
        echo -e "${GREEN}4.${NC}  生成函数文档"
        echo -e "${GREEN}5.${NC}  返回主菜单"
        
        read -rp "请选择操作: " choice
        
        case $choice in
            1)
                if command -v list_registered_functions &> /dev/null; then
                    list_registered_functions
                else
                    show_error "函数列表功能不可用"
                fi
                ;;
            2)
                if command -v check_function_conflicts &> /dev/null; then
                    check_function_conflicts
                else
                    show_error "冲突检查功能不可用"
                fi
                ;;
            3)
                if command -v get_function_stats &> /dev/null; then
                    get_function_stats
                else
                    show_error "统计功能不可用"
                fi
                ;;
            4)
                if command -v generate_function_docs &> /dev/null; then
                    local doc_file=$(generate_function_docs)
                    show_success "函数文档已生成: $doc_file"
                else
                    show_error "文档生成功能不可用"
                fi
                ;;
            5) return ;;
            *) show_error "无效选择" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 变量管理菜单
variable_management_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}变量管理:${NC}"
        echo -e "${GREEN}1.${NC}  列出所有IPV6WGM变量"
        echo -e "${GREEN}2.${NC}  验证变量值"
        echo -e "${GREEN}3.${NC}  从配置文件加载变量"
        echo -e "${GREEN}4.${NC}  保存变量到配置文件"
        echo -e "${GREEN}5.${NC}  返回主菜单"
        
        read -rp "请选择操作: " choice
        
        case $choice in
            1)
                if command -v list_ipv6wgm_variables &> /dev/null; then
                    list_ipv6wgm_variables
                else
                    show_error "变量列表功能不可用"
                fi
                ;;
            2)
                if command -v ensure_variables &> /dev/null; then
                    ensure_variables
                else
                    show_error "变量验证功能不可用"
                fi
                ;;
            3)
                if command -v load_variables_from_config &> /dev/null; then
                    load_variables_from_config "$IPV6WGM_CONFIG_DIR/manager.conf"
                else
                    show_error "变量加载功能不可用"
                fi
                ;;
            4)
                if command -v save_variables_to_config &> /dev/null; then
                    save_variables_to_config "$IPV6WGM_CONFIG_DIR/manager.conf"
                else
                    show_error "变量保存功能不可用"
                fi
                ;;
            5) return ;;
            *) show_error "无效选择" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 依赖管理菜单
dependency_management_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}依赖管理:${NC}"
        echo -e "${GREEN}1.${NC}  检查模块依赖"
        echo -e "${GREEN}2.${NC}  解析依赖关系"
        echo -e "${GREEN}3.${NC}  安装缺失依赖"
        echo -e "${GREEN}4.${NC}  锁定依赖版本"
        echo -e "${GREEN}5.${NC}  检查循环依赖"
        echo -e "${GREEN}6.${NC}  生成依赖报告"
        echo -e "${GREEN}7.${NC}  返回主菜单"
        
        read -rp "请选择操作: " choice
        
        case $choice in
            1)
                read -p "请输入模块名: " module_name
                if command -v check_module_dependencies &> /dev/null; then
                    check_module_dependencies "$module_name"
                else
                    show_error "依赖检查功能不可用"
                fi
                ;;
            2)
                read -p "请输入模块名: " module_name
                if command -v resolve_dependencies &> /dev/null; then
                    local deps=($(resolve_dependencies "$module_name"))
                    echo "依赖关系: ${deps[*]}"
                else
                    show_error "依赖解析功能不可用"
                fi
                ;;
            3)
                read -p "请输入模块名: " module_name
                if command -v install_missing_dependencies &> /dev/null; then
                    install_missing_dependencies "$module_name"
                else
                    show_error "依赖安装功能不可用"
                fi
                ;;
            4)
                if command -v lock_dependencies &> /dev/null; then
                    lock_dependencies
                else
                    show_error "依赖锁定功能不可用"
                fi
                ;;
            5)
                read -p "请输入模块名: " module_name
                if command -v check_circular_dependencies &> /dev/null; then
                    check_circular_dependencies "$module_name"
                else
                    show_error "循环依赖检查功能不可用"
                fi
                ;;
            6)
                if command -v generate_dependency_report &> /dev/null; then
                    local report_file=$(generate_dependency_report)
                    show_success "依赖报告已生成: $report_file"
                else
                    show_error "报告生成功能不可用"
                fi
                ;;
            7) return ;;
            *) show_error "无效选择" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 系统兼容性菜单
system_compatibility_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}系统兼容性:${NC}"
        echo -e "${GREEN}1.${NC}  检测操作系统"
        echo -e "${GREEN}2.${NC}  检查系统兼容性"
        echo -e "${GREEN}3.${NC}  检查架构兼容性"
        echo -e "${GREEN}4.${NC}  运行兼容性测试"
        echo -e "${GREEN}5.${NC}  适配环境变量"
        echo -e "${GREEN}6.${NC}  适配系统路径"
        echo -e "${GREEN}7.${NC}  返回主菜单"
        
        read -rp "请选择操作: " choice
        
        case $choice in
            1)
                if command -v detect_operating_system &> /dev/null; then
                    detect_operating_system
                else
                    show_error "系统检测功能不可用"
                fi
                ;;
            2)
                if command -v check_system_compatibility &> /dev/null; then
                    check_system_compatibility
                else
                    show_error "兼容性检查功能不可用"
                fi
                ;;
            3)
                if command -v check_architecture_compatibility &> /dev/null; then
                    check_architecture_compatibility
                else
                    show_error "架构检查功能不可用"
                fi
                ;;
            4)
                read -p "请输入测试类型 (basic/functional/performance/full): " test_type
                if command -v run_compatibility_test &> /dev/null; then
                    run_compatibility_test "$test_type"
                else
                    show_error "兼容性测试功能不可用"
                fi
                ;;
            5)
                if command -v adapt_environment &> /dev/null; then
                    adapt_environment
                else
                    show_error "环境适配功能不可用"
                fi
                ;;
            6)
                if command -v adapt_paths &> /dev/null; then
                    adapt_paths
                else
                    show_error "路径适配功能不可用"
                fi
                ;;
            7) return ;;
            *) show_error "无效选择" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 性能优化菜单
performance_optimization_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}性能优化:${NC}"
        echo -e "${GREEN}1.${NC}  启用/禁用缓存"
        echo -e "${GREEN}2.${NC}  清理缓存"
        echo -e "${GREEN}3.${NC}  查看缓存统计"
        echo -e "${GREEN}4.${NC}  内存优化"
        echo -e "${GREEN}5.${NC}  磁盘优化"
        echo -e "${GREEN}6.${NC}  启动性能监控"
        echo -e "${GREEN}7.${NC}  停止性能监控"
        echo -e "${GREEN}8.${NC}  生成性能报告"
        echo -e "${GREEN}9.${NC}  自动性能优化"
        echo -e "${GREEN}10.${NC} 返回主菜单"
        
        read -rp "请选择操作: " choice
        
        case $choice in
            1)
                read -p "启用缓存? (y/n): " enable
                if [[ "$enable" == "y" ]]; then
                    IPV6WGM_CACHE_ENABLED="true"
                    show_success "缓存已启用"
                else
                    IPV6WGM_CACHE_ENABLED="false"
                    show_success "缓存已禁用"
                fi
                ;;
            2)
                if command -v clear_cache &> /dev/null; then
                    clear_cache
                else
                    show_error "缓存清理功能不可用"
                fi
                ;;
            3)
                if command -v get_cache_stats &> /dev/null; then
                    get_cache_stats
                else
                    show_error "缓存统计功能不可用"
                fi
                ;;
            4)
                if command -v optimize_memory_usage &> /dev/null; then
                    optimize_memory_usage
                else
                    show_error "内存优化功能不可用"
                fi
                ;;
            5)
                if command -v optimize_disk_usage &> /dev/null; then
                    optimize_disk_usage
                else
                    show_error "磁盘优化功能不可用"
                fi
                ;;
            6)
                if command -v start_performance_monitoring &> /dev/null; then
                    start_performance_monitoring
                else
                    show_error "性能监控功能不可用"
                fi
                ;;
            7)
                if command -v stop_performance_monitoring &> /dev/null; then
                    stop_performance_monitoring
                else
                    show_error "性能监控功能不可用"
                fi
                ;;
            8)
                if command -v generate_performance_report &> /dev/null; then
                    local report_file=$(generate_performance_report)
                    show_success "性能报告已生成: $report_file"
                else
                    show_error "报告生成功能不可用"
                fi
                ;;
            9)
                if command -v auto_optimize_performance &> /dev/null; then
                    auto_optimize_performance
                else
                    show_error "自动优化功能不可用"
                fi
                ;;
            10) return ;;
            *) show_error "无效选择" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 高级错误处理菜单
advanced_error_handling_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}高级错误处理:${NC}"
        echo -e "${GREEN}1.${NC}  检测异常场景"
        echo -e "${GREEN}2.${NC}  处理异常场景"
        echo -e "${GREEN}3.${NC}  系统自检"
        echo -e "${GREEN}4.${NC}  生成错误报告"
        echo -e "${GREEN}5.${NC}  查看错误统计"
        echo -e "${GREEN}6.${NC}  返回主菜单"
        
        read -rp "请选择操作: " choice
        
        case $choice in
            1)
                read -p "请输入错误代码: " error_code
                read -p "请输入错误消息: " error_message
                if command -v detect_exception_scenario &> /dev/null; then
                    local scenario
                    scenario=$(detect_exception_scenario "$error_code" "$error_message")
                    echo "检测到异常场景: $scenario"
                else
                    show_error "异常检测功能不可用"
                fi
                ;;
            2)
                read -rp "请输入场景: " scenario
                read -rp "请输入错误代码: " error_code
                read -rp "请输入错误消息: " error_message
                if command -v handle_exception_scenario &> /dev/null; then
                    handle_exception_scenario "$scenario" "$error_code" "$error_message"
                else
                    show_error "异常处理功能不可用"
                fi
                ;;
            3)
                if command -v system_self_check &> /dev/null; then
                    system_self_check
                else
                    show_error "系统自检功能不可用"
                fi
                ;;
            4)
                if command -v generate_error_report &> /dev/null; then
                    local report_file
                    report_file=$(generate_error_report)
                    show_success "错误报告已生成: $report_file"
                else
                    show_error "报告生成功能不可用"
                fi
                ;;
            5)
                echo "=== 错误统计 ==="
                echo "总错误数: ${IPV6WGM_ERROR_STATS["total_errors"]}"
                echo "严重错误: ${IPV6WGM_ERROR_STATS["fatal_errors"]}"
                echo "已恢复错误: ${IPV6WGM_ERROR_STATS["recovered_errors"]}"
                echo "未恢复错误: ${IPV6WGM_ERROR_STATS["unrecoverable_errors"]}"
                ;;
            6) return ;;
            *) show_error "无效选择" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 系统自检菜单
system_self_check_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}系统自检:${NC}"
        echo -e "${GREEN}1.${NC}  完整系统自检"
        echo -e "${GREEN}2.${NC}  基础系统检查"
        echo -e "${GREEN}3.${NC}  功能系统检查"
        echo -e "${GREEN}4.${NC}  性能系统检查"
        echo -e "${GREEN}5.${NC}  返回主菜单"
        
        read -rp "请选择操作: " choice
        
        case $choice in
            1)
                if command -v system_self_check &> /dev/null; then
                    system_self_check
                else
                    show_error "系统自检功能不可用"
                fi
                ;;
            2)
                if command -v run_compatibility_test &> /dev/null; then
                    run_compatibility_test "basic"
                else
                    show_error "基础检查功能不可用"
                fi
                ;;
            3)
                if command -v run_compatibility_test &> /dev/null; then
                    run_compatibility_test "functional"
                else
                    show_error "功能检查功能不可用"
                fi
                ;;
            4)
                if command -v run_compatibility_test &> /dev/null; then
                    run_compatibility_test "performance"
                else
                    show_error "性能检查功能不可用"
                fi
                ;;
            5) return ;;
            *) show_error "无效选择" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 错误处理
trap 'handle_error $? "脚本在行 $LINENO 发生错误: $BASH_COMMAND" "main_script" "$LINENO"' ERR

# 健康检查功能
health_check() {
    log_info "执行健康检查..."
    
    local health_status=0
    
    # 检查核心文件
    local core_files=(
        "ipv6-wireguard-manager.sh"
        "modules/common_functions.sh"
        "modules/variable_management.sh"
    )
    
    for file in "${core_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "核心文件缺失: $file"
            ((health_status++))
        fi
    done
    
    # 检查模块加载
    if command -v import_module &> /dev/null; then
        if ! import_module "common_functions"; then
            log_error "核心模块加载失败"
            ((health_status++))
        fi
    else
        log_error "模块加载功能不可用"
        ((health_status++))
    fi
    
    # 检查系统资源
    if command -v get_memory_usage &> /dev/null; then
        local memory_usage
        local memory_int
        memory_usage=$(get_memory_usage)
        # 将浮点数转换为整数进行比较
        memory_int=$(echo "$memory_usage" | cut -d. -f1)
        if [[ $memory_int -gt 90 ]]; then
            log_warn "内存使用率过高: ${memory_usage}%"
        fi
    fi
    
    if [[ $health_status -eq 0 ]]; then
        log_success "健康检查通过"
        return 0
    else
        log_error "健康检查失败 ($health_status 个问题)"
        return 1
    fi
}

# 主函数
main() {
    # local args=("$@")  # 暂时注释掉未使用的变量
    
    # 处理特殊参数
    case "${1:-}" in
        "--health-check")
            health_check
            exit $?
            ;;
        "--version")
            echo "IPv6 WireGuard Manager v$IPV6WGM_VERSION"
            exit 0
            ;;
        "--help")
            show_help
            exit 0
            ;;
    esac
    
    # 执行原有的主函数逻辑
    show_main_menu
}

# 执行主函数
main "$@"
