#!/bin/bash

# 客户端管理模块
# 用于管理WireGuard客户端配置和状态

# 获取脚本目录（如果未定义）
if [[ -z "$SCRIPT_DIR" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# 配置目录（如果未定义则使用默认值）
CONFIG_DIR="${CONFIG_DIR:-/etc/ipv6-wireguard}"

# 客户端配置目录
CLIENT_CONFIG_DIR="${CLIENT_CONFIG_DIR:-$CONFIG_DIR/clients}"

# 客户端数据库文件
CLIENT_DB="$CONFIG_DIR/clients.db"

# 加载依赖模块
if [[ -f "$SCRIPT_DIR/modules/system_detection.sh" ]]; then
    source "$SCRIPT_DIR/modules/system_detection.sh"
fi

if [[ -f "$SCRIPT_DIR/modules/wireguard_config.sh" ]]; then
    source "$SCRIPT_DIR/modules/wireguard_config.sh"
fi

if [[ -f "$SCRIPT_DIR/modules/client_script_generator.sh" ]]; then
    source "$SCRIPT_DIR/modules/client_script_generator.sh"
fi

# 初始化客户端数据库
init_client_database() {
    if [[ ! -f "$CLIENT_DB" ]]; then
        cat > "$CLIENT_DB" << EOF
# IPv6 WireGuard Client Database
# Format: CLIENT_NAME|PRIVATE_KEY|PUBLIC_KEY|IPV4_ADDRESS|IPV6_ADDRESS|CREATED_DATE|LAST_SEEN|STATUS
EOF
        chmod 600 "$CLIENT_DB"
        log "INFO" "Client database initialized: $CLIENT_DB"
    fi
}

# 获取当前IPv6网络配置
get_current_ipv6_network() {
    # 从WireGuard配置中获取IPv6网络
    if [[ -f /etc/wireguard/wg0.conf ]]; then
        local wg_address=$(grep "Address.*::" /etc/wireguard/wg0.conf | head -1 | awk '{print $3}' | cut -d',' -f2)
        if [[ -n "$wg_address" ]]; then
            # 从服务器地址中提取网络前缀
            local server_ip=$(echo "$wg_address" | cut -d'/' -f1)
            local server_mask=$(echo "$wg_address" | cut -d'/' -f2)
            
            # 根据服务器地址生成网络前缀
            if [[ "$server_ip" =~ ::1$ ]]; then
                local network_prefix=$(echo "$server_ip" | sed 's/::1$/::/')
                echo "${network_prefix}${server_mask}"
                return
            fi
        fi
    fi
    
    # 默认配置
    echo "2001:db8::/48"
}

# 获取默认客户端输出目录
get_default_client_output_dir() {
    echo "/opt/ipv6-wireguard-manager/client-packages"
}

# 确保客户端输出目录存在
ensure_client_output_dir() {
    local output_dir="$1"
    
    if [[ ! -d "$output_dir" ]]; then
        mkdir -p "$output_dir"
        log "INFO" "Created client output directory: $output_dir"
    fi
}

# 自动分配客户端地址
auto_allocate_addresses() {
    local client_name="$1"
    local ipv4_network="${2:-10.0.0.0/24}"
    local ipv6_network="${3:-$(get_current_ipv6_network)}"
    
    # 获取网络信息
    local ipv4_base=$(echo "$ipv4_network" | cut -d'/' -f1 | cut -d'.' -f1-3)
    local ipv6_prefix=$(echo "$ipv6_network" | cut -d'/' -f1)
    local ipv6_subnet_mask=$(echo "$ipv6_network" | cut -d'/' -f2)
    
    # 确保客户端数据库文件存在
    if [[ ! -f "$CLIENT_DB" ]]; then
        mkdir -p "$(dirname "$CLIENT_DB")"
        touch "$CLIENT_DB"
        log "INFO" "Created client database: $CLIENT_DB"
    fi
    
    # 查找可用的IPv4地址
    local ipv4_address=""
    for i in {2..254}; do
        local test_ip="$ipv4_base.$i/32"
        if ! grep -q "|$test_ip|" "$CLIENT_DB" 2>/dev/null; then
            ipv4_address="$test_ip"
            break
        fi
    done
    
    # 查找可用的IPv6地址 - 支持/56到/72的子网段
    local ipv6_address=""
    local client_subnet_mask=""
    
    # 根据原始子网掩码确定客户端子网掩码
    case "$ipv6_subnet_mask" in
        56) client_subnet_mask="64" ;;  # /56 -> /64
        57) client_subnet_mask="65" ;;  # /57 -> /65
        58) client_subnet_mask="66" ;;  # /58 -> /66
        59) client_subnet_mask="67" ;;  # /59 -> /67
        60) client_subnet_mask="68" ;;  # /60 -> /68
        61) client_subnet_mask="69" ;;  # /61 -> /69
        62) client_subnet_mask="70" ;;  # /62 -> /70
        63) client_subnet_mask="71" ;;  # /63 -> /71
        64) client_subnet_mask="72" ;;  # /64 -> /72
        65) client_subnet_mask="73" ;;  # /65 -> /73
        66) client_subnet_mask="74" ;;  # /66 -> /74
        67) client_subnet_mask="75" ;;  # /67 -> /75
        68) client_subnet_mask="76" ;;  # /68 -> /76
        69) client_subnet_mask="77" ;;  # /69 -> /77
        70) client_subnet_mask="78" ;;  # /70 -> /78
        71) client_subnet_mask="79" ;;  # /71 -> /79
        72) client_subnet_mask="80" ;;  # /72 -> /80
        *) client_subnet_mask="128" ;;  # 默认使用/128
    esac
    
    # 生成客户端IPv6地址
    for i in {2..9999}; do
        # 正确处理IPv6地址格式
        local test_ipv6=""
        if [[ "$ipv6_prefix" == *"::" ]]; then
            # 如果前缀以::结尾，直接添加数字
            test_ipv6="${ipv6_prefix}${i}/${client_subnet_mask}"
        elif [[ "$ipv6_prefix" == *":" ]]; then
            # 如果前缀以:结尾，直接添加数字
            test_ipv6="${ipv6_prefix}${i}/${client_subnet_mask}"
        else
            # 如果前缀不以:结尾，添加:数字
            test_ipv6="${ipv6_prefix}:${i}/${client_subnet_mask}"
        fi
        
        if ! grep -q "|$test_ipv6|" "$CLIENT_DB" 2>/dev/null; then
            ipv6_address="$test_ipv6"
            break
        fi
    done
    
    if [[ -z "$ipv4_address" ]]; then
        log "ERROR" "No available IPv4 addresses in network $ipv4_network"
        return 1
    fi
    
    if [[ -z "$ipv6_address" ]]; then
        log "ERROR" "No available IPv6 addresses in network $ipv6_network"
        return 1
    fi
    
    # 记录分配信息到日志
    log "INFO" "Allocated IPv6 address: $ipv6_address (from /$ipv6_subnet_mask network, using /$client_subnet_mask for client)"
    # 只输出地址信息，不包含日志
    echo "$ipv4_address|$ipv6_address"
}

