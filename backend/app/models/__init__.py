"""
数据库模型 - 统一使用 models_complete.py 中的模型定义
说明：UserRole / RolePermission 已通过关联表实现，不再导出独立模型类
"""
from ..core.database import Base
from .models_complete import (
    User, Role, Permission,
    WireGuardServer, WireGuardClient,
    BGPSession, BGPAnnouncement,
    IPv6Pool, IPv6Allocation,
    AuditLog, SystemLog,
    NetworkInterface, NetworkAddress,
    user_roles, role_permissions,
    WireGuardStatus, BGPStatus, IPv6PoolStatus, LogLevel
)

# 若需增强功能（如 MFA、告警系统等），需先实现 enhanced_models 并取消以下注释
# from .enhanced_models import (...)

__all__ = [
    "Base",
    # 核心模型
    "User", "Role", "Permission",
    # WireGuard 管理
    "WireGuardServer", "WireGuardClient",
    # BGP 路由
    "BGPSession", "BGPAnnouncement",
    # IPv6 地址管理
    "IPv6Pool", "IPv6Allocation",
    # 日志与审计
    "AuditLog", "SystemLog",
    # 网络配置
    "NetworkInterface", "NetworkAddress",
    # 关联表（多对多关系）
    "user_roles", "role_permissions",
    # 枚举类型
    "WireGuardStatus", "BGPStatus", "IPv6PoolStatus", "LogLevel",
]
