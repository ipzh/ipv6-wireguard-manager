#!/bin/bash

# 客户端管理模块
# 负责客户端配置管理、状态监控、批量操作等客户端相关功能

# 客户端管理变量
CLIENT_DB="/var/lib/ipv6-wireguard-manager/clients.db"
CLIENT_CONFIG_DIR="/etc/wireguard/clients"
CLIENT_KEYS_DIR="/etc/wireguard/keys"
CLIENT_STATS_DB="/var/lib/ipv6-wireguard-manager/client_stats.db"

# 客户端状态
CLIENT_STATUS_ONLINE="online"
CLIENT_STATUS_OFFLINE="offline"
CLIENT_STATUS_UNKNOWN="unknown"

# 初始化客户端管理
init_client_management() {
    log_info "初始化客户端管理..."
    
    # 创建必要的目录
    mkdir -p "$CLIENT_CONFIG_DIR" "$CLIENT_KEYS_DIR"
    mkdir -p "$(dirname "$CLIENT_DB")" "$(dirname "$CLIENT_STATS_DB")"
    
    # 设置目录权限
    chmod 700 "$CLIENT_KEYS_DIR"
    chmod 755 "$CLIENT_CONFIG_DIR"
    
    # 初始化数据库
    init_client_databases
    
    log_info "客户端管理初始化完成"
}

# 初始化客户端数据库
init_client_databases() {
    log_info "初始化客户端数据库..."
    
    # 创建客户端数据库
    if [[ ! -f "$CLIENT_DB" ]]; then
        cat > "$CLIENT_DB" << EOF
# 客户端数据库
# 格式: client_id|name|ipv4_address|ipv6_address|public_key|private_key|created_time|updated_time|status|description|email|phone|department|notes
EOF
    fi
    
    # 创建客户端统计数据库
    if [[ ! -f "$CLIENT_STATS_DB" ]]; then
        cat > "$CLIENT_STATS_DB" << EOF
# 客户端统计数据库
# 格式: client_id|last_seen|bytes_received|bytes_sent|connection_count|total_uptime|last_ip
EOF
    fi
    
    log_info "客户端数据库初始化完成"
}

# 客户端管理主菜单
client_management_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 客户端管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 添加客户端"
        echo -e "${GREEN}2.${NC} 删除客户端"
        echo -e "${GREEN}3.${NC} 查看客户端列表"
        echo -e "${GREEN}4.${NC} 生成客户端配置"
        echo -e "${GREEN}5.${NC} 客户端状态查看"
        echo -e "${GREEN}6.${NC} 批量导入客户端"
        echo -e "${GREEN}7.${NC} 客户端配置修改"
        echo -e "${GREEN}8.${NC} 客户端数据库管理"
        echo -e "${GREEN}9.${NC} 客户端统计信息"
        echo -e "${GREEN}10.${NC} 客户端连接测试"
        echo -e "${GREEN}11.${NC} 实时监控客户端状态"
        echo -e "${GREEN}12.${NC} 批量删除客户端"
        echo -e "${GREEN}13.${NC} 批量导出客户端配置"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -p "请选择操作 [0-13]: " choice
        
        case $choice in
            1) add_client ;;
            2) remove_client ;;
            3) list_clients ;;
            4) generate_client_config ;;
            5) show_client_status ;;
            6) import_clients_batch ;;
            7) modify_client_config ;;
            8) manage_client_database ;;
            9) show_client_statistics ;;
            10) test_client_connection ;;
            11) real_time_client_monitoring ;;
            12) batch_delete_clients ;;
            13) batch_export_client_configs ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 添加客户端
add_client() {
    echo -e "${SECONDARY_COLOR}=== 添加客户端 ===${NC}"
    echo
    
    local client_name=$(show_input "客户端名称" "")
    local description=$(show_input "描述" "")
    local email=$(show_input "邮箱" "")
    local phone=$(show_input "电话" "")
    local department=$(show_input "部门" "")
    local notes=$(show_input "备注" "")
    
    if [[ -z "$client_name" ]]; then
        show_error "客户端名称不能为空"
        return 1
    fi
    
    # 检查客户端是否已存在
    if grep -q "^[^|]*|$client_name|" "$CLIENT_DB"; then
        show_error "客户端已存在: $client_name"
        return 1
    fi
    
    # 生成客户端ID
    local client_id="client_$(date +%s)_$(generate_random_string 8)"
    
    # 获取下一个可用的IP地址
    local ipv4_address=$(get_next_available_ip)
    local ipv6_address=$(get_next_available_ipv6)
    
    if [[ -z "$ipv4_address" ]] || [[ -z "$ipv6_address" ]]; then
        show_error "无法分配IP地址"
        return 1
    fi
    
    # 生成客户端密钥
    local client_private_key=$(generate_wireguard_key)
    local client_public_key=$(generate_wireguard_public_key "$client_private_key")
    
    if [[ -z "$client_private_key" ]] || [[ -z "$client_public_key" ]]; then
        show_error "密钥生成失败"
        return 1
    fi
    
    # 保存客户端密钥
    echo "$client_private_key" > "${CLIENT_KEYS_DIR}/${client_name}_private.key"
    echo "$client_public_key" > "${CLIENT_KEYS_DIR}/${client_name}_public.key"
    chmod 600 "${CLIENT_KEYS_DIR}/${client_name}_private.key"
    chmod 644 "${CLIENT_KEYS_DIR}/${client_name}_public.key"
    
    # 创建客户端配置
    create_client_config_file "$client_name" "$client_private_key" "$ipv4_address" "$ipv6_address"
    
    # 添加到服务器配置
    add_client_to_server_config "$client_name" "$client_public_key" "$ipv4_address" "$ipv6_address"
    
    # 添加到数据库
    local timestamp=$(get_timestamp)
    echo "$client_id|$client_name|$ipv4_address|$ipv6_address|$client_public_key|$client_private_key|$timestamp|$timestamp|$CLIENT_STATUS_OFFLINE|$description|$email|$phone|$department|$notes" >> "$CLIENT_DB"
    
    # 初始化统计记录
    echo "$client_id|$timestamp|0|0|0|0|" >> "$CLIENT_STATS_DB"
    
    # 重载WireGuard配置
    reload_wireguard_config
    
    log_info "客户端添加成功: $client_name"
    log_info "IPv4地址: $ipv4_address"
    log_info "IPv6地址: $ipv6_address"
    log_info "配置文件: ${CLIENT_CONFIG_DIR}/${client_name}.conf"
}

