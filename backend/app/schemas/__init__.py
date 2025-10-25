"""
Pydantic模式定义
"""
from .user import UserBase, UserCreate, UserUpdate, UserResponse, UserListResponse, RoleBase, RoleCreate, RoleUpdate, RoleResponse, PermissionBase, PermissionCreate, PermissionResponse
from .wireguard import (
    WireGuardServer, WireGuardServerCreate, WireGuardServerUpdate,
    WireGuardClient, WireGuardClientCreate, WireGuardClientUpdate
)
from .network import NetworkInterface, NetworkInterfaceCreate, FirewallRule, FirewallRuleCreate
from .monitoring import SystemMetric, AuditLog, OperationLog
from .config import ConfigVersion, BackupRecord
from .auth import Token, TokenRefresh, UserLogin, PasswordChange, PasswordReset, UserRegister, ForgotPassword, TokenVerify
from .common import BaseResponse, ErrorResponse, PaginationResponse, HealthCheckResponse, SystemInfoResponse, DatabaseStatusResponse

__all__ = [
    "UserBase",
    "UserCreate", 
    "UserUpdate",
    "UserResponse",
    "UserListResponse",
    "RoleBase",
    "RoleCreate",
    "RoleUpdate",
    "RoleResponse",
    "PermissionBase",
    "PermissionCreate",
    "PermissionResponse",
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
    "TokenRefresh",
    "UserLogin",
    "PasswordChange",
    "PasswordReset",
    "UserRegister",
    "ForgotPassword",
    "TokenVerify",
    "BaseResponse",
    "ErrorResponse",
    "PaginationResponse",
    "HealthCheckResponse",
    "SystemInfoResponse",
    "DatabaseStatusResponse",
]
