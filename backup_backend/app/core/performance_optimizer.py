"""
性能优化器
提供数据库查询优化、缓存策略、异步处理等性能优化功能
"""
import asyncio
import time
import logging
from typing import Dict, Any, List, Optional, Callable
from functools import wraps
from dataclasses import dataclass
from datetime import datetime, timedelta
import psutil
import gc

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import redis.asyncio as redis

logger = logging.getLogger(__name__)

@dataclass
class PerformanceMetrics:
    """性能指标"""
    cpu_usage: float
    memory_usage: float
    disk_io: Dict[str, float]
    network_io: Dict[str, float]
    database_connections: int
    cache_hit_rate: float
    response_time: float
    timestamp: datetime

class QueryOptimizer:
    """数据库查询优化器"""
    
    def __init__(self, db_session: AsyncSession):
        self.db_session = db_session
        self.query_cache = {}
        self.slow_queries = []
    
    async def optimize_query(self, query: str, params: Dict = None) -> Any:
        """优化查询执行"""
        start_time = time.time()
        
        try:
            # 查询缓存检查
            cache_key = f"{query}:{hash(str(params))}"
            if cache_key in self.query_cache:
                logger.debug(f"查询缓存命中: {cache_key}")
                return self.query_cache[cache_key]
            
            # 执行查询
            result = await self.db_session.execute(text(query), params or {})
            data = result.fetchall()
            
            # 记录慢查询
            execution_time = time.time() - start_time
            if execution_time > 1.0:  # 超过1秒的查询
                self.slow_queries.append({
                    'query': query,
                    'params': params,
                    'execution_time': execution_time,
                    'timestamp': datetime.now()
                })
                logger.warning(f"慢查询检测: {execution_time:.2f}s - {query}")
            
            # 缓存结果（仅缓存小结果集）
            if len(data) < 100:
                self.query_cache[cache_key] = data
            
            return data
            
        except Exception as e:
            logger.error(f"查询执行失败: {e}")
            raise
    
    async def get_slow_queries(self) -> List[Dict]:
        """获取慢查询列表"""
        return self.slow_queries
    
    async def clear_query_cache(self):
        """清理查询缓存"""
        self.query_cache.clear()
        logger.info("查询缓存已清理")

class CacheManager:
    """缓存管理器"""
    
    def __init__(self, redis_client: redis.Redis = None):
        self.redis_client = redis_client
        self.local_cache = {}
        self.cache_stats = {
            'hits': 0,
            'misses': 0,
            'sets': 0,
            'deletes': 0
        }
    
    async def get(self, key: str, default: Any = None) -> Any:
        """获取缓存值"""
        try:
            # 先检查本地缓存
            if key in self.local_cache:
                self.cache_stats['hits'] += 1
                return self.local_cache[key]
            
            # 检查Redis缓存
            if self.redis_client:
                value = await self.redis_client.get(key)
                if value:
                    self.cache_stats['hits'] += 1
                    # 同时更新本地缓存
                    self.local_cache[key] = value
                    return value
            
            self.cache_stats['misses'] += 1
            return default
            
        except Exception as e:
            logger.error(f"缓存获取失败: {e}")
            return default
    
    async def set(self, key: str, value: Any, ttl: int = 300) -> bool:
        """设置缓存值"""
        try:
            # 设置本地缓存
            self.local_cache[key] = value
            self.cache_stats['sets'] += 1
            
            # 设置Redis缓存
            if self.redis_client:
                await self.redis_client.setex(key, ttl, value)
            
            return True
            
        except Exception as e:
            logger.error(f"缓存设置失败: {e}")
            return False
    
    async def delete(self, key: str) -> bool:
        """删除缓存值"""
        try:
            # 删除本地缓存
            if key in self.local_cache:
                del self.local_cache[key]
            
            # 删除Redis缓存
            if self.redis_client:
                await self.redis_client.delete(key)
            
            self.cache_stats['deletes'] += 1
            return True
            
        except Exception as e:
            logger.error(f"缓存删除失败: {e}")
            return False
    
    def get_cache_stats(self) -> Dict[str, Any]:
        """获取缓存统计信息"""
        total_requests = self.cache_stats['hits'] + self.cache_stats['misses']
        hit_rate = (self.cache_stats['hits'] / total_requests * 100) if total_requests > 0 else 0
        
        return {
            'hits': self.cache_stats['hits'],
            'misses': self.cache_stats['misses'],
            'sets': self.cache_stats['sets'],
            'deletes': self.cache_stats['deletes'],
            'hit_rate': round(hit_rate, 2),
            'local_cache_size': len(self.local_cache)
        }
    
    async def clear_cache(self):
        """清理所有缓存"""
        self.local_cache.clear()
        if self.redis_client:
            await self.redis_client.flushdb()
        logger.info("缓存已清理")

