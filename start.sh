#!/bin/bash

# IPv6 WireGuard Manager 启动脚本
# 支持多种启动模式和自动配置

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# 默认配置
MODE="auto"
WORKERS=4
HOST="0.0.0.0"
PORT=8000
LOG_LEVEL="info"
RELOAD=false
DEBUG=false

# 显示帮助信息
show_help() {
    cat << EOF
IPv6 WireGuard Manager 启动脚本

用法: $0 [选项]

选项:
    -m, --mode MODE        启动模式 (auto|dev|prod|docker)
    -w, --workers NUM      工作进程数 (默认: 4)
    -h, --host HOST        监听主机 (默认: 0.0.0.0)
    -p, --port PORT        监听端口 (默认: 8000)
    -l, --log-level LEVEL  日志级别 (debug|info|warning|error)
    -r, --reload           开发模式热重载
    -d, --debug            调试模式
    --help                 显示此帮助信息

启动模式:
    auto    自动检测环境并选择最佳模式
    dev     开发模式 (热重载，单进程)
    prod    生产模式 (多进程，优化配置)
    docker  Docker模式 (容器内运行)

示例:
    $0                      # 自动模式启动
    $0 -m dev -r            # 开发模式启动
    $0 -m prod -w 8         # 生产模式，8个工作进程
    $0 -m docker            # Docker模式启动
EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mode)
                MODE="$2"
                shift 2
                ;;
            -w|--workers)
                WORKERS="$2"
                shift 2
                ;;
            -h|--host)
                HOST="$2"
                shift 2
                ;;
            -p|--port)
                PORT="$2"
                shift 2
                ;;
            -l|--log-level)
                LOG_LEVEL="$2"
                shift 2
                ;;
            -r|--reload)
                RELOAD=true
                shift
                ;;
            -d|--debug)
                DEBUG=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检查系统环境
check_environment() {
    log_info "检查系统环境..."
    
    # 检查Python版本
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 未安装"
        exit 1
    fi
    
    local python_version=$(python3 --version | cut -d' ' -f2)
    log_info "Python版本: $python_version"
    
    # 检查虚拟环境
    if [[ -z "$VIRTUAL_ENV" ]]; then
        log_warning "未检测到虚拟环境"
        if [[ -f "venv/bin/activate" ]]; then
            log_info "激活虚拟环境..."
            source venv/bin/activate
        else
            log_warning "建议使用虚拟环境"
        fi
    else
        log_success "虚拟环境已激活: $VIRTUAL_ENV"
    fi
    
    # 检查依赖
    if ! python3 -c "import fastapi, uvicorn" 2>/dev/null; then
        log_error "缺少必要依赖，请运行: pip install -r requirements.txt"
        exit 1
    fi
    
    log_success "环境检查通过"
}

# 检查数据库连接
check_database() {
    log_info "检查数据库连接..."
    
    # 运行数据库健康检查
    if python3 -c "
from backend.app.core.database_health import check_and_fix_database
if not check_and_fix_database():
    exit(1)
" 2>/dev/null; then
        log_success "数据库连接正常"
    else
        log_error "数据库连接失败"
        exit 1
    fi
}

# 检查端口可用性
check_port() {
    log_info "检查端口 $PORT 可用性..."
    
    if netstat -tuln 2>/dev/null | grep -q ":$PORT "; then
        log_error "端口 $PORT 已被占用"
        exit 1
    else
        log_success "端口 $PORT 可用"
    fi
}

# 开发模式启动
start_dev() {
    log_info "启动开发模式..."
    
    local cmd="uvicorn backend.app.main:app"
    cmd="$cmd --host $HOST --port $PORT"
    cmd="$cmd --log-level $LOG_LEVEL"
    
    if [[ "$RELOAD" == true ]]; then
        cmd="$cmd --reload"
    fi
    
    if [[ "$DEBUG" == true ]]; then
        cmd="$cmd --reload --log-level debug"
    fi
    
    log_info "执行命令: $cmd"
    exec $cmd
}

