#!/bin/bash

# 函数实现优化模块
# 提供函数重构、参数验证和返回值标准化功能

# =============================================================================
# 函数重构工具
# =============================================================================

# 函数分类管理
declare -A FUNCTION_CATEGORIES=(
    ["logging"]="log_info log_warn log_error log_debug log_fatal log_success"
    ["validation"]="validate_config_item validate_config_format validate_username validate_password"
    ["execution"]="safe_execute execute_command cached_command smart_cached_command"
    ["file_ops"]="load_config ensure_log_directory fix_line_endings"
    ["system"]="detect_os install_dependency install_python_dependency"
    ["cache"]="cached_command smart_cached_command warm_cache clear_cache"
    ["monitoring"]="get_memory_usage get_cpu_usage get_disk_usage"
)

# 函数依赖关系
declare -A FUNCTION_DEPENDENCIES=(
    ["log_with_level"]="check_log_level rotate_logs ensure_log_directory"
    ["safe_execute"]="log_debug log_error exit_with_error"
    ["cached_command"]="log_debug log_error"
    ["validate_config_item"]="log_error"
    ["load_config"]="log_info log_error validate_config_format"
)

# 函数重构：合并相似功能
refactor_similar_functions() {
    local category="$1"
    local functions="${FUNCTION_CATEGORIES[$category]}"
    
    if [[ -z "$functions" ]]; then
        log_error "未知的函数分类: $category"
        return 1
    fi
    
    log_info "重构分类 '$category' 中的函数: $functions"
    
    case "$category" in
        "logging")
            refactor_logging_functions
            ;;
        "validation")
            refactor_validation_functions
            ;;
        "execution")
            refactor_execution_functions
            ;;
        "cache")
            refactor_cache_functions
            ;;
        *)
            log_warn "暂不支持重构分类: $category"
            ;;
    esac
}

# 重构日志函数
refactor_logging_functions() {
    log_info "重构日志函数..."
    
    # 创建统一的日志处理函数
    cat > /tmp/unified_logging.sh << 'EOF'
# 统一的日志处理函数
unified_log() {
    local level="$1"
    local message="$2"
    local context="${3:-}"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local log_file="$IPV6WGM_LOG_FILE"
    
    # 参数验证
    if [[ -z "$level" || -z "$message" ]]; then
        echo "错误: 日志级别和消息不能为空" >&2
        return 1
    fi
    
    # 检查日志级别
    if ! check_log_level "$level"; then
        return 0
    fi
    
    # 确保日志目录存在
    ensure_log_directory "$log_file"
    
    # 日志轮转
    rotate_logs "$log_file"
    
    # 格式化消息
    local formatted_message="[$timestamp] [$level]"
    if [[ -n "$context" ]]; then
        formatted_message+=" [$context]"
    fi
    formatted_message+=" $message"
    
    # 输出到控制台和文件
    echo -e "$formatted_message" | tee -a "$log_file" 2>/dev/null || echo "$formatted_message"
}
EOF
    
    log_success "日志函数重构完成"
}

# 重构验证函数
refactor_validation_functions() {
    log_info "重构验证函数..."
    
    # 创建统一的验证框架
    cat > /tmp/unified_validation.sh << 'EOF'
# 统一的验证框架
unified_validate() {
    local value="$1"
    local type="$2"
    local options="${3:-}"
    
    # 参数验证
    if [[ -z "$value" ]]; then
        log_error "验证失败: 值不能为空"
        return 1
    fi
    
    if [[ -z "$type" ]]; then
        log_error "验证失败: 类型不能为空"
        return 1
    fi
    
    # 根据类型进行验证
    case "$type" in
        "port")
            validate_port "$value" "$options"
            ;;
        "ip")
            validate_ip "$value" "$options"
            ;;
        "boolean")
            validate_boolean "$value" "$options"
            ;;
        "path")
            validate_path "$value" "$options"
            ;;
        "string")
            validate_string "$value" "$options"
            ;;
        *)
            log_warn "未知的验证类型: $type"
            return 1
            ;;
    esac
}

# 端口验证
validate_port() {
    local value="$1"
    local options="$2"
    local min_port=1
    local max_port=65535
    
    # 解析选项
    if [[ -n "$options" ]]; then
        min_port=$(echo "$options" | cut -d',' -f1)
        max_port=$(echo "$options" | cut -d',' -f2)
    fi
    
    if [[ ! $value =~ ^[0-9]+$ ]]; then
        log_error "端口验证失败: 必须是数字"
        return 1
    fi
    
    if [[ $value -lt $min_port || $value -gt $max_port ]]; then
        log_error "端口验证失败: 必须在 $min_port-$max_port 范围内"
        return 1
    fi
    
    return 0
}

