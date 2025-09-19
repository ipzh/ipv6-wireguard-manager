#!/bin/bash

# IPv6 WireGuard Manager 卸载脚本
# 版本: 1.13

set -euo pipefail

# 加载公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/modules/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/modules/common_functions.sh"
fi

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 获取脚本目录
if [[ -L "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# 动态检测安装路径
detect_install_paths() {
    # 检测安装目录
    if [[ -d "/opt/ipv6-wireguard-manager" ]]; then
        INSTALL_DIR="/opt/ipv6-wireguard-manager"
    elif [[ -d "$SCRIPT_DIR" && -f "$SCRIPT_DIR/ipv6-wireguard-manager.sh" ]]; then
        INSTALL_DIR="$SCRIPT_DIR"
    else
        INSTALL_DIR="/opt/ipv6-wireguard-manager"
    fi
    
    # 检测配置目录
    if [[ -d "/etc/ipv6-wireguard" ]]; then
        CONFIG_DIR="/etc/ipv6-wireguard"
    else
        CONFIG_DIR="/etc/ipv6-wireguard"
    fi
    
    # 检测日志目录
    if [[ -d "/var/log/ipv6-wireguard" ]]; then
        LOG_DIR="/var/log/ipv6-wireguard"
    else
        LOG_DIR="/var/log/ipv6-wireguard"
    fi
    
    # 检测备份目录
    if [[ -d "/var/backups/ipv6-wireguard" ]]; then
        BACKUP_DIR="/var/backups/ipv6-wireguard"
    else
        BACKUP_DIR="/var/backups/ipv6-wireguard"
    fi
}

# 配置变量
SERVICE_NAME="ipv6-wireguard-manager"
INSTALL_DIR=""
CONFIG_DIR=""
LOG_DIR=""
BACKUP_DIR=""

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
    echo "[$timestamp] [$level] $message" >> /var/log/ipv6-wireguard-uninstall.log
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

# 显示卸载选项
show_uninstall_options() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                IPv6 WireGuard Manager                      ║${NC}"
    echo -e "${WHITE}║                    卸载程序 v1.11                         ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}请选择卸载模式:${NC}"
    echo
    echo -e "  ${GREEN}1.${NC} 标准卸载 (推荐)"
    echo -e "     • 删除 IPv6 WireGuard Manager 程序文件"
    echo -e "     • 删除管理配置文件"
    echo -e "     • 保留 WireGuard 和 BIRD 配置"
    echo -e "     • 保留客户端配置"
    echo
    echo -e "  ${GREEN}2.${NC} 完全卸载"
    echo -e "     • 删除所有程序文件"
    echo -e "     • 删除所有配置文件"
    echo -e "     • 删除 WireGuard 配置"
    echo -e "     • 删除 BIRD 配置"
    echo -e "     • 删除客户端配置"
    echo -e "     • 清理防火墙规则"
    echo
    echo -e "  ${GREEN}3.${NC} 自定义卸载"
    echo -e "     • 选择要删除的组件"
    echo
    echo -e "  ${GREEN}0.${NC} 取消卸载"
    echo
}

# 显示卸载确认
show_uninstall_confirmation() {
    local mode="$1"
    
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                IPv6 WireGuard Manager                      ║${NC}"
    echo -e "${WHITE}║                    卸载程序 v1.11                         ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${RED}警告: 此操作将卸载 IPv6 WireGuard Manager${NC}"
    echo
    
    case "$mode" in
        "1")
            echo -e "${YELLOW}标准卸载 - 将要删除的内容:${NC}"
            echo -e "  • 程序文件: $INSTALL_DIR"
            echo -e "  • 管理配置: $CONFIG_DIR"
            echo -e "  • 日志文件: $LOG_DIR"
            echo -e "  • 备份文件: $BACKUP_DIR"
            echo -e "  • 系统服务: $SERVICE_NAME"
            echo -e "  • 符号链接: /usr/local/bin/ipv6-wg-manager"
            echo -e "  • 符号链接: /usr/local/bin/wg-manager"
            echo
            echo -e "${GREEN}保留的内容:${NC}"
            echo -e "  • WireGuard 配置: /etc/wireguard/"
            echo -e "  • BIRD BGP 配置: /etc/bird/"
            echo -e "  • 客户端配置: /etc/wireguard/clients/"
            echo -e "  • 防火墙规则"
            ;;
        "2")
            echo -e "${YELLOW}完全卸载 - 将要删除的内容:${NC}"
            echo -e "  • 程序文件: $INSTALL_DIR"
            echo -e "  • 管理配置: $CONFIG_DIR"
            echo -e "  • 日志文件: $LOG_DIR"
            echo -e "  • 备份文件: $BACKUP_DIR"
            echo -e "  • 系统服务: $SERVICE_NAME"
            echo -e "  • 符号链接: /usr/local/bin/ipv6-wg-manager"
            echo -e "  • 符号链接: /usr/local/bin/wg-manager"
            echo -e "  • WireGuard 配置: /etc/wireguard/"
            echo -e "  • BIRD BGP 配置: /etc/bird/"
            echo -e "  • 客户端配置: /etc/wireguard/clients/"
            echo -e "  • 防火墙规则 (IPv6 WireGuard 相关)"
            ;;
        "3")
            echo -e "${YELLOW}自定义卸载 - 请选择要删除的组件:${NC}"
            ;;
    esac
    
    echo
    echo -e "${RED}此操作不可逆!${NC}"
    echo
}

