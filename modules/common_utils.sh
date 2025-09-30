#!/bin/bash

# IPv6 WireGuard Manager 通用工具函数模块
# 版本: 1.0.0
# 作者: IPv6 WireGuard Manager Team

# 显示横幅
show_banner() {
    local title="${1:-IPv6 WireGuard Manager}"
    local version="${2:-1.0.0}"
    local description="${3:-}"
    
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    $title                                                    ║"
    echo "║                                                                              ║"
    if [[ -n "$description" ]]; then
        echo "║  $description                                                              ║"
        echo "║                                                                              ║"
    fi
    echo "║  版本: $version                                                                ║"
    echo "║                                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}错误: 此脚本需要root权限运行${NC}"
        echo -e "${YELLOW}请使用: sudo $0${NC}"
        exit 1
    fi
}

# 检查系统要求
check_system_requirements() {
    log_info "检查系统要求..."
    
    local missing_deps=()
    local warnings=()
    
    # 检查必要的命令
    local required_commands=("bash" "curl" "wget" "tar" "gzip" "systemctl")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # 检查Bash版本
    local bash_version=$(bash --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -n1)
    if [[ $(echo "$bash_version < 4.0" | bc -l 2>/dev/null || echo "0") == "1" ]]; then
        warnings+=("Bash版本过低: $bash_version (建议4.0+)")
    fi
    
    # 检查内存
    local total_mem=$(free -m | awk 'NR==2{print $2}')
    if [[ $total_mem -lt 512 ]]; then
        warnings+=("内存不足: ${total_mem}MB (建议512MB+)")
    fi
    
    # 检查磁盘空间
    local available_space=$(df / | tail -1 | awk '{print $4}')
    if [[ $available_space -lt 1048576 ]]; then # 1GB in KB
        warnings+=("磁盘空间不足: ${available_space}KB (建议1GB+)")
    fi
    
    # 报告结果
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "缺少必要的系统依赖: ${missing_deps[*]}"
        log_error "请安装这些依赖后重试"
        return 1
    fi
    
    if [[ ${#warnings[@]} -gt 0 ]]; then
        for warning in "${warnings[@]}"; do
            log_warn "⚠️  $warning"
        done
    fi
    
    log_success "系统要求检查通过"
    return 0
}

# 显示帮助信息
show_help() {
    local script_name="${1:-$0}"
    local version="${2:-1.0.0}"
    local description="${3:-IPv6 WireGuard Manager}"
    
    cat << EOF
$description 版本 $version

用法: $script_name [选项]

选项:
    --help, -h          显示此帮助信息
    --version, -v       显示版本信息
    --verbose          详细输出模式
    --quiet            静默模式
    --force            强制操作（跳过确认）
    --dry-run          模拟运行（不执行实际操作）
    --config FILE      指定配置文件
    --log-level LEVEL  设置日志级别 (DEBUG|INFO|WARN|ERROR)

示例:
    $script_name --help
    $script_name --version
    $script_name --verbose --config /path/to/config.conf
    $script_name --dry-run

更多信息请访问: https://github.com/ipzh/ipv6-wireguard-manager
EOF
}

# 显示版本信息
show_version() {
    local script_name="${1:-$0}"
    local version="${2:-1.0.0}"
    local build_date="${3:-$(date '+%Y-%m-%d')}"
    local git_commit="${4:-$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')}"
    
    cat << EOF
$script_name 版本 $version
构建日期: $build_date
Git提交: $git_commit
作者: IPv6 WireGuard Manager Team
许可证: MIT
项目地址: https://github.com/ipzh/ipv6-wireguard-manager
EOF
}

# 确认操作
confirm() {
    local message="${1:-确定要继续吗？}"
    local default="${2:-false}"
    
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    
    local prompt=""
    if [[ "$default" == "true" ]]; then
        prompt="$message [Y/n]: "
    else
        prompt="$message [y/N]: "
    fi
    
    while true; do
        read -p "$prompt" -r response
        case "$response" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo])
                return 1
                ;;
            "")
                if [[ "$default" == "true" ]]; then
                    return 0
                else
                    return 1
                fi
                ;;
            *)
                echo "请输入 y 或 n"
                ;;
        esac
    done
}

# 进度条显示
show_progress() {
    local current="$1"
    local total="$2"
    local description="${3:-处理中}"
    local width="${4:-50}"
    
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${CYAN}%s: [" "$description"
    printf "%*s" "$filled" | tr ' ' '='
    printf "%*s" "$empty" | tr ' ' '-'
    printf "] %d%% (%d/%d)${NC}" "$percentage" "$current" "$total"
    
    if [[ $current -eq $total ]]; then
        echo
    fi
}

# 等待用户输入
wait_for_user() {
    local message="${1:-按任意键继续...}"
    echo -e "${YELLOW}$message${NC}"
    read -n 1 -s
    echo
}

# 清理临时文件
cleanup_temp_files() {
    local temp_dir="${1:-/tmp}"
    local pattern="${2:-ipv6-wireguard-*}"
    
    if [[ -d "$temp_dir" ]]; then
        find "$temp_dir" -name "$pattern" -type f -mtime +1 -delete 2>/dev/null || true
        log_debug "临时文件已清理: $temp_dir/$pattern"
    fi
}

# 检查网络连接
check_network_connectivity() {
    local test_hosts=("8.8.8.8" "1.1.1.1" "google.com")
    local connected=false
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 3 "$host" &> /dev/null; then
            connected=true
            break
        fi
    done
    
    if [[ "$connected" == "true" ]]; then
        log_success "网络连接正常"
        return 0
    else
        log_error "网络连接失败，请检查您的网络设置"
        return 1
    fi
}

# 获取系统信息
get_system_info() {
    local os_info=""
    local kernel_info=""
    local arch_info=""
    
    # 操作系统信息
    if [[ -f /etc/os-release ]]; then
        os_info=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
    else
        os_info="未知操作系统"
    fi
    
    # 内核信息
    kernel_info=$(uname -r)
    
    # 架构信息
    arch_info=$(uname -m)
    
    echo "操作系统: $os_info"
    echo "内核版本: $kernel_info"
    echo "系统架构: $arch_info"
    echo "主机名: $(hostname)"
    echo "当前用户: $(whoami)"
    echo "当前时间: $(date '+%Y-%m-%d %H:%M:%S')"
}

# 显示系统状态
show_system_status() {
    echo -e "${CYAN}=== 系统状态 ===${NC}"
    
    # 系统负载
    local load_avg=$(cat /proc/loadavg 2>/dev/null || echo "未知")
    echo -e "${GREEN}系统负载: $load_avg${NC}"
    
    # 内存使用
    local mem_info=$(free -h | grep Mem | awk '{print "已用: " $3 " / " $2 " (" int($3/$2*100) "%)"}')
    echo -e "${GREEN}内存使用: $mem_info${NC}"
    
    # 磁盘使用
    local disk_info=$(df -h / | tail -1 | awk '{print "已用: " $3 " / " $2 " (" $5 ")"}')
    echo -e "${GREEN}磁盘使用: $disk_info${NC}"
    
    # 网络接口
    local interfaces=$(ip link show | grep -E "^[0-9]+:" | awk -F': ' '{print $2}' | head -3 | tr '\n' ' ')
    echo -e "${GREEN}网络接口: $interfaces${NC}"
}

# 导出通用函数
export -f show_banner check_root check_system_requirements show_help show_version
export -f confirm show_progress wait_for_user cleanup_temp_files check_network_connectivity
export -f get_system_info show_system_status
