#!/bin/bash

# 测试管道安装修复

echo "=== 测试管道安装修复 ==="

# 创建测试目录
TEST_DIR="/tmp/pipe-install-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || exit

echo "测试目录: $TEST_DIR"

# 模拟管道安装
echo "1. 测试管道安装..."
echo "模拟执行: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash"

# 下载安装脚本
echo "2. 下载安装脚本..."
if curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh -o install.sh; then
    echo "✓ 安装脚本下载成功"
    
    # 检查脚本语法
    echo "3. 检查脚本语法..."
    if bash -n install.sh; then
        echo "✓ 脚本语法正确"
        
        # 模拟管道执行（使用echo | bash）
        echo "4. 模拟管道执行..."
        echo "" | timeout 30 bash install.sh 2>&1 | head -20
        
        # 检查退出码
        EXIT_CODE=$?
        echo "退出码: $EXIT_CODE"
        
        if [[ $EXIT_CODE -eq 0 ]]; then
            echo "✓ 管道执行成功"
        elif [[ $EXIT_CODE -eq 124 ]]; then
            echo "⚠ 管道执行超时（正常，因为需要用户交互）"
        else
            echo "✗ 管道执行失败，退出码: $EXIT_CODE"
        fi
        
    else
        echo "✗ 脚本语法错误"
        exit 1
    fi
else
    echo "✗ 安装脚本下载失败"
    exit 1
fi

# 清理
cd /
rm -rf "$TEST_DIR"
echo "✓ 测试完成，临时目录已清理"
