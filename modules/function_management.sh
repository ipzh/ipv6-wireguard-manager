#!/bin/bash

# 函数管理系统
# 提供函数定义检查、冲突检测和统一管理

# =============================================================================
# 函数注册表
# =============================================================================

# 已注册的函数列表
declare -A IPV6WGM_REGISTERED_FUNCTIONS=()
declare -A IPV6WGM_FUNCTION_SOURCES=()
declare -A IPV6WGM_FUNCTION_VERSIONS=()

# =============================================================================
# 函数管理函数
# =============================================================================

# 注册函数
register_function() {
    local func_name="$1"
    local source_file="$2"
    local version="${3:-1.0.0}"
    
    if [[ -n "${IPV6WGM_REGISTERED_FUNCTIONS[$func_name]:-}" ]]; then
        log_warn "函数 '$func_name' 已存在，来源: ${IPV6WGM_FUNCTION_SOURCES[$func_name]}"
        return 1
    fi
    
    IPV6WGM_REGISTERED_FUNCTIONS[$func_name]=1
    IPV6WGM_FUNCTION_SOURCES[$func_name]="$source_file"
    IPV6WGM_FUNCTION_VERSIONS[$func_name]="$version"
    
    log_debug "函数 '$func_name' 已注册，来源: $source_file"
    return 0
}

# 检查函数是否已注册
is_function_registered() {
    local func_name="$1"
    [[ -n "${IPV6WGM_REGISTERED_FUNCTIONS[$func_name]:-}" ]]
}

# 获取函数来源
get_function_source() {
    local func_name="$1"
    echo "${IPV6WGM_FUNCTION_SOURCES[$func_name]:-unknown}"
}

# 获取函数版本
get_function_version() {
    local func_name="$1"
    echo "${IPV6WGM_FUNCTION_VERSIONS[$func_name]:-unknown}"
}

# 列出所有已注册函数
list_registered_functions() {
    echo "=== 已注册函数列表 ==="
    for func in "${!IPV6WGM_REGISTERED_FUNCTIONS[@]}"; do
        local source="${IPV6WGM_FUNCTION_SOURCES[$func]}"
        local version="${IPV6WGM_FUNCTION_VERSIONS[$func]}"
        echo "$func (来源: $source, 版本: $version)"
    done
}

