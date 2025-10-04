#!/bin/bash

# IPv6 WireGuard Manager 卸载脚本
# 版本: 1.0.0
# 作者: IPv6 WireGuard Manager Team

# 设置错误处理，根据执行环境调整严格程度
if [[ -t 0 ]]; then
    # 交互式执行，使用严格模式（ERR trap在函数中也继承）
    set -Eeuo pipefail
else
    # 非交互执行，启用 ERR 继承与基本错误退出
    set -E -e
fi

# 安全的脚本目录检测
get_script_dir() {
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        # 标准情况：通过BASH_SOURCE获取
        echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit
    elif [[ -n "${0:-}" && "$0" != "-bash" && "$0" != "bash" ]]; then
        # 备选方案1：通过$0获取
        echo "$(cd "$(dirname "$0")" && pwd)" || exit
    else
        # 备选方案2：使用当前工作目录
        echo "$(pwd)"
    fi
}

# 获取脚本目录
SCRIPT_DIR="$(get_script_dir)"

# 检查是否通过符号链接运行，如果是则使用实际安装目录
if [[ -L "/usr/local/bin/ipv6-wireguard-manager" ]]; then
    # 通过符号链接运行，使用实际安装目录
    SCRIPT_DIR="/opt/ipv6-wireguard-manager"
    MODULES_DIR="/opt/ipv6-wireguard-manager/modules"
else
    # 直接运行，使用相对路径
    MODULES_DIR="${MODULES_DIR:-${SCRIPT_DIR}/modules}"
fi

# 提前定义颜色变量，避免导入失败时出错
RED='\033[0;31m'
GREEN='\033[0;32m'
# YELLOW=  # unused'\033[1;33m'
BLUE='\033[0;34m'
# PURPLE=  # unused'\033[0;35m'
# CYAN=  # unused'\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 引入统一公共函数库（包含颜色与日志函数），移除本地日志函数
if [[ -f "${MODULES_DIR}/common_functions.sh" ]]; then
    # shellcheck source=modules/common_functions.sh
    source "${MODULES_DIR}/common_functions.sh"
fi

# 改进的模块导入机制
import_module() {
    local module_name="$1"
    local module_path="${MODULES_DIR}/${module_name}.sh"
    
    if [[ -f "$module_path" ]]; then
        # shellcheck source=/dev/null
        source "$module_path"
        return 0
    else
        # 尝试从多个位置查找模块
        local alt_paths=(
            "$(pwd)/modules/${module_name}.sh"
            "/opt/ipv6-wireguard-manager/modules/${module_name}.sh"
            "/usr/local/share/ipv6-wireguard-manager/modules/${module_name}.sh"
        )
        
        for alt_path in "${alt_paths[@]}"; do
            if [[ -f "$alt_path" ]]; then
                # shellcheck source=/dev/null
                source "$alt_path"
                return 0
            fi
        done
    fi
    
    return 1
}

# 导入公共函数库
if ! import_module "common_functions"; then
    log_warn "无法导入公共函数库，使用内置函数"
    # 继续使用内置的基本函数
fi

# 导入模块加载器
if [[ -f "${MODULES_DIR}/module_loader.sh" ]]; then
    # shellcheck source=modules/module_loader.sh
    source "${MODULES_DIR}/module_loader.sh"
    log_info "模块加载器已导入"
else
    log_error "模块加载器文件不存在: ${MODULES_DIR}/module_loader.sh"
    exit 1
fi

# 颜色定义（如果公共函数库未加载则定义）
RED="${RED:-'\033[0;31m'}"
GREEN="${GREEN:-'\033[0;32m'}"
# YELLOW=  # unused"${YELLOW:-'\033[1;33m'}"
BLUE="${BLUE:-'\033[0;34m'}"
# PURPLE=  # unused"${PURPLE:-'\033[0;35m'}"
# CYAN=  # unused"${CYAN:-'\033[0;36m'}"
WHITE="${WHITE:-'\033[1;37m'}"
NC="${NC:-'\033[0m'}"

