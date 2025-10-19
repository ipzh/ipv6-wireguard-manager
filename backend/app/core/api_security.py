# API安全防护模块

import time
import hashlib
import hmac
import secrets
from typing import Optional, Dict, Any, List, Tuple
from datetime import datetime, timedelta
from collections import defaultdict, deque
from pydantic import BaseModel
import ipaddress
import re

class RateLimitConfig(BaseModel):
    """速率限制配置"""
    requests_per_minute: int = 60
    requests_per_hour: int = 1000
    requests_per_day: int = 10000
    burst_limit: int = 10
    window_size: int = 60  # 秒

class SecurityConfig(BaseModel):
    """安全配置"""
    max_request_size: int = 10 * 1024 * 1024  # 10MB
    max_header_size: int = 8192  # 8KB
    max_headers: int = 100
    allowed_methods: List[str] = ["GET", "POST", "PUT", "DELETE", "PATCH"]
    blocked_user_agents: List[str] = []
    blocked_ips: List[str] = []
    allowed_origins: List[str] = []
    require_https: bool = True
    hsts_max_age: int = 31536000  # 1年
    content_security_policy: str = "default-src 'self'"

class APISecurityManager:
    """API安全管理器"""
    
    def __init__(self, rate_limit_config: RateLimitConfig, security_config: SecurityConfig):
        self.rate_limit_config = rate_limit_config
        self.security_config = security_config
        
        # 速率限制存储
        self.rate_limit_store = defaultdict(lambda: defaultdict(deque))
        
        # 黑名单存储
        self.blacklist = set()
        
        # 白名单存储
        self.whitelist = set()
        
        # 异常检测
        self.suspicious_ips = defaultdict(int)
        self.suspicious_patterns = [
            r"\.\./",  # 路径遍历
            r"<script",  # XSS
            r"union\s+select",  # SQL注入
            r"exec\s*\(",  # 命令注入
            r"eval\s*\(",  # 代码注入
        ]
    
    def check_rate_limit(self, client_ip: str, user_id: Optional[int] = None) -> Tuple[bool, Dict[str, Any]]:
        """检查速率限制"""
        identifier = f"{client_ip}:{user_id}" if user_id else client_ip
        current_time = time.time()
        
        # 清理过期记录
        self._cleanup_rate_limit_records(identifier, current_time)
        
        # 检查各种限制
        minute_limit = self._check_limit(identifier, "minute", current_time, self.rate_limit_config.requests_per_minute, 60)
        hour_limit = self._check_limit(identifier, "hour", current_time, self.rate_limit_config.requests_per_hour, 3600)
        day_limit = self._check_limit(identifier, "day", current_time, self.rate_limit_config.requests_per_day, 86400)
        
        # 检查突发限制
        burst_limit = self._check_burst_limit(identifier, current_time)
        
        is_allowed = minute_limit and hour_limit and day_limit and burst_limit
        
        return is_allowed, {
            "minute_remaining": max(0, self.rate_limit_config.requests_per_minute - len(self.rate_limit_store[identifier]["minute"])),
            "hour_remaining": max(0, self.rate_limit_config.requests_per_hour - len(self.rate_limit_store[identifier]["hour"])),
            "day_remaining": max(0, self.rate_limit_config.requests_per_day - len(self.rate_limit_store[identifier]["day"])),
            "burst_allowed": burst_limit
        }
    
    def _check_limit(self, identifier: str, period: str, current_time: float, limit: int, window: int) -> bool:
        """检查特定时间窗口的限制"""
        records = self.rate_limit_store[identifier][period]
        
        # 移除过期记录
        while records and records[0] < current_time - window:
            records.popleft()
        
        if len(records) >= limit:
            return False
        
        # 添加当前请求
        records.append(current_time)
        return True
    
    def _check_burst_limit(self, identifier: str, current_time: float) -> bool:
        """检查突发限制"""
        records = self.rate_limit_store[identifier]["burst"]
        
        # 移除过期记录（最近10秒）
        while records and records[0] < current_time - 10:
            records.popleft()
        
        if len(records) >= self.rate_limit_config.burst_limit:
            return False
        
        records.append(current_time)
        return True
    
    def _cleanup_rate_limit_records(self, identifier: str, current_time: float):
        """清理过期的速率限制记录"""
        for period in ["minute", "hour", "day", "burst"]:
            records = self.rate_limit_store[identifier][period]
            window = {"minute": 60, "hour": 3600, "day": 86400, "burst": 10}[period]
            
            while records and records[0] < current_time - window:
                records.popleft()
    
    def check_ip_security(self, client_ip: str) -> Tuple[bool, str]:
        """检查IP安全性"""
        # 检查黑名单
        if client_ip in self.blacklist:
            return False, "IP地址在黑名单中"
        
        # 检查白名单（如果设置了）
        if self.whitelist and client_ip not in self.whitelist:
            return False, "IP地址不在白名单中"
        
        # 检查IP地址格式
        try:
            ipaddress.ip_address(client_ip)
        except ValueError:
            return False, "无效的IP地址格式"
        
        # 检查私有IP（如果配置不允许）
        if not self._is_private_ip_allowed(client_ip):
            return False, "不允许私有IP访问"
        
        return True, "IP安全检查通过"
    
    def _is_private_ip_allowed(self, ip: str) -> bool:
        """检查是否允许私有IP"""
        try:
            ip_obj = ipaddress.ip_address(ip)
            # 这里可以根据配置决定是否允许私有IP
            return True
        except ValueError:
            return False
    
    def detect_malicious_patterns(self, request_data: Dict[str, Any]) -> Tuple[bool, List[str]]:
        """检测恶意模式"""
        threats = []
        
        # 检查URL路径
        if "path" in request_data:
            for pattern in self.suspicious_patterns:
                if re.search(pattern, request_data["path"], re.IGNORECASE):
                    threats.append(f"检测到恶意模式: {pattern}")
        
        # 检查请求头
        if "headers" in request_data:
            for header_name, header_value in request_data["headers"].items():
                if isinstance(header_value, str):
                    for pattern in self.suspicious_patterns:
                        if re.search(pattern, header_value, re.IGNORECASE):
                            threats.append(f"请求头 {header_name} 包含恶意模式: {pattern}")
        
        # 检查请求体
        if "body" in request_data and isinstance(request_data["body"], str):
            for pattern in self.suspicious_patterns:
                if re.search(pattern, request_data["body"], re.IGNORECASE):
                    threats.append(f"请求体包含恶意模式: {pattern}")
        
        return len(threats) == 0, threats
    
    def validate_request_size(self, request_data: Dict[str, Any]) -> Tuple[bool, str]:
        """验证请求大小"""
        total_size = 0
        
        # 计算请求体大小
        if "body" in request_data:
            if isinstance(request_data["body"], str):
                total_size += len(request_data["body"].encode('utf-8'))
            elif isinstance(request_data["body"], bytes):
                total_size += len(request_data["body"])
        
        # 计算请求头大小
        if "headers" in request_data:
            for name, value in request_data["headers"].items():
                total_size += len(name.encode('utf-8'))
                if isinstance(value, str):
                    total_size += len(value.encode('utf-8'))
        
        if total_size > self.security_config.max_request_size:
            return False, f"请求大小超过限制: {total_size} > {self.security_config.max_request_size}"
        
        return True, "请求大小验证通过"
    
    def validate_headers(self, headers: Dict[str, Any]) -> Tuple[bool, List[str]]:
        """验证请求头"""
        errors = []
        
        # 检查请求头数量
        if len(headers) > self.security_config.max_headers:
            errors.append(f"请求头数量超过限制: {len(headers)} > {self.security_config.max_headers}")
        
        # 检查User-Agent
        user_agent = headers.get("user-agent", "")
        if user_agent in self.security_config.blocked_user_agents:
            errors.append("User-Agent被阻止")
        
        # 检查请求头大小
        for name, value in headers.items():
            header_size = len(name.encode('utf-8'))
            if isinstance(value, str):
                header_size += len(value.encode('utf-8'))
            
            if header_size > self.security_config.max_header_size:
                errors.append(f"请求头 {name} 大小超过限制")
        
        return len(errors) == 0, errors
    
    def generate_csrf_token(self, user_id: int) -> str:
        """生成CSRF令牌"""
        timestamp = str(int(time.time()))
        data = f"{user_id}:{timestamp}"
        token = hmac.new(
            secrets.token_bytes(32),
            data.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()
        return f"{timestamp}:{token}"
    
    def validate_csrf_token(self, token: str, user_id: int, max_age: int = 3600) -> bool:
        """验证CSRF令牌"""
        try:
            timestamp_str, token_hash = token.split(":", 1)
            timestamp = int(timestamp_str)
            
            # 检查令牌是否过期
            if time.time() - timestamp > max_age:
                return False
            
            # 重新生成令牌进行验证
            data = f"{user_id}:{timestamp_str}"
            expected_token = hmac.new(
                secrets.token_bytes(32),  # 这里应该使用存储的密钥
                data.encode('utf-8'),
                hashlib.sha256
            ).hexdigest()
            
            return hmac.compare_digest(token_hash, expected_token)
        except (ValueError, IndexError):
            return False
    
    def add_to_blacklist(self, ip: str, reason: str = ""):
        """添加到黑名单"""
        self.blacklist.add(ip)
        # 这里应该记录到数据库
    
    def remove_from_blacklist(self, ip: str):
        """从黑名单移除"""
        self.blacklist.discard(ip)
        # 这里应该从数据库删除
    
    def add_to_whitelist(self, ip: str):
        """添加到白名单"""
        self.whitelist.add(ip)
        # 这里应该记录到数据库
    
    def remove_from_whitelist(self, ip: str):
        """从白名单移除"""
        self.whitelist.discard(ip)
        # 这里应该从数据库删除
    
    def record_suspicious_activity(self, ip: str, activity_type: str, details: str):
        """记录可疑活动"""
        self.suspicious_ips[ip] += 1
        
        # 如果可疑活动过多，自动加入黑名单
        if self.suspicious_ips[ip] > 10:
            self.add_to_blacklist(ip, f"可疑活动过多: {activity_type}")
        
        # 这里应该记录到数据库
    
    def get_security_headers(self) -> Dict[str, str]:
        """获取安全响应头"""
        headers = {
            "X-Content-Type-Options": "nosniff",
            "X-Frame-Options": "DENY",
            "X-XSS-Protection": "1; mode=block",
            "Referrer-Policy": "strict-origin-when-cross-origin",
            "Permissions-Policy": "geolocation=(), microphone=(), camera=()"
        }
        
        if self.security_config.require_https:
            headers["Strict-Transport-Security"] = f"max-age={self.security_config.hsts_max_age}; includeSubDomains"
        
        if self.security_config.content_security_policy:
            headers["Content-Security-Policy"] = self.security_config.content_security_policy
        
        return headers

class APISecurityMiddleware:
    """API安全中间件"""
    
    def __init__(self, security_manager: APISecurityManager):
        self.security_manager = security_manager
    
    async def process_request(self, request, user_id: Optional[int] = None) -> Tuple[bool, Dict[str, Any]]:
        """处理请求安全检查"""
        client_ip = request.client.host if hasattr(request, 'client') else "unknown"
        
        # IP安全检查
        ip_allowed, ip_message = self.security_manager.check_ip_security(client_ip)
        if not ip_allowed:
            return False, {"error": "IP安全检查失败", "message": ip_message}
        
        # 速率限制检查
        rate_allowed, rate_info = self.security_manager.check_rate_limit(client_ip, user_id)
        if not rate_allowed:
            return False, {"error": "速率限制", "message": "请求过于频繁", "rate_info": rate_info}
        
        # 请求大小验证
        request_data = {
            "path": getattr(request, 'url', {}).get('path', ''),
            "headers": dict(request.headers) if hasattr(request, 'headers') else {},
            "body": await self._get_request_body(request) if hasattr(request, 'body') else ""
        }
        
        size_valid, size_message = self.security_manager.validate_request_size(request_data)
        if not size_valid:
            return False, {"error": "请求大小验证失败", "message": size_message}
        
        # 请求头验证
        headers_valid, header_errors = self.security_manager.validate_headers(request_data["headers"])
        if not headers_valid:
            return False, {"error": "请求头验证失败", "message": header_errors}
        
        # 恶意模式检测
        pattern_safe, threats = self.security_manager.detect_malicious_patterns(request_data)
        if not pattern_safe:
            self.security_manager.record_suspicious_activity(client_ip, "恶意模式", str(threats))
            return False, {"error": "检测到恶意模式", "message": threats}
        
        return True, {"message": "安全检查通过"}
    
    async def _get_request_body(self, request) -> str:
        """获取请求体"""
        try:
            if hasattr(request, 'body'):
                body = await request.body()
                return body.decode('utf-8') if isinstance(body, bytes) else str(body)
        except Exception:
            pass
        return ""
    
    def get_security_headers(self) -> Dict[str, str]:
        """获取安全响应头"""
        return self.security_manager.get_security_headers()
