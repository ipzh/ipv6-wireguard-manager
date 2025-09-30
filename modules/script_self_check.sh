#!/bin/bash

# 脚本自检模块
# 提供全面的脚本自检功能，确保关键模块正确加载

# =============================================================================
# 自检配置
# =============================================================================

# 关键模块列表
declare -A IPV6WGM_CRITICAL_MODULES=(
    ["common_functions"]="公共函数库"
    ["variable_management"]="变量管理系统"
    ["function_management"]="函数管理系统"
    ["unified_config"]="统一配置管理"
    ["error_handling"]="错误处理系统"
    ["system_detection"]="系统检测模块"
    ["module_loader"]="模块加载器"
)

# 可选模块列表
declare -A IPV6WGM_OPTIONAL_MODULES=(
    ["wireguard_config"]="WireGuard配置"
    ["client_management"]="客户端管理"
    ["system_monitoring"]="系统监控"
    ["performance_optimizer"]="性能优化"
    ["enhanced_module_loader"]="增强模块加载器"
    ["lazy_loading"]="懒加载模块"
    ["config_cache"]="配置缓存"
)

# 自检结果存储
declare -A IPV6WGM_SELF_CHECK_RESULTS=()
declare -g IPV6WGM_SELF_CHECK_PASSED=0
declare -g IPV6WGM_SELF_CHECK_FAILED=0
declare -g IPV6WGM_SELF_CHECK_TOTAL=0

# =============================================================================
# 自检函数
# =============================================================================

# 初始化自检系统
init_self_check() {
    log_info "初始化脚本自检系统..."
    
    # 重置计数器
    IPV6WGM_SELF_CHECK_PASSED=0
    IPV6WGM_SELF_CHECK_FAILED=0
    IPV6WGM_SELF_CHECK_TOTAL=0
    
    # 清空结果存储
    IPV6WGM_SELF_CHECK_RESULTS=()
    
    log_success "脚本自检系统初始化完成"
}

# 检查关键模块加载状态
check_critical_modules() {
    log_info "检查关键模块加载状态..."
    
    local module_name
    local module_description
    local check_passed=0
    local check_failed=0
    
    for module_name in "${!IPV6WGM_CRITICAL_MODULES[@]}"; do
        module_description="${IPV6WGM_CRITICAL_MODULES[$module_name]}"
        ((IPV6WGM_SELF_CHECK_TOTAL++))
        
        if check_module_loaded "$module_name"; then
            IPV6WGM_SELF_CHECK_RESULTS["$module_name"]="PASS"
            ((IPV6WGM_SELF_CHECK_PASSED++))
            ((check_passed++))
            log_success "✓ $module_description ($module_name) 已加载"
        else
            IPV6WGM_SELF_CHECK_RESULTS["$module_name"]="FAIL"
            ((IPV6WGM_SELF_CHECK_FAILED++))
            ((check_failed++))
            log_error "✗ $module_description ($module_name) 未加载"
        fi
    done
    
    log_info "关键模块检查完成: $check_passed 通过, $check_failed 失败"
    return $check_failed
}

# 检查可选模块加载状态
check_optional_modules() {
    log_info "检查可选模块加载状态..."
    
    local module_name
    local module_description
    local check_passed=0
    local check_failed=0
    
    for module_name in "${!IPV6WGM_OPTIONAL_MODULES[@]}"; do
        module_description="${IPV6WGM_OPTIONAL_MODULES[$module_name]}"
        ((IPV6WGM_SELF_CHECK_TOTAL++))
        
        if check_module_loaded "$module_name"; then
            IPV6WGM_SELF_CHECK_RESULTS["$module_name"]="PASS"
            ((IPV6WGM_SELF_CHECK_PASSED++))
            ((check_passed++))
            log_success "✓ $module_description ($module_name) 已加载"
        else
            IPV6WGM_SELF_CHECK_RESULTS["$module_name"]="WARN"
            ((check_passed++))  # 可选模块失败不计入失败数
            log_warn "! $module_description ($module_name) 未加载 (可选)"
        fi
    done
    
    log_info "可选模块检查完成: $check_passed 通过"
    return 0
}

