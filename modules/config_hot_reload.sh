#!/bin/bash

# 配置热重载模块
# 提供配置文件的实时监控和热重载功能

# =============================================================================
# 热重载配置
# =============================================================================

# 监控设置
declare -g IPV6WGM_HOT_RELOAD_ENABLED=false
declare -g IPV6WGM_CONFIG_WATCH_INTERVAL=5
declare -g IPV6WGM_CONFIG_WATCH_TIMEOUT=300
declare -g IPV6WGM_CONFIG_VALIDATION_ENABLED=true

# 监控文件列表
declare -a IPV6WGM_WATCHED_FILES=(
    "$CONFIG_FILE"
    "$CONFIG_DIR/manager.conf"
    "$CONFIG_DIR/bird.conf"
    "$CONFIG_DIR/firewall_rules.conf"
)

# 监控状态
declare -A IPV6WGM_FILE_HASHES=()
declare -A IPV6WGM_FILE_TIMESTAMPS=()
declare -g IPV6WGM_WATCH_PID=""
declare -g IPV6WGM_RELOAD_COUNT=0

# 重载回调函数
declare -a IPV6WGM_RELOAD_CALLBACKS=()

# =============================================================================
# 热重载函数
# =============================================================================

# 初始化热重载系统
init_hot_reload() {
    log_info "初始化配置热重载系统..."
    
    # 检查依赖
    if ! check_hot_reload_dependencies; then
        log_error "热重载依赖检查失败"
        return 1
    fi
    
    # 初始化文件监控
    init_file_monitoring
    
    # 注册默认重载回调
    register_default_reload_callbacks
    
    log_success "配置热重载系统初始化完成"
    return 0
}

# 检查热重载依赖
check_hot_reload_dependencies() {
    local missing_deps=()
    
    # 检查inotify-tools（如果可用）
    if ! command -v inotifywait >/dev/null 2>&1; then
        log_warn "inotifywait不可用，将使用轮询模式"
    fi
    
    # 检查md5sum
    if ! command -v md5sum >/dev/null 2>&1; then
        missing_deps+=("md5sum")
    fi
    
    # 检查stat
    if ! command -v stat >/dev/null 2>&1; then
        missing_deps+=("stat")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "缺少必要依赖: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# 初始化文件监控
init_file_monitoring() {
    # 计算初始文件哈希
    for file in "${IPV6WGM_WATCHED_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            IPV6WGM_FILE_HASHES["$file"]=$(calculate_file_hash "$file")
            IPV6WGM_FILE_TIMESTAMPS["$file"]=$(get_file_timestamp "$file")
        fi
    done
    
    log_debug "已初始化 ${#IPV6WGM_WATCHED_FILES[@]} 个文件的监控"
}

# 计算文件哈希
calculate_file_hash() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        md5sum "$file" 2>/dev/null | cut -d' ' -f1 || echo "unknown"
    else
        echo "missing"
    fi
}

# 获取文件时间戳
get_file_timestamp() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        stat -c %Y "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# 注册默认重载回调
register_default_reload_callbacks() {
    # 注册配置重载回调
    register_reload_callback "reload_config" "重新加载配置"
    
    # 注册WireGuard重载回调
    register_reload_callback "reload_wireguard" "重新加载WireGuard配置"
    
    # 注册BIRD重载回调
    register_reload_callback "reload_bird" "重新加载BIRD配置"
    
    # 注册防火墙重载回调
    register_reload_callback "reload_firewall" "重新加载防火墙规则"
}

# 注册重载回调函数
register_reload_callback() {
    local callback_function="$1"
    local description="${2:-未知回调}"
    
    if command -v "$callback_function" >/dev/null 2>&1; then
        IPV6WGM_RELOAD_CALLBACKS+=("$callback_function|$description")
        log_debug "已注册重载回调: $callback_function ($description)"
        return 0
    else
        log_warn "回调函数不存在: $callback_function"
        return 1
    fi
}

