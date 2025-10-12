#!/bin/bash

# 修复数据库初始化问题
echo "🔧 修复数据库初始化问题..."

APP_HOME="/opt/ipv6-wireguard-manager"

if [ ! -d "$APP_HOME/backend" ]; then
    echo "❌ 后端目录不存在: $APP_HOME/backend"
    exit 1
fi

cd "$APP_HOME/backend"

# 检查虚拟环境
if [ ! -d "venv" ]; then
    echo "❌ 虚拟环境不存在"
    exit 1
fi

source venv/bin/activate

echo "🔧 重新创建数据库表..."
python -c "
import sys
sys.path.insert(0, '.')
try:
    from app.core.database import sync_engine
    from app.models import Base
    Base.metadata.create_all(bind=sync_engine)
    print('✅ 数据库表创建成功')
except Exception as e:
    print(f'❌ 数据库表创建失败: {e}')
    sys.exit(1)
"

echo "🔧 重新初始化默认数据..."
python -c "
import sys
import asyncio
sys.path.insert(0, '.')
try:
    from app.core.init_db import init_db
    asyncio.run(init_db())
    print('✅ 默认数据初始化成功')
except Exception as e:
    print(f'❌ 默认数据初始化失败: {e}')
    # 不退出，继续
"

echo "🔧 重启后端服务..."
sudo systemctl restart ipv6-wireguard-manager

echo "⏳ 等待服务启动..."
sleep 5

echo "🔍 检查服务状态..."
if sudo systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "✅ 后端服务运行正常"
else
    echo "❌ 后端服务异常"
    sudo systemctl status ipv6-wireguard-manager
fi

echo "🔍 测试API访问..."
if curl -s "http://localhost:8000/api/v1/status/status" >/dev/null 2>&1; then
    echo "✅ API访问正常"
else
    echo "❌ API访问异常"
fi

echo "🎉 数据库初始化修复完成！"
