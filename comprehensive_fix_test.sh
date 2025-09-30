#!/bin/bash

# 综合修复测试脚本
# 测试所有修复的问题

set -e

echo "=== 综合修复测试 ==="

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

echo "1. 测试主菜单编号修复..."
# 检查菜单编号是否连续
if grep -q "echo -e.*[0-9]\+\.${NC}" ipv6-wireguard-manager.sh; then
    echo "✓ 主菜单编号已修复"
    ((PASSED_TESTS++))
else
    echo "✗ 主菜单编号修复失败"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

echo "2. 测试WireGuard安全修复..."
# 检查是否移除了固定测试密钥
if ! grep -q "test_private_key_for_testing" modules/wireguard_config.sh; then
    echo "✓ 固定测试密钥已移除"
    ((PASSED_TESTS++))
else
    echo "✗ 固定测试密钥未完全移除"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

echo "3. 测试变量命名规范修复..."
# 检查是否使用了IPV6WGM_前缀
if grep -q "IPV6WGM_WIREGUARD_CONFIG_DIR" modules/wireguard_config.sh; then
    echo "✓ 变量命名规范已统一"
    ((PASSED_TESTS++))
else
    echo "✗ 变量命名规范修复失败"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

echo "4. 测试Windows兼容性修复..."
# 检查是否创建了增强的Windows兼容性模块
if [[ -f "modules/enhanced_windows_compatibility.sh" ]]; then
    echo "✓ Windows兼容性模块已创建"
    ((PASSED_TESTS++))
else
    echo "✗ Windows兼容性模块创建失败"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

echo "5. 测试WireGuard配置功能..."
# 测试WireGuard配置是否正常工作
run_test "WireGuard配置测试" "bash -c 'source modules/wireguard_config.sh && test_wireguard_config'"

echo "6. 测试主脚本启动..."
# 测试主脚本是否能正常启动
run_test "主脚本启动测试" "bash ipv6-wireguard-manager.sh --help > /dev/null"

echo "7. 测试Windows兼容性功能..."
# 测试Windows兼容性模块
run_test "Windows兼容性测试" "bash -c 'source modules/enhanced_windows_compatibility.sh && run_windows_compatibility_test'"

echo "8. 测试菜单编号连续性..."
# 检查菜单编号是否从1连续到37
menu_numbers=$(grep -o '[0-9]\+\.' ipv6-wireguard-manager.sh | grep -o '[0-9]\+' | sort -n | uniq)
mapfile -t expected_numbers < <(seq 0 37)
missing_numbers=()
for num in "${expected_numbers[@]}"; do
    if ! echo "$menu_numbers" | grep -q "^$num$"; then
        missing_numbers+=("$num")
    fi
done

if [[ ${#missing_numbers[@]} -eq 0 ]]; then
    echo "✓ 菜单编号连续性检查通过"
    ((PASSED_TESTS++))
else
    echo "✗ 菜单编号连续性检查失败，缺少编号: ${missing_numbers[*]}"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

echo "9. 测试权限设置改进..."
# 检查权限设置是否改进了错误处理
if grep -q "无法设置.*权限" modules/wireguard_config.sh; then
    echo "✓ 权限设置错误处理已改进"
    ((PASSED_TESTS++))
else
    echo "✗ 权限设置错误处理改进失败"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

echo "10. 测试向后兼容性..."
# 检查是否保持了向后兼容性
if grep -q "向后兼容的变量别名" modules/wireguard_config.sh; then
    echo "✓ 向后兼容性已保持"
    ((PASSED_TESTS++))
else
    echo "✗ 向后兼容性保持失败"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

# 显示测试结果
echo "=========================================="
echo "综合修复测试完成！"
echo "总测试数: $TOTAL_TESTS"
echo "通过: $PASSED_TESTS"
echo "失败: $FAILED_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
    echo "🎉 所有修复测试通过！"
    exit 0
else
    echo "❌ 有 $FAILED_TESTS 个测试失败"
    exit 1
fi
