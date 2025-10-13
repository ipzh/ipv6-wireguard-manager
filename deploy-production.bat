@echo off
chcp 65001 >nul

:: IPv6 WireGuard Manager 生产环境部署脚本 (Windows)

echo 🚀 开始部署 IPv6 WireGuard Manager 生产环境...
echo.

:: 检查Docker和Docker Compose
:check_prerequisites
echo 🔍 检查系统依赖...

docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker 未安装
    exit /b 1
)

docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker Compose 未安装
    exit /b 1
)

echo ✅ 系统依赖检查通过
echo.

:: 创建环境文件
:create_env_file
echo 📝 创建环境配置文件...

if not exist .env.production (
    (
        echo # 生产环境配置
        echo POSTGRES_PASSWORD=password
        echo REDIS_PASSWORD=redis123
        echo SECRET_KEY=generated-secret-key-here
        echo GRAFANA_PASSWORD=admin123
        echo.
        echo # 应用配置
        echo DEBUG=false
        echo LOG_LEVEL=INFO
        echo API_V1_STR=/api/v1
        echo SERVER_HOST=::
        echo SERVER_PORT=8000
        echo.
        echo # 数据库配置
        echo DATABASE_URL=postgresql://ipv6wgm:password@postgres:5432/ipv6wgm
        echo DATABASE_POOL_SIZE=20
        echo DATABASE_MAX_OVERFLOW=30
        echo.
        echo # Redis配置
        echo REDIS_URL=redis://:redis123@redis:6379/0
        echo REDIS_POOL_SIZE=10
        echo.
        echo # 监控配置
        echo ENABLE_METRICS=true
        echo METRICS_PORT=9090
    ) > .env.production
    echo ✅ 环境配置文件创建成功
) else (
    echo ⚠️  环境配置文件已存在，跳过创建
)

echo.

:: 构建Docker镜像
:build_images
echo 🔨 构建Docker镜像...
echo.

:: 构建后端镜像
echo 📦 构建后端镜像...
docker build -f backend/Dockerfile.production -t ipv6-wireguard-backend:latest ./backend

:: 构建前端镜像
echo 📦 构建前端镜像...
docker build -f frontend/Dockerfile.production -t ipv6-wireguard-frontend:latest ./frontend

echo ✅ Docker镜像构建完成
echo.

:: 启动服务
:start_services
echo 🚀 启动服务...

docker-compose -f docker-compose.production.yml up -d

echo ✅ 服务启动完成
echo.

:: 等待服务就绪
:wait_for_services
echo ⏳ 等待服务就绪...
echo.

:: 等待数据库
echo 🗄️  等待数据库就绪...
:wait_db
docker-compose -f docker-compose.production.yml exec -T postgres pg_isready -U ipv6wgm -d ipv6wgm >nul 2>&1
if errorlevel 1 (
    echo ⏳ 数据库正在启动...
    timeout /t 5 /nobreak >nul
    goto wait_db
)
echo ✅ 数据库就绪

:: 等待后端服务
echo 🔧 等待后端服务就绪...
:wait_backend
curl -f http://localhost:8000/api/v1/health >nul 2>&1
if errorlevel 1 (
    echo ⏳ 后端服务正在启动...
    timeout /t 5 /nobreak >nul
    goto wait_backend
)
echo ✅ 后端服务就绪

:: 等待前端服务
echo 🌐 等待前端服务就绪...
:wait_frontend
curl -f http://localhost:80 >nul 2>&1
if errorlevel 1 (
    echo ⏳ 前端服务正在启动...
    timeout /t 5 /nobreak >nul
    goto wait_frontend
)
echo ✅ 前端服务就绪
echo.

:: 初始化数据库
:init_database
echo 🗃️  初始化数据库...

docker-compose -f docker-compose.production.yml exec -T backend python -c "from app.core.init_db_sync import create_tables, init_default_data; create_tables(); init_default_data()"

echo ✅ 数据库初始化完成
echo.

:: 显示部署信息
:show_deployment_info
echo 🎉 部署完成！
echo.
echo 📊 服务访问信息：
echo   🌐 前端应用: http://localhost
echo   🔧 后端API: http://localhost:8000
echo   📚 API文档: http://localhost:8000/docs
echo   📈 监控面板: http://localhost:3000
echo   📊 Prometheus: http://localhost:9090
echo.
echo 🔑 默认登录信息：
echo   用户名: admin
echo   密码: admin123
echo.
echo ⚠️  请及时修改默认密码！
echo.

echo ✅ 部署流程完成！
pause