# 检查模块是否已加载
check_module_loaded() {
    local module_name="$1"
    
    # 检查模块文件是否存在
    local module_path="${MODULES_DIR}/${module_name}.sh"
    if [[ ! -f "$module_path" ]]; then
        return 1
    fi
    
    # 检查关键函数是否存在
    case "$module_name" in
        "common_functions")
            command -v log_info >/dev/null 2>&1 && command -v log_error >/dev/null 2>&1
            ;;
        "variable_management")
            command -v init_variables >/dev/null 2>&1
            ;;
        "function_management")
            command -v register_function >/dev/null 2>&1
            ;;
        "unified_config")
            command -v load_config >/dev/null 2>&1
            ;;
        "error_handling")
            command -v handle_error >/dev/null 2>&1
            ;;
        "system_detection")
            command -v detect_system >/dev/null 2>&1
            ;;
        "module_loader")
            command -v load_module >/dev/null 2>&1
            ;;
        "wireguard_config")
            command -v init_wireguard_config >/dev/null 2>&1
            ;;
        "client_management")
            command -v init_client_management >/dev/null 2>&1
            ;;
        "system_monitoring")
            command -v collect_system_metrics >/dev/null 2>&1
            ;;
        "performance_optimizer")
            command -v optimize_performance >/dev/null 2>&1
            ;;
        "enhanced_module_loader")
            command -v enhanced_load_module >/dev/null 2>&1
            ;;
        "lazy_loading")
            command -v lazy_load >/dev/null 2>&1
            ;;
        "config_cache")
            command -v cache_config >/dev/null 2>&1
            ;;
        *)
            # 默认检查：尝试加载模块并检查是否有错误
            source "$module_path" 2>/dev/null && return 0
            ;;
    esac
}

# 检查系统环境
check_system_environment() {
    log_info "检查系统环境..."
    
    local checks_passed=0
    local checks_failed=0
    
    # 检查操作系统
    if [[ -f /etc/os-release ]]; then
        log_success "✓ 操作系统信息可获取"
        ((checks_passed++))
    else
        log_error "✗ 无法获取操作系统信息"
        ((checks_failed++))
    fi
    
    # 检查权限
    if [[ $EUID -eq 0 ]]; then
        log_success "✓ 运行权限正常 (root)"
        ((checks_passed++))
    else
        log_warn "! 非root权限运行，某些功能可能受限"
        ((checks_passed++))
    fi
    
    # 检查必要命令
    local required_commands=("bash" "grep" "sed" "awk" "curl" "wget")
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            log_success "✓ 命令 $cmd 可用"
            ((checks_passed++))
        else
            log_error "✗ 命令 $cmd 不可用"
            ((checks_failed++))
        fi
    done
    
    # 检查目录权限
    local required_dirs=("$CONFIG_DIR" "$LOG_DIR" "$MODULES_DIR")
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" && -r "$dir" ]]; then
            log_success "✓ 目录 $dir 可访问"
            ((checks_passed++))
        else
            log_error "✗ 目录 $dir 不可访问"
            ((checks_failed++))
        fi
    done
    
    log_info "系统环境检查完成: $checks_passed 通过, $checks_failed 失败"
    return $checks_failed
}

# 检查配置完整性
check_config_integrity() {
    log_info "检查配置完整性..."
    
    local checks_passed=0
    local checks_failed=0
    
    # 检查主配置文件
    if [[ -f "$CONFIG_DIR/manager.conf" ]]; then
        log_success "✓ 主配置文件存在"
        ((checks_passed++))
    else
        log_error "✗ 主配置文件不存在"
        ((checks_failed++))
    fi
    
    # 检查配置目录权限
    if [[ -w "$CONFIG_DIR" ]]; then
        log_success "✓ 配置目录可写"
        ((checks_passed++))
    else
        log_error "✗ 配置目录不可写"
        ((checks_failed++))
    fi
    
    # 检查日志目录
    if [[ -w "$LOG_DIR" ]]; then
        log_success "✓ 日志目录可写"
        ((checks_passed++))
    else
        log_error "✗ 日志目录不可写"
        ((checks_failed++))
    fi
    
    log_info "配置完整性检查完成: $checks_passed 通过, $checks_failed 失败"
    return $checks_failed
}

