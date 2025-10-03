#!/bin/bash

# 统一配置管理系统
# 支持YAML、JSON、INI和简单键值对格式的配置文件

# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
fi

# 导入增强安全功能
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/enhanced_security_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/enhanced_security_functions.sh"
fi

# 配置管理变量
declare -gA IPV6WGM_CONFIG_CACHE
declare -g IPV6WGM_CONFIG_CACHE_TTL=300  # 5分钟缓存
declare -gA IPV6WGM_CONFIG_CACHE_TIME

# 初始化统一配置管理
init_unified_config_manager() {
    log_info "初始化统一配置管理系统..."
    
    # 检查必要工具的可用性
    local tools_status=""
    
    if command -v yq &> /dev/null; then
        tools_status+="yq:✓ "
    else
        tools_status+="yq:✗ "
        log_warn "yq不可用，YAML配置支持将受限"
    fi
    
    if command -v jq &> /dev/null; then
        tools_status+="jq:✓ "
    else
        tools_status+="jq:✗ "
        log_warn "jq不可用，JSON配置支持将受限"
    fi
    
    log_info "配置工具状态: $tools_status"
    log_info "统一配置管理系统初始化完成"
    return 0
}

# 检测配置文件格式
detect_config_format() {
    local config_file="$1"
    
    if [[ -z "$config_file" || ! -f "$config_file" ]]; then
        echo "unknown"
        return 1
    fi
    
    # 根据文件扩展名判断
    local file_ext="${config_file##*.}"
    case "$file_ext" in
        "yaml"|"yml")
            echo "yaml"
            return 0
            ;;
        "json")
            echo "json"
            return 0
            ;;
        "ini")
            echo "ini"
            return 0
            ;;
        "conf"|"config"|"cfg")
            # 进一步检查内容格式
            if grep -q "^\[.*\]$" "$config_file" 2>/dev/null; then
                echo "ini"
            else
                echo "keyvalue"
            fi
            return 0
            ;;
        *)
            # 通过内容特征判断
            if grep -q "^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*:" "$config_file" 2>/dev/null; then
                echo "yaml"
            elif grep -q "^[[:space:]]*{" "$config_file" 2>/dev/null; then
                echo "json"
            elif grep -q "^\[.*\]$" "$config_file" 2>/dev/null; then
                echo "ini"
            else
                echo "keyvalue"
            fi
            return 0
            ;;
    esac
}

# 统一配置读取函数
read_config() {
    local config_file="$1"
    local config_key="$2"
    local default_value="$3"
    local use_cache="${4:-true}"
    
    if [[ -z "$config_file" || -z "$config_key" ]]; then
        log_error "read_config: 参数不完整"
        echo "$default_value"
        return 1
    fi
    
    if [[ ! -f "$config_file" ]]; then
        log_debug "配置文件不存在: $config_file"
        echo "$default_value"
        return 0
    fi
    
    # 检查缓存
    local cache_key="${config_file}:${config_key}"
    if [[ "$use_cache" == "true" && -n "${IPV6WGM_CONFIG_CACHE[$cache_key]}" ]]; then
        local cache_time="${IPV6WGM_CONFIG_CACHE_TIME[$cache_key]:-0}"
        local current_time=$(date +%s)
        
        if [[ $((current_time - cache_time)) -lt $IPV6WGM_CONFIG_CACHE_TTL ]]; then
            echo "${IPV6WGM_CONFIG_CACHE[$cache_key]}"
            return 0
        fi
    fi
    
    # 检测配置文件格式
    local config_format
    config_format=$(detect_config_format "$config_file")
    
    local value=""
    
    # 根据格式选择解析方法
    case "$config_format" in
        "yaml")
            value=$(read_yaml_config "$config_file" "$config_key" "$default_value")
            ;;
        "json")
            value=$(read_json_config "$config_file" "$config_key" "$default_value")
            ;;
        "ini")
            value=$(read_ini_config "$config_file" "$config_key" "$default_value")
            ;;
        "keyvalue")
            value=$(read_keyvalue_config "$config_file" "$config_key" "$default_value")
            ;;
        *)
            log_warn "未知配置文件格式: $config_format，尝试键值对解析"
            value=$(read_keyvalue_config "$config_file" "$config_key" "$default_value")
            ;;
    esac
    
    # 检查是否是敏感配置项，如果是则尝试解密
    if command -v is_sensitive_config &> /dev/null && is_sensitive_config "$config_key"; then
        if command -v read_sensitive_config &> /dev/null; then
            value=$(read_sensitive_config "$config_key" "$config_file" "$default_value")
        fi
    fi
    
    # 更新缓存
    if [[ "$use_cache" == "true" ]]; then
        IPV6WGM_CONFIG_CACHE[$cache_key]="$value"
        IPV6WGM_CONFIG_CACHE_TIME[$cache_key]=$(date +%s)
    fi
    
    echo "$value"
    return 0
}

