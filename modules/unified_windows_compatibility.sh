#!/bin/bash
# modules/unified_windows_compatibility.sh

# 统一的Windows兼容性模块
# 解决所有Windows环境下的兼容性问题

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
# Windows环境检测和初始化
# ================================================================

# 全局变量
declare -g IPV6WGM_WINDOWS_ENV_TYPE=""
declare -g IPV6WGM_WINDOWS_COMPATIBILITY_MODE=""
declare -gA IPV6WGM_WINDOWS_ALIASES=()
declare -gA IPV6WGM_WINDOWS_PATHS=()

# 检测Windows环境类型
detect_windows_environment() {
    log_debug "检测Windows环境..."
    
    # 检测WSL
    if [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ -n "${WSLENV:-}" ]] || \
       ([[ -f /proc/version ]] && grep -qi microsoft /proc/version); then
        IPV6WGM_WINDOWS_ENV_TYPE="wsl"
        log_info "检测到WSL环境"
    # 检测MSYS
    elif [[ "$OSTYPE" == "msys" ]]; then
        IPV6WGM_WINDOWS_ENV_TYPE="msys"
        log_info "检测到MSYS环境"
    # 检测Cygwin
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        IPV6WGM_WINDOWS_ENV_TYPE="cygwin"
        log_info "检测到Cygwin环境"
    # 检测Git Bash
    elif [[ -n "${MSYSTEM:-}" ]] && [[ "$MSYSTEM" =~ ^MINGW ]]; then
        IPV6WGM_WINDOWS_ENV_TYPE="gitbash"
        log_info "检测到Git Bash环境"
    # 检测PowerShell
    elif [[ -n "${PSModulePath:-}" ]] && [[ "$PSModulePath" =~ Windows ]]; then
        IPV6WGM_WINDOWS_ENV_TYPE="powershell"
        log_info "检测到PowerShell环境"
    else
        IPV6WGM_WINDOWS_ENV_TYPE="linux"
        log_info "检测到Linux环境"
    fi
    
    export IPV6WGM_WINDOWS_ENV_TYPE
    return 0
}

# 初始化Windows兼容性
init_windows_compatibility() {
    log_debug "初始化Windows兼容性..."
    
    # 检测环境
    detect_windows_environment
    
    # 设置路径映射
    setup_windows_paths
    
    # 设置命令别名
    setup_windows_aliases
    
    # 设置兼容性模式
    setup_compatibility_mode
    
    log_debug "Windows兼容性初始化完成"
    return 0
}

# ================================================================
# 路径管理
# ================================================================

# 设置Windows路径映射
setup_windows_paths() {
    case "$IPV6WGM_WINDOWS_ENV_TYPE" in
        "wsl")
            IPV6WGM_WINDOWS_PATHS["config"]="/etc/ipv6-wireguard-manager"
            IPV6WGM_WINDOWS_PATHS["log"]="/var/log/ipv6-wireguard-manager"
            IPV6WGM_WINDOWS_PATHS["run"]="/var/run/ipv6-wireguard-manager"
            IPV6WGM_WINDOWS_PATHS["cache"]="/var/cache/ipv6-wireguard-manager"
            ;;
        "msys"|"cygwin"|"gitbash")
            IPV6WGM_WINDOWS_PATHS["config"]="/c/ProgramData/ipv6-wireguard-manager"
            IPV6WGM_WINDOWS_PATHS["log"]="/c/ProgramData/ipv6-wireguard-manager/logs"
            IPV6WGM_WINDOWS_PATHS["run"]="/c/ProgramData/ipv6-wireguard-manager/run"
            IPV6WGM_WINDOWS_PATHS["cache"]="/c/ProgramData/ipv6-wireguard-manager/cache"
            ;;
        "powershell")
            IPV6WGM_WINDOWS_PATHS["config"]="C:\\ProgramData\\ipv6-wireguard-manager"
            IPV6WGM_WINDOWS_PATHS["log"]="C:\\ProgramData\\ipv6-wireguard-manager\\logs"
            IPV6WGM_WINDOWS_PATHS["run"]="C:\\ProgramData\\ipv6-wireguard-manager\\run"
            IPV6WGM_WINDOWS_PATHS["cache"]="C:\\ProgramData\\ipv6-wireguard-manager\\cache"
            ;;
        *)
            IPV6WGM_WINDOWS_PATHS["config"]="/etc/ipv6-wireguard-manager"
            IPV6WGM_WINDOWS_PATHS["log"]="/var/log/ipv6-wireguard-manager"
            IPV6WGM_WINDOWS_PATHS["run"]="/var/run/ipv6-wireguard-manager"
            IPV6WGM_WINDOWS_PATHS["cache"]="/var/cache/ipv6-wireguard-manager"
            ;;
    esac
}

