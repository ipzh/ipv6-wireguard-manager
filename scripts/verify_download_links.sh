#!/bin/bash

# 下载链接验证脚本
# 检查项目中所有下载链接的有效性

# 导入公共函数
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/../modules/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../modules/common_functions.sh"
fi

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
# YELLOW=  # unused'\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 验证结果统计
declare -i total_links=0
declare -i valid_links=0
declare -i invalid_links=0
declare -i timeout_links=0

# 验证单个链接
verify_link() {
    local url="$1"
    local description="$2"
    local timeout="${3:-10}"
    
    total_links=$((total_links + 1))
    
    echo -n "检查: $description ... "
    
    # 使用curl检查链接
    local response_code
    if command -v curl &> /dev/null; then
        response_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$timeout" "$url" 2>/dev/null)
    elif command -v wget &> /dev/null; then
        response_code=$(wget --spider --timeout="$timeout" -q "$url" 2>/dev/null && echo "200" || echo "000")
    else
        echo -e "${YELLOW}跳过 (无curl/wget)${NC}"
        return 1
    fi
    
    case "$response_code" in
        200)
            echo -e "${GREEN}✓ 有效${NC}"
            valid_links=$((valid_links + 1))
            return 0
            ;;
        404)
            echo -e "${RED}✗ 404 未找到${NC}"
            invalid_links=$((invalid_links + 1))
            return 1
            ;;
        403)
            echo -e "${YELLOW}⚠ 403 禁止访问${NC}"
            invalid_links=$((invalid_links + 1))
            return 1
            ;;
        000)
            echo -e "${YELLOW}⚠ 超时或连接失败${NC}"
            timeout_links=$((timeout_links + 1))
            return 1
            ;;
        *)
            echo -e "${YELLOW}⚠ HTTP $response_code${NC}"
            invalid_links=$((invalid_links + 1))
            return 1
            ;;
    esac
}

# 主验证函数
main() {
    echo -e "${BLUE}=== 下载链接验证工具 ===${NC}"
    echo "开始验证项目中的下载链接..."
    echo
    
    # GitHub API链接
    echo -e "${BLUE}GitHub API 链接:${NC}"
    verify_link "https://api.github.com/repos/ipzh/ipv6-wireguard-manager" "仓库信息API"
    verify_link "https://api.github.com/repos/ipzh/ipv6-wireguard-manager/releases/latest" "最新发布API"
    verify_link "https://api.github.com/repos/ipzh/ipv6-wireguard-manager/releases" "所有发布API"
    echo
    
    # GitHub下载链接
    echo -e "${BLUE}GitHub 下载链接:${NC}"
    verify_link "https://github.com/ipzh/ipv6-wireguard-manager/archive/refs/heads/main.tar.gz" "主分支源码包"
    verify_link "https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh" "安装脚本"
    verify_link "https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/uninstall.sh" "卸载脚本"
    verify_link "https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/update.sh" "更新脚本"
    echo
    
    # CDN链接
    echo -e "${BLUE}CDN 链接:${NC}"
    verify_link "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" "Bootstrap CSS"
    verify_link "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" "Bootstrap JS"
    verify_link "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" "Bootstrap Icons"
    verify_link "https://cdn.jsdelivr.net/npm/chart.js" "Chart.js"
    echo
    
    # 第三方服务链接
    echo -e "${BLUE}第三方服务链接:${NC}"
    verify_link "https://ipv4.icanhazip.com" "IPv4检测服务"
    verify_link "https://ipv6.icanhazip.com" "IPv6检测服务"
    verify_link "https://api.ipify.org" "IP检测API"
    verify_link "https://ifconfig.me/ip" "IP检测服务"
    verify_link "https://checkip.amazonaws.com" "AWS IP检测"
    echo
    
    # WireGuard相关链接
    echo -e "${BLUE}WireGuard 相关链接:${NC}"
    verify_link "https://download.wireguard.com/windows-client/wireguard-installer.exe" "WireGuard Windows客户端"
    verify_link "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" "Homebrew安装脚本"
    echo
    
    # 镜像站点链接
    echo -e "${BLUE}镜像站点链接:${NC}"
    verify_link "https://cdn.jsdelivr.net/gh/ipzh/ipv6-wireguard-manager@main" "jsDelivr镜像"
    verify_link "https://gitee.com/ipzh/ipv6-wireguard-manager/raw/main" "Gitee镜像"
    echo
    
    # 生成验证报告
    echo -e "${BLUE}=== 验证报告 ===${NC}"
    echo "总链接数: $total_links"
    echo -e "有效链接: ${GREEN}$valid_links${NC}"
    echo -e "无效链接: ${RED}$invalid_links${NC}"
    echo -e "超时链接: ${YELLOW}$timeout_links${NC}"
    
    local success_rate=$((valid_links * 100 / total_links))
    echo "成功率: ${success_rate}%"
    
    if [[ $invalid_links -eq 0 && $timeout_links -eq 0 ]]; then
        echo -e "${GREEN}✓ 所有链接验证通过${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ 部分链接存在问题，请检查上述报告${NC}"
        return 1
    fi
}

# 运行主函数
main "$@"

