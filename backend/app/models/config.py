"""
配置和备份相关模型
"""
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text, ForeignKey, BigInteger
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from ..core.database import Base


class ConfigVersion(Base):
    """配置版本模型"""
    __tablename__ = "config_versions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    config_type = Column(String(50), nullable=False, index=True)
    config_name = Column(String(100), nullable=False, index=True)
    version = Column(Integer, nullable=False)
    content = Column(Text, nullable=False)
    checksum = Column(String(64), nullable=False)
    is_active = Column(Boolean, default=False, nullable=False)
    created_by = Column(Integer, ForeignKey('users.id'), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    def __repr__(self):
        return f"<ConfigVersion(id={self.id}, type={self.config_type}, name={self.config_name}, version={self.version})>"


class BackupRecord(Base):
    """备份记录模型"""
    __tablename__ = "backup_records"

    id = Column(Integer, primary_key=True, autoincrement=True)
    backup_name = Column(String(100), nullable=False, index=True)
    backup_type = Column(String(50), nullable=False)  # 'full', 'incremental', 'config'
    file_path = Column(Text, nullable=False)
    file_size = Column(BigInteger, nullable=True)
    checksum = Column(String(64), nullable=True)
    status = Column(String(20), nullable=False)  # 'completed', 'failed', 'in_progress'
    created_by = Column(Integer, ForeignKey('users.id'), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    def __repr__(self):
        return f"<BackupRecord(id={self.id}, name={self.backup_name}, type={self.backup_type}, status={self.status})>"
