#!/bin/bash

# IPv6 WireGuard Manager 调试模式安装脚本
# 此脚本会详细记录安装过程中的所有问题，便于一次性修复

set -e  # 遇到错误立即退出

# 配置变量
LOG_FILE="/tmp/ipv6-wireguard-install-debug.log"
INSTALL_DIR="/opt/ipv6-wireguard-manager"
BACKEND_DIR="$INSTALL_DIR/backend"
FRONTEND_DIR="$INSTALL_DIR/frontend"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO") color=$BLUE ;;
        "SUCCESS") color=$GREEN ;;
        "WARNING") color=$YELLOW ;;
        "ERROR") color=$RED ;;
        "DEBUG") color=$NC ;;
    esac
    
    echo -e "${color}[$level] $message${NC}" | tee -a "$LOG_FILE"
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# 检查命令执行状态
check_command() {
    local cmd="$1"
    local description="$2"
    
    log "DEBUG" "执行命令: $cmd"
    
    if eval "$cmd" 2>&1 | tee -a "$LOG_FILE"; then
        log "SUCCESS" "$description 完成"
        return 0
    else
        local exit_code=${PIPESTATUS[0]}
        log "ERROR" "$description 失败 (退出码: $exit_code)"
        return $exit_code
    fi
}

# 检查系统环境
check_system() {
    log "INFO" "检查系统环境..."
    
    # 检查操作系统
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        log "INFO" "操作系统: $NAME $VERSION"
    else
        log "WARNING" "无法确定操作系统版本"
    fi
    
    # 检查Python版本
    if command -v python3 &> /dev/null; then
        python_version=$(python3 --version 2>&1)
        log "INFO" "Python版本: $python_version"
    else
        log "ERROR" "Python3 未安装"
        return 1
    fi
    
    # 检查Node.js版本
    if command -v node &> /dev/null; then
        node_version=$(node --version 2>&1)
        npm_version=$(npm --version 2>&1)
        log "INFO" "Node.js版本: $node_version"
        log "INFO" "npm版本: $npm_version"
    else
        log "ERROR" "Node.js 未安装"
        return 1
    fi
    
    # 检查Git
    if command -v git &> /dev/null; then
        git_version=$(git --version 2>&1)
        log "INFO" "Git版本: $git_version"
    else
        log "ERROR" "Git 未安装"
        return 1
    fi
    
    # 检查PostgreSQL
    if command -v psql &> /dev/null; then
        psql_version=$(psql --version 2>&1)
        log "INFO" "PostgreSQL版本: $psql_version"
    else
        log "WARNING" "PostgreSQL 未安装"
    fi
    
    # 检查Redis
    if command -v redis-cli &> /dev/null; then
        redis_version=$(redis-cli --version 2>&1)
        log "INFO" "Redis版本: $redis_version"
    else
        log "WARNING" "Redis 未安装"
    fi
    
    # 检查Nginx
    if command -v nginx &> /dev/null; then
        nginx_version=$(nginx -v 2>&1)
        log "INFO" "Nginx版本: $nginx_version"
    else
        log "WARNING" "Nginx 未安装"
    fi
}

# 克隆代码
clone_code() {
    log "INFO" "克隆代码..."
    
    # 创建安装目录
    check_command "sudo mkdir -p $INSTALL_DIR" "创建安装目录"
    check_command "sudo chown $(whoami):$(whoami) $INSTALL_DIR" "设置目录权限"
    
    # 克隆代码
    cd "$INSTALL_DIR"
    check_command "git clone https://github.com/ipzh/ipv6-wireguard-manager.git ." "克隆代码库"
    check_command "git log --oneline -5" "检查最新提交"
}

# 安装后端依赖
install_backend() {
    log "INFO" "安装后端依赖..."
    
    cd "$BACKEND_DIR"
    
    # 检查Python虚拟环境
    if [ ! -d "venv" ]; then
        # 检查并安装python3-venv包（确保虚拟环境创建成功）
        log "INFO" "检查python3-venv包..."
        if ! python3 -c "import ensurepip" 2>/dev/null; then
            log "INFO" "安装python3-venv包..."
            apt-get update -y
            apt-get install -y python3-venv
            log "SUCCESS" "python3-venv包安装完成"
        else
            log "SUCCESS" "python3-venv包已可用"
        fi
        
        check_command "python3 -m venv venv" "创建Python虚拟环境"
    fi
    
    # 激活虚拟环境
    source venv/bin/activate
    
    # 检查pip版本
    check_command "pip --version" "检查pip版本"
    
    # 升级pip
    check_command "pip install --upgrade pip" "升级pip"
    
    # 安装依赖
    log "INFO" "安装Python依赖包..."
    check_command "pip install -r requirements.txt" "安装requirements.txt依赖"
    
    # 检查是否有兼容性要求文件
    if [ -f "requirements-compatible.txt" ]; then
        check_command "pip install -r requirements-compatible.txt" "安装兼容性依赖"
    fi
    
    # 检查关键包是否安装成功
    check_command "python -c 'import fastapi; print(\"FastAPI版本:\", fastapi.__version__)'" "检查FastAPI"
    check_command "python -c 'import sqlalchemy; print(\"SQLAlchemy版本:\", sqlalchemy.__version__)'" "检查SQLAlchemy"
    check_command "python -c 'import pydantic; print(\"Pydantic版本:\", pydantic.__version__)'" "检查Pydantic"
}