class AsyncTaskManager:
    """异步任务管理器"""
    
    def __init__(self, max_workers: int = 10):
        self.max_workers = max_workers
        self.task_queue = asyncio.Queue()
        self.workers = []
        self.running_tasks = {}
        self.completed_tasks = {}
        self.failed_tasks = {}
    
    async def start(self):
        """启动任务管理器"""
        for i in range(self.max_workers):
            worker = asyncio.create_task(self._worker(f"worker-{i}"))
            self.workers.append(worker)
        logger.info(f"异步任务管理器已启动，工作线程数: {self.max_workers}")
    
    async def stop(self):
        """停止任务管理器"""
        # 停止所有工作线程
        for worker in self.workers:
            worker.cancel()
        
        # 等待所有任务完成
        await asyncio.gather(*self.workers, return_exceptions=True)
        logger.info("异步任务管理器已停止")
    
    async def _worker(self, worker_name: str):
        """工作线程"""
        while True:
            try:
                task = await self.task_queue.get()
                task_id = task.get('id')
                task_func = task.get('func')
                task_args = task.get('args', ())
                task_kwargs = task.get('kwargs', {})
                
                self.running_tasks[task_id] = {
                    'worker': worker_name,
                    'start_time': datetime.now(),
                    'status': 'running'
                }
                
                try:
                    result = await task_func(*task_args, **task_kwargs)
                    self.completed_tasks[task_id] = {
                        'result': result,
                        'completed_at': datetime.now(),
                        'status': 'completed'
                    }
                    logger.debug(f"任务 {task_id} 完成")
                    
                except Exception as e:
                    self.failed_tasks[task_id] = {
                        'error': str(e),
                        'failed_at': datetime.now(),
                        'status': 'failed'
                    }
                    logger.error(f"任务 {task_id} 失败: {e}")
                
                finally:
                    if task_id in self.running_tasks:
                        del self.running_tasks[task_id]
                    self.task_queue.task_done()
                    
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"工作线程 {worker_name} 错误: {e}")
    
    async def submit_task(self, task_id: str, func: Callable, *args, **kwargs) -> bool:
        """提交任务"""
        try:
            task = {
                'id': task_id,
                'func': func,
                'args': args,
                'kwargs': kwargs
            }
            await self.task_queue.put(task)
            logger.debug(f"任务 {task_id} 已提交")
            return True
        except Exception as e:
            logger.error(f"任务提交失败: {e}")
            return False
    
    async def get_task_status(self, task_id: str) -> Dict[str, Any]:
        """获取任务状态"""
        if task_id in self.running_tasks:
            return self.running_tasks[task_id]
        elif task_id in self.completed_tasks:
            return self.completed_tasks[task_id]
        elif task_id in self.failed_tasks:
            return self.failed_tasks[task_id]
        else:
            return {'status': 'not_found'}
    
    def get_task_stats(self) -> Dict[str, Any]:
        """获取任务统计信息"""
        return {
            'running_tasks': len(self.running_tasks),
            'completed_tasks': len(self.completed_tasks),
            'failed_tasks': len(self.failed_tasks),
            'queue_size': self.task_queue.qsize(),
            'workers': len(self.workers)
        }

