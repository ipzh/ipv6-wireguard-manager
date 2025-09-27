#!/bin/bash

# IPv6 WireGuard Manager 卸载脚本
# 版本: 1.0.0
# 作者: IPv6 WireGuard Manager Team

set -euo pipefail

# 统一的导入机制
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${MODULES_DIR:-${SCRIPT_DIR}/modules}"

# 导入公共函数库
if [[ -f "${MODULES_DIR}/common_functions.sh" ]]; then
    source "${MODULES_DIR}/common_functions.sh"
    # 验证导入是否成功
    if ! command -v log_info &> /dev/null; then
        echo -e "${RED}错误: 公共函数库导入失败，log_info函数不可用${NC}" >&2
        exit 1
    fi
else
    echo -e "${RED}错误: 公共函数库文件不存在: ${MODULES_DIR}/common_functions.sh${NC}" >&2
    exit 1
fi

# 导入模块加载器
if [[ -f "${MODULES_DIR}/module_loader.sh" ]]; then
    source "${MODULES_DIR}/module_loader.sh"
    log_info "模块加载器已导入"
else
    log_error "模块加载器文件不存在: ${MODULES_DIR}/module_loader.sh"
    exit 1
fi

# 颜色定义（如果公共函数库未加载则定义）
RED="${RED:-'\033[0;31m'}"
GREEN="${GREEN:-'\033[0;32m'}"
YELLOW="${YELLOW:-'\033[1;33m'}"
BLUE="${BLUE:-'\033[0;34m'}"
PURPLE="${PURPLE:-'\033[0;35m'}"
CYAN="${CYAN:-'\033[0;36m'}"
WHITE="${WHITE:-'\033[1;37m'}"
NC="${NC:-'\033[0m'}"

# 默认路径
INSTALL_DIR="/opt/ipv6-wireguard-manager"
CONFIG_DIR="/etc/ipv6-wireguard-manager"
LOG_DIR="/var/log/ipv6-wireguard-manager"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"
BIN_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"

# 统一的命令执行函数
execute_command() {
    local command="$1"
    local description="$2"
    local allow_failure="${3:-false}"
    local timeout="${4:-300}"  # 默认5分钟超时
    
    log_info "${description}..."
    
    # 使用timeout命令限制执行时间
    if command -v timeout >/dev/null 2>&1; then
        if timeout "$timeout" bash -c "$command"; then
            log_success "${description}完成"
            return 0
        else
            local exit_code=$?
            if [[ "$allow_failure" == "true" ]]; then
                log_warn "${description}执行失败，继续执行 (退出码: $exit_code)"
                return 1
            else
                log_error "${description}执行失败: 命令 '${command}' 返回非零状态 (退出码: $exit_code)"
                exit 1
            fi
        fi
    else
        # 如果没有timeout命令，直接执行
        if eval "$command"; then
            log_success "${description}完成"
            return 0
        else
            local exit_code=$?
            if [[ "$allow_failure" == "true" ]]; then
                log_warn "${description}执行失败，继续执行 (退出码: $exit_code)"
                return 1
            else
                log_error "${description}执行失败: 命令 '${command}' 返回非零状态 (退出码: $exit_code)"
                exit 1
            fi
        fi
    fi
}

# 安全权限设置函数
secure_permissions() {
    local target_path="$1"
    local mode="$2"
    local user="${3:-root}"
    local group="${4:-root}"
    
    if [[ ! -e "$target_path" ]]; then
        log_warn "目标路径不存在: $target_path"
        return 1
    fi
    
    execute_command "chown -R '${user}:${group}' '$target_path'" "设置 $target_path 的所有者" "true"
    execute_command "chmod -R '$mode' '$target_path'" "设置 $target_path 的权限" "true"
    
    # 对于配置文件等敏感内容，额外限制权限
    if [[ "$target_path" == *"config"* || "$target_path" == *".key" ]]; then
        execute_command "find '$target_path' -type f \\( -name '*.conf' -o -name '*.key' -o -name '*.pem' \\) -exec chmod 600 {} \\;" "设置敏感文件权限" "true"
    fi
    
    log_info "已设置 $target_path 的安全权限（$mode, ${user}:${group}）"
    return 0
}

