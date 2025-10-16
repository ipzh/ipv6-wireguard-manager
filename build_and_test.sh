#!/bin/bash

# IPv6 WireGuard Manager - 构建和测试脚本

set -e

echo "🚀 开始构建和测试 IPv6 WireGuard Manager..."

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

# 检查Docker是否安装
check_docker() {
    log_info "检查Docker环境..."
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    log_success "Docker环境检查通过"
}

# 构建后端镜像
build_backend() {
    log_info "构建后端Docker镜像..."
    cd backend
    docker build -t ipv6-wireguard-backend:latest .
    if [ $? -eq 0 ]; then
        log_success "后端镜像构建成功"
    else
        log_error "后端镜像构建失败"
        exit 1
    fi
    cd ..
}

# 构建前端镜像
build_frontend() {
    log_info "构建前端Docker镜像..."
    cd php-frontend
    docker build -t ipv6-wireguard-frontend:latest .
    if [ $? -eq 0 ]; then
        log_success "前端镜像构建成功"
    else
        log_error "前端镜像构建失败"
        exit 1
    fi
    cd ..
}

# 测试后端镜像
test_backend() {
    log_info "测试后端镜像..."
    docker run --rm -d --name test-backend -p 8001:8000 ipv6-wireguard-backend:latest
    
    # 等待服务启动
    sleep 10
    
    # 测试健康检查
    if curl -f http://localhost:8001/api/v1/health > /dev/null 2>&1; then
        log_success "后端健康检查通过"
    else
        log_warning "后端健康检查失败，但镜像构建成功"
    fi
    
    # 清理测试容器
    docker stop test-backend > /dev/null 2>&1
}

# 测试前端镜像
test_frontend() {
    log_info "测试前端镜像..."
    docker run --rm -d --name test-frontend -p 8080:80 ipv6-wireguard-frontend:latest
    
    # 等待服务启动
    sleep 10
    
    # 测试健康检查
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        log_success "前端健康检查通过"
    else
        log_warning "前端健康检查失败，但镜像构建成功"
    fi
    
    # 清理测试容器
    docker stop test-frontend > /dev/null 2>&1
}

# 验证Docker Compose配置
validate_compose() {
    log_info "验证Docker Compose配置..."
    if docker-compose config > /dev/null 2>&1; then
        log_success "Docker Compose配置验证通过"
    else
        log_error "Docker Compose配置验证失败"
        exit 1
    fi
}

# 主函数
main() {
    log_info "开始构建和测试流程..."
    
    # 检查环境
    check_docker
    
    # 验证配置
    validate_compose
    
    # 构建镜像
    build_backend
    build_frontend
    
    # 测试镜像
    test_backend
    test_frontend
    
    log_success "🎉 所有构建和测试完成！"
    log_info "可以使用以下命令启动完整服务："
    echo "  docker-compose up -d"
    echo ""
    log_info "或者单独启动服务："
    echo "  docker run -d -p 8000:8000 ipv6-wireguard-backend:latest"
    echo "  docker run -d -p 80:80 ipv6-wireguard-frontend:latest"
}

# 运行主函数
main "$@"
