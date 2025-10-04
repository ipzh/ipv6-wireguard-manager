#!/bin/bash

# 智能缓存策略模块
# 提供智能缓存管理、性能优化和缓存策略配置功能

# 统一缓存API入口（若存在则加载）
if [ -f "$(dirname "${BASH_SOURCE[0]}")/cache_api.sh" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/cache_api.sh"
elif [ -f "./modules/cache_api.sh" ]; then
    source "./modules/cache_api.sh"
fi

# =============================================================================
# 智能缓存配置
# =============================================================================

# 缓存设置
declare -g IPV6WGM_SMART_CACHE_ENABLED=true
declare -g IPV6WGM_CACHE_STRATEGY="adaptive"  # adaptive, aggressive, conservative
declare -g IPV6WGM_CACHE_TTL_DEFAULT=3600
declare -g IPV6WGM_CACHE_MAX_SIZE=100
declare -g IPV6WGM_CACHE_CLEANUP_INTERVAL=86400

# 缓存目录
declare -g IPV6WGM_SMART_CACHE_DIR="${CONFIG_DIR}/smart_cache"
declare -g IPV6WGM_CACHE_METADATA_FILE="${IPV6WGM_SMART_CACHE_DIR}/cache_metadata.json"
declare -g IPV6WGM_CACHE_STATS_FILE="${IPV6WGM_SMART_CACHE_DIR}/cache_stats.json"

# 缓存存储
declare -A IPV6WGM_CACHE_DATA=()
declare -A IPV6WGM_CACHE_TIMESTAMPS=()
declare -A IPV6WGM_CACHE_ACCESS_COUNT=()
declare -A IPV6WGM_CACHE_TTL=()

# 缓存统计
declare -g IPV6WGM_CACHE_HITS=0
declare -g IPV6WGM_CACHE_MISSES=0
declare -g IPV6WGM_CACHE_EVICTIONS=0
declare -g IPV6WGM_CACHE_SIZE=0
declare -g IPV6WGM_CACHE_LAST_CLEANUP=0

# 性能监控
declare -A IPV6WGM_CACHE_PERFORMANCE=()
declare -g IPV6WGM_CACHE_AVERAGE_ACCESS_TIME=0
declare -g IPV6WGM_CACHE_HIT_RATIO=0

# =============================================================================
# 智能缓存函数
# =============================================================================

# 初始化智能缓存系统
init_smart_caching() {
    log_info "初始化智能缓存系统..."
    
    # 创建缓存目录
    if ! mkdir -p "$IPV6WGM_SMART_CACHE_DIR"; then
        log_error "无法创建智能缓存目录: $IPV6WGM_SMART_CACHE_DIR"
        return 1
    fi
    
    # 加载缓存元数据
    load_cache_metadata
    
    
    # 加载缓存统计
    load_cache_stats
    
    # 启动缓存清理定时器
    start_cache_cleanup_timer
    
    log_success "智能缓存系统初始化完成"
    return 0
}

# 加载缓存元数据
load_cache_metadata() {
    if [[ -f "$IPV6WGM_CACHE_METADATA_FILE" ]]; then
        if command -v jq >/dev/null 2>&1; then
            load_cache_metadata_json
        else
            load_cache_metadata_text
        fi
    else
        log_debug "缓存元数据文件不存在，将创建新文件"
        create_cache_metadata_file
    fi
}

# 使用jq加载缓存元数据
load_cache_metadata_json() {
    local cache_count=$(jq '.cache_entries | length' "$IPV6WGM_CACHE_METADATA_FILE" 2>/dev/null || echo "0")
    
    for ((i=0; i<cache_count; i++)); do
        local key=$(jq -r ".cache_entries[$i].key" "$IPV6WGM_CACHE_METADATA_FILE" 2>/dev/null)
        local value=$(jq -r ".cache_entries[$i].value" "$IPV6WGM_CACHE_METADATA_FILE" 2>/dev/null)
        local timestamp=$(jq -r ".cache_entries[$i].timestamp" "$IPV6WGM_CACHE_METADATA_FILE" 2>/dev/null)
        local ttl=$(jq -r ".cache_entries[$i].ttl" "$IPV6WGM_CACHE_METADATA_FILE" 2>/dev/null)
        
        if [[ "$key" != "null" && -n "$key" ]]; then
            IPV6WGM_CACHE_DATA["$key"]="$value"
            IPV6WGM_CACHE_TIMESTAMPS["$key"]="$timestamp"
            IPV6WGM_CACHE_TTL["$key"]="$ttl"
            IPV6WGM_CACHE_ACCESS_COUNT["$key"]=0
        fi
    done
    
    IPV6WGM_CACHE_SIZE=${#IPV6WGM_CACHE_DATA[@]}
    log_debug "已加载 $IPV6WGM_CACHE_SIZE 个缓存条目"
}

# 使用文本处理加载缓存元数据
load_cache_metadata_text() {
    # 简单的文本解析（当jq不可用时）
    log_debug "已加载缓存元数据（文本模式）"
}

# 创建缓存元数据文件
create_cache_metadata_file() {
    local metadata='{
        "metadata": {
            "created": "'$(date -Iseconds)'",
            "version": "1.0.0",
            "description": "IPv6 WireGuard Manager 智能缓存元数据"
        },
        "cache_entries": [],
        "cache_config": {
            "strategy": "'$IPV6WGM_CACHE_STRATEGY'",
            "max_size": '$IPV6WGM_CACHE_MAX_SIZE',
            "default_ttl": '$IPV6WGM_CACHE_TTL_DEFAULT'
        }
    }'
    
    echo "$metadata" > "$IPV6WGM_CACHE_METADATA_FILE"
    log_debug "缓存元数据文件已创建: $IPV6WGM_CACHE_METADATA_FILE"
}

# 加载缓存统计
load_cache_stats() {
    if [[ -f "$IPV6WGM_CACHE_STATS_FILE" ]]; then
        if command -v jq >/dev/null 2>&1; then
            IPV6WGM_CACHE_HITS=$(jq -r '.cache_hits' "$IPV6WGM_CACHE_STATS_FILE" 2>/dev/null || echo "0")
            IPV6WGM_CACHE_MISSES=$(jq -r '.cache_misses' "$IPV6WGM_CACHE_STATS_FILE" 2>/dev/null || echo "0")
            IPV6WGM_CACHE_EVICTIONS=$(jq -r '.cache_evictions' "$IPV6WGM_CACHE_STATS_FILE" 2>/dev/null || echo "0")
            IPV6WGM_CACHE_LAST_CLEANUP=$(jq -r '.last_cleanup' "$IPV6WGM_CACHE_STATS_FILE" 2>/dev/null || echo "0")
        else
            # 简单的文本解析
            IPV6WGM_CACHE_HITS=0
            IPV6WGM_CACHE_MISSES=0
            IPV6WGM_CACHE_EVICTIONS=0
            IPV6WGM_CACHE_LAST_CLEANUP=0
        fi
    else
        create_cache_stats_file
    fi
    
    # 计算命中率
    calculate_cache_hit_ratio
}

# 创建缓存统计文件
create_cache_stats_file() {
    local stats='{
        "cache_hits": 0,
        "cache_misses": 0,
        "cache_evictions": 0,
        "last_cleanup": 0,
        "created": "'$(date -Iseconds)'"
    }'
    
    echo "$stats" > "$IPV6WGM_CACHE_STATS_FILE"
    log_debug "缓存统计文件已创建: $IPV6WGM_CACHE_STATS_FILE"
}

