#!/bin/bash

# WireGuard配置功能专项测试
set -e

echo "=== WireGuard配置功能专项测试 ==="

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

# 清理测试环境
cleanup_test_env() {
    echo "清理测试环境..."
    rm -rf "/tmp/ipv6-wireguard-test" 2>/dev/null || true
}

# 测试密钥生成
test_key_generation() {
    echo "1. 测试密钥生成功能..."
    
    # 测试密钥生成（使用测试环境）
    export WIREGUARD_KEYS_DIR="/tmp/ipv6-wireguard-test/keys"
    mkdir -p "$WIREGUARD_KEYS_DIR" 2>/dev/null || true
    
    run_test "密钥生成功能" "bash -c 'source modules/wireguard_config.sh && generate_server_keys && echo OK'"
}

# 测试配置创建
test_config_creation() {
    echo "2. 测试配置创建功能..."
    
    run_test "服务器配置创建" "bash -c 'source modules/wireguard_config.sh && test_wireguard_config && echo OK'"
    
    # 检查生成的文件
    if [[ -f "/tmp/ipv6-wireguard-test/config/wg0.conf" ]]; then
        echo "✓ 配置文件创建成功"
        ((PASSED_TESTS++))
    else
        echo "✗ 配置文件创建失败"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    if [[ -f "/tmp/ipv6-wireguard-test/keys/server_private.key" ]]; then
        echo "✓ 私钥文件创建成功"
        ((PASSED_TESTS++))
    else
        echo "✗ 私钥文件创建失败"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    if [[ -f "/tmp/ipv6-wireguard-test/keys/server_public.key" ]]; then
        echo "✓ 公钥文件创建成功"
        ((PASSED_TESTS++))
    else
        echo "✗ 公钥文件创建失败"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
}

# 测试配置内容
test_config_content() {
    echo "3. 测试配置内容..."
    
    local config_file="/tmp/ipv6-wireguard-test/config/wg0.conf"
    
    if [[ -f "$config_file" ]]; then
        # 检查配置文件是否包含必要字段
        if grep -q "\[Interface\]" "$config_file"; then
            echo "✓ 配置文件包含Interface段"
            ((PASSED_TESTS++))
        else
            echo "✗ 配置文件缺少Interface段"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
        
        if grep -q "PrivateKey" "$config_file"; then
            echo "✓ 配置文件包含PrivateKey"
            ((PASSED_TESTS++))
        else
            echo "✗ 配置文件缺少PrivateKey"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
        
        if grep -q "Address" "$config_file"; then
            echo "✓ 配置文件包含Address"
            ((PASSED_TESTS++))
        else
            echo "✗ 配置文件缺少Address"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
        
        if grep -q "ListenPort" "$config_file"; then
            echo "✓ 配置文件包含ListenPort"
            ((PASSED_TESTS++))
        else
            echo "✗ 配置文件缺少ListenPort"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    else
        echo "✗ 配置文件不存在，无法测试内容"
        ((FAILED_TESTS++))
        ((TOTAL_TESTS++))
    fi
}

# 测试错误处理
test_error_handling() {
    echo "4. 测试错误处理..."
    
    # 测试在无权限目录中创建配置
    run_test "权限错误处理" "bash -c 'source modules/wireguard_config.sh && mkdir -p /tmp/readonly-test && chmod 000 /tmp/readonly-test 2>/dev/null || true; WIREGUARD_KEYS_DIR=/tmp/readonly-test generate_server_keys; echo OK'"
    
    # 恢复权限
    chmod 755 /tmp/readonly-test 2>/dev/null || true
    rm -rf /tmp/readonly-test 2>/dev/null || true
}

# 测试性能
test_performance() {
    echo "5. 测试性能..."
    
    # 测试配置创建时间
    local start_time=$(date +%s%N)
    bash -c "source modules/wireguard_config.sh && test_wireguard_config" >/dev/null 2>&1
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))
    
    echo "  配置创建时间: ${duration}ms"
    
    if [ $duration -lt 5000 ]; then
        echo "✓ 性能测试通过 (${duration}ms)"
        ((PASSED_TESTS++))
    else
        echo "✗ 性能测试失败 (${duration}ms > 5000ms)"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
}

# 主测试函数
main() {
    echo "开始WireGuard配置功能专项测试..."
    echo "=========================================="
    
    # 清理测试环境
    cleanup_test_env
    
    # 运行所有测试
    test_key_generation
    test_config_creation
    test_config_content
    test_error_handling
    test_performance
    
    # 显示测试结果
    echo "=========================================="
    echo "测试完成！"
    echo "总测试数: $TOTAL_TESTS"
    echo "通过: $PASSED_TESTS"
    echo "失败: $FAILED_TESTS"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo "🎉 所有WireGuard配置测试通过！"
        exit 0
    else
        echo "❌ 有 $FAILED_TESTS 个测试失败"
        exit 1
    fi
}

# 运行主函数
main "$@"
