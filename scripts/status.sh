#!/bin/bash

# 查看服务状态脚本

echo "📊 IPv6 WireGuard Manager 服务状态"

# 检查是否在项目根目录
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 请在项目根目录运行此脚本"
    exit 1
fi

# 检查Docker是否安装
if command -v docker >/dev/null 2>&1 && command -v docker-compose >/dev/null 2>&1; then
    echo "🐳 Docker 服务状态:"
    docker-compose ps
elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    echo "🐳 Docker 服务状态:"
    docker compose ps
else
    echo "🔧 系统服务状态:"
    echo "后端服务:"
    systemctl is-active ipv6-wireguard-backend
    echo "前端服务:"
    systemctl is-active ipv6-wireguard-frontend
fi

echo ""
echo "🌐 服务访问地址:"
echo "   前端: http://localhost:3000"
echo "   API: http://localhost:8000"
echo "   文档: http://localhost:8000/docs"
