#!/bin/bash

echo "=== 重启服务测试修复 ==="

# 重启服务
echo "重启 ipv6-wireguard-manager 服务..."
sudo systemctl restart ipv6-wireguard-manager.service

# 等待服务启动
echo "等待服务启动..."
sleep 5

# 检查服务状态
echo "检查服务状态..."
sudo systemctl status ipv6-wireguard-manager.service --no-pager

# 运行服务检查
echo "运行服务检查..."
/opt/ipv6-wireguard-manager/scripts/check_api_service.sh -p 8000

echo "=== 修复测试完成 ==="
