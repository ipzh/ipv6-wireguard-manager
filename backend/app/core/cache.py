"""
缓存策略模块
实现多级缓存、缓存失效、缓存预热
"""

import time
import json
import logging
from typing import Any, Optional, Dict, List, Callable
from functools import wraps
import redis
from redis import ConnectionPool
import hashlib

logger = logging.getLogger(__name__)

class CacheManager:
    """缓存管理器"""
    
    def __init__(self, redis_pool: Optional[ConnectionPool] = None):
        self.redis_pool = redis_pool
        self.cache_enabled = redis_pool is not None
        self.local_cache = {}  # 本地缓存
        self.cache_stats = {
            'hits': 0,
            'misses': 0,
            'sets': 0,
            'deletes': 0
        }
    
    def get(self, key: str) -> Optional[Any]:
        """获取缓存数据"""
        # 先检查本地缓存
        if key in self.local_cache:
            item = self.local_cache[key]
            if time.time() < item['expires']:
                self.cache_stats['hits'] += 1
                return item['data']
            else:
                del self.local_cache[key]
        
        # 检查Redis缓存
        if self.cache_enabled:
            try:
                redis_client = redis.Redis(connection_pool=self.redis_pool)
                cached_data = redis_client.get(key)
                if cached_data:
                    data = json.loads(cached_data)
                    # 存储到本地缓存
                    self.local_cache[key] = {
                        'data': data,
                        'expires': time.time() + 300  # 5分钟本地缓存
                    }
                    self.cache_stats['hits'] += 1
                    return data
            except Exception as e:
                logger.warning(f"Redis缓存读取失败: {e}")
        
        self.cache_stats['misses'] += 1
        return None
    
    def set(self, key: str, data: Any, ttl: int = 3600):
        """设置缓存数据"""
        # 设置本地缓存
        self.local_cache[key] = {
            'data': data,
            'expires': time.time() + min(ttl, 300)  # 本地缓存最多5分钟
        }
        
        # 设置Redis缓存
        if self.cache_enabled:
            try:
                redis_client = redis.Redis(connection_pool=self.redis_pool)
                redis_client.setex(key, ttl, json.dumps(data, default=str))
                self.cache_stats['sets'] += 1
            except Exception as e:
                logger.warning(f"Redis缓存设置失败: {e}")
    
    def delete(self, key: str):
        """删除缓存"""
        # 删除本地缓存
        if key in self.local_cache:
            del self.local_cache[key]
        
        # 删除Redis缓存
        if self.cache_enabled:
            try:
                redis_client = redis.Redis(connection_pool=self.redis_pool)
                redis_client.delete(key)
                self.cache_stats['deletes'] += 1
            except Exception as e:
                logger.warning(f"Redis缓存删除失败: {e}")
    
    def delete_pattern(self, pattern: str):
        """按模式删除缓存"""
        if self.cache_enabled:
            try:
                redis_client = redis.Redis(connection_pool=self.redis_pool)
                keys = redis_client.keys(pattern)
                if keys:
                    redis_client.delete(*keys)
                    self.cache_stats['deletes'] += len(keys)
            except Exception as e:
                logger.warning(f"模式删除缓存失败: {e}")
    
    def clear(self):
        """清空所有缓存"""
        self.local_cache.clear()
        if self.cache_enabled:
            try:
                redis_client = redis.Redis(connection_pool=self.redis_pool)
                redis_client.flushdb()
            except Exception as e:
                logger.warning(f"清空缓存失败: {e}")
    
    def get_stats(self) -> Dict[str, Any]:
        """获取缓存统计"""
        total_requests = self.cache_stats['hits'] + self.cache_stats['misses']
        hit_rate = (self.cache_stats['hits'] / total_requests * 100) if total_requests > 0 else 0
        
        return {
            'cache_enabled': self.cache_enabled,
            'local_cache_size': len(self.local_cache),
            'hits': self.cache_stats['hits'],
            'misses': self.cache_stats['misses'],
            'hit_rate': hit_rate,
            'sets': self.cache_stats['sets'],
            'deletes': self.cache_stats['deletes']
        }

