#!/bin/bash

# 增强缓存系统模块
# 提供智能缓存、缓存预热、缓存统计和内存优化功能

# 缓存配置
declare -A CACHE_CONFIG=(
    ["enabled"]="true"
    ["default_ttl"]="300"
    ["max_size"]="1000"
    ["cleanup_interval"]="3600"
    ["memory_limit"]="100MiB"
)

# 缓存存储
declare -A CACHE_STORE=()
declare -A CACHE_TIMESTAMPS=()
declare -A CACHE_ACCESS_COUNT=()
declare -A CACHE_LRU_STAMP=()

# 缓存统计
declare -A CACHE_STATS=(
    ["hits"]=0
    ["misses"]=0
    ["evictions"]=0
    ["hit_rate"]=0
    ["total_size"]=0
)

# 智能缓存键生成
generate_cache_key() {
    local key_data="$1"
    local prefix="${2:-cmd}"
    
    # 生成数据哈希键
    local hash_key=$(echo "$key_data" | md5sum | cut -d' ' -f1)
    echo "${prefix}_${hash_key:0:16}"
}

# 检查缓存有效性
is_cache_valid() {
    local cache_key="$1"
    local ttl="${2:-${CACHE_CONFIG[default_ttl]}}"
    local current_time=$(date +%s)
    local cache_time="${CACHE_TIMESTAMPS[$cache_key]:-0}"
    
    if [[ ${CACHE_CONFIG[enabled]} != "true" ]]; then
        return 1
    fi
    
    if [[ -n "${CACHE_STORE[$cache_key]:-}" ]]; then
        if (( current_time - cache_time < ttl )); then
            return 0
        else
            # 缓存过期，清理
            unset CACHE_STORE[$cache_key]
            unset CACHE_TIMESTAMPS[$cache_key]
            unset CACHE_ACCESS_COUNT[$cache_key]
        fi
    fi
    
    return 1
}

# 智能缓存写入
smart_cache_set() {
    local cache_key="$1"
    local value="$2"
    local ttl="${3:-${CACHE_CONFIG[default_ttl]}}"
    local current_time=$(date +%s)
    
    # 检查缓存大小限制
    if [[ ${CACHE_STATS[total_size]} -ge ${CACHE_CONFIG[max_size]} ]]; then
        evict_old_cache_entries
    fi
    
    # 存储缓存数据
    CACHE_STORE[$cache_key]="$value"
    CACHE_TIMESTAMPS[$cache_key]=$current_time
    CACHE_ACCESS_COUNT[$cache_key]=0
    CACHE_LRU_STAMP[$cache_key]=$current_time
    
    ((CACHE_STATS[total_size]++))
    log_debug "缓存已存储: $cache_key (TTL: ${ttl}s)"
}

# 智能缓存读取
smart_cache_get() {
    local cache_key="$1"
    local ttl="${2:-${CACHE_CONFIG[default_ttl]}}"
    local current_time=$(date +%s)
    
    if is_cache_valid "$cache_key" "$ttl"; then
        # 更新访问统计
        ((CACHE_ACCESS_COUNT[$cache_key]++))
        CACHE_LRU_STAMP[$cache_key]=$current_time
        ((CACHE_STATS[hits]++))
        
        log_debug "缓存命中: $cache_key"
        echo "${CACHE_STORE[$cache_key]}"
        return 0
    else
        ((CACHE_STATS[misses]++))
        log_debug "缓存未命中: $cache_key"
        return 1
    fi
}

# LRU缓存清理
evict_old_cache_entries() {
    local max_entries_to_evict=$((CACHE_CONFIG[max_size] / 10))  # 清理10%
    local sorted_keys=$(printf '%s\n' "${!CACHE_LRU_STAMP[@]}" | sort -k1,1)
    
    local evict_count=0
    while IFS= read -r cache_key; do
        if [[ $evict_count -ge $max_entries_to_evict ]]; then
            break
        fi
        
        unset CACHE_STORE[$cache_key]
        unset CACHE_TIMESTAMPS[$cache_key]
        unset CACHE_ACCESS_COUNT[$cache_key]
        unset CACHE_LRU_STAMP[$cache_key]
        
        ((evict_count++))
        ((CACHE_STATS[evictions]++))
        ((CACHE_STATS[total_size]--))
        
    done <<< "$sorted_keys"
    
    log_debug "清理了 $evict_count 个缓存条目 (LRU策略)"
}

