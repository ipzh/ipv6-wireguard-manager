"""
网络相关模型
"""
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text
from sqlalchemy.dialects.postgresql import UUID, INET, MACADDR
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

# 兼容性处理：某些SQLAlchemy版本可能没有INET6
try:
    from sqlalchemy.dialects.postgresql import INET6
except ImportError:
    # 如果没有INET6，使用String作为替代
    INET6 = String(45)  # IPv6地址最大长度

from ..core.database import Base


class NetworkInterface(Base):
    """网络接口模型"""
    __tablename__ = "network_interfaces"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(50), nullable=False, index=True)
    type = Column(String(20), nullable=False)  # 'physical', 'virtual', 'tunnel'
    ipv4_address = Column(INET, nullable=True)
    ipv6_address = Column(INET6, nullable=True)
    mac_address = Column(MACADDR, nullable=True)
    mtu = Column(Integer, nullable=True)
    is_up = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    def __repr__(self):
        return f"<NetworkInterface(id={self.id}, name={self.name}, type={self.type})>"


class FirewallRule(Base):
    """防火墙规则模型"""
    __tablename__ = "firewall_rules"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False, index=True)
    table_name = Column(String(20), nullable=False)  # 'filter', 'nat', 'mangle'
    chain_name = Column(String(50), nullable=False)
    rule_spec = Column(Text, nullable=False)
    action = Column(String(20), nullable=False)
    priority = Column(Integer, default=0, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    def __repr__(self):
        return f"<FirewallRule(id={self.id}, name={self.name}, table={self.table_name})>"
