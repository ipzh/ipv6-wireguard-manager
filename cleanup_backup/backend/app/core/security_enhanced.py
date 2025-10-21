"""
安全增强模块
实现安全配置、漏洞扫描、审计日志
"""

import time
import logging
import hashlib
import secrets
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime, timedelta
from fastapi import Request, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
import jwt
from passlib.context import CryptContext
import re

logger = logging.getLogger(__name__)

# 密码加密上下文
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT配置
JWT_SECRET_KEY = "your-secret-key-here"
JWT_ALGORITHM = "HS256"
JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 30
JWT_REFRESH_TOKEN_EXPIRE_DAYS = 7

# 安全配置
SECURITY_CONFIG = {
    "password_min_length": 8,
    "password_require_uppercase": True,
    "password_require_lowercase": True,
    "password_require_numbers": True,
    "password_require_special": True,
    "max_login_attempts": 5,
    "lockout_duration_minutes": 15,
    "session_timeout_minutes": 30,
    "rate_limit_requests_per_minute": 100,
    "rate_limit_burst": 200
}

class SecurityManager:
    """安全管理器"""
    
    def __init__(self):
        self.failed_attempts = {}
        self.locked_accounts = {}
        self.audit_logs = []
    
    def hash_password(self, password: str) -> str:
        """哈希密码"""
        return pwd_context.hash(password)
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """验证密码"""
        return pwd_context.verify(plain_password, hashed_password)
    
    def validate_password_strength(self, password: str) -> Tuple[bool, List[str]]:
        """验证密码强度"""
        errors = []
        
        if len(password) < SECURITY_CONFIG["password_min_length"]:
            errors.append(f"密码长度至少需要{SECURITY_CONFIG['password_min_length']}位")
        
        if SECURITY_CONFIG["password_require_uppercase"] and not re.search(r'[A-Z]', password):
            errors.append("密码必须包含大写字母")
        
        if SECURITY_CONFIG["password_require_lowercase"] and not re.search(r'[a-z]', password):
            errors.append("密码必须包含小写字母")
        
        if SECURITY_CONFIG["password_require_numbers"] and not re.search(r'\d', password):
            errors.append("密码必须包含数字")
        
        if SECURITY_CONFIG["password_require_special"] and not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
            errors.append("密码必须包含特殊字符")
        
        return len(errors) == 0, errors
    
    def generate_secure_token(self, length: int = 32) -> str:
        """生成安全令牌"""
        return secrets.token_urlsafe(length)
    
    def create_access_token(self, data: Dict[str, Any]) -> str:
        """创建访问令牌"""
        to_encode = data.copy()
        expire = datetime.utcnow() + timedelta(minutes=JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
        return encoded_jwt
    
    def create_refresh_token(self, data: Dict[str, Any]) -> str:
        """创建刷新令牌"""
        to_encode = data.copy()
        expire = datetime.utcnow() + timedelta(days=JWT_REFRESH_TOKEN_EXPIRE_DAYS)
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
        return encoded_jwt
    
    def verify_token(self, token: str) -> Dict[str, Any]:
        """验证令牌"""
        try:
            payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
            return payload
        except jwt.ExpiredSignatureError:
            raise HTTPException(status_code=401, detail="令牌已过期")
        except jwt.JWTError:
            raise HTTPException(status_code=401, detail="无效令牌")
    
    def check_account_lockout(self, username: str) -> bool:
        """检查账户锁定状态"""
        if username in self.locked_accounts:
            lockout_time = self.locked_accounts[username]
            if datetime.utcnow() < lockout_time:
                return True
            else:
                # 锁定时间已过，解除锁定
                del self.locked_accounts[username]
                self.failed_attempts[username] = 0
        return False
    
    def record_failed_login(self, username: str, ip_address: str):
        """记录登录失败"""
        if username not in self.failed_attempts:
            self.failed_attempts[username] = 0
        
        self.failed_attempts[username] += 1
        
        # 记录审计日志
        self.log_security_event("LOGIN_FAILED", {
            "username": username,
            "ip_address": ip_address,
            "attempt_count": self.failed_attempts[username]
        })
        
        # 检查是否需要锁定账户
        if self.failed_attempts[username] >= SECURITY_CONFIG["max_login_attempts"]:
            lockout_time = datetime.utcnow() + timedelta(minutes=SECURITY_CONFIG["lockout_duration_minutes"])
            self.locked_accounts[username] = lockout_time
            
            self.log_security_event("ACCOUNT_LOCKED", {
                "username": username,
                "ip_address": ip_address,
                "lockout_duration": SECURITY_CONFIG["lockout_duration_minutes"]
            })
    
    def record_successful_login(self, username: str, ip_address: str):
        """记录成功登录"""
        # 清除失败记录
        if username in self.failed_attempts:
            del self.failed_attempts[username]
        
        # 记录审计日志
        self.log_security_event("LOGIN_SUCCESS", {
            "username": username,
            "ip_address": ip_address
        })
    
    def log_security_event(self, event_type: str, details: Dict[str, Any]):
        """记录安全事件"""
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "event_type": event_type,
            "details": details
        }
        
        self.audit_logs.append(log_entry)
        logger.warning(f"安全事件: {event_type} - {details}")
    
    def get_security_events(self, limit: int = 100) -> List[Dict[str, Any]]:
        """获取安全事件"""
        return self.audit_logs[-limit:]

