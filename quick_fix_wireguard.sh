#!/bin/bash

echo "=== 快速修复 WireGuard 目录和 net-tools 问题 ==="

# 1. 创建 WireGuard 目录并设置权限
echo "创建 WireGuard 配置目录..."
sudo mkdir -p /etc/wireguard
sudo chmod 700 /etc/wireguard
echo "✓ WireGuard 目录创建完成"

# 2. 安装 net-tools
echo "安装 net-tools..."
sudo apt-get update
sudo apt-get install -y net-tools
echo "✓ net-tools 安装完成"

# 3. 修复 .env 文件中的注释问题
echo "修复 .env 文件..."
sed -i 's/ACCESS_TOKEN_EXPIRE_MINUTES=1440 # 24 hours/ACCESS_TOKEN_EXPIRE_MINUTES=1440/' /opt/ipv6-wireguard-manager/.env
echo "✓ .env 文件修复完成"

# 4. 重启服务
echo "重启服务..."
sudo systemctl restart ipv6-wireguard-manager.service
sleep 3

# 5. 检查服务状态
echo "检查服务状态..."
sudo systemctl status ipv6-wireguard-manager.service --no-pager

# 6. 运行服务检查
echo "运行服务检查..."
/opt/ipv6-wireguard-manager/scripts/check_api_service.sh -p 8000

echo "=== 修复完成 ==="
