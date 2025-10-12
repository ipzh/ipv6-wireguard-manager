#!/bin/bash

# 快速修复VPS数据库问题 - 一键下载执行
echo "🔧 开始修复VPS数据库初始化问题..."

APP_HOME="/opt/ipv6-wireguard-manager"

# 检查目录是否存在
if [ ! -d "$APP_HOME/backend" ]; then
    echo "❌ 后端目录不存在: $APP_HOME/backend"
    echo "请确认安装路径是否正确"
    exit 1
fi

cd "$APP_HOME/backend"
echo "📁 当前目录: $(pwd)"

# 检查虚拟环境
if [ ! -d "venv" ]; then
    echo "❌ 虚拟环境不存在，请重新安装"
    exit 1
fi

echo "🔧 激活虚拟环境..."
source venv/bin/activate

echo "🔧 修复模型导入问题..."
# 直接修复models/__init__.py文件
cat > app/models/__init__.py << 'EOF'
"""
数据库模型
"""
from ..core.database import Base
from .user import User, Role, UserRole
from .wireguard import WireGuardServer, WireGuardClient, ClientServerRelation
from .network import NetworkInterface, FirewallRule
from .monitoring import SystemMetric, AuditLog, OperationLog
from .config import ConfigVersion, BackupRecord

__all__ = [
    "Base",
    "User",
    "Role", 
    "UserRole",
    "WireGuardServer",
    "WireGuardClient",
    "ClientServerRelation",
    "NetworkInterface",
    "FirewallRule",
    "SystemMetric",
    "AuditLog",
    "OperationLog",
    "ConfigVersion",
    "BackupRecord",
]
EOF

echo "✅ 已修复models/__init__.py"

echo "🔧 重新创建数据库表..."
python -c "
import sys
sys.path.insert(0, '.')
try:
    from app.core.database import sync_engine
    from app.models import Base
    print('正在创建数据库表...')
    Base.metadata.create_all(bind=sync_engine)
    print('✅ 数据库表创建成功')
except Exception as e:
    print(f'❌ 数据库表创建失败: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    echo "✅ 数据库表创建成功"
else
    echo "❌ 数据库表创建失败"
    exit 1
fi

echo "🔧 重新初始化默认数据..."
python -c "
import sys
import asyncio
sys.path.insert(0, '.')
try:
    from app.core.init_db import init_db
    print('正在初始化默认数据...')
    asyncio.run(init_db())
    print('✅ 默认数据初始化成功')
except Exception as e:
    print(f'❌ 默认数据初始化失败: {e}')
    import traceback
    traceback.print_exc()
    # 不退出，继续
"

echo "🔧 重启后端服务..."
sudo systemctl restart ipv6-wireguard-manager

echo "⏳ 等待服务启动..."
sleep 10

echo "🔍 检查服务状态..."
if sudo systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "✅ 后端服务运行正常"
else
    echo "❌ 后端服务异常"
    echo "📋 服务状态:"
    sudo systemctl status ipv6-wireguard-manager --no-pager -l
fi

echo "🔍 测试API访问..."
if curl -s "http://localhost:8000/api/v1/status/status" >/dev/null 2>&1; then
    echo "✅ API访问正常"
else
    echo "❌ API访问异常"
fi

echo "🔍 测试Web访问..."
if curl -s "http://localhost" >/dev/null 2>&1; then
    echo "✅ Web访问正常"
else
    echo "❌ Web访问异常"
fi

echo ""
echo "🎉 数据库初始化修复完成！"
echo ""
echo "📋 访问信息:"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')
echo "   Web界面: http://$SERVER_IP"
echo "   API文档: http://$SERVER_IP:8000/docs"
echo ""
echo "🔧 如果仍有问题，请检查:"
echo "   1. 数据库服务状态: sudo systemctl status postgresql"
echo "   2. 后端服务日志: sudo journalctl -u ipv6-wireguard-manager -f"
echo "   3. Nginx状态: sudo systemctl status nginx"
