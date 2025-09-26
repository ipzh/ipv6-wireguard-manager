#!/bin/bash

# WireGuard配置模块
# 负责WireGuard服务器的配置、管理和维护

# WireGuard配置变量
WIREGUARD_CONFIG_DIR="/etc/wireguard"
WIREGUARD_CONFIG_FILE="${WIREGUARD_CONFIG_DIR}/${WIREGUARD_INTERFACE:-wg0}.conf"
WIREGUARD_CLIENT_DIR="${WIREGUARD_CONFIG_DIR}/clients"
WIREGUARD_KEYS_DIR="${WIREGUARD_CONFIG_DIR}/keys"

# 默认配置
DEFAULT_WIREGUARD_CONFIG=(
    "[Interface]"
    "PrivateKey = SERVER_PRIVATE_KEY"
    "Address = 10.0.0.1/24, 2001:db8::1/64"
    "ListenPort = 51820"
    "PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE"
    "PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE"
    ""
    "# Clients will be added here"
)

# 客户端配置模板
CLIENT_CONFIG_TEMPLATE=(
    "[Interface]"
    "PrivateKey = CLIENT_PRIVATE_KEY"
    "Address = CLIENT_IPV4/32, CLIENT_IPV6/128"
    "DNS = 8.8.8.8, 2001:4860:4860::8888"
    ""
    "[Peer]"
    "PublicKey = SERVER_PUBLIC_KEY"
    "Endpoint = SERVER_ENDPOINT"
    "AllowedIPs = 0.0.0.0/0, ::/0"
    "PersistentKeepalive = 25"
)

# 生成WireGuard私钥
generate_wireguard_private_key() {
    if command -v wg &> /dev/null; then
        wg genkey
    else
        # 使用openssl生成私钥（如果wg命令不可用）
        openssl rand -base64 32 | tr -d "=+/" | cut -c1-44
    fi
}

# 生成WireGuard公钥
generate_wireguard_public_key() {
    local private_key="$1"
    if command -v wg &> /dev/null; then
        echo "$private_key" | wg pubkey
    else
        # 使用openssl生成公钥（如果wg命令不可用）
        echo "$private_key" | openssl dgst -sha256 -binary | openssl base64 | tr -d "=+/" | cut -c1-44
    fi
}

# 初始化WireGuard配置
init_wireguard_config() {
    log_info "初始化WireGuard配置..."
    
    # 创建必要的目录
    mkdir -p "$WIREGUARD_CONFIG_DIR" "$WIREGUARD_CLIENT_DIR" "$WIREGUARD_KEYS_DIR"
    
    # 设置目录权限
    chmod 700 "$WIREGUARD_CONFIG_DIR"
    chmod 700 "$WIREGUARD_KEYS_DIR"
    chmod 755 "$WIREGUARD_CLIENT_DIR"
    
    # 生成服务器密钥
    generate_server_keys
    
    # 创建服务器配置
    create_server_config
    
    # 启用IP转发
    enable_ip_forwarding
    
    log_info "WireGuard配置初始化完成"
}

# 生成服务器密钥
generate_server_keys() {
    log_info "生成服务器密钥..."
    
    local private_key_file="${WIREGUARD_KEYS_DIR}/server_private.key"
    local public_key_file="${WIREGUARD_KEYS_DIR}/server_public.key"
    
    # 检查是否已存在密钥
    if [[ -f "$private_key_file" && -f "$public_key_file" ]]; then
        log_info "服务器密钥已存在"
        return 0
    fi
    
    # 生成私钥
    if command -v wg &> /dev/null; then
        wg genkey > "$private_key_file"
        chmod 600 "$private_key_file"
        
        # 生成公钥
        wg pubkey < "$private_key_file" > "$public_key_file"
        chmod 644 "$public_key_file"
        
        log_info "服务器密钥生成完成"
    else
        log_error "WireGuard工具未安装，无法生成密钥"
        return 1
    fi
}

