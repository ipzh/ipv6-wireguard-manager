"""
增强安全模块 - API安全、数据加密、审计日志
"""
import hashlib
import hmac
import time
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import base64
import secrets
from fastapi import Request, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
import jwt
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from ..models.audit import AuditLog
from ..core.config import settings

logger = logging.getLogger(__name__)

class SecurityEnhanced:
    def __init__(self):
        self.encryption_key = self._get_or_create_encryption_key()
        self.fernet = Fernet(self.encryption_key)
        self.rate_limit_storage = {}
        self.blocked_ips = set()
        self.suspicious_activities = {}

    def _get_or_create_encryption_key(self) -> bytes:
        """获取或创建加密密钥"""
        try:
            # 从环境变量获取密钥
            key = settings.SECRET_KEY.encode()
            if len(key) < 32:
                key = key.ljust(32, b'0')
            elif len(key) > 32:
                key = key[:32]
            
            # 使用PBKDF2生成密钥
            kdf = PBKDF2HMAC(
                algorithm=hashes.SHA256(),
                length=32,
                salt=b'ipv6_wireguard_salt',
                iterations=100000,
            )
            return base64.urlsafe_b64encode(kdf.derive(key))
        except Exception as e:
            logger.error(f"创建加密密钥失败: {e}")
            return Fernet.generate_key()

    def encrypt_data(self, data: str) -> str:
        """加密数据"""
        try:
            encrypted_data = self.fernet.encrypt(data.encode())
            return base64.urlsafe_b64encode(encrypted_data).decode()
        except Exception as e:
            logger.error(f"加密数据失败: {e}")
            raise

    def decrypt_data(self, encrypted_data: str) -> str:
        """解密数据"""
        try:
            decoded_data = base64.urlsafe_b64decode(encrypted_data.encode())
            decrypted_data = self.fernet.decrypt(decoded_data)
            return decrypted_data.decode()
        except Exception as e:
            logger.error(f"解密数据失败: {e}")
            raise

    def generate_secure_token(self, data: Dict[str, Any], expires_delta: timedelta) -> str:
        """生成安全令牌"""
        try:
            to_encode = data.copy()
            expire = datetime.utcnow() + expires_delta
            to_encode.update({"exp": expire, "iat": datetime.utcnow()})
            
            # 添加随机盐值
            to_encode["salt"] = secrets.token_hex(16)
            
            encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm="HS256")
            return encoded_jwt
        except Exception as e:
            logger.error(f"生成安全令牌失败: {e}")
            raise

    def verify_secure_token(self, token: str) -> Optional[Dict[str, Any]]:
        """验证安全令牌"""
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
            return payload
        except jwt.ExpiredSignatureError:
            logger.warning("令牌已过期")
            return None
        except jwt.InvalidTokenError:
            logger.warning("无效令牌")
            return None
        except Exception as e:
            logger.error(f"验证令牌失败: {e}")
            return None

    def generate_api_key(self, user_id: str) -> str:
        """生成API密钥"""
        try:
            timestamp = str(int(time.time()))
            data = f"{user_id}:{timestamp}:{secrets.token_hex(32)}"
            signature = hmac.new(
                settings.SECRET_KEY.encode(),
                data.encode(),
                hashlib.sha256
            ).hexdigest()
            return f"wg_{base64.urlsafe_b64encode(f'{data}:{signature}'.encode()).decode()}"
        except Exception as e:
            logger.error(f"生成API密钥失败: {e}")
            raise

    def verify_api_key(self, api_key: str) -> Optional[Dict[str, Any]]:
        """验证API密钥"""
        try:
            if not api_key.startswith("wg_"):
                return None
            
            decoded_data = base64.urlsafe_b64decode(api_key[3:].encode()).decode()
            parts = decoded_data.split(":")
            
            if len(parts) < 4:
                return None
            
            user_id = parts[0]
            timestamp = parts[1]
            random_data = parts[2]
            signature = parts[3]
            
            # 验证签名
            data_to_verify = f"{user_id}:{timestamp}:{random_data}"
            expected_signature = hmac.new(
                settings.SECRET_KEY.encode(),
                data_to_verify.encode(),
                hashlib.sha256
            ).hexdigest()
            
            if not hmac.compare_digest(signature, expected_signature):
                return None
            
            # 检查时间戳（API密钥有效期24小时）
            key_time = int(timestamp)
            current_time = int(time.time())
            if current_time - key_time > 86400:  # 24小时
                return None
            
            return {
                "user_id": user_id,
                "created_at": key_time,
                "expires_at": key_time + 86400
            }
        except Exception as e:
            logger.error(f"验证API密钥失败: {e}")
            return None

    def check_rate_limit(self, client_ip: str, endpoint: str, limit: int = 100, window: int = 3600) -> bool:
        """检查速率限制"""
        try:
            current_time = int(time.time())
            key = f"{client_ip}:{endpoint}"
            
            if key not in self.rate_limit_storage:
                self.rate_limit_storage[key] = []
            
            # 清理过期记录
            self.rate_limit_storage[key] = [
                timestamp for timestamp in self.rate_limit_storage[key]
                if current_time - timestamp < window
            ]
            
            # 检查是否超过限制
            if len(self.rate_limit_storage[key]) >= limit:
                return False
            
            # 记录当前请求
            self.rate_limit_storage[key].append(current_time)
            return True
            
        except Exception as e:
            logger.error(f"检查速率限制失败: {e}")
            return True  # 出错时允许请求

    def detect_suspicious_activity(self, client_ip: str, request: Request) -> bool:
        """检测可疑活动"""
        try:
            current_time = int(time.time())
            
            if client_ip not in self.suspicious_activities:
                self.suspicious_activities[client_ip] = {
                    "requests": [],
                    "failed_attempts": 0,
                    "last_activity": current_time
                }
            
            activity = self.suspicious_activities[client_ip]
            
            # 记录请求
            activity["requests"].append({
                "timestamp": current_time,
                "method": request.method,
                "path": request.url.path,
                "user_agent": request.headers.get("user-agent", ""),
                "referer": request.headers.get("referer", "")
            })
            
            # 清理旧记录（保留最近1小时）
            activity["requests"] = [
                req for req in activity["requests"]
                if current_time - req["timestamp"] < 3600
            ]
            
            # 检测可疑模式
            suspicious_score = 0
            
            # 1. 请求频率过高
            if len(activity["requests"]) > 1000:  # 1小时内超过1000次请求
                suspicious_score += 50
            
            # 2. 大量404错误
            failed_requests = [req for req in activity["requests"] if "404" in str(req)]
            if len(failed_requests) > 100:
                suspicious_score += 30
            
            # 3. 异常User-Agent
            user_agents = [req["user_agent"] for req in activity["requests"]]
            if len(set(user_agents)) > 10:  # 使用过多不同的User-Agent
                suspicious_score += 20
            
            # 4. 扫描行为（访问不存在的路径）
            paths = [req["path"] for req in activity["requests"]]
            unique_paths = set(paths)
            if len(unique_paths) > 50:  # 访问过多不同路径
                suspicious_score += 25
            
            # 5. 缺少Referer（可能是爬虫）
            no_referer_count = sum(1 for req in activity["requests"] if not req["referer"])
            if no_referer_count > len(activity["requests"]) * 0.8:  # 80%以上请求没有Referer
                suspicious_score += 15
            
            # 如果可疑分数超过阈值，标记为可疑
            if suspicious_score > 50:
                logger.warning(f"检测到可疑活动: IP {client_ip}, 分数: {suspicious_score}")
                return True
            
            return False
            
        except Exception as e:
            logger.error(f"检测可疑活动失败: {e}")
            return False

    def block_ip(self, client_ip: str, reason: str, duration: int = 3600):
        """封禁IP地址"""
        try:
            self.blocked_ips.add(client_ip)
            logger.warning(f"封禁IP {client_ip}: {reason}, 持续时间: {duration}秒")
            
            # 设置自动解封
            def unblock_ip():
                time.sleep(duration)
                self.blocked_ips.discard(client_ip)
                logger.info(f"自动解封IP {client_ip}")
            
            import threading
            threading.Thread(target=unblock_ip, daemon=True).start()
            
        except Exception as e:
            logger.error(f"封禁IP失败: {e}")

    def is_ip_blocked(self, client_ip: str) -> bool:
        """检查IP是否被封禁"""
        return client_ip in self.blocked_ips

    def generate_csrf_token(self, session_id: str) -> str:
        """生成CSRF令牌"""
        try:
            data = f"{session_id}:{int(time.time())}"
            signature = hmac.new(
                settings.SECRET_KEY.encode(),
                data.encode(),
                hashlib.sha256
            ).hexdigest()
            return f"{data}:{signature}"
        except Exception as e:
            logger.error(f"生成CSRF令牌失败: {e}")
            raise

    def verify_csrf_token(self, token: str, session_id: str) -> bool:
        """验证CSRF令牌"""
        try:
            parts = token.split(":")
            if len(parts) != 3:
                return False
            
            token_session_id, timestamp, signature = parts
            
            if token_session_id != session_id:
                return False
            
            # 检查时间戳（CSRF令牌有效期1小时）
            token_time = int(timestamp)
            current_time = int(time.time())
            if current_time - token_time > 3600:
                return False
            
            # 验证签名
            data_to_verify = f"{session_id}:{timestamp}"
            expected_signature = hmac.new(
                settings.SECRET_KEY.encode(),
                data_to_verify.encode(),
                hashlib.sha256
            ).hexdigest()
            
            return hmac.compare_digest(signature, expected_signature)
            
        except Exception as e:
            logger.error(f"验证CSRF令牌失败: {e}")
            return False

