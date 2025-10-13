#!/bin/bash

# IPv6 WireGuard Manager VPS调试脚本一键下载器
# 在远程VPS上运行此脚本即可自动下载并运行调试脚本

echo "=== IPv6 WireGuard Manager VPS调试脚本一键下载 ==="
echo "正在下载调试脚本..."

# 创建临时目录
TEMP_DIR="/tmp/ipv6-wireguard-debug"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# 下载调试脚本
echo "下载VPS调试脚本..."
curl -s -O https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/vps-debug-install.sh

# 检查下载是否成功
if [ ! -f "vps-debug-install.sh" ]; then
    echo "❌ 下载失败，尝试备用下载方式..."
    
    # 备用下载方式
    wget -q https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/vps-debug-install.sh
    
    if [ ! -f "vps-debug-install.sh" ]; then
        echo "❌ 所有下载方式都失败，请检查网络连接"
        exit 1
    fi
fi

# 给脚本执行权限
chmod +x vps-debug-install.sh

echo "✅ 调试脚本下载成功"
echo ""
echo "=== 开始运行VPS调试脚本 ==="
echo "这将检查您的VPS环境并生成详细的问题报告"
echo ""

# 运行调试脚本
./vps-debug-install.sh

# 清理临时文件
cd /
rm -rf "$TEMP_DIR"

echo ""
echo "=== 调试完成 ==="
echo "请查看生成的报告文件了解详细问题"
echo "报告文件位置: /opt/ipv6-wireguard-manager/vps-debug-report-*.txt"