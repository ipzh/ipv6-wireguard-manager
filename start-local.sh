#!/bin/bash

# 本地启动脚本
echo "🚀 启动本地开发环境..."

# 检查是否在正确的目录
if [ ! -f "install-robust.sh" ]; then
    echo "❌ 请在项目根目录运行此脚本"
    exit 1
fi

# 设置环境配置
echo "🔧 设置环境配置..."
chmod +x setup-env.sh
./setup-env.sh

# 启动后端
echo "🐍 启动后端服务..."
cd backend

# 检查Python虚拟环境
if [ ! -d "venv" ]; then
    echo "📦 创建Python虚拟环境..."
    python3 -m venv venv
fi

# 激活虚拟环境
source venv/bin/activate

# 安装依赖
echo "📦 安装后端依赖..."
pip install -r requirements.txt

# 启动后端服务
echo "🚀 启动后端服务..."
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload &
BACKEND_PID=$!

# 等待后端启动
echo "⏳ 等待后端启动..."
sleep 5

# 检查后端是否启动成功
if curl -s http://127.0.0.1:8000/health >/dev/null 2>&1; then
    echo "✅ 后端服务启动成功"
else
    echo "❌ 后端服务启动失败"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

# 启动前端
echo "⚛️  启动前端服务..."
cd ../frontend

# 检查Node.js环境
if ! command -v node >/dev/null 2>&1; then
    echo "❌ Node.js未安装，请先安装Node.js"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

# 安装前端依赖
echo "📦 安装前端依赖..."
npm install

# 启动前端开发服务器
echo "🚀 启动前端开发服务器..."
npm run dev &
FRONTEND_PID=$!

# 等待前端启动
echo "⏳ 等待前端启动..."
sleep 10

# 检查前端是否启动成功
if curl -s http://localhost:5173 >/dev/null 2>&1; then
    echo "✅ 前端服务启动成功"
else
    echo "❌ 前端服务启动失败"
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
    exit 1
fi

echo ""
echo "🎉 本地开发环境启动完成！"
echo ""
echo "📋 访问地址:"
echo "   前端: http://localhost:5173"
echo "   后端API: http://127.0.0.1:8000"
echo "   API文档: http://127.0.0.1:8000/docs"
echo "   健康检查: http://127.0.0.1:8000/health"
echo ""
echo "🔧 管理命令:"
echo "   停止服务: kill $BACKEND_PID $FRONTEND_PID"
echo "   查看后端日志: tail -f backend/logs/app.log"
echo "   查看前端日志: 在浏览器开发者工具中查看"
echo ""
echo "⚠️  注意事项:"
echo "   1. 确保PostgreSQL和Redis服务正在运行"
echo "   2. 确保端口8000和5173未被占用"
echo "   3. 使用Ctrl+C停止服务"
echo ""

# 等待用户输入
echo "按Enter键停止所有服务..."
read

# 停止服务
echo "🛑 停止服务..."
kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
echo "✅ 服务已停止"
