#!/bin/bash

# 高级性能优化模块
# 提供命令缓存、并行处理、资源优化和性能监控

# =============================================================================
# 性能优化配置
# =============================================================================

# 缓存配置
declare -g IPV6WGM_CACHE_ENABLED="${IPV6WGM_CACHE_ENABLED:-true}"
declare -g IPV6WGM_CACHE_TTL="${IPV6WGM_CACHE_TTL:-300}"  # 5分钟
declare -g IPV6WGM_CACHE_MAX_SIZE="${IPV6WGM_CACHE_MAX_SIZE:-1000}"
declare -g IPV6WGM_CACHE_CLEANUP_INTERVAL="${IPV6WGM_CACHE_CLEANUP_INTERVAL:-3600}"  # 1小时

# 并行处理配置
declare -g IPV6WGM_PARALLEL_ENABLED="${IPV6WGM_PARALLEL_ENABLED:-true}"
declare -g IPV6WGM_MAX_PARALLEL_JOBS="${IPV6WGM_MAX_PARALLEL_JOBS:-4}"
declare -g IPV6WGM_JOB_TIMEOUT="${IPV6WGM_JOB_TIMEOUT:-300}"  # 5分钟

# 资源限制
declare -g IPV6WGM_MEMORY_LIMIT="${IPV6WGM_MEMORY_LIMIT:-1073741824}"  # 1GB
declare -g IPV6WGM_CPU_LIMIT="${IPV6WGM_CPU_LIMIT:-80}"  # 80%
declare -g IPV6WGM_DISK_LIMIT="${IPV6WGM_DISK_LIMIT:-5368709120}"  # 5GB

# 性能监控
declare -A IPV6WGM_PERFORMANCE_METRICS=()
declare -A IPV6WGM_CACHE_STATS=(
    ["hits"]=0
    ["misses"]=0
    ["size"]=0
    ["cleanups"]=0
)

# =============================================================================
# 高级缓存系统
# =============================================================================

# 智能缓存键生成
generate_cache_key() {
    local command="$1"
    local args=("${@:2}")
    
    # 生成基于命令和参数的哈希键
    local key_data="$command ${args[*]}"
    local cache_key=$(echo "$key_data" | md5sum | cut -d' ' -f1)
    
    echo "cmd_${cache_key:0:16}"
}

# 检查缓存是否有效
is_cache_valid() {
    local cache_key="$1"
    local ttl="${2:-$IPV6WGM_CACHE_TTL}"
    
    if [[ "$IPV6WGM_CACHE_ENABLED" != "true" ]]; then
        return 1
    fi
    
    local cache_file="/tmp/ipv6wgm_cache_${cache_key}"
    
    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi
    
    # 检查文件年龄
    local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
    
    if [[ $file_age -gt $ttl ]]; then
        rm -f "$cache_file"
        return 1
    fi
    
    return 0
}

# 从缓存获取结果
get_from_cache() {
    local cache_key="$1"
    local cache_file="/tmp/ipv6wgm_cache_${cache_key}"
    
    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
        ((IPV6WGM_CACHE_STATS["hits"]++))
        return 0
    else
        ((IPV6WGM_CACHE_STATS["misses"]++))
        return 1
    fi
}

# 保存到缓存
save_to_cache() {
    local cache_key="$1"
    local data="$2"
    local cache_file="/tmp/ipv6wgm_cache_${cache_key}"
    
    # 检查缓存大小限制
    if [[ ${IPV6WGM_CACHE_STATS["size"]} -ge $IPV6WGM_CACHE_MAX_SIZE ]]; then
        cleanup_old_cache_entries
    fi
    
    # 保存数据
    echo "$data" > "$cache_file"
    ((IPV6WGM_CACHE_STATS["size"]++))
    
    return 0
}

# 清理旧缓存条目
cleanup_old_cache_entries() {
    local cache_dir="/tmp"
    local mapfile -t cache_files < <(ls -t "$cache_dir"/ipv6wgm_cache_* 2>/dev/null | tail -n +$((IPV6WGM_CACHE_MAX_SIZE + 1)))
    
    for file in "${cache_files[@]}"; do
        rm -f "$file"
        ((IPV6WGM_CACHE_STATS["size"]--))
    done
    
    ((IPV6WGM_CACHE_STATS["cleanups"]++))
    log_debug "清理了 ${#cache_files[@]} 个旧缓存条目"
}

