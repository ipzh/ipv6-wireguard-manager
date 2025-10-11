#!/bin/bash

# 修复Docker构建问题

echo "🔧 修复Docker构建问题..."

# 进入项目目录
if [ -d "ipv6-wireguard-manager" ]; then
    cd ipv6-wireguard-manager
    echo "📁 进入项目目录: $(pwd)"
else
    echo "❌ 项目目录不存在"
    exit 1
fi

# 检查Docker Compose命令
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    echo "❌ Docker Compose 未找到"
    exit 1
fi

echo "   使用命令: $COMPOSE_CMD"

# 停止现有服务
echo "🛑 停止现有服务..."
$COMPOSE_CMD down

# 清理Docker缓存
echo "🧹 清理Docker缓存..."
docker system prune -f

# 重新构建镜像
echo "🔨 重新构建镜像..."
$COMPOSE_CMD build --no-cache

# 启动服务
echo "🚀 启动服务..."
$COMPOSE_CMD up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 检查服务状态
echo "🔍 检查服务状态..."
$COMPOSE_CMD ps

# 检查服务日志
echo "📋 检查服务日志..."
echo "=== 后端日志 ==="
$COMPOSE_CMD logs backend | tail -20

echo "=== 前端日志 ==="
$COMPOSE_CMD logs frontend | tail -20

echo ""
echo "🎉 修复完成！"
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
