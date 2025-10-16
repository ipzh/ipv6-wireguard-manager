"""
详细的审计日志系统
提供完整的用户行为审计、系统事件记录、安全事件跟踪等功能
"""
import asyncio
import json
import logging
import uuid
from typing import Dict, Any, List, Optional, Union
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict
from enum import Enum
import hashlib
import ipaddress

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import redis.asyncio as redis

logger = logging.getLogger(__name__)

class AuditEventType(Enum):
    """审计事件类型"""
    # 认证相关
    LOGIN_SUCCESS = "login_success"
    LOGIN_FAILED = "login_failed"
    LOGOUT = "logout"
    PASSWORD_CHANGED = "password_changed"
    PASSWORD_RESET = "password_reset"
    TWO_FACTOR_ENABLED = "two_factor_enabled"
    TWO_FACTOR_DISABLED = "two_factor_disabled"
    
    # 用户管理
    USER_CREATED = "user_created"
    USER_UPDATED = "user_updated"
    USER_DELETED = "user_deleted"
    USER_ACTIVATED = "user_activated"
    USER_DEACTIVATED = "user_deactivated"
    USER_ROLE_CHANGED = "user_role_changed"
    
    # 权限相关
    PERMISSION_GRANTED = "permission_granted"
    PERMISSION_REVOKED = "permission_revoked"
    ACCESS_DENIED = "access_denied"
    PRIVILEGE_ESCALATION = "privilege_escalation"
    
    # 系统配置
    CONFIG_CHANGED = "config_changed"
    SYSTEM_BACKUP = "system_backup"
    SYSTEM_RESTORE = "system_restore"
    SYSTEM_UPDATE = "system_update"
    
    # 网络管理
    WIREGUARD_SERVER_CREATED = "wireguard_server_created"
    WIREGUARD_SERVER_UPDATED = "wireguard_server_updated"
    WIREGUARD_SERVER_DELETED = "wireguard_server_deleted"
    WIREGUARD_CLIENT_CREATED = "wireguard_client_created"
    WIREGUARD_CLIENT_UPDATED = "wireguard_client_updated"
    WIREGUARD_CLIENT_DELETED = "wireguard_client_deleted"
    
    # BGP管理
    BGP_SESSION_CREATED = "bgp_session_created"
    BGP_SESSION_UPDATED = "bgp_session_updated"
    BGP_SESSION_DELETED = "bgp_session_deleted"
    BGP_ANNOUNCEMENT_CREATED = "bgp_announcement_created"
    BGP_ANNOUNCEMENT_UPDATED = "bgp_announcement_updated"
    BGP_ANNOUNCEMENT_DELETED = "bgp_announcement_deleted"
    
    # IPv6管理
    IPV6_POOL_CREATED = "ipv6_pool_created"
    IPV6_POOL_UPDATED = "ipv6_pool_updated"
    IPV6_POOL_DELETED = "ipv6_pool_deleted"
    IPV6_ALLOCATION_CREATED = "ipv6_allocation_created"
    IPV6_ALLOCATION_UPDATED = "ipv6_allocation_updated"
    IPV6_ALLOCATION_DELETED = "ipv6_allocation_deleted"
    
    # 安全事件
    SECURITY_THREAT_DETECTED = "security_threat_detected"
    SUSPICIOUS_ACTIVITY = "suspicious_activity"
    RATE_LIMIT_EXCEEDED = "rate_limit_exceeded"
    IP_BLOCKED = "ip_blocked"
    IP_UNBLOCKED = "ip_unblocked"
    
    # 数据访问
    DATA_VIEWED = "data_viewed"
    DATA_EXPORTED = "data_exported"
    DATA_IMPORTED = "data_imported"
    DATA_MODIFIED = "data_modified"
    
    # API访问
    API_ACCESS = "api_access"
    API_ERROR = "api_error"
    API_RATE_LIMIT = "api_rate_limit"

