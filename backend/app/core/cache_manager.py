# 缓存策略模块

import json
import pickle
import hashlib
import time
from typing import Any, Optional, Dict, List, Union, Callable
from datetime import datetime, timedelta
from functools import wraps
import asyncio
from enum import Enum

class CacheBackend(Enum):
    """缓存后端类型"""
    REDIS = "redis"
    MEMORY = "memory"
    FILE = "file"

class CacheStrategy(Enum):
    """缓存策略"""
    LRU = "lru"  # 最近最少使用
    LFU = "lfu"  # 最少使用频率
    TTL = "ttl"  # 生存时间
    WRITE_THROUGH = "write_through"  # 写穿透
    WRITE_BACK = "write_back"  # 写回

class CacheConfig:
    """缓存配置"""
    def __init__(
        self,
        backend: CacheBackend = CacheBackend.MEMORY,
        strategy: CacheStrategy = CacheStrategy.LRU,
        max_size: int = 1000,
        default_ttl: int = 3600,
        compression: bool = False,
        serialize_method: str = "json"
    ):
        self.backend = backend
        self.strategy = strategy
        self.max_size = max_size
        self.default_ttl = default_ttl
        self.compression = compression
        self.serialize_method = serialize_method

class CacheItem:
    """缓存项"""
    def __init__(self, key: str, value: Any, ttl: int = 3600, created_at: float = None):
        self.key = key
        self.value = value
        self.ttl = ttl
        self.created_at = created_at or time.time()
        self.access_count = 0
        self.last_accessed = self.created_at
    
    def is_expired(self) -> bool:
        """检查是否过期"""
        return time.time() - self.created_at > self.ttl
    
    def access(self):
        """访问缓存项"""
        self.access_count += 1
        self.last_accessed = time.time()
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典"""
        return {
            "key": self.key,
            "value": self.value,
            "ttl": self.ttl,
            "created_at": self.created_at,
            "access_count": self.access_count,
            "last_accessed": self.last_accessed
        }

class MemoryCache:
    """内存缓存实现"""
    
    def __init__(self, config: CacheConfig):
        self.config = config
        self.cache: Dict[str, CacheItem] = {}
        self.access_order: List[str] = []
    
    def get(self, key: str) -> Optional[Any]:
        """获取缓存值"""
        if key not in self.cache:
            return None
        
        item = self.cache[key]
        if item.is_expired():
            self.delete(key)
            return None
        
        item.access()
        self._update_access_order(key)
        return item.value
    
    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """设置缓存值"""
        ttl = ttl or self.config.default_ttl
        
        # 检查缓存大小限制
        if len(self.cache) >= self.config.max_size and key not in self.cache:
            self._evict_item()
        
        item = CacheItem(key, value, ttl)
        self.cache[key] = item
        self._update_access_order(key)
        return True
    
    def delete(self, key: str) -> bool:
        """删除缓存项"""
        if key in self.cache:
            del self.cache[key]
            if key in self.access_order:
                self.access_order.remove(key)
            return True
        return False
    
    def clear(self):
        """清空缓存"""
        self.cache.clear()
        self.access_order.clear()
    
    def _update_access_order(self, key: str):
        """更新访问顺序"""
        if key in self.access_order:
            self.access_order.remove(key)
        self.access_order.append(key)
    
    def _evict_item(self):
        """驱逐缓存项"""
        if not self.access_order:
            return
        
        if self.config.strategy == CacheStrategy.LRU:
            # 移除最近最少使用的项
            oldest_key = self.access_order[0]
            self.delete(oldest_key)
        elif self.config.strategy == CacheStrategy.LFU:
            # 移除使用频率最低的项
            least_used_key = min(
                self.cache.keys(),
                key=lambda k: self.cache[k].access_count
            )
            self.delete(least_used_key)
        else:
            # 默认移除第一个项
            oldest_key = self.access_order[0]
            self.delete(oldest_key)
    
    def get_stats(self) -> Dict[str, Any]:
        """获取缓存统计"""
        total_items = len(self.cache)
        expired_items = sum(1 for item in self.cache.values() if item.is_expired())
        
        return {
            "total_items": total_items,
            "expired_items": expired_items,
            "active_items": total_items - expired_items,
            "max_size": self.config.max_size,
            "usage_percentage": (total_items / self.config.max_size) * 100
        }

class RedisCache:
    """Redis缓存实现"""
    
    def __init__(self, config: CacheConfig, redis_client=None):
        self.config = config
        self.redis = redis_client
        self.key_prefix = "ipv6wgm:cache:"
    
    def _get_key(self, key: str) -> str:
        """获取完整的Redis键"""
        return f"{self.key_prefix}{key}"
    
    async def get(self, key: str) -> Optional[Any]:
        """获取缓存值"""
        if not self.redis:
            return None
        
        try:
            redis_key = self._get_key(key)
            data = await self.redis.get(redis_key)
            
            if data is None:
                return None
            
            if self.config.serialize_method == "json":
                return json.loads(data)
            elif self.config.serialize_method == "pickle":
                return pickle.loads(data)
            else:
                return data
        except Exception:
            return None
    
    async def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """设置缓存值"""
        if not self.redis:
            return False
        
        try:
            redis_key = self._get_key(key)
            ttl = ttl or self.config.default_ttl
            
            if self.config.serialize_method == "json":
                data = json.dumps(value)
            elif self.config.serialize_method == "pickle":
                data = pickle.dumps(value)
            else:
                data = value
            
            await self.redis.setex(redis_key, ttl, data)
            return True
        except Exception:
            return False
    
    async def delete(self, key: str) -> bool:
        """删除缓存项"""
        if not self.redis:
            return False
        
        try:
            redis_key = self._get_key(key)
            result = await self.redis.delete(redis_key)
            return result > 0
        except Exception:
            return False
    
    async def clear(self):
        """清空缓存"""
        if not self.redis:
            return
        
        try:
            pattern = f"{self.key_prefix}*"
            keys = await self.redis.keys(pattern)
            if keys:
                await self.redis.delete(*keys)
        except Exception:
            pass
    
    async def get_stats(self) -> Dict[str, Any]:
        """获取缓存统计"""
        if not self.redis:
            return {}
        
        try:
            pattern = f"{self.key_prefix}*"
            keys = await self.redis.keys(pattern)
            
            return {
                "total_items": len(keys),
                "max_size": self.config.max_size,
                "usage_percentage": (len(keys) / self.config.max_size) * 100 if self.config.max_size > 0 else 0
            }
        except Exception:
            return {}

class CacheManager:
    """缓存管理器"""
    
    def __init__(self, config: CacheConfig, redis_client=None):
        self.config = config
        self.redis_client = redis_client
        
        if config.backend == CacheBackend.MEMORY:
            self.cache = MemoryCache(config)
        elif config.backend == CacheBackend.REDIS:
            self.cache = RedisCache(config, redis_client)
        else:
            raise ValueError(f"不支持的缓存后端: {config.backend}")
    
    def generate_cache_key(self, prefix: str, *args, **kwargs) -> str:
        """生成缓存键"""
        key_data = {
            "prefix": prefix,
            "args": args,
            "kwargs": sorted(kwargs.items())
        }
        
        key_string = json.dumps(key_data, sort_keys=True)
        return hashlib.md5(key_string.encode()).hexdigest()
    
    async def get(self, key: str) -> Optional[Any]:
        """获取缓存值"""
        if self.config.backend == CacheBackend.REDIS:
            return await self.cache.get(key)
        else:
            return self.cache.get(key)
    
    async def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """设置缓存值"""
        if self.config.backend == CacheBackend.REDIS:
            return await self.cache.set(key, value, ttl)
        else:
            return self.cache.set(key, value, ttl)
    
    async def delete(self, key: str) -> bool:
        """删除缓存项"""
        if self.config.backend == CacheBackend.REDIS:
            return await self.cache.delete(key)
        else:
            return self.cache.delete(key)
    
    async def clear(self):
        """清空缓存"""
        if self.config.backend == CacheBackend.REDIS:
            await self.cache.clear()
        else:
            self.cache.clear()
    
    async def get_stats(self) -> Dict[str, Any]:
        """获取缓存统计"""
        if self.config.backend == CacheBackend.REDIS:
            return await self.cache.get_stats()
        else:
            return self.cache.get_stats()
    
    def cache_key(self, prefix: str, *args, **kwargs):
        """缓存键装饰器"""
        def decorator(func):
            @wraps(func)
            async def wrapper(*func_args, **func_kwargs):
                # 生成缓存键
                cache_key = self.generate_cache_key(prefix, *func_args, **func_kwargs)
                
                # 尝试从缓存获取
                cached_result = await self.get(cache_key)
                if cached_result is not None:
                    return cached_result
                
                # 执行函数
                result = await func(*func_args, **func_kwargs)
                
                # 存储到缓存
                await self.set(cache_key, result)
                
                return result
            return wrapper
        return decorator

class QueryCache:
    """查询缓存"""
    
    def __init__(self, cache_manager: CacheManager):
        self.cache_manager = cache_manager
    
    async def cache_query(self, query_key: str, query_func: Callable, ttl: int = 300):
        """缓存查询结果"""
        cached_result = await self.cache_manager.get(query_key)
        if cached_result is not None:
            return cached_result
        
        result = await query_func()
        await self.cache_manager.set(query_key, result, ttl)
        return result
    
    async def invalidate_query(self, pattern: str):
        """使查询缓存失效"""
        # 这里需要根据模式删除相关的缓存项
        # 具体实现取决于缓存后端
        pass

class SessionCache:
    """会话缓存"""
    
    def __init__(self, cache_manager: CacheManager):
        self.cache_manager = cache_manager
        self.session_ttl = 1800  # 30分钟
    
    async def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        """获取会话"""
        cache_key = f"session:{session_id}"
        return await self.cache_manager.get(cache_key)
    
    async def set_session(self, session_id: str, session_data: Dict[str, Any]):
        """设置会话"""
        cache_key = f"session:{session_id}"
        await self.cache_manager.set(cache_key, session_data, self.session_ttl)
    
    async def delete_session(self, session_id: str):
        """删除会话"""
        cache_key = f"session:{session_id}"
        await self.cache_manager.delete(cache_key)
    
    async def extend_session(self, session_id: str):
        """延长会话"""
        session_data = await self.get_session(session_id)
        if session_data:
            await self.set_session(session_id, session_data)

class APICache:
    """API响应缓存"""
    
    def __init__(self, cache_manager: CacheManager):
        self.cache_manager = cache_manager
    
    async def cache_api_response(self, endpoint: str, params: Dict[str, Any], response_data: Any, ttl: int = 60):
        """缓存API响应"""
        cache_key = self.cache_manager.generate_cache_key(f"api:{endpoint}", **params)
        await self.cache_manager.set(cache_key, response_data, ttl)
    
    async def get_cached_response(self, endpoint: str, params: Dict[str, Any]) -> Optional[Any]:
        """获取缓存的API响应"""
        cache_key = self.cache_manager.generate_cache_key(f"api:{endpoint}", **params)
        return await self.cache_manager.get(cache_key)
    
    async def invalidate_endpoint_cache(self, endpoint: str):
        """使端点缓存失效"""
        # 这里需要根据端点模式删除相关的缓存项
        pass

# 缓存配置实例
CACHE_CONFIGS = {
    "default": CacheConfig(
        backend=CacheBackend.MEMORY,
        strategy=CacheStrategy.LRU,
        max_size=1000,
        default_ttl=3600
    ),
    "redis": CacheConfig(
        backend=CacheBackend.REDIS,
        strategy=CacheStrategy.TTL,
        max_size=10000,
        default_ttl=3600
    ),
    "session": CacheConfig(
        backend=CacheBackend.REDIS,
        strategy=CacheStrategy.TTL,
        max_size=5000,
        default_ttl=1800
    ),
    "query": CacheConfig(
        backend=CacheBackend.REDIS,
        strategy=CacheStrategy.LRU,
        max_size=2000,
        default_ttl=300
    )
}
