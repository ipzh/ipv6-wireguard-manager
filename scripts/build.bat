@echo off
chcp 65001 >nul

REM IPv6 WireGuard Manager 构建脚本 (Windows)

echo 🔨 构建 IPv6 WireGuard Manager...

REM 构建后端镜像
echo 🐳 构建后端镜像...
docker-compose build backend

REM 构建前端镜像
echo 🐳 构建前端镜像...
docker-compose build frontend

REM 构建所有镜像
echo 🐳 构建所有镜像...
docker-compose build

echo ✅ 构建完成
echo.
echo 💡 提示：
echo    - 启动服务: scripts\start.bat
echo    - 查看镜像: docker images
echo.
pause
