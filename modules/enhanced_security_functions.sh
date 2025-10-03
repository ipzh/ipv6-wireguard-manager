#!/bin/bash

# 增强安全功能模块
# 提供敏感数据加密存储、安全配置管理等功能

# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
fi

# 安全配置变量
declare -g IPV6WGM_ENCRYPTION_KEY="${IPV6WGM_ENCRYPTION_KEY:-}"
declare -g IPV6WGM_MASTER_KEY="${IPV6WGM_MASTER_KEY:-default_fallback_key}"
declare -g IPV6WGM_SECURE_CONFIG_DIR="${IPV6WGM_CONFIG_DIR}/secure"
declare -g IPV6WGM_SENSITIVE_PATTERNS=("password" "secret" "key" "token" "cert" "auth" "credential")

# 初始化安全功能
init_enhanced_security() {
    log_info "初始化增强安全功能..."
    
    # 创建安全配置目录
    if ! mkdir -p "$IPV6WGM_SECURE_CONFIG_DIR" 2>/dev/null; then
        log_error "无法创建安全配置目录: $IPV6WGM_SECURE_CONFIG_DIR"
        return 1
    fi
    
    # 设置安全目录权限
    chmod 700 "$IPV6WGM_SECURE_CONFIG_DIR" 2>/dev/null || {
        log_warn "无法设置安全目录权限"
    }
    
    # 检查加密工具可用性
    if ! command -v openssl &> /dev/null; then
        log_warn "OpenSSL不可用，加密功能将受限"
        return 1
    fi
    
    log_info "增强安全功能初始化完成"
    return 0
}

# 加密敏感数据
encrypt_sensitive_data() {
    local data="$1"
    local encryption_key="${IPV6WGM_ENCRYPTION_KEY:-}"
    
    if [[ -z "$data" ]]; then
        log_error "encrypt_sensitive_data: 数据不能为空"
        return 1
    fi
    
    # 如果没有提供加密密钥，使用环境变量或默认密钥
    if [[ -z "$encryption_key" ]]; then
        encryption_key="${IPV6WGM_MASTER_KEY:-default_fallback_key}"
        log_warn "使用默认密钥进行加密，建议设置IPV6WGM_ENCRYPTION_KEY环境变量"
    fi
    
    # 检查OpenSSL可用性
    if ! command -v openssl &> /dev/null; then
        log_error "OpenSSL不可用，无法加密数据"
        return 1
    fi
    
    # 使用openssl进行加密
    local encrypted_data
    encrypted_data=$(echo "$data" | openssl enc -aes-256-cbc -base64 -pass pass:"$encryption_key" -pbkdf2 2>/dev/null)
    
    if [[ $? -eq 0 && -n "$encrypted_data" ]]; then
        echo "$encrypted_data"
        return 0
    else
        log_error "数据加密失败"
        return 1
    fi
}

# 解密敏感数据
decrypt_sensitive_data() {
    local encrypted_data="$1"
    local encryption_key="${IPV6WGM_ENCRYPTION_KEY:-}"
    
    if [[ -z "$encrypted_data" ]]; then
        log_error "decrypt_sensitive_data: 加密数据不能为空"
        return 1
    fi
    
    # 如果没有提供加密密钥，使用环境变量或默认密钥
    if [[ -z "$encryption_key" ]]; then
        encryption_key="${IPV6WGM_MASTER_KEY:-default_fallback_key}"
    fi
    
    # 检查OpenSSL可用性
    if ! command -v openssl &> /dev/null; then
        log_error "OpenSSL不可用，无法解密数据"
        return 1
    fi
    
    # 使用openssl进行解密
    local decrypted_data
    decrypted_data=$(echo "$encrypted_data" | openssl enc -aes-256-cbc -d -base64 -pass pass:"$encryption_key" -pbkdf2 2>/dev/null)
    
    if [[ $? -eq 0 && -n "$decrypted_data" ]]; then
        echo "$decrypted_data"
        return 0
    else
        log_error "数据解密失败"
        return 1
    fi
}

# 检查是否为敏感配置项
is_sensitive_config() {
    local key="$1"
    
    if [[ -z "$key" ]]; then
        return 1
    fi
    
    # 转换为小写进行匹配
    local key_lower=$(echo "$key" | tr '[:upper:]' '[:lower:]')
    
    for pattern in "${IPV6WGM_SENSITIVE_PATTERNS[@]}"; do
        if [[ "$key_lower" == *"$pattern"* ]]; then
            return 0
        fi
    done
    
    return 1
}

# 安全存储配置项
save_sensitive_config() {
    local key="$1"
    local value="$2"
    local config_file="$3"
    
    if [[ -z "$key" || -z "$value" || -z "$config_file" ]]; then
        log_error "save_sensitive_config: 参数不完整"
        return 1
    fi
    
    # 检查是否是敏感配置项
    if is_sensitive_config "$key"; then
        log_info "检测到敏感配置项: $key，将进行加密存储"
        
        # 加密敏感数据
        local encrypted_value
        encrypted_value=$(encrypt_sensitive_data "$value")
        
        if [[ $? -eq 0 && -n "$encrypted_value" ]]; then
            # 存储加密后的数据，添加特殊标记
            echo "${key}_ENCRYPTED=${encrypted_value}" >> "$config_file"
            log_info "敏感配置项已加密存储: $key"
            return 0
        else
            log_error "敏感配置项加密失败: $key"
            return 1
        fi
    else
        # 非敏感配置项直接存储
        echo "${key}=${value}" >> "$config_file"
        log_debug "普通配置项已存储: $key"
        return 0
    fi
}

