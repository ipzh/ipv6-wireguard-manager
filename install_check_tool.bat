@echo off
REM IPv6 WireGuard Manager 一键安装和检查工具
REM 自动下载、安装并运行检查工具

echo 🚀 IPv6 WireGuard Manager 一键安装和检查工具
echo ============================================
echo.

REM 设置下载URL
set BASE_URL=https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main
set CHECK_TOOL=one_click_check_simple.bat
set PYTHON_TOOL=scripts/one_click_check.py

echo [INFO] 正在下载检查工具...
echo [INFO] 下载地址: %BASE_URL%/%CHECK_TOOL%
echo.

REM 下载检查工具
powershell -Command "try { Invoke-WebRequest -Uri '%BASE_URL%/%CHECK_TOOL%' -OutFile '%CHECK_TOOL%' -UseBasicParsing; Write-Host '[SUCCESS] 检查工具下载完成' } catch { Write-Host '[ERROR] 检查工具下载失败:' $_.Exception.Message }"

if not exist "%CHECK_TOOL%" (
    echo [ERROR] 检查工具下载失败
    pause
    exit /b 1
)

echo.
echo [INFO] 正在下载Python版本检查工具...
powershell -Command "try { Invoke-WebRequest -Uri '%BASE_URL%/%PYTHON_TOOL%' -OutFile 'one_click_check.py' -UseBasicParsing; Write-Host '[SUCCESS] Python版本下载完成' } catch { Write-Host '[WARNING] Python版本下载失败，将使用基础版本' }"

echo.
echo [INFO] 正在下载使用说明...
powershell -Command "try { Invoke-WebRequest -Uri '%BASE_URL%/README_一键检查工具.md' -OutFile 'README_一键检查工具.md' -UseBasicParsing; Write-Host '[SUCCESS] 使用说明下载完成' } catch { Write-Host '[WARNING] 使用说明下载失败' }"

echo.
echo [INFO] 检查Python环境...
python --version >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] ✓ Python环境可用
    echo [INFO] 是否安装Python版本的依赖包? (Y/N)
    set /p install_python="请输入选择: "
    
    if /i "%install_python%"=="Y" (
        echo [INFO] 正在安装Python依赖包...
        pip install psutil requests
        if %ERRORLEVEL% EQU 0 (
            echo [SUCCESS] ✓ Python依赖包安装完成
        ) else (
            echo [WARNING] ⚠️ Python依赖包安装失败，将使用基础版本
        )
    )
) else (
    echo [WARNING] ⚠️ Python环境不可用，将使用基础版本
)

echo.
echo [INFO] 正在运行系统检查...
call "%CHECK_TOOL%"

echo.
echo [INFO] 安装完成！
echo [INFO] 可用的检查工具:
echo   - %CHECK_TOOL% (基础版本)
if exist "one_click_check.py" (
    echo   - one_click_check.py (Python版本，功能更全面)
)
if exist "README_一键检查工具.md" (
    echo   - README_一键检查工具.md (使用说明)
)

echo.
echo [INFO] 建议定期运行检查工具以监控系统状态
pause