# 统一的路径转换函数
convert_path() {
    local path="$1"
    local target_type="${2:-native}"
    
    if [[ -z "$path" ]]; then
        return 1
    fi
    
    case "$IPV6WGM_WINDOWS_ENV_TYPE" in
        "wsl")
            # WSL中保持Linux路径格式
            echo "$path"
            ;;
        "msys"|"cygwin"|"gitbash")
            # 转换为Windows路径格式
            if command -v cygpath >/dev/null 2>&1; then
                case "$target_type" in
                    "windows") cygpath -w "$path" ;;
                    "unix") cygpath -u "$path" ;;
                    *) cygpath "$path" ;;
                esac
            else
                # 手动转换路径分隔符
                echo "$path" | sed 's|/|\\|g'
            fi
            ;;
        "powershell")
            # PowerShell中转换为Windows路径
            echo "$path" | sed 's|/|\\|g'
            ;;
        *)
            echo "$path"
            ;;
    esac
}

# ================================================================
# 命令别名和兼容性
# ================================================================

# 设置Windows命令别名
setup_windows_aliases() {
    case "$IPV6WGM_WINDOWS_ENV_TYPE" in
        "wsl")
            # WSL环境，大部分Linux命令可用
            setup_wsl_aliases
            ;;
        "msys"|"cygwin"|"gitbash")
            # MSYS/Cygwin环境
            setup_msys_aliases
            ;;
        "powershell")
            # PowerShell环境
            setup_powershell_aliases
            ;;
    esac
}

# 设置WSL别名
setup_wsl_aliases() {
    # WSL中大部分命令都可用，只需要少量别名
    if ! command -v ip >/dev/null 2>&1 && command -v ipconfig >/dev/null 2>&1; then
        alias ip='ipconfig'
        IPV6WGM_WINDOWS_ALIASES["ip"]="ipconfig"
    fi
}

# 设置MSYS别名
setup_msys_aliases() {
    # 网络命令
    if ! command -v ip >/dev/null 2>&1 && command -v ipconfig >/dev/null 2>&1; then
        alias ip='ipconfig'
        IPV6WGM_WINDOWS_ALIASES["ip"]="ipconfig"
    fi
    
    # 内存信息
    if ! command -v free >/dev/null 2>&1 && command -v wmic >/dev/null 2>&1; then
        alias free='wmic OS get FreePhysicalMemory,TotalVisibleMemorySize /Value'
        IPV6WGM_WINDOWS_ALIASES["free"]="wmic OS get FreePhysicalMemory,TotalVisibleMemorySize /Value"
    fi
    
    # 进程信息
    if ! command -v ps >/dev/null 2>&1 && command -v tasklist >/dev/null 2>&1; then
        alias ps='tasklist'
        IPV6WGM_WINDOWS_ALIASES["ps"]="tasklist"
    fi
}

# 设置PowerShell别名
setup_powershell_aliases() {
    # 所有命令都需要通过PowerShell执行
    IPV6WGM_WINDOWS_ALIASES["ip"]="Get-NetIPConfiguration"
    IPV6WGM_WINDOWS_ALIASES["free"]="Get-WmiObject -Class Win32_OperatingSystem | Select-Object TotalVisibleMemorySize,FreePhysicalMemory"
    IPV6WGM_WINDOWS_ALIASES["ps"]="Get-Process"
    IPV6WGM_WINDOWS_ALIASES["systemctl"]="sc"
}

# ================================================================
# 兼容性模式设置
# ================================================================

# 设置兼容性模式
setup_compatibility_mode() {
    case "$IPV6WGM_WINDOWS_ENV_TYPE" in
        "wsl")
            IPV6WGM_WINDOWS_COMPATIBILITY_MODE="full"
            ;;
        "msys"|"cygwin"|"gitbash")
            IPV6WGM_WINDOWS_COMPATIBILITY_MODE="partial"
            ;;
        "powershell")
            IPV6WGM_WINDOWS_COMPATIBILITY_MODE="limited"
            ;;
        *)
            IPV6WGM_WINDOWS_COMPATIBILITY_MODE="none"
            ;;
    esac
}

# ================================================================
# Windows兼容的命令执行
# ================================================================