# 读取YAML配置
read_yaml_config() {
    local config_file="$1"
    local config_key="$2"
    local default_value="$3"
    
    if command -v yq &> /dev/null; then
        # 将点分隔的键转换为yq路径
        local yq_path="${config_key//./\.}"
        local value
        value=$(yq eval ".$yq_path" "$config_file" 2>/dev/null)
        
        if [[ "$value" != "null" && -n "$value" ]]; then
            echo "$value"
        else
            echo "$default_value"
        fi
    else
        log_warn "yq不可用，无法解析YAML配置"
        echo "$default_value"
    fi
}

# 读取JSON配置
read_json_config() {
    local config_file="$1"
    local config_key="$2"
    local default_value="$3"
    
    if command -v jq &> /dev/null; then
        # 将点分隔的键转换为jq路径
        local jq_path=".${config_key}"
        local value
        value=$(jq -r "$jq_path" "$config_file" 2>/dev/null)
        
        if [[ "$value" != "null" && -n "$value" ]]; then
            echo "$value"
        else
            echo "$default_value"
        fi
    else
        log_warn "jq不可用，无法解析JSON配置"
        echo "$default_value"
    fi
}

# 读取INI配置
read_ini_config() {
    local config_file="$1"
    local config_key="$2"
    local default_value="$3"
    
    # 支持section.key格式
    if [[ "$config_key" == *"."* ]]; then
        local section="${config_key%%.*}"
        local key="${config_key#*.}"
        
        # 查找section并读取key
        local in_section=false
        while IFS= read -r line; do
            # 跳过注释和空行
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line// }" ]] && continue
            
            # 检查section
            if [[ "$line" =~ ^\[.*\]$ ]]; then
                local current_section="${line#[}"
                current_section="${current_section%]}"
                if [[ "$current_section" == "$section" ]]; then
                    in_section=true
                else
                    in_section=false
                fi
                continue
            fi
            
            # 在正确的section中查找key
            if [[ "$in_section" == true && "$line" == *"="* ]]; then
                local line_key="${line%%=*}"
                line_key="${line_key// }"  # 去除空格
                
                if [[ "$line_key" == "$key" ]]; then
                    local value="${line#*=}"
                    value="${value# }"  # 去除前导空格
                    echo "$value"
                    return 0
                fi
            fi
        done < "$config_file"
    else
        # 简单的key=value格式
        local value
        value=$(grep "^[[:space:]]*${config_key}[[:space:]]*=" "$config_file" | head -1 | cut -d'=' -f2- | sed 's/^[[:space:]]*//')
        
        if [[ -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    fi
    
    echo "$default_value"
    return 0
}

# 读取键值对配置
read_keyvalue_config() {
    local config_file="$1"
    local config_key="$2"
    local default_value="$3"
    
    local value
    value=$(grep "^[[:space:]]*${config_key}[[:space:]]*=" "$config_file" | head -1 | cut -d'=' -f2- 2>/dev/null)
    
    # 去除前后空格和引号
    value="${value# }"
    value="${value% }"
    value="${value#\"}"
    value="${value%\"}"
    value="${value#\'}"
    value="${value%\'}"
    
    if [[ -n "$value" ]]; then
        echo "$value"
    else
        echo "$default_value"
    fi
}

# 统一配置写入函数
write_config() {
    local config_file="$1"
    local config_key="$2"
    local config_value="$3"
    local create_if_missing="${4:-true}"
    
    if [[ -z "$config_file" || -z "$config_key" ]]; then
        log_error "write_config: 参数不完整"
        return 1
    fi
    
    # 创建配置文件目录
    local config_dir
    config_dir=$(dirname "$config_file")
    if [[ ! -d "$config_dir" ]]; then
        if [[ "$create_if_missing" == "true" ]]; then
            mkdir -p "$config_dir" || {
                log_error "无法创建配置目录: $config_dir"
                return 1
            }
        else
            log_error "配置目录不存在: $config_dir"
            return 1
        fi
    fi
    
    # 检查是否是敏感配置项
    if command -v is_sensitive_config &> /dev/null && is_sensitive_config "$config_key"; then
        if command -v save_sensitive_config &> /dev/null; then
            save_sensitive_config "$config_key" "$config_value" "$config_file"
            return $?
        fi
    fi
    
    # 检测或确定配置文件格式
    local config_format
    if [[ -f "$config_file" ]]; then
        config_format=$(detect_config_format "$config_file")
    else
        # 根据文件扩展名确定格式
        local file_ext="${config_file##*.}"
        case "$file_ext" in
            "yaml"|"yml") config_format="yaml" ;;
            "json") config_format="json" ;;
            "ini") config_format="ini" ;;
            *) config_format="keyvalue" ;;
        esac
    fi
    
    # 根据格式写入配置
    case "$config_format" in
        "keyvalue")
            write_keyvalue_config "$config_file" "$config_key" "$config_value"
            ;;
        "ini")
            write_ini_config "$config_file" "$config_key" "$config_value"
            ;;
        *)
            log_warn "不支持写入格式: $config_format，使用键值对格式"
            write_keyvalue_config "$config_file" "$config_key" "$config_value"
            ;;
    esac
    
    # 清除相关缓存
    local cache_key="${config_file}:${config_key}"
    unset IPV6WGM_CONFIG_CACHE["$cache_key"]
    unset IPV6WGM_CONFIG_CACHE_TIME["$cache_key"]
    
    return $?
}

