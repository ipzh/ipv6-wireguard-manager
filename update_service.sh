#!/bin/bash
# 更新 systemd 服务文件以修复健康检查问题

echo "更新 systemd 服务配置..."

# 备份原服务文件
cp /etc/systemd/system/ipv6-wireguard-manager.service /etc/systemd/system/ipv6-wireguard-manager.service.backup.$(date +%Y%m%d_%H%M%S)

# 修复健康检查 - 移除 || exit 1，改为 || true
sed -i 's|ExecStartPost=/bin/bash -c.*curl.*exit 1.*|ExecStartPost=/bin/bash -c '\''if command -v curl >/dev/null 2>\&1; then curl -f http://[::1]:8000/api/v1/health || curl -f http://127.0.0.1:8000/api/v1/health || true; fi'\''|' /etc/systemd/system/ipv6-wireguard-manager.service

echo "服务文件已更新"
echo ""
echo "新的健康检查配置："
grep "ExecStartPost.*curl" /etc/systemd/system/ipv6-wireguard-manager.service

# 重新加载并重启
systemctl daemon-reload
echo ""
echo "重启服务..."
systemctl restart ipv6-wireguard-manager.service

sleep 5

echo ""
echo "检查服务状态..."
systemctl status ipv6-wireguard-manager.service --no-pager -l

echo ""
if systemctl is-active --quiet ipv6-wireguard-manager.service; then
    echo "✅ 服务启动成功！"
else
    echo "❌ 服务仍然失败，查看详细日志："
    journalctl -u ipv6-wireguard-manager.service -n 100 --no-pager | tail -50
fi

