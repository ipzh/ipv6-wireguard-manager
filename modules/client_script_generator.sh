#!/bin/bash

# IPv6 WireGuard 客户端脚本生成器
# 版本: 1.11
# 用于生成预配置的客户端安装脚本

set -euo pipefail

# 加载公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
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

# 日志函数
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "INFO")
            echo -e "${GREEN}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "DEBUG")
            echo -e "${BLUE}[$timestamp] [$level] $message${NC}" >&2
            ;;
        *)
            echo -e "[$timestamp] [$level] $message"
            ;;
    esac
}

# 生成客户端安装包
generate_client_installer() {
    local client_name="$1"
    local server_endpoint="$2"
    local server_port="$3"
    local client_ipv4="$4"
    local client_ipv6="$5"
    local client_private_key="$6"
    local server_public_key="$7"
    local output_dir="$8"
    
    log "INFO" "生成客户端安装包: $client_name"
    
    # 创建输出目录
    mkdir -p "$output_dir"
    
    # 生成 Linux 客户端脚本
    generate_linux_client_script "$client_name" "$server_endpoint" "$server_port" "$client_ipv4" "$client_ipv6" "$client_private_key" "$server_public_key" "$output_dir"
    
    # 生成 Windows 客户端脚本
    generate_windows_client_script "$client_name" "$server_endpoint" "$server_port" "$client_ipv4" "$client_ipv6" "$client_private_key" "$server_public_key" "$output_dir"
    
    # 生成配置文件
    generate_client_config "$client_name" "$server_endpoint" "$server_port" "$client_ipv4" "$client_ipv6" "$client_private_key" "$server_public_key" "$output_dir"
    
    # 生成更新配置
    generate_client_update_config "$client_name" "$server_endpoint" "$output_dir"
    
    # 生成 QR 码
    generate_client_qr_code "$client_name" "$output_dir"
    
    # 生成安装说明
    generate_installation_guide "$client_name" "$output_dir"
    
    log "INFO" "客户端安装包已生成: $output_dir"
}

