#!/bin/bash

# 修复Docker仓库配置问题

echo "🔧 修复Docker仓库配置问题..."

# 清理错误的Docker仓库配置
echo "🧹 清理错误的Docker仓库配置..."
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg

# 清理apt缓存
echo "🧹 清理apt缓存..."
sudo apt clean
sudo apt autoclean

# 更新包列表
echo "📦 更新包列表..."
sudo apt update

echo "✅ Docker仓库配置已清理"
echo ""
echo "现在可以重新运行安装脚本："
echo "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-smart.sh | bash"
