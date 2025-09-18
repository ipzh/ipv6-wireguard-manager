#!/bin/bash

# IPv6 WireGuard 客户端一键安装脚本
# 版本: 1.13
# 支持 Linux、Windows、macOS、Android、iOS

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
NC='\033[0m'

# 脚本信息
SCRIPT_NAME="IPv6 WireGuard 客户端安装器"
SCRIPT_VERSION="1.11"
SCRIPT_AUTHOR="IPv6 WireGuard Manager Team"

# 配置变量
CLIENT_CONFIG_DIR="$HOME/.config/wireguard"
CLIENT_LOG_DIR="$HOME/.local/log/wireguard"
TEMP_DIR="/tmp/wireguard-client-$$"

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
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "DEBUG")
            echo -e "${BLUE}[DEBUG]${NC} $message"
            ;;
    esac
}

# 错误处理函数
error_exit() {
    log "ERROR" "$1"
    cleanup_temp_files
    exit 1
}

# 清理临时文件
cleanup_temp_files() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log "DEBUG" "Cleaned up temporary directory: $TEMP_DIR"
    fi
}

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                IPv6 WireGuard 客户端安装器                  ║${NC}"
    echo -e "${WHITE}║                    版本: $SCRIPT_VERSION                        ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}此脚本将帮助您安装和配置 WireGuard 客户端${NC}"
    echo -e "${CYAN}支持平台: Linux、Windows、macOS、Android、iOS${NC}"
    echo
}

# 检测操作系统
detect_os() {
    local os_type=""
    local os_version=""
    local arch=""
    
    # 检测架构
    arch=$(uname -m)
    
    # 检测操作系统
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            os_type="$ID"
            os_version="$VERSION_ID"
        elif [[ -f /etc/redhat-release ]]; then
            os_type="rhel"
            os_version=$(cat /etc/redhat-release | sed 's/.*release //' | sed 's/ .*//')
        elif [[ -f /etc/debian_version ]]; then
            os_type="debian"
            os_version=$(cat /etc/debian_version)
        else
            os_type="linux"
            os_version="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="macos"
        os_version=$(sw_vers -productVersion)
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        os_type="windows"
        os_version="unknown"
    else
        os_type="unknown"
        os_version="unknown"
    fi
    
    echo "$os_type|$os_version|$arch"
}

# 检查 WireGuard 是否已安装
check_wireguard_installed() {
    if command -v wg >/dev/null 2>&1; then
        local version=$(wg --version 2>/dev/null || echo "unknown")
        log "INFO" "WireGuard 已安装: $version"
        return 0
    else
        log "INFO" "WireGuard 未安装"
        return 1
    fi
}

# 安装 WireGuard (Linux)
install_wireguard_linux() {
    local os_info="$1"
    local os_type=$(echo "$os_info" | cut -d'|' -f1)
    local os_version=$(echo "$os_info" | cut -d'|' -f2)
    
    log "INFO" "正在安装 WireGuard..."
    
    case "$os_type" in
        "ubuntu"|"debian")
            sudo apt update
            sudo apt install -y wireguard wireguard-tools
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y epel-release
                sudo dnf install -y wireguard-tools
            else
                sudo yum install -y epel-release
                sudo yum install -y wireguard-tools
            fi
            ;;
        "arch")
            sudo pacman -S --noconfirm wireguard-tools
            ;;
        "opensuse"|"sles")
            sudo zypper install -y wireguard-tools
            ;;
        *)
            log "WARN" "不支持的操作系统: $os_type"
            log "INFO" "请手动安装 WireGuard"
            return 1
            ;;
    esac
    
    log "INFO" "WireGuard 安装完成"
}

# 安装 WireGuard (macOS)
install_wireguard_macos() {
    log "INFO" "正在安装 WireGuard..."
    
    # 检查 Homebrew
    if ! command -v brew >/dev/null 2>&1; then
        log "INFO" "正在安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # 安装 WireGuard
    brew install wireguard-tools
    
    log "INFO" "WireGuard 安装完成"
}

