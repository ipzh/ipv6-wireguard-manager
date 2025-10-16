"""
安全增强模块
提供高级安全功能，包括威胁检测、安全审计、访问控制等
"""
import asyncio
import hashlib
import hmac
import secrets
import time
import logging
from typing import Dict, Any, List, Optional, Tuple, Set
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from enum import Enum
import ipaddress
import re
import json

from fastapi import Request, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import redis.asyncio as redis

logger = logging.getLogger(__name__)

class ThreatLevel(Enum):
    """威胁级别"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class SecurityEvent(Enum):
    """安全事件类型"""
    LOGIN_SUCCESS = "login_success"
    LOGIN_FAILED = "login_failed"
    LOGIN_BLOCKED = "login_blocked"
    PASSWORD_CHANGED = "password_changed"
    PERMISSION_DENIED = "permission_denied"
    SUSPICIOUS_ACTIVITY = "suspicious_activity"
    RATE_LIMIT_EXCEEDED = "rate_limit_exceeded"
    INVALID_TOKEN = "invalid_token"
    TOKEN_EXPIRED = "token_expired"
    ADMIN_ACTION = "admin_action"
    DATA_ACCESS = "data_access"
    CONFIG_CHANGE = "config_change"

@dataclass
class SecurityAlert:
    """安全告警"""
    id: str
    event_type: SecurityEvent
    threat_level: ThreatLevel
    source_ip: str
    user_id: Optional[str]
    description: str
    details: Dict[str, Any]
    timestamp: datetime
    resolved: bool = False
    resolved_at: Optional[datetime] = None
    resolved_by: Optional[str] = None

@dataclass
class AccessPattern:
    """访问模式"""
    ip_address: str
    user_agent: str
    endpoint: str
    method: str
    timestamp: datetime
    response_code: int
    response_time: float

@dataclass
class SecurityPolicy:
    """安全策略"""
    name: str
    enabled: bool
    rules: List[Dict[str, Any]]
    actions: List[str]
    created_at: datetime
    updated_at: datetime

class ThreatDetector:
    """威胁检测器"""
    
    def __init__(self):
        self.suspicious_patterns = {
            'sql_injection': [
                r"union\s+select",
                r"drop\s+table",
                r"delete\s+from",
                r"insert\s+into",
                r"update\s+set",
                r"exec\s*\(",
                r"script\s*>",
                r"<script",
                r"javascript:",
                r"onload\s*=",
                r"onerror\s*="
            ],
            'xss_attack': [
                r"<script[^>]*>.*?</script>",
                r"javascript:",
                r"on\w+\s*=",
                r"<iframe[^>]*>",
                r"<object[^>]*>",
                r"<embed[^>]*>",
                r"<link[^>]*>",
                r"<meta[^>]*>"
            ],
            'path_traversal': [
                r"\.\./",
                r"\.\.\\",
                r"%2e%2e%2f",
                r"%2e%2e%5c",
                r"\.\.%2f",
                r"\.\.%5c"
            ],
            'command_injection': [
                r";\s*rm\s+",
                r";\s*cat\s+",
                r";\s*ls\s+",
                r";\s*ps\s+",
                r";\s*kill\s+",
                r"|\s*rm\s+",
                r"|\s*cat\s+",
                r"|\s*ls\s+",
                r"|\s*ps\s+",
                r"|\s*kill\s+"
            ]
        }
        
        self.rate_limit_patterns = {}
        self.blocked_ips = set()
        self.suspicious_ips = set()
    
    def detect_threats(self, request: Request, user_id: Optional[str] = None) -> List[SecurityAlert]:
        """检测威胁"""
        alerts = []
        
        # 获取请求信息
        client_ip = self._get_client_ip(request)
        user_agent = request.headers.get("user-agent", "")
        url = str(request.url)
        method = request.method
        
        # 检测SQL注入
        sql_alerts = self._detect_sql_injection(url, client_ip, user_id)
        alerts.extend(sql_alerts)
        
        # 检测XSS攻击
        xss_alerts = self._detect_xss_attack(url, client_ip, user_id)
        alerts.extend(xss_alerts)
        
        # 检测路径遍历
        path_alerts = self._detect_path_traversal(url, client_ip, user_id)
        alerts.extend(path_alerts)
        
        # 检测命令注入
        cmd_alerts = self._detect_command_injection(url, client_ip, user_id)
        alerts.extend(cmd_alerts)
        
        # 检测异常访问模式
        pattern_alerts = self._detect_anomalous_patterns(request, user_id)
        alerts.extend(pattern_alerts)
        
        return alerts
    
    def _detect_sql_injection(self, url: str, client_ip: str, user_id: Optional[str]) -> List[SecurityAlert]:
        """检测SQL注入"""
        alerts = []
        patterns = self.suspicious_patterns['sql_injection']
        
        for pattern in patterns:
            if re.search(pattern, url, re.IGNORECASE):
                alert = SecurityAlert(
                    id=secrets.token_hex(8),
                    event_type=SecurityEvent.SUSPICIOUS_ACTIVITY,
                    threat_level=ThreatLevel.HIGH,
                    source_ip=client_ip,
                    user_id=user_id,
                    description="检测到SQL注入攻击尝试",
                    details={
                        'pattern': pattern,
                        'url': url,
                        'attack_type': 'sql_injection'
                    },
                    timestamp=datetime.now()
                )
                alerts.append(alert)
                self.suspicious_ips.add(client_ip)
        
        return alerts
    
    def _detect_xss_attack(self, url: str, client_ip: str, user_id: Optional[str]) -> List[SecurityAlert]:
        """检测XSS攻击"""
        alerts = []
        patterns = self.suspicious_patterns['xss_attack']
        
        for pattern in patterns:
            if re.search(pattern, url, re.IGNORECASE):
                alert = SecurityAlert(
                    id=secrets.token_hex(8),
                    event_type=SecurityEvent.SUSPICIOUS_ACTIVITY,
                    threat_level=ThreatLevel.MEDIUM,
                    source_ip=client_ip,
                    user_id=user_id,
                    description="检测到XSS攻击尝试",
                    details={
                        'pattern': pattern,
                        'url': url,
                        'attack_type': 'xss_attack'
                    },
                    timestamp=datetime.now()
                )
                alerts.append(alert)
                self.suspicious_ips.add(client_ip)
        
        return alerts
    
    def _detect_path_traversal(self, url: str, client_ip: str, user_id: Optional[str]) -> List[SecurityAlert]:
        """检测路径遍历"""
        alerts = []
        patterns = self.suspicious_patterns['path_traversal']
        
        for pattern in patterns:
            if re.search(pattern, url, re.IGNORECASE):
                alert = SecurityAlert(
                    id=secrets.token_hex(8),
                    event_type=SecurityEvent.SUSPICIOUS_ACTIVITY,
                    threat_level=ThreatLevel.HIGH,
                    source_ip=client_ip,
                    user_id=user_id,
                    description="检测到路径遍历攻击尝试",
                    details={
                        'pattern': pattern,
                        'url': url,
                        'attack_type': 'path_traversal'
                    },
                    timestamp=datetime.now()
                )
                alerts.append(alert)
                self.suspicious_ips.add(client_ip)
        
        return alerts
    
    def _detect_command_injection(self, url: str, client_ip: str, user_id: Optional[str]) -> List[SecurityAlert]:
        """检测命令注入"""
        alerts = []
        patterns = self.suspicious_patterns['command_injection']
        
        for pattern in patterns:
            if re.search(pattern, url, re.IGNORECASE):
                alert = SecurityAlert(
                    id=secrets.token_hex(8),
                    event_type=SecurityEvent.SUSPICIOUS_ACTIVITY,
                    threat_level=ThreatLevel.CRITICAL,
                    source_ip=client_ip,
                    user_id=user_id,
                    description="检测到命令注入攻击尝试",
                    details={
                        'pattern': pattern,
                        'url': url,
                        'attack_type': 'command_injection'
                    },
                    timestamp=datetime.now()
                )
                alerts.append(alert)
                self.blocked_ips.add(client_ip)
        
        return alerts
    
    def _detect_anomalous_patterns(self, request: Request, user_id: Optional[str]) -> List[SecurityAlert]:
        """检测异常访问模式"""
        alerts = []
        client_ip = self._get_client_ip(request)
        
        # 检测异常请求频率
        if self._is_high_frequency_request(client_ip):
            alert = SecurityAlert(
                id=secrets.token_hex(8),
                event_type=SecurityEvent.RATE_LIMIT_EXCEEDED,
                threat_level=ThreatLevel.MEDIUM,
                source_ip=client_ip,
                user_id=user_id,
                description="检测到异常高频请求",
                details={
                    'request_count': self._get_request_count(client_ip),
                    'time_window': '1分钟'
                },
                timestamp=datetime.now()
            )
            alerts.append(alert)
        
        # 检测异常User-Agent
        user_agent = request.headers.get("user-agent", "")
        if self._is_suspicious_user_agent(user_agent):
            alert = SecurityAlert(
                id=secrets.token_hex(8),
                event_type=SecurityEvent.SUSPICIOUS_ACTIVITY,
                threat_level=ThreatLevel.LOW,
                source_ip=client_ip,
                user_id=user_id,
                description="检测到可疑User-Agent",
                details={
                    'user_agent': user_agent,
                    'reason': 'suspicious_pattern'
                },
                timestamp=datetime.now()
            )
            alerts.append(alert)
        
        return alerts
    
    def _get_client_ip(self, request: Request) -> str:
        """获取客户端IP"""
        # 检查代理头
        forwarded_for = request.headers.get("x-forwarded-for")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        
        real_ip = request.headers.get("x-real-ip")
        if real_ip:
            return real_ip
        
        return request.client.host if request.client else "unknown"
    
    def _is_high_frequency_request(self, client_ip: str) -> bool:
        """检测高频请求"""
        current_time = time.time()
        window_start = current_time - 60  # 1分钟窗口
        
        # 这里应该从缓存或数据库获取请求计数
        # 简化实现，实际应该使用Redis或数据库
        request_count = self.rate_limit_patterns.get(client_ip, 0)
        return request_count > 100  # 1分钟内超过100次请求
    
    def _get_request_count(self, client_ip: str) -> int:
        """获取请求计数"""
        return self.rate_limit_patterns.get(client_ip, 0)
    
    def _is_suspicious_user_agent(self, user_agent: str) -> bool:
        """检测可疑User-Agent"""
        suspicious_patterns = [
            r"bot",
            r"crawler",
            r"spider",
            r"scraper",
            r"curl",
            r"wget",
            r"python",
            r"java",
            r"php"
        ]
        
        for pattern in suspicious_patterns:
            if re.search(pattern, user_agent, re.IGNORECASE):
                return True
        
        return False

class SecurityAuditor:
    """安全审计器"""
    
    def __init__(self, db_session: AsyncSession):
        self.db_session = db_session
        self.audit_logs = []
    
    async def log_security_event(self, event: SecurityEvent, user_id: Optional[str], 
                                client_ip: str, details: Dict[str, Any]):
        """记录安全事件"""
        audit_log = {
            'id': secrets.token_hex(8),
            'event_type': event.value,
            'user_id': user_id,
            'client_ip': client_ip,
            'details': details,
            'timestamp': datetime.now(),
            'severity': self._get_event_severity(event)
        }
        
        self.audit_logs.append(audit_log)
        
        # 保存到数据库
        await self._save_audit_log(audit_log)
        
        logger.info(f"安全事件记录: {event.value} - {user_id} - {client_ip}")
    
    async def _save_audit_log(self, audit_log: Dict[str, Any]):
        """保存审计日志到数据库"""
        try:
            query = """
            INSERT INTO security_audit_logs 
            (id, event_type, user_id, client_ip, details, timestamp, severity)
            VALUES (:id, :event_type, :user_id, :client_ip, :details, :timestamp, :severity)
            """
            await self.db_session.execute(text(query), audit_log)
            await self.db_session.commit()
        except Exception as e:
            logger.error(f"保存审计日志失败: {e}")
    
    def _get_event_severity(self, event: SecurityEvent) -> str:
        """获取事件严重级别"""
        severity_map = {
            SecurityEvent.LOGIN_SUCCESS: "info",
            SecurityEvent.LOGIN_FAILED: "warning",
            SecurityEvent.LOGIN_BLOCKED: "error",
            SecurityEvent.PASSWORD_CHANGED: "info",
            SecurityEvent.PERMISSION_DENIED: "warning",
            SecurityEvent.SUSPICIOUS_ACTIVITY: "error",
            SecurityEvent.RATE_LIMIT_EXCEEDED: "warning",
            SecurityEvent.INVALID_TOKEN: "warning",
            SecurityEvent.TOKEN_EXPIRED: "info",
            SecurityEvent.ADMIN_ACTION: "info",
            SecurityEvent.DATA_ACCESS: "info",
            SecurityEvent.CONFIG_CHANGE: "warning"
        }
        return severity_map.get(event, "info")
    
    async def get_audit_logs(self, start_time: datetime = None, end_time: datetime = None,
                           event_type: SecurityEvent = None, user_id: str = None) -> List[Dict[str, Any]]:
        """获取审计日志"""
        try:
            query = "SELECT * FROM security_audit_logs WHERE 1=1"
            params = {}
            
            if start_time:
                query += " AND timestamp >= :start_time"
                params['start_time'] = start_time
            
            if end_time:
                query += " AND timestamp <= :end_time"
                params['end_time'] = end_time
            
            if event_type:
                query += " AND event_type = :event_type"
                params['event_type'] = event_type.value
            
            if user_id:
                query += " AND user_id = :user_id"
                params['user_id'] = user_id
            
            query += " ORDER BY timestamp DESC LIMIT 1000"
            
            result = await self.db_session.execute(text(query), params)
            logs = result.fetchall()
            
            return [dict(log._mapping) for log in logs]
            
        except Exception as e:
            logger.error(f"获取审计日志失败: {e}")
            return []

class AccessController:
    """访问控制器"""
    
    def __init__(self):
        self.ip_whitelist = set()
        self.ip_blacklist = set()
        self.user_restrictions = {}
        self.time_restrictions = {}
    
    def add_ip_to_whitelist(self, ip: str):
        """添加IP到白名单"""
        self.ip_whitelist.add(ip)
        logger.info(f"IP {ip} 已添加到白名单")
    
    def add_ip_to_blacklist(self, ip: str):
        """添加IP到黑名单"""
        self.ip_blacklist.add(ip)
        logger.info(f"IP {ip} 已添加到黑名单")
    
    def remove_ip_from_whitelist(self, ip: str):
        """从白名单移除IP"""
        self.ip_whitelist.discard(ip)
        logger.info(f"IP {ip} 已从白名单移除")
    
    def remove_ip_from_blacklist(self, ip: str):
        """从黑名单移除IP"""
        self.ip_blacklist.discard(ip)
        logger.info(f"IP {ip} 已从黑名单移除")
    
    def is_ip_allowed(self, ip: str) -> bool:
        """检查IP是否允许访问"""
        # 检查黑名单
        if ip in self.ip_blacklist:
            return False
        
        # 检查白名单（如果设置了白名单）
        if self.ip_whitelist and ip not in self.ip_whitelist:
            return False
        
        return True
    
    def set_user_restriction(self, user_id: str, restrictions: Dict[str, Any]):
        """设置用户访问限制"""
        self.user_restrictions[user_id] = restrictions
        logger.info(f"用户 {user_id} 访问限制已设置")
    
    def remove_user_restriction(self, user_id: str):
        """移除用户访问限制"""
        self.user_restrictions.pop(user_id, None)
        logger.info(f"用户 {user_id} 访问限制已移除")
    
    def is_user_access_allowed(self, user_id: str, resource: str, action: str) -> bool:
        """检查用户是否允许访问资源"""
        restrictions = self.user_restrictions.get(user_id, {})
        
        # 检查时间限制
        if 'time_restrictions' in restrictions:
            if not self._check_time_restrictions(restrictions['time_restrictions']):
                return False
        
        # 检查资源限制
        if 'resource_restrictions' in restrictions:
            resource_restrictions = restrictions['resource_restrictions']
            if resource in resource_restrictions:
                allowed_actions = resource_restrictions[resource]
                if action not in allowed_actions:
                    return False
        
        return True
    
    def _check_time_restrictions(self, time_restrictions: Dict[str, Any]) -> bool:
        """检查时间限制"""
        current_time = datetime.now()
        current_hour = current_time.hour
        current_weekday = current_time.weekday()
        
        # 检查小时限制
        if 'allowed_hours' in time_restrictions:
            allowed_hours = time_restrictions['allowed_hours']
            if current_hour not in allowed_hours:
                return False
        
        # 检查星期限制
        if 'allowed_weekdays' in time_restrictions:
            allowed_weekdays = time_restrictions['allowed_weekdays']
            if current_weekday not in allowed_weekdays:
                return False
        
        return True

class SecurityManager:
    """安全管理器"""
    
    def __init__(self, db_session: AsyncSession, redis_client: redis.Redis = None):
        self.db_session = db_session
        self.redis_client = redis_client
        
        # 初始化组件
        self.threat_detector = ThreatDetector()
        self.security_auditor = SecurityAuditor(db_session)
        self.access_controller = AccessController()
        
        # 安全配置
        self.config = {
            'enable_threat_detection': True,
            'enable_security_audit': True,
            'enable_access_control': True,
            'enable_rate_limiting': True,
            'max_login_attempts': 5,
            'lockout_duration': 900,  # 15分钟
            'session_timeout': 1800,  # 30分钟
            'password_policy': {
                'min_length': 12,
                'require_uppercase': True,
                'require_lowercase': True,
                'require_digits': True,
                'require_special': True,
                'max_age_days': 90
            }
        }
        
        # 安全状态
        self.failed_login_attempts = {}
        self.locked_accounts = set()
        self.active_sessions = {}
    
    async def check_request_security(self, request: Request, user_id: Optional[str] = None) -> Tuple[bool, List[SecurityAlert]]:
        """检查请求安全性"""
        alerts = []
        
        # 获取客户端IP
        client_ip = self._get_client_ip(request)
        
        # 检查IP访问控制
        if not self.access_controller.is_ip_allowed(client_ip):
            alert = SecurityAlert(
                id=secrets.token_hex(8),
                event_type=SecurityEvent.PERMISSION_DENIED,
                threat_level=ThreatLevel.HIGH,
                source_ip=client_ip,
                user_id=user_id,
                description="IP地址被拒绝访问",
                details={'reason': 'ip_blocked'},
                timestamp=datetime.now()
            )
            alerts.append(alert)
            return False, alerts
        
        # 威胁检测
        if self.config['enable_threat_detection']:
            threat_alerts = self.threat_detector.detect_threats(request, user_id)
            alerts.extend(threat_alerts)
            
            # 如果有高威胁级别的告警，拒绝请求
            for alert in threat_alerts:
                if alert.threat_level in [ThreatLevel.HIGH, ThreatLevel.CRITICAL]:
                    return False, alerts
        
        # 记录安全事件
        if self.config['enable_security_audit']:
            await self.security_auditor.log_security_event(
                SecurityEvent.DATA_ACCESS,
                user_id,
                client_ip,
                {
                    'url': str(request.url),
                    'method': request.method,
                    'user_agent': request.headers.get("user-agent", "")
                }
            )
        
        return True, alerts
    
    async def check_login_security(self, username: str, client_ip: str) -> Tuple[bool, str]:
        """检查登录安全性"""
        # 检查账户是否被锁定
        if username in self.locked_accounts:
            await self.security_auditor.log_security_event(
                SecurityEvent.LOGIN_BLOCKED,
                username,
                client_ip,
                {'reason': 'account_locked'}
            )
            return False, "账户已被锁定，请稍后再试"
        
        # 检查失败登录次数
        failed_attempts = self.failed_login_attempts.get(username, 0)
        if failed_attempts >= self.config['max_login_attempts']:
            # 锁定账户
            self.locked_accounts.add(username)
            await self.security_auditor.log_security_event(
                SecurityEvent.LOGIN_BLOCKED,
                username,
                client_ip,
                {'reason': 'max_attempts_exceeded', 'attempts': failed_attempts}
            )
            return False, "登录失败次数过多，账户已被锁定"
        
        return True, ""
    
    async def record_login_attempt(self, username: str, client_ip: str, success: bool):
        """记录登录尝试"""
        if success:
            # 登录成功，清除失败计数
            self.failed_login_attempts.pop(username, None)
            self.locked_accounts.discard(username)
            
            await self.security_auditor.log_security_event(
                SecurityEvent.LOGIN_SUCCESS,
                username,
                client_ip,
                {'timestamp': datetime.now()}
            )
        else:
            # 登录失败，增加失败计数
            self.failed_login_attempts[username] = self.failed_login_attempts.get(username, 0) + 1
            
            await self.security_auditor.log_security_event(
                SecurityEvent.LOGIN_FAILED,
                username,
                client_ip,
                {'attempts': self.failed_login_attempts[username]}
            )
    
    async def validate_password(self, password: str) -> Tuple[bool, List[str]]:
        """验证密码强度"""
        errors = []
        policy = self.config['password_policy']
        
        # 检查长度
        if len(password) < policy['min_length']:
            errors.append(f"密码长度至少需要{policy['min_length']}个字符")
        
        # 检查复杂度
        if policy['require_uppercase'] and not re.search(r'[A-Z]', password):
            errors.append("密码必须包含大写字母")
        
        if policy['require_lowercase'] and not re.search(r'[a-z]', password):
            errors.append("密码必须包含小写字母")
        
        if policy['require_digits'] and not re.search(r'\d', password):
            errors.append("密码必须包含数字")
        
        if policy['require_special'] and not re.search(r'[@$!%*?&]', password):
            errors.append("密码必须包含特殊字符(@$!%*?&)")
        
        return len(errors) == 0, errors
    
    async def generate_secure_token(self, user_id: str, purpose: str = "auth") -> str:
        """生成安全令牌"""
        timestamp = str(int(time.time()))
        random_data = secrets.token_hex(16)
        data = f"{user_id}:{purpose}:{timestamp}:{random_data}"
        
        # 使用HMAC签名
        secret_key = "your_secret_key_here"  # 应该从配置获取
        signature = hmac.new(
            secret_key.encode(),
            data.encode(),
            hashlib.sha256
        ).hexdigest()
        
        token = f"{data}:{signature}"
        return token
    
    async def verify_secure_token(self, token: str, user_id: str, purpose: str = "auth") -> bool:
        """验证安全令牌"""
        try:
            parts = token.split(':')
            if len(parts) != 5:
                return False
            
            token_user_id, token_purpose, timestamp, random_data, signature = parts
            
            # 验证用户ID和用途
            if token_user_id != user_id or token_purpose != purpose:
                return False
            
            # 验证时间戳（令牌有效期1小时）
            token_time = int(timestamp)
            current_time = int(time.time())
            if current_time - token_time > 3600:
                return False
            
            # 验证签名
            data = f"{token_user_id}:{token_purpose}:{timestamp}:{random_data}"
            secret_key = "your_secret_key_here"  # 应该从配置获取
            expected_signature = hmac.new(
                secret_key.encode(),
                data.encode(),
                hashlib.sha256
            ).hexdigest()
            
            return hmac.compare_digest(signature, expected_signature)
            
        except Exception as e:
            logger.error(f"令牌验证失败: {e}")
            return False
    
    def _get_client_ip(self, request: Request) -> str:
        """获取客户端IP"""
        forwarded_for = request.headers.get("x-forwarded-for")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        
        real_ip = request.headers.get("x-real-ip")
        if real_ip:
            return real_ip
        
        return request.client.host if request.client else "unknown"
    
    async def get_security_summary(self) -> Dict[str, Any]:
        """获取安全摘要"""
        return {
            'threat_detection': {
                'enabled': self.config['enable_threat_detection'],
                'blocked_ips': len(self.threat_detector.blocked_ips),
                'suspicious_ips': len(self.threat_detector.suspicious_ips)
            },
            'access_control': {
                'enabled': self.config['enable_access_control'],
                'whitelist_size': len(self.access_controller.ip_whitelist),
                'blacklist_size': len(self.access_controller.ip_blacklist)
            },
            'account_security': {
                'locked_accounts': len(self.locked_accounts),
                'failed_attempts': len(self.failed_login_attempts),
                'active_sessions': len(self.active_sessions)
            },
            'password_policy': self.config['password_policy']
        }

# 全局安全管理器实例
security_manager: Optional[SecurityManager] = None

async def get_security_manager() -> SecurityManager:
    """获取安全管理器实例"""
    global security_manager
    if security_manager is None:
        raise ValueError("安全管理器未初始化")
    return security_manager

async def init_security_manager(db_session: AsyncSession, redis_client: redis.Redis = None):
    """初始化安全管理器"""
    global security_manager
    security_manager = SecurityManager(db_session, redis_client)
    logger.info("安全管理器初始化完成")

# 安全装饰器
def require_security_check(func):
    """安全检查装饰器"""
    async def wrapper(*args, **kwargs):
        # 这里应该从请求中获取信息进行安全检查
        # 简化实现
        return await func(*args, **kwargs)
    return wrapper

def rate_limit(requests_per_minute: int = 60):
    """速率限制装饰器"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            # 这里应该实现速率限制逻辑
            # 简化实现
            return await func(*args, **kwargs)
        return wrapper
    return decorator