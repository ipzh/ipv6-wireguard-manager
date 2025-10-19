#!/bin/bash

# Web服务检查脚本
# 用于检查Nginx前端服务的状态和功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置参数
WEB_PORT=${WEB_PORT:-80}
API_PORT=${API_PORT:-8000}
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
    
    # 尝试使用ss命令（现代系统）或netstat（传统系统）
    if command -v ss >/dev/null 2>&1; then
        if ss -tuln | grep -q ":$port "; then
            log_success "$description 端口 $port ($protocol) 正在监听"
            return 0
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -tuln | grep -q ":$port "; then
            log_success "$description 端口 $port ($protocol) 正在监听"
            return 0
        fi
    else
        # 如果没有ss或netstat，尝试使用lsof
        if command -v lsof >/dev/null 2>&1; then
            if lsof -i :$port >/dev/null 2>&1; then
                log_success "$description 端口 $port ($protocol) 正在监听"
                return 0
            fi
        else
            log_warning "无法检查端口监听状态（缺少ss、netstat或lsof命令）"
            return 1
        fi
    fi
    
    log_error "$description 端口 $port ($protocol) 未监听"
    return 1
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
    
    if curl -6 -s --connect-timeout 5 "http://[::1]:$port$path" >/dev/null 2>&1; then
        log_success "$service_name IPv6 连接正常"
        return 0
    else
        log_warning "$service_name IPv6 连接失败 (可能系统不支持IPv6或未启用)"
        return 1
    fi
}

# 检查Web页面响应
check_web_page_response() {
    log_info "检查Web页面响应..."
    
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$WEB_PORT/" 2>/dev/null)
    
    if [[ "$response_code" == "200" ]]; then
        log_success "Web页面响应正常 (HTTP 200)"
        return 0
    else
        log_error "Web页面响应异常 (HTTP $response_code)"
        return 1
    fi
}

# 检查Web页面内容
check_web_page_content() {
    log_info "检查Web页面内容..."
    
    local page_content=$(curl -s "http://localhost:$WEB_PORT/" 2>/dev/null)
    
    if [[ -n "$page_content" ]]; then
        # 检查是否包含常见的HTML标签
        if echo "$page_content" | grep -q "<html\|<HTML"; then
            log_success "Web页面包含HTML内容"
        else
            log_warning "Web页面可能不是标准HTML页面"
        fi
        
        # 检查是否包含JavaScript错误
        if echo "$page_content" | grep -q "JavaScript\|error\|Error"; then
            log_warning "Web页面可能包含JavaScript错误"
            echo "$page_content" | grep -o "JavaScript.*error\|Error.*" | head -5
        fi
        
        # 检查是否包含PHP错误
        if echo "$page_content" | grep -q "PHP Fatal error\|PHP Warning\|PHP Notice"; then
            log_error "Web页面包含PHP错误"
            echo "$page_content" | grep -o "PHP.*error\|PHP.*Warning\|PHP.*Notice" | head -5
            return 1
        fi
        
        return 0
    else
        log_error "无法获取Web页面内容"
        return 1
    fi
}

# 检查静态资源加载
check_static_resources() {
    log_info "检查静态资源加载..."
    
    local css_loaded=false
    local js_loaded=false
    
    # 获取页面内容并查找CSS和JS资源
    local page_content=$(curl -s "http://localhost:$WEB_PORT/" 2>/dev/null)
    
    # 检查CSS资源
    if echo "$page_content" | grep -q "link.*css\|\.css"; then
        local css_url=$(echo "$page_content" | grep -o 'href="[^"]*\.css"' | head -1 | cut -d'"' -f2)
        if [[ -n "$css_url" ]]; then
            if curl -s "http://localhost:$WEB_PORT/$css_url" >/dev/null 2>&1; then
                log_success "CSS资源加载正常: $css_url"
                css_loaded=true
            else
                log_error "CSS资源加载失败: $css_url"
            fi
        fi
    fi
    
    # 检查JS资源
    if echo "$page_content" | grep -q "script.*js\|\.js"; then
        local js_url=$(echo "$page_content" | grep -o 'src="[^"]*\.js"' | head -1 | cut -d'"' -f2)
        if [[ -n "$js_url" ]]; then
            if curl -s "http://localhost:$WEB_PORT/$js_url" >/dev/null 2>&1; then
                log_success "JS资源加载正常: $js_url"
                js_loaded=true
            else
                log_error "JS资源加载失败: $js_url"
            fi
        fi
    fi
    
    if $css_loaded && $js_loaded; then
        return 0
    else
        return 1
    fi
}

