@echo off
setlocal enabledelayedexpansion

:: Windows数据库修复脚本
:: 解决数据库配置冲突和权限问题

set LOG_FILE=windows-database-fix.log
set REPORT_FILE=windows-database-fix-report.txt

:: 日志函数
:log
    echo [%date% %time%] %*
    echo [%date% %time%] %* >> "%LOG_FILE%"
    goto :eof

:: 错误处理函数
:error_exit
    call :log "[ERROR] %*"
    echo 修复失败: %* >> "%REPORT_FILE%"
    exit /b 1

:: 成功函数
:success
    call :log "[SUCCESS] %*"
    echo 修复成功: %* >> "%REPORT_FILE%"
    goto :eof

:: 信息函数
:info
    call :log "[INFO] %*"
    echo 信息: %* >> "%REPORT_FILE%"
    goto :eof

:: 开始修复
call :log "开始Windows数据库修复..."

:: 1. 检查当前工作目录
if not exist "backend" (
    call :error_exit "请在项目根目录运行此脚本"
)

:: 2. 修复应用配置
call :info "修复应用数据库配置..."

:: 备份原始配置
if exist "backend\app\core\config.py" (
    copy "backend\app\core\config.py" "backend\app\core\config.py.backup" >nul 2>&1
    call :info "配置文件已备份"
)

:: 检查是否安装了PostgreSQL
set POSTGRESQL_INSTALLED=0
for /f "tokens=*" %%i in ('sc query postgresql-x64-15 2^>nul ^| find "STATE"') do set POSTGRESQL_INSTALLED=1

if "!POSTGRESQL_INSTALLED!"=="1" (
    call :info "检测到PostgreSQL服务，检查服务状态..."
    
    :: 检查PostgreSQL服务状态
    for /f "tokens=*" %%i in ('sc query postgresql-x64-15 ^| find "RUNNING"') do (
        call :info "PostgreSQL服务正在运行"
        
        :: 使用PostgreSQL配置
        call :info "配置应用使用PostgreSQL..."
        
        echo # 数据库配置> backend\.env
        echo DATABASE_URL=postgresql://ipv6wgm:password@localhost:5432/ipv6wgm>> backend\.env
        echo REDIS_URL=redis://localhost:6379/0>> backend\.env
        echo.>> backend\.env
        echo # 应用配置>> backend\.env
        echo DEBUG=false>> backend\.env
        echo LOG_LEVEL=INFO>> backend\.env
        
        :: 生成随机密钥
        for /f %%a in ('powershell -Command "-join ((65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,48,49,50,51,52,53,54,55,56,57) | Get-Random -Count 32 | %% {[char]%%_})"') do set SECRET_KEY=%%a
        echo SECRET_KEY=!SECRET_KEY!>> backend\.env
        echo.>> backend\.env
        echo # WireGuard配置>> backend\.env
        echo WIREGUARD_CONFIG_DIR=C:\ProgramData\wireguard>> backend\.env
        echo WIREGUARD_CLIENTS_DIR=C:\ProgramData\wireguard\clients>> backend\.env
        
        call :success "PostgreSQL环境配置完成"
    )
) else (
    :: 使用SQLite配置
    call :info "配置应用使用SQLite..."
    
    echo # 数据库配置> backend\.env
    echo DATABASE_URL=sqlite:///./ipv6_wireguard.db>> backend\.env
    echo REDIS_URL=redis://localhost:6379/0>> backend\.env
    echo.>> backend\.env
    echo # 应用配置>> backend\.env
    echo DEBUG=false>> backend\.env
    echo LOG_LEVEL=INFO>> backend\.env
    
    :: 生成随机密钥
    for /f %%a in ('powershell -Command "-join ((65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,48,49,50,51,52,53,54,55,56,57) | Get-Random -Count 32 | %% {[char]%%_})"') do set SECRET_KEY=%%a
    echo SECRET_KEY=!SECRET_KEY!>> backend\.env
    echo.>> backend\.env
    echo # WireGuard配置>> backend\.env
    echo WIREGUARD_CONFIG_DIR=C:\ProgramData\wireguard>> backend\.env
    echo WIREGUARD_CLIENTS_DIR=C:\ProgramData\wireguard\clients>> backend\.env
    
    call :success "SQLite环境配置完成"
)

:: 3. 测试修复结果
call :info "测试修复结果..."

cd backend

:: 检查Python环境
if exist "venv" (
    call venv\Scripts\activate.bat
    
    :: 测试数据库连接
    python -c "
from app.core.database import sync_engine
from sqlalchemy import text
try:
    with sync_engine.connect() as conn:
        result = conn.execute(text('SELECT 1'))
        print('数据库连接测试成功')
except Exception as e:
    print(f'数据库连接失败: {e}')
    exit(1)
" >nul 2>&1
    if errorlevel 1 (
        call :error_exit "数据库连接测试失败"
    ) else (
        call :success "数据库连接测试成功"
    )
    
    :: 测试应用启动
    python -c "
from app.main import app
print('应用导入成功')
" >nul 2>&1
    if errorlevel 1 (
        call :error_exit "应用导入测试失败"
    ) else (
        call :success "应用导入测试成功"
    )
    
    call deactivate
) else (
    call :info "Python虚拟环境不存在，跳过测试"
)

cd ..

:: 4. 生成修复报告
call :log "生成修复报告..."

echo === Windows数据库修复报告 === >> "%REPORT_FILE%"
echo 修复时间: %date% %time% >> "%REPORT_FILE%"
echo 修复状态: 完成 >> "%REPORT_FILE%"
echo. >> "%REPORT_FILE%"

:: 检查关键文件
if exist "backend\.env" (
    echo 环境配置文件: 已创建 >> "%REPORT_FILE%"
    for /f "tokens=*" %%i in ('type backend\.env ^| find "DATABASE_URL"') do echo 数据库配置: %%i >> "%REPORT_FILE%"
) else (
    echo 环境配置文件: 缺失 >> "%REPORT_FILE%"
)

if "!POSTGRESQL_INSTALLED!"=="1" (
    echo PostgreSQL状态: 检测到服务 >> "%REPORT_FILE%"
) else (
    echo PostgreSQL状态: 未检测到（使用SQLite） >> "%REPORT_FILE%"
)

call :log "Windows数据库修复完成！"
echo.
echo === 修复完成 ===
echo 日志文件: %LOG_FILE%
echo 报告文件: %REPORT_FILE%
echo.
echo 下一步操作:
if "!POSTGRESQL_INSTALLED!"=="1" (
    echo 1. PostgreSQL已配置完成，可以启动服务
) else (
    echo 1. 使用SQLite模式，数据库文件将保存在backend\ipv6_wireguard.db
)
echo 2. 启动后端服务: cd backend ^&^& venv\Scripts\activate ^&^& python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
echo 3. 启动前端服务: cd frontend ^&^& npm run dev

pause