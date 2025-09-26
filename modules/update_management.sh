#!/bin/bash

# 更新管理模块
# 负责版本检查、自动更新、更新日志、版本回滚等功能

# 更新管理配置变量
UPDATE_CONFIG_DIR="${CONFIG_DIR}/update"
UPDATE_CONFIG_FILE="${UPDATE_CONFIG_DIR}/update.conf"
UPDATE_LOG_FILE="${UPDATE_CONFIG_DIR}/update.log"
VERSION_DB="${UPDATE_CONFIG_DIR}/versions.db"
BACKUP_DIR="${UPDATE_CONFIG_DIR}/backups"

# 版本信息
CURRENT_VERSION="1.0.0"
LATEST_VERSION=""
UPDATE_AVAILABLE=false
AUTO_UPDATE_ENABLED=false
UPDATE_CHECK_INTERVAL=86400  # 24小时

# 更新源配置（从仓库配置加载）
UPDATE_REPOSITORY="${REPO_URL:-https://github.com/ipzh/ipv6-wireguard-manager}"
UPDATE_BRANCH="${REPO_BRANCH:-main}"
UPDATE_API_URL="${LATEST_RELEASE_URL:-https://api.github.com/repos/ipzh/ipv6-wireguard-manager/releases/latest}"

# 初始化更新管理
init_update_management() {
    log_info "初始化更新管理..."
    
    # 创建配置目录
    mkdir -p "$UPDATE_CONFIG_DIR" "$BACKUP_DIR"
    
    # 创建配置文件
    create_update_config
    
    # 加载配置
    load_update_config
    
    # 初始化版本数据库
    init_version_database
    
    log_info "更新管理初始化完成"
}

# 创建更新配置文件
create_update_config() {
    if [[ ! -f "$UPDATE_CONFIG_FILE" ]]; then
        cat > "$UPDATE_CONFIG_FILE" << EOF
# 更新管理配置文件
# 生成时间: $(get_timestamp)

# 版本信息
CURRENT_VERSION=$CURRENT_VERSION
LATEST_VERSION=
UPDATE_AVAILABLE=false

# 自动更新设置
AUTO_UPDATE_ENABLED=false
UPDATE_CHECK_INTERVAL=86400
UPDATE_CHECK_TIME=0

# 更新源配置
UPDATE_REPOSITORY=$UPDATE_REPOSITORY
UPDATE_BRANCH=$UPDATE_BRANCH
UPDATE_API_URL=$UPDATE_API_URL

# 备份设置
BACKUP_ENABLED=true
BACKUP_RETENTION_DAYS=30
BACKUP_BEFORE_UPDATE=true

# 通知设置
NOTIFICATION_ENABLED=true
NOTIFICATION_EMAIL=""
NOTIFICATION_WEBHOOK=""

# 安全设置
VERIFY_SIGNATURES=true
TRUSTED_KEYS=""
CHECKSUM_VERIFICATION=true

# 回滚设置
ROLLBACK_ENABLED=true
MAX_ROLLBACK_VERSIONS=5
EOF
        log_info "更新配置文件已创建: $UPDATE_CONFIG_FILE"
    fi
}

# 加载更新配置
load_update_config() {
    if [[ -f "$UPDATE_CONFIG_FILE" ]]; then
        source "$UPDATE_CONFIG_FILE"
        log_info "更新配置已加载"
    else
        log_warn "更新配置文件不存在，使用默认配置"
    fi
}

# 初始化版本数据库
init_version_database() {
    if [[ ! -f "$VERSION_DB" ]]; then
        cat > "$VERSION_DB" << EOF
# 版本数据库
# 格式: 版本号|安装时间|安装路径|备份路径|状态
$CURRENT_VERSION|$(date '+%Y-%m-%d %H:%M:%S')|$(pwd)|$BACKUP_DIR/backup_$CURRENT_VERSION|installed
EOF
        log_info "版本数据库已初始化"
    fi
}

