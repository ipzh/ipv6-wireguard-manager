#!/bin/bash

# 系统检测模块
# 用于检测系统环境、网络配置和依赖项

# 检测系统架构
detect_architecture() {
    local arch=$(uname -m)
    case "$arch" in
        "x86_64")
            echo "amd64"
            ;;
        "i386"|"i686")
            echo "i386"
            ;;
        "aarch64"|"arm64")
            echo "arm64"
            ;;
        "armv7l")
            echo "armhf"
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

# 检测包管理器
detect_package_manager() {
    if command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# 检测防火墙类型
detect_firewall() {
    if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
        echo "ufw"
    elif command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active firewalld >/dev/null 2>&1; then
        echo "firewalld"
    elif command -v nft >/dev/null 2>&1; then
        echo "nftables"
    elif command -v iptables >/dev/null 2>&1; then
        echo "iptables"
    else
        echo "none"
    fi
}

# 检测网络管理器
detect_network_manager() {
    if systemctl is-active NetworkManager >/dev/null 2>&1; then
        echo "NetworkManager"
    elif systemctl is-active systemd-networkd >/dev/null 2>&1; then
        echo "systemd-networkd"
    elif command -v ifupdown >/dev/null 2>&1; then
        echo "ifupdown"
    else
        echo "unknown"
    fi
}

# 检测IPv6支持
check_ipv6_support() {
    local ipv6_support=false
    
    # 检查内核支持
    if [[ -f /proc/net/if_inet6 ]]; then
        ipv6_support=true
    fi
    
    # 检查是否有IPv6地址
    if ip -6 addr show | grep -q "inet6"; then
        ipv6_support=true
    fi
    
    echo "$ipv6_support"
}

# 检测公网IP
get_public_ip() {
    local public_ip=""
    
    # 尝试多个服务获取公网IP
    local services=(
        "https://ipv4.icanhazip.com"
        "https://api.ipify.org"
        "https://checkip.amazonaws.com"
        "https://ifconfig.me/ip"
    )
    
    for service in "${services[@]}"; do
        if command -v curl >/dev/null 2>&1; then
            public_ip=$(curl -s --connect-timeout 5 --max-time 10 "$service" 2>/dev/null | tr -d '\n\r')
        elif command -v wget >/dev/null 2>&1; then
            public_ip=$(wget -qO- --timeout=10 "$service" 2>/dev/null | tr -d '\n\r')
        fi
        
        if [[ -n "$public_ip" ]] && [[ "$public_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "$public_ip"
            return 0
        fi
    done
    
    echo ""
}

# 检测IPv6公网地址
get_public_ipv6() {
    local public_ipv6=""
    
    # 尝试获取IPv6公网地址
    if command -v curl >/dev/null 2>&1; then
        public_ipv6=$(curl -s --connect-timeout 5 --max-time 10 "https://ipv6.icanhazip.com" 2>/dev/null | tr -d '\n\r')
    elif command -v wget >/dev/null 2>&1; then
        public_ipv6=$(wget -qO- --timeout=10 "https://ipv6.icanhazip.com" 2>/dev/null | tr -d '\n\r')
    fi
    
    if [[ -n "$public_ipv6" ]] && [[ "$public_ipv6" =~ ^[0-9a-fA-F:]+$ ]]; then
        echo "$public_ipv6"
    else
        echo ""
    fi
}

# 检测网络接口
get_network_interfaces() {
    local interfaces=()
    
    # 获取所有网络接口
    while IFS= read -r interface; do
        if [[ "$interface" != "lo" ]] && [[ -n "$interface" ]]; then
            interfaces+=("$interface")
        fi
    done < <(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$')
    
    printf '%s\n' "${interfaces[@]}"
}

# 获取默认网关接口
get_default_interface() {
    local default_interface=""
    
    if command -v ip >/dev/null 2>&1; then
        default_interface=$(ip route | grep default | awk '{print $5}' | head -1)
    elif command -v route >/dev/null 2>&1; then
        default_interface=$(route -n | grep '^0.0.0.0' | awk '{print $8}' | head -1)
    fi
    
    echo "$default_interface"
}

# 检测端口占用
check_port_usage() {
    local port="$1"
    local protocol="${2:-udp}"
    local pid=""
    
    if command -v ss >/dev/null 2>&1; then
        pid=$(ss -${protocol:0:1}lnp | grep ":$port " | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2 | head -1)
    elif command -v netstat >/dev/null 2>&1; then
        pid=$(netstat -${protocol:0:1}lnp | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | head -1)
    fi
    
    if [[ -n "$pid" ]] && [[ "$pid" != "-" ]]; then
        echo "$pid"
    else
        echo ""
    fi
}

# 检测进程信息
get_process_info() {
    local pid="$1"
    
    if [[ -n "$pid" ]] && [[ -d "/proc/$pid" ]]; then
        local cmdline=$(cat "/proc/$pid/cmdline" 2>/dev/null | tr '\0' ' ')
        local exe=$(readlink "/proc/$pid/exe" 2>/dev/null)
        
        echo "PID: $pid"
        echo "Command: $cmdline"
        echo "Executable: $exe"
    else
        echo "Process not found"
    fi
}

# 检测系统资源
check_system_resources() {
    local cpu_cores=$(nproc)
    local total_memory=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    local available_memory=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    local disk_usage=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
    
    echo "CPU Cores: $cpu_cores"
    echo "Total Memory: ${total_memory}MB"
    echo "Available Memory: ${available_memory}MB"
    echo "Disk Usage: ${disk_usage}%"
}

# 检测服务状态
check_service_status() {
    local service="$1"
    
    if systemctl is-active "$service" >/dev/null 2>&1; then
        echo "active"
    elif systemctl is-enabled "$service" >/dev/null 2>&1; then
        echo "enabled"
    else
        echo "inactive"
    fi
}

# 检测已安装的软件包
check_installed_packages() {
    local packages=("$@")
    local installed=()
    local missing=()
    
    for package in "${packages[@]}"; do
        case "$(detect_package_manager)" in
            "apt")
                if dpkg -l | grep -q "^ii  $package "; then
                    installed+=("$package")
                else
                    missing+=("$package")
                fi
                ;;
            "dnf"|"yum")
                if rpm -q "$package" >/dev/null 2>&1; then
                    installed+=("$package")
                else
                    missing+=("$package")
                fi
                ;;
            "pacman")
                if pacman -Q "$package" >/dev/null 2>&1; then
                    installed+=("$package")
                else
                    missing+=("$package")
                fi
                ;;
        esac
    done
    
    echo "INSTALLED:${installed[*]}"
    echo "MISSING:${missing[*]}"
}

# 检测内核版本
get_kernel_version() {
    uname -r
}

# 检测系统负载
get_system_load() {
    uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'
}

# 检测系统运行时间
get_system_uptime() {
    uptime -p
}

# 生成系统报告
generate_system_report() {
    local report_file="$1"
    
    cat > "$report_file" << EOF
# 系统检测报告
生成时间: $(date)
主机名: $(hostname)
操作系统: $OS_TYPE $OS_VERSION
架构: $(detect_architecture)
内核版本: $(get_kernel_version)
包管理器: $(detect_package_manager)
防火墙: $(detect_firewall)
网络管理器: $(detect_network_manager)

## 网络配置
IPv6支持: $(check_ipv6_support)
公网IPv4: $(get_public_ip)
公网IPv6: $(get_public_ipv6)
默认接口: $(get_default_interface)

## 系统资源
$(check_system_resources)
系统负载: $(get_system_load)
运行时间: $(get_system_uptime)

## 网络接口
$(get_network_interfaces | sed 's/^/- /')

## 服务状态
WireGuard: $(check_service_status wg-quick@wg0)
BIRD: $(check_service_status bird)
EOF
}
