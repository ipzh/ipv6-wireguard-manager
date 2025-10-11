#!/bin/bash

# IPv6 WireGuard Manager 启动脚本

set -e

echo "🚀 启动 IPv6 WireGuard Manager..."

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

# 检查Docker Compose是否安装
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

# 创建必要的目录
echo "📁 创建必要的目录..."
mkdir -p data/postgres
mkdir -p data/redis
mkdir -p logs
mkdir -p uploads

# 设置权限
chmod 755 data/postgres
chmod 755 data/redis
chmod 755 logs
chmod 755 uploads

# 检查环境配置文件
if [ ! -f "backend/.env" ]; then
    echo "📝 创建环境配置文件..."
    cp backend/env.example backend/.env
    echo "⚠️  请编辑 backend/.env 文件配置数据库密码等参数"
fi

# 启动服务
echo "🐳 启动 Docker 服务..."
docker-compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose ps

# 初始化数据库
echo "🗄️  初始化数据库..."
docker-compose exec backend python -c "
import asyncio
from app.core.init_db import init_db
asyncio.run(init_db())
"

echo "✅ IPv6 WireGuard Manager 启动完成！"
echo ""
echo "📋 服务信息："
echo "   - 前端地址: http://localhost:3000"
echo "   - 后端API: http://localhost:8000"
echo "   - API文档: http://localhost:8000/docs"
echo "   - 数据库: localhost:5432"
echo "   - Redis: localhost:6379"
echo ""
echo "🔑 默认登录信息："
echo "   用户名: admin"
echo "   密码: admin123"
echo ""
echo "📖 查看日志: docker-compose logs -f"
echo "🛑 停止服务: docker-compose down"
