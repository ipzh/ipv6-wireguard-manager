"""
API v1 路由 - 精简版
减少复杂的动态路由加载，使用静态路由定义
"""
from fastapi import APIRouter
from .endpoints import (
    auth,
    users,
    wireguard,
    ipv6,
    bgp,
    monitoring,
    system,
    health,
    debug
)

# 创建主路由器
api_router = APIRouter()

# 认证路由
api_router.include_router(
    auth.router,
    prefix="/auth",
    tags=["认证管理"]
)

# 用户管理路由
api_router.include_router(
    users.router,
    prefix="/users",
    tags=["用户管理"]
)

# WireGuard管理路由
api_router.include_router(
    wireguard.router,
    prefix="/wireguard",
    tags=["WireGuard管理"]
)

# IPv6管理路由
api_router.include_router(
    ipv6.router,
    prefix="/ipv6",
    tags=["IPv6管理"]
)

# BGP管理路由
api_router.include_router(
    bgp.router,
    prefix="/bgp",
    tags=["BGP管理"]
)

# 监控路由
api_router.include_router(
    monitoring.router,
    prefix="/monitoring",
    tags=["监控管理"]
)

# 系统管理路由
api_router.include_router(
    system.router,
    prefix="/system",
    tags=["系统管理"]
)

# 健康检查路由
api_router.include_router(
    health.router,
    prefix="/health",
    tags=["健康检查"]
)

# 调试路由（仅在调试模式下）
if __name__ == "__main__" or True:  # 临时启用调试路由
    api_router.include_router(
        debug.router,
        prefix="/debug",
        tags=["调试信息"]
    )