# 创建服务器配置
create_server_config() {
    log_info "创建服务器配置..."
    
    local private_key_file="${WIREGUARD_KEYS_DIR}/server_private.key"
    local public_key_file="${WIREGUARD_KEYS_DIR}/server_public.key"
    
    if [[ ! -f "$private_key_file" ]]; then
        log_error "服务器私钥不存在"
        return 1
    fi
    
    # 读取密钥
    local server_private_key=$(cat "$private_key_file")
    local server_public_key=$(cat "$public_key_file")
    
    # 获取服务器公网IP
    local server_endpoint=$(get_public_ipv4)
    if [[ -z "$server_endpoint" ]]; then
        log_warn "无法获取公网IP，请手动设置"
        server_endpoint="YOUR_SERVER_IP"
    fi
    
    # 创建配置文件
    cat > "$WIREGUARD_CONFIG_FILE" << EOF
[Interface]
PrivateKey = $server_private_key
Address = ${WIREGUARD_NETWORK:-10.0.0.1/24}, ${IPV6_PREFIX:-2001:db8::1/64}
ListenPort = ${WIREGUARD_PORT:-51820}
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ${SYSTEM_INFO["primary_interface"]} -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ${SYSTEM_INFO["primary_interface"]} -j MASQUERADE

# IPv6 forwarding
PostUp = ip6tables -A FORWARD -i %i -j ACCEPT; ip6tables -A FORWARD -o %i -j ACCEPT
PostDown = ip6tables -D FORWARD -i %i -j ACCEPT; ip6tables -D FORWARD -o %i -j ACCEPT

# Clients will be added here
EOF
    
    chmod 600 "$WIREGUARD_CONFIG_FILE"
    
    log_info "服务器配置已创建: $WIREGUARD_CONFIG_FILE"
    log_info "服务器公钥: $server_public_key"
    log_info "服务器端点: $server_endpoint:${WIREGUARD_PORT:-51820}"
}

# 启用IP转发
enable_ip_forwarding() {
    log_info "启用IP转发..."
    
    # 临时启用
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
    
    # 永久启用
    local sysctl_file="/etc/sysctl.conf"
    local ipv4_forward="net.ipv4.ip_forward = 1"
    local ipv6_forward="net.ipv6.conf.all.forwarding = 1"
    
    # 检查IPv4转发配置
    if ! grep -q "$ipv4_forward" "$sysctl_file" 2>/dev/null; then
        echo "$ipv4_forward" >> "$sysctl_file"
        log_info "已添加IPv4转发配置"
    fi
    
    # 检查IPv6转发配置
    if ! grep -q "$ipv6_forward" "$sysctl_file" 2>/dev/null; then
        echo "$ipv6_forward" >> "$sysctl_file"
        log_info "已添加IPv6转发配置"
    fi
    
    # 应用配置
    sysctl -p &>/dev/null || true
    
    log_info "IP转发已启用"
}

# 配置WireGuard
configure_wireguard() {
    log_info "配置WireGuard..."
    
    # 初始化配置
    init_wireguard_config
    
    # 启动服务
    start_wireguard_service
    
    # 启用开机自启
    enable_wireguard_service
    
    log_info "WireGuard配置完成"
}

# 启动WireGuard服务
start_wireguard_service() {
    log_info "启动WireGuard服务..."
    
    local interface="${WIREGUARD_INTERFACE:-wg0}"
    
    # 停止现有服务
    wg-quick down "$interface" 2>/dev/null || true
    
    # 启动服务
    if wg-quick up "$interface"; then
        log_info "WireGuard服务启动成功"
        
        # 检查服务状态
        if wg show "$interface" &>/dev/null; then
            log_info "WireGuard接口 $interface 已激活"
        else
            log_error "WireGuard接口 $interface 激活失败"
            return 1
        fi
    else
        log_error "WireGuard服务启动失败"
        return 1
    fi
}

# 停止WireGuard服务
stop_wireguard_service() {
    log_info "停止WireGuard服务..."
    
    local interface="${WIREGUARD_INTERFACE:-wg0}"
    
    if wg-quick down "$interface"; then
        log_info "WireGuard服务停止成功"
    else
        log_error "WireGuard服务停止失败"
        return 1
    fi
}

# 重启WireGuard服务
restart_wireguard_service() {
    log_info "重启WireGuard服务..."
    
    stop_wireguard_service
    sleep 2
    start_wireguard_service
}

# 启用WireGuard服务
enable_wireguard_service() {
    log_info "启用WireGuard开机自启..."
    
    local interface="${WIREGUARD_INTERFACE:-wg0}"
    
    if command -v systemctl &> /dev/null; then
        systemctl enable "wg-quick@$interface"
        log_info "WireGuard服务已设置为开机自启"
    else
        log_warn "systemctl不可用，无法设置开机自启"
    fi
}