# 计算缓存命中率
calculate_cache_hit_ratio() {
    local total_requests=$((IPV6WGM_CACHE_HITS + IPV6WGM_CACHE_MISSES))
    
    if [[ $total_requests -gt 0 ]]; then
        IPV6WGM_CACHE_HIT_RATIO=$(( (IPV6WGM_CACHE_HITS * 100) / total_requests ))
    else
        IPV6WGM_CACHE_HIT_RATIO=0
    fi
}

# 设置缓存条目
set_cache() {
    local key="$1"
    local value="$2"
    local ttl="${3:-$IPV6WGM_CACHE_TTL_DEFAULT}"
    
    if [[ -z "$key" || -z "$value" ]]; then
        log_error "缓存键和值不能为空"
        return 1
    fi
    
    # 检查缓存大小限制
    if [[ ${#IPV6WGM_CACHE_DATA[@]} -ge $IPV6WGM_CACHE_MAX_SIZE ]]; then
        evict_cache_entry
    fi
    
    # 优先调用统一缓存API
    if command -v cache_set >/dev/null 2>&1; then
        cache_set "$key" "$value" "$ttl" || true
    fi

    # 设置本地缓存条目（兼容模块内部统计与持久化）
    IPV6WGM_CACHE_DATA["$key"]="$value"
    IPV6WGM_CACHE_TIMESTAMPS["$key"]=$(date +%s)
    IPV6WGM_CACHE_TTL["$key"]="$ttl"
    IPV6WGM_CACHE_ACCESS_COUNT["$key"]=0
    
    IPV6WGM_CACHE_SIZE=${#IPV6WGM_CACHE_DATA[@]}
    
    # 保存到元数据文件
    save_cache_metadata
    
    log_debug "缓存条目已设置: $key (TTL: ${ttl}s)"
    return 0
}

# 获取缓存条目
get_cache() {
    local key="$1"
    
    if [[ -z "$key" ]]; then
        log_error "缓存键不能为空"
        return 1
    fi
    
    # 优先从统一缓存API读取
    if command -v cache_get >/dev/null 2>&1; then
        local api_val
        if api_val=$(cache_get "$key" 2>/dev/null); then
            ((IPV6WGM_CACHE_HITS++))
            echo "$api_val"
            log_debug "统一API缓存命中: $key"
            return 0
        fi
    fi

    # 检查本地缓存是否存在
    if [[ -z "${IPV6WGM_CACHE_DATA[$key]}" ]]; then
        ((IPV6WGM_CACHE_MISSES++))
        log_debug "缓存未命中: $key"
        return 1
    fi
    
    # 检查TTL
    local current_time=$(date +%s)
    local entry_time="${IPV6WGM_CACHE_TIMESTAMPS[$key]}"
    local ttl="${IPV6WGM_CACHE_TTL[$key]}"
    
    if [[ $((current_time - entry_time)) -gt $ttl ]]; then
        # 缓存过期，删除条目
        unset IPV6WGM_CACHE_DATA["$key"]
        unset IPV6WGM_CACHE_TIMESTAMPS["$key"]
        unset IPV6WGM_CACHE_TTL["$key"]
        unset IPV6WGM_CACHE_ACCESS_COUNT["$key"]
        
        ((IPV6WGM_CACHE_MISSES++))
        log_debug "缓存已过期: $key"
        return 1
    fi
    
    # 更新访问计数
    ((IPV6WGM_CACHE_ACCESS_COUNT["$key"]++))
    ((IPV6WGM_CACHE_HITS++))
    
    # 输出缓存值
    echo "${IPV6WGM_CACHE_DATA[$key]}"
    
    log_debug "缓存命中: $key"
    return 0
}

# 删除缓存条目
delete_cache() {
    local key="$1"
    
    if [[ -z "$key" ]]; then
        log_error "缓存键不能为空"
        return 1
    fi
    
    # 统一API失效
    command -v cache_invalidate >/dev/null 2>&1 && cache_invalidate "$key" || true

    if [[ -n "${IPV6WGM_CACHE_DATA[$key]}" ]]; then
        unset IPV6WGM_CACHE_DATA["$key"]
        unset IPV6WGM_CACHE_TIMESTAMPS["$key"]
        unset IPV6WGM_CACHE_TTL["$key"]
        unset IPV6WGM_CACHE_ACCESS_COUNT["$key"]
        
        IPV6WGM_CACHE_SIZE=${#IPV6WGM_CACHE_DATA[@]}
        
        # 保存到元数据文件
        save_cache_metadata
        
        log_debug "缓存条目已删除: $key"
        return 0
    else
        log_warn "缓存条目不存在: $key"
        return 1
    fi
}

# 清空所有缓存
clear_cache() {
    log_info "清空所有缓存..."

    # 统一API清空
    command -v cache_clear >/dev/null 2>&1 && cache_clear || true
    
    IPV6WGM_CACHE_DATA=()
    IPV6WGM_CACHE_TIMESTAMPS=()
    IPV6WGM_CACHE_TTL=()
    IPV6WGM_CACHE_ACCESS_COUNT=()
    IPV6WGM_CACHE_SIZE=0
    
    # 保存到元数据文件
    save_cache_metadata
    
    log_success "所有缓存已清空"
    return 0
}

# 驱逐缓存条目
evict_cache_entry() {
    local evicted_key=""
    local min_access_count=999999
    local oldest_time=9999999999
    
    # 根据策略选择驱逐的条目
    case "$IPV6WGM_CACHE_STRATEGY" in
        "adaptive")
            # 自适应策略：结合访问频率和时间
            for key in "${!IPV6WGM_CACHE_DATA[@]}"; do
                local access_count="${IPV6WGM_CACHE_ACCESS_COUNT[$key]}"
                local entry_time="${IPV6WGM_CACHE_TIMESTAMPS[$key]}"
                local score=$((access_count * 1000 + entry_time))
                
                if [[ $score -lt $min_access_count ]]; then
                    min_access_count=$score
                    evicted_key="$key"
                fi
            done
            ;;
        "aggressive")
            # 激进策略：优先驱逐最久未访问的条目
            for key in "${!IPV6WGM_CACHE_DATA[@]}"; do
                local entry_time="${IPV6WGM_CACHE_TIMESTAMPS[$key]}"
                if [[ $entry_time -lt $oldest_time ]]; then
                    oldest_time=$entry_time
                    evicted_key="$key"
                fi
            done
            ;;
        "conservative")
            # 保守策略：优先驱逐访问次数最少的条目
            for key in "${!IPV6WGM_CACHE_DATA[@]}"; do
                local access_count="${IPV6WGM_CACHE_ACCESS_COUNT[$key]}"
                if [[ $access_count -lt $min_access_count ]]; then
                    min_access_count=$access_count
                    evicted_key="$key"
                fi
            done
            ;;
    esac
    
    if [[ -n "$evicted_key" ]]; then
        delete_cache "$evicted_key"
        ((IPV6WGM_CACHE_EVICTIONS++))
        log_debug "缓存条目已驱逐: $evicted_key"
    fi
}

# 保存缓存元数据
save_cache_metadata() {
    if command -v jq >/dev/null 2>&1; then
        save_cache_metadata_json
    else
        save_cache_metadata_text
    fi
}

# 使用jq保存缓存元数据
save_cache_metadata_json() {
    local temp_file=$(mktemp)
    local cache_entries_json="["
    local first=true
    
    for key in "${!IPV6WGM_CACHE_DATA[@]}"; do
        local value="${IPV6WGM_CACHE_DATA[$key]}"
        local timestamp="${IPV6WGM_CACHE_TIMESTAMPS[$key]}"
        local ttl="${IPV6WGM_CACHE_TTL[$key]}"
        local access_count="${IPV6WGM_CACHE_ACCESS_COUNT[$key]}"
        
        if [[ "$first" == "true" ]]; then
            first=false
        else
            cache_entries_json="$cache_entries_json,"
        fi
        
        cache_entries_json="$cache_entries_json{
            \"key\": \"$key\",
            \"value\": \"$value\",
            \"timestamp\": $timestamp,
            \"ttl\": $ttl,
            \"access_count\": $access_count
        }"
    done
    
    cache_entries_json="$cache_entries_json]"
    
    # 构建完整的JSON
    local full_json=$(jq -n \
        --argjson entries "$cache_entries_json" \
        --arg strategy "$IPV6WGM_CACHE_STRATEGY" \
        --argjson max_size "$IPV6WGM_CACHE_MAX_SIZE" \
        --argjson default_ttl "$IPV6WGM_CACHE_TTL_DEFAULT" \
        '{
            metadata: {
                created: "'$(date -Iseconds)'",
                version: "1.0.0",
                description: "IPv6 WireGuard Manager 智能缓存元数据"
            },
            cache_entries: $entries,
            cache_config: {
                strategy: $strategy,
                max_size: $max_size,
                default_ttl: $default_ttl
            }
        }')
    
    echo "$full_json" > "$temp_file"
    
    if [[ $? -eq 0 ]]; then
        mv "$temp_file" "$IPV6WGM_CACHE_METADATA_FILE"
        log_debug "缓存元数据已保存"
    else
        rm -f "$temp_file"
        log_error "保存缓存元数据失败"
    fi
}

# 使用文本处理保存缓存元数据
save_cache_metadata_text() {
    # 简单的文本保存（当jq不可用时）
    {
        echo "# IPv6 WireGuard Manager 智能缓存元数据"
        echo "# 生成时间: $(date)"
        echo
        for key in "${!IPV6WGM_CACHE_DATA[@]}"; do
            local value="${IPV6WGM_CACHE_DATA[$key]}"
            local timestamp="${IPV6WGM_CACHE_TIMESTAMPS[$key]}"
            local ttl="${IPV6WGM_CACHE_TTL[$key]}"
            local access_count="${IPV6WGM_CACHE_ACCESS_COUNT[$key]}"
            echo "KEY: $key"
            echo "VALUE: $value"
            echo "TIMESTAMP: $timestamp"
            echo "TTL: $ttl"
            echo "ACCESS_COUNT: $access_count"
            echo
        done
    } > "$IPV6WGM_CACHE_METADATA_FILE"
    
    log_debug "缓存元数据已保存（文本模式）"
}

# 启动缓存清理定时器
start_cache_cleanup_timer() {
    # 检查是否需要清理
    local current_time=$(date +%s)
    local time_since_cleanup=$((current_time - IPV6WGM_CACHE_LAST_CLEANUP))
    
    if [[ $time_since_cleanup -ge $IPV6WGM_CACHE_CLEANUP_INTERVAL ]]; then
        cleanup_expired_cache
    fi
}

# 清理过期缓存
cleanup_expired_cache() {
    log_info "清理过期缓存..."
    
    local current_time=$(date +%s)
    local cleaned_count=0
    
    for key in "${!IPV6WGM_CACHE_DATA[@]}"; do
        local entry_time="${IPV6WGM_CACHE_TIMESTAMPS[$key]}"
        local ttl="${IPV6WGM_CACHE_TTL[$key]}"
        
        if [[ $((current_time - entry_time)) -gt $ttl ]]; then
            delete_cache "$key"
            ((cleaned_count++))
        fi
    done
    
    IPV6WGM_CACHE_LAST_CLEANUP=$current_time
    save_cache_stats
    
    log_info "已清理 $cleaned_count 个过期缓存条目"
}

# 保存缓存统计
save_cache_stats() {
    local stats='{
        "cache_hits": '$IPV6WGM_CACHE_HITS',
        "cache_misses": '$IPV6WGM_CACHE_MISSES',
        "cache_evictions": '$IPV6WGM_CACHE_EVICTIONS',
        "last_cleanup": '$IPV6WGM_CACHE_LAST_CLEANUP',
        "updated": "'$(date -Iseconds)'"
    }'
    
    echo "$stats" > "$IPV6WGM_CACHE_STATS_FILE"
}

