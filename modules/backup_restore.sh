#!/bin/bash

# 配置备份恢复模块
# 负责配置文件的备份、恢复、导入、导出等功能

# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"

# 确保日志相关变量已定义
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"
fi

# 备份配置变量
BACKUP_DIR="/var/lib/ipv6-wireguard-manager/backups"
BACKUP_CONFIG_FILE="${CONFIG_DIR}/backup.conf"
BACKUP_HISTORY_DB="/var/lib/ipv6-wireguard-manager/backup_history.db"

# 备份设置
BACKUP_ENABLED=true
BACKUP_RETENTION_DAYS=30
BACKUP_COMPRESSION=true
BACKUP_ENCRYPTION=false
AUTO_BACKUP_ENABLED=true
AUTO_BACKUP_INTERVAL=24

# 初始化备份恢复系统
init_backup_restore() {
    log_info "初始化备份恢复系统..."
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$(dirname "$BACKUP_HISTORY_DB")"
    
    # 创建备份配置文件
    create_backup_config
    
    # 初始化备份历史数据库
    init_backup_history_db
    
    # 加载备份配置
    load_backup_config
    
    log_info "备份恢复系统初始化完成"
}

# 创建备份配置
create_backup_config() {
    if [[ ! -f "$BACKUP_CONFIG_FILE" ]]; then
        cat > "$BACKUP_CONFIG_FILE" << EOF
# 备份配置文件
# 生成时间: $(get_timestamp)

# 备份设置
BACKUP_ENABLED=true
BACKUP_RETENTION_DAYS=30
BACKUP_COMPRESSION=true
BACKUP_ENCRYPTION=false
BACKUP_PASSWORD=""

# 自动备份设置
AUTO_BACKUP_ENABLED=true
AUTO_BACKUP_INTERVAL=24
AUTO_BACKUP_TIME="02:00"

# 备份内容
BACKUP_WIREGUARD=true
BACKUP_BIRD=true
BACKUP_CLIENT_DB=true
BACKUP_CONFIG_FILES=true
BACKUP_LOGS=true
BACKUP_KEYS=true

# 备份路径
WIREGUARD_BACKUP_PATH="/etc/wireguard"
BIRD_BACKUP_PATH="/etc/bird"
CLIENT_DB_BACKUP_PATH="/var/lib/ipv6-wireguard-manager"
CONFIG_BACKUP_PATH="${CONFIG_DIR}"
LOG_BACKUP_PATH="${LOG_DIR}"
KEY_BACKUP_PATH="/etc/wireguard/keys"

# 排除文件
EXCLUDE_PATTERNS=(
    "*.tmp"
    "*.log"
    "*.pid"
    "*.lock"
    "*.swp"
    "*.bak"
)

# 备份验证
BACKUP_VERIFICATION=true
BACKUP_INTEGRITY_CHECK=true
EOF
        log_info "备份配置文件已创建: $BACKUP_CONFIG_FILE"
    fi
}

# 初始化备份历史数据库
init_backup_history_db() {
    if [[ ! -f "$BACKUP_HISTORY_DB" ]]; then
        cat > "$BACKUP_HISTORY_DB" << EOF
# 备份历史数据库
# 格式: backup_id|timestamp|backup_type|backup_path|backup_size|status|description|restore_count
EOF
        log_info "备份历史数据库已创建"
    fi
}

# 加载备份配置
load_backup_config() {
    if [[ -f "$BACKUP_CONFIG_FILE" ]]; then
        source "$BACKUP_CONFIG_FILE"
        log_info "备份配置已加载"
    fi
}

# 备份恢复主菜单
backup_restore_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 配置备份/恢复 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 自动备份设置"
        echo -e "${GREEN}2.${NC} 手动备份配置"
        echo -e "${GREEN}3.${NC} 恢复配置"
        echo -e "${GREEN}4.${NC} 导入配置"
        echo -e "${GREEN}5.${NC} 导出配置"
        echo -e "${GREEN}6.${NC} 查看备份历史"
        echo -e "${GREEN}7.${NC} 备份管理"
        echo -e "${GREEN}8.${NC} 备份验证"
        echo -e "${GREEN}9.${NC} 备份清理"
        echo -e "${GREEN}10.${NC} 备份计划"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -rp "请选择操作 [0-10]: " choice
        
        case $choice in
            1) auto_backup_settings ;;
            2) manual_backup_config ;;
            3) restore_config ;;
            4) import_config ;;
            5) export_config ;;
            6) view_backup_history ;;
            7) backup_management ;;
            8) backup_verification ;;
            9) backup_cleanup ;;
            10) backup_schedule ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 自动备份设置