# 删除客户端
remove_client() {
    echo -e "${SECONDARY_COLOR}=== 删除客户端 ===${NC}"
    echo
    
    # 显示客户端列表
    list_clients
    echo
    
    local client_name=$(show_input "要删除的客户端名称" "")
    
    if [[ -z "$client_name" ]]; then
        show_error "客户端名称不能为空"
        return 1
    fi
    
    # 检查客户端是否存在
    if ! grep -q "^[^|]*|$client_name|" "$CLIENT_DB"; then
        show_error "客户端不存在: $client_name"
        return 1
    fi
    
    if show_confirm "确认删除客户端: $client_name"; then
        # 从服务器配置中删除客户端
        remove_wireguard_client "$client_name"
        
        # 删除客户端文件
        rm -f "${CLIENT_KEYS_DIR}/${client_name}_private.key"
        rm -f "${CLIENT_KEYS_DIR}/${client_name}_public.key"
        rm -f "${CLIENT_CONFIG_DIR}/${client_name}.conf"
        
        # 从数据库删除
        grep -v "^[^|]*|$client_name|" "$CLIENT_DB" > "${CLIENT_DB}.tmp"
        mv "${CLIENT_DB}.tmp" "$CLIENT_DB"
        
        # 删除统计记录
        local client_id=$(grep "^[^|]*|$client_name|" "$CLIENT_DB" | cut -d'|' -f1)
        if [[ -n "$client_id" ]]; then
            grep -v "^$client_id|" "$CLIENT_STATS_DB" > "${CLIENT_STATS_DB}.tmp"
            mv "${CLIENT_STATS_DB}.tmp" "$CLIENT_STATS_DB"
        fi
        
        # 重载WireGuard配置
        reload_wireguard_config
        
        log_info "客户端删除成功: $client_name"
    fi
}

# 列出客户端
list_clients() {
    log_info "客户端列表:"
    echo "----------------------------------------"
    printf "%-20s %-15s %-25s %-10s %-20s %-15s\n" "客户端名称" "IPv4地址" "IPv6地址" "状态" "最后连接" "部门"
    printf "%-20s %-15s %-25s %-10s %-20s %-15s\n" "--------------------" "---------------" "-------------------------" "----------" "--------------------" "---------------"
    
    if [[ -f "$CLIENT_DB" ]]; then
        while IFS='|' read -ra fields; do
            if [[ ${#fields[@]} -ge 14 ]]; then
                local name="${fields[1]}"
                local ipv4="${fields[2]}"
                local ipv6="${fields[3]}"
                local status="${fields[8]}"
                local department="${fields[12]}"
                
                # 获取最后连接时间
                local last_seen=""
                if [[ -f "$CLIENT_STATS_DB" ]]; then
                    local client_id="${fields[0]}"
                    last_seen=$(grep "^$client_id|" "$CLIENT_STATS_DB" | cut -d'|' -f2)
                fi
                
                # 检查实际连接状态
                local actual_status=$(check_client_connection_status "$ipv4")
                if [[ "$actual_status" != "$status" ]]; then
                    status="$actual_status"
                    # 更新数据库中的状态
                    update_client_status "$name" "$status"
                fi
                
                printf "%-20s %-15s %-25s %-10s %-20s %-15s\n" \
                    "$name" "$ipv4" "$ipv6" "$status" "$last_seen" "$department"
            fi
        done < "$CLIENT_DB"
    else
        log_info "没有客户端记录"
    fi
}

# 生成客户端配置
generate_client_config() {
    echo -e "${SECONDARY_COLOR}=== 生成客户端配置 ===${NC}"
    echo
    
    # 显示客户端列表
    list_clients
    echo
    
    local client_name=$(show_input "客户端名称" "")
    local output_format=$(show_selection "输出格式" "file" "qr" "text" "url")
    
    if [[ -z "$client_name" ]]; then
        show_error "客户端名称不能为空"
        return 1
    fi
    
    local config_file="${CLIENT_CONFIG_DIR}/${client_name}.conf"
    
    if [[ ! -f "$config_file" ]]; then
        show_error "客户端配置文件不存在: $client_name"
        return 1
    fi
    
    case "$output_format" in
        "file")
            echo "配置文件路径: $config_file"
            ;;
        "qr")
            if command -v qrencode &> /dev/null; then
                echo "客户端配置QR码:"
                qrencode -t ansiutf8 < "$config_file"
            else
                show_error "qrencode未安装，无法生成QR码"
                return 1
            fi
            ;;
        "text")
            echo "客户端配置内容:"
            echo "----------------------------------------"
            cat "$config_file"
            ;;
        "url")
            # 生成安装URL
            local install_url=$(generate_client_install_url "$client_name")
            echo "客户端安装URL: $install_url"
            ;;
        *)
            show_error "不支持的输出格式: $output_format"
            return 1
            ;;
    esac
}

