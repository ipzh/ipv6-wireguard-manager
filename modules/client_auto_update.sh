#!/bin/bash

# 客户端自动更新模块
# 支持自动检查更新、下载更新、安装更新

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 更新配置
UPDATE_SERVER_URL="${UPDATE_SERVER_URL:-http://your-server.com:8000}"
UPDATE_CHECK_INTERVAL="${UPDATE_CHECK_INTERVAL:-3600}"  # 1小时检查一次
AUTO_UPDATE_ENABLED="${AUTO_UPDATE_ENABLED:-true}"
UPDATE_LOG_FILE="${UPDATE_LOG_FILE:-$HOME/.local/log/wireguard/update.log}"

# 日志函数
log_update() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[UPDATE-ERROR]${NC} $message" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[UPDATE-WARN]${NC} $message"
            ;;
        "INFO")
            echo -e "${GREEN}[UPDATE-INFO]${NC} $message"
            ;;
        "DEBUG")
            echo -e "${BLUE}[UPDATE-DEBUG]${NC} $message"
            ;;
    esac
    
    # 写入日志文件
    echo "[$timestamp] [$level] $message" >> "$UPDATE_LOG_FILE"
}

# 检查更新
check_for_updates() {
    local client_name="$1"
    local current_version="$2"
    
    log_update "INFO" "检查客户端更新: $client_name"
    
    # 创建临时目录
    local temp_dir="/tmp/wireguard-update-$$"
    mkdir -p "$temp_dir"
    
    # 下载版本信息
    local version_url="$UPDATE_SERVER_URL/version.json"
    local version_file="$temp_dir/version.json"
    
    if ! curl -s -L -o "$version_file" "$version_url"; then
        log_update "WARN" "无法获取版本信息: $version_url"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # 解析版本信息
    local latest_version=$(grep -o '"version":"[^"]*"' "$version_file" | cut -d'"' -f4)
    local download_url=$(grep -o '"download_url":"[^"]*"' "$version_file" | cut -d'"' -f4)
    local changelog=$(grep -o '"changelog":"[^"]*"' "$version_file" | cut -d'"' -f4)
    
    if [[ -z "$latest_version" || -z "$download_url" ]]; then
        log_update "ERROR" "版本信息格式错误"
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_update "INFO" "当前版本: $current_version"
    log_update "INFO" "最新版本: $latest_version"
    
    # 比较版本
    if [[ "$current_version" != "$latest_version" ]]; then
        log_update "INFO" "发现新版本: $latest_version"
        echo "$latest_version|$download_url|$changelog"
        return 0
    else
        log_update "INFO" "客户端已是最新版本"
        rm -rf "$temp_dir"
        return 1
    fi
}

# 下载更新
download_update() {
    local download_url="$1"
    local output_dir="$2"
    
    log_update "INFO" "下载更新: $download_url"
    
    # 创建输出目录
    mkdir -p "$output_dir"
    
    # 下载更新包
    local update_file="$output_dir/update.tar.gz"
    if ! curl -s -L -o "$update_file" "$download_url"; then
        log_update "ERROR" "下载更新失败: $download_url"
        return 1
    fi
    
    # 验证下载文件
    if [[ ! -f "$update_file" || ! -s "$update_file" ]]; then
        log_update "ERROR" "更新文件下载失败或为空"
        return 1
    fi
    
    log_update "INFO" "更新下载完成: $update_file"
    echo "$update_file"
}

# 安装更新
install_update() {
    local update_file="$1"
    local client_name="$2"
    local backup_dir="$3"
    
    log_update "INFO" "安装更新: $update_file"
    
    # 创建备份目录
    mkdir -p "$backup_dir"
    
    # 备份当前配置
    local config_file="$HOME/.config/wireguard/$client_name.conf"
    if [[ -f "$config_file" ]]; then
        cp "$config_file" "$backup_dir/$client_name.conf.backup.$(date +%Y%m%d_%H%M%S)"
        log_update "INFO" "配置已备份: $backup_dir"
    fi
    
    # 停止当前客户端
    if command -v wg-quick >/dev/null 2>&1; then
        sudo wg-quick down "$client_name" 2>/dev/null || true
        log_update "INFO" "客户端已停止: $client_name"
    fi
    
    # 解压更新包
    local extract_dir="/tmp/wireguard-update-extract-$$"
    mkdir -p "$extract_dir"
    
    if ! tar -xzf "$update_file" -C "$extract_dir"; then
        log_update "ERROR" "解压更新包失败"
        rm -rf "$extract_dir"
        return 1
    fi
    
    # 安装新版本
    local install_script="$extract_dir/install-linux.sh"
    if [[ -f "$install_script" ]]; then
        chmod +x "$install_script"
        
        # 静默安装（跳过交互式提示）
        if ! echo "y" | "$install_script" --silent --no-start; then
            log_update "ERROR" "安装更新失败"
            rm -rf "$extract_dir"
            return 1
        fi
        
        log_update "INFO" "更新安装完成"
    else
        log_update "ERROR" "未找到安装脚本"
        rm -rf "$extract_dir"
        return 1
    fi
    
    # 清理临时文件
    rm -rf "$extract_dir"
    rm -f "$update_file"
    
    # 启动客户端
    if command -v wg-quick >/dev/null 2>&1; then
        sudo wg-quick up "$client_name"
        log_update "INFO" "客户端已启动: $client_name"
    fi
    
    log_update "INFO" "更新完成"
}