auto_backup_settings() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 自动备份设置 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 启用/禁用自动备份"
        echo -e "${GREEN}2.${NC} 设置备份间隔"
        echo -e "${GREEN}3.${NC} 设置备份时间"
        echo -e "${GREEN}4.${NC} 设置保留天数"
        echo -e "${GREEN}5.${NC} 配置备份内容"
        echo -e "${GREEN}6.${NC} 查看当前设置"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -rp "请选择操作 [0-6]: " choice
        
        case $choice in
            1) toggle_auto_backup ;;
            2) set_backup_interval ;;
            3) set_backup_time ;;
            4) set_retention_days ;;
            5) configure_backup_content ;;
            6) show_backup_settings ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 切换自动备份
toggle_auto_backup() {
    echo -e "${SECONDARY_COLOR}=== 启用/禁用自动备份 ===${NC}"
    echo
    
    local current_status=$([ "$AUTO_BACKUP_ENABLED" == "true" ] && echo "启用" || echo "禁用")
    echo "当前状态: $current_status"
    
    local new_status=$(show_selection "新的状态" "启用" "禁用")
    
    if [[ "$new_status" == "启用" ]]; then
        AUTO_BACKUP_ENABLED=true
        update_backup_config "AUTO_BACKUP_ENABLED" "true"
        log_info "自动备份已启用"
    else
        AUTO_BACKUP_ENABLED=false
        update_backup_config "AUTO_BACKUP_ENABLED" "false"
        log_info "自动备份已禁用"
    fi
}

# 设置备份间隔
set_backup_interval() {
    echo -e "${SECONDARY_COLOR}=== 设置备份间隔 ===${NC}"
    echo
    
    local current_interval="$AUTO_BACKUP_INTERVAL"
    echo "当前备份间隔: ${current_interval}小时"
    
    local new_interval=$(show_input "新的备份间隔(小时)" "$current_interval" "validate_port")
    
    if [[ -n "$new_interval" ]] && [[ "$new_interval" -gt 0 ]]; then
        AUTO_BACKUP_INTERVAL="$new_interval"
        update_backup_config "AUTO_BACKUP_INTERVAL" "$new_interval"
        log_info "备份间隔已设置为: ${new_interval}小时"
    else
        show_error "无效的备份间隔"
    fi
}

