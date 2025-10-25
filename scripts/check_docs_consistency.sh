#!/bin/bash

# IPv6 WireGuard Manager - 文档一致性检查脚本
# 用于检查安装文档与 install.sh 脚本的一致性

set -euo pipefail

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

# 检查文件是否存在
check_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log_error "文件不存在: $file"
        return 1
    fi
    return 0
}

# 检查文档中的安装命令
check_install_commands() {
    log_info "检查安装命令一致性..."
    
    local issues=0
    
    # 检查 QUICK_START.md
    if check_file_exists "docs/QUICK_START.md"; then
        if grep -q "install_native.sh" docs/QUICK_START.md; then
            log_warning "QUICK_START.md 中仍包含过时的 install_native.sh 命令"
            ((issues++))
        fi
        
        if grep -q "scripts/install.sh" docs/QUICK_START.md; then
            log_warning "QUICK_START.md 中仍包含过时的 scripts/install.sh 命令"
            ((issues++))
        fi
    fi
    
    # 检查 INSTALLATION_GUIDE.md
    if check_file_exists "docs/INSTALLATION_GUIDE.md"; then
        if grep -q "install_native.sh" docs/INSTALLATION_GUIDE.md; then
            log_warning "INSTALLATION_GUIDE.md 中仍包含过时的 install_native.sh 命令"
            ((issues++))
        fi
        
        if grep -q "scripts/install.sh" docs/INSTALLATION_GUIDE.md; then
            log_warning "INSTALLATION_GUIDE.md 中仍包含过时的 scripts/install.sh 命令"
            ((issues++))
        fi
    fi
    
    # 检查 README.md
    if check_file_exists "README.md"; then
        if grep -q "install_native.sh" README.md; then
            log_warning "README.md 中仍包含过时的 install_native.sh 命令"
            ((issues++))
        fi
        
        if grep -q "scripts/install.sh" README.md; then
            log_warning "README.md 中仍包含过时的 scripts/install.sh 命令"
            ((issues++))
        fi
    fi
    
    if [[ $issues -eq 0 ]]; then
        log_success "安装命令检查通过"
    else
        log_error "发现 $issues 个安装命令不一致问题"
    fi
    
    return $issues
}

# 检查文档中的参数选项
check_parameter_options() {
    log_info "检查参数选项一致性..."
    
    local issues=0
    
    # 从 install.sh 提取支持的参数
    local script_params=$(grep -E "^\s*--[a-zA-Z-]+" install.sh | sed 's/.*--\([a-zA-Z-]*\).*/\1/' | sort -u)
    
    # 检查文档中是否包含所有参数
    for param in $script_params; do
        if ! grep -q "--$param" docs/QUICK_START.md docs/INSTALLATION_GUIDE.md README.md 2>/dev/null; then
            log_warning "参数 --$param 在文档中未提及"
            ((issues++))
        fi
    done
    
    if [[ $issues -eq 0 ]]; then
        log_success "参数选项检查通过"
    else
        log_error "发现 $issues 个参数选项不一致问题"
    fi
    
    return $issues
}

# 检查系统要求描述
check_system_requirements() {
    log_info "检查系统要求描述一致性..."
    
    local issues=0
    
    # 检查操作系统支持
    if grep -q "Ubuntu 20.04+" docs/QUICK_START.md docs/INSTALLATION_GUIDE.md README.md 2>/dev/null; then
        log_warning "文档中仍包含过时的 Ubuntu 20.04+ 要求"
        ((issues++))
    fi
    
    if grep -q "CentOS 8+" docs/QUICK_START.md docs/INSTALLATION_GUIDE.md README.md 2>/dev/null; then
        log_warning "文档中仍包含过时的 CentOS 8+ 要求"
        ((issues++))
    fi
    
    if grep -q "Debian 11+" docs/QUICK_START.md docs/INSTALLATION_GUIDE.md README.md 2>/dev/null; then
        log_warning "文档中仍包含过时的 Debian 11+ 要求"
        ((issues++))
    fi
    
    if [[ $issues -eq 0 ]]; then
        log_success "系统要求描述检查通过"
    else
        log_error "发现 $issues 个系统要求描述不一致问题"
    fi
    
    return $issues
}