# 默认路径
INSTALL_DIR="/opt/ipv6-wireguard-manager"
CONFIG_DIR="/etc/ipv6-wireguard-manager"
LOG_DIR="/var/log/ipv6-wireguard-manager"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"
BIN_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"

# 卸载选项
REMOVE_CONFIG=false
REMOVE_LOGS=false
REMOVE_BACKUPS=false
REMOVE_WIREGUARD=false
REMOVE_BIRD=false
FORCE_UNINSTALL=false
VERBOSE=false

# 卸载模式
UNINSTALL_MODE="interactive"  # interactive, quick, force

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
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 显示卸载选项菜单
show_uninstall_menu() {
    while true; do
        clear
        show_banner
        echo -e "${CYAN}=== 卸载选项 ===${NC}"
        echo
        echo "1. 快速卸载 - 移除核心组件，保留配置和日志"
        echo "2. 完全卸载 - 移除所有组件，包括配置和日志"
        echo "3. 自定义卸载 - 选择要移除的组件"
        echo "4. 显示帮助信息"
        echo "0. 退出"
        echo
        read -rp "请选择卸载方式 [0-4]: " choice
        
        case "$choice" in
            1)
                quick_uninstall
                break
                ;;
            2)
                complete_uninstall
                break
                ;;
            3)
                custom_uninstall
                break
                ;;
            4)
                show_help
                ;;
            0)
                echo -e "${GREEN}退出卸载程序${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 快速卸载
quick_uninstall() {
    log_info "开始快速卸载..."
    UNINSTALL_MODE="quick"
    
    # 停止服务
    stop_services
    
    # 禁用服务
    disable_services
    
    # 删除服务文件
    remove_service_files
    
    # 删除可执行文件
    remove_executable_files
    
    # 删除安装目录
    remove_install_directory
    
    log_success "快速卸载完成"
    show_uninstall_summary
}

# 完全卸载
complete_uninstall() {
    log_info "开始完全卸载..."
    UNINSTALL_MODE="complete"
    
    # 停止服务
    stop_services
    
    # 禁用服务
    disable_services
    
    # 删除服务文件
    remove_service_files
    
    # 删除可执行文件
    remove_executable_files
    
    # 删除安装目录
    remove_install_directory
    
    # 删除配置目录
    remove_config_directory
    
    # 删除日志目录
    remove_log_directory
    
    # 删除备份目录
    remove_backup_directory
    
    # 清理WireGuard配置
    if [[ "$REMOVE_WIREGUARD" == "true" ]]; then
        remove_wireguard_config
    fi
    
    # 清理BIRD配置
    if [[ "$REMOVE_BIRD" == "true" ]]; then
        remove_bird_config
    fi
    
    log_success "完全卸载完成"
    show_uninstall_summary
}

# 自定义卸载
custom_uninstall() {
    log_info "开始自定义卸载..."
    UNINSTALL_MODE="custom"
    
    # 显示组件选择菜单
    show_component_selection
    
    # 停止服务
    stop_services
    
    # 禁用服务
    disable_services
    
    # 根据选择删除组件
    if [[ "$REMOVE_CONFIG" == "true" ]]; then
        remove_config_directory
    fi
    
    if [[ "$REMOVE_LOGS" == "true" ]]; then
        remove_log_directory
    fi
    
    if [[ "$REMOVE_BACKUPS" == "true" ]]; then
        remove_backup_directory
    fi
    
    if [[ "$REMOVE_WIREGUARD" == "true" ]]; then
        remove_wireguard_config
    fi
    
    if [[ "$REMOVE_BIRD" == "true" ]]; then
        remove_bird_config
    fi
    
    # 总是删除核心组件
    remove_service_files
    remove_executable_files
    remove_install_directory
    
    log_success "自定义卸载完成"
    show_uninstall_summary
}