# IP验证
validate_ip() {
    local value="$1"
    local options="$2"
    
    # IPv4验证
    if [[ $value =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        local IFS='.'
        local -a octets=($value)
        for octet in "${octets[@]}"; do
            if [[ $octet -gt 255 ]]; then
                log_error "IP验证失败: 八位字节值超出范围"
                return 1
            fi
        done
        return 0
    fi
    
    # IPv6验证（简化）
    if [[ $value =~ ^[0-9a-fA-F:]+$ ]]; then
        return 0
    fi
    
    log_error "IP验证失败: 无效的IP格式"
    return 1
}

# 布尔值验证
validate_boolean() {
    local value="$1"
    local options="$2"
    
    if [[ $value =~ ^(true|false|yes|no|1|0|on|off)$ ]]; then
        return 0
    fi
    
    log_error "布尔值验证失败: 必须是 true/false/yes/no/1/0/on/off"
    return 1
}

# 路径验证
validate_path() {
    local value="$1"
    local options="$2"
    
    if [[ $value =~ ^/ ]]; then
        return 0
    fi
    
    log_error "路径验证失败: 必须是绝对路径"
    return 1
}

# 字符串验证
validate_string() {
    local value="$1"
    local options="$2"
    local min_length=0
    local max_length=1000
    
    # 解析选项
    if [[ -n "$options" ]]; then
        min_length=$(echo "$options" | cut -d',' -f1)
        max_length=$(echo "$options" | cut -d',' -f2)
    fi
    
    local length=${#value}
    if [[ $length -lt $min_length || $length -gt $max_length ]]; then
        log_error "字符串验证失败: 长度必须在 $min_length-$max_length 范围内"
        return 1
    fi
    
    return 0
}
EOF
    
    log_success "验证函数重构完成"
}

# 重构执行函数
refactor_execution_functions() {
    log_info "重构执行函数..."
    
    # 创建统一的执行框架
    cat > /tmp/unified_execution.sh << 'EOF'
# 统一的执行框架
unified_execute() {
    local command="$1"
    local description="${2:-执行命令}"
    local options="${3:-}"
    local timeout=30
    local allow_failure=false
    local use_cache=false
    
    # 参数验证
    if [[ -z "$command" ]]; then
        log_error "执行失败: 命令不能为空"
        return 1
    fi
    
    # 解析选项
    if [[ -n "$options" ]]; then
        timeout=$(echo "$options" | cut -d',' -f1)
        allow_failure=$(echo "$options" | cut -d',' -f2)
        use_cache=$(echo "$options" | cut -d',' -f3)
    fi
    
    # 使用缓存执行
    if [[ "$use_cache" == "true" ]]; then
        local cache_key="exec_$(echo "$command" | md5sum | cut -d' ' -f1)"
        cached_command "$cache_key" "$command" 300
        return $?
    fi
    
    # 直接执行
    safe_execute "$command" "$description" "$allow_failure" "$timeout"
    return $?
}
EOF
    
    log_success "执行函数重构完成"
}

# 重构缓存函数
refactor_cache_functions() {
    log_info "重构缓存函数..."
    
    # 创建统一的缓存框架
    cat > /tmp/unified_cache.sh << 'EOF'
# 统一的缓存框架
unified_cache() {
    local action="$1"
    local key="$2"
    local value="${3:-}"
    local ttl="${4:-300}"
    
    # 参数验证
    if [[ -z "$action" || -z "$key" ]]; then
        log_error "缓存操作失败: 操作和键不能为空"
        return 1
    fi
    
    case "$action" in
        "get")
            echo "${CACHE[$key]}"
            ;;
        "set")
            if [[ -z "$value" ]]; then
                log_error "缓存设置失败: 值不能为空"
                return 1
            fi
            CACHE[$key]="$value"
            CACHE_TIMES[$key]=$(date +%s)
            ;;
        "delete")
            unset CACHE[$key]
            unset CACHE_TIMES[$key]
            ;;
        "exists")
            [[ -n "${CACHE[$key]}" ]]
            ;;
        "clear")
            clear_cache
            ;;
        *)
            log_error "未知的缓存操作: $action"
            return 1
            ;;
    esac
}
EOF
    
    log_success "缓存函数重构完成"
}

