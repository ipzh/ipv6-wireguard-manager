#!/bin/bash

# 测试安装脚本的参数解析功能（远程服务器版本）
echo "=== 测试安装脚本参数解析（远程服务器版本） ==="

# 下载安装脚本到临时目录
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "下载安装脚本..."
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh -o install.sh
chmod +x install.sh

# 测试1: 直接运行帮助
echo "测试1: 直接运行帮助"
./install.sh --help

echo -e "\n=== 测试2: 模拟管道执行 ==="

# 测试2: 模拟管道执行（无参数）
echo "测试2: 模拟管道执行（无参数）"
cat install.sh | head -20 | grep -A5 "版本:"

echo -e "\n=== 测试3: 检查参数解析逻辑 ==="

# 测试3: 检查参数解析函数
echo "测试3: 检查参数解析函数"
cat install.sh | grep -A30 "parse_arguments()" | head -40

echo -e "\n=== 测试4: 测试管道执行参数传递 ==="

# 测试4: 测试管道执行参数传递
echo "测试4: 测试管道执行参数传递"
echo "模拟: curl | bash -s -- docker"
cat install.sh | bash -s -- docker --help

echo -e "\n=== 测试完成 ==="

# 清理临时目录
cd /
rm -rf "$TEMP_DIR"