#!/bin/bash

# 更新管理模块
# 提供版本检查、自动更新、更新日志等功能

# 更新检查菜单
update_check_menu() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    更新检查                                ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}更新检查选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 检查更新"
        echo -e "  ${GREEN}2.${NC} 版本信息"
        echo -e "  ${GREEN}3.${NC} 更新管理器"
        echo -e "  ${GREEN}4.${NC} 系统包更新"
        echo -e "  ${GREEN}5.${NC} 更新日志"
        echo -e "  ${GREEN}6.${NC} 自动更新设置"
        echo -e "  ${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 (0-6): " choice
        
        case "$choice" in
            "1")
                check_for_updates
                ;;
            "2")
                show_version_info
                ;;
            "3")
                update_manager
                ;;
            "4")
                update_system_packages
                ;;
            "5")
                show_update_log
                ;;
            "6")
                auto_update_settings
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

# 检查更新
check_for_updates() {
    echo -e "${CYAN}检查更新...${NC}"
    echo
    
    # 检查管理器更新
    echo -e "${CYAN}IPv6 WireGuard管理器更新:${NC}"
    local current_version="1.11"
    local latest_version=""
    
    # 尝试从GitHub获取最新版本
    if command -v curl >/dev/null 2>&1; then
        local api_response=$(curl -s "https://api.github.com/repos/ipv6-wireguard-manager/ipv6-wireguard-manager/releases/latest" 2>/dev/null)
        if [[ $? -eq 0 ]] && [[ -n "$api_response" ]]; then
            latest_version=$(echo "$api_response" | grep '"tag_name"' | cut -d'"' -f4)
        fi
    elif command -v wget >/dev/null 2>&1; then
        local api_response=$(wget -qO- "https://api.github.com/repos/ipv6-wireguard-manager/ipv6-wireguard-manager/releases/latest" 2>/dev/null)
        if [[ $? -eq 0 ]] && [[ -n "$api_response" ]]; then
            latest_version=$(echo "$api_response" | grep '"tag_name"' | cut -d'"' -f4)
        fi
    fi
    
    if [[ -n "$latest_version" ]]; then
        if [[ "$latest_version" != "$current_version" ]]; then
            echo -e "  当前版本: $current_version"
            echo -e "  最新版本: ${GREEN}$latest_version${NC}"
            echo -e "  状态: ${YELLOW}有新版本可用${NC}"
        else
            echo -e "  当前版本: $current_version"
            echo -e "  状态: ${GREEN}已是最新版本${NC}"
        fi
    else
        echo -e "  当前版本: $current_version"
        echo -e "  状态: ${YELLOW}无法检查更新${NC}"
    fi
    
    echo
    
    # 检查系统包更新
    echo -e "${CYAN}系统包更新:${NC}"
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt update >/dev/null 2>&1
            local update_count=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")
            if [[ "$update_count" -gt 0 ]]; then
                echo -e "  状态: ${YELLOW}有 $update_count 个包可更新${NC}"
            else
                echo -e "  状态: ${GREEN}系统已是最新${NC}"
            fi
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                local update_count=$(dnf check-update 2>/dev/null | grep -c "updates")
                if [[ "$update_count" -gt 0 ]]; then
                    echo -e "  状态: ${YELLOW}有 $update_count 个包可更新${NC}"
                else
                    echo -e "  状态: ${GREEN}系统已是最新${NC}"
                fi
            else
                local update_count=$(yum check-update 2>/dev/null | grep -c "updates")
                if [[ "$update_count" -gt 0 ]]; then
                    echo -e "  状态: ${YELLOW}有 $update_count 个包可更新${NC}"
                else
                    echo -e "  状态: ${GREEN}系统已是最新${NC}"
                fi
            fi
            ;;
        "arch")
            local update_count=$(pacman -Qu 2>/dev/null | wc -l)
            if [[ "$update_count" -gt 0 ]]; then
                echo -e "  状态: ${YELLOW}有 $update_count 个包可更新${NC}"
            else
                echo -e "  状态: ${GREEN}系统已是最新${NC}"
            fi
            ;;
    esac
    
    echo
    read -p "按回车键继续..."
}

