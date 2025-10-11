@echo off
chcp 65001 >nul

REM IPv6 WireGuard Manager 恢复脚本 (Windows)

if "%1"=="" (
    echo ❌ 请指定备份文件
    echo 用法: %0 ^<backup_name^>
    pause
    exit /b 1
)

set BACKUP_NAME=%1
set BACKUP_DIR=backups

if not exist "%BACKUP_DIR%\%BACKUP_NAME%" (
    echo ❌ 备份目录不存在: %BACKUP_DIR%\%BACKUP_NAME%
    pause
    exit /b 1
)

echo 🔄 开始恢复 IPv6 WireGuard Manager...

REM 停止服务
echo 🛑 停止服务...
docker-compose down

REM 恢复数据库
echo 🗄️  恢复数据库...
docker-compose up -d db
timeout /t 10 /nobreak >nul
docker-compose exec -T db psql -U ipv6wgm -d ipv6wgm < "%BACKUP_DIR%\%BACKUP_NAME%\database.sql"

REM 恢复配置文件
echo 📁 恢复配置文件...
if exist "%BACKUP_DIR%\%BACKUP_NAME%\.env" copy "%BACKUP_DIR%\%BACKUP_NAME%\.env" "backend\"
if exist "%BACKUP_DIR%\%BACKUP_NAME%\docker-compose.yml" copy "%BACKUP_DIR%\%BACKUP_NAME%\docker-compose.yml" "."

REM 恢复数据目录
echo 📊 恢复数据目录...
if exist "%BACKUP_DIR%\%BACKUP_NAME%\data" xcopy "%BACKUP_DIR%\%BACKUP_NAME%\data" "data\" /E /I /Q

REM 启动所有服务
echo 🚀 启动所有服务...
docker-compose up -d

echo ✅ 恢复完成
echo.
echo 💡 提示：
echo    - 请检查服务状态: docker-compose ps
echo    - 查看日志: scripts\logs.bat
echo.
pause
