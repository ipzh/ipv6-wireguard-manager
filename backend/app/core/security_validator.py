"""
安全验证和监控模块
提供全面的安全检查和监控功能
"""

import asyncio
import hashlib
import hmac
import time
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Tuple
from fastapi import Request, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import structlog

from .unified_config import settings
from .exception_handlers import SecurityError, ErrorCodes
from .logging_manager import security_logger, get_logger

logger = get_logger("security_validator")

class SecurityValidator:
    """安全验证器"""
    
    def __init__(self):
        self.logger = logger
        self.failed_attempts = {}  # 存储失败尝试
        self.blocked_ips = set()    # 被阻止的IP
        self.rate_limits = {}       # 速率限制
    
    async def validate_request(self, request: Request) -> bool:
        """验证请求安全性"""
        try:
            # 检查IP是否被阻止
            client_ip = self._get_client_ip(request)
            if client_ip in self.blocked_ips:
                raise SecurityError("IP地址已被阻止", ErrorCodes.SECURITY_ERROR)
            
            # 检查速率限制
            if not await self._check_rate_limit(client_ip):
                raise SecurityError("请求频率过高", ErrorCodes.RATE_LIMIT_EXCEEDED)
            
            # 检查请求头
            if not self._validate_headers(request):
                raise SecurityError("请求头验证失败", ErrorCodes.SECURITY_ERROR)
            
            # 检查用户代理
            if not self._validate_user_agent(request):
                security_logger.log_suspicious_activity(
                    user_id="anonymous",
                    activity="suspicious_user_agent",
                    ip_address=client_ip,
                    details={"user_agent": request.headers.get("user-agent", "")}
                )
            
            return True
            
        except SecurityError:
            raise
        except Exception as e:
            self.logger.error("请求验证失败", error=str(e))
            raise SecurityError("请求验证失败", ErrorCodes.SECURITY_ERROR)
    
    def _get_client_ip(self, request: Request) -> str:
        """获取客户端IP地址"""
        # 检查代理头
        forwarded_for = request.headers.get("X-Forwarded-For")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        
        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            return real_ip
        
        return request.client.host if request.client else "unknown"
    
    async def _check_rate_limit(self, client_ip: str) -> bool:
        """检查速率限制"""
        current_time = time.time()
        window_size = 60  # 1分钟窗口
        max_requests = 100  # 最大请求数
        
        # 清理过期记录
        if client_ip in self.rate_limits:
            self.rate_limits[client_ip] = [
                timestamp for timestamp in self.rate_limits[client_ip]
                if current_time - timestamp < window_size
            ]
        else:
            self.rate_limits[client_ip] = []
        
        # 检查是否超过限制
        if len(self.rate_limits[client_ip]) >= max_requests:
            # 记录可疑活动
            security_logger.log_suspicious_activity(
                user_id="anonymous",
                activity="rate_limit_exceeded",
                ip_address=client_ip,
                details={"requests": len(self.rate_limits[client_ip]), "limit": max_requests}
            )
            return False
        
        # 记录请求
        self.rate_limits[client_ip].append(current_time)
        return True
    
    def _validate_headers(self, request: Request) -> bool:
        """验证请求头"""
        # 检查必需的请求头
        required_headers = ["User-Agent", "Accept"]
        for header in required_headers:
            if header not in request.headers:
                return False
        
        # 检查可疑的请求头
        suspicious_headers = [
            "X-Forwarded-Host",
            "X-Original-URL",
            "X-Rewrite-URL"
        ]
        
        for header in suspicious_headers:
            if header in request.headers:
                value = request.headers[header]
                if any(suspicious in value.lower() for suspicious in ["admin", "config", "debug"]):
                    return False
        
        return True
    
    def _validate_user_agent(self, request: Request) -> bool:
        """验证用户代理"""
        user_agent = request.headers.get("User-Agent", "").lower()
        
        # 检查空用户代理
        if not user_agent:
            return False
        
        # 检查可疑的用户代理
        suspicious_agents = [
            "sqlmap", "nmap", "nikto", "wget", "curl", "python-requests",
            "bot", "crawler", "spider", "scanner"
        ]
        
        for agent in suspicious_agents:
            if agent in user_agent:
                return False
        
        return True
    
    async def validate_password_strength(self, password: str) -> Tuple[bool, List[str]]:
        """验证密码强度"""
        errors = []
        
        # 长度检查
        if len(password) < settings.PASSWORD_MIN_LENGTH:
            errors.append(f"密码长度至少需要{settings.PASSWORD_MIN_LENGTH}个字符")
        
        # 复杂度检查
        if settings.PASSWORD_REQUIRE_UPPERCASE and not any(c.isupper() for c in password):
            errors.append("密码必须包含大写字母")
        
        if settings.PASSWORD_REQUIRE_LOWERCASE and not any(c.islower() for c in password):
            errors.append("密码必须包含小写字母")
        
        if settings.PASSWORD_REQUIRE_NUMBERS and not any(c.isdigit() for c in password):
            errors.append("密码必须包含数字")
        
        if settings.PASSWORD_REQUIRE_SPECIAL_CHARS and not any(c in "!@#$%^&*()_+-=[]{}|;:,.<>?" for c in password):
            errors.append("密码必须包含特殊字符")
        
        # 常见密码检查
        common_passwords = [
            "password", "123456", "admin", "root", "user", "test",
            "qwerty", "abc123", "password123", "admin123"
        ]
        
        if password.lower() in common_passwords:
            errors.append("不能使用常见密码")
        
        return len(errors) == 0, errors
    
    async def validate_jwt_token(self, token: str) -> Dict[str, Any]:
        """验证JWT令牌"""
        try:
            from jose import jwt, JWTError
            
            payload = jwt.decode(
                token,
                settings.SECRET_KEY,
                algorithms=[settings.ALGORITHM]
            )
            
            # 检查令牌过期时间
            exp = payload.get("exp")
            if exp and datetime.utcnow().timestamp() > exp:
                raise SecurityError("令牌已过期", ErrorCodes.TOKEN_EXPIRED)
            
            return payload
            
        except JWTError as e:
            raise SecurityError("无效的令牌", ErrorCodes.TOKEN_INVALID)
        except Exception as e:
            self.logger.error("令牌验证失败", error=str(e))
            raise SecurityError("令牌验证失败", ErrorCodes.SECURITY_ERROR)
    
    async def check_login_attempts(self, username: str, ip_address: str) -> bool:
        """检查登录尝试次数"""
        key = f"{username}:{ip_address}"
        current_time = time.time()
        window_size = 300  # 5分钟窗口
        max_attempts = 5   # 最大尝试次数
        
        # 清理过期记录
        if key in self.failed_attempts:
            self.failed_attempts[key] = [
                timestamp for timestamp in self.failed_attempts[key]
                if current_time - timestamp < window_size
            ]
        else:
            self.failed_attempts[key] = []
        
        # 检查是否超过限制
        if len(self.failed_attempts[key]) >= max_attempts:
            # 记录可疑活动
            security_logger.log_suspicious_activity(
                user_id=username,
                activity="too_many_login_attempts",
                ip_address=ip_address,
                details={"attempts": len(self.failed_attempts[key]), "limit": max_attempts}
            )
            return False
        
        return True
    
    def record_failed_login(self, username: str, ip_address: str):
        """记录失败的登录尝试"""
        key = f"{username}:{ip_address}"
        if key not in self.failed_attempts:
            self.failed_attempts[key] = []
        
        self.failed_attempts[key].append(time.time())
        
        # 记录登录尝试
        security_logger.log_login_attempt(
            username=username,
            ip_address=ip_address,
            success=False,
            reason="invalid_credentials"
        )
    
    def record_successful_login(self, username: str, ip_address: str):
        """记录成功的登录"""
        key = f"{username}:{ip_address}"
        if key in self.failed_attempts:
            del self.failed_attempts[key]
        
        security_logger.log_login_attempt(
            username=username,
            ip_address=ip_address,
            success=True
        )
    
    async def validate_file_upload(self, filename: str, content_type: str, file_size: int) -> bool:
        """验证文件上传"""
        # 检查文件大小
        if file_size > settings.MAX_FILE_SIZE:
            return False
        
        # 检查文件扩展名
        allowed_extensions = settings.ALLOWED_EXTENSIONS
        file_ext = "." + filename.split(".")[-1].lower()
        if file_ext not in allowed_extensions:
            return False
        
        # 检查文件类型
        suspicious_types = [
            "application/x-executable",
            "application/x-msdownload",
            "application/x-msdos-program"
        ]
        
        if content_type in suspicious_types:
            return False
        
        return True
    
    async def generate_csrf_token(self, user_id: str) -> str:
        """生成CSRF令牌"""
        timestamp = str(int(time.time()))
        data = f"{user_id}:{timestamp}"
        token = hmac.new(
            settings.SECRET_KEY.encode(),
            data.encode(),
            hashlib.sha256
        ).hexdigest()
        
        return f"{timestamp}:{token}"
    
    async def validate_csrf_token(self, token: str, user_id: str) -> bool:
        """验证CSRF令牌"""
        try:
            parts = token.split(":")
            if len(parts) != 2:
                return False
            
            timestamp, token_hash = parts
            data = f"{user_id}:{timestamp}"
            
            expected_token = hmac.new(
                settings.SECRET_KEY.encode(),
                data.encode(),
                hashlib.sha256
            ).hexdigest()
            
            # 检查令牌是否过期（1小时）
            if time.time() - int(timestamp) > 3600:
                return False
            
            return hmac.compare_digest(token_hash, expected_token)
            
        except Exception:
            return False
    
    async def get_security_status(self) -> Dict[str, Any]:
        """获取安全状态"""
        return {
            "blocked_ips": len(self.blocked_ips),
            "rate_limited_ips": len(self.rate_limits),
            "failed_login_attempts": len(self.failed_attempts),
            "timestamp": datetime.utcnow().isoformat()
        }

