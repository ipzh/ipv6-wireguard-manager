#!/bin/bash
# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"

# 确保日志相关变量已定义
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"
fi

# 客户端自动安装模块
# 负责客户端自动安装、远程安装、安装链接生成等功能

# 自动安装配置变量
AUTO_INSTALL_CONFIG_DIR="${CONFIG_DIR}/auto_install"
AUTO_INSTALL_CONFIG_FILE="${AUTO_INSTALL_CONFIG_DIR}/auto_install.conf"
INSTALL_TOKEN_DB="/var/lib/ipv6-wireguard-manager/install_tokens.db"
INSTALL_LOG_DB="/var/lib/ipv6-wireguard-manager/install_logs.db"

# 安装服务器配置
INSTALL_SERVER_PORT=8080
INSTALL_SERVER_HOST=""
INSTALL_BASE_URL=""
INSTALL_TOKEN_EXPIRY=3600
INSTALL_MAX_ATTEMPTS=3

# 支持的平台
SUPPORTED_PLATFORMS=("linux" "windows" "macos" "android" "ios")

# 初始化客户端自动安装
init_client_auto_install() {
    log_info "初始化客户端自动安装..."
    
    # 创建配置目录
    mkdir -p "$AUTO_INSTALL_CONFIG_DIR"
    mkdir -p "$(dirname "$INSTALL_TOKEN_DB")" "$(dirname "$INSTALL_LOG_DB")"
    
    # 创建配置文件
    create_auto_install_config
    
    # 初始化数据库
    init_auto_install_databases
    
    # 加载配置
    load_auto_install_config
    
    log_info "客户端自动安装初始化完成"
}

# 创建自动安装配置
create_auto_install_config() {
    if [[ ! -f "$AUTO_INSTALL_CONFIG_FILE" ]]; then
        cat > "$AUTO_INSTALL_CONFIG_FILE" << EOF
# 客户端自动安装配置文件
# 生成时间: $(get_timestamp)

# 安装服务器配置
INSTALL_SERVER_PORT=8080
INSTALL_SERVER_HOST=""
INSTALL_BASE_URL=""
INSTALL_SSL_ENABLED=false
INSTALL_SSL_CERT=""
INSTALL_SSL_KEY=""

# 安装令牌配置
INSTALL_TOKEN_EXPIRY=3600
INSTALL_TOKEN_LENGTH=32
INSTALL_MAX_ATTEMPTS=3
INSTALL_RATE_LIMIT=10

# 安装选项
INSTALL_AUTO_START=true
INSTALL_AUTO_CONNECT=true
INSTALL_QUIET_MODE=false
INSTALL_OVERWRITE=false
INSTALL_BACKUP_EXISTING=true

# 平台特定配置
LINUX_INSTALL_PATH="/etc/wireguard"
WINDOWS_INSTALL_PATH="C:\\Program Files\\WireGuard"
MACOS_INSTALL_PATH="/usr/local/etc/wireguard"
ANDROID_INSTALL_PATH="/data/data/com.wireguard.android"
IOS_INSTALL_PATH="/var/mobile/Library/Preferences"

# 安装脚本配置
INSTALL_SCRIPT_TEMPLATE="default"
INSTALL_SCRIPT_CUSTOM=""
INSTALL_SCRIPT_VALIDATION=true

# 安全配置
INSTALL_REQUIRE_AUTH=true
INSTALL_AUTH_METHOD="token"
INSTALL_IP_WHITELIST=""
INSTALL_USER_AGENT_FILTER=""

# 日志配置
INSTALL_LOG_ENABLED=true
INSTALL_LOG_LEVEL="INFO"
INSTALL_LOG_RETENTION=30

# 通知配置
INSTALL_NOTIFICATION_ENABLED=true
INSTALL_NOTIFICATION_EMAIL=""
INSTALL_NOTIFICATION_WEBHOOK=""
EOF
        log_info "自动安装配置文件已创建: $AUTO_INSTALL_CONFIG_FILE"
    fi
}

# 初始化自动安装数据库
init_auto_install_databases() {
    # 创建安装令牌数据库
    if [[ ! -f "$INSTALL_TOKEN_DB" ]]; then
        cat > "$INSTALL_TOKEN_DB" << EOF
# 安装令牌数据库
# 格式: token_id|client_name|token|created_time|expires_time|used|attempts|platform|ip_address|user_agent
EOF
    fi
    
    # 创建安装日志数据库
    if [[ ! -f "$INSTALL_LOG_DB" ]]; then
        cat > "$INSTALL_LOG_DB" << EOF
# 安装日志数据库
# 格式: log_id|timestamp|client_name|action|status|platform|ip_address|user_agent|error_message
EOF
    fi
    
    log_info "自动安装数据库初始化完成"
}

