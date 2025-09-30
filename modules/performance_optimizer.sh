#!/bin/bash

# 性能优化模块
# 提供模块懒加载、配置缓存、解析速度优化等功能

# 导入公共函数
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
fi

# =============================================================================
# 性能优化配置
# =============================================================================

# 缓存配置
declare -A IPV6WGM_CACHE=()
declare -A IPV6WGM_CACHE_TIMESTAMP=()
IPV6WGM_CACHE_TTL=300  # 缓存生存时间（秒）

# 懒加载配置
declare -A IPV6WGM_LAZY_LOADED=()
declare -A IPV6WGM_LAZY_LOAD_TIME=()

# 性能监控
declare -A IPV6WGM_PERFORMANCE_METRICS=()
IPV6WGM_START_TIME=$(date +%s.%N)

# =============================================================================
# 缓存管理函数
# =============================================================================

# 设置缓存
set_cache() {
    local key="$1"
    local value="$2"
    local ttl="${3:-$IPV6WGM_CACHE_TTL}"
    
    IPV6WGM_CACHE["$key"]="$value"
    IPV6WGM_CACHE_TIMESTAMP["$key"]=$(date +%s)
    
    log_debug "缓存设置: $key (TTL: ${ttl}s)"
}

# 获取缓存
get_cache() {
    local key="$1"
    local current_time=$(date +%s)
    local cache_time="${IPV6WGM_CACHE_TIMESTAMP[$key]:-0}"
    local ttl="${2:-$IPV6WGM_CACHE_TTL}"
    
    if [[ -n "${IPV6WGM_CACHE[$key]:-}" ]]; then
        if [[ $((current_time - cache_time)) -lt $ttl ]]; then
            log_debug "缓存命中: $key"
            echo "${IPV6WGM_CACHE[$key]}"
            return 0
        else
            log_debug "缓存过期: $key"
            unset IPV6WGM_CACHE["$key"]
            unset IPV6WGM_CACHE_TIMESTAMP["$key"]
        fi
    fi
    
    return 1
}

# 清除缓存
clear_cache() {
    local key="$1"
    
    if [[ -n "$key" ]]; then
        unset IPV6WGM_CACHE["$key"]
        unset IPV6WGM_CACHE_TIMESTAMP["$key"]
        log_debug "缓存清除: $key"
    else
        IPV6WGM_CACHE=()
        IPV6WGM_CACHE_TIMESTAMP=()
        log_debug "所有缓存已清除"
    fi
}

# 清除过期缓存
clear_expired_cache() {
    local current_time=$(date +%s)
    local expired_keys=()
    
    for key in "${!IPV6WGM_CACHE_TIMESTAMP[@]}"; do
        local cache_time="${IPV6WGM_CACHE_TIMESTAMP[$key]}"
        if [[ $((current_time - cache_time)) -ge $IPV6WGM_CACHE_TTL ]]; then
            expired_keys+=("$key")
        fi
    done
    
    for key in "${expired_keys[@]}"; do
        unset IPV6WGM_CACHE["$key"]
        unset IPV6WGM_CACHE_TIMESTAMP["$key"]
        log_debug "过期缓存清除: $key"
    done
}

# =============================================================================
# 懒加载管理函数
# =============================================================================

# 懒加载模块
lazy_load_module() {
    local module_name="$1"
    local module_file="${2:-modules/${module_name}.sh}"
    
    # 检查是否已加载
    if [[ "${IPV6WGM_LAZY_LOADED[$module_name]:-}" == "true" ]]; then
        log_debug "模块已加载: $module_name"
        return 0
    fi
    
    # 检查模块文件是否存在
    if [[ ! -f "$module_file" ]]; then
        log_error "模块文件不存在: $module_file"
        return 1
    fi
    
    # 加载模块
    local start_time=$(date +%s.%N)
    if source "$module_file"; then
        local end_time=$(date +%s.%N)
        local load_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        
        IPV6WGM_LAZY_LOADED["$module_name"]="true"
        IPV6WGM_LAZY_LOAD_TIME["$module_name"]="$load_time"
        
        log_debug "模块懒加载成功: $module_name (${load_time}s)"
        return 0
    else
        log_error "模块懒加载失败: $module_name"
        return 1
    fi
}

