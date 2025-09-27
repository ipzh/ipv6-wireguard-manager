#!/bin/bash

# IPv6 WireGuard Manager 安装脚本（带自动下载）
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

# 仓库配置
REPO_OWNER="${REPO_OWNER:-ipzh}"
REPO_NAME="${REPO_NAME:-ipv6-wireguard-manager}"
REPO_BRANCH="${REPO_BRANCH:-master}"
REPO_URL="${REPO_URL:-https://github.com/ipzh/ipv6-wireguard-manager}"
RAW_URL="${RAW_URL:-https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master}"

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

# 检查权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此安装脚本需要root权限运行"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 下载项目文件
download_project_files() {
    log_info "下载项目文件..."
    
    local download_url="${REPO_URL}/archive/refs/heads/${REPO_BRANCH}.tar.gz"
    local temp_dir="/tmp/${REPO_NAME}-download"
    
    # 创建临时目录
    execute_command "mkdir -p '$temp_dir'" "创建临时下载目录"
    cd "$temp_dir"
    
    # 下载项目文件
    log_info "正在下载项目文件..."
    log_info "下载URL: $download_url"
    
    if command -v curl &> /dev/null; then
        execute_command "curl -L -o '${REPO_NAME}.tar.gz' '$download_url'" "使用curl下载项目文件"
    elif command -v wget &> /dev/null; then
        execute_command "wget -O '${REPO_NAME}.tar.gz' '$download_url'" "使用wget下载项目文件"
    else
        log_error "需要curl或wget来下载文件"
        return 1
    fi
    
    if [[ -f "${REPO_NAME}.tar.gz" ]]; then
        # 检查文件大小
        local file_size=$(stat -c%s "${REPO_NAME}.tar.gz" 2>/dev/null || echo "0")
        log_info "下载文件大小: $file_size 字节"
        
        if [[ $file_size -lt 1000 ]]; then
            log_error "下载的文件太小，可能是错误页面"
            log_error "文件内容:"
            head -5 "${REPO_NAME}.tar.gz"
            return 1
        fi
        
        # 解压文件
        execute_command "tar -xzf '${REPO_NAME}.tar.gz'" "解压项目文件"
        
        # 移动到当前目录
        if [[ -d "${REPO_NAME}-${REPO_BRANCH}" ]]; then
            cp -r "${REPO_NAME}-${REPO_BRANCH}"/* ./
            rm -rf "${REPO_NAME}-${REPO_BRANCH}"
        fi
        
        log_success "项目文件下载完成"
        log_info "文件位置: $(pwd)"
        
        # 检查关键文件是否存在
        if [[ -f "ipv6-wireguard-manager.sh" ]]; then
            log_success "主脚本文件已下载"
        else
            log_error "主脚本文件下载失败"
            return 1
        fi
        
        if [[ -d "modules" ]]; then
            log_success "模块目录已下载"
        else
            log_error "模块目录下载失败"
            return 1
        fi
        
        return 0
    else
        log_error "文件下载失败"
        return 1
    fi
}

# 运行安装脚本
run_install_script() {
    log_info "运行安装脚本..."
    
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
    cd /
    rm -rf "/tmp/${REPO_NAME}-download"
}

# 主函数
main() {
    show_banner
    
    # 检查权限
    check_root
    
    # 设置清理陷阱
    trap cleanup EXIT
    
    # 下载项目文件
    if ! download_project_files; then
        log_error "项目文件下载失败"
        exit 1
    fi
    
    # 运行安装脚本
    if ! run_install_script "$@"; then
        log_error "安装失败"
        exit 1
    fi
    
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🎉 安装完成！IPv6 WireGuard Manager 已就绪 🎉            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${YELLOW}🚀 快速启动: ${CYAN}ipv6-wireguard-manager${NC}"
    echo -e "${YELLOW}📋 服务管理: ${CYAN}systemctl start ipv6-wireguard-manager${NC}"
    
    # 显示Web界面地址（如果安装了Web界面）
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
    echo -e "${GREEN}感谢使用IPv6 WireGuard Manager！${NC}"
    echo
}

# 执行主函数
main "$@"
