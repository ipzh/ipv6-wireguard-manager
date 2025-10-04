#!/bin/bash

# 统一安全修复模块
# 解决所有已识别的安全问题和兼容性问题

# =============================================================================
# 统一错误处理
# =============================================================================

# 权威的错误处理函数 - 所有脚本都应该使用这个
handle_error() {
    local exit_code="$1"
    local error_message="${2:-未知错误}"
    local context="${3:-}"
    local line_number="${4:-$LINENO}"
    
    # 记录错误到日志
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_message="[$timestamp] [ERROR] [$context] 行 $line_number: $error_message (退出码: $exit_code)"
    
    # 输出到stderr
    echo "$log_message" >&2
    
    # 记录到错误日志文件
    local error_log="${IPV6WGM_LOG_DIR:-/tmp}/error.log"
    mkdir -p "$(dirname "$error_log")" 2>/dev/null || true
    echo "$log_message" >> "$error_log"
    
    # 清理资源
    cleanup_on_error
    
    # 退出
    exit "$exit_code"
}

# 错误清理函数
cleanup_on_error() {
    # 清理临时文件
    if [[ -n "${IPV6WGM_TEMP_DIR:-}" && -d "$IPV6WGM_TEMP_DIR" ]]; then
        rm -rf "$IPV6WGM_TEMP_DIR" 2>/dev/null || true
    fi
    
    # 清理其他临时文件
    if [[ -n "${TEMP_FILES:-}" ]]; then
        for temp_file in $TEMP_FILES; do
            if [[ -f "$temp_file" ]]; then
                rm -f "$temp_file" 2>/dev/null || true
            fi
        done
    fi
}

# =============================================================================
# 安全文件删除
# =============================================================================

