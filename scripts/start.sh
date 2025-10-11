#!/bin/bash

# 启动服务脚本

echo "🚀 启动 IPv6 WireGuard Manager 服务..."

# 检查是否在项目根目录
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 请在项目根目录运行此脚本"
    exit 1
fi

# 检查Docker是否安装
if command -v docker >/dev/null 2>&1 && command -v docker-compose >/dev/null 2>&1; then
    echo "🐳 使用 Docker 启动服务..."
    docker-compose up -d
    echo "✅ Docker 服务启动完成"
elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    echo "🐳 使用 Docker Compose 启动服务..."
    docker compose up -d
    echo "✅ Docker 服务启动完成"
else
    echo "🔧 使用 systemd 启动服务..."
    sudo systemctl start ipv6-wireguard-backend
    sudo systemctl start ipv6-wireguard-frontend
    echo "✅ 系统服务启动完成"
fi

echo ""
echo "🌐 服务访问地址:"
echo "   前端: http://localhost:3000"
echo "   API: http://localhost:8000"
echo "   文档: http://localhost:8000/docs"
