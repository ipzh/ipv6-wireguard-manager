#!/bin/bash

# IPv6 WireGuard Manager 测试脚本

set -e

echo "🧪 运行 IPv6 WireGuard Manager 测试..."

# 检查环境
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 未安装"
    exit 1
fi

# 启动测试数据库
echo "🗄️  启动测试数据库..."
docker-compose -f docker-compose.test.yml up -d db

# 等待数据库启动
echo "⏳ 等待数据库启动..."
sleep 10

# 运行后端测试
echo "🧪 运行后端测试..."
cd backend
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install -r requirements.txt
pip install pytest pytest-asyncio httpx

# 运行测试
pytest tests/ -v --tb=short

cd ..

# 运行前端测试
echo "🧪 运行前端测试..."
cd frontend
if [ ! -d "node_modules" ]; then
    npm install
fi

# 运行测试
npm test -- --coverage --watchAll=false

cd ..

# 停止测试数据库
echo "🛑 停止测试数据库..."
docker-compose -f docker-compose.test.yml down

echo "✅ 测试完成"
