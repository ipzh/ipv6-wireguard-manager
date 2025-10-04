#!/bin/bash
# modules/module_deduplication.sh

# 模块去重和整合工具
# 解决模块间功能重复问题

# Source common functions
if [ -f "${IPV6WGM_ROOT_DIR}/modules/common_functions.sh" ]; then
    source "${IPV6WGM_ROOT_DIR}/modules/common_functions.sh"
elif [ -f "./modules/common_functions.sh" ]; then
    source "./modules/common_functions.sh"
else
    echo "Error: common_functions.sh not found!"
    exit 1
fi

# ================================================================
# 模块去重和整合功能
# ================================================================

# 检测重复函数
detect_duplicate_functions() {
    log_info "检测重复函数..."
    
    local duplicate_functions=()
    local function_locations=()
    
    # 扫描所有模块文件
    for module_file in "${IPV6WGM_MODULES_DIR}"/*.sh; do
        if [[ -f "$module_file" ]]; then
            local module_name=$(basename "$module_file" .sh)
            log_debug "扫描模块: $module_name"
            
            # 提取函数定义
            while IFS= read -r line; do
                if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\([[:space:]]*\)[[:space:]]*\{ ]]; then
                    local func_name="${BASH_REMATCH[1]}"
                    function_locations+=("$func_name:$module_name")
                fi
            done < "$module_file"
        fi
    done
    
    # 检测重复
    local seen_functions=()
    for location in "${function_locations[@]}"; do
        local func_name="${location%%:*}"
        local module_name="${location##*:}"
        
        if [[ " ${seen_functions[*]} " =~ " $func_name " ]]; then
            duplicate_functions+=("$func_name")
            log_warn "发现重复函数: $func_name (在模块: $module_name)"
        else
            seen_functions+=("$func_name")
        fi
    done
    
    if [[ ${#duplicate_functions[@]} -gt 0 ]]; then
        log_error "发现 ${#duplicate_functions[@]} 个重复函数"
        return 1
    else
        log_success "未发现重复函数"
        return 0
    fi
}

# 整合公共函数
consolidate_common_functions() {
    log_info "整合公共函数..."
    
    local consolidated_file="${IPV6WGM_MODULES_DIR}/consolidated_common_functions.sh"
    
    # 创建整合文件
    cat > "$consolidated_file" << 'EOF'
#!/bin/bash
# modules/consolidated_common_functions.sh

# 整合的公共函数库
# 仅统一引用公共函数，避免重复定义

# Source common functions
if [ -f "${IPV6WGM_ROOT_DIR}/modules/common_functions.sh" ]; then
    source "${IPV6WGM_ROOT_DIR}/modules/common_functions.sh"
elif [ -f "./modules/common_functions.sh" ]; then
    source "./modules/common_functions.sh"
else
    echo "Error: common_functions.sh not found!"
    exit 1
fi

# 日志函数统一由 modules/common_functions.sh 提供

# ================================================================
# 统一的错误处理函数
# ================================================================

# 统一的错误处理函数（避免重复定义）
unified_handle_error() {
    local error_code="$1"
    local error_message="$2"
    local context="${3:-unknown}"
    local line_number="${4:-$LINENO}"
    
    # 记录错误
    log_error "[错误码: $error_code] $error_message (上下文: $context, 行号: $line_number)"
    
    # 保存错误到错误日志
    local error_log_file="${IPV6WGM_LOG_DIR}/error.log"
    mkdir -p "$(dirname "$error_log_file")" 2>/dev/null || true
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] [${FUNCNAME[1]}] [Line: $line_number] $error_message" >> "$error_log_file" 2>/dev/null || true
    
    return "$error_code"
}

# ================================================================
# 统一的路径转换函数
# ================================================================

# 统一的路径转换函数（避免重复定义）
unified_convert_path() {
    local path="$1"
    local target_type="${2:-native}"
    
    if [[ -z "$path" ]]; then
        return 1
    fi
    
    # 检测Windows环境
    local windows_env=""
    if [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ -n "${WSLENV:-}" ]] || \
       ([[ -f /proc/version ]] && grep -qi microsoft /proc/version); then
        windows_env="wsl"
    elif [[ "$OSTYPE" == "msys" ]]; then
        windows_env="msys"
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        windows_env="cygwin"
    elif [[ -n "${MSYSTEM:-}" ]] && [[ "$MSYSTEM" =~ ^MINGW ]]; then
        windows_env="gitbash"
    fi
    
    case "$windows_env" in
        "wsl")
            echo "$path"
            ;;
        "msys"|"cygwin"|"gitbash")
            if command -v cygpath >/dev/null 2>&1; then
                case "$target_type" in
                    "windows") cygpath -w "$path" ;;
                    "unix") cygpath -u "$path" ;;
                    *) cygpath "$path" ;;
                esac
            else
                echo "$path" | sed 's|/|\\|g'
            fi
            ;;
        *)
            echo "$path"
            ;;
    esac
}

# ================================================================
# 统一的权限设置函数
# ================================================================

# 统一的权限设置函数（Windows兼容）
unified_set_permissions() {
    local target_path="$1"
    local mode="$2"
    local user="${3:-root}"
    local group="${4:-root}"
    
    if [[ ! -e "$target_path" ]]; then
        log_warn "目标路径不存在: $target_path"
        return 1
    fi
    
    # 检测Windows环境
    local is_windows=false
    if [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ -n "${WSLENV:-}" ]] || \
       ([[ -f /proc/version ]] && grep -qi microsoft /proc/version) || \
       [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        is_windows=true
    fi
    
    if [[ "$is_windows" == "true" ]]; then
        # Windows环境下的权限设置
        case "$OSTYPE" in
            "msys"|"cygwin")
                chmod -R "$mode" "$target_path" 2>/dev/null || true
                ;;
            *)
                # WSL环境
                chown -R "${user}:${group}" "$target_path" 2>/dev/null || true
                chmod -R "$mode" "$target_path" 2>/dev/null || true
                ;;
        esac
    else
        # Linux环境
        chown -R "${user}:${group}" "$target_path" 2>/dev/null || true
        chmod -R "$mode" "$target_path" 2>/dev/null || true
    fi
    
    log_info "已设置 $target_path 的权限（$mode, ${user}:${group}）"
    return 0
}

# ================================================================
# 统一的命令执行函数
# ================================================================

# 统一的命令执行函数（Windows兼容）
unified_execute_command() {
    local command="$1"
    local description="$2"
    local ignore_errors="${3:-false}"
    
    log_info "执行: $description"
    log_debug "命令: $command"
    
    # 执行命令
    if eval "$command"; then
        log_success "$description 完成"
        return 0
    else
        local exit_code=$?
        if [[ "$ignore_errors" == "true" ]]; then
            log_warn "$description 失败，但忽略错误 (退出码: $exit_code)"
            return 0
        else
            log_error "$description 失败 (退出码: $exit_code)"
            return $exit_code
        fi
    fi
}

# ================================================================
# 导出函数
# ================================================================

# 导出所有函数
export -f unified_handle_error
export -f unified_convert_path
export -f unified_set_permissions
export -f unified_execute_command

EOF
    
    log_success "公共函数已整合到: $consolidated_file"
    return 0
}

# 清理重复模块
cleanup_duplicate_modules() {
    log_info "清理重复模块..."
    
    local modules_to_remove=()
    
    # 检查是否有重复的Windows兼容性模块
    local windows_modules=("windows_compatibility.sh" "enhanced_windows_compatibility.sh" "enhanced_windows_support.sh")
    local keep_module="unified_windows_compatibility.sh"
    
    for module in "${windows_modules[@]}"; do
        if [[ -f "${IPV6WGM_MODULES_DIR}/$module" ]] && [[ "$module" != "$keep_module" ]]; then
            modules_to_remove+=("$module")
            log_warn "标记删除重复模块: $module"
        fi
    done
    
    # 检查是否有重复的错误处理模块
    local error_modules=("error_handling.sh" "advanced_error_handling.sh" "enhanced_error_handling.sh" "unified_error_handling.sh")
    local keep_error_module="unified_error_handling.sh"
    
    for module in "${error_modules[@]}"; do
        if [[ -f "${IPV6WGM_MODULES_DIR}/$module" ]] && [[ "$module" != "$keep_error_module" ]]; then
            modules_to_remove+=("$module")
            log_warn "标记删除重复模块: $module"
        fi
    done
    
    # 删除重复模块
    for module in "${modules_to_remove[@]}"; do
        if [[ -f "${IPV6WGM_MODULES_DIR}/$module" ]]; then
            mv "${IPV6WGM_MODULES_DIR}/$module" "${IPV6WGM_MODULES_DIR}/$module.backup"
            log_success "已备份重复模块: $module -> $module.backup"
        fi
    done
    
    log_success "重复模块清理完成"
    return 0
}

# 生成模块依赖图
generate_module_dependency_graph() {
    log_info "生成模块依赖图..."
    
    local graph_file="${IPV6WGM_LOG_DIR}/module_dependency_graph.dot"
    
    cat > "$graph_file" << 'EOF'
digraph ModuleDependencies {
    rankdir=TB;
    node [shape=box, style=filled, fillcolor=lightblue];
    
    // 核心模块
    "common_functions.sh" [fillcolor=lightgreen];
    "consolidated_common_functions.sh" [fillcolor=lightgreen];
    
    // 系统模块
    "unified_windows_compatibility.sh" [fillcolor=lightyellow];
    "enhanced_system_compatibility.sh" [fillcolor=lightyellow];
    
    // 功能模块
    "wireguard_config.sh" [fillcolor=lightcoral];
    "bird_config.sh" [fillcolor=lightcoral];
    "firewall_management.sh" [fillcolor=lightcoral];
    
    // 管理模块
    "config_manager.sh" [fillcolor=lightpink];
    "module_loader.sh" [fillcolor=lightpink];
    
    // 依赖关系
    "consolidated_common_functions.sh" -> "common_functions.sh";
    "unified_windows_compatibility.sh" -> "common_functions.sh";
    "enhanced_system_compatibility.sh" -> "common_functions.sh";
    "wireguard_config.sh" -> "common_functions.sh";
    "bird_config.sh" -> "common_functions.sh";
    "firewall_management.sh" -> "common_functions.sh";
    "config_manager.sh" -> "common_functions.sh";
    "module_loader.sh" -> "common_functions.sh";
}
EOF
    
    log_success "模块依赖图已生成: $graph_file"
    return 0
}

# 主函数
main() {
    log_info "开始模块去重和整合..."
    
    # 检测重复函数
    if ! detect_duplicate_functions; then
        log_warn "发现重复函数，继续整合..."
    fi
    
    # 整合公共函数
    consolidate_common_functions
    
    # 清理重复模块
    cleanup_duplicate_modules
    
    # 生成依赖图
    generate_module_dependency_graph
    
    log_success "模块去重和整合完成"
    return 0
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

# 导出函数
export -f detect_duplicate_functions
export -f consolidate_common_functions
export -f cleanup_duplicate_modules
export -f generate_module_dependency_graph
