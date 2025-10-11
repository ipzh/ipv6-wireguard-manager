@echo off
chcp 65001 >nul

REM IPv6 WireGuard Manager 一键安装脚本 (Windows)
REM 支持从GitHub克隆并自动安装

setlocal enabledelayedexpansion

REM 项目信息
set "PROJECT_NAME=IPv6 WireGuard Manager"
set "REPO_URL=https://github.com/ipzh/ipv6-wireguard-manager.git"
set "INSTALL_DIR=ipv6-wireguard-manager"

echo ==================================
echo %PROJECT_NAME% 一键安装脚本
echo ==================================
echo.

REM 检查系统要求
echo 🔍 检查系统要求...

REM 检查Docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker 未安装
    echo 请先安装 Docker Desktop: https://docs.docker.com/desktop/windows/install/
    pause
    exit /b 1
)

REM 检查Docker Compose
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker Compose 未安装
    echo 请先安装 Docker Compose
    pause
    exit /b 1
)

REM 检查Docker服务状态
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker 服务未运行
    echo 请启动 Docker Desktop
    pause
    exit /b 1
)

echo ✅ Docker 环境检查通过
echo.

REM 检查端口占用
echo 🔍 检查端口占用...
netstat -an | findstr ":3000" >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  端口 3000 已被占用
)

netstat -an | findstr ":8000" >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  端口 8000 已被占用
)

netstat -an | findstr ":5432" >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  端口 5432 已被占用
)

netstat -an | findstr ":6379" >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  端口 6379 已被占用
)

echo.

REM 克隆项目
echo 📥 克隆项目...

if exist "%INSTALL_DIR%" (
    echo ⚠️  目录 %INSTALL_DIR% 已存在
    set /p "choice=是否删除现有目录并重新安装? (y/N): "
    if /i "!choice!"=="y" (
        rmdir /s /q "%INSTALL_DIR%"
    ) else (
        echo 使用现有目录
        goto :setup_permissions
    )
)

git clone "%REPO_URL%" "%INSTALL_DIR%"
if %errorlevel% neq 0 (
    echo ❌ 克隆项目失败
    echo 请检查网络连接和Git安装
    pause
    exit /b 1
)

cd "%INSTALL_DIR%"
echo ✅ 项目克隆成功
echo.

:setup_permissions
REM 设置权限
echo 🔐 设置文件权限...

REM 创建必要的目录
if not exist "data\postgres" mkdir "data\postgres"
if not exist "data\redis" mkdir "data\redis"
if not exist "logs" mkdir "logs"
if not exist "uploads" mkdir "uploads"
if not exist "backups" mkdir "backups"

echo ✅ 目录创建完成
echo.

REM 配置环境
echo ⚙️  配置环境...

REM 检查环境配置文件
if not exist "backend\.env" (
    if exist "backend\env.example" (
        copy "backend\env.example" "backend\.env" >nul
        echo ✅ 环境配置文件已创建
    ) else (
        echo ⚠️  未找到环境配置文件模板
    )
)

REM 生成随机密码
set "SECRET_KEY=ipv6wgm-secret-key-%RANDOM%-%RANDOM%"
set "DB_PASSWORD=ipv6wgm-db-pass-%RANDOM%-%RANDOM%"

REM 更新环境配置
if exist "backend\.env" (
    powershell -Command "(Get-Content 'backend\.env') -replace 'your-super-secret-key-for-jwt', '%SECRET_KEY%' | Set-Content 'backend\.env'"
    powershell -Command "(Get-Content 'backend\.env') -replace 'ipv6wgm', '%DB_PASSWORD%' | Set-Content 'backend\.env'"
    echo ✅ 环境配置已更新
    echo 🔑 数据库密码: %DB_PASSWORD%
    echo 🔑 JWT密钥: %SECRET_KEY%
)

echo.

REM 启动服务
echo 🚀 启动服务...

docker-compose up -d
if %errorlevel% neq 0 (
    echo ❌ 启动服务失败
    echo 请检查Docker配置和端口占用
    pause
    exit /b 1
)

echo ✅ 服务启动成功
echo.

REM 等待服务启动
echo ⏳ 等待服务启动...
timeout /t 15 /nobreak >nul

REM 检查服务状态
docker-compose ps
echo.

REM 初始化数据库
echo 🗄️  初始化数据库...
timeout /t 10 /nobreak >nul

docker-compose exec -T backend python -c "import asyncio; from app.core.init_db import init_db; asyncio.run(init_db())" 2>nul
if %errorlevel% equ 0 (
    echo ✅ 数据库初始化成功
) else (
    echo ⚠️  数据库初始化可能失败，请手动检查
)

echo.

REM 验证安装
echo 🔍 验证安装...

REM 检查服务健康状态
curl -s http://localhost:8000 >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ 后端服务正常
) else (
    echo ❌ 后端服务异常
)

curl -s http://localhost:3000 >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ 前端服务正常
) else (
    echo ❌ 前端服务异常
)

echo.

REM 显示安装结果
echo ==================================
echo 🎉 安装完成！
echo ==================================
echo.
echo 📋 访问信息：
echo    - 前端界面: http://localhost:3000
echo    - 后端API: http://localhost:8000
echo    - API文档: http://localhost:8000/docs
echo.
echo 🔑 默认登录信息：
echo    用户名: admin
echo    密码: admin123
echo.
echo 🛠️  管理命令：
echo    查看状态: scripts\status.bat
echo    查看日志: scripts\logs.bat
echo    停止服务: scripts\stop.bat
echo    重启服务: scripts\stop.bat ^&^& scripts\start.bat
echo.
echo ⚠️  安全提醒：
echo    请在生产环境中修改默认密码
echo    配置文件位置: backend\.env
echo.

pause