class PerformanceMonitor:
    """性能监控器"""
    
    def __init__(self):
        self.metrics_history = []
        self.max_history = 1000
    
    async def collect_metrics(self) -> PerformanceMetrics:
        """收集性能指标"""
        try:
            # CPU使用率
            cpu_usage = psutil.cpu_percent(interval=1)
            
            # 内存使用率
            memory = psutil.virtual_memory()
            memory_usage = memory.percent
            
            # 磁盘IO
            disk_io = psutil.disk_io_counters()
            disk_io_dict = {
                'read_bytes': disk_io.read_bytes if disk_io else 0,
                'write_bytes': disk_io.write_bytes if disk_io else 0,
                'read_count': disk_io.read_count if disk_io else 0,
                'write_count': disk_io.write_count if disk_io else 0
            }
            
            # 网络IO
            network_io = psutil.net_io_counters()
            network_io_dict = {
                'bytes_sent': network_io.bytes_sent,
                'bytes_recv': network_io.bytes_recv,
                'packets_sent': network_io.packets_sent,
                'packets_recv': network_io.packets_recv
            }
            
            metrics = PerformanceMetrics(
                cpu_usage=cpu_usage,
                memory_usage=memory_usage,
                disk_io=disk_io_dict,
                network_io=network_io_dict,
                database_connections=0,  # 需要从数据库连接池获取
                cache_hit_rate=0,  # 需要从缓存管理器获取
                response_time=0,  # 需要从请求处理中获取
                timestamp=datetime.now()
            )
            
            # 保存到历史记录
            self.metrics_history.append(metrics)
            if len(self.metrics_history) > self.max_history:
                self.metrics_history.pop(0)
            
            return metrics
            
        except Exception as e:
            logger.error(f"性能指标收集失败: {e}")
            return None
    
    def get_metrics_history(self, hours: int = 24) -> List[PerformanceMetrics]:
        """获取历史性能指标"""
        cutoff_time = datetime.now() - timedelta(hours=hours)
        return [m for m in self.metrics_history if m.timestamp >= cutoff_time]
    
    def get_average_metrics(self, hours: int = 1) -> Dict[str, float]:
        """获取平均性能指标"""
        metrics = self.get_metrics_history(hours)
        if not metrics:
            return {}
        
        return {
            'avg_cpu_usage': sum(m.cpu_usage for m in metrics) / len(metrics),
            'avg_memory_usage': sum(m.memory_usage for m in metrics) / len(metrics),
            'avg_response_time': sum(m.response_time for m in metrics) / len(metrics),
            'avg_cache_hit_rate': sum(m.cache_hit_rate for m in metrics) / len(metrics)
        }

def performance_timer(func):
    """性能计时装饰器"""
    @wraps(func)
    async def wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            result = await func(*args, **kwargs)
            execution_time = time.time() - start_time
            logger.debug(f"{func.__name__} 执行时间: {execution_time:.3f}s")
            return result
        except Exception as e:
            execution_time = time.time() - start_time
            logger.error(f"{func.__name__} 执行失败，耗时: {execution_time:.3f}s, 错误: {e}")
            raise
    return wrapper

