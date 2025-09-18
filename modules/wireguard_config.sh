#!/bin/bash

# WireGuard配置模块
# 用于配置和管理WireGuard VPN服务器

# 加载公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
fi

# 生成WireGuard密钥对
generate_wireguard_keys() {
    local private_key_file="$1"
    local public_key_file="$2"
    
    if [[ ! -f "$private_key_file" ]]; then
        wg genkey > "$private_key_file"
        chmod 600 "$private_key_file"
    fi
    
    if [[ ! -f "$public_key_file" ]]; then
        wg pubkey < "$private_key_file" > "$public_key_file"
        chmod 644 "$public_key_file"
    fi
    
    echo "Keys generated: $private_key_file, $public_key_file"
}

# 生成预共享密钥
generate_preshared_key() {
    wg genpsk
}

# 创建WireGuard服务器配置
create_wireguard_server_config() {
    local config_file="$1"
    local private_key="$2"
    local listen_port="$3"
    local server_ipv4="$4"
    local server_ipv6="$5"
    local interface="$6"
    
    cat > "$config_file" << EOF
[Interface]
PrivateKey = $private_key
Address = $server_ipv4, $server_ipv6
ListenPort = $listen_port
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $interface -j MASQUERADE
PostUp = ip6tables -A FORWARD -i %i -j ACCEPT; ip6tables -A FORWARD -o %i -j ACCEPT
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $interface -j MASQUERADE
PostDown = ip6tables -D FORWARD -i %i -j ACCEPT; ip6tables -D FORWARD -o %i -j ACCEPT

# 客户端配置将在这里添加
EOF
    
    chmod 600 "$config_file"
    echo "WireGuard server configuration created: $config_file"
}

# 添加客户端到服务器配置
add_client_to_server_config() {
    local config_file="$1"
    local client_name="$2"
    local client_public_key="$3"
    local client_ipv4="$4"
    local client_ipv6="$5"
    local preshared_key="${6:-}"
    
    local client_section=""
    if [[ -n "$preshared_key" ]]; then
        client_section="PresharedKey = $preshared_key"
    fi
    
    cat >> "$config_file" << EOF

[Peer]
# $client_name
PublicKey = $client_public_key
AllowedIPs = $client_ipv4, $client_ipv6
$client_section
EOF
    
    echo "Client $client_name added to server configuration"
}

# 创建客户端配置
create_client_config() {
    local config_file="$1"
    local client_name="$2"
    local client_private_key="$3"
    local client_ipv4="$4"
    local client_ipv6="$5"
    local server_public_key="$6"
    local server_endpoint="$7"
    local server_port="$8"
    local preshared_key="${9:-}"
    
    local preshared_section=""
    if [[ -n "$preshared_key" ]]; then
        preshared_section="PresharedKey = $preshared_key"
    fi
    
    cat > "$config_file" << EOF
[Interface]
PrivateKey = $client_private_key
Address = $client_ipv4, $client_ipv6
DNS = 8.8.8.8, 2001:4860:4860::8888

[Peer]
PublicKey = $server_public_key
Endpoint = $server_endpoint:$server_port
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
$preshared_section
EOF
    
    chmod 600 "$config_file"
    echo "Client configuration created: $config_file"
}

# 生成客户端安装脚本
generate_client_install_script() {
    local script_file="$1"
    local client_name="$2"
    local config_file="$3"
    
    cat > "$script_file" << 'EOF'
#!/bin/bash

# WireGuard客户端安装脚本
# 自动检测系统并安装WireGuard客户端

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# 检测操作系统
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# 安装WireGuard
install_wireguard() {
    local os_type="$1"
    
    log "Installing WireGuard for $os_type..."
    
    case "$os_type" in
        "ubuntu"|"debian")
            apt update
            apt install -y wireguard
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y epel-release
                dnf install -y wireguard-tools
            else
                yum install -y epel-release
                yum install -y wireguard-tools
            fi
            ;;
        "arch")
            pacman -S --noconfirm wireguard-tools
            ;;
        *)
            error "Unsupported operating system: $os_type"
            ;;
    esac
}

# 主安装流程
main() {
    log "Starting WireGuard client installation..."
    
    # 检查root权限
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
    
    # 检测操作系统
    local os_type=$(detect_os)
    log "Detected OS: $os_type"
    
    # 安装WireGuard
    install_wireguard "$os_type"
    
    # 复制配置文件
    if [[ -f "CONFIG_FILE_PLACEHOLDER" ]]; then
        cp "CONFIG_FILE_PLACEHOLDER" /etc/wireguard/wg0.conf
        chmod 600 /etc/wireguard/wg0.conf
        log "Configuration file installed"
    else
        error "Configuration file not found"
    fi
    
    # 启动WireGuard
    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
    
    log "WireGuard client installation completed successfully!"
    log "Connection status:"
    wg show
}

