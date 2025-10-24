@echo off
REM IPv6 WireGuard Manager 一键检查工具 (Windows版本 - 无Python依赖)
REM 一键检查所有问题并生成综合诊断报告

echo 🔍 IPv6 WireGuard Manager 一键检查工具
echo ========================================
echo 检查时间: %date% %time%
echo 系统平台: %OS%
echo ========================================
echo

REM 创建报告文件
set REPORT_FILE=ipv6-wireguard-manager-check-%date:~0,4%%date:~5,2%%date:~8,2%-%time:~0,2%%time:~3,2%%time:~6,2%.txt
set REPORT_FILE=%REPORT_FILE: =0%

echo IPv6 WireGuard Manager 一键检查报告 > "%REPORT_FILE%"
echo 检查时间: %date% %time% >> "%REPORT_FILE%"
echo 系统平台: %OS% >> "%REPORT_FILE%"
echo ======================================== >> "%REPORT_FILE%"
echo. >> "%REPORT_FILE%"

REM 检查计数器
set /a ISSUES=0
set /a WARNINGS=0
set /a SUCCESSES=0

echo [INFO] 开始检查系统状态...
echo.

REM 1. 检查Python进程
echo === 1. 检查Python进程 ===
tasklist /FI "IMAGENAME eq python.exe" 2>nul | find /I "python.exe" >nul
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] ✓ Python进程运行正常
    echo [SUCCESS] ✓ Python进程运行正常 >> "%REPORT_FILE%"
    set /a SUCCESSES+=1
) else (
    echo [ERROR] ✗ Python进程未运行
    echo [ERROR] ✗ Python进程未运行 >> "%REPORT_FILE%"
    set /a ISSUES+=1
)

REM 2. 检查MySQL进程
echo === 2. 检查MySQL进程 ===
tasklist /FI "IMAGENAME eq mysqld.exe" 2>nul | find /I "mysqld.exe" >nul
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] ✓ MySQL进程运行正常
    echo [SUCCESS] ✓ MySQL进程运行正常 >> "%REPORT_FILE%"
    set /a SUCCESSES+=1
) else (
    echo [ERROR] ✗ MySQL进程未运行
    echo [ERROR] ✗ MySQL进程未运行 >> "%REPORT_FILE%"
    set /a ISSUES+=1
)

REM 3. 检查Nginx进程
echo === 3. 检查Nginx进程 ===
tasklist /FI "IMAGENAME eq nginx.exe" 2>nul | find /I "nginx.exe" >nul
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] ✓ Nginx进程运行正常
    echo [SUCCESS] ✓ Nginx进程运行正常 >> "%REPORT_FILE%"
    set /a SUCCESSES+=1
) else (
    echo [WARNING] ⚠️ Nginx进程未运行
    echo [WARNING] ⚠️ Nginx进程未运行 >> "%REPORT_FILE%"
    set /a WARNINGS+=1
)

REM 4. 检查端口监听
echo === 4. 检查端口监听 ===
netstat -an | findstr ":80 " >nul
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] ✓ 端口80正在监听
    echo [SUCCESS] ✓ 端口80正在监听 >> "%REPORT_FILE%"
    set /a SUCCESSES+=1
) else (
    echo [WARNING] ⚠️ 端口80未监听
    echo [WARNING] ⚠️ 端口80未监听 >> "%REPORT_FILE%"
    set /a WARNINGS+=1
)

netstat -an | findstr ":8000 " >nul
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] ✓ 端口8000正在监听
    echo [SUCCESS] ✓ 端口8000正在监听 >> "%REPORT_FILE%"
    set /a SUCCESSES+=1
) else (
    echo [ERROR] ✗ 端口8000未监听
    echo [ERROR] ✗ 端口8000未监听 >> "%REPORT_FILE%"
    set /a ISSUES+=1
)

netstat -an | findstr ":3306 " >nul
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] ✓ 端口3306正在监听
    echo [SUCCESS] ✓ 端口3306正在监听 >> "%REPORT_FILE%"
    set /a SUCCESSES+=1
) else (
    echo [ERROR] ✗ 端口3306未监听
    echo [ERROR] ✗ 端口3306未监听 >> "%REPORT_FILE%"
    set /a ISSUES+=1
)

REM 5. 检查配置文件
echo === 5. 检查配置文件 ===
if exist ".env" (
    echo [SUCCESS] ✓ .env配置文件存在
    echo [SUCCESS] ✓ .env配置文件存在 >> "%REPORT_FILE%"
    set /a SUCCESSES+=1
) else (
    echo [ERROR] ✗ .env配置文件不存在
    echo [ERROR] ✗ .env配置文件不存在 >> "%REPORT_FILE%"
    set /a ISSUES+=1
)

if exist "env.local" (
    echo [SUCCESS] ✓ env.local配置文件存在
    echo [SUCCESS] ✓ env.local配置文件存在 >> "%REPORT_FILE%"
    set /a SUCCESSES+=1
) else (
    echo [WARNING] ⚠️ env.local配置文件不存在
    echo [WARNING] ⚠️ env.local配置文件不存在 >> "%REPORT_FILE%"
    set /a WARNINGS+=1
)

if exist "backend\init_database.py" (
    echo [SUCCESS] ✓ 数据库初始化脚本存在
    echo [SUCCESS] ✓ 数据库初始化脚本存在 >> "%REPORT_FILE%"
    set /a SUCCESSES+=1
) else (
    echo [ERROR] ✗ 数据库初始化脚本不存在
    echo [ERROR] ✗ 数据库初始化脚本不存在 >> "%REPORT_FILE%"
    set /a ISSUES+=1
)

