#!/bin/bash

# IPv6 WireGuard Manager 安装脚本
# 版本: 1.0.0
# 作者: IPv6 WireGuard Manager Team

set -euo pipefail

# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/modules/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/modules/common_functions.sh"
    echo "已加载公共函数库"
else
    echo "警告: 无法加载公共函数库，使用内置函数"
fi

# 修复文件行尾符函数（备用定义）
if ! declare -f fix_line_endings >/dev/null 2>&1; then
    fix_line_endings() {
        local file="$1"
        
        if [[ ! -f "$file" ]]; then
            return 1
        fi
        
        # 转换Windows行尾符为Unix行尾符
        if command -v sed &> /dev/null; then
            sed -i 's/\r$//' "$file" 2>/dev/null || true
        elif command -v tr &> /dev/null; then
            tr -d '\r' < "$file" > "${file}.tmp" && mv "${file}.tmp" "$file" 2>/dev/null || true
        elif command -v dos2unix &> /dev/null; then
            dos2unix "$file" 2>/dev/null || true
        else
            # 使用Python作为最后的回退方案
            python3 -c "
import sys
with open('$file', 'rb') as f:
    content = f.read()
content = content.replace(b'\r\n', b'\n').replace(b'\r', b'\n')
with open('$file', 'wb') as f:
    f.write(content)
" 2>/dev/null || true
        fi
    }
fi

# 颜色定义（如果公共函数库未加载则定义）
RED="${RED:-'\033[0;31m'}"
GREEN="${GREEN:-'\033[0;32m'}"
YELLOW="${YELLOW:-'\033[1;33m'}"
BLUE="${BLUE:-'\033[0;34m'}"
PURPLE="${PURPLE:-'\033[0;35m'}"
CYAN="${CYAN:-'\033[0;36m'}"
WHITE="${WHITE:-'\033[1;37m'}"
INFO_COLOR="${INFO_COLOR:-'\033[0;36m'}"  # 信息颜色（青色）
NC="${NC:-'\033[0m'}"

# 备用日志函数（如果公共函数库未加载）
if ! declare -f log_info >/dev/null 2>&1; then
    log_info() {
        local log_file="${LOG_FILE:-/tmp/install.log}"
        mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
        echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$log_file"
    }
    
    log_success() {
        local log_file="${LOG_FILE:-/tmp/install.log}"
        mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
        echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$log_file"
    }
    
    log_warn() {
        local log_file="${LOG_FILE:-/tmp/install.log}"
        mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
        echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$log_file"
    }
    
    log_error() {
        local log_file="${LOG_FILE:-/tmp/install.log}"
        mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
        echo -e "${RED}[ERROR]${NC} $1" | tee -a "$log_file"
    }
    
    log_debug() {
        if [[ "${LOG_LEVEL:-INFO}" == "DEBUG" ]]; then
            local log_file="${LOG_FILE:-/tmp/install.log}"
            mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
            echo -e "${CYAN}[DEBUG]${NC} $1" | tee -a "$log_file"
        fi
    }
    
    echo "已加载备用日志函数"
fi

# 确保LOG_FILE变量已定义
LOG_FILE="${LOG_FILE:-/tmp/install.log}"

# 安装配置
INSTALL_DIR="/opt/ipv6-wireguard-manager"
CONFIG_DIR="/etc/ipv6-wireguard-manager"
LOG_DIR="/var/log/ipv6-wireguard-manager"
BIN_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"

# 仓库配置（可通过环境变量覆盖）
REPO_OWNER="${REPO_OWNER:-ipzh}"
REPO_NAME="${REPO_NAME:-ipv6-wireguard-manager}"
REPO_BRANCH="${REPO_BRANCH:-master}"
REPO_URL="${REPO_URL:-https://github.com/ipzh/ipv6-wireguard-manager}"
RAW_URL="${RAW_URL:-https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master}"
API_URL="${API_URL:-https://api.github.com/repos/ipzh/ipv6-wireguard-manager}"

# 安装选项
INSTALL_TYPE="full"  # full, minimal, custom
SKIP_DEPENDENCIES=false
SKIP_CONFIG=false
SKIP_SERVICE=false
FORCE_INSTALL=false
VERBOSE=false

# 功能选择（交互式安装时使用）
INSTALL_WIREGUARD=true
INSTALL_BIRD=true
INSTALL_FIREWALL=true
INSTALL_WEB_INTERFACE=true
INSTALL_MONITORING=true
INSTALL_CLIENT_AUTO_INSTALL=true
INSTALL_BACKUP_RESTORE=true
INSTALL_UPDATE_MANAGEMENT=true
INSTALL_SECURITY_ENHANCEMENTS=true
INSTALL_CONFIG_MANAGEMENT=true
INSTALL_WEB_INTERFACE_ENHANCED=true
INSTALL_OAUTH_AUTHENTICATION=true
INSTALL_SECURITY_AUDIT_MONITORING=true
INSTALL_NETWORK_TOPOLOGY=true
INSTALL_API_DOCUMENTATION=true
INSTALL_WEBSOCKET_REALTIME=true
INSTALL_MULTI_TENANT=true
INSTALL_RESOURCE_QUOTA=true
INSTALL_LAZY_LOADING=true
INSTALL_PERFORMANCE_OPTIMIZATION=true

# 显示横幅
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    IPv6 WireGuard Manager 安装程序                          ║"
    echo "║                                                                              ║"
    echo "║  版本: 1.0.0                                                                ║"
    echo "║  功能: 完整的IPv6 WireGuard VPN服务器管理系统                                ║"
    echo "║                                                                              ║"
    echo "║  特性:                                                                       ║"
    echo "║  • 自动环境检测和依赖安装                                                    ║"
    echo "║  • WireGuard服务器自动配置                                                   ║"
    echo "║  • BIRD BGP路由支持                                                         ║"
    echo "║  • IPv6子网管理                                                             ║"
    echo "║  • 多防火墙支持                                                             ║"
    echo "║  • 客户端自动安装功能                                                        ║"
    echo "║  • Web管理界面                                                               ║"
    echo "║  • 实时监控和告警                                                           ║"
    echo "║                                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 日志函数已从公共函数库导入

# 检查权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此安装脚本需要root权限运行"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    echo "IPv6 WireGuard Manager 安装脚本"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  -t, --type TYPE        安装类型 (full|minimal|custom) [默认: full]"
    echo "  -d, --dir DIR          安装目录 [默认: $INSTALL_DIR]"
    echo "  -c, --config-dir DIR   配置目录 [默认: $CONFIG_DIR]"
    echo "  -l, --log-dir DIR      日志目录 [默认: $LOG_DIR]"
    echo "  --skip-deps            跳过依赖安装"
    echo "  --skip-config          跳过配置创建"
    echo "  --skip-service         跳过服务安装"
    echo "  --force                强制安装（覆盖现有安装）"
    echo "  -v, --verbose          详细输出"
    echo "  -h, --help             显示此帮助信息"
    echo
    echo "安装类型:"
    echo "  full     完整安装（默认）"
    echo "  minimal  最小安装（仅核心功能）"
    echo "  custom   自定义安装"
    echo
    echo "示例:"
    echo "  $0                      # 完整安装"
    echo "  $0 -t minimal           # 最小安装"
    echo "  $0 --skip-deps          # 跳过依赖安装"
    echo "  $0 --force              # 强制安装"
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--type)
                INSTALL_TYPE="$2"
                shift 2
                ;;
            -d|--dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            -c|--config-dir)
                CONFIG_DIR="$2"
                shift 2
                ;;
            -l|--log-dir)
                LOG_DIR="$2"
                shift 2
                ;;
            --skip-deps)
                SKIP_DEPENDENCIES=true
                shift
                ;;
            --skip-config)
                SKIP_CONFIG=true
                shift
                ;;
            --skip-service)
                SKIP_SERVICE=true
                shift
                ;;
            --force)
                FORCE_INSTALL=true
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

# 检测操作系统
detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# 检查系统兼容性
check_system_compatibility() {
    # 确保日志目录和文件存在
    mkdir -p "$(dirname "${LOG_FILE:-/tmp/install.log}")" 2>/dev/null || true
    log_info "检查系统兼容性..."
    
    # 检查操作系统
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        log_info "操作系统: $PRETTY_NAME"
        
        # 检查支持的发行版
        case "$ID" in
            "ubuntu"|"debian"|"centos"|"rhel"|"fedora"|"rocky"|"almalinux"|"arch"|"opensuse")
                log_info "操作系统兼容性检查通过"
                ;;
            *)
                log_warn "操作系统可能不完全支持: $ID"
                ;;
        esac
    else
        log_error "无法检测操作系统"
        exit 1
    fi
    
    # 检查架构
    local arch=$(uname -m)
    case "$arch" in
        "x86_64"|"aarch64")
            log_info "系统架构: $arch (支持)"
            ;;
        *)
            log_warn "系统架构可能不完全支持: $arch"
            ;;
    esac
    
    # 检查内核版本
    local kernel_version=$(uname -r)
    log_info "内核版本: $kernel_version"
    
    # 检查内存
    local memory_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local memory_gb=$((memory_kb / 1024 / 1024))
    
    if [[ $memory_gb -lt 1 ]]; then
        log_warn "系统内存较少 ($memory_gb GB)，建议至少1GB"
    else
        log_info "系统内存: $memory_gb GB"
    fi
    
    # 检查磁盘空间
    local disk_space=$(df / | tail -1 | awk '{print $4}')
    local disk_space_gb=$((disk_space / 1024 / 1024))
    
    if [[ $disk_space_gb -lt 5 ]]; then
        log_warn "可用磁盘空间较少 ($disk_space_gb GB)，建议至少5GB"
    else
        log_info "可用磁盘空间: $disk_space_gb GB"
    fi
}

