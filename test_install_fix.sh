#!/bin/bash

# 测试安装脚本修复

echo "=== 测试安装脚本修复 ==="

# 创建测试目录
TEST_DIR="/tmp/install-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || exit

echo "测试目录: $TEST_DIR"

# 模拟下载过程
echo "1. 测试下载URL..."
DOWNLOAD_URL="https://github.com/ipzh/ipv6-wireguard-manager/archive/main.tar.gz"
echo "下载URL: $DOWNLOAD_URL"

# 测试下载
echo "2. 测试下载文件..."
if command -v curl &> /dev/null; then
    echo "使用curl下载..."
    if curl -fsSL --connect-timeout 30 --max-time 300 -o master.tar.gz "$DOWNLOAD_URL"; then
        echo "✓ 下载成功"
        
        # 检查文件大小
        FILE_SIZE=$(stat -c%s "master.tar.gz" 2>/dev/null || echo "0")
        echo "文件大小: $FILE_SIZE 字节"
        
        if [[ $FILE_SIZE -lt 1000 ]]; then
            echo "✗ 文件太小，可能是错误页面"
            echo "文件内容:"
            head -5 "master.tar.gz"
            exit 1
        fi
        
        # 测试解压
        echo "3. 测试解压文件..."
        if tar -xzf master.tar.gz; then
            echo "✓ 解压成功"
            
            # 检查解压后的目录结构
            echo "4. 检查目录结构..."
            echo "当前目录内容:"
            find . -type f -exec ls -la {} +
            
            # 查找解压后的目录
            EXTRACTED_DIR=""
            for dir in ipv6-wireguard-manager-*; do
                if [[ -d "$dir" ]]; then
                    EXTRACTED_DIR="$dir"
                    break
                fi
            done
            
            if [[ -n "$EXTRACTED_DIR" && -d "$EXTRACTED_DIR" ]]; then
                echo "✓ 找到解压目录: $EXTRACTED_DIR"
                echo "解压目录内容:"
                find . -type f -exec ls -la {} + "$EXTRACTED_DIR" | head -10
                
                # 检查关键文件
                if [[ -f "$EXTRACTED_DIR/ipv6-wireguard-manager.sh" ]]; then
                    echo "✓ 找到主脚本文件"
                else
                    echo "✗ 未找到主脚本文件"
                fi
                
                if [[ -d "$EXTRACTED_DIR/modules" ]]; then
                    echo "✓ 找到modules目录"
                else
                    echo "✗ 未找到modules目录"
                fi
                
                echo "✓ 安装脚本修复测试通过"
            else
                echo "✗ 未找到解压目录"
                exit 1
            fi
        else
            echo "✗ 解压失败"
            echo "文件类型:"
            file master.tar.gz
            exit 1
        fi
    else
        echo "✗ 下载失败"
        exit 1
    fi
else
    echo "✗ curl不可用"
    exit 1
fi

# 清理
cd / || exit
rm -rf "$TEST_DIR"
echo "✓ 测试完成，临时目录已清理"
