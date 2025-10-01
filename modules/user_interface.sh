#!/bin/bash
# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"

# 确保日志相关变量已定义
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"
fi

# 用户界面模块
# 提供统一的用户界面、菜单系统和交互功能

# 界面配置
UI_CONFIG=(
    "THEME=default"
    "COLORS=true"
    "ANIMATIONS=true"
    "SOUND_EFFECTS=false"
    "AUTO_REFRESH=false"
    "REFRESH_INTERVAL=30"
    "SHOW_PROGRESS=true"
    "CONFIRM_ACTIONS=true"
    "LOG_LEVEL=INFO"
)

# 主题配置
declare -A THEMES=(
    ["default"]="CYAN:WHITE:GREEN:YELLOW:RED:BLUE:PURPLE"
    ["dark"]="BLUE:WHITE:GREEN:YELLOW:RED:CYAN:PURPLE"
    ["light"]="BLACK:WHITE:GREEN:YELLOW:RED:BLUE:PURPLE"
    ["minimal"]="WHITE:WHITE:WHITE:WHITE:WHITE:WHITE:WHITE"
)

# 当前主题
CURRENT_THEME="default"

# 界面状态
UI_STATE=(
    "current_menu=main"
    "menu_stack=()"
    "last_action="
    "user_preferences=()"
)

# 初始化用户界面
init_user_interface() {
    log_info "初始化用户界面..."
    
    # 加载界面配置
    load_ui_config
    
    # 应用主题
    apply_theme "$CURRENT_THEME"
    
    # 设置终端
    setup_terminal
    
    # 显示欢迎信息
    show_welcome
    
    log_info "用户界面初始化完成"
}

# 加载界面配置
load_ui_config() {
    local config_file="${CONFIG_DIR}/ui.conf"
    
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        log_debug "已加载界面配置"
    else
        create_default_ui_config
    fi
}

# 创建默认界面配置
create_default_ui_config() {
    local config_file="${CONFIG_DIR}/ui.conf"
    
    cat > "$config_file" << EOF
# 用户界面配置文件
THEME=default
COLORS=true
ANIMATIONS=true
SOUND_EFFECTS=false
AUTO_REFRESH=false
REFRESH_INTERVAL=30
SHOW_PROGRESS=true
CONFIRM_ACTIONS=true
LOG_LEVEL=INFO
MENU_TIMEOUT=0
QUICK_ACTIONS=true
SHORTCUTS=true
EOF
    
    log_info "已创建默认界面配置: $config_file"
}

# 应用主题
apply_theme() {
    local theme_name="$1"
    
    if [[ -z "${THEMES[$theme_name]:-}" ]]; then
        log_warn "主题不存在: $theme_name，使用默认主题"
        theme_name="default"
    fi
    
    CURRENT_THEME="$theme_name"
    local theme_colors="${THEMES[$theme_name]}"
    
    # 解析主题颜色
    IFS=':' read -ra COLORS <<< "$theme_colors"
    
    # 设置颜色变量
    PRIMARY_COLOR="${!COLORS[0]:-CYAN}"
    SECONDARY_COLOR="${!COLORS[1]:-WHITE}"
    SUCCESS_COLOR="${!COLORS[2]:-GREEN}"
    WARNING_COLOR="${!COLORS[3]:-YELLOW}"
    ERROR_COLOR="${!COLORS[4]:-RED}"
    INFO_COLOR="${!COLORS[5]:-BLUE}"
    ACCENT_COLOR="${!COLORS[6]:-PURPLE}"
    
    log_info "已应用主题: $theme_name"
}