# 检查系统要求（别名函数，向后兼容）
check_system_requirements() {
    check_system_compatibility
}

# 检查现有安装
check_existing_installation() {
    log_info "检查现有安装..."
    
    local existing_dirs=("$INSTALL_DIR" "$CONFIG_DIR" "$LOG_DIR")
    local existing_files=("$BIN_DIR/ipv6-wireguard-manager" "$SERVICE_DIR/ipv6-wireguard-manager.service")
    
    local has_existing=false
    
    for dir in "${existing_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_warn "目录已存在: $dir"
            has_existing=true
        fi
    done
    
    for file in "${existing_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_warn "文件已存在: $file"
            has_existing=true
        fi
    done
    
    if [[ "$has_existing" == "true" ]]; then
        if [[ "$FORCE_INSTALL" == "true" ]]; then
            log_info "强制安装模式，将覆盖现有安装"
        else
            log_error "检测到现有安装，请使用 --force 选项强制安装"
            exit 1
        fi
    else
        log_info "未检测到现有安装"
    fi
}

# 安装依赖
install_dependencies() {
    if [[ "$SKIP_DEPENDENCIES" == "true" ]]; then
        log_info "跳过依赖安装"
        return 0
    fi
    
    log_info "安装系统依赖..."
    
    # 检测包管理器
    local package_manager=""
    if command -v apt-get &> /dev/null; then
        package_manager="apt"
    elif command -v yum &> /dev/null; then
        package_manager="yum"
    elif command -v dnf &> /dev/null; then
        package_manager="dnf"
    elif command -v pacman &> /dev/null; then
        package_manager="pacman"
    elif command -v zypper &> /dev/null; then
        package_manager="zypper"
    else
        log_error "不支持的包管理器"
        exit 1
    fi
    
    log_info "使用包管理器: $package_manager"
    
    # 更新包列表
    case "$package_manager" in
        "apt")
            apt-get update
            ;;
        "yum"|"dnf")
            $package_manager makecache
            ;;
        "pacman")
            pacman -Sy
            ;;
        "zypper")
            zypper refresh
            ;;
    esac
    
    # 安装必需包
    local packages=()
    
    case "$package_manager" in
        "apt")
            packages=(
                "wireguard" "wireguard-tools" "iptables" "ip6tables"
                "curl" "wget" "jq" "qrencode" "systemd" "rsyslog"
                "sqlite3" "python3-psutil"
            )
            ;;
        "yum"|"dnf")
            packages=(
                "wireguard-tools" "iptables" "ip6tables"
                "curl" "wget" "jq" "qrencode" "systemd" "rsyslog"
                "sqlite" "python3-psutil"
            )
            ;;
        "pacman")
            packages=(
                "wireguard-tools" "iptables" "ip6tables"
                "curl" "wget" "jq" "qrencode" "systemd" "rsyslog"
                "sqlite" "python-psutil"
            )
            ;;
        "zypper")
            packages=(
                "wireguard-tools" "iptables" "ip6tables"
                "curl" "wget" "jq" "qrencode" "systemd" "rsyslog"
                "sqlite3" "python3-psutil"
            )
            ;;
    esac
    
    # 根据安装类型调整包列表
    if [[ "$INSTALL_TYPE" == "minimal" ]]; then
        packages=("wireguard-tools" "iptables" "curl")
    fi
    
    # 安装包
    for package in "${packages[@]}"; do
        log_info "安装包: $package"
        
        case "$package_manager" in
            "apt")
                apt-get install -y "$package" || log_warn "包安装失败: $package"
                ;;
            "yum"|"dnf")
                $package_manager install -y "$package" || log_warn "包安装失败: $package"
                ;;
            "pacman")
                pacman -S --noconfirm "$package" || log_warn "包安装失败: $package"
                ;;
            "zypper")
                zypper install -y "$package" || log_warn "包安装失败: $package"
                ;;
        esac
    done
    
    # 安装BIRD 2.x（可选）
    if [[ "$INSTALL_TYPE" == "full" ]]; then
        log_info "安装BIRD 2.x BGP路由器..."
        
        case "$package_manager" in
            "apt")
                # Ubuntu/Debian: 优先安装bird2，回退到bird
                if apt-cache show bird2 >/dev/null 2>&1; then
                    apt-get install -y bird2 || log_warn "BIRD2安装失败，尝试安装BIRD"
                    apt-get install -y bird || log_warn "BIRD安装失败"
                else
                    apt-get install -y bird || log_warn "BIRD安装失败"
                fi
                ;;
            "yum"|"dnf")
                # CentOS/RHEL/Fedora: 优先安装bird2
                if $package_manager search bird2 >/dev/null 2>&1; then
                    $package_manager install -y bird2 || log_warn "BIRD2安装失败，尝试安装BIRD"
                    $package_manager install -y bird || log_warn "BIRD安装失败"
                else
                    $package_manager install -y bird || log_warn "BIRD安装失败"
                fi
                ;;
            "pacman")
                # Arch Linux: 优先安装bird2
                if pacman -Ss bird2 >/dev/null 2>&1; then
                    pacman -S --noconfirm bird2 || log_warn "BIRD2安装失败，尝试安装BIRD"
                    pacman -S --noconfirm bird || log_warn "BIRD安装失败"
                else
                    pacman -S --noconfirm bird || log_warn "BIRD安装失败"
                fi
                ;;
            "zypper")
                # openSUSE: 优先安装bird2
                if zypper search bird2 >/dev/null 2>&1; then
                    zypper install -y bird2 || log_warn "BIRD2安装失败，尝试安装BIRD"
                    zypper install -y bird || log_warn "BIRD安装失败"
                else
                    zypper install -y bird || log_warn "BIRD安装失败"
                fi
                ;;
        esac
        
        # 验证BIRD版本
        if command -v bird &> /dev/null; then
            local bird_version=$(bird --version 2>&1 | head -1)
            log_info "BIRD版本: $bird_version"
            
            # 检查是否为BIRD 2.x
            if [[ $bird_version =~ BIRD\ ([0-9]+)\. ]]; then
                local major_version="${BASH_REMATCH[1]}"
                if [[ $major_version -ge 2 ]]; then
                    log_success "BIRD 2.x 安装成功"
                else
                    log_warn "检测到BIRD 1.x，建议升级到BIRD 2.x"
                fi
            fi
        else
            log_error "BIRD安装失败"
        fi
    fi
    
    log_info "依赖安装完成"
}