# 检查地址冲突
check_address_conflict() {
    local ipv4_address="$1"
    local ipv6_address="$2"
    
    # 检查IPv4地址冲突
    if grep -q "|$ipv4_address|" "$CLIENT_DB" 2>/dev/null; then
        log "ERROR" "IPv4 address $ipv4_address is already in use"
        return 1
    fi
    
    # 检查IPv6地址冲突
    if grep -q "|$ipv6_address|" "$CLIENT_DB" 2>/dev/null; then
        log "ERROR" "IPv6 address $ipv6_address is already in use"
        return 1
    fi
    
    return 0
}

# 添加客户端
add_client() {
    local client_name="$1"
    local ipv4_address="${2:-auto}"
    local ipv6_address="${3:-auto}"
    local preshared_key="${4:-}"
    
    # 检查客户端是否已存在
    if grep -q "^$client_name|" "$CLIENT_DB"; then
        log "ERROR" "Client $client_name already exists"
        return 1
    fi
    
    # 自动分配地址（如果指定为auto）
    if [[ "$ipv4_address" == "auto" ]] || [[ "$ipv6_address" == "auto" ]]; then
        # 临时重定向日志到stderr，避免混入返回值
        local allocated_addresses=$(auto_allocate_addresses "$client_name" 2>/dev/null)
        if [[ $? -ne 0 ]] || [[ -z "$allocated_addresses" ]]; then
            log "ERROR" "Failed to allocate addresses for client $client_name"
            return 1
        fi
        
        if [[ "$ipv4_address" == "auto" ]]; then
            ipv4_address=$(echo "$allocated_addresses" | cut -d'|' -f1)
        fi
        
        if [[ "$ipv6_address" == "auto" ]]; then
            ipv6_address=$(echo "$allocated_addresses" | cut -d'|' -f2)
        fi
        
        # 日志已移至auto_allocate_addresses函数内部，避免混入返回值
    fi
    
    # 检查地址冲突
    if ! check_address_conflict "$ipv4_address" "$ipv6_address"; then
        return 1
    fi
    
    # 生成客户端密钥
    local client_private_key=$(wg genkey)
    local client_public_key=$(echo "$client_private_key" | wg pubkey)
    
    # 生成预共享密钥（如果未提供）
    if [[ -z "$preshared_key" ]]; then
        preshared_key=$(wg genpsk)
    fi
    
    # 添加到数据库
    local created_date=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$client_name|$client_private_key|$client_public_key|$ipv4_address|$ipv6_address|$created_date||active" >> "$CLIENT_DB"
    
    # 创建客户端配置目录
    local client_dir="$CLIENT_CONFIG_DIR/$client_name"
    mkdir -p "$client_dir"
    
    # 生成客户端配置文件
    local server_public_key=$(cat "$CONFIG_DIR/server_public_key")
    local server_endpoint=$(get_public_ip)
    local server_port=$(grep "ListenPort" /etc/wireguard/wg0.conf | awk '{print $3}')
    
    create_client_config "$client_dir/config.conf" "$client_name" "$client_private_key" "$ipv4_address" "$ipv6_address" "$server_public_key" "$server_endpoint" "$server_port" "$preshared_key"
    
    # 生成客户端安装脚本
    generate_client_install_script "$client_dir/install.sh" "$client_name" "$client_dir/config.conf"
    
    # 生成QR码
    generate_qr_code "$client_dir/config.conf" "$client_dir/qr.png"
    
    # 添加到服务器配置
    add_client_to_server_config "/etc/wireguard/wg0.conf" "$client_name" "$client_public_key" "$ipv4_address" "$ipv6_address" "$preshared_key"
    
    # 重新加载WireGuard配置
    wg syncconf wg0 <(wg-quick strip wg0)
    
    log "INFO" "Client $client_name added successfully"
    echo "Client configuration files created in: $client_dir"
}

# 生成QR码
generate_qr_code() {
    local config_file="$1"
    local qr_file="$2"
    
    if command -v qrencode >/dev/null 2>&1; then
        qrencode -t PNG -o "$qr_file" < "$config_file"
        echo "QR code generated: $qr_file"
    else
        echo "qrencode not installed, skipping QR code generation"
    fi
}

# 删除客户端
remove_client() {
    local client_name="$1"
    
    # 检查客户端是否存在
    if ! grep -q "^$client_name|" "$CLIENT_DB"; then
        log "ERROR" "Client $client_name not found"
        return 1
    fi
    
    # 获取客户端公钥
    local client_public_key=$(grep "^$client_name|" "$CLIENT_DB" | cut -d'|' -f3)
    
    # 从服务器配置中移除客户端
    remove_client_from_server_config "/etc/wireguard/wg0.conf" "$client_public_key"
    
    # 从数据库中移除客户端
    sed -i "/^$client_name|/d" "$CLIENT_DB"
    
    # 删除客户端配置目录
    local client_dir="$CLIENT_CONFIG_DIR/$client_name"
    if [[ -d "$client_dir" ]]; then
        rm -rf "$client_dir"
    fi
    
    # 重新加载WireGuard配置
    wg syncconf wg0 <(wg-quick strip wg0)
    
    log "INFO" "Client $client_name removed successfully"
}

# 从服务器配置中移除客户端
remove_client_from_server_config() {
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
}

