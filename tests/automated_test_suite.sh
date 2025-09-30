#!/bin/bash

# IPv6 WireGuard Manager 自动化测试套件
# 使用统一测试框架进行全面的单元测试、集成测试、性能测试和兼容性测试

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 导入统一测试框架
if [[ -f "$PROJECT_ROOT/modules/unified_test_framework.sh" ]]; then
    source "$PROJECT_ROOT/modules/unified_test_framework.sh"
else
    echo "错误: 无法导入统一测试框架" >&2
    exit 1
fi

# 导入其他必要模块
if [[ -f "$PROJECT_ROOT/modules/common_functions.sh" ]]; then
    source "$PROJECT_ROOT/modules/common_functions.sh"
fi

# 导入测试用例库
if [[ -f "$PROJECT_ROOT/tests/test_cases.sh" ]]; then
    source "$PROJECT_ROOT/tests/test_cases.sh"
fi

# =============================================================================
# 测试执行函数
# =============================================================================

# 执行所有测试
run_all_tests() {
    # 初始化测试环境
    init_test_environment
    
    # 设置测试配置
    set_test_config true false false 300 3
    
    # 运行具体测试
    run_unit_tests
    run_integration_tests
    run_performance_tests
    run_compatibility_tests
    
    # 生成测试报告
    generate_test_report
    
    # 清理测试环境
    cleanup_test_environment
}

# =============================================================================
# 单元测试
# =============================================================================

# 运行单元测试
run_unit_tests() {
    test_info "运行单元测试..."
    
    # 测试配置管理模块
    test_config_management
    
    # 测试网络管理模块
    test_network_management
    
    # 测试客户端管理模块
    test_client_management
    
    # 测试系统检测模块
    test_system_detection
    
    # 测试公共函数模块
    test_common_functions
}

# 测试配置管理模块
test_config_management() {
    test_info "测试配置管理模块..."
    
    # 运行配置管理相关测试用例
    test_config_manager_init
    test_config_validation
    test_config_cache
}

# 测试网络管理模块
test_network_management() {
    test_info "测试网络管理模块..."
    
    # 运行网络管理相关测试用例
    test_network_interface_detection
    test_ipv6_prefix_validation
}

# 测试客户端管理模块
test_client_management() {
    test_info "测试客户端管理模块..."
    
    # 运行客户端管理相关测试用例
    test_client_config_generation
    test_client_config_template
}

# 测试系统检测模块
test_system_detection() {
    test_info "测试系统检测模块..."
    
    # 运行系统检测相关测试用例
    test_os_detection
    test_kernel_version_detection
}

# 测试公共函数模块
test_common_functions() {
    test_info "测试公共函数模块..."
    
    # 运行公共函数相关测试用例
    test_variable_initialization
    test_logging_functionality
    test_directory_creation
}

# =============================================================================
# 集成测试
# =============================================================================

# 运行集成测试
run_integration_tests() {
    test_info "运行集成测试..."
    
    # 测试模块间交互
    test_module_interaction
    
    # 测试端到端流程
    test_end_to_end_flow
    
    # 测试错误处理
    test_error_handling
}

# 测试模块间交互
test_module_interaction() {
    test_info "测试模块间交互..."
    
    # 测试配置管理与其他模块的交互
    if init_config_manager; then
        test_success "配置管理模块初始化成功"
        
        # 测试配置读取
        local config_value=$(get_cached_config_item "SYSTEM_NAME" "默认值")
        assert_not_equal "$config_value" "默认值" "配置读取功能"
        
        # 测试配置验证
        if validate_config; then
            test_success "配置验证通过"
        else
            test_error "配置验证失败"
            return 1
        fi
    else
        test_error "配置管理模块初始化失败"
        return 1
    fi
}

