#!/bin/bash

# IPv6 WireGuard Manager 日志检查工具
# 用于快速诊断安装和运行问题

echo "🔍 IPv6 WireGuard Manager 日志检查工具"
echo "========================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 检查服务状态
check_service_status() {
    log_info "检查服务状态..."
    
    services=("ipv6-wireguard-manager" "mysql" "nginx" "php8.2-fpm")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log_success "✓ $service 服务运行正常"
        else
            log_error "✗ $service 服务未运行"
        fi
    done
    echo ""
}

# 检查IPv6 WireGuard Manager服务日志
check_main_service_logs() {
    log_info "检查IPv6 WireGuard Manager服务日志..."
    
    echo "=== 最近10条日志 ==="
    journalctl -u ipv6-wireguard-manager --no-pager -n 10
    
    echo ""
    echo "=== 错误日志 ==="
    journalctl -u ipv6-wireguard-manager --no-pager --since "1 hour ago" | grep -i error || echo "最近1小时内无错误日志"
    
    echo ""
    echo "=== 警告日志 ==="
    journalctl -u ipv6-wireguard-manager --no-pager --since "1 hour ago" | grep -i warning || echo "最近1小时内无警告日志"
    echo ""
}

# 检查应用日志文件
check_app_logs() {
    log_info "检查应用日志文件..."
    
    # 检查日志目录
    LOG_DIR="/opt/ipv6-wireguard-manager/logs"
    if [ -d "$LOG_DIR" ]; then
        log_success "✓ 日志目录存在: $LOG_DIR"
        
        # 列出日志文件
        echo "日志文件列表:"
        find "$LOG_DIR" -name "*.log" -type f -exec ls -la {} \;
        
        # 检查最新的日志文件
        LATEST_LOG=$(find "$LOG_DIR" -name "*.log" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        if [ -n "$LATEST_LOG" ]; then
            echo ""
            echo "=== 最新日志文件内容 (最后20行) ==="
            tail -20 "$LATEST_LOG"
        fi
    else
        log_warning "⚠️ 日志目录不存在: $LOG_DIR"
    fi
    echo ""
}

# 检查数据库日志
check_database_logs() {
    log_info "检查数据库日志..."
    
    # MySQL错误日志
    MYSQL_ERROR_LOG="/var/log/mysql/error.log"
    if [ -f "$MYSQL_ERROR_LOG" ]; then
        echo "=== MySQL错误日志 (最后10行) ==="
        tail -10 "$MYSQL_ERROR_LOG"
    else
        log_warning "⚠️ MySQL错误日志不存在: $MYSQL_ERROR_LOG"
    fi
    
    # MySQL服务日志
    echo ""
    echo "=== MySQL服务日志 (最近10条) ==="
    journalctl -u mysql --no-pager -n 10
    echo ""
}

# 检查Nginx日志
check_nginx_logs() {
    log_info "检查Nginx日志..."
    
    # Nginx错误日志
    NGINX_ERROR_LOG="/var/log/nginx/error.log"
    if [ -f "$NGINX_ERROR_LOG" ]; then
        echo "=== Nginx错误日志 (最后10行) ==="
        tail -10 "$NGINX_ERROR_LOG"
    else
        log_warning "⚠️ Nginx错误日志不存在: $NGINX_ERROR_LOG"
    fi
    
    # Nginx访问日志
    NGINX_ACCESS_LOG="/var/log/nginx/access.log"
    if [ -f "$NGINX_ACCESS_LOG" ]; then
        echo ""
        echo "=== Nginx访问日志 (最后5行) ==="
        tail -5 "$NGINX_ACCESS_LOG"
    fi
    
    # Nginx服务日志
    echo ""
    echo "=== Nginx服务日志 (最近10条) ==="
    journalctl -u nginx --no-pager -n 10
    echo ""
}

# 检查PHP-FPM日志
check_php_logs() {
    log_info "检查PHP-FPM日志..."
    
    # PHP-FPM错误日志
    PHP_ERROR_LOG="/var/log/php8.2-fpm.log"
    if [ -f "$PHP_ERROR_LOG" ]; then
        echo "=== PHP-FPM错误日志 (最后10行) ==="
        tail -10 "$PHP_ERROR_LOG"
    else
        log_warning "⚠️ PHP-FPM错误日志不存在: $PHP_ERROR_LOG"
    fi
    
    # PHP-FPM服务日志
    echo ""
    echo "=== PHP-FPM服务日志 (最近10条) ==="
    journalctl -u php8.2-fpm --no-pager -n 10
    echo ""
}

# 检查系统资源
check_system_resources() {
    log_info "检查系统资源..."
    
    echo "=== 内存使用情况 ==="
    free -h
    
    echo ""
    echo "=== 磁盘使用情况 ==="
    df -h
    
    echo ""
    echo "=== CPU负载 ==="
    uptime
    echo ""
}

# 检查网络连接
check_network() {
    log_info "检查网络连接..."
    
    echo "=== 端口监听情况 ==="
    netstat -tulpn | grep -E ":(80|443|8000|3306|9000)" || echo "未找到相关端口监听"
    
    echo ""
    echo "=== 本地连接测试 ==="
    curl -s --connect-timeout 5 http://localhost/ > /dev/null && log_success "✓ Web服务可访问" || log_error "✗ Web服务不可访问"
    curl -s --connect-timeout 5 http://localhost:8000/ > /dev/null && log_success "✓ API服务可访问" || log_error "✗ API服务不可访问"
    echo ""
}

# 生成诊断报告
generate_report() {
    log_info "生成诊断报告..."
    
    REPORT_FILE="/tmp/ipv6-wireguard-manager-diagnosis-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "IPv6 WireGuard Manager 诊断报告"
        echo "生成时间: $(date)"
        echo "========================================"
        echo ""
        
        echo "=== 服务状态 ==="
        systemctl status ipv6-wireguard-manager --no-pager -l
        echo ""
        
        echo "=== 最近错误日志 ==="
        journalctl -u ipv6-wireguard-manager --no-pager --since "1 hour ago" | grep -i error
        echo ""
        
        echo "=== 系统资源 ==="
        free -h
        df -h
        echo ""
        
        echo "=== 网络连接 ==="
        netstat -tulpn | grep -E ":(80|443|8000|3306|9000)"
        
    } > "$REPORT_FILE"
    
    log_success "✓ 诊断报告已生成: $REPORT_FILE"
    echo ""
}

