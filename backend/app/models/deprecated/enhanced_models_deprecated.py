"""
增强功能数据库模型
"""
from sqlalchemy import (
    Column, String, Boolean, DateTime, Text, ForeignKey,
    Integer, BigInteger, Float, Enum, Index, UniqueConstraint, CheckConstraint
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from sqlalchemy.dialects.mysql import JSON as MySQLJSON
import uuid
from datetime import datetime
from enum import Enum as PyEnum

from ..core.database import Base


# 枚举定义
class MFAMethod(PyEnum):
    TOTP = "totp"
    SMS = "sms"
    EMAIL = "email"
    BACKUP_CODE = "backup_code"
    HARDWARE_key="${API_KEY}"


class AlertSeverity(PyEnum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class AlertStatus(PyEnum):
    ACTIVE = "active"
    ACKNOWLEDGED = "acknowledged"
    RESOLVED = "resolved"
    SUPPRESSED = "suppressed"


class NotificationChannel(PyEnum):
    EMAIL = "email"
    SLACK = "slack"
    WEBHOOK = "webhook"
    SMS = "sms"
    DINGTALK = "dingtalk"
    TELEGRAM = "telegram"


class CacheType(PyEnum):
    MEMORY = "memory"
    REDIS = "redis"
    FILE = "file"


class CompressionType(PyEnum):
    GZIP = "gzip"
    DEFLATE = "deflate"
    BROTLI = "br"
    NONE = "identity"


# 密码历史表
class PasswordHistory(Base):
    """密码历史记录"""
    __tablename__ = "password_history"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    password_hash = Column(String(255), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # 关系
    user = relationship("User")

    # 索引
    __table_args__ = (
        Index('idx_password_history_user_id', 'user_id'),
        Index('idx_password_history_created_at', 'created_at'),
    )


# MFA设置表
class MFASettings(Base):
    """多因素认证设置"""
    __tablename__ = "mfa_settings"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'), nullable=False, unique=True)
    totp_secret = Column(String(32), nullable=True)
    totp_enabled = Column(Boolean, default=False, nullable=False)
    backup_codes = Column(MySQLJSON, nullable=True)
    sms_enabled = Column(Boolean, default=False, nullable=False)
    sms_phone = Column(String(20), nullable=True)
    email_enabled = Column(Boolean, default=True, nullable=False)
    hardware_key_enabled = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # 关系
    user = relationship("User")

    def __repr__(self):
        return f"<MFASettings(user_id={self.user_id}, totp_enabled={self.totp_enabled})>"


# MFA会话表
class MFASession(Base):
    """MFA会话"""
    __tablename__ = "mfa_sessions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(String(64), unique=True, nullable=False)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    session_data = Column(MySQLJSON, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # 关系
    user = relationship("User")

    # 索引
    __table_args__ = (
        Index('idx_mfa_sessions_session_id', 'session_id'),
        Index('idx_mfa_sessions_user_id', 'user_id'),
        Index('idx_mfa_sessions_expires_at', 'expires_at'),
    )


# 用户会话表
class UserSession(Base):
    """用户会话"""
    __tablename__ = "user_sessions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    session_token = Column(String(255), unique=True, nullable=False)
    device_name = Column(String(100), nullable=True)
    device_type = Column(String(20), nullable=True)  # mobile, desktop, tablet
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(Text, nullable=True)
    location = Column(String(100), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    last_activity = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # 关系
    user = relationship("User")

    # 索引
    __table_args__ = (
        Index('idx_user_sessions_user_id', 'user_id'),
        Index('idx_user_sessions_session_token', 'session_token'),
        Index('idx_user_sessions_last_activity', 'last_activity'),
    )


# 告警规则表
class AlertRule(Base):
    """告警规则"""
    __tablename__ = "alert_rules"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    condition = Column(MySQLJSON, nullable=False)
    severity = Column(Enum(AlertSeverity), nullable=False)
    enabled = Column(Boolean, default=True, nullable=False)
    cooldown = Column(Integer, default=300, nullable=False)  # 冷却时间（秒）
    notification_channels = Column(MySQLJSON, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # 关系
    alerts = relationship("Alert", back_populates="rule")

    # 索引
    __table_args__ = (
        Index('idx_alert_rules_name', 'name'),
        Index('idx_alert_rules_enabled', 'enabled'),
    )


# 告警表
class Alert(Base):
    """告警"""
    __tablename__ = "alerts"

    id = Column(Integer, primary_key=True, autoincrement=True)
    alert_id = Column(String(64), unique=True, nullable=False)
    rule_id = Column(Integer, ForeignKey('alert_rules.id', ondelete='SET NULL'), nullable=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    severity = Column(Enum(AlertSeverity), nullable=False)
    status = Column(Enum(AlertStatus), default=AlertStatus.ACTIVE, nullable=False)
    source = Column(String(100), nullable=False)
    metadata = Column(MySQLJSON, nullable=True)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    acknowledged_by = Column(Integer, ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    acknowledged_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # 关系
    rule = relationship("AlertRule", back_populates="alerts")
    acknowledged_user = relationship("User", foreign_keys=[acknowledged_by])

    # 索引
    __table_args__ = (
        Index('idx_alerts_alert_id', 'alert_id'),
        Index('idx_alerts_status', 'status'),
        Index('idx_alerts_severity', 'severity'),
        Index('idx_alerts_created_at', 'created_at'),
    )


# 通知配置表
class NotificationConfig(Base):
    """通知配置"""
    __tablename__ = "notification_configs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    channel = Column(Enum(NotificationChannel), nullable=False)
    enabled = Column(Boolean, default=True, nullable=False)
    config = Column(MySQLJSON, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # 索引
    __table_args__ = (
        Index('idx_notification_configs_channel', 'channel'),
        Index('idx_notification_configs_enabled', 'enabled'),
    )


# 缓存统计表
class CacheStats(Base):
    """缓存统计"""
    __tablename__ = "cache_stats"

    id = Column(Integer, primary_key=True, autoincrement=True)
    cache_type = Column(Enum(CacheType), nullable=False)
    cache_key = Column(String(255), nullable=False)
    hit_count = Column(BigInteger, default=0, nullable=False)
    miss_count = Column(BigInteger, default=0, nullable=False)
    total_size = Column(BigInteger, default=0, nullable=False)
    last_accessed = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # 索引
    __table_args__ = (
        Index('idx_cache_stats_cache_type', 'cache_type'),
        Index('idx_cache_stats_cache_key', 'cache_key'),
        Index('idx_cache_stats_last_accessed', 'last_accessed'),
    )


# 性能指标表
class PerformanceMetrics(Base):
    """性能指标"""
    __tablename__ = "performance_metrics"

    id = Column(Integer, primary_key=True, autoincrement=True)
    metric_name = Column(String(100), nullable=False)
    metric_value = Column(Float, nullable=False)
    metric_labels = Column(MySQLJSON, nullable=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # 索引
    __table_args__ = (
        Index('idx_performance_metrics_name', 'metric_name'),
        Index('idx_performance_metrics_timestamp', 'timestamp'),
    )


# 系统监控表
class SystemMetrics(Base):
    """系统监控指标"""
    __tablename__ = "system_metrics"

    id = Column(Integer, primary_key=True, autoincrement=True)
    cpu_usage = Column(Float, nullable=False)
    memory_usage = Column(Float, nullable=False)
    disk_usage = Column(Float, nullable=False)
    network_in = Column(BigInteger, nullable=False)
    network_out = Column(BigInteger, nullable=False)
    active_connections = Column(Integer, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # 索引
    __table_args__ = (
        Index('idx_system_metrics_timestamp', 'timestamp'),
    )


# 安全日志表
class SecurityLog(Base):
    """安全日志"""
    __tablename__ = "security_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    log_type = Column(String(50), nullable=False)  # login, logout, password_change, mfa, etc.
    log_level = Column(String(20), nullable=False)  # info, warning, error
    message = Column(Text, nullable=False)
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(Text, nullable=True)
    metadata = Column(MySQLJSON, nullable=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # 关系
    user = relationship("User")

    # 索引
    __table_args__ = (
        Index('idx_security_logs_user_id', 'user_id'),
        Index('idx_security_logs_log_type', 'log_type'),
        Index('idx_security_logs_log_level', 'log_level'),
        Index('idx_security_logs_timestamp', 'timestamp'),
    )


# API访问日志表
class APIAccessLog(Base):
    """API访问日志"""
    __tablename__ = "api_access_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    method = Column(String(10), nullable=False)
    endpoint = Column(String(255), nullable=False)
    status_code = Column(Integer, nullable=False)
    response_time = Column(Float, nullable=False)
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(Text, nullable=True)
    request_size = Column(Integer, nullable=False)
    response_size = Column(Integer, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # 关系
    user = relationship("User")

    # 索引
    __table_args__ = (
        Index('idx_api_access_logs_user_id', 'user_id'),
        Index('idx_api_access_logs_endpoint', 'endpoint'),
        Index('idx_api_access_logs_status_code', 'status_code'),
        Index('idx_api_access_logs_timestamp', 'timestamp'),
    )


# 配置表
class SystemConfig(Base):
    """系统配置"""
    __tablename__ = "system_configs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    config_key = Column(String(100), unique=True, nullable=False)
    config_value = Column(Text, nullable=False)
    config_type = Column(String(20), nullable=False)  # string, int, float, bool, json
    description = Column(Text, nullable=True)
    is_encrypted = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # 索引
    __table_args__ = (
        Index('idx_system_configs_key', 'config_key'),
    )


# 健康检查表
class HealthCheck(Base):
    """健康检查记录"""
    __tablename__ = "health_checks"

    id = Column(Integer, primary_key=True, autoincrement=True)
    service_name = Column(String(100), nullable=False)
    check_name = Column(String(100), nullable=False)
    status = Column(String(20), nullable=False)  # healthy, unhealthy, timeout, error
    response_time = Column(Float, nullable=True)
    error_message = Column(Text, nullable=True)
    metadata = Column(MySQLJSON, nullable=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # 索引
    __table_args__ = (
        Index('idx_health_checks_service', 'service_name'),
        Index('idx_health_checks_status', 'status'),
        Index('idx_health_checks_timestamp', 'timestamp'),
    )
