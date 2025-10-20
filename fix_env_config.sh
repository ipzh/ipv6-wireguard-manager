#!/bin/bash

# 修复 .env 配置文件中的注释问题
echo "修复 .env 配置文件..."

# 备份原文件
cp /opt/ipv6-wireguard-manager/.env /opt/ipv6-wireguard-manager/.env.backup

# 移除 ACCESS_TOKEN_EXPIRE_MINUTES 行中的注释
sed -i 's/ACCESS_TOKEN_EXPIRE_MINUTES=1440 # 24 hours/ACCESS_TOKEN_EXPIRE_MINUTES=1440/' /opt/ipv6-wireguard-manager/.env

echo "修复完成，重启服务..."

# 重启服务
systemctl restart ipv6-wireguard-manager.service

# 等待服务启动
sleep 3

# 检查服务状态
systemctl status ipv6-wireguard-manager.service --no-pager

echo "修复完成！"
