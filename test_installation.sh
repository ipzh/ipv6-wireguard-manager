#!/bin/bash

# IPv6 WireGuard Manager 安装测试脚本
# 用于验证安装是否成功

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

# 检查函数
check_service() {
    local service_name=$1
    log_info "检查服务: $service_name"
    
    if systemctl is-active --quiet "$service_name"; then
        log_success "$service_name 服务运行正常"
        return 0
    else
        log_error "$service_name 服务未运行"
        return 1
    fi
}

check_port() {
    local port=$1
    local service_name=$2
    log_info "检查端口: $port ($service_name)"
    
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        log_success "端口 $port 监听正常"
        return 0
    else
        log_error "端口 $port 未监听"
        return 1
    fi
}

check_http_response() {
    local url=$1
    local expected_status=$2
    log_info "检查HTTP响应: $url"
    
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [ "$status_code" = "$expected_status" ]; then
        log_success "HTTP响应正常: $status_code"
        return 0
    else
        log_error "HTTP响应异常: $status_code (期望: $expected_status)"
        return 1
    fi
}

check_file() {
    local file_path=$1
    local description=$2
    log_info "检查文件: $file_path ($description)"
    
    if [ -f "$file_path" ]; then
        log_success "$description 文件存在"
        return 0
    else
        log_error "$description 文件不存在"
        return 1
    fi
}

check_directory() {
    local dir_path=$1
    local description=$2
    log_info "检查目录: $dir_path ($description)"
    
    if [ -d "$dir_path" ]; then
        log_success "$description 目录存在"
        return 0
    else
        log_error "$description 目录不存在"
        return 1
    fi
}

# 主测试函数
main() {
    echo "=========================================="
    echo "🧪 IPv6 WireGuard Manager 安装测试"
    echo "=========================================="
    echo ""
    
    local test_results=()
    local total_tests=0
    local passed_tests=0
    
    # 检查安装目录
    log_info "检查安装目录..."
    if [ -d "/opt/ipv6-wireguard-manager" ]; then
        INSTALL_DIR="/opt/ipv6-wireguard-manager"
    elif [ -d "./backend" ]; then
        INSTALL_DIR="."
    else
        log_error "未找到安装目录"
        exit 1
    fi
    
    log_success "安装目录: $INSTALL_DIR"
    echo ""
    
    # 1. 检查服务状态
    log_info "1. 检查服务状态..."
    if check_service "ipv6-wireguard-manager"; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    if check_service "nginx"; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    if check_service "mysql"; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    if check_service "redis-server"; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    echo ""
    
    # 2. 检查端口监听
    log_info "2. 检查端口监听..."
    if check_port "80" "Nginx"; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    if check_port "8000" "API服务器"; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    if check_port "3306" "MySQL"; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    if check_port "6379" "Redis"; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    echo ""
    
    # 3. 检查文件结构
    log_info "3. 检查文件结构..."
    if check_directory "$INSTALL_DIR/backend" "后端"; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    if check_directory "$INSTALL_DIR/frontend" "前端"; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    if check_file "$INSTALL_DIR/backend/.env" "环境变量文件"; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    echo ""
    
    # 4. 检查HTTP响应
    log_info "4. 检查HTTP响应..."
    if check_http_response "http://localhost:8000/health" "200"; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    if check_http_response "http://localhost:8000/" "200"; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    if check_http_response "http://localhost/" "200"; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    echo ""
    
    # 5. 检查数据库连接
    log_info "5. 检查数据库连接..."
    cd "$INSTALL_DIR/backend"
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
        if python scripts/check_environment.py > /dev/null 2>&1; then
            log_success "数据库连接正常"
            ((passed_tests++))
        else
            log_error "数据库连接失败"
        fi
    else
        log_warning "虚拟环境不存在，跳过数据库检查"
    fi
    ((total_tests++))
    
    echo ""
    
    # 显示测试结果
    echo "=========================================="
    echo "📊 测试结果汇总"
    echo "=========================================="
    echo ""
    log_info "总测试数: $total_tests"
    log_info "通过测试: $passed_tests"
    log_info "失败测试: $((total_tests - passed_tests))"
    echo ""
    
    if [ $passed_tests -eq $total_tests ]; then
        log_success "🎉 所有测试通过！安装成功！"
        echo ""
        log_info "访问地址:"
        log_info "  前端界面: http://localhost/"
        log_info "  API文档: http://localhost:8000/docs"
        log_info "  健康检查: http://localhost:8000/health"
        echo ""
        log_info "默认登录信息:"
        log_info "  用户名: admin"
        log_info "  密码: admin123"
        return 0
    else
        log_error "⚠️ 部分测试失败，请检查安装"
        echo ""
        log_info "故障排除:"
        log_info "  1. 检查服务状态: systemctl status ipv6-wireguard-manager"
        log_info "  2. 查看服务日志: journalctl -u ipv6-wireguard-manager -f"
        log_info "  3. 检查端口监听: netstat -tlnp | grep -E ':(80|8000|3306|6379)'"
        log_info "  4. 运行环境检查: cd $INSTALL_DIR/backend && python scripts/check_environment.py"
        return 1
    fi
}

# 运行主函数
main "$@"