# 设置终端
setup_terminal() {
    # 检查终端类型
    if [[ -n "$TERM" ]]; then
        log_debug "终端类型: $TERM"
    fi
    
    # 检查颜色支持
    if [[ "${COLORS:-true}" == "true" ]]; then
        if command -v tput &> /dev/null; then
            local colors=$(tput colors 2>/dev/null || echo "0")
            if [[ $colors -ge 8 ]]; then
                log_debug "终端支持 $colors 种颜色"
            else
                log_warn "终端颜色支持有限"
            fi
        fi
    fi
    
    # 设置终端大小
    if command -v tput &> /dev/null; then
        TERMINAL_WIDTH=$(tput cols 2>/dev/null || echo "80")
        TERMINAL_HEIGHT=$(tput lines 2>/dev/null || echo "24")
    else
        TERMINAL_WIDTH=80
        TERMINAL_HEIGHT=24
    fi
    
    log_debug "终端大小: ${TERMINAL_WIDTH}x${TERMINAL_HEIGHT}"
}

# 显示欢迎信息
show_welcome() {
    if [[ "${ANIMATIONS:-true}" == "true" ]]; then
        show_animated_banner
    else
        show_banner
    fi
}

# 显示动画横幅
show_animated_banner() {
    local frames=(
        "正在启动 IPv6 WireGuard Manager..."
        "正在初始化系统检测..."
        "正在加载功能模块..."
        "正在准备用户界面..."
        "欢迎使用 IPv6 WireGuard Manager!"
    )
    
    for frame in "${frames[@]}"; do
        clear
        echo -e "${PRIMARY_COLOR}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PRIMARY_COLOR}║$(printf "%*s" $((80 - ${#frame})) "$frame")║${NC}"
        echo -e "${PRIMARY_COLOR}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
        smart_sleep "$IPV6WGM_SLEEP_UI"
    done
    
    smart_sleep "$IPV6WGM_SLEEP_MEDIUM"
}

# 显示横幅
show_banner() {
    clear
    echo -e "${PRIMARY_COLOR}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    IPv6 WireGuard VPN Manager v1.0.0                        ║"
    echo "║                                                                              ║"
    echo "║  功能特性:                                                                   ║"
    echo "║  • 自动环境检测和依赖安装                                                    ║"
    echo "║  • WireGuard服务器自动配置                                                   ║"
    echo "║  • BIRD BGP路由支持 (1.x/2.x/3.x)                                           ║"
    echo "║  • IPv6子网管理 (/56到/72)                                                  ║"
    echo "║  • 多防火墙支持 (UFW/firewalld/nftables/iptables)                           ║"
    echo "║  • 客户端自动安装功能                                                        ║"
    echo "║  • Web管理界面                                                               ║"
    echo "║  • 实时监控和告警                                                           ║"
    echo "║  • 批量管理功能                                                             ║"
    echo "║  • 配置备份恢复                                                             ║"
    echo "║                                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 显示菜单
show_menu() {
    local menu_type="$1"
    local title="$2"
    local options=("${@:3}")
    
    while true; do
        clear
        show_banner
        
        # 显示标题
        if [[ -n "$title" ]]; then
            echo -e "${SECONDARY_COLOR}=== $title ===${NC}"
            echo
        fi
        
        # 显示选项
        local index=1
        for option in "${options[@]}"; do
            if [[ $option == "---" ]]; then
                echo -e "${PRIMARY_COLOR}────────────────────────────────────────────────────────────────────────────────${NC}"
            else
                echo -e "${SUCCESS_COLOR}$index.${NC} $option"
                ((index++))
            fi
        done
        
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        # 获取用户输入
        read -rp "请选择操作 [0-$((index-1))]: " choice
        
        # 验证输入
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 0 && $choice -lt $index ]]; then
            if [[ $choice -eq 0 ]]; then
                return 0
            else
                local selected_option="${options[$((choice-1))]}"
                handle_menu_selection "$menu_type" "$choice" "$selected_option"
            fi
        else
            show_error "无效选择，请重新输入"
            smart_sleep "$IPV6WGM_SLEEP_LONG"
        fi
    done
}

