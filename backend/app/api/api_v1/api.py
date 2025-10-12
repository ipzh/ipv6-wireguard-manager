"""
API v1 路由聚合
"""
from fastapi import APIRouter

from .endpoints import auth, users, wireguard, network, monitoring, logs, websocket, system, status, bgp, ipv6, bgp_sessions, ipv6_pools

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

# BGP会话管理路由
api_router.include_router(bgp_sessions.router, prefix="/bgp/sessions", tags=["BGP会话管理"])

# IPv6前缀池管理路由
api_router.include_router(ipv6_pools.router, prefix="/ipv6/pools", tags=["IPv6前缀池管理"])

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