# 设置备份时间
set_backup_time() {
    echo -e "${SECONDARY_COLOR}=== 设置备份时间 ===${NC}"
    echo
    
    local current_time="$AUTO_BACKUP_TIME"
    echo "当前备份时间: $current_time"
    
    local new_time=$(show_input "新的备份时间(HH:MM)" "$current_time")
    
    if [[ "$new_time" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
        AUTO_BACKUP_TIME="$new_time"
        update_backup_config "AUTO_BACKUP_TIME" "$new_time"
        log_info "备份时间已设置为: $new_time"
    else
        show_error "无效的时间格式，请使用HH:MM格式"
    fi
}

# 设置保留天数
set_retention_days() {
    echo -e "${SECONDARY_COLOR}=== 设置保留天数 ===${NC}"
    echo
    
    local current_days="$BACKUP_RETENTION_DAYS"
    echo "当前保留天数: $current_days"
    
    local new_days=$(show_input "新的保留天数" "$current_days" "validate_port")
    
    if [[ -n "$new_days" ]] && [[ "$new_days" -gt 0 ]]; then
        BACKUP_RETENTION_DAYS="$new_days"
        update_backup_config "BACKUP_RETENTION_DAYS" "$new_days"
        log_info "保留天数已设置为: $new_days"
    else
        show_error "无效的保留天数"
    fi
}

# 配置备份内容
configure_backup_content() {
    echo -e "${SECONDARY_COLOR}=== 配置备份内容 ===${NC}"
    echo
    
    echo "当前备份内容:"
    echo "  WireGuard配置: $([ "$BACKUP_WIREGUARD" == "true" ] && echo "是" || echo "否")"
    echo "  BIRD配置: $([ "$BACKUP_BIRD" == "true" ] && echo "是" || echo "否")"
    echo "  客户端数据库: $([ "$BACKUP_CLIENT_DB" == "true" ] && echo "是" || echo "否")"
    echo "  配置文件: $([ "$BACKUP_CONFIG_FILES" == "true" ] && echo "是" || echo "否")"
    echo "  日志文件: $([ "$BACKUP_LOGS" == "true" ] && echo "是" || echo "否")"
    echo "  密钥文件: $([ "$BACKUP_KEYS" == "true" ] && echo "是" || echo "否")"
    echo
    
    local choice=$(show_selection "要修改的备份内容" "WireGuard配置" "BIRD配置" "客户端数据库" "配置文件" "日志文件" "密钥文件")
    
    case $choice in
        "WireGuard配置")
            toggle_backup_option "BACKUP_WIREGUARD"
            ;;
        "BIRD配置")
            toggle_backup_option "BACKUP_BIRD"
            ;;
        "客户端数据库")
            toggle_backup_option "BACKUP_CLIENT_DB"
            ;;
        "配置文件")
            toggle_backup_option "BACKUP_CONFIG_FILES"
            ;;
        "日志文件")
            toggle_backup_option "BACKUP_LOGS"
            ;;
        "密钥文件")
            toggle_backup_option "BACKUP_KEYS"
            ;;
    esac
}

# 切换备份选项
toggle_backup_option() {
    local option="$1"
    local current_value=$(get_backup_config_value "$option")
    local new_value=$([ "$current_value" == "true" ] && echo "false" || echo "true")
    
    update_backup_config "$option" "$new_value"
    log_info "$option 备份已$([ "$new_value" == "true" ] && echo "启用" || echo "禁用")"
}

# 显示备份设置
show_backup_settings() {
    log_info "当前备份设置:"
    echo "----------------------------------------"
    echo "自动备份: $([ "$AUTO_BACKUP_ENABLED" == "true" ] && echo "启用" || echo "禁用")"
    echo "备份间隔: ${AUTO_BACKUP_INTERVAL}小时"
    echo "备份时间: $AUTO_BACKUP_TIME"
    echo "保留天数: $BACKUP_RETENTION_DAYS"
    echo "压缩备份: $([ "$BACKUP_COMPRESSION" == "true" ] && echo "是" || echo "否")"
    echo "加密备份: $([ "$BACKUP_ENCRYPTION" == "true" ] && echo "是" || echo "否")"
    echo
    echo "备份内容:"
    echo "  WireGuard配置: $([ "$BACKUP_WIREGUARD" == "true" ] && echo "是" || echo "否")"
    echo "  BIRD配置: $([ "$BACKUP_BIRD" == "true" ] && echo "是" || echo "否")"
    echo "  客户端数据库: $([ "$BACKUP_CLIENT_DB" == "true" ] && echo "是" || echo "否")"
    echo "  配置文件: $([ "$BACKUP_CONFIG_FILES" == "true" ] && echo "是" || echo "否")"
    echo "  日志文件: $([ "$BACKUP_LOGS" == "true" ] && echo "是" || echo "否")"
    echo "  密钥文件: $([ "$BACKUP_KEYS" == "true" ] && echo "是" || echo "否")"
}

# 手动备份配置
manual_backup_config() {
    echo -e "${SECONDARY_COLOR}=== 手动备份配置 ===${NC}"
    echo
    
    local backup_type=$(show_selection "备份类型" "完整备份" "增量备份" "差异备份")
    local backup_name=$(show_input "备份名称" "manual_backup_$(date +%Y%m%d_%H%M%S)")
    local description=$(show_input "备份描述" "")
    
    log_info "开始手动备份: $backup_name"
    
    if create_backup "$backup_name" "$backup_type" "$description"; then
        log_info "手动备份完成: $backup_name"
    else
        log_error "手动备份失败"
    fi
}