# 写入键值对配置
write_keyvalue_config() {
    local config_file="$1"
    local config_key="$2"
    local config_value="$3"
    
    # 如果配置项已存在，更新它
    if [[ -f "$config_file" ]] && grep -q "^[[:space:]]*${config_key}[[:space:]]*=" "$config_file"; then
        # 使用sed更新现有配置项
        sed -i "s/^[[:space:]]*${config_key}[[:space:]]*=.*/${config_key}=${config_value}/" "$config_file"
    else
        # 添加新配置项
        echo "${config_key}=${config_value}" >> "$config_file"
    fi
    
    log_debug "配置项已更新: $config_key=$config_value"
    return 0
}

# 写入INI配置
write_ini_config() {
    local config_file="$1"
    local config_key="$2"
    local config_value="$3"
    
    # 支持section.key格式
    if [[ "$config_key" == *"."* ]]; then
        local section="${config_key%%.*}"
        local key="${config_key#*.}"
        
        # 确保section存在
        if [[ -f "$config_file" ]] && ! grep -q "^\[${section}\]$" "$config_file"; then
            echo "" >> "$config_file"
            echo "[${section}]" >> "$config_file"
        elif [[ ! -f "$config_file" ]]; then
            echo "[${section}]" > "$config_file"
        fi
        
        # 更新或添加配置项
        if grep -A 100 "^\[${section}\]$" "$config_file" | grep -q "^${key}="; then
            # 更新现有配置项
            sed -i "/^\[${section}\]$/,/^\[.*\]$/ s/^${key}=.*/${key}=${config_value}/" "$config_file"
        else
            # 在section后添加新配置项
            sed -i "/^\[${section}\]$/a ${key}=${config_value}" "$config_file"
        fi
    else
        # 简单的key=value格式
        write_keyvalue_config "$config_file" "$config_key" "$config_value"
    fi
    
    log_debug "INI配置项已更新: $config_key=$config_value"
    return 0
}

# 清除配置缓存
clear_config_cache() {
    local config_file="$1"
    
    if [[ -n "$config_file" ]]; then
        # 清除特定文件的缓存
        for cache_key in "${!IPV6WGM_CONFIG_CACHE[@]}"; do
            if [[ "$cache_key" == "${config_file}:"* ]]; then
                unset IPV6WGM_CONFIG_CACHE["$cache_key"]
                unset IPV6WGM_CONFIG_CACHE_TIME["$cache_key"]
            fi
        done
        log_debug "已清除配置文件缓存: $config_file"
    else
        # 清除所有缓存
        unset IPV6WGM_CONFIG_CACHE
        unset IPV6WGM_CONFIG_CACHE_TIME
        declare -gA IPV6WGM_CONFIG_CACHE
        declare -gA IPV6WGM_CONFIG_CACHE_TIME
        log_debug "已清除所有配置缓存"
    fi
}

# 验证配置文件
validate_config_file() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在: $config_file"
        return 1
    fi
    
    local config_format
    config_format=$(detect_config_format "$config_file")
    
    case "$config_format" in
        "yaml")
            if command -v yq &> /dev/null; then
                yq eval '.' "$config_file" > /dev/null 2>&1
                return $?
            else
                log_warn "无法验证YAML文件，yq不可用"
                return 0
            fi
            ;;
        "json")
            if command -v jq &> /dev/null; then
                jq '.' "$config_file" > /dev/null 2>&1
                return $?
            else
                log_warn "无法验证JSON文件，jq不可用"
                return 0
            fi
            ;;
        *)
            # 对于其他格式，进行基本的语法检查
            if grep -q "^[[:space:]]*[^#].*=" "$config_file" 2>/dev/null; then
                log_debug "配置文件格式验证通过: $config_file"
                return 0
            else
                log_warn "配置文件可能为空或格式异常: $config_file"
                return 1
            fi
            ;;
    esac
}

# 导出函数
export -f init_unified_config_manager detect_config_format read_config
export -f read_yaml_config read_json_config read_ini_config read_keyvalue_config
export -f write_config write_keyvalue_config write_ini_config
export -f clear_config_cache validate_config_file