# 停止服务
stop_services() {
    log "INFO" "Stopping services..."
    
    # 停止IPv6 WireGuard Manager服务
    if systemctl is-active "$SERVICE_NAME" >/dev/null 2>&1; then
        systemctl stop "$SERVICE_NAME"
        log "INFO" "Stopped $SERVICE_NAME service"
    fi
    
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
    
    echo -e "${GREEN}✓${NC} 服务已停止"
}

# 禁用服务
disable_services() {
    log "INFO" "Disabling services..."
    
    # 禁用IPv6 WireGuard Manager服务
    if systemctl is-enabled "$SERVICE_NAME" >/dev/null 2>&1; then
        systemctl disable "$SERVICE_NAME"
        log "INFO" "Disabled $SERVICE_NAME service"
    fi
    
    echo -e "${GREEN}✓${NC} 服务已禁用"
}

# 删除系统服务
remove_system_service() {
    log "INFO" "Removing system service..."
    
    if [[ -f "/etc/systemd/system/$SERVICE_NAME.service" ]]; then
        rm -f "/etc/systemd/system/$SERVICE_NAME.service"
        systemctl daemon-reload
        log "INFO" "Removed system service file"
    fi
    
    echo -e "${GREEN}✓${NC} 系统服务已删除"
}

# 删除符号链接
remove_symlinks() {
    log "INFO" "Removing symbolic links..."
    
    if [[ -L "/usr/local/bin/ipv6-wg-manager" ]]; then
        rm -f "/usr/local/bin/ipv6-wg-manager"
        log "INFO" "Removed symbolic link: /usr/local/bin/ipv6-wg-manager"
    fi
    
    if [[ -L "/usr/local/bin/wg-manager" ]]; then
        rm -f "/usr/local/bin/wg-manager"
        log "INFO" "Removed symbolic link: /usr/local/bin/wg-manager"
    fi
    
    echo -e "${GREEN}✓${NC} 符号链接已删除"
}

# 删除安装目录
remove_install_directory() {
    log "INFO" "Removing installation directory..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
        log "INFO" "Removed installation directory: $INSTALL_DIR"
    fi
    
    echo -e "${GREEN}✓${NC} 安装目录已删除"
}

# 删除配置目录
remove_config_directories() {
    log "INFO" "Removing configuration directories..."
    
    if [[ -d "$CONFIG_DIR" ]]; then
        rm -rf "$CONFIG_DIR"
        log "INFO" "Removed configuration directory: $CONFIG_DIR"
    fi
    
    if [[ -d "$LOG_DIR" ]]; then
        rm -rf "$LOG_DIR"
        log "INFO" "Removed log directory: $LOG_DIR"
    fi
    
    if [[ -d "$BACKUP_DIR" ]]; then
        rm -rf "$BACKUP_DIR"
        log "INFO" "Removed backup directory: $BACKUP_DIR"
    fi
    
    echo -e "${GREEN}✓${NC} 配置目录已删除"
}