# 主菜单
show_menu() {
    echo "请选择要检查的日志类型:"
    echo "1) 检查所有日志"
    echo "2) 检查服务状态"
    echo "3) 检查IPv6 WireGuard Manager日志"
    echo "4) 检查数据库日志"
    echo "5) 检查Nginx日志"
    echo "6) 检查PHP-FPM日志"
    echo "7) 检查系统资源"
    echo "8) 检查网络连接"
    echo "9) 生成诊断报告"
    echo "0) 退出"
    echo ""
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        show_menu
        read -p "请输入选项 (0-9): " choice
        
        case $choice in
            1)
                check_service_status
                check_main_service_logs
                check_app_logs
                check_database_logs
                check_nginx_logs
                check_php_logs
                check_system_resources
                check_network
                ;;
            2) check_service_status ;;
            3) check_main_service_logs ;;
            4) check_database_logs ;;
            5) check_nginx_logs ;;
            6) check_php_logs ;;
            7) check_system_resources ;;
            8) check_network ;;
            9) generate_report ;;
            0) exit 0 ;;
            *) log_error "无效选项" ;;
        esac
    else
        # 命令行参数模式
        case $1 in
            "status") check_service_status ;;
            "main") check_main_service_logs ;;
            "db") check_database_logs ;;
            "nginx") check_nginx_logs ;;
            "php") check_php_logs ;;
            "system") check_system_resources ;;
            "network") check_network ;;
            "report") generate_report ;;
            "all")
                check_service_status
                check_main_service_logs
                check_app_logs
                check_database_logs
                check_nginx_logs
                check_php_logs
                check_system_resources
                check_network
                ;;
            *)
                echo "用法: $0 [status|main|db|nginx|php|system|network|report|all]"
                echo "或者不带参数运行以显示菜单"
                ;;
        esac
    fi
}

# 运行主函数
main "$@"
