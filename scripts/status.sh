#!/bin/bash

# IPv6 WireGuard Manager 状态检查脚本

echo "📊 IPv6 WireGuard Manager 状态检查"
echo "=================================="

# 检查Docker服务状态
echo "🐳 Docker 服务状态："
docker-compose ps

echo ""

# 检查服务健康状态
echo "🏥 服务健康检查："

# 检查后端API
echo -n "后端API: "
if curl -s http://localhost:8000/health > /dev/null; then
    echo "✅ 正常"
else
    echo "❌ 异常"
fi

# 检查前端
echo -n "前端服务: "
if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ 正常"
else
    echo "❌ 异常"
fi

# 检查数据库连接
echo -n "数据库连接: "
if docker-compose exec -T db pg_isready -U ipv6wgm > /dev/null 2>&1; then
    echo "✅ 正常"
else
    echo "❌ 异常"
fi

# 检查Redis连接
echo -n "Redis连接: "
if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ 正常"
else
    echo "❌ 异常"
fi

echo ""

# 显示资源使用情况
echo "💻 资源使用情况："
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

echo ""

# 显示磁盘使用情况
echo "💾 磁盘使用情况："
df -h | grep -E "(Filesystem|/dev/)"

echo ""

# 显示最近日志
echo "📝 最近日志 (最后10行)："
docker-compose logs --tail=10
