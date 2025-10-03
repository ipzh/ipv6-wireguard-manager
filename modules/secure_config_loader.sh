#!/bin/bash

# ================================================================
# 安全配置加载模块 - 安全地加载和管理配置信息
# ================================================================

# 配置安全级别
CONFIG_SECURITY_LEVEL="${CONFIG_SECURITY_LEVEL:-medium}"
ENCRYPTION_KEY_FILE="${ENCRYPTION_KEY_FILE:-$IPV6WGM_DIR/config/.encryption_key}"

# 生成加密密钥
generate_encryption_key() {
    if [[ ! -f "$ENCRYPTION_KEY_FILE" ]]; then
        openssl rand -hex 32 > "$ENCRYPTION_KEY_FILE"
        chmod 600 "$ENCRYPTION_KEY_FILE"
        log_info "已生成新的配置加密密钥"
    fi
    
    cat "$ENCRYPTION_KEY_FILE"
}

# 加密配置值
encrypt_config_value() {
    local plaintext="$1"
    local key
    
    key=$(generate_encryption_key)
    
    local encrypted
    encrypted=$(echo "$plaintext" | openssl enc -aes-256-cbc -base64 -pass pass:"$key" 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        echo "$encrypted"
    else
        log_error "配置值加密失败"
        return 1
    fi
}

# 解密配置值
decrypt_config_value() {
    local encrypted="$1"
    local key
    
    if [[ ! -f "$ENCRYPTION_KEY_FILE" ]]; then
        log_error "加密密钥文件不存在，无法解密"
        return 1
    fi
    
    root_or_fatal="${2:-false}"
    
    key=$(cat "$ENCRYPTION_KEY_FILE" 2>/dev/null)
    if [[ $? -ne 0 && "$root_or_fatal" == "false" ]]; then
        log_warn "无法读取加密密钥，返回原始值"
        echo "$encrypted"
        return 0
    fi
    
    local decrypted
    decrypted=$(echo "$encrypted" | openssl enc -aes-256-cbc -base64 -d -pass pass:"$key" 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        echo "$decrypted"
    else
        log_error "配置值解密失败"
        return 1
    fi
}

# 安全设置配置值
secure_set_config() {
    local key="$1"
    local value="$2"
    local encrypt="${3:-true}"
    
    # 确定配置路径
    local config_path="$IPV6WGM_DIR/config/$key.conf"
    
    if [[ "$encrypt" == "true" ]]; then
        local encrypted_value
        encrypted_value=$(encrypt_config_value "$value")
        if [[ $? -eq 0 ]]; then
            echo "<encrypted>$encrypted_value</encrypted>" > "$config_path"
            chmod 600 "$config_path"
            log_debug "配置已安全保存: $key"
            return 0
        else
            return 1
        fi
    else
        echo "$value" > "$config_path"
        chmod 644 "$config_path"
        log_debug "配置已保存: $key"
        return 0
    fi
}

# 安全获取配置值
secure_get_config() {
    local key="$1"
    local config_path="$IPV6WGM_DIR/config/$key.conf"
    
    if [[ -f "$config_path" ]]; then
        local content
        content=$(cat "$config_path" 2>/dev/null)
        
        if [[ "$content" =~ ^<encrypted>(.*)</encrypted>$ ]]; then
            local encrypted_value
            encrypted_value=$(echo "$content" | sed 's/<encrypted>\(.*\)<\/encrypted>/\1/')
            
            local decrypted_value
            decrypted_value=$(decrypt_config_value "$encrypted_value" "true")
            if [[ $? -eq 0 ]]; then
                echo "$decrypted_value"
                return 0
            else
                log_warn "配置解密失败，尝试使用原始值: \($key\)"
                echo "$encrypted_value"
                return 1
            fi
        else
            echo "$content"
            return 0
        fi
    else
        log_warn "配置文件不存在: $config_path"
        return 1
    fi
}

# 生成安全的默认密码
generate_secure_password() {
    local length="${1:-16}"
    local include_special="${2:-true}"
    
    if [[ "$include_special" == "true" ]]; then
        openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length | sed 's/[0-9]/&A/' | head -1
    else
        openssl rand -hex $((length/2))
    fi
}

# 验证配置安全性
validate_config_security() {
    local issues=()
    
    # 检查默认密码
    local default_passwords=("admin123" "password" "root" "wireguard")
    for password in "${default_passwords[@]}"; do
        if grep -r "$password" "$IPV6WGM_DIR/config/" &>/dev/null; then
            issues+=("发现默认密码: $password")
        fi
    done
    
    # 检查配置文件权限
    local config_files
    config_files=$(find "$IPV6WGM_DIR/config/" -type f \( -name "*.conf" -o -name "*.key" -o -name "*.pem" \) 2>/dev/null)
    
    for file in $config_files; do
        local permissions
        permissions=$(stat -c "%a" "$file" 2>/dev/null)
        
        if [[ -z "$permissions" ]]; then
            permissions=$(stat -f "%Lp" "$file" 2>/dev/null)
        fi
        
        if [[ ! "$permissions" =~ ^[0-7][0-4][0-4]$ ]]; then
            issues+=("配置文件权限不安全: $file ($permissions)")
        fi
    done
    
    # 检查硬编码密码
    if grep -r "password.*=" "$IPV6WGM_DIR/config/" | grep -v ".****" &>/dev/null; then
        issues+=("可能存在硬编码密码")
    fi
    
    # 返回问题列表
    if [[ ${#issues[@]} -gt 0 ]]; then
        printf '%s\n' "${issues[@]}"
        return 1
    fi
    
    log_success "配置安全检查通过"
    return 0
}

# 自动修复配置安全问题
auto_fix_config_security() {
    log_info "开始自动修复配置安全问题..."
    
    local fixed=0
    
    # 修复文件权限
    local config_files
    config_files=$(find "$IPV6WGM_DIR/config/" -type f \( -name "*.conf" -o -name "*.key" -o -name "*.pem" \) 2>/dev/null)
    
    for file in $config_files; do
        local permissions
        permissions=$(stat -c "%a" "$file" 2>/dev/null)
        
        if [[ -z "$permissions" ]]; then
            permissions=$(stat -f "%Lp" "$file" 2>/dev/null)
        fi
        
        if [[ ! "$permissions" =~ ^[0-7][0-4][0-4]$ ]]; then
            chmod 600 "$file"
            ((fixed++))
            log_debug "已修复文件权限: $file"
        fi
    done
    
    # 自动生成安全密码
    local secure_passwords=("WG_ADMIN_PASSWORD" "DB_PASSWORD" "API_SECRET")
    for password_key in "${secure_passwords[@]}"; do
        local current_value
        current_value=$(secure_get_config "$password_key" 2>/dev/null)
        
        if [[ $? -ne 0 || "$current_value" =~ ^(admin123|password|root)$ ]]; then
            local new_password
            new_password=$(generate_secure_password 16 true)
            secure_set_config "$password_key" "$new_password" true
            ((fixed++))
            log_debug "已生成安全密码: $password_key"
        fi
    done
    
    log_success "配置安全问题自动修复完成 (修复数量: $fixed)"
    return 0
}

# 导出函数
export -f generate_encryption_key encrypt_config_value decrypt_config_value
export -f secure_set_config secure_get_config generate_secure_password
export -f validate_config_security auto_fix_config_security

# 别名
alias secure_set=secure_set_config
alias secure_get=secure_get_config
alias secure_pass=generate_secure_password
alias check_security=validate_config_security
alias fix_security=auto_fix_config_security
