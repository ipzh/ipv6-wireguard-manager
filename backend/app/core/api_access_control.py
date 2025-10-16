"""
API访问控制系统
提供API密钥管理、访问控制、速率限制等高级功能
"""
import asyncio
import hashlib
import hmac
import secrets
import time
import logging
from typing import Dict, Any, List, Optional, Set, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from enum import Enum
import json
import ipaddress

from fastapi import Request, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import redis.asyncio as redis

logger = logging.getLogger(__name__)

class APIKeyStatus(Enum):
    """API密钥状态"""
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"
    EXPIRED = "expired"

class AccessLevel(Enum):
    """访问级别"""
    READ = "read"
    WRITE = "write"
    ADMIN = "admin"
    SUPER_ADMIN = "super_admin"

@dataclass
class APIKey:
    """API密钥"""
    id: str
    name: str
    key_hash: str
    user_id: Optional[str]
    access_level: AccessLevel
    permissions: List[str]
    allowed_ips: List[str]
    allowed_endpoints: List[str]
    rate_limit: Dict[str, int]
    status: APIKeyStatus
    expires_at: Optional[datetime]
    last_used: Optional[datetime]
    created_at: datetime
    created_by: str
    description: str = ""
    tags: List[str] = field(default_factory=list)

@dataclass
class AccessRule:
    """访问规则"""
    id: str
    name: str
    description: str
    conditions: Dict[str, Any]
    actions: List[str]
    priority: int
    enabled: bool
    created_at: datetime
    updated_at: datetime

@dataclass
class RateLimitRule:
    """速率限制规则"""
    id: str
    name: str
    pattern: str  # 匹配模式
    limit: int  # 限制数量
    window: int  # 时间窗口（秒）
    action: str  # 超出限制时的动作
    enabled: bool
    created_at: datetime