# 加载自动安装配置
load_auto_install_config() {
    if [[ -f "$AUTO_INSTALL_CONFIG_FILE" ]]; then
        source "$AUTO_INSTALL_CONFIG_FILE"
        log_info "自动安装配置已加载"
    fi
}

# 客户端自动安装主菜单
client_auto_install_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 客户端自动安装 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 生成一键安装链接"
        echo -e "${GREEN}2.${NC} 远程自动安装"
        echo -e "${GREEN}3.${NC} 管理安装令牌"
        echo -e "${GREEN}4.${NC} 查看安装日志"
        echo -e "${GREEN}5.${NC} 安装服务器配置"
        echo -e "${GREEN}6.${NC} 平台支持管理"
        echo -e "${GREEN}7.${NC} 安装脚本管理"
        echo -e "${GREEN}8.${NC} 安全设置"
        echo -e "${GREEN}9.${NC} 安装统计"
        echo -e "${GREEN}10.${NC} 安装测试"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -rp "请选择操作 [0-10]: " choice
        
        case $choice in
            1) generate_install_links ;;
            2) remote_auto_install ;;
            3) manage_install_tokens ;;
            4) view_install_logs ;;
            5) install_server_config ;;
            6) platform_support_management ;;
            7) install_script_management ;;
            8) security_settings ;;
            9) install_statistics ;;
            10) install_testing ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 生成一键安装链接
generate_install_links() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 生成一键安装链接 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 为单个客户端生成链接"
        echo -e "${GREEN}2.${NC} 为多个客户端生成链接"
        echo -e "${GREEN}3.${NC} 生成通用安装链接"
        echo -e "${GREEN}4.${NC} 生成平台特定链接"
        echo -e "${GREEN}5.${NC} 查看已生成的链接"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -rp "请选择操作 [0-5]: " choice
        
        case $choice in
            1) generate_single_client_link ;;
            2) generate_multiple_client_links ;;
            3) generate_generic_install_link ;;
            4) generate_platform_specific_links ;;
            5) view_generated_links ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 为单个客户端生成链接
generate_single_client_link() {
    echo -e "${SECONDARY_COLOR}=== 为单个客户端生成链接 ===${NC}"
    echo
    
    # 显示客户端列表
    if [[ -f "$CLIENT_DB" ]]; then
        echo "可用客户端:"
        cut -d'|' -f2 "$CLIENT_DB" | nl
        echo
    fi
    
    local client_name=$(show_input "客户端名称" "")
    local platform=$(show_selection "目标平台" "linux" "windows" "macos" "android" "ios")
    local expiry_hours=$(show_input "链接有效期(小时)" "24")
    local description=$(show_input "链接描述" "")
    
    if [[ -z "$client_name" ]]; then
        show_error "客户端名称不能为空"
        return 1
    fi
    
    # 验证客户端存在
    if ! grep -q "^[^|]*|$client_name|" "$CLIENT_DB"; then
        show_error "客户端不存在: $client_name"
        return 1
    fi
    
    # 生成安装令牌
    local token=$(generate_install_token "$client_name" "$platform" "$expiry_hours")
    
    if [[ -n "$token" ]]; then
        # 生成安装链接
        local install_url=$(generate_install_url "$client_name" "$token" "$platform")
        
        echo
        echo "安装链接生成成功:"
        echo "客户端: $client_name"
        echo "平台: $platform"
        echo "有效期: ${expiry_hours}小时"
        echo "安装链接: $install_url"
        echo
        
        # 生成QR码
        if command -v qrencode &> /dev/null; then
            echo "QR码:"
            qrencode -t ansiutf8 "$install_url"
        fi
        
        log_info "安装链接生成成功: $client_name -> $platform"
    else
        log_error "安装令牌生成失败"
    fi
}

