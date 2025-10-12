#!/bin/bash

echo "🔍 诊断后端服务问题..."

# 检查服务状态
echo "📊 检查服务状态..."
systemctl status ipv6-wireguard-manager --no-pager

# 查看详细日志
echo "📋 查看服务日志..."
journalctl -u ipv6-wireguard-manager --no-pager -n 50

# 检查文件权限
echo "🔐 检查文件权限..."
ls -la /opt/ipv6-wireguard-manager/backend/
ls -la /opt/ipv6-wireguard-manager/backend/app/

# 检查Python环境
echo "🐍 检查Python环境..."
cd /opt/ipv6-wireguard-manager/backend
source venv/bin/activate
python --version
which python
pip list | grep pydantic

# 测试应用导入
echo "🧪 测试应用导入..."
python -c "
import sys
sys.path.insert(0, '/opt/ipv6-wireguard-manager/backend')
try:
    print('Testing imports...')
    from app.core.config import settings
    print('✅ Config imported')
    
    from app.core.database import async_engine
    print('✅ Database imported')
    
    from app.models import Base
    print('✅ Models imported')
    
    from app.schemas.monitoring import OperationLogBase
    print('✅ Monitoring schemas imported')
    
    from app.schemas.wireguard import WireGuardServerBase
    print('✅ WireGuard schemas imported')
    
    from app.schemas.network import NetworkInterfaceBase
    print('✅ Network schemas imported')
    
    from app.main import app
    print('✅ Main app imported')
    
    print('🎉 All imports successful!')
    
except Exception as e:
    print(f'❌ Import failed: {e}')
    import traceback
    traceback.print_exc()
"

# 检查数据库连接
echo "🗄️ 测试数据库连接..."
python -c "
import asyncio
import sys
sys.path.insert(0, '/opt/ipv6-wireguard-manager/backend')
from app.core.database import async_engine
from sqlalchemy import text

async def test_db():
    try:
        async with async_engine.begin() as conn:
            result = await conn.execute(text('SELECT 1'))
            print('✅ Database connection successful')
    except Exception as e:
        print(f'❌ Database connection failed: {e}')

asyncio.run(test_db())
"

# 手动启动应用测试
echo "🚀 手动启动应用测试..."
timeout 10 python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 &
APP_PID=$!
sleep 3

# 检查进程
if ps -p $APP_PID > /dev/null; then
    echo "✅ 应用进程运行正常 (PID: $APP_PID)"
    
    # 测试API
    echo "🌐 测试API..."
    curl -s http://127.0.0.1:8000/health || echo "API无响应"
    
    # 停止测试进程
    kill $APP_PID
else
    echo "❌ 应用进程启动失败"
fi

echo "✅ 诊断完成"