class APIKeyManager:
    """API密钥管理器"""
    
    def __init__(self, db_session: AsyncSession, redis_client: redis.Redis = None):
        self.db_session = db_session
        self.redis_client = redis_client
        
        # 配置
        self.config = {
            'key_length': 32,
            'hash_algorithm': 'sha256',
            'default_expiry_days': 365,
            'max_keys_per_user': 10,
            'enable_key_rotation': True
        }
    
    async def create_api_key(self, 
                           name: str,
                           user_id: Optional[str],
                           access_level: AccessLevel,
                           permissions: List[str],
                           allowed_ips: List[str] = None,
                           allowed_endpoints: List[str] = None,
                           rate_limit: Dict[str, int] = None,
                           expires_at: Optional[datetime] = None,
                           created_by: str = "system",
                           description: str = "",
                           tags: List[str] = None) -> Tuple[str, APIKey]:
        """创建API密钥"""
        try:
            # 生成密钥
            api_key = self._generate_api_key()
            key_hash = self._hash_api_key(api_key)
            
            # 设置默认值
            if allowed_ips is None:
                allowed_ips = []
            if allowed_endpoints is None:
                allowed_endpoints = []
            if rate_limit is None:
                rate_limit = {"requests_per_minute": 1000, "burst_limit": 2000}
            if expires_at is None:
                expires_at = datetime.now() + timedelta(days=self.config['default_expiry_days'])
            if tags is None:
                tags = []
            
            # 创建API密钥对象
            api_key_obj = APIKey(
                id=secrets.token_hex(8),
                name=name,
                key_hash=key_hash,
                user_id=user_id,
                access_level=access_level,
                permissions=permissions,
                allowed_ips=allowed_ips,
                allowed_endpoints=allowed_endpoints,
                rate_limit=rate_limit,
                status=APIKeyStatus.ACTIVE,
                expires_at=expires_at,
                last_used=None,
                created_at=datetime.now(),
                created_by=created_by,
                description=description,
                tags=tags
            )
            
            # 保存到数据库
            await self._save_api_key(api_key_obj)
            
            # 缓存到Redis
            if self.redis_client:
                await self._cache_api_key(api_key_obj)
            
            logger.info(f"API密钥已创建: {name} - {user_id}")
            return api_key, api_key_obj
            
        except Exception as e:
            logger.error(f"创建API密钥失败: {e}")
            raise
    
    async def validate_api_key(self, api_key: str, request: Request) -> Tuple[bool, Optional[APIKey], str]:
        """验证API密钥"""
        try:
            # 获取客户端IP
            client_ip = self._get_client_ip(request)
            
            # 从缓存或数据库获取密钥信息
            api_key_obj = await self._get_api_key_by_hash(self._hash_api_key(api_key))
            if not api_key_obj:
                return False, None, "无效的API密钥"
            
            # 检查状态
            if api_key_obj.status != APIKeyStatus.ACTIVE:
                return False, api_key_obj, "API密钥已禁用"
            
            # 检查过期时间
            if api_key_obj.expires_at and datetime.now() > api_key_obj.expires_at:
                return False, api_key_obj, "API密钥已过期"
            
            # 检查IP限制
            if api_key_obj.allowed_ips and client_ip not in api_key_obj.allowed_ips:
                return False, api_key_obj, "IP地址不在允许列表中"
            
            # 检查端点权限
            endpoint = request.url.path
            if api_key_obj.allowed_endpoints and not self._is_endpoint_allowed(endpoint, api_key_obj.allowed_endpoints):
                return False, api_key_obj, "端点不在允许列表中"
            
            # 更新最后使用时间
            await self._update_last_used(api_key_obj.id)
            
            return True, api_key_obj, "验证成功"
            
        except Exception as e:
            logger.error(f"验证API密钥失败: {e}")
            return False, None, "验证失败"
    
    async def revoke_api_key(self, key_id: str, revoked_by: str) -> bool:
        """撤销API密钥"""
        try:
            # 更新数据库
            query = """
            UPDATE api_keys 
            SET status = 'inactive', updated_at = NOW(), updated_by = :updated_by
            WHERE id = :key_id
            """
            await self.db_session.execute(text(query), {
                'key_id': key_id,
                'updated_by': revoked_by
            })
            await self.db_session.commit()
            
            # 从缓存中删除
            if self.redis_client:
                await self.redis_client.delete(f"api_key:{key_id}")
            
            logger.info(f"API密钥已撤销: {key_id}")
            return True
            
        except Exception as e:
            logger.error(f"撤销API密钥失败: {e}")
            return False
    
    async def rotate_api_key(self, key_id: str, rotated_by: str) -> Tuple[str, APIKey]:
        """轮换API密钥"""
        try:
            # 获取现有密钥信息
            api_key_obj = await self._get_api_key_by_id(key_id)
            if not api_key_obj:
                raise ValueError("API密钥不存在")
            
            # 生成新密钥
            new_api_key = self._generate_api_key()
            new_key_hash = self._hash_api_key(new_api_key)
            
            # 更新密钥
            api_key_obj.key_hash = new_key_hash
            api_key_obj.last_used = None
            
            # 保存到数据库
            await self._save_api_key(api_key_obj)
            
            # 更新缓存
            if self.redis_client:
                await self._cache_api_key(api_key_obj)
            
            logger.info(f"API密钥已轮换: {key_id}")
            return new_api_key, api_key_obj
            
        except Exception as e:
            logger.error(f"轮换API密钥失败: {e}")
            raise
    
    async def get_api_keys(self, user_id: Optional[str] = None, status: APIKeyStatus = None) -> List[APIKey]:
        """获取API密钥列表"""
        try:
            where_conditions = []
            params = {}
            
            if user_id:
                where_conditions.append("user_id = :user_id")
                params['user_id'] = user_id
            
            if status:
                where_conditions.append("status = :status")
                params['status'] = status.value
            
            where_clause = " AND ".join(where_conditions) if where_conditions else "1=1"
            
            query = f"""
            SELECT * FROM api_keys 
            WHERE {where_clause}
            ORDER BY created_at DESC
            """
            
            result = await self.db_session.execute(text(query), params)
            rows = result.fetchall()
            
            api_keys = []
            for row in rows:
                api_key = APIKey(
                    id=row.id,
                    name=row.name,
                    key_hash=row.key_hash,
                    user_id=row.user_id,
                    access_level=AccessLevel(row.access_level),
                    permissions=json.loads(row.permissions),
                    allowed_ips=json.loads(row.allowed_ips),
                    allowed_endpoints=json.loads(row.allowed_endpoints),
                    rate_limit=json.loads(row.rate_limit),
                    status=APIKeyStatus(row.status),
                    expires_at=row.expires_at,
                    last_used=row.last_used,
                    created_at=row.created_at,
                    created_by=row.created_by,
                    description=row.description,
                    tags=json.loads(row.tags) if row.tags else []
                )
                api_keys.append(api_key)
            
            return api_keys
            
        except Exception as e:
            logger.error(f"获取API密钥列表失败: {e}")
            return []
    
    def _generate_api_key(self) -> str:
        """生成API密钥"""
        return secrets.token_urlsafe(self.config['key_length'])
    
    def _hash_api_key(self, api_key: str) -> str:
        """哈希API密钥"""
        return hashlib.sha256(api_key.encode()).hexdigest()
    
    def _get_client_ip(self, request: Request) -> str:
        """获取客户端IP"""
        forwarded_for = request.headers.get("x-forwarded-for")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        
        real_ip = request.headers.get("x-real-ip")
        if real_ip:
            return real_ip
        
        return request.client.host if request.client else "unknown"
    
    def _is_endpoint_allowed(self, endpoint: str, allowed_endpoints: List[str]) -> bool:
        """检查端点是否允许"""
        for pattern in allowed_endpoints:
            if pattern == "*" or pattern == endpoint:
                return True
            if pattern.endswith("*") and endpoint.startswith(pattern[:-1]):
                return True
            if pattern.startswith("*") and endpoint.endswith(pattern[1:]):
                return True
        return False
    
    async def _save_api_key(self, api_key: APIKey):
        """保存API密钥到数据库"""
        query = """
        INSERT INTO api_keys 
        (id, name, key_hash, user_id, access_level, permissions, allowed_ips, 
         allowed_endpoints, rate_limit, status, expires_at, created_at, created_by, 
         description, tags)
        VALUES 
        (:id, :name, :key_hash, :user_id, :access_level, :permissions, :allowed_ips,
         :allowed_endpoints, :rate_limit, :status, :expires_at, :created_at, :created_by,
         :description, :tags)
        ON DUPLICATE KEY UPDATE
        name = VALUES(name),
        key_hash = VALUES(key_hash),
        access_level = VALUES(access_level),
        permissions = VALUES(permissions),
        allowed_ips = VALUES(allowed_ips),
        allowed_endpoints = VALUES(allowed_endpoints),
        rate_limit = VALUES(rate_limit),
        status = VALUES(status),
        expires_at = VALUES(expires_at),
        updated_at = NOW()
        """
        
        await self.db_session.execute(text(query), {
            'id': api_key.id,
            'name': api_key.name,
            'key_hash': api_key.key_hash,
            'user_id': api_key.user_id,
            'access_level': api_key.access_level.value,
            'permissions': json.dumps(api_key.permissions),
            'allowed_ips': json.dumps(api_key.allowed_ips),
            'allowed_endpoints': json.dumps(api_key.allowed_endpoints),
            'rate_limit': json.dumps(api_key.rate_limit),
            'status': api_key.status.value,
            'expires_at': api_key.expires_at,
            'created_at': api_key.created_at,
            'created_by': api_key.created_by,
            'description': api_key.description,
            'tags': json.dumps(api_key.tags)
        })
        await self.db_session.commit()
    
    async def _cache_api_key(self, api_key: APIKey):
        """缓存API密钥到Redis"""
        if self.redis_client:
            cache_data = {
                'id': api_key.id,
                'name': api_key.name,
                'user_id': api_key.user_id,
                'access_level': api_key.access_level.value,
                'permissions': api_key.permissions,
                'allowed_ips': api_key.allowed_ips,
                'allowed_endpoints': api_key.allowed_endpoints,
                'rate_limit': api_key.rate_limit,
                'status': api_key.status.value,
                'expires_at': api_key.expires_at.isoformat() if api_key.expires_at else None,
                'last_used': api_key.last_used.isoformat() if api_key.last_used else None,
                'created_at': api_key.created_at.isoformat(),
                'created_by': api_key.created_by,
                'description': api_key.description,
                'tags': api_key.tags
            }
            
            await self.redis_client.setex(
                f"api_key:{api_key.id}",
                3600,  # 1小时过期
                json.dumps(cache_data, default=str)
            )
    
    async def _get_api_key_by_hash(self, key_hash: str) -> Optional[APIKey]:
        """通过哈希获取API密钥"""
        try:
            # 先从缓存获取
            if self.redis_client:
                cached_data = await self.redis_client.get(f"api_key_hash:{key_hash}")
                if cached_data:
                    data = json.loads(cached_data)
                    return self._dict_to_api_key(data)
            
            # 从数据库获取
            query = "SELECT * FROM api_keys WHERE key_hash = :key_hash"
            result = await self.db_session.execute(text(query), {'key_hash': key_hash})
            row = result.fetchone()
            
            if row:
                api_key = self._row_to_api_key(row)
                # 缓存到Redis
                if self.redis_client:
                    await self.redis_client.setex(
                        f"api_key_hash:{key_hash}",
                        3600,
                        json.dumps(self._api_key_to_dict(api_key), default=str)
                    )
                return api_key
            
            return None
            
        except Exception as e:
            logger.error(f"获取API密钥失败: {e}")
            return None
    
    async def _get_api_key_by_id(self, key_id: str) -> Optional[APIKey]:
        """通过ID获取API密钥"""
        try:
            query = "SELECT * FROM api_keys WHERE id = :key_id"
            result = await self.db_session.execute(text(query), {'key_id': key_id})
            row = result.fetchone()
            
            if row:
                return self._row_to_api_key(row)
            
            return None
            
        except Exception as e:
            logger.error(f"获取API密钥失败: {e}")
            return None
    
    async def _update_last_used(self, key_id: str):
        """更新最后使用时间"""
        try:
            query = "UPDATE api_keys SET last_used = NOW() WHERE id = :key_id"
            await self.db_session.execute(text(query), {'key_id': key_id})
            await self.db_session.commit()
        except Exception as e:
            logger.error(f"更新最后使用时间失败: {e}")
    
    def _row_to_api_key(self, row) -> APIKey:
        """将数据库行转换为APIKey对象"""
        return APIKey(
            id=row.id,
            name=row.name,
            key_hash=row.key_hash,
            user_id=row.user_id,
            access_level=AccessLevel(row.access_level),
            permissions=json.loads(row.permissions),
            allowed_ips=json.loads(row.allowed_ips),
            allowed_endpoints=json.loads(row.allowed_endpoints),
            rate_limit=json.loads(row.rate_limit),
            status=APIKeyStatus(row.status),
            expires_at=row.expires_at,
            last_used=row.last_used,
            created_at=row.created_at,
            created_by=row.created_by,
            description=row.description,
            tags=json.loads(row.tags) if row.tags else []
        )
    
    def _api_key_to_dict(self, api_key: APIKey) -> Dict[str, Any]:
        """将APIKey对象转换为字典"""
        return {
            'id': api_key.id,
            'name': api_key.name,
            'key_hash': api_key.key_hash,
            'user_id': api_key.user_id,
            'access_level': api_key.access_level.value,
            'permissions': api_key.permissions,
            'allowed_ips': api_key.allowed_ips,
            'allowed_endpoints': api_key.allowed_endpoints,
            'rate_limit': api_key.rate_limit,
            'status': api_key.status.value,
            'expires_at': api_key.expires_at.isoformat() if api_key.expires_at else None,
            'last_used': api_key.last_used.isoformat() if api_key.last_used else None,
            'created_at': api_key.created_at.isoformat(),
            'created_by': api_key.created_by,
            'description': api_key.description,
            'tags': api_key.tags
        }
    
    def _dict_to_api_key(self, data: Dict[str, Any]) -> APIKey:
        """将字典转换为APIKey对象"""
        return APIKey(
            id=data['id'],
            name=data['name'],
            key_hash=data['key_hash'],
            user_id=data['user_id'],
            access_level=AccessLevel(data['access_level']),
            permissions=data['permissions'],
            allowed_ips=data['allowed_ips'],
            allowed_endpoints=data['allowed_endpoints'],
            rate_limit=data['rate_limit'],
            status=APIKeyStatus(data['status']),
            expires_at=datetime.fromisoformat(data['expires_at']) if data['expires_at'] else None,
            last_used=datetime.fromisoformat(data['last_used']) if data['last_used'] else None,
            created_at=datetime.fromisoformat(data['created_at']),
            created_by=data['created_by'],
            description=data['description'],
            tags=data['tags']
        )

