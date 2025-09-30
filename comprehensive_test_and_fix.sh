#!/bin/bash

# 综合测试和修复脚本
set -e

echo "=== 开始综合测试和修复 ==="

# 创建必要的目录
mkdir -p /tmp/ipv6-wireguard-test/{logs,config,monitoring}
mkdir -p /var/log/ipv6-wireguard-manager 2>/dev/null || true
mkdir -p /var/lib/ipv6-wireguard-manager/monitoring 2>/dev/null || true

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TOTAL_TESTS++))
    echo "测试: $test_name"
    
    if eval "$test_command" 2>/dev/null; then
        echo "✓ $test_name 通过"
        ((PASSED_TESTS++))
        return 0
    else
        echo "✗ $test_name 失败"
        ((FAILED_TESTS++))
        return 1
    fi
}

# 修复函数
fix_issue() {
    local issue="$1"
    local fix_command="$2"
    
    echo "修复: $issue"
    if eval "$fix_command"; then
        echo "✓ $issue 修复成功"
        return 0
    else
        echo "✗ $issue 修复失败"
        return 1
    fi
}

echo "1. 测试基础模块加载..."
run_test "公共函数库" "bash -c 'source modules/common_functions.sh && echo OK'"
run_test "系统检测" "bash -c 'source modules/system_detection.sh && echo OK'"
run_test "配置管理" "bash -c 'source modules/config_manager.sh && echo OK'"
run_test "错误处理" "bash -c 'source modules/error_handling.sh && echo OK'"

echo "2. 测试模块加载器..."
run_test "增强模块加载器" "bash -c 'source modules/enhanced_module_loader.sh && load_module_smart common_functions && echo OK'"

echo "3. 测试脚本集成..."
run_test "主脚本帮助" "bash ipv6-wireguard-manager.sh --help > /dev/null"
run_test "主脚本版本" "bash ipv6-wireguard-manager.sh --version > /dev/null"

echo "4. 测试性能..."
echo "启动时间测试..."
start_time=$(date +%s%N)
bash ipv6-wireguard-manager.sh --help > /dev/null 2>&1
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo "启动时间: ${duration}ms"

echo "5. 测试监控模块..."
run_test "系统监控" "bash -c 'source modules/system_monitoring.sh && collect_system_metrics && echo OK'"

echo "6. 测试WireGuard配置..."
run_test "WireGuard配置" "bash -c 'source modules/wireguard_config.sh && create_server_config && echo OK'"

echo "7. 测试客户端管理..."
run_test "客户端管理" "bash -c 'source modules/client_management.sh && list_clients && echo OK'"

echo "8. 测试异常处理..."
run_test "高级错误处理" "bash -c 'source modules/advanced_error_handling.sh && handle_error test && echo OK'"

echo "9. 测试功能测试模块..."
run_test "功能测试" "bash -c 'source modules/functional_tests.sh && echo OK'"
run_test "安全功能" "bash -c 'source modules/security_functions.sh && echo OK'"

echo "10. 测试Windows兼容性..."
run_test "Windows兼容性" "bash -c 'source modules/windows_compatibility.sh && echo OK'"

# 显示测试结果
echo "=========================================="
echo "测试完成！"
echo "总测试数: $TOTAL_TESTS"
echo "通过: $PASSED_TESTS"
echo "失败: $FAILED_TESTS"

if [ $FAILED_TESTS -gt 0 ]; then
    echo "开始修复问题..."
    
    # 修复日志目录权限问题
    fix_issue "创建日志目录" "mkdir -p /var/log/ipv6-wireguard-manager && chmod 755 /var/log/ipv6-wireguard-manager"
    
    # 修复监控目录问题
    fix_issue "创建监控目录" "mkdir -p /var/lib/ipv6-wireguard-manager/monitoring && chmod 755 /var/lib/ipv6-wireguard-manager/monitoring"
    
    echo "修复完成，重新运行测试..."
    bash comprehensive_test_and_fix.sh
else
    echo "所有测试通过！"
fi
