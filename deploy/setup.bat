@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM IPv6 WireGuard Manager 部署系统快速设置脚本 (Windows版本)

set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%deploy.conf"

REM 颜色定义
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

REM 日志函数
:log_info
echo %BLUE%[INFO]%NC% %~1
goto :eof

:log_success
echo %GREEN%[SUCCESS]%NC% %~1
goto :eof

:log_warning
echo %YELLOW%[WARNING]%NC% %~1
goto :eof

:log_error
echo %RED%[ERROR]%NC% %~1
goto :eof

REM 检查依赖
:check_dependencies
call :log_info "检查系统依赖..."

set "missing_deps="

REM 检查rsync
where rsync >nul 2>&1
if errorlevel 1 (
    set "missing_deps=!missing_deps! rsync"
)

REM 检查ssh
where ssh >nul 2>&1
if errorlevel 1 (
    set "missing_deps=!missing_deps! openssh"
)

REM 检查tar
where tar >nul 2>&1
if errorlevel 1 (
    set "missing_deps=!missing_deps! tar"
)

if not "!missing_deps!"=="" (
    call :log_error "缺少以下依赖:!missing_deps!"
    call :log_info "请安装缺少的依赖后重试"
    call :log_info "建议使用 WSL 或安装 Git for Windows"
    exit /b 1
)

call :log_success "系统依赖检查通过"
goto :eof

REM 创建配置文件
:create_config
if exist "%CONFIG_FILE%" (
    call :log_warning "配置文件已存在: %CONFIG_FILE%"
    set /p "overwrite=是否覆盖现有配置? (y/N): "
    if /i not "!overwrite!"=="y" (
        call :log_info "跳过配置文件创建"
        goto :eof
    )
)

call :log_info "创建配置文件..."

(
echo # IPv6 WireGuard Manager 部署配置文件
echo # 请根据实际情况修改以下配置
echo.
echo # 远程服务器配置
echo REMOTE_HOST=your-server.com
echo REMOTE_USER=root
echo REMOTE_PORT=22
echo REMOTE_PATH=/var/www/ipv6-wireguard-manager
echo.
echo # 本地配置
echo LOCAL_FRONTEND_PATH=php-frontend
echo BACKUP_PATH=backups
echo LOG_PATH=logs
echo.
echo # 部署选项
echo CREATE_BACKUP=true
echo RESTART_SERVICES=true
echo CLEAR_CACHE=true
echo RUN_TESTS=false
echo.
echo # 服务配置
echo WEB_SERVER=nginx
echo PHP_SERVICE=php8.1-fpm
) > "%CONFIG_FILE%"

call :log_success "配置文件已创建: %CONFIG_FILE%"
call :log_warning "请编辑配置文件并设置正确的服务器信息"
goto :eof

REM 设置脚本权限
:set_permissions
call :log_info "设置脚本执行权限..."

if exist "deploy.bat" (
    call :log_info "Windows批处理脚本已准备就绪"
)

if exist "deploy.ps1" (
    call :log_info "PowerShell脚本已准备就绪"
)

call :log_success "脚本权限设置完成"
goto :eof

REM 创建SSH密钥
:create_ssh_key
set "SSH_DIR=%USERPROFILE%\.ssh"
set "KEY_FILE=%SSH_DIR%\id_rsa"

if exist "%KEY_FILE%" (
    call :log_info "SSH密钥已存在: %KEY_FILE%"
    goto :eof
)

call :log_info "创建SSH密钥..."

if not exist "%SSH_DIR%" mkdir "%SSH_DIR%"

REM 使用ssh-keygen创建密钥
ssh-keygen -t rsa -b 4096 -f "%KEY_FILE%" -N "" -C "ipv6-wireguard-deploy"

call :log_success "SSH密钥已创建: %KEY_FILE%"
call :log_info "请将公钥复制到远程服务器:"
echo ssh-copy-id -p 22 user@your-server.com
echo 或者手动复制以下公钥内容:
type "%KEY_FILE%.pub"
goto :eof

REM 测试连接
:test_connection
if not exist "%CONFIG_FILE%" (
    call :log_warning "配置文件不存在，跳过连接测试"
    goto :eof
)

REM 读取配置文件
for /f "usebackq tokens=1,2 delims==" %%a in ("%CONFIG_FILE%") do (
    if not "%%a"=="" if not "%%a:~0,1%"=="#" (
        set "%%a=%%b"
    )
)

if "%REMOTE_HOST%"=="your-server.com" (
    call :log_warning "请先配置正确的服务器信息"
    goto :eof
)

call :log_info "测试SSH连接..."

ssh -p "%REMOTE_PORT%" -o ConnectTimeout=10 -o BatchMode=yes "%REMOTE_USER%@%REMOTE_HOST%" "echo SSH连接成功" 2>nul
if errorlevel 1 (
    call :log_error "SSH连接失败"
    call :log_info "请检查以下项目:"
    echo 1. 服务器地址和端口是否正确
    echo 2. 用户名是否正确
    echo 3. SSH密钥是否已配置
    echo 4. 服务器是否允许SSH连接
) else (
    call :log_success "SSH连接测试通过"
)
goto :eof

REM 显示使用说明
:show_usage
call :log_info "部署系统设置完成！"
echo.
echo 使用方法:
echo   Windows批处理: deploy\deploy.bat production --backup
echo   PowerShell:    .\deploy\deploy.ps1 production -Backup
echo   WSL/Linux:     ./deploy/deploy.sh production --backup
echo.
echo 下一步:
echo 1. 编辑 deploy.conf 配置文件
echo 2. 配置SSH密钥认证
echo 3. 测试连接: deploy\deploy.bat production --dry-run
echo 4. 执行部署: deploy\deploy.bat production --backup
echo.
echo 更多信息请查看 README.md 文件
goto :eof

REM 主函数
:main
call :log_info "IPv6 WireGuard Manager 部署系统快速设置 (Windows版本)"
echo.

call :check_dependencies
if errorlevel 1 exit /b 1

call :create_config
call :set_permissions

set /p "create_key=是否创建SSH密钥? (y/N): "
if /i "!create_key!"=="y" call :create_ssh_key

set /p "test_conn=是否测试SSH连接? (y/N): "
if /i "!test_conn!"=="y" call :test_connection

call :show_usage

endlocal
