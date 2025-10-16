@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: IPv6 WireGuard Manager - 智能安装启动器 (Windows版)
:: 一键智能安装，自动配置参数并退出

title IPv6 WireGuard Manager - 智能安装

echo.
echo [SUCCESS] IPv6 WireGuard Manager - 智能安装启动器
echo.
echo [INFO] 此脚本将自动执行以下操作：
echo [INFO] 1. 检测系统环境和资源
echo [INFO] 2. 根据系统资源自动选择最佳安装类型
echo [INFO] 3. 自动配置安装参数（端口、目录等）
echo [INFO] 4. 执行安装并自动退出
echo.
echo [WARNING] 注意：安装过程可能需要几分钟，请耐心等待
echo.

:: 询问用户是否继续
set /p continue="是否继续智能安装？(y/n): "
if /i not "%continue%"=="y" (
    echo [INFO] 安装已取消
    pause
    exit /b 0
)

:: 检查是否在WSL环境中
wsl --list --quiet >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] 未检测到WSL环境
    echo [INFO] 请先安装WSL (Windows Subsystem for Linux)
    echo [INFO] 安装方法: 在PowerShell中运行: wsl --install
    echo [INFO] 或者访问: https://aka.ms/wsl2
    pause
    exit /b 1
)

:: 执行智能安装
echo [INFO] 开始智能安装...
echo.

:: 获取当前脚本所在目录
set SCRIPT_DIR=%~dp0

:: 在WSL中执行智能安装脚本
wsl -e bash -c "cd '%SCRIPT_DIR%' && ./smart_install.sh"

:: 检查安装结果
if %errorlevel% equ 0 (
    echo.
    echo [SUCCESS] 智能安装完成！
) else (
    echo.
    echo [ERROR] 安装过程中出现错误
)

echo.
pause