# 全局安全实例
security_enhanced = SecurityEnhanced()

class SecurityMiddleware(BaseHTTPMiddleware):
    """安全中间件"""
    
    def __init__(self, app, rate_limit: int = 100, window: int = 3600):
        super().__init__(app)
        self.rate_limit = rate_limit
        self.window = window

    async def dispatch(self, request: Request, call_next):
        client_ip = request.client.host
        
        # 检查IP是否被封禁
        if security_enhanced.is_ip_blocked(client_ip):
            return Response(
                content=json.dumps({"error": "IP已被封禁"}),
                status_code=status.HTTP_403_FORBIDDEN,
                media_type="application/json"
            )
        
        # 检查速率限制
        if not security_enhanced.check_rate_limit(client_ip, request.url.path, self.rate_limit, self.window):
            logger.warning(f"IP {client_ip} 触发速率限制")
            return Response(
                content=json.dumps({"error": "请求过于频繁，请稍后再试"}),
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                media_type="application/json"
            )
        
        # 检测可疑活动
        if security_enhanced.detect_suspicious_activity(client_ip, request):
            security_enhanced.block_ip(client_ip, "可疑活动检测", 3600)
            return Response(
                content=json.dumps({"error": "检测到可疑活动"}),
                status_code=status.HTTP_403_FORBIDDEN,
                media_type="application/json"
            )
        
        # 记录审计日志
        await self.log_request(request, client_ip)
        
        response = await call_next(request)
        return response

    async def log_request(self, request: Request, client_ip: str):
        """记录请求审计日志"""
        try:
            # 这里应该将日志保存到数据库
            # 为了简化，我们只记录到日志文件
            audit_data = {
                "timestamp": datetime.now().isoformat(),
                "client_ip": client_ip,
                "method": request.method,
                "path": request.url.path,
                "query_params": str(request.query_params),
                "user_agent": request.headers.get("user-agent", ""),
                "referer": request.headers.get("referer", ""),
                "content_length": request.headers.get("content-length", "0")
            }
            
            logger.info(f"审计日志: {json.dumps(audit_data)}")
            
        except Exception as e:
            logger.error(f"记录审计日志失败: {e}")

class APIKeyAuth(HTTPBearer):
    """API密钥认证"""
    
    def __init__(self, auto_error: bool = True):
        super().__init__(auto_error=auto_error)

    async def __call__(self, request: Request) -> Optional[Dict[str, Any]]:
        credentials: HTTPAuthorizationCredentials = await super().__call__(request)
        
        if not credentials:
            if self.auto_error:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="未提供API密钥",
                    headers={"WWW-Authenticate": "Bearer"},
                )
            return None
        
        if not credentials.scheme == "Bearer":
            if self.auto_error:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="无效的认证方案",
                    headers={"WWW-Authenticate": "Bearer"},
                )
            return None
        
        # 验证API密钥
        api_key_data = security_enhanced.verify_api_key(credentials.credentials)
        if not api_key_data:
            if self.auto_error:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="无效的API密钥",
                    headers={"WWW-Authenticate": "Bearer"},
                )
            return None
        
        return api_key_data

# 创建认证实例
api_key_auth = APIKeyAuth()
