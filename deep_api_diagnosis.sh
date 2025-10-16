#!/bin/bash

# IPv6 WireGuard Manager - 深度API服务诊断脚本
# 全面检查API服务的所有可能问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

log_section() {
    echo -e "${CYAN}=== $1 ===${NC}"
}

# 默认配置
INSTALL_DIR="/opt/ipv6-wireguard-manager"
SERVICE_NAME="ipv6-wireguard-manager"
SERVICE_USER="ipv6wgm"
SERVICE_GROUP="ipv6wgm"
API_PORT="8000"
WEB_PORT="80"

# 诊断结果
DIAGNOSIS_RESULTS=()
ERRORS_FOUND=0
WARNINGS_FOUND=0

# 添加诊断结果
add_result() {
    local type="$1"
    local message="$2"
    DIAGNOSIS_RESULTS+=("$type|$message")
    
    if [[ "$type" == "ERROR" ]]; then
        ((ERRORS_FOUND++))
    elif [[ "$type" == "WARNING" ]]; then
        ((WARNINGS_FOUND++))
    fi
}

# 检查系统环境
check_system_environment() {
    log_section "系统环境检查"
    
    # 检查操作系统
    if [[ -f /etc/os-release ]]; then
        local os_info=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
        log_info "操作系统: $os_info"
        add_result "INFO" "操作系统: $os_info"
    else
        log_warning "无法确定操作系统版本"
        add_result "WARNING" "无法确定操作系统版本"
    fi
    
    # 检查内核版本
    local kernel_version=$(uname -r)
    log_info "内核版本: $kernel_version"
    add_result "INFO" "内核版本: $kernel_version"
    
    # 检查系统架构
    local arch=$(uname -m)
    log_info "系统架构: $arch"
    add_result "INFO" "系统架构: $arch"
    
    # 检查内存
    local memory=$(free -h | grep Mem | awk '{print $2}')
    log_info "系统内存: $memory"
    add_result "INFO" "系统内存: $memory"
    
    # 检查磁盘空间
    local disk_space=$(df -h / | tail -1 | awk '{print $4}')
    log_info "可用磁盘空间: $disk_space"
    add_result "INFO" "可用磁盘空间: $disk_space"
    
    echo ""
}

# 检查用户和权限
check_user_permissions() {
    log_section "用户和权限检查"
    
    # 检查服务用户
    if id "$SERVICE_USER" &>/dev/null; then
        local user_info=$(id "$SERVICE_USER")
        log_success "✓ 服务用户存在: $user_info"
        add_result "SUCCESS" "服务用户存在: $SERVICE_USER"
    else
        log_error "✗ 服务用户不存在: $SERVICE_USER"
        add_result "ERROR" "服务用户不存在: $SERVICE_USER"
    fi
    
    # 检查服务组
    if getent group "$SERVICE_GROUP" &>/dev/null; then
        log_success "✓ 服务组存在: $SERVICE_GROUP"
        add_result "SUCCESS" "服务组存在: $SERVICE_GROUP"
    else
        log_warning "⚠ 服务组不存在: $SERVICE_GROUP"
        add_result "WARNING" "服务组不存在: $SERVICE_GROUP"
    fi
    
    # 检查安装目录权限
    if [[ -d "$INSTALL_DIR" ]]; then
        local dir_owner=$(stat -c '%U:%G' "$INSTALL_DIR" 2>/dev/null || echo "unknown")
        if [[ "$dir_owner" == "$SERVICE_USER:$SERVICE_GROUP" ]]; then
            log_success "✓ 安装目录权限正确: $dir_owner"
            add_result "SUCCESS" "安装目录权限正确: $dir_owner"
        else
            log_error "✗ 安装目录权限不正确: $dir_owner (期望: $SERVICE_USER:$SERVICE_GROUP)"
            add_result "ERROR" "安装目录权限不正确: $dir_owner"
        fi
    else
        log_error "✗ 安装目录不存在: $INSTALL_DIR"
        add_result "ERROR" "安装目录不存在: $INSTALL_DIR"
    fi
    
    echo ""
}

