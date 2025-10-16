"""
Pydantic模式定义
"""
from .user import User, UserCreate, UserUpdate, UserInDB, Role, RoleCreate, RoleUpdate
from .wireguard import (
    WireGuardServer, WireGuardServerCreate, WireGuardServerUpdate,
    WireGuardClient, WireGuardClientCreate, WireGuardClientUpdate
)
from .network import NetworkInterface, NetworkInterfaceCreate, FirewallRule, FirewallRuleCreate
from .monitoring import SystemMetric, AuditLog, OperationLog
from .config import ConfigVersion, BackupRecord
from .common import Token, TokenPayload, Message

__all__ = [
    "User",
    "UserCreate", 
    "UserUpdate",
    "UserInDB",
    "Role",
    "RoleCreate",
    "RoleUpdate",
    "WireGuardServer",
    "WireGuardServerCreate",
    "WireGuardServerUpdate",
    "WireGuardClient",
    "WireGuardClientCreate", 
    "WireGuardClientUpdate",
    "NetworkInterface",
    "NetworkInterfaceCreate",
    "FirewallRule",
    "FirewallRuleCreate",
    "SystemMetric",
    "AuditLog",
    "OperationLog",
    "ConfigVersion",
    "BackupRecord",
    "Token",
    "TokenPayload",
    "Message",
    "TokenResponse",
    "MessageResponse",
]