# 显示版本信息
show_version_info() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    版本信息                                ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${CYAN}IPv6 WireGuard管理器:${NC}"
    echo "  版本: 1.0.5"
    echo "  构建日期: $(date -d "@$(stat -c %Y "$SCRIPT_DIR/ipv6-wireguard-manager.sh" 2>/dev/null || echo $(date +%s))" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "未知")"
    echo "  安装路径: $SCRIPT_DIR/"
    
    echo
    echo -e "${CYAN}系统信息:${NC}"
    echo "  操作系统: $OS_TYPE $OS_VERSION"
    echo "  内核版本: $(uname -r)"
    echo "  架构: $ARCH"
    echo "  主机名: $(hostname)"
    
    echo
    echo -e "${CYAN}相关软件版本:${NC}"
    
    # WireGuard版本
    if command -v wg >/dev/null 2>&1; then
        local wg_version=$(wg --version 2>/dev/null | head -1 || echo "未知")
        echo "  WireGuard: $wg_version"
    else
        echo "  WireGuard: 未安装"
    fi
    
    # BIRD版本
    if command -v birdc >/dev/null 2>&1; then
        local bird_version=$(birdc -v 2>/dev/null | head -1 || echo "未知")
        echo "  BIRD: $bird_version"
    elif command -v birdc2 >/dev/null 2>&1; then
        local bird_version=$(birdc2 -v 2>/dev/null | head -1 || echo "未知")
        echo "  BIRD2: $bird_version"
    else
        echo "  BIRD: 未安装"
    fi
    
    # 防火墙版本
    if command -v ufw >/dev/null 2>&1; then
        local ufw_version=$(ufw --version 2>/dev/null | head -1 || echo "未知")
        echo "  UFW: $ufw_version"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        local firewalld_version=$(firewall-cmd --version 2>/dev/null || echo "未知")
        echo "  Firewalld: $firewalld_version"
    else
        echo "  防火墙: 未配置"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 更新管理器
update_manager() {
    echo -e "${CYAN}更新管理器${NC}"
    echo "警告: 此操作将更新IPv6 WireGuard管理器脚本"
    read -p "确认更新管理器? (y/N): " confirm
    
    if [[ "${confirm,,}" == "y" ]]; then
        # 检查是否有更新脚本
        local update_script="$SCRIPT_DIR/scripts/update.sh"
        
        if [[ -f "$update_script" ]]; then
            echo "正在执行更新脚本..."
            if bash "$update_script"; then
                echo -e "${GREEN}✓${NC} 管理器更新成功"
                echo -e "${YELLOW}建议重新启动管理器以应用更新${NC}"
            else
                echo -e "${RED}✗${NC} 管理器更新失败"
            fi
        else
            echo -e "${YELLOW}更新脚本不存在，尝试手动更新...${NC}"
            
            # 尝试从GitHub下载最新版本
            if command -v curl >/dev/null 2>&1; then
                echo "正在从GitHub下载最新版本..."
                if curl -s -o "/tmp/ipv6-wireguard-manager.sh" "https://raw.githubusercontent.com/ipv6-wireguard-manager/ipv6-wireguard-manager/main/ipv6-wireguard-manager.sh"; then
                    if cp "/tmp/ipv6-wireguard-manager.sh" "$SCRIPT_DIR/ipv6-wireguard-manager.sh"; then
                        chmod +x "$SCRIPT_DIR/ipv6-wireguard-manager.sh"
                        echo -e "${GREEN}✓${NC} 管理器更新成功"
                        rm -f "/tmp/ipv6-wireguard-manager.sh"
                    else
                        echo -e "${RED}✗${NC} 管理器更新失败"
                    fi
                else
                    echo -e "${RED}✗${NC} 无法下载最新版本"
                fi
            else
                echo -e "${RED}✗${NC} 需要curl工具来下载更新"
            fi
        fi
    else
        echo -e "${YELLOW}管理器更新已取消${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 更新系统包
update_system_packages() {
    echo -e "${CYAN}系统包更新${NC}"
    echo "1. 检查更新"
    echo "2. 执行更新"
    echo "3. 仅安全更新"
    read -p "请选择操作 (1-3): " update_choice
    
    case "$update_choice" in
        "1")
            check_system_updates
            ;;
        "2")
            perform_system_update
            ;;
        "3")
            perform_security_update
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    read -p "按回车键继续..."
}