# 检查Python环境
check_python_environment() {
    log_section "Python环境检查"
    
    # 检查Python版本
    if command -v python3 &>/dev/null; then
        local python_version=$(python3 --version 2>&1)
        log_info "Python版本: $python_version"
        add_result "INFO" "Python版本: $python_version"
    else
        log_error "✗ Python3未安装"
        add_result "ERROR" "Python3未安装"
    fi
    
    # 检查虚拟环境
    if [[ -d "$INSTALL_DIR/venv" ]]; then
        log_success "✓ Python虚拟环境存在"
        add_result "SUCCESS" "Python虚拟环境存在"
        
        # 检查虚拟环境Python
        if [[ -f "$INSTALL_DIR/venv/bin/python" ]]; then
            local venv_python_version=$("$INSTALL_DIR/venv/bin/python" --version 2>&1)
            log_info "虚拟环境Python版本: $venv_python_version"
            add_result "INFO" "虚拟环境Python版本: $venv_python_version"
        else
            log_error "✗ 虚拟环境Python不存在"
            add_result "ERROR" "虚拟环境Python不存在"
        fi
        
        # 检查关键Python包
        local packages=("fastapi" "uvicorn" "sqlalchemy" "pymysql" "aiomysql")
        for package in "${packages[@]}"; do
            if "$INSTALL_DIR/venv/bin/python" -c "import $package" &>/dev/null; then
                log_success "✓ $package 包可用"
                add_result "SUCCESS" "Python包 $package 可用"
            else
                log_error "✗ $package 包不可用"
                add_result "ERROR" "Python包 $package 不可用"
            fi
        done
    else
        log_error "✗ Python虚拟环境不存在"
        add_result "ERROR" "Python虚拟环境不存在"
    fi
    
    echo ""
}

# 检查应用文件
check_application_files() {
    log_section "应用文件检查"
    
    # 检查主要应用文件
    local app_files=(
        "$INSTALL_DIR/backend/app/main.py"
        "$INSTALL_DIR/backend/app/core/config_enhanced.py"
        "$INSTALL_DIR/backend/requirements.txt"
    )
    
    for file in "${app_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "✓ 文件存在: $file"
            add_result "SUCCESS" "文件存在: $(basename $file)"
            
            # 检查文件权限
            local file_owner=$(stat -c '%U:%G' "$file" 2>/dev/null || echo "unknown")
            if [[ "$file_owner" == "$SERVICE_USER:$SERVICE_GROUP" ]]; then
                log_success "✓ 文件权限正确: $file_owner"
            else
                log_warning "⚠ 文件权限不正确: $file_owner"
                add_result "WARNING" "文件权限不正确: $(basename $file)"
            fi
        else
            log_error "✗ 文件不存在: $file"
            add_result "ERROR" "文件不存在: $(basename $file)"
        fi
    done
    
    # 检查配置文件
    if [[ -f "$INSTALL_DIR/.env" ]]; then
        log_success "✓ 环境配置文件存在"
        add_result "SUCCESS" "环境配置文件存在"
        
        # 检查关键配置项
        local config_items=("DATABASE_URL" "SECRET_KEY" "HOST" "PORT")
        for item in "${config_items[@]}"; do
            if grep -q "^$item=" "$INSTALL_DIR/.env"; then
                log_success "✓ 配置项存在: $item"
                add_result "SUCCESS" "配置项存在: $item"
            else
                log_warning "⚠ 配置项缺失: $item"
                add_result "WARNING" "配置项缺失: $item"
            fi
        done
    else
        log_error "✗ 环境配置文件不存在"
        add_result "ERROR" "环境配置文件不存在"
    fi
    
    echo ""
}

