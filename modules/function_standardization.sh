#!/bin/bash
# modules/function_standardization.sh

# 函数标准化工具
# 统一所有必须的功能和函数，确保一致性

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
# 核心必须函数定义
# ================================================================

# 确保所有核心函数都存在并统一
ensure_core_functions() {
    log_info "确保核心函数统一..."
    
    # 1. 日志函数
    ensure_log_functions
    
    # 2. 错误处理函数
    ensure_error_handling_functions
    
    # 3. 系统检测函数
    ensure_system_detection_functions
    
    # 4. 配置管理函数
    ensure_config_functions
    
    # 5. 模块管理函数
    ensure_module_functions
    
    # 6. 路径管理函数
    ensure_path_functions
    
    # 7. 权限管理函数
    ensure_permission_functions
    
    # 8. 网络管理函数
    ensure_network_functions
    
    log_success "核心函数统一完成"
}

# 确保日志函数统一（改为依赖公共库，不再本地定义）
ensure_log_functions() {
    # 日志函数由 modules/common_functions.sh 提供，这里仅校验存在
    if ! command -v log_info >/dev/null 2>&1; then
        if [ -f "${IPV6WGM_ROOT_DIR}/modules/common_functions.sh" ]; then
            source "${IPV6WGM_ROOT_DIR}/modules/common_functions.sh"
        elif [ -f "./modules/common_functions.sh" ]; then
            source "./modules/common_functions.sh"
        fi
    fi
    return 0
}

# 确保错误处理函数统一
ensure_error_handling_functions() {
    # 统一错误处理函数
    if ! command -v handle_error >/dev/null 2>&1; then
        handle_error() {
            local error_code="$1"
            local error_message="$2"
            local context="${3:-unknown}"
            local line_number="${4:-$LINENO}"
            
            log_error "[错误码: $error_code] $error_message (上下文: $context, 行号: $line_number)"
            
            # 保存错误到日志
            local error_log_file="${IPV6WGM_LOG_DIR}/error.log"
            mkdir -p "$(dirname "$error_log_file")" 2>/dev/null || true
            echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] [${FUNCNAME[1]}] [Line: $line_number] $error_message" >> "$error_log_file" 2>/dev/null || true
            
            return "$error_code"
        }
    fi
    
    # 安全执行函数
    if ! command -v safe_execute >/dev/null 2>&1; then
        safe_execute() {
            local command="$1"
            local description="$2"
            local ignore_errors="${3:-false}"
            
            log_debug "执行: $description"
            log_debug "命令: $command"
            
            if safe_execute "$command"; then
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
    fi
    
    # 导出错误处理函数
    export -f handle_error safe_execute
}

# 确保系统检测函数统一
ensure_system_detection_functions() {
    # 操作系统检测
    if ! command -v detect_os >/dev/null 2>&1; then
        detect_os() {
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                echo "$ID"
            elif [[ -f /etc/redhat-release ]]; then
                echo "rhel"
            elif [[ -f /etc/debian_version ]]; then
                echo "debian"
            else
                echo "unknown"
            fi
        }
    fi
    
    # 架构检测
    if ! command -v detect_arch >/dev/null 2>&1; then
        detect_arch() {
            uname -m
        }
    fi
    
    # 包管理器检测
    if ! command -v detect_package_manager >/dev/null 2>&1; then
        detect_package_manager() {
            if command -v apt >/dev/null 2>&1; then
                echo "apt"
            elif command -v yum >/dev/null 2>&1; then
                echo "yum"
            elif command -v dnf >/dev/null 2>&1; then
                echo "dnf"
            elif command -v pacman >/dev/null 2>&1; then
                echo "pacman"
            elif command -v zypper >/dev/null 2>&1; then
                echo "zypper"
            else
                echo "unknown"
            fi
        }
    fi
    
    # 导出系统检测函数
    export -f detect_os detect_arch detect_package_manager
}

