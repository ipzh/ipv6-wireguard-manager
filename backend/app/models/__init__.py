"""
数据库模型 - 统一使用models_complete.py和enhanced_models.py中的模型定义
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

# 导入增强功能模型
from .enhanced_models import (
    PasswordHistory, MFASettings, MFASession, UserSession,
    AlertRule, Alert, NotificationConfig, CacheStats,
    PerformanceMetrics, SystemMetrics, SecurityLog,
    APIAccessLog, SystemConfig, HealthCheck
)

__all__ = [
    "Base",
    # 基础模型
    "User", "Role", "Permission", "UserRole", "RolePermission",
    "WireGuardServer", "WireGuardClient", "BGPSession", "BGPAnnouncement",
    "IPv6Pool", "IPv6Allocation", "AuditLog", "SystemLog",
    "NetworkInterface", "NetworkAddress", "user_roles", "role_permissions",
    "WireGuardStatus", "BGPStatus", "IPv6PoolStatus", "LogLevel",
    # 增强功能模型
    "PasswordHistory", "MFASettings", "MFASession", "UserSession",
    "AlertRule", "Alert", "NotificationConfig", "CacheStats",
    "PerformanceMetrics", "SystemMetrics", "SecurityLog",
    "APIAccessLog", "SystemConfig", "HealthCheck"
]