# 安装 WireGuard (Windows)
install_wireguard_windows() {
    log "INFO" "Windows 平台安装说明:"
    echo
    echo -e "${YELLOW}1. 下载 WireGuard 客户端:${NC}"
    echo -e "   ${BLUE}https://www.wireguard.com/install/${NC}"
    echo
    echo -e "${YELLOW}2. 运行安装程序并按照提示安装${NC}"
    echo
    echo -e "${YELLOW}3. 安装完成后，请重新运行此脚本${NC}"
    echo
    
    read -p "按回车键继续..."
    return 1
}

# 创建客户端配置目录
create_client_directories() {
    log "INFO" "创建客户端配置目录..."
    
    mkdir -p "$CLIENT_CONFIG_DIR"
    mkdir -p "$CLIENT_LOG_DIR"
    mkdir -p "$TEMP_DIR"
    
    log "INFO" "配置目录: $CLIENT_CONFIG_DIR"
    log "INFO" "日志目录: $CLIENT_LOG_DIR"
}

# 交互式配置客户端
interactive_client_config() {
    local os_info="$1"
    local os_type=$(echo "$os_info" | cut -d'|' -f1)
    
    echo
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                        客户端配置                          ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    # 获取服务器信息
    echo -e "${YELLOW}请输入服务器信息:${NC}"
    read -p "服务器地址 (IP 或域名): " server_endpoint
    read -p "服务器端口 [51820]: " server_port
    server_port="${server_port:-51820}"
    
    # 获取客户端信息
    echo
    echo -e "${YELLOW}请输入客户端信息:${NC}"
    read -p "客户端名称: " client_name
    read -p "IPv4 地址 [10.0.0.2/32]: " client_ipv4
    client_ipv4="${client_ipv4:-10.0.0.2/32}"
    read -p "IPv6 地址 [2001:db8::2/64]: " client_ipv6
    client_ipv6="${client_ipv6:-2001:db8::2/64}"
    
    # 获取密钥信息
    echo
    echo -e "${YELLOW}请输入密钥信息:${NC}"
    read -p "客户端私钥: " client_private_key
    read -p "服务器公钥: " server_public_key
    
    # 生成客户端配置
    generate_client_config "$client_name" "$server_endpoint" "$server_port" "$client_ipv4" "$client_ipv6" "$client_private_key" "$server_public_key"
}

# 从配置文件导入
import_from_config() {
    echo
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                        配置文件导入                          ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}请选择导入方式:${NC}"
    echo -e "  ${GREEN}1.${NC} 从文件导入 (.conf 文件)"
    echo -e "  ${GREEN}2.${NC} 从 QR 码导入"
    echo -e "  ${GREEN}3.${NC} 从剪贴板导入"
    echo -e "  ${GREEN}4.${NC} 手动输入配置"
    echo
    
    read -p "请选择 (1-4): " import_choice
    
    case "$import_choice" in
        "1")
            import_from_file
            ;;
        "2")
            import_from_qr
            ;;
        "3")
            import_from_clipboard
            ;;
        "4")
            return 0  # 返回交互式配置
            ;;
        *)
            log "ERROR" "无效选择"
            return 1
            ;;
    esac
}

# 从文件导入配置
import_from_file() {
    read -p "配置文件路径: " config_file
    
    if [[ ! -f "$config_file" ]]; then
        log "ERROR" "配置文件不存在: $config_file"
        return 1
    fi
    
    local client_name=$(basename "$config_file" .conf)
    cp "$config_file" "$CLIENT_CONFIG_DIR/$client_name.conf"
    
    log "INFO" "配置文件已导入: $CLIENT_CONFIG_DIR/$client_name.conf"
    return 0
}

# 从 QR 码导入配置
import_from_qr() {
    if ! command -v qrencode >/dev/null 2>&1; then
        log "WARN" "qrencode 未安装，无法扫描 QR 码"
        log "INFO" "请手动输入配置或安装 qrencode"
        return 1
    fi
    
    log "INFO" "请使用摄像头扫描 QR 码..."
    # 这里需要实现 QR 码扫描功能
    log "WARN" "QR 码扫描功能暂未实现，请使用其他方式"
    return 1
}