# 安全的文件删除函数
safe_rm() {
    local target="$1"
    local force="${2:-false}"
    local dry_run="${3:-false}"
    
    # 检查参数
    if [[ -z "$target" ]]; then
        echo "错误: 未指定删除目标" >&2
        return 1
    fi
    
    # 防止删除根目录
    if [[ "$target" == "/" ]] || [[ "$target" == "/"* ]] && [[ ${#target} -lt 3 ]]; then
        echo "错误: 拒绝删除根目录或过短路径: $target" >&2
        return 1
    fi
    
    # 防止删除系统关键目录
    local critical_paths=(
        "/bin" "/sbin" "/usr" "/etc" "/var" "/opt" "/root" "/home"
        "/boot" "/dev" "/proc" "/sys" "/tmp" "/mnt" "/media"
    )
    
    for critical in "${critical_paths[@]}"; do
        if [[ "$target" == "$critical" ]] || [[ "$target" == "$critical/"* ]]; then
            echo "错误: 拒绝删除系统关键路径: $target" >&2
            return 1
        fi
    done
    
    # 限制到工作目录内（如果设置了IPV6WGM_ROOT_DIR）
    if [[ -n "${IPV6WGM_ROOT_DIR:-}" ]]; then
        local real_target
        real_target=$(realpath "$target" 2>/dev/null || echo "$target")
        local real_root
        real_root=$(realpath "$IPV6WGM_ROOT_DIR" 2>/dev/null || echo "$IPV6WGM_ROOT_DIR")
        
        if [[ "$real_target" != "$real_root" ]] && [[ "$real_target" != "$real_root/"* ]]; then
            echo "错误: 目标路径不在允许的工作目录内: $target" >&2
            return 1
        fi
    fi
    
    # 干运行模式
    if [[ "$dry_run" == "true" ]]; then
        echo "干运行: 将删除 $target"
        return 0
    fi
    
    # 确认删除（非强制模式）
    if [[ "$force" != "true" ]]; then
        echo "警告: 即将删除 $target"
        read -rp "确认删除? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "取消删除"
            return 0
        fi
    fi
    
    # 执行删除
    if rm -rf "$target" 2>/dev/null; then
        echo "成功删除: $target"
        return 0
    else
        echo "删除失败: $target" >&2
        return 1
    fi
}

# 安全的文件删除函数 - 替代rm -rf
safe_rm() {
    local target="$1"
    local force="${2:-false}"

    # 检查目标是否存在
    if [[ ! -e "$target" ]]; then
        log_debug "目标不存在，跳过删除: $target"
        return 0
    fi

    # 安全检查：禁止删除根目录、系统目录
    local dangerous_paths=("/" "/etc" "/usr" "/bin" "/sbin" "/lib" "/lib64" "/var" "/tmp" "/home" "/root")
    for dangerous_path in "${dangerous_paths[@]}"; do
        if [[ "$target" == "$dangerous_path" ]] || [[ "$target" == "$dangerous_path/"* ]]; then
            log_error "禁止删除危险路径: $target"
            return 1
        fi
    done

    # 检查是否为相对路径且不包含..
    if [[ "$target" != /* ]] && [[ "$target" != ~* ]] && [[ "$target" != "$(pwd)"* ]]; then
        if [[ "$target" == *".."* ]]; then
            log_error "禁止使用包含..的相对路径: $target"
            return 1
        fi
    fi

    # 确认删除（除非强制删除）
    if [[ "$force" != "true" ]]; then
        echo "警告: 将要删除 $target"
        read -rp "确认删除? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "取消删除"
            return 0
        fi
    fi

    # 执行安全删除
    if [[ -d "$target" ]]; then
        # 对于目录，先检查权限和内容
        if [[ ! -w "$target" ]]; then
            log_error "没有权限删除目录: $target"
            return 1
        fi

        # 递归删除目录
        find "$target" -type f -exec chmod +w {} \; 2>/dev/null
        if rm -rf "$target" 2>/dev/null; then
            log_info "成功删除目录: $target"
            return 0
        else
            log_error "删除目录失败: $target"
            return 1
        fi
    else
        # 对于文件，直接删除
        if rm -f "$target" 2>/dev/null; then
            log_debug "成功删除文件: $target"
            return 0
        else
            log_error "删除文件失败: $target"
            return 1
        fi
    fi
}

# 加密敏感配置值
encrypt_sensitive_config() {
    local key="$1"
    local value="$2"
    local config_file="$3"

    # 检查是否为敏感配置项
    local sensitive_patterns=("password" "secret" "key" "token" "cert" "private")
    local is_sensitive=false

    for pattern in "${sensitive_patterns[@]}"; do
        if [[ "$key" == *"$pattern"* ]]; then
            is_sensitive=true
            break
        fi
    done

    if [[ "$is_sensitive" == "true" ]]; then
        # 生成加密密钥（如果不存在）
        local encryption_key_file="$CONFIG_DIR/.encryption_key"
        if [[ ! -f "$encryption_key_file" ]]; then
            openssl rand -base64 32 > "$encryption_key_file"
            chmod 600 "$encryption_key_file"
        fi

        # 加密敏感值
        local encryption_key=$(cat "$encryption_key_file")
        local encrypted_value=$(echo -n "$value" | openssl enc -aes-256-cbc -a -salt -pbkdf2 -pass pass:"$encryption_key")

        # 在配置文件中替换为加密值
        if [[ -f "$config_file" ]]; then
            sed -i "s|^${key}=.*|${key}=encrypted:${encrypted_value}|" "$config_file"
        fi

        log_info "敏感配置已加密: $key"
        return 0
    fi

    return 1
}

# 解密敏感配置值
decrypt_sensitive_config() {
    local key="$1"
    local encrypted_value="$2"

    # 检查是否为加密值
    if [[ "$encrypted_value" == "encrypted:"* ]]; then
        local encryption_key_file="$CONFIG_DIR/.encryption_key"
        if [[ ! -f "$encryption_key_file" ]]; then
            log_error "加密密钥文件不存在，无法解密配置"
            return 1
        fi

        local encryption_key=$(cat "$encryption_key_file")
        local actual_encrypted="${encrypted_value#encrypted:}"

        # 解密值
        local decrypted_value=$(echo -n "$actual_encrypted" | base64 -d | openssl enc -aes-256-cbc -d -salt -pbkdf2 -pass pass:"$encryption_key" 2>/dev/null)

        if [[ -n "$decrypted_value" ]]; then
            echo "$decrypted_value"
            return 0
        fi
    fi

    # 如果不是加密值，直接返回原值
    echo "$encrypted_value"
    return 0
}

# =============================================================================
# 安全命令执行
# =============================================================================

# 安全的命令执行函数 - 替代eval
safe_execute() {
    local cmd_array=("$@")
    local description="${cmd_array[0]}"
    local allow_failure="${cmd_array[1]:-false}"
    
    # 移除前两个参数，保留实际命令
    shift 2
    local actual_cmd=("$@")
    
    echo "执行: $description"
    echo "命令: ${actual_cmd[*]}"
    
    # 使用数组执行命令，避免eval
    if "${actual_cmd[@]}"; then
        echo "成功: $description"
        return 0
    else
        local exit_code=$?
        if [[ "$allow_failure" == "true" ]]; then
            echo "警告: $description 执行失败，继续执行 (退出码: $exit_code)"
            return 1
        else
            echo "错误: $description 执行失败 (退出码: $exit_code)" >&2
            return 1
        fi
    fi
}

# 受控的bash执行 - 仅在模板可控时使用
safe_bash_exec() {
    local template="$1"
    local description="${2:-执行bash命令}"
    local allow_failure="${3:-false}"
    
    # 检查模板是否包含危险字符
    if [[ "$template" =~ [;&\|\`\$\(\)] ]]; then
        echo "错误: 模板包含危险字符，拒绝执行" >&2
        return 1
    fi
    
    echo "执行: $description"
    echo "模板: $template"
    
    if bash -c "$template"; then
        echo "成功: $description"
        return 0
    else
        local exit_code=$?
        if [[ "$allow_failure" == "true" ]]; then
            echo "警告: $description 执行失败，继续执行 (退出码: $exit_code)"
            return 1
        else
            echo "错误: $description 执行失败 (退出码: $exit_code)" >&2
            return 1
        fi
    fi
}

# =============================================================================
# 安全下载和验证
# =============================================================================

# 安全的下载函数
safe_download() {
    local url="$1"
    local output_file="$2"
    local expected_hash="${3:-}"
    local timeout="${4:-300}"
    
    if [[ -z "$url" ]] || [[ -z "$output_file" ]]; then
        echo "错误: URL和输出文件必须指定" >&2
        return 1
    fi
    
    echo "下载: $url -> $output_file"
    
    # 使用curl进行安全下载
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL --connect-timeout 30 --max-time "$timeout" \
           --proto '=https' --tlsv1.2 --location --fail \
           -o "$output_file" "$url"; then
            echo "下载成功: $output_file"
        else
            echo "下载失败: $url" >&2
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget --timeout=30 --tries=3 --secure-protocol=TLSv1_2 \
           -O "$output_file" "$url"; then
            echo "下载成功: $output_file"
        else
            echo "下载失败: $url" >&2
            return 1
        fi
    else
        echo "错误: 未找到curl或wget" >&2
        return 1
    fi
    
    # 验证文件哈希（如果提供）
    if [[ -n "$expected_hash" ]]; then
        if verify_file_hash "$output_file" "$expected_hash"; then
            echo "文件哈希验证通过"
        else
            echo "错误: 文件哈希验证失败" >&2
            rm -f "$output_file"
            return 1
        fi
    fi
    
    return 0
}

# 验证文件哈希
verify_file_hash() {
    local file="$1"
    local expected_hash="$2"
    
    if [[ ! -f "$file" ]]; then
        echo "错误: 文件不存在: $file" >&2
        return 1
    fi
    
    local actual_hash
    if command -v sha256sum >/dev/null 2>&1; then
        actual_hash=$(sha256sum "$file" | cut -d' ' -f1)
    elif command -v shasum >/dev/null 2>&1; then
        actual_hash=$(shasum -a 256 "$file" | cut -d' ' -f1)
    else
        echo "错误: 未找到哈希计算工具" >&2
        return 1
    fi
    
    if [[ "$actual_hash" == "$expected_hash" ]]; then
        return 0
    else
        echo "哈希不匹配: 期望 $expected_hash, 实际 $actual_hash" >&2
        return 1
    fi
}

# =============================================================================
# 统一Windows兼容性
# =============================================================================

# 统一的Windows环境检测
detect_unified_windows_env() {
    # 检测WSL
    if [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ -n "${WSLENV:-}" ]] || \
       ([[ -f /proc/version ]] && grep -qi microsoft /proc/version); then
        export IPV6WGM_WINDOWS_ENV_TYPE="wsl"
        export IPV6WGM_WINDOWS_ENV="true"
        return 0
    fi
    
    # 检测Git Bash
    if [[ -n "${MSYSTEM:-}" ]] && [[ "$MSYSTEM" =~ ^MINGW ]]; then
        export IPV6WGM_WINDOWS_ENV_TYPE="gitbash"
        export IPV6WGM_WINDOWS_ENV="true"
        return 0
    fi
    
    # 检测MSYS
    if [[ "$OSTYPE" == "msys" ]]; then
        export IPV6WGM_WINDOWS_ENV_TYPE="msys"
        export IPV6WGM_WINDOWS_ENV="true"
        return 0
    fi
    
    # 检测Cygwin
    if [[ "$OSTYPE" == "cygwin" ]]; then
        export IPV6WGM_WINDOWS_ENV_TYPE="cygwin"
        export IPV6WGM_WINDOWS_ENV="true"
        return 0
    fi
    
    # 检测PowerShell
    if [[ -n "${PSModulePath:-}" ]] && [[ "$PSModulePath" =~ Windows ]]; then
        export IPV6WGM_WINDOWS_ENV_TYPE="powershell"
        export IPV6WGM_WINDOWS_ENV="true"
        return 0
    fi
    
    # Linux环境
    export IPV6WGM_WINDOWS_ENV_TYPE="linux"
    export IPV6WGM_WINDOWS_ENV="false"
    return 0
}

# 统一的路径转换
convert_unified_path() {
    local path="$1"
    local target_type="${2:-native}"
    
    if [[ -z "$path" ]]; then
        return 1
    fi
    
    case "${IPV6WGM_WINDOWS_ENV_TYPE:-linux}" in
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
        "powershell")
            echo "$path" | sed 's|/|\\|g'
            ;;
        *)
            echo "$path"
            ;;
    esac
}

# =============================================================================
# 模块加载统一
# =============================================================================

# 统一的模块加载函数
load_module_unified() {
    local module_name="$1"
    local force_reload="${2:-false}"
    
    # 检查模块是否已加载
    if [[ -n "${LOADED_MODULES[$module_name]}" && "$force_reload" != "true" ]]; then
        return 0
    fi
    
    # 查找模块文件
    local module_path=""
    local search_paths=(
        "${IPV6WGM_MODULES_DIR:-./modules}/${module_name}.sh"
        "${SCRIPT_DIR:-.}/modules/${module_name}.sh"
        "$(pwd)/modules/${module_name}.sh"
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -f "$path" ]]; then
            module_path="$path"
            break
        fi
    done
    
    if [[ -z "$module_path" ]]; then
        echo "错误: 无法找到模块文件: $module_name" >&2
        return 1
    fi
    
    # 加载模块
    if source "$module_path"; then
        LOADED_MODULES[$module_name]=true
        echo "模块加载成功: $module_name"
        return 0
    else
        echo "错误: 模块加载失败: $module_name" >&2
        return 1
    fi
}

# 兼容性函数 - 为历史代码提供import_module接口
import_module() {
    echo "警告: import_module已废弃，请使用load_module_unified" >&2
    load_module_unified "$@"
}

# =============================================================================
# 导出函数
# =============================================================================

export -f handle_error cleanup_on_error
export -f safe_rm safe_execute safe_bash_exec
export -f safe_download verify_file_hash
export -f detect_unified_windows_env convert_unified_path
export -f load_module_unified import_module
