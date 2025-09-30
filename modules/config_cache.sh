#!/bin/bash

# 配置缓存模块
# 提供配置文件缓存、解析优化、热重载等功能

# 导入公共函数
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
fi

# 导入性能优化模块
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/performance_optimizer.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/performance_optimizer.sh"
fi

# =============================================================================
# 配置缓存配置
# =============================================================================

# 配置文件缓存
declare -A IPV6WGM_CONFIG_CACHE=()
declare -A IPV6WGM_CONFIG_TIMESTAMP=()
declare -A IPV6WGM_CONFIG_HASH=()

# 配置解析缓存
declare -A IPV6WGM_PARSED_CONFIG_CACHE=()
declare -A IPV6WGM_PARSED_CONFIG_TIMESTAMP=()

# 配置热重载
declare -A IPV6WGM_CONFIG_WATCHERS=()
IPV6WGM_CONFIG_CACHE_TTL=300  # 配置缓存生存时间（秒）

# =============================================================================
# 配置文件管理函数
# =============================================================================

# 缓存配置文件
cache_config_file() {
    local config_file="$1"
    local cache_key="config_${config_file//\//_}"
    
    # 检查文件是否存在
    if [[ ! -f "$config_file" ]]; then
        log_warn "配置文件不存在: $config_file"
        return 1
    fi
    
    # 计算文件哈希
    local file_hash=$(get_file_hash "$config_file")
    local cached_hash="${IPV6WGM_CONFIG_HASH[$cache_key]}"
    
    # 检查文件是否已更改
    if [[ "$file_hash" == "$cached_hash" ]]; then
        log_debug "配置文件未更改: $config_file"
        return 0
    fi
    
    # 读取配置文件
    local config_content=$(cat "$config_file")
    local current_time=$(date +%s)
    
    # 更新缓存
    IPV6WGM_CONFIG_CACHE["$cache_key"]="$config_content"
    IPV6WGM_CONFIG_TIMESTAMP["$cache_key"]="$current_time"
    IPV6WGM_CONFIG_HASH["$cache_key"]="$file_hash"
    
    log_debug "配置文件已缓存: $config_file (哈希: ${file_hash:0:8})"
    echo "$config_content"
}

# 获取缓存的配置文件
get_cached_config_file() {
    local config_file="$1"
    local cache_key="config_${config_file//\//_}"
    local current_time=$(date +%s)
    local cache_time="${IPV6WGM_CONFIG_TIMESTAMP[$cache_key]:-0}"
    
    # 检查缓存是否存在且未过期
    if [[ -n "${IPV6WGM_CONFIG_CACHE[$cache_key]:-}" ]]; then
        if [[ $((current_time - cache_time)) -lt $IPV6WGM_CONFIG_CACHE_TTL ]]; then
            log_debug "配置缓存命中: $config_file"
            echo "${IPV6WGM_CONFIG_CACHE[$cache_key]}"
            return 0
        else
            log_debug "配置缓存过期: $config_file"
            # 清除过期缓存
            unset IPV6WGM_CONFIG_CACHE["$cache_key"]
            unset IPV6WGM_CONFIG_TIMESTAMP["$cache_key"]
            unset IPV6WGM_CONFIG_HASH["$cache_key"]
        fi
    fi
    
    return 1
}

# 获取文件哈希
get_file_hash() {
    local file_path="$1"
    
    if command -v md5sum >/dev/null 2>&1; then
        md5sum "$file_path" 2>/dev/null | cut -d' ' -f1
    elif command -v md5 >/dev/null 2>&1; then
        md5 -q "$file_path" 2>/dev/null
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file_path" 2>/dev/null | cut -d' ' -f1
    else
        # 使用文件大小和修改时间作为简单哈希
        stat -c "%s-%Y" "$file_path" 2>/dev/null || echo "unknown"
    fi
}

# =============================================================================
# 配置解析函数
# =============================================================================

