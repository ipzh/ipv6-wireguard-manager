#!/bin/bash

# IPv6 WireGuard Manager 独立安装脚本
# 版本: 1.13
# 此脚本会自动下载完整的项目文件

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

# 脚本信息
SCRIPT_NAME="IPv6 WireGuard Manager"
SCRIPT_VERSION="1.11"
SCRIPT_AUTHOR="IPv6 WireGuard Manager Team"
INSTALL_DIR="/opt/ipv6-wireguard-manager"
SERVICE_NAME="ipv6-wireguard-manager"

# GitHub仓库信息
GITHUB_REPO="ipzh/ipv6-wireguard-manager"
GITHUB_BRANCH="main"
GITHUB_BASE_URL="https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH"

# 临时下载目录
TEMP_DIR="/tmp/ipv6-wireguard-install-$$"

# 系统信息变量
OS_TYPE=""
OS_VERSION=""
ARCH=""

# 日志函数
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "INFO")
            echo -e "${GREEN}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "DEBUG")
            echo -e "${BLUE}[$timestamp] [$level] $message${NC}" >&2
            ;;
        *)
            echo -e "[$timestamp] [$level] $message" >&2
            ;;
    esac
}

# 错误处理函数
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# 清理临时文件
cleanup_temp_files() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log "DEBUG" "Cleaned up temporary directory: $TEMP_DIR"
    fi
}

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root"
    fi
}

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                IPv6 WireGuard Manager                      ║${NC}"
    echo -e "${WHITE}║                    独立安装程序 v$SCRIPT_VERSION                ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}欢迎使用 IPv6 WireGuard Manager!${NC}"
    echo
    echo -e "${YELLOW}此安装程序将:${NC}"
    echo -e "  • 自动下载完整的项目文件"
    echo -e "  • 检测系统环境并安装依赖"
    echo -e "  • 配置 WireGuard VPN 服务器"
    echo -e "  • 支持 IPv6 前缀分发和 BGP 路由"
    echo -e "  • 客户端配置生成和管理"
    echo -e "  • 防火墙自动配置"
    echo
    echo -e "${YELLOW}系统要求:${NC}"
    echo -e "  • 支持的操作系统: Debian, Ubuntu, CentOS, RHEL, Fedora, Rocky Linux, AlmaLinux, Arch Linux"
    echo -e "  • 需要 root 权限"
    echo -e "  • 需要公网 IPv4 地址"
    echo -e "  • 需要开放 WireGuard 端口 (默认 51820)"
    echo -e "  • 需要网络连接以下载项目文件"
    echo
}

# 检测操作系统
detect_os() {
    log "INFO" "Detecting operating system..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_TYPE="$ID"
        OS_VERSION="$VERSION_ID"
    elif [[ -f /etc/redhat-release ]]; then
        OS_TYPE="rhel"
        OS_VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+' | head -1)
    elif [[ -f /etc/debian_version ]]; then
        OS_TYPE="debian"
        OS_VERSION=$(cat /etc/debian_version)
    else
        error_exit "Unsupported operating system"
    fi
    
    ARCH=$(uname -m)
    
    log "INFO" "Detected OS: $OS_TYPE $OS_VERSION ($ARCH)"
    echo -e "${GREEN}✓${NC} 检测到操作系统: $OS_TYPE $OS_VERSION ($ARCH)"
}

# 检查系统要求
check_requirements() {
    log "INFO" "Checking system requirements..."
    
    # 检查内存
    local total_memory=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    if [[ $total_memory -lt 512 ]]; then
        log "WARN" "Low memory detected: ${total_memory}MB (recommended: 512MB+)"
    fi
    
    # 检查磁盘空间
    local available_space=$(df / | awk 'NR==2{print $4}')
    if [[ $available_space -lt 1048576 ]]; then  # 1GB in KB
        log "WARN" "Low disk space detected: ${available_space}KB (recommended: 1GB+)"
    fi
}

