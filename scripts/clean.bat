@echo off
chcp 65001 >nul

REM IPv6 WireGuard Manager 清理脚本 (Windows)

echo 🧹 清理 IPv6 WireGuard Manager 数据...

REM 停止所有服务
echo 🛑 停止服务...
docker-compose down

REM 删除容器和网络
echo 🗑️  删除容器和网络...
docker-compose down --volumes --remove-orphans

REM 删除镜像
echo 🗑️  删除镜像...
docker-compose down --rmi all

REM 清理Docker系统
echo 🧹 清理Docker系统...
docker system prune -f

REM 删除数据目录
echo 🗑️  删除数据目录...
if exist "data" rmdir /s /q "data"
if exist "logs" rmdir /s /q "logs"
if exist "uploads" rmdir /s /q "uploads"

echo ✅ 清理完成
echo.
echo 💡 提示：
echo    - 所有数据已被删除
echo    - 重新启动: scripts\start.bat
echo.
pause
