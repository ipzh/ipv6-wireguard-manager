#!/bin/bash

# 测试安装脚本
# 用于验证一键安装功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo "=================================="
    print_message $BLUE "IPv6 WireGuard Manager 安装测试"
    echo "=================================="
    echo ""
}

# 测试curl安装
test_curl_install() {
    print_message $YELLOW "🧪 测试 curl 一键安装..."
    
    # 创建测试目录
    TEST_DIR="test-install-$(date +%s)"
    mkdir "$TEST_DIR"
    cd "$TEST_DIR"
    
    # 模拟curl安装
    print_message $YELLOW "📥 下载安装脚本..."
    if curl -fsSL "https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-simple.sh" -o "install.sh"; then
        print_message $GREEN "✅ 安装脚本下载成功"
    else
        print_message $RED "❌ 安装脚本下载失败"
        return 1
    fi
    
    # 给脚本执行权限
    chmod +x install.sh
    
    # 检查脚本语法
    if bash -n install.sh; then
        print_message $GREEN "✅ 脚本语法检查通过"
    else
        print_message $RED "❌ 脚本语法错误"
        return 1
    fi
    
    print_message $GREEN "✅ curl 安装测试通过"
    
    # 清理测试目录
    cd ..
    rm -rf "$TEST_DIR"
}

# 测试Git安装
test_git_install() {
    print_message $YELLOW "🧪 测试 Git 安装..."
    
    # 创建测试目录
    TEST_DIR="test-git-$(date +%s)"
    mkdir "$TEST_DIR"
    cd "$TEST_DIR"
    
    # 克隆项目
    if git clone "https://github.com/ipzh/ipv6-wireguard-manager.git" "test-project"; then
        print_message $GREEN "✅ 项目克隆成功"
    else
        print_message $RED "❌ 项目克隆失败"
        return 1
    fi
    
    cd test-project
    
    # 检查必要文件
    local required_files=(
        "docker-compose.yml"
        "backend/requirements.txt"
        "frontend/package.json"
        "scripts/start.sh"
        "install-simple.sh"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            print_message $GREEN "✅ 文件存在: $file"
        else
            print_message $RED "❌ 文件缺失: $file"
            return 1
        fi
    done
    
    print_message $GREEN "✅ Git 安装测试通过"
    
    # 清理测试目录
    cd ../..
    rm -rf "$TEST_DIR"
}

# 测试Docker配置
test_docker_config() {
    print_message $YELLOW "🧪 测试 Docker 配置..."
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        print_message $RED "❌ Docker 未安装"
        return 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_message $RED "❌ Docker Compose 未安装"
        return 1
    fi
    
    # 检查Docker服务
    if ! docker info &> /dev/null; then
        print_message $RED "❌ Docker 服务未运行"
        return 1
    fi
    
    print_message $GREEN "✅ Docker 配置测试通过"
}

# 主函数
main() {
    print_header
    
    # 运行测试
    test_curl_install
    test_git_install
    test_docker_config
    
    echo ""
    echo "=================================="
    print_message $GREEN "🎉 所有测试通过！"
    echo "=================================="
    echo ""
    
    print_message $BLUE "📋 安装命令："
    echo "   curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-curl.sh | bash"
    echo ""
    
    print_message $BLUE "📋 或者使用 Git："
    echo "   git clone https://github.com/ipzh/ipv6-wireguard-manager.git"
    echo "   cd ipv6-wireguard-manager"
    echo "   ./scripts/start.sh"
    echo ""
}

# 运行主函数
main "$@"