# 安装依赖
install_dependencies() {
    log "INFO" "Installing system dependencies..."
    
    # 首先安装基础工具
    install_basic_tools
    
    # 安装WireGuard（必需）
    install_wireguard
    
    # 安装BIRD（可选，失败不影响WireGuard）
    install_bird
    
    # 安装防火墙工具
    install_firewall_tools
    
    log "INFO" "Dependencies installation completed"
}

# 安装基础工具
install_basic_tools() {
    log "INFO" "Installing basic tools..."
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt update
            apt install -y curl wget iptables
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y epel-release
                dnf install -y curl wget iptables
            else
                yum install -y epel-release
                yum install -y curl wget iptables
            fi
            ;;
        "arch")
            pacman -S --noconfirm curl wget iptables
            ;;
        *)
            error_exit "Unsupported operating system: $OS_TYPE"
            ;;
    esac
    
    log "INFO" "Basic tools installed successfully"
}

# 安装WireGuard
install_wireguard() {
    log "INFO" "Installing WireGuard..."
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            if apt install -y wireguard wireguard-tools; then
                log "INFO" "WireGuard installed successfully"
            else
                log "ERROR" "Failed to install WireGuard"
                error_exit "WireGuard installation failed"
            fi
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                if dnf install -y wireguard-tools; then
                    log "INFO" "WireGuard installed successfully"
                else
                    log "ERROR" "Failed to install WireGuard"
                    error_exit "WireGuard installation failed"
                fi
            else
                if yum install -y wireguard-tools; then
                    log "INFO" "WireGuard installed successfully"
                else
                    log "ERROR" "Failed to install WireGuard"
                    error_exit "WireGuard installation failed"
                fi
            fi
            ;;
        "arch")
            if pacman -S --noconfirm wireguard-tools; then
                log "INFO" "WireGuard installed successfully"
            else
                log "ERROR" "Failed to install WireGuard"
                error_exit "WireGuard installation failed"
            fi
            ;;
    esac
}

# 安装BIRD
install_bird() {
    log "INFO" "Installing BIRD BGP daemon..."
    
    local bird_installed=false
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            # 优先尝试安装BIRD 2.x
            if apt install -y bird2 2>/dev/null; then
                log "INFO" "BIRD 2.x installed successfully"
                bird_installed=true
            # 如果BIRD 2.x失败，尝试BIRD 1.x
            elif apt install -y bird 2>/dev/null; then
                log "INFO" "BIRD 1.x installed successfully"
                bird_installed=true
            else
                log "WARN" "Failed to install BIRD, continuing without BGP support"
            fi
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                # 优先尝试安装BIRD 2.x
                if dnf install -y bird2 2>/dev/null; then
                    log "INFO" "BIRD 2.x installed successfully"
                    bird_installed=true
                # 如果BIRD 2.x失败，尝试BIRD 1.x
                elif dnf install -y bird 2>/dev/null; then
                    log "INFO" "BIRD 1.x installed successfully"
                    bird_installed=true
                else
                    log "WARN" "Failed to install BIRD, continuing without BGP support"
                fi
            else
                # 优先尝试安装BIRD 2.x
                if yum install -y bird2 2>/dev/null; then
                    log "INFO" "BIRD 2.x installed successfully"
                    bird_installed=true
                # 如果BIRD 2.x失败，尝试BIRD 1.x
                elif yum install -y bird 2>/dev/null; then
                    log "INFO" "BIRD 1.x installed successfully"
                    bird_installed=true
                else
                    log "WARN" "Failed to install BIRD, continuing without BGP support"
                fi
            fi
            ;;
        "arch")
            # 优先尝试安装BIRD 2.x
            if pacman -S --noconfirm bird2 2>/dev/null; then
                log "INFO" "BIRD 2.x installed successfully"
                bird_installed=true
            # 如果BIRD 2.x失败，尝试BIRD 1.x
            elif pacman -S --noconfirm bird 2>/dev/null; then
                log "INFO" "BIRD 1.x installed successfully"
                bird_installed=true
            else
                log "WARN" "Failed to install BIRD, continuing without BGP support"
            fi
            ;;
    esac
    
    if [[ "$bird_installed" == "true" ]]; then
        log "INFO" "BIRD installed successfully"
    else
        log "WARN" "BIRD not installed - BGP features will be disabled"
    fi
}

