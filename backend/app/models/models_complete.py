"""
完整的数据模型定义 - 解决模型不完整问题
"""
from sqlalchemy import (
    Column, String, Boolean, DateTime, Text, ForeignKey, Table,
    Integer, Float, JSON, Enum, Index, UniqueConstraint, CheckConstraint
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from sqlalchemy.dialects.postgresql import UUID, INET, CIDR
from sqlalchemy.dialects.mysql import JSON as MySQLJSON
import uuid
from datetime import datetime
from enum import Enum as PyEnum

from ..core.database import Base


# 枚举定义
class UserRole(PyEnum):
    ADMIN = "admin"
    OPERATOR = "operator"
    USER = "user"


class WireGuardStatus(PyEnum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    PENDING = "pending"
    ERROR = "error"


class BGPStatus(PyEnum):
    ESTABLISHED = "established"
    IDLE = "idle"
    CONNECT = "connect"
    ACTIVE = "active"
    OPENSENT = "opensent"
    OPENCONFIRM = "openconfirm"


class IPv6PoolStatus(PyEnum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    DEPLETED = "depleted"


class LogLevel(PyEnum):
    DEBUG = "debug"
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


# 关联表定义
user_roles = Table(
    'user_roles',
    Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id', ondelete='CASCADE'), primary_key=True),
    Column('role_id', Integer, ForeignKey('roles.id', ondelete='CASCADE'), primary_key=True),
    Column('created_at', DateTime(timezone=True), server_default=func.now()),
    Index('idx_user_roles_user_id', 'user_id'),
    Index('idx_user_roles_role_id', 'role_id'),
)

role_permissions = Table(
    'role_permissions',
    Base.metadata,
    Column('role_id', Integer, ForeignKey('roles.id', ondelete='CASCADE'), primary_key=True),
    Column('permission_id', Integer, ForeignKey('permissions.id', ondelete='CASCADE'), primary_key=True),
    Column('created_at', DateTime(timezone=True), server_default=func.now()),
    Index('idx_role_permissions_role_id', 'role_id'),
    Index('idx_role_permissions_permission_id', 'permission_id'),
)


class User(Base):
    """用户模型"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    uuid = Column(String(36), unique=True, nullable=False, default=lambda: str(uuid.uuid4()))
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100), nullable=True)
    phone = Column(String(20), nullable=True)
    avatar_url = Column(String(500), nullable=True)
    
    # 状态字段
    is_active = Column(Boolean, default=True, nullable=False)
    is_superuser = Column(Boolean, default=False, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    
    # 时间字段
    last_login = Column(DateTime(timezone=True), nullable=True)
    last_activity = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # 安全字段
    failed_login_attempts = Column(Integer, default=0, nullable=False)
    locked_until = Column(DateTime(timezone=True), nullable=True)
    password_changed_at = Column(DateTime(timezone=True), nullable=True)
    
    # 关系
    roles = relationship("Role", secondary=user_roles, back_populates="users")
    audit_logs = relationship("AuditLog", back_populates="user")
    wireguard_servers = relationship("WireGuardServer", back_populates="created_by_user")
    wireguard_clients = relationship("WireGuardClient", back_populates="created_by_user")
    
    # 索引
    __table_args__ = (
        Index('idx_users_email', 'email'),
        Index('idx_users_username', 'username'),
        Index('idx_users_is_active', 'is_active'),
        Index('idx_users_created_at', 'created_at'),
    )

    def __repr__(self):
        return f"<User(id={self.id}, username={self.username})>"


class Role(Base):
    """角色模型"""
    __tablename__ = "roles"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(50), unique=True, nullable=False, index=True)
    display_name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    is_system = Column(Boolean, default=False, nullable=False)  # 系统角色不能删除
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # 关系
    users = relationship("User", secondary=user_roles, back_populates="roles")
    permissions = relationship("Permission", secondary=role_permissions, back_populates="roles")
    
    # 索引
    __table_args__ = (
        Index('idx_roles_name', 'name'),
        Index('idx_roles_is_system', 'is_system'),
    )

    def __repr__(self):
        return f"<Role(id={self.id}, name={self.name})>"


class Permission(Base):
    """权限模型"""
    __tablename__ = "permissions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    resource = Column(String(50), nullable=False)  # 资源类型：users, wireguard, bgp, etc.
    action = Column(String(50), nullable=False)    # 操作类型：view, create, edit, delete, manage
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # 关系
    roles = relationship("Role", secondary=role_permissions, back_populates="permissions")
    
    # 索引
    __table_args__ = (
        Index('idx_permissions_name', 'name'),
        Index('idx_permissions_resource', 'resource'),
        Index('idx_permissions_action', 'action'),
        UniqueConstraint('resource', 'action', name='uq_permission_resource_action'),
    )

    def __repr__(self):
        return f"<Permission(id={self.id}, name={self.name})>"


class WireGuardServer(Base):
    """WireGuard服务器模型"""
    __tablename__ = "wireguard_servers"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    interface = Column(String(20), nullable=False, default="wg0")
    
    # 网络配置
    private_key = Column(String(255), nullable=False)
    public_key = Column(String(255), nullable=False, index=True)
    listen_port = Column(Integer, nullable=False, default=51820)
    address = Column(String(100), nullable=False)  # 服务器IP地址
    dns = Column(String(255), nullable=True)       # DNS服务器
    
    # 状态
    status = Column(Enum(WireGuardStatus), default=WireGuardStatus.INACTIVE, nullable=False)
    is_enabled = Column(Boolean, default=True, nullable=False)
    
    # 统计信息
    total_clients = Column(Integer, default=0, nullable=False)
    active_clients = Column(Integer, default=0, nullable=False)
    total_bytes_sent = Column(BigInteger, default=0, nullable=False)
    total_bytes_received = Column(BigInteger, default=0, nullable=False)
    
    # 时间字段
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    last_sync = Column(DateTime(timezone=True), nullable=True)
    
    # 外键
    created_by = Column(Integer, ForeignKey('users.id'), nullable=False)
    
    # 关系
    created_by_user = relationship("User", back_populates="wireguard_servers")
    clients = relationship("WireGuardClient", back_populates="server")
    
    # 索引
    __table_args__ = (
        Index('idx_wg_servers_name', 'name'),
        Index('idx_wg_servers_status', 'status'),
        Index('idx_wg_servers_created_by', 'created_by'),
        Index('idx_wg_servers_created_at', 'created_at'),
    )

    def __repr__(self):
        return f"<WireGuardServer(id={self.id}, name={self.name})>"


class WireGuardClient(Base):
    """WireGuard客户端模型"""
    __tablename__ = "wireguard_clients"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False, index=True)
    description = Column(Text, nullable=True)
    
    # 网络配置
    private_key = Column(String(255), nullable=False)
    public_key = Column(String(255), nullable=False, index=True)
    allowed_ips = Column(String(255), nullable=False)  # 允许的IP地址
    endpoint = Column(String(255), nullable=True)      # 客户端端点
    
    # 状态
    status = Column(Enum(WireGuardStatus), default=WireGuardStatus.INACTIVE, nullable=False)
    is_enabled = Column(Boolean, default=True, nullable=False)
    
    # 统计信息
    bytes_sent = Column(BigInteger, default=0, nullable=False)
    bytes_received = Column(BigInteger, default=0, nullable=False)
    last_handshake = Column(DateTime(timezone=True), nullable=True)
    
    # 时间字段
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # 外键
    server_id = Column(Integer, ForeignKey('wireguard_servers.id', ondelete='CASCADE'), nullable=False)
    created_by = Column(Integer, ForeignKey('users.id'), nullable=False)
    
    # 关系
    server = relationship("WireGuardServer", back_populates="clients")
    created_by_user = relationship("User", back_populates="wireguard_clients")
    
    # 索引
    __table_args__ = (
        Index('idx_wg_clients_name', 'name'),
        Index('idx_wg_clients_server_id', 'server_id'),
        Index('idx_wg_clients_status', 'status'),
        Index('idx_wg_clients_created_by', 'created_by'),
        UniqueConstraint('server_id', 'name', name='uq_wg_client_server_name'),
    )

    def __repr__(self):
        return f"<WireGuardClient(id={self.id}, name={self.name})>"


class BGPSession(Base):
    """BGP会话模型"""
    __tablename__ = "bgp_sessions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    
    # BGP配置
    local_as = Column(Integer, nullable=False)
    remote_as = Column(Integer, nullable=False)
    local_ip = Column(String(45), nullable=False)    # 支持IPv4和IPv6
    remote_ip = Column(String(45), nullable=False)   # 支持IPv4和IPv6
    hold_time = Column(Integer, default=180, nullable=False)
    keepalive_time = Column(Integer, default=60, nullable=False)
    
    # 状态
    status = Column(Enum(BGPStatus), default=BGPStatus.IDLE, nullable=False)
    is_enabled = Column(Boolean, default=True, nullable=False)
    
    # 统计信息
    established_time = Column(DateTime(timezone=True), nullable=True)
    last_update = Column(DateTime(timezone=True), nullable=True)
    prefixes_received = Column(Integer, default=0, nullable=False)
    prefixes_sent = Column(Integer, default=0, nullable=False)
    
    # 时间字段
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # 外键
    created_by = Column(Integer, ForeignKey('users.id'), nullable=False)
    
    # 关系
    created_by_user = relationship("User")
    announcements = relationship("BGPAnnouncement", back_populates="session")
    
    # 索引
    __table_args__ = (
        Index('idx_bgp_sessions_name', 'name'),
        Index('idx_bgp_sessions_status', 'status'),
        Index('idx_bgp_sessions_created_by', 'created_by'),
        Index('idx_bgp_sessions_remote_ip', 'remote_ip'),
    )

    def __repr__(self):
        return f"<BGPSession(id={self.id}, name={self.name})>"


class BGPAnnouncement(Base):
    """BGP宣告模型"""
    __tablename__ = "bgp_announcements"

    id = Column(Integer, primary_key=True, autoincrement=True)
    prefix = Column(String(50), nullable=False)  # 宣告的前缀
    description = Column(Text, nullable=True)
    
    # 状态
    is_active = Column(Boolean, default=True, nullable=False)
    
    # 时间字段
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # 外键
    session_id = Column(Integer, ForeignKey('bgp_sessions.id', ondelete='CASCADE'), nullable=False)
    created_by = Column(Integer, ForeignKey('users.id'), nullable=False)
    
    # 关系
    session = relationship("BGPSession", back_populates="announcements")
    created_by_user = relationship("User")
    
    # 索引
    __table_args__ = (
        Index('idx_bgp_announcements_prefix', 'prefix'),
        Index('idx_bgp_announcements_session_id', 'session_id'),
        Index('idx_bgp_announcements_is_active', 'is_active'),
        UniqueConstraint('session_id', 'prefix', name='uq_bgp_announcement_session_prefix'),
    )

    def __repr__(self):
        return f"<BGPAnnouncement(id={self.id}, prefix={self.prefix})>"


class IPv6Pool(Base):
    """IPv6前缀池模型"""
    __tablename__ = "ipv6_pools"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    
    # IPv6配置
    prefix = Column(String(50), nullable=False)      # IPv6前缀
    prefix_length = Column(Integer, nullable=False)  # 前缀长度
    total_addresses = Column(BigInteger, nullable=False)  # 总地址数
    
    # 状态
    status = Column(Enum(IPv6PoolStatus), default=IPv6PoolStatus.ACTIVE, nullable=False)
    is_enabled = Column(Boolean, default=True, nullable=False)
    
    # 统计信息
    allocated_addresses = Column(BigInteger, default=0, nullable=False)
    available_addresses = Column(BigInteger, nullable=False)  # 可用地址数
    
    # 时间字段
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # 外键
    created_by = Column(Integer, ForeignKey('users.id'), nullable=False)
    
    # 关系
    created_by_user = relationship("User")
    allocations = relationship("IPv6Allocation", back_populates="pool")
    
    # 索引
    __table_args__ = (
        Index('idx_ipv6_pools_name', 'name'),
        Index('idx_ipv6_pools_prefix', 'prefix'),
        Index('idx_ipv6_pools_status', 'status'),
        Index('idx_ipv6_pools_created_by', 'created_by'),
    )

    def __repr__(self):
        return f"<IPv6Pool(id={self.id}, name={self.name})>"


class IPv6Allocation(Base):
    """IPv6分配模型"""
    __tablename__ = "ipv6_allocations"

    id = Column(Integer, primary_key=True, autoincrement=True)
    allocated_prefix = Column(String(50), nullable=False)  # 分配的IPv6前缀
    prefix_length = Column(Integer, nullable=False)        # 分配的前缀长度
    description = Column(Text, nullable=True)
    
    # 状态
    is_active = Column(Boolean, default=True, nullable=False)
    
    # 时间字段
    allocated_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # 外键
    pool_id = Column(Integer, ForeignKey('ipv6_pools.id', ondelete='CASCADE'), nullable=False)
    client_id = Column(Integer, ForeignKey('wireguard_clients.id', ondelete='SET NULL'), nullable=True)
    created_by = Column(Integer, ForeignKey('users.id'), nullable=False)
    
    # 关系
    pool = relationship("IPv6Pool", back_populates="allocations")
    client = relationship("WireGuardClient")
    created_by_user = relationship("User")
    
    # 索引
    __table_args__ = (
        Index('idx_ipv6_allocations_prefix', 'allocated_prefix'),
        Index('idx_ipv6_allocations_pool_id', 'pool_id'),
        Index('idx_ipv6_allocations_client_id', 'client_id'),
        Index('idx_ipv6_allocations_is_active', 'is_active'),
        UniqueConstraint('allocated_prefix', name='uq_ipv6_allocation_prefix'),
    )

    def __repr__(self):
        return f"<IPv6Allocation(id={self.id}, prefix={self.allocated_prefix})>"


class AuditLog(Base):
    """审计日志模型"""
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    
    # 操作信息
    action = Column(String(100), nullable=False)      # 操作类型
    resource_type = Column(String(50), nullable=False) # 资源类型
    resource_id = Column(String(50), nullable=True)    # 资源ID
    description = Column(Text, nullable=True)          # 操作描述
    
    # 请求信息
    ip_address = Column(String(45), nullable=True)     # 支持IPv4和IPv6
    user_agent = Column(Text, nullable=True)
    request_method = Column(String(10), nullable=True)
    request_path = Column(String(500), nullable=True)
    
    # 结果
    success = Column(Boolean, nullable=False)
    error_message = Column(Text, nullable=True)
    
    # 时间字段
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # 外键
    user_id = Column(Integer, ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    
    # 关系
    user = relationship("User", back_populates="audit_logs")
    
    # 索引
    __table_args__ = (
        Index('idx_audit_logs_action', 'action'),
        Index('idx_audit_logs_resource_type', 'resource_type'),
        Index('idx_audit_logs_user_id', 'user_id'),
        Index('idx_audit_logs_created_at', 'created_at'),
        Index('idx_audit_logs_success', 'success'),
    )

    def __repr__(self):
        return f"<AuditLog(id={self.id}, action={self.action})>"


class SystemLog(Base):
    """系统日志模型"""
    __tablename__ = "system_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    
    # 日志信息
    level = Column(Enum(LogLevel), nullable=False)
    message = Column(Text, nullable=False)
    module = Column(String(100), nullable=True)
    function = Column(String(100), nullable=True)
    line_number = Column(Integer, nullable=True)
    
    # 额外信息
    extra_data = Column(JSON, nullable=True)  # 额外的结构化数据
    
    # 时间字段
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # 索引
    __table_args__ = (
        Index('idx_system_logs_level', 'level'),
        Index('idx_system_logs_module', 'module'),
        Index('idx_system_logs_created_at', 'created_at'),
    )

    def __repr__(self):
        return f"<SystemLog(id={self.id}, level={self.level})>"


class NetworkInterface(Base):
    """网络接口模型"""
    __tablename__ = "network_interfaces"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(50), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    
    # 接口信息
    interface_type = Column(String(20), nullable=False)  # ethernet, wireless, tunnel, etc.
    mac_address = Column(String(17), nullable=True)
    mtu = Column(Integer, default=1500, nullable=False)
    
    # 状态
    is_up = Column(Boolean, default=False, nullable=False)
    is_enabled = Column(Boolean, default=True, nullable=False)
    
    # 统计信息
    bytes_sent = Column(BigInteger, default=0, nullable=False)
    bytes_received = Column(BigInteger, default=0, nullable=False)
    packets_sent = Column(BigInteger, default=0, nullable=False)
    packets_received = Column(BigInteger, default=0, nullable=False)
    
    # 时间字段
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    last_updated = Column(DateTime(timezone=True), nullable=True)
    
    # 关系
    addresses = relationship("NetworkAddress", back_populates="interface")
    
    # 索引
    __table_args__ = (
        Index('idx_network_interfaces_name', 'name'),
        Index('idx_network_interfaces_type', 'interface_type'),
        Index('idx_network_interfaces_is_up', 'is_up'),
    )

    def __repr__(self):
        return f"<NetworkInterface(id={self.id}, name={self.name})>"


class NetworkAddress(Base):
    """网络地址模型"""
    __tablename__ = "network_addresses"

    id = Column(Integer, primary_key=True, autoincrement=True)
    address = Column(String(50), nullable=False)  # IP地址
    prefix_length = Column(Integer, nullable=False)  # 前缀长度
    address_type = Column(String(10), nullable=False)  # ipv4, ipv6
    
    # 状态
    is_primary = Column(Boolean, default=False, nullable=False)
    is_enabled = Column(Boolean, default=True, nullable=False)
    
    # 时间字段
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # 外键
    interface_id = Column(Integer, ForeignKey('network_interfaces.id', ondelete='CASCADE'), nullable=False)
    
    # 关系
    interface = relationship("NetworkInterface", back_populates="addresses")
    
    # 索引
    __table_args__ = (
        Index('idx_network_addresses_address', 'address'),
        Index('idx_network_addresses_interface_id', 'interface_id'),
        Index('idx_network_addresses_type', 'address_type'),
        UniqueConstraint('interface_id', 'address', name='uq_network_address_interface_address'),
    )

    def __repr__(self):
        return f"<NetworkAddress(id={self.id}, address={self.address})>"


# 导出所有模型
__all__ = [
    "User", "Role", "Permission", "UserRole", "RolePermission",
    "WireGuardServer", "WireGuardClient", "WireGuardStatus",
    "BGPSession", "BGPAnnouncement", "BGPStatus",
    "IPv6Pool", "IPv6Allocation", "IPv6PoolStatus",
    "AuditLog", "SystemLog", "LogLevel",
    "NetworkInterface", "NetworkAddress"
]