# 为多个客户端生成链接
generate_multiple_client_links() {
    echo -e "${SECONDARY_COLOR}=== 为多个客户端生成链接 ===${NC}"
    echo
    
    local platform=$(show_selection "目标平台" "linux" "windows" "macos" "android" "ios")
    local expiry_hours=$(show_input "链接有效期(小时)" "24")
    local output_file=$(show_input "输出文件路径" "/tmp/install_links_$(date +%Y%m%d_%H%M%S).txt")
    
    if [[ ! -f "$CLIENT_DB" ]]; then
        show_error "客户端数据库不存在"
        return 1
    fi
    
    log_info "为多个客户端生成安装链接..."
    
    local success_count=0
    local error_count=0
    
    # 创建输出文件
    cat > "$output_file" << EOF
# 客户端安装链接列表
# 生成时间: $(get_timestamp)
# 平台: $platform
# 有效期: ${expiry_hours}小时

EOF
    
    while IFS='|' read -ra fields; do
        if [[ ${#fields[@]} -ge 14 ]]; then
            local client_name="${fields[1]}"
            local token=$(generate_install_token "$client_name" "$platform" "$expiry_hours")
            
            if [[ -n "$token" ]]; then
                local install_url=$(generate_install_url "$client_name" "$token" "$platform")
                echo "$client_name|$install_url" >> "$output_file"
                ((success_count++))
            else
                echo "$client_name|ERROR: 令牌生成失败" >> "$output_file"
                ((error_count++))
            fi
        fi
    done < "$CLIENT_DB"
    
    echo "" >> "$output_file"
    echo "# 统计信息" >> "$output_file"
    echo "# 成功: $success_count" >> "$output_file"
    echo "# 失败: $error_count" >> "$output_file"
    
    log_info "批量安装链接生成完成: 成功 $success_count, 失败 $error_count"
    log_info "输出文件: $output_file"
}

# 生成通用安装链接
generate_generic_install_link() {
    echo -e "${SECONDARY_COLOR}=== 生成通用安装链接 ===${NC}"
    echo
    
    local platform=$(show_selection "目标平台" "linux" "windows" "macos" "android" "ios")
    local expiry_hours=$(show_input "链接有效期(小时)" "24")
    local description=$(show_input "链接描述" "")
    
    # 生成通用令牌
    local token=$(generate_generic_install_token "$platform" "$expiry_hours")
    
    if [[ -n "$token" ]]; then
        local install_url=$(generate_generic_install_url "$token" "$platform")
        
        echo
        echo "通用安装链接生成成功:"
        echo "平台: $platform"
        echo "有效期: ${expiry_hours}小时"
        echo "描述: $description"
        echo "安装链接: $install_url"
        echo
        
        log_info "通用安装链接生成成功: $platform"
    else
        log_error "通用安装令牌生成失败"
    fi
}

# 生成平台特定链接
generate_platform_specific_links() {
    echo -e "${SECONDARY_COLOR}=== 生成平台特定链接 ===${NC}"
    echo
    
    local client_name=$(show_input "客户端名称" "")
    local expiry_hours=$(show_input "链接有效期(小时)" "24")
    
    if [[ -z "$client_name" ]]; then
        show_error "客户端名称不能为空"
        return 1
    fi
    
    echo "为所有支持的平台生成安装链接:"
    
    for platform in "${SUPPORTED_PLATFORMS[@]}"; do
        local token=$(generate_install_token "$client_name" "$platform" "$expiry_hours")
        
        if [[ -n "$token" ]]; then
            local install_url=$(generate_install_url "$client_name" "$token" "$platform")
            echo "  $platform: $install_url"
        else
            echo "  $platform: ERROR - 令牌生成失败"
        fi
    done
    
    log_info "平台特定链接生成完成: $client_name"
}

# 查看已生成的链接
view_generated_links() {
    log_info "已生成的安装链接:"
    echo "----------------------------------------"
    
    if [[ -f "$INSTALL_TOKEN_DB" ]]; then
        printf "%-20s %-10s %-20s %-15s %-10s %-15s\n" "客户端" "平台" "令牌" "创建时间" "过期时间" "状态"
        printf "%-20s %-10s %-20s %-15s %-10s %-15s\n" "--------------------" "----------" "--------------------" "---------------" "----------" "---------------"
        
        while IFS='|' read -ra fields; do
            if [[ ${#fields[@]} -ge 10 ]]; then
                local client_name="${fields[1]}"
                local token="${fields[2]}"
                local created_time="${fields[3]}"
                local expires_time="${fields[4]}"
                local used="${fields[5]}"
                local platform="${fields[7]}"
                
                local status="未使用"
                if [[ "$used" == "true" ]]; then
                    status="已使用"
                elif [[ "$expires_time" < "$(date +%Y-%m-%d\ %H:%M:%S)" ]]; then
                    status="已过期"
                fi
                
                printf "%-20s %-10s %-20s %-15s %-10s %-15s\n" \
                    "$client_name" "$platform" "${token:0:20}..." "$created_time" "$expires_time" "$status"
            fi
        done < "$INSTALL_TOKEN_DB" | tail -20
    else
        log_info "没有已生成的安装链接"
    fi
}

# 远程自动安装
remote_auto_install() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 远程自动安装 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 基于IP的远程安装"
        echo -e "${GREEN}2.${NC} 基于SSH的远程安装"
        echo -e "${GREEN}3.${NC} 基于API的远程安装"
        echo -e "${GREEN}4.${NC} 批量远程安装"
        echo -e "${GREEN}5.${NC} 远程安装监控"
        echo -e "${GREEN}6.${NC} 远程安装配置"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -rp "请选择操作 [0-6]: " choice
        
        case $choice in
            1) ip_based_remote_install ;;
            2) ssh_based_remote_install ;;
            3) api_based_remote_install ;;
            4) batch_remote_install ;;
            5) remote_install_monitoring ;;
            6) remote_install_config ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 基于IP的远程安装
