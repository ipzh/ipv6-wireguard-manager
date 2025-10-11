#!/bin/bash

# IPv6 WireGuard Manager 清理脚本

echo "🧹 清理 IPv6 WireGuard Manager 数据..."

# 停止所有服务
echo "🛑 停止服务..."
docker-compose down

# 删除容器和网络
echo "🗑️  删除容器和网络..."
docker-compose down --volumes --remove-orphans

# 删除镜像
echo "🗑️  删除镜像..."
docker-compose down --rmi all

# 清理Docker系统
echo "🧹 清理Docker系统..."
docker system prune -f

# 删除数据目录
echo "🗑️  删除数据目录..."
rm -rf data/
rm -rf logs/
rm -rf uploads/

echo "✅ 清理完成"
echo ""
echo "💡 提示："
echo "   - 所有数据已被删除"
echo "   - 重新启动: ./scripts/start.sh"