# 处理菜单选择
handle_menu_selection() {
    local menu_type="$1"
    local choice="$2"
    local option="$3"
    
    log_info "用户选择: $menu_type - $choice - $option"
    
    # 记录最后操作
    UI_STATE["last_action"]="$menu_type:$choice:$option"
    
    # 根据菜单类型处理选择
    case "$menu_type" in
        "main")
            handle_main_menu_selection "$choice" "$option"
            ;;
        "server")
            handle_server_menu_selection "$choice" "$option"
            ;;
        "client")
            handle_client_menu_selection "$choice" "$option"
            ;;
        "network")
            handle_network_menu_selection "$choice" "$option"
            ;;
        "firewall")
            handle_firewall_menu_selection "$choice" "$option"
            ;;
        "system")
            handle_system_menu_selection "$choice" "$option"
            ;;
        *)
            log_warn "未知菜单类型: $menu_type"
            ;;
    esac
}

# 显示确认对话框
show_confirm() {
    local message="$1"
    local default="${2:-n}"
    
    echo -e "${WARNING_COLOR}⚠ $message${NC}"
    
    if [[ "$default" == "y" ]]; then
        read -rp "确认执行? [Y/n]: " -n 1 -r
        echo
        [[ $REPLY =~ ^[Nn]$ ]] && return 1
    else
        read -rp "确认执行? [y/N]: " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && return 0
    fi
    
    return 1
}

# 显示输入对话框
show_input() {
    local prompt="$1"
    local default="${2:-}"
    local validation="${3:-}"
    
    while true; do
        if [[ -n "$default" ]]; then
            read -rp "$prompt [默认: $default]: " input
            input="${input:-$default}"
        else
            read -rp "$prompt: " input
        fi
        
        if [[ -n "$validation" ]]; then
            if eval "$validation '$input'"; then
                echo "$input"
                return 0
            else
                show_error "输入验证失败，请重新输入"
            fi
        else
            echo "$input"
            return 0
        fi
    done
}

# 显示密码输入
show_password_input() {
    local prompt="$1"
    local confirm_prompt="${2:-确认密码}"
    
    while true; do
        read -s -p "$prompt: " password1
        echo
        read -s -p "$confirm_prompt: " password2
        echo
        
        if [[ "$password1" == "$password2" ]]; then
            echo "$password1"
            return 0
        else
            show_error "密码不匹配，请重新输入"
        fi
    done
}

# 显示选择列表
show_selection() {
    local title="$1"
    local options=("${@:2}")
    
    echo -e "${SECONDARY_COLOR}=== $title ===${NC}"
    echo
    
    local index=1
    for option in "${options[@]}"; do
        echo -e "${SUCCESS_COLOR}$index.${NC} $option"
        ((index++))
    done
    
    echo
    
    while true; do
        read -rp "请选择 [1-$((index-1))]: " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 && $choice -lt $index ]]; then
            echo "${options[$((choice-1))]}"
            return 0
        else
            show_error "无效选择，请重新输入"
        fi
    done
}

