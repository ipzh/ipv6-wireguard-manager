#!/bin/bash
# modules/module_import_checker.sh

# 模块导入检查工具
# 确保所有模块都能正确导入和初始化

# Source common functions
if [ -f "${IPV6WGM_ROOT_DIR}/modules/common_functions.sh" ]; then
    source "${IPV6WGM_ROOT_DIR}/modules/common_functions.sh"
elif [ -f "./modules/common_functions.sh" ]; then
    source "./modules/common_functions.sh"
else
    echo "Error: common_functions.sh not found!"
    exit 1
fi

# ================================================================
# 模块导入检查功能
# ================================================================

# 检查模块导入状态
check_module_imports() {
    log_info "检查模块导入状态..."
    
    local modules=(
        "common_functions"
        "function_standardization"
        "variable_management"
        "function_management"
        "main_script_refactor"
        "module_loading_tracker"
        "script_self_check"
        "config_version_control"
        "config_backup_recovery"
        "config_hot_reload"
        "module_version_compatibility"
        "module_preloading"
        "unified_windows_compatibility"
        "hardware_compatibility"
        "smart_caching"
        "enhanced_module_loader"
        "unified_config"
        "enhanced_config_management"
        "resource_monitoring"
        "lazy_loading"
        "dependency_manager"
        "enhanced_system_compatibility"
        "advanced_performance_optimization"
        "advanced_error_handling"
        "common_utils"
        "version_control"
    )
    
    local success_count=0
    local total_count=${#modules[@]}
    
    for module in "${modules[@]}"; do
        if check_single_module_import "$module"; then
            ((success_count++))
        fi
    done
    
    log_info "模块导入检查完成: $success_count/$total_count 成功"
    
    if [[ $success_count -eq $total_count ]]; then
        log_success "所有模块导入成功"
        return 0
    else
        log_warn "有 $((total_count - success_count)) 个模块导入失败"
        return 1
    fi
}

# 检查单个模块导入
check_single_module_import() {
    local module_name="$1"
    local module_path="${IPV6WGM_MODULES_DIR}/${module_name}.sh"
    
    # 检查文件是否存在
    if [[ ! -f "$module_path" ]]; then
        log_error "模块文件不存在: $module_name"
        return 1
    fi
    
    # 检查语法
    if ! bash -n "$module_path" 2>/dev/null; then
        log_error "模块语法错误: $module_name"
        return 1
    fi
    
    # 尝试导入模块
    if source "$module_path" 2>/dev/null; then
        log_success "模块导入成功: $module_name"
        return 0
    else
        log_error "模块导入失败: $module_name"
        return 1
    fi
}

# 检查核心函数可用性
check_core_functions_availability() {
    log_info "检查核心函数可用性..."
    
    local core_functions=(
        "log_info" "log_error" "log_warn" "log_success" "log_debug"
        "handle_error" "safe_execute"
        "detect_os" "detect_arch" "detect_package_manager"
        "load_config" "validate_config" "get_config_value"
        "import_module" "check_module"
        "convert_path" "ensure_directory"
        "set_permissions"
        "get_network_interfaces" "get_ip_address"
    )
    
    local available_count=0
    local total_count=${#core_functions[@]}
    
    for func in "${core_functions[@]}"; do
        if command -v "$func" >/dev/null 2>&1; then
            ((available_count++))
        else
            log_warn "核心函数不可用: $func"
        fi
    done
    
    log_info "核心函数可用性: $available_count/$total_count"
    
    if [[ $available_count -eq $total_count ]]; then
        log_success "所有核心函数都可用"
        return 0
    else
        log_warn "有 $((total_count - available_count)) 个核心函数不可用"
        return 1
    fi
}

# 检查模块依赖关系
check_module_dependencies() {
    log_info "检查模块依赖关系..."
    
    local dependency_issues=0
    
    # 检查关键依赖
    local critical_dependencies=(
        "common_functions:基础函数库"
        "function_standardization:函数标准化"
        "variable_management:变量管理"
        "unified_windows_compatibility:Windows兼容性"
    )
    
    for dep in "${critical_dependencies[@]}"; do
        local module="${dep%%:*}"
        local description="${dep##*:}"
        
        if ! check_single_module_import "$module"; then
            log_error "关键依赖缺失: $description ($module)"
            ((dependency_issues++))
        fi
    done
    
    if [[ $dependency_issues -eq 0 ]]; then
        log_success "所有关键依赖都满足"
        return 0
    else
        log_error "发现 $dependency_issues 个依赖问题"
        return 1
    fi
}

# 生成模块导入报告
generate_import_report() {
    log_info "生成模块导入报告..."
    
    local report_file="${IPV6WGM_LOG_DIR}/module_import_report_$(date +%Y%m%d%H%M%S).log"
    
    {
        echo "=== IPv6 WireGuard Manager 模块导入报告 ==="
        echo "生成时间: $(date)"
        echo "---------------------------------------"
        echo
        
        echo "--- 模块导入检查 ---"
        check_module_imports
        echo
        
        echo "--- 核心函数可用性检查 ---"
        check_core_functions_availability
        echo
        
        echo "--- 模块依赖关系检查 ---"
        check_module_dependencies
        echo
        
        echo "--- 环境信息 ---"
        echo "操作系统: $(uname -s)"
        echo "架构: $(uname -m)"
        echo "Shell: $SHELL"
        echo "Bash版本: $BASH_VERSION"
        echo "工作目录: $(pwd)"
        echo "模块目录: ${IPV6WGM_MODULES_DIR:-未设置}"
        echo
        
        echo "--- 已加载模块列表 ---"
        if command -v list_loaded_modules >/dev/null 2>&1; then
            list_loaded_modules
        else
            echo "模块列表功能不可用"
        fi
        echo
        
        echo "=== 报告结束 ==="
    } | tee "$report_file"
    
    log_success "模块导入报告已生成: $report_file"
    echo "$report_file"
    return 0
}

# 修复模块导入问题
fix_module_import_issues() {
    log_info "修复模块导入问题..."
    
    local fixes_applied=0
    
    # 确保模块目录存在
    if [[ ! -d "${IPV6WGM_MODULES_DIR}" ]]; then
        log_warn "模块目录不存在，尝试创建: ${IPV6WGM_MODULES_DIR}"
        if mkdir -p "${IPV6WGM_MODULES_DIR}" 2>/dev/null; then
            log_success "模块目录已创建"
            ((fixes_applied++))
        else
            log_error "无法创建模块目录"
        fi
    fi
    
    # 确保日志目录存在
    if [[ ! -d "${IPV6WGM_LOG_DIR}" ]]; then
        log_warn "日志目录不存在，尝试创建: ${IPV6WGM_LOG_DIR}"
        if mkdir -p "${IPV6WGM_LOG_DIR}" 2>/dev/null; then
            log_success "日志目录已创建"
            ((fixes_applied++))
        else
            log_error "无法创建日志目录"
        fi
    fi
    
    # 确保配置目录存在
    if [[ ! -d "${IPV6WGM_CONFIG_DIR}" ]]; then
        log_warn "配置目录不存在，尝试创建: ${IPV6WGM_CONFIG_DIR}"
        if mkdir -p "${IPV6WGM_CONFIG_DIR}" 2>/dev/null; then
            log_success "配置目录已创建"
            ((fixes_applied++))
        else
            log_error "无法创建配置目录"
        fi
    fi
    
    # 重新加载函数标准化
    if [[ -f "${IPV6WGM_MODULES_DIR}/function_standardization.sh" ]]; then
        log_info "重新加载函数标准化模块..."
        if source "${IPV6WGM_MODULES_DIR}/function_standardization.sh" 2>/dev/null; then
            if command -v ensure_core_functions >/dev/null 2>&1; then
                ensure_core_functions
                log_success "函数标准化模块重新加载成功"
                ((fixes_applied++))
            fi
        else
            log_error "函数标准化模块重新加载失败"
        fi
    fi
    
    log_info "应用了 $fixes_applied 个修复"
    return 0
}

# ================================================================
# 主函数
# ================================================================

# 主函数
main() {
    log_info "开始模块导入检查..."
    
    # 检查模块导入
    local import_status=0
    check_module_imports || import_status=1
    
    # 检查核心函数
    local function_status=0
    check_core_functions_availability || function_status=1
    
    # 检查依赖关系
    local dependency_status=0
    check_module_dependencies || dependency_status=1
    
    # 生成报告
    generate_import_report
    
    # 如果有问题，尝试修复
    if [[ $import_status -ne 0 || $function_status -ne 0 || $dependency_status -ne 0 ]]; then
        log_warn "发现模块导入问题，尝试修复..."
        fix_module_import_issues
    fi
    
    # 最终检查
    if [[ $import_status -eq 0 && $function_status -eq 0 && $dependency_status -eq 0 ]]; then
        log_success "模块导入检查完成，所有模块正常"
        return 0
    else
        log_error "模块导入检查完成，仍有问题需要解决"
        return 1
    fi
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

# 导出函数
export -f check_module_imports
export -f check_single_module_import
export -f check_core_functions_availability
export -f check_module_dependencies
export -f generate_import_report
export -f fix_module_import_issues
