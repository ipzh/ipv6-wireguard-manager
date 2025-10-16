@echo off
REM IPv6 WireGuard Manager - 诊断脚本设置批处理文件
REM 在Windows环境中设置诊断脚本的执行权限

echo 设置诊断脚本权限...

REM 设置shell脚本权限（在WSL或Git Bash中）
if exist "deep_api_diagnosis.sh" (
    echo 找到 deep_api_diagnosis.sh
    wsl chmod +x deep_api_diagnosis.sh 2>nul || echo 注意: 需要在WSL或Linux环境中运行
)

if exist "comprehensive_api_diagnosis.sh" (
    echo 找到 comprehensive_api_diagnosis.sh
    wsl chmod +x comprehensive_api_diagnosis.sh 2>nul || echo 注意: 需要在WSL或Linux环境中运行
)

if exist "quick_fix_wireguard_permissions.sh" (
    echo 找到 quick_fix_wireguard_permissions.sh
    wsl chmod +x quick_fix_wireguard_permissions.sh 2>nul || echo 注意: 需要在WSL或Linux环境中运行
)

REM Python脚本不需要设置执行权限，但可以检查
if exist "deep_code_analysis.py" (
    echo 找到 deep_code_analysis.py
    python --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo Python环境可用
    ) else (
        echo 警告: Python环境不可用
    )
)

echo.
echo 诊断脚本设置完成！
echo.
echo 使用方法:
echo 1. 在Linux环境中运行:
echo    ./comprehensive_api_diagnosis.sh
echo.
echo 2. 在Windows WSL中运行:
echo    wsl ./comprehensive_api_diagnosis.sh
echo.
echo 3. 单独运行代码分析:
echo    python deep_code_analysis.py
echo.
pause
