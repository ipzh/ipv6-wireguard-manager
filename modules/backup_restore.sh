#!/bin/bash

# 备份恢复模块
# 提供配置备份、恢复、自动备份设置等功能

# 备份恢复菜单
backup_restore_menu() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    配置备份/恢复                          ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}备份恢复选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 创建配置备份"
        echo -e "  ${GREEN}2.${NC} 恢复配置备份"
        echo -e "  ${GREEN}3.${NC} 列出备份文件"
        echo -e "  ${GREEN}4.${NC} 删除备份文件"
        echo -e "  ${GREEN}5.${NC} 自动备份设置"
        echo -e "  ${GREEN}6.${NC} 导出配置"
        echo -e "  ${GREEN}7.${NC} 导入配置"
        echo -e "  ${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 (0-7): " choice
        
        case "$choice" in
            "1")
                create_config_backup
                ;;
            "2")
                restore_config_backup
                ;;
            "3")
                list_backups
                ;;
            "4")
                delete_backup
                ;;
            "5")
                auto_backup_settings
                ;;
            "6")
                export_config
                ;;
            "7")
                import_config
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 创建配置备份
create_config_backup() {
    echo -e "${CYAN}创建配置备份${NC}"
    
    # 创建备份目录
    local backup_dir="$SCRIPT_DIR/backups"
    mkdir -p "$backup_dir"
    
    # 生成备份文件名
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$backup_dir/ipv6_wireguard_backup_$timestamp.tar.gz"
    
    echo "正在创建备份文件: $backup_file"
    
    # 创建临时目录
    local temp_dir=$(mktemp -d)
    
    # 复制配置文件
    if [[ -d /etc/wireguard ]]; then
        cp -r /etc/wireguard "$temp_dir/" 2>/dev/null
        echo -e "${GREEN}✓${NC} WireGuard配置已复制"
    fi
    
    if [[ -f /etc/bird/bird.conf ]]; then
        cp -r /etc/bird "$temp_dir/" 2>/dev/null
        echo -e "${GREEN}✓${NC} BIRD配置已复制"
    fi
    
    if [[ -f "$SCRIPT_DIR/manager.conf" ]]; then
        cp "$SCRIPT_DIR/manager.conf" "$temp_dir/" 2>/dev/null
        echo -e "${GREEN}✓${NC} 管理器配置已复制"
    fi
    
    # 保存防火墙状态
    if command -v ufw >/dev/null 2>&1; then
        ufw status > "$temp_dir/ufw_status.txt" 2>/dev/null
        echo -e "${GREEN}✓${NC} UFW状态已保存"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --list-all > "$temp_dir/firewalld_status.txt" 2>/dev/null
        echo -e "${GREEN}✓${NC} Firewalld状态已保存"
    fi
    
    # 保存系统信息
    {
        echo "备份时间: $(date)"
        echo "系统信息: $OS_TYPE $OS_VERSION"
        echo "内核版本: $(uname -r)"
        echo "架构: $ARCH"
    } > "$temp_dir/system_info.txt"
    
    # 创建压缩包
    if tar -czf "$backup_file" -C "$temp_dir" . 2>/dev/null; then
        echo -e "${GREEN}✓${NC} 备份文件创建成功: $backup_file"
        
        # 显示备份文件信息
        local backup_size=$(du -h "$backup_file" | cut -f1)
        echo "备份文件大小: $backup_size"
    else
        echo -e "${RED}✗${NC} 备份文件创建失败"
    fi
    
    # 清理临时目录
    rm -rf "$temp_dir"
    
    read -p "按回车键继续..."
}