# 执行Windows兼容命令
execute_windows_command() {
    local command="$1"
    shift
    local args=("$@")
    
    # 检查是否有别名
    local alias_cmd="${IPV6WGM_WINDOWS_ALIASES[$command]}"
    if [[ -n "$alias_cmd" ]]; then
        log_debug "使用别名执行命令: $command -> $alias_cmd"
        command="$alias_cmd"
    fi
    
    # 根据环境类型执行命令
    case "$IPV6WGM_WINDOWS_ENV_TYPE" in
        "powershell")
            # PowerShell环境
            powershell -Command "$command ${args[*]}"
            ;;
        *)
            # 其他环境
            "$command" "${args[@]}"
            ;;
    esac
}

# ================================================================
# Windows兼容的权限管理
# ================================================================

# Windows兼容的权限设置
set_windows_permissions() {
    local target_path="$1"
    local mode="$2"
    local user="${3:-root}"
    local group="${4:-root}"
    
    if [[ ! -e "$target_path" ]]; then
        log_warn "目标路径不存在: $target_path"
        return 1
    fi
    
    case "$IPV6WGM_WINDOWS_ENV_TYPE" in
        "wsl")
            # WSL中可以使用Linux权限命令
            chown -R "${user}:${group}" "$target_path" 2>/dev/null || true
            chmod -R "$mode" "$target_path" 2>/dev/null || true
            ;;
        "msys"|"cygwin"|"gitbash")
            # MSYS/Cygwin中权限管理有限
            chmod -R "$mode" "$target_path" 2>/dev/null || true
            ;;
        "powershell")
            # PowerShell中通过icacls设置权限
            if command -v icacls >/dev/null 2>&1; then
                icacls "$target_path" /grant "${user}:F" /T 2>/dev/null || true
            fi
            ;;
    esac
    
    log_info "已设置 $target_path 的权限（$mode, ${user}:${group}）"
    return 0
}

# ================================================================
# Windows兼容的目录创建
# ================================================================

# Windows兼容的目录创建
create_windows_directory() {
    local dir_path="$1"
    local mode="${2:-755}"
    local user="${3:-root}"
    local group="${4:-root}"
    
    # 转换路径
    local windows_path=$(convert_path "$dir_path" "windows")
    
    # 创建目录
    case "$IPV6WGM_WINDOWS_ENV_TYPE" in
        "powershell")
            # PowerShell中创建目录
            powershell -Command "New-Item -ItemType Directory -Path '$windows_path' -Force" 2>/dev/null || true
            ;;
        *)
            # 其他环境
            mkdir -p "$dir_path" 2>/dev/null || true
            ;;
    esac
    
    # 设置权限
    set_windows_permissions "$dir_path" "$mode" "$user" "$group"
    
    return 0
}

# ================================================================
# Windows兼容性检查
# ================================================================

# 检查Windows兼容性
check_windows_compatibility() {
    log_info "检查Windows兼容性..."
    
    local issues=()
    
    # 检查必要命令
    local required_commands=("curl" "wget" "tar" "gzip")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            local alias_cmd="${IPV6WGM_WINDOWS_ALIASES[$cmd]}"
            if [[ -n "$alias_cmd" ]] && command -v "$alias_cmd" >/dev/null 2>&1; then
                log_debug "命令 $cmd 通过别名 $alias_cmd 可用"
            else
                issues+=("$cmd")
            fi
        fi
    done
    
    # 检查路径转换
    if ! test_path_conversion; then
        issues+=("path_conversion")
    fi
    
    # 检查权限
    if ! test_windows_permissions; then
        issues+=("permissions")
    fi
    
    # 报告兼容性问题
    if [[ ${#issues[@]} -gt 0 ]]; then
        log_warn "发现兼容性问题: ${issues[*]}"
        return 1
    else
        log_success "Windows兼容性检查通过"
        return 0
    fi
}

# 测试路径转换
test_path_conversion() {
    local test_path="/tmp/test"
    local converted_path=$(convert_path "$test_path")
    
    if [[ -n "$converted_path" ]]; then
        log_debug "路径转换测试通过: $test_path -> $converted_path"
        return 0
    else
        log_debug "路径转换测试失败"
        return 1
    fi
}

# 测试Windows权限
test_windows_permissions() {
    local test_file="/tmp/windows_test_$$"
    
    if touch "$test_file" 2>/dev/null; then
        rm -f "$test_file"
        log_debug "权限测试通过"
        return 0
    else
        log_debug "权限测试失败"
        return 1
    fi
}

# ================================================================
# 导出函数
# ================================================================

# 导出所有函数
export -f detect_windows_environment
export -f init_windows_compatibility
export -f convert_path
export -f execute_windows_command
export -f set_windows_permissions
export -f create_windows_directory
export -f check_windows_compatibility
export -f test_path_conversion
export -f test_windows_permissions
