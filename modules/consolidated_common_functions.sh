#!/bin/bash
# modules/consolidated_common_functions.sh

# 整合的公共函数库
# 包含所有模块的公共函数，避免重复定义

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
# 统一的日志函数
# ================================================================

# 确保日志函数存在
ensure_log_functions() {
    # 如果log_info不存在，定义它
    if ! command -v log_info >/dev/null 2>&1; then
        log_info() {
            echo -e "${BLUE}[INFO]${NC} $1"
        }
    fi
    
    if ! command -v log_error >/dev/null 2>&1; then
        log_error() {
            echo -e "${RED}[ERROR]${NC} $1" >&2
        }
    fi
    
    if ! command -v log_warn >/dev/null 2>&1; then
        log_warn() {
            echo -e "${YELLOW}[WARN]${NC} $1"
        }
    fi
    
    if ! command -v log_success >/dev/null 2>&1; then
        log_success() {
            echo -e "${GREEN}[SUCCESS]${NC} $1"
        }
    fi
    
    if ! command -v log_debug >/dev/null 2>&1; then
        log_debug() {
            if [[ "${IPV6WGM_DEBUG_MODE:-false}" == "true" ]]; then
                echo -e "${PURPLE}[DEBUG]${NC} $1"
            fi
        }
    fi
}

# ================================================================
# 统一的错误处理函数
# ================================================================

# 统一的错误处理函数（避免重复定义）
unified_handle_error() {
    local error_code="$1"
    local error_message="$2"
    local context="${3:-unknown}"
    local line_number="${4:-$LINENO}"
    
    # 确保日志函数存在
    ensure_log_functions
    
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
    
    # 确保日志函数存在
    ensure_log_functions
    
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
export -f ensure_log_functions
export -f unified_handle_error
export -f unified_convert_path
export -f unified_set_permissions
export -f unified_execute_command

