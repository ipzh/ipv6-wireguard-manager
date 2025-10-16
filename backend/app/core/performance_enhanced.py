"""
增强的性能优化模块
实现数据库连接池优化、缓存机制、异步处理优化
"""
import asyncio
import time
import logging
from typing import Dict, Any, Optional, List, Union
from functools import wraps
from datetime import datetime, timedelta
import json
import pickle
from contextlib import asynccontextmanager

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import QueuePool, StaticPool
from sqlalchemy import event, text
import aioredis
from fastapi import Request, Response

from .config_enhanced import settings, PerformanceConfig

logger = logging.getLogger(__name__)

class DatabaseConnectionPool:
    """数据库连接池管理器"""
    
    def __init__(self, config: PerformanceConfig):
        self.config = config
        self.engine = None
        self.session_factory = None
        self._initialize_pool()
    
    def _initialize_pool(self):
        """初始化连接池"""
        try:
            # 创建异步引擎
            self.engine = create_async_engine(
                settings.DATABASE_URL.replace("mysql://", "mysql+aiomysql://"),
                poolclass=QueuePool,
                pool_size=self.config.DB_POOL_SIZE,
                max_overflow=self.config.DB_MAX_OVERFLOW,
                pool_timeout=self.config.DB_POOL_TIMEOUT,
                pool_recycle=self.config.DB_POOL_RECYCLE,
                pool_pre_ping=self.config.DB_POOL_PRE_PING,
                echo=settings.DEBUG,
                connect_args={
                    "connect_timeout": settings.DATABASE_CONNECT_TIMEOUT,
                    "charset": "utf8mb4",
                    "autocommit": False
                }
            )
            
            # 创建会话工厂
            self.session_factory = async_sessionmaker(
                bind=self.engine,
                class_=AsyncSession,
                expire_on_commit=False,
                autoflush=False,
                autocommit=False
            )
            
            # 添加连接池事件监听器
            self._setup_pool_events()
            
            logger.info(f"Database connection pool initialized with size {self.config.DB_POOL_SIZE}")
            
        except Exception as e:
            logger.error(f"Failed to initialize database connection pool: {e}")
            raise
    
    def _setup_pool_events(self):
        """设置连接池事件监听器"""
        
        @event.listens_for(self.engine.sync_engine, "connect")
        def set_sqlite_pragma(dbapi_connection, connection_record):
            """设置连接参数"""
            if "mysql" in str(dbapi_connection):
                with dbapi_connection.cursor() as cursor:
                    cursor.execute("SET SESSION sql_mode = 'STRICT_TRANS_TABLES'")
                    cursor.execute("SET SESSION time_zone = '+00:00'")
        
        @event.listens_for(self.engine.sync_engine, "checkout")
        def receive_checkout(dbapi_connection, connection_record, connection_proxy):
            """连接检出事件"""
            logger.debug("Connection checked out from pool")
        
        @event.listens_for(self.engine.sync_engine, "checkin")
        def receive_checkin(dbapi_connection, connection_record):
            """连接检入事件"""
            logger.debug("Connection checked in to pool")
    
    @asynccontextmanager
    async def get_session(self):
        """获取数据库会话"""
        async with self.session_factory() as session:
            try:
                yield session
            except Exception as e:
                await session.rollback()
                logger.error(f"Database session error: {e}")
                raise
            finally:
                await session.close()
    
    async def execute_query(self, query: str, params: Dict[str, Any] = None) -> List[Dict[str, Any]]:
        """执行查询"""
        async with self.get_session() as session:
            result = await session.execute(text(query), params or {})
            return [dict(row) for row in result]
    
    async def execute_update(self, query: str, params: Dict[str, Any] = None) -> int:
        """执行更新"""
        async with self.get_session() as session:
            result = await session.execute(text(query), params or {})
            await session.commit()
            return result.rowcount
    
    def get_pool_status(self) -> Dict[str, Any]:
        """获取连接池状态"""
        if not self.engine:
            return {"status": "not_initialized"}
        
        pool = self.engine.pool
        return {
            "status": "active",
            "size": pool.size(),
            "checked_in": pool.checkedin(),
            "checked_out": pool.checkedout(),
            "overflow": pool.overflow(),
            "invalid": pool.invalid()
        }
    
    async def close(self):
        """关闭连接池"""
        if self.engine:
            await self.engine.dispose()
            logger.info("Database connection pool closed")