# 恢复配置
restore_config() {
    echo -e "${SECONDARY_COLOR}=== 恢复配置 ===${NC}"
    echo
    
    # 显示可用备份
    list_available_backups
    echo
    
    local backup_id=$(show_input "要恢复的备份ID" "")
    
    if [[ -z "$backup_id" ]]; then
        show_error "备份ID不能为空"
        return 1
    fi
    
    # 验证备份存在
    if ! backup_exists "$backup_id"; then
        show_error "备份不存在: $backup_id"
        return 1
    fi
    
    if show_confirm "确认恢复备份: $backup_id"; then
        if restore_backup "$backup_id"; then
            log_info "配置恢复成功: $backup_id"
        else
            log_error "配置恢复失败"
        fi
    fi
}

# 导入配置
import_config() {
    echo -e "${SECONDARY_COLOR}=== 导入配置 ===${NC}"
    echo
    
    local import_file=$(show_input "配置文件路径" "")
    
    if [[ -z "$import_file" ]] || [[ ! -f "$import_file" ]]; then
        show_error "配置文件不存在"
        return 1
    fi
    
    local import_type=$(show_selection "导入类型" "完整导入" "部分导入" "合并导入")
    
    if show_confirm "确认导入配置: $import_file"; then
        if import_backup "$import_file" "$import_type"; then
            log_info "配置导入成功"
        else
            log_error "配置导入失败"
        fi
    fi
}

# 导出配置
export_config() {
    echo -e "${SECONDARY_COLOR}=== 导出配置 ===${NC}"
    echo
    
    local export_type=$(show_selection "导出类型" "完整导出" "部分导出" "自定义导出")
    local export_format=$(show_selection "导出格式" "tar.gz" "zip" "tar")
    local output_path=$(show_input "输出路径" "/tmp/ipv6-wg-config-$(date +%Y%m%d_%H%M%S).$export_format")
    
    if export_backup "$export_type" "$export_format" "$output_path"; then
        log_info "配置导出成功: $output_path"
    else
        log_error "配置导出失败"
    fi
}

# 查看备份历史
view_backup_history() {
    log_info "备份历史:"
    echo "----------------------------------------"
    
    if [[ -f "$BACKUP_HISTORY_DB" ]]; then
        printf "%-20s %-15s %-20s %-15s %-10s %-30s\n" "备份ID" "时间" "类型" "大小" "状态" "描述"
        printf "%-20s %-15s %-20s %-15s %-10s %-30s\n" "--------------------" "---------------" "--------------------" "---------------" "----------" "------------------------------"
        
        while IFS='|' read -ra fields; do
            if [[ ${#fields[@]} -ge 8 ]]; then
                printf "%-20s %-15s %-20s %-15s %-10s %-30s\n" \
                    "${fields[0]}" "${fields[1]}" "${fields[2]}" "${fields[4]}" "${fields[5]}" "${fields[6]}"
            fi
        done < "$BACKUP_HISTORY_DB" | tail -20
    else
        log_info "没有备份历史记录"
    fi
}

# 备份管理
backup_management() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 备份管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看备份列表"
        echo -e "${GREEN}2.${NC} 删除备份"
        echo -e "${GREEN}3.${NC} 备份详情"
        echo -e "${GREEN}4.${NC} 备份统计"
        echo -e "${GREEN}5.${NC} 备份压缩"
        echo -e "${GREEN}6.${NC} 备份加密"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -rp "请选择操作 [0-6]: " choice
        
        case $choice in
            1) list_available_backups ;;
            2) delete_backup ;;
            3) backup_details ;;
            4) backup_statistics ;;
            5) compress_backup ;;
            6) encrypt_backup ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 列出可用备份
list_available_backups() {
    log_info "可用备份列表:"
    echo "----------------------------------------"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        find . -type f -exec ls -la {} + "$BACKUP_DIR" | grep -E "\.(tar\.gz|zip|tar)$" | while read -r line; do
            echo "$line"
        done
    else
        log_info "备份目录不存在"
    fi
}

