#!/bin/bash

# 停止服务脚本

echo "🛑 停止 IPv6 WireGuard Manager 服务..."

# 检查是否在项目根目录
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 请在项目根目录运行此脚本"
    exit 1
fi

# 检查Docker是否安装
if command -v docker >/dev/null 2>&1 && command -v docker-compose >/dev/null 2>&1; then
    echo "🐳 使用 Docker 停止服务..."
    docker-compose down
    echo "✅ Docker 服务停止完成"
elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    echo "🐳 使用 Docker Compose 停止服务..."
    docker compose down
    echo "✅ Docker 服务停止完成"
else
    echo "🔧 使用 systemd 停止服务..."
    sudo systemctl stop ipv6-wireguard-backend
    sudo systemctl stop ipv6-wireguard-frontend
    echo "✅ 系统服务停止完成"
fi
