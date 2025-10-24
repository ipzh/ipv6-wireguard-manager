@echo off
REM IPv6 WireGuard Manager 一键检查工具 - 远程下载版本
REM 自动下载并运行一键检查工具

echo 🔍 IPv6 WireGuard Manager 一键检查工具 - 远程下载版本
echo =====================================================
echo.

REM 设置下载URL
set DOWNLOAD_URL=https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/one_click_check_simple.bat
set LOCAL_FILE=one_click_check_simple.bat

echo [INFO] 正在下载一键检查工具...
echo [INFO] 下载地址: %DOWNLOAD_URL%
echo.

REM 检查是否有PowerShell
powershell -Command "Get-Host" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [INFO] 使用PowerShell下载...
    powershell -Command "try { Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%LOCAL_FILE%' -UseBasicParsing; Write-Host '[SUCCESS] 下载完成' } catch { Write-Host '[ERROR] 下载失败:' $_.Exception.Message }"
) else (
    echo [INFO] 使用curl下载...
    curl -o "%LOCAL_FILE%" "%DOWNLOAD_URL%"
    if %ERRORLEVEL% EQU 0 (
        echo [SUCCESS] 下载完成
    ) else (
        echo [ERROR] 下载失败
        pause
        exit /b 1
    )
)

echo.
echo [INFO] 检查下载的文件...
if exist "%LOCAL_FILE%" (
    echo [SUCCESS] ✓ 文件下载成功: %LOCAL_FILE%
    echo.
    echo [INFO] 是否立即运行检查工具? (Y/N)
    set /p choice="请输入选择: "
    
    if /i "%choice%"=="Y" (
        echo.
        echo [INFO] 正在运行一键检查工具...
        call "%LOCAL_FILE%"
    ) else (
        echo.
        echo [INFO] 文件已下载到当前目录: %LOCAL_FILE%
        echo [INFO] 您可以稍后手动运行: %LOCAL_FILE%
    )
) else (
    echo [ERROR] ✗ 文件下载失败
    pause
    exit /b 1
)

echo.
echo [INFO] 下载完成！
pause