# 安装前端依赖
install_frontend() {
    log "INFO" "安装前端依赖..."
    
    cd "$FRONTEND_DIR"
    
    # 检查package.json
    if [ ! -f "package.json" ]; then
        log "ERROR" "package.json 文件不存在"
        return 1
    fi
    
    # 检查引擎要求
    log "INFO" "检查package.json引擎要求..."
    node_required=$(grep -o '"node": "[^"]*"' package.json | cut -d'"' -f4)
    npm_required=$(grep -o '"npm": "[^"]*"' package.json | cut -d'"' -f4)
    
    log "INFO" "要求的Node.js版本: $node_required"
    log "INFO" "要求的npm版本: $npm_required"
    
    # 安装依赖
    log "INFO" "安装npm依赖包..."
    check_command "npm install" "安装npm依赖"
    
    # 检查关键包是否安装成功
    check_command "npm list react" "检查React"
    check_command "npm list vite" "检查Vite"
    check_command "npm list antd" "检查Ant Design"
}

# 配置数据库
setup_database() {
    log "INFO" "配置数据库..."
    
    cd "$BACKEND_DIR"
    source venv/bin/activate
    
    # 检查数据库连接
    log "INFO" "检查数据库连接..."
    
    # 尝试导入数据库模块（使用新的健康检查功能）
    check_command "python -c 'from app.core.database import engine; print(\"数据库引擎创建成功\")'" "检查数据库引擎"
    
    # 检查数据库表
    check_command "python -c 'from app.core.database import Base; from app.models import *; print(\"模型导入成功\")'" "检查数据模型"
    
    # 运行数据库初始化（使用新的健康检查功能）
    log "INFO" "运行数据库初始化..."
    check_command "python -c 'from app.core.database import init_db; import asyncio; print(\"开始数据库初始化...\"); result = asyncio.run(init_db()); print(f\"数据库初始化完成: {result}\")'" "执行数据库初始化"
    
    # 运行数据库迁移
    log "INFO" "运行数据库迁移..."
    if [ -d "migrations" ]; then
        check_command "alembic upgrade head" "执行数据库迁移"
    else
        log "WARNING" "未找到migrations目录，跳过迁移"
    fi
}

# 构建前端
build_frontend() {
    log "INFO" "构建前端..."
    
    cd "$FRONTEND_DIR"
    
    # 检查构建配置
    if [ ! -f "vite.config.ts" ] && [ ! -f "vite.config.js" ]; then
        log "WARNING" "未找到Vite配置文件"
    fi
    
    # 执行构建
    check_command "npm run build" "构建前端"
    
    # 检查构建结果
    if [ -d "dist" ]; then
        check_command "ls -la dist/" "检查构建输出"
        check_command "[ -f \"dist/index.html\" ] && echo \"index.html存在\" || echo \"index.html不存在\"" "检查index.html"
    else
        log "ERROR" "构建失败：dist目录不存在"
        return 1
    fi
}

# 测试后端启动
test_backend_startup() {
    log "INFO" "测试后端启动..."
    
    cd "$BACKEND_DIR"
    source venv/bin/activate
    
    # 检查主应用文件
    if [ ! -f "app/main.py" ]; then
        log "ERROR" "主应用文件 app/main.py 不存在"
        return 1
    fi
    
    # 尝试导入主应用
    log "INFO" "检查应用导入..."
    check_command "python -c 'from app.main import app; print(\"应用导入成功\")'" "导入主应用"
    
    # 检查API路由
    check_command "python -c 'from app.main import app; print(\"路由数量:\", len(app.routes))'" "检查路由"
    
    # 测试快速启动（不绑定端口）
    log "INFO" "测试应用启动（5秒超时）..."
    timeout 5s python -c "
import asyncio
from app.main import app
import uvicorn

async def test_startup():
    try:
        config = uvicorn.Config(app, host='127.0.0.1', port=8000, log_level='error')
        server = uvicorn.Server(config)
        # 只启动不服务
        await server.startup()
        print('启动测试成功')
        await server.shutdown()
    except Exception as e:
        print(f'启动失败: {e}')
        raise

asyncio.run(test_startup())
" 2>&1 | tee -a "$LOG_FILE"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log "SUCCESS" "后端启动测试成功"
    else
        log "ERROR" "后端启动测试失败"
        return 1
    fi
}