# 显示客户端状态
show_client_status() {
    echo -e "${SECONDARY_COLOR}=== 客户端状态 ===${NC}"
    echo
    
    local client_name=$(show_input "客户端名称" "")
    
    if [[ -z "$client_name" ]]; then
        show_error "客户端名称不能为空"
        return 1
    fi
    
    # 获取客户端信息
    local client_info=$(grep "^[^|]*|$client_name|" "$CLIENT_DB")
    if [[ -z "$client_info" ]]; then
        show_error "客户端不存在: $client_name"
        return 1
    fi
    
    IFS='|' read -ra fields <<< "$client_info"
    local client_id="${fields[0]}"
    local ipv4="${fields[2]}"
    local ipv6="${fields[3]}"
    local public_key="${fields[4]}"
    local created_time="${fields[6]}"
    local updated_time="${fields[7]}"
    local status="${fields[8]}"
    local description="${fields[9]}"
    
    echo "客户端信息:"
    echo "  名称: $client_name"
    echo "  IPv4地址: $ipv4"
    echo "  IPv6地址: $ipv6"
    echo "  公钥: $public_key"
    echo "  状态: $status"
    echo "  描述: $description"
    echo "  创建时间: $created_time"
    echo "  更新时间: $updated_time"
    echo
    
    # 获取统计信息
    local stats_info=$(grep "^$client_id|" "$CLIENT_STATS_DB")
    if [[ -n "$stats_info" ]]; then
        IFS='|' read -ra stats_fields <<< "$stats_info"
        local last_seen="${stats_fields[1]}"
        local bytes_received="${stats_fields[2]}"
        local bytes_sent="${stats_fields[3]}"
        local connection_count="${stats_fields[4]}"
        local total_uptime="${stats_fields[5]}"
        local last_ip="${stats_fields[6]}"
        
        echo "统计信息:"
        echo "  最后连接: $last_seen"
        echo "  接收字节: $bytes_received"
        echo "  发送字节: $bytes_sent"
        echo "  连接次数: $connection_count"
        echo "  总运行时间: $total_uptime"
        echo "  最后IP: $last_ip"
    fi
    
    # 检查WireGuard连接状态
    echo
    echo "WireGuard连接状态:"
    if command -v wg &> /dev/null; then
        wg show | grep -A 5 "$public_key" || echo "  未连接"
    else
        echo "  WireGuard工具未安装"
    fi
}

# 批量导入客户端
import_clients_batch() {
    echo -e "${SECONDARY_COLOR}=== 批量导入客户端 ===${NC}"
    echo
    
    local csv_file=$(show_input "CSV文件路径" "")
    
    if [[ -z "$csv_file" ]] || [[ ! -f "$csv_file" ]]; then
        show_error "CSV文件不存在"
        return 1
    fi
    
    log_info "开始批量导入客户端..."
    
    local success_count=0
    local error_count=0
    local line_number=0
    
    while IFS=',' read -ra fields; do
        ((line_number++))
        
        # 跳过标题行
        if [[ $line_number -eq 1 ]]; then
            continue
        fi
        
        # 检查字段数量
        if [[ ${#fields[@]} -lt 4 ]]; then
            log_warn "第 $line_number 行字段不足，跳过"
            ((error_count++))
            continue
        fi
        
        local name=$(trim "${fields[0]}")
        local ipv4=$(trim "${fields[1]}")
        local ipv6=$(trim "${fields[2]}")
        local description=$(trim "${fields[3]}")
        local email=$(trim "${fields[4]:-}")
        local phone=$(trim "${fields[5]:-}")
        local department=$(trim "${fields[6]:-}")
        local notes=$(trim "${fields[7]:-}")
        
        # 验证必需字段
        if [[ -z "$name" ]] || [[ -z "$ipv4" ]] || [[ -z "$ipv6" ]]; then
            log_warn "第 $line_number 行必需字段缺失，跳过"
            ((error_count++))
            continue
        fi
        
        # 检查客户端是否已存在
        if grep -q "^[^|]*|$name|" "$CLIENT_DB"; then
            log_warn "客户端已存在: $name，跳过"
            ((error_count++))
            continue
        fi
        
        # 添加客户端
        if add_client_from_csv "$name" "$ipv4" "$ipv6" "$description" "$email" "$phone" "$department" "$notes"; then
            ((success_count++))
            log_info "客户端导入成功: $name"
        else
            ((error_count++))
            log_error "客户端导入失败: $name"
        fi
        
    done < "$csv_file"
    
    log_info "批量导入完成: 成功 $success_count, 失败 $error_count"
}

# 从CSV添加客户端
add_client_from_csv() {
    local name="$1"
    local ipv4="$2"
    local ipv6="$3"
    local description="$4"
    local email="$5"
    local phone="$6"
    local department="$7"
    local notes="$8"
    
    # 生成客户端ID
    local client_id="client_$(date +%s)_$(generate_random_string 8)"
    
    # 生成客户端密钥
    local client_private_key=$(generate_wireguard_key)
    local client_public_key=$(generate_wireguard_public_key "$client_private_key")
    
    if [[ -z "$client_private_key" ]] || [[ -z "$client_public_key" ]]; then
        return 1
    fi
    
    # 保存客户端密钥
    echo "$client_private_key" > "${CLIENT_KEYS_DIR}/${name}_private.key"
    echo "$client_public_key" > "${CLIENT_KEYS_DIR}/${name}_public.key"
    chmod 600 "${CLIENT_KEYS_DIR}/${name}_private.key"
    chmod 644 "${CLIENT_KEYS_DIR}/${name}_public.key"
    
    # 创建客户端配置
    create_client_config_file "$name" "$client_private_key" "$ipv4" "$ipv6"
    
    # 添加到服务器配置
    add_client_to_server_config "$name" "$client_public_key" "$ipv4" "$ipv6"
    
    # 添加到数据库
    local timestamp=$(get_timestamp)
    echo "$client_id|$name|$ipv4|$ipv6|$client_public_key|$client_private_key|$timestamp|$timestamp|$CLIENT_STATUS_OFFLINE|$description|$email|$phone|$department|$notes" >> "$CLIENT_DB"
    
    # 初始化统计记录
    echo "$client_id|$timestamp|0|0|0|0|" >> "$CLIENT_STATS_DB"
    
    return 0
}

# 修改客户端配置
modify_client_config() {
    echo -e "${SECONDARY_COLOR}=== 修改客户端配置 ===${NC}"
    echo
    
    local client_name=$(show_input "客户端名称" "")
    
    if [[ -z "$client_name" ]]; then
        show_error "客户端名称不能为空"
        return 1
    fi
    
    # 检查客户端是否存在
    if ! grep -q "^[^|]*|$client_name|" "$CLIENT_DB"; then
        show_error "客户端不存在: $client_name"
        return 1
    fi
    
    echo "修改选项:"
    echo "1. 修改描述"
    echo "2. 修改邮箱"
    echo "3. 修改电话"
    echo "4. 修改部门"
    echo "5. 修改备注"
    echo "6. 重新生成密钥"
    echo "7. 修改IP地址"
    
    local choice=$(show_input "选择操作" "")
    
    case $choice in
        1)
            local new_description=$(show_input "新描述" "")
            update_client_field "$client_name" "description" "$new_description"
            ;;
        2)
            local new_email=$(show_input "新邮箱" "")
            update_client_field "$client_name" "email" "$new_email"
            ;;
        3)
            local new_phone=$(show_input "新电话" "")
            update_client_field "$client_name" "phone" "$new_phone"
            ;;
        4)
            local new_department=$(show_input "新部门" "")
            update_client_field "$client_name" "department" "$new_department"
            ;;
        5)
            local new_notes=$(show_input "新备注" "")
            update_client_field "$client_name" "notes" "$new_notes"
            ;;
        6)
            regenerate_client_keys "$client_name"
            ;;
        7)
            modify_client_ip_addresses "$client_name"
            ;;
        *)
            show_error "无效选择"
            ;;
    esac
}

