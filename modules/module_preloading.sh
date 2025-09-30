#!/bin/bash

# 模块预加载模块
# 提供模块预加载、优先级管理和性能优化功能

# =============================================================================
# 预加载配置
# =============================================================================

# 预加载设置
declare -g IPV6WGM_PRELOAD_ENABLED=true
declare -g IPV6WGM_PRELOAD_CACHE_ENABLED=true
declare -g IPV6WGM_PRELOAD_PRIORITY_ENABLED=true
declare -g IPV6WGM_PRELOAD_BACKGROUND_ENABLED=true

# 预加载目录
declare -g IPV6WGM_PRELOAD_CACHE_DIR="${CONFIG_DIR}/preload_cache"
declare -g IPV6WGM_PRELOAD_LOG_FILE="${LOG_DIR}/preload.log"

# 预加载优先级配置
declare -A IPV6WGM_MODULE_PRIORITIES=(
    ["common_functions"]=1
    ["variable_management"]=2
    ["function_management"]=3
    ["unified_config"]=4
    ["error_handling"]=5
    ["system_detection"]=6
    ["module_loader"]=7
    ["enhanced_module_loader"]=8
    ["script_self_check"]=9
    ["module_loading_tracker"]=10
    ["config_version_control"]=11
    ["config_backup_recovery"]=12
    ["config_hot_reload"]=13
    ["module_version_compatibility"]=14
    ["module_preloading"]=15
)

# 预加载状态
declare -A IPV6WGM_PRELOAD_STATUS=()
declare -A IPV6WGM_PRELOAD_CACHE=()
declare -A IPV6WGM_PRELOAD_TIMES=()
declare -g IPV6WGM_PRELOAD_COUNT=0
declare -g IPV6WGM_PRELOAD_SUCCESS_COUNT=0
declare -g IPV6WGM_PRELOAD_FAILED_COUNT=0

# 预加载队列
declare -a IPV6WGM_PRELOAD_QUEUE=()
declare -a IPV6WGM_PRELOAD_BACKGROUND_QUEUE=()

# =============================================================================
# 预加载函数
# =============================================================================

# 初始化预加载系统
init_preloading() {
    log_info "初始化模块预加载系统..."
    
    # 创建预加载缓存目录
    if ! mkdir -p "$IPV6WGM_PRELOAD_CACHE_DIR"; then
        log_error "无法创建预加载缓存目录: $IPV6WGM_PRELOAD_CACHE_DIR"
        return 1
    fi
    
    # 创建预加载日志文件
    if ! touch "$IPV6WGM_PRELOAD_LOG_FILE"; then
        log_error "无法创建预加载日志文件: $IPV6WGM_PRELOAD_LOG_FILE"
        return 1
    fi
    
    # 初始化预加载状态
    init_preload_status
    
    # 构建预加载队列
    build_preload_queue
    
    log_success "模块预加载系统初始化完成"
    return 0
}