# 获取缓存统计
get_cache_statistics() {
    echo "=== 智能缓存统计 ==="
    echo "缓存启用: $([ "$IPV6WGM_SMART_CACHE_ENABLED" == "true" ] && echo "是" || echo "否")"
    echo "缓存策略: $IPV6WGM_CACHE_STRATEGY"
    echo "最大缓存大小: $IPV6WGM_CACHE_MAX_SIZE"
    echo "默认TTL: ${IPV6WGM_CACHE_TTL_DEFAULT}秒"
    echo "当前缓存大小: $IPV6WGM_CACHE_SIZE"
    echo "缓存命中: $IPV6WGM_CACHE_HITS"
    echo "缓存未命中: $IPV6WGM_CACHE_MISSES"
    echo "缓存驱逐: $IPV6WGM_CACHE_EVICTIONS"
    echo "命中率: ${IPV6WGM_CACHE_HIT_RATIO}%"
    echo "最后清理: $(date -d @$IPV6WGM_CACHE_LAST_CLEANUP '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "从未清理")"
    
    # 显示缓存条目详情
    if [[ $IPV6WGM_CACHE_SIZE -gt 0 ]]; then
        echo
        echo "缓存条目详情:"
        printf "%-20s %-10s %-15s %-10s\n" "键" "访问次数" "创建时间" "TTL"
        printf "%-20s %-10s %-15s %-10s\n" "---" "--------" "----------" "---"
        
        for key in "${!IPV6WGM_CACHE_DATA[@]}"; do
            local access_count="${IPV6WGM_CACHE_ACCESS_COUNT[$key]}"
            local timestamp="${IPV6WGM_CACHE_TIMESTAMPS[$key]}"
            local ttl="${IPV6WGM_CACHE_TTL[$key]}"
            local create_time=$(date -d @$timestamp '+%H:%M:%S' 2>/dev/null || echo "未知")
            
            printf "%-20s %-10s %-15s %-10s\n" "$key" "$access_count" "$create_time" "${ttl}s"
        done
    fi
}