# 运行主函数
main "$@"
EOF
    
    # 替换占位符
    sed -i "s|CONFIG_FILE_PLACEHOLDER|$config_file|g" "$script_file"
    
    chmod +x "$script_file"
    echo "Client install script generated: $script_file"
}

# 生成QR码配置
generate_qr_code() {
    local config_file="$1"
    local qr_file="$2"
    
    if command -v qrencode >/dev/null 2>&1; then
        qrencode -t png -o "$qr_file" < "$config_file"
        echo "QR code generated: $qr_file"
    else
        echo "qrencode not installed, skipping QR code generation"
    fi
}

# 启动WireGuard服务
start_wireguard_service() {
    local interface="$1"
    
    systemctl enable "wg-quick@$interface"
    systemctl start "wg-quick@$interface"
    
    if systemctl is-active "wg-quick@$interface" >/dev/null 2>&1; then
        echo "WireGuard service started successfully"
        return 0
    else
        echo "Failed to start WireGuard service"
        return 1
    fi
}

# 停止WireGuard服务
stop_wireguard_service() {
    local interface="$1"
    
    systemctl stop "wg-quick@$interface"
    systemctl disable "wg-quick@$interface"
    
    echo "WireGuard service stopped"
}

# 重启WireGuard服务
restart_wireguard_service() {
    local interface="$1"
    
    systemctl restart "wg-quick@$interface"
    
    if systemctl is-active "wg-quick@$interface" >/dev/null 2>&1; then
        echo "WireGuard service restarted successfully"
        return 0
    else
        echo "Failed to restart WireGuard service"
        return 1
    fi
}

# 获取WireGuard状态
get_wireguard_status() {
    local interface="$1"
    
    if systemctl is-active "wg-quick@$interface" >/dev/null 2>&1; then
        echo "active"
    else
        echo "inactive"
    fi
}

# 显示WireGuard连接信息
show_wireguard_connections() {
    local interface="$1"
    
    if command -v wg >/dev/null 2>&1; then
        wg show "$interface"
    else
        echo "WireGuard tools not installed"
    fi
}

# 获取客户端统计信息
get_client_stats() {
    local interface="$1"
    
    if command -v wg >/dev/null 2>&1; then
        wg show "$interface" dump | while IFS=$'\t' read -r interface private_key public_key preshared_key endpoint allowed_ips latest_handshake transfer_rx transfer_tx persistent_keepalive; do
            if [[ "$public_key" != "(none)" ]]; then
                echo "Client: $public_key"
                echo "  Endpoint: $endpoint"
                echo "  Allowed IPs: $allowed_ips"
                echo "  Latest Handshake: $latest_handshake"
                echo "  Transfer: RX $transfer_rx, TX $transfer_tx"
                echo "  Keepalive: $persistent_keepalive"
                echo
            fi
        done
    fi
}

# 移除客户端
remove_client() {
    local config_file="$1"
    local client_public_key="$2"
    
    # 创建临时文件
    local temp_file=$(mktemp)
    
    # 复制除了指定客户端之外的所有内容
    awk -v key="$client_public_key" '
    BEGIN { skip = 0 }
    /^\[Peer\]/ { 
        if (skip) skip = 0
        peer_section = 1
    }
    /^PublicKey = / {
        if (peer_section && $3 == key) {
            skip = 1
            peer_section = 0
        }
    }
    !skip { print }
    ' "$config_file" > "$temp_file"
    
    # 替换原文件
    mv "$temp_file" "$config_file"
    
    echo "Client with public key $client_public_key removed"
}

# 更新客户端配置
update_client_config() {
    local config_file="$1"
    local client_public_key="$2"
    local new_allowed_ips="$3"
    
    # 使用sed更新AllowedIPs
    sed -i "/^PublicKey = $client_public_key$/,/^$/ s/^AllowedIPs = .*/AllowedIPs = $new_allowed_ips/" "$config_file"
    
    echo "Client configuration updated"
}

# 备份WireGuard配置
backup_wireguard_config() {
    local backup_dir="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    
    # 备份配置文件
    if [[ -d /etc/wireguard ]]; then
        cp -r /etc/wireguard "$backup_dir/wireguard_$timestamp"
    fi
    
    # 备份客户端配置
    if [[ -d "$CLIENT_CONFIG_DIR" ]]; then
        cp -r "$CLIENT_CONFIG_DIR" "$backup_dir/clients_$timestamp"
    fi
    
    echo "WireGuard configuration backed up to: $backup_dir"
}

# 恢复WireGuard配置
restore_wireguard_config() {
    local backup_dir="$1"
    local timestamp="$2"
    
    if [[ -d "$backup_dir/wireguard_$timestamp" ]]; then
        cp -r "$backup_dir/wireguard_$timestamp"/* /etc/wireguard/
        echo "WireGuard configuration restored from: $backup_dir/wireguard_$timestamp"
    else
        echo "Backup not found: $backup_dir/wireguard_$timestamp"
        return 1
    fi
}