# 确保配置管理函数统一
ensure_config_functions() {
    # 配置加载函数
    if ! command -v load_config >/dev/null 2>&1; then
        load_config() {
            local config_file="$1"
            if [[ -f "$config_file" ]]; then
                source "$config_file"
                return 0
            else
                log_error "配置文件不存在: $config_file"
                return 1
            fi
        }
    fi
    
    # 配置验证函数
    if ! command -v validate_config >/dev/null 2>&1; then
        validate_config() {
            local config_file="$1"
            if [[ ! -f "$config_file" ]]; then
                log_error "配置文件不存在: $config_file"
                return 1
            fi
            
            # 基本语法检查
            if bash -n "$config_file" 2>/dev/null; then
                log_success "配置文件语法正确: $config_file"
                return 0
            else
                log_error "配置文件语法错误: $config_file"
                return 1
            fi
        }
    fi
    
    # 配置获取函数
    if ! command -v get_config_value >/dev/null 2>&1; then
        get_config_value() {
            local key="$1"
            local default_value="${2:-}"
            local config_file="${3:-${IPV6WGM_CONFIG_DIR}/manager.conf}"
            
            if [[ -f "$config_file" ]]; then
                local value=$(grep "^${key}=" "$config_file" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
                echo "${value:-$default_value}"
            else
                echo "$default_value"
            fi
        }
    fi
    
    # 导出配置管理函数
    export -f load_config validate_config get_config_value
}

# 确保模块管理函数统一
ensure_module_functions() {
    # 模块导入函数
    if ! command -v import_module >/dev/null 2>&1; then
        import_module() {
            local module_name="$1"
            local module_path="${IPV6WGM_MODULES_DIR}/${module_name}.sh"
            
            if [[ -f "$module_path" ]]; then
                source "$module_path"
                return 0
            else
                # 尝试从多个位置查找模块
                local alt_paths=(
                    "/opt/ipv6-wireguard-manager/modules/${module_name}.sh"
                    "/usr/local/share/ipv6-wireguard-manager/modules/${module_name}.sh"
                    "$(pwd)/modules/${module_name}.sh"
                    "${IPV6WGM_SCRIPT_DIR}/modules/${module_name}.sh"
                )
                
                for alt_path in "${alt_paths[@]}"; do
                    if [[ -f "$alt_path" ]]; then
                        source "$alt_path"
                        return 0
                    fi
                done
                
                log_error "模块文件不存在: ${module_name}.sh"
                return 1
            fi
        }
    fi
    
    # 模块检查函数
    if ! command -v check_module >/dev/null 2>&1; then
        check_module() {
            local module_name="$1"
            local module_path="${IPV6WGM_MODULES_DIR}/${module_name}.sh"
            
            if [[ -f "$module_path" ]]; then
                # 检查语法
                if bash -n "$module_path" 2>/dev/null; then
                    log_success "模块语法正确: $module_name"
                    return 0
                else
                    log_error "模块语法错误: $module_name"
                    return 1
                fi
            else
                log_error "模块文件不存在: $module_name"
                return 1
            fi
        }
    fi
    
    # 导出模块管理函数
    export -f import_module check_module
}

# 确保路径管理函数统一
ensure_path_functions() {
    # 路径转换函数
    if ! command -v convert_path >/dev/null 2>&1; then
        convert_path() {
            local path="$1"
            local target_type="${2:-native}"
            
            # 检测Windows环境
            local is_windows=false
            if [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ -n "${WSLENV:-}" ]] || \
               ([[ -f /proc/version ]] && grep -qi microsoft /proc/version) || \
               [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
                is_windows=true
            fi
            
            if [[ "$is_windows" == "true" ]]; then
                case "$OSTYPE" in
                    "msys"|"cygwin")
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
            else
                echo "$path"
            fi
        }
    fi
    
    # 目录创建函数
    if ! command -v ensure_directory >/dev/null 2>&1; then
        ensure_directory() {
            local dir_path="$1"
            local mode="${2:-755}"
            
            if [[ ! -d "$dir_path" ]]; then
                if mkdir -p "$dir_path" 2>/dev/null; then
                    chmod "$mode" "$dir_path" 2>/dev/null || true
                    log_success "目录已创建: $dir_path"
                    return 0
                else
                    log_error "无法创建目录: $dir_path"
                    return 1
                fi
            else
                log_debug "目录已存在: $dir_path"
                return 0
            fi
        }
    fi
    
    # 导出路径管理函数
    export -f convert_path ensure_directory
}

# 确保权限管理函数统一
ensure_permission_functions() {
    # 权限设置函数
    if ! command -v set_permissions >/dev/null 2>&1; then
        set_permissions() {
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
            
            log_success "权限已设置: $target_path ($mode, ${user}:${group})"
            return 0
        }
    fi
    
    # 导出权限管理函数
    export -f set_permissions
}

