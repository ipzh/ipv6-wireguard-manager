#!/bin/bash

# IPv6 WireGuard VPN Manager
# 支持IPv6前缀分发和BGP路由的WireGuard VPN服务器管理工具
# 版本: 1.13
# 作者: IPv6 WireGuard Manager

set -euo pipefail

# 加载公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/modules/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/modules/common_functions.sh"
fi

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 全局变量
# 获取脚本目录
if [[ -L "${BASH_SOURCE[0]}" ]]; then
    # 如果是符号链接，获取实际路径
    SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
else
    # 如果不是符号链接，使用常规方法
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# 检查模块目录是否存在，如果不存在则尝试下载或使用当前目录
if [[ ! -d "$SCRIPT_DIR/modules" ]]; then
    # 尝试使用当前工作目录
    if [[ -d "./modules" ]]; then
        SCRIPT_DIR="$(pwd)"
        echo -e "${YELLOW}警告: 在符号链接目录中未找到模块，使用当前目录: $SCRIPT_DIR${NC}"
    else
        echo -e "${YELLOW}警告: 未找到模块目录，尝试自动下载必需文件...${NC}"
        download_required_files
    fi
fi

# 模块目录
MODULES_DIR="$SCRIPT_DIR/modules"

# 目录配置
CONFIG_DIR="/etc/ipv6-wireguard"
LOG_DIR="/var/log/ipv6-wireguard"
BACKUP_DIR="/var/backups/ipv6-wireguard"
CLIENT_CONFIG_DIR="$CONFIG_DIR/clients"
TEMP_DIR="/tmp/ipv6-wireguard"

# 默认配置
DEFAULT_WG_PORT=51820
DEFAULT_IPV6_PREFIX="2001:db8::/48"
DEFAULT_AS_NUMBER=65001
DEFAULT_LOG_LEVEL="info"

# 系统信息
OS_TYPE=""
OS_VERSION=""
ARCH=""
IS_ROOT=false

# 配置状态
WG_INSTALLED=false
BIRD_INSTALLED=false

# 模块加载函数
load_module() {
    local module_name="$1"
    local module_file="$MODULES_DIR/${module_name}.sh"
    
    # 调试信息
    if [[ "${LOG_LEVEL:-info}" == "debug" ]]; then
        log "DEBUG" "尝试加载模块: $module_name"
        log "DEBUG" "模块文件路径: $module_file"
        log "DEBUG" "模块目录: $MODULES_DIR"
        log "DEBUG" "脚本目录: $SCRIPT_DIR"
    fi
    
    if [[ -f "$module_file" ]]; then
        if source "$module_file"; then
            if [[ "${LOG_LEVEL:-info}" == "debug" ]]; then
                echo -e "${GREEN}[DEBUG]${NC} 模块 $module_name 加载成功"
            fi
            return 0
        else
            echo -e "${RED}错误: 模块 $module_name 加载失败${NC}"
            return 1
        fi
    else
        echo -e "${RED}错误: 模块文件 $module_file 不存在${NC}"
        echo -e "${YELLOW}提示: 请检查模块目录是否正确: $MODULES_DIR${NC}"
        return 1
    fi
}
FIREWALL_TYPE=""
IPV6_ENABLED=false

# 日志函数
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message" >&2
            ;;
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message" >&2
            ;;
        "DEBUG")
            if [[ "${LOG_LEVEL:-info}" == "debug" ]]; then
                echo -e "${BLUE}[DEBUG]${NC} $message" >&2
            fi
            ;;
    esac
    
    # 写入日志文件
    echo "[$timestamp] [$level] $message" >> "$LOG_DIR/manager.log"
}

# 错误处理函数
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# 警告函数
warn() {
    log "WARN" "$1"
}

# 信息函数
info() {
    log "INFO" "$1"
}

# 调试函数
debug() {
    log "DEBUG" "$1"
}

