"""
网络相关模型
"""
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from ..core.database import Base


class NetworkInterface(Base):
    """网络接口模型"""
    __tablename__ = "network_interfaces"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(50), nullable=False, index=True)
    type = Column(String(20), nullable=False)  # 'physical', 'virtual', 'tunnel'
    ipv4_address = Column(String(45), nullable=True)
    ipv6_address = Column(String(45), nullable=True)
    mac_address = Column(String(17), nullable=True)  # MAC地址格式: XX:XX:XX:XX:XX:XX
    mtu = Column(Integer, nullable=True)
    is_up = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    def __repr__(self):
        return f"<NetworkInterface(id={self.id}, name={self.name}, type={self.type})>"


class FirewallRule(Base):
    """防火墙规则模型"""
    __tablename__ = "firewall_rules"

    id = Column(Integer, primary_key=True, autoincrement=True)
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
