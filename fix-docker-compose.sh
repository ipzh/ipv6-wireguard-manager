#!/bin/bash

# 修复Docker Compose命令问题

echo "🔧 修复Docker Compose命令问题..."

# 检查Docker Compose版本
echo "🔍 检查Docker Compose..."

if command -v docker-compose >/dev/null 2>&1; then
    echo "✅ 找到 docker-compose 命令"
    docker-compose --version
elif docker compose version >/dev/null 2>&1; then
    echo "✅ 找到 docker compose 插件"
    docker compose version
else
    echo "❌ 未找到Docker Compose"
    echo "请重新运行安装脚本"
    exit 1
fi

# 进入项目目录
if [ -d "ipv6-wireguard-manager" ]; then
    cd ipv6-wireguard-manager
    echo "📁 进入项目目录: $(pwd)"
    
    # 启动服务
    echo "🚀 启动服务..."
    if command -v docker-compose >/dev/null 2>&1; then
        echo "   使用: docker-compose"
        docker-compose up -d
    elif docker compose version >/dev/null 2>&1; then
        echo "   使用: docker compose"
        docker compose up -d
    else
        echo "❌ Docker Compose 未找到"
        exit 1
    fi
    
    # 等待服务启动
    echo "⏳ 等待服务启动..."
    sleep 30
    
    # 检查服务状态
    echo "🔍 检查服务状态..."
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose ps
    else
        docker compose ps
    fi
    
    echo ""
    echo "🎉 服务启动完成！"
    echo ""
    echo "📋 访问信息："
    echo "   - 前端界面: http://localhost:3000"
    echo "   - 后端API: http://localhost:8000"
    echo "   - API文档: http://localhost:8000/docs"
    echo ""
    echo "🔑 默认登录信息："
    echo "   用户名: admin"
    echo "   密码: admin123"
    echo ""
else
    echo "❌ 项目目录不存在"
    echo "请先运行安装脚本"
    exit 1
fi
