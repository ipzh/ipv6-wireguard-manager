@echo off
chcp 65001 >nul

REM IPv6 WireGuard Manager 启动脚本 (Windows)

echo 🚀 启动 IPv6 WireGuard Manager...

REM 检查Docker是否安装
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker 未安装，请先安装 Docker Desktop
    pause
    exit /b 1
)

REM 检查Docker Compose是否安装
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker Compose 未安装，请先安装 Docker Compose
    pause
    exit /b 1
)

REM 创建必要的目录
echo 📁 创建必要的目录...
if not exist "data\postgres" mkdir "data\postgres"
if not exist "data\redis" mkdir "data\redis"
if not exist "logs" mkdir "logs"
if not exist "uploads" mkdir "uploads"

REM 检查环境配置文件
if not exist "backend\.env" (
    echo 📝 创建环境配置文件...
    copy "backend\env.example" "backend\.env"
    echo ⚠️  请编辑 backend\.env 文件配置数据库密码等参数
)

REM 启动服务
echo 🐳 启动 Docker 服务...
docker-compose up -d

REM 等待服务启动
echo ⏳ 等待服务启动...
timeout /t 10 /nobreak >nul

REM 检查服务状态
echo 🔍 检查服务状态...
docker-compose ps

REM 初始化数据库
echo 🗄️  初始化数据库...
docker-compose exec backend python -c "import asyncio; from app.core.init_db import init_db; asyncio.run(init_db())"

echo ✅ IPv6 WireGuard Manager 启动完成！
echo.
echo 📋 服务信息：
echo    - 前端地址: http://localhost:3000
echo    - 后端API: http://localhost:8000
echo    - API文档: http://localhost:8000/docs
echo    - 数据库: localhost:5432
echo    - Redis: localhost:6379
echo.
echo 🔑 默认登录信息：
echo    用户名: admin
echo    密码: admin123
echo.
echo 📖 查看日志: docker-compose logs -f
echo 🛑 停止服务: docker-compose down
echo.
pause