# 生成 Linux/Unix 客户端脚本
generate_linux_client_script() {
    local client_name="$1"
    local server_endpoint="$2"
    local server_port="$3"
    local client_ipv4="$4"
    local client_ipv6="$5"
    local client_private_key="$6"
    local server_public_key="$7"
    local output_dir="$8"
    
    local script_file="$output_dir/install-linux.sh"
    
    cat > "$script_file" << 'LINUX_SCRIPT_END'
#!/bin/bash

# IPv6 WireGuard 客户端自动安装脚本
# 此脚本已预配置服务器信息，直接运行即可

set -euo pipefail

# 预配置的服务器信息
SERVER_ENDPOINT="SERVER_ENDPOINT_PLACEHOLDER"
SERVER_PORT="SERVER_PORT_PLACEHOLDER"
CLIENT_NAME="CLIENT_NAME_PLACEHOLDER"
CLIENT_IPV4="CLIENT_IPV4_PLACEHOLDER"
CLIENT_IPV6="CLIENT_IPV6_PLACEHOLDER"
CLIENT_PRIVATE_KEY="CLIENT_PRIVATE_KEY_PLACEHOLDER"
SERVER_PUBLIC_KEY="SERVER_PUBLIC_KEY_PLACEHOLDER"

# 配置目录
CLIENT_CONFIG_DIR="$HOME/.config/wireguard"
CLIENT_LOG_DIR="$HOME/.local/log/wireguard"

# 日志函数已在文件开头定义，此处删除重复定义

# 错误处理函数
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                IPv6 WireGuard 客户端自动安装                ║${NC}"
    echo -e "${WHITE}║                    客户端: $CLIENT_NAME                        ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}此脚本将自动安装和配置 WireGuard 客户端${NC}"
    echo -e "${CYAN}服务器: $SERVER_ENDPOINT:$SERVER_PORT${NC}"
    echo -e "${CYAN}客户端: $CLIENT_NAME${NC}"
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

# 安装 WireGuard
install_wireguard() {
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

# 创建客户端配置目录
create_client_directories() {
    log "INFO" "创建客户端配置目录..."
    
    mkdir -p "$CLIENT_CONFIG_DIR"
    mkdir -p "$CLIENT_LOG_DIR"
    
    log "INFO" "配置目录: $CLIENT_CONFIG_DIR"
    log "INFO" "日志目录: $CLIENT_LOG_DIR"
}

# 生成客户端配置
generate_client_config() {
    log "INFO" "生成客户端配置: $CLIENT_NAME"
    
    cat > "$CLIENT_CONFIG_DIR/$CLIENT_NAME.conf" << CONFIG_END
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IPV4, $CLIENT_IPV6
DNS = 8.8.8.8, 2001:4860:4860::8888

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_ENDPOINT:$SERVER_PORT
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
CONFIG_END
    
    chmod 600 "$CLIENT_CONFIG_DIR/$CLIENT_NAME.conf"
    
    log "INFO" "客户端配置已生成: $CLIENT_CONFIG_DIR/$CLIENT_NAME.conf"
}

# 启动 WireGuard 客户端
start_wireguard() {
    log "INFO" "启动 WireGuard 客户端..."
    
    if command -v wg-quick >/dev/null 2>&1; then
        sudo wg-quick up "$CLIENT_NAME"
        log "INFO" "WireGuard 客户端已启动"
    else
        log "ERROR" "wg-quick 命令未找到"
        return 1
    fi
}

# 显示连接状态
show_status() {
    echo
    echo -e "${CYAN}WireGuard 客户端状态:${NC}"
    
    if command -v wg >/dev/null 2>&1; then
        wg show
    else
        echo -e "${RED}WireGuard 未安装${NC}"
    fi
    
    echo
    echo -e "${CYAN}配置文件位置:${NC}"
    echo -e "  $CLIENT_CONFIG_DIR/$CLIENT_NAME.conf"
    
    echo
    echo -e "${CYAN}日志文件位置:${NC}"
    echo -e "  $CLIENT_LOG_DIR/"
    
    echo
    echo -e "${CYAN}管理命令:${NC}"
    echo -e "  启动: ${YELLOW}sudo wg-quick up $CLIENT_NAME${NC}"
    echo -e "  停止: ${YELLOW}sudo wg-quick down $CLIENT_NAME${NC}"
    echo -e "  状态: ${YELLOW}wg show${NC}"
    echo -e "  日志: ${YELLOW}journalctl -u wg-quick@$CLIENT_NAME${NC}"
}

# 主函数
main() {
    show_welcome
    
    # 检测操作系统
    local os_info=$(detect_os)
    log "INFO" "检测到操作系统: $os_info"
    
    # 检查 WireGuard 是否已安装
    if ! check_wireguard_installed; then
        # 安装 WireGuard
        install_wireguard "$os_info"
    fi
    
    # 创建配置目录
    create_client_directories
    
    # 生成客户端配置
    generate_client_config
    
    # 启动 WireGuard
    if start_wireguard; then
        show_status
        echo
        echo -e "${GREEN}WireGuard 客户端安装和配置完成!${NC}"
    else
        echo
        echo -e "${YELLOW}WireGuard 客户端配置完成，但启动失败${NC}"
        echo -e "${YELLOW}请手动运行: sudo wg-quick up $CLIENT_NAME${NC}"
    fi
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
LINUX_SCRIPT_END

    # 替换占位符
    sed -i "s/SERVER_ENDPOINT_PLACEHOLDER/$server_endpoint/g" "$script_file"
    sed -i "s/SERVER_PORT_PLACEHOLDER/$server_port/g" "$script_file"
    sed -i "s/CLIENT_NAME_PLACEHOLDER/$client_name/g" "$script_file"
    sed -i "s/CLIENT_IPV4_PLACEHOLDER/$client_ipv4/g" "$script_file"
    sed -i "s/CLIENT_IPV6_PLACEHOLDER/$client_ipv6/g" "$script_file"
    sed -i "s/CLIENT_PRIVATE_KEY_PLACEHOLDER/$client_private_key/g" "$script_file"
    sed -i "s/SERVER_PUBLIC_KEY_PLACEHOLDER/$server_public_key/g" "$script_file"
    
    chmod +x "$script_file"
    log "INFO" "Linux 客户端脚本已生成: $script_file"
}

# 生成 Windows 客户端脚本
generate_windows_client_script() {
    local client_name="$1"
    local server_endpoint="$2"
    local server_port="$3"
    local client_ipv4="$4"
    local client_ipv6="$5"
    local client_private_key="$6"
    local server_public_key="$7"
    local output_dir="$8"
    
    local script_file="$output_dir/install-windows.ps1"
    
    cat > "$script_file" << 'WINDOWS_SCRIPT_END'
# IPv6 WireGuard 客户端自动安装脚本 (Windows PowerShell)
# 版本: 1.11
# 支持 Windows 10/11

param(
    [string]$ConfigFile = "",
    [string]$ClientName = "client",
    [switch]$SkipInstall = $false,
    [switch]$Help = $false
)

# 颜色定义
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"
$White = "White"

# 预配置的服务器信息
$SERVER_ENDPOINT = "SERVER_ENDPOINT_PLACEHOLDER"
$SERVER_PORT = "SERVER_PORT_PLACEHOLDER"
$CLIENT_NAME = "CLIENT_NAME_PLACEHOLDER"
$CLIENT_IPV4 = "CLIENT_IPV4_PLACEHOLDER"
$CLIENT_IPV6 = "CLIENT_IPV6_PLACEHOLDER"
$CLIENT_PRIVATE_KEY = "CLIENT_PRIVATE_KEY_PLACEHOLDER"
$SERVER_PUBLIC_KEY = "SERVER_PUBLIC_KEY_PLACEHOLDER"

# 配置目录
$ClientConfigDir = "$env:USERPROFILE\.config\wireguard"
$ClientLogDir = "$env:USERPROFILE\.local\log\wireguard"

# 日志函数
function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    switch ($Level) {
        "ERROR" {
            Write-Host "[$timestamp] [ERROR] $Message" -ForegroundColor $Red
        }
        "WARN" {
            Write-Host "[$timestamp] [WARN] $Message" -ForegroundColor $Yellow
        }
        "INFO" {
            Write-Host "[$timestamp] [INFO] $Message" -ForegroundColor $Green
        }
        "DEBUG" {
            Write-Host "[$timestamp] [DEBUG] $Message" -ForegroundColor $Blue
        }
        default {
            Write-Host "[$timestamp] [$Level] $Message"
        }
    }
}

# 生成客户端配置
function New-ClientConfig {
    Write-Log "INFO" "生成客户端配置: $CLIENT_NAME"
    
    $configContent = @"
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IPV4, $CLIENT_IPV6
DNS = 8.8.8.8, 2001:4860:4860::8888

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_ENDPOINT`:$SERVER_PORT
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
"@
    
    $configFile = "$ClientConfigDir\$CLIENT_NAME.conf"
    $configContent | Out-File -FilePath $configFile -Encoding UTF8
    
    Write-Log "INFO" "客户端配置已生成: $configFile"
}

# 主函数
function Main {
    Write-Log "INFO" "开始 WireGuard 客户端安装..."
    
    # 创建配置目录
    if (-not (Test-Path $ClientConfigDir)) {
        New-Item -ItemType Directory -Path $ClientConfigDir -Force | Out-Null
    }
    
    # 生成客户端配置
    New-ClientConfig
    
    Write-Log "INFO" "WireGuard 客户端配置完成!"
}

# 脚本入口点
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
WINDOWS_SCRIPT_END

    # 替换占位符
    sed -i "s/SERVER_ENDPOINT_PLACEHOLDER/$server_endpoint/g" "$script_file"
    sed -i "s/SERVER_PORT_PLACEHOLDER/$server_port/g" "$script_file"
    sed -i "s/CLIENT_NAME_PLACEHOLDER/$client_name/g" "$script_file"
    sed -i "s/CLIENT_IPV4_PLACEHOLDER/$client_ipv4/g" "$script_file"
    sed -i "s/CLIENT_IPV6_PLACEHOLDER/$client_ipv6/g" "$script_file"
    sed -i "s/CLIENT_PRIVATE_KEY_PLACEHOLDER/$client_private_key/g" "$script_file"
    sed -i "s/SERVER_PUBLIC_KEY_PLACEHOLDER/$server_public_key/g" "$script_file"
    
    log "INFO" "Windows 客户端脚本已生成: $script_file"
}

# 生成客户端配置文件
generate_client_config() {
    local client_name="$1"
    local server_endpoint="$2"
    local server_port="$3"
    local client_ipv4="$4"
    local client_ipv6="$5"
    local client_private_key="$6"
    local server_public_key="$7"
    local output_dir="$8"
    
    local config_file="$output_dir/$client_name.conf"
    
    cat > "$config_file" << CONFIG_FILE_END
[Interface]
PrivateKey = $client_private_key
Address = $client_ipv4, $client_ipv6
DNS = 8.8.8.8, 2001:4860:4860::8888

[Peer]
PublicKey = $server_public_key
Endpoint = $server_endpoint:$server_port
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
CONFIG_FILE_END
    
    chmod 600 "$config_file"
    log "INFO" "客户端配置文件已生成: $config_file"
}

# 生成客户端更新配置
generate_client_update_config() {
    local client_name="$1"
    local server_endpoint="$2"
    local output_dir="$3"
    
    local update_config_file="$output_dir/update.conf"
    
    cat > "$update_config_file" << UPDATE_CONFIG_END
CLIENT_NAME=$client_name
UPDATE_SERVER_URL=http://$server_endpoint:8000
UPDATE_CHECK_INTERVAL=3600
AUTO_UPDATE_ENABLED=true
UPDATE_LOG_FILE=\$HOME/.local/log/wireguard/update.log
UPDATE_CONFIG_END
    
    chmod 644 "$update_config_file"
    log "INFO" "客户端更新配置已生成: $update_config_file"
}

# 生成客户端 QR 码
generate_client_qr_code() {
    local client_name="$1"
    local output_dir="$2"
    
    local config_file="$output_dir/$client_name.conf"
    local qr_file="$output_dir/$client_name.png"
    
    if command -v qrencode >/dev/null 2>&1; then
        qrencode -t png -o "$qr_file" < "$config_file"
        log "INFO" "客户端 QR 码已生成: $qr_file"
    else
        log "WARN" "qrencode 未安装，跳过 QR 码生成"
    fi
}

# 生成安装说明
generate_installation_guide() {
    local client_name="$1"
    local output_dir="$2"
    
    local guide_file="$output_dir/README.md"
    
    cat > "$guide_file" << GUIDE_END
# IPv6 WireGuard 客户端安装包

## 客户端信息
- **客户端名称**: $client_name
- **生成时间**: $(date '+%Y-%m-%d %H:%M:%S')

## 文件说明
- \`install-linux.sh\` - Linux/Unix/macOS 自动安装脚本
- \`install-windows.ps1\` - Windows 自动安装脚本
- \`$client_name.conf\` - WireGuard 客户端配置文件
- \`update.conf\` - 自动更新配置文件
- \`$client_name.png\` - 移动设备 QR 码 (如果可用)
- \`README.md\` - 本说明文件

## 安装方法

### Linux/Unix/macOS
\`\`\`bash
# 给脚本执行权限
chmod +x install-linux.sh

# 运行安装脚本
./install-linux.sh
\`\`\`

### Windows
\`\`\`powershell
# 以管理员身份运行 PowerShell
.\install-windows.ps1
\`\`\`

### 移动设备 (Android/iOS)
1. 安装 WireGuard 应用
2. 扫描 QR 码或导入配置文件
3. 连接 VPN

## 技术支持

如需技术支持，请联系管理员。
GUIDE_END

    log "INFO" "安装说明已生成: $guide_file"
}

# 主函数
main() {
    if [[ $# -lt 8 ]]; then
        echo "用法: $0 <client_name> <server_endpoint> <server_port> <client_ipv4> <client_ipv6> <client_private_key> <server_public_key> <output_dir>"
        exit 1
    fi
    
    generate_client_installer "$@"
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
