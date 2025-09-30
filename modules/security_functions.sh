#!/bin/bash

# 安全功能模块
# 提供敏感数据处理、输入验证、安全存储等功能

# ================================================================
# 敏感数据处理
# ================================================================

# 输入清理函数
sanitize_input() {
    # 移除潜在的命令注入字符
    local sanitized="$(echo "$1" | sed 's/[;&|`$<>(){}*\[\]\\'"'"']//g')"
    echo "$sanitized"
}

# 验证输入格式
validate_input_format() {
    local input="$1"
    local pattern="$2"
    local field_name="${3:-输入}"
    
    if [[ "$input" =~ $pattern ]]; then
        log_debug "✓ $field_name 格式验证通过"
        return 0
    else
        log_error "✗ $field_name 格式验证失败: $input"
        return 1
    fi
}

# 验证IP地址
validate_ip_address() {
    local ip="$1"
    local ip_type="${2:-both}"  # ipv4, ipv6, both
    
    case "$ip_type" in
        "ipv4")
            if [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                # 验证每个八位数的范围
                local IFS='.'
                local -a octets=($ip)
                for octet in "${octets[@]}"; do
                    if [[ $octet -gt 255 ]]; then
                        return 1
                    fi
                done
                return 0
            fi
            ;;
        "ipv6")
            if [[ "$ip" =~ ^[0-9a-fA-F:]+$ ]]; then
                return 0
            fi
            ;;
        "both")
            if validate_ip_address "$ip" "ipv4" || validate_ip_address "$ip" "ipv6"; then
                return 0
            fi
            ;;
    esac
    
    return 1
}

# 验证端口号
validate_port() {
    local port="$1"
    
    if [[ "$port" =~ ^[0-9]+$ ]] && [[ $port -ge 1 ]] && [[ $port -le 65535 ]]; then
        return 0
    else
        return 1
    fi
}

# 验证MAC地址
validate_mac_address() {
    local mac="$1"
    
    if [[ "$mac" =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]]; then
        return 0
    else
        return 1
    fi
}

# ================================================================
# 安全存储
# ================================================================

# 安全存储敏感配置
secure_store_config() {
    local key="$1"
    local value="$2"
    local config_file="$3"
    
    # 检查是否包含敏感关键词
    local sensitive_keys=("password" "secret" "key" "token" "cert" "private")
    
    for sk in "${sensitive_keys[@]}"; do
        if [[ "$key" == *"$sk"* ]]; then
            # 对敏感数据进行特殊处理（实际项目中应使用加密）
            local obfuscated_value="$(echo "$value" | sed 's/./*/g')"
            echo "$key=$obfuscated_value" >> "$config_file"
            return 0
        fi
    done
    
    # 非敏感数据直接存储
    echo "$key=$value" >> "$config_file"
    return 0
}

# 安全读取配置
secure_read_config() {
    local key="$1"
    local config_file="$2"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在: $config_file"
        return 1
    fi
    
    local value=$(grep "^$key=" "$config_file" | cut -d'=' -f2-)
    
    if [[ -n "$value" ]]; then
        # 检查是否为base64编码
        if echo "$value" | base64 -d >/dev/null 2>&1; then
            echo "$(echo "$value" | base64 -d)"
        else
            echo "$value"
        fi
        return 0
    else
        return 1
    fi
}

# 设置文件权限
set_secure_permissions() {
    local file_path="$1"
    local permissions="${2:-600}"
    
    if [[ -f "$file_path" ]]; then
        chmod "$permissions" "$file_path"
        log_debug "文件权限已设置: $file_path ($permissions)"
        return 0
    else
        log_error "文件不存在: $file_path"
        return 1
    fi
}

# ================================================================
# 安全审计
# ================================================================

