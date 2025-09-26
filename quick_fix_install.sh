#!/bin/bash

# 快速修复安装脚本
# 解决check_system_requirements函数缺失问题

set -euo pipefail

echo "🔧 快速修复安装脚本..."

# 下载最新版本的安装脚本
echo "📥 下载最新版本的安装脚本..."
curl -sSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh -o install_fixed.sh

# 检查是否下载成功
if [[ ! -f "install_fixed.sh" ]]; then
    echo "❌ 下载失败，请检查网络连接"
    exit 1
fi

# 修复check_system_requirements函数调用错误
echo "🔧 修复函数调用错误..."
sed -i 's/check_system_requirements/check_system_compatibility/g' install_fixed.sh

# 设置执行权限
chmod +x install_fixed.sh

echo "✅ 修复完成，运行安装脚本..."
echo

# 运行修复后的安装脚本
sudo ./install_fixed.sh

# 清理临时文件
rm -f install_fixed.sh

echo "🎉 安装完成！"