ip_based_remote_install() {
    echo -e "${SECONDARY_COLOR}=== 基于IP的远程安装 ===${NC}"
    echo
    
    local target_ip=$(show_input "目标IP地址" "" "validate_ipv4")
    local client_name=$(show_input "客户端名称" "")
    local platform=$(show_selection "目标平台" "linux" "windows" "macos")
    local install_method=$(show_selection "安装方法" "http" "https" "ftp" "scp")
    
    if [[ -z "$target_ip" ]] || [[ -z "$client_name" ]]; then
        show_error "IP地址和客户端名称不能为空"
        return 1
    fi
    
    # 验证客户端存在
    if ! grep -q "^[^|]*|$client_name|" "$CLIENT_DB"; then
        show_error "客户端不存在: $client_name"
        return 1
    fi
    
    log_info "开始基于IP的远程安装: $target_ip -> $client_name"
    
    # 生成安装令牌
    local token=$(generate_install_token "$client_name" "$platform" "1")
    
    if [[ -n "$token" ]]; then
        # 创建安装脚本
        local install_script=$(create_remote_install_script "$client_name" "$platform" "$token")
        
        # 传输安装脚本
        if transfer_install_script "$install_script" "$target_ip" "$install_method"; then
            # 执行远程安装
            if execute_remote_install "$target_ip" "$install_script" "$platform"; then
                log_info "远程安装成功: $target_ip -> $client_name"
            else
                log_error "远程安装执行失败"
            fi
        else
            log_error "安装脚本传输失败"
        fi
    else
        log_error "安装令牌生成失败"
    fi
}

# 基于SSH的远程安装
ssh_based_remote_install() {
    echo -e "${SECONDARY_COLOR}=== 基于SSH的远程安装 ===${NC}"
    echo
    
    local target_host=$(show_input "目标主机" "")
    local ssh_user=$(show_input "SSH用户名" "root")
    local ssh_port=$(show_input "SSH端口" "22")
    local client_name=$(show_input "客户端名称" "")
    local platform=$(show_selection "目标平台" "linux" "macos")
    
    if [[ -z "$target_host" ]] || [[ -z "$client_name" ]]; then
        show_error "目标主机和客户端名称不能为空"
        return 1
    fi
    
    # 验证客户端存在
    if ! grep -q "^[^|]*|$client_name|" "$CLIENT_DB"; then
        show_error "客户端不存在: $client_name"
        return 1
    fi
    
    log_info "开始基于SSH的远程安装: $target_host -> $client_name"
    
    # 生成安装令牌
    local token=$(generate_install_token "$client_name" "$platform" "1")
    
    if [[ -n "$token" ]]; then
        # 创建安装脚本
        local install_script=$(create_remote_install_script "$client_name" "$platform" "$token")
        
        # 通过SSH传输并执行
        if ssh_remote_install "$target_host" "$ssh_user" "$ssh_port" "$install_script" "$platform"; then
            log_info "SSH远程安装成功: $target_host -> $client_name"
        else
            log_error "SSH远程安装失败"
        fi
    else
        log_error "安装令牌生成失败"
    fi
}

# 管理安装令牌
manage_install_tokens() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 管理安装令牌 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看所有令牌"
        echo -e "${GREEN}2.${NC} 撤销令牌"
        echo -e "${GREEN}3.${NC} 延长令牌有效期"
        echo -e "${GREEN}4.${NC} 清理过期令牌"
        echo -e "${GREEN}5.${NC} 令牌统计"
        echo -e "${GREEN}6.${NC} 令牌安全设置"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -rp "请选择操作 [0-6]: " choice
        
        case $choice in
            1) view_all_tokens ;;
            2) revoke_token ;;
            3) extend_token_validity ;;
            4) cleanup_expired_tokens ;;
            5) token_statistics ;;
            6) token_security_settings ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 查看所有令牌
