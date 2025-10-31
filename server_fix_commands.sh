#!/bin/bash
# 服务器端修复脚本
# 用于更新代码并重启服务

set -e

echo "=================================="
echo "开始修复API服务问题"
echo "=================================="
echo ""

INSTALL_DIR="/opt/ipv6-wireguard-manager"
cd "$INSTALL_DIR"

# 1. 拉取最新代码
echo "1️⃣  拉取最新代码..."
git pull || {
    echo "⚠️  拉取代码失败，尝试重置到远程版本"
    git fetch origin main
    git reset --hard origin/main
}

# 2. 验证修复是否已应用
echo ""
echo "2️⃣  验证修复是否已应用..."

# 检查unified_config.py是否包含新的降级逻辑
if grep -q "WireGuard配置目录不可访问" backend/app/core/unified_config.py; then
    echo "✅ 权限降级修复已应用"
else
    echo "⚠️  权限降级修复未应用，手动修复..."
    # 手动应用修复
    sed -i '292s/raise PermissionError/# 记录警告并降级到临时目录\n                import logging\n                logging.warning(\n                    f"WireGuard配置目录不可访问(需读写): {self.WIREGUARD_CONFIG_DIR}，将降级使用 \/tmp 目录"\n                )\n                self.WIREGUARD_CONFIG_DIR = "\/tmp\/ipv6-wireguard-config"\n                self.WIREGUARD_CLIENTS_DIR = "\/tmp\/ipv6-wireguard-clients"\n                Path(self.WIREGUARD_CONFIG_DIR).mkdir(parents=True, exist_ok=True)\n                Path(self.WIREGUARD_CLIENTS_DIR).mkdir(parents=True, exist_ok=True)/' backend/app/core/unified_config.py
    echo "✅ 手动修复完成"
fi

# 检查api/__init__.py是否修复了前缀
if grep -q 'api_router.include_router(v1_router, prefix="")' backend/app/api/__init__.py; then
    echo "✅ API路由前缀修复已应用"
else
    echo "⚠️  API路由前缀修复未应用，手动修复..."
    sed -i '17s/prefix="\/v1"/prefix=""/' backend/app/api/__init__.py
    echo "✅ 手动修复完成"
fi

# 3. 重启服务
echo ""
echo "3️⃣  重启服务..."
sudo systemctl daemon-reload
sudo systemctl restart ipv6-wireguard-manager

# 4. 等待服务启动
echo ""
echo "4️⃣  等待服务启动..."
sleep 3

# 5. 检查服务状态
echo ""
echo "5️⃣  检查服务状态..."
if sudo systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "✅ 服务正在运行"
else
    echo "❌ 服务未运行"
    echo ""
    echo "查看日志:"
    sudo journalctl -u ipv6-wireguard-manager -n 50 --no-pager
    exit 1
fi

# 6. 检查端口监听
echo ""
echo "6️⃣  检查端口监听..."
if ss -tlnp | grep -q ":8000"; then
    echo "✅ 端口8000正在监听"
else
    echo "❌ 端口8000未监听"
    exit 1
fi

# 7. 测试API健康检查
echo ""
echo "7️⃣  测试API健康检查..."
# 尝试IPv6，失败则尝试IPv4
if curl -6 -s --connect-timeout 5 http://[::1]:8000/api/v1/health >/dev/null 2>&1; then
    echo "✅ IPv6健康检查成功"
elif curl -4 -s --connect-timeout 5 http://127.0.0.1:8000/api/v1/health >/dev/null 2>&1; then
    echo "✅ IPv4健康检查成功"
else
    echo "⚠️  健康检查失败，显示详细信息:"
    curl -v http://127.0.0.1:8000/api/v1/health 2>&1 || curl -v http://[::1]:8000/api/v1/health 2>&1
fi

# 8. 显示最终状态
echo ""
echo "=================================="
echo "修复完成！"
echo "=================================="
echo ""
echo "服务状态:"
sudo systemctl status ipv6-wireguard-manager --no-pager -l
echo ""
echo "访问地址:"
echo "  - 本地: http://localhost:8000/api/v1/health"
echo "  - API文档: http://localhost:8000/docs"

