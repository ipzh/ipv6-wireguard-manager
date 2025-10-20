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

# 导入增强功能模型
# 注意：enhanced_models.py暂时不存在，已注释掉相关导入
# from .enhanced_models import (
#     PasswordHistory, MFASettings, MFASession, UserSession,
#     AlertRule, Alert, NotificationConfig, CacheStats,
#     PerformanceMetrics, SystemMetrics, SecurityLog,
#     APIAccessLog, SystemConfig, HealthCheck
# )

__all__ = [
    "Base",
    # 基础模型
    "User", "Role", "Permission", "UserRole", "RolePermission",
    "WireGuardServer", "WireGuardClient", "BGPSession", "BGPAnnouncement",
    "IPv6Pool", "IPv6Allocation", "AuditLog", "SystemLog",
    "NetworkInterface", "NetworkAddress", "user_roles", "role_permissions",
    "WireGuardStatus", "BGPStatus", "IPv6PoolStatus", "LogLevel",
    # 增强功能模型 - 暂时注释掉
    # "PasswordHistory", "MFASettings", "MFASession", "UserSession",
    # "AlertRule", "Alert", "NotificationConfig", "CacheStats",
    # "PerformanceMetrics", "SystemMetrics", "SecurityLog",
    # "APIAccessLog", "SystemConfig", "HealthCheck"
]