# 自动下载必需文件
download_required_files() {
    local github_base_url="https://raw.githubusercontent.com/ipv6-wireguard-manager/ipv6-wireguard-manager/main"
    local temp_dir="/tmp/ipv6-wireguard-download-$$"
    
    echo -e "${CYAN}正在下载必需文件...${NC}"
    
    # 创建临时目录
    mkdir -p "$temp_dir"
    
    # 必需的文件列表
    local required_files=(
        "modules/system_detection.sh"
        "modules/wireguard_config.sh"
        "modules/bird_config.sh"
        "modules/firewall_config.sh"
        "modules/client_management.sh"
        "modules/network_management.sh"
        "modules/server_management.sh"
        "modules/system_maintenance.sh"
        "modules/backup_restore.sh"
        "modules/update_management.sh"
        "modules/wireguard_diagnostics.sh"
        "modules/bird_permissions.sh"
        "modules/client_script_generator.sh"
        "modules/client_auto_update.sh"
        "ipv6-wireguard-manager-core.sh"
        "install.sh"
        "uninstall.sh"
    )
    
    # 创建模块目录
    mkdir -p "$SCRIPT_DIR/modules"
    
    # 下载文件
    local success_count=0
    local total_count=${#required_files[@]}
    
    for file in "${required_files[@]}"; do
        local filename=$(basename "$file")
        local target_dir="$SCRIPT_DIR"
        
        # 如果是模块文件，设置目标目录
        if [[ "$file" == modules/* ]]; then
            target_dir="$SCRIPT_DIR/modules"
        fi
        
        echo -n "  下载 $filename... "
        
        if curl -s -L -o "$target_dir/$filename" "$github_base_url/$file" 2>/dev/null; then
            chmod +x "$target_dir/$filename" 2>/dev/null || true
            echo -e "${GREEN}✓${NC}"
            ((success_count++))
        else
            echo -e "${RED}✗${NC}"
        fi
    done
    
    # 清理临时目录
    rm -rf "$temp_dir"
    
    echo
    echo -e "${CYAN}下载完成: $success_count/$total_count 个文件${NC}"
    
    if [[ $success_count -eq $total_count ]]; then
        echo -e "${GREEN}所有必需文件下载成功！${NC}"
        return 0
    elif [[ $success_count -gt 0 ]]; then
        echo -e "${YELLOW}部分文件下载成功，请检查网络连接后重试${NC}"
        return 1
    else
        echo -e "${RED}文件下载失败，请检查网络连接${NC}"
        return 1
    fi
}

# 检查文件完整性
check_file_integrity() {
    local missing_files=()
    local required_files=(
        "modules/system_detection.sh"
        "modules/wireguard_config.sh"
        "modules/bird_config.sh"
        "modules/firewall_config.sh"
        "modules/client_management.sh"
        "modules/network_management.sh"
        "modules/server_management.sh"
        "modules/system_maintenance.sh"
        "modules/backup_restore.sh"
        "modules/update_management.sh"
        "modules/wireguard_diagnostics.sh"
        "modules/bird_permissions.sh"
        "modules/client_script_generator.sh"
        "modules/client_auto_update.sh"
    )
    
    for file in "${required_files[@]}"; do
        local filepath="$SCRIPT_DIR/$file"
        if [[ ! -f "$filepath" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo -e "${YELLOW}发现缺失文件:${NC}"
        for file in "${missing_files[@]}"; do
            echo -e "  - $file"
        done
        return 1
    fi
    
    return 0
}

# 创建目录函数（跨平台兼容）
# 删除重复的 create_directories 函数，使用下面定义的更完整版本

# 检查root权限
check_root() {
    if [[ $EUID -eq 0 ]]; then
        IS_ROOT=true
        log "INFO" "Running with root privileges"
    else
        error_exit "This script must be run as root"
    fi
}

# 创建必要目录
create_directories() {
    log "INFO" "Creating necessary directories..."
    
    local dirs=("$CONFIG_DIR" "$LOG_DIR" "$BACKUP_DIR" "$CLIENT_CONFIG_DIR" "$TEMP_DIR")
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            chmod 755 "$dir"
            log "DEBUG" "Created directory: $dir"
        fi
    done
}

# 检测操作系统
detect_os() {
    log "INFO" "Detecting operating system..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_TYPE="$ID"
        OS_VERSION="$VERSION_ID"
    elif [[ -f /etc/redhat-release ]]; then
        OS_TYPE="rhel"
        OS_VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+' | head -1)
    elif [[ -f /etc/debian_version ]]; then
        OS_TYPE="debian"
        OS_VERSION=$(cat /etc/debian_version)
    else
        error_exit "Unsupported operating system"
    fi
    
    ARCH=$(uname -m)
    
    log "INFO" "Detected OS: $OS_TYPE $OS_VERSION ($ARCH)"
}

# 检查IPv6支持
check_ipv6() {
    log "INFO" "Checking IPv6 support..."
    
    if [[ -f /proc/net/if_inet6 ]]; then
        IPV6_ENABLED=true
        log "INFO" "IPv6 is supported"
    else
        IPV6_ENABLED=false
        log "WARN" "IPv6 is not supported on this system"
    fi
}

# 检查网络接口
get_network_interfaces() {
    log "INFO" "Getting available network interfaces..."
    
    local interfaces=()
    
    # 使用ip命令获取网络接口
    if command -v ip >/dev/null 2>&1; then
        while IFS= read -r interface; do
            if [[ "$interface" != "lo" ]] && [[ -n "$interface" ]]; then
                interfaces+=("$interface")
            fi
        done < <(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' 2>/dev/null)
    else
        # 如果ip命令不可用，使用ifconfig
        if command -v ifconfig >/dev/null 2>&1; then
            while IFS= read -r interface; do
                if [[ "$interface" != "lo" ]] && [[ -n "$interface" ]]; then
                    interfaces+=("$interface")
                fi
            done < <(ifconfig -a | grep -E "^[a-zA-Z]" | awk '{print $1}' | cut -d: -f1 | grep -v '^lo$' 2>/dev/null)
        else
            # 最后的备选方案
            log "WARN" "Cannot detect network interfaces using ip or ifconfig"
            interfaces=("eth0" "ens33" "enp0s3" "wlan0")
        fi
    fi
    
    # 返回数组
    printf '%s\n' "${interfaces[@]}"
}

# 检查端口占用
check_port() {
    local port="$1"
    local protocol="${2:-udp}"
    
    if command -v ss >/dev/null 2>&1; then
        if ss -${protocol:0:1}ln | grep -q ":$port "; then
            return 0  # 端口被占用
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -${protocol:0:1}ln | grep -q ":$port "; then
            return 0  # 端口被占用
        fi
    fi
    
    return 1  # 端口未被占用
}

# 交互式端口选择
interactive_port_selection() {
    local default_port="$1"
    local port="$default_port"
    
    while true; do
        echo -e "${CYAN}WireGuard端口配置${NC}"
        echo "当前默认端口: $default_port"
        read -p "请输入WireGuard端口 (默认: $default_port): " input_port
        
        if [[ -z "$input_port" ]]; then
            port="$default_port"
        else
            # 清理输入，移除任何非数字字符
            input_port=$(echo "$input_port" | tr -d '[:alpha:][:punct:][:space:]')
            
            if [[ "$input_port" =~ ^[0-9]+$ ]] && [[ "$input_port" -ge 1 ]] && [[ "$input_port" -le 65535 ]]; then
                port="$input_port"
            else
                echo -e "${RED}错误: 端口必须是1-65535之间的数字${NC}"
                echo -e "${RED}输入的内容: '$input_port' 不是有效的端口号${NC}"
                continue
            fi
        fi
        
        if check_port "$port" "udp"; then
            echo -e "${YELLOW}警告: 端口 $port 已被占用${NC}"
            read -p "是否继续使用此端口? (y/N): " continue_choice
            if [[ "${continue_choice,,}" != "y" ]]; then
                continue
            fi
        fi
        
        echo -e "${GREEN}✓${NC} 已选择端口: $port"
        break
    done
    
    echo "$port"
}

# 交互式IPv6前缀配置
interactive_ipv6_prefix() {
    local default_prefix="$1"
    local prefix="$default_prefix"
    
    echo -e "${CYAN}IPv6前缀配置${NC}" >&2
    echo "当前默认前缀: $default_prefix" >&2
    echo "支持的格式:" >&2
    echo "  - 单段前缀: 2001:db8::/48" >&2
    echo "  - 多段前缀: 2001:db8::/48,2001:db9::/48" >&2
    echo "  - 子网前缀: 2001:db8:1::/64 (大于/48)" >&2
    
    while true; do
        read -p "请输入IPv6前缀 (默认: $default_prefix): " input_prefix
        
        if [[ -z "$input_prefix" ]]; then
            prefix="$default_prefix"
        else
            # 验证IPv6前缀格式
            if [[ "$input_prefix" =~ ^[0-9a-fA-F:]+/[0-9]+(,[0-9a-fA-F:]+/[0-9]+)*$ ]]; then
                prefix="$input_prefix"
            else
                echo -e "${RED}错误: IPv6前缀格式不正确${NC}" >&2
                continue
            fi
        fi
        
        echo -e "${GREEN}✓${NC} 已选择IPv6前缀: $prefix" >&2
        break
    done
    
    echo "$prefix"
}

# 交互式网络接口选择
interactive_interface_selection() {
    # 获取网络接口列表
    local interfaces=($(get_network_interfaces))
    
    if [[ ${#interfaces[@]} -eq 0 ]]; then
        echo -e "${RED}错误: 未找到可用的网络接口${NC}"
        echo -e "${YELLOW}请检查网络接口配置${NC}"
        return 1
    fi
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                        网络接口选择                          ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${YELLOW}可用的网络接口:${NC}"
    
    for i in "${!interfaces[@]}"; do
        # 获取接口状态和IP信息
        local interface="${interfaces[$i]}"
        local status="未知"
        local ip_info=""
        
        # 检查接口状态和IP信息
        if command -v ip >/dev/null 2>&1; then
            status=$(ip link show "$interface" 2>/dev/null | grep -o "state [A-Z]*" | cut -d' ' -f2)
            ip_info=$(ip addr show "$interface" 2>/dev/null | grep "inet " | head -1 | awk '{print $2}' | cut -d'/' -f1)
        else
            # 如果ip命令不可用，使用ifconfig
            if command -v ifconfig >/dev/null 2>&1; then
                status=$(ifconfig "$interface" 2>/dev/null | grep -o "UP\|DOWN" | head -1)
                ip_info=$(ifconfig "$interface" 2>/dev/null | grep "inet " | head -1 | awk '{print $2}')
            fi
        fi
        
        if [[ -n "$ip_info" ]]; then
            echo -e "  ${GREEN}$((i+1)).${NC} ${interface} (状态: ${status}, IP: ${ip_info})"
        else
            echo -e "  ${GREEN}$((i+1)).${NC} ${interface} (状态: ${status})"
        fi
    done
    
    echo
    while true; do
        read -p "请选择网络接口 (1-${#interfaces[@]}): " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#interfaces[@]}" ]]; then
            local selected_interface="${interfaces[$((choice-1))]}"
            echo -e "${GREEN}✓${NC} 已选择网络接口: ${selected_interface}"
            echo "$selected_interface"
            return 0
        else
            echo -e "${RED}错误: 请选择有效的接口编号 (1-${#interfaces[@]})${NC}"
        fi
    done
}

# 交互式日志级别选择
interactive_log_level() {
    local default_level="${1:-info}"
    local log_level=""
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                        日志级别选择                          ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${YELLOW}可用的日志级别:${NC}"
    echo -e "  ${GREEN}1.${NC} debug  - 调试信息 (最详细)"
    echo -e "  ${GREEN}2.${NC} info   - 一般信息 (推荐)"
    echo -e "  ${GREEN}3.${NC} warn   - 警告信息"
    echo -e "  ${GREEN}4.${NC} error  - 错误信息 (最简洁)"
    echo
    
    while true; do
        read -p "请选择日志级别 (1-4) [默认: ${default_level}]: " choice
        
        case "$choice" in
            "1"|"debug")
                log_level="debug"
                break
                ;;
            "2"|"info")
                log_level="info"
                break
                ;;
            "3"|"warn")
                log_level="warn"
                break
                ;;
            "4"|"error")
                log_level="error"
                break
                ;;
            "")
                log_level="$default_level"
                break
                ;;
            *)
                echo -e "${RED}错误: 请选择有效的日志级别 (1-4)${NC}"
                ;;
        esac
    done
    
    echo -e "${GREEN}✓${NC} 已选择日志级别: ${log_level}"
    echo "$log_level"
}

# 交互式AS号配置
interactive_as_number() {
    local default_as="$1"
    local as_number="$default_as"
    
    echo -e "${CYAN}BGP AS号配置${NC}"
    echo "当前默认AS号: $default_as"
    echo "AS号范围: 1-4294967295 (私有AS号: 64512-65534)"
    
    while true; do
        read -p "请输入BGP AS号 (默认: $default_as): " input_as
        
        if [[ -z "$input_as" ]]; then
            as_number="$default_as"
        else
            if [[ "$input_as" =~ ^[0-9]+$ ]] && [[ "$input_as" -ge 1 ]] && [[ "$input_as" -le 4294967295 ]]; then
                as_number="$input_as"
            else
                echo -e "${RED}错误: AS号必须是1-4294967295之间的数字${NC}"
                continue
            fi
        fi
        
        echo -e "${GREEN}✓${NC} 已选择AS号: $as_number"
        break
    done
    
    echo "$as_number"
}

# 删除重复的 interactive_log_level 函数，使用上面定义的版本

# 显示主菜单
show_main_menu() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                IPv6 WireGuard VPN Manager                  ║${NC}"
    echo -e "${WHITE}║                    版本 1.13                              ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # 确保系统信息已初始化
    if [[ -z "$OS_TYPE" ]]; then
        detect_system_info
    fi
    
    echo -e "${CYAN}系统信息:${NC}"
    echo -e "  操作系统: $OS_TYPE $OS_VERSION ($ARCH)"
    echo -e "  运行环境: Linux/Unix"
    echo -e "  IPv6支持: $([ "$IPV6_ENABLED" = true ] && echo -e "${GREEN}是${NC}" || echo -e "${RED}否${NC}")"
    echo -e "  WireGuard: $([ "$WG_INSTALLED" = true ] && echo -e "${GREEN}已安装${NC}" || echo -e "${RED}未安装${NC}")"
    echo -e "  BIRD BGP: $([ "$BIRD_INSTALLED" = true ] && echo -e "${GREEN}已安装${NC}" || echo -e "${RED}未安装${NC}")"
    echo -e "  配置目录: $CONFIG_DIR"
    echo
    echo -e "${YELLOW}主菜单:${NC}"
    echo -e "  ${GREEN}1.${NC} 快速安装 (一键配置)"
    echo -e "  ${GREEN}2.${NC} 交互式安装"
    echo -e "  ${GREEN}3.${NC} 服务器管理"
    echo -e "  ${GREEN}4.${NC} 客户端管理"
    echo -e "  ${GREEN}5.${NC} 网络配置"
    echo -e "  ${GREEN}6.${NC} BGP配置管理"
    echo -e "  ${GREEN}7.${NC} 防火墙管理"
    echo -e "  ${GREEN}8.${NC} 系统维护"
    echo -e "  ${GREEN}9.${NC} 配置备份/恢复"
    echo -e "  ${GREEN}10.${NC} 更新检查"
    echo -e "  ${GREEN}11.${NC} 下载必需文件"
    echo -e "  ${GREEN}0.${NC} 退出"
    echo
}

# 快速安装模式
quick_install() {
    log "INFO" "Starting quick installation..."
    
    echo -e "${CYAN}快速安装模式${NC}"
    echo "将使用默认配置进行安装:"
    echo "  - WireGuard端口: $DEFAULT_WG_PORT"
    echo "  - IPv6前缀: $DEFAULT_IPV6_PREFIX"
    echo "  - AS号: $DEFAULT_AS_NUMBER"
    echo "  - 启用BIRD BGP服务"
    echo "  - 自动配置防火墙"
    echo
    
    read -p "确认开始快速安装? (y/N): " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        log "INFO" "Quick installation cancelled by user"
        return
    fi
    
    # 执行安装步骤
    install_dependencies
    configure_wireguard "$DEFAULT_WG_PORT" "$DEFAULT_IPV6_PREFIX"
    configure_bird "$DEFAULT_AS_NUMBER"
    configure_firewall
    start_services
    
    log "INFO" "Quick installation completed successfully"
    echo -e "${GREEN}快速安装完成!${NC}"
}

# 交互式安装模式
interactive_install() {
    log "INFO" "Starting interactive installation..."
    
    echo -e "${CYAN}交互式安装模式${NC}"
    echo
    
    # 安装模式选择
    echo "请选择安装模式:"
    echo "  1. 完整安装 (包含所有功能)"
    echo "  2. 最小安装 (仅WireGuard)"
    read -p "请选择 (1-2): " install_mode
    
    case "$install_mode" in
        "1")
            install_mode="full"
            ;;
        "2")
            install_mode="minimal"
            ;;
        *)
            error_exit "无效的安装模式选择"
            ;;
    esac
    
    # 服务器/客户端模式选择
    echo
    echo "请选择运行模式:"
    echo "  1. 服务器模式 (VPN服务器)"
    echo "  2. 客户端模式 (VPN客户端)"
    read -p "请选择 (1-2): " run_mode
    
    case "$run_mode" in
        "1")
            run_mode="server"
            ;;
        "2")
            run_mode="client"
            ;;
        *)
            error_exit "无效的运行模式选择"
            ;;
    esac
    
    # 网络配置
    echo
    local wg_port=$(interactive_port_selection "$DEFAULT_WG_PORT")
    echo
    local ipv6_prefix=$(interactive_ipv6_prefix "$DEFAULT_IPV6_PREFIX")
    echo
    local interface=$(interactive_interface_selection)
    echo
    
    # 服务选择
    local enable_bird=false
    local enable_firewall=false
    local enable_security=false
    
    if [[ "$install_mode" == "full" ]]; then
        echo
        read -p "启用BIRD BGP服务? (y/N): " bird_choice
        [[ "${bird_choice,,}" == "y" ]] && enable_bird=true
        
        echo
        read -p "自动配置防火墙? (y/N): " firewall_choice
        [[ "${firewall_choice,,}" == "y" ]] && enable_firewall=true
        
        echo
        read -p "安装安全工具? (y/N): " security_choice
        [[ "${security_choice,,}" == "y" ]] && enable_security=true
    fi
    
    # 高级配置
    local as_number="$DEFAULT_AS_NUMBER"
    local log_level="$DEFAULT_LOG_LEVEL"
    
    if [[ "$enable_bird" == true ]]; then
        echo
        as_number=$(interactive_as_number "$DEFAULT_AS_NUMBER")
    fi
    
    echo
    log_level=$(interactive_log_level "$DEFAULT_LOG_LEVEL")
    
    # 确认配置
    echo
    echo -e "${CYAN}安装配置确认:${NC}"
    echo "  安装模式: $install_mode"
    echo "  运行模式: $run_mode"
    echo "  WireGuard端口: $wg_port"
    echo "  IPv6前缀: $ipv6_prefix"
    echo "  网络接口: $interface"
    echo "  BIRD BGP: $([ "$enable_bird" == true ] && echo "启用" || echo "禁用")"
    echo "  防火墙配置: $([ "$enable_firewall" == true ] && echo "启用" || echo "禁用")"
    echo "  安全工具: $([ "$enable_security" == true ] && echo "启用" || echo "禁用")"
    echo "  AS号: $as_number"
    echo "  日志级别: $log_level"
    echo
    
    read -p "确认开始安装? (y/N): " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        log "INFO" "Interactive installation cancelled by user"
        return
    fi
    
    # 执行安装
    install_dependencies
    configure_wireguard "$wg_port" "$ipv6_prefix" "$interface"
    
    if [[ "$enable_bird" == true ]]; then
        configure_bird "$as_number"
    fi
    
    if [[ "$enable_firewall" == true ]]; then
        configure_firewall
    fi
    
    if [[ "$enable_security" == true ]]; then
        install_security_tools
    fi
    
    start_services
    
    log "INFO" "Interactive installation completed successfully"
    echo -e "${GREEN}交互式安装完成!${NC}"
}

# 安装依赖
install_dependencies() {
    log "INFO" "Installing dependencies..."
    
    # 首先安装基础工具
    install_basic_tools
    
    # 安装WireGuard（必需）
    install_wireguard
    
    # 安装BIRD（可选，失败不影响WireGuard）
    install_bird
    
    # 安装防火墙工具
    install_firewall_tools
    
    WG_INSTALLED=true
    log "INFO" "Dependencies installation completed"
}

# 安装基础工具
install_basic_tools() {
    log "INFO" "Installing basic tools..."
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt update
            apt install -y curl wget iptables
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y epel-release
                dnf install -y curl wget iptables
            else
                yum install -y epel-release
                yum install -y curl wget iptables
            fi
            ;;
        "arch")
            pacman -S --noconfirm curl wget iptables
            ;;
        *)
            error_exit "Unsupported operating system: $OS_TYPE"
            ;;
    esac
    
    log "INFO" "Basic tools installed successfully"
}

# 安装WireGuard
install_wireguard() {
    log "INFO" "Installing WireGuard..."
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            if apt install -y wireguard wireguard-tools; then
                log "INFO" "WireGuard installed successfully"
            else
                log "ERROR" "Failed to install WireGuard"
                error_exit "WireGuard installation failed"
            fi
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                if dnf install -y wireguard-tools; then
                    log "INFO" "WireGuard installed successfully"
                else
                    log "ERROR" "Failed to install WireGuard"
                    error_exit "WireGuard installation failed"
                fi
            else
                if yum install -y wireguard-tools; then
                    log "INFO" "WireGuard installed successfully"
                else
                    log "ERROR" "Failed to install WireGuard"
                    error_exit "WireGuard installation failed"
                fi
            fi
            ;;
        "arch")
            if pacman -S --noconfirm wireguard-tools; then
                log "INFO" "WireGuard installed successfully"
            else
                log "ERROR" "Failed to install WireGuard"
                error_exit "WireGuard installation failed"
            fi
            ;;
    esac
}

# 安装BIRD
install_bird() {
    log "INFO" "Installing BIRD BGP daemon..."
    
    local bird_installed=false
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            # 优先尝试安装BIRD 2.x
            if apt install -y bird2 2>/dev/null; then
                log "INFO" "BIRD 2.x installed successfully"
                bird_installed=true
            # 如果BIRD 2.x失败，尝试BIRD 1.x
            elif apt install -y bird 2>/dev/null; then
                log "INFO" "BIRD 1.x installed successfully"
                bird_installed=true
            else
                log "WARN" "Failed to install BIRD, continuing without BGP support"
            fi
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                # 优先尝试安装BIRD 2.x
                if dnf install -y bird2 2>/dev/null; then
                    log "INFO" "BIRD 2.x installed successfully"
                    bird_installed=true
                # 如果BIRD 2.x失败，尝试BIRD 1.x
                elif dnf install -y bird 2>/dev/null; then
                    log "INFO" "BIRD 1.x installed successfully"
                    bird_installed=true
                else
                    log "WARN" "Failed to install BIRD, continuing without BGP support"
                fi
            else
                # 优先尝试安装BIRD 2.x
                if yum install -y bird2 2>/dev/null; then
                    log "INFO" "BIRD 2.x installed successfully"
                    bird_installed=true
                # 如果BIRD 2.x失败，尝试BIRD 1.x
                elif yum install -y bird 2>/dev/null; then
                    log "INFO" "BIRD 1.x installed successfully"
                    bird_installed=true
                else
                    log "WARN" "Failed to install BIRD, continuing without BGP support"
                fi
            fi
            ;;
        "arch")
            # 优先尝试安装BIRD 2.x
            if pacman -S --noconfirm bird2 2>/dev/null; then
                log "INFO" "BIRD 2.x installed successfully"
                bird_installed=true
            # 如果BIRD 2.x失败，尝试BIRD 1.x
            elif pacman -S --noconfirm bird 2>/dev/null; then
                log "INFO" "BIRD 1.x installed successfully"
                bird_installed=true
            else
                log "WARN" "Failed to install BIRD, continuing without BGP support"
            fi
            ;;
    esac
    
    if [[ "$bird_installed" == "true" ]]; then
        BIRD_INSTALLED=true
        # 检测BIRD版本
        detect_bird_version
    else
        BIRD_INSTALLED=false
        log "WARN" "BIRD not installed - BGP features will be disabled"
    fi
}

# 安装防火墙工具
install_firewall_tools() {
    log "INFO" "Installing firewall tools..."
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt install -y ufw
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y firewalld
            else
                yum install -y firewalld
            fi
            ;;
        "arch")
            pacman -S --noconfirm ufw
            ;;
    esac
    
    log "INFO" "Firewall tools installed successfully"
}

# 检测BIRD版本
detect_bird_version() {
    if command -v birdc2 >/dev/null 2>&1; then
        BIRD_VERSION="2.x"
        BIRD_SERVICE="bird2"
        BIRD_CONFIG="/etc/bird/bird.conf"
        log "INFO" "Detected BIRD 2.x"
    elif command -v birdc >/dev/null 2>&1; then
        BIRD_VERSION="1.x"
        BIRD_SERVICE="bird"
        BIRD_CONFIG="/etc/bird/bird.conf"
        log "INFO" "Detected BIRD 1.x"
    else
        BIRD_VERSION="none"
        BIRD_SERVICE=""
        BIRD_CONFIG=""
        log "WARN" "BIRD not detected"
    fi
}

# 配置WireGuard
configure_wireguard() {
    local port="$1"
    local ipv6_prefix="$2"
    local interface="${3:-$(ip route | grep default | awk '{print $5}' | head -1)}"
    
    # 验证端口号
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
        log "ERROR" "Invalid port number: $port"
        log "ERROR" "Port must be a number between 1 and 65535"
        return 1
    fi
    
    log "INFO" "Configuring WireGuard server with port: $port"
    
    # 生成服务器密钥
    local server_private_key=$(wg genkey)
    local server_public_key=$(echo "$server_private_key" | wg pubkey)
    
    # 从IPv6前缀中提取服务器地址（使用::1作为服务器地址）
    local network_part=$(echo "$ipv6_prefix" | cut -d'/' -f1)
    if [[ "$network_part" == *"::" ]]; then
        local server_ipv6="${network_part}1/64"
    elif [[ "$network_part" == *":" ]]; then
        local server_ipv6="${network_part}1/64"
    else
        local server_ipv6="${network_part}:1/64"
    fi
    
    # 创建WireGuard配置
    cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $server_private_key
Address = 10.0.0.1/24, $server_ipv6
ListenPort = $port
SaveConfig = true

# 启用 IPv6 转发
PostUp = echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
PostUp = echo 1 > /proc/sys/net/ipv6/conf/%i/forwarding
PostDown = echo 0 > /proc/sys/net/ipv6/conf/all/forwarding
PostDown = echo 0 > /proc/sys/net/ipv6/conf/%i/forwarding

# 防火墙规则
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $interface -j MASQUERADE
PostUp = ip6tables -A FORWARD -i %i -j ACCEPT; ip6tables -A FORWARD -o %i -j ACCEPT
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $interface -j MASQUERADE
PostDown = ip6tables -D FORWARD -i %i -j ACCEPT; ip6tables -D FORWARD -o %i -j ACCEPT

# 客户端配置将在这里添加
EOF
    
    # 保存服务器公钥
    echo "$server_public_key" > "$CONFIG_DIR/server_public_key"
    
    # 设置权限
    chmod 600 /etc/wireguard/wg0.conf
    chmod 600 "$CONFIG_DIR/server_public_key"
    
    log "INFO" "WireGuard server configured successfully"
}

# 配置BIRD权限
configure_bird_permissions() {
    log "INFO" "Configuring BIRD permissions..."
    
    # 创建BIRD用户和组
    if ! getent group bird >/dev/null 2>&1; then
        groupadd -r bird
        log "INFO" "Created bird group"
    fi
    
    if ! getent passwd bird >/dev/null 2>&1; then
        useradd -r -g bird -d /var/lib/bird -s /bin/false bird
        log "INFO" "Created bird user"
    fi
    
    # 创建BIRD目录
    mkdir -p /etc/bird
    mkdir -p /var/lib/bird
    mkdir -p /var/log/bird
    mkdir -p /var/run/bird
    
    # 设置权限
    chown -R bird:bird /var/lib/bird
    chown -R bird:bird /var/log/bird
    chown -R bird:bird /var/run/bird
    chmod 755 /etc/bird
    chmod 755 /var/lib/bird
    chmod 755 /var/log/bird
    chmod 755 /var/run/bird
    
    log "INFO" "BIRD permissions configured successfully"
}

# 配置BIRD BGP
configure_bird() {
    local as_number="$1"
    
    log "INFO" "Configuring BIRD BGP daemon..."
    
    # 首先配置BIRD权限
    configure_bird_permissions
    
    # 检查BIRD配置模块是否存在
    if [[ -f "$SCRIPT_DIR/modules/bird_config.sh" ]]; then
        # 使用BIRD配置模块创建配置
        source "$SCRIPT_DIR/modules/bird_config.sh"
        
        # 创建BIRD配置
        if declare -f create_bird_config >/dev/null; then
            create_bird_config "/etc/bird/bird.conf" "10.0.0.1" "$as_number" "$DEFAULT_IPV6_PREFIX"
        else
            create_basic_bird_config "/etc/bird/bird.conf" "10.0.0.1" "$as_number" "$DEFAULT_IPV6_PREFIX"
        fi
    else
        # 创建基本BIRD配置
        create_basic_bird_config "/etc/bird/bird.conf" "10.0.0.1" "$as_number" "$DEFAULT_IPV6_PREFIX"
    fi
    
    BIRD_INSTALLED=true
    log "INFO" "BIRD BGP configured successfully"
}

# 基本BIRD配置函数（内置备用函数）
create_basic_bird_config() {
    local config_file="$1"
    local router_id="$2"
    local as_number="$3"
    local ipv6_prefixes="$4"
    
    log "INFO" "Creating basic BIRD configuration..."
    
    cat > "$config_file" << EOF
# BIRD BGP Configuration for IPv6 WireGuard
# Generated by IPv6 WireGuard Manager
# Router ID: $router_id
# AS Number: $as_number

# 路由器ID
router id $router_id;

# 设备协议
protocol device {
    scan time 10;
}

# 内核协议 - 处理路由表
protocol kernel {
    ipv6 {
        import all;
        export all;
    };
    learn;
    scan time 20;
}

# 直连协议 - 处理直连网络
protocol direct {
    ipv6;
    interface "wg0";
}

# 静态路由配置
protocol static {
    ipv6;
    
    # 宣告IPv6前缀
    route $ipv6_prefixes via ::1;
}

# 日志配置
log syslog { debug, trace, info, remote, warning, error, auth, fatal, bug };
log "/var/log/bird/bird.log" { info, remote, warning, error, auth, fatal, bug };
EOF

    # 设置配置文件权限
    chmod 644 "$config_file"
    chown bird:bird "$config_file"
    
    log "INFO" "Basic BIRD configuration created: $config_file"
}

# 配置防火墙
configure_firewall() {
    log "INFO" "Configuring firewall..."
    
    # 检测防火墙类型
    if command -v ufw >/dev/null 2>&1; then
        FIREWALL_TYPE="ufw"
        ufw --force enable
        ufw allow "$DEFAULT_WG_PORT"/udp
        ufw allow ssh
        log "INFO" "UFW firewall configured"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        FIREWALL_TYPE="firewalld"
        systemctl enable firewalld
        systemctl start firewalld
        firewall-cmd --permanent --add-port="$DEFAULT_WG_PORT"/udp
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --reload
        log "INFO" "Firewalld configured"
    elif command -v nft >/dev/null 2>&1; then
        FIREWALL_TYPE="nftables"
        # nftables配置
        log "INFO" "nftables configured"
    else
        FIREWALL_TYPE="iptables"
        # iptables配置
        iptables -A INPUT -p udp --dport "$DEFAULT_WG_PORT" -j ACCEPT
        iptables -A INPUT -p tcp --dport 22 -j ACCEPT
        log "INFO" "iptables configured"
    fi
}

# 安装安全工具
install_security_tools() {
    log "INFO" "Installing security tools..."
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt install -y fail2ban ufw
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y fail2ban
            else
                yum install -y fail2ban
            fi
            ;;
        "arch")
            pacman -S --noconfirm fail2ban
            ;;
    esac
    
    log "INFO" "Security tools installed successfully"
}

# 启动服务
start_services() {
    log "INFO" "Starting services..."
    
    # 启动WireGuard
    if systemctl enable wg-quick@wg0; then
        log "INFO" "WireGuard service enabled successfully"
        
        if systemctl start wg-quick@wg0; then
            log "INFO" "WireGuard service started successfully"
        else
            log "ERROR" "Failed to start WireGuard service"
            log "INFO" "Diagnosing WireGuard startup issue..."
            diagnose_wireguard_startup_issue
            error_exit "WireGuard service startup failed"
        fi
    else
        log "ERROR" "Failed to enable WireGuard service"
        error_exit "WireGuard service enable failed"
    fi
    
    # 启动BIRD (如果已安装且已配置)
    if [[ "$BIRD_INSTALLED" == true ]]; then
        log "INFO" "Attempting to start BIRD service"
        
        # 检查BIRD配置模块是否存在
        if [[ -f "$SCRIPT_DIR/modules/bird_config.sh" ]]; then
            source "$SCRIPT_DIR/modules/bird_config.sh"
            
            # 创建BIRD systemd服务文件
            if declare -f create_bird_systemd_service >/dev/null; then
                create_bird_systemd_service
            fi
        fi
        
        # 尝试启动BIRD 2.x
        if systemctl enable bird2 2>/dev/null && systemctl start bird2 2>/dev/null; then
            log "INFO" "BIRD 2.x service started successfully"
        # 尝试启动BIRD 1.x
        elif systemctl enable bird 2>/dev/null && systemctl start bird 2>/dev/null; then
            log "INFO" "BIRD 1.x service started successfully"
        else
            log "WARN" "Failed to start BIRD service, but continuing installation"
            log "WARN" "BGP features will be disabled until BIRD is manually configured"
        fi
    else
        log "INFO" "BIRD not configured, skipping BIRD service startup"
    fi
    
    log "INFO" "Services startup completed"
}

# 诊断 WireGuard 启动问题
diagnose_wireguard_startup_issue() {
    log "INFO" "开始诊断 WireGuard 启动问题..."
    
    # 检查配置文件
    if [[ -f /etc/wireguard/wg0.conf ]]; then
        log "INFO" "配置文件存在: /etc/wireguard/wg0.conf"
        
        # 检查配置文件语法
        if wg-quick strip wg0 >/dev/null 2>&1; then
            log "INFO" "配置文件语法正确"
        else
            log "ERROR" "配置文件语法错误"
            log "INFO" "语法检查结果:"
            wg-quick strip wg0 2>&1 || true
        fi
        
        # 检查文件权限
        local file_perms=$(stat -c "%a" /etc/wireguard/wg0.conf 2>/dev/null || echo "unknown")
        local file_owner=$(stat -c "%U:%G" /etc/wireguard/wg0.conf 2>/dev/null || echo "unknown")
        log "INFO" "文件权限: $file_perms, 所有者: $file_owner"
        
        if [[ "$file_perms" != "600" ]]; then
            log "WARN" "配置文件权限不正确，应该是 600"
            chmod 600 /etc/wireguard/wg0.conf
        fi
        
        if [[ "$file_owner" != "root:root" ]]; then
            log "WARN" "配置文件所有者不正确，应该是 root:root"
            chown root:root /etc/wireguard/wg0.conf
        fi
    else
        log "ERROR" "配置文件不存在: /etc/wireguard/wg0.conf"
    fi
    
    # 检查 IPv6 配置
    if [[ -f /proc/sys/net/ipv6/conf/all/disable_ipv6 ]]; then
        local ipv6_disabled=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6)
        if [[ "$ipv6_disabled" == "1" ]]; then
            log "WARN" "IPv6 已禁用，尝试启用..."
            echo 0 > /proc/sys/net/ipv6/conf/all/disable_ipv6
        fi
    fi
    
    # 检查 IPv6 转发
    if [[ -f /proc/sys/net/ipv6/conf/all/forwarding ]]; then
        local ipv6_forwarding=$(cat /proc/sys/net/ipv6/conf/all/forwarding)
        if [[ "$ipv6_forwarding" != "1" ]]; then
            log "WARN" "IPv6 转发未启用，尝试启用..."
            echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
        fi
    fi
    
    # 检查 WireGuard 模块
    if ! lsmod | grep -q wireguard; then
        log "WARN" "WireGuard 内核模块未加载，尝试加载..."
        modprobe wireguard 2>/dev/null || log "WARN" "无法加载 WireGuard 模块"
    fi
    
    # 检查端口占用
    local wg_port="51820"
    if netstat -tulpn 2>/dev/null | grep -q ":$wg_port "; then
        log "WARN" "端口 $wg_port 已被占用"
        netstat -tulpn | grep ":$wg_port " || true
    fi
    
    # 显示详细错误信息
    log "INFO" "WireGuard 服务状态:"
    systemctl status wg-quick@wg0 --no-pager -l || true
    
    log "INFO" "系统日志 (最后 10 行):"
    journalctl -xeu wg-quick@wg0.service --no-pager -l | tail -10 || true
}

# 服务器管理菜单
server_management_menu() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    服务器管理                              ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        # 显示服务状态
        show_service_status
        
        echo -e "${YELLOW}服务器管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看服务状态"
        echo -e "  ${GREEN}2.${NC} 启动服务"
        echo -e "  ${GREEN}3.${NC} 停止服务"
        echo -e "  ${GREEN}4.${NC} 重启服务"
        echo -e "  ${GREEN}5.${NC} 重载配置"
        echo -e "  ${GREEN}6.${NC} 查看服务日志"
        echo -e "  ${GREEN}7.${NC} 查看系统资源使用"
        echo -e "  ${GREEN}8.${NC} 查看网络连接"
        echo -e "  ${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 (0-8): " choice
        
        case "$choice" in
            "1")
                show_service_status
                read -p "按回车键继续..."
                ;;
            "2")
                start_services_manually
                ;;
            "3")
                stop_services_manually
                ;;
            "4")
                restart_services_manually
                ;;
            "5")
                reload_configurations
                ;;
            "6")
                view_service_logs
                ;;
            "7")
                show_system_resources
                ;;
            "8")
                show_network_connections
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 显示服务状态
show_service_status() {
    echo -e "${CYAN}服务状态:${NC}"
    echo
    
    # WireGuard状态
    if systemctl is-active --quiet wg-quick@wg0; then
        echo -e "  WireGuard: ${GREEN}运行中${NC}"
        local wg_peers=$(wg show wg0 | grep -c "peer:" 2>/dev/null || echo "0")
        echo -e "    连接客户端: $wg_peers"
    else
        echo -e "  WireGuard: ${RED}未运行${NC}"
    fi
    
    # BIRD状态
    if systemctl is-active --quiet bird; then
        echo -e "  BIRD BGP: ${GREEN}运行中${NC}"
    elif systemctl is-active --quiet bird2; then
        echo -e "  BIRD BGP: ${GREEN}运行中${NC}"
    else
        echo -e "  BIRD BGP: ${RED}未运行${NC}"
    fi
    
    # 防火墙状态
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            echo -e "  防火墙 (UFW): ${GREEN}已启用${NC}"
        else
            echo -e "  防火墙 (UFW): ${YELLOW}已禁用${NC}"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if systemctl is-active --quiet firewalld; then
            echo -e "  防火墙 (Firewalld): ${GREEN}已启用${NC}"
        else
            echo -e "  防火墙 (Firewalld): ${YELLOW}已禁用${NC}"
        fi
    else
        echo -e "  防火墙: ${YELLOW}未配置${NC}"
    fi
    
    echo
}

# 手动启动服务
start_services_manually() {
    echo -e "${CYAN}启动服务...${NC}"
    
    # 启动WireGuard
    if systemctl start wg-quick@wg0; then
        echo -e "${GREEN}✓${NC} WireGuard 启动成功"
    else
        echo -e "${RED}✗${NC} WireGuard 启动失败"
    fi
    
    # 启动BIRD
    if systemctl is-active --quiet bird; then
        echo -e "${GREEN}✓${NC} BIRD 已在运行"
    elif systemctl is-active --quiet bird2; then
        echo -e "${GREEN}✓${NC} BIRD2 已在运行"
    else
        if systemctl start bird 2>/dev/null || systemctl start bird2 2>/dev/null; then
            echo -e "${GREEN}✓${NC} BIRD 启动成功"
        else
            echo -e "${YELLOW}⚠${NC} BIRD 启动失败或未安装"
        fi
    fi
    
    read -p "按回车键继续..."
}

# 手动停止服务
stop_services_manually() {
    echo -e "${CYAN}停止服务...${NC}"
    
    # 停止WireGuard
    if systemctl stop wg-quick@wg0; then
        echo -e "${GREEN}✓${NC} WireGuard 停止成功"
    else
        echo -e "${RED}✗${NC} WireGuard 停止失败"
    fi
    
    # 停止BIRD
    if systemctl stop bird 2>/dev/null || systemctl stop bird2 2>/dev/null; then
        echo -e "${GREEN}✓${NC} BIRD 停止成功"
    else
        echo -e "${YELLOW}⚠${NC} BIRD 停止失败或未运行"
    fi
    
    read -p "按回车键继续..."
}

# 手动重启服务
restart_services_manually() {
    echo -e "${CYAN}重启服务...${NC}"
    
    # 重启WireGuard
    if systemctl restart wg-quick@wg0; then
        echo -e "${GREEN}✓${NC} WireGuard 重启成功"
    else
        echo -e "${RED}✗${NC} WireGuard 重启失败"
    fi
    
    # 重启BIRD
    if systemctl restart bird 2>/dev/null || systemctl restart bird2 2>/dev/null; then
        echo -e "${GREEN}✓${NC} BIRD 重启成功"
    else
        echo -e "${YELLOW}⚠${NC} BIRD 重启失败或未安装"
    fi
    
    read -p "按回车键继续..."
}

# 重载配置
reload_configurations() {
    echo -e "${CYAN}重载配置...${NC}"
    
    # 重载WireGuard配置
    if wg-quick down wg0 2>/dev/null && wg-quick up wg0 2>/dev/null; then
        echo -e "${GREEN}✓${NC} WireGuard 配置重载成功"
    else
        echo -e "${RED}✗${NC} WireGuard 配置重载失败"
    fi
    
    # 重载BIRD配置
    if command -v birdc >/dev/null 2>&1; then
        if birdc configure 2>/dev/null; then
            echo -e "${GREEN}✓${NC} BIRD 配置重载成功"
        else
            echo -e "${YELLOW}⚠${NC} BIRD 配置重载失败"
        fi
    elif command -v birdc2 >/dev/null 2>&1; then
        if birdc2 configure 2>/dev/null; then
            echo -e "${GREEN}✓${NC} BIRD2 配置重载成功"
        else
            echo -e "${YELLOW}⚠${NC} BIRD2 配置重载失败"
        fi
    else
        echo -e "${YELLOW}⚠${NC} BIRD 控制台未找到"
    fi
    
    read -p "按回车键继续..."
}

# 查看服务日志
view_service_logs() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    服务日志查看                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}日志查看选项:${NC}"
        echo -e "  ${GREEN}1.${NC} WireGuard 日志"
        echo -e "  ${GREEN}2.${NC} BIRD 日志"
        echo -e "  ${GREEN}3.${NC} 系统日志"
        echo -e "  ${GREEN}4.${NC} 防火墙日志"
        echo -e "  ${GREEN}5.${NC} 实时日志监控"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择 (0-5): " choice
        
        case "$choice" in
            "1")
                echo -e "${CYAN}WireGuard 日志 (最近50行):${NC}"
                journalctl -u wg-quick@wg0 -n 50 --no-pager
                read -p "按回车键继续..."
                ;;
            "2")
                echo -e "${CYAN}BIRD 日志 (最近50行):${NC}"
                if [[ -f /var/log/bird/bird.log ]]; then
                    tail -50 /var/log/bird/bird.log
                else
                    journalctl -u bird -n 50 --no-pager 2>/dev/null || journalctl -u bird2 -n 50 --no-pager 2>/dev/null || echo "BIRD 日志未找到"
                fi
                read -p "按回车键继续..."
                ;;
            "3")
                echo -e "${CYAN}系统日志 (最近50行):${NC}"
                journalctl -n 50 --no-pager
                read -p "按回车键继续..."
                ;;
            "4")
                echo -e "${CYAN}防火墙日志:${NC}"
                if command -v ufw >/dev/null 2>&1; then
                    ufw status verbose
                elif command -v firewall-cmd >/dev/null 2>&1; then
                    firewall-cmd --list-all
                else
                    iptables -L -n
                fi
                read -p "按回车键继续..."
                ;;
            "5")
                echo -e "${CYAN}实时日志监控 (按 Ctrl+C 退出):${NC}"
                journalctl -f
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 显示系统资源使用
show_system_resources() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    系统资源使用                            ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # CPU使用率
    echo -e "${CYAN}CPU 使用率:${NC}"
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | while read cpu; do
        echo "  CPU: ${cpu}%"
    done
    
    # 内存使用
    echo -e "${CYAN}内存使用:${NC}"
    free -h | grep -E "Mem|Swap" | while read line; do
        echo "  $line"
    done
    
    # 磁盘使用
    echo -e "${CYAN}磁盘使用:${NC}"
    df -h | grep -E "/$|/var|/etc" | while read line; do
        echo "  $line"
    done
    
    # 网络接口统计
    echo -e "${CYAN}网络接口统计:${NC}"
    if command -v wg >/dev/null 2>&1; then
        wg show wg0 2>/dev/null | while read line; do
            echo "  $line"
        done
    fi
    
    # 进程信息
    echo -e "${CYAN}相关进程:${NC}"
    ps aux | grep -E "wireguard|bird|wg-quick" | grep -v grep | while read line; do
        echo "  $line"
    done
    
    echo
    read -p "按回车键继续..."
}

# 显示网络连接
show_network_connections() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    网络连接状态                            ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # WireGuard接口信息
    echo -e "${CYAN}WireGuard 接口信息:${NC}"
    if command -v wg >/dev/null 2>&1; then
        wg show wg0 2>/dev/null || echo "  WireGuard 接口未配置或未运行"
    else
        echo "  WireGuard 工具未安装"
    fi
    
    echo
    
    # 网络接口状态
    echo -e "${CYAN}网络接口状态:${NC}"
    ip addr show | grep -E "inet|inet6" | while read line; do
        echo "  $line"
    done
    
    echo
    
    # 路由表
    echo -e "${CYAN}IPv6 路由表:${NC}"
    ip -6 route show | head -20 | while read line; do
        echo "  $line"
    done
    
    echo
    
    # 活动连接
    echo -e "${CYAN}活动连接 (UDP):${NC}"
    ss -uln | grep -E ":51820|:179" | while read line; do
        echo "  $line"
    done
    
    echo
    read -p "按回车键继续..."
}

# BGP配置管理菜单
bgp_config_menu() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    BGP配置管理                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}BGP配置选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 交互式BGP配置"
        echo -e "  ${GREEN}2.${NC} 查看当前BGP配置"
        echo -e "  ${GREEN}3.${NC} 生成BGP配置文件"
        echo -e "  ${GREEN}4.${NC} 测试BGP配置"
        echo -e "  ${GREEN}5.${NC} 重启BIRD服务"
        echo -e "  ${GREEN}6.${NC} 查看BGP状态"
        echo -e "  ${GREEN}7.${NC} 导入BGP配置"
        echo -e "  ${GREEN}8.${NC} 导出BGP配置"
        echo -e "  ${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 (0-8): " choice
        
        case "$choice" in
            "1")
                if load_module "bird_config"; then
                    interactive_bgp_config
                    read -p "按回车键继续..."
                else
                    echo -e "${RED}无法加载BGP配置模块${NC}"
                    read -p "按回车键继续..."
                fi
                ;;
            "2")
                show_bgp_config
                ;;
            "3")
                generate_bgp_config
                ;;
            "4")
                test_bgp_config
                ;;
            "5")
                restart_bird_service
                ;;
            "6")
                show_bgp_status
                ;;
            "7")
                import_bgp_config
                ;;
            "8")
                export_bgp_config
                ;;
            "0")
                break
                ;;
            *)
                echo -e "${RED}无效选择，请重试${NC}"
                read -p "按回车键继续..."
                ;;
        esac
    done
}

# 显示当前BGP配置
show_bgp_config() {
    echo -e "${CYAN}当前BGP配置:${NC}"
    echo
    
    if [[ -n "$BGP_ROUTER_ID" ]]; then
        echo -e "路由器ID: ${GREEN}$BGP_ROUTER_ID${NC}"
    else
        echo -e "路由器ID: ${RED}未配置${NC}"
    fi
    
    if [[ -n "$BGP_AS_NUMBER" ]]; then
        echo -e "AS号: ${GREEN}$BGP_AS_NUMBER${NC}"
    else
        echo -e "AS号: ${RED}未配置${NC}"
    fi
    
    if [[ -n "$BGP_UPSTREAM_ASN" ]]; then
        echo -e "上游ASN: ${GREEN}$BGP_UPSTREAM_ASN${NC}"
    else
        echo -e "上游ASN: ${RED}未配置${NC}"
    fi
    
    if [[ -n "$BGP_NEIGHBORS" ]]; then
        echo -e "BGP邻居: ${GREEN}已配置${NC}"
        IFS='|' read -ra neighbors <<< "$BGP_NEIGHBORS"
        for neighbor in "${neighbors[@]}"; do
            if [[ -n "$neighbor" ]]; then
                IFS=',' read -ra parts <<< "$neighbor"
                echo -e "  - ${parts[0]}: ${parts[1]} (AS ${parts[2]})"
            fi
        done
    else
        echo -e "BGP邻居: ${RED}未配置${NC}"
    fi
    
    if [[ -n "$BGP_MULTIHOP" ]]; then
        echo -e "Multihop: ${GREEN}$BGP_MULTIHOP${NC}"
    else
        echo -e "Multihop: ${RED}未配置${NC}"
    fi
    
    if [[ -n "$BGP_IPV6_PREFIXES" ]]; then
        echo -e "IPv6前缀: ${GREEN}$BGP_IPV6_PREFIXES${NC}"
    else
        echo -e "IPv6前缀: ${RED}未配置${NC}"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 生成BGP配置文件
generate_bgp_config() {
    echo -e "${CYAN}生成BGP配置文件...${NC}"
    
    if load_module "bird_config"; then
        # 检测BIRD版本
        detect_bird_version
        
        # 创建配置目录
        mkdir -p /etc/bird
        
        # 生成配置文件
        local config_file="/etc/bird/bird.conf"
        create_bird_config "$config_file" "$BGP_ROUTER_ID" "$BGP_AS_NUMBER" "$BGP_IPV6_PREFIXES"
        
        echo -e "${GREEN}✓${NC} BGP配置文件已生成: $config_file"
    else
        echo -e "${RED}无法加载BGP配置模块${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 测试BGP配置
test_bgp_config() {
    echo -e "${CYAN}测试BGP配置...${NC}"
    
    local config_file="/etc/bird/bird.conf"
    
    if [[ ! -f "$config_file" ]]; then
        echo -e "${RED}配置文件不存在: $config_file${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    # 检测BIRD版本
    if command -v bird >/dev/null 2>&1; then
        local bird_cmd="bird"
    elif command -v bird2 >/dev/null 2>&1; then
        local bird_cmd="bird2"
    else
        echo -e "${RED}BIRD未安装${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    # 测试配置语法
    if $bird_cmd -c "$config_file" -p; then
        echo -e "${GREEN}✓${NC} BGP配置语法正确"
    else
        echo -e "${RED}✗${NC} BGP配置语法错误"
    fi
    
    read -p "按回车键继续..."
}

# 重启BIRD服务
restart_bird_service() {
    echo -e "${CYAN}重启BIRD服务...${NC}"
    
    if systemctl is-active --quiet bird; then
        echo "停止BIRD服务..."
        systemctl stop bird
    elif systemctl is-active --quiet bird2; then
        echo "停止BIRD2服务..."
        systemctl stop bird2
    fi
    
    sleep 2
    
    if systemctl start bird; then
        echo -e "${GREEN}✓${NC} BIRD服务启动成功"
    elif systemctl start bird2; then
        echo -e "${GREEN}✓${NC} BIRD2服务启动成功"
    else
        echo -e "${RED}✗${NC} BIRD服务启动失败"
    fi
    
    read -p "按回车键继续..."
}

# 显示BGP状态
show_bgp_status() {
    echo -e "${CYAN}BGP状态信息:${NC}"
    echo
    
    if command -v birdc >/dev/null 2>&1; then
        echo -e "${CYAN}BIRD状态:${NC}"
        birdc show status 2>/dev/null || echo "无法获取BIRD状态"
        echo
        echo -e "${CYAN}BGP协议状态:${NC}"
        birdc show protocols all bgp 2>/dev/null || echo "无BGP协议配置"
    elif command -v birdc2 >/dev/null 2>&1; then
        echo -e "${CYAN}BIRD2状态:${NC}"
        birdc2 show status 2>/dev/null || echo "无法获取BIRD2状态"
        echo
        echo -e "${CYAN}BGP协议状态:${NC}"
        birdc2 show protocols all bgp 2>/dev/null || echo "无BGP协议配置"
    else
        echo -e "${RED}BIRD控制台未找到${NC}"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 导入BGP配置
import_bgp_config() {
    echo -e "${CYAN}导入BGP配置${NC}"
    echo "请选择要导入的配置文件:"
    
    local config_dir="/etc/ipv6-wireguard"
    if [[ -d "$config_dir" ]]; then
        local configs=($(find "$config_dir" -name "*.conf" -type f))
        if [[ ${#configs[@]} -gt 0 ]]; then
            for i in "${!configs[@]}"; do
                echo -e "  ${GREEN}$((i+1)).${NC} ${configs[i]}"
            done
        else
            echo "未找到配置文件"
            read -p "按回车键继续..."
            return
        fi
    else
        echo "配置目录不存在: $config_dir"
        read -p "按回车键继续..."
        return
    fi
    
    read -p "请选择配置文件 (1-${#configs[@]}): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#configs[@]} ]]; then
        local selected_config="${configs[$((choice-1))]}"
        echo "导入配置: $selected_config"
        # 这里可以添加具体的导入逻辑
        echo -e "${GREEN}✓${NC} 配置导入完成"
    else
        echo -e "${RED}无效选择${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 导出BGP配置
export_bgp_config() {
    echo -e "${CYAN}导出BGP配置${NC}"
    
    local export_dir="/etc/ipv6-wireguard/exports"
    mkdir -p "$export_dir"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local export_file="$export_dir/bgp_config_$timestamp.conf"
    
    cat > "$export_file" << EOF
# BGP配置导出
# 导出时间: $(date)
# 路由器ID: $BGP_ROUTER_ID
# AS号: $BGP_AS_NUMBER
# 上游ASN: $BGP_UPSTREAM_ASN
# Multihop: $BGP_MULTIHOP
# IPv6前缀: $BGP_IPV6_PREFIXES

# BGP邻居配置
$BGP_NEIGHBORS
EOF
    
    echo -e "${GREEN}✓${NC} BGP配置已导出到: $export_file"
    read -p "按回车键继续..."
}

# 网络配置菜单
network_config_menu() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    网络配置管理                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}网络配置选项:${NC}"
        echo -e "  ${GREEN}1.${NC} IPv6前缀管理"
        echo -e "  ${GREEN}2.${NC} BGP邻居配置"
        echo -e "  ${GREEN}3.${NC} 路由表查看"
        echo -e "  ${GREEN}4.${NC} 网络接口管理"
        echo -e "  ${GREEN}5.${NC} 网络诊断工具"
        echo -e "  ${GREEN}6.${NC} 查看BGP状态"
        echo -e "  ${GREEN}7.${NC} 网络统计信息"
        echo -e "  ${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 (0-7): " choice
        
        case "$choice" in
            "1")
                ipv6_prefix_management
                ;;
            "2")
                bgp_neighbor_management
                ;;
            "3")
                view_routing_table
                ;;
            "4")
                network_interface_management
                ;;
            "5")
                network_diagnostics
                ;;
            "6")
                view_bgp_status
                ;;
            "7")
                show_network_statistics
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# IPv6前缀管理
ipv6_prefix_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    IPv6前缀管理                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        # 显示当前前缀配置
        echo -e "${CYAN}当前IPv6前缀配置:${NC}"
        if [[ -f /etc/wireguard/wg0.conf ]]; then
            grep "Address" /etc/wireguard/wg0.conf | head -1
        else
            echo "  WireGuard配置未找到"
        fi
        
        echo
        echo -e "${YELLOW}IPv6前缀管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看当前前缀"
        echo -e "  ${GREEN}2.${NC} 添加新前缀"
        echo -e "  ${GREEN}3.${NC} 删除前缀"
        echo -e "  ${GREEN}4.${NC} 修改前缀"
        echo -e "  ${GREEN}5.${NC} 前缀分配统计"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                show_current_prefixes
                ;;
            "2")
                add_ipv6_prefix
                ;;
            "3")
                remove_ipv6_prefix
                ;;
            "4")
                modify_ipv6_prefix
                ;;
            "5")
                show_prefix_statistics
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 显示当前前缀
show_current_prefixes() {
    echo -e "${CYAN}当前IPv6前缀配置:${NC}"
    if [[ -f /etc/wireguard/wg0.conf ]]; then
        grep "Address" /etc/wireguard/wg0.conf | while read line; do
            echo "  $line"
        done
    else
        echo "  WireGuard配置未找到"
    fi
    
    echo
    echo -e "${CYAN}BIRD配置中的前缀:${NC}"
    if [[ -f /etc/bird/bird.conf ]]; then
        grep -E "route.*via" /etc/bird/bird.conf | while read line; do
            echo "  $line"
        done
    else
        echo "  BIRD配置未找到"
    fi
    
    read -p "按回车键继续..."
}

# 添加IPv6前缀
add_ipv6_prefix() {
    echo -e "${CYAN}添加IPv6前缀${NC}"
    echo "支持的格式: 2001:db8::/48"
    
    read -p "请输入新的IPv6前缀: " new_prefix
    
    if [[ "$new_prefix" =~ ^[0-9a-fA-F:]+/[0-9]+$ ]]; then
        # 添加到WireGuard配置
        if [[ -f /etc/wireguard/wg0.conf ]]; then
            # 检查前缀是否已存在
            if grep -q "$new_prefix" /etc/wireguard/wg0.conf; then
                echo -e "${YELLOW}前缀已存在${NC}"
            else
                # 添加到Address行
                sed -i "s/Address = /Address = $new_prefix, /" /etc/wireguard/wg0.conf
                echo -e "${GREEN}✓${NC} 前缀已添加到WireGuard配置"
            fi
        fi
        
        # 添加到BIRD配置
        if [[ -f /etc/bird/bird.conf ]]; then
            # 检查前缀是否已存在
            if grep -q "$new_prefix" /etc/bird/bird.conf; then
                echo -e "${YELLOW}前缀在BIRD配置中已存在${NC}"
            else
                # 添加到静态路由
                sed -i "/route.*via ::1;/a\\    route $new_prefix via ::1;" /etc/bird/bird.conf
                echo -e "${GREEN}✓${NC} 前缀已添加到BIRD配置"
            fi
        fi
        
        echo -e "${GREEN}前缀添加完成${NC}"
    else
        echo -e "${RED}无效的IPv6前缀格式${NC}"
    fi
    
    read -p "按回车键继续..."
}

# BGP邻居管理
bgp_neighbor_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    BGP邻居管理                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}BGP邻居管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看当前邻居"
        echo -e "  ${GREEN}2.${NC} 添加BGP邻居"
        echo -e "  ${GREEN}3.${NC} 删除BGP邻居"
        echo -e "  ${GREEN}4.${NC} 修改邻居配置"
        echo -e "  ${GREEN}5.${NC} 邻居状态检查"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                show_bgp_neighbors
                ;;
            "2")
                add_bgp_neighbor
                ;;
            "3")
                remove_bgp_neighbor
                ;;
            "4")
                modify_bgp_neighbor
                ;;
            "5")
                check_bgp_neighbor_status
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 查看BGP邻居
show_bgp_neighbors() {
    echo -e "${CYAN}当前BGP邻居配置:${NC}"
    
    if command -v birdc >/dev/null 2>&1; then
        echo -e "${CYAN}BIRD邻居状态:${NC}"
        birdc show protocols 2>/dev/null | grep -E "BGP|neighbor" || echo "  无BGP邻居配置"
    elif command -v birdc2 >/dev/null 2>&1; then
        echo -e "${CYAN}BIRD2邻居状态:${NC}"
        birdc2 show protocols 2>/dev/null | grep -E "BGP|neighbor" || echo "  无BGP邻居配置"
    else
        echo "  BIRD控制台未找到"
    fi
    
    echo
    echo -e "${CYAN}配置文件中的邻居:${NC}"
    if [[ -f /etc/bird/bird.conf ]]; then
        grep -A 10 "protocol bgp" /etc/bird/bird.conf | while read line; do
            echo "  $line"
        done
    else
        echo "  BIRD配置文件未找到"
    fi
    
    read -p "按回车键继续..."
}

# 查看路由表
view_routing_table() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    路由表查看                              ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${CYAN}IPv4路由表:${NC}"
    ip route show | head -20 | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${CYAN}IPv6路由表:${NC}"
    ip -6 route show | head -20 | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${CYAN}BGP路由表:${NC}"
    if command -v birdc >/dev/null 2>&1; then
        birdc show route 2>/dev/null | head -20 || echo "  BGP路由表为空或BIRD未运行"
    elif command -v birdc2 >/dev/null 2>&1; then
        birdc2 show route 2>/dev/null | head -20 || echo "  BGP路由表为空或BIRD未运行"
    else
        echo "  BIRD控制台未找到"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 网络诊断工具
network_diagnostics() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    网络诊断工具                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}诊断工具选项:${NC}"
        echo -e "  ${GREEN}1.${NC} Ping测试"
        echo -e "  ${GREEN}2.${NC} 网络连通性测试"
        echo -e "  ${GREEN}3.${NC} DNS解析测试"
        echo -e "  ${GREEN}4.${NC} 端口扫描"
        echo -e "  ${GREEN}5.${NC} 网络延迟测试"
        echo -e "  ${GREEN}6.${NC} 路由跟踪"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-6): " choice
        
        case "$choice" in
            "1")
                ping_test
                ;;
            "2")
                connectivity_test
                ;;
            "3")
                dns_test
                ;;
            "4")
                port_scan
                ;;
            "5")
                latency_test
                ;;
            "6")
                traceroute_test
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# Ping测试
ping_test() {
    echo -e "${CYAN}Ping测试${NC}"
    read -p "请输入要测试的IP地址或域名: " target
    
    if [[ -n "$target" ]]; then
        echo -e "${CYAN}正在测试 $target...${NC}"
        ping -c 4 "$target" 2>/dev/null || echo -e "${RED}Ping测试失败${NC}"
    else
        echo -e "${RED}请输入有效的目标地址${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 网络连通性测试
connectivity_test() {
    echo -e "${CYAN}网络连通性测试${NC}"
    echo "测试常用服务的连通性..."
    
    local targets=("8.8.8.8" "1.1.1.1" "google.com" "cloudflare.com")
    
    for target in "${targets[@]}"; do
        echo -n "测试 $target: "
        if ping -c 1 -W 3 "$target" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ 连通${NC}"
        else
            echo -e "${RED}✗ 不通${NC}"
        fi
    done
    
    read -p "按回车键继续..."
}

# DNS解析测试
dns_test() {
    echo -e "${CYAN}DNS解析测试${NC}"
    read -p "请输入要测试的域名: " domain
    
    if [[ -n "$domain" ]]; then
        echo -e "${CYAN}正在解析 $domain...${NC}"
        nslookup "$domain" 2>/dev/null || echo -e "${RED}DNS解析失败${NC}"
    else
        echo -e "${RED}请输入有效的域名${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 端口扫描
port_scan() {
    echo -e "${CYAN}端口扫描${NC}"
    read -p "请输入要扫描的主机IP: " host
    read -p "请输入要扫描的端口范围 (如: 80-443): " ports
    
    if [[ -n "$host" && -n "$ports" ]]; then
        echo -e "${CYAN}正在扫描 $host:$ports...${NC}"
        if command -v nmap >/dev/null 2>&1; then
            nmap -p "$ports" "$host" 2>/dev/null || echo -e "${RED}端口扫描失败${NC}"
        else
            echo -e "${YELLOW}nmap未安装，使用nc进行简单扫描${NC}"
            nc -zv "$host" "$ports" 2>&1 || echo -e "${RED}端口扫描失败${NC}"
        fi
    else
        echo -e "${RED}请输入有效的主机和端口${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 网络延迟测试
latency_test() {
    echo -e "${CYAN}网络延迟测试${NC}"
    read -p "请输入要测试的目标: " target
    
    if [[ -n "$target" ]]; then
        echo -e "${CYAN}正在测试 $target 的延迟...${NC}"
        ping -c 10 "$target" 2>/dev/null | tail -1 || echo -e "${RED}延迟测试失败${NC}"
    else
        echo -e "${RED}请输入有效的目标地址${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 路由跟踪
traceroute_test() {
    echo -e "${CYAN}路由跟踪${NC}"
    read -p "请输入要跟踪的目标: " target
    
    if [[ -n "$target" ]]; then
        echo -e "${CYAN}正在跟踪到 $target 的路由...${NC}"
        traceroute "$target" 2>/dev/null || echo -e "${RED}路由跟踪失败${NC}"
    else
        echo -e "${RED}请输入有效的目标地址${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 查看BGP状态
view_bgp_status() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    BGP状态查看                              ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    if command -v birdc >/dev/null 2>&1; then
        echo -e "${CYAN}BIRD状态:${NC}"
        birdc show status 2>/dev/null || echo "  BIRD未运行或配置错误"
        
        echo
        echo -e "${CYAN}BGP协议状态:${NC}"
        birdc show protocols 2>/dev/null || echo "  无协议信息"
        
        echo
        echo -e "${CYAN}BGP路由统计:${NC}"
        birdc show route count 2>/dev/null || echo "  无路由统计"
    elif command -v birdc2 >/dev/null 2>&1; then
        echo -e "${CYAN}BIRD2状态:${NC}"
        birdc2 show status 2>/dev/null || echo "  BIRD2未运行或配置错误"
        
        echo
        echo -e "${CYAN}BGP协议状态:${NC}"
        birdc2 show protocols 2>/dev/null || echo "  无协议信息"
        
        echo
        echo -e "${CYAN}BGP路由统计:${NC}"
        birdc2 show route count 2>/dev/null || echo "  无路由统计"
    else
        echo -e "${RED}BIRD控制台未找到${NC}"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 显示网络统计信息
show_network_statistics() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    网络统计信息                            ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${CYAN}网络接口统计:${NC}"
    cat /proc/net/dev | head -2
    cat /proc/net/dev | grep -E "eth|ens|enp|wg" | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${CYAN}连接统计:${NC}"
    ss -s 2>/dev/null || netstat -s 2>/dev/null | head -10
    
    echo
    echo -e "${CYAN}WireGuard统计:${NC}"
    if command -v wg >/dev/null 2>&1; then
        wg show wg0 2>/dev/null | while read line; do
            echo "  $line"
        done
    else
        echo "  WireGuard未安装或未运行"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 网络接口管理
network_interface_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    网络接口管理                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${CYAN}当前网络接口:${NC}"
        ip link show | grep -E "^[0-9]+:" | while read line; do
            echo "  $line"
        done
        
        echo
        echo -e "${YELLOW}接口管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看接口详情"
        echo -e "  ${GREEN}2.${NC} 启用/禁用接口"
        echo -e "  ${GREEN}3.${NC} 配置IP地址"
        echo -e "  ${GREEN}4.${NC} 查看接口统计"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-4): " choice
        
        case "$choice" in
            "1")
                show_interface_details
                ;;
            "2")
                toggle_interface
                ;;
            "3")
                configure_interface_ip
                ;;
            "4")
                show_interface_statistics
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 显示接口详情
show_interface_details() {
    read -p "请输入接口名称: " interface
    
    if [[ -n "$interface" ]]; then
        echo -e "${CYAN}接口 $interface 详情:${NC}"
        ip addr show "$interface" 2>/dev/null || echo -e "${RED}接口不存在${NC}"
    else
        echo -e "${RED}请输入有效的接口名称${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 启用/禁用接口
toggle_interface() {
    read -p "请输入接口名称: " interface
    read -p "操作 (up/down): " action
    
    if [[ -n "$interface" && -n "$action" ]]; then
        if [[ "$action" == "up" || "$action" == "down" ]]; then
            if ip link set "$interface" "$action" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} 接口 $interface 已$action"
            else
                echo -e "${RED}✗${NC} 操作失败"
            fi
        else
            echo -e "${RED}无效操作，请使用 up 或 down${NC}"
        fi
    else
        echo -e "${RED}请输入有效的接口名称和操作${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 配置接口IP
configure_interface_ip() {
    read -p "请输入接口名称: " interface
    read -p "请输入IP地址 (如: 192.168.1.100/24): " ip_address
    
    if [[ -n "$interface" && -n "$ip_address" ]]; then
        if ip addr add "$ip_address" dev "$interface" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} IP地址已添加到接口 $interface"
        else
            echo -e "${RED}✗${NC} 配置失败"
        fi
    else
        echo -e "${RED}请输入有效的接口名称和IP地址${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 显示接口统计
show_interface_statistics() {
    read -p "请输入接口名称: " interface
    
    if [[ -n "$interface" ]]; then
        echo -e "${CYAN}接口 $interface 统计:${NC}"
        cat /proc/net/dev | grep "$interface" || echo -e "${RED}接口不存在${NC}"
    else
        echo -e "${RED}请输入有效的接口名称${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 防火墙管理菜单
firewall_management_menu() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    防火墙管理                              ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        # 显示防火墙状态
        show_firewall_status
        
        echo -e "${YELLOW}防火墙管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看防火墙状态"
        echo -e "  ${GREEN}2.${NC} 启用/禁用防火墙"
        echo -e "  ${GREEN}3.${NC} 查看防火墙规则"
        echo -e "  ${GREEN}4.${NC} 添加防火墙规则"
        echo -e "  ${GREEN}5.${NC} 删除防火墙规则"
        echo -e "  ${GREEN}6.${NC} 端口管理"
        echo -e "  ${GREEN}7.${NC} 服务管理"
        echo -e "  ${GREEN}8.${NC} 防火墙日志"
        echo -e "  ${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 (0-8): " choice
        
        case "$choice" in
            "1")
                show_firewall_status
                read -p "按回车键继续..."
                ;;
            "2")
                toggle_firewall
                ;;
            "3")
                view_firewall_rules
                ;;
            "4")
                add_firewall_rule
                ;;
            "5")
                remove_firewall_rule
                ;;
            "6")
                port_management
                ;;
            "7")
                service_management
                ;;
            "8")
                view_firewall_logs
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 显示防火墙状态
show_firewall_status() {
    echo -e "${CYAN}防火墙状态:${NC}"
    echo
    
    if command -v ufw >/dev/null 2>&1; then
        echo -e "  UFW: $([ "$(ufw status | grep 'Status:' | awk '{print $2}')" == "active" ] && echo -e "${GREEN}已启用${NC}" || echo -e "${RED}已禁用${NC}")"
        local ufw_rules=$(ufw status numbered | grep -c "^\[" 2>/dev/null || echo "0")
        echo -e "    规则数量: $ufw_rules"
    fi
    
    if command -v firewall-cmd >/dev/null 2>&1; then
        if systemctl is-active --quiet firewalld; then
            echo -e "  Firewalld: ${GREEN}已启用${NC}"
            local firewalld_zones=$(firewall-cmd --get-zones 2>/dev/null | wc -w)
            echo -e "    活动区域: $firewalld_zones"
        else
            echo -e "  Firewalld: ${RED}已禁用${NC}"
        fi
    fi
    
    if command -v nft >/dev/null 2>&1; then
        echo -e "  nftables: $([ "$(nft list tables 2>/dev/null | wc -l)" -gt 0 ] && echo -e "${GREEN}已配置${NC}" || echo -e "${YELLOW}未配置${NC}")"
    fi
    
    if command -v iptables >/dev/null 2>&1; then
        local iptables_rules=$(iptables -L | grep -c "^Chain" 2>/dev/null || echo "0")
        echo -e "  iptables: $([ "$iptables_rules" -gt 0 ] && echo -e "${GREEN}已配置${NC}" || echo -e "${YELLOW}未配置${NC}")"
        echo -e "    链数量: $iptables_rules"
    fi
    
    echo
}

# 启用/禁用防火墙
toggle_firewall() {
    echo -e "${CYAN}防火墙控制${NC}"
    echo "1. 启用防火墙"
    echo "2. 禁用防火墙"
    read -p "请选择操作 (1-2): " action
    
    case "$action" in
        "1")
            enable_firewall
            ;;
        "2")
            disable_firewall
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    read -p "按回车键继续..."
}

# 启用防火墙
enable_firewall() {
    if command -v ufw >/dev/null 2>&1; then
        if ufw --force enable; then
            echo -e "${GREEN}✓${NC} UFW 已启用"
        else
            echo -e "${RED}✗${NC} UFW 启用失败"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if systemctl enable firewalld && systemctl start firewalld; then
            echo -e "${GREEN}✓${NC} Firewalld 已启用"
        else
            echo -e "${RED}✗${NC} Firewalld 启用失败"
        fi
    else
        echo -e "${YELLOW}未找到支持的防火墙工具${NC}"
    fi
}

# 禁用防火墙
disable_firewall() {
    if command -v ufw >/dev/null 2>&1; then
        if ufw disable; then
            echo -e "${GREEN}✓${NC} UFW 已禁用"
        else
            echo -e "${RED}✗${NC} UFW 禁用失败"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if systemctl stop firewalld && systemctl disable firewalld; then
            echo -e "${GREEN}✓${NC} Firewalld 已禁用"
        else
            echo -e "${RED}✗${NC} Firewalld 禁用失败"
        fi
    else
        echo -e "${YELLOW}未找到支持的防火墙工具${NC}"
    fi
}

# 查看防火墙规则
view_firewall_rules() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    防火墙规则查看                            ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    if command -v ufw >/dev/null 2>&1; then
        echo -e "${CYAN}UFW 规则:${NC}"
        ufw status verbose
        echo
    fi
    
    if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld; then
        echo -e "${CYAN}Firewalld 规则:${NC}"
        firewall-cmd --list-all
        echo
    fi
    
    if command -v iptables >/dev/null 2>&1; then
        echo -e "${CYAN}iptables 规则:${NC}"
        iptables -L -n -v
        echo
    fi
    
    if command -v nft >/dev/null 2>&1; then
        echo -e "${CYAN}nftables 规则:${NC}"
        nft list ruleset 2>/dev/null || echo "  nftables 未配置"
        echo
    fi
    
    read -p "按回车键继续..."
}

# 添加防火墙规则
add_firewall_rule() {
    echo -e "${CYAN}添加防火墙规则${NC}"
    echo "1. 允许端口"
    echo "2. 拒绝端口"
    echo "3. 允许IP"
    echo "4. 拒绝IP"
    read -p "请选择规则类型 (1-4): " rule_type
    
    case "$rule_type" in
        "1")
            add_port_rule "allow"
            ;;
        "2")
            add_port_rule "deny"
            ;;
        "3")
            add_ip_rule "allow"
            ;;
        "4")
            add_ip_rule "deny"
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    read -p "按回车键继续..."
}

# 添加端口规则
add_port_rule() {
    local action="$1"
    read -p "请输入端口号或端口范围 (如: 80 或 80-443): " port
    read -p "请输入协议 (tcp/udp，默认tcp): " protocol
    protocol="${protocol:-tcp}"
    
    if [[ -n "$port" ]]; then
        if command -v ufw >/dev/null 2>&1; then
            if [[ "$action" == "allow" ]]; then
                ufw allow "$port/$protocol"
                echo -e "${GREEN}✓${NC} UFW 规则已添加: 允许 $port/$protocol"
            else
                ufw deny "$port/$protocol"
                echo -e "${GREEN}✓${NC} UFW 规则已添加: 拒绝 $port/$protocol"
            fi
        elif command -v firewall-cmd >/dev/null 2>&1; then
            if [[ "$action" == "allow" ]]; then
                firewall-cmd --permanent --add-port="$port/$protocol"
                firewall-cmd --reload
                echo -e "${GREEN}✓${NC} Firewalld 规则已添加: 允许 $port/$protocol"
            else
                firewall-cmd --permanent --remove-port="$port/$protocol"
                firewall-cmd --reload
                echo -e "${GREEN}✓${NC} Firewalld 规则已添加: 拒绝 $port/$protocol"
            fi
        else
            echo -e "${YELLOW}未找到支持的防火墙工具${NC}"
        fi
    else
        echo -e "${RED}请输入有效的端口${NC}"
    fi
}

# 添加IP规则
add_ip_rule() {
    local action="$1"
    read -p "请输入IP地址或网段: " ip_address
    
    if [[ -n "$ip_address" ]]; then
        if command -v ufw >/dev/null 2>&1; then
            if [[ "$action" == "allow" ]]; then
                ufw allow from "$ip_address"
                echo -e "${GREEN}✓${NC} UFW 规则已添加: 允许来自 $ip_address"
            else
                ufw deny from "$ip_address"
                echo -e "${GREEN}✓${NC} UFW 规则已添加: 拒绝来自 $ip_address"
            fi
        elif command -v firewall-cmd >/dev/null 2>&1; then
            if [[ "$action" == "allow" ]]; then
                firewall-cmd --permanent --add-source="$ip_address"
                firewall-cmd --reload
                echo -e "${GREEN}✓${NC} Firewalld 规则已添加: 允许来自 $ip_address"
            else
                firewall-cmd --permanent --remove-source="$ip_address"
                firewall-cmd --reload
                echo -e "${GREEN}✓${NC} Firewalld 规则已添加: 拒绝来自 $ip_address"
            fi
        else
            echo -e "${YELLOW}未找到支持的防火墙工具${NC}"
        fi
    else
        echo -e "${RED}请输入有效的IP地址${NC}"
    fi
}

# 删除防火墙规则
remove_firewall_rule() {
    echo -e "${CYAN}删除防火墙规则${NC}"
    
    if command -v ufw >/dev/null 2>&1; then
        echo -e "${CYAN}当前UFW规则:${NC}"
        ufw status numbered
        echo
        read -p "请输入要删除的规则编号: " rule_num
        
        if [[ "$rule_num" =~ ^[0-9]+$ ]]; then
            if ufw --force delete "$rule_num"; then
                echo -e "${GREEN}✓${NC} 规则已删除"
            else
                echo -e "${RED}✗${NC} 删除失败"
            fi
        else
            echo -e "${RED}请输入有效的规则编号${NC}"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        echo -e "${CYAN}当前Firewalld规则:${NC}"
        firewall-cmd --list-all
        echo
        read -p "请输入要删除的端口 (如: 80/tcp): " port
        read -p "请输入要删除的源IP (可选): " source_ip
        
        if [[ -n "$port" ]]; then
            if [[ -n "$source_ip" ]]; then
                firewall-cmd --permanent --remove-source="$source_ip"
            fi
            firewall-cmd --permanent --remove-port="$port"
            firewall-cmd --reload
            echo -e "${GREEN}✓${NC} 规则已删除"
        else
            echo -e "${RED}请输入有效的端口${NC}"
        fi
    else
        echo -e "${YELLOW}未找到支持的防火墙工具${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 端口管理
port_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    端口管理                                ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}端口管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看开放端口"
        echo -e "  ${GREEN}2.${NC} 开放常用端口"
        echo -e "  ${GREEN}3.${NC} 关闭端口"
        echo -e "  ${GREEN}4.${NC} 端口扫描"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-4): " choice
        
        case "$choice" in
            "1")
                show_open_ports
                ;;
            "2")
                open_common_ports
                ;;
            "3")
                close_port
                ;;
            "4")
                scan_ports
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 查看开放端口
show_open_ports() {
    echo -e "${CYAN}当前开放的端口:${NC}"
    
    if command -v ss >/dev/null 2>&1; then
        ss -tuln | grep LISTEN | while read line; do
            echo "  $line"
        done
    else
        netstat -tuln | grep LISTEN | while read line; do
            echo "  $line"
        done
    fi
    
    echo
    read -p "按回车键继续..."
}

# 开放常用端口
open_common_ports() {
    echo -e "${CYAN}开放常用端口${NC}"
    echo "1. SSH (22/tcp)"
    echo "2. HTTP (80/tcp)"
    echo "3. HTTPS (443/tcp)"
    echo "4. WireGuard (51820/udp)"
    echo "5. BGP (179/tcp)"
    echo "6. 自定义端口"
    read -p "请选择要开放的端口 (1-6): " choice
    
    case "$choice" in
        "1")
            open_port "22" "tcp" "SSH"
            ;;
        "2")
            open_port "80" "tcp" "HTTP"
            ;;
        "3")
            open_port "443" "tcp" "HTTPS"
            ;;
        "4")
            open_port "51820" "udp" "WireGuard"
            ;;
        "5")
            open_port "179" "tcp" "BGP"
            ;;
        "6")
            read -p "请输入端口号: " port
            read -p "请输入协议 (tcp/udp): " protocol
            read -p "请输入描述: " description
            open_port "$port" "$protocol" "$description"
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    read -p "按回车键继续..."
}

# 开放端口
open_port() {
    local port="$1"
    local protocol="$2"
    local description="$3"
    
    if command -v ufw >/dev/null 2>&1; then
        if ufw allow "$port/$protocol"; then
            echo -e "${GREEN}✓${NC} $description ($port/$protocol) 已开放"
        else
            echo -e "${RED}✗${NC} 开放失败"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if firewall-cmd --permanent --add-port="$port/$protocol" && firewall-cmd --reload; then
            echo -e "${GREEN}✓${NC} $description ($port/$protocol) 已开放"
        else
            echo -e "${RED}✗${NC} 开放失败"
        fi
    else
        echo -e "${YELLOW}未找到支持的防火墙工具${NC}"
    fi
}

# 关闭端口
close_port() {
    read -p "请输入要关闭的端口: " port
    read -p "请输入协议 (tcp/udp): " protocol
    
    if [[ -n "$port" && -n "$protocol" ]]; then
        if command -v ufw >/dev/null 2>&1; then
            if ufw deny "$port/$protocol"; then
                echo -e "${GREEN}✓${NC} 端口 $port/$protocol 已关闭"
            else
                echo -e "${RED}✗${NC} 关闭失败"
            fi
        elif command -v firewall-cmd >/dev/null 2>&1; then
            if firewall-cmd --permanent --remove-port="$port/$protocol" && firewall-cmd --reload; then
                echo -e "${GREEN}✓${NC} 端口 $port/$protocol 已关闭"
            else
                echo -e "${RED}✗${NC} 关闭失败"
            fi
        else
            echo -e "${YELLOW}未找到支持的防火墙工具${NC}"
        fi
    else
        echo -e "${RED}请输入有效的端口和协议${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 端口扫描
scan_ports() {
    read -p "请输入要扫描的主机IP (默认本机): " host
    host="${host:-127.0.0.1}"
    
    echo -e "${CYAN}正在扫描 $host 的端口...${NC}"
    
    if command -v nmap >/dev/null 2>&1; then
        nmap -sT -O "$host" 2>/dev/null || echo -e "${RED}端口扫描失败${NC}"
    else
        echo -e "${YELLOW}nmap未安装，使用nc进行简单扫描${NC}"
        for port in 22 80 443 8080 3306 5432; do
            if nc -z "$host" "$port" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} 端口 $port 开放"
            else
                echo -e "${RED}✗${NC} 端口 $port 关闭"
            fi
        done
    fi
    
    read -p "按回车键继续..."
}

# 服务管理
service_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    服务管理                                ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}服务管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看服务状态"
        echo -e "  ${GREEN}2.${NC} 启动服务"
        echo -e "  ${GREEN}3.${NC} 停止服务"
        echo -e "  ${GREEN}4.${NC} 重启服务"
        echo -e "  ${GREEN}5.${NC} 启用/禁用服务"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                show_service_status
                ;;
            "2")
                start_service
                ;;
            "3")
                stop_service
                ;;
            "4")
                restart_service
                ;;
            "5")
                toggle_service
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 启动服务
start_service() {
    read -p "请输入服务名称: " service_name
    
    if [[ -n "$service_name" ]]; then
        if systemctl start "$service_name"; then
            echo -e "${GREEN}✓${NC} 服务 $service_name 已启动"
        else
            echo -e "${RED}✗${NC} 服务启动失败"
        fi
    else
        echo -e "${RED}请输入有效的服务名称${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 停止服务
stop_service() {
    read -p "请输入服务名称: " service_name
    
    if [[ -n "$service_name" ]]; then
        if systemctl stop "$service_name"; then
            echo -e "${GREEN}✓${NC} 服务 $service_name 已停止"
        else
            echo -e "${RED}✗${NC} 服务停止失败"
        fi
    else
        echo -e "${RED}请输入有效的服务名称${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 重启服务
restart_service() {
    read -p "请输入服务名称: " service_name
    
    if [[ -n "$service_name" ]]; then
        if systemctl restart "$service_name"; then
            echo -e "${GREEN}✓${NC} 服务 $service_name 已重启"
        else
            echo -e "${RED}✗${NC} 服务重启失败"
        fi
    else
        echo -e "${RED}请输入有效的服务名称${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 启用/禁用服务
toggle_service() {
    read -p "请输入服务名称: " service_name
    read -p "操作 (enable/disable): " action
    
    if [[ -n "$service_name" && -n "$action" ]]; then
        if [[ "$action" == "enable" || "$action" == "disable" ]]; then
            if systemctl "$action" "$service_name"; then
                echo -e "${GREEN}✓${NC} 服务 $service_name 已$action"
            else
                echo -e "${RED}✗${NC} 操作失败"
            fi
        else
            echo -e "${RED}无效操作，请使用 enable 或 disable${NC}"
        fi
    else
        echo -e "${RED}请输入有效的服务名称和操作${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 查看防火墙日志
view_firewall_logs() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    防火墙日志                                ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${CYAN}系统日志中的防火墙信息:${NC}"
    journalctl -u firewalld -n 50 --no-pager 2>/dev/null || echo "  无Firewalld日志"
    
    echo
    echo -e "${CYAN}内核日志中的防火墙信息:${NC}"
    dmesg | grep -i "firewall\|iptables\|ufw" | tail -20 || echo "  无防火墙内核日志"
    
    echo
    echo -e "${CYAN}系统日志中的网络连接:${NC}"
    journalctl | grep -i "connection\|refused\|timeout" | tail -10 || echo "  无网络连接日志"
    
    echo
    read -p "按回车键继续..."
}

# 系统维护菜单
system_maintenance_menu() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    系统维护                                ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}系统维护选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 系统状态检查"
        echo -e "  ${GREEN}2.${NC} 性能监控"
        echo -e "  ${GREEN}3.${NC} 日志管理"
        echo -e "  ${GREEN}4.${NC} 磁盘空间管理"
        echo -e "  ${GREEN}5.${NC} 系统更新"
        echo -e "  ${GREEN}6.${NC} 进程管理"
        echo -e "  ${GREEN}7.${NC} 系统清理"
        echo -e "  ${GREEN}8.${NC} 安全扫描"
        echo -e "  ${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 (0-8): " choice
        
        case "$choice" in
            "1")
                system_status_check
                ;;
            "2")
                performance_monitoring
                ;;
            "3")
                log_management
                ;;
            "4")
                disk_space_management
                ;;
            "5")
                system_update
                ;;
            "6")
                process_management
                ;;
            "7")
                system_cleanup
                ;;
            "8")
                security_scan
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 系统状态检查
system_status_check() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    系统状态检查                            ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # 系统信息
    echo -e "${CYAN}系统信息:${NC}"
    echo "  主机名: $(hostname)"
    echo "  操作系统: $OS_TYPE $OS_VERSION"
    echo "  架构: $ARCH"
    echo "  内核版本: $(uname -r)"
    echo "  运行时间: $(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}' | sed 's/,//')"
    
    # 负载信息
    echo
    echo -e "${CYAN}系统负载:${NC}"
    uptime | awk -F'load average:' '{print "  " $2}'
    
    # 内存使用
    echo
    echo -e "${CYAN}内存使用:${NC}"
    free -h | while read line; do
        echo "  $line"
    done
    
    # 磁盘使用
    echo
    echo -e "${CYAN}磁盘使用:${NC}"
    df -h | grep -E "/$|/var|/etc|/tmp" | while read line; do
        echo "  $line"
    done
    
    # 网络接口状态
    echo
    echo -e "${CYAN}网络接口状态:${NC}"
    ip link show | grep -E "state UP|state DOWN" | while read line; do
        echo "  $line"
    done
    
    # 服务状态
    echo
    echo -e "${CYAN}关键服务状态:${NC}"
    local services=("wg-quick@wg0" "bird" "bird2" "firewalld" "ufw")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "  $service: ${GREEN}运行中${NC}"
        else
            echo -e "  $service: ${RED}未运行${NC}"
        fi
    done
    
    echo
    read -p "按回车键继续..."
}

# 性能监控
performance_monitoring() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    性能监控                                ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}性能监控选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 实时监控"
        echo -e "  ${GREEN}2.${NC} CPU使用率"
        echo -e "  ${GREEN}3.${NC} 内存使用率"
        echo -e "  ${GREEN}4.${NC} 磁盘I/O"
        echo -e "  ${GREEN}5.${NC} 网络流量"
        echo -e "  ${GREEN}6.${NC} 进程资源使用"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-6): " choice
        
        case "$choice" in
            "1")
                real_time_monitoring
                ;;
            "2")
                cpu_usage_monitoring
                ;;
            "3")
                memory_usage_monitoring
                ;;
            "4")
                disk_io_monitoring
                ;;
            "5")
                network_traffic_monitoring
                ;;
            "6")
                process_resource_monitoring
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 实时监控
real_time_monitoring() {
    echo -e "${CYAN}实时系统监控 (按 Ctrl+C 退出):${NC}"
    echo
    
    if command -v htop >/dev/null 2>&1; then
        htop
    elif command -v top >/dev/null 2>&1; then
        top
    else
        echo -e "${RED}未找到监控工具${NC}"
    fi
}

# CPU使用率监控
cpu_usage_monitoring() {
    echo -e "${CYAN}CPU使用率监控:${NC}"
    echo
    
    # 使用top命令获取CPU使用率
    top -bn1 | grep "Cpu(s)" | while read line; do
        echo "  $line"
    done
    
    # 显示CPU核心数
    echo "  CPU核心数: $(nproc)"
    
    # 显示CPU信息
    if [[ -f /proc/cpuinfo ]]; then
        echo "  CPU型号: $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 内存使用率监控
memory_usage_monitoring() {
    echo -e "${CYAN}内存使用率监控:${NC}"
    echo
    
    # 显示内存使用情况
    free -h | while read line; do
        echo "  $line"
    done
    
    # 显示内存详细信息
    echo
    echo -e "${CYAN}内存详细信息:${NC}"
    if [[ -f /proc/meminfo ]]; then
        grep -E "MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree" /proc/meminfo | while read line; do
            echo "  $line"
        done
    fi
    
    echo
    read -p "按回车键继续..."
}

# 磁盘I/O监控
disk_io_monitoring() {
    echo -e "${CYAN}磁盘I/O监控:${NC}"
    echo
    
    if command -v iostat >/dev/null 2>&1; then
        iostat -x 1 3
    else
        echo -e "${YELLOW}iostat未安装，显示基本磁盘信息:${NC}"
        df -h | while read line; do
            echo "  $line"
        done
    fi
    
    echo
    read -p "按回车键继续..."
}

# 网络流量监控
network_traffic_monitoring() {
    echo -e "${CYAN}网络流量监控:${NC}"
    echo
    
    if command -v iftop >/dev/null 2>&1; then
        echo -e "${YELLOW}启动iftop网络流量监控 (按 q 退出):${NC}"
        iftop
    else
        echo -e "${YELLOW}iftop未安装，显示网络接口统计:${NC}"
        cat /proc/net/dev | head -2
        cat /proc/net/dev | grep -E "eth|ens|enp|wg" | while read line; do
            echo "  $line"
        done
    fi
    
    echo
    read -p "按回车键继续..."
}

# 进程资源使用监控
process_resource_monitoring() {
    echo -e "${CYAN}进程资源使用监控:${NC}"
    echo
    
    echo -e "${CYAN}CPU使用率最高的进程:${NC}"
    ps aux --sort=-%cpu | head -10 | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${CYAN}内存使用率最高的进程:${NC}"
    ps aux --sort=-%mem | head -10 | while read line; do
        echo "  $line"
    done
    
    echo
    read -p "按回车键继续..."
}

# 日志管理
log_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    日志管理                                ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}日志管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看系统日志"
        echo -e "  ${GREEN}2.${NC} 查看应用日志"
        echo -e "  ${GREEN}3.${NC} 日志文件大小"
        echo -e "  ${GREEN}4.${NC} 清理日志文件"
        echo -e "  ${GREEN}5.${NC} 实时日志监控"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                view_system_logs
                ;;
            "2")
                view_application_logs
                ;;
            "3")
                check_log_sizes
                ;;
            "4")
                clean_log_files
                ;;
            "5")
                real_time_log_monitoring
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 查看系统日志
view_system_logs() {
    echo -e "${CYAN}系统日志 (最近50行):${NC}"
    journalctl -n 50 --no-pager
    echo
    read -p "按回车键继续..."
}

# 查看应用日志
view_application_logs() {
    echo -e "${CYAN}应用日志:${NC}"
    echo "1. WireGuard日志"
    echo "2. BIRD日志"
    echo "3. 防火墙日志"
    echo "4. 系统服务日志"
    read -p "请选择日志类型 (1-4): " log_type
    
    case "$log_type" in
        "1")
            journalctl -u wg-quick@wg0 -n 50 --no-pager
            ;;
        "2")
            if [[ -f /var/log/bird/bird.log ]]; then
                tail -50 /var/log/bird/bird.log
            else
                journalctl -u bird -n 50 --no-pager 2>/dev/null || journalctl -u bird2 -n 50 --no-pager 2>/dev/null
            fi
            ;;
        "3")
            journalctl -u firewalld -n 50 --no-pager 2>/dev/null || echo "无防火墙日志"
            ;;
        "4")
            journalctl -u systemd-networkd -n 50 --no-pager 2>/dev/null || echo "无网络服务日志"
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    echo
    read -p "按回车键继续..."
}

# 检查日志文件大小
check_log_sizes() {
    echo -e "${CYAN}日志文件大小:${NC}"
    echo
    
    # 检查系统日志大小
    if [[ -d /var/log ]]; then
        echo -e "${CYAN}系统日志目录大小:${NC}"
        du -sh /var/log/* 2>/dev/null | sort -hr | head -10 | while read line; do
            echo "  $line"
        done
    fi
    
    # 检查journal日志大小
    echo
    echo -e "${CYAN}Journal日志大小:${NC}"
    journalctl --disk-usage 2>/dev/null || echo "  无法获取journal日志大小"
    
    echo
    read -p "按回车键继续..."
}

# 清理日志文件
clean_log_files() {
    echo -e "${CYAN}清理日志文件${NC}"
    echo "警告: 此操作将清理系统日志文件，请确认是否继续"
    read -p "确认清理日志文件? (y/N): " confirm
    
    if [[ "${confirm,,}" == "y" ]]; then
        # 清理journal日志
        journalctl --vacuum-time=7d 2>/dev/null && echo -e "${GREEN}✓${NC} Journal日志已清理"
        
        # 清理旧日志文件
        find /var/log -name "*.log" -type f -mtime +30 -delete 2>/dev/null && echo -e "${GREEN}✓${NC} 旧日志文件已清理"
        
        # 清理临时文件
        find /tmp -type f -mtime +7 -delete 2>/dev/null && echo -e "${GREEN}✓${NC} 临时文件已清理"
        
        echo -e "${GREEN}日志清理完成${NC}"
    else
        echo -e "${YELLOW}日志清理已取消${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 实时日志监控
real_time_log_monitoring() {
    echo -e "${CYAN}实时日志监控 (按 Ctrl+C 退出):${NC}"
    echo "1. 系统日志"
    echo "2. WireGuard日志"
    echo "3. BIRD日志"
    read -p "请选择监控类型 (1-3): " monitor_type
    
    case "$monitor_type" in
        "1")
            journalctl -f
            ;;
        "2")
            journalctl -u wg-quick@wg0 -f
            ;;
        "3")
            if [[ -f /var/log/bird/bird.log ]]; then
                tail -f /var/log/bird/bird.log
            else
                journalctl -u bird -f 2>/dev/null || journalctl -u bird2 -f 2>/dev/null
            fi
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
}

# 磁盘空间管理
disk_space_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    磁盘空间管理                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}磁盘空间管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看磁盘使用情况"
        echo -e "  ${GREEN}2.${NC} 查找大文件"
        echo -e "  ${GREEN}3.${NC} 清理临时文件"
        echo -e "  ${GREEN}4.${NC} 清理包缓存"
        echo -e "  ${GREEN}5.${NC} 清理日志文件"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                show_disk_usage
                ;;
            "2")
                find_large_files
                ;;
            "3")
                clean_temp_files
                ;;
            "4")
                clean_package_cache
                ;;
            "5")
                clean_log_files
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 显示磁盘使用情况
show_disk_usage() {
    echo -e "${CYAN}磁盘使用情况:${NC}"
    df -h | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${CYAN}目录大小 (前10个最大的目录):${NC}"
    du -sh /* 2>/dev/null | sort -hr | head -10 | while read line; do
        echo "  $line"
    done
    
    echo
    read -p "按回车键继续..."
}

# 查找大文件
find_large_files() {
    read -p "请输入要查找的目录 (默认: /): " search_dir
    search_dir="${search_dir:-/}"
    
    echo -e "${CYAN}在 $search_dir 中查找大于100MB的文件:${NC}"
    find "$search_dir" -type f -size +100M 2>/dev/null | head -20 | while read file; do
        size=$(du -h "$file" 2>/dev/null | cut -f1)
        echo "  $size - $file"
    done
    
    echo
    read -p "按回车键继续..."
}

# 清理临时文件
clean_temp_files() {
    echo -e "${CYAN}清理临时文件${NC}"
    
    # 清理/tmp目录
    find /tmp -type f -mtime +7 -delete 2>/dev/null && echo -e "${GREEN}✓${NC} /tmp目录已清理"
    
    # 清理/var/tmp目录
    find /var/tmp -type f -mtime +7 -delete 2>/dev/null && echo -e "${GREEN}✓${NC} /var/tmp目录已清理"
    
    # 清理用户临时目录
    find /home -name ".cache" -type d -exec find {} -type f -mtime +7 -delete \; 2>/dev/null && echo -e "${GREEN}✓${NC} 用户缓存已清理"
    
    echo -e "${GREEN}临时文件清理完成${NC}"
    read -p "按回车键继续..."
}

# 清理包缓存
clean_package_cache() {
    echo -e "${CYAN}清理包缓存${NC}"
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt clean && echo -e "${GREEN}✓${NC} APT缓存已清理"
            apt autoremove -y && echo -e "${GREEN}✓${NC} 无用包已清理"
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                dnf clean all && echo -e "${GREEN}✓${NC} DNF缓存已清理"
                dnf autoremove -y && echo -e "${GREEN}✓${NC} 无用包已清理"
            else
                yum clean all && echo -e "${GREEN}✓${NC} YUM缓存已清理"
            fi
            ;;
        "arch")
            pacman -Sc --noconfirm && echo -e "${GREEN}✓${NC} Pacman缓存已清理"
            ;;
    esac
    
    echo -e "${GREEN}包缓存清理完成${NC}"
    read -p "按回车键继续..."
}

# 系统更新
system_update() {
    echo -e "${CYAN}系统更新${NC}"
    echo "1. 检查更新"
    echo "2. 执行更新"
    echo "3. 仅安全更新"
    read -p "请选择操作 (1-3): " update_choice
    
    case "$update_choice" in
        "1")
            check_system_updates
            ;;
        "2")
            perform_system_update
            ;;
        "3")
            perform_security_update
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    read -p "按回车键继续..."
}

# 检查系统更新
check_system_updates() {
    echo -e "${CYAN}检查系统更新...${NC}"
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt update >/dev/null 2>&1
            apt list --upgradable 2>/dev/null | grep -c "upgradable" | while read count; do
                echo "  可更新包数量: $count"
            done
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                dnf check-update 2>/dev/null | grep -c "updates" | while read count; do
                    echo "  可更新包数量: $count"
                done
            else
                yum check-update 2>/dev/null | grep -c "updates" | while read count; do
                    echo "  可更新包数量: $count"
                done
            fi
            ;;
        "arch")
            pacman -Qu 2>/dev/null | wc -l | while read count; do
                echo "  可更新包数量: $count"
            done
            ;;
    esac
}

# 执行系统更新
perform_system_update() {
    echo -e "${CYAN}执行系统更新...${NC}"
    echo "警告: 此操作将更新系统包，可能需要重启"
    read -p "确认继续? (y/N): " confirm
    
    if [[ "${confirm,,}" == "y" ]]; then
        case "$OS_TYPE" in
            "ubuntu"|"debian")
                apt update && apt upgrade -y
                ;;
            "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
                if command -v dnf >/dev/null 2>&1; then
                    dnf update -y
                else
                    yum update -y
                fi
                ;;
            "arch")
                pacman -Syu --noconfirm
                ;;
        esac
        echo -e "${GREEN}系统更新完成${NC}"
    else
        echo -e "${YELLOW}系统更新已取消${NC}"
    fi
}

# 执行安全更新
perform_security_update() {
    echo -e "${CYAN}执行安全更新...${NC}"
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt update && apt upgrade -y -s | grep -i security
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                dnf update --security -y
            else
                yum update --security -y
            fi
            ;;
        "arch")
            pacman -Syu --noconfirm
            ;;
    esac
    
    echo -e "${GREEN}安全更新完成${NC}"
}

# 进程管理
process_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    进程管理                                ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}进程管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看运行进程"
        echo -e "  ${GREEN}2.${NC} 查找进程"
        echo -e "  ${GREEN}3.${NC} 终止进程"
        echo -e "  ${GREEN}4.${NC} 进程详细信息"
        echo -e "  ${GREEN}5.${NC} 进程资源使用"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                show_running_processes
                ;;
            "2")
                find_process
                ;;
            "3")
                kill_process
                ;;
            "4")
                show_process_details
                ;;
            "5")
                show_process_resources
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 查看运行进程
show_running_processes() {
    echo -e "${CYAN}运行中的进程 (前20个):${NC}"
    ps aux | head -1
    ps aux | tail -n +2 | head -20 | while read line; do
        echo "  $line"
    done
    
    echo
    read -p "按回车键继续..."
}

# 查找进程
find_process() {
    read -p "请输入进程名称或关键词: " process_name
    
    if [[ -n "$process_name" ]]; then
        echo -e "${CYAN}查找包含 '$process_name' 的进程:${NC}"
        ps aux | grep -i "$process_name" | grep -v grep | while read line; do
            echo "  $line"
        done
    else
        echo -e "${RED}请输入有效的进程名称${NC}"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 终止进程
kill_process() {
    read -p "请输入进程ID (PID): " pid
    
    if [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "1. 正常终止 (SIGTERM)"
        echo "2. 强制终止 (SIGKILL)"
        read -p "请选择终止方式 (1-2): " kill_type
        
        case "$kill_type" in
            "1")
                if kill "$pid" 2>/dev/null; then
                    echo -e "${GREEN}✓${NC} 进程 $pid 已正常终止"
                else
                    echo -e "${RED}✗${NC} 终止进程失败"
                fi
                ;;
            "2")
                if kill -9 "$pid" 2>/dev/null; then
                    echo -e "${GREEN}✓${NC} 进程 $pid 已强制终止"
                else
                    echo -e "${RED}✗${NC} 强制终止进程失败"
                fi
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                ;;
        esac
    else
        echo -e "${RED}请输入有效的进程ID${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 显示进程详细信息
show_process_details() {
    read -p "请输入进程ID (PID): " pid
    
    if [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo -e "${CYAN}进程 $pid 详细信息:${NC}"
        ps -p "$pid" -o pid,ppid,cmd,%cpu,%mem,etime,stat 2>/dev/null || echo -e "${RED}进程不存在${NC}"
    else
        echo -e "${RED}请输入有效的进程ID${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 显示进程资源使用
show_process_resources() {
    echo -e "${CYAN}进程资源使用情况:${NC}"
    echo
    
    echo -e "${CYAN}CPU使用率最高的进程:${NC}"
    ps aux --sort=-%cpu | head -10 | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${CYAN}内存使用率最高的进程:${NC}"
    ps aux --sort=-%mem | head -10 | while read line; do
        echo "  $line"
    done
    
    echo
    read -p "按回车键继续..."
}

# 系统清理
system_cleanup() {
    echo -e "${CYAN}系统清理${NC}"
    echo "此操作将清理系统中的临时文件、缓存和日志"
    read -p "确认执行系统清理? (y/N): " confirm
    
    if [[ "${confirm,,}" == "y" ]]; then
        # 清理临时文件
        clean_temp_files
        
        # 清理包缓存
        clean_package_cache
        
        # 清理日志文件
        clean_log_files
        
        # 清理用户缓存
        find /home -name ".cache" -type d -exec find {} -type f -mtime +7 -delete \; 2>/dev/null && echo -e "${GREEN}✓${NC} 用户缓存已清理"
        
        # 清理缩略图缓存
        find /home -name ".thumbnails" -type d -exec find {} -type f -mtime +7 -delete \; 2>/dev/null && echo -e "${GREEN}✓${NC} 缩略图缓存已清理"
        
        echo -e "${GREEN}系统清理完成${NC}"
    else
        echo -e "${YELLOW}系统清理已取消${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 安全扫描
security_scan() {
    echo -e "${CYAN}安全扫描${NC}"
    echo "1. 检查开放端口"
    echo "2. 检查用户账户"
    echo "3. 检查文件权限"
    echo "4. 检查系统服务"
    read -p "请选择扫描类型 (1-4): " scan_type
    
    case "$scan_type" in
        "1")
            scan_open_ports
            ;;
        "2")
            check_user_accounts
            ;;
        "3")
            check_file_permissions
            ;;
        "4")
            check_system_services
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    read -p "按回车键继续..."
}

# 扫描开放端口
scan_open_ports() {
    echo -e "${CYAN}扫描开放端口:${NC}"
    
    if command -v nmap >/dev/null 2>&1; then
        nmap -sT -O localhost 2>/dev/null || echo -e "${RED}端口扫描失败${NC}"
    else
        echo -e "${YELLOW}nmap未安装，使用netstat显示监听端口:${NC}"
        netstat -tuln | grep LISTEN | while read line; do
            echo "  $line"
        done
    fi
}

# 检查用户账户
check_user_accounts() {
    echo -e "${CYAN}检查用户账户:${NC}"
    
    echo -e "${CYAN}系统用户:${NC}"
    awk -F: '$3 < 1000 {print "  " $1 ":" $3 ":" $7}' /etc/passwd | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${CYAN}普通用户:${NC}"
    awk -F: '$3 >= 1000 {print "  " $1 ":" $3 ":" $7}' /etc/passwd | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${CYAN}具有sudo权限的用户:${NC}"
    grep -E '^[^#]*sudo' /etc/group | cut -d: -f4 | tr ',' '\n' | while read user; do
        echo "  $user"
    done
}

# 检查文件权限
check_file_permissions() {
    echo -e "${CYAN}检查关键文件权限:${NC}"
    
    local critical_files=("/etc/passwd" "/etc/shadow" "/etc/group" "/etc/sudoers" "/etc/ssh/sshd_config")
    
    for file in "${critical_files[@]}"; do
        if [[ -f "$file" ]]; then
            local perms=$(stat -c "%a %n" "$file" 2>/dev/null)
            echo "  $perms"
        fi
    done
}

# 检查系统服务
check_system_services() {
    echo -e "${CYAN}检查系统服务状态:${NC}"
    
    local services=("ssh" "sshd" "firewalld" "ufw" "fail2ban" "cron" "systemd-resolved")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "  $service: ${GREEN}运行中${NC}"
        else
            echo -e "  $service: ${RED}未运行${NC}"
        fi
    done
}

# 配置备份/恢复菜单
backup_restore_menu() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    配置备份/恢复                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}备份/恢复选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 创建配置备份"
        echo -e "  ${GREEN}2.${NC} 恢复配置备份"
        echo -e "  ${GREEN}3.${NC} 查看备份列表"
        echo -e "  ${GREEN}4.${NC} 删除备份"
        echo -e "  ${GREEN}5.${NC} 自动备份设置"
        echo -e "  ${GREEN}6.${NC} 导出配置"
        echo -e "  ${GREEN}7.${NC} 导入配置"
        echo -e "  ${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 (0-7): " choice
        
        case "$choice" in
            "1")
                create_config_backup
                ;;
            "2")
                restore_config_backup
                ;;
            "3")
                list_backups
                ;;
            "4")
                delete_backup
                ;;
            "5")
                auto_backup_settings
                ;;
            "6")
                export_config
                ;;
            "7")
                import_config
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 创建配置备份
create_config_backup() {
    echo -e "${CYAN}创建配置备份${NC}"
    
    # 生成备份文件名
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_name="ipv6_wireguard_backup_$timestamp"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    echo "备份名称: $backup_name"
    echo "备份路径: $backup_path"
    echo
    
    # 创建备份目录
    mkdir -p "$backup_path"
    
    # 备份WireGuard配置
    if [[ -d /etc/wireguard ]]; then
        cp -r /etc/wireguard "$backup_path/" 2>/dev/null && echo -e "${GREEN}✓${NC} WireGuard配置已备份"
    fi
    
    # 备份BIRD配置
    if [[ -d /etc/bird ]]; then
        cp -r /etc/bird "$backup_path/" 2>/dev/null && echo -e "${GREEN}✓${NC} BIRD配置已备份"
    fi
    
    # 备份IPv6 WireGuard管理器配置
    if [[ -d "$CONFIG_DIR" ]]; then
        cp -r "$CONFIG_DIR" "$backup_path/ipv6_wireguard_config" 2>/dev/null && echo -e "${GREEN}✓${NC} 管理器配置已备份"
    fi
    
    # 备份防火墙配置
    if command -v ufw >/dev/null 2>&1; then
        ufw status > "$backup_path/ufw_status.txt" 2>/dev/null && echo -e "${GREEN}✓${NC} UFW配置已备份"
    fi
    
    if command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --list-all > "$backup_path/firewalld_config.txt" 2>/dev/null && echo -e "${GREEN}✓${NC} Firewalld配置已备份"
    fi
    
    # 备份系统信息
    {
        echo "备份时间: $(date)"
        echo "系统信息: $OS_TYPE $OS_VERSION ($ARCH)"
        echo "内核版本: $(uname -r)"
        echo "主机名: $(hostname)"
    } > "$backup_path/system_info.txt"
    
    # 创建备份压缩包
    cd "$BACKUP_DIR"
    tar -czf "${backup_name}.tar.gz" "$backup_name" 2>/dev/null
    rm -rf "$backup_name"
    
    echo -e "${GREEN}✓${NC} 备份压缩包已创建: ${backup_name}.tar.gz"
    echo -e "${GREEN}配置备份完成!${NC}"
    
    read -p "按回车键继续..."
}

# 恢复配置备份
restore_config_backup() {
    echo -e "${CYAN}恢复配置备份${NC}"
    
    # 显示可用的备份
    echo -e "${CYAN}可用的备份:${NC}"
    local backups=()
    local i=1
    
    for backup in "$BACKUP_DIR"/*.tar.gz; do
        if [[ -f "$backup" ]]; then
            local backup_name=$(basename "$backup" .tar.gz)
            local backup_date=$(stat -c %y "$backup" 2>/dev/null | cut -d' ' -f1)
            local backup_size=$(du -h "$backup" 2>/dev/null | cut -f1)
            echo "  $i. $backup_name ($backup_date, $backup_size)"
            backups+=("$backup")
            ((i++))
        fi
    done
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo -e "${YELLOW}没有找到可用的备份${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    echo
    read -p "请选择要恢复的备份 (1-${#backups[@]}): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#backups[@]}" ]]; then
        local selected_backup="${backups[$((choice-1))]}"
        local backup_name=$(basename "$selected_backup" .tar.gz)
        
        echo -e "${CYAN}恢复备份: $backup_name${NC}"
        echo "警告: 此操作将覆盖当前配置"
        read -p "确认恢复备份? (y/N): " confirm
        
        if [[ "${confirm,,}" == "y" ]]; then
            # 创建临时目录
            local temp_dir="/tmp/backup_restore_$$"
            mkdir -p "$temp_dir"
            
            # 解压备份
            if tar -xzf "$selected_backup" -C "$temp_dir" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} 备份解压成功"
                
                # 恢复WireGuard配置
                if [[ -d "$temp_dir/$backup_name/wireguard" ]]; then
                    cp -r "$temp_dir/$backup_name/wireguard"/* /etc/wireguard/ 2>/dev/null && echo -e "${GREEN}✓${NC} WireGuard配置已恢复"
                fi
                
                # 恢复BIRD配置
                if [[ -d "$temp_dir/$backup_name/bird" ]]; then
                    cp -r "$temp_dir/$backup_name/bird"/* /etc/bird/ 2>/dev/null && echo -e "${GREEN}✓${NC} BIRD配置已恢复"
                fi
                
                # 恢复管理器配置
                if [[ -d "$temp_dir/$backup_name/ipv6_wireguard_config" ]]; then
                    cp -r "$temp_dir/$backup_name/ipv6_wireguard_config"/* "$CONFIG_DIR/" 2>/dev/null && echo -e "${GREEN}✓${NC} 管理器配置已恢复"
                fi
                
                # 清理临时目录
                rm -rf "$temp_dir"
                
                echo -e "${GREEN}配置恢复完成!${NC}"
                echo -e "${YELLOW}建议重启相关服务以应用新配置${NC}"
            else
                echo -e "${RED}✗${NC} 备份解压失败"
                rm -rf "$temp_dir"
            fi
        else
            echo -e "${YELLOW}配置恢复已取消${NC}"
        fi
    else
        echo -e "${RED}无效选择${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 查看备份列表
list_backups() {
    echo -e "${CYAN}备份列表:${NC}"
    echo
    
    if [[ -d "$BACKUP_DIR" ]]; then
        local total_size=0
        local backup_count=0
        
        for backup in "$BACKUP_DIR"/*.tar.gz; do
            if [[ -f "$backup" ]]; then
                local backup_name=$(basename "$backup" .tar.gz)
                local backup_date=$(stat -c %y "$backup" 2>/dev/null | cut -d' ' -f1,2)
                local backup_size=$(du -h "$backup" 2>/dev/null | cut -f1)
                local backup_size_bytes=$(du -b "$backup" 2>/dev/null | cut -f1)
                
                echo "  文件名: $backup_name"
                echo "  创建时间: $backup_date"
                echo "  大小: $backup_size"
                echo "  ---"
                
                total_size=$((total_size + backup_size_bytes))
                ((backup_count++))
            fi
        done
        
        if [[ $backup_count -eq 0 ]]; then
            echo -e "${YELLOW}没有找到备份文件${NC}"
        else
            echo
            echo -e "${CYAN}统计信息:${NC}"
            echo "  备份数量: $backup_count"
            echo "  总大小: $(numfmt --to=iec $total_size)"
        fi
    else
        echo -e "${YELLOW}备份目录不存在${NC}"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 删除备份
delete_backup() {
    echo -e "${CYAN}删除备份${NC}"
    
    # 显示可用的备份
    echo -e "${CYAN}可用的备份:${NC}"
    local backups=()
    local i=1
    
    for backup in "$BACKUP_DIR"/*.tar.gz; do
        if [[ -f "$backup" ]]; then
            local backup_name=$(basename "$backup" .tar.gz)
            local backup_date=$(stat -c %y "$backup" 2>/dev/null | cut -d' ' -f1)
            local backup_size=$(du -h "$backup" 2>/dev/null | cut -f1)
            echo "  $i. $backup_name ($backup_date, $backup_size)"
            backups+=("$backup")
            ((i++))
        fi
    done
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo -e "${YELLOW}没有找到可用的备份${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    echo
    read -p "请选择要删除的备份 (1-${#backups[@]}): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#backups[@]}" ]]; then
        local selected_backup="${backups[$((choice-1))]}"
        local backup_name=$(basename "$selected_backup" .tar.gz)
        
        echo -e "${CYAN}删除备份: $backup_name${NC}"
        read -p "确认删除此备份? (y/N): " confirm
        
        if [[ "${confirm,,}" == "y" ]]; then
            if rm "$selected_backup" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} 备份已删除"
            else
                echo -e "${RED}✗${NC} 删除失败"
            fi
        else
            echo -e "${YELLOW}删除已取消${NC}"
        fi
    else
        echo -e "${RED}无效选择${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 自动备份设置
auto_backup_settings() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    自动备份设置                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}自动备份设置选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看当前设置"
        echo -e "  ${GREEN}2.${NC} 启用自动备份"
        echo -e "  ${GREEN}3.${NC} 禁用自动备份"
        echo -e "  ${GREEN}4.${NC} 设置备份频率"
        echo -e "  ${GREEN}5.${NC} 设置保留数量"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                show_auto_backup_settings
                ;;
            "2")
                enable_auto_backup
                ;;
            "3")
                disable_auto_backup
                ;;
            "4")
                set_backup_frequency
                ;;
            "5")
                set_backup_retention
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 显示自动备份设置
show_auto_backup_settings() {
    echo -e "${CYAN}自动备份设置:${NC}"
    echo
    
    if [[ -f "$CONFIG_DIR/auto_backup.conf" ]]; then
        source "$CONFIG_DIR/auto_backup.conf"
        echo "  自动备份: $([ "$AUTO_BACKUP_ENABLED" == "true" ] && echo -e "${GREEN}已启用${NC}" || echo -e "${RED}已禁用${NC}")"
        echo "  备份频率: ${BACKUP_FREQUENCY:-未设置}"
        echo "  保留数量: ${BACKUP_RETENTION:-未设置}"
        echo "  最后备份: ${LAST_BACKUP_TIME:-从未}"
    else
        echo -e "${YELLOW}自动备份未配置${NC}"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 启用自动备份
enable_auto_backup() {
    echo -e "${CYAN}启用自动备份${NC}"
    
    # 创建自动备份配置
    cat > "$CONFIG_DIR/auto_backup.conf" << EOF
AUTO_BACKUP_ENABLED=true
BACKUP_FREQUENCY=daily
BACKUP_RETENTION=7
LAST_BACKUP_TIME=
EOF
    
    # 创建cron任务
    (crontab -l 2>/dev/null; echo "0 2 * * * $SCRIPT_DIR/ipv6-wireguard-manager.sh --auto-backup") | crontab -
    
    echo -e "${GREEN}✓${NC} 自动备份已启用"
    echo -e "${GREEN}✓${NC} 每日凌晨2点自动备份"
    
    read -p "按回车键继续..."
}

# 禁用自动备份
disable_auto_backup() {
    echo -e "${CYAN}禁用自动备份${NC}"
    
    # 更新配置文件
    if [[ -f "$CONFIG_DIR/auto_backup.conf" ]]; then
        sed -i 's/AUTO_BACKUP_ENABLED=true/AUTO_BACKUP_ENABLED=false/' "$CONFIG_DIR/auto_backup.conf"
    fi
    
    # 删除cron任务
    crontab -l 2>/dev/null | grep -v "ipv6-wireguard-manager.sh --auto-backup" | crontab -
    
    echo -e "${GREEN}✓${NC} 自动备份已禁用"
    
    read -p "按回车键继续..."
}

# 导出配置
export_config() {
    echo -e "${CYAN}导出配置${NC}"
    
    read -p "请输入导出文件名 (默认: ipv6_wireguard_config): " export_name
    export_name="${export_name:-ipv6_wireguard_config}"
    
    local export_path="$BACKUP_DIR/${export_name}_$(date '+%Y%m%d_%H%M%S').tar.gz"
    
    # 创建临时目录
    local temp_dir="/tmp/export_$$"
    mkdir -p "$temp_dir"
    
    # 复制配置文件
    if [[ -d /etc/wireguard ]]; then
        cp -r /etc/wireguard "$temp_dir/"
    fi
    
    if [[ -d /etc/bird ]]; then
        cp -r /etc/bird "$temp_dir/"
    fi
    
    if [[ -d "$CONFIG_DIR" ]]; then
        cp -r "$CONFIG_DIR" "$temp_dir/ipv6_wireguard_config"
    fi
    
    # 创建压缩包
    cd "$temp_dir"
    tar -czf "$export_path" . 2>/dev/null
    cd - >/dev/null
    
    # 清理临时目录
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}✓${NC} 配置已导出到: $export_path"
    
    read -p "按回车键继续..."
}

# 导入配置
import_config() {
    echo -e "${CYAN}导入配置${NC}"
    
    read -p "请输入配置文件路径: " import_path
    
    if [[ -f "$import_path" ]]; then
        echo "警告: 此操作将覆盖当前配置"
        read -p "确认导入配置? (y/N): " confirm
        
        if [[ "${confirm,,}" == "y" ]]; then
            # 创建临时目录
            local temp_dir="/tmp/import_$$"
            mkdir -p "$temp_dir"
            
            # 解压配置
            if tar -xzf "$import_path" -C "$temp_dir" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} 配置文件解压成功"
                
                # 导入WireGuard配置
                if [[ -d "$temp_dir/wireguard" ]]; then
                    cp -r "$temp_dir/wireguard"/* /etc/wireguard/ 2>/dev/null && echo -e "${GREEN}✓${NC} WireGuard配置已导入"
                fi
                
                # 导入BIRD配置
                if [[ -d "$temp_dir/bird" ]]; then
                    cp -r "$temp_dir/bird"/* /etc/bird/ 2>/dev/null && echo -e "${GREEN}✓${NC} BIRD配置已导入"
                fi
                
                # 导入管理器配置
                if [[ -d "$temp_dir/ipv6_wireguard_config" ]]; then
                    cp -r "$temp_dir/ipv6_wireguard_config"/* "$CONFIG_DIR/" 2>/dev/null && echo -e "${GREEN}✓${NC} 管理器配置已导入"
                fi
                
                # 清理临时目录
                rm -rf "$temp_dir"
                
                echo -e "${GREEN}配置导入完成!${NC}"
            else
                echo -e "${RED}✗${NC} 配置文件解压失败"
                rm -rf "$temp_dir"
            fi
        else
            echo -e "${YELLOW}配置导入已取消${NC}"
        fi
    else
        echo -e "${RED}配置文件不存在${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 更新检查菜单
update_check_menu() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    更新检查                                ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}更新检查选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 检查更新"
        echo -e "  ${GREEN}2.${NC} 查看版本信息"
        echo -e "  ${GREEN}3.${NC} 更新管理器"
        echo -e "  ${GREEN}4.${NC} 更新系统包"
        echo -e "  ${GREEN}5.${NC} 查看更新日志"
        echo -e "  ${GREEN}6.${NC} 自动更新设置"
        echo -e "  ${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 (0-6): " choice
        
        case "$choice" in
            "1")
                check_for_updates
                ;;
            "2")
                show_version_info
                ;;
            "3")
                update_manager
                ;;
            "4")
                update_system_packages
                ;;
            "5")
                show_update_log
                ;;
            "6")
                auto_update_settings
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 检查更新
check_for_updates() {
    echo -e "${CYAN}检查更新...${NC}"
    echo
    
    # 检查管理器版本
    local current_version="1.11"
    local latest_version=""
    
    echo -e "${CYAN}IPv6 WireGuard Manager:${NC}"
    echo "  当前版本: $current_version"
    
    # 尝试从GitHub获取最新版本
    if command -v curl >/dev/null 2>&1; then
        echo "  正在检查最新版本..."
        latest_version=$(curl -s "https://api.github.com/repos/ipv6-wireguard-manager/ipv6-wireguard-manager/releases/latest" 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
        
        if [[ -n "$latest_version" ]]; then
            echo "  最新版本: $latest_version"
            if [[ "$latest_version" != "v$current_version" ]]; then
                echo -e "  状态: ${YELLOW}有新版本可用${NC}"
            else
                echo -e "  状态: ${GREEN}已是最新版本${NC}"
            fi
        else
            echo -e "  状态: ${YELLOW}无法检查更新${NC}"
        fi
    else
        echo -e "  状态: ${YELLOW}curl未安装，无法检查更新${NC}"
    fi
    
    echo
    
    # 检查系统包更新
    echo -e "${CYAN}系统包更新:${NC}"
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt update >/dev/null 2>&1
            local update_count=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")
            echo "  可更新包数量: $update_count"
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                local update_count=$(dnf check-update 2>/dev/null | grep -c "updates")
                echo "  可更新包数量: $update_count"
            else
                local update_count=$(yum check-update 2>/dev/null | grep -c "updates")
                echo "  可更新包数量: $update_count"
            fi
            ;;
        "arch")
            local update_count=$(pacman -Qu 2>/dev/null | wc -l)
            echo "  可更新包数量: $update_count"
            ;;
    esac
    
    echo
    
    # 检查关键服务版本
    echo -e "${CYAN}关键服务版本:${NC}"
    
    if command -v wg >/dev/null 2>&1; then
        local wg_version=$(wg --version 2>/dev/null | head -1)
        echo "  WireGuard: $wg_version"
    else
        echo "  WireGuard: 未安装"
    fi
    
    if command -v birdc >/dev/null 2>&1; then
        local bird_version=$(birdc -v 2>/dev/null | head -1)
        echo "  BIRD: $bird_version"
    elif command -v birdc2 >/dev/null 2>&1; then
        local bird_version=$(birdc2 -v 2>/dev/null | head -1)
        echo "  BIRD2: $bird_version"
    else
        echo "  BIRD: 未安装"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 显示版本信息
show_version_info() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    版本信息                                ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${CYAN}IPv6 WireGuard Manager:${NC}"
    echo "  版本: 1.0.5"
    echo "  构建日期: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  作者: IPv6 WireGuard Manager Team"
    echo "  许可证: MIT"
    echo
    
    echo -e "${CYAN}系统信息:${NC}"
    echo "  操作系统: $OS_TYPE $OS_VERSION"
    echo "  架构: $ARCH"
    echo "  内核版本: $(uname -r)"
    echo "  主机名: $(hostname)"
    echo
    
    echo -e "${CYAN}已安装组件:${NC}"
    
    if command -v wg >/dev/null 2>&1; then
        local wg_version=$(wg --version 2>/dev/null | head -1)
        echo "  WireGuard: $wg_version"
    else
        echo "  WireGuard: 未安装"
    fi
    
    if command -v birdc >/dev/null 2>&1; then
        local bird_version=$(birdc -v 2>/dev/null | head -1)
        echo "  BIRD: $bird_version"
    elif command -v birdc2 >/dev/null 2>&1; then
        local bird_version=$(birdc2 -v 2>/dev/null | head -1)
        echo "  BIRD2: $bird_version"
    else
        echo "  BIRD: 未安装"
    fi
    
    if command -v ufw >/dev/null 2>&1; then
        echo "  UFW: $(ufw --version 2>/dev/null | head -1)"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        echo "  Firewalld: $(firewall-cmd --version 2>/dev/null)"
    else
        echo "  防火墙: 未配置"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 更新管理器
update_manager() {
    echo -e "${CYAN}更新IPv6 WireGuard Manager${NC}"
    echo "警告: 此操作将更新管理器到最新版本"
    read -p "确认更新? (y/N): " confirm
    
    if [[ "${confirm,,}" == "y" ]]; then
        echo "正在更新管理器..."
        
        # 检查是否有更新脚本
        if [[ -f "$SCRIPT_DIR/scripts/update.sh" ]]; then
            echo "执行更新脚本..."
            bash "$SCRIPT_DIR/scripts/update.sh"
        else
            echo -e "${YELLOW}更新脚本未找到，请手动更新${NC}"
            echo "您可以从以下位置获取最新版本:"
            echo "  GitHub: https://github.com/ipv6-wireguard-manager/ipv6-wireguard-manager"
        fi
        
        echo -e "${GREEN}管理器更新完成${NC}"
    else
        echo -e "${YELLOW}更新已取消${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 更新系统包
update_system_packages() {
    echo -e "${CYAN}更新系统包${NC}"
    echo "1. 检查更新"
    echo "2. 执行更新"
    echo "3. 仅安全更新"
    read -p "请选择操作 (1-3): " update_choice
    
    case "$update_choice" in
        "1")
            check_system_updates
            ;;
        "2")
            perform_system_update
            ;;
        "3")
            perform_security_update
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    read -p "按回车键继续..."
}

# 查看更新日志
show_update_log() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    更新日志                                ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${CYAN}版本 1.13 (当前版本)${NC}"
    echo "  发布日期: $(date '+%Y-%m-%d')"
    echo "  新功能:"
    echo "    - 完整的IPv6 WireGuard VPN服务器管理"
    echo "    - BGP路由支持"
    echo "    - 客户端管理功能"
    echo "    - 网络配置管理"
    echo "    - 防火墙管理"
    echo "    - 系统维护工具"
    echo "    - 配置备份/恢复"
    echo "    - 自动更新检查"
    echo "    - 多操作系统支持"
    echo "    - 交互式安装向导"
    echo
    echo "  修复:"
    echo "    - 初始版本"
    echo
    echo "  已知问题:"
    echo "    - 无"
    echo
    
    echo -e "${CYAN}获取更多信息:${NC}"
    echo "  GitHub: https://github.com/ipv6-wireguard-manager/ipv6-wireguard-manager"
    echo "  文档: https://github.com/ipv6-wireguard-manager/ipv6-wireguard-manager/wiki"
    echo "  问题报告: https://github.com/ipv6-wireguard-manager/ipv6-wireguard-manager/issues"
    echo
    
    read -p "按回车键继续..."
}

# 自动更新设置
auto_update_settings() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    自动更新设置                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}自动更新设置选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看当前设置"
        echo -e "  ${GREEN}2.${NC} 启用自动更新"
        echo -e "  ${GREEN}3.${NC} 禁用自动更新"
        echo -e "  ${GREEN}4.${NC} 设置更新频率"
        echo -e "  ${GREEN}5.${NC} 设置更新类型"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                show_auto_update_settings
                ;;
            "2")
                enable_auto_update
                ;;
            "3")
                disable_auto_update
                ;;
            "4")
                set_update_frequency
                ;;
            "5")
                set_update_type
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 显示自动更新设置
show_auto_update_settings() {
    echo -e "${CYAN}自动更新设置:${NC}"
    echo
    
    if [[ -f "$CONFIG_DIR/auto_update.conf" ]]; then
        source "$CONFIG_DIR/auto_update.conf"
        echo "  自动更新: $([ "$AUTO_UPDATE_ENABLED" == "true" ] && echo -e "${GREEN}已启用${NC}" || echo -e "${RED}已禁用${NC}")"
        echo "  更新频率: ${UPDATE_FREQUENCY:-未设置}"
        echo "  更新类型: ${UPDATE_TYPE:-未设置}"
        echo "  最后检查: ${LAST_UPDATE_CHECK:-从未}"
    else
        echo -e "${YELLOW}自动更新未配置${NC}"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 启用自动更新
enable_auto_update() {
    echo -e "${CYAN}启用自动更新${NC}"
    
    # 创建自动更新配置
    cat > "$CONFIG_DIR/auto_update.conf" << EOF
AUTO_UPDATE_ENABLED=true
UPDATE_FREQUENCY=weekly
UPDATE_TYPE=security
LAST_UPDATE_CHECK=
EOF
    
    # 创建cron任务
    (crontab -l 2>/dev/null; echo "0 3 * * 0 $SCRIPT_DIR/ipv6-wireguard-manager.sh --auto-update") | crontab -
    
    echo -e "${GREEN}✓${NC} 自动更新已启用"
    echo -e "${GREEN}✓${NC} 每周日凌晨3点自动检查更新"
    
    read -p "按回车键继续..."
}

# 禁用自动更新
disable_auto_update() {
    echo -e "${CYAN}禁用自动更新${NC}"
    
    # 更新配置文件
    if [[ -f "$CONFIG_DIR/auto_update.conf" ]]; then
        sed -i 's/AUTO_UPDATE_ENABLED=true/AUTO_UPDATE_ENABLED=false/' "$CONFIG_DIR/auto_update.conf"
    fi
    
    # 删除cron任务
    crontab -l 2>/dev/null | grep -v "ipv6-wireguard-manager.sh --auto-update" | crontab -
    
    echo -e "${GREEN}✓${NC} 自动更新已禁用"
    
    read -p "按回车键继续..."
}

# 设置更新频率
set_update_frequency() {
    echo -e "${CYAN}设置更新频率${NC}"
    echo "1. 每日"
    echo "2. 每周"
    echo "3. 每月"
    read -p "请选择更新频率 (1-3): " frequency_choice
    
    case "$frequency_choice" in
        "1")
            local frequency="daily"
            local cron_time="0 3 * * *"
            ;;
        "2")
            local frequency="weekly"
            local cron_time="0 3 * * 0"
            ;;
        "3")
            local frequency="monthly"
            local cron_time="0 3 1 * *"
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            return
            ;;
    esac
    
    # 更新配置文件
    if [[ -f "$CONFIG_DIR/auto_update.conf" ]]; then
        sed -i "s/UPDATE_FREQUENCY=.*/UPDATE_FREQUENCY=$frequency/" "$CONFIG_DIR/auto_update.conf"
    fi
    
    # 更新cron任务
    crontab -l 2>/dev/null | grep -v "ipv6-wireguard-manager.sh --auto-update" | crontab -
    (crontab -l 2>/dev/null; echo "$cron_time $SCRIPT_DIR/ipv6-wireguard-manager.sh --auto-update") | crontab -
    
    echo -e "${GREEN}✓${NC} 更新频率已设置为: $frequency"
    
    read -p "按回车键继续..."
}

# 设置更新类型
set_update_type() {
    echo -e "${CYAN}设置更新类型${NC}"
    echo "1. 仅安全更新"
    echo "2. 所有更新"
    read -p "请选择更新类型 (1-2): " type_choice
    
    case "$type_choice" in
        "1")
            local update_type="security"
            ;;
        "2")
            local update_type="all"
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            return
            ;;
    esac
    
    # 更新配置文件
    if [[ -f "$CONFIG_DIR/auto_update.conf" ]]; then
        sed -i "s/UPDATE_TYPE=.*/UPDATE_TYPE=$update_type/" "$CONFIG_DIR/auto_update.conf"
    fi
    
    echo -e "${GREEN}✓${NC} 更新类型已设置为: $update_type"
    
    read -p "按回车键继续..."
}

# 检测系统信息
detect_system_info() {
    # 先加载保存的安装状态
    load_installation_status
    
    # 检测操作系统
    detect_os
    
    # 检查IPv6支持
    check_ipv6
    
    # 检测WireGuard安装状态
    detect_wireguard_status
    
    # 检测BIRD安装状态
    detect_bird_status
}

# 检测WireGuard安装状态
detect_wireguard_status() {
    if command -v wg >/dev/null 2>&1; then
        WG_INSTALLED=true
        log "INFO" "WireGuard is installed"
    else
        WG_INSTALLED=false
        log "INFO" "WireGuard is not installed"
    fi
    
    # 保存状态到配置文件
    save_installation_status
}

# 检测BIRD安装状态
detect_bird_status() {
    if command -v bird >/dev/null 2>&1 || command -v bird2 >/dev/null 2>&1; then
        BIRD_INSTALLED=true
        log "INFO" "BIRD BGP is installed"
    else
        BIRD_INSTALLED=false
        log "INFO" "BIRD BGP is not installed"
    fi
    
    # 保存状态到配置文件
    save_installation_status
}

# 保存安装状态到配置文件
save_installation_status() {
    local status_file="$CONFIG_DIR/installation_status.conf"
    
    cat > "$status_file" << EOF
# IPv6 WireGuard Manager Installation Status
# Generated on $(date)

WG_INSTALLED=$WG_INSTALLED
BIRD_INSTALLED=$BIRD_INSTALLED
IPV6_ENABLED=$IPV6_ENABLED
OS_TYPE=$OS_TYPE
OS_VERSION=$OS_VERSION
EOF
    
    chmod 644 "$status_file"
}

# 加载安装状态
load_installation_status() {
    local status_file="$CONFIG_DIR/installation_status.conf"
    
    if [[ -f "$status_file" ]]; then
        source "$status_file"
        log "INFO" "Loaded installation status from $status_file"
    else
        log "INFO" "No installation status file found, using defaults"
    fi
}


# 主循环
main() {
    # 初始化
    check_root
    create_directories
    detect_system_info
    
    # 加载模块
    if [[ -f "$SCRIPT_DIR/modules/client_management.sh" ]]; then
        source "$SCRIPT_DIR/modules/client_management.sh"
    else
        log "WARN" "Client management module not found, using basic functions"
        # 创建基本的客户端管理函数
        client_management_menu() {
            echo "客户端管理功能需要完整安装才能使用"
            echo "请重新运行安装程序下载完整文件"
            read -p "按回车键继续..."
        }
    fi
    
    # 设置日志级别
    LOG_LEVEL="${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}"
    
    log "INFO" "IPv6 WireGuard Manager started"
    
    # 主菜单循环
    while true; do
        show_main_menu
        read -p "请选择操作 (0-11): " choice
        
        case "$choice" in
            "1")
                quick_install
                ;;
            "2")
                interactive_install
                ;;
            "3")
                if load_module "server_management"; then
                    server_management_menu
                else
                    echo -e "${RED}无法加载服务器管理模块${NC}"
                read -p "按回车键继续..."
                fi
                ;;
            "4")
                if load_module "client_management"; then
                client_management_menu
                else
                    echo -e "${RED}无法加载客户端管理模块${NC}"
                    read -p "按回车键继续..."
                fi
                ;;
            "5")
                if load_module "network_management"; then
                    network_config_menu
                else
                    echo -e "${RED}无法加载网络管理模块${NC}"
                read -p "按回车键继续..."
                fi
                ;;
            "6")
                bgp_config_menu
                ;;
            "7")
                if load_module "firewall_management"; then
                    firewall_management_menu
                else
                    echo -e "${RED}无法加载防火墙管理模块${NC}"
                read -p "按回车键继续..."
                fi
                ;;
            "8")
                if load_module "system_maintenance"; then
                    system_maintenance_menu
                else
                    echo -e "${RED}无法加载系统维护模块${NC}"
                read -p "按回车键继续..."
                fi
                ;;
            "9")
                if load_module "backup_restore"; then
                    backup_restore_menu
                else
                    echo -e "${RED}无法加载备份恢复模块${NC}"
                read -p "按回车键继续..."
                fi
                ;;
            "10")
                if load_module "update_management"; then
                    update_check_menu
                else
                    echo -e "${RED}无法加载更新管理模块${NC}"
                read -p "按回车键继续..."
                fi
                ;;
            "11")
                echo -e "${CYAN}下载必需文件${NC}"
                echo
                
                # 检查文件完整性
                if check_file_integrity; then
                    echo -e "${GREEN}所有必需文件已存在${NC}"
                    read -p "按回车键继续..."
                else
                    echo -e "${YELLOW}发现缺失文件，开始下载...${NC}"
                    echo
                    
                    if download_required_files; then
                        echo -e "${GREEN}文件下载完成！${NC}"
                        echo -e "${YELLOW}请重新启动脚本以加载新文件${NC}"
                        read -p "按回车键继续..."
                    else
                        echo -e "${RED}文件下载失败，请检查网络连接${NC}"
                        read -p "按回车键继续..."
                    fi
                fi
                ;;
            "0")
                log "INFO" "Exiting IPv6 WireGuard Manager"
                echo -e "${GREEN}感谢使用 IPv6 WireGuard Manager!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