# 安装防火墙工具
install_firewall_tools() {
    log "INFO" "Installing firewall tools..."
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt install -y ufw
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y firewalld
            else
                yum install -y firewalld
            fi
            ;;
        "arch")
            pacman -S --noconfirm ufw
            ;;
    esac
    
    log "INFO" "Firewall tools installed successfully"
    
    # 检查网络连接
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        error_exit "No internet connection detected. This installer requires internet access to download project files."
    fi
    
    echo -e "${GREEN}✓${NC} 系统要求检查完成"
}

# 安装依赖
install_dependencies() {
    log "INFO" "Installing dependencies..."
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt update
            apt install -y curl wget tar gzip
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y curl wget tar gzip
            else
                yum install -y curl wget tar gzip
            fi
            ;;
        "arch")
            pacman -S --noconfirm curl wget tar gzip
            ;;
        *)
            error_exit "Unsupported operating system: $OS_TYPE"
            ;;
    esac
    
    echo -e "${GREEN}✓${NC} 依赖安装完成"
}

# 下载项目文件
download_project_files() {
    log "INFO" "Downloading project files from GitHub..."
    log "INFO" "Temporary directory: $TEMP_DIR"
    
    # 创建临时目录
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # 定义需要下载的文件列表
    local files=(
        "ipv6-wireguard-manager.sh"
        "README.md"
        "PROJECT_SUMMARY.md"
        "uninstall.sh"
    )
    
    # 下载文档文件
    log "INFO" "Downloading documentation..."
    mkdir -p "$TEMP_DIR/docs"
    local doc_files=(
        "BIRD_PERMISSIONS.md"
        "BIRD_VERSION_COMPATIBILITY.md"
        "INSTALLATION.md"
        "USAGE.md"
    )
    
    for file in "${doc_files[@]}"; do
        if ! curl -s -L -o "$TEMP_DIR/docs/$file" "$GITHUB_BASE_URL/docs/$file"; then
            log "WARN" "Failed to download docs/$file"
        else
            log "INFO" "Successfully downloaded docs/$file"
        fi
    done
    
    # 下载示例文件
    log "INFO" "Downloading examples..."
    mkdir -p "$TEMP_DIR/examples"
    local example_files=(
        "bgp_neighbors.conf"
        "clients.csv"
        "ipv6_prefixes.conf"
        "quick_batch_example.sh"
    )
    
    for file in "${example_files[@]}"; do
        if ! curl -s -L -o "$TEMP_DIR/examples/$file" "$GITHUB_BASE_URL/examples/$file"; then
            log "WARN" "Failed to download examples/$file"
        else
            log "INFO" "Successfully downloaded examples/$file"
        fi
    done
    
    # 下载单个文件
    for file in "${files[@]}"; do
        log "INFO" "Downloading $file..."
        if ! curl -s -L -o "$TEMP_DIR/$file" "$GITHUB_BASE_URL/$file"; then
            log "WARN" "Failed to download $file, will create a basic version"
        else
            log "INFO" "Successfully downloaded $file"
        fi
    done
    
    # 下载模块文件
    log "INFO" "Downloading modules..."
    mkdir -p "$TEMP_DIR/modules"
    local module_files=(
        "system_detection.sh"
        "wireguard_config.sh"
        "bird_config.sh"
        "firewall_config.sh"
        "client_management.sh"
        "server_management.sh"
        "network_management.sh"
        "firewall_management.sh"
        "system_maintenance.sh"
        "backup_restore.sh"
        "update_management.sh"
        "wireguard_diagnostics.sh"
        "client_script_generator.sh"
        "client_auto_update.sh"
    )
    
    for file in "${module_files[@]}"; do
        if ! curl -s -L -o "$TEMP_DIR/modules/$file" "$GITHUB_BASE_URL/modules/$file"; then
            log "WARN" "Failed to download modules/$file"
        else
            log "INFO" "Successfully downloaded modules/$file"
        fi
    done
    
    # 下载配置文件
    log "INFO" "Downloading config files..."
    mkdir -p "$TEMP_DIR/config"
    local config_files=(
        "manager.conf"
        "client_template.conf"
        "bird_template.conf"
        "bird_v2_template.conf"
        "bird_v3_template.conf"
        "firewall_rules.conf"
    )
    
    for file in "${config_files[@]}"; do
        if ! curl -s -L -o "$TEMP_DIR/config/$file" "$GITHUB_BASE_URL/config/$file"; then
            log "WARN" "Failed to download config/$file"
        else
            log "INFO" "Successfully downloaded config/$file"
        fi
    done
    
    # 下载脚本文件
    log "INFO" "Downloading scripts..."
    mkdir -p "$TEMP_DIR/scripts"
    local script_files=(
        "update.sh"
        "check_bird_permissions.sh"
        "check_bird_version.sh"
    )
    
    for file in "${script_files[@]}"; do
        if ! curl -s -L -o "$TEMP_DIR/scripts/$file" "$GITHUB_BASE_URL/scripts/$file"; then
            log "WARN" "Failed to download scripts/$file"
        else
            log "INFO" "Successfully downloaded scripts/$file"
        fi
    done
    
    # 设置执行权限
    find "$TEMP_DIR" -name "*.sh" -exec chmod +x {} \;
    
    # 验证下载的文件
    log "INFO" "Verifying downloaded files..."
    if [[ -f "$TEMP_DIR/ipv6-wireguard-manager.sh" ]]; then
        log "INFO" "Main script found: $TEMP_DIR/ipv6-wireguard-manager.sh"
    else
        log "ERROR" "Main script not found in $TEMP_DIR"
        error_exit "Failed to download main script"
    fi
    
    echo -e "${GREEN}✓${NC} 项目文件下载完成"
}