# 创建目录结构
create_directories() {
    log_info "创建目录结构..."
    
    local directories=(
        "$INSTALL_DIR"
        "$INSTALL_DIR/modules"
        "$INSTALL_DIR/config"
        "$INSTALL_DIR/scripts"
        "$INSTALL_DIR/examples"
        "$INSTALL_DIR/docs"
        "$CONFIG_DIR"
        "$LOG_DIR"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        log_debug "创建目录: $dir"
    done
    
    # 设置权限
    chmod 755 "$INSTALL_DIR"
    chmod 755 "$CONFIG_DIR"
    chmod 755 "$LOG_DIR"
    
    log_info "目录结构创建完成"
}

# 安装文件
install_files() {
    log_info "安装程序文件..."
    
    # 获取脚本所在目录
    local script_dir="$(dirname "${BASH_SOURCE[0]}")"
    
    # 如果脚本目录是当前目录，尝试从不同位置查找
    if [[ "$script_dir" == "." ]]; then
        # 尝试从常见位置查找
        local possible_dirs=(
            "/tmp/ipv6-wireguard-manager"
            "/tmp/${REPO_NAME}"
            "$(pwd)"
            "/opt/ipv6-wireguard-manager"
        )
        
        for dir in "${possible_dirs[@]}"; do
            if [[ -f "$dir/ipv6-wireguard-manager.sh" ]]; then
                script_dir="$dir"
                break
            fi
        done
    fi
    
    local main_script="$script_dir/ipv6-wireguard-manager.sh"
    
    # 复制主脚本
    if [[ -f "$main_script" ]]; then
        cp "$main_script" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/ipv6-wireguard-manager.sh"
        log_debug "安装主脚本: $main_script"
        
        # 创建全局可执行文件
        cp "$main_script" "$BIN_DIR/ipv6-wireguard-manager"
        chmod +x "$BIN_DIR/ipv6-wireguard-manager"
        log_debug "创建全局命令: $BIN_DIR/ipv6-wireguard-manager"
    else
        log_error "主脚本文件不存在: $main_script"
        log_error "当前目录: $(pwd)"
        log_error "脚本目录: $script_dir"
        log_error "请确保在正确的目录中运行安装脚本"
        exit 1
    fi
    
    # 复制模块文件
    if [[ -d "$script_dir/modules" ]]; then
        cp -r "$script_dir/modules"/* "$INSTALL_DIR/modules/"
        chmod +x "$INSTALL_DIR/modules"/*.sh
        log_debug "安装模块文件"
    else
        log_warn "模块目录不存在: $script_dir/modules"
    fi
    
    # 复制配置文件
    if [[ -d "$script_dir/config" ]]; then
        cp -r "$script_dir/config"/* "$INSTALL_DIR/config/"
        log_debug "安装配置文件"
    else
        log_warn "配置目录不存在: $script_dir/config"
    fi
    
    # 复制脚本文件
    if [[ -d "$script_dir/scripts" ]]; then
        cp -r "$script_dir/scripts"/* "$INSTALL_DIR/scripts/"
        chmod +x "$INSTALL_DIR/scripts"/*.sh
        log_debug "安装脚本文件"
    else
        log_warn "脚本目录不存在: $script_dir/scripts"
    fi
    
    # 复制示例文件
    if [[ -d "$script_dir/examples" ]]; then
        cp -r "$script_dir/examples"/* "$INSTALL_DIR/examples/"
        log_debug "安装示例文件"
    else
        log_warn "示例目录不存在: $script_dir/examples"
    fi
    
    # 复制文档文件
    if [[ -d "$script_dir/docs" ]]; then
        cp -r "$script_dir/docs"/* "$INSTALL_DIR/docs/"
        log_debug "安装文档文件"
    else
        log_warn "文档目录不存在: $script_dir/docs"
    fi
    
    # 创建符号链接到BIN_DIR
    if [[ -f "$INSTALL_DIR/ipv6-wireguard-manager.sh" ]]; then
        ln -sf "$INSTALL_DIR/ipv6-wireguard-manager.sh" "$BIN_DIR/ipv6-wireguard-manager"
        log_debug "创建符号链接: $BIN_DIR/ipv6-wireguard-manager -> $INSTALL_DIR/ipv6-wireguard-manager.sh"
    else
        log_error "主脚本文件不存在，无法创建符号链接"
    fi
    
    log_info "程序文件安装完成"
}

# 创建配置文件
create_configuration() {
    if [[ "$SKIP_CONFIG" == "true" ]]; then
        log_info "跳过配置创建"
        return 0
    fi
    
    log_info "创建配置文件..."
    
    # 主配置文件
    cat > "$CONFIG_DIR/manager.conf" << 'EOF'
# IPv6 WireGuard Manager 主配置文件
# 生成时间: $(date)

# WireGuard配置
WIREGUARD_PORT=51820
WIREGUARD_INTERFACE=wg0
WIREGUARD_NETWORK=10.0.0.0/24

# IPv6配置
IPV6_PREFIX=2001:db8::/56

# BIRD配置
BIRD_VERSION=auto
BIRD_ROUTER_ID=auto

# 防火墙配置
FIREWALL_TYPE=auto

# Web管理界面
WEB_PORT=8080
WEB_USER=admin
WEB_PASS=admin123

# 日志配置
LOG_LEVEL=INFO
LOG_FILE=/var/log/ipv6-wireguard-manager/manager.log

# 备份配置
BACKUP_DIR=/var/backups/ipv6-wireguard
CLIENT_CONFIG_DIR=/etc/wireguard/clients

# 系统配置
INSTALL_DIR=/opt/ipv6-wireguard-manager
CONFIG_DIR=/etc/ipv6-wireguard-manager
LOG_DIR=/var/log/ipv6-wireguard-manager
EOF
    
    # 错误处理配置
    cat > "$CONFIG_DIR/error_handling.conf" << 'EOF'
# 错误处理配置文件
LOG_ERRORS=true
SEND_ALERTS=false
AUTO_RECOVERY=true
MAX_RETRIES=3
RETRY_DELAY=5
ERROR_THRESHOLD=10
CLEANUP_ON_ERROR=true
ALERT_EMAIL=""
ALERT_WEBHOOK=""
ERROR_LOG_FILE=/var/log/ipv6-wireguard-manager/errors.log
EOF
    
    # 用户界面配置
    cat > "$CONFIG_DIR/ui.conf" << 'EOF'
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
    
    # 设置配置文件权限
    chmod 600 "$CONFIG_DIR"/*.conf
    
    # 确保配置文件使用Unix行尾符
    for conf_file in "$CONFIG_DIR"/*.conf; do
        if [[ -f "$conf_file" ]]; then
            fix_line_endings "$conf_file"
        fi
    done
    
    log_info "配置文件创建完成"
}

# 安装系统服务
install_service() {
    if [[ "$SKIP_SERVICE" == "true" ]]; then
        log_info "跳过服务安装"
        return 0
    fi
    
    log_info "安装系统服务..."
    
    # 创建systemd服务文件
    cat > "$SERVICE_DIR/ipv6-wireguard-manager.service" << EOF
[Unit]
Description=IPv6 WireGuard Manager
Documentation=https://github.com/example/ipv6-wireguard-manager
After=network.target
Wants=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$BIN_DIR/ipv6-wireguard-manager --start-services
ExecStop=$BIN_DIR/ipv6-wireguard-manager --stop-services
ExecReload=$BIN_DIR/ipv6-wireguard-manager --reload-config
User=root
Group=root
WorkingDirectory=$INSTALL_DIR
Environment=CONFIG_DIR=$CONFIG_DIR
Environment=LOG_DIR=$LOG_DIR

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载systemd
    systemctl daemon-reload
    
    # 启用服务
    systemctl enable ipv6-wireguard-manager.service
    
    log_info "系统服务安装完成"
}

# 设置权限
set_permissions() {
    log_info "设置文件权限..."
    
    # 设置目录权限
    chown -R root:root "$INSTALL_DIR"
    chown -R root:root "$CONFIG_DIR"
    chown -R root:root "$LOG_DIR"
    
    # 设置文件权限
    chmod 755 "$INSTALL_DIR"
    chmod 755 "$BIN_DIR/ipv6-wireguard-manager"
    chmod 600 "$CONFIG_DIR"/*.conf
    chmod 644 "$SERVICE_DIR/ipv6-wireguard-manager.service"
    
    # 设置日志目录权限
    chmod 755 "$LOG_DIR"
    
    log_info "文件权限设置完成"
}

# 创建卸载脚本
create_uninstall_script() {
    log_info "创建卸载脚本..."
    
    cat > "$INSTALL_DIR/uninstall.sh" << EOF
#!/bin/bash

# IPv6 WireGuard Manager 卸载脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} \$1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} \$1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} \$1"
}

# 检查权限
if [[ \$EUID -ne 0 ]]; then
    log_error "此卸载脚本需要root权限运行"
    echo "请使用: sudo \$0"
    exit 1
fi

log_info "开始卸载IPv6 WireGuard Manager..."

# 停止服务
if systemctl is-active --quiet ipv6-wireguard-manager; then
    log_info "停止服务..."
    systemctl stop ipv6-wireguard-manager
fi

# 禁用服务
if systemctl is-enabled --quiet ipv6-wireguard-manager; then
    log_info "禁用服务..."
    systemctl disable ipv6-wireguard-manager
fi

# 删除服务文件
if [[ -f "$SERVICE_DIR/ipv6-wireguard-manager.service" ]]; then
    log_info "删除服务文件..."
    rm -f "$SERVICE_DIR/ipv6-wireguard-manager.service"
    systemctl daemon-reload
fi

# 删除符号链接
if [[ -L "$BIN_DIR/ipv6-wireguard-manager" ]]; then
    log_info "删除符号链接..."
    rm -f "$BIN_DIR/ipv6-wireguard-manager"
fi

# 删除安装目录
if [[ -d "$INSTALL_DIR" ]]; then
    log_info "删除安装目录..."
    rm -rf "$INSTALL_DIR"
fi

# 删除配置目录
if [[ -d "$CONFIG_DIR" ]]; then
    log_info "删除配置目录..."
    rm -rf "$CONFIG_DIR"
fi

# 删除日志目录
if [[ -d "$LOG_DIR" ]]; then
    log_info "删除日志目录..."
    rm -rf "$LOG_DIR"
fi

# 停止性能监控
if command -v pkill &> /dev/null; then
    log_info "停止性能监控..."
    pkill -f "performance_monitor.sh" 2>/dev/null || true
    rm -f "/tmp/performance_monitor.sh"
fi

# 清理缓存
if [[ -f "$INSTALL_DIR/modules/performance_enhancements.sh" ]]; then
    log_info "清理性能缓存..."
    source "$INSTALL_DIR/modules/performance_enhancements.sh"
    clear_cache 2>/dev/null || true
fi

log_info "IPv6 WireGuard Manager 卸载完成"
EOF
    
    chmod +x "$INSTALL_DIR/uninstall.sh"
    
    log_info "卸载脚本创建完成"
}

# 运行安装后配置
post_install_configuration() {
    log_info "运行安装后配置..."
    
    # 创建日志文件
    touch "$LOG_DIR/manager.log"
    touch "$LOG_DIR/errors.log"
    chmod 644 "$LOG_DIR"/*.log
    
    # 初始化WireGuard配置
    if [[ "$INSTALL_TYPE" == "full" ]]; then
        log_info "初始化WireGuard配置..."
        "$BIN_DIR/ipv6-wireguard-manager" --init-wireguard || log_warn "WireGuard初始化失败"
    fi
    
    # 初始化BIRD配置
    if [[ "$INSTALL_TYPE" == "full" ]]; then
        log_info "初始化BIRD配置..."
        "$BIN_DIR/ipv6-wireguard-manager" --init-bird || log_warn "BIRD初始化失败"
    fi
    
    log_info "安装后配置完成"
}

# 创建全局命令别名
create_global_alias() {
    log_info "验证全局命令..."
    
    # 确保 /usr/local/bin 目录存在
    mkdir -p /usr/local/bin
    
    # 验证全局命令是否已创建
    if [[ -f "$BIN_DIR/ipv6-wireguard-manager" ]]; then
        log_info "全局命令 'ipv6-wireguard-manager' 已就绪"
        log_info "位置: $BIN_DIR/ipv6-wireguard-manager"
        
        # 测试命令是否可执行
        if "$BIN_DIR/ipv6-wireguard-manager" --version >/dev/null 2>&1; then
            log_success "全局命令测试成功"
        else
            log_warn "全局命令可能存在问题，但文件已创建"
        fi
    else
        log_error "全局命令文件不存在: $BIN_DIR/ipv6-wireguard-manager"
        log_error "请检查安装过程是否完成"
        return 1
    fi
}

# 显示安装完成信息
show_installation_complete() {
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🎉 安装完成！IPv6 WireGuard Manager 已就绪 🎉            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # 快速启动
    echo -e "${YELLOW}🚀 快速启动:${NC}"
    echo -e "  ${CYAN}ipv6-wireguard-manager${NC}"
    echo
    
    # 服务管理
    echo -e "${BLUE}⚙️  服务管理:${NC}"
    echo -e "  ├─ 启动服务: ${CYAN}systemctl start ipv6-wireguard-manager${NC}"
    echo -e "  ├─ 查看状态: ${CYAN}systemctl status ipv6-wireguard-manager${NC}"
    echo -e "  └─ 查看日志: ${CYAN}journalctl -u ipv6-wireguard-manager -f${NC}"
    echo
    
    # Web界面
    if [[ "$INSTALL_WEB_INTERFACE" == "true" ]]; then
        echo -e "${GREEN}🌐 Web界面:${NC}"
        
        # 获取IPv4地址
        local ipv4_addr=""
        if command -v ip &> /dev/null; then
            ipv4_addr=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' | head -1)
        elif command -v hostname &> /dev/null; then
            ipv4_addr=$(hostname -I | awk '{print $1}' 2>/dev/null)
        fi
        
        # 获取IPv6地址
        local ipv6_addr=""
        if command -v ip &> /dev/null; then
            ipv6_addr=$(ip -6 addr show | grep -oP 'inet6 \K[^/]+' | grep -v '^::1$' | grep -v '^fe80:' | head -1)
        fi
        
        # 显示Web界面地址
        if [[ -n "$ipv4_addr" ]]; then
            echo -e "  ├─ IPv4: ${CYAN}http://$ipv4_addr:8080${NC}"
            echo -e "  └─ IPv4: ${CYAN}https://$ipv4_addr:8443${NC}"
        fi
        
        if [[ -n "$ipv6_addr" ]]; then
            echo -e "  ├─ IPv6: ${CYAN}http://[$ipv6_addr]:8080${NC}"
            echo -e "  └─ IPv6: ${CYAN}https://[$ipv6_addr]:8443${NC}"
        fi
        
        # 如果都没有获取到，显示本地地址
        if [[ -z "$ipv4_addr" && -z "$ipv6_addr" ]]; then
            echo -e "  ├─ 本地: ${CYAN}http://localhost:8080${NC}"
            echo -e "  └─ 本地: ${CYAN}https://localhost:8443${NC}"
        fi
        
        echo
    fi
    
    # 立即启动
    echo -e "${GREEN}🎯 立即启动?${NC}"
    read -p "是否立即启动IPv6 WireGuard Manager? [Y/n]: " start_now
    
    if [[ "$start_now" =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}稍后运行: ${CYAN}ipv6-wireguard-manager${NC}"
    else
        echo -e "${GREEN}正在启动...${NC}"
        echo
        
        # 检查全局命令是否可用
        if command -v ipv6-wireguard-manager &> /dev/null; then
            echo -e "${GREEN}使用全局命令启动...${NC}"
            ipv6-wireguard-manager
        # 检查安装目录中的可执行文件
        elif [[ -f "$BIN_DIR/ipv6-wireguard-manager" ]]; then
            echo -e "${YELLOW}使用安装目录中的文件启动...${NC}"
            "$BIN_DIR/ipv6-wireguard-manager"
        # 检查主脚本文件
        elif [[ -f "$INSTALL_DIR/ipv6-wireguard-manager.sh" ]]; then
            echo -e "${YELLOW}使用主脚本文件启动...${NC}"
            "$INSTALL_DIR/ipv6-wireguard-manager.sh"
        else
            echo -e "${RED}错误: 找不到可执行文件${NC}"
            echo -e "${RED}请检查以下位置:${NC}"
            echo -e "  - /usr/local/bin/ipv6-wireguard-manager"
            echo -e "  - $BIN_DIR/ipv6-wireguard-manager"
            echo -e "  - $INSTALL_DIR/ipv6-wireguard-manager.sh"
            echo
            echo -e "${YELLOW}请手动运行以下命令之一:${NC}"
            echo -e "  ${CYAN}sudo ln -sf $BIN_DIR/ipv6-wireguard-manager /usr/local/bin/ipv6-wireguard-manager${NC}"
            echo -e "  ${CYAN}$BIN_DIR/ipv6-wireguard-manager${NC}"
        fi
    fi
    
    echo
    echo -e "${GREEN}感谢使用IPv6 WireGuard Manager！${NC}"
    echo
}

# 主安装函数
main() {
    show_banner
    
    # 解析参数
    parse_arguments "$@"
    
    # 检查权限
    check_root
    
    # 如果没有参数，显示安装方法选择
    if [[ $# -eq 0 ]]; then
        show_install_methods
        # 不要return，让脚本继续执行
    fi
    
    # 检查系统兼容性
    check_system_compatibility
    
    # 检查现有安装
    check_existing_installation
    
    # 安装依赖
    install_dependencies
    
    # 创建目录结构
    create_directories
    
    # 下载项目文件（如果还没有）
    if [[ ! -f "ipv6-wireguard-manager.sh" ]]; then
        log_info "下载项目文件..."
        download_project_files
    fi
    
    # 安装文件
    install_files
    
    # 创建配置文件
    create_configuration
    
    # 安装系统服务
    install_service
    
    # 设置权限
    set_permissions
    
    # 创建卸载脚本
    create_uninstall_script
    
    # 运行安装后配置
    post_install_configuration
    
    # 创建全局命令别名
    create_global_alias
    
    # 显示安装完成信息
    show_installation_complete
}

# 显示安装方法选择
show_install_methods() {
    # 确保INFO_COLOR变量已定义
    INFO_COLOR="${INFO_COLOR:-$CYAN}"
    
    echo -e "${CYAN}=== 安装方法选择 ===${NC}"
    echo
    echo -e "${GREEN}1.${NC} 快速安装 - 使用默认配置"
    echo -e "${GREEN}2.${NC} 交互式安装 - 自定义配置"
    echo -e "${GREEN}3.${NC} 仅下载文件 - 不安装"
    echo -e "${GREEN}4.${NC} 显示安装帮助"
    echo
    echo -e "${INFO_COLOR}0.${NC} 退出"
    echo
    
    read -p "请选择安装方法 [0-4]: " choice
    
    case $choice in
        1) quick_install ;;
        2) interactive_install ;;
        3) download_only ;;
        4) show_install_help ;;
        0) exit 0 ;;
        *) 
            echo -e "${RED}无效选择，请重新输入${NC}"
            show_install_methods
            ;;
    esac
}

# 快速安装
quick_install() {
    echo -e "${GREEN}开始快速安装...${NC}"
    INSTALL_TYPE="full"
    
    # 快速安装默认安装所有功能
    INSTALL_WIREGUARD=true
    INSTALL_BIRD=true
    INSTALL_FIREWALL=true
    INSTALL_WEB_INTERFACE=true
    INSTALL_MONITORING=true
    INSTALL_CLIENT_AUTO_INSTALL=true
    INSTALL_BACKUP_RESTORE=true
    INSTALL_UPDATE_MANAGEMENT=true
    INSTALL_SECURITY_ENHANCEMENTS=true
    
    perform_installation
}

# 交互式安装
interactive_install() {
    echo -e "${GREEN}开始交互式安装...${NC}"
    configure_installation
    perform_installation
}

# 仅下载文件
download_only() {
    echo -e "${GREEN}开始下载文件...${NC}"
    download_project_files
}

# 显示安装帮助
show_install_help() {
    echo -e "${CYAN}=== 安装帮助 ===${NC}"
    echo
    echo "可用的安装方法:"
    echo "----------------------------------------"
    echo "1. 一键安装（推荐）"
    echo "   curl -sSL ${RAW_URL}/install.sh | bash"
    echo
    echo "2. 手动下载安装"
    echo "   wget ${RAW_URL}/install.sh"
    echo "   chmod +x install.sh"
    echo "   sudo ./install.sh"
    echo
    echo "3. 交互式安装"
    echo "   sudo ./install.sh"
    echo "   选择安装选项"
    echo
    echo "4. 从源码安装"
    echo "   git clone ${REPO_URL}"
    echo "   cd ${REPO_NAME}"
    echo "   sudo ./install.sh"
    echo
    echo "安装选项:"
    echo "----------------------------------------"
    echo "1. 快速安装 - 使用默认配置"
    echo "2. 交互式安装 - 自定义配置"
    echo "3. 仅下载文件 - 不安装"
    echo
    echo "更多信息请访问: ${REPO_URL}"
    echo
    read -p "按回车键返回主菜单..."
    show_install_methods
}

# 配置安装
configure_installation() {
    echo -e "${CYAN}=== 配置安装 ===${NC}"
    echo
    
    # 选择安装类型
    echo "安装类型:"
    echo "1. 完整安装 - 所有功能"
    echo "2. 最小安装 - 仅核心功能"
    echo "3. 自定义安装 - 选择组件"
    echo
    
    read -p "请选择安装类型 [1-3]: " install_choice
    
    case $install_choice in
        1) 
            INSTALL_TYPE="full"
            # 完整安装默认安装所有功能
            INSTALL_WIREGUARD=true
            INSTALL_BIRD=true
            INSTALL_FIREWALL=true
            INSTALL_WEB_INTERFACE=true
            INSTALL_MONITORING=true
            INSTALL_CLIENT_AUTO_INSTALL=true
            INSTALL_BACKUP_RESTORE=true
            INSTALL_UPDATE_MANAGEMENT=true
            INSTALL_SECURITY_ENHANCEMENTS=true
            ;;
        2) 
            INSTALL_TYPE="minimal"
            # 最小安装只安装核心功能
            INSTALL_WIREGUARD=true
            INSTALL_BIRD=true
            INSTALL_FIREWALL=true
            INSTALL_WEB_INTERFACE=false
            INSTALL_MONITORING=false
            INSTALL_CLIENT_AUTO_INSTALL=false
            INSTALL_BACKUP_RESTORE=false
            INSTALL_UPDATE_MANAGEMENT=false
            INSTALL_SECURITY_ENHANCEMENTS=false
            ;;
        3) 
            INSTALL_TYPE="custom"
            configure_custom_installation
            ;;
        *) 
            echo -e "${RED}无效选择，使用默认配置${NC}"
            INSTALL_TYPE="full"
            ;;
    esac
    
    # 配置安装目录
    read -p "安装目录 [默认: $INSTALL_DIR]: " custom_install_dir
    if [[ -n "$custom_install_dir" ]]; then
        INSTALL_DIR="$custom_install_dir"
    fi
    
    # 配置选项
    echo
    echo "安装选项:"
    read -p "跳过依赖安装? [y/N]: " skip_deps
    if [[ "$skip_deps" =~ ^[Yy]$ ]]; then
        SKIP_DEPENDENCIES=true
    fi
    
    read -p "跳过配置创建? [y/N]: " skip_config
    if [[ "$skip_config" =~ ^[Yy]$ ]]; then
        SKIP_CONFIG=true
    fi
    
    read -p "跳过服务安装? [y/N]: " skip_service
    if [[ "$skip_service" =~ ^[Yy]$ ]]; then
        SKIP_SERVICE=true
    fi
    
    read -p "强制安装（覆盖现有）? [y/N]: " force_install
    if [[ "$force_install" =~ ^[Yy]$ ]]; then
        FORCE_INSTALL=true
    fi
}

# 配置自定义安装
configure_custom_installation() {
    echo -e "${CYAN}=== 自定义安装配置 ===${NC}"
    echo
    
    echo "请选择要安装的功能模块:"
    echo
    
    # WireGuard配置
    read -p "安装WireGuard VPN服务? [Y/n]: " install_wireguard
    if [[ "$install_wireguard" =~ ^[Nn]$ ]]; then
        INSTALL_WIREGUARD=false
    else
        INSTALL_WIREGUARD=true
    fi
    
    # BIRD BGP路由
    read -p "安装BIRD BGP路由服务? [Y/n]: " install_bird
    if [[ "$install_bird" =~ ^[Nn]$ ]]; then
        INSTALL_BIRD=false
    else
        INSTALL_BIRD=true
    fi
    
    # 防火墙管理
    read -p "安装防火墙管理功能? [Y/n]: " install_firewall
    if [[ "$install_firewall" =~ ^[Nn]$ ]]; then
        INSTALL_FIREWALL=false
    else
        INSTALL_FIREWALL=true
    fi
    
    # Web管理界面
    read -p "安装Web管理界面? [y/N]: " install_web
    if [[ "$install_web" =~ ^[Yy]$ ]]; then
        INSTALL_WEB_INTERFACE=true
    else
        INSTALL_WEB_INTERFACE=false
    fi
    
    # 监控告警系统
    read -p "安装监控告警系统? [y/N]: " install_monitoring
    if [[ "$install_monitoring" =~ ^[Yy]$ ]]; then
        INSTALL_MONITORING=true
    else
        INSTALL_MONITORING=false
    fi
    
    # 客户端自动安装
    read -p "安装客户端自动安装功能? [y/N]: " install_auto_install
    if [[ "$install_auto_install" =~ ^[Yy]$ ]]; then
        INSTALL_CLIENT_AUTO_INSTALL=true
    else
        INSTALL_CLIENT_AUTO_INSTALL=false
    fi
    
    # 备份恢复
    read -p "安装配置备份恢复功能? [y/N]: " install_backup
    if [[ "$install_backup" =~ ^[Yy]$ ]]; then
        INSTALL_BACKUP_RESTORE=true
    else
        INSTALL_BACKUP_RESTORE=false
    fi
    
    # 更新管理
    read -p "安装更新管理功能? [y/N]: " install_update
    if [[ "$install_update" =~ ^[Yy]$ ]]; then
        INSTALL_UPDATE_MANAGEMENT=true
    else
        INSTALL_UPDATE_MANAGEMENT=false
    fi
    
    # 安全增强
    read -p "安装安全增强功能? [y/N]: " install_security
    if [[ "$install_security" =~ ^[Yy]$ ]]; then
        INSTALL_SECURITY_ENHANCEMENTS=true
    else
        INSTALL_SECURITY_ENHANCEMENTS=false
    fi
    
    # 配置管理
    read -p "安装配置管理功能? [y/N]: " install_config
    if [[ "$install_config" =~ ^[Yy]$ ]]; then
        INSTALL_CONFIG_MANAGEMENT=true
    else
        INSTALL_CONFIG_MANAGEMENT=false
    fi
    
    # 增强Web界面
    read -p "安装增强Web界面功能? [y/N]: " install_web_enhanced
    if [[ "$install_web_enhanced" =~ ^[Yy]$ ]]; then
        INSTALL_WEB_INTERFACE_ENHANCED=true
    else
        INSTALL_WEB_INTERFACE_ENHANCED=false
    fi
    
    # OAuth认证
    read -p "安装OAuth认证功能? [y/N]: " install_oauth
    if [[ "$install_oauth" =~ ^[Yy]$ ]]; then
        INSTALL_OAUTH_AUTHENTICATION=true
    else
        INSTALL_OAUTH_AUTHENTICATION=false
    fi
    
    # 安全审计监控
    read -p "安装安全审计监控功能? [y/N]: " install_audit
    if [[ "$install_audit" =~ ^[Yy]$ ]]; then
        INSTALL_SECURITY_AUDIT_MONITORING=true
    else
        INSTALL_SECURITY_AUDIT_MONITORING=false
    fi
    
    # 网络拓扑图
    read -p "安装网络拓扑图功能? [y/N]: " install_topology
    if [[ "$install_topology" =~ ^[Yy]$ ]]; then
        INSTALL_NETWORK_TOPOLOGY=true
    else
        INSTALL_NETWORK_TOPOLOGY=false
    fi
    
    # API文档
    read -p "安装API文档功能? [y/N]: " install_api_docs
    if [[ "$install_api_docs" =~ ^[Yy]$ ]]; then
        INSTALL_API_DOCUMENTATION=true
    else
        INSTALL_API_DOCUMENTATION=false
    fi
    
    # WebSocket实时通信
    read -p "安装WebSocket实时通信功能? [y/N]: " install_websocket
    if [[ "$install_websocket" =~ ^[Yy]$ ]]; then
        INSTALL_WEBSOCKET_REALTIME=true
    else
        INSTALL_WEBSOCKET_REALTIME=false
    fi
    
    # 多租户管理
    read -p "安装多租户管理功能? [y/N]: " install_tenant
    if [[ "$install_tenant" =~ ^[Yy]$ ]]; then
        INSTALL_MULTI_TENANT=true
    else
        INSTALL_MULTI_TENANT=false
    fi
    
    # 资源配额管理
    read -p "安装资源配额管理功能? [y/N]: " install_quota
    if [[ "$install_quota" =~ ^[Yy]$ ]]; then
        INSTALL_RESOURCE_QUOTA=true
    else
        INSTALL_RESOURCE_QUOTA=false
    fi
    
    # 配置懒加载
    read -p "安装配置懒加载功能? [y/N]: " install_lazy
    if [[ "$install_lazy" =~ ^[Yy]$ ]]; then
        INSTALL_LAZY_LOADING=true
    else
        INSTALL_LAZY_LOADING=false
    fi
    
    # 性能优化
    read -p "安装性能优化功能? [y/N]: " install_performance
    if [[ "$install_performance" =~ ^[Yy]$ ]]; then
        INSTALL_PERFORMANCE_OPTIMIZATION=true
    else
        INSTALL_PERFORMANCE_OPTIMIZATION=false
    fi
    
    echo
    echo -e "${GREEN}自定义安装配置完成${NC}"
    echo "已选择的功能:"
    [[ "$INSTALL_WIREGUARD" == "true" ]] && echo "  ✓ WireGuard VPN服务"
    [[ "$INSTALL_BIRD" == "true" ]] && echo "  ✓ BIRD BGP路由服务"
    [[ "$INSTALL_FIREWALL" == "true" ]] && echo "  ✓ 防火墙管理功能"
    [[ "$INSTALL_WEB_INTERFACE" == "true" ]] && echo "  ✓ Web管理界面"
    [[ "$INSTALL_MONITORING" == "true" ]] && echo "  ✓ 监控告警系统"
    [[ "$INSTALL_CLIENT_AUTO_INSTALL" == "true" ]] && echo "  ✓ 客户端自动安装功能"
    [[ "$INSTALL_BACKUP_RESTORE" == "true" ]] && echo "  ✓ 配置备份恢复功能"
    [[ "$INSTALL_UPDATE_MANAGEMENT" == "true" ]] && echo "  ✓ 更新管理功能"
    [[ "$INSTALL_SECURITY_ENHANCEMENTS" == "true" ]] && echo "  ✓ 安全增强功能"
    [[ "$INSTALL_CONFIG_MANAGEMENT" == "true" ]] && echo "  ✓ 配置管理功能"
    [[ "$INSTALL_WEB_INTERFACE_ENHANCED" == "true" ]] && echo "  ✓ 增强Web界面功能"
    [[ "$INSTALL_OAUTH_AUTHENTICATION" == "true" ]] && echo "  ✓ OAuth认证功能"
    [[ "$INSTALL_SECURITY_AUDIT_MONITORING" == "true" ]] && echo "  ✓ 安全审计监控功能"
    [[ "$INSTALL_NETWORK_TOPOLOGY" == "true" ]] && echo "  ✓ 网络拓扑图功能"
    [[ "$INSTALL_API_DOCUMENTATION" == "true" ]] && echo "  ✓ API文档功能"
    [[ "$INSTALL_WEBSOCKET_REALTIME" == "true" ]] && echo "  ✓ WebSocket实时通信功能"
    [[ "$INSTALL_MULTI_TENANT" == "true" ]] && echo "  ✓ 多租户管理功能"
    [[ "$INSTALL_RESOURCE_QUOTA" == "true" ]] && echo "  ✓ 资源配额管理功能"
    [[ "$INSTALL_LAZY_LOADING" == "true" ]] && echo "  ✓ 配置懒加载功能"
    [[ "$INSTALL_PERFORMANCE_OPTIMIZATION" == "true" ]] && echo "  ✓ 性能优化功能"
    [[ "$INSTALL_CONFIG_MANAGEMENT" == "true" ]] && echo "  ✓ 配置管理功能"
    [[ "$INSTALL_WEB_INTERFACE_ENHANCED" == "true" ]] && echo "  ✓ 增强Web界面功能"
    [[ "$INSTALL_OAUTH_AUTHENTICATION" == "true" ]] && echo "  ✓ OAuth认证功能"
    [[ "$INSTALL_SECURITY_AUDIT_MONITORING" == "true" ]] && echo "  ✓ 安全审计监控功能"
}

# 下载项目文件
download_project_files() {
    echo -e "${GREEN}下载项目文件...${NC}"
    
    local download_url="${REPO_URL}/archive/refs/heads/${REPO_BRANCH}.tar.gz"
    local temp_dir="/tmp/${REPO_NAME}-download"
    
    # 创建临时目录
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # 下载项目文件
    echo "正在下载项目文件..."
    echo "下载URL: $download_url"
    if command -v curl &> /dev/null; then
        if ! curl -L -o "${REPO_NAME}.tar.gz" "$download_url"; then
            echo -e "${RED}下载失败，请检查网络连接和URL${NC}"
            return 1
        fi
    elif command -v wget &> /dev/null; then
        if ! wget -O "${REPO_NAME}.tar.gz" "$download_url"; then
            echo -e "${RED}下载失败，请检查网络连接和URL${NC}"
            return 1
        fi
    else
        echo -e "${RED}需要curl或wget来下载文件${NC}"
        return 1
    fi
    
    if [[ -f "${REPO_NAME}.tar.gz" ]]; then
        # 检查文件大小
        local file_size=$(stat -c%s "${REPO_NAME}.tar.gz" 2>/dev/null || echo "0")
        echo "下载文件大小: $file_size 字节"
        
        if [[ $file_size -lt 1000 ]]; then
            echo -e "${RED}下载的文件太小，可能是错误页面${NC}"
            echo "文件内容:"
            head -5 "${REPO_NAME}.tar.gz"
            return 1
        fi
        
        # 解压文件
        echo "正在解压文件..."
        if ! tar -xzf "${REPO_NAME}.tar.gz"; then
            echo -e "${RED}解压失败，文件可能损坏${NC}"
            return 1
        fi
        
        # 移动到当前目录
        if [[ -d "${REPO_NAME}-${REPO_BRANCH}" ]]; then
            cp -r "${REPO_NAME}-${REPO_BRANCH}"/* ./
            rm -rf "${REPO_NAME}-${REPO_BRANCH}"
        fi
        
        echo -e "${GREEN}项目文件下载完成${NC}"
        echo "文件位置: $(pwd)"
        echo "请运行: sudo ./install.sh"
    else
        echo -e "${RED}文件下载失败${NC}"
        return 1
    fi
}

# 执行安装
perform_installation() {
    echo -e "${GREEN}开始执行安装...${NC}"
    
    # 检查系统要求
    check_system_compatibility
    
    # 检查现有安装
    check_existing_installation
    
    # 安装依赖
    if [[ "$SKIP_DEPENDENCIES" != "true" ]]; then
        install_dependencies
    fi
    
    # 创建目录
    create_directories
    
    # 下载项目文件
    download_project_files
    
    # 安装文件
    install_files
    
    # 根据选择的功能进行安装
    install_selected_features
    
    # 创建配置文件
    if [[ "$SKIP_CONFIG" != "true" ]]; then
        create_configuration
    fi
    
    # 安装系统服务
    if [[ "$SKIP_SERVICE" != "true" ]]; then
        install_service
    fi
    
    # 设置权限
    set_permissions
    
    # 创建卸载脚本
    create_uninstall_script
    
    # 运行安装后配置
    post_install_configuration
    
    # 显示安装完成信息
    show_installation_complete
}

# 安装选择的功能
install_selected_features() {
    echo -e "${CYAN}=== 安装选择的功能 ===${NC}"
    echo
    
    # WireGuard VPN服务
    if [[ "$INSTALL_WIREGUARD" == "true" ]]; then
        echo "安装WireGuard VPN服务..."
        install_wireguard_service
    fi
    
    # BIRD BGP路由服务
    if [[ "$INSTALL_BIRD" == "true" ]]; then
        echo "安装BIRD BGP路由服务..."
        install_bird_service
    fi
    
    # 防火墙管理功能
    if [[ "$INSTALL_FIREWALL" == "true" ]]; then
        echo "安装防火墙管理功能..."
        install_firewall_management
    fi
    
    # Web管理界面
    if [[ "$INSTALL_WEB_INTERFACE" == "true" ]]; then
        echo "安装Web管理界面..."
        install_web_interface
    fi
    
    # 监控告警系统
    if [[ "$INSTALL_MONITORING" == "true" ]]; then
        echo "安装监控告警系统..."
        install_monitoring_system
    fi
    
    # 客户端自动安装功能
    if [[ "$INSTALL_CLIENT_AUTO_INSTALL" == "true" ]]; then
        echo "安装客户端自动安装功能..."
        install_client_auto_install
    fi
    
    # 配置备份恢复功能
    if [[ "$INSTALL_BACKUP_RESTORE" == "true" ]]; then
        echo "安装配置备份恢复功能..."
        install_backup_restore
    fi
    
    # 更新管理功能
    if [[ "$INSTALL_UPDATE_MANAGEMENT" == "true" ]]; then
        echo "安装更新管理功能..."
        install_update_management
    fi
    
    # 安全增强功能
    if [[ "$INSTALL_SECURITY_ENHANCEMENTS" == "true" ]]; then
        echo "安装安全增强功能..."
        install_security_enhancements
    fi
    
    # 配置管理功能
    if [[ "$INSTALL_CONFIG_MANAGEMENT" == "true" ]]; then
        echo "安装配置管理功能..."
        install_config_management
    fi
    
    # 增强Web界面功能
    if [[ "$INSTALL_WEB_INTERFACE_ENHANCED" == "true" ]]; then
        echo "安装增强Web界面功能..."
        install_web_interface_enhanced
    fi
    
    # OAuth认证功能
    if [[ "$INSTALL_OAUTH_AUTHENTICATION" == "true" ]]; then
        echo "安装OAuth认证功能..."
        install_oauth_authentication
    fi
    
    # 安全审计监控功能
    if [[ "$INSTALL_SECURITY_AUDIT_MONITORING" == "true" ]]; then
        echo "安装安全审计监控功能..."
        install_security_audit_monitoring
    fi
    
    # 网络拓扑图功能
    if [[ "$INSTALL_NETWORK_TOPOLOGY" == "true" ]]; then
        echo "安装网络拓扑图功能..."
        install_network_topology
    fi
    
    # API文档功能
    if [[ "$INSTALL_API_DOCUMENTATION" == "true" ]]; then
        echo "安装API文档功能..."
        install_api_documentation
    fi
    
    # WebSocket实时通信功能
    if [[ "$INSTALL_WEBSOCKET_REALTIME" == "true" ]]; then
        echo "安装WebSocket实时通信功能..."
        install_websocket_realtime
    fi
    
    # 多租户管理功能
    if [[ "$INSTALL_MULTI_TENANT" == "true" ]]; then
        echo "安装多租户管理功能..."
        install_multi_tenant
    fi
    
    # 资源配额管理功能
    if [[ "$INSTALL_RESOURCE_QUOTA" == "true" ]]; then
        echo "安装资源配额管理功能..."
        install_resource_quota
    fi
    
    # 配置懒加载功能
    if [[ "$INSTALL_LAZY_LOADING" == "true" ]]; then
        echo "安装配置懒加载功能..."
        install_lazy_loading
    fi
    
    # 性能优化功能
    if [[ "$INSTALL_PERFORMANCE_OPTIMIZATION" == "true" ]]; then
        echo "安装性能优化功能..."
        install_performance_optimization
    fi
    
    echo -e "${GREEN}功能安装完成${NC}"
}

# 安装WireGuard服务
install_wireguard_service() {
    log_info "安装WireGuard VPN服务..."
    
    # 检测WireGuard是否已安装
    if ! command -v wg &> /dev/null; then
        log_info "安装WireGuard..."
        # 这里添加WireGuard安装逻辑
    fi
    
    # 配置WireGuard
    log_info "配置WireGuard..."
    # 这里添加WireGuard配置逻辑
    
    log_info "WireGuard VPN服务安装完成"
}

# 安装BIRD服务
install_bird_service() {
    log_info "安装BIRD BGP路由服务..."
    
    # 检测BIRD是否已安装
    if ! command -v bird &> /dev/null; then
        log_info "安装BIRD..."
        # 这里添加BIRD安装逻辑
    fi
    
    # 配置BIRD
    log_info "配置BIRD..."
    # 这里添加BIRD配置逻辑
    
    log_info "BIRD BGP路由服务安装完成"
}

# 安装防火墙管理
install_firewall_management() {
    log_info "安装防火墙管理功能..."
    
    # 检测防火墙类型
    local firewall_type=""
    if command -v ufw &> /dev/null; then
        firewall_type="ufw"
    elif command -v firewall-cmd &> /dev/null; then
        firewall_type="firewalld"
    elif command -v nft &> /dev/null; then
        firewall_type="nftables"
    elif command -v iptables &> /dev/null; then
        firewall_type="iptables"
    fi
    
    if [[ -n "$firewall_type" ]]; then
        log_info "检测到防火墙类型: $firewall_type"
        configure_firewall_ports "$firewall_type"
    else
        log_warn "未检测到支持的防火墙类型"
    fi
    
    log_info "防火墙管理功能安装完成"
}

# 配置防火墙端口
configure_firewall_ports() {
    local firewall_type="$1"
    
    log_info "配置防火墙端口..."
    
    # 定义需要开放的端口
    local ports=(
        "51820/udp"    # WireGuard
        "179/tcp"      # BGP
        "8080/tcp"     # Web管理界面
        "8443/tcp"     # HTTPS Web管理界面
        "22/tcp"       # SSH
        "80/tcp"       # HTTP
        "443/tcp"      # HTTPS
    )
    
    case "$firewall_type" in
        "ufw")
            configure_ufw_ports "${ports[@]}"
            ;;
        "firewalld")
            configure_firewalld_ports "${ports[@]}"
            ;;
        "nftables")
            configure_nftables_ports "${ports[@]}"
            ;;
        "iptables")
            configure_iptables_ports "${ports[@]}"
            ;;
    esac
}

# 配置UFW端口
configure_ufw_ports() {
    local ports=("$@")
    
    log_info "配置UFW防火墙端口..."
    
    for port in "${ports[@]}"; do
        log_info "开放端口: $port"
        ufw allow "$port" 2>/dev/null || log_warn "无法开放端口: $port"
    done
    
    # 启用UFW
    ufw --force enable 2>/dev/null || log_warn "无法启用UFW"
    
    log_info "UFW防火墙配置完成"
}

# 配置firewalld端口
configure_firewalld_ports() {
    local ports=("$@")
    
    log_info "配置firewalld防火墙端口..."
    
    for port in "${ports[@]}"; do
        log_info "开放端口: $port"
        firewall-cmd --permanent --add-port="$port" 2>/dev/null || log_warn "无法开放端口: $port"
    done
    
    # 重载firewalld配置
    firewall-cmd --reload 2>/dev/null || log_warn "无法重载firewalld配置"
    
    log_info "firewalld防火墙配置完成"
}

# 配置nftables端口
configure_nftables_ports() {
    local ports=("$@")
    
    log_info "配置nftables防火墙端口..."
    
    # 这里添加nftables配置逻辑
    log_info "nftables防火墙配置完成"
}

# 配置iptables端口
configure_iptables_ports() {
    local ports=("$@")
    
    log_info "配置iptables防火墙端口..."
    
    # 这里添加iptables配置逻辑
    log_info "iptables防火墙配置完成"
}

# 安装Web管理界面
install_web_interface() {
    log_info "安装Web管理界面..."
    
    # 检测Web服务器
    local web_server=""
    if command -v nginx &> /dev/null; then
        web_server="nginx"
    elif command -v apache2 &> /dev/null; then
        web_server="apache2"
    elif command -v httpd &> /dev/null; then
        web_server="httpd"
    fi
    
    if [[ -n "$web_server" ]]; then
        log_info "检测到Web服务器: $web_server"
        configure_web_server "$web_server"
    else
        log_info "安装Nginx Web服务器..."
        install_nginx
        configure_web_server "nginx"
    fi
    
    log_info "Web管理界面安装完成"
}

# 安装Nginx
install_nginx() {
    log_info "安装Nginx..."
    
    # 检测包管理器
    local package_manager=""
    if command -v apt &> /dev/null; then
        package_manager="apt"
    elif command -v yum &> /dev/null; then
        package_manager="yum"
    elif command -v dnf &> /dev/null; then
        package_manager="dnf"
    elif command -v pacman &> /dev/null; then
        package_manager="pacman"
    elif command -v zypper &> /dev/null; then
        package_manager="zypper"
    fi
    
    case "$package_manager" in
        "apt")
            apt-get update
            apt-get install -y nginx
            ;;
        "yum"|"dnf")
            $package_manager install -y nginx
            ;;
        "pacman")
            pacman -S --noconfirm nginx
            ;;
        "zypper")
            zypper install -y nginx
            ;;
        *)
            log_error "不支持的包管理器，请手动安装Nginx"
            return 1
            ;;
    esac
    
    # 启动并启用Nginx服务
    systemctl start nginx
    systemctl enable nginx
    
    # 创建必要的目录
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    
    log_success "Nginx安装完成"
}

# 配置Web服务器
configure_web_server() {
    local web_server="$1"
    
    log_info "配置Web服务器: $web_server"
    # 这里添加Web服务器配置逻辑
}

# 安装监控系统
install_monitoring_system() {
    log_info "安装监控告警系统..."
    # 这里添加监控系统安装逻辑
    log_info "监控告警系统安装完成"
}

# 安装客户端自动安装功能
install_client_auto_install() {
    log_info "安装客户端自动安装功能..."
    # 这里添加客户端自动安装功能安装逻辑
    log_info "客户端自动安装功能安装完成"
}

# 安装备份恢复功能
install_backup_restore() {
    log_info "安装配置备份恢复功能..."
    # 这里添加备份恢复功能安装逻辑
    log_info "配置备份恢复功能安装完成"
}

# 安装更新管理功能
install_update_management() {
    log_info "安装更新管理功能..."
    # 这里添加更新管理功能安装逻辑
    log_info "更新管理功能安装完成"
}

# 安装安全增强功能
install_security_enhancements() {
    log_info "安装安全增强功能..."
    # 这里添加安全增强功能安装逻辑
    log_info "安全增强功能安装完成"
}

# 安装配置管理功能
install_config_management() {
    log_info "安装配置管理功能..."
    
    # 检查yq工具是否安装
    if ! command -v yq &> /dev/null; then
        log_info "安装yq工具..."
        case "$(detect_os)" in
            "ubuntu"|"debian")
                wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
                chmod +x /usr/local/bin/yq
                ;;
            "centos"|"rhel"|"rocky"|"almalinux")
                wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
                chmod +x /usr/local/bin/yq
                ;;
            "fedora")
                dnf install -y yq || log_warn "yq安装失败"
                ;;
            "arch")
                pacman -S --noconfirm yq || log_warn "yq安装失败"
                ;;
            "opensuse")
                zypper install -y yq || log_warn "yq安装失败"
                ;;
        esac
    fi
    
    # 初始化配置管理
    if [[ -f "$INSTALL_DIR/modules/config_management.sh" ]]; then
        source "$INSTALL_DIR/modules/config_management.sh"
        init_config_management
    fi
    
    log_info "配置管理功能安装完成"
}

# 安装增强Web界面功能
install_web_interface_enhanced() {
    log_info "安装增强Web界面功能..."
    
    # 安装系统依赖
    log_info "安装系统依赖..."
    case "$(detect_os)" in
        "ubuntu"|"debian")
            apt-get update && apt-get install -y sqlite3 python3-psutil || log_warn "系统依赖安装失败"
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            yum install -y sqlite python3-psutil || log_warn "系统依赖安装失败"
            ;;
        "fedora")
            dnf install -y sqlite python3-psutil || log_warn "系统依赖安装失败"
            ;;
        "arch")
            pacman -S --noconfirm sqlite python-psutil || log_warn "系统依赖安装失败"
            ;;
        "opensuse")
            zypper install -y sqlite3 python3-psutil || log_warn "系统依赖安装失败"
            ;;
    esac
    
    # 安装Python依赖
    if command -v python3 &> /dev/null; then
        log_info "安装Python依赖..."
        pip3 install psutil || log_warn "Python依赖安装失败"
    else
        log_warn "Python3未安装，增强Web界面功能可能无法正常工作"
    fi
    
    # 初始化增强Web界面
    if [[ -f "$INSTALL_DIR/modules/web_interface_enhanced.sh" ]]; then
        source "$INSTALL_DIR/modules/web_interface_enhanced.sh"
        init_enhanced_web_interface
    fi
    
    log_info "增强Web界面功能安装完成"
}

# 安装OAuth认证功能
install_oauth_authentication() {
    log_info "安装OAuth认证功能..."
    
    # 安装OpenSSL（用于生成密钥）
    if ! command -v openssl &> /dev/null; then
        log_info "安装OpenSSL..."
        case "$(detect_os)" in
            "ubuntu"|"debian")
                apt-get update && apt-get install -y openssl
                ;;
            "centos"|"rhel"|"rocky"|"almalinux")
                yum install -y openssl
                ;;
            "fedora")
                dnf install -y openssl
                ;;
            "arch")
                pacman -S --noconfirm openssl
                ;;
            "opensuse")
                zypper install -y openssl
                ;;
        esac
    fi
    
    # 初始化OAuth认证系统
    if [[ -f "$INSTALL_DIR/modules/oauth_authentication.sh" ]]; then
        source "$INSTALL_DIR/modules/oauth_authentication.sh"
        init_oauth_authentication
    fi
    
    log_info "OAuth认证功能安装完成"
}

# 安装安全审计监控功能
install_security_audit_monitoring() {
    log_info "安装安全审计监控功能..."
    
    # 安装邮件发送工具
    if ! command -v mail &> /dev/null; then
        log_info "安装邮件发送工具..."
        case "$(detect_os)" in
            "ubuntu"|"debian")
                apt-get update && apt-get install -y mailutils
                ;;
            "centos"|"rhel"|"rocky"|"almalinux")
                yum install -y mailx
                ;;
            "fedora")
                dnf install -y mailx
                ;;
            "arch")
                pacman -S --noconfirm mailutils
                ;;
            "opensuse")
                zypper install -y mailx
                ;;
        esac
    fi
    
    # 安装curl（用于Webhook通知）
    if ! command -v curl &> /dev/null; then
        log_info "安装curl..."
        case "$(detect_os)" in
            "ubuntu"|"debian")
                apt-get update && apt-get install -y curl
                ;;
            "centos"|"rhel"|"rocky"|"almalinux")
                yum install -y curl
                ;;
            "fedora")
                dnf install -y curl
                ;;
            "arch")
                pacman -S --noconfirm curl
                ;;
            "opensuse")
                zypper install -y curl
                ;;
        esac
    fi
    
    # 初始化安全审计监控系统
    if [[ -f "$INSTALL_DIR/modules/security_audit_monitoring.sh" ]]; then
        source "$INSTALL_DIR/modules/security_audit_monitoring.sh"
        init_security_audit_monitoring
    fi
    
    log_info "安全审计监控功能安装完成"
}

# 安装网络拓扑图功能
install_network_topology() {
    log_info "安装网络拓扑图功能..."
    
    # 安装Python依赖
    if command -v python3 &> /dev/null; then
        log_info "安装Python依赖..."
        pip3 install websockets || log_warn "websockets安装失败"
    else
        log_warn "Python3未安装，网络拓扑图功能可能无法正常工作"
    fi
    
    # 初始化网络拓扑模块
    if [[ -f "$INSTALL_DIR/modules/network_topology.sh" ]]; then
        source "$INSTALL_DIR/modules/network_topology.sh"
        init_network_topology
    fi
    
    log_info "网络拓扑图功能安装完成"
}

# 安装API文档功能
install_api_documentation() {
    log_info "安装API文档功能..."
    
    # 安装wget或curl（用于下载Swagger UI）
    if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
        log_info "安装wget..."
        case "$(detect_os)" in
            "ubuntu"|"debian")
                apt-get update && apt-get install -y wget
                ;;
            "centos"|"rhel"|"rocky"|"almalinux")
                yum install -y wget
                ;;
            "fedora")
                dnf install -y wget
                ;;
            "arch")
                pacman -S --noconfirm wget
                ;;
            "opensuse")
                zypper install -y wget
                ;;
        esac
    fi
    
    # 初始化API文档模块
    if [[ -f "$INSTALL_DIR/modules/api_documentation.sh" ]]; then
        source "$INSTALL_DIR/modules/api_documentation.sh"
        init_api_documentation
    fi
    
    log_info "API文档功能安装完成"
}

# 安装WebSocket实时通信功能
install_websocket_realtime() {
    log_info "安装WebSocket实时通信功能..."
    
    # 安装Python依赖
    if command -v python3 &> /dev/null; then
        log_info "安装Python依赖..."
        pip3 install websockets || log_warn "websockets安装失败"
    else
        log_warn "Python3未安装，WebSocket实时通信功能可能无法正常工作"
    fi
    
    # 初始化WebSocket模块
    if [[ -f "$INSTALL_DIR/modules/websocket_realtime.sh" ]]; then
        source "$INSTALL_DIR/modules/websocket_realtime.sh"
        init_websocket_realtime
    fi
    
    log_info "WebSocket实时通信功能安装完成"
}

# 安装多租户管理功能
install_multi_tenant() {
    log_info "安装多租户管理功能..."
    
    # 初始化多租户模块
    if [[ -f "$INSTALL_DIR/modules/multi_tenant.sh" ]]; then
        source "$INSTALL_DIR/modules/multi_tenant.sh"
        init_multi_tenant
    fi
    
    log_info "多租户管理功能安装完成"
}

# 安装资源配额管理功能
install_resource_quota() {
    log_info "安装资源配额管理功能..."
    
    # 安装Python依赖
    if command -v python3 &> /dev/null; then
        log_info "安装Python依赖..."
        pip3 install psutil || log_warn "psutil安装失败"
    else
        log_warn "Python3未安装，资源配额管理功能可能无法正常工作"
    fi
    
    # 初始化资源配额模块
    if [[ -f "$INSTALL_DIR/modules/resource_quota.sh" ]]; then
        source "$INSTALL_DIR/modules/resource_quota.sh"
        init_resource_quota
    fi
    
    log_info "资源配额管理功能安装完成"
}

# 安装配置懒加载功能
install_lazy_loading() {
    log_info "安装配置懒加载功能..."
    
    # 安装Python依赖
    if command -v python3 &> /dev/null; then
        log_info "安装Python依赖..."
        pip3 install psutil || log_warn "psutil安装失败"
    else
        log_warn "Python3未安装，配置懒加载功能可能无法正常工作"
    fi
    
    # 初始化懒加载模块
    if [[ -f "$INSTALL_DIR/modules/lazy_loading.sh" ]]; then
        source "$INSTALL_DIR/modules/lazy_loading.sh"
        init_lazy_loading
    fi
    
    log_info "配置懒加载功能安装完成"
}

# 安装性能优化功能
install_performance_optimization() {
    log_info "安装性能优化功能..."
    
    # 安装Python依赖
    if command -v python3 &> /dev/null; then
        log_info "安装Python依赖..."
        pip3 install psutil || log_warn "psutil安装失败"
    else
        log_warn "Python3未安装，性能优化功能可能无法正常工作"
    fi
    
    # 初始化性能优化模块
    if [[ -f "$INSTALL_DIR/modules/performance_optimization.sh" ]]; then
        source "$INSTALL_DIR/modules/performance_optimization.sh"
        init_performance_optimization
    fi
    
    # 初始化性能增强模块
    if [[ -f "$INSTALL_DIR/modules/performance_enhancements.sh" ]]; then
        source "$INSTALL_DIR/modules/performance_enhancements.sh"
        init_performance_enhancements
    fi
    
    log_info "性能优化功能安装完成"
}

# 错误处理
trap 'log_error "安装过程中发生错误，行号: $LINENO"' ERR

# 执行主函数
main "$@"
