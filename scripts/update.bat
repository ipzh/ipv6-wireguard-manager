@echo off
chcp 65001 >nul

REM IPv6 WireGuard Manager 更新脚本 (Windows)

echo 🔄 更新 IPv6 WireGuard Manager...

REM 备份当前配置
echo 💾 备份当前配置...
call scripts\backup.bat

REM 停止服务
echo 🛑 停止服务...
docker-compose down

REM 拉取最新代码
echo 📥 拉取最新代码...
git pull origin main

REM 更新镜像
echo 🐳 更新镜像...
docker-compose pull

REM 重新构建镜像
echo 🔨 重新构建镜像...
docker-compose build

REM 启动服务
echo 🚀 启动服务...
docker-compose up -d

REM 等待服务启动
echo ⏳ 等待服务启动...
timeout /t 15 /nobreak >nul

REM 检查服务状态
echo 🔍 检查服务状态...
docker-compose ps

echo ✅ 更新完成
echo.
echo 💡 提示：
echo    - 查看日志: scripts\logs.bat
echo    - 检查状态: scripts\status.bat
echo.
pause