class RateLimiter:
    """速率限制器"""
    
    def __init__(self):
        self.requests = {}
    
    def is_rate_limited(self, identifier: str, limit: int = 100, window: int = 60) -> bool:
        """检查是否超过速率限制"""
        now = time.time()
        window_start = now - window
        
        # 清理过期的请求记录
        if identifier in self.requests:
            self.requests[identifier] = [
                req_time for req_time in self.requests[identifier]
                if req_time > window_start
            ]
        else:
            self.requests[identifier] = []
        
        # 检查是否超过限制
        if len(self.requests[identifier]) >= limit:
            return True
        
        # 记录当前请求
        self.requests[identifier].append(now)
        return False

class SecurityHeaders:
    """安全头管理器"""
    
    @staticmethod
    def get_security_headers() -> Dict[str, str]:
        """获取安全头"""
        return {
            "X-Content-Type-Options": "nosniff",
            "X-Frame-Options": "DENY",
            "X-XSS-Protection": "1; mode=block",
            "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
            "Content-Security-Policy": "default-src 'self'",
            "Referrer-Policy": "strict-origin-when-cross-origin",
            "Permissions-Policy": "geolocation=(), microphone=(), camera=()"
        }

class VulnerabilityScanner:
    """漏洞扫描器"""
    
    def __init__(self):
        self.scan_results = []
    
    def scan_sql_injection(self, query: str) -> bool:
        """扫描SQL注入漏洞"""
        sql_patterns = [
            r"('|(\\')|(;)|(--)|(\\|)|(\\*)|(\\+)|(\\-)|(\\/)|(\\%)|(\\^)|(\\&)|(\\|)|(\\~)|(\\!)|(\\@)|(\\#)|(\\$)|(\\%)|(\\^)|(\\&)|(\\*)|(\\()|(\\))|(\\-)|(\\+)|(\\=)|(\\[)|(\\])|(\\{)|(\\})|(\\;)|(\\:)|(\\')|(\\\")|(\\,)|(\\.)|(\\<)|(\\>)|(\\/)|(\\?)|(\\`)|(\\~))",
            r"(union|select|insert|update|delete|drop|create|alter|exec|execute)",
            r"(script|javascript|vbscript|onload|onerror|onclick)"
        ]
        
        for pattern in sql_patterns:
            if re.search(pattern, query, re.IGNORECASE):
                return True
        return False
    
    def scan_xss(self, content: str) -> bool:
        """扫描XSS漏洞"""
        xss_patterns = [
            r"<script[^>]*>.*?</script>",
            r"javascript:",
            r"on\w+\s*=",
            r"<iframe[^>]*>",
            r"<object[^>]*>",
            r"<embed[^>]*>"
        ]
        
        for pattern in xss_patterns:
            if re.search(pattern, content, re.IGNORECASE):
                return True
        return False
    
    def scan_path_traversal(self, path: str) -> bool:
        """扫描路径遍历漏洞"""
        traversal_patterns = [
            r"\.\./",
            r"\.\.\\",
            r"\.\.%2f",
            r"\.\.%5c",
            r"\.\.%252f",
            r"\.\.%255c"
        ]
        
        for pattern in traversal_patterns:
            if re.search(pattern, path, re.IGNORECASE):
                return True
        return False
    
    def scan_command_injection(self, command: str) -> bool:
        """扫描命令注入漏洞"""
        injection_patterns = [
            r"[;&|]",
            r"`.*`",
            r"\$\(.*\)",
            r"<.*>",
            r"\|\|",
            r"&&"
        ]
        
        for pattern in injection_patterns:
            if re.search(pattern, command):
                return True
        return False
    
    def scan_input(self, input_data: str, input_type: str = "general") -> Dict[str, Any]:
        """扫描输入数据"""
        vulnerabilities = []
        
        if self.scan_sql_injection(input_data):
            vulnerabilities.append("SQL_INJECTION")
        
        if self.scan_xss(input_data):
            vulnerabilities.append("XSS")
        
        if self.scan_path_traversal(input_data):
            vulnerabilities.append("PATH_TRAVERSAL")
        
        if self.scan_command_injection(input_data):
            vulnerabilities.append("COMMAND_INJECTION")
        
        return {
            "input": input_data,
            "type": input_type,
            "vulnerabilities": vulnerabilities,
            "is_safe": len(vulnerabilities) == 0
        }