# 带缓存的命令执行
execute_with_cache() {
    local command="$1"
    local cache_key="$2"
    local ttl="${3:-${CACHE_CONFIG[default_ttl]}}"
    local force_refresh="${4:-false}"
    
    # 如果没有提供缓存键，生成一个
    if [[ -z "$cache_key" ]]; then
        cache_key=$(generate_cache_key "$command")
    fi
    
    # 检查是否强制刷新
    if [[ "$force_refresh" == "true" ]]; then
        unset CACHE_STORE[$cache_key]
        unset CACHE_TIMESTAMPS[$cache_key]
        unset CACHE_ACCESS_COUNT[$cache_key]
    fi
    
    # 尝试从缓存读取
    local cached_result
    if cached_result=$(smart_cache_get "$cache_key" "$ttl"); then
        echo "$cached_result"
        return 0
    fi
    
    # 执行命令
    log_debug "执行命令并缓存: $command"
    local result
    local start_time=$(date +%s%3N)
    
    if result=$(safe_execute_command "$command" 2>/dev/null); then
        local end_time=$(date +%s%3N)
        local execution_time=$((end_time - start_time))
        
        # 存储到缓存
        smart_cache_set "$cache_key" "$result" "$ttl"
        
        log_debug "命令执行成功并已缓存: $cache_key (执行时间: ${execution_time}ms)"
        echo "$result"
        return 0
    else
        log_warn "命令执行失败: $command"
        return 1
    fi
}

# 缓存预热
warmup_cache() {
    log_info "开始缓存预热..."
    
    local warmup_commands=(
        "wg show"
        "ip addr show"
        "systemctl status wg-quick@wg0 || true"
        "birdc show protocols || true"
        "netstat -tulpn | grep -E ':(51820|179)' || true"
    )
    
    for cmd in "${warmup_commands[@]}"; do
        if safe_execute_command "$cmd" >/dev/null 2>&1; then
            cache_key=$(generate_cache_key "$cmd" "warmup")
            execute_with_cache "$cmd" "$cache_key" 600
            log_debug "预热缓存: $cmd"
        fi
    done
    
    log_success "缓存预热完成"
}

# 缓存统计
get_cache_stats() {
    local total_operations=$((CACHE_STATS[hits] + CACHE_STATS[misses]))
    local hit_rate=0
    
    if [[ $total_operations -gt 0 ]]; then
        hit_rate=$((CACHE_STATS[hits] * 100 / total_operations))
    fi
    
    CACHE_STATS[hit_rate]=$hit_rate
    
    echo "=== 缓存统计 ==="
    echo "缓存命中: ${CACHE_STATS[hits]}"
    echo "缓存未命中: ${CACHE_STATS[misses]}"
    echo "缓存淘汰: ${CACHE_STATS[evictions]}"
    echo "缓存大小: ${CACHE_STATS[total_size]}"
    echo "命中率: ${hit_rate}%"
    echo "缓存键数量: ${#CACHE_STORE[@]}"
}

# 清理所有缓存
clear_all_cache() {
    log_info "清理所有缓存..."
    
    CACHE_STORE=()
    CACHE_TIMESTAMPS=()
    CACHE_ACCESS_COUNT=()
    CACHE_LRU_STAMP=()
    
    CACHE_STATS[hits]=0
    CACHE_STATS[misses]=0
    CACHE_STATS[evictions]=0
    CACHE_STATS[total_size]=0
    
    log_success "所有缓存已清理"
}

# 内存使用监控
monitor_cache_memory() {
    local cache_count=${#CACHE_STORE[@]}
    local estimated_size=$((cache_count * 512))  # 估算每个缓存条目512字节
    
    if [[ $estimated_size -gt 50000 ]]; then  # 超过50KB
        log_warn "缓存内存使用过高，执行清理"
        evict_old_cache_entries
    fi
}

# 定期缓存维护
cache_maintenance() {
    log_info "执行缓存维护..."
    
    # 清理过期缓存
    for cache_key in "${!CACHE_TIMESTAMPS[@]}"; do
        if ! is_cache_valid "$cache_key"; then
            unset CACHE_STORE[$cache_key]
            unset CACHE_TIMESTAMPS[$cache_key]
            unset CACHE_ACCESS_COUNT[$cache_key]
            unset CACHE_LRU_STAMP[$cache_key]
            ((CACHE_STATS[total_size]--
        fi
    done
    
    # 监控内存使用
    monitor_cache_memory
    
    # 生成统计报告
    get_cache_stats
    
    log_success "缓存维护完成"
}

# 导出函数
export -f generate_cache_key is_cache_valid smart_cache_set smart_cache_get
export -f execute_with_cache warmup_cache get_cache_stats clear_all_cache
export -f cache_maintenance monitor_cache_memory

# 别名
# 仅在未提供统一API实现时设置别名，避免覆盖
command -v cache_set >/dev/null 2>&1 || alias cache_set=smart_cache_set
command -v cache_get >/dev/null 2>&1 || alias cache_get=smart_cache_get
command -v cache_exec >/dev/null 2>&1 || alias cache_exec=execute_with_cache
command -v cache_stats >/dev/null 2>&1 || alias cache_stats=get_cache_stats
command -v cache_clear >/dev/null 2>&1 || alias cache_clear=clear_all_cache