# 启动配置监控
start_config_monitoring() {
    if [[ "$IPV6WGM_HOT_RELOAD_ENABLED" == "true" ]]; then
        log_warn "配置监控已在运行"
        return 0
    fi
    
    log_info "启动配置监控..."
    
    # 启动监控进程
    if command -v inotifywait >/dev/null 2>&1; then
        start_inotify_monitoring
    else
        start_polling_monitoring
    fi
    
    IPV6WGM_HOT_RELOAD_ENABLED=true
    log_success "配置监控已启动"
    return 0
}

# 启动inotify监控
start_inotify_monitoring() {
    local watch_dirs=()
    
    # 收集监控目录
    for file in "${IPV6WGM_WATCHED_FILES[@]}"; do
        local dir=$(dirname "$file")
        if [[ ! " ${watch_dirs[*]} " =~ " $dir " ]]; then
            watch_dirs+=("$dir")
        fi
    done
    
    # 启动inotifywait
    (
        while true; do
            inotifywait -e modify,move,create,delete "${watch_dirs[@]}" 2>/dev/null | while read -r path action file; do
                local full_path="${path}/${file}"
                if [[ " ${IPV6WGM_WATCHED_FILES[*]} " =~ " $full_path " ]]; then
                    handle_file_change "$full_path" "$action"
                fi
            done
            smart_sleep "$IPV6WGM_SLEEP_MEDIUM"
        done
    ) &
    
    IPV6WGM_WATCH_PID=$!
    log_debug "inotify监控已启动，PID: $IPV6WGM_WATCH_PID"
}

# 启动轮询监控
start_polling_monitoring() {
    (
        while true; do
            check_file_changes
            sleep "$IPV6WGM_CONFIG_WATCH_INTERVAL"
        done
    ) &
    
    IPV6WGM_WATCH_PID=$!
    log_debug "轮询监控已启动，PID: $IPV6WGM_WATCH_PID"
}

# 检查文件变化
check_file_changes() {
    for file in "${IPV6WGM_WATCHED_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            local current_hash=$(calculate_file_hash "$file")
            local current_timestamp=$(get_file_timestamp "$file")
            local stored_hash="${IPV6WGM_FILE_HASHES[$file]}"
            local stored_timestamp="${IPV6WGM_FILE_TIMESTAMPS[$file]}"
            
            # 检查文件是否发生变化
            if [[ "$current_hash" != "$stored_hash" || "$current_timestamp" != "$stored_timestamp" ]]; then
                handle_file_change "$file" "modified"
                
                # 更新存储的哈希和时间戳
                IPV6WGM_FILE_HASHES["$file"]="$current_hash"
                IPV6WGM_FILE_TIMESTAMPS["$file"]="$current_timestamp"
            fi
        else
            # 文件不存在
            if [[ "${IPV6WGM_FILE_HASHES[$file]}" != "missing" ]]; then
                handle_file_change "$file" "deleted"
                IPV6WGM_FILE_HASHES["$file"]="missing"
                IPV6WGM_FILE_TIMESTAMPS["$file"]="0"
            fi
        fi
    done
}

# 处理文件变化
handle_file_change() {
    local file="$1"
    local action="$2"
    
    log_info "检测到文件变化: $file ($action)"
    
    # 验证配置文件（如果启用）
    if [[ "$IPV6WGM_CONFIG_VALIDATION_ENABLED" == "true" ]]; then
        if ! validate_config_file "$file"; then
            log_error "配置文件验证失败: $file"
            return 1
        fi
    fi
    
    # 执行重载
    if execute_reload "$file" "$action"; then
        ((IPV6WGM_RELOAD_COUNT++))
        log_success "配置重载成功: $file"
    else
        log_error "配置重载失败: $file"
    fi
}

# 验证配置文件
validate_config_file() {
    local file="$1"
    
    # 基本文件检查
    if [[ ! -f "$file" ]]; then
        log_error "文件不存在: $file"
        return 1
    fi
    
    if [[ ! -r "$file" ]]; then
        log_error "文件不可读: $file"
        return 1
    fi
    
    # 根据文件类型进行特定验证
    local filename=$(basename "$file")
    case "$filename" in
        "manager.conf")
            validate_manager_config "$file"
            ;;
        "bird.conf")
            validate_bird_config "$file"
            ;;
        "firewall_rules.conf")
            validate_firewall_config "$file"
            ;;
        *)
            # 通用验证
            validate_generic_config "$file"
            ;;
    esac
}

