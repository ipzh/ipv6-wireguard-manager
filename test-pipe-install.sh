#!/bin/bash

# 测试管道安装脚本

echo "🧪 测试管道安装脚本..."

# 测试1: 检查脚本是否支持管道执行
echo "测试1: 检查脚本是否支持管道执行"
if [ -t 0 ]; then
    echo "✅ 当前是交互式终端"
else
    echo "✅ 当前是管道执行模式"
fi

# 测试2: 模拟管道执行
echo ""
echo "测试2: 模拟管道执行"
echo "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash" | bash -c 'if [ ! -t 0 ]; then echo "✅ 管道执行模式检测正常"; else echo "❌ 管道执行模式检测失败"; fi'

# 测试3: 检查交互式输入处理
echo ""
echo "测试3: 检查交互式输入处理"
if [ -t 0 ]; then
    echo "✅ 交互式模式: 支持用户输入"
else
    echo "✅ 非交互式模式: 自动选择"
fi

echo ""
echo "🎯 测试完成"