# 安全读取配置项
read_sensitive_config() {
    local key="$1"
    local config_file="$2"
    local default_value="$3"
    
    if [[ -z "$key" || -z "$config_file" ]]; then
        log_error "read_sensitive_config: 参数不完整"
        return 1
    fi
    
    if [[ ! -f "$config_file" ]]; then
        echo "$default_value"
        return 0
    fi
    
    # 首先尝试读取加密版本
    local encrypted_key="${key}_ENCRYPTED"
    local encrypted_value
    encrypted_value=$(grep "^${encrypted_key}=" "$config_file" | cut -d'=' -f2- 2>/dev/null)
    
    if [[ -n "$encrypted_value" ]]; then
        # 解密数据
        local decrypted_value
        decrypted_value=$(decrypt_sensitive_data "$encrypted_value")
        
        if [[ $? -eq 0 && -n "$decrypted_value" ]]; then
            echo "$decrypted_value"
            return 0
        else
            log_warn "敏感配置项解密失败: $key，使用默认值"
            echo "$default_value"
            return 1
        fi
    else
        # 尝试读取普通版本
        local plain_value
        plain_value=$(grep "^${key}=" "$config_file" | cut -d'=' -f2- 2>/dev/null)
        
        if [[ -n "$plain_value" ]]; then
            echo "$plain_value"
            return 0
        else
            echo "$default_value"
            return 0
        fi
    fi
}

# 迁移敏感配置到加密存储
migrate_sensitive_configs() {
    local config_file="$1"
    
    if [[ -z "$config_file" || ! -f "$config_file" ]]; then
        log_error "migrate_sensitive_configs: 配置文件不存在"
        return 1
    fi
    
    log_info "开始迁移敏感配置到加密存储..."
    
    local temp_file="${config_file}.tmp"
    local migrated_count=0
    
    # 创建临时文件
    > "$temp_file"
    
    # 逐行处理配置文件
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        if [[ "$key" =~ ^[[:space:]]*# ]] || [[ -z "$key" ]]; then
            echo "${key}=${value}" >> "$temp_file"
            continue
        fi
        
        # 检查是否是敏感配置项
        if is_sensitive_config "$key" && [[ ! "$key" == *"_ENCRYPTED" ]]; then
            log_info "迁移敏感配置项: $key"
            
            # 加密并存储
            local encrypted_value
            encrypted_value=$(encrypt_sensitive_data "$value")
            
            if [[ $? -eq 0 && -n "$encrypted_value" ]]; then
                echo "${key}_ENCRYPTED=${encrypted_value}" >> "$temp_file"
                ((migrated_count++))
            else
                log_warn "配置项加密失败，保持原样: $key"
                echo "${key}=${value}" >> "$temp_file"
            fi
        else
            # 非敏感配置项或已加密配置项保持原样
            echo "${key}=${value}" >> "$temp_file"
        fi
    done < "$config_file"
    
    # 替换原文件
    if mv "$temp_file" "$config_file"; then
        log_info "敏感配置迁移完成，共迁移 $migrated_count 个配置项"
        return 0
    else
        log_error "配置文件替换失败"
        rm -f "$temp_file"
        return 1
    fi
}

# 生成安全的随机密钥
generate_secure_key() {
    local key_length="${1:-32}"
    
    if command -v openssl &> /dev/null; then
        openssl rand -base64 "$key_length" | tr -d "=+/" | cut -c1-"$key_length"
    elif [[ -f /dev/urandom ]]; then
        tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$key_length"
    else
        # 回退方案
        date +%s | sha256sum | base64 | head -c "$key_length"
    fi
}

# 验证加密密钥强度
validate_encryption_key() {
    local key="$1"
    
    if [[ -z "$key" ]]; then
        log_error "加密密钥不能为空"
        return 1
    fi
    
    # 检查密钥长度
    if [[ ${#key} -lt 16 ]]; then
        log_warn "加密密钥长度过短，建议至少16个字符"
        return 1
    fi
    
    # 检查密钥复杂度
    if [[ ! "$key" =~ [A-Z] ]] || [[ ! "$key" =~ [a-z] ]] || [[ ! "$key" =~ [0-9] ]]; then
        log_warn "加密密钥复杂度不足，建议包含大小写字母和数字"
        return 1
    fi
    
    log_info "加密密钥验证通过"
    return 0
}

# 安全清理内存中的敏感数据
secure_cleanup() {
    # 清理环境变量中的敏感数据
    unset IPV6WGM_ENCRYPTION_KEY
    unset IPV6WGM_MASTER_KEY
    
    # 清理可能的临时变量
    local vars_to_clear=(
        "encrypted_data" "decrypted_data" "encryption_key"
        "plain_value" "encrypted_value" "key_lower"
    )
    
    for var in "${vars_to_clear[@]}"; do
        unset "$var" 2>/dev/null || true
    done
    
    log_debug "敏感数据内存清理完成"
}

# 导出函数
export -f init_enhanced_security encrypt_sensitive_data decrypt_sensitive_data
export -f is_sensitive_config save_sensitive_config read_sensitive_config
export -f migrate_sensitive_configs generate_secure_key validate_encryption_key
export -f secure_cleanup