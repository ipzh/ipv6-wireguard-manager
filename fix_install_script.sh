#!/bin/bash

# 临时修复脚本 - 修复INFO_COLOR变量未定义问题
# 这个脚本会下载最新版本的安装脚本并运行

set -euo pipefail

echo "🔧 修复安装脚本中的INFO_COLOR变量问题..."

# 下载最新版本的安装脚本
echo "📥 下载最新版本的安装脚本..."
curl -sSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh -o install_latest.sh

# 检查是否下载成功
if [[ ! -f "install_latest.sh" ]]; then
    echo "❌ 下载失败，请检查网络连接"
    exit 1
fi

# 检查INFO_COLOR变量是否存在
if grep -q "INFO_COLOR=" install_latest.sh; then
    echo "✅ 最新版本已包含INFO_COLOR变量定义"
else
    echo "⚠️ 最新版本仍缺少INFO_COLOR变量，正在修复..."
    
    # 在颜色定义部分添加INFO_COLOR
    sed -i '/NC=.*No Color/a INFO_COLOR="\\033[0;36m"  # 信息颜色（青色）' install_latest.sh
fi

# 设置执行权限
chmod +x install_latest.sh

echo "✅ 修复完成，运行安装脚本..."
echo

# 运行修复后的安装脚本
./install_latest.sh

# 清理临时文件
rm -f install_latest.sh

echo "🎉 安装完成！"
