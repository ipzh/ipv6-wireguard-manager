@echo off
chcp 65001 >nul

REM IPv6 WireGuard Manager 开发环境启动脚本 (Windows)

echo 🛠️  启动 IPv6 WireGuard Manager 开发环境...

REM 检查环境
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python 未安装
    pause
    exit /b 1
)

node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js 未安装
    pause
    exit /b 1
)

REM 启动数据库和Redis
echo 🗄️  启动数据库和Redis...
docker-compose up -d db redis

REM 等待数据库启动
echo ⏳ 等待数据库启动...
timeout /t 10 /nobreak >nul

REM 安装后端依赖
echo 📦 安装后端依赖...
cd backend
if not exist "venv" (
    python -m venv venv
)
call venv\Scripts\activate.bat
pip install -r requirements.txt

REM 初始化数据库
echo 🗄️  初始化数据库...
python -c "import asyncio; from app.core.init_db import init_db; asyncio.run(init_db())"

REM 启动后端开发服务器
echo 🚀 启动后端开发服务器...
start "Backend Server" cmd /k "venv\Scripts\activate.bat && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"

cd ..

REM 安装前端依赖
echo 📦 安装前端依赖...
cd frontend
if not exist "node_modules" (
    npm install
)

REM 启动前端开发服务器
echo 🚀 启动前端开发服务器...
start "Frontend Server" cmd /k "npm run dev"

cd ..

echo ✅ 开发环境启动完成！
echo.
echo 📋 服务信息：
echo    - 前端开发服务器: http://localhost:3000
echo    - 后端API: http://localhost:8000
echo    - API文档: http://localhost:8000/docs
echo.
echo 🛑 停止开发环境: 关闭所有命令行窗口
echo.
pause
