@echo off
echo 正在验证Cookie实施方案...
echo.

REM 检查PHP是否可用
where php >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 未找到PHP命令，请确保PHP已安装并添加到系统PATH中
    echo.
    echo 如果您使用Docker运行项目，请使用以下命令:
    echo docker exec -it ipv6-wireguard-frontend php /var/www/html/tests/verify_cookie_implementation.php
    echo.
    pause
    exit /b 1
)

REM 运行验证脚本
php verify_cookie_implementation.php

echo.
echo 验证完成！
pause