# 清理临时文件
cleanup_temp_files() {
    log "INFO" "Cleaning up temporary files..."
    
    # 清理临时目录
    if [[ -d "/tmp/ipv6-wireguard" ]]; then
        rm -rf "/tmp/ipv6-wireguard"
    fi
    
    # 清理日志文件
    rm -f /var/log/ipv6-wireguard-install.log
    rm -f /var/log/ipv6-wireguard-uninstall.log
    
    echo -e "${GREEN}✓${NC} 临时文件已清理"
}

# 完全卸载 WireGuard
uninstall_wireguard() {
    log "INFO" "Uninstalling WireGuard..."
    
    # 停止 WireGuard 服务
    if systemctl is-active wg-quick@wg0 >/dev/null 2>&1; then
        systemctl stop wg-quick@wg0
        log "INFO" "Stopped WireGuard service"
    fi
    
    # 禁用 WireGuard 服务
    if systemctl is-enabled wg-quick@wg0 >/dev/null 2>&1; then
        systemctl disable wg-quick@wg0
        log "INFO" "Disabled WireGuard service"
    fi
    
    # 删除 WireGuard 配置
    if [[ -d "/etc/wireguard" ]]; then
        rm -rf "/etc/wireguard"
        log "INFO" "Removed WireGuard configuration"
    fi
    
    # 卸载 WireGuard 包
    if command -v apt >/dev/null 2>&1; then
        apt remove -y wireguard wireguard-tools 2>/dev/null || true
    elif command -v dnf >/dev/null 2>&1; then
        dnf remove -y wireguard-tools 2>/dev/null || true
    elif command -v yum >/dev/null 2>&1; then
        yum remove -y wireguard-tools 2>/dev/null || true
    elif command -v pacman >/dev/null 2>&1; then
        pacman -R --noconfirm wireguard-tools 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✓${NC} WireGuard 已完全卸载"
}

# 完全卸载 BIRD
uninstall_bird() {
    log "INFO" "Uninstalling BIRD BGP..."
    
    # 停止 BIRD 服务
    if systemctl is-active bird >/dev/null 2>&1; then
        systemctl stop bird
        log "INFO" "Stopped BIRD service"
    fi
    
    # 禁用 BIRD 服务
    if systemctl is-enabled bird >/dev/null 2>&1; then
        systemctl disable bird
        log "INFO" "Disabled BIRD service"
    fi
    
    # 删除 BIRD 配置
    if [[ -d "/etc/bird" ]]; then
        rm -rf "/etc/bird"
        log "INFO" "Removed BIRD configuration"
    fi
    
    # 卸载 BIRD 包
    if command -v apt >/dev/null 2>&1; then
        apt remove -y bird bird6 2>/dev/null || true
    elif command -v dnf >/dev/null 2>&1; then
        dnf remove -y bird 2>/dev/null || true
    elif command -v yum >/dev/null 2>&1; then
        yum remove -y bird 2>/dev/null || true
    elif command -v pacman >/dev/null 2>&1; then
        pacman -R --noconfirm bird 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✓${NC} BIRD BGP 已完全卸载"
}

# 清理防火墙规则
cleanup_firewall_rules() {
    log "INFO" "Cleaning up firewall rules..."
    
    # 清理 UFW 规则
    if command -v ufw >/dev/null 2>&1; then
        # 删除 IPv6 WireGuard 相关的 UFW 规则
        ufw --force delete allow 51820/udp 2>/dev/null || true
        ufw --force delete allow 179/tcp 2>/dev/null || true
        ufw --force delete allow 179/udp 2>/dev/null || true
        log "INFO" "Cleaned UFW rules"
    fi
    
    # 清理 firewalld 规则
    if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active firewalld >/dev/null 2>&1; then
        firewall-cmd --permanent --remove-port=51820/udp 2>/dev/null || true
        firewall-cmd --permanent --remove-port=179/tcp 2>/dev/null || true
        firewall-cmd --permanent --remove-port=179/udp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
        log "INFO" "Cleaned firewalld rules"
    fi
    
    # 清理 iptables 规则
    if command -v iptables >/dev/null 2>&1; then
        # 删除 IPv6 WireGuard 相关的 iptables 规则
        iptables -D INPUT -p udp --dport 51820 -j ACCEPT 2>/dev/null || true
        iptables -D INPUT -p tcp --dport 179 -j ACCEPT 2>/dev/null || true
        iptables -D INPUT -p udp --dport 179 -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -i wg0 -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -o wg0 -j ACCEPT 2>/dev/null || true
        iptables -t nat -D POSTROUTING -o wg0 -j MASQUERADE 2>/dev/null || true
        log "INFO" "Cleaned iptables rules"
    fi
    
    echo -e "${GREEN}✓${NC} 防火墙规则已清理"
}

