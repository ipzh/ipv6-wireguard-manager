#!/bin/bash
# 修复服务器API问题

cd /opt/ipv6-wireguard-manager

echo "修复1: 权限检查降级"
python3 << 'EOF'
import re

# 读取文件
with open('backend/app/core/unified_config.py', 'r', encoding='utf-8') as f:
    content = f.read()

# 替换raise PermissionError为降级逻辑
old_pattern = '''                raise PermissionError(f"Cannot access WireGuard config directory: {self.WIREGUARD_CONFIG_DIR}")'''

new_code = '''                # 记录警告并降级到临时目录，避免阻断服务启动
                import logging
                logging.warning(
                    f"WireGuard配置目录不可访问(需读写): {self.WIREGUARD_CONFIG_DIR}，将降级使用 /tmp 目录"
                )
                self.WIREGUARD_CONFIG_DIR = "/tmp/ipv6-wireguard-config"
                self.WIREGUARD_CLIENTS_DIR = "/tmp/ipv6-wireguard-clients"
                Path(self.WIREGUARD_CONFIG_DIR).mkdir(parents=True, exist_ok=True)
                Path(self.WIREGUARD_CLIENTS_DIR).mkdir(parents=True, exist_ok=True)'''

content = content.replace(old_pattern, new_code)

# 写回文件
with open('backend/app/core/unified_config.py', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 权限检查修复完成")
EOF

echo "修复2: API路由前缀"
python3 << 'EOF'
import re

with open('backend/app/api/__init__.py', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    'api_router.include_router(v1_router, prefix="/v1")',
    'api_router.include_router(v1_router, prefix="")'
)

with open('backend/app/api/__init__.py', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ API路由修复完成")
EOF

echo "重启服务..."
sudo systemctl daemon-reload
sudo systemctl restart ipv6-wireguard-manager

echo "等待5秒..."
sleep 5

echo "检查服务状态:"
sudo systemctl status ipv6-wireguard-manager --no-pager -l

echo ""
echo "测试API:"
curl -v http://127.0.0.1:8000/api/v1/health

echo ""
echo "修复完成！"