# 生产模式启动
start_prod() {
    log_info "启动生产模式..."
    
    # 检查gunicorn是否可用
    if ! command -v gunicorn &> /dev/null; then
        log_warning "gunicorn 未安装，使用 uvicorn 启动"
        start_uvicorn_prod
        return
    fi
    
    local cmd="gunicorn backend.app.main:app"
    cmd="$cmd -w $WORKERS"
    cmd="$cmd -k uvicorn.workers.UvicornWorker"
    cmd="$cmd -b $HOST:$PORT"
    cmd="$cmd --log-level $LOG_LEVEL"
    cmd="$cmd --access-logfile -"
    cmd="$cmd --error-logfile -"
    cmd="$cmd --preload"
    
    log_info "执行命令: $cmd"
    exec $cmd
}

# 使用uvicorn启动生产模式
start_uvicorn_prod() {
    log_info "使用 uvicorn 启动生产模式..."
    
    local cmd="uvicorn backend.app.main:app"
    cmd="$cmd --host $HOST --port $PORT"
    cmd="$cmd --workers $WORKERS"
    cmd="$cmd --log-level $LOG_LEVEL"
    cmd="$cmd --access-log"
    
    log_info "执行命令: $cmd"
    exec $cmd
}

# Docker模式启动
start_docker() {
    log_info "启动Docker模式..."
    
    # 检查Docker是否可用
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装"
        exit 1
    fi
    
    # 检查docker-compose是否可用
    if ! command -v docker-compose &> /dev/null; then
        log_error "docker-compose 未安装"
        exit 1
    fi
    
    # 启动Docker服务
    log_info "启动Docker服务..."
    docker-compose up -d
    
    log_success "Docker服务已启动"
    log_info "查看日志: docker-compose logs -f"
    log_info "停止服务: docker-compose down"
}

# 自动模式启动
start_auto() {
    log_info "自动检测启动模式..."
    
    # 检查是否在Docker容器中
    if [[ -f /.dockerenv ]]; then
        log_info "检测到Docker环境，使用Docker模式"
        start_docker
        return
    fi
    
    # 检查是否在开发环境
    if [[ "$DEBUG" == true || "$RELOAD" == true ]]; then
        log_info "检测到开发环境，使用开发模式"
        start_dev
        return
    fi
    
    # 检查系统资源
    local memory_mb=$(free -m | awk 'NR==2{print $2}')
    local cpu_cores=$(nproc)
    
    log_info "系统内存: ${memory_mb}MB"
    log_info "CPU核心: $cpu_cores"
    
    # 根据系统资源调整工作进程数
    if [[ $memory_mb -lt 1024 ]]; then
        WORKERS=1
        log_warning "内存不足，使用单进程模式"
    elif [[ $memory_mb -lt 2048 ]]; then
        WORKERS=2
        log_info "内存较少，使用2个工作进程"
    else
        WORKERS=$((cpu_cores * 2))
        log_info "使用 $WORKERS 个工作进程"
    fi
    
    # 检查是否有systemd服务
    if systemctl is-active --quiet ipv6-wireguard-manager 2>/dev/null; then
        log_info "检测到systemd服务，启动服务..."
        systemctl start ipv6-wireguard-manager
        return
    fi
    
    # 默认使用生产模式
    log_info "使用生产模式启动"
    start_prod
}

# 主函数
main() {
    echo "=========================================="
    echo "IPv6 WireGuard Manager 启动脚本"
    echo "=========================================="
    
    # 解析参数
    parse_args "$@"
    
    # 显示配置
    log_info "启动配置:"
    log_info "  模式: $MODE"
    log_info "  主机: $HOST"
    log_info "  端口: $PORT"
    log_info "  工作进程: $WORKERS"
    log_info "  日志级别: $LOG_LEVEL"
    log_info "  热重载: $RELOAD"
    log_info "  调试模式: $DEBUG"
    
    # 环境检查
    check_environment
    check_database
    check_port
    
    # 根据模式启动
    case $MODE in
        "dev")
            start_dev
            ;;
        "prod")
            start_prod
            ;;
        "docker")
            start_docker
            ;;
        "auto")
            start_auto
            ;;
        *)
            log_error "不支持的启动模式: $MODE"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
