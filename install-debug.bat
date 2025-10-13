@echo off
setlocal enabledelayedexpansion

:: IPv6 WireGuard Manager 调试模式安装脚本 (Windows版本)
:: 此脚本会详细记录安装过程中的所有问题，便于一次性修复

:: 配置变量
set LOG_FILE=%TEMP%\ipv6-wireguard-install-debug.log
set INSTALL_DIR=%CD%
set BACKEND_DIR=%INSTALL_DIR%\backend
set FRONTEND_DIR=%INSTALL_DIR%\frontend

:: 清空日志文件
echo. > "%LOG_FILE%"

:: 日志函数
:log
set level=%~1
set message=%~2
for /f "tokens=1-3 delims=: " %%a in ("%time%") do set timestamp=%date% %%a:%%b:%%c

echo [%timestamp%] [%level%] %message% >> "%LOG_FILE%"

if "%level%"=="INFO" (
    echo [INFO] %message%
) else if "%level%"=="SUCCESS" (
    echo [SUCCESS] %message%
) else if "%level%"=="WARNING" (
    echo [WARNING] %message%
) else if "%level%"=="ERROR" (
    echo [ERROR] %message%
) else if "%level%"=="DEBUG" (
    echo [DEBUG] %message%
)

goto :eof

:: 检查命令执行状态
:check_command
set cmd=%~1
set description=%~2

call :log "DEBUG" "执行命令: %cmd%"

echo [COMMAND] %cmd% >> "%LOG_FILE%"
%cmd% >> "%LOG_FILE%" 2>&1
set exit_code=!errorlevel!

if !exit_code! equ 0 (
    call :log "SUCCESS" "%description% 完成"
) else (
    call :log "ERROR" "%description% 失败 (退出码: !exit_code!)"
)

goto :eof

:: 检查系统环境
:check_system
call :log "INFO" "检查系统环境..."

:: 检查操作系统
ver >> "%LOG_FILE%" 2>&1
call :log "INFO" "操作系统: Windows"

:: 检查Python版本
python --version >> "%LOG_FILE%" 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=*" %%i in ('python --version 2^>^&1') do set python_version=%%i
    call :log "INFO" "Python版本: !python_version!"
) else (
    call :log "ERROR" "Python 未安装"
    exit /b 1
)

:: 检查Node.js版本
node --version >> "%LOG_FILE%" 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=*" %%i in ('node --version 2^>^&1') do set node_version=%%i
    for /f "tokens=*" %%i in ('npm --version 2^>^&1') do set npm_version=%%i
    call :log "INFO" "Node.js版本: !node_version!"
    call :log "INFO" "npm版本: !npm_version!"
) else (
    call :log "ERROR" "Node.js 未安装"
    exit /b 1
)

:: 检查Git
git --version >> "%LOG_FILE%" 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=*" %%i in ('git --version 2^>^&1') do set git_version=%%i
    call :log "INFO" "Git版本: !git_version!"
) else (
    call :log "ERROR" "Git 未安装"
    exit /b 1
)

goto :eof

:: 检查代码状态
:check_code
call :log "INFO" "检查代码状态..."

:: 检查当前目录
dir >> "%LOG_FILE%" 2>&1

:: 检查Git状态
git status >> "%LOG_FILE%" 2>&1
if !errorlevel! equ 0 (
    call :log "INFO" "Git仓库状态正常"
    git log --oneline -5 >> "%LOG_FILE%" 2>&1
) else (
    call :log "WARNING" "当前目录不是Git仓库或Git状态异常"
)

goto :eof

:: 安装后端依赖
:install_backend
call :log "INFO" "安装后端依赖..."

cd "%BACKEND_DIR%"

:: 检查Python虚拟环境
if not exist "venv" (
    call :check_command "python -m venv venv" "创建Python虚拟环境"
)

:: 激活虚拟环境
call venv\Scripts\activate.bat

:: 检查pip版本
call :check_command "pip --version" "检查pip版本"

:: 升级pip
call :check_command "pip install --upgrade pip" "升级pip"

:: 安装依赖
call :log "INFO" "安装Python依赖包..."
call :check_command "pip install -r requirements.txt" "安装requirements.txt依赖"

:: 检查是否有兼容性要求文件
if exist "requirements-compatible.txt" (
    call :check_command "pip install -r requirements-compatible.txt" "安装兼容性依赖"
)

:: 检查关键包是否安装成功
call :check_command "python -c "import fastapi; print('FastAPI版本:', fastapi.__version__)"" "检查FastAPI"
call :check_command "python -c "import sqlalchemy; print('SQLAlchemy版本:', sqlalchemy.__version__)"" "检查SQLAlchemy"
call :check_command "python -c "import pydantic; print('Pydantic版本:', pydantic.__version__)"" "检查Pydantic"

goto :eof

:: 安装前端依赖
:install_frontend
call :log "INFO" "安装前端依赖..."

cd "%FRONTEND_DIR%"

:: 检查package.json
if not exist "package.json" (
    call :log "ERROR" "package.json 文件不存在"
    exit /b 1
)

