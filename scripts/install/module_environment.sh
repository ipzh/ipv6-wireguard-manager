#!/bin/bash

# 环境检测模块
# 检查系统环境、依赖和权限

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

# 检查操作系统
check_os() {
    log_info "检查操作系统..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        log_success "检测到Linux系统"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        log_success "检测到macOS系统"
    else
        log_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
}

# 检查系统架构
check_architecture() {
    log_info "检查系统架构..."
    
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            log_success "检测到x86_64架构"
            ;;
        arm64|aarch64)
            log_success "检测到ARM64架构"
            ;;
        *)
            log_warning "未识别的架构: $ARCH，继续安装..."
            ;;
    esac
}

# 检查内存
check_memory() {
    log_info "检查系统内存..."
    
    if [[ "$OS" == "linux" ]]; then
        MEMORY_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        MEMORY_MB=$((MEMORY_KB / 1024))
    elif [[ "$OS" == "macos" ]]; then
        MEMORY_MB=$(sysctl -n hw.memsize | awk '{print int($0/1024/1024)}')
    fi
    
    if [[ $MEMORY_MB -lt 1024 ]]; then
        log_warning "系统内存较少 (${MEMORY_MB}MB)，建议至少1GB内存"
    else
        log_success "系统内存充足 (${MEMORY_MB}MB)"
    fi
}

# 检查磁盘空间
check_disk_space() {
    log_info "检查磁盘空间..."
    
    if [[ "$OS" == "linux" ]]; then
        DISK_SPACE=$(df / | awk 'NR==2 {print $4}')
        DISK_SPACE_MB=$((DISK_SPACE / 1024))
    elif [[ "$OS" == "macos" ]]; then
        DISK_SPACE=$(df / | awk 'NR==2 {print $4}')
        DISK_SPACE_MB=$((DISK_SPACE / 1024))
    fi
    
    if [[ $DISK_SPACE_MB -lt 2048 ]]; then
        log_warning "磁盘空间较少 (${DISK_SPACE_MB}MB)，建议至少2GB可用空间"
    else
        log_success "磁盘空间充足 (${DISK_SPACE_MB}MB)"
    fi
}

# 检查网络连接
check_network() {
    log_info "检查网络连接..."
    
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_success "网络连接正常"
    else
        log_warning "网络连接可能有问题，请检查网络设置"
    fi
}

# 检查必需命令
check_required_commands() {
    log_info "检查必需命令..."
    
    REQUIRED_COMMANDS=("curl" "wget" "tar" "gzip")
    MISSING_COMMANDS=()
    
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            MISSING_COMMANDS+=("$cmd")
        fi
    done
    
    if [[ ${#MISSING_COMMANDS[@]} -ne 0 ]]; then
        log_error "缺少必需命令: ${MISSING_COMMANDS[*]}"
        log_info "请安装缺少的命令后重试"
        exit 1
    fi
    
    log_success "所有必需命令已安装"
}

# 检查Python环境
check_python() {
    log_info "检查Python环境..."
    
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
        PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)
        
        if [[ $PYTHON_MAJOR -ge 3 && $PYTHON_MINOR -ge 8 ]]; then
            log_success "Python版本符合要求: $PYTHON_VERSION"
        else
            log_error "Python版本过低，需要3.8+，当前版本: $PYTHON_VERSION"
            exit 1
        fi
    else
        log_error "Python3未安装，请先安装Python 3.8+"
        exit 1
    fi
}

# 检查PHP环境
check_php() {
    log_info "检查PHP环境..."
    
    if command -v php &> /dev/null; then
        PHP_VERSION=$(php --version | head -n1 | cut -d' ' -f2)
        PHP_MAJOR=$(echo $PHP_VERSION | cut -d'.' -f1)
        PHP_MINOR=$(echo $PHP_VERSION | cut -d'.' -f2)
        
        if [[ $PHP_MAJOR -ge 8 && $PHP_MINOR -ge 1 ]]; then
            log_success "PHP版本符合要求: $PHP_VERSION"
        else
            log_error "PHP版本过低，需要8.1+，当前版本: $PHP_VERSION"
            exit 1
        fi
    else
        log_error "PHP未安装，请先安装PHP 8.1+"
        exit 1
    fi
}

# 检查MySQL
check_mysql() {
    log_info "检查MySQL环境..."
    
    if command -v mysql &> /dev/null; then
        MYSQL_VERSION=$(mysql --version | cut -d' ' -f3)
        log_success "MySQL客户端已安装: $MYSQL_VERSION"
    else
        log_warning "MySQL客户端未安装，请确保数据库服务可用"
    fi
}

# 检查Docker
check_docker() {
    log_info "检查Docker环境..."
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        log_success "Docker已安装: $DOCKER_VERSION"
        
        if command -v docker-compose &> /dev/null; then
            COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
            log_success "Docker Compose已安装: $COMPOSE_VERSION"
        else
            log_warning "Docker Compose未安装，建议安装以支持容器化部署"
        fi
    else
        log_warning "Docker未安装，将使用原生部署方式"
    fi
}

# 检查权限
check_permissions() {
    log_info "检查安装权限..."
    
    if [[ $EUID -eq 0 ]]; then
        log_warning "以root用户运行，请注意安全性"
    else
        log_success "非root用户运行，安全性较好"
    fi
}

# 主检查函数
check_environment() {
    log_info "开始环境检查..."
    echo ""
    
    check_os
    check_architecture
    check_memory
    check_disk_space
    check_network
    check_required_commands
    check_python
    check_php
    check_mysql
    check_docker
    check_permissions
    
    echo ""
    log_success "环境检查完成！"
    echo ""
    log_info "系统信息:"
    echo "  操作系统: $OS"
    echo "  架构: $ARCH"
    echo "  内存: ${MEMORY_MB}MB"
    echo "  磁盘空间: ${DISK_SPACE_MB}MB"
    echo "  Python: $PYTHON_VERSION"
    echo "  PHP: $PHP_VERSION"
    echo ""
}