class RateLimiter:
    """速率限制器"""
    
    def __init__(self, redis_client: redis.Redis):
        self.redis_client = redis_client
        self.rules = {}
    
    async def check_rate_limit(self, identifier: str, rule: RateLimitRule) -> Tuple[bool, Dict[str, Any]]:
        """检查速率限制"""
        try:
            current_time = int(time.time())
            window_start = current_time - rule.window
            
            # 使用滑动窗口算法
            key = f"rate_limit:{rule.id}:{identifier}"
            
            # 获取当前计数
            pipe = self.redis_client.pipeline()
            pipe.zremrangebyscore(key, 0, window_start)  # 清理过期记录
            pipe.zcard(key)  # 获取当前计数
            pipe.zadd(key, {str(current_time): current_time})  # 添加当前请求
            pipe.expire(key, rule.window)  # 设置过期时间
            
            results = await pipe.execute()
            current_count = results[1]
            
            # 检查是否超出限制
            if current_count >= rule.limit:
                return False, {
                    'limit': rule.limit,
                    'current': current_count,
                    'window': rule.window,
                    'reset_time': current_time + rule.window
                }
            
            return True, {
                'limit': rule.limit,
                'current': current_count + 1,
                'window': rule.window,
                'reset_time': current_time + rule.window
            }
            
        except Exception as e:
            logger.error(f"速率限制检查失败: {e}")
            return True, {}  # 出错时允许通过
    
    async def add_rate_limit_rule(self, rule: RateLimitRule):
        """添加速率限制规则"""
        self.rules[rule.id] = rule
    
    async def remove_rate_limit_rule(self, rule_id: str):
        """移除速率限制规则"""
        if rule_id in self.rules:
            del self.rules[rule_id]

