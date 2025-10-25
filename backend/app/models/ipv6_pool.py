"""
IPv6前缀池模型
"""
from sqlalchemy import Column, String, Boolean, Integer, DateTime, ForeignKey, Text, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum

from ..core.database import Base


class PoolStatus(str, enum.Enum):
    """前缀池状态"""
    ACTIVE = "active"
    DEPLETED = "depleted"
    MAINTENANCE = "maintenance"
    DISABLED = "disabled"


class IPv6PrefixPool(Base):
    __tablename__ = "ipv6_prefix_pools"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False, unique=True)
    prefix = Column(String(128), nullable=False)  # 如 2001:db8::/48
    prefix_length = Column(Integer, nullable=False)  # 如 64
    total_capacity = Column(Integer, nullable=False)  # 总容量
    used_count = Column(Integer, default=0)  # 已使用数量
    status = Column(Enum(PoolStatus), default=PoolStatus.ACTIVE)
    description = Column(Text, nullable=True)
    auto_announce = Column(Boolean, default=False)  # 分配即宣告
    max_prefix_limit = Column(Integer, nullable=True)  # 最大前缀限制
    whitelist_enabled = Column(Boolean, default=False)  # 启用白名单
    rpki_enabled = Column(Boolean, default=False)  # 启用RPKI预检
    enabled = Column(Boolean, default=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # 关联关系
    allocations = relationship("IPv6Allocation", back_populates="pool", cascade="all, delete-orphan")
    whitelist_entries = relationship("IPv6Whitelist", back_populates="pool", cascade="all, delete-orphan")


class IPv6Allocation(Base):
    __tablename__ = "ipv6_allocations"

    id = Column(Integer, primary_key=True, autoincrement=True)
    pool_id = Column(Integer, ForeignKey("ipv6_prefix_pools.id"), nullable=False)
    client_id = Column(Integer, ForeignKey("wireguard_clients.id"), nullable=True)
    server_id = Column(Integer, ForeignKey("wireguard_servers.id"), nullable=True)
    
    allocated_prefix = Column(String(128), nullable=False)  # 分配的前缀
    allocated_at = Column(DateTime(timezone=True), server_default=func.now())
    released_at = Column(DateTime(timezone=True), nullable=True)
    is_active = Column(Boolean, default=True)
    
    # 关联关系
    pool = relationship("IPv6PrefixPool", back_populates="allocations")
    client = relationship("WireGuardClient", back_populates="ipv6_allocations")
    server = relationship("WireGuardServer", back_populates="ipv6_allocations")


class IPv6Whitelist(Base):
    __tablename__ = "ipv6_whitelist"

    id = Column(Integer, primary_key=True, autoincrement=True)
    pool_id = Column(Integer, ForeignKey("ipv6_prefix_pools.id"), nullable=False)
    prefix = Column(String(128), nullable=False)  # 白名单前缀
    description = Column(Text, nullable=True)
    enabled = Column(Boolean, default=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 关联关系
    pool = relationship("IPv6PrefixPool", back_populates="whitelist_entries")


class BGPAlert(Base):
    __tablename__ = "bgp_alerts"

    id = Column(Integer, primary_key=True, autoincrement=True)
    alert_type = Column(String(50), nullable=False)  # RPKI_INVALID, PREFIX_LIMIT, etc.
    severity = Column(String(20), nullable=False)  # INFO, WARNING, ERROR, CRITICAL
    message = Column(Text, nullable=False)
    prefix = Column(String(128), nullable=True)
    session_id = Column(Integer, ForeignKey("bgp_sessions.id"), nullable=True)
    pool_id = Column(Integer, ForeignKey("ipv6_prefix_pools.id"), nullable=True)
    
    is_resolved = Column(Boolean, default=False)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 关联关系
    session = relationship("BGPSession")
    pool = relationship("IPv6PrefixPool")
