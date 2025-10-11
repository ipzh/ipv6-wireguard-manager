#!/bin/bash

# IPv6 WireGuard Manager 更新脚本

set -e

echo "🔄 更新 IPv6 WireGuard Manager..."

# 备份当前配置
echo "💾 备份当前配置..."
./scripts/backup.sh

# 停止服务
echo "🛑 停止服务..."
docker-compose down

# 拉取最新代码
echo "📥 拉取最新代码..."
git pull origin main

# 更新镜像
echo "🐳 更新镜像..."
docker-compose pull

# 重新构建镜像
echo "🔨 重新构建镜像..."
docker-compose build

# 启动服务
echo "🚀 启动服务..."
docker-compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 15

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose ps

echo "✅ 更新完成"
echo ""
echo "💡 提示："
echo "   - 查看日志: ./scripts/logs.sh"
echo "   - 检查状态: ./scripts/status.sh"