# 客户端数据库管理
manage_client_database() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 客户端数据库管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看数据库统计"
        echo -e "${GREEN}2.${NC} 清理数据库"
        echo -e "${GREEN}3.${NC} 备份数据库"
        echo -e "${GREEN}4.${NC} 恢复数据库"
        echo -e "${GREEN}5.${NC} 导出数据库"
        echo -e "${GREEN}6.${NC} 导入数据库"
        echo -e "${GREEN}7.${NC} 数据库完整性检查"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -p "请选择操作 [0-7]: " choice
        
        case $choice in
            1) show_database_statistics ;;
            2) cleanup_database ;;
            3) backup_database ;;
            4) restore_database ;;
            5) export_database ;;
            6) import_database ;;
            7) check_database_integrity ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 显示客户端统计信息
show_client_statistics() {
    log_info "客户端统计信息:"
    echo "----------------------------------------"
    
    if [[ -f "$CLIENT_DB" ]]; then
        local total_clients=$(wc -l < "$CLIENT_DB")
        local online_clients=$(grep "|$CLIENT_STATUS_ONLINE|" "$CLIENT_DB" | wc -l)
        local offline_clients=$(grep "|$CLIENT_STATUS_OFFLINE|" "$CLIENT_DB" | wc -l)
        
        echo "总客户端数: $total_clients"
        echo "在线客户端: $online_clients"
        echo "离线客户端: $offline_clients"
        echo
        
        # 按部门统计
        echo "按部门统计:"
        cut -d'|' -f13 "$CLIENT_DB" | sort | uniq -c | sort -nr | head -10
        echo
        
        # 最近创建的客户端
        echo "最近创建的客户端:"
        tail -5 "$CLIENT_DB" | while IFS='|' read -ra fields; do
            echo "  ${fields[1]} (${fields[6]})"
        done
    else
        log_info "客户端数据库不存在"
    fi
}

# 测试客户端连接
test_client_connection() {
    echo -e "${SECONDARY_COLOR}=== 客户端连接测试 ===${NC}"
    echo
    
    local client_name=$(show_input "客户端名称" "")
    
    if [[ -z "$client_name" ]]; then
        show_error "客户端名称不能为空"
        return 1
    fi
    
    # 获取客户端信息
    local client_info=$(grep "^[^|]*|$client_name|" "$CLIENT_DB")
    if [[ -z "$client_info" ]]; then
        show_error "客户端不存在: $client_name"
        return 1
    fi
    
    IFS='|' read -ra fields <<< "$client_info"
    local ipv4="${fields[2]}"
    local ipv6="${fields[3]}"
    
    log_info "测试客户端连接: $client_name"
    echo "IPv4地址: $ipv4"
    echo "IPv6地址: $ipv6"
    echo
    
    # 测试IPv4连接
    echo "IPv4连接测试:"
    if ping -c 3 "$ipv4" &>/dev/null; then
        show_success "IPv4连接正常"
    else
        show_error "IPv4连接失败"
    fi
    
    # 测试IPv6连接
    echo "IPv6连接测试:"
    if ping6 -c 3 "$ipv6" &>/dev/null; then
        show_success "IPv6连接正常"
    else
        show_error "IPv6连接失败"
    fi
    
    # 测试WireGuard连接
    echo "WireGuard连接测试:"
    if command -v wg &> /dev/null; then
        local public_key="${fields[4]}"
        if wg show | grep -q "$public_key"; then
            show_success "WireGuard连接正常"
        else
            show_error "WireGuard连接失败"
        fi
    else
        show_warning "WireGuard工具未安装"
    fi
}

# 辅助函数