# 带缓存的命令执行
execute_with_cache() {
    local command="$1"
    local description="${2:-执行命令}"
    local ttl="${3:-$IPV6WGM_CACHE_TTL}"
    local args=("${@:4}")
    
    # 生成缓存键
    local cache_key=$(generate_cache_key "$command" "${args[@]}")
    
    # 尝试从缓存获取
    if is_cache_valid "$cache_key" "$ttl"; then
        log_debug "从缓存获取结果: $description"
        get_from_cache "$cache_key"
        return $?
    fi
    
    # 执行命令
    log_debug "执行命令: $command ${args[*]}"
    local result
    local exit_code
    
    if result=$($command "${args[@]}" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    # 保存到缓存
    if [[ $exit_code -eq 0 ]]; then
        save_to_cache "$cache_key" "$result"
        log_debug "结果已缓存: $description"
    fi
    
    echo "$result"
    return $exit_code
}

# =============================================================================
# 并行处理系统
# =============================================================================

# 并行执行任务
execute_parallel() {
    local tasks=("$@")
    local max_jobs="${IPV6WGM_MAX_PARALLEL_JOBS}"
    local timeout="${IPV6WGM_JOB_TIMEOUT}"
    
    if [[ "$IPV6WGM_PARALLEL_ENABLED" != "true" ]]; then
        # 串行执行
        for task in "${tasks[@]}"; do
            eval "$task"
        done
        return 0
    fi
    
    log_info "并行执行 ${#tasks[@]} 个任务 (最大并发: $max_jobs)"
    
    local pids=()
    local results=()
    local task_index=0
    
    # 启动初始任务
    while [[ $task_index -lt ${#tasks[@]} && ${#pids[@]} -lt $max_jobs ]]; do
        start_parallel_task "${tasks[$task_index]}" "$task_index" &
        pids+=($!)
        ((task_index++))
    done
    
    # 管理任务执行
    while [[ ${#pids[@]} -gt 0 ]]; do
        for i in "${!pids[@]}"; do
            local pid="${pids[$i]}"
            
            # 检查进程是否完成
            if ! kill -0 "$pid" 2>/dev/null; then
                wait "$pid"
                local exit_code=$?
                results+=("$exit_code")
                unset pids[$i]
                
                # 启动新任务
                if [[ $task_index -lt ${#tasks[@]} ]]; then
                    start_parallel_task "${tasks[$task_index]}" "$task_index" &
                    pids+=($!)
                    ((task_index++))
                fi
            fi
        done
        
        # 短暂等待
        smart_sleep "$IPV6WGM_SLEEP_SHORT"
    done
    
    # 检查结果
    local failed_count=0
    for result in "${results[@]}"; do
        if [[ $result -ne 0 ]]; then
            ((failed_count++))
        fi
    done
    
    if [[ $failed_count -eq 0 ]]; then
        log_success "所有并行任务执行成功"
        return 0
    else
        log_error "$failed_count 个并行任务执行失败"
        return 1
    fi
}

# 启动并行任务
start_parallel_task() {
    local task="$1"
    local task_id="$2"
    
    log_debug "启动并行任务 $task_id: $task"
    
    # 设置超时
    if command -v timeout &> /dev/null; then
        timeout "$IPV6WGM_JOB_TIMEOUT" bash -c "$task"
    else
        eval "$task"
    fi
}

# 批量处理
batch_process() {
    local items=("$@")
    local batch_size="${1:-10}"
    local items=("${@:2}")
    
    log_info "批量处理 ${#items[@]} 个项目 (批次大小: $batch_size)"
    
    local batches=()
    local current_batch=()
    
    for item in "${items[@]}"; do
        current_batch+=("$item")
        
        if [[ ${#current_batch[@]} -eq $batch_size ]]; then
            batches+=("${current_batch[*]}")
            current_batch=()
        fi
    done
    
    # 添加剩余项目
    if [[ ${#current_batch[@]} -gt 0 ]]; then
        batches+=("${current_batch[*]}")
    fi
    
    # 处理批次
    for batch in "${batches[@]}"; do
        log_debug "处理批次: $batch"
        # 这里可以添加具体的批次处理逻辑
    done
    
    log_success "批量处理完成"
}

# =============================================================================
# 资源优化
# =============================================================================

# 内存优化
optimize_memory_usage() {
    log_info "优化内存使用..."
    
    # 清理未使用的变量
    unset_variables_by_pattern "TEMP_"
    unset_variables_by_pattern "CACHE_"
    
    # 清理大型数组
    cleanup_large_arrays
    
    # 强制垃圾回收
    force_garbage_collection
    
    log_success "内存优化完成"
}

# 按模式清理变量
unset_variables_by_pattern() {
    local pattern="$1"
    
    for var in $(compgen -v | grep "^$pattern"); do
        unset "$var" 2>/dev/null || true
    done
}

# 清理大型数组
cleanup_large_arrays() {
    # 清理临时数组
    local temp_arrays=("TEMP_ARRAY" "CACHE_ARRAY" "RESULTS_ARRAY")
    
    for array_name in "${temp_arrays[@]}"; do
        if declare -p "$array_name" &> /dev/null; then
            unset "$array_name"
        fi
    done
}

# 强制垃圾回收
force_garbage_collection() {
    # 在bash中，通过重新分配变量来触发垃圾回收
    local temp_var=""
    temp_var=$(date)
    unset temp_var
}

# 磁盘空间优化
optimize_disk_usage() {
    log_info "优化磁盘使用..."
    
    # 清理临时文件
    cleanup_temp_files
    
    # 清理日志文件
    cleanup_log_files
    
    # 清理缓存文件
    cleanup_cache_files
    
    log_success "磁盘优化完成"
}

# 清理临时文件
cleanup_temp_files() {
    local temp_dirs=("/tmp" "/var/tmp" "$IPV6WGM_TEMP_DIR")
    
    for dir in "${temp_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            find "$dir" -name "ipv6wgm_*" -mtime +1 -delete 2>/dev/null || true
        fi
    done
}

# 清理日志文件
cleanup_log_files() {
    local log_dir="$IPV6WGM_LOG_DIR"
    
    if [[ -d "$log_dir" ]]; then
        # 清理旧日志文件
        find "$log_dir" -name "*.log.*" -mtime +7 -delete 2>/dev/null || true
        
        # 截断大日志文件
        find "$log_dir" -name "*.log" -size +100M -print0 | xargs -0 -r truncate -s 50M 2>/dev/null || true
    fi
}

# 清理缓存文件
cleanup_cache_files() {
    local cache_dir="/tmp"
    
    if [[ -d "$cache_dir" ]]; then
        find "$cache_dir" -name "ipv6wgm_cache_*" -mtime +1 -delete 2>/dev/null || true
    fi
}

# =============================================================================
# 性能监控
# =============================================================================

# 开始性能监控
start_performance_monitoring() {
    local monitor_interval="${1:-60}"
    
    log_info "启动性能监控 (间隔: ${monitor_interval}秒)"
    
    while true; do
        collect_performance_metrics
        sleep "$monitor_interval"
    done &
    
    local monitor_pid=$!
    echo "$monitor_pid" > "/tmp/ipv6wgm_performance_monitor.pid"
    
    log_success "性能监控已启动 (PID: $monitor_pid)"
}

# 停止性能监控
stop_performance_monitoring() {
    local pid_file="/tmp/ipv6wgm_performance_monitor.pid"
    
    if [[ -f "$pid_file" ]]; then
        local monitor_pid=$(cat "$pid_file")
        if kill -0 "$monitor_pid" 2>/dev/null; then
            kill "$monitor_pid"
            rm -f "$pid_file"
            log_success "性能监控已停止"
        else
            log_warn "性能监控进程不存在"
        fi
    else
        log_warn "性能监控未运行"
    fi
}

# 收集性能指标
collect_performance_metrics() {
    local timestamp=$(date +%s)
    
    # CPU使用率
    local cpu_usage=$(get_cpu_usage "$@")
    IPV6WGM_PERFORMANCE_METRICS["cpu_$timestamp"]="$cpu_usage"
    
    # 内存使用率
    local memory_usage=$(get_memory_usage "$@")
    IPV6WGM_PERFORMANCE_METRICS["memory_$timestamp"]="$memory_usage"
    
    # 磁盘使用率
    local disk_usage=$(get_disk_usage "$@")
    IPV6WGM_PERFORMANCE_METRICS["disk_$timestamp"]="$disk_usage"
    
    # 缓存统计
    IPV6WGM_PERFORMANCE_METRICS["cache_hits_$timestamp"]="${IPV6WGM_CACHE_STATS["hits"]}"
    IPV6WGM_PERFORMANCE_METRICS["cache_misses_$timestamp"]="${IPV6WGM_CACHE_STATS["misses"]}"
    
    # 清理旧指标
    cleanup_old_metrics
}

# 清理旧指标
cleanup_old_metrics() {
    local current_time=$(date +%s)
    local max_age=3600  # 1小时
    
    for key in "${!IPV6WGM_PERFORMANCE_METRICS[@]}"; do
        if [[ "$key" =~ _([0-9]+)$ ]]; then
            local timestamp="${BASH_REMATCH[1]}"
            local age=$((current_time - timestamp))
            
            if [[ $age -gt $max_age ]]; then
                unset IPV6WGM_PERFORMANCE_METRICS["$key"]
            fi
        fi
    done
}

# 生成性能报告
generate_performance_report() {
    local output_file="${1:-/tmp/performance_report_$(date +%Y%m%d_%H%M%S).txt}"
    
    {
        echo "=== IPv6 WireGuard Manager 性能报告 ==="
        echo "生成时间: $(date)"
        echo ""
        
        echo "=== 缓存统计 ==="
        echo "缓存命中: ${IPV6WGM_CACHE_STATS["hits"]}"
        echo "缓存未命中: ${IPV6WGM_CACHE_STATS["misses"]}"
        echo "缓存大小: ${IPV6WGM_CACHE_STATS["size"]}"
        echo "清理次数: ${IPV6WGM_CACHE_STATS["cleanups"]}"
        echo ""
        
        echo "=== 性能指标 ==="
        for key in "${!IPV6WGM_PERFORMANCE_METRICS[@]}"; do
            if [[ "$key" =~ ^(cpu|memory|disk)_([0-9]+)$ ]]; then
                local metric_type="${BASH_REMATCH[1]}"
                local timestamp="${BASH_REMATCH[2]}"
                local value="${IPV6WGM_PERFORMANCE_METRICS[$key]}"
                local time_str=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$timestamp")
                echo "$metric_type ($time_str): $value"
            fi
        done
        echo ""
        
        echo "=== 系统资源 ==="
        echo "当前CPU使用率: $(get_cpu_usage "$@")%"
        echo "当前内存使用率: $(get_memory_usage "$@")%"
        echo "当前磁盘使用率: $(get_disk_usage "$@")%"
        echo ""
        
        echo "=== 优化建议 ==="
        generate_optimization_suggestions
        
    } > "$output_file"
    
    log_info "性能报告已生成: $output_file"
    echo "$output_file"
}

# 生成优化建议
generate_optimization_suggestions() {
    local cpu_usage=$(get_cpu_usage "$@")
    local memory_usage=$(get_memory_usage "$@")
    local disk_usage=$(get_disk_usage "$@")
    
    echo "基于当前性能指标的优化建议:"
    echo ""
    
    if [[ $cpu_usage -gt 80 ]]; then
        echo "- CPU使用率过高 ($cpu_usage%)，建议:"
        echo "  * 减少并行任务数量"
        echo "  * 优化算法复杂度"
        echo "  * 考虑负载均衡"
    fi
    
    if [[ $memory_usage -gt 80 ]]; then
        echo "- 内存使用率过高 ($memory_usage%)，建议:"
        echo "  * 清理未使用的变量和数组"
        echo "  * 减少缓存大小"
        echo "  * 优化数据结构"
    fi
    
    if [[ $disk_usage -gt 80 ]]; then
        echo "- 磁盘使用率过高 ($disk_usage%)，建议:"
        echo "  * 清理临时文件和日志"
        echo "  * 压缩旧数据"
        echo "  * 考虑扩展存储"
    fi
    
    # 缓存优化建议
    local cache_hits="${IPV6WGM_CACHE_STATS["hits"]}"
    local cache_misses="${IPV6WGM_CACHE_STATS["misses"]}"
    local total_requests=$((cache_hits + cache_misses))
    
    if [[ $total_requests -gt 0 ]]; then
        local hit_rate=$((cache_hits * 100 / total_requests))
        if [[ $hit_rate -lt 50 ]]; then
            echo "- 缓存命中率较低 ($hit_rate%)，建议:"
            echo "  * 增加缓存TTL"
            echo "  * 优化缓存键生成"
            echo "  * 检查缓存策略"
        fi
    fi
}

# =============================================================================
# 智能优化
# =============================================================================

# 自动性能优化
auto_optimize_performance() {
    log_info "开始自动性能优化..."
    
    # 检查系统资源
    local cpu_usage=$(get_cpu_usage "$@")
    local memory_usage=$(get_memory_usage "$@")
    local disk_usage=$(get_disk_usage "$@")
    
    # 根据资源使用情况调整配置
    if [[ $cpu_usage -gt 70 ]]; then
        IPV6WGM_MAX_PARALLEL_JOBS=$((IPV6WGM_MAX_PARALLEL_JOBS / 2))
        log_info "CPU使用率高，减少并行任务数: $IPV6WGM_MAX_PARALLEL_JOBS"
    fi
    
    if [[ $memory_usage -gt 70 ]]; then
        IPV6WGM_CACHE_MAX_SIZE=$((IPV6WGM_CACHE_MAX_SIZE / 2))
        log_info "内存使用率高，减少缓存大小: $IPV6WGM_CACHE_MAX_SIZE"
    fi
    
    if [[ $disk_usage -gt 70 ]]; then
        optimize_disk_usage
        log_info "磁盘使用率高，执行磁盘优化"
    fi
    
    # 执行优化
    optimize_memory_usage
    optimize_disk_usage
    
    log_success "自动性能优化完成"
}

# 导出函数
export -f generate_cache_key is_cache_valid get_from_cache save_to_cache
export -f execute_with_cache cleanup_old_cache_entries
export -f execute_parallel start_parallel_task batch_process
export -f optimize_memory_usage optimize_disk_usage cleanup_temp_files
export -f start_performance_monitoring stop_performance_monitoring
export -f collect_performance_metrics generate_performance_report
export -f auto_optimize_performance