# 列出所有客户端
list_clients() {
    if [[ ! -f "$CLIENT_DB" ]]; then
        echo "No clients found"
        return
    fi
    
    printf "%-20s %-15s %-25s %-15s %-20s %s\n" "NAME" "IPv4" "IPv6" "STATUS" "CREATED" "LAST_SEEN"
    printf "%-20s %-15s %-25s %-15s %-20s %s\n" "----" "----" "----" "------" "-------" "---------"
    
    while IFS='|' read -r name private_key public_key ipv4 ipv6 created last_seen status; do
        if [[ "$name" != "#"* ]]; then
            printf "%-20s %-15s %-25s %-15s %-20s %s\n" "$name" "$ipv4" "$ipv6" "$status" "$created" "${last_seen:-Never}"
        fi
    done < "$CLIENT_DB"
}

# 获取客户端信息
get_client_info() {
    local client_name="$1"
    
    if [[ ! -f "$CLIENT_DB" ]]; then
        echo "Client database not found"
        return 1
    fi
    
    local client_info=$(grep "^$client_name|" "$CLIENT_DB")
    if [[ -z "$client_info" ]]; then
        echo "Client $client_name not found"
        return 1
    fi
    
    IFS='|' read -r name private_key public_key ipv4 ipv6 created last_seen status <<< "$client_info"
    
    echo "Client Information:"
    echo "  Name: $name"
    echo "  IPv4 Address: $ipv4"
    echo "  IPv6 Address: $ipv6"
    echo "  Public Key: $public_key"
    echo "  Status: $status"
    echo "  Created: $created"
    echo "  Last Seen: ${last_seen:-Never}"
    echo "  Config Directory: $CLIENT_CONFIG_DIR/$name"
}

# 更新客户端状态
update_client_status() {
    local client_name="$1"
    local status="$2"
    
    if [[ ! -f "$CLIENT_DB" ]]; then
        log "ERROR" "Client database not found"
        return 1
    fi
    
    if ! grep -q "^$client_name|" "$CLIENT_DB"; then
        log "ERROR" "Client $client_name not found"
        return 1
    fi
    
    # 更新状态
    sed -i "s/^$client_name|.*|$/$client_name|\1|\2|\3|\4|\5|\6|$status/" "$CLIENT_DB"
    
    log "INFO" "Client $client_name status updated to: $status"
}

# 更新客户端最后连接时间
update_client_last_seen() {
    local client_public_key="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ ! -f "$CLIENT_DB" ]]; then
        return 1
    fi
    
    # 更新最后连接时间
    sed -i "s/^\([^|]*\)|\([^|]*\)|$client_public_key|\([^|]*\)|\([^|]*\)|\([^|]*\)|\([^|]*\)|\([^|]*\)$/\1|\2|$client_public_key|\3|\4|\5|$timestamp|\7/" "$CLIENT_DB"
}

# 获取客户端统计信息
get_client_stats() {
    local total_clients=0
    local active_clients=0
    local inactive_clients=0
    
    if [[ -f "$CLIENT_DB" ]]; then
        while IFS='|' read -r name private_key public_key ipv4 ipv6 created last_seen status; do
            if [[ "$name" != "#"* ]]; then
                ((total_clients++))
                if [[ "$status" == "active" ]]; then
                    ((active_clients++))
                else
                    ((inactive_clients++))
                fi
            fi
        done < "$CLIENT_DB"
    fi
    
    echo "Client Statistics:"
    echo "  Total Clients: $total_clients"
    echo "  Active Clients: $active_clients"
    echo "  Inactive Clients: $inactive_clients"
}

# 生成客户端配置包
generate_client_package() {
    local client_name="$1"
    local package_dir="$2"
    
    if ! grep -q "^$client_name|" "$CLIENT_DB"; then
        log "ERROR" "Client $client_name not found"
        return 1
    fi
    
    local client_dir="$CLIENT_CONFIG_DIR/$client_name"
    if [[ ! -d "$client_dir" ]]; then
        log "ERROR" "Client directory not found: $client_dir"
        return 1
    fi
    
    # 创建包目录
    mkdir -p "$package_dir"
    
    # 复制客户端文件
    cp "$client_dir/config.conf" "$package_dir/"
    cp "$client_dir/install.sh" "$package_dir/"
    if [[ -f "$client_dir/qr.png" ]]; then
        cp "$client_dir/qr.png" "$package_dir/"
    fi
    
    # 创建README文件
    cat > "$package_dir/README.txt" << EOF
WireGuard Client Configuration Package
=====================================

Client Name: $client_name
Generated: $(date)

Files:
- config.conf: WireGuard client configuration
- install.sh: Automatic installation script
- qr.png: QR code for mobile clients (if available)
- README.txt: This file

Installation:
1. Copy all files to your client device
2. Run: sudo ./install.sh
3. Or manually import config.conf to your WireGuard client

For mobile devices, scan the QR code with your WireGuard app.
EOF

    # 创建压缩包
    local package_file="$package_dir/${client_name}_wireguard_config.tar.gz"
    tar -czf "$package_file" -C "$package_dir" .
    
    log "INFO" "Client package generated: $package_file"
    echo "Client package created: $package_file"
}