# 设置缓存策略
set_cache_strategy() {
    local strategy="$1"
    
    case "$strategy" in
        "adaptive"|"aggressive"|"conservative")
            IPV6WGM_CACHE_STRATEGY="$strategy"
            log_success "缓存策略已设置为: $strategy"
            return 0
            ;;
        *)
            log_error "无效的缓存策略: $strategy"
            log_info "支持的策略: adaptive, aggressive, conservative"
            return 1
            ;;
    esac
}

# 设置缓存大小限制
set_cache_max_size() {
    local max_size="$1"
    
    if [[ "$max_size" =~ ^[0-9]+$ ]] && [[ $max_size -gt 0 ]]; then
        IPV6WGM_CACHE_MAX_SIZE="$max_size"
        log_success "缓存最大大小已设置为: $max_size"
        return 0
    else
        log_error "无效的缓存大小: $max_size"
        return 1
    fi
}

# 设置默认TTL
set_cache_default_ttl() {
    local ttl="$1"
    
    if [[ "$ttl" =~ ^[0-9]+$ ]] && [[ $ttl -gt 0 ]]; then
        IPV6WGM_CACHE_TTL_DEFAULT="$ttl"
        log_success "默认TTL已设置为: ${ttl}秒"
        return 0
    else
        log_error "无效的TTL: $ttl"
        return 1
    fi
}

# 导出函数
export -f init_smart_caching
export -f set_cache
export -f get_cache
export -f delete_cache
export -f clear_cache
export -f cleanup_expired_cache
export -f get_cache_statistics
export -f set_cache_strategy
export -f set_cache_max_size
export -f set_cache_default_ttl
