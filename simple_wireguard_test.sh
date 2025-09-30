#!/bin/bash

echo "=== WireGuard配置功能测试 ==="

# 清理测试环境
rm -rf "/tmp/ipv6-wireguard-test" 2>/dev/null || true

# 测试密钥生成
echo "1. 测试密钥生成..."
if bash -c "source modules/wireguard_config.sh && generate_server_keys && echo 'Key generation OK'" 2>/dev/null; then
    echo "✓ 密钥生成测试通过"
else
    echo "✗ 密钥生成测试失败"
fi

# 测试配置创建
echo "2. 测试配置创建..."
if bash -c "source modules/wireguard_config.sh && test_wireguard_config && echo 'Config creation OK'" 2>/dev/null; then
    echo "✓ 配置创建测试通过"
else
    echo "✗ 配置创建测试失败"
fi

# 检查生成的文件
echo "3. 检查生成的文件..."
if [[ -f "/tmp/ipv6-wireguard-test/config/wg0.conf" ]]; then
    echo "✓ 配置文件已创建"
    echo "  配置文件内容预览:"
    head -5 "/tmp/ipv6-wireguard-test/config/wg0.conf" | sed 's/^/    /'
else
    echo "✗ 配置文件未创建"
fi

if [[ -f "/tmp/ipv6-wireguard-test/keys/server_private.key" ]]; then
    echo "✓ 私钥文件已创建"
else
    echo "✗ 私钥文件未创建"
fi

if [[ -f "/tmp/ipv6-wireguard-test/keys/server_public.key" ]]; then
    echo "✓ 公钥文件已创建"
    echo "  公钥内容: $(cat /tmp/ipv6-wireguard-test/keys/server_public.key)"
else
    echo "✗ 公钥文件未创建"
fi

# 测试性能
echo "4. 测试性能..."
start_time=$(date +%s%N)
bash -c "source modules/wireguard_config.sh && test_wireguard_config" >/dev/null 2>&1
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo "  配置创建时间: ${duration}ms"

if [ $duration -lt 5000 ]; then
    echo "✓ 性能测试通过"
else
    echo "✗ 性能测试失败"
fi

echo "=== 测试完成 ==="