# 自定义卸载选择
custom_uninstall_menu() {
    local components=()
    
    echo -e "${CYAN}请选择要删除的组件:${NC}"
    echo
    
    # 检查各个组件是否存在
    local wg_exists=false
    local bird_exists=false
    local fw_exists=false
    
    if [[ -d "/etc/wireguard" ]] || systemctl is-active wg-quick@wg0 >/dev/null 2>&1; then
        wg_exists=true
    fi
    
    if [[ -d "/etc/bird" ]] || systemctl is-active bird >/dev/null 2>&1; then
        bird_exists=true
    fi
    
    if command -v ufw >/dev/null 2>&1 || command -v firewall-cmd >/dev/null 2>&1 || command -v iptables >/dev/null 2>&1; then
        fw_exists=true
    fi
    
    # 显示选项
    if [[ "$wg_exists" == true ]]; then
        echo -e "  ${GREEN}1.${NC} WireGuard 配置和客户端"
    fi
    
    if [[ "$bird_exists" == true ]]; then
        echo -e "  ${GREEN}2.${NC} BIRD BGP 配置"
    fi
    
    if [[ "$fw_exists" == true ]]; then
        echo -e "  ${GREEN}3.${NC} 防火墙规则"
    fi
    
    echo -e "  ${GREEN}4.${NC} 客户端配置目录"
    echo -e "  ${GREEN}5.${NC} 所有日志文件"
    echo -e "  ${GREEN}6.${NC} 所有备份文件"
    echo
    echo -e "  ${GREEN}0.${NC} 完成选择"
    echo
    
    while true; do
        read -p "请选择要删除的组件 (0-6): " choice
        
        case "$choice" in
            "1")
                if [[ "$wg_exists" == true ]]; then
                    components+=("wireguard")
                    echo -e "${GREEN}✓${NC} 已选择 WireGuard"
                else
                    echo -e "${RED}WireGuard 未安装${NC}"
                fi
                ;;
            "2")
                if [[ "$bird_exists" == true ]]; then
                    components+=("bird")
                    echo -e "${GREEN}✓${NC} 已选择 BIRD BGP"
                else
                    echo -e "${RED}BIRD BGP 未安装${NC}"
                fi
                ;;
            "3")
                if [[ "$fw_exists" == true ]]; then
                    components+=("firewall")
                    echo -e "${GREEN}✓${NC} 已选择防火墙规则"
                else
                    echo -e "${RED}防火墙未配置${NC}"
                fi
                ;;
            "4")
                components+=("clients")
                echo -e "${GREEN}✓${NC} 已选择客户端配置"
                ;;
            "5")
                components+=("logs")
                echo -e "${GREEN}✓${NC} 已选择日志文件"
                ;;
            "6")
                components+=("backups")
                echo -e "${GREEN}✓${NC} 已选择备份文件"
                ;;
            "0")
                break
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                ;;
        esac
    done
    
    # 执行自定义卸载
    for component in "${components[@]}"; do
        case "$component" in
            "wireguard")
                uninstall_wireguard
                ;;
            "bird")
                uninstall_bird
                ;;
            "firewall")
                cleanup_firewall_rules
                ;;
            "clients")
                if [[ -d "/etc/wireguard/clients" ]]; then
                    rm -rf "/etc/wireguard/clients"
                    log "INFO" "Removed client configurations"
                    echo -e "${GREEN}✓${NC} 客户端配置已删除"
                fi
                ;;
            "logs")
                find /var/log -name "*wireguard*" -type f -delete 2>/dev/null || true
                find /var/log -name "*bird*" -type f -delete 2>/dev/null || true
                log "INFO" "Cleaned log files"
                echo -e "${GREEN}✓${NC} 日志文件已清理"
                ;;
            "backups")
                if [[ -d "/var/backups/ipv6-wireguard" ]]; then
                    rm -rf "/var/backups/ipv6-wireguard"
                    log "INFO" "Removed backup files"
                    echo -e "${GREEN}✓${NC} 备份文件已删除"
                fi
                ;;
        esac
    done
}