view_all_tokens() {
    log_info "所有安装令牌:"
    echo "----------------------------------------"
    
    if [[ -f "$INSTALL_TOKEN_DB" ]]; then
        printf "%-20s %-10s %-32s %-20s %-20s %-10s %-15s\n" "客户端" "平台" "令牌" "创建时间" "过期时间" "使用次数" "状态"
        printf "%-20s %-10s %-32s %-20s %-20s %-10s %-15s\n" "--------------------" "----------" "--------------------------------" "--------------------" "--------------------" "----------" "---------------"
        
        while IFS='|' read -ra fields; do
            if [[ ${#fields[@]} -ge 10 ]]; then
                local client_name="${fields[1]}"
                local token="${fields[2]}"
                local created_time="${fields[3]}"
                local expires_time="${fields[4]}"
                local used="${fields[5]}"
                local attempts="${fields[6]}"
                local platform="${fields[7]}"
                
                local status="有效"
                if [[ "$used" == "true" ]]; then
                    status="已使用"
                elif [[ "$expires_time" < "$(date +%Y-%m-%d\ %H:%M:%S)" ]]; then
                    status="已过期"
                fi
                
                printf "%-20s %-10s %-32s %-20s %-20s %-10s %-15s\n" \
                    "$client_name" "$platform" "$token" "$created_time" "$expires_time" "$attempts" "$status"
            fi
        done < "$INSTALL_TOKEN_DB"
    else
        log_info "没有安装令牌"
    fi
}

# 撤销令牌
revoke_token() {
    echo -e "${SECONDARY_COLOR}=== 撤销令牌 ===${NC}"
    echo
    
    local token=$(show_input "要撤销的令牌" "")
    
    if [[ -z "$token" ]]; then
        show_error "令牌不能为空"
        return 1
    fi
    
    # 查找令牌
    if grep -q "^[^|]*|[^|]*|$token|" "$INSTALL_TOKEN_DB"; then
        if show_confirm "确认撤销令牌: $token"; then
            # 标记令牌为已撤销
            sed -i "s/^\([^|]*|[^|]*|$token|[^|]*|[^|]*|\)[^|]*\(|.*\)/\1revoked\2/" "$INSTALL_TOKEN_DB"
            log_info "令牌撤销成功: $token"
        fi
    else
        show_error "令牌不存在: $token"
    fi
}

# 查看安装日志
view_install_logs() {
    log_info "安装日志:"
    echo "----------------------------------------"
    
    if [[ -f "$INSTALL_LOG_DB" ]]; then
        printf "%-20s %-20s %-20s %-10s %-10s %-15s %-50s\n" "时间" "客户端" "操作" "状态" "平台" "IP地址" "错误信息"
        printf "%-20s %-20s %-20s %-10s %-10s %-15s %-50s\n" "--------------------" "--------------------" "--------------------" "----------" "----------" "---------------" "--------------------------------------------------"
        
        while IFS='|' read -ra fields; do
            if [[ ${#fields[@]} -ge 9 ]]; then
                printf "%-20s %-20s %-20s %-10s %-10s %-15s %-50s\n" \
                    "${fields[1]}" "${fields[2]}" "${fields[3]}" "${fields[4]}" "${fields[5]}" "${fields[6]}" "${fields[8]}"
            fi
        done < "$INSTALL_LOG_DB" | tail -20
    else
        log_info "没有安装日志"
    fi
}

# 核心函数

# 生成安装令牌
generate_install_token() {
    local client_name="$1"
    local platform="$2"
    local expiry_hours="$3"
    
    local token_id="token_$(date +%s)_$(generate_random_string 8)"
    local token=$(generate_random_string "${INSTALL_TOKEN_LENGTH:-32}")
    local created_time=$(get_timestamp)
    local expires_time=$(date -d "+${expiry_hours} hours" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date "+%Y-%m-%d %H:%M:%S")
    
    # 记录到数据库
    echo "$token_id|$client_name|$token|$created_time|$expires_time|false|0|$platform||" >> "$INSTALL_TOKEN_DB"
    
    echo "$token"
}

# 生成通用安装令牌
generate_generic_install_token() {
    local platform="$1"
    local expiry_hours="$2"
    
    local token_id="generic_token_$(date +%s)_$(generate_random_string 8)"
    local token=$(generate_random_string "${INSTALL_TOKEN_LENGTH:-32}")
    local created_time=$(get_timestamp)
    local expires_time=$(date -d "+${expiry_hours} hours" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date "+%Y-%m-%d %H:%M:%S")
    
    # 记录到数据库
    echo "$token_id|generic|$token|$created_time|$expires_time|false|0|$platform||" >> "$INSTALL_TOKEN_DB"
    
    echo "$token"
}

# 生成安装URL
generate_install_url() {
    local client_name="$1"
    local token="$2"
    local platform="$3"
    
    local base_url="$INSTALL_BASE_URL"
    if [[ -z "$base_url" ]]; then
        local server_ip=$(get_public_ipv4)
        local server_port="$INSTALL_SERVER_PORT"
        base_url="http://$server_ip:$server_port"
    fi
    
    echo "$base_url/install?client=$client_name&token=$token&platform=$platform"
}

# 生成通用安装URL
generate_generic_install_url() {
    local token="$1"
    local platform="$2"
    
    local base_url="$INSTALL_BASE_URL"
    if [[ -z "$base_url" ]]; then
        local server_ip=$(get_public_ipv4)
        local server_port="$INSTALL_SERVER_PORT"
        base_url="http://$server_ip:$server_port"
    fi
    
    echo "$base_url/install?token=$token&platform=$platform"
}

# 创建远程安装脚本
create_remote_install_script() {
    local client_name="$1"
    local platform="$2"
    local token="$3"
    
    local script_path="/tmp/install_${client_name}_$(date +%s).sh"
    
    case "$platform" in
        "linux")
            create_linux_install_script "$client_name" "$token" "$script_path"
            ;;
        "windows")
            create_windows_install_script "$client_name" "$token" "$script_path"
            ;;
        "macos")
            create_macos_install_script "$client_name" "$token" "$script_path"
            ;;
        *)
            log_error "不支持的平台: $platform"
            return 1
            ;;
    esac
    
    echo "$script_path"
}

# 创建Linux安装脚本
create_linux_install_script() {
    local client_name="$1"
    local token="$2"
    local script_path="$3"
    
    cat > "$script_path" << EOF
#!/bin/bash

# Linux WireGuard客户端自动安装脚本
# 客户端: $client_name
# 生成时间: $(get_timestamp)

set -e

# 配置变量
CLIENT_NAME="$client_name"
TOKEN="$token"
SERVER_URL="$INSTALL_BASE_URL"
INSTALL_PATH="/etc/wireguard"
CONFIG_FILE="\$INSTALL_PATH/\$CLIENT_NAME.conf"

# 日志函数
log_info() {
    echo "[INFO] \$(date '+%Y-%m-%d %H:%M:%S') \$1"
}

log_error() {
    echo "[ERROR] \$(date '+%Y-%m-%d %H:%M:%S') \$1" >&2
}

# 检查root权限
if [[ \$EUID -ne 0 ]]; then
    log_error "此脚本需要root权限运行"
    exit 1
fi

log_info "开始安装WireGuard客户端: \$CLIENT_NAME"

# 检测操作系统
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=\$ID
    VERSION=\$VERSION_ID
else
    log_error "无法检测操作系统"
    exit 1
fi

log_info "检测到操作系统: \$OS \$VERSION"

# 安装WireGuard
case "\$OS" in
    ubuntu|debian)
        apt update
        apt install -y wireguard
        ;;
    centos|rhel|rocky|almalinux)
        if command -v dnf &> /dev/null; then
            dnf install -y wireguard-tools
        else
            yum install -y wireguard-tools
        fi
        ;;
    arch)
        pacman -Sy --noconfirm wireguard-tools
        ;;
    *)
        log_error "不支持的操作系统: \$OS"
        exit 1
        ;;