# 初始化预加载状态
init_preload_status() {
    # 扫描所有模块
    for module_file in "$MODULES_DIR"/*.sh; do
        if [[ -f "$module_file" ]]; then
            local module_name=$(basename "$module_file" .sh)
            IPV6WGM_PRELOAD_STATUS["$module_name"]="pending"
        fi
    done
    
    log_debug "已初始化 ${#IPV6WGM_PRELOAD_STATUS[@]} 个模块的预加载状态"
}

# 构建预加载队列
build_preload_queue() {
    # 清空队列
    IPV6WGM_PRELOAD_QUEUE=()
    IPV6WGM_PRELOAD_BACKGROUND_QUEUE=()
    
    # 按优先级排序模块
    local sorted_modules=($(
        for module_name in "${!IPV6WGM_PRELOAD_STATUS[@]}"; do
            local priority="${IPV6WGM_MODULE_PRIORITIES[$module_name]:-999}"
            echo "$priority|$module_name"
        done | sort -n | cut -d'|' -f2
    ))
    
    # 将模块分配到队列
    for module_name in "${sorted_modules[@]}"; do
        local priority="${IPV6WGM_MODULE_PRIORITIES[$module_name]:-999}"
        
        if [[ $priority -le 10 ]]; then
            # 高优先级模块加入主队列
            IPV6WGM_PRELOAD_QUEUE+=("$module_name")
        else
            # 低优先级模块加入后台队列
            IPV6WGM_PRELOAD_BACKGROUND_QUEUE+=("$module_name")
        fi
    done
    
    log_debug "预加载队列构建完成: ${#IPV6WGM_PRELOAD_QUEUE[@]} 个主队列模块, ${#IPV6WGM_PRELOAD_BACKGROUND_QUEUE[@]} 个后台队列模块"
}

# 预加载模块
preload_module() {
    local module_name="$1"
    local background="${2:-false}"
    
    if [[ -z "$module_name" ]]; then
        log_error "请指定模块名称"
        return 1
    fi
    
    # 检查模块是否已加载
    if [[ "${IPV6WGM_PRELOAD_STATUS[$module_name]}" == "loaded" ]]; then
        log_debug "模块已加载: $module_name"
        return 0
    fi
    
    # 检查模块文件是否存在
    local module_file="${MODULES_DIR}/${module_name}.sh"
    if [[ ! -f "$module_file" ]]; then
        log_error "模块文件不存在: $module_file"
        IPV6WGM_PRELOAD_STATUS["$module_name"]="failed"
        ((IPV6WGM_PRELOAD_FAILED_COUNT++))
        return 1
    fi
    
    # 记录开始时间
    local start_time=$(date +%s.%N)
    
    # 检查缓存
    if [[ "$IPV6WGM_PRELOAD_CACHE_ENABLED" == "true" ]]; then
        if load_from_cache "$module_name"; then
            IPV6WGM_PRELOAD_STATUS["$module_name"]="loaded"
            ((IPV6WGM_PRELOAD_SUCCESS_COUNT++))
            log_debug "模块从缓存加载: $module_name"
            return 0
        fi
    fi
    
    # 加载模块
    if load_module_direct "$module_name"; then
        # 记录加载时间
        local end_time=$(date +%s.%N)
        local load_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        IPV6WGM_PRELOAD_TIMES["$module_name"]="$load_time"
        
        # 更新状态
        IPV6WGM_PRELOAD_STATUS["$module_name"]="loaded"
        ((IPV6WGM_PRELOAD_SUCCESS_COUNT++))
        
        # 保存到缓存
        if [[ "$IPV6WGM_PRELOAD_CACHE_ENABLED" == "true" ]]; then
            save_to_cache "$module_name"
        fi
        
        # 记录日志
        log_preload_event "$module_name" "loaded" "$load_time" "$background"
        
        log_debug "模块预加载成功: $module_name (${load_time}s)"
        return 0
    else
        IPV6WGM_PRELOAD_STATUS["$module_name"]="failed"
        ((IPV6WGM_PRELOAD_FAILED_COUNT++))
        
        # 记录日志
        log_preload_event "$module_name" "failed" "0" "$background"
        
        log_error "模块预加载失败: $module_name"
        return 1
    fi
}

# 直接加载模块
load_module_direct() {
    local module_name="$1"
    local module_file="${MODULES_DIR}/${module_name}.sh"
    
    # 使用source加载模块
    if source "$module_file" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 从缓存加载
load_from_cache() {
    local module_name="$1"
    local cache_file="${IPV6WGM_PRELOAD_CACHE_DIR}/${module_name}.cache"
    
    if [[ -f "$cache_file" ]]; then
        # 检查缓存是否过期
        local cache_time=$(stat -c %Y "$cache_file" 2>/dev/null || echo "0")
        local current_time=$(date +%s)
        local cache_age=$((current_time - cache_time))
        
        if [[ $cache_age -lt $IPV6WGM_VERSION_CACHE_TTL ]]; then
            # 从缓存加载
            if source "$cache_file" 2>/dev/null; then
                return 0
            fi
        fi
    fi
    
    return 1
}

# 保存到缓存
save_to_cache() {
    local module_name="$1"
    local module_file="${MODULES_DIR}/${module_name}.sh"
    local cache_file="${IPV6WGM_PRELOAD_CACHE_DIR}/${module_name}.cache"
    
    if [[ -f "$module_file" ]]; then
        cp "$module_file" "$cache_file" 2>/dev/null
    fi
}

# 记录预加载事件
log_preload_event() {
    local module_name="$1"
    local status="$2"
    local load_time="$3"
    local background="$4"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local bg_flag=""
    if [[ "$background" == "true" ]]; then
        bg_flag=" [BG]"
    fi
    
    echo "[$timestamp] $status: $module_name (${load_time}s)$bg_flag" >> "$IPV6WGM_PRELOAD_LOG_FILE"
}

# 预加载所有模块
preload_all_modules() {
    log_info "开始预加载所有模块..."
    
    local start_time=$(date +%s.%N)
    IPV6WGM_PRELOAD_COUNT=0
    IPV6WGM_PRELOAD_SUCCESS_COUNT=0
    IPV6WGM_PRELOAD_FAILED_COUNT=0
    
    # 预加载主队列模块
    for module_name in "${IPV6WGM_PRELOAD_QUEUE[@]}"; do
        ((IPV6WGM_PRELOAD_COUNT++))
        preload_module "$module_name" "false"
    done
    
    # 预加载后台队列模块
    if [[ "$IPV6WGM_PRELOAD_BACKGROUND_ENABLED" == "true" ]]; then
        for module_name in "${IPV6WGM_PRELOAD_BACKGROUND_QUEUE[@]}"; do
            ((IPV6WGM_PRELOAD_COUNT++))
            preload_module "$module_name" "true" &
        done
        
        # 等待后台加载完成
        wait
    fi
    
    # 计算总时间
    local end_time=$(date +%s.%N)
    local total_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    
    # 输出结果
    echo
    echo "=== 模块预加载结果 ==="
    echo "总模块数: $IPV6WGM_PRELOAD_COUNT"
    echo "成功加载: $IPV6WGM_PRELOAD_SUCCESS_COUNT"
    echo "加载失败: $IPV6WGM_PRELOAD_FAILED_COUNT"
    echo "总加载时间: ${total_time}s"
    
    if [[ $IPV6WGM_PRELOAD_SUCCESS_COUNT -gt 0 ]]; then
        local avg_time=$(echo "scale=3; $total_time / $IPV6WGM_PRELOAD_SUCCESS_COUNT" | bc -l 2>/dev/null || echo "0")
        echo "平均加载时间: ${avg_time}s"
    fi
    
    if [[ $IPV6WGM_PRELOAD_FAILED_COUNT -eq 0 ]]; then
        log_success "所有模块预加载成功！"
        return 0
    else
        log_error "有 $IPV6WGM_PRELOAD_FAILED_COUNT 个模块预加载失败"
        return 1
    fi
}

# 预加载指定模块
preload_specific_modules() {
    local modules=("$@")
    
    if [[ ${#modules[@]} -eq 0 ]]; then
        log_error "请指定要预加载的模块"
        return 1
    fi
    
    log_info "预加载指定模块: ${modules[*]}"
    
    local success_count=0
    local failed_count=0
    
    for module_name in "${modules[@]}"; do
        if preload_module "$module_name"; then
            ((success_count++))
        else
            ((failed_count++))
        fi
    done
    
    echo
    echo "=== 指定模块预加载结果 ==="
    echo "指定模块数: ${#modules[@]}"
    echo "成功加载: $success_count"
    echo "加载失败: $failed_count"
    
    if [[ $failed_count -eq 0 ]]; then
        log_success "所有指定模块预加载成功！"
        return 0
    else
        log_error "有 $failed_count 个指定模块预加载失败"
        return 1
    fi
}

# 获取预加载状态
get_preload_status() {
    echo "=== 模块预加载状态 ==="
    echo "预加载启用: $([ "$IPV6WGM_PRELOAD_ENABLED" == "true" ] && echo "是" || echo "否")"
    echo "缓存启用: $([ "$IPV6WGM_PRELOAD_CACHE_ENABLED" == "true" ] && echo "是" || echo "否")"
    echo "优先级启用: $([ "$IPV6WGM_PRELOAD_PRIORITY_ENABLED" == "true" ] && echo "是" || echo "否")"
    echo "后台加载启用: $([ "$IPV6WGM_PRELOAD_BACKGROUND_ENABLED" == "true" ] && echo "是" || echo "否")"
    echo "总模块数: ${#IPV6WGM_PRELOAD_STATUS[@]}"
    echo "已加载模块: $IPV6WGM_PRELOAD_SUCCESS_COUNT"
    echo "加载失败模块: $IPV6WGM_PRELOAD_FAILED_COUNT"
    echo "缓存目录: $IPV6WGM_PRELOAD_CACHE_DIR"
    echo "日志文件: $IPV6WGM_PRELOAD_LOG_FILE"
    
    echo
    echo "模块状态详情:"
    printf "%-20s %-10s %-10s\n" "模块名称" "状态" "加载时间"
    printf "%-20s %-10s %-10s\n" "--------" "----" "--------"
    
    for module_name in "${!IPV6WGM_PRELOAD_STATUS[@]}"; do
        local status="${IPV6WGM_PRELOAD_STATUS[$module_name]}"
        local load_time="${IPV6WGM_PRELOAD_TIMES[$module_name]:-0}"
        printf "%-20s %-10s %-10s\n" "$module_name" "$status" "${load_time}s"
    done
}

# 清理预加载缓存
clear_preload_cache() {
    log_info "清理预加载缓存..."
    
    if [[ -d "$IPV6WGM_PRELOAD_CACHE_DIR" ]]; then
        local cache_count=$(find "$IPV6WGM_PRELOAD_CACHE_DIR" -name "*.cache" | wc -l)
        
        if rm -f "$IPV6WGM_PRELOAD_CACHE_DIR"/*.cache 2>/dev/null; then
            log_success "已清理 $cache_count 个缓存文件"
        else
            log_error "清理缓存失败"
            return 1
        fi
    else
        log_warn "缓存目录不存在"
    fi
    
    return 0
}

# 设置模块优先级
set_module_priority() {
    local module_name="$1"
    local priority="$2"
    
    if [[ -z "$module_name" || -z "$priority" ]]; then
        log_error "请指定模块名称和优先级"
        return 1
    fi
    
    if ! [[ "$priority" =~ ^[0-9]+$ ]]; then
        log_error "优先级必须是数字"
        return 1
    fi
    
    IPV6WGM_MODULE_PRIORITIES["$module_name"]="$priority"
    
    # 重新构建队列
    build_preload_queue
    
    log_success "模块优先级已设置: $module_name = $priority"
    return 0
}

# 获取预加载统计
get_preload_statistics() {
    echo "=== 模块预加载统计 ==="
    echo "总预加载次数: $IPV6WGM_PRELOAD_COUNT"
    echo "成功次数: $IPV6WGM_PRELOAD_SUCCESS_COUNT"
    echo "失败次数: $IPV6WGM_PRELOAD_FAILED_COUNT"
    
    if [[ $IPV6WGM_PRELOAD_COUNT -gt 0 ]]; then
        local success_rate=$(( (IPV6WGM_PRELOAD_SUCCESS_COUNT * 100) / IPV6WGM_PRELOAD_COUNT ))
        echo "成功率: ${success_rate}%"
    fi
    
    # 计算平均加载时间
    local total_time=0
    local loaded_count=0
    
    for module_name in "${!IPV6WGM_PRELOAD_TIMES[@]}"; do
        local load_time="${IPV6WGM_PRELOAD_TIMES[$module_name]}"
        if [[ -n "$load_time" && "$load_time" != "0" ]]; then
            total_time=$(echo "$total_time + $load_time" | bc -l 2>/dev/null || echo "$total_time")
            ((loaded_count++))
        fi
    done
    
    if [[ $loaded_count -gt 0 ]]; then
        local avg_time=$(echo "scale=3; $total_time / $loaded_count" | bc -l 2>/dev/null || echo "0")
        echo "平均加载时间: ${avg_time}s"
    fi
    
    # 显示最慢的模块
    local slowest_module=""
    local slowest_time=0
    
    for module_name in "${!IPV6WGM_PRELOAD_TIMES[@]}"; do
        local load_time="${IPV6WGM_PRELOAD_TIMES[$module_name]}"
        if [[ -n "$load_time" && "$load_time" != "0" ]]; then
            if (( $(echo "$load_time > $slowest_time" | bc -l 2>/dev/null || echo "0") )); then
                slowest_time="$load_time"
                slowest_module="$module_name"
            fi
        fi
    done
    
    if [[ -n "$slowest_module" ]]; then
        echo "最慢模块: $slowest_module (${slowest_time}s)"
    fi
}

# 导出函数
export -f init_preloading
export -f preload_module
export -f preload_all_modules
export -f preload_specific_modules
export -f get_preload_status
export -f clear_preload_cache
export -f set_module_priority
export -f get_preload_statistics