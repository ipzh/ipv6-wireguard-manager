#!/bin/bash

echo "🔍 诊断后端服务启动问题..."

# 检查服务状态
echo "1. 检查服务状态..."
systemctl status ipv6-wireguard-manager.service --no-pager

echo ""
echo "2. 检查服务日志..."
journalctl -u ipv6-wireguard-manager.service -n 20 --no-pager

echo ""
echo "3. 检查应用目录..."
ls -la /opt/ipv6-wireguard-manager/

echo ""
echo "4. 检查虚拟环境..."
ls -la /opt/ipv6-wireguard-manager/backend/venv/bin/

echo ""
echo "5. 检查Python路径..."
which python3
python3 --version

echo ""
echo "6. 检查应用文件..."
ls -la /opt/ipv6-wireguard-manager/backend/app/

echo ""
echo "7. 检查环境变量..."
cat /opt/ipv6-wireguard-manager/.env 2>/dev/null || echo "环境变量文件不存在"

echo ""
echo "8. 手动测试启动..."
cd /opt/ipv6-wireguard-manager/backend
source venv/bin/activate
python -c "import app.main; print('导入成功')" 2>&1

echo ""
echo "9. 检查依赖..."
pip list | grep -E "(fastapi|uvicorn|sqlalchemy)"

echo ""
echo "10. 检查端口占用..."
netstat -tlnp | grep :8000

echo ""
echo "11. 检查数据库连接..."
python -c "
import os
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine

async def test_db():
    try:
        db_url = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/ipv6_wireguard_manager')
        engine = create_async_engine(db_url)
        async with engine.begin() as conn:
            result = await conn.execute('SELECT 1')
            print('数据库连接成功')
    except Exception as e:
        print(f'数据库连接失败: {e}')

asyncio.run(test_db())
"

echo ""
echo "12. 检查Redis连接..."
python -c "
import redis
try:
    r = redis.Redis(host='localhost', port=6379, db=0)
    r.ping()
    print('Redis连接成功')
except Exception as e:
    print(f'Redis连接失败: {e}')
"

echo ""
echo "诊断完成！请查看上述输出以确定问题所在。"