# 从剪贴板导入配置
import_from_clipboard() {
    local os_info="$1"
    local os_type=$(echo "$os_info" | cut -d'|' -f1)
    
    case "$os_type" in
        "linux")
            if command -v xclip >/dev/null 2>&1; then
                local config_content=$(xclip -selection clipboard -o)
            elif command -v xsel >/dev/null 2>&1; then
                local config_content=$(xsel --clipboard --output)
            else
                log "ERROR" "未找到剪贴板工具 (xclip 或 xsel)"
                return 1
            fi
            ;;
        "macos")
            local config_content=$(pbpaste)
            ;;
        "windows")
            # Windows 剪贴板访问需要特殊处理
            log "WARN" "Windows 剪贴板访问暂未实现"
            return 1
            ;;
        *)
            log "ERROR" "不支持的操作系统: $os_type"
            return 1
            ;;
    esac
    
    if [[ -z "$config_content" ]]; then
        log "ERROR" "剪贴板为空"
        return 1
    fi
    
    # 解析配置内容
    local client_name=$(echo "$config_content" | grep -o '\[Interface\]' -A 20 | grep -o 'Name.*' | cut -d'=' -f2 | tr -d ' ' || echo "client")
    echo "$config_content" > "$CLIENT_CONFIG_DIR/$client_name.conf"
    
    log "INFO" "配置已从剪贴板导入: $CLIENT_CONFIG_DIR/$client_name.conf"
    return 0
}

# 生成客户端配置
generate_client_config() {
    local client_name="$1"
    local server_endpoint="$2"
    local server_port="$3"
    local client_ipv4="$4"
    local client_ipv6="$5"
    local client_private_key="$6"
    local server_public_key="$7"
    
    log "INFO" "生成客户端配置: $client_name"
    
    cat > "$CLIENT_CONFIG_DIR/$client_name.conf" << EOF
[Interface]
PrivateKey = $client_private_key
Address = $client_ipv4, $client_ipv6
DNS = 8.8.8.8, 2001:4860:4860::8888

[Peer]
PublicKey = $server_public_key
Endpoint = $server_endpoint:$server_port
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
    
    chmod 600 "$CLIENT_CONFIG_DIR/$client_name.conf"
    
    log "INFO" "客户端配置已生成: $CLIENT_CONFIG_DIR/$client_name.conf"
}

# 启动 WireGuard 客户端
start_wireguard_client() {
    local client_name="$1"
    local os_info="$2"
    local os_type=$(echo "$os_info" | cut -d'|' -f1)
    
    log "INFO" "启动 WireGuard 客户端: $client_name"
    
    case "$os_type" in
        "linux")
            if command -v wg-quick >/dev/null 2>&1; then
                sudo wg-quick up "$client_name"
                log "INFO" "WireGuard 客户端已启动"
            else
                log "ERROR" "wg-quick 命令不可用"
                return 1
            fi
            ;;
        "macos")
            if command -v wg-quick >/dev/null 2>&1; then
                sudo wg-quick up "$client_name"
                log "INFO" "WireGuard 客户端已启动"
            else
                log "ERROR" "wg-quick 命令不可用"
                return 1
            fi
            ;;
        "windows")
            log "INFO" "Windows 平台请使用 WireGuard 图形界面启动客户端"
            ;;
        *)
            log "WARN" "不支持的操作系统: $os_type"
            return 1
            ;;
    esac
}

# 显示客户端状态
show_client_status() {
    local client_name="$1"
    
    echo
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                        客户端状态                          ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    if command -v wg >/dev/null 2>&1; then
        echo -e "${YELLOW}WireGuard 接口状态:${NC}"
        wg show
        echo
    fi
    
    if [[ -f "$CLIENT_CONFIG_DIR/$client_name.conf" ]]; then
        echo -e "${YELLOW}配置文件:${NC} $CLIENT_CONFIG_DIR/$client_name.conf"
        echo -e "${YELLOW}配置内容:${NC}"
        cat "$CLIENT_CONFIG_DIR/$client_name.conf"
    fi
}