# 检查系统更新
check_system_updates() {
    echo -e "${CYAN}检查系统更新...${NC}"
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt update >/dev/null 2>&1
            echo -e "${CYAN}可更新的包:${NC}"
            apt list --upgradable 2>/dev/null | grep -v "Listing..." | while read line; do
                echo "  $line"
            done
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                echo -e "${CYAN}可更新的包:${NC}"
                dnf check-update 2>/dev/null | grep -v "Last metadata" | while read line; do
                    echo "  $line"
                done
            else
                echo -e "${CYAN}可更新的包:${NC}"
                yum check-update 2>/dev/null | grep -v "Loaded plugins" | while read line; do
                    echo "  $line"
                done
            fi
            ;;
        "arch")
            echo -e "${CYAN}可更新的包:${NC}"
            pacman -Qu 2>/dev/null | while read line; do
                echo "  $line"
            done
            ;;
    esac
}

# 执行系统更新
perform_system_update() {
    echo -e "${CYAN}执行系统更新...${NC}"
    echo "警告: 此操作将更新系统包，可能需要重启"
    read -p "确认继续? (y/N): " confirm
    
    if [[ "${confirm,,}" == "y" ]]; then
        case "$OS_TYPE" in
            "ubuntu"|"debian")
                apt update && apt upgrade -y
                ;;
            "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
                if command -v dnf >/dev/null 2>&1; then
                    dnf update -y
                else
                    yum update -y
                fi
                ;;
            "arch")
                pacman -Syu --noconfirm
                ;;
        esac
        echo -e "${GREEN}系统更新完成${NC}"
    else
        echo -e "${YELLOW}系统更新已取消${NC}"
    fi
}

# 执行安全更新
perform_security_update() {
    echo -e "${CYAN}执行安全更新...${NC}"
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt update && apt upgrade -y -s | grep -i security
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                dnf update --security -y
            else
                yum update --security -y
            fi
            ;;
        "arch")
            pacman -Syu --noconfirm
            ;;
    esac
    
    echo -e "${GREEN}安全更新完成${NC}"
}

# 显示更新日志
show_update_log() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    更新日志                                ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${CYAN}版本 1.0.5 (2024-01-20)${NC}"
    echo "  - 初始版本发布"
    echo "  - 支持IPv6 WireGuard配置"
    echo "  - 支持BIRD BGP路由"
    echo "  - 支持多种防火墙管理"
    echo "  - 支持客户端管理"
    echo "  - 支持配置备份和恢复"
    echo "  - 支持系统维护功能"
    echo "  - 支持自动更新检查"
    
    echo
    echo -e "${CYAN}计划中的功能:${NC}"
    echo "  - 支持更多BIRD版本"
    echo "  - 增强网络诊断工具"
    echo "  - 支持集群部署"
    echo "  - 支持Web管理界面"
    echo "  - 支持更多操作系统"
    
    echo
    read -p "按回车键继续..."
}

# 自动更新设置
auto_update_settings() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    自动更新设置                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}自动更新设置选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看自动更新设置"
        echo -e "  ${GREEN}2.${NC} 启用自动更新"
        echo -e "  ${GREEN}3.${NC} 禁用自动更新"
        echo -e "  ${GREEN}4.${NC} 设置更新频率"
        echo -e "  ${GREEN}5.${NC} 设置更新类型"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                show_auto_update_settings
                ;;
            "2")
                enable_auto_update
                ;;
            "3")
                disable_auto_update
                ;;
            "4")
                set_update_frequency
                ;;
            "5")
                set_update_type
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