# 预加载模块
preload_modules() {
    local modules=("$@")
    
    for module in "${modules[@]}"; do
        lazy_load_module "$module"
    done
}

# 检查模块是否已加载
is_module_loaded() {
    local module_name="$1"
    [[ "${IPV6WGM_LAZY_LOADED[$module_name]:-}" == "true" ]]
}

# 获取模块加载时间
get_module_load_time() {
    local module_name="$1"
    echo "${IPV6WGM_LAZY_LOAD_TIME[$module_name]:-0}"
}

# =============================================================================
# 配置缓存函数
# =============================================================================

# 缓存配置文件内容
cache_config_file() {
    local config_file="$1"
    local cache_key="config_${config_file//\//_}"
    
    # 检查缓存
    if get_cache "$cache_key"; then
        return 0
    fi
    
    # 读取配置文件
    if [[ -f "$config_file" ]]; then
        local config_content=$(cat "$config_file")
        set_cache "$cache_key" "$config_content"
        echo "$config_content"
    else
        log_warn "配置文件不存在: $config_file"
        return 1
    fi
}

# 缓存解析后的配置
cache_parsed_config() {
    local config_file="$1"
    local cache_key="parsed_${config_file//\//_}"
    
    # 检查缓存
    if get_cache "$cache_key"; then
        return 0
    fi
    
    # 解析配置
    local parsed_config=$(parse_config_file "$config_file")
    if [[ $? -eq 0 ]]; then
        set_cache "$cache_key" "$parsed_config"
        echo "$parsed_config"
    else
        return 1
    fi
}

# 解析配置文件（优化版本）
parse_config_file() {
    local config_file="$1"
    local cache_key="parsed_${config_file//\//_}"
    
    # 检查缓存
    if get_cache "$cache_key"; then
        return 0
    fi
    
    # 解析配置
    local config_vars=()
    local config_values=()
    
    if [[ -f "$config_file" ]]; then
        while IFS='=' read -r key value; do
            # 跳过注释和空行
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            
            # 去除前后空格
            key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # 去除引号
            value=$(echo "$value" | sed 's/^"//;s/"$//')
            
            config_vars+=("$key")
            config_values+=("$value")
        done < "$config_file"
    fi
    
    # 缓存结果
    local result=$(printf '%s\n' "${config_vars[@]}" | paste -sd '|')
    set_cache "$cache_key" "$result"
    
    echo "$result"
}

# =============================================================================
# 性能监控函数
# =============================================================================

# 开始性能计时
start_timer() {
    local timer_name="$1"
    IPV6WGM_PERFORMANCE_METRICS["${timer_name}_start"]=$(date +%s.%N)
}

# 结束性能计时
end_timer() {
    local timer_name="$1"
    local start_time="${IPV6WGM_PERFORMANCE_METRICS["${timer_name}_start"]}"
    
    if [[ -n "$start_time" ]]; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        IPV6WGM_PERFORMANCE_METRICS["${timer_name}_duration"]="$duration"
        log_debug "性能计时: $timer_name = ${duration}s"
        echo "$duration"
    else
        log_warn "计时器未开始: $timer_name"
        echo "0"
    fi
}

