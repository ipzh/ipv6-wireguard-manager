#!/bin/bash

# IPv6 WireGuard VPN Manager - Core Script
# 支持IPv6前缀分发和BGP路由的WireGuard VPN服务器管理工具
# 版本: 1.11
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
FIREWALL_TYPE=""
IPV6_ENABLED=false

# 模块加载函数
load_module() {
    local module_name="$1"
    local module_file="$MODULES_DIR/${module_name}.sh"
    
    # 调试信息
    if [[ "${LOG_LEVEL:-info}" == "debug" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} 尝试加载模块: $module_name"
        echo -e "${BLUE}[DEBUG]${NC} 模块文件路径: $module_file"
        echo -e "${BLUE}[DEBUG]${NC} 模块目录: $MODULES_DIR"
        echo -e "${BLUE}[DEBUG]${NC} 脚本目录: $SCRIPT_DIR"
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

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 控制台输出
    case "$level" in
        "ERROR")
            echo -e "${RED}[$timestamp] [$level] $message${NC}"
            ;;
        "WARN")
            echo -e "${YELLOW}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "INFO")
            echo -e "${GREEN}[$timestamp] [$level] $message${NC}" >&2
            ;;
        *)
            echo -e "[$timestamp] [$level] $message" >&2
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
        "ipv6-wireguard-manager.sh"
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
create_directories() {
    local dirs=("$CONFIG_DIR" "$LOG_DIR" "$BACKUP_DIR" "$CLIENT_CONFIG_DIR" "$TEMP_DIR")
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            if mkdir -p "$dir" 2>/dev/null; then
                log "INFO" "创建目录: $dir"
            else
                log "WARN" "无法创建目录: $dir"
            fi
        fi
    done
}

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root"
    fi
    IS_ROOT=true
}

# 删除重复的 create_directories 函数，使用上面定义的版本

# 检测操作系统
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_TYPE="$ID"
        OS_VERSION="$VERSION_ID"
    elif [[ -f /etc/redhat-release ]]; then
        OS_TYPE="rhel"
        OS_VERSION=$(cat /etc/redhat-release | sed 's/.*release //' | sed 's/ .*//')
    elif [[ -f /etc/debian_version ]]; then
        OS_TYPE="debian"
        OS_VERSION=$(cat /etc/debian_version)
    else
        OS_TYPE="unknown"
        OS_VERSION="unknown"
    fi
    
    ARCH=$(uname -m)
    
    log "INFO" "Detected OS: $OS_TYPE $OS_VERSION ($ARCH)"
}

# 检查IPv6支持
check_ipv6() {
    if [[ -f /proc/net/if_inet6 ]]; then
        IPV6_ENABLED=true
        log "INFO" "IPv6 is supported on this system"
    else
        IPV6_ENABLED=false
        log "WARN" "IPv6 is not supported on this system"
    fi
}

