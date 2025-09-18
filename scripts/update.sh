#!/bin/bash

# IPv6 WireGuard Manager 更新脚本
# 版本: 1.13

set -euo pipefail

# 加载公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/../modules/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../modules/common_functions.sh"
fi

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
INSTALL_DIR="/opt/ipv6-wireguard-manager"
UPDATE_URL="https://github.com/ipv6-wireguard-manager/ipv6-wireguard-manager"
BACKUP_DIR="/var/backups/ipv6-wireguard"
TEMP_DIR="/tmp/ipv6-wireguard-update"

# 日志函数
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "DEBUG")
            echo -e "${BLUE}[DEBUG]${NC} $message"
            ;;
    esac
    
    # 写入日志文件
    echo "[$timestamp] [$level] $message" >> /var/log/ipv6-wireguard-update.log
}

# 错误处理函数
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root"
    fi
}

# 检查当前版本
get_current_version() {
    if [[ -f "$INSTALL_DIR/config/manager.conf" ]]; then
        grep "^version = " "$INSTALL_DIR/config/manager.conf" | cut -d'=' -f2 | tr -d ' '
    else
        echo "unknown"
    fi
}

# 检查最新版本
get_latest_version() {
    local latest_version=""
    
    # 尝试从GitHub API获取最新版本
    if command -v curl >/dev/null 2>&1; then
        latest_version=$(curl -s "https://api.github.com/repos/ipv6-wireguard-manager/ipv6-wireguard-manager/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
    fi
    
    if [[ -z "$latest_version" ]]; then
        # 备用方法：从Git标签获取
        if command -v git >/dev/null 2>&1; then
            latest_version=$(git ls-remote --tags "$UPDATE_URL.git" | grep -v '\^{}' | tail -1 | cut -d'/' -f3)
        fi
    fi
    
    echo "${latest_version:-unknown}"
}

# 创建备份
create_backup() {
    local backup_name="backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log "INFO" "Creating backup: $backup_name"
    
    mkdir -p "$backup_path"
    
    # 备份配置文件
    if [[ -d "$INSTALL_DIR/config" ]]; then
        cp -r "$INSTALL_DIR/config" "$backup_path/"
    fi
    
    # 备份WireGuard配置
    if [[ -d "/etc/wireguard" ]]; then
        cp -r "/etc/wireguard" "$backup_path/"
    fi
    
    # 备份BIRD配置
    if [[ -f "/etc/bird/bird.conf" ]]; then
        cp "/etc/bird/bird.conf" "$backup_path/"
    fi
    
    # 创建备份信息文件
    cat > "$backup_path/backup_info.txt" << EOF
Backup Information
==================
Backup Name: $backup_name
Backup Date: $(date)
Current Version: $(get_current_version)
Backup Type: Pre-update backup
EOF
    
    log "INFO" "Backup created: $backup_path"
    echo "$backup_path"
}

# 下载更新
download_update() {
    local version="$1"
    local download_url=""
    
    log "INFO" "Downloading update version: $version"
    
    # 创建临时目录
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # 确定下载URL
    if [[ "$version" == "latest" ]]; then
        download_url="$UPDATE_URL/archive/main.zip"
    else
        download_url="$UPDATE_URL/archive/v$version.zip"
    fi
    
    # 下载更新包
    if command -v wget >/dev/null 2>&1; then
        wget -O update.zip "$download_url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o update.zip "$download_url"
    else
        error_exit "Neither wget nor curl is available"
    fi
    
    # 解压更新包
    if command -v unzip >/dev/null 2>&1; then
        unzip -q update.zip
    else
        error_exit "unzip is not available"
    fi
    
    # 查找解压后的目录
    local extracted_dir=$(find . -maxdepth 1 -type d -name "ipv6-wireguard-manager*" | head -1)
    
    if [[ -z "$extracted_dir" ]]; then
        error_exit "Failed to extract update package"
    fi
    
    echo "$TEMP_DIR/$extracted_dir"
}

# 停止服务
stop_services() {
    log "INFO" "Stopping services..."
    
    # 停止WireGuard服务
    if systemctl is-active wg-quick@wg0 >/dev/null 2>&1; then
        systemctl stop wg-quick@wg0
        log "INFO" "Stopped WireGuard service"
    fi
    
    # 停止BIRD服务
    if systemctl is-active bird >/dev/null 2>&1; then
        systemctl stop bird
        log "INFO" "Stopped BIRD service"
    fi
}

# 应用更新
apply_update() {
    local update_dir="$1"
    
    log "INFO" "Applying update..."
    
    # 备份当前安装
    local backup_path=$(create_backup)
    
    # 停止服务
    stop_services
    
    # 更新程序文件
    if [[ -d "$update_dir" ]]; then
        # 更新主脚本
        if [[ -f "$update_dir/ipv6-wireguard-manager.sh" ]]; then
            cp "$update_dir/ipv6-wireguard-manager.sh" "$INSTALL_DIR/"
            chmod +x "$INSTALL_DIR/ipv6-wireguard-manager.sh"
        fi
        
        # 更新模块文件
        if [[ -d "$update_dir/modules" ]]; then
            cp -r "$update_dir/modules"/* "$INSTALL_DIR/modules/"
            chmod +x "$INSTALL_DIR/modules"/*.sh
        fi
        
        # 更新脚本文件
        if [[ -d "$update_dir/scripts" ]]; then
            cp -r "$update_dir/scripts"/* "$INSTALL_DIR/scripts/"
            chmod +x "$INSTALL_DIR/scripts"/*.sh
        fi
        
        # 更新配置文件（保留用户配置）
        if [[ -d "$update_dir/config" ]]; then
            # 只更新模板文件，不覆盖用户配置
            for file in "$update_dir/config"/*.conf; do
                if [[ -f "$file" ]]; then
                    local filename=$(basename "$file")
                    if [[ "$filename" == "manager.conf" ]]; then
                        # 合并配置文件
                        merge_config_file "$file" "$INSTALL_DIR/config/$filename"
                    else
                        # 直接复制模板文件
                        cp "$file" "$INSTALL_DIR/config/"
                    fi
                fi
            done
        fi
    fi
    
    log "INFO" "Update applied successfully"
}

# 合并配置文件
merge_config_file() {
    local new_config="$1"
    local current_config="$2"
    
    if [[ ! -f "$current_config" ]]; then
        cp "$new_config" "$current_config"
        return
    fi
    
    # 创建临时文件
    local temp_config=$(mktemp)
    
    # 合并配置（保留用户的自定义设置）
    while IFS='=' read -r key value; do
        if [[ "$key" =~ ^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*$ ]]; then
            # 检查当前配置中是否有此键
            if grep -q "^$key[[:space:]]*=" "$current_config"; then
                # 保留当前配置的值
                grep "^$key[[:space:]]*=" "$current_config" >> "$temp_config"
            else
                # 使用新配置的值
                echo "$key = $value" >> "$temp_config"
            fi
        else
            # 保留注释和空行
            echo "$key=$value" >> "$temp_config"
        fi
    done < "$new_config"
    
    # 替换配置文件
    mv "$temp_config" "$current_config"
}

# 启动服务
start_services() {
    log "INFO" "Starting services..."
    
    # 启动WireGuard服务
    if systemctl is-enabled wg-quick@wg0 >/dev/null 2>&1; then
        systemctl start wg-quick@wg0
        log "INFO" "Started WireGuard service"
    fi
    
    # 启动BIRD服务
    if systemctl is-enabled bird >/dev/null 2>&1; then
        systemctl start bird
        log "INFO" "Started BIRD service"
    fi
}

# 清理临时文件
cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log "INFO" "Cleaned up temporary files"
    fi
}

# 验证更新
verify_update() {
    local expected_version="$1"
    local current_version=$(get_current_version)
    
    if [[ "$current_version" == "$expected_version" ]]; then
        log "INFO" "Update verification successful"
        return 0
    else
        log "ERROR" "Update verification failed: expected $expected_version, got $current_version"
        return 1
    fi
}

# 显示更新信息
show_update_info() {
    local current_version="$1"
    local latest_version="$2"
    
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                IPv6 WireGuard Manager                      ║${NC}"
    echo -e "${BLUE}║                    更新程序 v1.11                         ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}版本信息:${NC}"
    echo -e "  当前版本: $current_version"
    echo -e "  最新版本: $latest_version"
    echo
    
    if [[ "$current_version" == "$latest_version" ]]; then
        echo -e "${GREEN}✓ 您已经运行最新版本!${NC}"
        return 1
    else
        echo -e "${YELLOW}发现新版本，是否立即更新?${NC}"
        return 0
    fi
}

# 主更新流程
main() {
    # 检查root权限
    check_root
    
    # 获取版本信息
    local current_version=$(get_current_version)
    local latest_version=$(get_latest_version)
    
    # 显示更新信息
    if ! show_update_info "$current_version" "$latest_version"; then
        exit 0
    fi
    
    # 确认更新
    read -p "确认开始更新? (y/N): " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        echo "更新已取消"
        exit 0
    fi
    
    # 开始更新
    log "INFO" "Starting update from $current_version to $latest_version"
    
    # 下载更新
    local update_dir=$(download_update "$latest_version")
    
    # 应用更新
    apply_update "$update_dir"
    
    # 启动服务
    start_services
    
    # 验证更新
    if verify_update "$latest_version"; then
        log "INFO" "Update completed successfully"
        echo -e "${GREEN}✓ 更新完成!${NC}"
        echo -e "  新版本: $latest_version"
        echo -e "  备份位置: $BACKUP_DIR"
    else
        log "ERROR" "Update verification failed"
        echo -e "${RED}✗ 更新验证失败${NC}"
        echo -e "  请检查日志文件: /var/log/ipv6-wireguard-update.log"
        exit 1
    fi
    
    # 清理临时文件
    cleanup
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