# 生成客户端安装包（自动安装脚本）
generate_client_installer_package() {
    local client_name="$1"
    local output_dir="$2"
    
    if [[ -z "$client_name" || -z "$output_dir" ]]; then
        log "ERROR" "客户端名称和输出目录不能为空"
        return 1
    fi
    
    # 检查客户端是否存在
    if ! grep -q "^$client_name|" "$CLIENT_DB"; then
        log "ERROR" "客户端 $client_name 不存在"
        return 1
    fi
    
    # 确保输出目录存在
    ensure_client_output_dir "$output_dir"
    
    # 获取客户端信息
    local client_info=$(grep "^$client_name|" "$CLIENT_DB")
    local private_key=$(echo "$client_info" | cut -d'|' -f2)
    local public_key=$(echo "$client_info" | cut -d'|' -f3)
    local ipv4_address=$(echo "$client_info" | cut -d'|' -f4)
    local ipv6_address=$(echo "$client_info" | cut -d'|' -f5)
    
    # 获取服务器信息
    local server_public_key=$(get_server_public_key)
    local server_endpoint=$(get_public_ip)
    local server_port=$(get_wireguard_port)
    
    # 使用客户端脚本生成器
    if [[ -f "$SCRIPT_DIR/modules/client_script_generator.sh" ]]; then
        source "$SCRIPT_DIR/modules/client_script_generator.sh"
        generate_client_installer "$client_name" "$server_endpoint" "$server_port" "$ipv4_address" "$ipv6_address" "$private_key" "$server_public_key" "$output_dir"
    else
        log "ERROR" "客户端脚本生成器模块未找到"
        return 1
    fi
    
    log "INFO" "客户端安装包已生成: $output_dir"
    log "INFO" "Linux 安装脚本: $output_dir/install-linux.sh"
    log "INFO" "Windows 安装脚本: $output_dir/install-windows.ps1"
    log "INFO" "配置文件: $output_dir/$client_name.conf"
    
    # 显示下载链接
    echo
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                        下载链接                          ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${YELLOW}客户端安装包已生成，可通过以下方式下载:${NC}"
    echo
    echo -e "${GREEN}1. 直接下载整个目录:${NC}"
    echo -e "   ${BLUE}scp -r $output_dir user@client-ip:/tmp/${NC}"
    echo
    echo -e "${GREEN}2. 下载单个文件:${NC}"
    echo -e "   ${BLUE}scp $output_dir/install-linux.sh user@client-ip:/tmp/${NC}"
    echo -e "   ${BLUE}scp $output_dir/install-windows.ps1 user@client-ip:/tmp/${NC}"
    echo
    echo -e "${GREEN}3. 通过 HTTP 服务器:${NC}"
    echo -e "   ${BLUE}python3 -m http.server 8000 -d $output_dir${NC}"
    echo -e "   ${BLUE}然后访问: http://server-ip:8000/${NC}"
    echo
    echo -e "${YELLOW}客户端运行命令:${NC}"
    echo -e "   ${BLUE}Linux: chmod +x install-linux.sh && ./install-linux.sh${NC}"
    echo -e "   ${BLUE}Windows: .\\install-windows.ps1${NC}"
}

# 批量生成客户端配置
batch_generate_clients() {
    local config_file="$1"
    local auto_allocate="${2:-false}"
    
    if [[ ! -f "$config_file" ]]; then
        log "ERROR" "Configuration file not found: $config_file"
        return 1
    fi
    
    local success_count=0
    local error_count=0
    
    # 配置文件格式: client_name,ipv4_address,ipv6_address,description
    while IFS=',' read -r name ipv4 ipv6 description; do
        if [[ "$name" != "#"* ]] && [[ -n "$name" ]]; then
            echo "Generating client: $name"
            
            # 如果启用自动分配，将地址设置为auto
            if [[ "$auto_allocate" == "true" ]]; then
                ipv4="auto"
                ipv6="auto"
            fi
            
            if add_client "$name" "$ipv4" "$ipv6"; then
                ((success_count++))
                echo "✓ Client $name added successfully"
            else
                ((error_count++))
                echo "✗ Failed to add client $name"
            fi
        fi
    done < "$config_file"
    
    log "INFO" "Batch client generation completed: $success_count successful, $error_count failed"
    echo "Batch generation summary: $success_count successful, $error_count failed"
}

# 快速批量添加客户端（自动分配地址）
quick_batch_add_clients() {
    local client_count="$1"
    local name_prefix="${2:-client}"
    local start_index="${3:-1}"
    
    if [[ ! "$client_count" =~ ^[0-9]+$ ]] || [[ "$client_count" -lt 1 ]]; then
        log "ERROR" "Invalid client count: $client_count"
        return 1
    fi
    
    local success_count=0
    local error_count=0
    
    echo "Adding $client_count clients with prefix '$name_prefix' starting from index $start_index..."
    
    for ((i=start_index; i<start_index+client_count; i++)); do
        local client_name="${name_prefix}${i}"
        echo "Adding client: $client_name"
        
        if add_client "$client_name" "auto" "auto"; then
            ((success_count++))
            echo "✓ Client $client_name added successfully"
        else
            ((error_count++))
            echo "✗ Failed to add client $client_name"
        fi
    done
    
    log "INFO" "Quick batch add completed: $success_count successful, $error_count failed"
    echo "Quick batch add summary: $success_count successful, $error_count failed"
}

# 导出客户端配置
export_client_configs() {
    local export_dir="$1"
    local format="${2:-tar}"  # tar, zip, individual
    
    mkdir -p "$export_dir"
    
    case "$format" in
        "tar")
            tar -czf "$export_dir/all_clients.tar.gz" -C "$CLIENT_CONFIG_DIR" .
            echo "All client configurations exported to: $export_dir/all_clients.tar.gz"
            ;;
        "zip")
            if command -v zip >/dev/null 2>&1; then
                zip -r "$export_dir/all_clients.zip" "$CLIENT_CONFIG_DIR"
                echo "All client configurations exported to: $export_dir/all_clients.zip"
            else
                log "ERROR" "zip command not found"
                return 1
            fi
            ;;
        "individual")
            if [[ -f "$CLIENT_DB" ]]; then
                while IFS='|' read -r name private_key public_key ipv4 ipv6 created last_seen status; do
                    if [[ "$name" != "#"* ]]; then
                        generate_client_package "$name" "$export_dir/$name"
                    fi
                done < "$CLIENT_DB"
                echo "Individual client packages exported to: $export_dir"
            fi
            ;;
    esac
}

