#!/bin/bash

# 修复Debian系统Docker安装问题

echo "🔧 修复Debian系统Docker安装问题..."

# 清理错误的Docker仓库
echo "🧹 清理错误的Docker仓库..."
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg

# 更新包列表
echo "📦 更新包列表..."
sudo apt update

# 安装必要的依赖
echo "📦 安装依赖..."
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 添加正确的Debian Docker GPG密钥
echo "🔑 添加Debian Docker GPG密钥..."
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 添加正确的Debian Docker仓库
echo "📋 添加Debian Docker仓库..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 更新包列表
echo "📦 更新包列表..."
sudo apt update

# 安装Docker
echo "📦 安装Docker..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动Docker服务
echo "🚀 启动Docker服务..."
sudo systemctl start docker
sudo systemctl enable docker

# 验证安装
echo "🔍 验证Docker安装..."
if docker --version >/dev/null 2>&1; then
    echo "✅ Docker 安装成功: $(docker --version)"
else
    echo "❌ Docker 安装失败"
    exit 1
fi

if docker compose version >/dev/null 2>&1; then
    echo "✅ Docker Compose 安装成功"
else
    echo "❌ Docker Compose 安装失败"
    exit 1
fi

echo "🎉 Debian Docker 安装修复完成！"
echo ""
echo "现在可以重新运行安装脚本："
echo "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-curl.sh | bash"
