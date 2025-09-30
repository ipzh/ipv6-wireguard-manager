#!/bin/bash

# 增强的模块加载系统
# 实现智能模块依赖管理和懒加载机制

# =============================================================================
# 模块依赖关系管理
# =============================================================================

# 模块依赖关系图
declare -A MODULE_DEPENDENCIES=(
    ["common_functions"]=""
    ["variable_management"]="common_functions"
    ["function_management"]="common_functions variable_management"
    ["main_script_refactor"]="common_functions variable_management function_management"
    ["unified_config"]="common_functions variable_management"
    ["error_handling"]="common_functions variable_management"
    ["enhanced_error_handling"]="common_functions error_handling"
    ["system_detection"]="common_functions variable_management"
    ["function_optimizer"]="common_functions function_management"
    ["wireguard_config"]="common_functions unified_config system_detection"
    ["bird_config"]="common_functions unified_config system_detection"
    ["web_management"]="common_functions unified_config error_handling"
    ["firewall_management"]="common_functions unified_config system_detection"
    ["client_management"]="common_functions unified_config wireguard_config"
    ["backup_restore"]="common_functions unified_config"
    ["system_monitoring"]="common_functions unified_config"
    ["resource_monitoring"]="common_functions system_monitoring"
    ["self_diagnosis"]="common_functions unified_config system_monitoring"
    ["lazy_loading"]="common_functions"
    ["version_control"]="common_functions"
    ["enhanced_module_loader"]="common_functions function_management"
)

# 模块版本信息
declare -A MODULE_VERSIONS=(
    ["common_functions"]="1.2.0"
    ["variable_management"]="1.0.0"
    ["function_management"]="1.0.0"
    ["main_script_refactor"]="1.0.0"
    ["unified_config"]="1.1.0"
    ["error_handling"]="1.0.0"
    ["enhanced_error_handling"]="1.0.0"
    ["system_detection"]="1.0.0"
    ["function_optimizer"]="1.0.0"
    ["wireguard_config"]="1.0.0"
    ["bird_config"]="1.0.0"
    ["web_management"]="1.0.0"
    ["firewall_management"]="1.0.0"
    ["client_management"]="1.0.0"
    ["backup_restore"]="1.0.0"
    ["system_monitoring"]="1.0.0"
    ["resource_monitoring"]="1.0.0"
    ["self_diagnosis"]="1.0.0"
    ["lazy_loading"]="1.0.0"
    ["version_control"]="1.0.0"
    ["enhanced_module_loader"]="1.1.0"
)

# 模块加载状态
declare -A MODULE_LOAD_STATES=(
    ["unloaded"]="未加载"
    ["loading"]="加载中"
    ["loaded"]="已加载"
    ["failed"]="加载失败"
    ["deprecated"]="已废弃"
)

# 已加载模块记录
declare -A LOADED_MODULES
declare -A MODULE_LOAD_TIMES
declare -A MODULE_LOAD_COUNTS

# 模块加载统计
declare -g TOTAL_MODULE_LOADS=0
declare -g TOTAL_MODULE_LOAD_TIME=0

# =============================================================================
# 核心模块加载函数
# =============================================================================

