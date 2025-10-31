#!/bin/bash
# 快速修复脚本 - 不依赖git

set -e

echo "=================================="
echo "快速修复API服务"
echo "=================================="
echo ""

INSTALL_DIR="/opt/ipv6-wireguard-manager"
cd "$INSTALL_DIR"

# 1. 手动修复 backend/app/core/unified_config.py
echo "1️⃣  修复权限检查..."
sed -i '293d' backend/app/core/unified_config.py  # 删除raise行
sed -i '292a\                # 记录警告并降级到临时目录，避免阻断服务启动\
                import logging\
                logging.warning(\
                    f"WireGuard配置目录不可访问(需读写): {self.WIREGUARD_CONFIG_DIR}，将降级使用 /tmp 目录"\
                )\
                self.WIREGUARD_CONFIG_DIR = "/tmp/ipv6-wireguard-config"\
                self.WIREGUARD_CLIENTS_DIR = "/tmp/ipv6-wireguard-clients"\
                Path(self.WIREGUARD_CONFIG_DIR).mkdir(parents=True, exist_ok=True)\
                Path(self.WIREGUARD_CLIENTS_DIR).mkdir(parents=True, exist_ok=True)' backend/app/core/unified_config.py

# 2. 手动修复 backend/app/api/__init__.py
echo "2️⃣  修复API路由前缀..."
sed -i 's/api_router.include_router(v1_router, prefix="\/v1")/api_router.include_router(v1_router, prefix="")/' backend/app/api/__init__.py

# 3. 重启服务
echo "3️⃣  重启服务..."
sudo systemctl daemon-reload
sudo systemctl restart ipv6-wireguard-manager

# 4. 等待并检查
echo "4️⃣  等待服务启动..."
sleep 5

echo "5️⃣  检查服务状态..."
sudo systemctl status ipv6-wireguard-manager --no-pager -l

echo ""
echo "6️⃣  测试API..."
curl -v http://127.0.0.1:8000/api/v1/health

echo ""
echo "修复完成！"

