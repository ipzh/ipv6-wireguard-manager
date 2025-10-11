#!/bin/bash

# 查看服务日志脚本

echo "📋 IPv6 WireGuard Manager 服务日志"

# 检查是否在项目根目录
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 请在项目根目录运行此脚本"
    exit 1
fi

# 检查Docker是否安装
if command -v docker >/dev/null 2>&1 && command -v docker-compose >/dev/null 2>&1; then
    echo "🐳 Docker 服务日志:"
    docker-compose logs -f
elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    echo "🐳 Docker 服务日志:"
    docker compose logs -f
else
    echo "🔧 系统服务日志:"
    echo "后端服务日志:"
    journalctl -u ipv6-wireguard-backend -f
fi
