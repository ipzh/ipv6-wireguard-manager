#!/bin/bash

# IPv6 WireGuard Manager 测试用例库
# 提供完整的测试用例实现

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 导入统一测试框架
if [[ -f "$PROJECT_ROOT/modules/unified_test_framework.sh" ]]; then
    source "$PROJECT_ROOT/modules/unified_test_framework.sh"
else
    echo "错误: 无法导入统一测试框架" >&2
    exit 1
fi

# 导入公共函数
if [[ -f "$PROJECT_ROOT/modules/common_functions.sh" ]]; then
    source "$PROJECT_ROOT/modules/common_functions.sh"
fi

# =============================================================================
# 配置管理测试用例
# =============================================================================

# 测试配置管理模块初始化
test_config_manager_init() {
    local test_name="配置管理模块初始化"
    test_info "运行测试: $test_name"
    
    # 测试配置目录创建
    local config_dir="/tmp/test_config_$(date +%s)"
    mkdir -p "$config_dir"
    
    # 设置测试环境变量
    local original_config_dir="${IPV6WGM_CONFIG_DIR:-}"
    export IPV6WGM_CONFIG_DIR="$config_dir"
    
    # 测试初始化函数
    if init_config_manager; then
        test_success "配置管理模块初始化成功"
        
        # 验证配置目录结构
        local required_dirs=("$config_dir" "$config_dir/backup" "$config_dir/templates")
        for dir in "${required_dirs[@]}"; do
            if [[ -d "$dir" ]]; then
                test_success "配置目录存在: $dir"
            else
                test_error "配置目录不存在: $dir"
                return 1
            fi
        done
        
        # 验证默认配置文件
        if [[ -f "$config_dir/manager.conf" ]]; then
            test_success "默认配置文件已创建"
        else
            test_error "默认配置文件未创建"
            return 1
        fi
        
    else
        test_error "配置管理模块初始化失败"
        return 1
    fi
    
    # 清理测试环境
    rm -rf "$config_dir"
    export IPV6WGM_CONFIG_DIR="$original_config_dir"
    
    return 0
}

# 测试配置验证功能
test_config_validation() {
    local test_name="配置验证功能"
    test_info "运行测试: $test_name"
    
    # 创建测试配置文件
    local test_config_file="/tmp/test_config_$(date +%s).conf"
    
    # 测试有效配置
    cat > "$test_config_file" << 'EOF'
SYSTEM_NAME="Test System"
SYSTEM_VERSION="1.0.0"
NETWORK_IPV6_PREFIX="2001:db8::/64"
WIREGUARD_ENABLED=true
BIRD_ENABLED=false
FIREWALL_ENABLED=false
EOF
    
    if validate_config "$test_config_file" "main"; then
        test_success "有效配置验证通过"
    else
        test_error "有效配置验证失败"
        rm -f "$test_config_file"
        return 1
    fi
    
    # 测试无效配置
    cat > "$test_config_file" << 'EOF'
INVALID_CONFIG=invalid_value
MISSING_REQUIRED_FIELD=
EOF
    
    if ! validate_config "$test_config_file" "main"; then
        test_success "无效配置被正确检测"
    else
        test_error "无效配置未被检测"
        rm -f "$test_config_file"
        return 1
    fi
    
    # 清理
    rm -f "$test_config_file"
    return 0
}

# 测试配置缓存功能
test_config_cache() {
    local test_name="配置缓存功能"
    test_info "运行测试: $test_name"
    
    # 测试缓存初始化
    if init_config_manager; then
        test_success "配置缓存初始化成功"
    else
        test_error "配置缓存初始化失败"
        return 1
    fi
    
    # 测试缓存有效性检查
    if is_config_cache_valid; then
        test_success "配置缓存有效性检查通过"
    else
        test_warning "配置缓存无效，将重新加载"
        load_config_to_cache
    fi
    
    # 测试缓存项存储和检索
    local test_key="test_key_$(date +%s)"
    local test_value="test_value_$(date +%s)"
    
    if cache_config_item "$test_key" "$test_value"; then
        test_success "配置项缓存成功"
        
        local retrieved_value=$(get_cached_config_item "$test_key" "")
        if [[ "$retrieved_value" == "$test_value" ]]; then
            test_success "配置项检索成功"
        else
            test_error "配置项检索失败: 期望 '$test_value', 实际 '$retrieved_value'"
            return 1
        fi
    else
        test_error "配置项缓存失败"
        return 1
    fi
    
    return 0
}

# =============================================================================
# 网络管理测试用例
# =============================================================================