# 智能模块加载函数
load_module_smart() {
    local module_name="$1"
    local force_reload="${2:-false}"
    local start_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    # 检查模块是否已加载
    if [[ -n "${LOADED_MODULES[$module_name]}" && "$force_reload" != "true" ]]; then
        log_debug "模块 '$module_name' 已加载，跳过"
        return 0
    fi
    
    # 检查模块版本兼容性
    if ! check_module_version_compatibility "$module_name"; then
        log_error "模块 '$module_name' 版本不兼容"
        return 1
    fi
    
    # 检查模块依赖
    if [[ -n "${MODULE_DEPENDENCIES[$module_name]}" ]]; then
        for dep in ${MODULE_DEPENDENCIES[$module_name]}; do
            if [[ -n "$dep" ]]; then
                log_debug "加载模块 '$module_name' 的依赖: '$dep'"
                if ! load_module_smart "$dep" "$force_reload"; then
                    log_error "无法加载模块 '$module_name' 的依赖 '$dep'"
                    return 1
                fi
            fi
        done
    fi
    
    # 查找模块文件
    local module_path=""
    local search_paths=(
        "/opt/ipv6-wireguard-manager/modules/${module_name}.sh"
        "$IPV6WGM_MODULES_DIR/${module_name}.sh"
        "$(pwd)/modules/${module_name}.sh"
        "/usr/local/share/ipv6-wireguard-manager/modules/${module_name}.sh"
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -f "$path" ]]; then
            module_path="$path"
            break
        fi
    done
    
    if [[ -z "$module_path" ]]; then
        log_error "无法找到模块文件: $module_name"
        return 1
    fi
    
    # 加载模块
    log_debug "加载模块: $module_name (文件: $module_path, 版本: ${MODULE_VERSIONS[$module_name]})"
    
    # 记录加载前状态
    local functions_before=$(declare -F | wc -l)
    
    if source "$module_path"; then
        # 记录加载后状态
        local functions_after=$(declare -F | wc -l)
        local functions_added=$((functions_after - functions_before))
        
        # 更新加载记录
        LOADED_MODULES[$module_name]=1
        MODULE_LOAD_TIMES[$module_name]=$(date +%s%3N 2>/dev/null || date +%s)
        MODULE_LOAD_COUNTS[$module_name]=$((${MODULE_LOAD_COUNTS[$module_name]:-0} + 1))
        
        # 更新统计
        TOTAL_MODULE_LOADS=$((TOTAL_MODULE_LOADS + 1))
        local load_time=$(($(date +%s%3N 2>/dev/null || date +%s) - start_time))
        TOTAL_MODULE_LOAD_TIME=$((TOTAL_MODULE_LOAD_TIME + load_time))
        
        log_success "模块 '$module_name' 加载成功 (版本: ${MODULE_VERSIONS[$module_name]}, 新增函数: $functions_added, 耗时: ${load_time}ms)"
        return 0
    else
        log_error "模块 '$module_name' 加载失败"
        return 1
    fi
}

# 检查模块版本兼容性
check_module_version_compatibility() {
    local module_name="$1"
    local required_version="${MODULE_VERSIONS[$module_name]}"
    
    if [[ -z "$required_version" ]]; then
        log_warn "模块 '$module_name' 没有版本信息"
        return 0
    fi
    
    # 检查核心模块版本
    if [[ "$module_name" == "common_functions" ]]; then
        local current_version="1.2.0"
        if ! compare_versions "$current_version" "$required_version"; then
            log_error "核心模块版本不匹配: 当前 $current_version, 需要 $required_version"
            return 1
        fi
    fi
    
    return 0
}

# 版本比较函数
compare_versions() {
    local version1="$1"
    local version2="$2"
    
    # 简单的版本比较 (支持 x.y.z 格式)
    local IFS='.'
    local -a v1=($version1)
    local -a v2=($version2)
    
    for i in {0..2}; do
        local num1=${v1[$i]:-0}
        local num2=${v2[$i]:-0}
        
        if [[ $num1 -gt $num2 ]]; then
            return 0
        elif [[ $num1 -lt $num2 ]]; then
            return 1
        fi
    done
    
    return 0
}

# 懒加载模块函数
lazy_load_module() {
    local module_name="$1"
    local function_name="$2"
    
    # 检查函数是否已存在
    if declare -f "$function_name" >/dev/null 2>&1; then
        return 0
    fi
    
    # 懒加载模块
    if load_module_smart "$module_name"; then
        # 检查函数是否现在存在
        if declare -f "$function_name" >/dev/null 2>&1; then
            log_debug "懒加载成功: $function_name 来自模块 $module_name"
            return 0
        else
            log_warn "模块 $module_name 加载成功，但函数 $function_name 不存在"
            return 1
        fi
    else
        log_error "懒加载失败: 无法加载模块 $module_name"
        return 1
    fi
}