# 创建客户端配置文件
create_client_config_file() {
    local client_name="$1"
    local private_key="$2"
    local ipv4_address="$3"
    local ipv6_address="$4"
    
    # 获取服务器信息
    local server_public_key=$(cat "${WIREGUARD_KEYS_DIR}/server_public.key")
    local server_endpoint=$(get_public_ipv4)
    local server_port="${WIREGUARD_PORT:-51820}"
    
    # 创建客户端配置
    cat > "${CLIENT_CONFIG_DIR}/${client_name}.conf" << EOF
[Interface]
PrivateKey = $private_key
Address = $ipv4_address/32, $ipv6_address/128
DNS = 8.8.8.8, 2001:4860:4860::8888

[Peer]
PublicKey = $server_public_key
Endpoint = $server_endpoint:$server_port
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
    
    chmod 600 "${CLIENT_CONFIG_DIR}/${client_name}.conf"
}

# 检查客户端连接状态
check_client_connection_status() {
    local ipv4_address="$1"
    
    if command -v wg &> /dev/null; then
        if wg show | grep -q "$ipv4_address"; then
            echo "$CLIENT_STATUS_ONLINE"
        else
            echo "$CLIENT_STATUS_OFFLINE"
        fi
    else
        echo "$CLIENT_STATUS_UNKNOWN"
    fi
}

# 更新客户端状态
update_client_status() {
    local client_name="$1"
    local status="$2"
    local timestamp=$(get_timestamp)
    
    # 更新数据库中的状态
    sed -i "s/^\([^|]*|$client_name|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|\)[^|]*\(|.*\)/\1$timestamp\2/" "$CLIENT_DB"
    sed -i "s/^\([^|]*|$client_name|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|\)[^|]*\(|.*\)/\1$status\2/" "$CLIENT_DB"
}

# 更新客户端字段
update_client_field() {
    local client_name="$1"
    local field="$2"
    local value="$3"
    local timestamp=$(get_timestamp)
    
    # 根据字段名确定位置
    local field_position=0
    case "$field" in
        "description") field_position=9 ;;
        "email") field_position=10 ;;
        "phone") field_position=11 ;;
        "department") field_position=12 ;;
        "notes") field_position=13 ;;
        *) show_error "未知字段: $field"; return 1 ;;
    esac
    
    # 更新数据库
    local temp_file=$(create_temp_file "client_db")
    while IFS='|' read -ra fields; do
        if [[ "${fields[1]}" == "$client_name" ]]; then
            fields[$field_position]="$value"
            fields[7]="$timestamp"  # 更新时间
        fi
        echo "$(array_join "|" "${fields[@]}")" >> "$temp_file"
    done < "$CLIENT_DB"
    
    mv "$temp_file" "$CLIENT_DB"
    log_info "客户端字段更新成功: $client_name -> $field = $value"
}

# 重新生成客户端密钥
regenerate_client_keys() {
    local client_name="$1"
    
    if show_confirm "确认重新生成客户端密钥: $client_name"; then
        # 生成新密钥
        local new_private_key=$(generate_wireguard_key)
        local new_public_key=$(generate_wireguard_public_key "$new_private_key")
        
        # 更新密钥文件
        echo "$new_private_key" > "${CLIENT_KEYS_DIR}/${client_name}_private.key"
        echo "$new_public_key" > "${CLIENT_KEYS_DIR}/${client_name}_public.key"
        
        # 更新客户端配置
        local config_file="${CLIENT_CONFIG_DIR}/${client_name}.conf"
        sed -i "s/PrivateKey = .*/PrivateKey = $new_private_key/" "$config_file"
        
        # 更新服务器配置
        # 这里需要更新服务器配置中的公钥
        
        # 更新数据库
        update_client_field "$client_name" "public_key" "$new_public_key"
        update_client_field "$client_name" "private_key" "$new_private_key"
        
        # 重载配置
        reload_wireguard_config
        
        log_info "客户端密钥重新生成成功: $client_name"
    fi
}

# 修改客户端IP地址
modify_client_ip_addresses() {
    local client_name="$1"
    
    local new_ipv4=$(show_input "新IPv4地址" "" "validate_ipv4")
    local new_ipv6=$(show_input "新IPv6地址" "" "validate_ipv6")
    
    if [[ -z "$new_ipv4" ]] || [[ -z "$new_ipv6" ]]; then
        show_error "IP地址不能为空"
        return 1
    fi
    
    # 更新客户端配置
    local config_file="${CLIENT_CONFIG_DIR}/${client_name}.conf"
    sed -i "s/Address = .*/Address = $new_ipv4\/32, $new_ipv6\/128/" "$config_file"
    
    # 更新服务器配置
    # 这里需要更新服务器配置中的IP地址
    
    # 更新数据库
    update_client_field "$client_name" "ipv4_address" "$new_ipv4"
    update_client_field "$client_name" "ipv6_address" "$new_ipv6"
    
    # 重载配置
    reload_wireguard_config
    
    log_info "客户端IP地址修改成功: $client_name"
}

# 生成客户端安装URL
generate_client_install_url() {
    local client_name="$1"
    local server_ip=$(get_public_ipv4)
    local server_port="${WEB_PORT:-8080}"
    local token=$(generate_random_string 32)
    
    echo "http://$server_ip:$server_port/install?client=$client_name&token=$token"
}

# 数据库管理函数
show_database_statistics() {
    log_info "数据库统计信息:"
    echo "----------------------------------------"
    
    if [[ -f "$CLIENT_DB" ]]; then
        local db_size=$(stat -c%s "$CLIENT_DB")
        local record_count=$(wc -l < "$CLIENT_DB")
        echo "客户端数据库:"
        echo "  文件大小: $db_size 字节"
        echo "  记录数量: $record_count"
    fi
    
    if [[ -f "$CLIENT_STATS_DB" ]]; then
        local stats_size=$(stat -c%s "$CLIENT_STATS_DB")
        local stats_count=$(wc -l < "$CLIENT_STATS_DB")
        echo "统计数据库:"
        echo "  文件大小: $stats_size 字节"
        echo "  记录数量: $stats_count"
    fi
}

