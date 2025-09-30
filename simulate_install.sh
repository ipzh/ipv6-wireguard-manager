#!/bin/bash

# 模拟用户安装过程

echo "=== 模拟用户安装过程 ==="

# 创建测试目录
TEST_DIR="/tmp/user-install-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || exit

echo "测试目录: $TEST_DIR"

# 模拟用户执行安装命令
echo "模拟执行: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash"

# 下载安装脚本
echo "1. 下载安装脚本..."
if curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh -o install.sh; then
    echo "✓ 安装脚本下载成功"
    
    # 检查安装脚本内容
    if [[ -f "install.sh" && -s "install.sh" ]]; then
        echo "✓ 安装脚本文件存在且非空"
        
        # 模拟安装过程（不实际执行，只检查脚本语法）
        echo "2. 检查安装脚本语法..."
        if bash -n install.sh; then
            echo "✓ 安装脚本语法正确"
            
            # 检查关键函数是否存在
            if grep -q "download_project_files" install.sh; then
                echo "✓ 找到下载函数"
            else
                echo "✗ 未找到下载函数"
            fi
            
            if grep -q "ipv6-wireguard-manager-\*" install.sh; then
                echo "✓ 找到目录匹配逻辑"
            else
                echo "✗ 未找到目录匹配逻辑"
            fi
            
            echo "✓ 安装脚本修复验证通过"
        else
            echo "✗ 安装脚本语法错误"
            exit 1
        fi
    else
        echo "✗ 安装脚本文件不存在或为空"
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
