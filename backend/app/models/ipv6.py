"""
IPv6前缀池与分配模型
"""
from sqlalchemy import Column, String, Boolean, Integer, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from ..core.database import Base


class PrefixPool(Base):
    __tablename__ = "prefix_pools"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    base_prefix = Column(String(128), nullable=False)  # 形如 2001:db8::/32 或 1${SERVER_HOST}/16
    prefix_len = Column(Integer, nullable=False)  # 要分配的子网前缀长度
    description = Column(Text, nullable=True)
    enabled = Column(Boolean, default=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    prefixes = relationship("PoolPrefix", back_populates="pool", cascade="all, delete-orphan")


class PoolPrefix(Base):
    __tablename__ = "pool_prefixes"

    id = Column(Integer, primary_key=True, autoincrement=True)
    pool_id = Column(Integer, ForeignKey("prefix_pools.id"), nullable=False)
    prefix = Column(String(128), nullable=False)
    status = Column(String(32), nullable=False, default="free")  # free | allocated | reserved
    assigned_to_type = Column(String(64), nullable=True)  # server | client | site
    assigned_to_id = Column(String(64), nullable=True)
    note = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    pool = relationship("PrefixPool", back_populates="prefixes")