# 显示保留的文件
show_preserved_files() {
    echo
    echo -e "${CYAN}以下文件被保留:${NC}"
    echo
    
    # 检查WireGuard配置
    if [[ -d "/etc/wireguard" ]]; then
        echo -e "  ${YELLOW}WireGuard 配置:${NC} /etc/wireguard/"
        if [[ -f "/etc/wireguard/wg0.conf" ]]; then
            echo -e "    - wg0.conf (服务器配置)"
        fi
    fi
    
    # 检查BIRD配置
    if [[ -f "/etc/bird/bird.conf" ]]; then
        echo -e "  ${YELLOW}BIRD BGP 配置:${NC} /etc/bird/bird.conf"
    fi
    
    # 检查防火墙配置
    if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
        echo -e "  ${YELLOW}防火墙配置:${NC} UFW 规则"
    elif command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active firewalld >/dev/null 2>&1; then
        echo -e "  ${YELLOW}防火墙配置:${NC} Firewalld 规则"
    fi
    
    # 检查客户端配置
    if [[ -d "/etc/wireguard/clients" ]]; then
        local client_count=$(find /etc/wireguard/clients -name "*.conf" | wc -l)
        if [[ $client_count -gt 0 ]]; then
            echo -e "  ${YELLOW}客户端配置:${NC} /etc/wireguard/clients/ ($client_count 个客户端)"
        fi
    fi
}

# 显示卸载完成信息
show_completion_info() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                卸载完成!                                  ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}✓${NC} IPv6 WireGuard Manager 卸载成功!"
    echo
    show_preserved_files
    echo
    echo -e "${CYAN}后续操作:${NC}"
    echo -e "  • 如需重新安装，请运行安装脚本"
    echo -e "  • 如需完全清理，请手动删除保留的文件"
    echo -e "  • 如需停止 WireGuard 服务，请运行: ${YELLOW}systemctl stop wg-quick@wg0${NC}"
    echo -e "  • 如需停止 BIRD 服务，请运行: ${YELLOW}systemctl stop bird${NC}"
    echo
    echo -e "${GREEN}感谢使用 IPv6 WireGuard Manager!${NC}"
}

# 确认卸载
confirm_uninstall() {
    local mode="$1"
    
    echo
    read -p "确定要卸载 IPv6 WireGuard Manager 吗? (y/N): " confirm1
    
    if [[ "${confirm1,,}" != "y" ]]; then
        echo "卸载已取消"
        exit 0
    fi
    
    echo
    read -p "此操作不可逆，请再次确认 (y/N): " confirm2
    
    if [[ "${confirm2,,}" != "y" ]]; then
        echo "卸载已取消"
        exit 0
    fi
}

# 选择卸载模式
select_uninstall_mode() {
    while true; do
        show_uninstall_options
        read -p "请选择卸载模式 (0-3): " choice
        
        case "$choice" in
            "1")
                echo "standard"
                return
                ;;
            "2")
                echo "complete"
                return
                ;;
            "3")
                echo "custom"
                return
                ;;
            "0")
                echo "卸载已取消"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 主卸载流程
main() {
    # 检查root权限
    check_root
    
    # 检测安装路径
    detect_install_paths
    
    # 选择卸载模式
    local mode=$(select_uninstall_mode)
    
    # 显示卸载确认
    show_uninstall_confirmation "$mode"
    
    # 确认卸载
    confirm_uninstall "$mode"
    
    # 开始卸载
    log "INFO" "Starting uninstallation of IPv6 WireGuard Manager (mode: $mode)"
    
    # 停止服务
    stop_services
    disable_services
    remove_system_service
    remove_symlinks
    
    # 根据模式执行不同的卸载操作
    case "$mode" in
        "standard")
            # 标准卸载：只删除管理程序
            remove_install_directory
            remove_config_directories
            cleanup_temp_files
            ;;
        "complete")
            # 完全卸载：删除所有组件
            remove_install_directory
            remove_config_directories
            cleanup_temp_files
            uninstall_wireguard
            uninstall_bird
            cleanup_firewall_rules
            ;;
        "custom")
            # 自定义卸载：用户选择组件
            remove_install_directory
            remove_config_directories
            cleanup_temp_files
            custom_uninstall_menu
            ;;
    esac
    
    show_completion_info
    log "INFO" "Uninstallation completed successfully (mode: $mode)"
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