class APIAccessController:
    """API访问控制器"""
    
    def __init__(self, db_session: AsyncSession, redis_client: redis.Redis = None):
        self.db_session = db_session
        self.redis_client = redis_client
        
        # 初始化组件
        self.api_key_manager = APIKeyManager(db_session, redis_client)
        self.rate_limiter = RateLimiter(redis_client) if redis_client else None
        
        # 配置
        self.config = {
            'enable_api_key_auth': True,
            'enable_rate_limiting': True,
            'enable_ip_whitelist': True,
            'default_rate_limit': {
                'requests_per_minute': 1000,
                'burst_limit': 2000
            }
        }
    
    async def authenticate_request(self, request: Request) -> Tuple[bool, Optional[APIKey], str]:
        """认证请求"""
        try:
            # 检查API密钥
            if self.config['enable_api_key_auth']:
                api_key = self._extract_api_key(request)
                if not api_key:
                    return False, None, "缺少API密钥"
                
                is_valid, api_key_obj, message = await self.api_key_manager.validate_api_key(api_key, request)
                if not is_valid:
                    return False, None, message
                
                # 检查速率限制
                if self.config['enable_rate_limiting'] and self.rate_limiter:
                    identifier = self._get_rate_limit_identifier(request, api_key_obj)
                    rate_limit_rule = self._get_rate_limit_rule(api_key_obj)
                    
                    if rate_limit_rule:
                        is_allowed, rate_info = await self.rate_limiter.check_rate_limit(identifier, rate_limit_rule)
                        if not is_allowed:
                            return False, api_key_obj, f"速率限制超出: {rate_info}"
                
                return True, api_key_obj, "认证成功"
            
            return True, None, "认证成功"
            
        except Exception as e:
            logger.error(f"请求认证失败: {e}")
            return False, None, "认证失败"
    
    def _extract_api_key(self, request: Request) -> Optional[str]:
        """提取API密钥"""
        # 从Header中获取
        api_key = request.headers.get("X-API-Key")
        if api_key:
            return api_key
        
        # 从Authorization Header中获取
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            return auth_header[7:]
        
        # 从查询参数中获取
        api_key = request.query_params.get("api_key")
        if api_key:
            return api_key
        
        return None
    
    def _get_rate_limit_identifier(self, request: Request, api_key: APIKey) -> str:
        """获取速率限制标识符"""
        if api_key.user_id:
            return f"user:{api_key.user_id}"
        else:
            return f"key:{api_key.id}"
    
    def _get_rate_limit_rule(self, api_key: APIKey) -> Optional[RateLimitRule]:
        """获取速率限制规则"""
        rate_limit = api_key.rate_limit
        if not rate_limit:
            return None
        
        return RateLimitRule(
            id=f"api_key_{api_key.id}",
            name=f"API Key {api_key.name}",
            pattern="*",
            limit=rate_limit.get('requests_per_minute', 1000),
            window=60,  # 1分钟
            action="block",
            enabled=True,
            created_at=datetime.now()
        )

# 全局API访问控制器实例
api_access_controller: Optional[APIAccessController] = None

async def get_api_access_controller() -> APIAccessController:
    """获取API访问控制器实例"""
    global api_access_controller
    if api_access_controller is None:
        raise ValueError("API访问控制器未初始化")
    return api_access_controller

async def init_api_access_controller(db_session: AsyncSession, redis_client: redis.Redis = None):
    """初始化API访问控制器"""
    global api_access_controller
    api_access_controller = APIAccessController(db_session, redis_client)
    logger.info("API访问控制器初始化完成")