# 检查目录结构
check_directory_structure() {
    log_section "目录结构检查"
    
    local required_dirs=(
        "$INSTALL_DIR/uploads"
        "$INSTALL_DIR/logs"
        "$INSTALL_DIR/wireguard"
        "$INSTALL_DIR/wireguard/clients"
        "$INSTALL_DIR/backups"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_success "✓ 目录存在: $dir"
            add_result "SUCCESS" "目录存在: $(basename $dir)"
            
            # 检查目录权限
            local dir_owner=$(stat -c '%U:%G' "$dir" 2>/dev/null || echo "unknown")
            if [[ "$dir_owner" == "$SERVICE_USER:$SERVICE_GROUP" ]]; then
                log_success "✓ 目录权限正确: $dir_owner"
            else
                log_warning "⚠ 目录权限不正确: $dir_owner"
                add_result "WARNING" "目录权限不正确: $(basename $dir)"
            fi
        else
            log_error "✗ 目录不存在: $dir"
            add_result "ERROR" "目录不存在: $(basename $dir)"
        fi
    done
    
    echo ""
}

# 检查数据库连接
check_database_connection() {
    log_section "数据库连接检查"
    
    # 检查MySQL服务
    if systemctl is-active --quiet mysql; then
        log_success "✓ MySQL服务运行中"
        add_result "SUCCESS" "MySQL服务运行中"
    elif systemctl is-active --quiet mariadb; then
        log_success "✓ MariaDB服务运行中"
        add_result "SUCCESS" "MariaDB服务运行中"
    else
        log_error "✗ 数据库服务未运行"
        add_result "ERROR" "数据库服务未运行"
    fi
    
    # 测试数据库连接
    if mysql -u ipv6wgm -pipv6wgm_password -e "SELECT 1;" &>/dev/null; then
        log_success "✓ 数据库连接正常"
        add_result "SUCCESS" "数据库连接正常"
        
        # 检查数据库是否存在
        if mysql -u ipv6wgm -pipv6wgm_password -e "USE ipv6wgm; SELECT 1;" &>/dev/null; then
            log_success "✓ 数据库 ipv6wgm 存在"
            add_result "SUCCESS" "数据库 ipv6wgm 存在"
        else
            log_warning "⚠ 数据库 ipv6wgm 不存在"
            add_result "WARNING" "数据库 ipv6wgm 不存在"
        fi
    else
        log_error "✗ 数据库连接失败"
        add_result "ERROR" "数据库连接失败"
    fi
    
    echo ""
}

# 检查网络和端口
check_network_ports() {
    log_section "网络和端口检查"
    
    # 检查API端口
    if netstat -tlnp 2>/dev/null | grep -q ":$API_PORT "; then
        log_success "✓ API端口 $API_PORT 正在监听"
        add_result "SUCCESS" "API端口 $API_PORT 正在监听"
    else
        log_error "✗ API端口 $API_PORT 未监听"
        add_result "ERROR" "API端口 $API_PORT 未监听"
    fi
    
    # 检查Web端口
    if netstat -tlnp 2>/dev/null | grep -q ":$WEB_PORT "; then
        log_success "✓ Web端口 $WEB_PORT 正在监听"
        add_result "SUCCESS" "Web端口 $WEB_PORT 正在监听"
    else
        log_warning "⚠ Web端口 $WEB_PORT 未监听"
        add_result "WARNING" "Web端口 $WEB_PORT 未监听"
    fi
    
    # 检查端口占用进程
    local api_process=$(netstat -tlnp 2>/dev/null | grep ":$API_PORT " | awk '{print $7}' | cut -d'/' -f1)
    if [[ -n "$api_process" ]]; then
        log_info "API端口进程: $api_process"
        add_result "INFO" "API端口进程: $api_process"
    fi
    
    echo ""
}

# 检查服务状态
check_service_status() {
    log_section "服务状态检查"
    
    # 检查systemd服务状态
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_success "✓ 服务正在运行"
        add_result "SUCCESS" "服务正在运行"
    else
        log_error "✗ 服务未运行"
        add_result "ERROR" "服务未运行"
    fi
    
    # 检查服务是否启用
    if systemctl is-enabled --quiet "$SERVICE_NAME"; then
        log_success "✓ 服务已启用"
        add_result "SUCCESS" "服务已启用"
    else
        log_warning "⚠ 服务未启用"
        add_result "WARNING" "服务未启用"
    fi
    
    # 检查服务文件
    if [[ -f "/etc/systemd/system/$SERVICE_NAME.service" ]]; then
        log_success "✓ 服务文件存在"
        add_result "SUCCESS" "服务文件存在"
        
        # 检查服务文件权限
        local service_owner=$(stat -c '%U:%G' "/etc/systemd/system/$SERVICE_NAME.service" 2>/dev/null || echo "unknown")
        if [[ "$service_owner" == "root:root" ]]; then
            log_success "✓ 服务文件权限正确: $service_owner"
        else
            log_warning "⚠ 服务文件权限不正确: $service_owner"
            add_result "WARNING" "服务文件权限不正确"
        fi
    else
        log_error "✗ 服务文件不存在"
        add_result "ERROR" "服务文件不存在"
    fi
    
    echo ""
}

# 检查API连接
check_api_connectivity() {
    log_section "API连接检查"
    
    # 检查本地API连接
    if curl -f http://localhost:$API_PORT/api/v1/health &>/dev/null; then
        log_success "✓ 本地API连接正常"
        add_result "SUCCESS" "本地API连接正常"
        
        # 获取API响应
        local api_response=$(curl -s http://localhost:$API_PORT/api/v1/health 2>/dev/null)
        if [[ -n "$api_response" ]]; then
            log_info "API响应: $api_response"
            add_result "INFO" "API响应正常"
        fi
    else
        log_error "✗ 本地API连接失败"
        add_result "ERROR" "本地API连接失败"
    fi
    
    # 检查API文档
    if curl -f http://localhost:$API_PORT/docs &>/dev/null; then
        log_success "✓ API文档可访问"
        add_result "SUCCESS" "API文档可访问"
    else
        log_warning "⚠ API文档不可访问"
        add_result "WARNING" "API文档不可访问"
    fi
    
    # 检查根路径
    if curl -f http://localhost:$API_PORT/ &>/dev/null; then
        log_success "✓ API根路径可访问"
        add_result "SUCCESS" "API根路径可访问"
    else
        log_warning "⚠ API根路径不可访问"
        add_result "WARNING" "API根路径不可访问"
    fi
    
    echo ""
}

# 检查前端连接
check_frontend_connectivity() {
    log_section "前端连接检查"
    
    # 检查前端页面
    if curl -f http://localhost:$WEB_PORT/ &>/dev/null; then
        log_success "✓ 前端页面可访问"
        add_result "SUCCESS" "前端页面可访问"
    else
        log_error "✗ 前端页面不可访问"
        add_result "ERROR" "前端页面不可访问"
    fi
    
    # 检查Nginx状态
    if systemctl is-active --quiet nginx; then
        log_success "✓ Nginx服务运行中"
        add_result "SUCCESS" "Nginx服务运行中"
    else
        log_error "✗ Nginx服务未运行"
        add_result "ERROR" "Nginx服务未运行"
    fi
    
    echo ""
}

# 检查日志和错误
check_logs_and_errors() {
    log_section "日志和错误检查"
    
    # 检查最近的错误日志
    local error_count=$(journalctl -u "$SERVICE_NAME" --no-pager -n 100 | grep -i error | wc -l)
    if [[ $error_count -gt 0 ]]; then
        log_warning "⚠ 发现 $error_count 个错误日志"
        add_result "WARNING" "发现 $error_count 个错误日志"
        
        # 显示最近的错误
        log_info "最近的错误:"
        journalctl -u "$SERVICE_NAME" --no-pager -n 20 | grep -i error | tail -5
    else
        log_success "✓ 未发现错误日志"
        add_result "SUCCESS" "未发现错误日志"
    fi
    
    # 检查服务重启次数
    local restart_count=$(systemctl show "$SERVICE_NAME" --property=ExecMainStatus --value 2>/dev/null || echo "0")
    if [[ "$restart_count" != "0" ]]; then
        log_warning "⚠ 服务重启次数: $restart_count"
        add_result "WARNING" "服务重启次数: $restart_count"
    fi
    
    echo ""
}

# 检查系统资源
check_system_resources() {
    log_section "系统资源检查"
    
    # 检查内存使用
    local memory_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    log_info "内存使用率: ${memory_usage}%"
    if (( $(echo "$memory_usage > 90" | bc -l) )); then
        log_warning "⚠ 内存使用率过高: ${memory_usage}%"
        add_result "WARNING" "内存使用率过高: ${memory_usage}%"
    else
        add_result "SUCCESS" "内存使用率正常: ${memory_usage}%"
    fi
    
    # 检查磁盘使用
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    log_info "磁盘使用率: ${disk_usage}%"
    if [[ $disk_usage -gt 90 ]]; then
        log_warning "⚠ 磁盘使用率过高: ${disk_usage}%"
        add_result "WARNING" "磁盘使用率过高: ${disk_usage}%"
    else
        add_result "SUCCESS" "磁盘使用率正常: ${disk_usage}%"
    fi
    
    # 检查CPU负载
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    log_info "CPU负载: $cpu_load"
    if (( $(echo "$cpu_load > 5.0" | bc -l) )); then
        log_warning "⚠ CPU负载过高: $cpu_load"
        add_result "WARNING" "CPU负载过高: $cpu_load"
    else
        add_result "SUCCESS" "CPU负载正常: $cpu_load"
    fi
    
    echo ""
}

# 显示诊断结果
show_diagnosis_results() {
    log_section "诊断结果汇总"
    
    echo "详细结果:"
    echo "=================================="
    
    for result in "${DIAGNOSIS_RESULTS[@]}"; do
        local type=$(echo "$result" | cut -d'|' -f1)
        local message=$(echo "$result" | cut -d'|' -f2-)
        
        case "$type" in
            "SUCCESS")
                log_success "✓ $message"
                ;;
            "ERROR")
                log_error "✗ $message"
                ;;
            "WARNING")
                log_warning "⚠ $message"
                ;;
            "INFO")
                log_info "ℹ $message"
                ;;
        esac
    done
    
    echo "=================================="
    log_info "总计: ${#DIAGNOSIS_RESULTS[@]} 项检查"
    log_success "成功: $((${#DIAGNOSIS_RESULTS[@]} - ERRORS_FOUND - WARNINGS_FOUND)) 项"
    
    if [[ $WARNINGS_FOUND -gt 0 ]]; then
        log_warning "警告: $WARNINGS_FOUND 项"
    fi
    
    if [[ $ERRORS_FOUND -gt 0 ]]; then
        log_error "错误: $ERRORS_FOUND 项"
        echo ""
        log_error "❌ 发现 $ERRORS_FOUND 个错误，需要修复"
        return 1
    else
        log_success "🎉 所有检查通过！"
        return 0
    fi
}

