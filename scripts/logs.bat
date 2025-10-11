@echo off
chcp 65001 >nul

REM IPv6 WireGuard Manager 日志查看脚本 (Windows)

echo 📖 查看 IPv6 WireGuard Manager 日志...

REM 检查参数
if "%1"=="" (
    echo 显示所有服务日志...
    docker-compose logs -f
) else (
    if "%1"=="backend" (
        echo 显示后端日志...
        docker-compose logs -f backend
    ) else if "%1"=="frontend" (
        echo 显示前端日志...
        docker-compose logs -f frontend
    ) else if "%1"=="db" (
        echo 显示数据库日志...
        docker-compose logs -f db
    ) else if "%1"=="redis" (
        echo 显示Redis日志...
        docker-compose logs -f redis
    ) else (
        echo 显示 %1 服务日志...
        docker-compose logs -f %1
    )
)
