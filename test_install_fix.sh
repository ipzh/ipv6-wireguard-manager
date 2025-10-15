#!/bin/bash

# 测试安装脚本的参数解析功能
echo "=== 测试安装脚本参数解析 ==="

# 测试1: 直接运行帮助
echo "测试1: 直接运行帮助"
./install.sh --help

echo -e "\n=== 测试2: 模拟管道执行 ==="

# 测试2: 模拟管道执行（无参数）
echo "测试2: 模拟管道执行（无参数）"
cat install.sh | head -20 | grep -A5 "版本:"

echo -e "\n=== 测试3: 检查参数解析逻辑 ==="

# 测试3: 检查参数解析函数
cat install.sh | grep -A30 "parse_arguments()" | head -40

echo -e "\n=== 测试完成 ==="