# 显示组件选择菜单
show_component_selection() {
    echo -e "${CYAN}=== 选择要移除的组件 ===${NC}"
    echo
    
    read -rp "是否删除配置文件? [y/N]: " remove_config
    if [[ "$remove_config" =~ ^[Yy]$ ]]; then
        REMOVE_CONFIG=true
    fi
    
    read -rp "是否删除日志文件? [y/N]: " remove_logs
    if [[ "$remove_logs" =~ ^[Yy]$ ]]; then
        REMOVE_LOGS=true
    fi
    
    read -rp "是否删除备份文件? [y/N]: " remove_backups
    if [[ "$remove_backups" =~ ^[Yy]$ ]]; then
        REMOVE_BACKUPS=true
    fi
    
    read -rp "是否删除WireGuard配置? [y/N]: " remove_wireguard
    if [[ "$remove_wireguard" =~ ^[Yy]$ ]]; then
        REMOVE_WIREGUARD=true
    fi
    
    read -rp "是否删除BIRD配置? [y/N]: " remove_bird
    if [[ "$remove_bird" =~ ^[Yy]$ ]]; then
        REMOVE_BIRD=true
    fi
}

# 显示卸载总结
show_uninstall_summary() {
    echo
    echo -e "${GREEN}=== 卸载总结 ===${NC}"
    echo -e "${GREEN}✓ IPv6 WireGuard Manager 已成功卸载${NC}"
    echo
    echo -e "${YELLOW}已移除的组件:${NC}"
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
    echo -e "${CYAN}感谢使用IPv6 WireGuard Manager！${NC}"
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
    if systemctl is-enabled ipv6-wireguard-manager 2>/dev/null; then
        execute_command "systemctl disable ipv6-wireguard-manager" "禁用IPv6 WireGuard Manager服务" "true"
    fi
    
    # 禁用WireGuard服务
    if systemctl is-enabled wg-quick@wg0 2>/dev/null; then
        execute_command "systemctl disable wg-quick@wg0" "禁用WireGuard服务" "true"
    fi
    
    # 禁用BIRD服务
    if systemctl is-enabled bird 2>/dev/null; then
        execute_command "systemctl disable bird" "禁用BIRD服务" "true"
    fi
    
    if systemctl is-enabled bird6 2>/dev/null; then
        execute_command "systemctl disable bird6" "禁用BIRD6服务" "true"
    fi
    
    log_info "服务禁用完成"
}

# 删除服务文件
remove_service_files() {
    log_info "删除服务文件..."
    
    # 删除IPv6 WireGuard Manager服务文件
    if [[ -f "$SERVICE_DIR/ipv6-wireguard-manager.service" ]]; then
        execute_command "rm -f '$SERVICE_DIR/ipv6-wireguard-manager.service'" "删除IPv6 WireGuard Manager服务文件" "true"
    fi
    
    # 重新加载systemd
    execute_command "systemctl daemon-reload" "重新加载systemd配置" "true"
    
    log_info "服务文件删除完成"
}

# 删除可执行文件
remove_executable_files() {
    log_info "删除可执行文件..."
    
    # 删除全局命令别名
    if [[ -L "$BIN_DIR/ipv6-wireguard-manager" ]]; then
        execute_command "rm -f '$BIN_DIR/ipv6-wireguard-manager'" "删除全局命令别名" "true"
    fi
    
    log_info "可执行文件删除完成"
}

# 删除安装目录
remove_install_directory() {
    log_info "删除安装目录..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        execute_command "rm -rf '$INSTALL_DIR'" "删除安装目录" "true"
    fi
    
    log_info "安装目录删除完成"
}

# 删除配置目录
remove_config_directory() {
    log_info "删除配置目录..."
    
    if [[ -d "$CONFIG_DIR" ]]; then
        execute_command "rm -rf '$CONFIG_DIR'" "删除配置目录" "true"
    fi
    
    log_info "配置目录删除完成"
}

