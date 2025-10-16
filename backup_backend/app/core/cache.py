"""
缓存配置和管理
"""
import redis.asyncio as redis
from typing import Any, Optional, Union
import json
import pickle
from datetime import timedelta
import logging

from .config import settings

logger = logging.getLogger(__name__)

class CacheManager:
    """缓存管理器"""
    
    def __init__(self):
        self.redis_client: Optional[redis.Redis] = None
        self._is_connected = False
    
    async def connect(self):
        """连接Redis"""
        try:
            self.redis_client = redis.Redis.from_url(
                settings.REDIS_URL,
                max_connections=settings.REDIS_POOL_SIZE,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5,
                retry_on_timeout=True,
            )
            # 测试连接
            await self.redis_client.ping()
            self._is_connected = True
            logger.info("Redis缓存连接成功")
        except Exception as e:
            logger.warning(f"Redis连接失败，使用内存缓存: {e}")
            self.redis_client = None
            self._is_connected = False
    
    async def disconnect(self):
        """断开Redis连接"""
        if self.redis_client:
            await self.redis_client.close()
            self._is_connected = False
    
    async def set(self, key: str, value: Any, expire: Optional[int] = None) -> bool:
        """设置缓存"""
        try:
            if self._is_connected and self.redis_client:
                # 使用JSON序列化
                serialized_value = json.dumps(value, default=str)
                if expire:
                    await self.redis_client.setex(key, expire, serialized_value)
                else:
                    await self.redis_client.set(key, serialized_value)
                return True
            else:
                # 内存缓存（简单实现）
                if not hasattr(self, '_memory_cache'):
                    self._memory_cache = {}
                self._memory_cache[key] = value
                return True
        except Exception as e:
            logger.error(f"设置缓存失败: {e}")
            return False
    
    async def get(self, key: str, default: Any = None) -> Any:
        """获取缓存"""
        try:
            if self._is_connected and self.redis_client:
                value = await self.redis_client.get(key)
                if value:
                    return json.loads(value)
                return default
            else:
                # 内存缓存
                if hasattr(self, '_memory_cache') and key in self._memory_cache:
                    return self._memory_cache[key]
                return default
        except Exception as e:
            logger.error(f"获取缓存失败: {e}")
            return default
    
    async def delete(self, key: str) -> bool:
        """删除缓存"""
        try:
            if self._is_connected and self.redis_client:
                result = await self.redis_client.delete(key)
                return result > 0
            else:
                # 内存缓存
                if hasattr(self, '_memory_cache') and key in self._memory_cache:
                    del self._memory_cache[key]
                    return True
                return False
        except Exception as e:
            logger.error(f"删除缓存失败: {e}")
            return False
    
    async def exists(self, key: str) -> bool:
        """检查缓存是否存在"""
        try:
            if self._is_connected and self.redis_client:
                return await self.redis_client.exists(key) > 0
            else:
                return hasattr(self, '_memory_cache') and key in self._memory_cache
        except Exception as e:
            logger.error(f"检查缓存存在失败: {e}")
            return False
    
    async def clear_pattern(self, pattern: str) -> int:
        """清除匹配模式的缓存"""
        try:
            if self._is_connected and self.redis_client:
                keys = await self.redis_client.keys(pattern)
                if keys:
                    await self.redis_client.delete(*keys)
                    return len(keys)
                return 0
            else:
                # 内存缓存
                if hasattr(self, '_memory_cache'):
                    keys_to_delete = [k for k in self._memory_cache.keys() if pattern in k]
                    for key in keys_to_delete:
                        del self._memory_cache[key]
                    return len(keys_to_delete)
                return 0
        except Exception as e:
            logger.error(f"清除模式缓存失败: {e}")
            return 0

# 全局缓存实例
cache_manager = CacheManager()

# 缓存装饰器
def cached(expire: int = 300, key_prefix: str = "cache:"):
    """缓存装饰器"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            # 生成缓存键
            cache_key = f"{key_prefix}{func.__module__}.{func.__name__}:"
            if args:
                cache_key += str(hash(str(args)))
            if kwargs:
                cache_key += str(hash(str(sorted(kwargs.items()))))
            
            # 尝试从缓存获取
            cached_result = await cache_manager.get(cache_key)
            if cached_result is not None:
                logger.debug(f"缓存命中: {cache_key}")
                return cached_result
            
            # 执行函数
            result = await func(*args, **kwargs)
            
            # 设置缓存
            await cache_manager.set(cache_key, result, expire)
            logger.debug(f"缓存设置: {cache_key}")
            
            return result
        
        return wrapper
    return decorator

# 预定义的缓存键
class CacheKeys:
    """缓存键常量"""
    
    # 系统状态
    SYSTEM_STATUS = "system:status"
    SYSTEM_METRICS = "system:metrics"
    
    # WireGuard相关
    WIREGUARD_SERVERS = "wireguard:servers"
    WIREGUARD_CLIENTS = "wireguard:clients"
    WIREGUARD_STATUS = "wireguard:status"
    
    # BGP相关
    BGP_SESSIONS = "bgp:sessions"
    BGP_NEIGHBORS = "bgp:neighbors"
    BGP_PREFIXES = "bgp:prefixes"
    
    # IPv6相关
    IPV6_POOLS = "ipv6:pools"
    IPV6_ALLOCATIONS = "ipv6:allocations"
    IPV6_UTILIZATION = "ipv6:utilization"
    
    # 监控相关
    METRICS_HISTORY = "metrics:history"
    ALERTS = "alerts:current"

async def init_cache():
    """初始化缓存"""
    await cache_manager.connect()

async def close_cache():
    """关闭缓存"""
    await cache_manager.disconnect()