esac

# 下载客户端配置
log_info "下载客户端配置..."
if command -v curl &> /dev/null; then
    curl -s "\$SERVER_URL/download/\$CLIENT_NAME?token=\$TOKEN" -o "\$CONFIG_FILE"
elif command -v wget &> /dev/null; then
    wget -q "\$SERVER_URL/download/\$CLIENT_NAME?token=\$TOKEN" -O "\$CONFIG_FILE"
else
    log_error "需要curl或wget来下载配置"
    exit 1
fi

# 验证配置文件
if [[ ! -f "\$CONFIG_FILE" ]] || [[ ! -s "\$CONFIG_FILE" ]]; then
    log_error "配置文件下载失败"
    exit 1
fi

# 设置文件权限
chmod 600 "\$CONFIG_FILE"

# 启动WireGuard
log_info "启动WireGuard客户端..."
wg-quick up "\$CLIENT_NAME"

# 设置开机自启
systemctl enable wg-quick@\$CLIENT_NAME

log_info "WireGuard客户端安装完成: \$CLIENT_NAME"

# 显示状态
wg show "\$CLIENT_NAME"

log_info "安装脚本执行完成"
EOF
    
    chmod +x "$script_path"
}

# 创建Windows安装脚本
create_windows_install_script() {
    local client_name="$1"
    local token="$2"
    local script_path="$3"
    
    cat > "$script_path" << EOF
@echo off
REM Windows WireGuard客户端自动安装脚本
REM 客户端: $client_name
REM 生成时间: $(get_timestamp)

setlocal enabledelayedexpansion

REM 配置变量
set CLIENT_NAME=$client_name
set TOKEN=$token
set SERVER_URL=$INSTALL_BASE_URL
set CONFIG_FILE=%TEMP%\\%CLIENT_NAME%.conf

echo [INFO] 开始安装WireGuard客户端: %CLIENT_NAME%

REM 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] 此脚本需要管理员权限运行
    exit /b 1
)

