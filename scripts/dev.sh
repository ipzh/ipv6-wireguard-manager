#!/bin/bash

# IPv6 WireGuard Manager 开发环境启动脚本

echo "🛠️  启动 IPv6 WireGuard Manager 开发环境..."

# 检查环境
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 未安装"
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装"
    exit 1
fi

# 启动数据库和Redis
echo "🗄️  启动数据库和Redis..."
docker-compose up -d db redis

# 等待数据库启动
echo "⏳ 等待数据库启动..."
sleep 10

# 安装后端依赖
echo "📦 安装后端依赖..."
cd backend
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install -r requirements.txt

# 初始化数据库
echo "🗄️  初始化数据库..."
python -c "
import asyncio
from app.core.init_db import init_db
asyncio.run(init_db())
"

# 启动后端开发服务器
echo "🚀 启动后端开发服务器..."
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!

cd ..

# 安装前端依赖
echo "📦 安装前端依赖..."
cd frontend
if [ ! -d "node_modules" ]; then
    npm install
fi

# 启动前端开发服务器
echo "🚀 启动前端开发服务器..."
npm run dev &
FRONTEND_PID=$!

cd ..

echo "✅ 开发环境启动完成！"
echo ""
echo "📋 服务信息："
echo "   - 前端开发服务器: http://localhost:3000"
echo "   - 后端API: http://localhost:8000"
echo "   - API文档: http://localhost:8000/docs"
echo ""
echo "🛑 停止开发环境: Ctrl+C"

# 等待用户中断
trap "echo '🛑 停止开发环境...'; kill $BACKEND_PID $FRONTEND_PID; docker-compose down; exit" INT
wait
