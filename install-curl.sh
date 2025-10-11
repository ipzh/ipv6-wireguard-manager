#!/bin/bash

# IPv6 WireGuard Manager 一键安装脚本 (curl版本)
# 使用curl直接下载并执行安装脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="IPv6 WireGuard Manager"
INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-online.sh"

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo "=================================="
    print_message $BLUE "$PROJECT_NAME 一键安装"
    echo "=================================="
    echo ""
    print_message $YELLOW "本脚本将自动下载并安装 $PROJECT_NAME"
    echo ""
}

# 检查curl
check_curl() {
    if ! command -v curl &> /dev/null; then
        print_message $RED "❌ curl 未安装"
        print_message $YELLOW "请先安装 curl"
        exit 1
    fi
    print_message $GREEN "✅ curl 已安装"
}

# 下载并执行安装脚本
download_and_execute() {
    print_message $YELLOW "📥 下载安装脚本..."
    
    # 创建临时文件
    TEMP_SCRIPT=$(mktemp)
    
    # 下载安装脚本
    if ! curl -sSL "$INSTALL_SCRIPT_URL" -o "$TEMP_SCRIPT"; then
        print_message $RED "❌ 下载安装脚本失败"
        print_message $YELLOW "请检查网络连接"
        exit 1
    fi
    
    print_message $GREEN "✅ 安装脚本下载成功"
    
    # 给脚本执行权限
    chmod +x "$TEMP_SCRIPT"
    
    # 执行安装脚本
    print_message $YELLOW "🚀 开始安装..."
    echo ""
    
    exec "$TEMP_SCRIPT"
}

# 主函数
main() {
    print_header
    
    # 检查curl
    check_curl
    
    echo ""
    read -p "按 Enter 键开始安装，或 Ctrl+C 取消..."
    echo ""
    
    # 下载并执行
    download_and_execute
}

# 运行主函数
main "$@"