:: 检查引擎要求
call :log "INFO" "检查package.json引擎要求..."
for /f "tokens=*" %%i in ('type package.json ^| findstr \"node\"') do set node_line=%%i
for /f "tokens=*" %%i in ('type package.json ^| findstr \"npm\"') do set npm_line=%%i

call :log "INFO" "Node.js要求: !node_line!"
call :log "INFO" "npm要求: !npm_line!"

:: 安装依赖
call :log "INFO" "安装npm依赖包..."
call :check_command "npm install" "安装npm依赖"

:: 检查关键包是否安装成功
call :check_command "npm list react" "检查React"
call :check_command "npm list vite" "检查Vite"
call :check_command "npm list antd" "检查Ant Design"

goto :eof

:: 配置数据库
:setup_database
call :log "INFO" "配置数据库..."

cd "%BACKEND_DIR%"
call venv\Scripts\activate.bat

:: 检查数据库连接
call :log "INFO" "检查数据库连接..."

:: 尝试导入数据库模块
call :check_command "python -c "from app.core.database import engine; print('数据库引擎创建成功')"" "检查数据库引擎"

:: 检查数据库表
call :check_command "python -c "from app.core.database import Base; from app.models import *; print('模型导入成功')"" "检查数据模型"

goto :eof

:: 构建前端
:build_frontend
call :log "INFO" "构建前端..."

cd "%FRONTEND_DIR%"

:: 检查构建配置
if not exist "vite.config.ts" if not exist "vite.config.js" (
    call :log "WARNING" "未找到Vite配置文件"
)

:: 执行构建
call :check_command "npm run build" "构建前端"

:: 检查构建结果
if exist "dist" (
    dir dist >> "%LOG_FILE%" 2>&1
    if exist "dist\index.html" (
        call :log "INFO" "index.html存在"
    ) else (
        call :log "ERROR" "index.html不存在"
    )
) else (
    call :log "ERROR" "构建失败：dist目录不存在"
    exit /b 1
)

goto :eof

:: 测试后端启动
:test_backend_startup
call :log "INFO" "测试后端启动..."

cd "%BACKEND_DIR%"
call venv\Scripts\activate.bat

:: 检查主应用文件
if not exist "app\main.py" (
    call :log "ERROR" "主应用文件 app\main.py 不存在"
    exit /b 1
)

:: 尝试导入主应用
call :log "INFO" "检查应用导入..."
call :check_command "python -c "from app.main import app; print('应用导入成功')"" "导入主应用"

:: 检查API路由
call :check_command "python -c "from app.main import app; print('路由数量:', len(app.routes))"" "检查路由"

call :log "SUCCESS" "后端启动测试成功"

goto :eof

:: 生成问题报告
:generate_report
call :log "INFO" "生成安装问题报告..."

set report_file=%INSTALL_DIR%\installation-report-%date:~0,4%%date:~5,2%%date:~8,2%-%time:~0,2%%time:~3,2%%time:~6,2%.txt

echo === IPv6 WireGuard Manager 安装问题报告 === > "%report_file%"
echo 生成时间: %date% %time% >> "%report_file%"
echo 安装目录: %INSTALL_DIR% >> "%report_file%"
echo 日志文件: %LOG_FILE% >> "%report_file%"
echo. >> "%report_file%"

:: 提取错误和警告
echo === 错误汇总 === >> "%report_file%"
findstr "\[ERROR\]" "%LOG_FILE%" >> "%report_file%" 2>nul

echo. >> "%report_file%"
echo === 警告汇总 === >> "%report_file%"
findstr "\[WARNING\]" "%LOG_FILE%" >> "%report_file%" 2>nul

echo. >> "%report_file%"
echo === 详细日志 === >> "%report_file%"
echo 请查看完整日志文件: %LOG_FILE% >> "%report_file%"

call :log "SUCCESS" "问题报告已生成: %report_file%"

:: 显示关键问题
set error_count=0
set warning_count=0

for /f %%i in ('findstr /c:"[ERROR]" "%LOG_FILE%" ^| find /c /v ""') do set error_count=%%i
for /f %%i in ('findstr /c:"[WARNING]" "%LOG_FILE%" ^| find /c /v ""') do set warning_count=%%i

echo.
echo === 安装摘要 ===
echo 错误数量: %error_count%
echo 警告数量: %warning_count%
echo 日志文件: %LOG_FILE%
echo 报告文件: %report_file%

if %error_count% equ 0 (
    call :log "SUCCESS" "安装完成，未发现严重错误"
) else (
    call :log "WARNING" "安装完成，但发现 %error_count% 个错误需要修复"
)

goto :eof

:: 主函数
:main
echo === IPv6 WireGuard Manager 调试模式安装脚本 ===
echo 此脚本会详细记录安装过程中的所有问题
echo 日志文件: %LOG_FILE%
echo.

:: 执行安装步骤
call :check_system
call :check_code
call :install_backend
call :install_frontend
call :setup_database
call :build_frontend
call :test_backend_startup

:: 生成报告
call :generate_report

echo.
echo 安装完成！请查看报告文件了解详细问题。
echo 如需修复问题，请根据报告中的错误信息逐一解决。

goto :eof

:: 执行主函数
call :main

pause