class CacheManager:
    """缓存管理器"""
    
    def __init__(self, config: PerformanceConfig):
        self.config = config
        self.redis_client = None
        self.local_cache: Dict[str, Dict[str, Any]] = {}
        self._initialize_cache()
    
    def _initialize_cache(self):
        """初始化缓存"""
        if settings.USE_REDIS and settings.REDIS_URL:
            try:
                self.redis_client = aioredis.from_url(
                    settings.REDIS_URL,
                    max_connections=self.config.CACHE_MAX_SIZE,
                    decode_responses=True
                )
                logger.info("Redis cache initialized")
            except Exception as e:
                logger.warning(f"Failed to initialize Redis cache: {e}")
                self.redis_client = None
        
        if not self.redis_client:
            logger.info("Using local cache")
    
    async def get(self, key: str) -> Optional[Any]:
        """获取缓存值"""
        try:
            if self.redis_client:
                value = await self.redis_client.get(key)
                if value:
                    return json.loads(value)
            else:
                # 使用本地缓存
                if key in self.local_cache:
                    cache_data = self.local_cache[key]
                    if cache_data["expires"] > time.time():
                        return cache_data["value"]
                    else:
                        del self.local_cache[key]
            
            return None
        except Exception as e:
            logger.error(f"Cache get error: {e}")
            return None
    
    async def set(self, key: str, value: Any, ttl: int = None) -> bool:
        """设置缓存值"""
        try:
            ttl = ttl or self.config.CACHE_DEFAULT_TTL
            
            if self.redis_client:
                await self.redis_client.setex(key, ttl, json.dumps(value))
            else:
                # 使用本地缓存
                self.local_cache[key] = {
                    "value": value,
                    "expires": time.time() + ttl
                }
                
                # 清理过期缓存
                await self._cleanup_local_cache()
            
            return True
        except Exception as e:
            logger.error(f"Cache set error: {e}")
            return False
    
    async def delete(self, key: str) -> bool:
        """删除缓存值"""
        try:
            if self.redis_client:
                await self.redis_client.delete(key)
            else:
                self.local_cache.pop(key, None)
            
            return True
        except Exception as e:
            logger.error(f"Cache delete error: {e}")
            return False
    
    async def clear(self) -> bool:
        """清空缓存"""
        try:
            if self.redis_client:
                await self.redis_client.flushdb()
            else:
                self.local_cache.clear()
            
            return True
        except Exception as e:
            logger.error(f"Cache clear error: {e}")
            return False
    
    async def _cleanup_local_cache(self):
        """清理本地缓存"""
        current_time = time.time()
        expired_keys = [
            key for key, data in self.local_cache.items()
            if data["expires"] <= current_time
        ]
        
        for key in expired_keys:
            del self.local_cache[key]
    
    async def get_stats(self) -> Dict[str, Any]:
        """获取缓存统计"""
        if self.redis_client:
            info = await self.redis_client.info()
            return {
                "type": "redis",
                "connected_clients": info.get("connected_clients", 0),
                "used_memory": info.get("used_memory", 0),
                "keyspace_hits": info.get("keyspace_hits", 0),
                "keyspace_misses": info.get("keyspace_misses", 0)
            }
        else:
            return {
                "type": "local",
                "size": len(self.local_cache),
                "max_size": self.config.CACHE_MAX_SIZE
            }

class AsyncTaskManager:
    """异步任务管理器"""
    
    def __init__(self, config: PerformanceConfig):
        self.config = config
        self.task_queue = asyncio.Queue(maxsize=config.ASYNC_QUEUE_SIZE)
        self.workers = []
        self.running = False
    
    async def start(self):
        """启动任务管理器"""
        if self.running:
            return
        
        self.running = True
        
        # 启动工作线程
        for i in range(self.config.ASYNC_WORKERS):
            worker = asyncio.create_task(self._worker(f"worker-{i}"))
            self.workers.append(worker)
        
        logger.info(f"Async task manager started with {self.config.ASYNC_WORKERS} workers")
    
    async def stop(self):
        """停止任务管理器"""
        if not self.running:
            return
        
        self.running = False
        
        # 等待所有任务完成
        await self.task_queue.join()
        
        # 取消所有工作线程
        for worker in self.workers:
            worker.cancel()
        
        await asyncio.gather(*self.workers, return_exceptions=True)
        self.workers.clear()
        
        logger.info("Async task manager stopped")
    
    async def _worker(self, worker_name: str):
        """工作线程"""
        while self.running:
            try:
                # 获取任务
                task = await asyncio.wait_for(
                    self.task_queue.get(),
                    timeout=1.0
                )
                
                # 执行任务
                await self._execute_task(task)
                
                # 标记任务完成
                self.task_queue.task_done()
                
            except asyncio.TimeoutError:
                continue
            except Exception as e:
                logger.error(f"Worker {worker_name} error: {e}")
    
    async def _execute_task(self, task: Dict[str, Any]):
        """执行任务"""
        try:
            task_type = task.get("type")
            task_data = task.get("data", {})
            
            if task_type == "email":
                await self._send_email(task_data)
            elif task_type == "backup":
                await self._create_backup(task_data)
            elif task_type == "cleanup":
                await self._cleanup_data(task_data)
            else:
                logger.warning(f"Unknown task type: {task_type}")
                
        except Exception as e:
            logger.error(f"Task execution error: {e}")
    
    async def _send_email(self, data: Dict[str, Any]):
        """发送邮件任务"""
        # 实现邮件发送逻辑
        logger.info(f"Sending email: {data}")
    
    async def _create_backup(self, data: Dict[str, Any]):
        """创建备份任务"""
        # 实现备份逻辑
        logger.info(f"Creating backup: {data}")
    
    async def _cleanup_data(self, data: Dict[str, Any]):
        """清理数据任务"""
        # 实现数据清理逻辑
        logger.info(f"Cleaning up data: {data}")
    
    async def add_task(self, task_type: str, data: Dict[str, Any] = None) -> bool:
        """添加任务"""
        try:
            task = {
                "type": task_type,
                "data": data or {},
                "created_at": datetime.utcnow().isoformat()
            }
            
            await self.task_queue.put(task)
            return True
            
        except asyncio.QueueFull:
            logger.error("Task queue is full")
            return False
        except Exception as e:
            logger.error(f"Failed to add task: {e}")
            return False
    
    def get_queue_status(self) -> Dict[str, Any]:
        """获取队列状态"""
        return {
            "running": self.running,
            "queue_size": self.task_queue.qsize(),
            "max_size": self.config.ASYNC_QUEUE_SIZE,
            "workers": len(self.workers)
        }