# 检查硬编码凭据
check_hardcoded_credentials() {
    local search_path="${1:-$PROJECT_ROOT}"
    local issues=0
    
    log_info "检查硬编码凭据..."
    
    # 检查密码模式
    local password_patterns=(
        "password.*=.*['\"][^'\"]*['\"]"
        "passwd.*=.*['\"][^'\"]*['\"]"
        "pwd.*=.*['\"][^'\"]*['\"]"
        "secret.*=.*['\"][^'\"]*['\"]"
        "key.*=.*['\"][^'\"]*['\"]"
        "token.*=.*['\"][^'\"]*['\"]"
    )
    
    for pattern in "${password_patterns[@]}"; do
        if grep -r -i "$pattern" "$search_path" --include="*.sh" --include="*.conf" >/dev/null 2>&1; then
            log_warn "发现可能的硬编码凭据: $pattern"
            issues=$((issues + 1))
        fi
    done
    
    # 检查API密钥
    if grep -r -i "api.*key.*=" "$search_path" --include="*.sh" --include="*.conf" >/dev/null 2>&1; then
        log_warn "发现可能的API密钥"
        issues=$((issues + 1))
    fi
    
    if [[ $issues -eq 0 ]]; then
        log_success "✓ 未发现硬编码凭据"
        return 0
    else
        log_error "✗ 发现 $issues 个潜在安全问题"
        return 1
    fi
}

# 检查文件权限
check_file_permissions() {
    local search_path="${1:-$PROJECT_ROOT}"
    local issues=0
    
    log_info "检查文件权限..."
    
    # 检查敏感文件权限
    local sensitive_files=(
        "*.key" "*.pem" "*.p12" "*.crt" "*.cert"
        "*.conf" "*.config" "*.ini"
    )
    
    for pattern in "${sensitive_files[@]}"; do
        while IFS= read -r -d '' file; do
            local perms=$(stat -c "%a" "$file" 2>/dev/null || echo "000")
            if [[ "$perms" != "600" ]] && [[ "$perms" != "644" ]]; then
                log_warn "文件权限不当: $file ($perms)"
                issues=$((issues + 1))
            fi
        done < <(find "$search_path" -name "$pattern" -type f -print0 2>/dev/null)
    done
    
    if [[ $issues -eq 0 ]]; then
        log_success "✓ 文件权限检查通过"
        return 0
    else
        log_error "✗ 发现 $issues 个权限问题"
        return 1
    fi
}

# 检查输入验证
check_input_validation() {
    local search_path="${1:-$PROJECT_ROOT}"
    local issues=0
    
    log_info "检查输入验证..."
    
    # 检查是否有输入验证函数
    local validation_functions=$(grep -r "sanitize_input\|validate_" "$search_path/modules/" 2>/dev/null | wc -l)
    
    if [[ $validation_functions -lt 5 ]]; then
        log_warn "输入验证函数较少: $validation_functions"
        issues=$((issues + 1))
    fi
    
    # 检查直接使用用户输入的地方
    local unsafe_patterns=(
        "echo.*\$"
        "eval.*\$"
        "exec.*\$"
        "system.*\$"
    )
    
    for pattern in "${unsafe_patterns[@]}"; do
        if grep -r "$pattern" "$search_path" --include="*.sh" >/dev/null 2>&1; then
            log_warn "发现可能的命令注入风险: $pattern"
            issues=$((issues + 1))
        fi
    done
    
    if [[ $issues -eq 0 ]]; then
        log_success "✓ 输入验证检查通过"
        return 0
    else
        log_error "✗ 发现 $issues 个输入验证问题"
        return 1
    fi
}

# 检查网络安全
check_network_security() {
    local issues=0
    
    log_info "检查网络安全..."
    
    # 检查是否使用HTTPS
    if grep -r "http://" "$PROJECT_ROOT" --include="*.sh" --include="*.conf" >/dev/null 2>&1; then
        log_warn "发现HTTP连接，建议使用HTTPS"
        issues=$((issues + 1))
    fi
    
    # 检查端口配置
    if grep -r "port.*=.*[0-9]" "$PROJECT_ROOT" --include="*.sh" --include="*.conf" >/dev/null 2>&1; then
        log_info "发现端口配置，请确保使用安全端口"
    fi
    
    # 检查防火墙配置
    if ! command -v iptables &> /dev/null; then
        log_warn "iptables未安装，无法检查防火墙配置"
    fi
    
    if [[ $issues -eq 0 ]]; then
        log_success "✓ 网络安全检查通过"
        return 0
    else
        log_error "✗ 发现 $issues 个网络安全问题"
        return 1
    fi
}

# ================================================================
# 密钥管理
# ================================================================

