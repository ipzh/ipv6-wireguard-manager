#!/bin/bash

echo "=== 性能测试 ==="

# 测试启动时间
echo "1. 测试启动时间..."
for i in {1..5}; do
    start_time=$(date +%s%N)
    bash ipv6-wireguard-manager.sh --help > /dev/null 2>&1
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    echo "  第${i}次: ${duration}ms"
done

# 测试模块加载时间
echo "2. 测试模块加载时间..."
for module in common_functions system_detection config_manager wireguard_config client_management; do
    start_time=$(date +%s%N)
    bash -c "source modules/${module}.sh && echo OK" > /dev/null 2>&1
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    echo "  ${module}: ${duration}ms"
done

# 测试内存使用
echo "3. 测试内存使用..."
if command -v ps >/dev/null 2>&1; then
    echo "  当前内存使用:"
    ps -o pid,vsz,rss,comm -p $$ 2>/dev/null || echo "  无法获取内存信息"
else
    echo "  无法测试内存使用（ps命令不可用）"
fi

echo "=== 性能测试完成 ==="