# 全局安全验证器实例
security_validator = SecurityValidator()

# 安全中间件
class SecurityMiddleware:
    """安全中间件"""
    
    def __init__(self, app):
        self.app = app
        self.validator = security_validator
    
    async def __call__(self, scope, receive, send):
        if scope["type"] == "http":
            request = Request(scope, receive)
            
            try:
                # 验证请求安全性
                await self.validator.validate_request(request)
            except SecurityError as e:
                response = JSONResponse(
                    status_code=status.HTTP_403_FORBIDDEN,
                    content={
                        "error": True,
                        "message": e.message,
                        "error_code": e.error_code
                    }
                )
                await response(scope, receive, send)
                return
        
        await self.app(scope, receive, send)

# 便捷函数
async def validate_request_security(request: Request) -> bool:
    """验证请求安全性"""
    return await security_validator.validate_request(request)

async def validate_password(password: str) -> Tuple[bool, List[str]]:
    """验证密码强度"""
    return await security_validator.validate_password_strength(password)

async def validate_jwt(token: str) -> Dict[str, Any]:
    """验证JWT令牌"""
    return await security_validator.validate_jwt_token(token)

async def check_login_attempts(username: str, ip_address: str) -> bool:
    """检查登录尝试"""
    return await security_validator.check_login_attempts(username, ip_address)

def record_failed_login(username: str, ip_address: str):
    """记录失败登录"""
    security_validator.record_failed_login(username, ip_address)

def record_successful_login(username: str, ip_address: str):
    """记录成功登录"""
    security_validator.record_successful_login(username, ip_address)

async def validate_file_upload(filename: str, content_type: str, file_size: int) -> bool:
    """验证文件上传"""
    return await security_validator.validate_file_upload(filename, content_type, file_size)

async def generate_csrf_token(user_id: str) -> str:
    """生成CSRF令牌"""
    return await security_validator.generate_csrf_token(user_id)

async def validate_csrf_token(token: str, user_id: str) -> bool:
    """验证CSRF令牌"""
    return await security_validator.validate_csrf_token(token, user_id)

async def get_security_status() -> Dict[str, Any]:
    """获取安全状态"""
    return await security_validator.get_security_status()