# 显示进度条
show_progress_bar() {
    local current="$1"
    local total="$2"
    local description="$3"
    local width=50
    
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${INFO_COLOR}[${NC}"
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "${INFO_COLOR}]${NC} %d%% %s" "$percentage" "$description"
    
    if [[ $current -eq $total ]]; then
        echo
    fi
}

# 显示加载动画
show_loading() {
    local message="$1"
    local duration="${2:-5}"
    
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local frame_count=${#frames[@]}
    local frame_index=0
    
    echo -n "$message "
    
    for ((i=0; i<duration*10; i++)); do
        printf "\r${INFO_COLOR}%s${NC} %s" "${frames[$frame_index]}" "$message"
        ((frame_index = (frame_index + 1) % frame_count))
        smart_sleep "$IPV6WGM_SLEEP_SHORT"
    done
    
    echo
}

# 显示成功消息
show_success() {
    local message="$1"
    echo -e "${SUCCESS_COLOR}✓ $message${NC}"
}

# 显示错误消息
show_error() {
    local message="$1"
    echo -e "${ERROR_COLOR}✗ $message${NC}"
}

# 显示警告消息
show_warning() {
    local message="$1"
    echo -e "${WARNING_COLOR}⚠ $message${NC}"
}

# 显示信息消息
show_info() {
    local message="$1"
    echo -e "${INFO_COLOR}ℹ $message${NC}"
}

# 显示表格
show_table() {
    local headers=("$@")
    local data=()
    
    # 计算列宽
    local col_widths=()
    for header in "${headers[@]}"; do
        col_widths+=(${#header})
    done
    
    # 显示表头
    echo -e "${PRIMARY_COLOR}┌${NC}"
    for i in "${!headers[@]}"; do
        printf "%-${col_widths[$i]}s" "${headers[$i]}"
        if [[ $i -lt $((${#headers[@]}-1)) ]]; then
            echo -e "${PRIMARY_COLOR}│${NC}"
        fi
    done
    echo -e "${PRIMARY_COLOR}┐${NC}"
    
    # 显示分隔线
    echo -e "${PRIMARY_COLOR}├${NC}"
    for i in "${!headers[@]}"; do
        printf "%${col_widths[$i]}s" | tr ' ' '─'
        if [[ $i -lt $((${#headers[@]}-1)) ]]; then
            echo -e "${PRIMARY_COLOR}┼${NC}"
        fi
    done
    echo -e "${PRIMARY_COLOR}┤${NC}"
    
    # 显示数据行
    for row in "${data[@]}"; do
        echo -e "${PRIMARY_COLOR}│${NC}"
        IFS='|' read -ra fields <<< "$row"
        for i in "${!fields[@]}"; do
            printf "%-${col_widths[$i]}s" "${fields[$i]}"
            if [[ $i -lt $((${#fields[@]}-1)) ]]; then
                echo -e "${PRIMARY_COLOR}│${NC}"
            fi
        done
        echo -e "${PRIMARY_COLOR}│${NC}"
    done
    
    # 显示底部边框
    echo -e "${PRIMARY_COLOR}└${NC}"
    for i in "${!headers[@]}"; do
        printf "%${col_widths[$i]}s" | tr ' ' '─'
        if [[ $i -lt $((${#headers[@]}-1)) ]]; then
            echo -e "${PRIMARY_COLOR}┴${NC}"
        fi
    done
    echo -e "${PRIMARY_COLOR}┘${NC}"
}

# 显示帮助信息
show_help() {
    local topic="${1:-general}"
    
    case "$topic" in
        "general")
            show_general_help
            ;;
        "installation")
            show_installation_help
            ;;
        "configuration")
            show_configuration_help
            ;;
        "troubleshooting")
            show_troubleshooting_help
            ;;
        *)
            show_error "未知帮助主题: $topic"
            ;;
    esac
}

# 显示一般帮助
show_general_help() {
    echo -e "${SECONDARY_COLOR}=== 一般帮助 ===${NC}"
    echo
    echo "IPv6 WireGuard Manager 是一个功能强大的VPN服务器管理工具。"
    echo
    echo "主要功能:"
    echo "  • 自动安装和配置WireGuard服务器"
    echo "  • 支持BIRD BGP路由"
    echo "  • IPv6子网管理"
    echo "  • 多防火墙支持"
    echo "  • 客户端自动安装"
    echo "  • Web管理界面"
    echo "  • 实时监控和告警"
    echo
    echo "使用提示:"
    echo "  • 使用数字键选择菜单选项"
    echo "  • 按0返回上级菜单"
    echo "  • 使用Ctrl+C退出程序"
    echo "  • 查看日志文件获取详细信息"
}

# 显示安装帮助
show_installation_help() {
    echo -e "${SECONDARY_COLOR}=== 安装帮助 ===${NC}"
    echo
    echo "安装要求:"
    echo "  • Linux操作系统 (Ubuntu 18.04+, Debian 9+, CentOS 7+, 等)"
    echo "  • Root权限"
    echo "  • 互联网连接"
    echo "  • 至少1GB内存"
    echo "  • 至少10GB磁盘空间"
    echo
    echo "安装步骤:"
    echo "  1. 下载安装脚本"
    echo "  2. 运行安装脚本"
    echo "  3. 选择安装类型"
    echo "  4. 配置系统参数"
    echo "  5. 等待安装完成"
    echo
    echo "故障排除:"
    echo "  • 检查系统兼容性"
    echo "  • 确保有足够的权限"
    echo "  • 检查网络连接"
    echo "  • 查看安装日志"
}

# 显示配置帮助
show_configuration_help() {
    echo -e "${SECONDARY_COLOR}=== 配置帮助 ===${NC}"
    echo
    echo "配置文件位置:"
    echo "  • 主配置: $CONFIG_FILE"
    echo "  • WireGuard: /etc/wireguard/"
    echo "  • BIRD: /etc/bird/"
    echo "  • 防火墙: /etc/ufw/ 或 /etc/firewalld/"
    echo
    echo "重要配置项:"
    echo "  • WIREGUARD_PORT: WireGuard监听端口"
    echo "  • WIREGUARD_INTERFACE: WireGuard接口名"
    echo "  • IPV6_PREFIX: IPv6前缀"
    echo "  • BIRD_VERSION: BIRD版本"
    echo "  • FIREWALL_TYPE: 防火墙类型"
    echo
    echo "配置修改:"
    echo "  • 使用配置菜单修改设置"
    echo "  • 手动编辑配置文件"
    echo "  • 重启服务应用更改"
}

# 显示故障排除帮助
show_troubleshooting_help() {
    echo -e "${SECONDARY_COLOR}=== 故障排除帮助 ===${NC}"
    echo
    echo "常见问题:"
    echo "  • 服务无法启动: 检查配置文件和权限"
    echo "  • 客户端无法连接: 检查防火墙和网络配置"
    echo "  • BGP路由问题: 检查BIRD配置和邻居设置"
    echo "  • IPv6问题: 检查IPv6前缀和路由配置"
    echo
    echo "诊断工具:"
    echo "  • 系统状态检查"
    echo "  • 网络连接测试"
    echo "  • 服务状态检查"
    echo "  • 日志文件分析"
    echo
    echo "获取支持:"
    echo "  • 查看日志文件"
    echo "  • 运行诊断工具"
    echo "  • 生成系统报告"
    echo "  • 联系技术支持"
}

# 保存用户偏好
save_user_preferences() {
    local config_file="${CONFIG_DIR}/ui.conf"
    
    cat > "$config_file" << EOF
# 用户界面配置文件
THEME=$CURRENT_THEME
COLORS=${COLORS:-true}
ANIMATIONS=${ANIMATIONS:-true}
SOUND_EFFECTS=${SOUND_EFFECTS:-false}
AUTO_REFRESH=${AUTO_REFRESH:-false}
REFRESH_INTERVAL=${REFRESH_INTERVAL:-30}
SHOW_PROGRESS=${SHOW_PROGRESS:-true}
CONFIRM_ACTIONS=${CONFIRM_ACTIONS:-true}
LOG_LEVEL=${LOG_LEVEL:-INFO}
MENU_TIMEOUT=${MENU_TIMEOUT:-0}
QUICK_ACTIONS=${QUICK_ACTIONS:-true}
SHORTCUTS=${SHORTCUTS:-true}
EOF
    
    log_info "用户偏好已保存"
}

# 导出函数
export -f init_user_interface load_ui_config create_default_ui_config apply_theme
export -f setup_terminal show_welcome show_animated_banner show_banner
export -f show_menu handle_menu_selection show_confirm show_input show_password_input
export -f show_selection show_progress_bar show_loading show_success show_error
export -f show_warning show_info show_table show_help show_general_help
export -f show_installation_help show_configuration_help show_troubleshooting_help
export -f save_user_preferences