# 解析配置文件（优化版本）
parse_config_file() {
    local config_file="$1"
    local cache_key="parsed_${config_file//\//_}"
    local current_time=$(date +%s)
    local cache_time="${IPV6WGM_PARSED_CONFIG_TIMESTAMP[$cache_key]:-0}"
    
    # 检查解析缓存
    if [[ -n "${IPV6WGM_PARSED_CONFIG_CACHE[$cache_key]:-}" ]]; then
        if [[ $((current_time - cache_time)) -lt $IPV6WGM_CONFIG_CACHE_TTL ]]; then
            log_debug "解析缓存命中: $config_file"
            echo "${IPV6WGM_PARSED_CONFIG_CACHE[$cache_key]}"
            return 0
        fi
    fi
    
    # 获取配置文件内容
    local config_content
    if ! config_content=$(get_cached_config_file "$config_file"); then
        if ! config_content=$(cache_config_file "$config_file"); then
            log_error "无法读取配置文件: $config_file"
            return 1
        fi
    fi
    
    # 解析配置
    local parsed_config=$(parse_config_content "$config_content")
    local parse_result=$?
    
    if [[ $parse_result -eq 0 ]]; then
        # 缓存解析结果
        IPV6WGM_PARSED_CONFIG_CACHE["$cache_key"]="$parsed_config"
        IPV6WGM_PARSED_CONFIG_TIMESTAMP["$cache_key"]="$current_time"
        
        log_debug "配置解析完成: $config_file"
        echo "$parsed_config"
    else
        log_error "配置解析失败: $config_file"
        return 1
    fi
}

