"""
API v1 路由聚合
"""
from fastapi import APIRouter

# 导入所有端点模块
try:
    from .endpoints import auth, users, wireguard, network, monitoring, logs, websocket, system, status, bgp, ipv6, health, debug
except ImportError as e:
    print(f"Warning: Some endpoint modules could not be imported: {e}")
    # 创建空的模块作为占位符
    class EmptyModule:
        router = APIRouter()
    
    auth = EmptyModule()
    users = EmptyModule()
    wireguard = EmptyModule()
    network = EmptyModule()
    monitoring = EmptyModule()
    logs = EmptyModule()
    websocket = EmptyModule()
    system = EmptyModule()
    status = EmptyModule()
    bgp = EmptyModule()
    ipv6 = EmptyModule()
    health = EmptyModule()
    debug = EmptyModule()

api_router = APIRouter()

# 认证相关路由
api_router.include_router(auth.router, prefix="/auth", tags=["认证"])

# 用户管理路由
api_router.include_router(users.router, prefix="/users", tags=["用户管理"])

# WireGuard管理路由
api_router.include_router(wireguard.router, prefix="/wireguard", tags=["WireGuard管理"])

# 网络管理路由
api_router.include_router(network.router, prefix="/network", tags=["网络管理"])

# BGP管理路由
api_router.include_router(bgp.router, prefix="/bgp", tags=["BGP管理"])

# 监控路由
api_router.include_router(monitoring.router, prefix="/monitoring", tags=["系统监控"])

# 日志路由
api_router.include_router(logs.router, prefix="/logs", tags=["日志管理"])

# WebSocket实时通信路由
api_router.include_router(websocket.router, prefix="/ws", tags=["WebSocket实时通信"])

# 系统管理路由
api_router.include_router(system.router, prefix="/system", tags=["系统管理"])

# IPv6管理路由
api_router.include_router(ipv6.router, prefix="/ipv6", tags=["IPv6管理"])

# 状态检查路由
api_router.include_router(status.router, prefix="/status", tags=["状态检查"])

# 健康检查路由
api_router.include_router(health.router, prefix="", tags=["健康检查"])

# 调试和诊断路由
api_router.include_router(debug.router, prefix="/debug", tags=["调试诊断"])