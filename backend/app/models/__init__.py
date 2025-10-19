"""
数据库模型 - 统一使用models_complete.py中的模型定义
"""
from ..core.database import Base
from .models_complete import (
    User, Role, Permission, UserRole, RolePermission,
    WireGuardServer, WireGuardClient,
    BGPSession, BGPAnnouncement,
    IPv6Pool, IPv6Allocation,
    AuditLog, SystemLog,
    NetworkInterface, NetworkAddress,
    user_roles, role_permissions,
    WireGuardStatus, BGPStatus, IPv6PoolStatus, LogLevel
)

__all__ = [
    "Base",
    "User",
    "Role", 
    "Permission",
    "UserRole",
    "RolePermission",
    "WireGuardServer",
    "WireGuardClient",
    "BGPSession",
    "BGPAnnouncement",
    "IPv6Pool",
    "IPv6Allocation",
    "AuditLog",
    "SystemLog",
    "NetworkInterface",
    "NetworkAddress",
    "user_roles",
    "role_permissions",
    "WireGuardStatus",
    "BGPStatus",
    "IPv6PoolStatus",
    "LogLevel",
]