# 检查网络接口
get_network_interfaces() {
    local interfaces=()
    
    # 获取网络接口列表
    if command -v ip >/dev/null 2>&1; then
        while IFS= read -r interface; do
            if [[ "$interface" != "lo" ]]; then
                interfaces+=("$interface")
            fi
        done < <(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' 2>/dev/null)
    else
        # 如果ip命令不可用，使用ifconfig
        if command -v ifconfig >/dev/null 2>&1; then
            while IFS= read -r interface; do
                if [[ "$interface" != "lo" ]]; then
                    interfaces+=("$interface")
                fi
            done < <(ifconfig -a | grep -E "^[a-zA-Z]" | awk '{print $1}' | cut -d: -f1 | grep -v '^lo$' 2>/dev/null)
        else
            # 最后的备选方案
            interfaces=("eth0" "ens33" "enp0s3" "wlan0")
        fi
    fi
    
    # 返回数组
    printf '%s\n' "${interfaces[@]}"
}

# 检查端口占用
is_port_in_use() {
    local port="$1"
    
    if command -v ss >/dev/null 2>&1; then
        if ss -tuln | grep -q ":$port "; then
            return 0  # 端口被占用
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -tuln | grep -q ":$port "; then
            return 0  # 端口被占用
        fi
    fi
    
    return 1  # 端口未被占用
}

# 交互式端口选择
interactive_port_selection() {
    local default_port="$1"
    local port=""
    
    while true; do
        read -p "请输入WireGuard端口 [$default_port]: " port
        port="${port:-$default_port}"
        
        if [[ "$port" =~ ^[0-9]+$ ]] && [[ "$port" -ge 1 ]] && [[ "$port" -le 65535 ]]; then
            if is_port_in_use "$port"; then
                echo -e "${YELLOW}端口 $port 已被占用，请选择其他端口${NC}"
            else
                break
            fi
        else
            echo -e "${RED}请输入有效的端口号 (1-65535)${NC}"
        fi
    done
    
    echo "$port"
}

# 交互式IPv6前缀配置
interactive_ipv6_prefix() {
    local default_prefix="$1"
    local prefix=""
    
    while true; do
        read -p "请输入IPv6前缀 [$default_prefix]: " prefix
        prefix="${prefix:-$default_prefix}"
        
        if [[ "$prefix" =~ ^[0-9a-fA-F:]+/[0-9]+$ ]]; then
            break
        else
            echo -e "${RED}请输入有效的IPv6前缀格式 (如: 2001:db8::/48)${NC}"
        fi
    done
    
    echo "$prefix"
}

# 交互式网络接口选择
interactive_interface_selection() {
    local interfaces=($(get_network_interfaces))
    local selected_interface=""
    
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
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#interfaces[@]} ]]; then
            selected_interface="${interfaces[$((choice-1))]}"
            echo -e "${GREEN}✓${NC} 已选择网络接口: ${selected_interface}"
            break
        else
            echo -e "${RED}错误: 请选择有效的接口编号 (1-${#interfaces[@]})${NC}"
        fi
    done
    
    echo "$selected_interface"
}

# 交互式AS号配置
interactive_as_number() {
    local default_as="$1"
    local as_number=""
    
    while true; do
        read -p "请输入AS号 [$default_as]: " as_number
        as_number="${as_number:-$default_as}"
        
        if [[ "$as_number" =~ ^[0-9]+$ ]] && [[ "$as_number" -ge 1 ]] && [[ "$as_number" -le 4294967295 ]]; then
            break
        else
            echo -e "${RED}请输入有效的AS号 (1-4294967295)${NC}"
        fi
    done
    
    echo "$as_number"
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

# 显示主菜单
show_main_menu() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                IPv6 WireGuard VPN Manager                  ║${NC}"
    echo -e "${WHITE}║                    版本: 1.11                             ║${NC}"
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
    echo -e "  ${GREEN}6.${NC} 防火墙管理"
    echo -e "  ${GREEN}7.${NC} 系统维护"
    echo -e "  ${GREEN}8.${NC} 配置备份/恢复"
    echo -e "  ${GREEN}9.${NC} 更新检查"
    echo -e "  ${GREEN}10.${NC} 下载必需文件"
    echo -e "  ${GREEN}0.${NC} 退出"
    echo
}

# 快速安装模式
quick_install() {
    log "INFO" "Starting quick installation"
    
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
    
    log "INFO" "Quick installation completed successfully"
    echo -e "${GREEN}快速安装完成!${NC}"
}

# 交互式安装模式
interactive_install() {
    log "INFO" "Starting interactive installation"
    
    echo -e "${CYAN}交互式安装向导${NC}"
    echo "此向导将引导您完成IPv6 WireGuard VPN服务器的配置"
    echo
    
    # 获取配置参数
    local wg_port=$(interactive_port_selection "$DEFAULT_WG_PORT")
    local ipv6_prefix=$(interactive_ipv6_prefix "$DEFAULT_IPV6_PREFIX")
    local interface=$(interactive_interface_selection)
    
    # 服务选择
    echo
    read -p "启用BIRD BGP服务? (y/N): " bird_choice
    local enable_bird=false
    [[ "${bird_choice,,}" == "y" ]] && enable_bird=true
    
    echo
    read -p "自动配置防火墙? (y/N): " firewall_choice
    local enable_firewall=false
    [[ "${firewall_choice,,}" == "y" ]] && enable_firewall=true
    
    # 高级配置
    local as_number="$DEFAULT_AS_NUMBER"
    local log_level="$DEFAULT_LOG_LEVEL"
    
    if [[ "$enable_bird" == true ]]; then
        as_number=$(interactive_as_number "$DEFAULT_AS_NUMBER")
    fi
    
    log_level=$(interactive_log_level "$DEFAULT_LOG_LEVEL")
    
    echo
    echo -e "${CYAN}配置摘要:${NC}"
    echo "  WireGuard端口: $wg_port"
    echo "  IPv6前缀: $ipv6_prefix"
    echo "  网络接口: $interface"
    echo "  BIRD BGP: $([ "$enable_bird" == true ] && echo "启用" || echo "禁用")"
    echo "  防火墙配置: $([ "$enable_firewall" == true ] && echo "启用" || echo "禁用")"
    echo "  AS号: $as_number"
    echo "  日志级别: $log_level"
    echo
    
    read -p "确认开始安装? (y/N): " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        echo -e "${YELLOW}安装已取消${NC}"
        return
    fi
    
    # 安装依赖
    install_dependencies
    
    # 配置WireGuard
    configure_wireguard "$wg_port" "$ipv6_prefix" "$interface"
    
    # 配置BIRD（如果启用）
    if [[ "$enable_bird" == true ]]; then
        configure_bird "$as_number"
    fi
    
    # 配置防火墙（如果启用）
    if [[ "$enable_firewall" == true ]]; then
        configure_firewall
    fi
    
    # 启动服务
    start_services
    
    log "INFO" "Interactive installation completed successfully"
    echo -e "${GREEN}交互式安装完成!${NC}"
}

# 安装依赖
install_dependencies() {
    log "INFO" "Installing dependencies"
    
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
    log "INFO" "Installing basic tools"
    
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
    esac
    
    log "INFO" "Basic tools installed successfully"
}

# 安装WireGuard
install_wireguard() {
    log "INFO" "Installing WireGuard"
    
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
    log "INFO" "Installing BIRD BGP daemon"
    
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
    log "INFO" "Installing firewall tools"
    
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

# 删除重复的 configure_wireguard 函数，使用下面定义的更完整版本

# 删除重复的 configure_bird_permissions 函数，使用下面定义的更完整版本

# 删除重复的 configure_bird 函数，使用下面定义的更完整版本

# 配置防火墙
configure_firewall() {
    log "INFO" "Configuring firewall"
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            ufw --force enable
            ufw allow $DEFAULT_WG_PORT/udp
            ufw allow 179/tcp
            FIREWALL_TYPE="ufw"
            log "INFO" "UFW configured"
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            systemctl enable firewalld
            systemctl start firewalld
            firewall-cmd --permanent --add-port=$DEFAULT_WG_PORT/udp
            firewall-cmd --permanent --add-port=179/tcp
            firewall-cmd --reload
            FIREWALL_TYPE="firewalld"
            log "INFO" "Firewalld configured"
            ;;
        "arch")
            systemctl enable firewalld
            systemctl start firewalld
            firewall-cmd --permanent --add-port=$DEFAULT_WG_PORT/udp
            firewall-cmd --permanent --add-port=179/tcp
            firewall-cmd --reload
            FIREWALL_TYPE="firewalld"
            log "INFO" "Firewalld configured"
            ;;
    esac
    
    # 配置iptables规则
    iptables -A FORWARD -i wg0 -j ACCEPT
    iptables -A FORWARD -o wg0 -j ACCEPT
    iptables -t nat -A POSTROUTING -o $interface -j MASQUERADE
    
    log "INFO" "iptables configured"
}

# 安装安全工具
install_security_tools() {
    log "INFO" "Installing security tools"
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt install -y fail2ban
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

# 配置BIRD BGP
configure_bird() {
    local as_number="${1:-$DEFAULT_AS_NUMBER}"
    
    log "INFO" "Configuring BIRD BGP daemon..."
    
    # 检查BIRD是否已安装
    if ! command -v birdc2 >/dev/null 2>&1 && ! command -v birdc >/dev/null 2>&1; then
        log "WARN" "BIRD not installed, skipping BIRD configuration"
        return 0
    fi
    
    # 配置BIRD权限
    configure_bird_permissions
    
    # 创建基本BIRD配置
    create_basic_bird_config "/etc/bird/bird.conf" "10.0.0.1" "$as_number" "$DEFAULT_IPV6_PREFIX"
    
    BIRD_INSTALLED=true
    log "INFO" "BIRD BGP configured successfully"
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

# 基本BIRD配置函数
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

# 配置WireGuard
configure_wireguard() {
    local wg_port="${1:-$DEFAULT_WG_PORT}"
    local ipv6_prefix="${2:-$DEFAULT_IPV6_PREFIX}"
    local interface="${3:-wg0}"
    
    log "INFO" "Configuring WireGuard..."
    
    # 生成服务器密钥
    local server_private_key=$(wg genkey)
    local server_public_key=$(echo "$server_private_key" | wg pubkey)
    
    # 创建WireGuard配置目录
    mkdir -p /etc/wireguard
    
    # 从IPv6前缀中提取服务器地址（使用::1作为服务器地址）
    local network_part=$(echo "$ipv6_prefix" | cut -d'/' -f1)
    if [[ "$network_part" == *"::" ]]; then
        local server_ipv6="${network_part}1/64"
    elif [[ "$network_part" == *":" ]]; then
        local server_ipv6="${network_part}1/64"
    else
        local server_ipv6="${network_part}:1/64"
    fi
    
    # 创建WireGuard配置文件
    cat > "/etc/wireguard/$interface.conf" << EOF
[Interface]
PrivateKey = $server_private_key
Address = 10.0.0.1/24, $server_ipv6
ListenPort = $wg_port
SaveConfig = true

# 启用IPv6转发
PostUp = echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
PostUp = echo 1 > /proc/sys/net/ipv6/conf/%i/forwarding
PostDown = echo 0 > /proc/sys/net/ipv6/conf/all/forwarding
PostDown = echo 0 > /proc/sys/net/ipv6/conf/%i/forwarding

# 防火墙规则
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT
PostUp = ip6tables -A FORWARD -i %i -j ACCEPT; ip6tables -A FORWARD -o %i -j ACCEPT
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT
PostDown = ip6tables -D FORWARD -i %i -j ACCEPT; ip6tables -D FORWARD -o %i -j ACCEPT

# 客户端配置将在这里添加
EOF

    # 设置配置文件权限
    chmod 600 "/etc/wireguard/$interface.conf"
    
    log "INFO" "WireGuard configured successfully"
    log "INFO" "Server public key: $server_public_key"
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
    else
        log "WARN" "No supported firewall found, skipping firewall configuration"
    fi
}

# 启动服务
start_services() {
    log "INFO" "Starting services"
    
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
    
    # 启动BIRD（可选，失败不影响WireGuard）
    if command -v birdc2 >/dev/null 2>&1 || command -v birdc >/dev/null 2>&1; then
        log "INFO" "Attempting to start BIRD service"
        
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
        log "WARN" "BIRD not installed, skipping BIRD service startup"
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

# 主函数
main() {
    # 检查root权限
    check_root
    
    # 创建必要目录
    create_directories
    
    # 检测系统信息
    detect_system_info
    
    # 主循环
    while true; do
        show_main_menu
        read -p "请选择操作 (0-10): " choice
        
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
                if load_module "firewall_management"; then
                    firewall_management_menu
                else
                    echo -e "${RED}无法加载防火墙管理模块${NC}"
                    read -p "按回车键继续..."
                fi
                ;;
            "7")
                if load_module "system_maintenance"; then
                    system_maintenance_menu
                else
                    echo -e "${RED}无法加载系统维护模块${NC}"
                    read -p "按回车键继续..."
                fi
                ;;
            "8")
                if load_module "backup_restore"; then
                    backup_restore_menu
                else
                    echo -e "${RED}无法加载备份恢复模块${NC}"
                    read -p "按回车键继续..."
                fi
                ;;
            "9")
                if load_module "update_management"; then
                    update_check_menu
                else
                    echo -e "${RED}无法加载更新管理模块${NC}"
                    read -p "按回车键继续..."
                fi
                ;;
            "10")
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