# 生成安全密钥
generate_secure_key() {
    local key_type="${1:-random}"
    local key_length="${2:-32}"
    
    case "$key_type" in
        "random")
            if command -v openssl &> /dev/null; then
                openssl rand -hex "$key_length"
            elif command -v head &> /dev/null && [[ -c /dev/urandom ]]; then
                head -c "$key_length" /dev/urandom | xxd -p -c "$key_length"
            else
                # 简单的随机字符串生成
                cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c "$key_length"
            fi
            ;;
        "wireguard")
            if command -v wg &> /dev/null; then
                wg genkey
            else
                log_error "WireGuard未安装，无法生成密钥"
                return 1
            fi
            ;;
        *)
            log_error "不支持的密钥类型: $key_type"
            return 1
            ;;
    esac
}

# 安全存储密钥
store_secure_key() {
    local key="$1"
    local key_file="$2"
    local permissions="${3:-600}"
    
    # 创建密钥文件
    echo "$key" > "$key_file"
    
    # 设置安全权限
    chmod "$permissions" "$key_file"
    
    # 设置所有者
    if command -v chown &> /dev/null; then
        chown root:root "$key_file" 2>/dev/null || true
    fi
    
    log_debug "密钥已安全存储: $key_file"
}

# ================================================================
# 安全日志
# ================================================================

# 记录安全事件
log_security_event() {
    local event_type="$1"
    local event_message="$2"
    local severity="${3:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local security_log_file="${IPV6WGM_LOG_DIR}/security.log"
    
    # 确保日志目录存在
    mkdir -p "$(dirname "$security_log_file")"
    
    # 记录安全事件
    echo "[$timestamp] [$severity] [$event_type] $event_message" >> "$security_log_file"
    
    # 根据严重程度决定是否输出到控制台
    case "$severity" in
        "CRITICAL"|"ERROR")
            log_error "安全事件: $event_message"
            ;;
        "WARNING")
            log_warn "安全事件: $event_message"
            ;;
        *)
            log_debug "安全事件: $event_message"
            ;;
    esac
}

# 检查安全日志
check_security_logs() {
    local log_file="${IPV6WGM_LOG_DIR}/security.log"
    
    if [[ ! -f "$log_file" ]]; then
        log_info "安全日志文件不存在: $log_file"
        return 0
    fi
    
    # 检查最近的错误和警告
    local error_count=$(grep -c "\[ERROR\]\|\[CRITICAL\]" "$log_file" 2>/dev/null || echo "0")
    local warning_count=$(grep -c "\[WARNING\]" "$log_file" 2>/dev/null || echo "0")
    
    if [[ $error_count -gt 0 ]]; then
        log_warn "发现 $error_count 个安全错误"
    fi
    
    if [[ $warning_count -gt 0 ]]; then
        log_info "发现 $warning_count 个安全警告"
    fi
    
    log_success "安全日志检查完成"
}

# ================================================================
# 主安全测试函数
# ================================================================

# 运行所有安全测试
run_security_tests() {
    log_info "开始运行安全测试..."
    
    local total_issues=0
    
    # 检查硬编码凭据
    if ! check_hardcoded_credentials; then
        total_issues=$((total_issues + 1))
    fi
    
    # 检查文件权限
    if ! check_file_permissions; then
        total_issues=$((total_issues + 1))
    fi
    
    # 检查输入验证
    if ! check_input_validation; then
        total_issues=$((total_issues + 1))
    fi
    
    # 检查网络安全
    if ! check_network_security; then
        total_issues=$((total_issues + 1))
    fi
    
    # 检查安全日志
    check_security_logs
    
    if [[ $total_issues -eq 0 ]]; then
        log_success "✓ 所有安全测试通过"
        return 0
    else
        log_error "✗ 发现 $total_issues 个安全问题"
        return 1
    fi
}

# ================================================================
# 导出函数
# ================================================================

export -f sanitize_input validate_input_format validate_ip_address validate_port validate_mac_address
export -f secure_store_config secure_read_config set_secure_permissions
export -f check_hardcoded_credentials check_file_permissions check_input_validation check_network_security
export -f generate_secure_key store_secure_key
export -f log_security_event check_security_logs
export -f run_security_tests