# 测试网络接口检测
test_network_interface_detection() {
    local test_name="网络接口检测"
    test_info "运行测试: $test_name"
    
    # 检查ip命令可用性
    if command -v ip &> /dev/null; then
        test_success "ip命令可用"
        
        # 获取网络接口列表
        local interfaces=$(ip link show | grep -c "state UP" || echo "0")
        if [[ "$interfaces" -gt 0 ]]; then
            test_success "检测到 $interfaces 个活跃网络接口"
        else
            test_warning "未检测到活跃网络接口"
        fi
    else
        test_warning "ip命令不可用，跳过网络接口检测"
    fi
    
    # 检查IPv6支持
    if [[ -f /proc/net/if_inet6 ]]; then
        test_success "系统支持IPv6"
        
        # 检查IPv6地址
        local ipv6_addresses=$(ip -6 addr show | grep -c "inet6" || echo "0")
        if [[ "$ipv6_addresses" -gt 0 ]]; then
            test_success "检测到 $ipv6_addresses 个IPv6地址"
        else
            test_warning "未检测到IPv6地址"
        fi
    else
        test_warning "系统不支持IPv6"
    fi
    
    return 0
}

# 测试IPv6前缀验证
test_ipv6_prefix_validation() {
    local test_name="IPv6前缀验证"
    test_info "运行测试: $test_name"
    
    # 测试有效IPv6前缀
    local valid_prefixes=(
        "2001:db8::/64"
        "2001:db8:1::/64"
        "fd00:dead:beef::/64"
        "::1/128"
    )
    
    for prefix in "${valid_prefixes[@]}"; do
        if validate_ipv6_prefix "$prefix"; then
            test_success "有效IPv6前缀验证通过: $prefix"
        else
            test_error "有效IPv6前缀验证失败: $prefix"
            return 1
        fi
    done
    
    # 测试无效IPv6前缀
    local invalid_prefixes=(
        "192.168.1.0/24"
        "invalid_prefix"
        "2001:db8::/129"
        "2001:db8::/0"
    )
    
    for prefix in "${invalid_prefixes[@]}"; do
        if ! validate_ipv6_prefix "$prefix"; then
            test_success "无效IPv6前缀被正确检测: $prefix"
        else
            test_error "无效IPv6前缀未被检测: $prefix"
            return 1
        fi
    done
    
    return 0
}

# =============================================================================
# 客户端管理测试用例
# =============================================================================

# 测试客户端配置生成
test_client_config_generation() {
    local test_name="客户端配置生成"
    test_info "运行测试: $test_name"
    
    # 创建测试客户端数据
    local test_client_data="/tmp/test_client_$(date +%s).csv"
    cat > "$test_client_data" << 'EOF'
name,public_key,allowed_ips,description
test-client-1,test-public-key-1,10.0.0.2/32,fd00:dead:beef::2/128,测试客户端1
test-client-2,test-public-key-2,10.0.0.3/32,fd00:dead:beef::3/128,测试客户端2
EOF
    
    # 测试客户端配置解析
    if [[ -f "$test_client_data" ]]; then
        test_success "测试客户端数据文件创建成功"
        
        # 验证CSV格式
        local line_count=$(wc -l < "$test_client_data")
        if [[ "$line_count" -eq 3 ]]; then
            test_success "客户端数据格式正确 (3行)"
        else
            test_error "客户端数据格式错误: 期望3行，实际$line_count行"
            rm -f "$test_client_data"
            return 1
        fi
    else
        test_error "测试客户端数据文件创建失败"
        return 1
    fi
    
    # 清理
    rm -f "$test_client_data"
    return 0
}

# 测试客户端配置模板
test_client_config_template() {
    local test_name="客户端配置模板"
    test_info "运行测试: $test_name"
    
    # 检查客户端配置模板
    local client_template="${IPV6WGM_CONFIG_TEMPLATES_DIR}/client.yaml"
    if [[ -f "$client_template" ]]; then
        test_success "客户端配置模板存在"
        
        # 验证模板内容
        if grep -q "{{PRIVATE_KEY}}" "$client_template"; then
            test_success "模板包含必要的占位符"
        else
            test_warning "模板可能缺少必要的占位符"
        fi
    else
        test_warning "客户端配置模板不存在，将创建"
        
        # 创建基本模板
        mkdir -p "$(dirname "$client_template")"
        cat > "$client_template" << 'EOF'
# 客户端配置模板
[Interface]
PrivateKey = {{PRIVATE_KEY}}
Address = {{CLIENT_IPV4}}/32, {{CLIENT_IPV6}}/128
DNS = {{DNS_SERVER}}

[Peer]
PublicKey = {{SERVER_PUBLIC_KEY}}
Endpoint = {{SERVER_ENDPOINT}}:{{SERVER_PORT}}
AllowedIPs = {{ALLOWED_IPS}}
PersistentKeepalive = 25
EOF
        test_success "客户端配置模板已创建"
    fi
    
    return 0
}