cleanup_database() {
    log_info "清理数据库..."
    
    # 清理无效记录
    local temp_file=$(create_temp_file "client_db")
    while IFS='|' read -ra fields; do
        if [[ ${#fields[@]} -ge 14 ]]; then
            echo "$(array_join "|" "${fields[@]}")" >> "$temp_file"
        fi
    done < "$CLIENT_DB"
    
    mv "$temp_file" "$CLIENT_DB"
    log_info "数据库清理完成"
}

backup_database() {
    local backup_dir="${BACKUP_DIR}/clients"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${backup_dir}/client_db_${timestamp}.tar.gz"
    
    mkdir -p "$backup_dir"
    
    tar -czf "$backup_file" "$CLIENT_DB" "$CLIENT_STATS_DB" 2>/dev/null
    
    log_info "数据库备份成功: $backup_file"
}

restore_database() {
    local backup_file=$(show_input "备份文件路径" "")
    
    if [[ -z "$backup_file" ]] || [[ ! -f "$backup_file" ]]; then
        show_error "备份文件不存在"
        return 1
    fi
    
    # 备份当前数据库
    backup_database
    
    # 恢复数据库
    tar -xzf "$backup_file" -C "$(dirname "$CLIENT_DB")" 2>/dev/null
    
    log_info "数据库恢复成功"
}

export_database() {
    local output_file=$(show_input "输出文件路径" "/tmp/client_db_$(date +%Y%m%d_%H%M%S).csv")
    
    if [[ -f "$CLIENT_DB" ]]; then
        cp "$CLIENT_DB" "$output_file"
        log_info "数据库导出成功: $output_file"
    else
        show_error "客户端数据库不存在"
    fi
}

import_database() {
    local input_file=$(show_input "输入文件路径" "")
    
    if [[ -z "$input_file" ]] || [[ ! -f "$input_file" ]]; then
        show_error "输入文件不存在"
        return 1
    fi
    
    # 备份当前数据库
    backup_database
    
    # 导入数据库
    cp "$input_file" "$CLIENT_DB"
    
    log_info "数据库导入成功"
}

check_database_integrity() {
    log_info "检查数据库完整性..."
    
    local errors=0
    
    if [[ -f "$CLIENT_DB" ]]; then
        while IFS='|' read -ra fields; do
            if [[ ${#fields[@]} -lt 14 ]]; then
                log_error "记录字段不足: ${#fields[@]} < 14"
                ((errors++))
            fi
        done < "$CLIENT_DB"
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_info "数据库完整性检查通过"
    else
        log_error "发现 $errors 个数据库完整性问题"
    fi
}

# 实时监控客户端状态
real_time_client_monitoring() {
    echo -e "${SECONDARY_COLOR}=== 实时监控客户端状态 ===${NC}"
    echo
    
    local refresh_interval=$(show_input "刷新间隔(秒)" "5")
    local max_duration=$(show_input "监控时长(分钟，0为无限)" "0")
    
    if [[ ! "$refresh_interval" =~ ^[0-9]+$ ]] || [[ "$refresh_interval" -lt 1 ]]; then
        refresh_interval=5
    fi
    
    if [[ ! "$max_duration" =~ ^[0-9]+$ ]]; then
        max_duration=0
    fi
    
    local start_time=$(date +%s)
    local end_time=$((start_time + max_duration * 60))
    
    echo "开始实时监控客户端状态..."
    echo "刷新间隔: ${refresh_interval}秒"
    if [[ $max_duration -gt 0 ]]; then
        echo "监控时长: ${max_duration}分钟"
    else
        echo "监控时长: 无限（按Ctrl+C退出）"
    fi
    echo "按 Ctrl+C 退出监控"
    echo
    
    # 设置信号处理
    trap 'echo -e "\n监控已停止"; return 0' INT
    
    while true; do
        # 检查是否超时
        if [[ $max_duration -gt 0 ]] && [[ $(date +%s) -ge $end_time ]]; then
            echo "监控时间已到，自动退出"
            break
        fi
        
        # 清屏并显示当前时间
        clear
        echo -e "${SECONDARY_COLOR}=== 实时监控客户端状态 ===${NC}"
        echo "当前时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "刷新间隔: ${refresh_interval}秒"
        echo
        
        # 显示客户端状态
        printf "%-20s %-15s %-25s %-10s %-20s %-15s\n" "客户端名称" "IPv4地址" "IPv6地址" "状态" "最后连接" "流量统计"
        printf "%-20s %-15s %-25s %-10s %-20s %-15s\n" "--------------------" "---------------" "-------------------------" "----------" "--------------------" "---------------"
        
        if [[ -f "$CLIENT_DB" ]]; then
            while IFS='|' read -ra fields; do
                if [[ ${#fields[@]} -ge 14 ]]; then
                    local name="${fields[1]}"
                    local ipv4="${fields[2]}"
                    local ipv6="${fields[3]}"
                    local client_id="${fields[0]}"
                    
                    # 检查实际连接状态
                    local actual_status=$(check_client_connection_status "$ipv4")
                    
                    # 获取最后连接时间
                    local last_seen=""
                    local traffic_stats=""
                    if [[ -f "$CLIENT_STATS_DB" ]]; then
                        local stats_info=$(grep "^$client_id|" "$CLIENT_STATS_DB")
                        if [[ -n "$stats_info" ]]; then
                            IFS='|' read -ra stats_fields <<< "$stats_info"
                            last_seen="${stats_fields[1]}"
                            local bytes_received="${stats_fields[2]}"
                            local bytes_sent="${stats_fields[3]}"
                            traffic_stats="${bytes_received}/${bytes_sent}"
                        fi
                    fi
                    
                    # 更新数据库中的状态
                    if [[ "$actual_status" != "${fields[8]}" ]]; then
                        update_client_status "$name" "$actual_status"
                    fi
                    
                    printf "%-20s %-15s %-25s %-10s %-20s %-15s\n" \
                        "$name" "$ipv4" "$ipv6" "$actual_status" "$last_seen" "$traffic_stats"
                fi
            done < "$CLIENT_DB"
        else
            echo "没有客户端记录"
        fi
        
        echo
        echo "按 Ctrl+C 退出监控"
        
        # 等待指定时间
        sleep "$refresh_interval"
    done
}

# 批量删除客户端
batch_delete_clients() {
    echo -e "${SECONDARY_COLOR}=== 批量删除客户端 ===${NC}"
    echo
    
    local delete_method=$(show_selection "删除方式" "选择客户端" "按条件删除" "删除所有")
    
    case "$delete_method" in
        "选择客户端")
            batch_delete_selected_clients
            ;;
        "按条件删除")
            batch_delete_by_condition
            ;;
        "删除所有")
            batch_delete_all_clients
            ;;
    esac
}

# 批量删除选中的客户端
batch_delete_selected_clients() {
    echo "请选择要删除的客户端（用逗号分隔序号）:"
    list_clients
    echo
    
    local selection=$(show_input "客户端序号" "")
    
    if [[ -z "$selection" ]]; then
        show_error "未选择任何客户端"
        return 1
    fi
    
    IFS=',' read -ra indices <<< "$selection"
    local deleted_count=0
    
    for index in "${indices[@]}"; do
        index=$(trim "$index")
        if [[ "$index" =~ ^[0-9]+$ ]]; then
            local client_name=$(get_client_name_by_index "$index")
            if [[ -n "$client_name" ]]; then
                if show_confirm "确认删除客户端: $client_name"; then
                    if remove_client_by_name "$client_name"; then
                        ((deleted_count++))
                        log_info "客户端删除成功: $client_name"
                    else
                        log_error "客户端删除失败: $client_name"
                    fi
                fi
            fi
        fi
    done
    
    log_info "批量删除完成: 成功删除 $deleted_count 个客户端"
}

# 按条件批量删除客户端
batch_delete_by_condition() {
    echo "按条件删除客户端:"
    echo "1. 按状态删除"
    echo "2. 按部门删除"
    echo "3. 按创建时间删除"
    
    local condition_type=$(show_input "选择条件类型" "")
    
    case "$condition_type" in
        1)
            local status=$(show_selection "客户端状态" "offline" "online" "unknown")
            batch_delete_by_status "$status"
            ;;
        2)
            local department=$(show_input "部门名称" "")
            batch_delete_by_department "$department"
            ;;
        3)
            local days=$(show_input "删除多少天前创建的客户端" "30")
            batch_delete_by_creation_time "$days"
            ;;
        *)
            show_error "无效的条件类型"
            ;;
    esac
}

# 批量删除所有客户端
batch_delete_all_clients() {
    if show_confirm "确认删除所有客户端？此操作不可恢复！"; then
        if show_confirm "再次确认：真的要删除所有客户端吗？"; then
            local total_count=$(wc -l < "$CLIENT_DB" 2>/dev/null || echo "0")
            local deleted_count=0
            
            while IFS='|' read -ra fields; do
                if [[ ${#fields[@]} -ge 14 ]]; then
                    local client_name="${fields[1]}"
                    if remove_client_by_name "$client_name"; then
                        ((deleted_count++))
                    fi
                fi
            done < "$CLIENT_DB"
            
            log_info "批量删除完成: 成功删除 $deleted_count/$total_count 个客户端"
        fi
    fi
}

# 批量导出客户端配置
batch_export_client_configs() {
    echo -e "${SECONDARY_COLOR}=== 批量导出客户端配置 ===${NC}"
    echo
    
    local export_format=$(show_selection "导出格式" "配置文件" "QR码" "安装链接" "CSV")
    local output_dir=$(show_input "输出目录" "/tmp/client_configs_$(date +%Y%m%d_%H%M%S)")
    
    if [[ -z "$output_dir" ]]; then
        show_error "输出目录不能为空"
        return 1
    fi
    
    mkdir -p "$output_dir"
    
    log_info "开始批量导出客户端配置..."
    log_info "导出格式: $export_format"
    log_info "输出目录: $output_dir"
    
    local success_count=0
    local error_count=0
    
    if [[ -f "$CLIENT_DB" ]]; then
        while IFS='|' read -ra fields; do
            if [[ ${#fields[@]} -ge 14 ]]; then
                local client_name="${fields[1]}"
                
                case "$export_format" in
                    "配置文件")
                        if export_client_config_file "$client_name" "$output_dir"; then
                            ((success_count++))
                        else
                            ((error_count++))
                        fi
                        ;;
                    "QR码")
                        if export_client_qr_code "$client_name" "$output_dir"; then
                            ((success_count++))
                        else
                            ((error_count++))
                        fi
                        ;;
                    "安装链接")
                        if export_client_install_url "$client_name" "$output_dir"; then
                            ((success_count++))
                        else
                            ((error_count++))
                        fi
                        ;;
                    "CSV")
                        if export_client_csv "$client_name" "$output_dir"; then
                            ((success_count++))
                        else
                            ((error_count++))
                        fi
                        ;;
                esac
            fi
        done < "$CLIENT_DB"
    else
        log_info "没有客户端记录"
        return 1
    fi
    
    log_info "批量导出完成: 成功 $success_count, 失败 $error_count"
    log_info "输出目录: $output_dir"
}

# 辅助函数

# 根据索引获取客户端名称
get_client_name_by_index() {
    local index="$1"
    local current_index=1
    
    if [[ -f "$CLIENT_DB" ]]; then
        while IFS='|' read -ra fields; do
            if [[ ${#fields[@]} -ge 14 ]]; then
                if [[ $current_index -eq $index ]]; then
                    echo "${fields[1]}"
                    return 0
                fi
                ((current_index++))
            fi
        done < "$CLIENT_DB"
    fi
    
    return 1
}

# 按名称删除客户端
remove_client_by_name() {
    local client_name="$1"
    
    # 从服务器配置中删除客户端
    remove_wireguard_client "$client_name"
    
    # 删除客户端文件
    rm -f "${CLIENT_KEYS_DIR}/${client_name}_private.key"
    rm -f "${CLIENT_KEYS_DIR}/${client_name}_public.key"
    rm -f "${CLIENT_CONFIG_DIR}/${client_name}.conf"
    
    # 从数据库删除
    grep -v "^[^|]*|$client_name|" "$CLIENT_DB" > "${CLIENT_DB}.tmp"
    mv "${CLIENT_DB}.tmp" "$CLIENT_DB"
    
    # 删除统计记录
    local client_id=$(grep "^[^|]*|$client_name|" "$CLIENT_DB" | cut -d'|' -f1)
    if [[ -n "$client_id" ]]; then
        grep -v "^$client_id|" "$CLIENT_STATS_DB" > "${CLIENT_STATS_DB}.tmp"
        mv "${CLIENT_STATS_DB}.tmp" "$CLIENT_STATS_DB"
    fi
    
    # 重载WireGuard配置
    reload_wireguard_config
    
    return 0
}

# 按状态批量删除
batch_delete_by_status() {
    local status="$1"
    local deleted_count=0
    
    while IFS='|' read -ra fields; do
        if [[ ${#fields[@]} -ge 14 ]] && [[ "${fields[8]}" == "$status" ]]; then
            local client_name="${fields[1]}"
            if show_confirm "删除客户端: $client_name (状态: $status)"; then
                if remove_client_by_name "$client_name"; then
                    ((deleted_count++))
                fi
            fi
        fi
    done < "$CLIENT_DB"
    
    log_info "按状态删除完成: 删除了 $deleted_count 个状态为 $status 的客户端"
}

# 按部门批量删除
batch_delete_by_department() {
    local department="$1"
    local deleted_count=0
    
    while IFS='|' read -ra fields; do
        if [[ ${#fields[@]} -ge 14 ]] && [[ "${fields[12]}" == "$department" ]]; then
            local client_name="${fields[1]}"
            if show_confirm "删除客户端: $client_name (部门: $department)"; then
                if remove_client_by_name "$client_name"; then
                    ((deleted_count++))
                fi
            fi
        fi
    done < "$CLIENT_DB"
    
    log_info "按部门删除完成: 删除了 $deleted_count 个部门为 $department 的客户端"
}

# 按创建时间批量删除
batch_delete_by_creation_time() {
    local days="$1"
    local deleted_count=0
    local cutoff_date=$(date -d "$days days ago" "+%Y-%m-%d" 2>/dev/null || date "+%Y-%m-%d")
    
    while IFS='|' read -ra fields; do
        if [[ ${#fields[@]} -ge 14 ]]; then
            local created_time="${fields[6]}"
            local created_date=$(echo "$created_time" | cut -d' ' -f1)
            
            if [[ "$created_date" < "$cutoff_date" ]]; then
                local client_name="${fields[1]}"
                if show_confirm "删除客户端: $client_name (创建于: $created_date)"; then
                    if remove_client_by_name "$client_name"; then
                        ((deleted_count++))
                    fi
                fi
            fi
        fi
    done < "$CLIENT_DB"
    
    log_info "按创建时间删除完成: 删除了 $deleted_count 个 $days 天前创建的客户端"
}

# 导出客户端配置文件
export_client_config_file() {
    local client_name="$1"
    local output_dir="$2"
    local config_file="${CLIENT_CONFIG_DIR}/${client_name}.conf"
    
    if [[ -f "$config_file" ]]; then
        cp "$config_file" "${output_dir}/${client_name}.conf"
        return 0
    else
        log_error "客户端配置文件不存在: $client_name"
        return 1
    fi
}

# 导出客户端QR码
export_client_qr_code() {
    local client_name="$1"
    local output_dir="$2"
    local config_file="${CLIENT_CONFIG_DIR}/${client_name}.conf"
    
    if [[ -f "$config_file" ]] && command -v qrencode &> /dev/null; then
        qrencode -t png -o "${output_dir}/${client_name}_qr.png" < "$config_file"
        return 0
    else
        log_error "无法生成QR码: $client_name"
        return 1
    fi
}

# 导出客户端安装链接
export_client_install_url() {
    local client_name="$1"
    local output_dir="$2"
    local install_url=$(generate_client_install_url "$client_name")
    
    echo "$client_name,$install_url" >> "${output_dir}/install_urls.csv"
    return 0
}

# 导出客户端CSV
export_client_csv() {
    local client_name="$1"
    local output_dir="$2"
    
    local client_info=$(grep "^[^|]*|$client_name|" "$CLIENT_DB")
    if [[ -n "$client_info" ]]; then
        echo "$client_info" >> "${output_dir}/clients.csv"
        return 0
    else
        log_error "客户端信息不存在: $client_name"
        return 1
    fi
}

# 导出函数
export -f init_client_management init_client_databases client_management_menu
export -f add_client remove_client list_clients generate_client_config show_client_status
export -f import_clients_batch add_client_from_csv modify_client_config manage_client_database
export -f show_client_statistics test_client_connection create_client_config_file
export -f check_client_connection_status update_client_status update_client_field
export -f regenerate_client_keys modify_client_ip_addresses generate_client_install_url
export -f show_database_statistics cleanup_database backup_database restore_database
export -f export_database import_database check_database_integrity
export -f real_time_client_monitoring batch_delete_clients batch_export_client_configs
export -f get_client_name_by_index remove_client_by_name batch_delete_by_status
export -f batch_delete_by_department batch_delete_by_creation_time
export -f export_client_config_file export_client_qr_code export_client_install_url export_client_csv