# 生成自检报告
generate_self_check_report() {
    local report_file="${LOG_DIR}/self_check_report_$(date +%Y%m%d_%H%M%S).log"
    
    log_info "生成自检报告: $report_file"
    
    {
        echo "=== IPv6 WireGuard Manager 自检报告 ==="
        echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "脚本版本: ${IPV6WGM_VERSION:-unknown}"
        echo "系统信息: $(uname -a)"
        echo
        
        echo "=== 检查结果汇总 ==="
        echo "总检查项: $IPV6WGM_SELF_CHECK_TOTAL"
        echo "通过项目: $IPV6WGM_SELF_CHECK_PASSED"
        echo "失败项目: $IPV6WGM_SELF_CHECK_FAILED"
        echo "成功率: $(( (IPV6WGM_SELF_CHECK_PASSED * 100) / IPV6WGM_SELF_CHECK_TOTAL ))%"
        echo
        
        echo "=== 关键模块状态 ==="
        for module_name in "${!IPV6WGM_CRITICAL_MODULES[@]}"; do
            local status="${IPV6WGM_SELF_CHECK_RESULTS[$module_name]:-UNKNOWN}"
            local description="${IPV6WGM_CRITICAL_MODULES[$module_name]}"
            echo "$module_name ($description): $status"
        done
        echo
        
        echo "=== 可选模块状态 ==="
        for module_name in "${!IPV6WGM_OPTIONAL_MODULES[@]}"; do
            local status="${IPV6WGM_SELF_CHECK_RESULTS[$module_name]:-UNKNOWN}"
            local description="${IPV6WGM_OPTIONAL_MODULES[$module_name]}"
            echo "$module_name ($description): $status"
        done
        echo
        
        echo "=== 系统环境信息 ==="
        echo "操作系统: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "unknown")"
        echo "内核版本: $(uname -r)"
        echo "架构: $(uname -m)"
        echo "用户: $(whoami)"
        echo "工作目录: $(pwd)"
        echo "脚本目录: $SCRIPT_DIR"
        echo "模块目录: $MODULES_DIR"
        echo "配置目录: $CONFIG_DIR"
        echo "日志目录: $LOG_DIR"
        
    } > "$report_file"
    
    log_success "自检报告已生成: $report_file"
    return 0
}

# 执行完整自检
run_complete_self_check() {
    log_info "开始执行完整自检..."
    
    init_self_check
    
    local total_failures=0
    
    # 检查关键模块
    if ! check_critical_modules; then
        ((total_failures++))
    fi
    
    # 检查可选模块
    check_optional_modules
    
    # 检查系统环境
    if ! check_system_environment; then
        ((total_failures++))
    fi
    
    # 检查配置完整性
    if ! check_config_integrity; then
        ((total_failures++))
    fi
    
    # 生成报告
    generate_self_check_report
    
    # 输出结果
    echo
    echo "=== 自检结果汇总 ==="
    echo "总检查项: $IPV6WGM_SELF_CHECK_TOTAL"
    echo "通过项目: $IPV6WGM_SELF_CHECK_PASSED"
    echo "失败项目: $IPV6WGM_SELF_CHECK_FAILED"
    echo "成功率: $(( (IPV6WGM_SELF_CHECK_PASSED * 100) / IPV6WGM_SELF_CHECK_TOTAL ))%"
    
    if [[ $total_failures -eq 0 ]]; then
        log_success "所有自检项目通过！"
        return 0
    else
        log_error "有 $total_failures 个检查类别失败"
        return 1
    fi
}

# 快速自检（仅检查关键模块）
run_quick_self_check() {
    log_info "开始执行快速自检..."
    
    init_self_check
    check_critical_modules
    
    echo
    echo "=== 快速自检结果 ==="
    echo "关键模块检查: $IPV6WGM_SELF_CHECK_PASSED 通过, $IPV6WGM_SELF_CHECK_FAILED 失败"
    
    if [[ $IPV6WGM_SELF_CHECK_FAILED -eq 0 ]]; then
        log_success "关键模块检查通过！"
        return 0
    else
        log_error "关键模块检查失败"
        return 1
    fi
}

# 导出函数
export -f init_self_check
export -f check_critical_modules
export -f check_optional_modules
export -f check_module_loaded
export -f check_system_environment
export -f check_config_integrity
export -f generate_self_check_report
export -f run_complete_self_check
export -f run_quick_self_check