class AuditSeverity(Enum):
    """审计严重级别"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

@dataclass
class AuditLogEntry:
    """审计日志条目"""
    id: str
    event_type: AuditEventType
    severity: AuditSeverity
    user_id: Optional[str]
    username: Optional[str]
    session_id: Optional[str]
    ip_address: str
    user_agent: Optional[str]
    resource_type: Optional[str]
    resource_id: Optional[str]
    action: str
    description: str
    details: Dict[str, Any]
    result: str  # success, failure, error
    error_message: Optional[str]
    timestamp: datetime
    duration_ms: Optional[int] = None
    tags: List[str] = None
    
    def __post_init__(self):
        if self.tags is None:
            self.tags = []

@dataclass
class AuditQuery:
    """审计查询条件"""
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    user_id: Optional[str] = None
    username: Optional[str] = None
    event_type: Optional[AuditEventType] = None
    severity: Optional[AuditSeverity] = None
    ip_address: Optional[str] = None
    resource_type: Optional[str] = None
    resource_id: Optional[str] = None
    result: Optional[str] = None
    tags: Optional[List[str]] = None
    limit: int = 1000
    offset: int = 0

class AuditLogger:
    """审计日志记录器"""
    
    def __init__(self, db_session: AsyncSession, redis_client: redis.Redis = None):
        self.db_session = db_session
        self.redis_client = redis_client
        
        # 配置
        self.config = {
            'enable_audit_logging': True,
            'enable_real_time_alerts': True,
            'retention_days': 365,
            'batch_size': 100,
            'flush_interval': 30,  # 秒
            'enable_compression': True,
            'enable_encryption': False
        }
        
        # 日志缓冲区
        self.log_buffer = []
        self.buffer_lock = asyncio.Lock()
        
        # 敏感数据字段
        self.sensitive_fields = {
            'password', 'secret', 'token', 'key', 'credential',
            'private_key', 'api_key', 'access_token', 'refresh_token'
        }
        
        # 启动后台任务
        self._start_background_tasks()
    
    def _start_background_tasks(self):
        """启动后台任务"""
        if self.config['enable_audit_logging']:
            asyncio.create_task(self._flush_logs_periodically())
            asyncio.create_task(self._cleanup_old_logs())
    
    async def log_event(self, 
                       event_type: AuditEventType,
                       user_id: Optional[str] = None,
                       username: Optional[str] = None,
                       session_id: Optional[str] = None,
                       ip_address: str = "unknown",
                       user_agent: Optional[str] = None,
                       resource_type: Optional[str] = None,
                       resource_id: Optional[str] = None,
                       action: str = "",
                       description: str = "",
                       details: Dict[str, Any] = None,
                       result: str = "success",
                       error_message: Optional[str] = None,
                       severity: AuditSeverity = AuditSeverity.MEDIUM,
                       duration_ms: Optional[int] = None,
                       tags: List[str] = None):
        """记录审计事件"""
        if not self.config['enable_audit_logging']:
            return
        
        try:
            # 清理敏感数据
            if details:
                details = self._sanitize_sensitive_data(details)
            
            # 创建审计日志条目
            log_entry = AuditLogEntry(
                id=str(uuid.uuid4()),
                event_type=event_type,
                severity=severity,
                user_id=user_id,
                username=username,
                session_id=session_id,
                ip_address=ip_address,
                user_agent=user_agent,
                resource_type=resource_type,
                resource_id=resource_id,
                action=action,
                description=description,
                details=details or {},
                result=result,
                error_message=error_message,
                timestamp=datetime.now(),
                duration_ms=duration_ms,
                tags=tags or []
            )
            
            # 添加到缓冲区
            async with self.buffer_lock:
                self.log_buffer.append(log_entry)
                
                # 如果缓冲区满了，立即刷新
                if len(self.log_buffer) >= self.config['batch_size']:
                    await self._flush_logs()
            
            # 实时告警
            if self.config['enable_real_time_alerts']:
                await self._check_real_time_alerts(log_entry)
            
            logger.debug(f"审计事件已记录: {event_type.value} - {user_id} - {action}")
            
        except Exception as e:
            logger.error(f"记录审计事件失败: {e}")
    
    async def _flush_logs(self):
        """刷新日志缓冲区"""
        if not self.log_buffer:
            return
        
        try:
            # 批量插入数据库
            await self._batch_insert_logs(self.log_buffer.copy())
            
            # 清空缓冲区
            self.log_buffer.clear()
            
            logger.debug(f"已刷新 {len(self.log_buffer)} 条审计日志")
            
        except Exception as e:
            logger.error(f"刷新审计日志失败: {e}")
    
    async def _batch_insert_logs(self, logs: List[AuditLogEntry]):
        """批量插入日志"""
        try:
            query = """
            INSERT INTO audit_logs 
            (id, event_type, severity, user_id, username, session_id, ip_address, 
             user_agent, resource_type, resource_id, action, description, details, 
             result, error_message, timestamp, duration_ms, tags)
            VALUES 
            (:id, :event_type, :severity, :user_id, :username, :session_id, :ip_address,
             :user_agent, :resource_type, :resource_id, :action, :description, :details,
             :result, :error_message, :timestamp, :duration_ms, :tags)
            """
            
            # 准备批量数据
            batch_data = []
            for log in logs:
                batch_data.append({
                    'id': log.id,
                    'event_type': log.event_type.value,
                    'severity': log.severity.value,
                    'user_id': log.user_id,
                    'username': log.username,
                    'session_id': log.session_id,
                    'ip_address': log.ip_address,
                    'user_agent': log.user_agent,
                    'resource_type': log.resource_type,
                    'resource_id': log.resource_id,
                    'action': log.action,
                    'description': log.description,
                    'details': json.dumps(log.details),
                    'result': log.result,
                    'error_message': log.error_message,
                    'timestamp': log.timestamp,
                    'duration_ms': log.duration_ms,
                    'tags': json.dumps(log.tags)
                })
            
            # 执行批量插入
            await self.db_session.execute(text(query), batch_data)
            await self.db_session.commit()
            
        except Exception as e:
            logger.error(f"批量插入审计日志失败: {e}")
            raise
    
    async def _flush_logs_periodically(self):
        """定期刷新日志"""
        while True:
            try:
                await asyncio.sleep(self.config['flush_interval'])
                async with self.buffer_lock:
                    if self.log_buffer:
                        await self._flush_logs()
            except Exception as e:
                logger.error(f"定期刷新审计日志失败: {e}")
                await asyncio.sleep(60)  # 错误时等待更长时间
    
    async def _cleanup_old_logs(self):
        """清理旧日志"""
        while True:
            try:
                await asyncio.sleep(3600)  # 每小时检查一次
                
                cutoff_date = datetime.now() - timedelta(days=self.config['retention_days'])
                
                query = "DELETE FROM audit_logs WHERE timestamp < :cutoff_date"
                result = await self.db_session.execute(text(query), {'cutoff_date': cutoff_date})
                await self.db_session.commit()
                
                deleted_count = result.rowcount
                if deleted_count > 0:
                    logger.info(f"已清理 {deleted_count} 条过期审计日志")
                
            except Exception as e:
                logger.error(f"清理旧审计日志失败: {e}")
                await asyncio.sleep(3600)
    
    async def _check_real_time_alerts(self, log_entry: AuditLogEntry):
        """检查实时告警"""
        try:
            # 高严重级别事件立即告警
            if log_entry.severity in [AuditSeverity.HIGH, AuditSeverity.CRITICAL]:
                await self._send_real_time_alert(log_entry)
            
            # 安全相关事件告警
            security_events = [
                AuditEventType.SECURITY_THREAT_DETECTED,
                AuditEventType.SUSPICIOUS_ACTIVITY,
                AuditEventType.PRIVILEGE_ESCALATION,
                AuditEventType.IP_BLOCKED
            ]
            
            if log_entry.event_type in security_events:
                await self._send_real_time_alert(log_entry)
            
            # 失败的操作告警
            if log_entry.result == "failure" and log_entry.severity in [AuditSeverity.MEDIUM, AuditSeverity.HIGH]:
                await self._send_real_time_alert(log_entry)
                
        except Exception as e:
            logger.error(f"实时告警检查失败: {e}")
    
    async def _send_real_time_alert(self, log_entry: AuditLogEntry):
        """发送实时告警"""
        try:
            alert_data = {
                'type': 'audit_alert',
                'severity': log_entry.severity.value,
                'event_type': log_entry.event_type.value,
                'user_id': log_entry.user_id,
                'username': log_entry.username,
                'ip_address': log_entry.ip_address,
                'description': log_entry.description,
                'timestamp': log_entry.timestamp.isoformat(),
                'details': log_entry.details
            }
            
            # 发送到Redis频道
            if self.redis_client:
                await self.redis_client.publish('audit_alerts', json.dumps(alert_data))
            
            logger.warning(f"审计告警: {log_entry.event_type.value} - {log_entry.severity.value}")
            
        except Exception as e:
            logger.error(f"发送实时告警失败: {e}")
    
    def _sanitize_sensitive_data(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """清理敏感数据"""
        sanitized = {}
        
        for key, value in data.items():
            key_lower = key.lower()
            
            # 检查是否包含敏感字段
            if any(sensitive in key_lower for sensitive in self.sensitive_fields):
                sanitized[key] = "***REDACTED***"
            elif isinstance(value, dict):
                sanitized[key] = self._sanitize_sensitive_data(value)
            elif isinstance(value, list):
                sanitized[key] = [
                    self._sanitize_sensitive_data(item) if isinstance(item, dict) else item
                    for item in value
                ]
            else:
                sanitized[key] = value
        
        return sanitized
    
    async def query_logs(self, query: AuditQuery) -> List[AuditLogEntry]:
        """查询审计日志"""
        try:
            # 构建查询条件
            where_conditions = []
            params = {}
            
            if query.start_time:
                where_conditions.append("timestamp >= :start_time")
                params['start_time'] = query.start_time
            
            if query.end_time:
                where_conditions.append("timestamp <= :end_time")
                params['end_time'] = query.end_time
            
            if query.user_id:
                where_conditions.append("user_id = :user_id")
                params['user_id'] = query.user_id
            
            if query.username:
                where_conditions.append("username LIKE :username")
                params['username'] = f"%{query.username}%"
            
            if query.event_type:
                where_conditions.append("event_type = :event_type")
                params['event_type'] = query.event_type.value
            
            if query.severity:
                where_conditions.append("severity = :severity")
                params['severity'] = query.severity.value
            
            if query.ip_address:
                where_conditions.append("ip_address = :ip_address")
                params['ip_address'] = query.ip_address
            
            if query.resource_type:
                where_conditions.append("resource_type = :resource_type")
                params['resource_type'] = query.resource_type
            
            if query.resource_id:
                where_conditions.append("resource_id = :resource_id")
                params['resource_id'] = query.resource_id
            
            if query.result:
                where_conditions.append("result = :result")
                params['result'] = query.result
            
            if query.tags:
                for i, tag in enumerate(query.tags):
                    where_conditions.append(f"JSON_CONTAINS(tags, :tag_{i})")
                    params[f'tag_{i}'] = json.dumps(tag)
            
            # 构建完整查询
            where_clause = " AND ".join(where_conditions) if where_conditions else "1=1"
            
            sql_query = f"""
            SELECT * FROM audit_logs 
            WHERE {where_clause}
            ORDER BY timestamp DESC
            LIMIT :limit OFFSET :offset
            """
            
            params['limit'] = query.limit
            params['offset'] = query.offset
            
            result = await self.db_session.execute(text(sql_query), params)
            rows = result.fetchall()
            
            # 转换为AuditLogEntry对象
            logs = []
            for row in rows:
                log_entry = AuditLogEntry(
                    id=row.id,
                    event_type=AuditEventType(row.event_type),
                    severity=AuditSeverity(row.severity),
                    user_id=row.user_id,
                    username=row.username,
                    session_id=row.session_id,
                    ip_address=row.ip_address,
                    user_agent=row.user_agent,
                    resource_type=row.resource_type,
                    resource_id=row.resource_id,
                    action=row.action,
                    description=row.description,
                    details=json.loads(row.details) if row.details else {},
                    result=row.result,
                    error_message=row.error_message,
                    timestamp=row.timestamp,
                    duration_ms=row.duration_ms,
                    tags=json.loads(row.tags) if row.tags else []
                )
                logs.append(log_entry)
            
            return logs
            
        except Exception as e:
            logger.error(f"查询审计日志失败: {e}")
            return []
    
    async def get_audit_statistics(self, start_time: datetime = None, end_time: datetime = None) -> Dict[str, Any]:
        """获取审计统计信息"""
        try:
            if start_time is None:
                start_time = datetime.now() - timedelta(days=30)
            if end_time is None:
                end_time = datetime.now()
            
            # 基础统计
            stats_query = """
            SELECT 
                COUNT(*) as total_events,
                COUNT(DISTINCT user_id) as unique_users,
                COUNT(DISTINCT ip_address) as unique_ips,
                COUNT(CASE WHEN result = 'success' THEN 1 END) as successful_events,
                COUNT(CASE WHEN result = 'failure' THEN 1 END) as failed_events,
                COUNT(CASE WHEN severity = 'critical' THEN 1 END) as critical_events,
                COUNT(CASE WHEN severity = 'high' THEN 1 END) as high_events,
                COUNT(CASE WHEN severity = 'medium' THEN 1 END) as medium_events,
                COUNT(CASE WHEN severity = 'low' THEN 1 END) as low_events
            FROM audit_logs 
            WHERE timestamp BETWEEN :start_time AND :end_time
            """
            
            result = await self.db_session.execute(text(stats_query), {
                'start_time': start_time,
                'end_time': end_time
            })
            stats = result.fetchone()
            
            # 事件类型统计
            event_type_query = """
            SELECT event_type, COUNT(*) as count
            FROM audit_logs 
            WHERE timestamp BETWEEN :start_time AND :end_time
            GROUP BY event_type
            ORDER BY count DESC
            LIMIT 10
            """
            
            result = await self.db_session.execute(text(event_type_query), {
                'start_time': start_time,
                'end_time': end_time
            })
            event_types = result.fetchall()
            
            # 用户活动统计
            user_activity_query = """
            SELECT username, COUNT(*) as activity_count
            FROM audit_logs 
            WHERE timestamp BETWEEN :start_time AND :end_time
            AND user_id IS NOT NULL
            GROUP BY username
            ORDER BY activity_count DESC
            LIMIT 10
            """
            
            result = await self.db_session.execute(text(user_activity_query), {
                'start_time': start_time,
                'end_time': end_time
            })
            user_activities = result.fetchall()
            
            return {
                'period': {
                    'start_time': start_time.isoformat(),
                    'end_time': end_time.isoformat()
                },
                'summary': {
                    'total_events': stats.total_events,
                    'unique_users': stats.unique_users,
                    'unique_ips': stats.unique_ips,
                    'successful_events': stats.successful_events,
                    'failed_events': stats.failed_events
                },
                'severity_breakdown': {
                    'critical': stats.critical_events,
                    'high': stats.high_events,
                    'medium': stats.medium_events,
                    'low': stats.low_events
                },
                'top_event_types': [
                    {'event_type': row.event_type, 'count': row.count}
                    for row in event_types
                ],
                'top_active_users': [
                    {'username': row.username, 'activity_count': row.activity_count}
                    for row in user_activities
                ]
            }
            
        except Exception as e:
            logger.error(f"获取审计统计信息失败: {e}")
            return {}
    
    async def export_logs(self, query: AuditQuery, format: str = "json") -> str:
        """导出审计日志"""
        try:
            logs = await self.query_logs(query)
            
            if format == "json":
                return json.dumps([asdict(log) for log in logs], indent=2, default=str)
            elif format == "csv":
                import csv
                import io
                
                output = io.StringIO()
                if logs:
                    writer = csv.DictWriter(output, fieldnames=asdict(logs[0]).keys())
                    writer.writeheader()
                    for log in logs:
                        writer.writerow(asdict(log))
                return output.getvalue()
            else:
                raise ValueError(f"不支持的导出格式: {format}")
                
        except Exception as e:
            logger.error(f"导出审计日志失败: {e}")
            return ""

# 全局审计日志记录器实例
audit_logger: Optional[AuditLogger] = None

async def get_audit_logger() -> AuditLogger:
    """获取审计日志记录器实例"""
    global audit_logger
    if audit_logger is None:
        raise ValueError("审计日志记录器未初始化")
    return audit_logger

async def init_audit_logger(db_session: AsyncSession, redis_client: redis.Redis = None):
    """初始化审计日志记录器"""
    global audit_logger
    audit_logger = AuditLogger(db_session, redis_client)
    logger.info("审计日志记录器初始化完成")

# 审计装饰器
def audit_log(event_type: AuditEventType, 
              severity: AuditSeverity = AuditSeverity.MEDIUM,
              action: str = "",
              description: str = "",
              resource_type: str = None):
    """审计日志装饰器"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            start_time = datetime.now()
            result = "success"
            error_message = None
            
            try:
                # 执行函数
                return_value = await func(*args, **kwargs)
                return return_value
            except Exception as e:
                result = "error"
                error_message = str(e)
                raise
            finally:
                # 记录审计日志
                try:
                    audit_logger_instance = await get_audit_logger()
                    await audit_logger_instance.log_event(
                        event_type=event_type,
                        severity=severity,
                        action=action or func.__name__,
                        description=description or f"执行函数 {func.__name__}",
                        resource_type=resource_type,
                        result=result,
                        error_message=error_message,
                        duration_ms=int((datetime.now() - start_time).total_seconds() * 1000)
                    )
                except Exception as audit_error:
                    logger.error(f"记录审计日志失败: {audit_error}")
        
        return wrapper
    return decorator