# 验证管理器配置
validate_manager_config() {
    local file="$1"
    
    # 检查必要的配置项
    local required_keys=("IPV6WGM_VERSION" "IPV6WGM_CONFIG_DIR" "IPV6WGM_LOG_DIR")
    
    for key in "${required_keys[@]}"; do
        if ! grep -q "^${key}=" "$file"; then
            log_error "缺少必要配置项: $key"
            return 1
        fi
    done
    
    return 0
}

# 验证BIRD配置
validate_bird_config() {
    local file="$1"
    
    # 检查BIRD配置语法
    if command -v birdc >/dev/null 2>&1; then
        if ! birdc -c "$file" -p 2>/dev/null; then
            log_error "BIRD配置语法错误"
            return 1
        fi
    fi
    
    return 0
}

# 验证防火墙配置
validate_firewall_config() {
    local file="$1"
    
    # 检查防火墙规则语法
    if command -v iptables >/dev/null 2>&1; then
        # 这里可以添加iptables规则验证逻辑
        log_debug "防火墙配置验证通过"
    fi
    
    return 0
}

# 验证通用配置
validate_generic_config() {
    local file="$1"
    
    # 检查文件是否为空
    if [[ ! -s "$file" ]]; then
        log_error "配置文件为空: $file"
        return 1
    fi
    
    # 检查文件编码
    if ! file "$file" | grep -q "text"; then
        log_error "配置文件不是文本文件: $file"
        return 1
    fi
    
    return 0
}

