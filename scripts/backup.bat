@echo off
chcp 65001 >nul

REM IPv6 WireGuard Manager 备份脚本 (Windows)

set BACKUP_DIR=backups
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "TIMESTAMP=%YYYY%%MM%%DD%_%HH%%Min%%Sec%"
set "BACKUP_NAME=ipv6wgm_backup_%TIMESTAMP%"

echo 💾 开始备份 IPv6 WireGuard Manager...

REM 创建备份目录
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
if not exist "%BACKUP_DIR%\%BACKUP_NAME%" mkdir "%BACKUP_DIR%\%BACKUP_NAME%"

REM 备份数据库
echo 🗄️  备份数据库...
docker-compose exec -T db pg_dump -U ipv6wgm ipv6wgm > "%BACKUP_DIR%\%BACKUP_NAME%\database.sql"

REM 备份配置文件
echo 📁 备份配置文件...
if exist "backend\.env" copy "backend\.env" "%BACKUP_DIR%\%BACKUP_NAME%\"
copy "docker-compose.yml" "%BACKUP_DIR%\%BACKUP_NAME%\"
if exist "backend\app\core\config.py" copy "backend\app\core\config.py" "%BACKUP_DIR%\%BACKUP_NAME%\"

REM 备份数据目录
echo 📊 备份数据目录...
if exist "data" xcopy "data" "%BACKUP_DIR%\%BACKUP_NAME%\data\" /E /I /Q

REM 创建备份信息文件
echo 📝 创建备份信息...
echo 备份时间: %date% %time% > "%BACKUP_DIR%\%BACKUP_NAME%\backup_info.txt"
echo 系统信息: %COMPUTERNAME% >> "%BACKUP_DIR%\%BACKUP_NAME%\backup_info.txt"
echo Docker版本: >> "%BACKUP_DIR%\%BACKUP_NAME%\backup_info.txt"
docker --version >> "%BACKUP_DIR%\%BACKUP_NAME%\backup_info.txt"
echo. >> "%BACKUP_DIR%\%BACKUP_NAME%\backup_info.txt"
echo 备份内容: >> "%BACKUP_DIR%\%BACKUP_NAME%\backup_info.txt"
echo - 数据库 (PostgreSQL) >> "%BACKUP_DIR%\%BACKUP_NAME%\backup_info.txt"
echo - 配置文件 >> "%BACKUP_DIR%\%BACKUP_NAME%\backup_info.txt"
echo - 数据目录 >> "%BACKUP_DIR%\%BACKUP_NAME%\backup_info.txt"

echo ✅ 备份完成: %BACKUP_DIR%\%BACKUP_NAME%
echo.
echo 💡 恢复备份: scripts\restore.bat %BACKUP_NAME%
echo.
pause
