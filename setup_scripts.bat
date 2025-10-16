@echo off
REM IPv6 WireGuard Manager - 脚本权限设置
REM 为Linux脚本设置执行权限

echo 设置脚本执行权限...

REM 检查是否在WSL或Git Bash环境中
where bash >nul 2>&1
if %errorlevel% equ 0 (
    echo 检测到bash环境，设置Linux脚本权限...
    bash -c "chmod +x diagnose_service.sh"
    bash -c "chmod +x quick_fix_service.sh"
    bash -c "chmod +x check_api_service.sh"
    bash -c "chmod +x fix_api_service.sh"
    bash -c "chmod +x fix_php_fpm.sh"
    bash -c "chmod +x quick_fix_mysql.sh"
    bash -c "chmod +x fix_mysql_install.sh"
    bash -c "chmod +x test_system_compatibility.sh"
    bash -c "chmod +x verify_installation.sh"
    echo Linux脚本权限设置完成！
) else (
    echo 未检测到bash环境，请在Linux系统中运行以下命令：
    echo chmod +x diagnose_service.sh
    echo chmod +x quick_fix_service.sh
    echo chmod +x check_api_service.sh
    echo chmod +x fix_api_service.sh
    echo chmod +x fix_php_fpm.sh
    echo chmod +x quick_fix_mysql.sh
    echo chmod +x fix_mysql_install.sh
    echo chmod +x test_system_compatibility.sh
    echo chmod +x verify_installation.sh
)

echo.
echo 脚本权限设置完成！
echo.
echo 使用方法：
echo 1. 诊断服务问题: ./diagnose_service.sh
echo 2. 快速修复服务: ./quick_fix_service.sh
echo 3. 检查API服务: ./check_api_service.sh
echo 4. 修复API服务: ./fix_api_service.sh
echo.
pause