# 自动更新检查
auto_update_check() {
    local client_name="$1"
    local current_version="$2"
    
    if [[ "$AUTO_UPDATE_ENABLED" != "true" ]]; then
        log_update "DEBUG" "自动更新已禁用"
        return 0
    fi
    
    # 检查更新间隔
    local last_check_file="$HOME/.local/log/wireguard/last_update_check"
    local current_time=$(date +%s)
    local last_check_time=0
    
    if [[ -f "$last_check_file" ]]; then
        last_check_time=$(cat "$last_check_file")
    fi
    
    local time_diff=$((current_time - last_check_time))
    if [[ $time_diff -lt $UPDATE_CHECK_INTERVAL ]]; then
        log_update "DEBUG" "更新检查间隔未到，跳过检查"
        return 0
    fi
    
    # 更新检查时间
    echo "$current_time" > "$last_check_file"
    
    # 检查更新
    local update_info=$(check_for_updates "$client_name" "$current_version")
    if [[ $? -eq 0 ]]; then
        local latest_version=$(echo "$update_info" | cut -d'|' -f1)
        local download_url=$(echo "$update_info" | cut -d'|' -f2)
        local changelog=$(echo "$update_info" | cut -d'|' -f3)
        
        log_update "INFO" "发现新版本: $latest_version"
        log_update "INFO" "更新说明: $changelog"
        
        # 询问是否更新
        echo
        echo -e "${YELLOW}发现新版本: $latest_version${NC}"
        echo -e "${YELLOW}更新说明: $changelog${NC}"
        echo
        read -p "是否立即更新? (y/N): " update_choice
        
        if [[ "${update_choice,,}" == "y" ]]; then
            # 下载更新
            local update_dir="/tmp/wireguard-update-$$"
            local update_file=$(download_update "$download_url" "$update_dir")
            
            if [[ $? -eq 0 ]]; then
                # 安装更新
                local backup_dir="$HOME/.local/backup/wireguard"
                install_update "$update_file" "$client_name" "$backup_dir"
            else
                log_update "ERROR" "更新失败"
            fi
            
            # 清理临时目录
            rm -rf "$update_dir"
        else
            log_update "INFO" "用户选择跳过更新"
        fi
    fi
}

# 手动更新
manual_update() {
    local client_name="$1"
    local current_version="$2"
    
    log_update "INFO" "手动检查更新: $client_name"
    
    # 检查更新
    local update_info=$(check_for_updates "$client_name" "$current_version")
    if [[ $? -eq 0 ]]; then
        local latest_version=$(echo "$update_info" | cut -d'|' -f1)
        local download_url=$(echo "$update_info" | cut -d'|' -f2)
        local changelog=$(echo "$update_info" | cut -d'|' -f3)
        
        echo
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}                        发现新版本                          ${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${YELLOW}当前版本:${NC} $current_version"
        echo -e "${YELLOW}最新版本:${NC} $latest_version"
        echo -e "${YELLOW}更新说明:${NC} $changelog"
        echo
        
        read -p "是否立即更新? (y/N): " update_choice
        
        if [[ "${update_choice,,}" == "y" ]]; then
            # 下载更新
            local update_dir="/tmp/wireguard-update-$$"
            local update_file=$(download_update "$download_url" "$update_dir")
            
            if [[ $? -eq 0 ]]; then
                # 安装更新
                local backup_dir="$HOME/.local/backup/wireguard"
                install_update "$update_file" "$client_name" "$backup_dir"
                
                if [[ $? -eq 0 ]]; then
                    echo
                    echo -e "${GREEN}更新完成！${NC}"
                    echo -e "${GREEN}客户端已重启并连接到服务器${NC}"
                else
                    echo
                    echo -e "${RED}更新失败！${NC}"
                    echo -e "${YELLOW}请检查日志文件: $UPDATE_LOG_FILE${NC}"
                fi
            else
                echo
                echo -e "${RED}下载更新失败！${NC}"
            fi
            
            # 清理临时目录
            rm -rf "$update_dir"
        else
            echo -e "${YELLOW}更新已取消${NC}"
        fi
    else
        echo
        echo -e "${GREEN}客户端已是最新版本${NC}"
    fi
}

