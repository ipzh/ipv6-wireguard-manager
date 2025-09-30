#!/bin/bash

# 模块加载状态追踪模块
# 提供详细的模块加载状态追踪和性能监控

# =============================================================================
# 追踪配置
# =============================================================================

# 加载状态枚举
declare -g IPV6WGM_MODULE_STATUS_LOADING="LOADING"
declare -g IPV6WGM_MODULE_STATUS_LOADED="LOADED"
declare -g IPV6WGM_MODULE_STATUS_FAILED="FAILED"
declare -g IPV6WGM_MODULE_STATUS_SKIPPED="SKIPPED"

# 模块加载状态存储
declare -A IPV6WGM_MODULE_LOADING_STATUS=()
declare -A IPV6WGM_MODULE_LOADING_START_TIME=()
declare -A IPV6WGM_MODULE_LOADING_END_TIME=()
declare -A IPV6WGM_MODULE_LOADING_DURATION=()
declare -A IPV6WGM_MODULE_LOADING_ERRORS=()
declare -A IPV6WGM_MODULE_LOADING_DEPENDENCIES=()

# 加载统计
declare -g IPV6WGM_TOTAL_MODULES_ATTEMPTED=0
declare -g IPV6WGM_TOTAL_MODULES_LOADED=0
declare -g IPV6WGM_TOTAL_MODULES_FAILED=0
declare -g IPV6WGM_TOTAL_LOADING_TIME=0

# 追踪开关
declare -g IPV6WGM_LOADING_TRACKING_ENABLED=true
declare -g IPV6WGM_LOADING_PERFORMANCE_MONITORING=true

# =============================================================================
# 追踪函数
# =============================================================================

# 初始化加载追踪
init_loading_tracker() {
    log_info "初始化模块加载追踪系统..."
    
    # 重置统计
    IPV6WGM_TOTAL_MODULES_ATTEMPTED=0
    IPV6WGM_TOTAL_MODULES_LOADED=0
    IPV6WGM_TOTAL_MODULES_FAILED=0
    IPV6WGM_TOTAL_LOADING_TIME=0
    
    # 清空状态存储
    IPV6WGM_MODULE_LOADING_STATUS=()
    IPV6WGM_MODULE_LOADING_START_TIME=()
    IPV6WGM_MODULE_LOADING_END_TIME=()
    IPV6WGM_MODULE_LOADING_DURATION=()
    IPV6WGM_MODULE_LOADING_ERRORS=()
    IPV6WGM_MODULE_LOADING_DEPENDENCIES=()
    
    log_success "模块加载追踪系统初始化完成"
}

# 开始追踪模块加载
start_module_tracking() {
    local module_name="$1"
    local dependencies="${2:-}"
    
    if [[ "$IPV6WGM_LOADING_TRACKING_ENABLED" != "true" ]]; then
        return 0
    fi
    
    log_debug "开始追踪模块加载: $module_name"
    
    # 记录开始时间
    IPV6WGM_MODULE_LOADING_START_TIME["$module_name"]=$(date +%s.%N)
    
    # 设置状态为加载中
    IPV6WGM_MODULE_LOADING_STATUS["$module_name"]="$IPV6WGM_MODULE_STATUS_LOADING"
    
    # 记录依赖关系
    if [[ -n "$dependencies" ]]; then
        IPV6WGM_MODULE_LOADING_DEPENDENCIES["$module_name"]="$dependencies"
    fi
    
    # 增加尝试计数
    ((IPV6WGM_TOTAL_MODULES_ATTEMPTED++))
}

# 完成模块加载追踪
complete_module_tracking() {
    local module_name="$1"
    local success="${2:-true}"
    local error_message="${3:-}"
    
    if [[ "$IPV6WGM_LOADING_TRACKING_ENABLED" != "true" ]]; then
        return 0
    fi
    
    # 记录结束时间
    IPV6WGM_MODULE_LOADING_END_TIME["$module_name"]=$(date +%s.%N)
    
    # 计算加载时间
    local start_time="${IPV6WGM_MODULE_LOADING_START_TIME[$module_name]}"
    local end_time="${IPV6WGM_MODULE_LOADING_END_TIME[$module_name]}"
    
    if [[ -n "$start_time" && -n "$end_time" ]]; then
        local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        IPV6WGM_MODULE_LOADING_DURATION["$module_name"]="$duration"
        IPV6WGM_TOTAL_LOADING_TIME=$(echo "$IPV6WGM_TOTAL_LOADING_TIME + $duration" | bc -l 2>/dev/null || echo "$IPV6WGM_TOTAL_LOADING_TIME")
    fi
    
    # 设置最终状态
    if [[ "$success" == "true" ]]; then
        IPV6WGM_MODULE_LOADING_STATUS["$module_name"]="$IPV6WGM_MODULE_STATUS_LOADED"
        ((IPV6WGM_TOTAL_MODULES_LOADED++))
        log_debug "模块加载完成: $module_name (${IPV6WGM_MODULE_LOADING_DURATION[$module_name]}s)"
    else
        IPV6WGM_MODULE_LOADING_STATUS["$module_name"]="$IPV6WGM_MODULE_STATUS_FAILED"
        IPV6WGM_MODULE_LOADING_ERRORS["$module_name"]="$error_message"
        ((IPV6WGM_TOTAL_MODULES_FAILED++))
        log_error "模块加载失败: $module_name - $error_message"
    fi
}

