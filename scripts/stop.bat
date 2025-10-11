@echo off
chcp 65001 >nul

REM IPv6 WireGuard Manager 停止脚本 (Windows)

echo 🛑 停止 IPv6 WireGuard Manager...

REM 停止所有服务
docker-compose down

echo ✅ 所有服务已停止
echo.
echo 💡 提示：
echo    - 数据已保存到 data\ 目录
echo    - 重新启动: scripts\start.bat
echo    - 完全清理: scripts\clean.bat
echo.
pause
