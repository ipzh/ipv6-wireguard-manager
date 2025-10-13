"""
数据库模型
"""
from ..core.database import Base
from .user import User, Role, UserRole
from .wireguard import WireGuardServer, WireGuardClient, ClientServerRelation
from .network import NetworkInterface, FirewallRule
from .bgp import BGPSession, BGPAnnouncement, BGPOperation, SessionStatus, OperationType
from .ipv6_pool import IPv6PrefixPool, IPv6Allocation, IPv6Whitelist, BGPAlert, PoolStatus
from .monitoring import SystemMetric, AuditLog
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
    "BGPSession",
    "BGPAnnouncement",
    "BGPOperation",
    "SessionStatus",
    "OperationType",
    "IPv6PrefixPool",
    "IPv6Allocation",
    "IPv6Whitelist",
    "BGPAlert",
    "PoolStatus",
    "SystemMetric",
    "AuditLog",
    "ConfigVersion",
    "BackupRecord",
]