# 解析配置内容
parse_config_content() {
    local content="$1"
    local config_vars=()
    local config_values=()
    
    # 使用更高效的解析方法
    while IFS= read -r line; do
        # 跳过注释和空行
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        
        # 查找等号
        if [[ "$line" =~ ^[[:space:]]*([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # 去除前后空格
            key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # 去除引号
            value=$(echo "$value" | sed 's/^"//;s/"$//')
            
            config_vars+=("$key")
            config_values+=("$value")
        fi
    done <<< "$content"
    
    # 返回解析结果
    printf '%s\n' "${config_vars[@]}" | paste -sd '|'
}

# =============================================================================
# 配置热重载函数
# =============================================================================

# 添加配置文件监视器
add_config_watcher() {
    local config_file="$1"
    local callback_function="$2"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在: $config_file"
        return 1
    fi
    
    IPV6WGM_CONFIG_WATCHERS["$config_file"]="$callback_function"
    log_debug "配置文件监视器已添加: $config_file"
}

# 移除配置文件监视器
remove_config_watcher() {
    local config_file="$1"
    
    if [[ -n "${IPV6WGM_CONFIG_WATCHERS[$config_file]:-}" ]]; then
        unset IPV6WGM_CONFIG_WATCHERS["$config_file"]
        log_debug "配置文件监视器已移除: $config_file"
    fi
}

# 检查配置文件更改
check_config_changes() {
    local changed_files=()
    
    for config_file in "${!IPV6WGM_CONFIG_WATCHERS[@]}"; do
        local cache_key="config_${config_file//\//_}"
        local current_hash=$(get_file_hash "$config_file")
        local cached_hash="${IPV6WGM_CONFIG_HASH[$cache_key]}"
        
        if [[ "$current_hash" != "$cached_hash" ]]; then
            changed_files+=("$config_file")
        fi
    done
    
    # 处理更改的文件
    for config_file in "${changed_files[@]}"; do
        local callback_function="${IPV6WGM_CONFIG_WATCHERS[$config_file]}"
        
        log_info "配置文件已更改: $config_file"
        
        # 清除相关缓存
        clear_config_cache "$config_file"
        
        # 调用回调函数
        if [[ -n "$callback_function" ]] && command -v "$callback_function" >/dev/null 2>&1; then
            log_debug "调用回调函数: $callback_function"
            "$callback_function" "$config_file"
        fi
    done
    
    echo "${#changed_files[@]}"
}

# =============================================================================
# 缓存管理函数
# =============================================================================

# 清除配置文件缓存
clear_config_cache() {
    local config_file="$1"
    
    if [[ -n "$config_file" ]]; then
        local cache_key="config_${config_file//\//_}"
        local parsed_cache_key="parsed_${config_file//\//_}"
        
        unset IPV6WGM_CONFIG_CACHE["$cache_key"]
        unset IPV6WGM_CONFIG_TIMESTAMP["$cache_key"]
        unset IPV6WGM_CONFIG_HASH["$cache_key"]
        unset IPV6WGM_PARSED_CONFIG_CACHE["$parsed_cache_key"]
        unset IPV6WGM_PARSED_CONFIG_TIMESTAMP["$parsed_cache_key"]
        
        log_debug "配置文件缓存已清除: $config_file"
    else
        # 清除所有缓存
        IPV6WGM_CONFIG_CACHE=()
        IPV6WGM_CONFIG_TIMESTAMP=()
        IPV6WGM_CONFIG_HASH=()
        IPV6WGM_PARSED_CONFIG_CACHE=()
        IPV6WGM_PARSED_CONFIG_TIMESTAMP=()
        
        log_debug "所有配置缓存已清除"
    fi
}

# 清除过期缓存
clear_expired_config_cache() {
    local current_time=$(date +%s)
    local expired_keys=()
    
    # 检查配置缓存
    for key in "${!IPV6WGM_CONFIG_TIMESTAMP[@]}"; do
        local cache_time="${IPV6WGM_CONFIG_TIMESTAMP[$key]}"
        if [[ $((current_time - cache_time)) -ge $IPV6WGM_CONFIG_CACHE_TTL ]]; then
            expired_keys+=("$key")
        fi
    done
    
    # 检查解析缓存
    for key in "${!IPV6WGM_PARSED_CONFIG_TIMESTAMP[@]}"; do
        local cache_time="${IPV6WGM_PARSED_CONFIG_TIMESTAMP[$key]}"
        if [[ $((current_time - cache_time)) -ge $IPV6WGM_CONFIG_CACHE_TTL ]]; then
            expired_keys+=("$key")
        fi
    done
    
    # 清除过期缓存
    for key in "${expired_keys[@]}"; do
        unset IPV6WGM_CONFIG_CACHE["$key"]
        unset IPV6WGM_CONFIG_TIMESTAMP["$key"]
        unset IPV6WGM_CONFIG_HASH["$key"]
        unset IPV6WGM_PARSED_CONFIG_CACHE["$key"]
        unset IPV6WGM_PARSED_CONFIG_TIMESTAMP["$key"]
        log_debug "过期配置缓存已清除: $key"
    done
}

# =============================================================================
# 配置验证函数
# =============================================================================

# 验证配置文件
validate_config_file() {
    local config_file="$1"
    local validation_rules="$2"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在: $config_file"
        return 1
    fi
    
    # 解析配置文件
    local parsed_config=$(parse_config_file "$config_file")
    if [[ $? -ne 0 ]]; then
        log_error "配置文件解析失败: $config_file"
        return 1
    fi
    
    # 验证配置项
    local validation_result=$(validate_config_content "$parsed_config" "$validation_rules")
    local validation_code=$?
    
    if [[ $validation_code -eq 0 ]]; then
        log_success "配置文件验证通过: $config_file"
    else
        log_error "配置文件验证失败: $config_file"
        log_error "验证结果: $validation_result"
    fi
    
    return $validation_code
}

# 验证配置内容
validate_config_content() {
    local parsed_config="$1"
    local validation_rules="$2"
    
    # 这里可以添加具体的验证逻辑
    # 例如：检查必需的配置项、验证配置值格式等
    
    log_debug "配置内容验证: $parsed_config"
    return 0
}

# =============================================================================
# 统计和监控函数
# =============================================================================

# 获取缓存统计
get_config_cache_stats() {
    echo "=== 配置缓存统计 ==="
    echo "配置文件缓存项数: ${#IPV6WGM_CONFIG_CACHE[@]}"
    echo "解析缓存项数: ${#IPV6WGM_PARSED_CONFIG_CACHE[@]}"
    echo "监视器数量: ${#IPV6WGM_CONFIG_WATCHERS[@]}"
    echo "缓存TTL: ${IPV6WGM_CONFIG_CACHE_TTL}s"
    
    echo
    echo "=== 配置文件缓存 ==="
    for key in "${!IPV6WGM_CONFIG_CACHE[@]}"; do
        local timestamp="${IPV6WGM_CONFIG_TIMESTAMP[$key]}"
        local age=$(( $(date +%s) - timestamp ))
        echo "$key: ${age}s ago"
    done
}

# =============================================================================
# 初始化函数
# =============================================================================

# 初始化配置缓存模块
init_config_cache() {
    log_info "初始化配置缓存模块..."
    
    # 设置缓存清理定时任务
    if command -v trap >/dev/null 2>&1; then
        trap clear_expired_config_cache EXIT
    fi
    
    # 设置配置文件检查间隔
    if [[ -n "${IPV6WGM_CONFIG_CHECK_INTERVAL:-}" ]]; then
        log_debug "配置文件检查间隔: ${IPV6WGM_CONFIG_CHECK_INTERVAL}s"
    fi
    
    log_success "配置缓存模块初始化完成"
}

# 导出函数
export -f cache_config_file get_cached_config_file get_file_hash
export -f parse_config_file parse_config_content
export -f add_config_watcher remove_config_watcher check_config_changes
export -f clear_config_cache clear_expired_config_cache
export -f validate_config_file validate_config_content
export -f get_config_cache_stats init_config_cache

# 如果直接执行此脚本，则初始化
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_config_cache
fi