# 生成 QR 码
generate_qr_code() {
    local client_name="$1"
    
    if ! command -v qrencode >/dev/null 2>&1; then
        log "WARN" "qrencode 未安装，无法生成 QR 码"
        log "INFO" "请安装 qrencode: sudo apt install qrencode (Ubuntu/Debian)"
        return 1
    fi
    
    if [[ ! -f "$CLIENT_CONFIG_DIR/$client_name.conf" ]]; then
        log "ERROR" "配置文件不存在: $CLIENT_CONFIG_DIR/$client_name.conf"
        return 1
    fi
    
    echo
    echo -e "${CYAN}客户端配置 QR 码:${NC}"
    qrencode -t ansiutf8 < "$CLIENT_CONFIG_DIR/$client_name.conf"
    echo
}

# 主函数
main() {
    # 设置清理函数
    trap cleanup_temp_files EXIT
    
    # 显示欢迎信息
    show_welcome
    
    # 检测操作系统
    local os_info=$(detect_os)
    local os_type=$(echo "$os_info" | cut -d'|' -f1)
    local os_version=$(echo "$os_info" | cut -d'|' -f2)
    local arch=$(echo "$os_info" | cut -d'|' -f3)
    
    log "INFO" "检测到操作系统: $os_type $os_version ($arch)"
    
    # 创建客户端目录
    create_client_directories
    
    # 检查 WireGuard 是否已安装
    if ! check_wireguard_installed; then
        echo
        read -p "WireGuard 未安装，是否现在安装? (y/N): " install_choice
        
        if [[ "${install_choice,,}" == "y" ]]; then
            case "$os_type" in
                "ubuntu"|"debian"|"centos"|"rhel"|"fedora"|"rocky"|"almalinux"|"arch"|"opensuse"|"sles")
                    install_wireguard_linux "$os_info"
                    ;;
                "macos")
                    install_wireguard_macos
                    ;;
                "windows")
                    install_wireguard_windows
                    exit 0
                    ;;
                *)
                    log "ERROR" "不支持的操作系统: $os_type"
                    exit 1
                    ;;
            esac
        else
            log "INFO" "请手动安装 WireGuard 后重新运行此脚本"
            exit 0
        fi
    fi
    
    # 选择配置方式
    echo
    echo -e "${CYAN}请选择配置方式:${NC}"
    echo -e "  ${GREEN}1.${NC} 交互式配置"
    echo -e "  ${GREEN}2.${NC} 从配置文件导入"
    echo -e "  ${GREEN}3.${NC} 从服务器获取配置"
    echo
    
    read -p "请选择 (1-3): " config_choice
    
    local client_name=""
    
    case "$config_choice" in
        "1")
            interactive_client_config "$os_info"
            read -p "客户端名称: " client_name
            ;;
        "2")
            if import_from_config "$os_info"; then
                read -p "客户端名称: " client_name
            else
                interactive_client_config "$os_info"
                read -p "客户端名称: " client_name
            fi
            ;;
        "3")
            log "INFO" "从服务器获取配置功能暂未实现"
            interactive_client_config "$os_info"
            read -p "客户端名称: " client_name
            ;;
        *)
            log "ERROR" "无效选择"
            exit 1
            ;;
    esac
    
    if [[ -z "$client_name" ]]; then
        client_name="client"
    fi
    
    # 启动客户端
    echo
    read -p "是否立即启动 WireGuard 客户端? (y/N): " start_choice
    
    if [[ "${start_choice,,}" == "y" ]]; then
        start_wireguard_client "$client_name" "$os_info"
    fi
    
    # 显示状态
    show_client_status "$client_name"
    
    # 生成 QR 码
    echo
    read -p "是否生成 QR 码? (y/N): " qr_choice
    
    if [[ "${qr_choice,,}" == "y" ]]; then
        generate_qr_code "$client_name"
    fi
    
    echo
    log "INFO" "客户端安装完成!"
    echo -e "${GREEN}配置文件位置: $CLIENT_CONFIG_DIR/$client_name.conf${NC}"
    echo -e "${GREEN}日志文件位置: $CLIENT_LOG_DIR/${NC}"
    echo
    echo -e "${YELLOW}常用命令:${NC}"
    echo -e "  启动: ${BLUE}sudo wg-quick up $client_name${NC}"
    echo -e "  停止: ${BLUE}sudo wg-quick down $client_name${NC}"
    echo -e "  状态: ${BLUE}sudo wg show${NC}"
    echo -e "  日志: ${BLUE}sudo journalctl -u wg-quick@$client_name${NC}"
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