class CacheDecorator:
    """缓存装饰器"""
    
    def __init__(self, cache_manager: CacheManager):
        self.cache_manager = cache_manager
    
    def cache(self, ttl: int = 3600, key_prefix: str = ""):
        """缓存装饰器"""
        def decorator(func):
            @wraps(func)
            async def wrapper(*args, **kwargs):
                # 生成缓存键
                cache_key = self._generate_cache_key(func, args, kwargs, key_prefix)
                
                # 尝试从缓存获取
                cached_result = self.cache_manager.get(cache_key)
                if cached_result is not None:
                    logger.debug(f"缓存命中: {cache_key}")
                    return cached_result
                
                # 执行函数
                result = await func(*args, **kwargs)
                
                # 存储到缓存
                self.cache_manager.set(cache_key, result, ttl)
                logger.debug(f"缓存存储: {cache_key}")
                
                return result
            return wrapper
        return decorator
    
    def _generate_cache_key(self, func: Callable, args: tuple, kwargs: dict, prefix: str) -> str:
        """生成缓存键"""
        # 创建参数哈希
        params = str(args) + str(sorted(kwargs.items()))
        params_hash = hashlib.md5(params.encode()).hexdigest()
        
        # 组合缓存键
        key = f"{prefix}:{func.__name__}:{params_hash}"
        return key

class CacheWarmer:
    """缓存预热器"""
    
    def __init__(self, cache_manager: CacheManager):
        self.cache_manager = cache_manager
    
    async def warm_user_cache(self, user_ids: List[int]):
        """预热用户缓存"""
        for user_id in user_ids:
            cache_key = f"user:{user_id}"
            if not self.cache_manager.get(cache_key):
                # 这里应该从数据库加载用户数据
                # user_data = await load_user_from_db(user_id)
                # self.cache_manager.set(cache_key, user_data, 3600)
                pass
    
    async def warm_server_cache(self, server_ids: List[int]):
        """预热服务器缓存"""
        for server_id in server_ids:
            cache_key = f"server:{server_id}"
            if not self.cache_manager.get(cache_key):
                # 这里应该从数据库加载服务器数据
                # server_data = await load_server_from_db(server_id)
                # self.cache_manager.set(cache_key, server_data, 3600)
                pass
    
    async def warm_statistics_cache(self):
        """预热统计缓存"""
        stats_keys = [
            'user_count',
            'server_count',
            'client_count',
            'active_connections'
        ]
        
        for key in stats_keys:
            if not self.cache_manager.get(key):
                # 这里应该计算统计数据
                # stats = await calculate_statistics()
                # self.cache_manager.set(key, stats, 1800)  # 30分钟缓存
                pass

class CacheInvalidator:
    """缓存失效器"""
    
    def __init__(self, cache_manager: CacheManager):
        self.cache_manager = cache_manager
    
    def invalidate_user_cache(self, user_id: int):
        """使用户缓存失效"""
        patterns = [
            f"user:{user_id}",
            f"user_clients:{user_id}",
            f"user_stats:{user_id}"
        ]
        
        for pattern in patterns:
            self.cache_manager.delete(pattern)
    
    def invalidate_server_cache(self, server_id: int):
        """使服务器缓存失效"""
        patterns = [
            f"server:{server_id}",
            f"server_clients:{server_id}",
            f"server_stats:{server_id}"
        ]
        
        for pattern in patterns:
            self.cache_manager.delete(pattern)
    
    def invalidate_statistics_cache(self):
        """使统计缓存失效"""
        patterns = [
            "user_count",
            "server_count",
            "client_count",
            "active_connections",
            "system_stats"
        ]
        
        for pattern in patterns:
            self.cache_manager.delete(pattern)
    
    def invalidate_all_cache(self):
        """使所有缓存失效"""
        self.cache_manager.clear()

# 创建全局缓存管理器
cache_manager = CacheManager()
cache_decorator = CacheDecorator(cache_manager)
cache_warmer = CacheWarmer(cache_manager)
cache_invalidator = CacheInvalidator(cache_manager)