# 禁用WireGuard服务
disable_wireguard_service() {
    log_info "禁用WireGuard开机自启..."
    
    local interface="${WIREGUARD_INTERFACE:-wg0}"
    
    if command -v systemctl &> /dev/null; then
        systemctl disable "wg-quick@$interface"
        log_info "WireGuard服务已禁用开机自启"
    else
        log_warn "systemctl不可用，无法禁用开机自启"
    fi
}

# 添加客户端
add_wireguard_client() {
    local client_name="$1"
    local client_ipv4="$2"
    local client_ipv6="$3"
    
    if [[ -z "$client_name" ]]; then
        log_error "客户端名称不能为空"
        return 1
    fi
    
    log_info "添加WireGuard客户端: $client_name"
    
    # 生成客户端密钥
    local client_private_key=$(wg genkey)
    local client_public_key=$(echo "$client_private_key" | wg pubkey)
    
    # 保存客户端密钥
    echo "$client_private_key" > "${WIREGUARD_KEYS_DIR}/${client_name}_private.key"
    echo "$client_public_key" > "${WIREGUARD_KEYS_DIR}/${client_name}_public.key"
    chmod 600 "${WIREGUARD_KEYS_DIR}/${client_name}_private.key"
    chmod 644 "${WIREGUARD_KEYS_DIR}/${client_name}_public.key"
    
    # 获取服务器公钥和端点
    local server_public_key=$(cat "${WIREGUARD_KEYS_DIR}/server_public.key")
    local server_endpoint=$(get_public_ipv4)
    local server_port="${WIREGUARD_PORT:-51820}"
    
    # 创建客户端配置
    local client_config_file="${WIREGUARD_CLIENT_DIR}/${client_name}.conf"
    cat > "$client_config_file" << EOF
[Interface]
PrivateKey = $client_private_key
Address = $client_ipv4/32, $client_ipv6/128
DNS = 8.8.8.8, 2001:4860:4860::8888

[Peer]
PublicKey = $server_public_key
Endpoint = $server_endpoint:$server_port
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
    
    chmod 600 "$client_config_file"
    
    # 添加客户端到服务器配置
    add_client_to_server_config "$client_name" "$client_public_key" "$client_ipv4" "$client_ipv6"
    
    # 重载配置
    reload_wireguard_config
    
    log_info "客户端 $client_name 添加成功"
    log_info "客户端配置文件: $client_config_file"
    
    return 0
}

# 添加客户端到服务器配置
add_client_to_server_config() {
    local client_name="$1"
    local client_public_key="$2"
    local client_ipv4="$3"
    local client_ipv6="$4"
    
    # 备份原配置
    backup_file "$WIREGUARD_CONFIG_FILE"
    
    # 添加客户端配置到服务器文件
    cat >> "$WIREGUARD_CONFIG_FILE" << EOF

# Client: $client_name
[Peer]
PublicKey = $client_public_key
AllowedIPs = $client_ipv4/32, $client_ipv6/128
EOF
    
    log_info "客户端 $client_name 已添加到服务器配置"
}

# 删除客户端
remove_wireguard_client() {
    local client_name="$1"
    
    if [[ -z "$client_name" ]]; then
        log_error "客户端名称不能为空"
        return 1
    fi
    
    log_info "删除WireGuard客户端: $client_name"
    
    # 备份原配置
    backup_file "$WIREGUARD_CONFIG_FILE"
    
    # 从服务器配置中删除客户端
    local temp_config=$(create_temp_file "wireguard_config")
    grep -v "Client: $client_name" "$WIREGUARD_CONFIG_FILE" | \
    grep -v "PublicKey = $(cat "${WIREGUARD_KEYS_DIR}/${client_name}_public.key" 2>/dev/null)" | \
    grep -v "AllowedIPs = " > "$temp_config"
    
    mv "$temp_config" "$WIREGUARD_CONFIG_FILE"
    
    # 删除客户端文件
    rm -f "${WIREGUARD_KEYS_DIR}/${client_name}_private.key"
    rm -f "${WIREGUARD_KEYS_DIR}/${client_name}_public.key"
    rm -f "${WIREGUARD_CLIENT_DIR}/${client_name}.conf"
    
    # 重载配置
    reload_wireguard_config
    
    log_info "客户端 $client_name 删除成功"
}

