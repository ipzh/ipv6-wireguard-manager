#!/bin/bash

# IPv6 WireGuard Manager 一键安装脚本
# 支持从GitHub克隆并自动安装

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
    echo "=================================="
    print_message $BLUE "$PROJECT_NAME 一键安装脚本"
    echo "=================================="
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
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        print_message $RED "❌ Docker 未安装"
        print_message $YELLOW "请先安装 Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_message $RED "❌ Docker Compose 未安装"
        print_message $YELLOW "请先安装 Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # 检查Docker服务状态
    if ! docker info &> /dev/null; then
        print_message $RED "❌ Docker 服务未运行"
        print_message $YELLOW "请启动 Docker 服务"
        exit 1
    fi
    
    print_message $GREEN "✅ Docker 环境检查通过"
    
    # 检查端口占用
    check_port() {
        local port=$1
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            print_message $YELLOW "⚠️  端口 $port 已被占用"
            return 1
        fi
        return 0
    }
    
    if ! check_port 3000; then
        print_message $YELLOW "⚠️  前端端口 3000 被占用，将使用其他端口"
    fi
    
    if ! check_port 8000; then
        print_message $YELLOW "⚠️  后端端口 8000 被占用，将使用其他端口"
    fi
    
    if ! check_port 5432; then
        print_message $YELLOW "⚠️  数据库端口 5432 被占用，将使用其他端口"
    fi
    
    if ! check_port 6379; then
        print_message $YELLOW "⚠️  Redis端口 6379 被占用，将使用其他端口"
    fi
}

# 克隆项目
clone_project() {
    print_message $YELLOW "📥 克隆项目..."
    
    if [ -d "$INSTALL_DIR" ]; then
        print_message $YELLOW "⚠️  目录 $INSTALL_DIR 已存在"
        read -p "是否删除现有目录并重新安装? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_DIR"
        else
            print_message $YELLOW "使用现有目录"
            return
        fi
    fi
    
    if ! git clone "$REPO_URL" "$INSTALL_DIR"; then
        print_message $RED "❌ 克隆项目失败"
        exit 1
    fi
    
    cd "$INSTALL_DIR"
    print_message $GREEN "✅ 项目克隆成功"
}

# 设置权限
setup_permissions() {
    print_message $YELLOW "🔐 设置文件权限..."
    
    # 给脚本执行权限
    chmod +x scripts/*.sh
    
    # 创建必要的目录
    mkdir -p data/postgres
    mkdir -p data/redis
    mkdir -p logs
    mkdir -p uploads
    mkdir -p backups
    
    # 设置目录权限
    chmod 755 data/
    chmod 755 logs/
    chmod 755 uploads/
    chmod 755 backups/
    
    print_message $GREEN "✅ 权限设置完成"
}

# 配置环境
setup_environment() {
    print_message $YELLOW "⚙️  配置环境..."
    
    # 检查环境配置文件
    if [ ! -f "backend/.env" ]; then
        if [ -f "backend/env.example" ]; then
            cp backend/env.example backend/.env
            print_message $GREEN "✅ 环境配置文件已创建"
        else
            print_message $YELLOW "⚠️  未找到环境配置文件模板"
        fi
    fi
    
    # 生成随机密码
    generate_password() {
        openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
    }
    
    # 更新环境配置
    if [ -f "backend/.env" ]; then
        # 生成随机密钥
        SECRET_KEY=$(generate_password)
        DB_PASSWORD=$(generate_password)
        
        # 更新配置文件
        sed -i.bak "s/your-super-secret-key-for-jwt/$SECRET_KEY/" backend/.env
        sed -i.bak "s/ipv6wgm/$DB_PASSWORD/" backend/.env
        
        print_message $GREEN "✅ 环境配置已更新"
        print_message $YELLOW "🔑 数据库密码: $DB_PASSWORD"
        print_message $YELLOW "🔑 JWT密钥: $SECRET_KEY"
    fi
}

# 启动服务
start_services() {
    print_message $YELLOW "🚀 启动服务..."
    
    # 启动Docker服务
    if ! docker-compose up -d; then
        print_message $RED "❌ 启动服务失败"
        exit 1
    fi
    
    # 等待服务启动
    print_message $YELLOW "⏳ 等待服务启动..."
    sleep 15
    
    # 检查服务状态
    if ! docker-compose ps | grep -q "Up"; then
        print_message $RED "❌ 服务启动失败"
        print_message $YELLOW "查看日志: docker-compose logs"
        exit 1
    fi
    
    print_message $GREEN "✅ 服务启动成功"
}

# 初始化数据
init_database() {
    print_message $YELLOW "🗄️  初始化数据库..."
    
    # 等待数据库启动
    sleep 10
    
    # 初始化数据库
    if docker-compose exec -T backend python -c "
import asyncio
from app.core.init_db import init_db
asyncio.run(init_db())
" 2>/dev/null; then
        print_message $GREEN "✅ 数据库初始化成功"
    else
        print_message $YELLOW "⚠️  数据库初始化可能失败，请手动检查"
    fi
}

# 验证安装
verify_installation() {
    print_message $YELLOW "🔍 验证安装..."
    
    # 检查服务健康状态
    local services=("backend:8000" "frontend:3000")
    local all_healthy=true
    
    for service in "${services[@]}"; do
        local name=$(echo $service | cut -d: -f1)
        local port=$(echo $service | cut -d: -f2)
        
        if curl -s "http://localhost:$port" > /dev/null 2>&1; then
            print_message $GREEN "✅ $name 服务正常"
        else
            print_message $RED "❌ $name 服务异常"
            all_healthy=false
        fi
    done
    
    if [ "$all_healthy" = true ]; then
        print_message $GREEN "✅ 所有服务运行正常"
    else
        print_message $YELLOW "⚠️  部分服务可能存在问题"
    fi
}

# 显示安装结果
show_result() {
    echo ""
    echo "=================================="
    print_message $GREEN "🎉 安装完成！"
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
    echo "   查看状态: ./scripts/status.sh"
    echo "   查看日志: ./scripts/logs.sh"
    echo "   停止服务: ./scripts/stop.sh"
    echo "   重启服务: ./scripts/stop.sh && ./scripts/start.sh"
    echo ""
    print_message $YELLOW "⚠️  安全提醒："
    echo "   请在生产环境中修改默认密码"
    echo "   配置文件位置: backend/.env"
    echo ""
}

# 主函数
main() {
    print_header
    
    # 检查系统要求
    check_requirements
    
    # 克隆项目
    clone_project
    
    # 设置权限
    setup_permissions
    
    # 配置环境
    setup_environment
    
    # 启动服务
    start_services
    
    # 初始化数据
    init_database
    
    # 验证安装
    verify_installation
    
    # 显示结果
    show_result
}

# 错误处理
trap 'print_message $RED "❌ 安装过程中发生错误，请检查日志"; exit 1' ERR

# 运行主函数
main "$@"