# 确保网络管理函数统一
ensure_network_functions() {
    # 网络接口检测
    if ! command -v get_network_interfaces >/dev/null 2>&1; then
        get_network_interfaces() {
            if command -v ip >/dev/null 2>&1; then
                ip link show | grep -E "^[0-9]+:" | cut -d: -f2 | tr -d ' '
            elif command -v ifconfig >/dev/null 2>&1; then
                ifconfig -a | grep -E "^[a-zA-Z0-9]+" | cut -d: -f1
            else
                log_warn "无法检测网络接口"
                return 1
            fi
        }
    fi
    
    # IP地址检测
    if ! command -v get_ip_address >/dev/null 2>&1; then
        get_ip_address() {
            local interface="${1:-eth0}"
            if command -v ip >/dev/null 2>&1; then
                ip addr show "$interface" | grep "inet " | awk '{print $2}' | cut -d/ -f1
            elif command -v ifconfig >/dev/null 2>&1; then
                ifconfig "$interface" | grep "inet " | awk '{print $2}'
            else
                log_warn "无法获取IP地址"
                return 1
            fi
        }
    fi
    
    # 导出网络管理函数
    export -f get_network_interfaces get_ip_address
}

# ================================================================
# 函数标准化检查
# ================================================================

# 检查所有核心函数是否存在
check_core_functions() {
    log_info "检查核心函数完整性..."
    
    local missing_functions=()
    local core_functions=(
        "log_info" "log_error" "log_warn" "log_success" "log_debug"
        "handle_error" "safe_execute"
        "detect_os" "detect_arch" "detect_package_manager"
        "load_config" "validate_config" "get_config_value"
        "import_module" "check_module"
        "convert_path" "ensure_directory"
        "set_permissions"
        "get_network_interfaces" "get_ip_address"
    )
    
    for func in "${core_functions[@]}"; do
        if ! command -v "$func" >/dev/null 2>&1; then
            missing_functions+=("$func")
        fi
    done
    
    if [[ ${#missing_functions[@]} -gt 0 ]]; then
        log_error "缺少核心函数: ${missing_functions[*]}"
        return 1
    else
        log_success "所有核心函数都存在"
        return 0
    fi
}

# 生成函数标准化报告
generate_standardization_report() {
    log_info "生成函数标准化报告..."
    
    local report_file="${IPV6WGM_LOG_DIR}/function_standardization_report_$(date +%Y%m%d%H%M%S).log"
    
    {
        echo "=== IPv6 WireGuard Manager 函数标准化报告 ==="
        echo "生成时间: $(date)"
        echo "---------------------------------------"
        echo
        
        echo "--- 核心函数检查 ---"
        check_core_functions
        echo
        
        echo "--- 函数分类统计 ---"
        echo "日志函数: $(command -v log_info log_error log_warn log_success log_debug 2>/dev/null | wc -l)/5"
        echo "错误处理函数: $(command -v handle_error safe_execute 2>/dev/null | wc -l)/2"
        echo "系统检测函数: $(command -v detect_os detect_arch detect_package_manager 2>/dev/null | wc -l)/3"
        echo "配置管理函数: $(command -v load_config validate_config get_config_value 2>/dev/null | wc -l)/3"
        echo "模块管理函数: $(command -v import_module check_module 2>/dev/null | wc -l)/2"
        echo "路径管理函数: $(command -v convert_path ensure_directory 2>/dev/null | wc -l)/2"
        echo "权限管理函数: $(command -v set_permissions 2>/dev/null | wc -l)/1"
        echo "网络管理函数: $(command -v get_network_interfaces get_ip_address 2>/dev/null | wc -l)/2"
        echo
        
        echo "--- 函数导出状态 ---"
        echo "已导出的函数:"
        export -p | grep -E "declare -fx" | wc -l
        echo
        
        echo "=== 报告结束 ==="
    } | tee "$report_file"
    
    log_success "函数标准化报告已生成: $report_file"
    echo "$report_file"
    return 0
}

# ================================================================
# 主函数
# ================================================================

# 主函数
main() {
    log_info "开始函数标准化..."
    
    # 确保核心函数统一
    ensure_core_functions
    
    # 检查函数完整性
    if check_core_functions; then
        log_success "函数标准化完成"
        
        # 生成报告
        generate_standardization_report
        
        return 0
    else
        log_error "函数标准化失败"
        return 1
    fi
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

# 导出函数
export -f ensure_core_functions
export -f check_core_functions
export -f generate_standardization_report
