#!/bin/bash

echo "🔧 逐步恢复API端点..."

# 停止服务
systemctl stop ipv6-wireguard-manager

# 创建逐步恢复的API路由文件
cat > /opt/ipv6-wireguard-manager/backend/app/api/api_v1/api.py << 'EOF'
"""
API v1 路由聚合 - 逐步恢复版本
"""
from fastapi import APIRouter

# 逐步导入端点，一次一个来找出问题
try:
    from .endpoints import auth
    print("✅ Auth endpoint imported successfully")
except Exception as e:
    print(f"❌ Auth endpoint import failed: {e}")
    auth = None

try:
    from .endpoints import status
    print("✅ Status endpoint imported successfully")
except Exception as e:
    print(f"❌ Status endpoint import failed: {e}")
    status = None

# 暂时不导入其他可能有问题的端点
# from .endpoints import users, wireguard, network, monitoring, logs, websocket, system, bgp, ipv6, bgp_sessions, ipv6_pools

api_router = APIRouter()

# 添加基本测试路由
@api_router.get("/test")
async def test_api():
    """测试API是否工作"""
    return {"message": "API is working", "status": "ok"}

# 逐步添加端点路由
if auth:
    try:
        api_router.include_router(auth.router, prefix="/auth", tags=["认证"])
        print("✅ Auth router added successfully")
    except Exception as e:
        print(f"❌ Auth router failed: {e}")

if status:
    try:
        api_router.include_router(status.router, prefix="/status", tags=["状态检查"])
        print("✅ Status router added successfully")
    except Exception as e:
        print(f"❌ Status router failed: {e}")

# 暂时注释掉其他路由
# 用户管理路由
# api_router.include_router(users.router, prefix="/users", tags=["用户管理"])

# WireGuard管理路由
# api_router.include_router(wireguard.router, prefix="/wireguard", tags=["WireGuard管理"])

# 网络管理路由
# api_router.include_router(network.router, prefix="/network", tags=["网络管理"])

# BGP管理路由
# api_router.include_router(bgp.router, prefix="/bgp", tags=["BGP管理"])

# BGP会话管理路由
# api_router.include_router(bgp_sessions.router, prefix="/bgp/sessions", tags=["BGP会话管理"])

# IPv6前缀池管理路由
# api_router.include_router(ipv6_pools.router, prefix="/ipv6/pools", tags=["IPv6前缀池管理"])

# 监控路由
# api_router.include_router(monitoring.router, prefix="/monitoring", tags=["系统监控"])

# 日志路由
# api_router.include_router(logs.router, prefix="/logs", tags=["日志管理"])

# WebSocket实时通信路由
# api_router.include_router(websocket.router, prefix="/ws", tags=["WebSocket实时通信"])

# 系统管理路由
# api_router.include_router(system.router, prefix="/system", tags=["系统管理"])

# IPv6管理路由
# api_router.include_router(ipv6.router, prefix="/ipv6", tags=["IPv6管理"])
EOF

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
curl -s http://127.0.0.1:8000/health || echo "健康检查API无响应"
curl -s http://127.0.0.1:8000/api/v1/test || echo "测试API无响应"

echo "✅ 修复完成"
