#!/bin/bash

# API服务检查脚本
# 用于一键安装后检查API服务的状态和功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置参数
API_PORT=${API_PORT:-8000}
WEB_PORT=${WEB_PORT:-80}
HOSTNAME=${HOSTNAME:-localhost}
INSTALL_DIR=${INSTALL_DIR:-/opt/ipv6-wireguard-manager}

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

# 检查系统服务状态
check_service_status() {
    local service_name=$1
    local service_description=$2
    
    log_info "检查 $service_description 服务状态..."
    
    if systemctl is-active --quiet "$service_name"; then
        log_success "$service_description 服务正在运行"
        return 0
    else
        log_error "$service_description 服务未运行"
        return 1
    fi
}

# 检查端口监听状态
check_port_listening() {
    local port=$1
    local protocol=$2
    local description=$3
    
    log_info "检查 $description 端口 $port ($protocol) 监听状态..."
    
    # 尝试使用多种方法检查端口
    local port_found=false
    
    # 方法1: 使用 netstat (如果可用)
    if command -v netstat >/dev/null 2>&1; then
        if netstat -tuln | grep -q ":$port "; then
            port_found=true
        fi
    # 方法2: 使用 ss (如果可用)
    elif command -v ss >/dev/null 2>&1; then
        if ss -tuln | grep -q ":$port "; then
            port_found=true
        fi
    # 方法3: 使用 lsof (如果可用)
    elif command -v lsof >/dev/null 2>&1; then
        if lsof -i ":$port" >/dev/null 2>&1; then
            port_found=true
        fi
    # 方法4: 使用 telnet 测试连接
    elif command -v telnet >/dev/null 2>&1; then
        if echo "quit" | timeout 2 telnet localhost "$port" >/dev/null 2>&1; then
            port_found=true
        fi
    # 方法5: 使用 nc (netcat)
    elif command -v nc >/dev/null 2>&1; then
        if nc -z localhost "$port" >/dev/null 2>&1; then
            port_found=true
        fi
    else
        log_warning "无法找到合适的工具检查端口状态 (netstat, ss, lsof, telnet, nc)"
        return 1
    fi
    
    if [[ "$port_found" == "true" ]]; then
        log_success "$description 端口 $port ($protocol) 正在监听"
        return 0
    else
        log_error "$description 端口 $port ($protocol) 未监听"
        return 1
    fi
}

# 检查IPv4连接性
check_ipv4_connectivity() {
    local service_name=$1
    local port=$2
    local path=$3
    
    log_info "检查 $service_name IPv4 连接性..."
    
    if curl -4 -s --connect-timeout 5 "http://127.0.0.1:$port$path" >/dev/null 2>&1; then
        log_success "$service_name IPv4 连接正常"
        return 0
    else
        log_error "$service_name IPv4 连接失败"
        return 1
    fi
}

# 检查IPv6连接性
check_ipv6_connectivity() {
    local service_name=$1
    local port=$2
    local path=$3
    
    log_info "检查 $service_name IPv6 连接性..."
    
    # 首先检查系统是否支持IPv6
    if ! command -v ip >/dev/null 2>&1; then
        log_warning "无法检查IPv6支持状态 (ip命令不可用)"
        return 1
    fi
    
    # 检查是否有IPv6地址
    local ipv6_addresses=$(ip -6 addr show | grep -c "inet6")
    if [[ $ipv6_addresses -eq 0 ]]; then
        log_warning "$service_name IPv6 连接失败 (系统未配置IPv6地址)"
        return 1
    fi
    
    # 尝试多种IPv6连接方法
    local ipv6_connected=false
    
    # 方法1: 使用 ::1 (localhost IPv6)
    if curl -6 -s --connect-timeout 5 "http://[::1]:$port$path" >/dev/null 2>&1; then
        ipv6_connected=true
    # 方法2: 使用系统IPv6地址
    elif command -v ip >/dev/null 2>&1; then
        local system_ipv6=$(ip -6 addr show | grep "inet6" | grep -v "::1" | head -1 | awk '{print $2}' | cut -d'/' -f1)
        if [[ -n "$system_ipv6" ]]; then
            if curl -6 -s --connect-timeout 5 "http://[$system_ipv6]:$port$path" >/dev/null 2>&1; then
                ipv6_connected=true
            fi
        fi
    # 方法3: 使用 nc (netcat) 测试IPv6连接
    elif command -v nc >/dev/null 2>&1; then
        if nc -6 -z ::1 "$port" >/dev/null 2>&1; then
            ipv6_connected=true
        fi
    fi
    
    if [[ "$ipv6_connected" == "true" ]]; then
        log_success "$service_name IPv6 连接正常"
        return 0
    else
        log_warning "$service_name IPv6 连接失败 (可能系统不支持IPv6或未启用)"
        return 1
    fi
}

