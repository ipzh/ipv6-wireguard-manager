#!/bin/bash

# IPv6 WireGuard Manager 在线一键安装脚本
# 直接从GitHub下载并安装，无需预先克隆

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="IPv6 WireGuard Manager"
REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager.git"
INSTALL_DIR="ipv6-wireguard-manager"

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    clear
    echo "=================================="
    print_message $BLUE "$PROJECT_NAME 在线一键安装"
    echo "=================================="
    echo ""
    print_message $YELLOW "本脚本将自动下载并安装 $PROJECT_NAME"
    print_message $YELLOW "支持 Linux、macOS 和 Windows (WSL)"
    echo ""
}

# 检查系统要求
check_requirements() {
    print_message $YELLOW "🔍 检查系统要求..."
    
    # 检查操作系统
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
    else
        print_message $RED "❌ 不支持的操作系统: $OSTYPE"
        exit 1
    fi
    
    print_message $GREEN "✅ 操作系统: $OS"
    
    # 检查必要工具
    local missing_tools=()
    
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        missing_tools+=("docker-compose")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_message $RED "❌ 缺少必要工具: ${missing_tools[*]}"
        echo ""
        print_message $YELLOW "请安装以下工具："
        for tool in "${missing_tools[@]}"; do
            case $tool in
                "git")
                    echo "  - Git: https://git-scm.com/downloads"
                    ;;
                "docker")
                    echo "  - Docker: https://docs.docker.com/get-docker/"
                    ;;
                "docker-compose")
                    echo "  - Docker Compose: https://docs.docker.com/compose/install/"
                    ;;
            esac
        done
        exit 1
    fi
    
    # 检查Docker服务状态
    if ! docker info &> /dev/null; then
        print_message $RED "❌ Docker 服务未运行"
        print_message $YELLOW "请启动 Docker 服务"
        exit 1
    fi
    
    print_message $GREEN "✅ 系统要求检查通过"
}

# 下载并安装
download_and_install() {
    print_message $YELLOW "📥 下载项目..."
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # 克隆项目
    if ! git clone "$REPO_URL" "$INSTALL_DIR"; then
        print_message $RED "❌ 下载项目失败"
        print_message $YELLOW "请检查网络连接和GitHub访问"
        exit 1
    fi
    
    cd "$INSTALL_DIR"
    print_message $GREEN "✅ 项目下载成功"
    
    # 设置权限
    print_message $YELLOW "🔐 设置文件权限..."
    chmod +x scripts/*.sh 2>/dev/null || true
    chmod +x install.sh 2>/dev/null || true
    
    # 创建必要目录
    mkdir -p data/postgres data/redis logs uploads backups
    
    print_message $GREEN "✅ 权限设置完成"
    
    # 配置环境
    print_message $YELLOW "⚙️  配置环境..."
    
    if [ -f "backend/env.example" ] && [ ! -f "backend/.env" ]; then
        cp backend/env.example backend/.env
        
        # 生成随机密码
        generate_password() {
            openssl rand -base64 32 | tr -d "=+/" | cut -c1-25 2>/dev/null || \
            head /dev/urandom | tr -dc A-Za-z0-9 | head -c 25
        }
        
        SECRET_KEY=$(generate_password)
        DB_PASSWORD=$(generate_password)
        
        # 更新配置文件
        sed -i.bak "s/your-super-secret-key-for-jwt/$SECRET_KEY/" backend/.env 2>/dev/null || \
        sed -i "" "s/your-super-secret-key-for-jwt/$SECRET_KEY/" backend/.env 2>/dev/null || true
        
        sed -i.bak "s/ipv6wgm/$DB_PASSWORD/" backend/.env 2>/dev/null || \
        sed -i "" "s/ipv6wgm/$DB_PASSWORD/" backend/.env 2>/dev/null || true
        
        print_message $GREEN "✅ 环境配置已更新"
    fi
    
    # 启动服务
    print_message $YELLOW "🚀 启动服务..."
    
    if ! docker-compose up -d; then
        print_message $RED "❌ 启动服务失败"
        exit 1
    fi
    
    # 等待服务启动
    print_message $YELLOW "⏳ 等待服务启动..."
    sleep 20
    
    # 初始化数据库
    print_message $YELLOW "🗄️  初始化数据库..."
    sleep 10
    
    if docker-compose exec -T backend python -c "
import asyncio
from app.core.init_db import init_db
asyncio.run(init_db())
" 2>/dev/null; then
        print_message $GREEN "✅ 数据库初始化成功"
    else
        print_message $YELLOW "⚠️  数据库初始化可能失败，请手动检查"
    fi
    
    # 验证安装
    print_message $YELLOW "🔍 验证安装..."
    
    local all_healthy=true
    
    if curl -s "http://localhost:8000" > /dev/null 2>&1; then
        print_message $GREEN "✅ 后端服务正常"
    else
        print_message $RED "❌ 后端服务异常"
        all_healthy=false
    fi
    
    if curl -s "http://localhost:3000" > /dev/null 2>&1; then
        print_message $GREEN "✅ 前端服务正常"
    else
        print_message $RED "❌ 前端服务异常"
        all_healthy=false
    fi
    
    # 显示结果
    echo ""
    echo "=================================="
    if [ "$all_healthy" = true ]; then
        print_message $GREEN "🎉 安装完成！"
    else
        print_message $YELLOW "⚠️  安装完成，但部分服务可能存在问题"
    fi
    echo "=================================="
    echo ""
    
    print_message $BLUE "📋 访问信息："
    echo "   - 前端界面: http://localhost:3000"
    echo "   - 后端API: http://localhost:8000"
    echo "   - API文档: http://localhost:8000/docs"
    echo ""
    
    print_message $BLUE "🔑 默认登录信息："
    echo "   用户名: admin"
    echo "   密码: admin123"
    echo ""
    
    print_message $BLUE "🛠️  管理命令："
    echo "   查看状态: docker-compose ps"
    echo "   查看日志: docker-compose logs -f"
    echo "   停止服务: docker-compose down"
    echo "   重启服务: docker-compose restart"
    echo ""
    
    print_message $YELLOW "⚠️  安全提醒："
    echo "   请在生产环境中修改默认密码"
    echo "   配置文件位置: backend/.env"
    echo ""
    
    print_message $BLUE "📁 项目位置："
    echo "   $(pwd)"
    echo ""
    
    # 询问是否移动到用户目录
    read -p "是否将项目移动到用户主目录? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -d "$HOME/$INSTALL_DIR" ]; then
            print_message $YELLOW "⚠️  目标目录已存在，跳过移动"
        else
            mv "$(pwd)" "$HOME/$INSTALL_DIR"
            print_message $GREEN "✅ 项目已移动到: $HOME/$INSTALL_DIR"
            print_message $BLUE "请运行: cd $HOME/$INSTALL_DIR"
        fi
    fi
}

# 主函数
main() {
    print_header
    
    # 检查系统要求
    check_requirements
    
    echo ""
    read -p "按 Enter 键开始安装，或 Ctrl+C 取消..."
    echo ""
    
    # 下载并安装
    download_and_install
}

# 错误处理
trap 'print_message $RED "❌ 安装过程中发生错误"; exit 1' ERR

# 运行主函数
main "$@"
