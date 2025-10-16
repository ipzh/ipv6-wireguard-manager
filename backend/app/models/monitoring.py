"""
监控和日志相关模型
"""
from sqlalchemy import Column, String, Integer, DateTime, Text, ForeignKey, BigInteger, Numeric
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from ..core.database import Base


class SystemMetric(Base):
    """系统指标模型"""
    __tablename__ = "system_metrics"

    id = Column(Integer, primary_key=True, autoincrement=True)
    metric_name = Column(String(100), nullable=False, index=True)
    metric_value = Column(Numeric(15, 4), nullable=False)
    metric_unit = Column(String(20), nullable=True)
    tags = Column(Text, nullable=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    def __repr__(self):
        return f"<SystemMetric(id={self.id}, name={self.metric_name}, value={self.metric_value})>"


class AuditLog(Base):
    """审计日志模型"""
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=True)
    action = Column(String(100), nullable=False, index=True)
    resource_type = Column(String(50), nullable=True)
    resource_id = Column(Integer, nullable=True)
    details = Column(Text, nullable=True)
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(Text, nullable=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # 关系
    user = relationship("User", back_populates="audit_logs")

    def __repr__(self):
        return f"<AuditLog(id={self.id}, action={self.action}, user_id={self.user_id})>"


class OperationLog(Base):
    """操作日志模型"""
    __tablename__ = "operation_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    operation_type = Column(String(50), nullable=False, index=True)
    operation_data = Column(Text, nullable=False)
    status = Column(String(20), nullable=False)  # 'success', 'failed', 'pending'
    error_message = Column(Text, nullable=True)
    execution_time = Column(Integer, nullable=True)  # 毫秒
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    def __repr__(self):
        return f"<OperationLog(id={self.id}, type={self.operation_type}, status={self.status})>"
