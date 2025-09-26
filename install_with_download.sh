#!/bin/bash

# IPv6 WireGuard Manager 安装脚本（带自动下载）
# 版本: 1.0.0
# 作者: IPv6 WireGuard Manager Team

set -euo pipefail

# 仓库配置
REPO_OWNER="${REPO_OWNER:-ipzh}"
REPO_NAME="${REPO_NAME:-ipv6-wireguard-manager}"
REPO_BRANCH="${REPO_BRANCH:-master}"
REPO_URL="${REPO_URL:-https://github.com/ipzh/ipv6-wireguard-manager}"
RAW_URL="${RAW_URL:-https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
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
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # 下载项目文件
    log_info "正在下载项目文件..."
    log_info "下载URL: $download_url"
    
    if command -v curl &> /dev/null; then
        if ! curl -L -o "${REPO_NAME}.tar.gz" "$download_url"; then
            log_error "下载失败，请检查网络连接和URL"
            return 1
        fi
    elif command -v wget &> /dev/null; then
        if ! wget -O "${REPO_NAME}.tar.gz" "$download_url"; then
            log_error "下载失败，请检查网络连接和URL"
            return 1
        fi
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
        log_info "正在解压文件..."
        if ! tar -xzf "${REPO_NAME}.tar.gz"; then
            log_error "解压失败，文件可能损坏"
            return 1
        fi
        
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
        chmod +x install.sh
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