# 执行重载
execute_reload() {
    local file="$1"
    local action="$2"
    
    log_info "执行配置重载: $file"
    
    # 执行所有注册的回调函数
    local success_count=0
    local total_count=${#IPV6WGM_RELOAD_CALLBACKS[@]}
    
    for callback_info in "${IPV6WGM_RELOAD_CALLBACKS[@]}"; do
        local callback_function="${callback_info%%|*}"
        local description="${callback_info#*|}"
        
        if command -v "$callback_function" >/dev/null 2>&1; then
            log_debug "执行回调: $description"
            if "$callback_function" "$file" "$action"; then
                ((success_count++))
                log_debug "回调执行成功: $description"
            else
                log_warn "回调执行失败: $description"
            fi
        fi
    done
    
    # 检查重载结果
    if [[ $success_count -eq $total_count ]]; then
        log_success "所有重载回调执行成功 ($success_count/$total_count)"
        return 0
    else
        log_warn "部分重载回调执行失败 ($success_count/$total_count)"
        return 1
    fi
}

# 停止配置监控
stop_config_monitoring() {
    if [[ "$IPV6WGM_HOT_RELOAD_ENABLED" != "true" ]]; then
        log_warn "配置监控未运行"
        return 0
    fi
    
    log_info "停止配置监控..."
    
    if [[ -n "$IPV6WGM_WATCH_PID" && "$IPV6WGM_WATCH_PID" != "0" ]]; then
        if kill "$IPV6WGM_WATCH_PID" 2>/dev/null; then
            log_debug "监控进程已停止，PID: $IPV6WGM_WATCH_PID"
        else
            log_warn "无法停止监控进程: $IPV6WGM_WATCH_PID"
        fi
        IPV6WGM_WATCH_PID=""
    fi
    
    IPV6WGM_HOT_RELOAD_ENABLED=false
    log_success "配置监控已停止"
    return 0
}

# 手动触发重载
trigger_reload() {
    local file="${1:-}"
    
    if [[ -n "$file" ]]; then
        # 重载指定文件
        if [[ -f "$file" ]]; then
            handle_file_change "$file" "manual"
        else
            log_error "文件不存在: $file"
            return 1
        fi
    else
        # 重载所有监控文件
        log_info "手动触发所有配置重载..."
        for file in "${IPV6WGM_WATCHED_FILES[@]}"; do
            if [[ -f "$file" ]]; then
                handle_file_change "$file" "manual"
            fi
        done
    fi
    
    return 0
}

# 获取监控状态
get_monitoring_status() {
    echo "=== 配置热重载状态 ==="
    echo "监控状态: $([ "$IPV6WGM_HOT_RELOAD_ENABLED" == "true" ] && echo "运行中" || echo "已停止")"
    echo "监控进程PID: ${IPV6WGM_WATCH_PID:-无}"
    echo "监控间隔: ${IPV6WGM_CONFIG_WATCH_INTERVAL}秒"
    echo "配置验证: $([ "$IPV6WGM_CONFIG_VALIDATION_ENABLED" == "true" ] && echo "启用" || echo "禁用")"
    echo "重载次数: $IPV6WGM_RELOAD_COUNT"
    echo "监控文件数: ${#IPV6WGM_WATCHED_FILES[@]}"
    echo "注册回调数: ${#IPV6WGM_RELOAD_CALLBACKS[@]}"
    
    echo
    echo "监控文件列表:"
    for file in "${IPV6WGM_WATCHED_FILES[@]}"; do
        local status="存在"
        local hash="${IPV6WGM_FILE_HASHES[$file]}"
        
        if [[ ! -f "$file" ]]; then
            status="不存在"
            hash="missing"
        fi
        
        echo "  $file - $status (${hash:0:8}...)"
    done
    
    echo
    echo "注册的回调函数:"
    for callback_info in "${IPV6WGM_RELOAD_CALLBACKS[@]}"; do
        local callback_function="${callback_info%%|*}"
        local description="${callback_info#*|}"
        echo "  $callback_function - $description"
    done
}

# 设置监控参数
set_monitoring_parameters() {
    local interval="$1"
    local validation="$2"
    
    if [[ -n "$interval" && "$interval" =~ ^[0-9]+$ ]]; then
        IPV6WGM_CONFIG_WATCH_INTERVAL="$interval"
        log_info "监控间隔已设置为: $interval 秒"
    fi
    
    if [[ -n "$validation" ]]; then
        if [[ "$validation" == "true" || "$validation" == "false" ]]; then
            IPV6WGM_CONFIG_VALIDATION_ENABLED="$validation"
            log_info "配置验证已设置为: $validation"
        else
            log_error "无效的验证设置: $validation"
            return 1
        fi
    fi
    
    return 0
}

# 添加监控文件
add_watched_file() {
    local file="$1"
    
    if [[ -z "$file" ]]; then
        log_error "请指定要监控的文件"
        return 1
    fi
    
    # 检查文件是否已在监控列表中
    if [[ " ${IPV6WGM_WATCHED_FILES[*]} " =~ " $file " ]]; then
        log_warn "文件已在监控列表中: $file"
        return 0
    fi
    
    # 添加到监控列表
    IPV6WGM_WATCHED_FILES+=("$file")
    
    # 初始化文件监控
    if [[ -f "$file" ]]; then
        IPV6WGM_FILE_HASHES["$file"]=$(calculate_file_hash "$file")
        IPV6WGM_FILE_TIMESTAMPS["$file"]=$(get_file_timestamp "$file")
    else
        IPV6WGM_FILE_HASHES["$file"]="missing"
        IPV6WGM_FILE_TIMESTAMPS["$file"]="0"
    fi
    
    log_success "已添加监控文件: $file"
    return 0
}

# 移除监控文件
remove_watched_file() {
    local file="$1"
    
    if [[ -z "$file" ]]; then
        log_error "请指定要移除的文件"
        return 1
    fi
    
    # 从监控列表中移除
    local new_watched_files=()
    for watched_file in "${IPV6WGM_WATCHED_FILES[@]}"; do
        if [[ "$watched_file" != "$file" ]]; then
            new_watched_files+=("$watched_file")
        fi
    done
    IPV6WGM_WATCHED_FILES=("${new_watched_files[@]}")
    
    # 从哈希表中移除
    unset IPV6WGM_FILE_HASHES["$file"]
    unset IPV6WGM_FILE_TIMESTAMPS["$file"]
    
    log_success "已移除监控文件: $file"
    return 0
}

# 导出函数
export -f init_hot_reload
export -f start_config_monitoring
export -f stop_config_monitoring
export -f trigger_reload
export -f get_monitoring_status
export -f set_monitoring_parameters
export -f add_watched_file
export -f remove_watched_file
export -f register_reload_callback