# 测试端到端流程
test_end_to_end_flow() {
    test_info "测试端到端流程..."
    
    # 模拟完整的配置流程
    local test_config_file="/tmp/test_config_$(date +%s).conf"
    
    # 创建测试配置
    cat > "$test_config_file" << EOF
SYSTEM_NAME="Test System"
SYSTEM_VERSION="1.0.0"
NETWORK_IPV6_PREFIX="2001:db8::/64"
WIREGUARD_ENABLED=true
BIRD_ENABLED=true
FIREWALL_ENABLED=true
EOF
    
    # 测试配置加载
    if [[ -f "$test_config_file" ]]; then
        test_success "测试配置文件创建成功"
        
        # 测试配置验证
        if validate_config "$test_config_file" "main"; then
            test_success "测试配置验证通过"
        else
            test_error "测试配置验证失败"
        fi
        
        # 清理测试文件
        rm -f "$test_config_file"
    else
        test_error "测试配置文件创建失败"
        return 1
    fi
}

# 测试错误处理
test_error_handling() {
    test_info "测试错误处理..."
    
    # 测试无效配置处理
    local invalid_config_file="/tmp/invalid_config_$(date +%s).conf"
    
    # 创建无效配置
    cat > "$invalid_config_file" << EOF
INVALID_CONFIG=invalid_value
MISSING_REQUIRED_FIELD=
EOF
    
    # 测试错误检测
    if ! validate_config "$invalid_config_file" "main"; then
        test_success "无效配置被正确检测"
    else
        test_error "无效配置未被检测"
    fi
    
    # 清理测试文件
    rm -f "$invalid_config_file"
}

# =============================================================================
# 性能测试
# =============================================================================

# 运行性能测试
run_performance_tests() {
    test_info "运行性能测试..."
    
    # 测试配置加载性能
    test_config_loading_performance
    
    # 测试模块导入性能
    test_module_import_performance
    
    # 测试内存使用
    test_memory_usage
}

# 测试配置加载性能
test_config_loading_performance() {
    test_info "测试配置加载性能..."
    test_config_loading_performance
}

# 测试模块导入性能
test_module_import_performance() {
    test_info "测试模块导入性能..."
    test_module_import_performance
}

# 测试内存使用
test_memory_usage() {
    test_info "测试内存使用..."
    test_memory_usage
}

# =============================================================================
# 兼容性测试
# =============================================================================

# 运行兼容性测试
run_compatibility_tests() {
    test_info "运行兼容性测试..."
    
    # 测试操作系统兼容性
    test_os_compatibility
    
    # 测试Shell兼容性
    test_shell_compatibility
    
    # 测试工具依赖
    test_tool_dependencies
}

# 测试操作系统兼容性
test_os_compatibility() {
    test_info "测试操作系统兼容性..."
    
    # 检测操作系统类型
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        test_success "检测到操作系统: $NAME $VERSION"
        
        # 测试支持的发行版
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
}

# 测试Shell兼容性
test_shell_compatibility() {
    test_info "测试Shell兼容性..."
    
    # 测试Bash版本
    local bash_version=$(bash --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -n1)
    assert_greater_than "${bash_version%%.*}" 3 "Bash版本兼容性"
    
    # 测试Shell特性
    if [[ "${BASH_VERSION%%.*}" -ge 4 ]]; then
        test_success "Bash版本支持关联数组"
    else
        test_error "Bash版本过低，不支持关联数组"
        return 1
    fi
}

# 测试工具依赖
test_tool_dependencies() {
    test_info "测试工具依赖..."
    
    # 必需工具列表
    local required_tools=("bash" "grep" "sed" "awk" "cut" "sort" "uniq")
    
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            test_success "工具可用: $tool"
        else
            test_error "工具不可用: $tool"
            return 1
        fi
    done
    
    # 可选工具
    local optional_tools=("yq" "jq" "curl" "wget")
    
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            test_success "可选工具可用: $tool"
        else
            test_warning "可选工具不可用: $tool"
        fi
    done
}

# =============================================================================
# 主执行函数
# =============================================================================

# 主函数
main() {
    echo "IPv6 WireGuard Manager 自动化测试套件"
    echo "======================================"
    echo
    
    # 检查参数
    case "${1:-all}" in
        "unit")
            test_info "运行单元测试..."
            run_unit_tests
            ;;
        "integration")
            test_info "运行集成测试..."
            run_integration_tests
            ;;
        "performance")
            test_info "运行性能测试..."
            run_performance_tests
            ;;
        "compatibility")
            test_info "运行兼容性测试..."
            run_compatibility_tests
            ;;
        "all"|*)
            test_info "运行所有测试..."
            run_all_tests
            ;;
    esac
}

# 如果直接执行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi