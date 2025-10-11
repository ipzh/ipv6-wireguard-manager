@echo off
chcp 65001 >nul

REM IPv6 WireGuard Manager 状态检查脚本 (Windows)

echo 📊 IPv6 WireGuard Manager 状态检查
echo ==================================

REM 检查Docker服务状态
echo 🐳 Docker 服务状态：
docker-compose ps

echo.

REM 检查服务健康状态
echo 🏥 服务健康检查：

REM 检查后端API
echo -n 后端API: 
curl -s http://localhost:8000/health >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ 正常
) else (
    echo ❌ 异常
)

REM 检查前端
echo -n 前端服务: 
curl -s http://localhost:3000 >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ 正常
) else (
    echo ❌ 异常
)

REM 检查数据库连接
echo -n 数据库连接: 
docker-compose exec -T db pg_isready -U ipv6wgm >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ 正常
) else (
    echo ❌ 异常
)

REM 检查Redis连接
echo -n Redis连接: 
docker-compose exec -T redis redis-cli ping >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ 正常
) else (
    echo ❌ 异常
)

echo.

REM 显示资源使用情况
echo 💻 资源使用情况：
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

echo.

REM 显示磁盘使用情况
echo 💾 磁盘使用情况：
wmic logicaldisk get size,freespace,caption

echo.

REM 显示最近日志
echo 📝 最近日志 (最后10行)：
docker-compose logs --tail=10

echo.
pause