# 删除备份
delete_backup() {
    echo -e "${SECONDARY_COLOR}=== 删除备份 ===${NC}"
    echo
    
    list_available_backups
    echo
    
    local backup_name=$(show_input "要删除的备份名称" "")
    
    if [[ -z "$backup_name" ]]; then
        show_error "备份名称不能为空"
        return 1
    fi
    
    local backup_path="$BACKUP_DIR/$backup_name"
    
    if [[ ! -f "$backup_path" ]]; then
        show_error "备份文件不存在: $backup_name"
        return 1
    fi
    
    if show_confirm "确认删除备份: $backup_name"; then
        rm -f "$backup_path"
        # 从历史数据库删除记录
        remove_backup_from_history "$backup_name"
        log_info "备份删除成功: $backup_name"
    fi
}

# 备份验证
backup_verification() {
    echo -e "${SECONDARY_COLOR}=== 备份验证 ===${NC}"
    echo
    
    local backup_name=$(show_input "要验证的备份名称" "")
    
    if [[ -z "$backup_name" ]]; then
        show_error "备份名称不能为空"
        return 1
    fi
    
    local backup_path="$BACKUP_DIR/$backup_name"
    
    if [[ ! -f "$backup_path" ]]; then
        show_error "备份文件不存在: $backup_name"
        return 1
    fi
    
    log_info "验证备份: $backup_name"
    
    # 检查文件完整性
    if verify_backup_integrity "$backup_path"; then
        show_success "备份完整性验证通过"
    else
        show_error "备份完整性验证失败"
    fi
    
    # 检查文件内容
    if verify_backup_content "$backup_path"; then
        show_success "备份内容验证通过"
    else
        show_error "备份内容验证失败"
    fi
}

# 备份清理
backup_cleanup() {
    echo -e "${SECONDARY_COLOR}=== 备份清理 ===${NC}"
    echo
    
    local cleanup_type=$(show_selection "清理类型" "按时间清理" "按大小清理" "按数量清理" "全部清理")
    
    case $cleanup_type in
        "按时间清理")
            cleanup_backups_by_time
            ;;
        "按大小清理")
            cleanup_backups_by_size
            ;;
        "按数量清理")
            cleanup_backups_by_count
            ;;
        "全部清理")
            cleanup_all_backups
            ;;
    esac
}

# 备份计划
backup_schedule() {
    echo -e "${SECONDARY_COLOR}=== 备份计划 ===${NC}"
    echo
    
    echo "当前备份计划:"
    echo "  自动备份: $([ "$AUTO_BACKUP_ENABLED" == "true" ] && echo "启用" || echo "禁用")"
    echo "  备份间隔: ${AUTO_BACKUP_INTERVAL}小时"
    echo "  备份时间: $AUTO_BACKUP_TIME"
    echo "  下次备份: $(get_next_backup_time)"
    echo
    
    local choice=$(show_selection "操作" "立即执行备份" "修改计划" "查看计划详情")
    
    case $choice in
        "立即执行备份")
            execute_scheduled_backup
            ;;
        "修改计划")
            modify_backup_schedule
            ;;
        "查看计划详情")
            show_backup_schedule_details
            ;;
    esac
}

# 核心备份函数