class AuditLogger:
    """审计日志记录器"""
    
    def __init__(self, db_session: Session):
        self.db_session = db_session
    
    def log_user_action(self, user_id: int, action: str, details: Dict[str, Any], ip_address: str = None):
        """记录用户操作"""
        audit_entry = {
            "user_id": user_id,
            "action": action,
            "details": details,
            "ip_address": ip_address,
            "timestamp": datetime.utcnow(),
            "session_id": self._get_session_id()
        }
        
        # 这里应该将审计日志存储到数据库
        logger.info(f"审计日志: {audit_entry}")
    
    def log_system_event(self, event_type: str, details: Dict[str, Any]):
        """记录系统事件"""
        system_entry = {
            "event_type": event_type,
            "details": details,
            "timestamp": datetime.utcnow(),
            "severity": self._get_severity(event_type)
        }
        
        logger.warning(f"系统事件: {system_entry}")
    
    def log_security_event(self, event_type: str, details: Dict[str, Any]):
        """记录安全事件"""
        security_entry = {
            "event_type": event_type,
            "details": details,
            "timestamp": datetime.utcnow(),
            "severity": "HIGH"
        }
        
        logger.error(f"安全事件: {security_entry}")
    
    def _get_session_id(self) -> str:
        """获取会话ID"""
        return secrets.token_urlsafe(16)
    
    def _get_severity(self, event_type: str) -> str:
        """获取事件严重性"""
        high_severity_events = [
            "LOGIN_FAILED", "ACCOUNT_LOCKED", "UNAUTHORIZED_ACCESS",
            "PRIVILEGE_ESCALATION", "DATA_BREACH", "MALICIOUS_ACTIVITY"
        ]
        
        if event_type in high_severity_events:
            return "HIGH"
        elif "ERROR" in event_type:
            return "MEDIUM"
        else:
            return "LOW"

# 创建全局实例
security_manager = SecurityManager()
rate_limiter = RateLimiter()
vulnerability_scanner = VulnerabilityScanner()

# JWT认证依赖
security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """获取当前用户"""
    token = credentials.credentials
    payload = security_manager.verify_token(token)
    return payload

def check_rate_limit(request: Request):
    """检查速率限制"""
    client_ip = request.client.host
    if rate_limiter.is_rate_limited(client_ip):
        raise HTTPException(status_code=429, detail="请求过于频繁")