class PerformanceMonitor:
    """性能监控器"""
    
    def __init__(self):
        self.metrics: Dict[str, List[float]] = {}
        self.start_time = time.time()
    
    def record_metric(self, name: str, value: float):
        """记录性能指标"""
        if name not in self.metrics:
            self.metrics[name] = []
        
        self.metrics[name].append(value)
        
        # 保持最近1000个记录
        if len(self.metrics[name]) > 1000:
            self.metrics[name] = self.metrics[name][-1000:]
    
    def get_metric_stats(self, name: str) -> Dict[str, float]:
        """获取指标统计"""
        if name not in self.metrics or not self.metrics[name]:
            return {}
        
        values = self.metrics[name]
        return {
            "count": len(values),
            "min": min(values),
            "max": max(values),
            "avg": sum(values) / len(values),
            "latest": values[-1]
        }
    
    def get_all_stats(self) -> Dict[str, Dict[str, float]]:
        """获取所有指标统计"""
        return {name: self.get_metric_stats(name) for name in self.metrics}
    
    def get_uptime(self) -> float:
        """获取运行时间"""
        return time.time() - self.start_time

class PerformanceManager:
    """性能管理器"""
    
    def __init__(self):
        self.config = settings.get_performance_config()
        self.db_pool = DatabaseConnectionPool(self.config)
        self.cache_manager = CacheManager(self.config)
        self.task_manager = AsyncTaskManager(self.config)
        self.monitor = PerformanceMonitor()
    
    async def start(self):
        """启动性能管理器"""
        await self.task_manager.start()
        logger.info("Performance manager started")
    
    async def stop(self):
        """停止性能管理器"""
        await self.task_manager.stop()
        await self.db_pool.close()
        logger.info("Performance manager stopped")
    
    def get_status(self) -> Dict[str, Any]:
        """获取性能状态"""
        return {
            "database_pool": self.db_pool.get_pool_status(),
            "cache": self.cache_manager.get_stats(),
            "task_queue": self.task_manager.get_queue_status(),
            "metrics": self.monitor.get_all_stats(),
            "uptime": self.monitor.get_uptime()
        }

# 创建全局性能管理器实例
performance_manager = PerformanceManager()

# 装饰器
def monitor_performance(func):
    """性能监控装饰器"""
    @wraps(func)
    async def wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            result = await func(*args, **kwargs)
            execution_time = time.time() - start_time
            performance_manager.monitor.record_metric(f"{func.__name__}_execution_time", execution_time)
            return result
        except Exception as e:
            execution_time = time.time() - start_time
            performance_manager.monitor.record_metric(f"{func.__name__}_error_time", execution_time)
            raise
    return wrapper

def cache_result(ttl: int = 300):
    """缓存结果装饰器"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # 生成缓存键
            cache_key = f"{func.__name__}:{hash(str(args) + str(kwargs))}"
            
            # 尝试从缓存获取
            cached_result = await performance_manager.cache_manager.get(cache_key)
            if cached_result is not None:
                return cached_result
            
            # 执行函数
            result = await func(*args, **kwargs)
            
            # 缓存结果
            await performance_manager.cache_manager.set(cache_key, result, ttl)
            
            return result
        return wrapper
    return decorator

def async_task(task_type: str):
    """异步任务装饰器"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # 执行函数
            result = await func(*args, **kwargs)
            
            # 添加异步任务
            await performance_manager.task_manager.add_task(task_type, {
                "function": func.__name__,
                "args": str(args),
                "kwargs": str(kwargs),
                "result": str(result)
            })
            
            return result
        return wrapper
    return decorator

# 导出
__all__ = [
    "PerformanceManager",
    "DatabaseConnectionPool",
    "CacheManager", 
    "AsyncTaskManager",
    "PerformanceMonitor",
    "performance_manager",
    "monitor_performance",
    "cache_result",
    "async_task"
]
