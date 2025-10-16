#!/bin/bash

# IPv6 WireGuard Manager - 综合API诊断脚本
# 结合系统检查和代码分析的全面诊断

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

log_section() {
    echo -e "${CYAN}=== $1 ===${NC}"
}

# 默认配置
INSTALL_DIR="/opt/ipv6-wireguard-manager"
SERVICE_NAME="ipv6-wireguard-manager"

log_section "IPv6 WireGuard Manager - 综合API诊断"

# 检查脚本权限
check_script_permissions() {
    log_info "检查诊断脚本权限..."
    
    local scripts=(
        "deep_api_diagnosis.sh"
        "deep_code_analysis.py"
        "fix_permissions.sh"
        "quick_fix_wireguard_permissions.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            chmod +x "$script"
            log_success "✓ 设置执行权限: $script"
        else
            log_warning "⚠ 脚本不存在: $script"
        fi
    done
}

# 运行系统诊断
run_system_diagnosis() {
    log_section "运行系统诊断"
    
    if [[ -f "deep_api_diagnosis.sh" ]]; then
        log_info "执行系统诊断..."
        chmod +x deep_api_diagnosis.sh
        ./deep_api_diagnosis.sh
    else
        log_error "系统诊断脚本不存在"
        return 1
    fi
}

# 运行代码分析
run_code_analysis() {
    log_section "运行代码分析"
    
    if [[ -f "deep_code_analysis.py" ]]; then
        log_info "执行代码分析..."
        chmod +x deep_code_analysis.py
        
        # 检查Python环境
        if command -v python3 &>/dev/null; then
            python3 deep_code_analysis.py
        else
            log_error "Python3未安装，无法运行代码分析"
            return 1
        fi
    else
        log_error "代码分析脚本不存在"
        return 1
    fi
}

# 运行权限修复
run_permission_fix() {
    log_section "运行权限修复"
    
    if [[ -f "quick_fix_wireguard_permissions.sh" ]]; then
        log_info "执行权限修复..."
        chmod +x quick_fix_wireguard_permissions.sh
        ./quick_fix_wireguard_permissions.sh
    else
        log_warning "权限修复脚本不存在，尝试使用通用修复脚本..."
        if [[ -f "fix_permissions.sh" ]]; then
            chmod +x fix_permissions.sh
            ./fix_permissions.sh
        else
            log_error "没有可用的权限修复脚本"
            return 1
        fi
    fi
}

# 测试API服务
test_api_service() {
    log_section "测试API服务"
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 10
    
    # 检查服务状态
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_success "✓ 服务正在运行"
    else
        log_error "✗ 服务未运行"
        return 1
    fi
    
    # 测试API连接
    log_info "测试API连接..."
    local retry_count=0
    local max_retries=10
    
    while [[ $retry_count -lt $max_retries ]]; do
        if curl -f http://localhost:8000/api/v1/health &>/dev/null; then
            log_success "✓ API连接成功"
            break
        else
            retry_count=$((retry_count + 1))
            log_info "API连接失败，重试 $retry_count/$max_retries..."
            sleep 3
        fi
    done
    
    if [[ $retry_count -eq $max_retries ]]; then
        log_error "✗ API连接失败，已达到最大重试次数"
        return 1
    fi
    
    # 测试API文档
    if curl -f http://localhost:8000/docs &>/dev/null; then
        log_success "✓ API文档可访问"
    else
        log_warning "⚠ API文档不可访问"
    fi
    
    # 测试前端页面
    if curl -f http://localhost/ &>/dev/null; then
        log_success "✓ 前端页面可访问"
    else
        log_warning "⚠ 前端页面不可访问"
    fi
}

# 显示最终状态
show_final_status() {
    log_section "最终状态检查"
    
    # 服务状态
    log_info "服务状态:"
    systemctl status "$SERVICE_NAME" --no-pager -l
    
    echo ""
    
    # 端口监听
    log_info "端口监听状态:"
    netstat -tlnp | grep -E ":(80|8000) " || log_warning "未检测到端口监听"
    
    echo ""
    
    # 最近日志
    log_info "最近的服务日志:"
    journalctl -u "$SERVICE_NAME" --no-pager -n 10
    
    echo ""
    
    # 系统资源
    log_info "系统资源使用:"
    echo "内存使用:"
    free -h
    echo ""
    echo "磁盘使用:"
    df -h /
}

# 提供修复建议
provide_fix_suggestions() {
    log_section "修复建议"
    
    echo "如果发现问题，可以尝试以下修复步骤:"
    echo ""
    echo "1. 权限问题修复:"
    echo "   ./quick_fix_wireguard_permissions.sh"
    echo ""
    echo "2. 服务重启:"
    echo "   sudo systemctl restart $SERVICE_NAME"
    echo ""
    echo "3. 查看详细日志:"
    echo "   sudo journalctl -u $SERVICE_NAME -f"
    echo ""
    echo "4. 使用CLI工具:"
    echo "   ipv6-wireguard-manager status"
    echo "   ipv6-wireguard-manager logs -f"
    echo ""
    echo "5. 重新安装:"
    echo "   ./install.sh"
    echo ""
}

# 主函数
main() {
    log_info "开始综合API诊断..."
    echo ""
    
    # 检查脚本权限
    check_script_permissions
    echo ""
    
    # 运行系统诊断
    if ! run_system_diagnosis; then
        log_error "系统诊断失败"
    fi
    echo ""
    
    # 运行代码分析
    if ! run_code_analysis; then
        log_error "代码分析失败"
    fi
    echo ""
    
    # 运行权限修复
    log_info "尝试修复发现的问题..."
    if ! run_permission_fix; then
        log_warning "权限修复失败，请手动检查"
    fi
    echo ""
    
    # 测试API服务
    if ! test_api_service; then
        log_error "API服务测试失败"
        echo ""
        provide_fix_suggestions
        exit 1
    fi
    echo ""
    
    # 显示最终状态
    show_final_status
    echo ""
    
    log_success "🎉 综合API诊断完成！"
    echo ""
    log_info "访问信息:"
    log_info "  API健康检查: http://localhost:8000/api/v1/health"
    log_info "  API文档: http://localhost:8000/docs"
    log_info "  前端页面: http://localhost/"
    echo ""
    log_info "管理命令:"
    log_info "  查看状态: ipv6-wireguard-manager status"
    log_info "  查看日志: ipv6-wireguard-manager logs -f"
    log_info "  系统监控: ipv6-wireguard-manager monitor"
}

# 运行主函数
main "$@"