# 配置自动更新
configure_auto_update() {
    local client_name="$1"
    
    echo
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                        自动更新配置                          ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    # 当前配置
    echo -e "${YELLOW}当前配置:${NC}"
    echo -e "  自动更新: $([ "$AUTO_UPDATE_ENABLED" = "true" ] && echo "启用" || echo "禁用")"
    echo -e "  检查间隔: $UPDATE_CHECK_INTERVAL 秒 ($((UPDATE_CHECK_INTERVAL/3600)) 小时)"
    echo -e "  更新服务器: $UPDATE_SERVER_URL"
    echo -e "  日志文件: $UPDATE_LOG_FILE"
    echo
    
    # 配置选项
    echo -e "${YELLOW}配置选项:${NC}"
    echo -e "  ${GREEN}1.${NC} 启用/禁用自动更新"
    echo -e "  ${GREEN}2.${NC} 设置检查间隔"
    echo -e "  ${GREEN}3.${NC} 设置更新服务器"
    echo -e "  ${GREEN}4.${NC} 查看更新日志"
    echo -e "  ${GREEN}5.${NC} 手动检查更新"
    echo -e "  ${GREEN}0.${NC} 返回"
    echo
    
    read -p "请选择 (0-5): " choice
    
    case "$choice" in
        "1")
            if [[ "$AUTO_UPDATE_ENABLED" = "true" ]]; then
                AUTO_UPDATE_ENABLED="false"
                echo -e "${YELLOW}自动更新已禁用${NC}"
            else
                AUTO_UPDATE_ENABLED="true"
                echo -e "${GREEN}自动更新已启用${NC}"
            fi
            ;;
        "2")
            read -p "请输入检查间隔（秒，默认3600）: " interval
            UPDATE_CHECK_INTERVAL="${interval:-3600}"
            echo -e "${GREEN}检查间隔已设置为: $UPDATE_CHECK_INTERVAL 秒${NC}"
            ;;
        "3")
            read -p "请输入更新服务器URL: " server_url
            UPDATE_SERVER_URL="${server_url:-$UPDATE_SERVER_URL}"
            echo -e "${GREEN}更新服务器已设置为: $UPDATE_SERVER_URL${NC}"
            ;;
        "4")
            if [[ -f "$UPDATE_LOG_FILE" ]]; then
                echo -e "${YELLOW}更新日志:${NC}"
                tail -20 "$UPDATE_LOG_FILE"
            else
                echo -e "${YELLOW}暂无更新日志${NC}"
            fi
            ;;
        "5")
            local current_version="1.11"  # 从配置文件读取
            manual_update "$client_name" "$current_version"
            ;;
        "0")
            return 0
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    # 保存配置
    local config_file="$HOME/.config/wireguard/update.conf"
    cat > "$config_file" << EOF
# WireGuard 客户端自动更新配置
AUTO_UPDATE_ENABLED=$AUTO_UPDATE_ENABLED
UPDATE_CHECK_INTERVAL=$UPDATE_CHECK_INTERVAL
UPDATE_SERVER_URL=$UPDATE_SERVER_URL
UPDATE_LOG_FILE=$UPDATE_LOG_FILE
EOF
    
    echo -e "${GREEN}配置已保存: $config_file${NC}"
}

# 主函数
main() {
    local action="$1"
    local client_name="$2"
    local current_version="$3"
    
    case "$action" in
        "check")
            check_for_updates "$client_name" "${current_version:-1.11}"
            ;;
        "update")
            manual_update "$client_name" "${current_version:-1.11}"
            ;;
        "auto")
            auto_update_check "$client_name" "${current_version:-1.11}"
            ;;
        "config")
            configure_auto_update "$client_name"
            ;;
        *)
            echo "用法: $0 {check|update|auto|config} <client_name> [version]"
            echo
            echo "命令:"
            echo "  check  - 检查更新"
            echo "  update - 手动更新"
            echo "  auto   - 自动更新检查"
            echo "  config - 配置自动更新"
            exit 1
            ;;
    esac
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
