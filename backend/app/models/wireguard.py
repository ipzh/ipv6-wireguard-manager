"""
WireGuard相关模型
"""
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text, ForeignKey, BigInteger
from sqlalchemy.dialects.postgresql import UUID, INET, ARRAY
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


class WireGuardServer(Base):
    """WireGuard服务器模型"""
    __tablename__ = "wireguard_servers"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False, index=True)
    interface = Column(String(20), default='wg0', nullable=False)
    listen_port = Column(Integer, nullable=False)
    private_key = Column(Text, nullable=False)
    public_key = Column(Text, nullable=False)
    ipv4_address = Column(INET, nullable=True)
    ipv6_address = Column(INET6, nullable=True)
    dns_servers = Column(ARRAY(INET), nullable=True)
    mtu = Column(Integer, default=1420, nullable=False)
    config_file_path = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # 关系
    clients = relationship("WireGuardClient", secondary="client_server_relations", back_populates="servers")

    def __repr__(self):
        return f"<WireGuardServer(id={self.id}, name={self.name}, interface={self.interface})>"


class WireGuardClient(Base):
    """WireGuard客户端模型"""
    __tablename__ = "wireguard_clients"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False, index=True)
    description = Column(Text, nullable=True)
    private_key = Column(Text, nullable=False)
    public_key = Column(Text, nullable=False)
    ipv4_address = Column(INET, nullable=True)
    ipv6_address = Column(INET6, nullable=True)
    allowed_ips = Column(ARRAY(INET), nullable=True)
    persistent_keepalive = Column(Integer, default=25, nullable=False)
    qr_code = Column(Text, nullable=True)
    config_file_path = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    last_seen = Column(DateTime(timezone=True), nullable=True)
    bytes_received = Column(BigInteger, default=0, nullable=False)
    bytes_sent = Column(BigInteger, default=0, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # 关系
    servers = relationship("WireGuardServer", secondary="client_server_relations", back_populates="clients")

    def __repr__(self):
        return f"<WireGuardClient(id={self.id}, name={self.name})>"


class ClientServerRelation(Base):
    """客户端服务器关联模型"""
    __tablename__ = "client_server_relations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    client_id = Column(UUID(as_uuid=True), ForeignKey('wireguard_clients.id', ondelete='CASCADE'), nullable=False)
    server_id = Column(UUID(as_uuid=True), ForeignKey('wireguard_servers.id', ondelete='CASCADE'), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    def __repr__(self):
        return f"<ClientServerRelation(client_id={self.client_id}, server_id={self.server_id})>"