# 批量加载模块
load_modules_batch() {
    local modules=("$@")
    local success_count=0
    local failed_count=0
    
    log_info "开始批量加载模块: ${modules[*]}"
    
    for module in "${modules[@]}"; do
        if load_module_smart "$module"; then
            ((success_count++))
        else
            ((failed_count++))
        fi
    done
    
    log_info "批量加载完成: 成功 $success_count, 失败 $failed_count"
    
    if [[ $failed_count -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# =============================================================================
# 模块管理函数
# =============================================================================

# 列出已加载模块
list_loaded_modules() {
    log_info "已加载模块列表:"
    for module in "${!LOADED_MODULES[@]}"; do
        local load_time="${MODULE_LOAD_TIMES[$module]:-未知}"
        local load_count="${MODULE_LOAD_COUNTS[$module]:-0}"
        log_info "- $module (加载时间: $load_time, 加载次数: $load_count)"
    done
}

# 获取模块统计信息
get_module_stats() {
    local total_modules=${#LOADED_MODULES[@]}
    local avg_load_time=0
    
    if [[ $TOTAL_MODULE_LOADS -gt 0 ]]; then
        avg_load_time=$((TOTAL_MODULE_LOAD_TIME / TOTAL_MODULE_LOADS))
    fi
    
    echo "模块统计信息:"
    echo "- 已加载模块数: $total_modules"
    echo "- 总加载次数: $TOTAL_MODULE_LOADS"
    echo "- 平均加载时间: ${avg_load_time}ms"
    echo "- 总加载时间: ${TOTAL_MODULE_LOAD_TIME}ms"
}

# 检查模块依赖
check_module_dependencies() {
    local module_name="$1"
    
    if [[ -z "${MODULE_DEPENDENCIES[$module_name]}" ]]; then
        log_info "模块 '$module_name' 没有依赖"
        return 0
    fi
    
    log_info "模块 '$module_name' 的依赖关系:"
    for dep in ${MODULE_DEPENDENCIES[$module_name]}; do
        if [[ -n "$dep" ]]; then
            if [[ -n "${LOADED_MODULES[$dep]}" ]]; then
                log_success "- $dep (已加载)"
            else
                log_warn "- $dep (未加载)"
            fi
        fi
    done
}

# 卸载模块（实验性功能）
unload_module() {
    local module_name="$1"
    
    if [[ -z "${LOADED_MODULES[$module_name]}" ]]; then
        log_warn "模块 '$module_name' 未加载"
        return 1
    fi
    
    # 注意：在bash中完全卸载模块是困难的，这里只是标记为未加载
    unset LOADED_MODULES[$module_name]
    unset MODULE_LOAD_TIMES[$module_name]
    unset MODULE_LOAD_COUNTS[$module_name]
    
    log_info "模块 '$module_name' 已标记为卸载"
    return 0
}

# 清理模块缓存
clear_module_cache() {
    LOADED_MODULES=()
    MODULE_LOAD_TIMES=()
    MODULE_LOAD_COUNTS=()
    TOTAL_MODULE_LOADS=0
    TOTAL_MODULE_LOAD_TIME=0
    
    log_info "模块缓存已清理"
}

# =============================================================================
# 性能优化函数
# =============================================================================

# 预加载核心模块
preload_core_modules() {
    local core_modules=("common_functions" "unified_config" "error_handling")
    
    log_info "预加载核心模块..."
    load_modules_batch "${core_modules[@]}"
}

# 按需加载模块
load_module_on_demand() {
    local function_name="$1"
    local module_name="$2"
    
    # 检查函数是否已存在
    if declare -f "$function_name" >/dev/null 2>&1; then
        return 0
    fi
    
    # 如果指定了模块名，直接加载
    if [[ -n "$module_name" ]]; then
        lazy_load_module "$module_name" "$function_name"
        return $?
    fi
    
    # 否则尝试从所有模块中查找
    for module in "${!MODULE_DEPENDENCIES[@]}"; do
        if load_module_smart "$module" 2>/dev/null; then
            if declare -f "$function_name" >/dev/null 2>&1; then
                log_debug "按需加载成功: $function_name 来自模块 $module"
                return 0
            fi
        fi
    done
    
    log_error "无法找到函数: $function_name"
    return 1
}

# 导出函数
export -f load_module_smart lazy_load_module load_modules_batch
export -f list_loaded_modules get_module_stats check_module_dependencies
export -f unload_module clear_module_cache preload_core_modules load_module_on_demand