# 查看自动更新设置
show_auto_update_settings() {
    echo -e "${CYAN}自动更新设置:${NC}"
    
    # 检查cron任务
    if crontab -l 2>/dev/null | grep -q "ipv6-wireguard-update"; then
        echo -e "  状态: ${GREEN}已启用${NC}"
        echo -e "  频率: $(crontab -l 2>/dev/null | grep "ipv6-wireguard-update" | awk '{print $1, $2, $3, $4, $5}')"
    else
        echo -e "  状态: ${RED}已禁用${NC}"
    fi
    
    # 检查更新脚本
    local update_script="$SCRIPT_DIR/scripts/auto_update.sh"
    if [[ -f "$update_script" ]]; then
        echo -e "  更新脚本: $update_script"
        echo -e "  脚本状态: ${GREEN}存在${NC}"
    else
        echo -e "  更新脚本: ${RED}不存在${NC}"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 启用自动更新
enable_auto_update() {
    echo -e "${CYAN}启用自动更新${NC}"
    
    # 设置默认更新频率 (每周日凌晨3点)
    local cron_schedule="0 3 * * 0"
    
    # 创建更新脚本
    local update_script="$SCRIPT_DIR/scripts/auto_update.sh"
    mkdir -p "$(dirname "$update_script")"
    
    cat > "$update_script" << 'EOF'
#!/bin/bash

# 自动更新脚本
LOG_FILE="/var/log/ipv6-wireguard-update.log"

echo "$(date): 开始自动更新检查" >> "$LOG_FILE"

# 检查管理器更新
if command -v curl >/dev/null 2>&1; then
    local api_response=$(curl -s "https://api.github.com/repos/ipv6-wireguard-manager/ipv6-wireguard-manager/releases/latest" 2>/dev/null)
    if [[ $? -eq 0 ]] && [[ -n "$api_response" ]]; then
        latest_version=$(echo "$api_response" | grep '"tag_name"' | cut -d'"' -f4)
    fi
    current_version="1.11"
    
    if [[ -n "$latest_version" ]] && [[ "$latest_version" != "$current_version" ]]; then
        echo "$(date): 发现新版本 $latest_version" >> "$LOG_FILE"
        
        # 下载并更新管理器
        if curl -s -o "/tmp/ipv6-wireguard-manager.sh" "https://raw.githubusercontent.com/ipv6-wireguard-manager/ipv6-wireguard-manager/main/ipv6-wireguard-manager.sh"; then
            if cp "/tmp/ipv6-wireguard-manager.sh" "$SCRIPT_DIR/ipv6-wireguard-manager.sh"; then
                chmod +x "$SCRIPT_DIR/ipv6-wireguard-manager.sh"
                echo "$(date): 管理器更新成功" >> "$LOG_FILE"
                rm -f "/tmp/ipv6-wireguard-manager.sh"
            else
                echo "$(date): 管理器更新失败" >> "$LOG_FILE"
            fi
        else
            echo "$(date): 无法下载最新版本" >> "$LOG_FILE"
        fi
    else
        echo "$(date): 管理器已是最新版本" >> "$LOG_FILE"
    fi
fi

# 检查系统包更新
case "$(uname -s)" in
    "Linux")
        if command -v apt >/dev/null 2>&1; then
            apt update >/dev/null 2>&1
            update_count=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")
            if [[ "$update_count" -gt 0 ]]; then
                echo "$(date): 发现 $update_count 个系统包可更新" >> "$LOG_FILE"
                # 这里可以添加自动更新系统包的逻辑
            fi
        fi
        ;;
esac

echo "$(date): 自动更新检查完成" >> "$LOG_FILE"
EOF
    
    chmod +x "$update_script"
    
    # 添加cron任务
    (crontab -l 2>/dev/null; echo "$cron_schedule $update_script") | crontab -
    
    echo -e "${GREEN}✓${NC} 自动更新已启用"
    echo -e "  更新频率: 每周日凌晨3点"
    echo -e "  更新脚本: $update_script"
    echo -e "  日志文件: /var/log/ipv6-wireguard-update.log"
    
    read -p "按回车键继续..."
}