# 重载WireGuard配置
reload_wireguard_config() {
    log_info "重载WireGuard配置..."
    
    local interface="${WIREGUARD_INTERFACE:-wg0}"
    
    # 检查配置语法
    if wg-quick strip "$interface" >/dev/null 2>&1; then
        # 重载配置
        wg syncconf "$interface" "$WIREGUARD_CONFIG_FILE"
        log_info "WireGuard配置重载成功"
    else
        log_error "WireGuard配置语法错误"
        return 1
    fi
}

# 生成客户端配置
generate_client_config() {
    local client_name="$1"
    local output_format="${2:-file}"  # file, qr, text
    
    if [[ -z "$client_name" ]]; then
        log_error "客户端名称不能为空"
        return 1
    fi
    
    local client_config_file="${WIREGUARD_CLIENT_DIR}/${client_name}.conf"
    
    if [[ ! -f "$client_config_file" ]]; then
        log_error "客户端配置文件不存在: $client_name"
        return 1
    fi
    
    case "$output_format" in
        "file")
            echo "$client_config_file"
            ;;
        "qr")
            if command -v qrencode &> /dev/null; then
                qrencode -t ansiutf8 < "$client_config_file"
            else
                log_error "qrencode未安装，无法生成QR码"
                return 1
            fi
            ;;
        "text")
            cat "$client_config_file"
            ;;
        *)
            log_error "不支持的输出格式: $output_format"
            return 1
            ;;
    esac
}