# 跳过模块加载追踪
skip_module_tracking() {
    local module_name="$1"
    local reason="${2:-skipped}"
    
    if [[ "$IPV6WGM_LOADING_TRACKING_ENABLED" != "true" ]]; then
        return 0
    fi
    
    IPV6WGM_MODULE_LOADING_STATUS["$module_name"]="$IPV6WGM_MODULE_STATUS_SKIPPED"
    IPV6WGM_MODULE_LOADING_ERRORS["$module_name"]="$reason"
    
    log_debug "模块加载跳过: $module_name - $reason"
}

# 获取模块加载状态
get_module_loading_status() {
    local module_name="$1"
    echo "${IPV6WGM_MODULE_LOADING_STATUS[$module_name]:-UNKNOWN}"
}

# 获取模块加载时间
get_module_loading_duration() {
    local module_name="$1"
    echo "${IPV6WGM_MODULE_LOADING_DURATION[$module_name]:-0}"
}

# 获取模块加载错误
get_module_loading_error() {
    local module_name="$1"
    echo "${IPV6WGM_MODULE_LOADING_ERRORS[$module_name]:-}"
}

# 获取模块依赖关系
get_module_dependencies() {
    local module_name="$1"
    echo "${IPV6WGM_MODULE_LOADING_DEPENDENCIES[$module_name]:-}"
}

# 检查模块是否已加载
is_module_loaded() {
    local module_name="$1"
    local status="${IPV6WGM_MODULE_LOADING_STATUS[$module_name]:-UNKNOWN}"
    [[ "$status" == "$IPV6WGM_MODULE_STATUS_LOADED" ]]
}

# 检查模块是否加载失败
is_module_failed() {
    local module_name="$1"
    local status="${IPV6WGM_MODULE_LOADING_STATUS[$module_name]:-UNKNOWN}"
    [[ "$status" == "$IPV6WGM_MODULE_STATUS_FAILED" ]]
}

# 获取加载统计信息
get_loading_statistics() {
    echo "=== 模块加载统计 ==="
    echo "总尝试加载: $IPV6WGM_TOTAL_MODULES_ATTEMPTED"
    echo "成功加载: $IPV6WGM_TOTAL_MODULES_LOADED"
    echo "加载失败: $IPV6WGM_TOTAL_MODULES_FAILED"
    echo "总加载时间: ${IPV6WGM_TOTAL_LOADING_TIME}s"
    
    if [[ $IPV6WGM_TOTAL_MODULES_ATTEMPTED -gt 0 ]]; then
        local success_rate=$(( (IPV6WGM_TOTAL_MODULES_LOADED * 100) / IPV6WGM_TOTAL_MODULES_ATTEMPTED ))
        echo "成功率: ${success_rate}%"
    fi
    
    if [[ $IPV6WGM_TOTAL_MODULES_LOADED -gt 0 ]]; then
        local avg_time=$(echo "scale=3; $IPV6WGM_TOTAL_LOADING_TIME / $IPV6WGM_TOTAL_MODULES_LOADED" | bc -l 2>/dev/null || echo "0")
        echo "平均加载时间: ${avg_time}s"
    fi
}