# 检查函数冲突
check_function_conflicts() {
    local conflicts=()
    
    # 检查重复定义的函数
    for func in "${!IPV6WGM_REGISTERED_FUNCTIONS[@]}"; do
        local sources=()
        for source in "${!IPV6WGM_FUNCTION_SOURCES[@]}"; do
            if [[ "${IPV6WGM_FUNCTION_SOURCES[$source]}" == "$func" ]]; then
                sources+=("$source")
            fi
        done
        
        if [[ ${#sources[@]} -gt 1 ]]; then
            conflicts+=("$func: ${sources[*]}")
        fi
    done
    
    if [[ ${#conflicts[@]} -gt 0 ]]; then
        log_error "发现函数冲突:"
        for conflict in "${conflicts[@]}"; do
            log_error "  $conflict"
        done
        return 1
    fi
    
    return 0
}

# 安全函数定义包装器
safe_define_function() {
    local func_name="$1"
    local source_file="$2"
    local version="${3:-1.0.0}"
    local func_body="$4"
    
    # 检查函数是否已存在
    if is_function_registered "$func_name"; then
        local existing_source=$(get_function_source "$func_name")
        log_warn "函数 '$func_name' 已存在，跳过定义 (现有来源: $existing_source)"
        return 0
    fi
    
    # 定义函数 - 使用更安全的方式
    bash -c "$func_body"
    
    # 注册函数
    register_function "$func_name" "$source_file" "$version"
    
    return 0
}

# 函数重写保护
protect_function() {
    local func_name="$1"
    local source_file="$2"
    
    if is_function_registered "$func_name"; then
        local existing_source=$(get_function_source "$func_name")
        if [[ "$existing_source" != "$source_file" ]]; then
            log_error "函数 '$func_name' 已被保护，不能重写 (现有来源: $existing_source)"
            return 1
        fi
    fi
    
    return 0
}

# 函数版本检查
check_function_version() {
    local func_name="$1"
    local required_version="$2"
    
    if ! is_function_registered "$func_name"; then
        log_error "函数 '$func_name' 未注册"
        return 1
    fi
    
    local current_version=$(get_function_version "$func_name")
    
    # 简单的版本比较 (假设版本格式为 x.y.z)
    if [[ "$current_version" != "$required_version" ]]; then
        log_warn "函数 '$func_name' 版本不匹配 (当前: $current_version, 需要: $required_version)"
        return 1
    fi
    
    return 0
}

# 函数依赖检查
check_function_dependencies() {
    local func_name="$1"
    local dependencies=("${@:2}")
    
    for dep in "${dependencies[@]}"; do
        if ! is_function_registered "$dep"; then
            log_error "函数 '$func_name' 缺少依赖: $dep"
            return 1
        fi
    done
    
    return 0
}

# 函数执行包装器
execute_function_safely() {
    local func_name="$1"
    local args=("${@:2}")
    
    if ! is_function_registered "$func_name"; then
        log_error "函数 '$func_name' 未注册"
        return 1
    fi
    
    # 执行函数
    "$func_name" "${args[@]}"
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "函数 '$func_name' 执行失败，退出码: $exit_code"
    fi
    
    return $exit_code
}

# 函数性能监控
monitor_function_performance() {
    local func_name="$1"
    local args=("${@:2}")
    
    if ! is_function_registered "$func_name"; then
        log_error "函数 '$func_name' 未注册"
        return 1
    fi
    
    local start_time=$(date +%s.%N)
    
    # 执行函数
    "$func_name" "${args[@]}"
    local exit_code=$?
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    
    log_debug "函数 '$func_name' 执行时间: ${duration}s"
    
    return $exit_code
}

# 函数文档生成
generate_function_docs() {
    local output_file="${1:-/tmp/function_docs.md}"
    
    {
        echo "# 函数文档"
        echo ""
        echo "生成时间: $(date)"
        echo ""
        
        for func in "${!IPV6WGM_REGISTERED_FUNCTIONS[@]}"; do
            local source="${IPV6WGM_FUNCTION_SOURCES[$func]}"
            local version="${IPV6WGM_FUNCTION_VERSIONS[$func]}"
            
            echo "## $func"
            echo ""
            echo "- **来源**: $source"
            echo "- **版本**: $version"
            echo "- **状态**: 已注册"
            echo ""
        done
    } > "$output_file"
    
    log_info "函数文档已生成: $output_file"
}

# 函数清理
cleanup_functions() {
    local source_file="$1"
    
    local functions_to_remove=()
    for func in "${!IPV6WGM_FUNCTION_SOURCES[@]}"; do
        if [[ "${IPV6WGM_FUNCTION_SOURCES[$func]}" == "$source_file" ]]; then
            functions_to_remove+=("$func")
        fi
    done
    
    for func in "${functions_to_remove[@]}"; do
        unset IPV6WGM_REGISTERED_FUNCTIONS[$func]
        unset IPV6WGM_FUNCTION_SOURCES[$func]
        unset IPV6WGM_FUNCTION_VERSIONS[$func]
        log_debug "已清理函数: $func"
    done
}

# 函数统计
get_function_stats() {
    local total_functions=${#IPV6WGM_REGISTERED_FUNCTIONS[@]}
    local sources=()
    
    for source in "${IPV6WGM_FUNCTION_SOURCES[@]}"; do
        sources+=("$source")
    done
    
    local unique_sources=$(printf '%s\n' "${sources[@]}" | sort -u | wc -l)
    
    echo "总函数数: $total_functions"
    echo "来源文件数: $unique_sources"
}

# 导出函数
export -f register_function
export -f is_function_registered
export -f get_function_source
export -f get_function_version
export -f list_registered_functions
export -f check_function_conflicts
export -f safe_define_function
export -f protect_function
export -f check_function_version
export -f check_function_dependencies
export -f execute_function_safely
export -f monitor_function_performance
export -f generate_function_docs
export -f cleanup_functions
export -f get_function_stats
