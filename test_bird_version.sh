#!/bin/bash

# BIRD版本检测测试脚本
# 用于验证BIRD 2.x优先安装逻辑

echo "=== BIRD版本检测测试 ==="

# 检测当前安装的BIRD版本
echo "检测当前BIRD安装状态:"

if command -v birdc2 >/dev/null 2>&1; then
    echo "✓ BIRD 2.x 已安装"
    birdc2 -v 2>/dev/null | head -1
elif command -v birdc >/dev/null 2>&1; then
    echo "✓ BIRD 1.x 已安装"
    birdc -v 2>/dev/null | head -1
else
    echo "✗ 未检测到BIRD安装"
fi

echo
echo "检测BIRD服务状态:"

if systemctl is-active --quiet bird2; then
    echo "✓ BIRD2 服务正在运行"
elif systemctl is-active --quiet bird; then
    echo "✓ BIRD 服务正在运行"
else
    echo "✗ BIRD服务未运行"
fi

echo
echo "检测BIRD配置文件:"

if [[ -f /etc/bird/bird.conf ]]; then
    echo "✓ BIRD配置文件存在: /etc/bird/bird.conf"
elif [[ -f /etc/bird2/bird.conf ]]; then
    echo "✓ BIRD2配置文件存在: /etc/bird2/bird.conf"
else
    echo "✗ 未找到BIRD配置文件"
fi

echo
echo "=== 测试完成 ==="
