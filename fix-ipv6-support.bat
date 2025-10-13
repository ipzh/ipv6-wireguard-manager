@echo off
chcp 65001 >nul

:: IPv6 WireGuard Manager - IPv6支持修复脚本 (Windows版本)
:: 修复服务只监听IPv4而不监听IPv6的问题

echo ========================================
echo IPv6 WireGuard Manager - IPv6支持修复
echo ========================================
echo.

:: 检查是否以管理员权限运行
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] 此脚本需要以管理员权限运行
    echo 请右键点击脚本，选择"以管理员身份运行"
    pause
    exit /b 1
)

:: 显示当前监听状态
echo [INFO] 检查当前端口监听状态...
echo.
echo === 端口3000监听状态 ===
netstat -an | findstr ":3000"
if errorlevel 1 echo 端口3000未监听

echo === 端口3001监听状态 ===
netstat -an | findstr ":3001"
if errorlevel 1 echo 端口3001未监听

echo.

:: 检查Python HTTP服务器配置
echo [INFO] 检查Python HTTP服务器配置...

:: 检查第一个HTTP服务器（端口3000）
tasklist | findstr "python.exe" >nul
if %errorlevel% equ 0 (
    echo [INFO] Python HTTP服务器正在运行
    echo [INFO] 当前Python服务器监听IPv4地址
    echo [INFO] 要支持IPv6，需要修改启动命令
) else (
    echo [WARNING] 未找到运行的Python HTTP服务器
)

echo.

:: 提供修复建议
echo [INFO] IPv6支持修复建议：
echo 1. 对于Python HTTP服务器，使用以下命令支持IPv6：
echo    python -m http.server 3000 --bind ::
echo.
echo 2. 对于开发服务器，修改vite配置支持IPv6：
echo    在vite.config.ts中添加：
echo    server: { host: '::' }
echo.

:: 显示当前网络配置
echo [INFO] 当前网络配置：
ipconfig | findstr "IPv4"
ipconfig | findstr "IPv6"

echo.

:: 测试本地访问
echo [INFO] 测试本地访问...

:: 测试IPv4访问
echo 测试IPv4访问（127.0.0.1:3000）...
curl -s -o nul -w "%%{http_code}" http://127.0.0.1:3000 2>nul
if %errorlevel% equ 0 (
    echo [SUCCESS] IPv4本地访问正常
) else (
    echo [ERROR] IPv4本地访问失败
)

:: 测试IPv6本地访问
echo 测试IPv6访问（[::1]:3000）...
curl -s -o nul -w "%%{http_code}" http://[::1]:3000 2>nul
if %errorlevel% equ 0 (
    echo [SUCCESS] IPv6本地访问正常
) else (
    echo [WARNING] IPv6本地访问失败（可能是IPv6配置问题）
)

echo.

:: 提供完整的修复方案
echo [INFO] 完整的IPv6支持解决方案：
echo.
echo 方案1：修改现有服务器配置
echo ----------------------------------------
echo 1. 停止当前HTTP服务器
echo 2. 使用支持IPv6的命令重新启动：
echo    python -m http.server 3000 --bind ::
echo.

echo 方案2：修改Vite开发配置
echo ----------------------------------------
echo 1. 编辑 vite.config.ts
echo 2. 添加服务器配置：
echo    export default defineConfig({
    echo      server: {
    echo        host: '::',
    echo        port: 3000
    echo      }
    echo    })
echo.

echo 方案3：使用Docker（推荐用于生产环境）
echo ----------------------------------------
echo 1. 使用提供的Docker配置
echo 2. Docker默认支持IPv4和IPv6
echo.

:: 检查Windows IPv6支持
echo [INFO] 检查Windows IPv6支持...
netsh interface ipv6 show interfaces >nul 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] Windows IPv6支持已启用
) else (
    echo [WARNING] Windows IPv6支持可能未启用
    echo 如需启用IPv6，请参考：
    echo https://support.microsoft.com/zh-cn/windows/
)

echo.
echo ========================================
echo [SUCCESS] IPv6支持检查完成！
echo ========================================
echo.
echo 下一步操作：
echo 1. 根据上述方案选择适合的修复方法
echo 2. 重新启动服务以应用IPv6配置
echo 3. 测试IPv6访问：http://[::1]:3000
echo.
echo 对于远程服务器，请使用Linux版本的修复脚本：
echo fix-ipv6-support.sh
echo.

pause