@echo off
REM IPv6 WireGuard Manager 一键检查工具 (Windows版本)
REM 一键检查所有问题并生成综合诊断报告

echo 🔍 IPv6 WireGuard Manager 一键检查工具
echo ========================================
echo.

REM 检查Python是否可用
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Python未安装或不在PATH中
    echo 请先安装Python并添加到PATH
    pause
    exit /b 1
)

REM 检查必要的Python包
echo [INFO] 检查Python依赖包...
python -c "import psutil, requests" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] 缺少必要的Python包，正在安装...
    pip install psutil requests
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] 包安装失败
        pause
        exit /b 1
    )
)

REM 运行一键检查
echo [INFO] 开始运行一键检查...
python scripts\one_click_check.py

REM 检查退出码
if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] ✅ 所有检查通过，系统运行正常！
) else if %ERRORLEVEL% EQU 1 (
    echo.
    echo [ERROR] ❌ 发现严重问题，需要修复！
) else if %ERRORLEVEL% EQU 2 (
    echo.
    echo [WARNING] ⚠️ 发现警告，建议检查！
)

echo.
echo 检查完成！详细报告已保存到当前目录
pause
