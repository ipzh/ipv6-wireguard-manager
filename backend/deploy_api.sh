#!/bin/bash
# IPv6 WireGuard Manager API 部署和启动脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Python环境
check_python() {
    log_info "检查Python环境..."
    
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
        log_success "Python版本: $PYTHON_VERSION"
        
        # 检查Python版本是否满足要求
        if python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)"; then
            log_success "Python版本满足要求 (>= 3.8)"
        else
            log_error "Python版本过低，需要 >= 3.8"
            exit 1
        fi
    else
        log_error "未找到Python3，请先安装Python 3.8+"
        exit 1
    fi
}

# 检查依赖
check_dependencies() {
    log_info "检查系统依赖..."
    
    # 检查MySQL
    if command -v mysql &> /dev/null; then
        log_success "MySQL已安装"
    else
        log_warning "MySQL未安装，请确保数据库服务可用"
    fi
    
    # 检查pip
    if command -v pip3 &> /dev/null; then
        log_success "pip3已安装"
    else
        log_error "pip3未安装，请先安装pip"
        exit 1
    fi
}

# 安装Python依赖
install_dependencies() {
    log_info "安装Python依赖..."
    
    # 创建虚拟环境（如果不存在）
    if [ ! -d "venv" ]; then
        log_info "创建虚拟环境..."
        python3 -m venv venv
    fi
    
    # 激活虚拟环境
    source venv/bin/activate
    
    # 升级pip
    log_info "升级pip..."
    pip install --upgrade pip
    
    # 安装依赖
    if [ -f "requirements-simple.txt" ]; then
        log_info "使用简化依赖文件安装..."
        pip install -r requirements-simple.txt
    elif [ -f "requirements.txt" ]; then
        log_info "使用完整依赖文件安装..."
        pip install -r requirements.txt
    else
        log_error "未找到依赖文件"
        exit 1
    fi
    
    log_success "依赖安装完成"
}

# 配置环境
setup_environment() {
    log_info "配置环境..."
    
    # 创建.env文件（如果不存在）
    if [ ! -f ".env" ]; then
        if [ -f "env.example" ]; then
            log_info "创建.env文件..."
            cp env.example .env
            log_warning "请编辑.env文件配置数据库连接信息"
        else
            log_warning "未找到env.example文件，请手动创建.env文件"
        fi
    fi
    
    # 创建必要的目录
    mkdir -p logs uploads wireguard/clients
    log_success "目录创建完成"
}

# 初始化数据库
init_database() {
    log_info "初始化数据库..."
    
    # 激活虚拟环境
    source venv/bin/activate
    
    # 运行数据库初始化
    if [ -f "init_database_simple.py" ]; then
        log_info "运行简化数据库初始化..."
        python init_database_simple.py
    elif [ -f "init_database.py" ]; then
        log_info "运行完整数据库初始化..."
        python init_database.py
    else
        log_warning "未找到数据库初始化脚本"
    fi
}

# 启动API服务
start_api() {
    log_info "启动API服务..."
    
    # 激活虚拟环境
    source venv/bin/activate
    
    # 检查API服务是否已经在运行
    if pgrep -f "uvicorn.*app.main:app" > /dev/null; then
        log_warning "API服务已在运行，停止现有服务..."
        pkill -f "uvicorn.*app.main:app"
        sleep 2
    fi
    
    # 启动API服务
    if [ -f "run_api.py" ]; then
        log_info "使用run_api.py启动服务..."
        nohup python run_api.py > logs/api.log 2>&1 &
    else
        log_info "使用uvicorn直接启动服务..."
        nohup uvicorn app.main:app --host ${SERVER_HOST} --port 8000 --reload > logs/api.log 2>&1 &
    fi
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 5
    
    # 检查服务状态
    if pgrep -f "uvicorn.*app.main:app" > /dev/null; then
        log_success "API服务启动成功"
        log_info "服务日志: logs/api.log"
        log_info "API文档: http://localhost:${API_PORT}/docs"
        log_info "健康检查: http://localhost:${API_PORT}/health"
    else
        log_error "API服务启动失败，请检查日志"
        exit 1
    fi
}

# 测试API服务
test_api() {
    log_info "测试API服务..."
    
    # 激活虚拟环境
    source venv/bin/activate
    
    # 等待服务完全启动
    sleep 3
    
    # 运行API测试
    if [ -f "test_api.py" ]; then
        python test_api.py
    else
        log_warning "未找到API测试脚本"
    fi
}

# 显示状态
show_status() {
    log_info "服务状态:"
    
    if pgrep -f "uvicorn.*app.main:app" > /dev/null; then
        log_success "API服务: 运行中"
        echo "  PID: $(pgrep -f 'uvicorn.*app.main:app')"
        echo "  端口: 8000"
        echo "  文档: http://localhost:${API_PORT}/docs"
        echo "  健康检查: http://localhost:${API_PORT}/health"
    else
        log_error "API服务: 未运行"
    fi
}

# 停止服务
stop_api() {
    log_info "停止API服务..."
    
    if pgrep -f "uvicorn.*app.main:app" > /dev/null; then
        pkill -f "uvicorn.*app.main:app"
        log_success "API服务已停止"
    else
        log_warning "API服务未运行"
    fi
}

# 重启服务
restart_api() {
    log_info "重启API服务..."
    stop_api
    sleep 2
    start_api
}

# 显示帮助
show_help() {
    echo "IPv6 WireGuard Manager API 部署脚本"
    echo ""
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  install     - 安装依赖和配置环境"
    echo "  init        - 初始化数据库"
    echo "  start       - 启动API服务"
    echo "  stop        - 停止API服务"
    echo "  restart     - 重启API服务"
    echo "  test        - 测试API服务"
    echo "  status      - 显示服务状态"
    echo "  deploy      - 完整部署（安装+初始化+启动+测试）"
    echo "  help        - 显示此帮助信息"
    echo ""
}

# 主函数
main() {
    case "${1:-help}" in
        "install")
            check_python
            check_dependencies
            install_dependencies
            setup_environment
            ;;
        "init")
            init_database
            ;;
        "start")
            start_api
            ;;
        "stop")
            stop_api
            ;;
        "restart")
            restart_api
            ;;
        "test")
            test_api
            ;;
        "status")
            show_status
            ;;
        "deploy")
            check_python
            check_dependencies
            install_dependencies
            setup_environment
            init_database
            start_api
            test_api
            show_status
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# 运行主函数
main "$@"
