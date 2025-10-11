@echo off
chcp 65001 >nul

REM IPv6 WireGuard Manager 测试脚本 (Windows)

echo 🧪 运行 IPv6 WireGuard Manager 测试...

REM 检查环境
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python 未安装
    pause
    exit /b 1
)

REM 启动测试数据库
echo 🗄️  启动测试数据库...
docker-compose -f docker-compose.test.yml up -d db

REM 等待数据库启动
echo ⏳ 等待数据库启动...
timeout /t 10 /nobreak >nul

REM 运行后端测试
echo 🧪 运行后端测试...
cd backend
if not exist "venv" (
    python -m venv venv
)
call venv\Scripts\activate.bat
pip install -r requirements.txt
pip install pytest pytest-asyncio httpx

REM 运行测试
pytest tests/ -v --tb=short

cd ..

REM 运行前端测试
echo 🧪 运行前端测试...
cd frontend
if not exist "node_modules" (
    npm install
)

REM 运行测试
npm test -- --coverage --watchAll=false

cd ..

REM 停止测试数据库
echo 🛑 停止测试数据库...
docker-compose -f docker-compose.test.yml down

echo ✅ 测试完成
echo.
pause