# 获取详细加载报告
get_detailed_loading_report() {
    local report_file="${LOG_DIR}/module_loading_report_$(date +%Y%m%d_%H%M%S).log"
    
    log_info "生成详细加载报告: $report_file"
    
    {
        echo "=== 模块加载详细报告 ==="
        echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "脚本版本: ${IPV6WGM_VERSION:-unknown}"
        echo
        
        echo "=== 加载统计 ==="
        get_loading_statistics
        echo
        
        echo "=== 模块加载详情 ==="
        for module_name in "${!IPV6WGM_MODULE_LOADING_STATUS[@]}"; do
            local status="${IPV6WGM_MODULE_LOADING_STATUS[$module_name]}"
            local duration="${IPV6WGM_MODULE_LOADING_DURATION[$module_name]:-0}"
            local error="${IPV6WGM_MODULE_LOADING_ERRORS[$module_name]:-}"
            local dependencies="${IPV6WGM_MODULE_LOADING_DEPENDENCIES[$module_name]:-}"
            
            echo "模块: $module_name"
            echo "  状态: $status"
            echo "  加载时间: ${duration}s"
            if [[ -n "$dependencies" ]]; then
                echo "  依赖: $dependencies"
            fi
            if [[ -n "$error" ]]; then
                echo "  错误: $error"
            fi
            echo
        done
        
        echo "=== 性能分析 ==="
        if [[ ${#IPV6WGM_MODULE_LOADING_DURATION[@]} -gt 0 ]]; then
            # 找出加载时间最长的模块
            local slowest_module=""
            local slowest_time=0
            for module_name in "${!IPV6WGM_MODULE_LOADING_DURATION[@]}"; do
                local duration="${IPV6WGM_MODULE_LOADING_DURATION[$module_name]}"
                if (( $(echo "$duration > $slowest_time" | bc -l 2>/dev/null || echo "0") )); then
                    slowest_time="$duration"
                    slowest_module="$module_name"
                fi
            done
            
            if [[ -n "$slowest_module" ]]; then
                echo "最慢加载模块: $slowest_module (${slowest_time}s)"
            fi
            
            # 计算加载时间分布
            local fast_count=0
            local medium_count=0
            local slow_count=0
            
            for module_name in "${!IPV6WGM_MODULE_LOADING_DURATION[@]}"; do
                local duration="${IPV6WGM_MODULE_LOADING_DURATION[$module_name]}"
                if (( $(echo "$duration < 0.1" | bc -l 2>/dev/null || echo "0") )); then
                    ((fast_count++))
                elif (( $(echo "$duration < 1.0" | bc -l 2>/dev/null || echo "0") )); then
                    ((medium_count++))
                else
                    ((slow_count++))
                fi
            done
            
            echo "加载时间分布:"
            echo "  快速 (<0.1s): $fast_count 个模块"
            echo "  中等 (0.1-1.0s): $medium_count 个模块"
            echo "  缓慢 (>1.0s): $slow_count 个模块"
        fi
        
    } > "$report_file"
    
    log_success "详细加载报告已生成: $report_file"
    return 0
}

# 显示实时加载状态
show_realtime_loading_status() {
    if [[ "$IPV6WGM_LOADING_TRACKING_ENABLED" != "true" ]]; then
        return 0
    fi
    
    echo "=== 实时模块加载状态 ==="
    
    local loading_count=0
    local loaded_count=0
    local failed_count=0
    local skipped_count=0
    
    for module_name in "${!IPV6WGM_MODULE_LOADING_STATUS[@]}"; do
        local status="${IPV6WGM_MODULE_LOADING_STATUS[$module_name]}"
        case "$status" in
            "$IPV6WGM_MODULE_STATUS_LOADING")
                ((loading_count++))
                echo "🔄 $module_name (加载中...)"
                ;;
            "$IPV6WGM_MODULE_STATUS_LOADED")
                ((loaded_count++))
                local duration="${IPV6WGM_MODULE_LOADING_DURATION[$module_name]:-0}"
                echo "✅ $module_name (已加载, ${duration}s)"
                ;;
            "$IPV6WGM_MODULE_STATUS_FAILED")
                ((failed_count++))
                local error="${IPV6WGM_MODULE_LOADING_ERRORS[$module_name]:-未知错误}"
                echo "❌ $module_name (失败: $error)"
                ;;
            "$IPV6WGM_MODULE_STATUS_SKIPPED")
                ((skipped_count++))
                echo "⏭️  $module_name (跳过)"
                ;;
        esac
    done
    
    echo
    echo "统计: 加载中 $loading_count, 已加载 $loaded_count, 失败 $failed_count, 跳过 $skipped_count"
}

# 启用/禁用加载追踪
set_loading_tracking() {
    local enabled="$1"
    IPV6WGM_LOADING_TRACKING_ENABLED="$enabled"
    
    if [[ "$enabled" == "true" ]]; then
        log_info "模块加载追踪已启用"
    else
        log_info "模块加载追踪已禁用"
    fi
}

# 启用/禁用性能监控
set_performance_monitoring() {
    local enabled="$1"
    IPV6WGM_LOADING_PERFORMANCE_MONITORING="$enabled"
    
    if [[ "$enabled" == "true" ]]; then
        log_info "模块加载性能监控已启用"
    else
        log_info "模块加载性能监控已禁用"
    fi
}

# 导出函数
export -f init_loading_tracker
export -f start_module_tracking
export -f complete_module_tracking
export -f skip_module_tracking
export -f get_module_loading_status
export -f get_module_loading_duration
export -f get_module_loading_error
export -f get_module_dependencies
export -f is_module_loaded
export -f is_module_failed
export -f get_loading_statistics
export -f get_detailed_loading_report
export -f show_realtime_loading_status
export -f set_loading_tracking
export -f set_performance_monitoring