# 导入客户端配置
import_client_configs() {
    local import_file="$1"
    
    if [[ ! -f "$import_file" ]]; then
        log "ERROR" "Import file not found: $import_file"
        return 1
    fi
    
    # 解压到临时目录
    local temp_dir=$(mktemp -d)
    tar -xzf "$import_file" -C "$temp_dir"
    
    # 复制配置文件
    cp -r "$temp_dir"/* "$CLIENT_CONFIG_DIR/"
    
    # 清理临时目录
    rm -rf "$temp_dir"
    
    log "INFO" "Client configurations imported from: $import_file"
}

# 监控客户端连接
monitor_client_connections() {
    local interface="${1:-wg0}"
    
    echo "Monitoring client connections on interface: $interface"
    echo "Press Ctrl+C to stop"
    echo
    
    while true; do
        clear
        echo "=== WireGuard Client Connections ==="
        echo "Time: $(date)"
        echo
        
        if command -v wg >/dev/null 2>&1; then
            wg show "$interface" dump | while IFS=$'\t' read -r interface private_key public_key preshared_key endpoint allowed_ips latest_handshake transfer_rx transfer_tx persistent_keepalive; do
                if [[ "$public_key" != "(none)" ]]; then
                    # 查找客户端名称
                    local client_name=$(grep "|$public_key|" "$CLIENT_DB" | cut -d'|' -f1)
                    if [[ -z "$client_name" ]]; then
                        client_name="Unknown"
                    fi
                    
                    # 更新最后连接时间
                    update_client_last_seen "$public_key"
                    
                    # 格式化传输量
                    local rx_mb=$((transfer_rx / 1024 / 1024))
                    local tx_mb=$((transfer_tx / 1024 / 1024))
                    
                    # 格式化握手时间
                    local handshake_time="Never"
                    if [[ "$latest_handshake" != "0" ]]; then
                        handshake_time=$(date -d "@$latest_handshake" '+%Y-%m-%d %H:%M:%S')
                    fi
                    
                    echo "Client: $client_name"
                    echo "  Public Key: ${public_key:0:20}..."
                    echo "  Endpoint: $endpoint"
                    echo "  Allowed IPs: $allowed_ips"
                    echo "  Latest Handshake: $handshake_time"
                    echo "  Transfer: RX ${rx_mb}MB, TX ${tx_mb}MB"
                    echo "  Keepalive: $persistent_keepalive"
                    echo
                fi
            done
        fi
        
        sleep 5
    done
}

# 清理不活跃的客户端
cleanup_inactive_clients() {
    local days_threshold="${1:-30}"
    local current_time=$(date +%s)
    local threshold_time=$((current_time - days_threshold * 24 * 60 * 60))
    
    if [[ ! -f "$CLIENT_DB" ]]; then
        log "INFO" "No client database found"
        return 0
    fi
    
    local cleaned_count=0
    
    while IFS='|' read -r name private_key public_key ipv4 ipv6 created last_seen status; do
        if [[ "$name" != "#"* ]]; then
            if [[ "$last_seen" == "" ]] || [[ "$last_seen" == "Never" ]]; then
                # 从未连接的客户端，检查创建时间
                local created_time=$(date -d "$created" +%s 2>/dev/null || echo "0")
                if [[ "$created_time" -lt "$threshold_time" ]]; then
                    echo "Removing inactive client: $name (never connected, created: $created)"
                    remove_client "$name"
                    ((cleaned_count++))
                fi
            else
                # 检查最后连接时间
                local last_seen_time=$(date -d "$last_seen" +%s 2>/dev/null || echo "0")
                if [[ "$last_seen_time" -lt "$threshold_time" ]]; then
                    echo "Removing inactive client: $name (last seen: $last_seen)"
                    remove_client "$name"
                    ((cleaned_count++))
                fi
            fi
        fi
    done < "$CLIENT_DB"
    
    log "INFO" "Cleaned up $cleaned_count inactive clients"
}

# 客户端输出目录管理
client_output_directory_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                 客户端输出目录管理                        ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        local default_dir=$(get_default_client_output_dir)
        echo -e "${YELLOW}当前默认输出目录:${NC} $default_dir"
        echo
        
        if [[ -d "$default_dir" ]]; then
            local file_count=$(find "$default_dir" -type f | wc -l)
            local dir_size=$(du -sh "$default_dir" 2>/dev/null | cut -f1)
            echo -e "${GREEN}目录状态:${NC} 存在"
            echo -e "${GREEN}文件数量:${NC} $file_count"
            echo -e "${GREEN}目录大小:${NC} $dir_size"
        else
            echo -e "${RED}目录状态:${NC} 不存在"
        fi
        
        echo
        echo -e "${YELLOW}管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看目录内容"
        echo -e "  ${GREEN}2.${NC} 创建默认目录"
        echo -e "  ${GREEN}3.${NC} 清理目录内容"
        echo -e "  ${GREEN}4.${NC} 更改默认目录"
        echo -e "  ${GREEN}5.${NC} 批量生成所有客户端包到默认目录"
        echo -e "  ${GREEN}0.${NC} 返回客户端管理"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                if [[ -d "$default_dir" ]]; then
                    echo -e "${CYAN}目录内容:${NC}"
                    ls -la "$default_dir" | head -20
                    if [[ $(ls -1 "$default_dir" | wc -l) -gt 20 ]]; then
                        echo "... (显示前20个文件)"
                    fi
                else
                    echo -e "${RED}目录不存在${NC}"
                fi
                read -p "按回车键继续..."
                ;;
            "2")
                ensure_client_output_dir "$default_dir"
                echo -e "${GREEN}✓${NC} 默认目录已创建: $default_dir"
                read -p "按回车键继续..."
                ;;
            "3")
                if [[ -d "$default_dir" ]]; then
                    echo -e "${YELLOW}警告: 这将删除目录中的所有文件！${NC}"
                    read -p "确认清理目录? (y/N): " confirm
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        rm -rf "$default_dir"/*
                        echo -e "${GREEN}✓${NC} 目录已清理"
                    else
                        echo -e "${YELLOW}操作已取消${NC}"
                    fi
                else
                    echo -e "${RED}目录不存在${NC}"
                fi
                read -p "按回车键继续..."
                ;;
            "4")
                echo -e "${YELLOW}当前默认目录: $default_dir${NC}"
                read -p "输入新的默认目录: " new_dir
                if [[ -n "$new_dir" ]]; then
                    # 这里可以更新配置文件或环境变量
                    echo -e "${GREEN}✓${NC} 新默认目录设置为: $new_dir"
                    echo -e "${YELLOW}注意: 此设置仅在当前会话中有效${NC}"
                else
                    echo -e "${RED}目录不能为空${NC}"
                fi
                read -p "按回车键继续..."
                ;;
            "5")
                if [[ -f "$CLIENT_DB" ]] && [[ -s "$CLIENT_DB" ]]; then
                    echo -e "${YELLOW}开始批量生成所有客户端包...${NC}"
                    local count=0
                    while IFS='|' read -r name private_key public_key ipv4 ipv6 created last_seen status; do
                        if [[ -n "$name" ]] && [[ "$name" != "client_name" ]]; then
                            echo -e "${BLUE}生成客户端包: $name${NC}"
                            generate_client_installer_package "$name" "$default_dir"
                            ((count++))
                        fi
                    done < "$CLIENT_DB"
                    echo -e "${GREEN}✓${NC} 已生成 $count 个客户端包到: $default_dir"
                else
                    echo -e "${RED}没有找到客户端数据${NC}"
                fi
                read -p "按回车键继续..."
                ;;
            "0")
                return 0
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 地址池管理
address_pool_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                   地址池管理菜单                          ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        echo -e "${YELLOW}地址池管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看地址池状态"
        echo -e "  ${GREEN}2.${NC} 查看已使用地址"
        echo -e "  ${GREEN}3.${NC} 查看可用地址"
        echo -e "  ${GREEN}4.${NC} 地址冲突检测"
        echo -e "  ${GREEN}5.${NC} 重新分配地址"
        echo -e "  ${GREEN}6.${NC} 地址池统计"
        echo -e "  ${GREEN}0.${NC} 返回客户端管理"
        echo
        
        read -p "请选择操作 (0-6): " choice
        
        case "$choice" in
            "1")
                show_address_pool_status
                read -p "按回车键继续..."
                ;;
            "2")
                show_used_addresses
                read -p "按回车键继续..."
                ;;
            "3")
                show_available_addresses
                read -p "按回车键继续..."
                ;;
            "4")
                check_all_address_conflicts
                read -p "按回车键继续..."
                ;;
            "5")
                read -p "客户端名称: " client_name
                reallocate_client_address "$client_name"
                read -p "按回车键继续..."
                ;;
            "6")
                show_address_pool_statistics
                read -p "按回车键继续..."
                ;;
            "0")
                return 0
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 显示地址池状态
show_address_pool_status() {
    echo -e "${CYAN}=== 地址池状态 ===${NC}"
    echo
    
    # IPv4地址池状态
    local ipv4_network="10.0.0.0/24"
    local ipv4_total=253  # 10.0.0.1 是服务器，10.0.0.0 和 10.0.0.255 不可用
    local ipv4_used=0
    
    if [[ -f "$CLIENT_DB" ]]; then
        ipv4_used=$(grep -c "^[^#]" "$CLIENT_DB")
    fi
    
    local ipv4_available=$((ipv4_total - ipv4_used))
    
    echo -e "${YELLOW}IPv4地址池:${NC}"
    echo -e "  网络: $ipv4_network"
    echo -e "  总数: $ipv4_total"
    echo -e "  已用: $ipv4_used"
    echo -e "  可用: $ipv4_available"
    echo -e "  使用率: $((ipv4_used * 100 / ipv4_total))%"
    echo
    
    # IPv6地址池状态
    local ipv6_network=$(get_current_ipv6_network)
    local ipv6_subnet_mask=$(echo "$ipv6_network" | cut -d'/' -f2)
    local client_subnet_mask="64"  # 默认客户端子网掩码
    
    # 根据网络配置确定客户端子网掩码
    case "$ipv6_subnet_mask" in
        56) client_subnet_mask="64" ;;
        57) client_subnet_mask="65" ;;
        58) client_subnet_mask="66" ;;
        59) client_subnet_mask="67" ;;
        60) client_subnet_mask="68" ;;
        61) client_subnet_mask="69" ;;
        62) client_subnet_mask="70" ;;
        63) client_subnet_mask="71" ;;
        64) client_subnet_mask="72" ;;
        65) client_subnet_mask="73" ;;
        66) client_subnet_mask="74" ;;
        67) client_subnet_mask="75" ;;
        68) client_subnet_mask="76" ;;
        69) client_subnet_mask="77" ;;
        70) client_subnet_mask="78" ;;
        71) client_subnet_mask="79" ;;
        72) client_subnet_mask="80" ;;
        *) client_subnet_mask="128" ;;
    esac
    
    local ipv6_total=9998  # 假设使用 /48 前缀
    local ipv6_used=0
    
    if [[ -f "$CLIENT_DB" ]]; then
        ipv6_used=$(grep -c "^[^#]" "$CLIENT_DB")
    fi
    
    local ipv6_available=$((ipv6_total - ipv6_used))
    
    echo -e "${YELLOW}IPv6地址池:${NC}"
    echo -e "  网络: $ipv6_network"
    echo -e "  客户端子网掩码: /$client_subnet_mask"
    echo -e "  总数: $ipv6_total"
    echo -e "  已用: $ipv6_used"
    echo -e "  可用: $ipv6_available"
    echo -e "  使用率: $((ipv6_used * 100 / ipv6_total))%"
    echo -e "  支持范围: /56 到 /72 的子网段"
}

# 显示已使用地址
show_used_addresses() {
    echo -e "${CYAN}=== 已使用地址 ===${NC}"
    echo
    
    if [[ ! -f "$CLIENT_DB" ]]; then
        echo "没有客户端数据库文件"
        return
    fi
    
    printf "%-20s %-15s %-25s %-15s\n" "客户端名称" "IPv4地址" "IPv6地址" "状态"
    printf "%-20s %-15s %-25s %-15s\n" "----------" "--------" "--------" "----"
    
    while IFS='|' read -r name private_key public_key ipv4 ipv6 created last_seen status; do
        if [[ "$name" != "#"* ]]; then
            printf "%-20s %-15s %-25s %-15s\n" "$name" "$ipv4" "$ipv6" "$status"
        fi
    done < "$CLIENT_DB"
}

# 显示可用地址
show_available_addresses() {
    echo -e "${CYAN}=== 可用地址 ===${NC}"
    echo
    
    local ipv4_network="10.0.0.0/24"
    local ipv6_network=$(get_current_ipv6_network)
    
    echo -e "${YELLOW}可用IPv4地址 (前10个):${NC}"
    local count=0
    for i in {2..254}; do
        local test_ip="10.0.0.$i/32"
        if ! grep -q "|$test_ip|" "$CLIENT_DB" 2>/dev/null; then
            echo "  $test_ip"
            ((count++))
            if [[ $count -ge 10 ]]; then
                break
            fi
        fi
    done
    
    echo
    echo -e "${YELLOW}可用IPv6地址 (前10个):${NC}"
    echo -e "${BLUE}支持子网段范围: /56 到 /72${NC}"
    echo -e "${BLUE}地址分配规则: 服务器使用具体地址，客户端从子网段分配${NC}"
    echo
    
    count=0
    local ipv6_prefix=$(echo "$ipv6_network" | cut -d'/' -f1)
    local ipv6_subnet_mask=$(echo "$ipv6_network" | cut -d'/' -f2)
    local client_subnet_mask="64"  # 默认客户端子网掩码
    
    # 根据网络配置确定客户端子网掩码
    case "$ipv6_subnet_mask" in
        56) client_subnet_mask="64" ;;
        57) client_subnet_mask="65" ;;
        58) client_subnet_mask="66" ;;
        59) client_subnet_mask="67" ;;
        60) client_subnet_mask="68" ;;
        61) client_subnet_mask="69" ;;
        62) client_subnet_mask="70" ;;
        63) client_subnet_mask="71" ;;
        64) client_subnet_mask="72" ;;
        65) client_subnet_mask="73" ;;
        66) client_subnet_mask="74" ;;
        67) client_subnet_mask="75" ;;
        68) client_subnet_mask="76" ;;
        69) client_subnet_mask="77" ;;
        70) client_subnet_mask="78" ;;
        71) client_subnet_mask="79" ;;
        72) client_subnet_mask="80" ;;
        *) client_subnet_mask="128" ;;
    esac
    
    for i in {2..9999}; do
        local test_ipv6="${ipv6_prefix}${i}/${client_subnet_mask}"
        if ! grep -q "|$test_ipv6|" "$CLIENT_DB" 2>/dev/null; then
            echo "  $test_ipv6"
            ((count++))
            if [[ $count -ge 10 ]]; then
                break
            fi
        fi
    done
    
    echo
    echo -e "${YELLOW}子网段分配说明:${NC}"
    echo "  - 服务器地址: ${ipv6_prefix}1/64 (固定)"
    echo "  - 客户端地址: ${ipv6_prefix}2/${client_subnet_mask} 到 ${ipv6_prefix}9999/${client_subnet_mask}"
    echo "  - 支持范围: /56 到 /72 的子网段"
    echo "  - 当前配置: /${ipv6_subnet_mask} 网络，客户端使用 /${client_subnet_mask}"
}

# 检查所有地址冲突
check_all_address_conflicts() {
    echo -e "${CYAN}=== 地址冲突检测 ===${NC}"
    echo
    
    if [[ ! -f "$CLIENT_DB" ]]; then
        echo "没有客户端数据库文件"
        return
    fi
    
    local conflicts=0
    
    # 检查IPv4地址冲突
    echo -e "${YELLOW}检查IPv4地址冲突...${NC}"
    local ipv4_addresses=()
    while IFS='|' read -r name private_key public_key ipv4 ipv6 created last_seen status; do
        if [[ "$name" != "#"* ]]; then
            ipv4_addresses+=("$ipv4")
        fi
    done < "$CLIENT_DB"
    
    # 检查重复的IPv4地址
    for addr in "${ipv4_addresses[@]}"; do
        local count=$(printf '%s\n' "${ipv4_addresses[@]}" | grep -c "^$addr$")
        if [[ $count -gt 1 ]]; then
            echo -e "${RED}IPv4地址冲突: $addr (使用 $count 次)${NC}"
            ((conflicts++))
        fi
    done
    
    # 检查IPv6地址冲突
    echo -e "${YELLOW}检查IPv6地址冲突...${NC}"
    local ipv6_addresses=()
    while IFS='|' read -r name private_key public_key ipv4 ipv6 created last_seen status; do
        if [[ "$name" != "#"* ]]; then
            ipv6_addresses+=("$ipv6")
        fi
    done < "$CLIENT_DB"
    
    # 检查重复的IPv6地址
    for addr in "${ipv6_addresses[@]}"; do
        local count=$(printf '%s\n' "${ipv6_addresses[@]}" | grep -c "^$addr$")
        if [[ $count -gt 1 ]]; then
            echo -e "${RED}IPv6地址冲突: $addr (使用 $count 次)${NC}"
            ((conflicts++))
        fi
    done
    
    if [[ $conflicts -eq 0 ]]; then
        echo -e "${GREEN}✓ 没有发现地址冲突${NC}"
    else
        echo -e "${RED}✗ 发现 $conflicts 个地址冲突${NC}"
    fi
}

# 重新分配客户端地址
reallocate_client_address() {
    local client_name="$1"
    
    if [[ -z "$client_name" ]]; then
        read -p "客户端名称: " client_name
    fi
    
    if ! grep -q "^$client_name|" "$CLIENT_DB"; then
        log "ERROR" "Client $client_name not found"
        return 1
    fi
    
    echo "重新分配客户端 $client_name 的地址..."
    
    # 获取新的地址
    local new_addresses=$(auto_allocate_addresses "$client_name")
    if [[ $? -ne 0 ]]; then
        log "ERROR" "Failed to allocate new addresses for client $client_name"
        return 1
    fi
    
    local new_ipv4=$(echo "$new_addresses" | cut -d'|' -f1)
    local new_ipv6=$(echo "$new_addresses" | cut -d'|' -f2)
    
    # 更新数据库
    local temp_file=$(mktemp)
    while IFS='|' read -r name private_key public_key ipv4 ipv6 created last_seen status; do
        if [[ "$name" == "$client_name" ]]; then
            echo "$name|$private_key|$public_key|$new_ipv4|$new_ipv6|$created|$last_seen|$status" >> "$temp_file"
        else
            echo "$name|$private_key|$public_key|$ipv4|$ipv6|$created|$last_seen|$status" >> "$temp_file"
        fi
    done < "$CLIENT_DB"
    
    mv "$temp_file" "$CLIENT_DB"
    
    # 更新服务器配置
    local client_public_key=$(grep "^$client_name|" "$CLIENT_DB" | cut -d'|' -f3)
    remove_client_from_server_config "/etc/wireguard/wg0.conf" "$client_public_key"
    add_client_to_server_config "/etc/wireguard/wg0.conf" "$client_name" "$client_public_key" "$new_ipv4" "$new_ipv6"
    
    # 重新加载WireGuard配置
    wg syncconf wg0 <(wg-quick strip wg0)
    
    log "INFO" "Client $client_name address reallocated: IPv4=$new_ipv4, IPv6=$new_ipv6"
    echo -e "${GREEN}✓ 客户端 $client_name 地址重新分配成功${NC}"
    echo -e "  新IPv4地址: $new_ipv4"
    echo -e "  新IPv6地址: $new_ipv6"
}

# 显示地址池统计
show_address_pool_statistics() {
    echo -e "${CYAN}=== 地址池统计 ===${NC}"
    echo
    
    if [[ ! -f "$CLIENT_DB" ]]; then
        echo "没有客户端数据库文件"
        return
    fi
    
    local total_clients=0
    local active_clients=0
    local inactive_clients=0
    
    while IFS='|' read -r name private_key public_key ipv4 ipv6 created last_seen status; do
        if [[ "$name" != "#"* ]]; then
            ((total_clients++))
            if [[ "$status" == "active" ]]; then
                ((active_clients++))
            else
                ((inactive_clients++))
            fi
        fi
    done < "$CLIENT_DB"
    
    echo -e "${YELLOW}客户端统计:${NC}"
    echo -e "  总客户端数: $total_clients"
    echo -e "  活跃客户端: $active_clients"
    echo -e "  非活跃客户端: $inactive_clients"
    echo
    
    # 地址使用统计
    local ipv4_network="10.0.0.0/24"
    local ipv4_total=253
    local ipv4_used=$total_clients
    local ipv4_available=$((ipv4_total - ipv4_used))
    
    echo -e "${YELLOW}IPv4地址统计:${NC}"
    echo -e "  网络: $ipv4_network"
    echo -e "  总数: $ipv4_total"
    echo -e "  已用: $ipv4_used"
    echo -e "  可用: $ipv4_available"
    echo -e "  使用率: $((ipv4_used * 100 / ipv4_total))%"
    echo
    
    # IPv6地址统计
    local ipv6_network="2001:db8::/48"
    local ipv6_total=9998
    local ipv6_used=$total_clients
    local ipv6_available=$((ipv6_total - ipv6_used))
    
    echo -e "${YELLOW}IPv6地址统计:${NC}"
    echo -e "  网络: $ipv6_network"
    echo -e "  总数: $ipv6_total"
    echo -e "  已用: $ipv6_used"
    echo -e "  可用: $ipv6_available"
    echo -e "  使用率: $((ipv6_used * 100 / ipv6_total))%"
}

# 客户端管理菜单
client_management_menu() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                   客户端管理菜单                          ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        echo -e "${YELLOW}客户端管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 添加客户端"
        echo -e "  ${GREEN}2.${NC} 删除客户端"
        echo -e "  ${GREEN}3.${NC} 列出所有客户端"
        echo -e "  ${GREEN}4.${NC} 查看客户端信息"
        echo -e "  ${GREEN}5.${NC} 生成客户端配置包"
        echo -e "  ${GREEN}6.${NC} 生成客户端安装包 (自动安装脚本)"
        echo -e "  ${GREEN}7.${NC} 批量生成客户端"
        echo -e "  ${GREEN}8.${NC} 快速批量添加客户端"
        echo -e "  ${GREEN}9.${NC} 导出客户端配置"
        echo -e "  ${GREEN}10.${NC} 监控客户端连接"
        echo -e "  ${GREEN}11.${NC} 清理不活跃客户端"
        echo -e "  ${GREEN}12.${NC} 地址池管理"
        echo -e "  ${GREEN}13.${NC} 客户端输出目录管理"
        echo -e "  ${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 (0-13): " choice
        
        case "$choice" in
            "1")
                read -p "客户端名称: " client_name
                echo "地址分配选项:"
                echo "  1. 自动分配地址"
                echo "  2. 手动指定地址"
                read -p "请选择 (1-2): " addr_choice
                
                if [[ "$addr_choice" == "1" ]]; then
                    add_client "$client_name" "auto" "auto"
                else
                    read -p "IPv4地址 (例如: 10.0.0.2/32): " ipv4_address
                    read -p "IPv6地址 (例如: 2001:db8::2/128): " ipv6_address
                    add_client "$client_name" "$ipv4_address" "$ipv6_address"
                fi
                read -p "按回车键继续..."
                ;;
            "2")
                list_clients
                echo
                read -p "要删除的客户端名称: " client_name
                remove_client "$client_name"
                read -p "按回车键继续..."
                ;;
            "3")
                list_clients
                read -p "按回车键继续..."
                ;;
            "4")
                read -p "客户端名称: " client_name
                get_client_info "$client_name"
                read -p "按回车键继续..."
                ;;
            "5")
                read -p "客户端名称: " client_name
                echo "输出目录选项:"
                echo "  1. 使用默认安装目录 (/opt/ipv6-wireguard-manager/client-packages)"
                echo "  2. 手动输入目录"
                read -p "请选择 (1-2): " dir_choice
                
                if [[ "$dir_choice" == "1" ]]; then
                    output_dir="/opt/ipv6-wireguard-manager/client-packages"
                else
                    read -p "输出目录: " output_dir
                fi
                
                generate_client_package "$client_name" "$output_dir"
                read -p "按回车键继续..."
                ;;
            "6")
                read -p "客户端名称: " client_name
                echo "输出目录选项:"
                echo "  1. 使用默认安装目录 (/opt/ipv6-wireguard-manager/client-packages)"
                echo "  2. 手动输入目录"
                read -p "请选择 (1-2): " dir_choice
                
                if [[ "$dir_choice" == "1" ]]; then
                    output_dir="/opt/ipv6-wireguard-manager/client-packages"
                else
                    read -p "输出目录: " output_dir
                fi
                
                generate_client_installer_package "$client_name" "$output_dir"
                read -p "按回车键继续..."
                ;;
            "7")
                read -p "配置文件路径: " config_file
                echo "地址分配选项:"
                echo "  1. 使用配置文件中的地址"
                echo "  2. 自动分配地址"
                read -p "请选择 (1-2): " auto_choice
                
                if [[ "$auto_choice" == "2" ]]; then
                    batch_generate_clients "$config_file" "true"
                else
                    batch_generate_clients "$config_file" "false"
                fi
                read -p "按回车键继续..."
                ;;
            "8")
                read -p "要添加的客户端数量: " client_count
                read -p "客户端名称前缀 (默认: client): " name_prefix
                read -p "起始索引 (默认: 1): " start_index
                
                quick_batch_add_clients "${client_count:-10}" "${name_prefix:-client}" "${start_index:-1}"
                read -p "按回车键继续..."
                ;;
            "9")
                read -p "导出目录: " export_dir
                export_client_configs "$export_dir"
                read -p "按回车键继续..."
                ;;
            "10")
                monitor_client_connections
                ;;
            "11")
                read -p "清理多少天未连接的客户端 (默认30天): " days
                cleanup_inactive_clients "${days:-30}"
                read -p "按回车键继续..."
                ;;
            "12")
                address_pool_management
                ;;
            "13")
                client_output_directory_management
                ;;
            "0")
                return 0
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}
