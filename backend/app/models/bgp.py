"""
BGP相关模型：会话与宣告
"""
from sqlalchemy import Column, String, Boolean, Integer, DateTime, ForeignKey, Text, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum

from ..core.database import Base


class SessionStatus(str, enum.Enum):
    """BGP会话状态"""
    ESTABLISHED = "established"
    IDLE = "idle"
    CONNECT = "connect"
    ACTIVE = "active"
    OPENSENT = "opensent"
    OPENCONFIRM = "openconfirm"
    UNKNOWN = "unknown"


class OperationType(str, enum.Enum):
    """操作类型"""
    RELOAD = "reload"
    RESTART = "restart"
    START = "start"
    STOP = "stop"
    ANNOUNCE = "announce"
    WITHDRAW = "withdraw"


class BGPSession(Base):
    __tablename__ = "bgp_sessions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    neighbor = Column(String(128), nullable=False)  # 对等体地址（IPv4/IPv6）
    remote_as = Column(Integer, nullable=False)
    hold_time = Column(Integer, nullable=True)
    password = Column(String(128), nullable=True)
    description = Column(Text, nullable=True)
    enabled = Column(Boolean, default=True)
    status = Column(Enum(SessionStatus), default=SessionStatus.UNKNOWN)
    last_status_change = Column(DateTime(timezone=True), nullable=True)
    uptime = Column(Integer, default=0)  # 运行时间（秒）
    prefixes_received = Column(Integer, default=0)  # 接收的前缀数
    prefixes_sent = Column(Integer, default=0)  # 发送的前缀数

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    announcements = relationship("BGPAnnouncement", back_populates="session", cascade="all, delete-orphan")
    operations = relationship("BGPOperation", back_populates="session", cascade="all, delete-orphan")


class BGPAnnouncement(Base):
    __tablename__ = "bgp_announcements"

    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(Integer, ForeignKey("bgp_sessions.id"), nullable=True)

    prefix = Column(String(128), nullable=False)  # 形如 192.0.2.0/24 或 2001:db8::/32
    asn = Column(Integer, nullable=True)  # 可选，通常由会话remote_as决定
    next_hop = Column(String(128), nullable=True)
    description = Column(Text, nullable=True)
    enabled = Column(Boolean, default=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    session = relationship("BGPSession", back_populates="announcements")


class BGPOperation(Base):
    __tablename__ = "bgp_operations"

    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(Integer, ForeignKey("bgp_sessions.id"), nullable=True)
    operation_type = Column(Enum(OperationType), nullable=False)
    status = Column(String(20), nullable=False)  # SUCCESS, FAILED, PENDING
    message = Column(Text, nullable=True)
    error_details = Column(Text, nullable=True)
    rollback_data = Column(Text, nullable=True)  # 回滚数据（JSON格式）
    
    started_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True), nullable=True)
    
    # 关联关系
    session = relationship("BGPSession", back_populates="operations")