REM 下载WireGuard安装程序
echo [INFO] 下载WireGuard安装程序...
powershell -Command "Invoke-WebRequest -Uri 'https://download.wireguard.com/windows-client/wireguard-installer.exe' -OutFile '%TEMP%\\wireguard-installer.exe'"

REM 安装WireGuard
echo [INFO] 安装WireGuard...
%TEMP%\\wireguard-installer.exe /S

REM 等待安装完成
timeout /t 10 /nobreak >nul

REM 下载客户端配置
echo [INFO] 下载客户端配置...
powershell -Command "Invoke-WebRequest -Uri '%SERVER_URL%/download/%CLIENT_NAME%?token=%TOKEN%' -OutFile '%CONFIG_FILE%'"

REM 验证配置文件
if not exist "%CONFIG_FILE%" (
    echo [ERROR] 配置文件下载失败
    exit /b 1
)

REM 导入配置到WireGuard
echo [INFO] 导入配置到WireGuard...
"C:\\Program Files\\WireGuard\\wireguard.exe" /installtunnelservice "%CONFIG_FILE%"

echo [INFO] WireGuard客户端安装完成: %CLIENT_NAME%

REM 清理临时文件
del "%TEMP%\\wireguard-installer.exe" 2>nul
del "%CONFIG_FILE%" 2>nul

echo [INFO] 安装脚本执行完成
pause
EOF
}

# 创建macOS安装脚本
create_macos_install_script() {
    local client_name="$1"
    local token="$2"
    local script_path="$3"
    
    cat > "$script_path" << EOF
#!/bin/bash

# macOS WireGuard客户端自动安装脚本
# 客户端: $client_name
# 生成时间: $(get_timestamp)

set -e

# 配置变量
CLIENT_NAME="$client_name"
TOKEN="$token"
SERVER_URL="$INSTALL_BASE_URL"
CONFIG_FILE="/tmp/\$CLIENT_NAME.conf"

# 日志函数
log_info() {
    echo "[INFO] \$(date '+%Y-%m-%d %H:%M:%S') \$1"
}

log_error() {
    echo "[ERROR] \$(date '+%Y-%m-%d %H:%M:%S') \$1" >&2
}

log_info "开始安装WireGuard客户端: \$CLIENT_NAME"

# 检查Homebrew
if ! command -v brew &> /dev/null; then
    log_info "安装Homebrew..."
    /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 安装WireGuard
log_info "安装WireGuard..."
brew install wireguard-tools

# 下载客户端配置
log_info "下载客户端配置..."
curl -s "\$SERVER_URL/download/\$CLIENT_NAME?token=\$TOKEN" -o "\$CONFIG_FILE"

# 验证配置文件
if [[ ! -f "\$CONFIG_FILE" ]] || [[ ! -s "\$CONFIG_FILE" ]]; then
    log_error "配置文件下载失败"
    exit 1
fi

# 启动WireGuard
log_info "启动WireGuard客户端..."
sudo wg-quick up "\$CONFIG_FILE"

log_info "WireGuard客户端安装完成: \$CLIENT_NAME"

# 显示状态
sudo wg show

log_info "安装脚本执行完成"
EOF
    
    chmod +x "$script_path"
}

# 占位函数 - 这些功能需要进一步实现
install_server_config() {
    echo -e "${SECONDARY_COLOR}=== 安装服务器配置 ===${NC}"
    echo
    
    local config_type=$(show_selection "配置类型" "HTTP服务器" "HTTPS服务器" "自定义服务器")
    
    case "$config_type" in
        "HTTP服务器")
            configure_http_install_server
            ;;
        "HTTPS服务器")
            configure_https_install_server
            ;;
        "自定义服务器")
            configure_custom_install_server
            ;;
    esac
}

# 配置HTTP安装服务器
configure_http_install_server() {
    local port=$(show_input "HTTP端口" "8080")
    local host=$(show_input "绑定地址" "0.0.0.0")
    
    update_auto_install_config "INSTALL_SERVER_PORT" "$port"
    update_auto_install_config "INSTALL_SERVER_HOST" "$host"
    update_auto_install_config "INSTALL_SSL_ENABLED" "false"
    
    log_info "HTTP安装服务器配置完成: $host:$port"
}