# =============================================================================
# 系统检测测试用例
# =============================================================================

# 测试操作系统检测
test_os_detection() {
    local test_name="操作系统检测"
    test_info "运行测试: $test_name"
    
    # 检测操作系统类型
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        test_success "检测到操作系统: $NAME $VERSION"
        
        # 验证支持的发行版
        case "$ID" in
            "ubuntu"|"debian"|"centos"|"rhel"|"fedora"|"arch"|"opensuse")
                test_success "支持的操作系统: $ID"
                ;;
            *)
                test_warning "未测试的操作系统: $ID"
                ;;
        esac
    else
        test_warning "无法检测操作系统信息"
    fi
    
    # 检测系统架构
    local arch=$(uname -m)
    case "$arch" in
        "x86_64"|"aarch64"|"arm64"|"armv7l")
            test_success "支持的架构: $arch"
            ;;
        *)
            test_warning "未测试的架构: $arch"
            ;;
    esac
    
    return 0
}

# 测试内核版本检测
test_kernel_version_detection() {
    local test_name="内核版本检测"
    test_info "运行测试: $test_name"
    
    local kernel_version=$(uname -r)
    test_success "检测到内核版本: $kernel_version"
    
    # 验证内核版本格式
    if [[ "$kernel_version" =~ ^[0-9]+\.[0-9]+ ]]; then
        test_success "内核版本格式正确"
        
        # 检查最低版本要求
        local major_version=$(echo "$kernel_version" | cut -d. -f1)
        if [[ "$major_version" -ge 4 ]]; then
            test_success "内核版本满足最低要求 (4.0+)"
        else
            test_warning "内核版本可能过低: $kernel_version (需要 4.0+)"
        fi
    else
        test_error "内核版本格式不正确: $kernel_version"
        return 1
    fi
    
    return 0
}

# =============================================================================
# 公共函数测试用例
# =============================================================================

# 测试变量初始化
test_variable_initialization() {
    local test_name="变量初始化"
    test_info "运行测试: $test_name"
    
    # 测试变量初始化函数
    if ensure_variables; then
        test_success "变量初始化成功"
        
        # 验证关键变量
        local required_vars=(
            "IPV6WGM_CONFIG_DIR"
            "IPV6WGM_LOG_DIR"
            "IPV6WGM_SCRIPT_DIR"
            "IPV6WGM_MODULES_DIR"
        )
        
        for var in "${required_vars[@]}"; do
            if [[ -n "${!var:-}" ]]; then
                test_success "变量已设置: $var=${!var}"
            else
                test_error "变量未设置: $var"
                return 1
            fi
        done
    else
        test_error "变量初始化失败"
        return 1
    fi
    
    return 0
}

# 测试日志功能
test_logging_functionality() {
    local test_name="日志功能"
    test_info "运行测试: $test_name"
    
    # 测试各种日志级别
    local log_functions=("log_info" "log_success" "log_warning" "log_error" "log_debug")
    
    for log_func in "${log_functions[@]}"; do
        if declare -f "$log_func" > /dev/null; then
            test_success "日志函数可用: $log_func"
            
            # 测试日志输出
            if "$log_func" "测试日志消息" > /dev/null 2>&1; then
                test_success "日志函数工作正常: $log_func"
            else
                test_error "日志函数工作异常: $log_func"
                return 1
            fi
        else
            test_error "日志函数不可用: $log_func"
            return 1
        fi
    done
    
    return 0
}

# 测试目录创建功能
test_directory_creation() {
    local test_name="目录创建功能"
    test_info "运行测试: $test_name"
    
    # 创建测试目录
    local test_dir="/tmp/test_dir_$(date +%s)"
    
    if mkdir -p "$test_dir" && [[ -d "$test_dir" ]]; then
        test_success "目录创建成功: $test_dir"
        
        # 测试子目录创建
        local sub_dir="$test_dir/subdir"
        if mkdir -p "$sub_dir" && [[ -d "$sub_dir" ]]; then
            test_success "子目录创建成功: $sub_dir"
        else
            test_error "子目录创建失败: $sub_dir"
            rm -rf "$test_dir"
            return 1
        fi
        
        # 测试权限
        if [[ -w "$test_dir" ]]; then
            test_success "目录权限正确"
        else
            test_error "目录权限错误"
            rm -rf "$test_dir"
            return 1
        fi
        
    else
        test_error "目录创建失败: $test_dir"
        return 1
    fi
    
    # 清理
    rm -rf "$test_dir"
    return 0
}

# =============================================================================
# 性能测试用例
# =============================================================================