def cache_result(ttl: int = 300, key_prefix: str = ""):
    """缓存结果装饰器"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # 生成缓存键
            cache_key = f"{key_prefix}{func.__name__}:{hash(str(args) + str(kwargs))}"
            
            # 尝试从缓存获取
            cache_manager = getattr(wrapper, '_cache_manager', None)
            if cache_manager:
                cached_result = await cache_manager.get(cache_key)
                if cached_result is not None:
                    logger.debug(f"缓存命中: {cache_key}")
                    return cached_result
            
            # 执行函数
            result = await func(*args, **kwargs)
            
            # 缓存结果
            if cache_manager:
                await cache_manager.set(cache_key, result, ttl)
                logger.debug(f"结果已缓存: {cache_key}")
            
            return result
        return wrapper
    return decorator

class PerformanceOptimizer:
    """性能优化器主类"""
    
    def __init__(self, db_session: AsyncSession = None, redis_client: redis.Redis = None):
        self.db_session = db_session
        self.redis_client = redis_client
        
        # 初始化组件
        self.query_optimizer = QueryOptimizer(db_session) if db_session else None
        self.cache_manager = CacheManager(redis_client)
        self.task_manager = AsyncTaskManager()
        self.performance_monitor = PerformanceMonitor()
        
        # 性能配置
        self.config = {
            'enable_query_cache': True,
            'enable_result_cache': True,
            'enable_async_tasks': True,
            'enable_performance_monitoring': True,
            'cache_ttl': 300,
            'max_workers': 10,
            'slow_query_threshold': 1.0
        }
    
    async def start(self):
        """启动性能优化器"""
        if self.config['enable_async_tasks']:
            await self.task_manager.start()
        
        if self.config['enable_performance_monitoring']:
            # 启动性能监控任务
            await self.task_manager.submit_task(
                'performance_monitor',
                self._performance_monitoring_loop
            )
        
        logger.info("性能优化器已启动")
    
    async def stop(self):
        """停止性能优化器"""
        if self.config['enable_async_tasks']:
            await self.task_manager.stop()
        
        logger.info("性能优化器已停止")
    
    async def _performance_monitoring_loop(self):
        """性能监控循环"""
        while True:
            try:
                await self.performance_monitor.collect_metrics()
                await asyncio.sleep(30)  # 每30秒收集一次
            except Exception as e:
                logger.error(f"性能监控错误: {e}")
                await asyncio.sleep(60)  # 错误时等待更长时间
    
    async def optimize_database_query(self, query: str, params: Dict = None) -> Any:
        """优化数据库查询"""
        if not self.query_optimizer:
            raise ValueError("数据库会话未配置")
        
        return await self.query_optimizer.optimize_query(query, params)
    
    async def get_cached_data(self, key: str, default: Any = None) -> Any:
        """获取缓存数据"""
        return await self.cache_manager.get(key, default)
    
    async def set_cached_data(self, key: str, value: Any, ttl: int = None) -> bool:
        """设置缓存数据"""
        ttl = ttl or self.config['cache_ttl']
        return await self.cache_manager.set(key, value, ttl)
    
    async def submit_async_task(self, task_id: str, func: Callable, *args, **kwargs) -> bool:
        """提交异步任务"""
        if not self.config['enable_async_tasks']:
            return False
        
        return await self.task_manager.submit_task(task_id, func, *args, **kwargs)
    
    async def get_performance_metrics(self) -> PerformanceMetrics:
        """获取性能指标"""
        return await self.performance_monitor.collect_metrics()
    
    async def get_performance_summary(self) -> Dict[str, Any]:
        """获取性能摘要"""
        metrics = await self.get_performance_metrics()
        cache_stats = self.cache_manager.get_cache_stats()
        task_stats = self.task_manager.get_task_stats()
        
        return {
            'system_metrics': {
                'cpu_usage': metrics.cpu_usage,
                'memory_usage': metrics.memory_usage,
                'disk_io': metrics.disk_io,
                'network_io': metrics.network_io
            },
            'application_metrics': {
                'database_connections': metrics.database_connections,
                'cache_hit_rate': cache_stats['hit_rate'],
                'response_time': metrics.response_time
            },
            'cache_stats': cache_stats,
            'task_stats': task_stats,
            'timestamp': metrics.timestamp
        }
    
    async def cleanup(self):
        """清理资源"""
        # 清理查询缓存
        if self.query_optimizer:
            await self.query_optimizer.clear_query_cache()
        
        # 清理应用缓存
        await self.cache_manager.clear_cache()
        
        # 垃圾回收
        gc.collect()
        
        logger.info("性能优化器资源清理完成")

# 全局性能优化器实例
performance_optimizer: Optional[PerformanceOptimizer] = None

async def get_performance_optimizer() -> PerformanceOptimizer:
    """获取性能优化器实例"""
    global performance_optimizer
    if performance_optimizer is None:
        raise ValueError("性能优化器未初始化")
    return performance_optimizer

async def init_performance_optimizer(db_session: AsyncSession = None, redis_client: redis.Redis = None):
    """初始化性能优化器"""
    global performance_optimizer
    performance_optimizer = PerformanceOptimizer(db_session, redis_client)
    await performance_optimizer.start()
    logger.info("性能优化器初始化完成")

async def shutdown_performance_optimizer():
    """关闭性能优化器"""
    global performance_optimizer
    if performance_optimizer:
        await performance_optimizer.stop()
        await performance_optimizer.cleanup()
        performance_optimizer = None
    logger.info("性能优化器已关闭")