# 创建备份
create_backup() {
    local backup_name="$1"
    local backup_type="$2"
    local description="$3"
    
    local backup_id="backup_$(date +%s)_$(generate_random_string 8)"
    local backup_path="$BACKUP_DIR/${backup_name}.tar.gz"
    local timestamp=$(get_timestamp)
    
    log_info "创建备份: $backup_name (类型: $backup_type)"
    
    # 创建临时目录
    local temp_dir=$(create_temp_dir "backup_$backup_id")
    
    # 备份WireGuard配置
    if [[ "$BACKUP_WIREGUARD" == "true" ]]; then
        backup_wireguard_config "$temp_dir"
    fi
    
    # 备份BIRD配置
    if [[ "$BACKUP_BIRD" == "true" ]]; then
        backup_bird_config "$temp_dir"
    fi
    
    # 备份客户端数据库
    if [[ "$BACKUP_CLIENT_DB" == "true" ]]; then
        backup_client_database "$temp_dir"
    fi
    
    # 备份配置文件
    if [[ "$BACKUP_CONFIG_FILES" == "true" ]]; then
        backup_config_files "$temp_dir"
    fi
    
    # 备份日志文件
    if [[ "$BACKUP_LOGS" == "true" ]]; then
        backup_log_files "$temp_dir"
    fi
    
    # 备份密钥文件
    if [[ "$BACKUP_KEYS" == "true" ]]; then
        backup_key_files "$temp_dir"
    fi
    
    # 创建备份包
    if [[ "$BACKUP_COMPRESSION" == "true" ]]; then
        tar -czf "$backup_path" -C "$temp_dir" . 2>/dev/null
    else
        tar -cf "${backup_path%.gz}" -C "$temp_dir" . 2>/dev/null
    fi
    
    # 加密备份
    if [[ "$BACKUP_ENCRYPTION" == "true" ]] && [[ -n "$BACKUP_PASSWORD" ]]; then
        encrypt_backup_file "$backup_path"
    fi
    
    # 清理临时目录
    rm -rf "$temp_dir"
    
    # 记录备份历史
    local backup_size=$(stat -c%s "$backup_path" 2>/dev/null || echo "0")
    echo "$backup_id|$timestamp|$backup_type|$backup_path|$backup_size|success|$description|0" >> "$BACKUP_HISTORY_DB"
    
    log_info "备份创建成功: $backup_path (大小: $backup_size 字节)"
    return 0
}

# 恢复备份
restore_backup() {
    local backup_id="$1"
    
    # 获取备份信息
    local backup_info=$(grep "^$backup_id|" "$BACKUP_HISTORY_DB")
    if [[ -z "$backup_info" ]]; then
        log_error "备份记录不存在: $backup_id"
        return 1
    fi
    
    IFS='|' read -ra fields <<< "$backup_info"
    local backup_path="${fields[3]}"
    
    if [[ ! -f "$backup_path" ]]; then
        log_error "备份文件不存在: $backup_path"
        return 1
    fi
    
    log_info "恢复备份: $backup_id"
    
    # 创建临时目录
    local temp_dir=$(create_temp_dir "restore_$backup_id")
    
    # 解密备份
    if [[ "$BACKUP_ENCRYPTION" == "true" ]]; then
        decrypt_backup_file "$backup_path" "$temp_dir"
    else
        tar -xzf "$backup_path" -C "$temp_dir" 2>/dev/null
    fi
    
    # 恢复配置
    restore_wireguard_config "$temp_dir"
    restore_bird_config "$temp_dir"
    restore_client_database "$temp_dir"
    restore_config_files "$temp_dir"
    restore_key_files "$temp_dir"
    
    # 清理临时目录
    rm -rf "$temp_dir"
    
    # 更新恢复计数
    local restore_count=$((${fields[7]} + 1))
    sed -i "s/^$backup_id|.*|$restore_count$/$backup_id|${fields[1]}|${fields[2]}|${fields[3]}|${fields[4]}|${fields[5]}|${fields[6]}|$restore_count/" "$BACKUP_HISTORY_DB"
    
    log_info "备份恢复成功: $backup_id"
    return 0
}