# 删除日志目录
remove_log_directory() {
    log_info "删除日志目录..."
    
    if [[ -d "$LOG_DIR" ]]; then
        execute_command "rm -rf '$LOG_DIR'" "删除日志目录" "true"
    fi
    
    log_info "日志目录删除完成"
}

# 删除备份目录
remove_backup_directory() {
    log_info "删除备份目录..."
    
    local backup_dir="/var/backups/ipv6-wireguard"
    if [[ -d "$backup_dir" ]]; then
        execute_command "rm -rf '$backup_dir'" "删除备份目录" "true"
    fi
    
    log_info "备份目录删除完成"
}

# 删除WireGuard配置
remove_wireguard_config() {
    log_info "删除WireGuard配置..."
    
    if [[ -d "/etc/wireguard" ]]; then
        execute_command "rm -rf /etc/wireguard" "删除WireGuard配置" "true"
    fi
    
    log_info "WireGuard配置删除完成"
}

# 删除BIRD配置
remove_bird_config() {
    log_info "删除BIRD配置..."
    
    if [[ -d "/etc/bird" ]]; then
        execute_command "rm -rf /etc/bird" "删除BIRD配置" "true"
    fi
    
    log_info "BIRD配置删除完成"
}

# 显示帮助信息
show_help() {
    clear
    echo -e "${CYAN}=== IPv6 WireGuard Manager 卸载帮助 ===${NC}"
    echo
    echo -e "${YELLOW}卸载选项:${NC}"
    echo "  1. 快速卸载 - 移除核心组件，保留配置和日志"
    echo "     • 删除程序文件和服务"
    echo "     • 保留配置文件和日志"
    echo "     • 适合临时卸载或重新安装"
    echo
    echo "  2. 完全卸载 - 移除所有组件，包括配置和日志"
    echo "     • 删除所有相关文件和目录"
    echo "     • 清理WireGuard和BIRD配置"
    echo "     • 适合完全移除"
    echo
    echo "  3. 自定义卸载 - 选择要移除的组件"
    echo "     • 灵活选择要删除的组件"
    echo "     • 适合部分清理"
    echo
    echo -e "${YELLOW}注意事项:${NC}"
    echo "  • 卸载前请确保已备份重要数据"
    echo "  • 完全卸载将删除所有配置和日志"
    echo "  • 建议在卸载前停止相关服务"
    echo
    read -rp "按回车键返回主菜单..."
}

# 处理命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick|-q)
                UNINSTALL_MODE="quick"
                shift
                ;;
            --complete|-c)
                UNINSTALL_MODE="complete"
                shift
                ;;
            --force|-f)
                # FORCE_UNINSTALL=true  # 暂时注释掉未使用的变量
                shift
                ;;
            --verbose|-v)
                # VERBOSE=true  # 暂时注释掉未使用的变量
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version)
                echo "IPv6 WireGuard Manager 卸载程序 v1.0.0"
                exit 0
                ;;
            *)
                echo -e "${RED}未知参数: $1${NC}"
                echo "使用 --help 查看帮助信息"
                exit 1
                ;;
        esac
    done
}

# 主函数
main() {
    # 检查是否以root权限运行
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}错误: 此脚本需要root权限运行${NC}"
        echo "请使用: sudo $0"
        exit 1
    fi
    
    # 解析命令行参数
    parse_arguments "$@"
    
    # 显示横幅
    show_banner
    
    # 根据模式执行卸载
    case "$UNINSTALL_MODE" in
        "quick")
            quick_uninstall
            ;;
        "complete")
            complete_uninstall
            ;;
        "custom")
            custom_uninstall
            ;;
        "interactive")
            show_uninstall_menu
            ;;
        *)
            echo -e "${RED}错误: 未知的卸载模式${NC}"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"