# 检查前端到API的连接
check_frontend_api_connection() {
    log_info "检查前端到API的连接..."
    
    # 检查API代理是否正常工作
    if curl -s "http://localhost:$WEB_PORT/api/v1/health" >/dev/null 2>&1; then
        log_success "前端到API的代理连接正常"
        return 0
    else
        log_error "前端到API的代理连接失败"
        
        # 尝试直接连接API服务
        if curl -s "http://localhost:$API_PORT/api/v1/health" >/dev/null 2>&1; then
            log_warning "API服务本身正常，但前端代理可能配置有误"
        else
            log_error "API服务本身也可能存在问题"
        fi
        
        return 1
    fi
}

# 检查Nginx配置
check_nginx_config() {
    log_info "检查Nginx配置..."
    
    if nginx -t >/dev/null 2>&1; then
        log_success "Nginx配置语法正确"
        return 0
    else
        log_error "Nginx配置存在语法错误"
        nginx -t
        return 1
    fi
}

# 检查Nginx日志
check_nginx_logs() {
    log_info "检查Nginx最近的日志..."
    
    local log_lines=10
    local error_count=$(tail -n $log_lines /var/log/nginx/error.log 2>/dev/null | grep -i "error\|crit\|alert\|emerg" | wc -l)
    
    if [[ $error_count -eq 0 ]]; then
        log_success "Nginx最近 $log_lines 行日志中无错误"
    else
        log_warning "Nginx最近 $log_lines 行日志中发现 $error_count 个错误"
        tail -n $log_lines /var/log/nginx/error.log 2>/dev/null | grep -i "error\|crit\|alert\|emerg"
    fi
}

# 检查PHP-FPM状态（如果使用PHP）
check_php_fpm_status() {
    log_info "检查PHP-FPM状态..."
    
    if systemctl is-active --quiet "php-fpm" 2>/dev/null || systemctl is-active --quiet "php7.4-fpm" 2>/dev/null || systemctl is-active --quiet "php8.0-fpm" 2>/dev/null || systemctl is-active --quiet "php8.1-fpm" 2>/dev/null || systemctl is-active --quiet "php8.2-fpm" 2>/dev/null; then
        log_success "PHP-FPM服务正在运行"
        return 0
    else
        log_warning "PHP-FPM服务未运行或未安装"
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
    echo "Web服务检查报告"
    echo "===================================="
    echo "总检查项目: $total_checks"
    echo -e "通过检查: ${GREEN}$passed_checks${NC}"
    echo -e "失败检查: ${RED}$failed_checks${NC}"
    
    if [[ $failed_checks -eq 0 ]]; then
        echo ""
        log_success "所有检查通过！Web服务运行正常。"
        return 0
    else
        echo ""
        log_warning "部分检查未通过，请检查相关配置和日志。"
        echo ""
        echo "常见问题解决方案："
        echo "1. 如果Nginx服务未运行，尝试: sudo systemctl start nginx"
        echo "2. 如果端口未监听，检查Nginx配置文件: /etc/nginx/sites-enabled/default"
        echo "3. 如果前端页面有错误，检查PHP错误日志: /var/log/php_errors.log"
        echo "4. 如果API代理失败，检查Nginx代理配置和API服务状态"
        return 1
    fi
}

# 主检查函数
main() {
    echo "===================================="
    echo "IPv6 WireGuard Manager Web服务检查"
    echo "===================================="
    echo ""
    
    local total_checks=0
    local passed_checks=0
    
    # 检查Nginx服务状态
    ((total_checks++))
    if check_service_status "nginx" "Nginx"; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查PHP-FPM服务状态
    ((total_checks++))
    if check_php_fpm_status; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查Web端口监听状态
    ((total_checks++))
    if check_port_listening "$WEB_PORT" "tcp" "Web服务"; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查IPv4连接性
    ((total_checks++))
    if check_ipv4_connectivity "Web服务" "$WEB_PORT" "/"; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查IPv6连接性
    ((total_checks++))
    if check_ipv6_connectivity "Web服务" "$WEB_PORT" "/"; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查Web页面响应
    ((total_checks++))
    if check_web_page_response; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查Web页面内容
    ((total_checks++))
    if check_web_page_content; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查静态资源加载
    ((total_checks++))
    if check_static_resources; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查前端到API的连接
    ((total_checks++))
    if check_frontend_api_connection; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查Nginx配置
    ((total_checks++))
    if check_nginx_config; then
        ((passed_checks++))
    fi
    echo ""
    
    # 检查Nginx日志
    ((total_checks++))
    if check_nginx_logs; then
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
    echo "  -p, --api-port PORT     指定API端口 (默认: 8000)"
    echo "  -w, --web-port PORT     指定Web端口 (默认: 80)"
    echo "  -h, --hostname HOST     指定主机名 (默认: localhost)"
    echo "  -i, --install-dir DIR   指定安装目录 (默认: /opt/ipv6-wireguard-manager)"
    echo "  --help                  显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                      # 使用默认参数检查"
    echo "  $0 -w 8080              # 指定Web端口为8080"
    echo "  $0 -w 8080 -p 8001      # 指定Web端口为8080，API端口为8001"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--api-port)
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