# =============================================================================
# 参数验证增强
# =============================================================================

# 增强的参数验证函数
enhanced_parameter_validation() {
    local function_name="$1"
    local parameters=("${@:2}")
    
    log_debug "验证函数 '$function_name' 的参数: ${parameters[*]}"
    
    # 检查参数数量
    local expected_count=$(get_function_parameter_count "$function_name")
    local actual_count=${#parameters[@]}
    
    if [[ $actual_count -lt $expected_count ]]; then
        log_error "函数 '$function_name' 参数不足: 期望 $expected_count，实际 $actual_count"
        return 1
    fi
    
    # 验证每个参数
    for i in "${!parameters[@]}"; do
        local param="${parameters[$i]}"
        local param_type=$(get_function_parameter_type "$function_name" $i)
        
        if ! validate_parameter_type "$param" "$param_type"; then
            log_error "函数 '$function_name' 参数 $((i+1)) 类型验证失败: 期望 $param_type，实际值 '$param'"
            return 1
        fi
    done
    
    return 0
}

# 获取函数参数数量
get_function_parameter_count() {
    local function_name="$1"
    
    case "$function_name" in
        "log_with_level") echo 2 ;;
        "safe_execute") echo 4 ;;
        "cached_command") echo 4 ;;
        "validate_config_item") echo 3 ;;
        "load_config") echo 1 ;;
        *) echo 0 ;;
    esac
}

# 获取函数参数类型
get_function_parameter_type() {
    local function_name="$1"
    local param_index="$2"
    
    case "$function_name" in
        "log_with_level")
            case $param_index in
                0) echo "string" ;;
                1) echo "string" ;;
            esac
            ;;
        "safe_execute")
            case $param_index in
                0) echo "string" ;;
                1) echo "string" ;;
                2) echo "boolean" ;;
                3) echo "number" ;;
            esac
            ;;
        "cached_command")
            case $param_index in
                0) echo "string" ;;
                1) echo "string" ;;
                2) echo "number" ;;
                3) echo "boolean" ;;
            esac
            ;;
        "validate_config_item")
            case $param_index in
                0) echo "string" ;;
                1) echo "string" ;;
                2) echo "string" ;;
            esac
            ;;
        "load_config")
            case $param_index in
                0) echo "path" ;;
            esac
            ;;
    esac
}

# 验证参数类型
validate_parameter_type() {
    local value="$1"
    local type="$2"
    
    case "$type" in
        "string")
            [[ -n "$value" ]]
            ;;
        "number")
            [[ $value =~ ^[0-9]+$ ]]
            ;;
        "boolean")
            [[ $value =~ ^(true|false|yes|no|1|0)$ ]]
            ;;
        "path")
            [[ $value =~ ^/ ]]
            ;;
        *)
            true
            ;;
    esac
}

# =============================================================================
# 函数返回值标准化
# =============================================================================

# 标准化返回值
standardized_return() {
    local success="$1"
    local message="${2:-}"
    local data="${3:-}"
    local exit_code="${4:-0}"
    
    if [[ "$success" == "true" ]]; then
        if [[ -n "$data" ]]; then
            echo "$data"
        fi
        return 0
    else
        if [[ -n "$message" ]]; then
            log_error "$message"
        fi
        return "${exit_code:-1}"
    fi
}

# 函数执行包装器
function_wrapper() {
    local function_name="$1"
    local parameters=("${@:2}")
    
    # 参数验证
    if ! enhanced_parameter_validation "$function_name" "${parameters[@]}"; then
        return 1
    fi
    
    # 执行函数
    local start_time=$(date +%s%3N 2>/dev/null || date +%s)
    local result
    local exit_code
    
    if result=$("$function_name" "${parameters[@]}" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    local end_time=$(date +%s%3N 2>/dev/null || date +%s)
    local execution_time=$((end_time - start_time))
    
    # 记录执行信息
    log_debug "函数 '$function_name' 执行完成: 退出码=$exit_code, 耗时=${execution_time}ms"
    
    # 返回结果
    if [[ $exit_code -eq 0 ]]; then
        echo "$result"
        return 0
    else
        log_error "函数 '$function_name' 执行失败: $result"
        return $exit_code
    fi
}

# 导出函数
export -f refactor_similar_functions enhanced_parameter_validation standardized_return function_wrapper