# 提供修复建议
provide_fix_suggestions() {
    if [[ $ERRORS_FOUND -gt 0 ]]; then
        log_section "修复建议"
        
        echo "根据发现的错误，建议执行以下修复步骤:"
        echo ""
        
        # 检查是否有权限相关错误
        if printf '%s\n' "${DIAGNOSIS_RESULTS[@]}" | grep -q "权限"; then
            echo "1. 修复权限问题:"
            echo "   ./fix_permissions.sh"
            echo ""
        fi
        
        # 检查是否有目录相关错误
        if printf '%s\n' "${DIAGNOSIS_RESULTS[@]}" | grep -q "目录不存在"; then
            echo "2. 创建缺失目录:"
            echo "   ./quick_fix_wireguard_permissions.sh"
            echo ""
        fi
        
        # 检查是否有服务相关错误
        if printf '%s\n' "${DIAGNOSIS_RESULTS[@]}" | grep -q "服务未运行"; then
            echo "3. 重启服务:"
            echo "   sudo systemctl restart $SERVICE_NAME"
            echo ""
        fi
        
        # 检查是否有数据库相关错误
        if printf '%s\n' "${DIAGNOSIS_RESULTS[@]}" | grep -q "数据库"; then
            echo "4. 检查数据库服务:"
            echo "   sudo systemctl status mysql"
            echo "   sudo systemctl status mariadb"
            echo ""
        fi
        
        echo "5. 查看详细日志:"
        echo "   sudo journalctl -u $SERVICE_NAME -f"
        echo ""
    fi
}

# 主函数
main() {
    log_info "IPv6 WireGuard Manager - 深度API服务诊断"
    echo ""
    
    # 执行所有检查
    check_system_environment
    check_user_permissions
    check_python_environment
    check_application_files
    check_directory_structure
    check_database_connection
    check_network_ports
    check_service_status
    check_api_connectivity
    check_frontend_connectivity
    check_logs_and_errors
    check_system_resources
    
    # 显示结果
    if show_diagnosis_results; then
        log_success "🎉 API服务诊断完成，所有检查通过！"
    else
        log_error "❌ API服务诊断完成，发现 $ERRORS_FOUND 个错误"
        provide_fix_suggestions
    fi
}

# 运行主函数
main "$@"
