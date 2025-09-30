#!/bin/bash

# IPv6 WireGuard Manager 安装脚本（带自动下载）
# 版本: 1.0.0
# 作者: IPv6 WireGuard Manager Team

# 设置错误处理，根据执行环境调整严格程度
if [[ -t 0 ]]; then
    # 交互式执行，使用严格模式
    set -euo pipefail
else
    # 管道执行，使用宽松模式
    set -e
fi

# 安全的脚本目录检测
get_script_dir() {
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        # 标准情况：通过BASH_SOURCE获取
        echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    elif [[ -n "${0:-}" && "$0" != "-bash" && "$0" != "bash" ]]; then
        # 备选方案1：通过$0获取
        echo "$(cd "$(dirname "$0")" && pwd)"
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
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 基础日志函数的备选实现
if ! command -v log_info &> /dev/null; then
    log_info() { echo -e "${BLUE}[INFO]${NC} $@"; }
    log_success() { echo -e "${GREEN}[SUCCESS]${NC} $@"; }
    log_warn() { echo -e "${YELLOW}[WARN]${NC} $@"; }
    log_error() { echo -e "${RED}[ERROR]${NC} $@"; }
    log_debug() { echo -e "${PURPLE}[DEBUG]${NC} $@"; }
fi

# 改进的模块导入机制
import_module() {
    local module_name="$1"
    local module_path="${MODULES_DIR}/${module_name}.sh"
    
    if [[ -f "$module_path" ]]; then
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
    source "${MODULES_DIR}/module_loader.sh"
    log_info "模块加载器已导入"
else
    log_error "模块加载器文件不存在: ${MODULES_DIR}/module_loader.sh"
    exit 1
fi

# 仓库配置
REPO_OWNER="${REPO_OWNER:-ipzh}"
REPO_NAME="${REPO_NAME:-ipv6-wireguard-manager}"
REPO_BRANCH="${REPO_BRANCH:-main}"
REPO_URL="${REPO_URL:-https://github.com/ipzh/ipv6-wireguard-manager}"
RAW_URL="${RAW_URL:-https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main}"

# 函数已在common_functions.sh中定义，无需重复定义

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
    echo "║  • Web管理界面                                                              ║"
    echo "║  • 实时监控和日志                                                           ║"
    echo "║                                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 检查网络连接
check_network_connectivity() {
    log_info "检查网络连接..."
    
    local test_urls=(
        "https://github.com"
        "https://raw.githubusercontent.com"
        "https://api.github.com"
    )
    
    local connectivity_ok=false
    
    for url in "${test_urls[@]}"; do
        if execute_command "curl -s --connect-timeout 10 --max-time 30 '$url' >/dev/null" "测试连接到 $url" "true"; then
            log_success "网络连接正常: $url"
            connectivity_ok=true
            break
        else
            log_warn "无法连接到: $url"
        fi
    done
    
    if [[ "$connectivity_ok" == "false" ]]; then
        log_error "网络连接检查失败，请检查网络设置"
        return 1
    fi
    
    return 0
}

# 检查系统要求
check_system_requirements() {
    log_info "检查系统要求..."
    
    # 检查操作系统
    if [[ ! -f /etc/os-release ]]; then
        log_error "不支持的操作系统"
        return 1
    fi
    
    # 检查必要的命令
    local required_commands=("curl" "wget" "tar" "gzip")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_warn "缺少命令: $cmd，将尝试安装"
            install_dependency "$cmd" "$cmd工具" "true"
        fi
    done
    
    # 检查磁盘空间
    local available_space=$(df /tmp | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 1048576 ]]; then # 1GB in KB
        log_warn "可用磁盘空间不足1GB，可能影响下载和安装"
    fi
    
    log_success "系统要求检查完成"
    return 0
}

# 下载项目文件（增强版）
download_project_files() {
    log_info "下载项目文件..."
    
    local download_url="${REPO_URL}/archive/refs/heads/${REPO_BRANCH}.tar.gz"
    local temp_dir="/tmp/${REPO_NAME}-download"
    local max_retries=3
    local retry_count=0
    
    # 创建临时目录
    execute_command "mkdir -p '$temp_dir'" "创建临时下载目录"
    cd "$temp_dir"
    
    # 下载项目文件（带重试机制）
    while [[ $retry_count -lt $max_retries ]]; do
        log_info "正在下载项目文件... (尝试 $((retry_count + 1))/$max_retries)"
        log_info "下载URL: $download_url"
        
        local download_success=false
        
        if command -v curl &> /dev/null; then
            if execute_command "curl -L --connect-timeout 30 --max-time 300 -o '${REPO_NAME}.tar.gz' '$download_url'" "使用curl下载项目文件" "true"; then
                download_success=true
            fi
        elif command -v wget &> /dev/null; then
            if execute_command "wget --timeout=30 --tries=3 -O '${REPO_NAME}.tar.gz' '$download_url'" "使用wget下载项目文件" "true"; then
                download_success=true
            fi
        else
            log_error "需要curl或wget来下载文件"
            return 1
        fi
        
        if [[ "$download_success" == "true" && -f "${REPO_NAME}.tar.gz" ]]; then
            # 检查文件大小和完整性
            local file_size=$(stat -c%s "${REPO_NAME}.tar.gz" 2>/dev/null || echo "0")
            log_info "下载文件大小: $file_size 字节"
            
            if [[ $file_size -lt 1000 ]]; then
                log_warn "下载的文件太小，可能是错误页面，重试..."
                rm -f "${REPO_NAME}.tar.gz"
                retry_count=$((retry_count + 1))
                sleep 2
                continue
            fi
            
            # 验证文件完整性
            if execute_command "tar -tzf '${REPO_NAME}.tar.gz' >/dev/null 2>&1" "验证压缩文件完整性" "true"; then
                log_success "文件下载和验证成功"
                break
            else
                log_warn "文件完整性验证失败，重试..."
                rm -f "${REPO_NAME}.tar.gz"
                retry_count=$((retry_count + 1))
                sleep 2
                continue
            fi
        else
            log_warn "下载失败，重试..."
            retry_count=$((retry_count + 1))
            sleep 2
        fi
    done
    
    if [[ $retry_count -eq $max_retries ]]; then
        log_error "下载失败，已达到最大重试次数"
        return 1
    fi
    
    # 解压文件
    execute_command "tar -xzf '${REPO_NAME}.tar.gz'" "解压项目文件"
    
    # 移动到当前目录
    if [[ -d "${REPO_NAME}-${REPO_BRANCH}" ]]; then
        execute_command "cp -r '${REPO_NAME}-${REPO_BRANCH}'/* ./" "复制项目文件"
        execute_command "rm -rf '${REPO_NAME}-${REPO_BRANCH}'" "清理临时目录"
    fi
    
    log_success "项目文件下载完成"
    log_info "文件位置: $(pwd)"
    
    # 检查关键文件是否存在
    if [[ -f "ipv6-wireguard-manager.sh" ]]; then
        log_success "主脚本文件已下载"
    else
        log_error "主脚本文件未找到"
        return 1
    fi
    
    if [[ -f "install.sh" ]]; then
        log_success "安装脚本已下载"
    else
        log_error "安装脚本未找到"
        return 1
    fi
}

# 运行安装脚本
run_install_script() {
    log_info "运行安装脚本..."
    
    # 添加EUID检查
    if [[ $EUID -ne 0 ]]; then
        log_error "错误: 此脚本需要以root权限运行"
        log_error "请使用sudo命令或以root用户身份执行此脚本"
        log_error "例如: sudo $0 或 sudo bash $0"
        return 1
    fi
    
    # 验证root权限
    if ! id -u >/dev/null 2>&1 || [[ $(id -u) -ne 0 ]]; then
        log_error "无法验证root权限"
        return 1
    fi
    
    log_info "权限验证通过，继续执行安装..."
    
    if [[ -f "install.sh" ]]; then
        execute_command "chmod +x install.sh" "设置安装脚本执行权限"
        ./install.sh "$@"
    else
        log_error "安装脚本不存在"
        return 1
    fi
}

# 清理临时文件
cleanup() {
    log_info "清理临时文件..."
    
    if [[ -d "/tmp/${REPO_NAME}-download" ]]; then
        execute_command "rm -rf '/tmp/${REPO_NAME}-download'" "清理临时下载目录" "true"
    fi
    
    log_info "清理完成"
}

# 显示安装完成信息
show_installation_complete() {
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🎉 安装完成！IPv6 WireGuard Manager 已就绪 🎉            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${YELLOW}🚀 快速启动: ${CYAN}ipv6-wireguard-manager${NC}"
    echo -e "${YELLOW}📋 服务管理: ${CYAN}systemctl start ipv6-wireguard-manager${NC}"
    
    # 显示Web界面地址（如果安装了Web界面）
    if systemctl is-enabled ipv6-wireguard-manager &>/dev/null; then
        echo
        echo -e "${YELLOW}🌐 Web界面:${NC}"
        
        # 获取服务器IP地址
        local server_ipv4=$(get_local_ipv4 2>/dev/null || echo "localhost")
        local server_ipv6=$(get_local_ipv6 2>/dev/null || echo "")
        
        echo -e "  • IPv4: ${CYAN}http://${server_ipv4}:8080${NC}"
        if [[ -n "$server_ipv6" ]]; then
            echo -e "  • IPv6: ${CYAN}http://[${server_ipv6}]:8080${NC}"
        fi
    fi
    
    echo
    echo -e "${YELLOW}📚 更多信息:${NC}"
    echo -e "  • 文档: ${CYAN}https://github.com/ipzh/ipv6-wireguard-manager${NC}"
    echo -e "  • 支持: ${CYAN}https://github.com/ipzh/ipv6-wireguard-manager/issues${NC}"
    echo
}

# 处理命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                echo "IPv6 WireGuard Manager 安装脚本（带自动下载）"
                echo
                echo "用法: $0 [选项]"
                echo
                echo "选项:"
                echo "  --help, -h          显示此帮助信息"
                echo "  --version          显示版本信息"
                echo "  --no-download      跳过下载，使用本地文件"
                echo "  --force            强制重新下载"
                echo
                echo "示例:"
                echo "  $0                  # 标准安装"
                echo "  $0 --force          # 强制重新下载并安装"
                echo
                exit 0
                ;;
            --version)
                echo "IPv6 WireGuard Manager 安装脚本 v1.0.0"
                exit 0
                ;;
            --no-download)
                NO_DOWNLOAD=true
                shift
                ;;
            --force)
                FORCE_DOWNLOAD=true
                shift
                ;;
            *)
                # 传递给安装脚本的参数
                break
                ;;
        esac
    done
}

# 主函数
main() {
    # 显示横幅
    show_banner
    
    # 解析命令行参数
    parse_arguments "$@"
    
    # 检查网络连接
    if [[ "${NO_DOWNLOAD:-false}" != "true" ]]; then
        if ! check_network_connectivity; then
            log_error "网络连接检查失败"
            exit 1
        fi
    fi
    
    # 检查系统要求
    if ! check_system_requirements; then
        log_error "系统要求检查失败"
        exit 1
    fi
    
    # 设置清理陷阱
    trap cleanup EXIT
    
    # 下载项目文件
    if [[ "${NO_DOWNLOAD:-false}" != "true" ]]; then
        if ! download_project_files; then
            log_error "项目文件下载失败"
            exit 1
        fi
    fi
    
    # 运行安装脚本
    if ! run_install_script "$@"; then
        log_error "安装失败"
        exit 1
    fi
    
    # 显示安装完成信息
    show_installation_complete
}

# 执行主函数
main "$@"