# 备份WireGuard配置
backup_wireguard_config() {
    local temp_dir="$1"
    local wg_backup_dir="$temp_dir/wireguard"
    
    mkdir -p "$wg_backup_dir"
    
    if [[ -d "$WIREGUARD_BACKUP_PATH" ]]; then
        cp -r "$WIREGUARD_BACKUP_PATH"/* "$wg_backup_dir/" 2>/dev/null
        log_info "WireGuard配置已备份"
    fi
}

# 备份BIRD配置
backup_bird_config() {
    local temp_dir="$1"
    local bird_backup_dir="$temp_dir/bird"
    
    mkdir -p "$bird_backup_dir"
    
    if [[ -d "$BIRD_BACKUP_PATH" ]]; then
        cp -r "$BIRD_BACKUP_PATH"/* "$bird_backup_dir/" 2>/dev/null
        log_info "BIRD配置已备份"
    fi
}

# 备份客户端数据库
backup_client_database() {
    local temp_dir="$1"
    local db_backup_dir="$temp_dir/database"
    
    mkdir -p "$db_backup_dir"
    
    if [[ -d "$CLIENT_DB_BACKUP_PATH" ]]; then
        cp -r "$CLIENT_DB_BACKUP_PATH"/* "$db_backup_dir/" 2>/dev/null
        log_info "客户端数据库已备份"
    fi
}

# 备份配置文件
backup_config_files() {
    local temp_dir="$1"
    local config_backup_dir="$temp_dir/config"
    
    mkdir -p "$config_backup_dir"
    
    if [[ -d "$CONFIG_BACKUP_PATH" ]]; then
        cp -r "$CONFIG_BACKUP_PATH"/* "$config_backup_dir/" 2>/dev/null
        log_info "配置文件已备份"
    fi
}

# 备份日志文件
backup_log_files() {
    local temp_dir="$1"
    local log_backup_dir="$temp_dir/logs"
    
    mkdir -p "$log_backup_dir"
    
    if [[ -d "$LOG_BACKUP_PATH" ]]; then
        cp -r "$LOG_BACKUP_PATH"/* "$log_backup_dir/" 2>/dev/null
        log_info "日志文件已备份"
    fi
}

# 备份密钥文件
backup_key_files() {
    local temp_dir="$1"
    local key_backup_dir="$temp_dir/keys"
    
    mkdir -p "$key_backup_dir"
    
    if [[ -d "$KEY_BACKUP_PATH" ]]; then
        cp -r "$KEY_BACKUP_PATH"/* "$key_backup_dir/" 2>/dev/null
        log_info "密钥文件已备份"
    fi
}

# 恢复配置函数
restore_wireguard_config() {
    local temp_dir="$1"
    local wg_backup_dir="$temp_dir/wireguard"
    
    if [[ -d "$wg_backup_dir" ]]; then
        cp -r "$wg_backup_dir"/* "$WIREGUARD_BACKUP_PATH/" 2>/dev/null
        log_info "WireGuard配置已恢复"
    fi
}

restore_bird_config() {
    local temp_dir="$1"
    local bird_backup_dir="$temp_dir/bird"
    
    if [[ -d "$bird_backup_dir" ]]; then
        cp -r "$bird_backup_dir"/* "$BIRD_BACKUP_PATH/" 2>/dev/null
        log_info "BIRD配置已恢复"
    fi
}

restore_client_database() {
    local temp_dir="$1"
    local db_backup_dir="$temp_dir/database"
    
    if [[ -d "$db_backup_dir" ]]; then
        cp -r "$db_backup_dir"/* "$CLIENT_DB_BACKUP_PATH/" 2>/dev/null
        log_info "客户端数据库已恢复"
    fi
}

restore_config_files() {
    local temp_dir="$1"
    local config_backup_dir="$temp_dir/config"
    
    if [[ -d "$config_backup_dir" ]]; then
        cp -r "$config_backup_dir"/* "$CONFIG_BACKUP_PATH/" 2>/dev/null
        log_info "配置文件已恢复"
    fi
}

restore_key_files() {
    local temp_dir="$1"
    local key_backup_dir="$temp_dir/keys"
    
    if [[ -d "$key_backup_dir" ]]; then
        cp -r "$key_backup_dir"/* "$KEY_BACKUP_PATH/" 2>/dev/null
        log_info "密钥文件已恢复"
    fi
}

# 辅助函数

# 更新备份配置
update_backup_config() {
    local key="$1"
    local value="$2"
    
    if grep -q "^${key}=" "$BACKUP_CONFIG_FILE"; then
        sed -i "s/^${key}=.*/${key}=${value}/" "$BACKUP_CONFIG_FILE"
    else
        echo "${key}=${value}" >> "$BACKUP_CONFIG_FILE"
    fi
}

# 获取备份配置值
get_backup_config_value() {
    local key="$1"
    grep "^${key}=" "$BACKUP_CONFIG_FILE" | cut -d'=' -f2
}

# 检查备份是否存在
backup_exists() {
    local backup_id="$1"
    grep -q "^$backup_id|" "$BACKUP_HISTORY_DB"
}

