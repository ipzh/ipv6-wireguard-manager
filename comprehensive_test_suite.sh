#!/bin/bash

# 全面测试套件
# 测试所有核心功能模块

# set -e  # 注释掉，避免测试中断

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_TESTS++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_TESTS++))
}

log_warning() {
    : # 空函数体
}

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TOTAL_TESTS++))
    log_info "Running test: $test_name"
    
    if eval "$test_command" 2>/dev/null; then
        log_success "$test_name"
        return 0
    else
        log_error "$test_name"
        return 1
    fi
}

# 测试公共函数库
test_common_functions() {
    log_info "=== 测试公共函数库 ==="
    
    # 测试日志函数
    run_test "日志函数测试" "source modules/common_functions.sh && log_info 'test' > /dev/null"
    
    # 测试系统检测函数
    run_test "系统检测函数测试" "source modules/system_detection.sh && detect_os > /dev/null"
    
    # 测试配置管理函数
    run_test "配置管理函数测试" "source modules/config_manager.sh && load_config > /dev/null"
    
    # 测试错误处理函数
    run_test "错误处理函数测试" "source modules/error_handling.sh && handle_error 'test' > /dev/null"
}

# 测试模块加载器
test_module_loader() {
    log_info "=== 测试模块加载器 ==="
    
    # 测试模块加载
    run_test "模块加载测试" "source modules/module_loader.sh && load_module 'common_functions' > /dev/null"
    
    # 测试增强模块加载器
    run_test "增强模块加载器测试" "source modules/enhanced_module_loader.sh && load_module 'common_functions' > /dev/null"
    
    # 测试模块依赖检查
    run_test "模块依赖检查测试" "source modules/enhanced_module_loader.sh && check_module_dependencies 'common_functions' > /dev/null"
}

# 测试脚本集成
test_script_integration() {
    log_info "=== 测试脚本集成 ==="
    
    # 测试主脚本加载
    run_test "主脚本加载测试" "bash -c 'source ipv6-wireguard-manager.sh --help > /dev/null'"
    
    # 测试模块间通信
    run_test "模块间通信测试" "bash -c 'source modules/common_functions.sh && source modules/config_manager.sh && echo \"Integration test passed\"'"
    
    # 测试配置一致性
    run_test "配置一致性测试" "bash -c 'source modules/unified_config.sh && validate_config > /dev/null'"
}

# 测试性能
test_performance() {
    log_info "=== 测试性能 ==="
    
    # 测试启动时间
    local start_time
    start_time=$(date +%s%N)
    bash -c "source ipv6-wireguard-manager.sh --help > /dev/null" 2>/dev/null
    local end_time
    end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))
    
    if [ $duration -lt 5000 ]; then
        log_success "启动时间测试 (${duration}ms)"
    else
        log_error "启动时间测试 (${duration}ms) - 超过5秒"
    fi
    
    # 测试内存使用
    run_test "内存使用测试" "bash -c 'source modules/resource_monitoring.sh && check_memory_usage > /dev/null'"
}

# 测试监控模块
test_monitoring() {
    log_info "=== 测试监控模块 ==="
    
    # 测试系统监控
    run_test "系统监控测试" "bash -c 'source modules/system_monitoring.sh && monitor_system > /dev/null'"
    
    # 测试资源监控
    run_test "资源监控测试" "bash -c 'source modules/resource_monitoring.sh && monitor_resources > /dev/null'"
    
    # 测试安全监控
    run_test "安全监控测试" "bash -c 'source modules/security_audit_monitoring.sh && audit_system > /dev/null'"
}

# 测试WireGuard配置生成
test_wireguard_config() {
    log_info "=== 测试WireGuard配置生成 ==="
    
    # 测试配置生成
    run_test "WireGuard配置生成测试" "bash -c 'source modules/wireguard_config.sh && generate_server_config > /dev/null'"
    
    # 测试BIRD配置
    run_test "BIRD配置测试" "bash -c 'source modules/bird_config.sh && generate_bird_config > /dev/null'"
    
    # 测试防火墙配置
    run_test "防火墙配置测试" "bash -c 'source modules/firewall_management.sh && configure_firewall > /dev/null'"
}

# 测试客户端管理
test_client_management() {
    log_info "=== 测试客户端管理 ==="
    
    # 测试客户端管理
    run_test "客户端管理测试" "bash -c 'source modules/client_management.sh && list_clients > /dev/null'"
    
    # 测试客户端自动安装
    run_test "客户端自动安装测试" "bash -c 'source modules/client_auto_install.sh && check_requirements > /dev/null'"
    
    # 测试网络管理
    run_test "网络管理测试" "bash -c 'source modules/network_management.sh && check_network_status > /dev/null'"
}

# 测试异常情况
test_exception_handling() {
    log_info "=== 测试异常情况 ==="
    
    # 测试错误处理
    run_test "错误处理测试" "bash -c 'source modules/advanced_error_handling.sh && handle_error \"test error\" > /dev/null'"
    
    # 测试自诊断
    run_test "自诊断测试" "bash -c 'source modules/self_diagnosis.sh && diagnose_system > /dev/null'"
    
    # 测试兼容性
    run_test "兼容性测试" "bash -c 'source modules/enhanced_system_compatibility.sh && check_compatibility > /dev/null'"
    
    # 测试Windows兼容性
    run_test "Windows兼容性测试" "bash -c 'source modules/windows_compatibility.sh && check_windows_compatibility > /dev/null'"
}

# 测试功能测试模块
test_functional_tests() {
    log_info "=== 测试功能测试模块 ==="
    
    # 测试功能测试框架
    run_test "功能测试框架测试" "bash -c 'source modules/functional_tests.sh && run_functional_tests > /dev/null'"
    
    # 测试安全功能
    run_test "安全功能测试" "bash -c 'source modules/security_functions.sh && test_security_functions > /dev/null'"
}

# 主测试函数
main() {
    log_info "开始全面测试套件..."
    echo "=========================================="
    
    # 创建测试环境
    mkdir -p /tmp/ipv6-wireguard-test
    cd /tmp/ipv6-wireguard-test || exit
    
    # 复制必要文件到测试目录
    cp -r /d/IPv6-\ WireGuard\ -manager/* . 2>/dev/null || true
    
    # 运行所有测试
    test_common_functions
    test_module_loader
    test_script_integration
    test_performance
    test_monitoring
    test_wireguard_config
    test_client_management
    test_exception_handling
    test_functional_tests
    
    # 显示测试结果
    echo "=========================================="
    log_info "测试完成！"
    echo "总测试数: $TOTAL_TESTS"
    echo "通过: $PASSED_TESTS"
    echo "失败: $FAILED_TESTS"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "所有测试通过！"
        exit 0
    else
        log_error "有 $FAILED_TESTS 个测试失败"
        exit 1
    fi
}

# 运行主函数
main "$@"