# 卸载选项
REMOVE_CONFIG=false
REMOVE_LOGS=false
REMOVE_BACKUPS=false
REMOVE_WIREGUARD=false
REMOVE_BIRD=false
FORCE_UNINSTALL=false
VERBOSE=false

# 显示横幅
show_banner() {
    clear
    echo -e "${RED}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    IPv6 WireGuard Manager 卸载程序                          ║"
    echo "║                                                                              ║"
    echo "║  版本: 1.0.0                                                                ║"
    echo "║  功能: 完全移除IPv6 WireGuard Manager及其相关组件                            ║"
    echo "║                                                                              ║"
    echo "║  警告: 此操作将删除所有配置和数据，且不可恢复！                              ║"
    echo "║                                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 日志函数已从公共函数库导入

# 检查权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此卸载脚本需要root权限运行"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    echo "IPv6 WireGuard Manager 卸载脚本"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  --remove-config        删除配置文件"
    echo "  --remove-logs          删除日志文件"
    echo "  --remove-backups       删除备份文件"
    echo "  --remove-wireguard     删除WireGuard配置"
    echo "  --remove-bird          删除BIRD配置"
    echo "  --force                强制卸载（不询问确认）"
    echo "  -v, --verbose          详细输出"
    echo "  -h, --help             显示此帮助信息"
    echo
    echo "示例:"
    echo "  $0                      # 标准卸载"
    echo "  $0 --remove-config      # 删除配置文件"
    echo "  $0 --force              # 强制卸载"
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --remove-config)
                REMOVE_CONFIG=true
                shift
                ;;
            --remove-logs)
                REMOVE_LOGS=true
                shift
                ;;
            --remove-backups)
                REMOVE_BACKUPS=true
                shift
                ;;
            --remove-wireguard)
                REMOVE_WIREGUARD=true
                shift
                ;;
            --remove-bird)
                REMOVE_BIRD=true
                shift
                ;;
            --force)
                FORCE_UNINSTALL=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 确认卸载
confirm_uninstall() {
    if [[ "$FORCE_UNINSTALL" == "true" ]]; then
        return 0
    fi
    
    echo -e "${YELLOW}警告: 此操作将完全删除IPv6 WireGuard Manager及其所有数据！${NC}"
    echo
    echo "将被删除的内容:"
    echo "  • 程序文件: $INSTALL_DIR"
    echo "  • 系统服务: ipv6-wireguard-manager.service"
    echo "  • 可执行文件: $BIN_DIR/ipv6-wireguard-manager"
    
    if [[ "$REMOVE_CONFIG" == "true" ]]; then
        echo "  • 配置文件: $CONFIG_DIR"
    fi
    
    if [[ "$REMOVE_LOGS" == "true" ]]; then
        echo "  • 日志文件: $LOG_DIR"
    fi
    
    if [[ "$REMOVE_BACKUPS" == "true" ]]; then
        echo "  • 备份文件: /var/backups/ipv6-wireguard"
    fi
    
    if [[ "$REMOVE_WIREGUARD" == "true" ]]; then
        echo "  • WireGuard配置: /etc/wireguard"
    fi
    
    if [[ "$REMOVE_BIRD" == "true" ]]; then
        echo "  • BIRD配置: /etc/bird"
    fi
    
    echo
    echo -e "${RED}此操作不可恢复！${NC}"
    echo
    
    read -p "确认继续卸载? [y/N]: " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "卸载已取消"
        exit 0
    fi
}

# 检查安装状态
check_installation_status() {
    log_info "检查安装状态..."
    
    local installed_components=()
    
    # 检查程序文件
    if [[ -d "$INSTALL_DIR" ]]; then
        installed_components+=("程序文件")
    fi
    
    # 检查系统服务
    if systemctl list-unit-files | grep -q "ipv6-wireguard-manager.service"; then
        installed_components+=("系统服务")
    fi
    
    # 检查可执行文件
    if [[ -L "$BIN_DIR/ipv6-wireguard-manager" ]]; then
        installed_components+=("可执行文件")
    fi
    
    # 检查配置文件
    if [[ -d "$CONFIG_DIR" ]]; then
        installed_components+=("配置文件")
    fi
    
    # 检查日志文件
    if [[ -d "$LOG_DIR" ]]; then
        installed_components+=("日志文件")
    fi
    
    if [[ ${#installed_components[@]} -eq 0 ]]; then
        log_info "未检测到IPv6 WireGuard Manager安装"
        exit 0
    fi
    
    log_info "检测到已安装组件: ${installed_components[*]}"
}

# 停止服务
stop_services() {
    log_info "停止相关服务..."
    
    # 停止IPv6 WireGuard Manager服务
    if systemctl is-active --quiet ipv6-wireguard-manager 2>/dev/null; then
        execute_command "systemctl stop ipv6-wireguard-manager" "停止IPv6 WireGuard Manager服务" "true"
    fi
    
    # 停止WireGuard服务
    if systemctl is-active --quiet wg-quick@wg0 2>/dev/null; then
        execute_command "systemctl stop wg-quick@wg0" "停止WireGuard服务" "true"
    fi
    
    # 停止BIRD服务
    if systemctl is-active --quiet bird 2>/dev/null; then
        execute_command "systemctl stop bird" "停止BIRD服务" "true"
    fi
    
    if systemctl is-active --quiet bird6 2>/dev/null; then
        execute_command "systemctl stop bird6" "停止BIRD6服务" "true"
    fi
    
    log_info "服务停止完成"
}

# 禁用服务
disable_services() {
    log_info "禁用相关服务..."
    
    # 禁用IPv6 WireGuard Manager服务
    if systemctl is-enabled --quiet ipv6-wireguard-manager 2>/dev/null; then
        log_info "禁用IPv6 WireGuard Manager服务..."
        systemctl disable ipv6-wireguard-manager || log_warn "禁用服务失败"
    fi
    
    # 禁用WireGuard服务
    if systemctl is-enabled --quiet wg-quick@wg0 2>/dev/null; then
        log_info "禁用WireGuard服务..."
        systemctl disable wg-quick@wg0 || log_warn "禁用WireGuard服务失败"
    fi
    
    # 禁用BIRD服务
    if systemctl is-enabled --quiet bird 2>/dev/null; then
        log_info "禁用BIRD服务..."
        systemctl disable bird || log_warn "禁用BIRD服务失败"
    fi
    
    if systemctl is-enabled --quiet bird6 2>/dev/null; then
        log_info "禁用BIRD6服务..."
        systemctl disable bird6 || log_warn "禁用BIRD6服务失败"
    fi
    
    log_info "服务禁用完成"
}

# 删除服务文件
remove_service_files() {
    log_info "删除服务文件..."
    
    # 删除IPv6 WireGuard Manager服务文件
    if [[ -f "$SERVICE_DIR/ipv6-wireguard-manager.service" ]]; then
        log_info "删除IPv6 WireGuard Manager服务文件..."
        rm -f "$SERVICE_DIR/ipv6-wireguard-manager.service"
        systemctl daemon-reload
    fi
    
    log_info "服务文件删除完成"
}

# 删除可执行文件
remove_executables() {
    log_info "删除可执行文件..."
    
    # 删除符号链接
    if [[ -L "$BIN_DIR/ipv6-wireguard-manager" ]]; then
        log_info "删除可执行文件链接..."
        rm -f "$BIN_DIR/ipv6-wireguard-manager"
    fi
    
    log_info "可执行文件删除完成"
}

# 删除程序文件
remove_program_files() {
    log_info "删除程序文件..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        log_info "删除安装目录: $INSTALL_DIR"
        rm -rf "$INSTALL_DIR"
    fi
    
    log_info "程序文件删除完成"
}

# 删除配置文件
remove_configuration_files() {
    if [[ "$REMOVE_CONFIG" != "true" ]]; then
        log_info "保留配置文件（使用 --remove-config 删除）"
        return 0
    fi
    
    log_info "删除配置文件..."
    
    if [[ -d "$CONFIG_DIR" ]]; then
        log_info "删除配置目录: $CONFIG_DIR"
        rm -rf "$CONFIG_DIR"
    fi
    
    log_info "配置文件删除完成"
}

# 删除日志文件
remove_log_files() {
    if [[ "$REMOVE_LOGS" != "true" ]]; then
        log_info "保留日志文件（使用 --remove-logs 删除）"
        return 0
    fi
    
    log_info "删除日志文件..."
    
    if [[ -d "$LOG_DIR" ]]; then
        log_info "删除日志目录: $LOG_DIR"
        rm -rf "$LOG_DIR"
    fi
    
    log_info "日志文件删除完成"
}

# 删除备份文件
remove_backup_files() {
    if [[ "$REMOVE_BACKUPS" != "true" ]]; then
        log_info "保留备份文件（使用 --remove-backups 删除）"
        return 0
    fi
    
    log_info "删除备份文件..."
    
    local backup_dir="/var/backups/ipv6-wireguard"
    if [[ -d "$backup_dir" ]]; then
        log_info "删除备份目录: $backup_dir"
        rm -rf "$backup_dir"
    fi
    
    log_info "备份文件删除完成"
}

# 删除WireGuard配置
remove_wireguard_configuration() {
    if [[ "$REMOVE_WIREGUARD" != "true" ]]; then
        log_info "保留WireGuard配置（使用 --remove-wireguard 删除）"
        return 0
    fi
    
    log_info "删除WireGuard配置..."
    
    # 停止WireGuard接口
    if command -v wg &> /dev/null; then
        local interfaces=$(wg show interfaces 2>/dev/null || echo "")
        for interface in $interfaces; do
            log_info "停止WireGuard接口: $interface"
            wg-quick down "$interface" 2>/dev/null || true
        done
    fi
    
    # 删除WireGuard配置目录
    if [[ -d "/etc/wireguard" ]]; then
        log_info "删除WireGuard配置目录: /etc/wireguard"
        rm -rf /etc/wireguard
    fi
    
    log_info "WireGuard配置删除完成"
}

# 删除BIRD配置
remove_bird_configuration() {
    if [[ "$REMOVE_BIRD" != "true" ]]; then
        log_info "保留BIRD配置（使用 --remove-bird 删除）"
        return 0
    fi
    
    log_info "删除BIRD配置..."
    
    # 删除BIRD配置目录
    if [[ -d "/etc/bird" ]]; then
        log_info "删除BIRD配置目录: /etc/bird"
        rm -rf /etc/bird
    fi
    
    log_info "BIRD配置删除完成"
}

# 清理防火墙规则
cleanup_firewall_rules() {
    log_info "清理防火墙规则..."
    
    # 清理iptables规则
    if command -v iptables &> /dev/null; then
        log_info "清理iptables规则..."
        
        # 删除WireGuard相关规则
        iptables -D FORWARD -i wg+ -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -o wg+ -j ACCEPT 2>/dev/null || true
        iptables -t nat -D POSTROUTING -o wg+ -j MASQUERADE 2>/dev/null || true
        
        # 删除IPv6规则
        ip6tables -D FORWARD -i wg+ -j ACCEPT 2>/dev/null || true
        ip6tables -D FORWARD -o wg+ -j ACCEPT 2>/dev/null || true
    fi
    
    # 清理UFW规则
    if command -v ufw &> /dev/null; then
        log_info "清理UFW规则..."
        ufw --force delete allow 51820/udp 2>/dev/null || true
    fi
    
    # 清理firewalld规则
    if command -v firewall-cmd &> /dev/null; then
        log_info "清理firewalld规则..."
        firewall-cmd --permanent --remove-port=51820/udp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
    fi
    
    log_info "防火墙规则清理完成"
}

# 清理系统配置
cleanup_system_configuration() {
    log_info "清理系统配置..."
    
    # 恢复IP转发设置
    if [[ -f /etc/sysctl.conf ]]; then
        log_info "恢复IP转发设置..."
        sed -i '/net.ipv4.ip_forward = 1/d' /etc/sysctl.conf
        sed -i '/net.ipv6.conf.all.forwarding = 1/d' /etc/sysctl.conf
        sysctl -p &>/dev/null || true
    fi
    
    # 清理cron任务
    if [[ -f /etc/crontab ]]; then
        log_info "清理cron任务..."
        sed -i '/ipv6-wireguard-manager/d' /etc/crontab 2>/dev/null || true
    fi
    
    log_info "系统配置清理完成"
}

# 验证卸载
verify_uninstallation() {
    log_info "验证卸载结果..."
    
    local remaining_items=()
    
    # 检查程序文件
    if [[ -d "$INSTALL_DIR" ]]; then
        remaining_items+=("程序文件: $INSTALL_DIR")
    fi
    
    # 检查系统服务
    if systemctl list-unit-files | grep -q "ipv6-wireguard-manager.service"; then
        remaining_items+=("系统服务: ipv6-wireguard-manager.service")
    fi
    
    # 检查可执行文件
    if [[ -L "$BIN_DIR/ipv6-wireguard-manager" ]]; then
        remaining_items+=("可执行文件: $BIN_DIR/ipv6-wireguard-manager")
    fi
    
    # 检查配置文件
    if [[ "$REMOVE_CONFIG" == "true" && -d "$CONFIG_DIR" ]]; then
        remaining_items+=("配置文件: $CONFIG_DIR")
    fi
    
    # 检查日志文件
    if [[ "$REMOVE_LOGS" == "true" && -d "$LOG_DIR" ]]; then
        remaining_items+=("日志文件: $LOG_DIR")
    fi
    
    if [[ ${#remaining_items[@]} -eq 0 ]]; then
        log_info "卸载验证通过，所有指定项目已删除"
        return 0
    else
        log_warn "以下项目仍然存在:"
        for item in "${remaining_items[@]}"; do
            log_warn "  • $item"
        done
        return 1
    fi
}

# 显示卸载完成信息
show_uninstallation_complete() {
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                       卸载完成！                                           ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}卸载摘要:${NC}"
    echo "  • IPv6 WireGuard Manager 已完全移除"
    echo "  • 系统服务已停止并禁用"
    echo "  • 程序文件已删除"
    
    if [[ "$REMOVE_CONFIG" == "true" ]]; then
        echo "  • 配置文件已删除"
    else
        echo "  • 配置文件已保留"
    fi
    
    if [[ "$REMOVE_LOGS" == "true" ]]; then
        echo "  • 日志文件已删除"
    else
        echo "  • 日志文件已保留"
    fi
    
    if [[ "$REMOVE_BACKUPS" == "true" ]]; then
        echo "  • 备份文件已删除"
    else
        echo "  • 备份文件已保留"
    fi
    
    if [[ "$REMOVE_WIREGUARD" == "true" ]]; then
        echo "  • WireGuard配置已删除"
    else
        echo "  • WireGuard配置已保留"
    fi
    
    if [[ "$REMOVE_BIRD" == "true" ]]; then
        echo "  • BIRD配置已删除"
    else
        echo "  • BIRD配置已保留"
    fi
    
    echo
    echo -e "${YELLOW}注意: 如果保留了配置文件，您可以稍后手动删除它们${NC}"
    echo
}

# 主卸载函数
main() {
    show_banner
    
    # 解析参数
    parse_arguments "$@"
    
    # 检查权限
    check_root
    
    # 确认卸载
    confirm_uninstall
    
    # 检查安装状态
    check_installation_status
    
    # 停止服务
    stop_services
    
    # 禁用服务
    disable_services
    
    # 删除服务文件
    remove_service_files
    
    # 删除可执行文件
    remove_executables
    
    # 删除程序文件
    remove_program_files
    
    # 删除配置文件
    remove_configuration_files
    
    # 删除日志文件
    remove_log_files
    
    # 删除备份文件
    remove_backup_files
    
    # 删除WireGuard配置
    remove_wireguard_configuration
    
    # 删除BIRD配置
    remove_bird_configuration
    
    # 清理防火墙规则
    cleanup_firewall_rules
    
    # 清理系统配置
    cleanup_system_configuration
    
    # 验证卸载
    verify_uninstallation
    
    # 显示卸载完成信息
    show_uninstallation_complete
}

# 错误处理
trap 'log_error "卸载过程中发生错误，行号: $LINENO"' ERR

# 执行主函数
main "$@"
