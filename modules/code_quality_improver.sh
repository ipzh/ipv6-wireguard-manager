#!/bin/bash

# 代码质量改进模块
# 提供重复代码检测、错误处理优化、日志记录增强等功能

# 导入公共函数
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
fi

# =============================================================================
# 代码质量配置
# =============================================================================

# 重复代码检测配置
declare -A IPV6WGM_DUPLICATE_FUNCTIONS=()
declare -A IPV6WGM_FUNCTION_USAGE=()
declare -A IPV6WGM_CODE_PATTERNS=()

# 错误处理配置
declare -A IPV6WGM_ERROR_HANDLERS=()
declare -A IPV6WGM_ERROR_COUNTS=()
IPV6WGM_MAX_ERROR_COUNT=10

# 日志记录配置
declare -A IPV6WGM_LOG_LEVELS=(
    ["DEBUG"]="0"
    ["INFO"]="1"
    ["WARN"]="2"
    ["ERROR"]="3"
    ["FATAL"]="4"
)
IPV6WGM_CURRENT_LOG_LEVEL="${IPV6WGM_LOG_LEVEL:-INFO}"

# =============================================================================
# 重复代码检测函数
# =============================================================================

# 检测重复函数
detect_duplicate_functions() {
    local file_path="$1"
    local functions=()
    local duplicates=()
    
    if [[ ! -f "$file_path" ]]; then
        log_error "文件不存在: $file_path"
        return 1
    fi
    
    # 提取所有函数定义
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\([[:space:]]*\)[[:space:]]*\{ ]]; then
            local func_name="${BASH_REMATCH[1]}"
            functions+=("$func_name")
        fi
    done < "$file_path"
    
    # 检测重复函数
    local seen=()
    for func in "${functions[@]}"; do
        if [[ " ${seen[*]} " =~ " $func " ]]; then
            duplicates+=("$func")
        else
            seen+=("$func")
        fi
    done
    
    # 记录重复函数
    if [[ ${#duplicates[@]} -gt 0 ]]; then
        log_warn "发现重复函数: ${duplicates[*]}"
        IPV6WGM_DUPLICATE_FUNCTIONS["$file_path"]="${duplicates[*]}"
        return 1
    else
        log_success "未发现重复函数: $file_path"
        return 0
    fi
}

# 检测重复代码块
detect_duplicate_code_blocks() {
    local file_path="$1"
    local min_lines="${2:-5}"  # 最小代码块行数
    
    if [[ ! -f "$file_path" ]]; then
        log_error "文件不存在: $file_path"
        return 1
    fi
    
    local lines=()
    local duplicates=()
    
    # 读取文件内容
    mapfile -t lines < "$file_path"
    
    # 检测重复代码块
    for ((i=0; i<${#lines[@]}-min_lines; i++)); do
        local block=()
        for ((j=0; j<min_lines; j++)); do
            block+=("${lines[i+j]}")
        done
        
        # 检查是否有重复的代码块
        for ((k=i+min_lines; k<${#lines[@]}-min_lines; k++)); do
            local match=true
            for ((l=0; l<min_lines; l++)); do
                if [[ "${lines[k+l]}" != "${block[l]}" ]]; then
                    match=false
                    break
                fi
            done
            
            if [[ "$match" == true ]]; then
                duplicates+=("行 $((i+1))-$((i+min_lines)) 与 行 $((k+1))-$((k+min_lines)) 重复")
            fi
        done
    done
    
    # 记录重复代码块
    if [[ ${#duplicates[@]} -gt 0 ]]; then
        log_warn "发现重复代码块:"
        for dup in "${duplicates[@]}"; do
            log_warn "  $dup"
        done
        IPV6WGM_CODE_PATTERNS["$file_path"]="${duplicates[*]}"
        return 1
    else
        log_success "未发现重复代码块: $file_path"
        return 0
    fi
}

# 提取公共函数
extract_common_functions() {
    local file_path="$1"
    local output_file="${2:-common_functions_extracted.sh}"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "文件不存在: $file_path"
        return 1
    fi
    
    local common_functions=()
    local function_patterns=(
        "log_[a-zA-Z_]+"
        "check_[a-zA-Z_]+"
        "validate_[a-zA-Z_]+"
        "get_[a-zA-Z_]+"
        "set_[a-zA-Z_]+"
        "is_[a-zA-Z_]+"
        "has_[a-zA-Z_]+"
    )
    
    # 提取公共函数
    for pattern in "${function_patterns[@]}"; do
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*($pattern)[[:space:]]*\([[:space:]]*\)[[:space:]]*\{ ]]; then
                local func_name="${BASH_REMATCH[1]}"
                common_functions+=("$func_name")
            fi
        done < "$file_path"
    done
    
    # 生成公共函数文件
    {
        echo "#!/bin/bash"
        echo "# 提取的公共函数"
        echo "# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        
        for func in "${common_functions[@]}"; do
            echo "# 提取函数: $func"
            extract_function "$file_path" "$func"
            echo ""
        done
    } > "$output_file"
    
    log_success "公共函数已提取到: $output_file"
    echo "${#common_functions[@]}"
}

# 提取单个函数
extract_function() {
    local file_path="$1"
    local func_name="$2"
    local in_function=false
    local brace_count=0
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*${func_name}[[:space:]]*\([[:space:]]*\)[[:space:]]*\{ ]]; then
            in_function=true
            brace_count=1
            echo "$line"
        elif [[ "$in_function" == true ]]; then
            echo "$line"
            
            # 计算大括号
            local open_braces=$(echo "$line" | grep -o '{' | wc -l)
            local close_braces=$(echo "$line" | grep -o '}' | wc -l)
            brace_count=$((brace_count + open_braces - close_braces))
            
            if [[ $brace_count -eq 0 ]]; then
                break
            fi
        fi
    done < "$file_path"
}

# =============================================================================
# 错误处理优化函数
# =============================================================================

# 增强错误处理
enhanced_error_handling() {
    local function_name="$1"
    local error_code="$2"
    local error_message="$3"
    local context="${4:-}"
    
    # 记录错误
    local error_key="${function_name}_${error_code}"
    IPV6WGM_ERROR_COUNTS["$error_key"]=$((${IPV6WGM_ERROR_COUNTS["$error_key"]:-0} + 1))
    
    # 检查错误频率
    if [[ ${IPV6WGM_ERROR_COUNTS["$error_key"]} -gt $IPV6WGM_MAX_ERROR_COUNT ]]; then
        log_error "错误频率过高: $function_name (错误码: $error_code)"
        log_error "已发生 ${IPV6WGM_ERROR_COUNTS["$error_key"]} 次错误"
        return 1
    fi
    
    # 记录详细错误信息
    log_error "函数: $function_name"
    log_error "错误码: $error_code"
    log_error "错误信息: $error_message"
    if [[ -n "$context" ]]; then
        log_error "上下文: $context"
    fi
    log_error "错误计数: ${IPV6WGM_ERROR_COUNTS["$error_key"]}"
    
    return $error_code
}

# 设置错误处理器
set_error_handler() {
    local function_name="$1"
    local handler_function="$2"
    
    if [[ -n "$handler_function" ]] && command -v "$handler_function" >/dev/null 2>&1; then
        IPV6WGM_ERROR_HANDLERS["$function_name"]="$handler_function"
        log_debug "错误处理器已设置: $function_name -> $handler_function"
    else
        log_error "无效的错误处理器: $handler_function"
        return 1
    fi
}

# 调用错误处理器
call_error_handler() {
    local function_name="$1"
    local error_code="$2"
    local error_message="$3"
    
    local handler="${IPV6WGM_ERROR_HANDLERS[$function_name]}"
    if [[ -n "$handler" ]]; then
        log_debug "调用错误处理器: $handler"
        "$handler" "$function_name" "$error_code" "$error_message"
    fi
}

# 重置错误计数
reset_error_counts() {
    local function_name="$1"
    
    if [[ -n "$function_name" ]]; then
        local error_key="${function_name}_*"
        for key in "${!IPV6WGM_ERROR_COUNTS[@]}"; do
            if [[ "$key" =~ ^${function_name}_ ]]; then
                unset IPV6WGM_ERROR_COUNTS["$key"]
            fi
        done
        log_debug "错误计数已重置: $function_name"
    else
        IPV6WGM_ERROR_COUNTS=()
        log_debug "所有错误计数已重置"
    fi
}

# =============================================================================
# 日志记录增强函数
# =============================================================================

# 设置日志级别
set_log_level() {
    local level="$1"
    
    if [[ -n "${IPV6WGM_LOG_LEVELS[$level]:-}" ]]; then
        IPV6WGM_CURRENT_LOG_LEVEL="$level"
        log_debug "日志级别已设置为: $level"
    else
        log_error "无效的日志级别: $level"
        log_info "可用级别: ${!IPV6WGM_LOG_LEVELS[*]}"
        return 1
    fi
}

# 检查日志级别
should_log() {
    local level="$1"
    local current_level_value="${IPV6WGM_LOG_LEVELS[$IPV6WGM_CURRENT_LOG_LEVEL]}"
    local message_level_value="${IPV6WGM_LOG_LEVELS[$level]}"
    
    [[ $message_level_value -ge $current_level_value ]]
}

# 增强日志函数
enhanced_log() {
    local level="$1"
    local message="$2"
    local context="${3:-}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if should_log "$level"; then
        local color=""
        case "$level" in
            "DEBUG") color='\033[0;35m' ;;
            "INFO")  color='\033[0;34m' ;;
            "WARN")  color='\033[1;33m' ;;
            "ERROR") color='\033[0;31m' ;;
            "FATAL") color='\033[1;31m' ;;
        esac
        
        local reset='\033[0m'
        local prefix="[$timestamp] [$level]"
        
        if [[ -n "$context" ]]; then
            echo -e "${color}${prefix} [${context}] ${message}${reset}"
        else
            echo -e "${color}${prefix} ${message}${reset}"
        fi
    fi
}

# 结构化日志
structured_log() {
    local level="$1"
    local event="$2"
    local data="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if should_log "$level"; then
        local log_entry=$(cat << EOF
{
    "timestamp": "$timestamp",
    "level": "$level",
    "event": "$event",
    "data": "$data"
}
EOF
        )
        echo "$log_entry"
    fi
}

# 性能日志
performance_log() {
    local function_name="$1"
    local start_time="$2"
    local end_time="$3"
    local additional_info="${4:-}"
    
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    
    structured_log "INFO" "performance" "function=$function_name,duration=${duration}s,info=$additional_info"
}

# =============================================================================
# 代码分析函数
# =============================================================================

# 分析代码复杂度
analyze_code_complexity() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "文件不存在: $file_path"
        return 1
    fi
    
    local total_lines=0
    local function_count=0
    local if_count=0
    local for_count=0
    local while_count=0
    local case_count=0
    
    while IFS= read -r line; do
        ((total_lines++))
        
        # 统计控制结构
        if [[ "$line" =~ ^[[:space:]]*if[[:space:]] ]]; then
            ((if_count++))
        elif [[ "$line" =~ ^[[:space:]]*for[[:space:]] ]]; then
            ((for_count++))
        elif [[ "$line" =~ ^[[:space:]]*while[[:space:]] ]]; then
            ((while_count++))
        elif [[ "$line" =~ ^[[:space:]]*case[[:space:]] ]]; then
            ((case_count++))
        elif [[ "$line" =~ ^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\([[:space:]]*\)[[:space:]]*\{ ]]; then
            ((function_count++))
        fi
    done < "$file_path"
    
    # 计算复杂度指标
    local control_structures=$((if_count + for_count + while_count + case_count))
    local complexity_ratio=$((control_structures * 100 / total_lines))
    
    echo "=== 代码复杂度分析: $file_path ==="
    echo "总行数: $total_lines"
    echo "函数数: $function_count"
    echo "if语句: $if_count"
    echo "for循环: $for_count"
    echo "while循环: $while_count"
    echo "case语句: $case_count"
    echo "控制结构总数: $control_structures"
    echo "复杂度比例: ${complexity_ratio}%"
    
    # 复杂度评估
    if [[ $complexity_ratio -lt 20 ]]; then
        log_success "代码复杂度: 低"
    elif [[ $complexity_ratio -lt 40 ]]; then
        log_warn "代码复杂度: 中等"
    else
        log_error "代码复杂度: 高"
    fi
}

# 分析函数使用情况
analyze_function_usage() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "文件不存在: $file_path"
        return 1
    fi
    
    local functions=()
    local usage_count=()
    
    # 提取函数定义
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\([[:space:]]*\)[[:space:]]*\{ ]]; then
            local func_name="${BASH_REMATCH[1]}"
            functions+=("$func_name")
            usage_count+=("0")
        fi
    done < "$file_path"
    
    # 统计函数使用次数
    for ((i=0; i<${#functions[@]}; i++)); do
        local func_name="${functions[i]}"
        local count=$(grep -c "$func_name" "$file_path" 2>/dev/null || echo "0")
        usage_count[i]="$count"
    done
    
    echo "=== 函数使用情况分析: $file_path ==="
    for ((i=0; i<${#functions[@]}; i++)); do
        local func_name="${functions[i]}"
        local count="${usage_count[i]}"
        echo "$func_name: $count 次使用"
        
        if [[ $count -eq 1 ]]; then
            log_warn "函数 $func_name 只使用一次，考虑内联"
        elif [[ $count -gt 10 ]]; then
            log_success "函数 $func_name 使用频繁，考虑优化"
        fi
    done
}

# =============================================================================
# 代码重构建议函数
# =============================================================================

# 生成重构建议
generate_refactoring_suggestions() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "文件不存在: $file_path"
        return 1
    fi
    
    echo "=== 重构建议: $file_path ==="
    
    # 检测重复函数
    if ! detect_duplicate_functions "$file_path"; then
        echo "建议: 合并重复函数"
    fi
    
    # 检测重复代码块
    if ! detect_duplicate_code_blocks "$file_path"; then
        echo "建议: 提取重复代码块为函数"
    fi
    
    # 分析函数使用情况
    analyze_function_usage "$file_path"
    
    # 分析代码复杂度
    analyze_code_complexity "$file_path"
}

# =============================================================================
# 统计和监控函数
# =============================================================================

# 获取代码质量统计
get_code_quality_stats() {
    echo "=== 代码质量统计 ==="
    echo "重复函数数: ${#IPV6WGM_DUPLICATE_FUNCTIONS[@]}"
    echo "错误处理器数: ${#IPV6WGM_ERROR_HANDLERS[@]}"
    echo "当前日志级别: $IPV6WGM_CURRENT_LOG_LEVEL"
    echo "错误计数总数: ${#IPV6WGM_ERROR_COUNTS[@]}"
    
    echo
    echo "=== 错误统计 ==="
    for key in "${!IPV6WGM_ERROR_COUNTS[@]}"; do
        echo "$key: ${IPV6WGM_ERROR_COUNTS[$key]} 次"
    done
}

# =============================================================================
# 初始化函数
# =============================================================================

# 初始化代码质量改进模块
init_code_quality_improver() {
    log_info "初始化代码质量改进模块..."
    
    # 设置默认日志级别
    set_log_level "${IPV6WGM_LOG_LEVEL:-INFO}"
    
    # 设置默认错误处理器
    set_error_handler "default" "enhanced_error_handling"
    
    log_success "代码质量改进模块初始化完成"
}

# 导出函数
export -f detect_duplicate_functions detect_duplicate_code_blocks
export -f extract_common_functions extract_function
export -f enhanced_error_handling set_error_handler call_error_handler reset_error_counts
export -f set_log_level should_log enhanced_log structured_log performance_log
export -f analyze_code_complexity analyze_function_usage generate_refactoring_suggestions
export -f get_code_quality_stats init_code_quality_improver

# 如果直接执行此脚本，则初始化
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_code_quality_improver
fi