# 更新检查菜单
update_check_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 更新检查 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 检查当前版本"
        echo -e "${GREEN}2.${NC} 检查更新"
        echo -e "${GREEN}3.${NC} 自动更新"
        echo -e "${GREEN}4.${NC} 查看更新日志"
        echo -e "${GREEN}5.${NC} 回滚版本"
        echo -e "${GREEN}6.${NC} 更新设置"
        echo -e "${GREEN}7.${NC} 更新历史"
        echo -e "${GREEN}8.${NC} 清理更新文件"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -p "请选择操作 [0-8]: " choice
        
        case $choice in
            1) check_current_version ;;
            2) check_for_updates ;;
            3) auto_update ;;
            4) view_update_log ;;
            5) rollback_version ;;
            6) update_settings ;;
            7) update_history ;;
            8) cleanup_update_files ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 检查当前版本
check_current_version() {
    echo -e "${SECONDARY_COLOR}=== 检查当前版本 ===${NC}"
    echo
    
    echo "当前版本信息:"
    echo "----------------------------------------"
    echo "版本号: $CURRENT_VERSION"
    echo "安装路径: $(pwd)"
    echo "安装时间: $(get_installation_time)"
    echo "构建信息: $(get_build_info)"
    echo "Git信息: $(get_git_info)"
    echo
    
    # 显示组件版本
    echo "组件版本:"
    echo "----------------------------------------"
    show_component_versions
    
    # 显示系统信息
    echo "系统信息:"
    echo "----------------------------------------"
    show_system_info
}

# 获取安装时间
get_installation_time() {
    if [[ -f "$VERSION_DB" ]]; then
        grep "^$CURRENT_VERSION|" "$VERSION_DB" | cut -d'|' -f2
    else
        echo "未知"
    fi
}

# 获取构建信息
get_build_info() {
    local build_file="BUILD_INFO"
    if [[ -f "$build_file" ]]; then
        cat "$build_file"
    else
        echo "构建信息不可用"
    fi
}

# 获取Git信息
get_git_info() {
    if command -v git &> /dev/null && [[ -d ".git" ]]; then
        local commit=$(git rev-parse --short HEAD 2>/dev/null)
        local branch=$(git branch --show-current 2>/dev/null)
        local date=$(git log -1 --format=%cd --date=short 2>/dev/null)
        echo "分支: $branch, 提交: $commit, 日期: $date"
    else
        echo "Git信息不可用"
    fi
}

# 显示组件版本
show_component_versions() {
    echo "WireGuard: $(get_wireguard_version)"
    echo "BIRD: $(get_bird_version)"
    echo "系统内核: $(uname -r)"
    echo "Bash: $(bash --version | head -1)"
    echo "Python: $(python3 --version 2>/dev/null || echo '未安装')"
    echo "Node.js: $(node --version 2>/dev/null || echo '未安装')"
}

# 获取WireGuard版本
get_wireguard_version() {
    if command -v wg &> /dev/null; then
        wg --version 2>/dev/null || echo "版本信息不可用"
    else
        echo "未安装"
    fi
}

# 获取BIRD版本
get_bird_version() {
    if command -v bird &> /dev/null; then
        bird --version 2>/dev/null || echo "版本信息不可用"
    else
        echo "未安装"
    fi
}

# 显示系统信息
show_system_info() {
    echo "操作系统: $(lsb_release -d 2>/dev/null | cut -f2 || uname -o)"
    echo "架构: $(uname -m)"
    echo "主机名: $(hostname)"
    echo "运行时间: $(uptime -p 2>/dev/null || uptime)"
}

# 检查更新
check_for_updates() {
    echo -e "${SECONDARY_COLOR}=== 检查更新 ===${NC}"
    echo
    
    log_info "正在检查更新..."
    
    # 检查网络连接
    if ! check_network_connectivity; then
        show_error "网络连接不可用，无法检查更新"
        return 1
    fi
    
    # 从GitHub API获取最新版本
    local latest_info=$(get_latest_version_info)
    
    if [[ -n "$latest_info" ]]; then
        parse_latest_version_info "$latest_info"
        display_update_info
    else
        show_error "无法获取更新信息"
        return 1
    fi
    
    # 更新检查时间
    update_check_time "$(date +%s)"
}