# 检查默认凭据描述
check_default_credentials() {
    log_info "检查默认凭据描述一致性..."
    
    local issues=0
    
    # 检查是否还包含固定密码
    if grep -q "admin123" docs/QUICK_START.md docs/INSTALLATION_GUIDE.md README.md 2>/dev/null; then
        log_warning "文档中仍包含过时的固定密码 admin123"
        ((issues++))
    fi
    
    if grep -q "ipv6wgm_password" docs/QUICK_START.md docs/INSTALLATION_GUIDE.md README.md 2>/dev/null; then
        log_warning "文档中仍包含过时的固定密码 ipv6wgm_password"
        ((issues++))
    fi
    
    if [[ $issues -eq 0 ]]; then
        log_success "默认凭据描述检查通过"
    else
        log_error "发现 $issues 个默认凭据描述不一致问题"
    fi
    
    return $issues
}

# 检查脚本语法
check_script_syntax() {
    log_info "检查 install.sh 脚本语法..."
    
    if bash -n install.sh; then
        log_success "install.sh 脚本语法检查通过"
        return 0
    else
        log_error "install.sh 脚本语法检查失败"
        return 1
    fi
}

# 检查脚本功能
check_script_functionality() {
    log_info "检查 install.sh 脚本功能..."
    
    local issues=0
    
    # 检查帮助函数是否存在
    if ! grep -q "show_help()" install.sh; then
        log_error "show_help 函数不存在"
        ((issues++))
    fi
    
    # 检查主要安装函数是否存在
    if ! grep -q "install_docker()" install.sh; then
        log_error "install_docker 函数不存在"
        ((issues++))
    fi
    
    if ! grep -q "install_basic_dependencies()" install.sh; then
        log_error "install_basic_dependencies 函数不存在"
        ((issues++))
    fi
    
    # 检查错误处理函数是否存在
    if ! grep -q "handle_error()" install.sh; then
        log_error "handle_error 函数不存在"
        ((issues++))
    fi
    
    if ! grep -q "safe_execute()" install.sh; then
        log_error "safe_execute 函数不存在"
        ((issues++))
    fi
    
    if [[ $issues -eq 0 ]]; then
        log_success "install.sh 脚本功能检查通过"
    else
        log_error "发现 $issues 个脚本功能问题"
    fi
    
    return $issues
}

# 生成检查报告
generate_report() {
    local total_issues=$1
    
    echo ""
    echo "=========================================="
    echo "文档一致性检查报告"
    echo "=========================================="
    echo "检查时间: $(date)"
    echo "总问题数: $total_issues"
    echo ""
    
    if [[ $total_issues -eq 0 ]]; then
        log_success "所有检查通过！文档与脚本完全一致。"
        echo ""
        echo "建议:"
        echo "1. 定期运行此检查脚本"
        echo "2. 在更新脚本后及时更新文档"
        echo "3. 建立自动化检查流程"
    else
        log_error "发现 $total_issues 个问题需要修复"
        echo ""
        echo "建议:"
        echo "1. 立即修复发现的问题"
        echo "2. 重新运行检查脚本验证修复"
        echo "3. 建立持续集成检查"
    fi
    
    echo "=========================================="
}

# 主函数
main() {
    log_info "开始文档一致性检查..."
    
    local total_issues=0
    
    # 检查脚本语法
    if ! check_script_syntax; then
        ((total_issues++))
    fi
    
    # 检查脚本功能
    if ! check_script_functionality; then
        ((total_issues++))
    fi
    
    # 检查安装命令
    if ! check_install_commands; then
        ((total_issues++))
    fi
    
    # 检查参数选项
    if ! check_parameter_options; then
        ((total_issues++))
    fi
    
    # 检查系统要求
    if ! check_system_requirements; then
        ((total_issues++))
    fi
    
    # 检查默认凭据
    if ! check_default_credentials; then
        ((total_issues++))
    fi
    
    # 生成报告
    generate_report $total_issues
    
    if [[ $total_issues -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# 运行主函数
main "$@"
