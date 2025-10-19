@echo off
REM IPv6 WireGuard Manager API 部署和启动脚本 (Windows)

setlocal enabledelayedexpansion

REM 设置颜色（Windows 10+）
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "RED=%ESC%[31m"
set "GREEN=%ESC%[32m"
set "YELLOW=%ESC%[33m"
set "BLUE=%ESC%[34m"
set "NC=%ESC%[0m"

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

REM 检查Python环境
:check_python
call :log_info "检查Python环境..."

python --version >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "未找到Python，请先安装Python 3.8+"
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
call :log_success "Python版本: %PYTHON_VERSION%"

REM 检查Python版本
python -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)" >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "Python版本过低，需要 >= 3.8"
    exit /b 1
)

call :log_success "Python版本满足要求 (>= 3.8)"
goto :eof

REM 检查依赖
:check_dependencies
call :log_info "检查系统依赖..."

REM 检查pip
pip --version >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "pip未安装，请先安装pip"
    exit /b 1
)
call :log_success "pip已安装"

REM 检查MySQL（可选）
mysql --version >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "MySQL已安装"
) else (
    call :log_warning "MySQL未安装，请确保数据库服务可用"
)
goto :eof

REM 安装Python依赖
:install_dependencies
call :log_info "安装Python依赖..."

REM 创建虚拟环境（如果不存在）
if not exist "venv" (
    call :log_info "创建虚拟环境..."
    python -m venv venv
)

REM 激活虚拟环境
call venv\Scripts\activate.bat

REM 升级pip
call :log_info "升级pip..."
python -m pip install --upgrade pip

REM 安装依赖
if exist "requirements-simple.txt" (
    call :log_info "使用简化依赖文件安装..."
    pip install -r requirements-simple.txt
) else if exist "requirements.txt" (
    call :log_info "使用完整依赖文件安装..."
    pip install -r requirements.txt
) else (
    call :log_error "未找到依赖文件"
    exit /b 1
)

call :log_success "依赖安装完成"
goto :eof

REM 配置环境
:setup_environment
call :log_info "配置环境..."

REM 创建.env文件（如果不存在）
if not exist ".env" (
    if exist "env.example" (
        call :log_info "创建.env文件..."
        copy env.example .env
        call :log_warning "请编辑.env文件配置数据库连接信息"
    ) else (
        call :log_warning "未找到env.example文件，请手动创建.env文件"
    )
)

REM 创建必要的目录
if not exist "logs" mkdir logs
if not exist "uploads" mkdir uploads
if not exist "wireguard" mkdir wireguard
if not exist "wireguard\clients" mkdir wireguard\clients

call :log_success "目录创建完成"
goto :eof

REM 初始化数据库
:init_database
call :log_info "初始化数据库..."

REM 激活虚拟环境
call venv\Scripts\activate.bat

REM 运行数据库初始化
if exist "init_database_simple.py" (
    call :log_info "运行简化数据库初始化..."
    python init_database_simple.py
) else if exist "init_database.py" (
    call :log_info "运行完整数据库初始化..."
    python init_database.py
) else (
    call :log_warning "未找到数据库初始化脚本"
)
goto :eof

REM 启动API服务
:start_api
call :log_info "启动API服务..."

REM 激活虚拟环境
call venv\Scripts\activate.bat

REM 检查API服务是否已经在运行
tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *uvicorn*" >nul 2>&1
if %errorlevel% equ 0 (
    call :log_warning "API服务已在运行，停止现有服务..."
    taskkill /F /IM python.exe /FI "WINDOWTITLE eq *uvicorn*" >nul 2>&1
    timeout /t 2 >nul
)

REM 启动API服务
if exist "run_api.py" (
    call :log_info "使用run_api.py启动服务..."
    start /B python run_api.py > logs\api.log 2>&1
) else (
    call :log_info "使用uvicorn直接启动服务..."
    start /B uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload > logs\api.log 2>&1
)

REM 等待服务启动
call :log_info "等待服务启动..."
timeout /t 5 >nul

REM 检查服务状态
tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *uvicorn*" >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "API服务启动成功"
    call :log_info "服务日志: logs\api.log"
    call :log_info "API文档: http://localhost:8000/docs"
    call :log_info "健康检查: http://localhost:8000/health"
) else (
    call :log_error "API服务启动失败，请检查日志"
    exit /b 1
)
goto :eof

REM 测试API服务
:test_api
call :log_info "测试API服务..."

REM 激活虚拟环境
call venv\Scripts\activate.bat

REM 等待服务完全启动
timeout /t 3 >nul

REM 运行API测试
if exist "test_api.py" (
    python test_api.py
) else (
    call :log_warning "未找到API测试脚本"
)
goto :eof

REM 显示状态
:show_status
call :log_info "服务状态:"

tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *uvicorn*" >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "API服务: 运行中"
    echo   端口: 8000
    echo   文档: http://localhost:8000/docs
    echo   健康检查: http://localhost:8000/health
) else (
    call :log_error "API服务: 未运行"
)
goto :eof

REM 停止服务
:stop_api
call :log_info "停止API服务..."

tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *uvicorn*" >nul 2>&1
if %errorlevel% equ 0 (
    taskkill /F /IM python.exe /FI "WINDOWTITLE eq *uvicorn*" >nul 2>&1
    call :log_success "API服务已停止"
) else (
    call :log_warning "API服务未运行"
)
goto :eof

REM 重启服务
:restart_api
call :log_info "重启API服务..."
call :stop_api
timeout /t 2 >nul
call :start_api
goto :eof

REM 显示帮助
:show_help
echo IPv6 WireGuard Manager API 部署脚本 (Windows)
echo.
echo 用法: %0 [命令]
echo.
echo 命令:
echo   install     - 安装依赖和配置环境
echo   init        - 初始化数据库
echo   start       - 启动API服务
echo   stop        - 停止API服务
echo   restart     - 重启API服务
echo   test        - 测试API服务
echo   status      - 显示服务状态
echo   deploy      - 完整部署（安装+初始化+启动+测试）
echo   help        - 显示此帮助信息
echo.
goto :eof

REM 主函数
:main
if "%1"=="install" (
    call :check_python
    call :check_dependencies
    call :install_dependencies
    call :setup_environment
) else if "%1"=="init" (
    call :init_database
) else if "%1"=="start" (
    call :start_api
) else if "%1"=="stop" (
    call :stop_api
) else if "%1"=="restart" (
    call :restart_api
) else if "%1"=="test" (
    call :test_api
) else if "%1"=="status" (
    call :show_status
) else if "%1"=="deploy" (
    call :check_python
    call :check_dependencies
    call :install_dependencies
    call :setup_environment
    call :init_database
    call :start_api
    call :test_api
    call :show_status
) else (
    call :show_help
)
goto :eof

REM 运行主函数
call :main %1