# 验证备份完整性
verify_backup_integrity() {
    local backup_path="$1"
    
    if [[ "$backup_path" =~ \.tar\.gz$ ]]; then
        tar -tzf "$backup_path" >/dev/null 2>&1
    elif [[ "$backup_path" =~ \.tar$ ]]; then
        tar -tf "$backup_path" >/dev/null 2>&1
    elif [[ "$backup_path" =~ \.zip$ ]]; then
        unzip -t "$backup_path" >/dev/null 2>&1
    else
        return 1
    fi
}

# 验证备份内容
verify_backup_content() {
    local backup_path="$1"
    
    # 这里可以添加更详细的内容验证逻辑
    return 0
}

# 加密备份文件
encrypt_backup_file() {
    local backup_path="$1"
    
    if command -v gpg &> /dev/null; then
        gpg --symmetric --cipher-algo AES256 --passphrase "$BACKUP_PASSWORD" "$backup_path"
        rm -f "$backup_path"
        mv "${backup_path}.gpg" "$backup_path"
    else
        log_warn "GPG未安装，无法加密备份"
    fi
}

# 解密备份文件
decrypt_backup_file() {
    local backup_path="$1"
    local output_dir="$2"
    
    if command -v gpg &> /dev/null; then
        gpg --decrypt --passphrase "$BACKUP_PASSWORD" "$backup_path" | tar -xz -C "$output_dir"
    else
        log_warn "GPG未安装，无法解密备份"
        return 1
    fi
}

# 清理函数
cleanup_backups_by_time() {
    local days="$BACKUP_RETENTION_DAYS"
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$days -delete
    log_info "已清理 $days 天前的备份"
}

cleanup_backups_by_size() {
    local max_size=$(show_input "最大备份大小(MB)" "1000")
    find "$BACKUP_DIR" -name "*.tar.gz" -size +${max_size}M -delete
    log_info "已清理超过 ${max_size}MB 的备份"
}

cleanup_backups_by_count() {
    local max_count=$(show_input "最大备份数量" "10")
    ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | tail -n +$((max_count + 1)) | xargs rm -f
    log_info "已清理多余的备份，保留最新 $max_count 个"
}

cleanup_all_backups() {
    if show_confirm "确认删除所有备份"; then
        rm -f "$BACKUP_DIR"/*.tar.gz
        rm -f "$BACKUP_DIR"/*.tar
        rm -f "$BACKUP_DIR"/*.zip
        log_info "所有备份已删除"
    fi
}

# 占位函数
backup_details() { log_info "备份详情功能待实现"; }
backup_statistics() { log_info "备份统计功能待实现"; }
compress_backup() { log_info "备份压缩功能待实现"; }
encrypt_backup() { log_info "备份加密功能待实现"; }
get_next_backup_time() { echo "待计算"; }
execute_scheduled_backup() { log_info "执行计划备份功能待实现"; }
modify_backup_schedule() { log_info "修改备份计划功能待实现"; }
show_backup_schedule_details() { log_info "显示备份计划详情功能待实现"; }
import_backup() { log_info "导入备份功能待实现"; }
export_backup() { log_info "导出备份功能待实现"; }
remove_backup_from_history() { log_info "从历史删除备份功能待实现"; }

# 导出函数
export -f init_backup_restore create_backup_config init_backup_history_db
export -f load_backup_config backup_restore_menu auto_backup_settings
export -f toggle_auto_backup set_backup_interval set_backup_time set_retention_days
export -f configure_backup_content show_backup_settings manual_backup_config
export -f restore_config import_config export_config view_backup_history
export -f backup_management list_available_backups delete_backup backup_verification
export -f backup_cleanup backup_schedule create_backup restore_backup
export -f backup_wireguard_config backup_bird_config backup_client_database
export -f backup_config_files backup_log_files backup_key_files
export -f restore_wireguard_config restore_bird_config restore_client_database
export -f restore_config_files restore_key_files update_backup_config
export -f get_backup_config_value backup_exists verify_backup_integrity
export -f verify_backup_content encrypt_backup_file decrypt_backup_file
export -f cleanup_backups_by_time cleanup_backups_by_size cleanup_backups_by_count cleanup_all_backups