# 禁用自动更新
disable_auto_update() {
    echo -e "${CYAN}禁用自动更新${NC}"
    
    # 移除cron任务
    crontab -l 2>/dev/null | grep -v "ipv6-wireguard-update" | crontab -
    
    # 删除更新脚本
    local update_script="$SCRIPT_DIR/scripts/auto_update.sh"
    if [[ -f "$update_script" ]]; then
        rm "$update_script"
    fi
    
    echo -e "${GREEN}✓${NC} 自动更新已禁用"
    
    read -p "按回车键继续..."
}

# 设置更新频率
set_update_frequency() {
    echo -e "${CYAN}设置更新频率${NC}"
    echo "1. 每小时"
    echo "2. 每天"
    echo "3. 每周"
    echo "4. 每月"
    echo "5. 自定义"
    read -p "请选择更新频率 (1-5): " frequency
    
    local cron_schedule=""
    
    case "$frequency" in
        "1")
            cron_schedule="0 * * * *"  # 每小时
            ;;
        "2")
            cron_schedule="0 3 * * *"  # 每天凌晨3点
            ;;
        "3")
            cron_schedule="0 3 * * 0"  # 每周日凌晨3点
            ;;
        "4")
            cron_schedule="0 3 1 * *"  # 每月1日凌晨3点
            ;;
        "5")
            read -p "请输入cron表达式 (如: 0 3 * * 0): " cron_schedule
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            read -p "按回车键继续..."
            return
            ;;
    esac
    
    if [[ -n "$cron_schedule" ]]; then
        # 更新cron任务
        crontab -l 2>/dev/null | grep -v "ipv6-wireguard-update" | crontab -
        (crontab -l 2>/dev/null; echo "$cron_schedule $SCRIPT_DIR/scripts/auto_update.sh") | crontab -
        
        echo -e "${GREEN}✓${NC} 更新频率已设置为: $cron_schedule"
    fi
    
    read -p "按回车键继续..."
}

# 设置更新类型
set_update_type() {
    echo -e "${CYAN}设置更新类型${NC}"
    echo "1. 仅检查更新"
    echo "2. 自动更新管理器"
    echo "3. 自动更新系统包"
    echo "4. 全部自动更新"
    read -p "请选择更新类型 (1-4): " update_type
    
    local update_script="$SCRIPT_DIR/scripts/auto_update.sh"
    
    if [[ -f "$update_script" ]]; then
        case "$update_type" in
            "1")
                # 仅检查更新
                sed -i 's/# 这里可以添加自动更新系统包的逻辑/echo "$(date): 仅检查更新，不执行自动更新" >> "$LOG_FILE"/' "$update_script"
                echo -e "${GREEN}✓${NC} 更新类型已设置为: 仅检查更新"
                ;;
            "2")
                # 自动更新管理器
                sed -i 's/# 这里可以添加自动更新系统包的逻辑/echo "$(date): 仅更新管理器，不更新系统包" >> "$LOG_FILE"/' "$update_script"
                echo -e "${GREEN}✓${NC} 更新类型已设置为: 自动更新管理器"
                ;;
            "3")
                # 自动更新系统包
                sed -i 's/# 这里可以添加自动更新系统包的逻辑/apt upgrade -y >> "$LOG_FILE" 2>&1/' "$update_script"
                echo -e "${GREEN}✓${NC} 更新类型已设置为: 自动更新系统包"
                ;;
            "4")
                # 全部自动更新
                sed -i 's/# 这里可以添加自动更新系统包的逻辑/apt upgrade -y >> "$LOG_FILE" 2>&1/' "$update_script"
                echo -e "${GREEN}✓${NC} 更新类型已设置为: 全部自动更新"
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                ;;
        esac
    else
        echo -e "${YELLOW}自动更新未启用，请先启用自动更新${NC}"
    fi
    
    read -p "按回车键继续..."
}