REM 6. 检查日志目录
echo === 6. 检查日志目录 ===
if exist "logs" (
    echo [SUCCESS] ✓ 日志目录存在
    echo [SUCCESS] ✓ 日志目录存在 >> "%REPORT_FILE%"
    set /a SUCCESSES+=1
    
    REM 检查日志文件
    dir logs\*.log /B 2>nul | findstr "." >nul
    if %ERRORLEVEL% EQU 0 (
        echo [SUCCESS] ✓ 找到日志文件
        echo [SUCCESS] ✓ 找到日志文件 >> "%REPORT_FILE%"
        set /a SUCCESSES+=1
    ) else (
        echo [WARNING] ⚠️ 未找到日志文件
        echo [WARNING] ⚠️ 未找到日志文件 >> "%REPORT_FILE%"
        set /a WARNINGS+=1
    )
) else (
    echo [ERROR] ✗ 日志目录不存在
    echo [ERROR] ✗ 日志目录不存在 >> "%REPORT_FILE%"
    set /a ISSUES+=1
)

REM 7. 检查环境变量
echo === 7. 检查环境变量 ===
if defined DATABASE_URL (
    echo [SUCCESS] ✓ DATABASE_URL环境变量已设置
    echo [SUCCESS] ✓ DATABASE_URL环境变量已设置 >> "%REPORT_FILE%"
    set /a SUCCESSES+=1
) else (
    echo [ERROR] ✗ DATABASE_URL环境变量未设置
    echo [ERROR] ✗ DATABASE_URL环境变量未设置 >> "%REPORT_FILE%"
    set /a ISSUES+=1
)

if defined SERVER_HOST (
    echo [SUCCESS] ✓ SERVER_HOST环境变量已设置
    echo [SUCCESS] ✓ SERVER_HOST环境变量已设置 >> "%REPORT_FILE%"
    set /a SUCCESSES+=1
) else (
    echo [WARNING] ⚠️ SERVER_HOST环境变量未设置
    echo [WARNING] ⚠️ SERVER_HOST环境变量未设置 >> "%REPORT_FILE%"
    set /a WARNINGS+=1
)

REM 8. 检查系统资源
echo === 8. 检查系统资源 ===
echo [INFO] 内存使用情况:
wmic OS get TotalVisibleMemorySize,FreePhysicalMemory /format:table
echo [INFO] 内存使用情况: >> "%REPORT_FILE%"
wmic OS get TotalVisibleMemorySize,FreePhysicalMemory /format:table >> "%REPORT_FILE%"

echo [INFO] 磁盘使用情况:
wmic logicaldisk get size,freespace,caption
echo [INFO] 磁盘使用情况: >> "%REPORT_FILE%"
wmic logicaldisk get size,freespace,caption >> "%REPORT_FILE%"

REM 9. 检查网络连接
echo === 9. 检查网络连接 ===
curl -s --connect-timeout 5 http://localhost/ >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] ✓ Web服务可访问
    echo [SUCCESS] ✓ Web服务可访问 >> "%REPORT_FILE%"
    set /a SUCCESSES+=1
) else (
    echo [ERROR] ✗ Web服务不可访问
    echo [ERROR] ✗ Web服务不可访问 >> "%REPORT_FILE%"
    set /a ISSUES+=1
)

curl -s --connect-timeout 5 http://localhost:8000/ >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] ✓ API服务可访问
    echo [SUCCESS] ✓ API服务可访问 >> "%REPORT_FILE%"
    set /a SUCCESSES+=1
) else (
    echo [ERROR] ✗ API服务不可访问
    echo [ERROR] ✗ API服务不可访问 >> "%REPORT_FILE%"
    set /a ISSUES+=1
)

REM 10. 生成总结
echo.
echo ========================================
echo 📊 检查总结
echo ========================================
echo ✅ 成功项目: %SUCCESSES%
echo ⚠️ 警告项目: %WARNINGS%
echo ❌ 问题项目: %ISSUES%
echo ========================================

echo. >> "%REPORT_FILE%"
echo ======================================== >> "%REPORT_FILE%"
echo 📊 检查总结 >> "%REPORT_FILE%"
echo ======================================== >> "%REPORT_FILE%"
echo ✅ 成功项目: %SUCCESSES% >> "%REPORT_FILE%"
echo ⚠️ 警告项目: %WARNINGS% >> "%REPORT_FILE%"
echo ❌ 问题项目: %ISSUES% >> "%REPORT_FILE%"
echo ======================================== >> "%REPORT_FILE%"

REM 生成修复建议
echo.
echo ========================================
echo 🔧 修复建议
echo ========================================

if %ISSUES% GTR 0 (
    echo 🚨 发现以下问题需要修复:
    echo   - 检查服务是否正在运行
    echo   - 验证配置文件是否存在
    echo   - 确认环境变量已设置
    echo   - 检查端口监听状态
    echo   - 验证网络连接
)

if %WARNINGS% GTR 0 (
    echo.
    echo ⚠️ 发现以下警告:
    echo   - 建议检查Nginx服务状态
    echo   - 建议设置SERVER_HOST环境变量
    echo   - 建议创建env.local配置文件
)

if %ISSUES% EQU 0 (
    if %WARNINGS% EQU 0 (
        echo ✅ 所有检查通过，系统运行正常！
    ) else (
        echo ⚠️ 系统基本正常，但有一些警告建议处理
    )
) else (
    echo ❌ 发现严重问题，需要修复！
)

echo.
echo 📄 详细报告已保存到: %REPORT_FILE%
echo.

REM 返回退出码
if %ISSUES% GTR 0 (
    exit /b 1
) else if %WARNINGS% GTR 0 (
    exit /b 2
) else (
    exit /b 0
)
