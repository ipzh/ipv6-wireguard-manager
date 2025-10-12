#!/bin/bash

echo "🔧 强制修复服务器上的validator问题..."

# 停止服务
systemctl stop ipv6-wireguard-manager

# 修复monitoring.py
echo "修复 monitoring.py..."
sed -i 's/from pydantic import BaseModel, validator/from pydantic import BaseModel, field_validator/g' /opt/ipv6-wireguard-manager/backend/app/schemas/monitoring.py
sed -i 's/@validator/@field_validator\n    @classmethod/g' /opt/ipv6-wireguard-manager/backend/app/schemas/monitoring.py

# 修复wireguard.py
echo "修复 wireguard.py..."
sed -i 's/from pydantic import BaseModel, validator/from pydantic import BaseModel, field_validator/g' /opt/ipv6-wireguard-manager/backend/app/schemas/wireguard.py
sed -i 's/@validator/@field_validator\n    @classmethod/g' /opt/ipv6-wireguard-manager/backend/app/schemas/wireguard.py

# 修复network.py
echo "修复 network.py..."
sed -i 's/from pydantic import BaseModel, validator/from pydantic import BaseModel, field_validator/g' /opt/ipv6-wireguard-manager/backend/app/schemas/network.py
sed -i 's/@validator/@field_validator\n    @classmethod/g' /opt/ipv6-wireguard-manager/backend/app/schemas/network.py

# 验证修复
echo "验证修复..."
cd /opt/ipv6-wireguard-manager/backend
source venv/bin/activate

python -c "
import sys
sys.path.insert(0, '/opt/ipv6-wireguard-manager/backend')
try:
    from app.schemas.monitoring import OperationLogBase
    print('✅ monitoring.py 修复成功')
except Exception as e:
    print(f'❌ monitoring.py 仍有问题: {e}')

try:
    from app.schemas.wireguard import WireGuardServerBase
    print('✅ wireguard.py 修复成功')
except Exception as e:
    print(f'❌ wireguard.py 仍有问题: {e}')

try:
    from app.schemas.network import NetworkInterfaceBase
    print('✅ network.py 修复成功')
except Exception as e:
    print(f'❌ network.py 仍有问题: {e}')

try:
    from app.main import app
    print('✅ 主应用导入成功')
except Exception as e:
    print(f'❌ 主应用导入失败: {e}')
"

# 启动服务
echo "启动服务..."
systemctl start ipv6-wireguard-manager
sleep 5

# 检查状态
systemctl status ipv6-wireguard-manager --no-pager

echo "✅ 修复完成"
