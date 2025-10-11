#!/bin/bash

# IPv6 WireGuard Manager 停止脚本

echo "🛑 停止 IPv6 WireGuard Manager..."

# 停止所有服务
docker-compose down

echo "✅ 所有服务已停止"
echo ""
echo "💡 提示："
echo "   - 数据已保存到 data/ 目录"
echo "   - 重新启动: ./scripts/start.sh"
echo "   - 完全清理: ./scripts/clean.sh"