# 测试配置加载性能
test_config_loading_performance() {
    local test_name="配置加载性能"
    test_info "运行测试: $test_name"
    
    local start_time=$(date +%s%N)
    
    # 测试配置加载时间
    if load_config_to_cache; then
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))  # 转换为毫秒
        
        test_success "配置加载完成，耗时: ${duration}ms"
        
        # 性能断言：配置加载应在100ms内完成
        if [[ "$duration" -lt 100 ]]; then
            test_success "配置加载性能满足要求 (<100ms)"
        else
            test_warning "配置加载性能较慢: ${duration}ms (建议 <100ms)"
        fi
    else
        test_error "配置加载失败"
        return 1
    fi
    
    return 0
}

# 测试模块导入性能
test_module_import_performance() {
    local test_name="模块导入性能"
    test_info "运行测试: $test_name"
    
    local start_time=$(date +%s%N)
    
    # 测试模块导入时间
    if source "$PROJECT_ROOT/modules/common_functions.sh"; then
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))  # 转换为毫秒
        
        test_success "模块导入完成，耗时: ${duration}ms"
        
        # 性能断言：模块导入应在50ms内完成
        if [[ "$duration" -lt 50 ]]; then
            test_success "模块导入性能满足要求 (<50ms)"
        else
            test_warning "模块导入性能较慢: ${duration}ms (建议 <50ms)"
        fi
    else
        test_error "模块导入失败"
        return 1
    fi
    
    return 0
}

# 测试内存使用
test_memory_usage() {
    local test_name="内存使用"
    test_info "运行测试: $test_name"
    
    # 获取当前内存使用
    local memory_before=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")
    
    # 执行一些操作
    init_test_environment
    init_config_manager
    
    # 获取操作后内存使用
    local memory_after=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")
    local memory_diff=$((memory_after - memory_before))
    
    test_success "内存使用增加: ${memory_diff}KB"
    
    # 性能断言：内存使用增加应小于10MB
    if [[ "$memory_diff" -lt 10240 ]]; then
        test_success "内存使用控制良好 (<10MB)"
    else
        test_warning "内存使用较高: ${memory_diff}KB (建议 <10MB)"
    fi
    
    return 0
}

# =============================================================================
# 错误处理测试用例
# =============================================================================

# 测试错误检测和处理
test_error_detection() {
    local test_name="错误检测和处理"
    test_info "运行测试: $test_name"
    
    # 测试文件不存在错误
    local non_existent_file="/tmp/non_existent_file_$(date +%s)"
    if ! [[ -f "$non_existent_file" ]]; then
        test_success "文件不存在错误被正确检测"
    else
        test_error "文件不存在错误未被检测"
        return 1
    fi
    
    # 测试权限错误
    local protected_file="/root/protected_file_$(date +%s)"
    if ! touch "$protected_file" 2>/dev/null; then
        test_success "权限错误被正确检测"
    else
        test_warning "权限错误未被检测（可能以root权限运行）"
        rm -f "$protected_file"
    fi
    
    # 测试命令不存在错误
    if ! command -v "non_existent_command_$(date +%s)" &> /dev/null; then
        test_success "命令不存在错误被正确检测"
    else
        test_error "命令不存在错误未被检测"
        return 1
    fi
    
    return 0
}

# 测试错误恢复机制
test_error_recovery() {
    local test_name="错误恢复机制"
    test_info "运行测试: $test_name"
    
    # 测试配置错误恢复
    local invalid_config_file="/tmp/invalid_config_$(date +%s).conf"
    cat > "$invalid_config_file" << 'EOF'
INVALID_CONFIG=invalid_value
MISSING_REQUIRED_FIELD=
EOF
    
    # 测试错误检测
    if ! validate_config "$invalid_config_file" "main"; then
        test_success "配置错误被正确检测"
        
        # 测试默认配置恢复
        if create_default_config; then
            test_success "默认配置恢复成功"
        else
            test_warning "默认配置恢复失败"
        fi
    else
        test_error "配置错误未被检测"
        rm -f "$invalid_config_file"
        return 1
    fi
    
    # 清理
    rm -f "$invalid_config_file"
    return 0
}

# =============================================================================
# 导出测试函数
# =============================================================================

# 导出所有测试函数
export -f test_config_manager_init
export -f test_config_validation
export -f test_config_cache
export -f test_network_interface_detection
export -f test_ipv6_prefix_validation
export -f test_client_config_generation
export -f test_client_config_template
export -f test_os_detection
export -f test_kernel_version_detection
export -f test_variable_initialization
export -f test_logging_functionality
export -f test_directory_creation
export -f test_config_loading_performance
export -f test_module_import_performance
export -f test_memory_usage
export -f test_error_detection
export -f test_error_recovery