# 获取性能统计
get_performance_stats() {
    echo "=== 性能统计 ==="
    echo "启动时间: $IPV6WGM_START_TIME"
    echo "当前时间: $(date +%s.%N)"
    
    echo
    echo "=== 模块加载时间 ==="
    for module in "${!IPV6WGM_LAZY_LOAD_TIME[@]}"; do
        echo "$module: ${IPV6WGM_LAZY_LOAD_TIME[$module]}s"
    done
    
    echo
    echo "=== 性能计时 ==="
    for metric in "${!IPV6WGM_PERFORMANCE_METRICS[@]}"; do
        if [[ "$metric" =~ _duration$ ]]; then
            local timer_name="${metric%_duration}"
            echo "$timer_name: ${IPV6WGM_PERFORMANCE_METRICS[$metric]}s"
        fi
    done
    
    echo
    echo "=== 缓存统计 ==="
    echo "缓存项数: ${#IPV6WGM_CACHE[@]}"
    echo "已加载模块数: ${#IPV6WGM_LAZY_LOADED[@]}"
}

# =============================================================================
# 优化函数
# =============================================================================

# 优化文件读取
optimized_file_read() {
    local file_path="$1"
    local cache_key="file_${file_path//\//_}"
    
    # 检查缓存
    if get_cache "$cache_key"; then
        return 0
    fi
    
    # 读取文件
    if [[ -f "$file_path" ]]; then
        local content=$(cat "$file_path")
        set_cache "$cache_key" "$content"
        echo "$content"
    else
        log_warn "文件不存在: $file_path"
        return 1
    fi
}

# 优化命令执行
optimized_command_execution() {
    local command="$1"
    local cache_key="cmd_${command//[^a-zA-Z0-9]/_}"
    local ttl="${2:-60}"  # 命令结果缓存1分钟
    
    # 检查缓存
    if get_cache "$cache_key" "$ttl"; then
        return 0
    fi
    
    # 执行命令
    local result=$(eval "$command" 2>/dev/null)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        set_cache "$cache_key" "$result" "$ttl"
        echo "$result"
    else
        log_warn "命令执行失败: $command"
        return 1
    fi
}

# 批量处理优化
batch_process() {
    local items=("$@")
    local batch_size=10
    local results=()
    
    for ((i=0; i<${#items[@]}; i+=batch_size)); do
        local batch=("${items[@]:i:batch_size}")
        local batch_results=()
        
        for item in "${batch[@]}"; do
            # 处理单个项目
            batch_results+=("$(process_item "$item")")
        done
        
        results+=("${batch_results[@]}")
    done
    
    printf '%s\n' "${results[@]}"
}

# 处理单个项目（示例函数）
process_item() {
    local item="$1"
    # 这里可以添加具体的处理逻辑
    echo "processed: $item"
}

# =============================================================================
# 内存优化函数
# =============================================================================

# 清理内存
cleanup_memory() {
    # 清除过期缓存
    clear_expired_cache
    
    # 清理未使用的变量
    unset IPV6WGM_PERFORMANCE_METRICS
    
    # 强制垃圾回收（如果支持）
    if command -v sync >/dev/null 2>&1; then
        sync
    fi
    
    log_debug "内存清理完成"
}

# 获取内存使用情况
get_memory_usage() {
    if command -v free >/dev/null 2>&1; then
        free -h
    elif command -v vm_stat >/dev/null 2>&1; then
        vm_stat
    else
        log_warn "无法获取内存使用情况"
    fi
}

# =============================================================================
# 初始化函数
# =============================================================================

# 初始化性能优化模块
init_performance_optimizer() {
    log_info "初始化性能优化模块..."
    
    # 设置缓存清理定时任务
    if command -v trap >/dev/null 2>&1; then
        trap cleanup_memory EXIT
    fi
    
    # 预加载常用模块
    local common_modules=("common_functions" "error_handling")
    preload_modules "${common_modules[@]}"
    
    log_success "性能优化模块初始化完成"
}

# 导出函数
export -f set_cache get_cache clear_cache clear_expired_cache
export -f lazy_load_module preload_modules is_module_loaded get_module_load_time
export -f cache_config_file cache_parsed_config parse_config_file
export -f start_timer end_timer get_performance_stats
export -f optimized_file_read optimized_command_execution batch_process
export -f cleanup_memory get_memory_usage init_performance_optimizer

# 如果直接执行此脚本，则初始化
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_performance_optimizer
fi