# 配置HTTPS安装服务器
configure_https_install_server() {
    local port=$(show_input "HTTPS端口" "8443")
    local host=$(show_input "绑定地址" "0.0.0.0")
    local cert_file=$(show_input "SSL证书文件路径" "")
    local key_file=$(show_input "SSL私钥文件路径" "")
    
    if [[ -f "$cert_file" ]] && [[ -f "$key_file" ]]; then
        update_auto_install_config "INSTALL_SERVER_PORT" "$port"
        update_auto_install_config "INSTALL_SERVER_HOST" "$host"
        update_auto_install_config "INSTALL_SSL_ENABLED" "true"
        update_auto_install_config "INSTALL_SSL_CERT" "$cert_file"
        update_auto_install_config "INSTALL_SSL_KEY" "$key_file"
        
        log_info "HTTPS安装服务器配置完成: $host:$port"
    else
        show_error "SSL证书或私钥文件不存在"
    fi
}

# 配置自定义安装服务器
configure_custom_install_server() {
    local base_url=$(show_input "服务器基础URL" "")
    local auth_method=$(show_selection "认证方法" "token" "basic" "none")
    
    update_auto_install_config "INSTALL_BASE_URL" "$base_url"
    update_auto_install_config "INSTALL_AUTH_METHOD" "$auth_method"
    
    log_info "自定义安装服务器配置完成: $base_url"
}
platform_support_management() { log_info "平台支持管理功能待实现"; }
install_script_management() { log_info "安装脚本管理功能待实现"; }
security_settings() { log_info "安全设置功能待实现"; }
install_statistics() { log_info "安装统计功能待实现"; }
install_testing() { log_info "安装测试功能待实现"; }
api_based_remote_install() { log_info "基于API的远程安装功能待实现"; }
batch_remote_install() { log_info "批量远程安装功能待实现"; }
remote_install_monitoring() { log_info "远程安装监控功能待实现"; }
remote_install_config() { log_info "远程安装配置功能待实现"; }
extend_token_validity() { log_info "延长令牌有效期功能待实现"; }
cleanup_expired_tokens() { log_info "清理过期令牌功能待实现"; }
token_statistics() { log_info "令牌统计功能待实现"; }
token_security_settings() { log_info "令牌安全设置功能待实现"; }
transfer_install_script() { log_info "传输安装脚本功能待实现"; }
execute_remote_install() { log_info "执行远程安装功能待实现"; }
ssh_remote_install() {
    local target_host="$1"
    local ssh_user="$2"
    local ssh_port="$3"
    local install_script="$4"
    local platform="$5"
    
    log_info "开始SSH远程安装: $target_host"
    
    # 测试SSH连接
    if ! ssh -o ConnectTimeout=10 -o BatchMode=yes -p "$ssh_port" "$ssh_user@$target_host" "echo 'SSH连接测试成功'" &>/dev/null; then
        log_error "SSH连接失败: $target_host"
        return 1
    fi
    
    # 传输并执行安装脚本
    if scp -P "$ssh_port" "$install_script" "$ssh_user@$target_host:/tmp/install.sh"; then
        log_info "安装脚本传输成功: $target_host"
        
        # 执行安装脚本
        if ssh -p "$ssh_port" "$ssh_user@$target_host" "chmod +x /tmp/install.sh && /tmp/install.sh"; then
            log_info "SSH远程安装成功: $target_host"
            
            # 清理临时文件
            ssh -p "$ssh_port" "$ssh_user@$target_host" "rm -f /tmp/install.sh"
            
            return 0
        else
            log_error "安装脚本执行失败: $target_host"
            return 1
        fi
    else
        log_error "安装脚本传输失败: $target_host"
        return 1
    fi
}

# 辅助函数

# 更新自动安装配置
update_auto_install_config() {
    local key="$1"
    local value="$2"
    
    if grep -q "^${key}=" "$AUTO_INSTALL_CONFIG_FILE"; then
        sed -i "s/^${key}=.*/${key}=${value}/" "$AUTO_INSTALL_CONFIG_FILE"
    else
        echo "${key}=${value}" >> "$AUTO_INSTALL_CONFIG_FILE"
    fi
}

# 导出函数
export -f init_client_auto_install create_auto_install_config init_auto_install_databases
export -f load_auto_install_config client_auto_install_menu generate_install_links
export -f generate_single_client_link generate_multiple_client_links generate_generic_install_link
export -f generate_platform_specific_links view_generated_links remote_auto_install
export -f ip_based_remote_install ssh_based_remote_install manage_install_tokens
export -f view_all_tokens revoke_token view_install_logs
export -f generate_install_token generate_generic_install_token generate_install_url
export -f generate_generic_install_url create_remote_install_script
export -f create_linux_install_script create_windows_install_script create_macos_install_script
export -f install_server_config configure_http_install_server configure_https_install_server
export -f configure_custom_install_server ssh_remote_install update_auto_install_config