# 配置系统服务
setup_systemd() {
    log "INFO" "配置系统服务..."
    
    # 检查服务文件模板
    if [ -f "deploy-production.sh" ]; then
        log "INFO" "找到部署脚本，检查服务配置..."
        
        # 从部署脚本中提取服务配置
        service_config=$(grep -A 20 "ExecStart" deploy-production.sh 2>/dev/null || echo "未找到服务配置")
        log "DEBUG" "服务配置: $service_config"
    fi
    
    # 创建服务文件
    local service_file="/etc/systemd/system/ipv6-wireguard-manager.service"
    
    if [ ! -f "$service_file" ]; then
        log "INFO" "创建系统服务文件..."
        
        sudo tee "$service_file" > /dev/null <<EOF
[Unit]
Description=IPv6 WireGuard Manager
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=$BACKEND_DIR
Environment=PATH=$BACKEND_DIR/venv/bin
Environment=DATABASE_URL=postgresql://ipv6wgm:password@localhost:5432/ipv6wgm
Environment=REDIS_URL=redis://localhost:6379/0
Environment=SECRET_KEY=your-secret-key-change-this-in-production
Environment=DEBUG=false
Environment=LOG_LEVEL=INFO
ExecStart=$BACKEND_DIR/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        
        check_command "sudo systemctl daemon-reload" "重新加载系统服务"
        check_command "sudo systemctl enable ipv6-wireguard-manager" "启用服务"
    else
        log "INFO" "系统服务文件已存在"
    fi
}

# 配置Nginx
setup_nginx() {
    log "INFO" "配置Nginx..."
    
    if command -v nginx &> /dev/null; then
        # 检查Nginx配置
        check_command "sudo nginx -t" "测试Nginx配置"
        
        # 检查默认站点配置
        if [ -f "/etc/nginx/sites-available/default" ]; then
            log "INFO" "检查默认Nginx站点配置..."
            sudo grep -A 10 -B 5 "ipv6-wireguard" /etc/nginx/sites-available/default 2>&1 | tee -a "$LOG_FILE" || log "WARNING" "未找到相关配置"
        fi
    else
        log "WARNING" "Nginx未安装，跳过配置"
    fi
}

# 启动服务
start_services() {
    log "INFO" "启动服务..."
    
    # 启动后端服务
    check_command "sudo systemctl start ipv6-wireguard-manager" "启动后端服务"
    
    # 检查服务状态
    sleep 3
    check_command "sudo systemctl status ipv6-wireguard-manager" "检查后端服务状态"
    
    # 检查服务日志
    log "INFO" "检查服务日志..."
    sudo journalctl -u ipv6-wireguard-manager --no-pager -n 10 2>&1 | tee -a "$LOG_FILE"
    
    # 测试API接口
    log "INFO" "测试API接口..."
    check_command "curl -s http://localhost:8000/api/v1/status || echo 'API测试失败'" "测试状态API"
}

# 生成问题报告
generate_report() {
    log "INFO" "生成安装问题报告..."
    
    local report_file="$INSTALL_DIR/installation-report-$(date +%Y%m%d-%H%M%S).txt"
    
    echo "=== IPv6 WireGuard Manager 安装问题报告 ===" > "$report_file"
    echo "生成时间: $(date)" >> "$report_file"
    echo "安装目录: $INSTALL_DIR" >> "$report_file"
    echo "日志文件: $LOG_FILE" >> "$report_file"
    echo "" >> "$report_file"
    
    # 提取错误和警告
    echo "=== 错误汇总 ===" >> "$report_file"
    grep "\[ERROR\]" "$LOG_FILE" >> "$report_file"
    
    echo "" >> "$report_file"
    echo "=== 警告汇总 ===" >> "$report_file"
    grep "\[WARNING\]" "$LOG_FILE" >> "$report_file"
    
    echo "" >> "$report_file"
    echo "=== 详细日志 ===" >> "$report_file"
    echo "请查看完整日志文件: $LOG_FILE" >> "$report_file"
    
    log "SUCCESS" "问题报告已生成: $report_file"
    
    # 显示关键问题
    local error_count=$(grep -c "\[ERROR\]" "$LOG_FILE")
    local warning_count=$(grep -c "\[WARNING\]" "$LOG_FILE")
    
    echo ""
    echo "=== 安装摘要 ==="
    echo "错误数量: $error_count"
    echo "警告数量: $warning_count"
    echo "日志文件: $LOG_FILE"
    echo "报告文件: $report_file"
    
    if [ $error_count -eq 0 ]; then
        log "SUCCESS" "安装完成，未发现严重错误"
    else
        log "WARNING" "安装完成，但发现 $error_count 个错误需要修复"
    fi
}

# 主函数
main() {
    echo "=== IPv6 WireGuard Manager 调试模式安装脚本 ==="
    echo "此脚本会详细记录安装过程中的所有问题"
    echo "日志文件: $LOG_FILE"
    echo ""
    
    # 清空日志文件
    > "$LOG_FILE"
    
    # 执行安装步骤
    check_system
    clone_code
    install_backend
    install_frontend
    setup_database
    build_frontend
    test_backend_startup
    setup_systemd
    setup_nginx
    start_services
    
    # 生成报告
    generate_report
    
    echo ""
    echo "安装完成！请查看报告文件了解详细问题。"
    echo "如需修复问题，请根据报告中的错误信息逐一解决。"
}

# 执行主函数
main "$@"