# 列出所有客户端
list_wireguard_clients() {
    log_info "WireGuard客户端列表:"
    
    if [[ -d "$WIREGUARD_CLIENT_DIR" ]]; then
        local clients=($(ls "$WIREGUARD_CLIENT_DIR"/*.conf 2>/dev/null | xargs -n 1 basename | sed 's/\.conf$//'))
        
        if [[ ${#clients[@]} -eq 0 ]]; then
            log_info "没有找到客户端"
            return 0
        fi
        
        printf "%-20s %-20s %-20s %-15s\n" "客户端名称" "IPv4地址" "IPv6地址" "状态"
        printf "%-20s %-20s %-20s %-15s\n" "--------------------" "--------------------" "--------------------" "---------------"
        
        for client in "${clients[@]}"; do
            local config_file="${WIREGUARD_CLIENT_DIR}/${client}.conf"
            local ipv4=$(grep "Address = " "$config_file" | awk '{print $2}' | cut -d'/' -f1)
            local ipv6=$(grep "Address = " "$config_file" | awk '{print $3}' | cut -d'/' -f1)
            local status="离线"
            
            # 检查客户端是否在线
            if wg show "${WIREGUARD_INTERFACE:-wg0}" | grep -q "$ipv4"; then
                status="在线"
            fi
            
            printf "%-20s %-20s %-20s %-15s\n" "$client" "$ipv4" "$ipv6" "$status"
        done
    else
        log_info "客户端目录不存在"
    fi
}

# 显示WireGuard状态
show_wireguard_status() {
    log_info "WireGuard状态信息:"
    
    local interface="${WIREGUARD_INTERFACE:-wg0}"
    
    if wg show "$interface" &>/dev/null; then
        echo "接口: $interface"
        echo "状态: 运行中"
        echo
        
        echo "接口信息:"
        wg show "$interface"
        echo
        
        echo "传输统计:"
        wg show "$interface" transfer
        echo
        
        echo "最新握手:"
        wg show "$interface" latest-handshakes
    else
        echo "接口: $interface"
        echo "状态: 未运行"
    fi
}

# 获取下一个可用IP
get_next_available_ip() {
    local network="${WIREGUARD_NETWORK:-10.0.0.0/24}"
    local base_ip=$(echo "$network" | cut -d'/' -f1 | cut -d'.' -f1-3)
    local used_ips=()
    
    # 获取已使用的IP
    if [[ -f "$WIREGUARD_CONFIG_FILE" ]]; then
        while IFS= read -r line; do
            if [[ $line =~ AllowedIPs.*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
                used_ips+=("${BASH_REMATCH[1]}")
            fi
        done < "$WIREGUARD_CONFIG_FILE"
    fi
    
    # 查找下一个可用IP
    for i in {2..254}; do
        local test_ip="$base_ip.$i"
        if ! array_contains "$test_ip" "${used_ips[@]}"; then
            echo "$test_ip"
            return 0
        fi
    done
    
    log_error "没有可用的IP地址"
    return 1
}

# 获取下一个可用IPv6
get_next_available_ipv6() {
    local prefix="${IPV6_PREFIX:-2001:db8::/64}"
    local base_prefix=$(echo "$prefix" | cut -d'/' -f1 | cut -d':' -f1-4)
    local used_ips=()
    
    # 获取已使用的IPv6
    if [[ -f "$WIREGUARD_CONFIG_FILE" ]]; then
        while IFS= read -r line; do
            if [[ $line =~ AllowedIPs.*([0-9a-f:]+) ]]; then
                used_ips+=("${BASH_REMATCH[1]}")
            fi
        done < "$WIREGUARD_CONFIG_FILE"
    fi
    
    # 查找下一个可用IPv6
    for i in {1..ffff}; do
        local test_ipv6="$base_prefix:$i"
        if ! array_contains "$test_ipv6" "${used_ips[@]}"; then
            echo "$test_ipv6"
            return 0
        fi
    done
    
    log_error "没有可用的IPv6地址"
    return 1
}

# 验证WireGuard配置
validate_wireguard_config() {
    local config_file="${1:-$WIREGUARD_CONFIG_FILE}"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在: $config_file"
        return 1
    fi
    
    log_info "验证WireGuard配置: $config_file"
    
    # 检查配置语法
    if wg-quick strip "$(basename "$config_file" .conf)" >/dev/null 2>&1; then
        log_info "配置语法正确"
    else
        log_error "配置语法错误"
        return 1
    fi
    
    # 检查必需字段
    local required_fields=("PrivateKey" "Address" "ListenPort")
    for field in "${required_fields[@]}"; do
        if ! grep -q "^$field = " "$config_file"; then
            log_error "缺少必需字段: $field"
            return 1
        fi
    done
    
    log_info "配置验证通过"
    return 0
}

# 备份WireGuard配置
backup_wireguard_config() {
    local backup_dir="${BACKUP_DIR:-/var/backups/ipv6-wireguard}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${backup_dir}/wireguard_config_${timestamp}.tar.gz"
    
    mkdir -p "$backup_dir"
    
    log_info "备份WireGuard配置到: $backup_file"
    
    tar -czf "$backup_file" -C "$WIREGUARD_CONFIG_DIR" . 2>/dev/null
    
    if [[ -f "$backup_file" ]]; then
        log_info "WireGuard配置备份成功"
        echo "$backup_file"
    else
        log_error "WireGuard配置备份失败"
        return 1
    fi
}

# 恢复WireGuard配置
restore_wireguard_config() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        log_error "备份文件路径不能为空"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "备份文件不存在: $backup_file"
        return 1
    fi
    
    log_info "从备份恢复WireGuard配置: $backup_file"
    
    # 停止服务
    stop_wireguard_service
    
    # 备份当前配置
    backup_wireguard_config
    
    # 恢复配置
    tar -xzf "$backup_file" -C "$WIREGUARD_CONFIG_DIR" 2>/dev/null
    
    # 设置权限
    chmod 700 "$WIREGUARD_CONFIG_DIR"
    chmod 600 "$WIREGUARD_CONFIG_FILE"
    chmod 600 "${WIREGUARD_KEYS_DIR}"/*.key 2>/dev/null || true
    
    # 启动服务
    start_wireguard_service
    
    log_info "WireGuard配置恢复成功"
}

# 导出函数
export -f init_wireguard_config generate_server_keys create_server_config
export -f enable_ip_forwarding configure_wireguard start_wireguard_service
export -f stop_wireguard_service restart_wireguard_service enable_wireguard_service
export -f disable_wireguard_service add_wireguard_client add_client_to_server_config
export -f remove_wireguard_client reload_wireguard_config generate_client_config
export -f list_wireguard_clients show_wireguard_status get_next_available_ip
export -f get_next_available_ipv6 validate_wireguard_config backup_wireguard_config
export -f restore_wireguard_config