# 检查API健康状态
check_api_health() {
    log_info "检查API健康状态..."
    
    local response=$(curl -s --connect-timeout 10 "http://localhost:$API_PORT/api/v1/health" 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        # 尝试解析JSON响应
        if echo "$response" | grep -q '"status"' 2>/dev/null; then
            local status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
            if [[ "$status" == "healthy" || "$status" == "ok" ]]; then
                log_success "API健康状态: $status"
                return 0
            else
                log_warning "API健康状态: $status"
                return 1
            fi
        else
            log_success "API响应正常 (非标准健康检查端点)"
            return 0
        fi
    else
        log_error "无法获取API健康状态"
        return 1
    fi
}

# 检查API文档可访问性
check_api_docs() {
    log_info "检查API文档可访问性..."
    
    if curl -s --connect-timeout 10 "http://localhost:$API_PORT/docs" | grep -q "swagger" 2>/dev/null; then
        log_success "API文档可正常访问"
        return 0
    else
        log_error "无法访问API文档"
        return 1
    fi
}

# 检查API基本功能
check_api_functionality() {
    log_info "检查API基本功能..."
    
    # 检查API根端点
    local root_response=$(curl -s --connect-timeout 10 "http://localhost:$API_PORT/" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        log_success "API根端点响应正常"
    else
        log_error "API根端点无响应"
        return 1
    fi
    
    # 检查API版本端点
    local version_response=$(curl -s --connect-timeout 10 "http://localhost:$API_PORT/api/v1/" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        log_success "API版本端点响应正常"
    else
        log_warning "API版本端点无响应"
    fi
    
    return 0
}

# 检查API服务日志
check_api_logs() {
    log_info "检查API服务最近的日志..."
    
    local log_lines=10
    local error_count=$(journalctl -u ipv6-wireguard-manager --no-pager -n $log_lines | grep -i "error\|exception\|failed" | wc -l)
    
    if [[ $error_count -eq 0 ]]; then
        log_success "API服务最近 $log_lines 行日志中无错误"
    else
        log_warning "API服务最近 $log_lines 行日志中发现 $error_count 个错误"
        journalctl -u ipv6-wireguard-manager --no-pager -n $log_lines | grep -i "error\|exception\|failed"
    fi
}

# 检查API服务进程状态
check_api_process() {
    log_info "检查API服务进程状态..."
    
    local process_count=$(pgrep -f "uvicorn.*backend.app.main:app" | wc -l)
    
    if [[ $process_count -gt 0 ]]; then
        log_success "API服务进程正在运行 (进程数: $process_count)"
        
        # 检查进程资源使用情况
        local pid=$(pgrep -f "uvicorn.*backend.app.main:app" | head -1)
        if [[ -n "$pid" ]]; then
            local memory=$(ps -p "$pid" -o rss= | tr -d ' ')
            local memory_mb=$((memory / 1024))
            log_info "API服务进程内存使用: ${memory_mb}MB"
        fi
    else
        log_error "未找到API服务进程"
        return 1
    fi
}

# 生成检查报告
generate_report() {
    local total_checks=$1
    local passed_checks=$2
    local failed_checks=$((total_checks - passed_checks))
    
    echo ""
    echo "===================================="
    echo "API服务检查报告"
    echo "===================================="
    echo "总检查项目: $total_checks"
    echo -e "通过检查: ${GREEN}$passed_checks${NC}"
    echo -e "失败检查: ${RED}$failed_checks${NC}"
    
    if [[ $failed_checks -eq 0 ]]; then
        echo ""
        log_success "所有检查通过！API服务运行正常。"
        return 0
    else
        echo ""
        log_warning "部分检查未通过，请检查相关配置和日志。"
        return 1
    fi
}

# 主检查函数
main() {
    echo "===================================="
    echo "IPv6 WireGuard Manager API服务检查"
    echo "===================================="
    echo ""
    
    local total_checks=0
    local passed_checks=0
    
    # 检查系统服务状态
    ((total_checks++))
    if check_service_status "ipv6-wireguard-manager" "API服务"; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查端口监听状态
    ((total_checks++))
    if check_port_listening "$API_PORT" "tcp" "API服务"; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查IPv4连接性
    ((total_checks++))
    if check_ipv4_connectivity "API服务" "$API_PORT" "/api/v1/health"; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查IPv6连接性
    ((total_checks++))
    if check_ipv6_connectivity "API服务" "$API_PORT" "/api/v1/health"; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查API健康状态
    ((total_checks++))
    if check_api_health; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查API文档可访问性
    ((total_checks++))
    if check_api_docs; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查API基本功能
    ((total_checks++))
    if check_api_functionality; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查API服务进程状态
    ((total_checks++))
    if check_api_process; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查API服务日志
    ((total_checks++))
    if check_api_logs; then
        ((passed_checks++))
    fi
    echo ""
    
    # 生成检查报告
    generate_report $total_checks $passed_checks
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -p, --port PORT      指定API端口 (默认: 8000)"
    echo "  -w, --web-port PORT  指定Web端口 (默认: 80)"
    echo "  -h, --hostname HOST  指定主机名 (默认: localhost)"
    echo "  -i, --install-dir DIR 指定安装目录 (默认: /opt/ipv6-wireguard-manager)"
    echo "  --help               显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                   # 使用默认参数检查"
    echo "  $0 -p 8080           # 指定API端口为8080"
    echo "  $0 -w 8080 -p 8001   # 指定Web端口为8080，API端口为8001"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            API_PORT="$2"
            shift 2
            ;;
        -w|--web-port)
            WEB_PORT="$2"
            shift 2
            ;;
        -h|--hostname)
            HOSTNAME="$2"
            shift 2
            ;;
        -i|--install-dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 运行主函数
main "$@"