# 恢复配置备份
restore_config_backup() {
    echo -e "${CYAN}恢复配置备份${NC}"
    
    local backup_dir="$SCRIPT_DIR/backups"
    
    if [[ ! -d "$backup_dir" ]]; then
        echo -e "${RED}备份目录不存在${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    # 列出可用的备份文件
    echo -e "${CYAN}可用的备份文件:${NC}"
    local backups=($(ls -t "$backup_dir"/*.tar.gz 2>/dev/null))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo -e "${RED}没有找到备份文件${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    # 显示备份文件列表
    for i in "${!backups[@]}"; do
        local file=$(basename "${backups[$i]}")
        local size=$(du -h "${backups[$i]}" | cut -f1)
        local date=$(stat -c "%y" "${backups[$i]}" | cut -d' ' -f1,2 | cut -d'.' -f1)
        echo "  $((i+1)). $file ($size, $date)"
    done
    
    echo
    read -p "请选择要恢复的备份文件编号 (1-${#backups[@]}): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#backups[@]} ]]; then
        local selected_backup="${backups[$((choice-1))]}"
        local backup_name=$(basename "$selected_backup")
        
        echo -e "${YELLOW}警告: 此操作将覆盖当前配置${NC}"
        read -p "确认恢复备份 '$backup_name'? (y/N): " confirm
        
        if [[ "${confirm,,}" == "y" ]]; then
            # 创建临时目录
            local temp_dir=$(mktemp -d)
            
            # 解压备份文件
            if tar -xzf "$selected_backup" -C "$temp_dir" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} 备份文件解压成功"
                
                # 恢复WireGuard配置
                if [[ -d "$temp_dir/wireguard" ]]; then
                    if cp -r "$temp_dir/wireguard"/* /etc/wireguard/ 2>/dev/null; then
                        echo -e "${GREEN}✓${NC} WireGuard配置已恢复"
                    else
                        echo -e "${RED}✗${NC} WireGuard配置恢复失败"
                    fi
                fi
                
                # 恢复BIRD配置
                if [[ -d "$temp_dir/bird" ]]; then
                    if cp -r "$temp_dir/bird"/* /etc/bird/ 2>/dev/null; then
                        echo -e "${GREEN}✓${NC} BIRD配置已恢复"
                    else
                        echo -e "${RED}✗${NC} BIRD配置恢复失败"
                    fi
                fi
                
                # 恢复管理器配置
                if [[ -f "$temp_dir/manager.conf" ]]; then
                    if cp "$temp_dir/manager.conf" "$SCRIPT_DIR/" 2>/dev/null; then
                        echo -e "${GREEN}✓${NC} 管理器配置已恢复"
                    else
                        echo -e "${RED}✗${NC} 管理器配置恢复失败"
                    fi
                fi
                
                # 恢复防火墙状态
                if [[ -f "$temp_dir/ufw_status.txt" ]]; then
                    echo -e "${YELLOW}请手动恢复UFW状态${NC}"
                elif [[ -f "$temp_dir/firewalld_status.txt" ]]; then
                    echo -e "${YELLOW}请手动恢复Firewalld状态${NC}"
                fi
                
                echo -e "${GREEN}配置恢复完成${NC}"
                echo -e "${YELLOW}建议重启相关服务以应用新配置${NC}"
            else
                echo -e "${RED}✗${NC} 备份文件解压失败"
            fi
            
            # 清理临时目录
            rm -rf "$temp_dir"
        else
            echo -e "${YELLOW}配置恢复已取消${NC}"
        fi
    else
        echo -e "${RED}无效选择${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 列出备份文件
list_backups() {
    echo -e "${CYAN}备份文件列表:${NC}"
    
    local backup_dir="$SCRIPT_DIR/backups"
    
    if [[ ! -d "$backup_dir" ]]; then
        echo -e "${RED}备份目录不存在${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    local backups=($(ls -t "$backup_dir"/*.tar.gz 2>/dev/null))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo -e "${YELLOW}没有找到备份文件${NC}"
    else
        echo
        printf "%-4s %-40s %-10s %-20s\n" "序号" "文件名" "大小" "创建时间"
        echo "----------------------------------------------------------------"
        
        for i in "${!backups[@]}"; do
            local file=$(basename "${backups[$i]}")
            local size=$(du -h "${backups[$i]}" | cut -f1)
            local date=$(stat -c "%y" "${backups[$i]}" | cut -d' ' -f1,2 | cut -d'.' -f1)
            printf "%-4s %-40s %-10s %-20s\n" "$((i+1))" "$file" "$size" "$date"
        done
    fi
    
    echo
    read -p "按回车键继续..."
}

# 删除备份文件
delete_backup() {
    echo -e "${CYAN}删除备份文件${NC}"
    
    local backup_dir="$SCRIPT_DIR/backups"
    
    if [[ ! -d "$backup_dir" ]]; then
        echo -e "${RED}备份目录不存在${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    # 列出可用的备份文件
    local backups=($(ls -t "$backup_dir"/*.tar.gz 2>/dev/null))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo -e "${RED}没有找到备份文件${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    # 显示备份文件列表
    echo -e "${CYAN}可用的备份文件:${NC}"
    for i in "${!backups[@]}"; do
        local file=$(basename "${backups[$i]}")
        local size=$(du -h "${backups[$i]}" | cut -f1)
        local date=$(stat -c "%y" "${backups[$i]}" | cut -d' ' -f1,2 | cut -d'.' -f1)
        echo "  $((i+1)). $file ($size, $date)"
    done
    
    echo
    read -p "请选择要删除的备份文件编号 (1-${#backups[@]}): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#backups[@]} ]]; then
        local selected_backup="${backups[$((choice-1))]}"
        local backup_name=$(basename "$selected_backup")
        
        read -p "确认删除备份 '$backup_name'? (y/N): " confirm
        
        if [[ "${confirm,,}" == "y" ]]; then
            if rm "$selected_backup" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} 备份文件已删除"
            else
                echo -e "${RED}✗${NC} 删除失败"
            fi
        else
            echo -e "${YELLOW}删除已取消${NC}"
        fi
    else
        echo -e "${RED}无效选择${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 自动备份设置
auto_backup_settings() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    自动备份设置                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}自动备份设置选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看自动备份设置"
        echo -e "  ${GREEN}2.${NC} 启用自动备份"
        echo -e "  ${GREEN}3.${NC} 禁用自动备份"
        echo -e "  ${GREEN}4.${NC} 设置备份频率"
        echo -e "  ${GREEN}5.${NC} 设置备份保留数量"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                show_auto_backup_settings
                ;;
            "2")
                enable_auto_backup
                ;;
            "3")
                disable_auto_backup
                ;;
            "4")
                set_backup_frequency
                ;;
            "5")
                set_backup_retention
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 查看自动备份设置
show_auto_backup_settings() {
    echo -e "${CYAN}自动备份设置:${NC}"
    
    # 检查cron任务
    if crontab -l 2>/dev/null | grep -q "ipv6-wireguard-backup"; then
        echo -e "  状态: ${GREEN}已启用${NC}"
        echo -e "  频率: $(crontab -l 2>/dev/null | grep "ipv6-wireguard-backup" | awk '{print $1, $2, $3, $4, $5}')"
    else
        echo -e "  状态: ${RED}已禁用${NC}"
    fi
    
    # 检查备份目录
    local backup_dir="$SCRIPT_DIR/backups"
    if [[ -d "$backup_dir" ]]; then
        local backup_count=$(ls -1 "$backup_dir"/*.tar.gz 2>/dev/null | wc -l)
        echo -e "  备份目录: $backup_dir"
        echo -e "  备份数量: $backup_count"
    else
        echo -e "  备份目录: ${RED}不存在${NC}"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 启用自动备份
enable_auto_backup() {
    echo -e "${CYAN}启用自动备份${NC}"
    
    # 设置默认备份频率 (每天凌晨2点)
    local cron_schedule="0 2 * * *"
    
    # 创建备份脚本
    local backup_script="$SCRIPT_DIR/scripts/auto_backup.sh"
    mkdir -p "$(dirname "$backup_script")"
    
    cat > "$backup_script" << 'EOF'
#!/bin/bash

# 自动备份脚本
BACKUP_DIR="$SCRIPT_DIR/backups"
mkdir -p "$BACKUP_DIR"

# 生成备份文件名
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/ipv6_wireguard_auto_backup_$TIMESTAMP.tar.gz"

# 创建临时目录
TEMP_DIR=$(mktemp -d)

# 复制配置文件
if [[ -d /etc/wireguard ]]; then
    cp -r /etc/wireguard "$TEMP_DIR/" 2>/dev/null
fi

if [[ -f /etc/bird/bird.conf ]]; then
    cp -r /etc/bird "$TEMP_DIR/" 2>/dev/null
fi

if [[ -f "$SCRIPT_DIR/manager.conf" ]]; then
    cp "$SCRIPT_DIR/manager.conf" "$TEMP_DIR/" 2>/dev/null
fi

# 保存系统信息
{
    echo "备份时间: $(date)"
    echo "系统信息: $(uname -a)"
} > "$TEMP_DIR/system_info.txt"

# 创建压缩包
if tar -czf "$BACKUP_FILE" -C "$TEMP_DIR" . 2>/dev/null; then
    echo "$(date): 自动备份创建成功: $BACKUP_FILE" >> /var/log/ipv6-wireguard-backup.log
else
    echo "$(date): 自动备份创建失败" >> /var/log/ipv6-wireguard-backup.log
fi

# 清理临时目录
rm -rf "$TEMP_DIR"

# 清理旧备份 (保留最近30个)
cd "$BACKUP_DIR"
ls -t ipv6_wireguard_auto_backup_*.tar.gz 2>/dev/null | tail -n +31 | xargs -r rm

echo "$(date): 自动备份完成" >> /var/log/ipv6-wireguard-backup.log
EOF
    
    chmod +x "$backup_script"
    
    # 添加cron任务
    (crontab -l 2>/dev/null; echo "$cron_schedule $backup_script") | crontab -
    
    echo -e "${GREEN}✓${NC} 自动备份已启用"
    echo -e "  备份频率: 每天凌晨2点"
    echo -e "  备份脚本: $backup_script"
    echo -e "  日志文件: /var/log/ipv6-wireguard-backup.log"
    
    read -p "按回车键继续..."
}

# 禁用自动备份
disable_auto_backup() {
    echo -e "${CYAN}禁用自动备份${NC}"
    
    # 移除cron任务
    crontab -l 2>/dev/null | grep -v "ipv6-wireguard-backup" | crontab -
    
    # 删除备份脚本
    local backup_script="$SCRIPT_DIR/scripts/auto_backup.sh"
    if [[ -f "$backup_script" ]]; then
        rm "$backup_script"
    fi
    
    echo -e "${GREEN}✓${NC} 自动备份已禁用"
    
    read -p "按回车键继续..."
}

# 设置备份频率
set_backup_frequency() {
    echo -e "${CYAN}设置备份频率${NC}"
    echo "1. 每小时"
    echo "2. 每天"
    echo "3. 每周"
    echo "4. 每月"
    echo "5. 自定义"
    read -p "请选择备份频率 (1-5): " frequency
    
    local cron_schedule=""
    
    case "$frequency" in
        "1")
            cron_schedule="0 * * * *"  # 每小时
            ;;
        "2")
            cron_schedule="0 2 * * *"  # 每天凌晨2点
            ;;
        "3")
            cron_schedule="0 2 * * 0"  # 每周日凌晨2点
            ;;
        "4")
            cron_schedule="0 2 1 * *"  # 每月1日凌晨2点
            ;;
        "5")
            read -p "请输入cron表达式 (如: 0 2 * * *): " cron_schedule
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            read -p "按回车键继续..."
            return
            ;;
    esac
    
    if [[ -n "$cron_schedule" ]]; then
        # 更新cron任务
        crontab -l 2>/dev/null | grep -v "ipv6-wireguard-backup" | crontab -
        (crontab -l 2>/dev/null; echo "$cron_schedule $SCRIPT_DIR/scripts/auto_backup.sh") | crontab -
        
        echo -e "${GREEN}✓${NC} 备份频率已设置为: $cron_schedule"
    fi
    
    read -p "按回车键继续..."
}

# 设置备份保留数量
set_backup_retention() {
    echo -e "${CYAN}设置备份保留数量${NC}"
    read -p "请输入要保留的备份文件数量 (默认30): " retention_count
    
    retention_count="${retention_count:-30}"
    
    if [[ "$retention_count" =~ ^[0-9]+$ ]] && [[ "$retention_count" -gt 0 ]]; then
        # 更新备份脚本中的保留数量
        local backup_script="$SCRIPT_DIR/scripts/auto_backup.sh"
        if [[ -f "$backup_script" ]]; then
            sed -i "s/tail -n +31/tail -n +$((retention_count + 1))/" "$backup_script"
            echo -e "${GREEN}✓${NC} 备份保留数量已设置为: $retention_count"
        else
            echo -e "${YELLOW}自动备份未启用，请先启用自动备份${NC}"
        fi
    else
        echo -e "${RED}请输入有效的数字${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 导出配置
export_config() {
    echo -e "${CYAN}导出配置${NC}"
    
    # 创建导出目录
    local export_dir="$SCRIPT_DIR/exports"
    mkdir -p "$export_dir"
    
    # 生成导出文件名
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local export_file="$export_dir/ipv6_wireguard_export_$timestamp.tar.gz"
    
    echo "正在导出配置到: $export_file"
    
    # 创建临时目录
    local temp_dir=$(mktemp -d)
    
    # 复制配置文件
    if [[ -d /etc/wireguard ]]; then
        cp -r /etc/wireguard "$temp_dir/" 2>/dev/null
        echo -e "${GREEN}✓${NC} WireGuard配置已导出"
    fi
    
    if [[ -f /etc/bird/bird.conf ]]; then
        cp -r /etc/bird "$temp_dir/" 2>/dev/null
        echo -e "${GREEN}✓${NC} BIRD配置已导出"
    fi
    
    if [[ -f "$SCRIPT_DIR/manager.conf" ]]; then
        cp "$SCRIPT_DIR/manager.conf" "$temp_dir/" 2>/dev/null
        echo -e "${GREEN}✓${NC} 管理器配置已导出"
    fi
    
    # 保存系统信息
    {
        echo "导出时间: $(date)"
        echo "系统信息: $OS_TYPE $OS_VERSION"
        echo "内核版本: $(uname -r)"
        echo "架构: $ARCH"
    } > "$temp_dir/system_info.txt"
    
    # 创建压缩包
    if tar -czf "$export_file" -C "$temp_dir" . 2>/dev/null; then
        echo -e "${GREEN}✓${NC} 配置导出成功: $export_file"
        
        # 显示导出文件信息
        local export_size=$(du -h "$export_file" | cut -f1)
        echo "导出文件大小: $export_size"
    else
        echo -e "${RED}✗${NC} 配置导出失败"
    fi
    
    # 清理临时目录
    rm -rf "$temp_dir"
    
    read -p "按回车键继续..."
}

# 导入配置
import_config() {
    echo -e "${CYAN}导入配置${NC}"
    
    local export_dir="$SCRIPT_DIR/exports"
    
    if [[ ! -d "$export_dir" ]]; then
        echo -e "${RED}导出目录不存在${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    # 列出可用的导出文件
    echo -e "${CYAN}可用的导出文件:${NC}"
    local exports=($(ls -t "$export_dir"/*.tar.gz 2>/dev/null))
    
    if [[ ${#exports[@]} -eq 0 ]]; then
        echo -e "${RED}没有找到导出文件${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    # 显示导出文件列表
    for i in "${!exports[@]}"; do
        local file=$(basename "${exports[$i]}")
        local size=$(du -h "${exports[$i]}" | cut -f1)
        local date=$(stat -c "%y" "${exports[$i]}" | cut -d' ' -f1,2 | cut -d'.' -f1)
        echo "  $((i+1)). $file ($size, $date)"
    done
    
    echo
    read -p "请选择要导入的导出文件编号 (1-${#exports[@]}): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#exports[@]} ]]; then
        local selected_export="${exports[$((choice-1))]}"
        local export_name=$(basename "$selected_export")
        
        echo -e "${YELLOW}警告: 此操作将覆盖当前配置${NC}"
        read -p "确认导入配置 '$export_name'? (y/N): " confirm
        
        if [[ "${confirm,,}" == "y" ]]; then
            # 创建临时目录
            local temp_dir=$(mktemp -d)
            
            # 解压导出文件
            if tar -xzf "$selected_export" -C "$temp_dir" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} 导出文件解压成功"
                
                # 导入WireGuard配置
                if [[ -d "$temp_dir/wireguard" ]]; then
                    if cp -r "$temp_dir/wireguard"/* /etc/wireguard/ 2>/dev/null; then
                        echo -e "${GREEN}✓${NC} WireGuard配置已导入"
                    else
                        echo -e "${RED}✗${NC} WireGuard配置导入失败"
                    fi
                fi
                
                # 导入BIRD配置
                if [[ -d "$temp_dir/bird" ]]; then
                    if cp -r "$temp_dir/bird"/* /etc/bird/ 2>/dev/null; then
                        echo -e "${GREEN}✓${NC} BIRD配置已导入"
                    else
                        echo -e "${RED}✗${NC} BIRD配置导入失败"
                    fi
                fi
                
                # 导入管理器配置
                if [[ -f "$temp_dir/manager.conf" ]]; then
                    if cp "$temp_dir/manager.conf" "$SCRIPT_DIR/" 2>/dev/null; then
                        echo -e "${GREEN}✓${NC} 管理器配置已导入"
                    else
                        echo -e "${RED}✗${NC} 管理器配置导入失败"
                    fi
                fi
                
                echo -e "${GREEN}配置导入完成${NC}"
                echo -e "${YELLOW}建议重启相关服务以应用新配置${NC}"
            else
                echo -e "${RED}✗${NC} 导出文件解压失败"
            fi
            
            # 清理临时目录
            rm -rf "$temp_dir"
        else
            echo -e "${YELLOW}配置导入已取消${NC}"
        fi
    else
        echo -e "${RED}无效选择${NC}"
    fi
    
    read -p "按回车键继续..."
}