# 检查网络连接
check_network_connectivity() {
    if ping -c 1 8.8.8.8 &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 获取最新版本信息
get_latest_version_info() {
    if command -v curl &> /dev/null; then
        curl -s "$UPDATE_API_URL" 2>/dev/null
    elif command -v wget &> /dev/null; then
        wget -qO- "$UPDATE_API_URL" 2>/dev/null
    else
        log_error "需要curl或wget来检查更新"
        return 1
    fi
}

# 解析最新版本信息
parse_latest_version_info() {
    local version_info="$1"
    
    # 使用jq解析JSON（如果可用）
    if command -v jq &> /dev/null; then
        LATEST_VERSION=$(echo "$version_info" | jq -r '.tag_name' | sed 's/^v//')
        UPDATE_AVAILABLE=$(compare_versions "$CURRENT_VERSION" "$LATEST_VERSION")
    else
        # 简单的文本解析
        LATEST_VERSION=$(echo "$version_info" | grep -o '"tag_name":"[^"]*"' | cut -d'"' -f4 | sed 's/^v//')
        UPDATE_AVAILABLE=$(compare_versions "$CURRENT_VERSION" "$LATEST_VERSION")
    fi
    
    # 更新配置文件
    update_config_value "LATEST_VERSION" "$LATEST_VERSION"
    update_config_value "UPDATE_AVAILABLE" "$UPDATE_AVAILABLE"
}

# 比较版本号
compare_versions() {
    local current="$1"
    local latest="$2"
    
    if [[ "$current" == "$latest" ]]; then
        echo "false"
    else
        # 简单的版本比较（可以改进）
        if [[ "$latest" > "$current" ]]; then
            echo "true"
        else
            echo "false"
        fi
    fi
}

# 显示更新信息
display_update_info() {
    echo "更新检查结果:"
    echo "----------------------------------------"
    echo "当前版本: $CURRENT_VERSION"
    echo "最新版本: $LATEST_VERSION"
    
    if [[ "$UPDATE_AVAILABLE" == "true" ]]; then
        echo -e "状态: ${GREEN}有可用更新${NC}"
        echo
        echo "更新内容:"
        echo "----------------------------------------"
        show_release_notes "$LATEST_VERSION"
    else
        echo -e "状态: ${GREEN}已是最新版本${NC}"
    fi
    
    echo
    echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
}

# 显示发布说明
show_release_notes() {
    local version="$1"
    
    # 尝试获取发布说明
    local release_url="${UPDATE_API_URL%/latest}"
    local release_info=$(curl -s "$release_url/tags/v$version" 2>/dev/null)
    
    if command -v jq &> /dev/null && [[ -n "$release_info" ]]; then
        echo "$release_info" | jq -r '.body' | head -20
    else
        echo "发布说明不可用"
    fi
}

# 自动更新
auto_update() {
    echo -e "${SECONDARY_COLOR}=== 自动更新 ===${NC}"
    echo
    
    # 检查是否有可用更新
    if [[ "$UPDATE_AVAILABLE" != "true" ]]; then
        log_info "没有可用更新"
        return 0
    fi
    
    echo "发现新版本: $LATEST_VERSION"
    echo "当前版本: $CURRENT_VERSION"
    echo
    
    if ! show_confirm "确认更新到最新版本？"; then
        log_info "更新已取消"
        return 0
    fi
    
    # 执行更新
    perform_update
}

# 执行更新
perform_update() {
    log_info "开始执行更新..."
    
    # 1. 创建备份
    if [[ "$BACKUP_BEFORE_UPDATE" == "true" ]]; then
        create_update_backup
    fi
    
    # 2. 下载更新
    if download_update; then
        log_info "更新下载成功"
    else
        log_error "更新下载失败"
        return 1
    fi
    
    # 3. 验证更新
    if verify_update; then
        log_info "更新验证成功"
    else
        log_error "更新验证失败"
        return 1
    fi
    
    # 4. 安装更新
    if install_update; then
        log_info "更新安装成功"
        update_version_database
        send_update_notification
    else
        log_error "更新安装失败"
        rollback_update
        return 1
    fi
    
    log_info "更新完成"
}

# 创建更新备份
create_update_backup() {
    log_info "创建更新备份..."
    
    local backup_name="backup_${CURRENT_VERSION}_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    mkdir -p "$backup_path"
    
    # 备份重要文件
    cp -r modules "$backup_path/"
    cp -r config "$backup_path/"
    cp -r scripts "$backup_path/"
    cp *.sh "$backup_path/" 2>/dev/null || true
    cp *.md "$backup_path/" 2>/dev/null || true
    
    # 记录备份信息
    echo "$backup_name|$(date '+%Y-%m-%d %H:%M:%S')|$backup_path|backup" >> "$VERSION_DB"
    
    log_info "备份已创建: $backup_path"
}

# 下载更新
download_update() {
    log_info "下载更新..."
    
    local download_dir="/tmp/ipv6-wireguard-manager-update"
    local download_url="${UPDATE_REPOSITORY}/archive/refs/tags/v${LATEST_VERSION}.tar.gz"
    
    mkdir -p "$download_dir"
    cd "$download_dir"
    
    if command -v curl &> /dev/null; then
        curl -L -o "update.tar.gz" "$download_url"
    elif command -v wget &> /dev/null; then
        wget -O "update.tar.gz" "$download_url"
    else
        log_error "需要curl或wget来下载更新"
        return 1
    fi
    
    if [[ -f "update.tar.gz" ]]; then
        tar -xzf "update.tar.gz"
        log_info "更新下载成功"
        return 0
    else
        log_error "更新下载失败"
        return 1
    fi
}

# 验证更新
verify_update() {
    log_info "验证更新..."
    
    # 检查文件完整性
    if [[ "$CHECKSUM_VERIFICATION" == "true" ]]; then
        verify_checksums
    fi
    
    # 检查签名
    if [[ "$VERIFY_SIGNATURES" == "true" ]]; then
        verify_signatures
    fi
    
    return 0
}

# 验证校验和
verify_checksums() {
    log_info "验证文件校验和..."
    
    local checksum_file="CHECKSUMS"
    if [[ -f "$checksum_file" ]]; then
        if command -v sha256sum &> /dev/null; then
            sha256sum -c "$checksum_file"
        elif command -v shasum &> /dev/null; then
            shasum -c "$checksum_file"
        fi
    fi
}

# 验证签名
verify_signatures() {
    log_info "验证文件签名..."
    
    local signature_file="SIGNATURES"
    if [[ -f "$signature_file" ]] && command -v gpg &> /dev/null; then
        gpg --verify "$signature_file"
    fi
}

# 安装更新
install_update() {
    log_info "安装更新..."
    
    local update_dir="/tmp/ipv6-wireguard-manager-update/ipv6-wireguard-manager-${LATEST_VERSION}"
    
    if [[ -d "$update_dir" ]]; then
        # 停止服务
        stop_services
        
        # 备份当前配置
        backup_current_config
        
        # 安装新文件
        cp -r "$update_dir"/* "$(pwd)/"
        
        # 恢复配置
        restore_config
        
        # 启动服务
        start_services
        
        # 清理临时文件
        rm -rf "/tmp/ipv6-wireguard-manager-update"
        
        log_info "更新安装完成"
        return 0
    else
        log_error "更新目录不存在"
        return 1
    fi
}

# 停止服务
stop_services() {
    log_info "停止相关服务..."
    
    systemctl stop bird 2>/dev/null || true
    systemctl stop bird6 2>/dev/null || true
    systemctl stop wg-quick@wg0 2>/dev/null || true
}

# 启动服务
start_services() {
    log_info "启动相关服务..."
    
    systemctl start bird 2>/dev/null || true
    systemctl start bird6 2>/dev/null || true
    systemctl start wg-quick@wg0 2>/dev/null || true
}

# 备份当前配置
backup_current_config() {
    log_info "备份当前配置..."
    
    local config_backup="$BACKUP_DIR/config_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$config_backup"
    
    cp -r config "$config_backup/"
    cp *.conf "$config_backup/" 2>/dev/null || true
}

# 恢复配置
restore_config() {
    log_info "恢复配置..."
    
    # 这里可以添加配置恢复逻辑
    # 例如：合并新旧配置，保留用户自定义设置等
}

# 更新版本数据库
update_version_database() {
    log_info "更新版本数据库..."
    
    local install_time=$(date '+%Y-%m-%d %H:%M:%S')
    local install_path=$(pwd)
    local backup_path="$BACKUP_DIR/backup_$LATEST_VERSION"
    
    echo "$LATEST_VERSION|$install_time|$install_path|$backup_path|installed" >> "$VERSION_DB"
    
    # 更新当前版本
    update_config_value "CURRENT_VERSION" "$LATEST_VERSION"
    CURRENT_VERSION="$LATEST_VERSION"
}

# 发送更新通知
send_update_notification() {
    if [[ "$NOTIFICATION_ENABLED" == "true" ]]; then
        log_info "发送更新通知..."
        
        local message="IPv6 WireGuard Manager 已更新到版本 $LATEST_VERSION"
        
        # 邮件通知
        if [[ -n "$NOTIFICATION_EMAIL" ]]; then
            send_email_notification "$message"
        fi
        
        # Webhook通知
        if [[ -n "$NOTIFICATION_WEBHOOK" ]]; then
            send_webhook_notification "$message"
        fi
    fi
}

# 发送邮件通知
send_email_notification() {
    local message="$1"
    
    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "IPv6 WireGuard Manager 更新通知" "$NOTIFICATION_EMAIL"
    fi
}

# 发送Webhook通知
send_webhook_notification() {
    local message="$1"
    
    local payload="{\"text\":\"$message\",\"timestamp\":\"$(date -Iseconds)\"}"
    
    if command -v curl &> /dev/null; then
        curl -X POST -H "Content-Type: application/json" -d "$payload" "$NOTIFICATION_WEBHOOK"
    fi
}

# 回滚更新
rollback_update() {
    log_info "回滚更新..."
    
    # 从备份恢复
    local latest_backup=$(get_latest_backup)
    if [[ -n "$latest_backup" ]]; then
        restore_from_backup "$latest_backup"
    else
        log_error "没有可用的备份"
    fi
}

# 获取最新备份
get_latest_backup() {
    grep "|backup$" "$VERSION_DB" | tail -1 | cut -d'|' -f3
}

# 从备份恢复
restore_from_backup() {
    local backup_path="$1"
    
    if [[ -d "$backup_path" ]]; then
        cp -r "$backup_path"/* "$(pwd)/"
        log_info "已从备份恢复: $backup_path"
    else
        log_error "备份路径不存在: $backup_path"
    fi
}

# 查看更新日志
view_update_log() {
    echo -e "${SECONDARY_COLOR}=== 查看更新日志 ===${NC}"
    echo
    
    if [[ -f "$UPDATE_LOG_FILE" ]]; then
        echo "更新日志:"
        echo "----------------------------------------"
        tail -50 "$UPDATE_LOG_FILE"
    else
        echo "更新日志文件不存在"
    fi
    
    echo
    echo "版本历史:"
    echo "----------------------------------------"
    if [[ -f "$VERSION_DB" ]]; then
        printf "%-15s %-20s %-15s %-20s\n" "版本" "安装时间" "状态" "备份路径"
        printf "%-15s %-20s %-15s %-20s\n" "---------------" "--------------------" "---------------" "--------------------"
        
        while IFS='|' read -r version time path backup status; do
            printf "%-15s %-20s %-15s %-20s\n" "$version" "$time" "$status" "$backup"
        done < "$VERSION_DB"
    else
        echo "版本数据库不存在"
    fi
}

# 回滚版本
rollback_version() {
    echo -e "${SECONDARY_COLOR}=== 回滚版本 ===${NC}"
    echo
    
    if [[ ! -f "$VERSION_DB" ]]; then
        show_error "版本数据库不存在"
        return 1
    fi
    
    # 显示可用版本
    echo "可用版本:"
    echo "----------------------------------------"
    local versions=()
    local i=1
    
    while IFS='|' read -r version time path backup status; do
        if [[ "$status" == "installed" ]]; then
            echo "$i. $version ($time)"
            versions+=("$version|$backup")
            ((i++))
        fi
    done < "$VERSION_DB"
    
    if [[ ${#versions[@]} -le 1 ]]; then
        show_error "没有可回滚的版本"
        return 1
    fi
    
    echo
    local choice=$(show_input "选择要回滚到的版本序号" "")
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -lt ${#versions[@]} ]]; then
        local selected_version="${versions[$((choice-1))]}"
        local version_name=$(echo "$selected_version" | cut -d'|' -f1)
        local backup_path=$(echo "$selected_version" | cut -d'|' -f2)
        
        if show_confirm "确认回滚到版本 $version_name？"; then
            perform_rollback "$version_name" "$backup_path"
        else
            log_info "回滚已取消"
        fi
    else
        show_error "无效的版本选择"
    fi
}

# 执行回滚
perform_rollback() {
    local target_version="$1"
    local backup_path="$2"
    
    log_info "开始回滚到版本: $target_version"
    
    # 创建当前版本备份
    create_update_backup
    
    # 停止服务
    stop_services
    
    # 从备份恢复
    if [[ -d "$backup_path" ]]; then
        cp -r "$backup_path"/* "$(pwd)/"
        
        # 更新版本数据库
        local rollback_time=$(date '+%Y-%m-%d %H:%M:%S')
        echo "$target_version|$rollback_time|$(pwd)|$backup_path|installed" >> "$VERSION_DB"
        
        # 更新当前版本
        update_config_value "CURRENT_VERSION" "$target_version"
        CURRENT_VERSION="$target_version"
        
        # 启动服务
        start_services
        
        log_info "回滚完成: $target_version"
    else
        log_error "备份路径不存在: $backup_path"
    fi
}

# 更新设置
update_settings() {
    echo -e "${SECONDARY_COLOR}=== 更新设置 ===${NC}"
    echo
    
    local setting_type=$(show_selection "设置类型" "自动更新" "通知设置" "安全设置" "备份设置")
    
    case "$setting_type" in
        "自动更新")
            configure_auto_update
            ;;
        "通知设置")
            configure_notifications
            ;;
        "安全设置")
            configure_security_settings
            ;;
        "备份设置")
            configure_backup_settings
            ;;
    esac
}

# 配置自动更新
configure_auto_update() {
    echo "自动更新设置:"
    echo "----------------------------------------"
    
    local auto_enabled=$(show_selection "启用自动更新" "是" "否")
    local check_interval=$(show_input "检查间隔(小时)" "24")
    
    update_config_value "AUTO_UPDATE_ENABLED" "$([ "$auto_enabled" == "是" ] && echo "true" || echo "false")"
    update_config_value "UPDATE_CHECK_INTERVAL" "$((check_interval * 3600))"
    
    log_info "自动更新设置已更新"
}

# 配置通知设置
configure_notifications() {
    echo "通知设置:"
    echo "----------------------------------------"
    
    local notify_enabled=$(show_selection "启用通知" "是" "否")
    local email=$(show_input "通知邮箱" "$NOTIFICATION_EMAIL")
    local webhook=$(show_input "Webhook URL" "$NOTIFICATION_WEBHOOK")
    
    update_config_value "NOTIFICATION_ENABLED" "$([ "$notify_enabled" == "是" ] && echo "true" || echo "false")"
    update_config_value "NOTIFICATION_EMAIL" "$email"
    update_config_value "NOTIFICATION_WEBHOOK" "$webhook"
    
    log_info "通知设置已更新"
}

# 配置安全设置
configure_security_settings() {
    echo "安全设置:"
    echo "----------------------------------------"
    
    local verify_sig=$(show_selection "验证签名" "是" "否")
    local verify_checksum=$(show_selection "验证校验和" "是" "否")
    
    update_config_value "VERIFY_SIGNATURES" "$([ "$verify_sig" == "是" ] && echo "true" || echo "false")"
    update_config_value "CHECKSUM_VERIFICATION" "$([ "$verify_checksum" == "是" ] && echo "true" || echo "false")"
    
    log_info "安全设置已更新"
}

# 配置备份设置
configure_backup_settings() {
    echo "备份设置:"
    echo "----------------------------------------"
    
    local backup_enabled=$(show_selection "启用备份" "是" "否")
    local backup_before=$(show_selection "更新前备份" "是" "否")
    local retention=$(show_input "备份保留天数" "30")
    
    update_config_value "BACKUP_ENABLED" "$([ "$backup_enabled" == "是" ] && echo "true" || echo "false")"
    update_config_value "BACKUP_BEFORE_UPDATE" "$([ "$backup_before" == "是" ] && echo "true" || echo "false")"
    update_config_value "BACKUP_RETENTION_DAYS" "$retention"
    
    log_info "备份设置已更新"
}

# 更新历史
update_history() {
    echo -e "${SECONDARY_COLOR}=== 更新历史 ===${NC}"
    echo
    
    if [[ -f "$VERSION_DB" ]]; then
        echo "版本历史记录:"
        echo "----------------------------------------"
        printf "%-15s %-20s %-15s %-30s\n" "版本" "时间" "状态" "路径"
        printf "%-15s %-20s %-15s %-30s\n" "---------------" "--------------------" "---------------" "------------------------------"
        
        while IFS='|' read -r version time path backup status; do
            printf "%-15s %-20s %-15s %-30s\n" "$version" "$time" "$status" "$path"
        done < "$VERSION_DB"
    else
        echo "没有更新历史记录"
    fi
}

# 清理更新文件
cleanup_update_files() {
    echo -e "${SECONDARY_COLOR}=== 清理更新文件 ===${NC}"
    echo
    
    local cleanup_type=$(show_selection "清理类型" "清理临时文件" "清理旧备份" "清理日志文件" "全部清理")
    
    case "$cleanup_type" in
        "清理临时文件")
            cleanup_temp_files
            ;;
        "清理旧备份")
            cleanup_old_backups
            ;;
        "清理日志文件")
            cleanup_log_files
            ;;
        "全部清理")
            cleanup_temp_files
            cleanup_old_backups
            cleanup_log_files
            ;;
    esac
}

# 清理临时文件
cleanup_temp_files() {
    log_info "清理临时文件..."
    
    rm -rf /tmp/ipv6-wireguard-manager-update*
    rm -rf /tmp/update-*
    
    log_info "临时文件清理完成"
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理旧备份..."
    
    local retention_days=${BACKUP_RETENTION_DAYS:-30}
    find "$BACKUP_DIR" -type d -name "backup_*" -mtime +$retention_days -exec rm -rf {} \;
    
    log_info "旧备份清理完成"
}

# 清理日志文件
cleanup_log_files() {
    log_info "清理日志文件..."
    
    if [[ -f "$UPDATE_LOG_FILE" ]]; then
        > "$UPDATE_LOG_FILE"
    fi
    
    log_info "日志文件清理完成"
}

# 辅助函数

# 更新配置值
update_config_value() {
    local key="$1"
    local value="$2"
    
    if grep -q "^${key}=" "$UPDATE_CONFIG_FILE"; then
        sed -i "s/^${key}=.*/${key}=${value}/" "$UPDATE_CONFIG_FILE"
    else
        echo "${key}=${value}" >> "$UPDATE_CONFIG_FILE"
    fi
}

# 更新检查时间
update_check_time() {
    local timestamp="$1"
    update_config_value "UPDATE_CHECK_TIME" "$timestamp"
}

# 记录更新日志
log_update() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$UPDATE_LOG_FILE"
}

# 导出函数
export -f init_update_management create_update_config load_update_config
export -f init_version_database update_check_menu check_current_version
export -f check_for_updates auto_update view_update_log rollback_version
export -f update_settings update_history cleanup_update_files
export -f perform_update create_update_backup download_update verify_update
export -f install_update perform_rollback configure_auto_update
export -f configure_notifications configure_security_settings configure_backup_settings
export -f cleanup_temp_files cleanup_old_backups cleanup_log_files
export -f update_config_value log_update
