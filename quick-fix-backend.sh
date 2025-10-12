#!/bin/bash

echo "🔧 快速修复后端问题..."

# 停止服务
systemctl stop ipv6-wireguard-manager

# 修复auth.py导入问题
echo "修复 auth.py 导入问题..."
sed -i 's/from ....core.security import create_access_token, verify_password, get_password_hash/from ....core.security import create_access_token, verify_password, get_password_hash, get_current_user_id/g' /opt/ipv6-wireguard-manager/backend/app/api/api_v1/endpoints/auth.py

# 验证修复
echo "验证修复..."
cd /opt/ipv6-wireguard-manager/backend
source venv/bin/activate

python -c "
import sys
sys.path.insert(0, '/opt/ipv6-wireguard-manager/backend')
try:
    from app.main import app
    print('✅ 主应用导入成功')
except Exception as e:
    print(f'❌ 主应用导入失败: {e}')
    import traceback
    traceback.print_exc()
"

# 启动服务
echo "启动服务..."
systemctl start ipv6-wireguard-manager
sleep 5

# 检查状态
echo "检查服务状态..."
systemctl status ipv6-wireguard-manager --no-pager

# 检查端口
echo "检查端口监听..."
netstat -tlnp | grep :8000 || echo "端口8000未监听"

# 测试API
echo "测试API..."
curl -s http://127.0.0.1:8000/health || echo "API无响应"

echo "✅ 修复完成"