# 创建安装目录
create_install_directory() {
    log "INFO" "Creating installation directory..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/modules"
    mkdir -p "$INSTALL_DIR/config"
    mkdir -p "$INSTALL_DIR/scripts"
    
    echo -e "${GREEN}✓${NC} 安装目录创建完成: $INSTALL_DIR"
}

# 复制文件
copy_files() {
    log "INFO" "Copying files..."
    log "INFO" "Source directory: $TEMP_DIR"
    log "INFO" "Target directory: $INSTALL_DIR"
    
    # 复制主脚本
    if [[ -f "$TEMP_DIR/ipv6-wireguard-manager.sh" ]]; then
        cp "$TEMP_DIR/ipv6-wireguard-manager.sh" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/ipv6-wireguard-manager.sh"
        log "INFO" "Copied main script from $TEMP_DIR/ipv6-wireguard-manager.sh"
    else
        error_exit "Main script not found in downloaded files: $TEMP_DIR/ipv6-wireguard-manager.sh"
    fi
    
    # 复制模块文件
    if [[ -d "$TEMP_DIR/modules" ]]; then
        cp -r "$TEMP_DIR/modules"/* "$INSTALL_DIR/modules/"
        chmod +x "$INSTALL_DIR/modules"/*.sh
        log "INFO" "Copied modules from $TEMP_DIR/modules/"
    else
        log "WARN" "Modules directory not found, creating basic modules"
        create_basic_modules
    fi
    
    # 复制配置文件
    if [[ -d "$TEMP_DIR/config" ]]; then
        cp -r "$TEMP_DIR/config"/* "$INSTALL_DIR/config/"
        log "INFO" "Copied config files from $TEMP_DIR/config/"
    else
        log "WARN" "Config directory not found, creating basic config"
        create_basic_config
    fi
    
    # 复制脚本文件
    if [[ -d "$TEMP_DIR/scripts" ]]; then
        cp -r "$TEMP_DIR/scripts"/* "$INSTALL_DIR/scripts/"
        chmod +x "$INSTALL_DIR/scripts"/*.sh
        log "INFO" "Copied scripts from $TEMP_DIR/scripts/"
    fi
    
    # 复制文档文件
    if [[ -d "$TEMP_DIR/docs" ]]; then
        cp -r "$TEMP_DIR/docs" "$INSTALL_DIR/"
        log "INFO" "Copied documentation from $TEMP_DIR/docs/"
    fi
    
    # 复制示例文件
    if [[ -d "$TEMP_DIR/examples" ]]; then
        cp -r "$TEMP_DIR/examples" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/examples"/*.sh 2>/dev/null || true
        log "INFO" "Copied examples from $TEMP_DIR/examples/"
    fi
    
    # 复制其他文件
    for file in "README.md" "PROJECT_SUMMARY.md" "uninstall.sh"; do
        if [[ -f "$TEMP_DIR/$file" ]]; then
            cp "$TEMP_DIR/$file" "$INSTALL_DIR/"
            log "INFO" "Copied $file"
        fi
    done
    
    echo -e "${GREEN}✓${NC} 文件复制完成"
}

# 创建基本模块（如果下载失败）
create_basic_modules() {
    log "INFO" "Creating basic modules..."
    
    # 创建所有必要的模块文件
    local modules=(
        "server_management.sh"
        "client_management.sh"
        "network_management.sh"
        "firewall_management.sh"
        "system_maintenance.sh"
        "backup_restore.sh"
        "update_management.sh"
        "wireguard_diagnostics.sh"
    )
    
    for module in "${modules[@]}"; do
        cat > "$INSTALL_DIR/modules/$module" << 'EOF'
#!/bin/bash

# 基本模块文件

# 获取脚本目录（如果未定义）
if [[ -z "$SCRIPT_DIR" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# 模块菜单函数
module_menu() {
    echo "此模块需要完整安装才能使用"
    echo "请重新运行安装程序下载完整文件"
    read -p "按回车键继续..."
}

# 导出函数供主脚本调用
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 如果直接运行此脚本
    module_menu
fi
EOF
        chmod +x "$INSTALL_DIR/modules/$module"
        log "INFO" "Created basic module: $module"
    done
}

# 创建基本配置（如果下载失败）
create_basic_config() {
    log "INFO" "Creating basic configuration..."
    
    cat > "$INSTALL_DIR/config/manager.conf" << EOF
# IPv6 WireGuard Manager Configuration
# Generated on $(date)

[general]
version = $SCRIPT_VERSION
install_dir = $INSTALL_DIR
log_level = info

[wireguard]
default_port = 51820
default_interface = wg0
config_dir = /etc/wireguard

[bird]
config_file = /etc/bird/bird.conf
default_as = 65001

[clients]
config_dir = $INSTALL_DIR/config/clients
database_file = $INSTALL_DIR/config/clients.db

[firewall]
auto_configure = true
default_policy = deny
EOF
}

# 创建符号链接
create_symlinks() {
    log "INFO" "Creating symbolic links..."
    
    # 创建主命令链接
    ln -sf "$INSTALL_DIR/ipv6-wireguard-manager.sh" "/usr/local/bin/ipv6-wg-manager"
    ln -sf "$INSTALL_DIR/ipv6-wireguard-manager.sh" "/usr/local/bin/wg-manager"
    
    echo -e "${GREEN}✓${NC} 符号链接创建完成"
}

# 创建系统服务
create_system_service() {
    log "INFO" "Creating system service..."
    
    cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOF
[Unit]
Description=IPv6 WireGuard Manager
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true
ExecReload=/bin/true
WorkingDirectory=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    
    echo -e "${GREEN}✓${NC} 系统服务创建完成"
}

# 创建配置文件
create_config_files() {
    log "INFO" "Creating configuration files..."
    
    # 创建主配置文件（如果不存在）
    if [[ ! -f "$INSTALL_DIR/config/manager.conf" ]]; then
        create_basic_config
    fi
    
    # 创建日志配置
    cat > "$INSTALL_DIR/config/logging.conf" << EOF
# Logging Configuration

[loggers]
keys=root,manager

[handlers]
keys=consoleHandler,fileHandler

[formatters]
keys=simpleFormatter

[logger_root]
level=INFO
handlers=consoleHandler

[logger_manager]
level=INFO
handlers=fileHandler
qualname=manager
propagate=0

[handler_consoleHandler]
class=StreamHandler
level=INFO
formatter=simpleFormatter
args=(sys.stdout,)

[handler_fileHandler]
class=FileHandler
level=INFO
formatter=simpleFormatter
args=('/var/log/ipv6-wireguard/manager.log',)

[formatter_simpleFormatter]
format=%(asctime)s - %(name)s - %(levelname)s - %(message)s
EOF

    echo -e "${GREEN}✓${NC} 配置文件创建完成"
}

# 创建卸载脚本
create_uninstall_script() {
    log "INFO" "Creating uninstall script..."
    
    cat > "$INSTALL_DIR/uninstall.sh" << 'EOF'
#!/bin/bash

# IPv6 WireGuard Manager 卸载脚本

set -euo pipefail

# 重复定义已删除

# 检查root权限
check_root

echo -e "${YELLOW}IPv6 WireGuard Manager 卸载程序${NC}"
echo
read -p "确定要卸载 IPv6 WireGuard Manager 吗? (y/N): " confirm

if [[ "${confirm,,}" != "y" ]]; then
    echo "卸载已取消"
    exit 0
fi

log "Stopping services..."
systemctl stop "$SERVICE_NAME" 2>/dev/null || true
systemctl stop wg-quick@wg0 2>/dev/null || true
systemctl stop bird 2>/dev/null || true

log "Disabling services..."
systemctl disable "$SERVICE_NAME" 2>/dev/null || true

log "Removing system service..."
rm -f "/etc/systemd/system/$SERVICE_NAME.service"
systemctl daemon-reload

log "Removing symbolic links..."
rm -f "/usr/local/bin/ipv6-wg-manager"
rm -f "/usr/local/bin/wg-manager"

log "Removing installation directory..."
rm -rf "$INSTALL_DIR"

log "Removing configuration directories..."
rm -rf "/etc/ipv6-wireguard"
rm -rf "/var/log/ipv6-wireguard"
rm -rf "/var/backups/ipv6-wireguard"

log "IPv6 WireGuard Manager 卸载完成"
echo -e "${GREEN}卸载成功!${NC}"
EOF

    chmod +x "$INSTALL_DIR/uninstall.sh"
    
    echo -e "${GREEN}✓${NC} 卸载脚本创建完成"
}

# 设置权限
set_permissions() {
    log "INFO" "Setting permissions..."
    
    # 设置目录权限
    chmod 755 "$INSTALL_DIR"
    chmod 755 "$INSTALL_DIR/modules"
    chmod 755 "$INSTALL_DIR/config"
    chmod 755 "$INSTALL_DIR/scripts"
    
    # 设置文件权限
    find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \;
    
    # 创建必要的目录
    mkdir -p /etc/ipv6-wireguard
    mkdir -p /var/log/ipv6-wireguard
    mkdir -p /var/backups/ipv6-wireguard
    
    chmod 755 /etc/ipv6-wireguard
    chmod 755 /var/log/ipv6-wireguard
    chmod 755 /var/backups/ipv6-wireguard
    
    echo -e "${GREEN}✓${NC} 权限设置完成"
}

# 验证安装
verify_installation() {
    log "INFO" "Verifying installation..."
    
    local errors=0
    
    # 检查主脚本
    if [[ ! -f "$INSTALL_DIR/ipv6-wireguard-manager.sh" ]]; then
        log "ERROR" "Main script not found"
        ((errors++))
    fi
    
    # 检查模块文件
    local modules=(
        "system_detection.sh"
        "wireguard_config.sh"
        "bird_config.sh"
        "firewall_config.sh"
        "client_management.sh"
        "server_management.sh"
        "network_management.sh"
        "firewall_management.sh"
        "system_maintenance.sh"
        "backup_restore.sh"
        "update_management.sh"
        "wireguard_diagnostics.sh"
    )
    for module in "${modules[@]}"; do
        if [[ ! -f "$INSTALL_DIR/modules/$module" ]]; then
            log "ERROR" "Module not found: $module"
            ((errors++))
        fi
    done
    
    # 检查符号链接
    if [[ ! -L "/usr/local/bin/ipv6-wg-manager" ]]; then
        log "ERROR" "Symbolic link not created"
        ((errors++))
    fi
    
    # 检查服务
    if ! systemctl is-enabled "$SERVICE_NAME" >/dev/null 2>&1; then
        log "ERROR" "Service not enabled"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}✓${NC} 安装验证通过"
        return 0
    else
        echo -e "${RED}✗${NC} 安装验证失败 ($errors 个错误)"
        return 1
    fi
}

# 显示安装完成信息
show_completion_info() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                安装完成!                                  ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}✓${NC} IPv6 WireGuard Manager 安装成功!"
    echo
    echo -e "${CYAN}使用方法:${NC}"
    echo -e "  启动管理器: ${YELLOW}ipv6-wg-manager${NC}"
    echo -e "  或使用: ${YELLOW}wg-manager${NC}"
    echo
    echo -e "${CYAN}安装位置:${NC}"
    echo -e "  程序目录: ${YELLOW}$INSTALL_DIR${NC}"
    echo -e "  配置文件: ${YELLOW}$INSTALL_DIR/config${NC}"
    echo -e "  日志文件: ${YELLOW}/var/log/ipv6-wireguard${NC}"
    echo
    echo -e "${CYAN}卸载方法:${NC}"
    echo -e "  运行: ${YELLOW}$INSTALL_DIR/uninstall.sh${NC}"
    echo
    echo -e "${YELLOW}下一步:${NC}"
    echo -e "  1. 运行 ${YELLOW}ipv6-wg-manager${NC} 开始配置"
    echo -e "  2. 选择快速安装或交互式安装"
    echo -e "  3. 按照向导完成配置"
    echo
    echo -e "${GREEN}感谢使用 IPv6 WireGuard Manager!${NC}"
}

# 主安装流程
main() {
    # 设置清理陷阱
    trap cleanup_temp_files EXIT
    
    # 检查root权限
    check_root
    
    # 显示欢迎信息
    show_welcome
    
    # 确认安装
    read -p "是否继续安装? (y/N): " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        echo "安装已取消"
        exit 0
    fi
    
    # 开始安装
    log "INFO" "Starting installation of IPv6 WireGuard Manager v$SCRIPT_VERSION"
    
    detect_os
    check_requirements
    install_dependencies
    download_project_files
    create_install_directory
    copy_files
    create_symlinks
    create_system_service
    create_config_files
    create_uninstall_script
    set_permissions
    
    # 验证安装
    if verify_installation; then
        show_completion_info
        log "INFO" "Installation completed successfully"
    else
        error_exit "Installation verification failed"
    fi
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
