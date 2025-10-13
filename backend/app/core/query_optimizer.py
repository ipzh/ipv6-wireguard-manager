"""
数据库查询优化器
"""
from typing import Any, Dict, List, Optional, Union
from sqlalchemy.orm import Query, Session
from sqlalchemy import text, func, desc, asc
import time
import logging
from datetime import datetime, timedelta

from .cache import cache_manager, cached, CacheKeys

logger = logging.getLogger(__name__)

class QueryOptimizer:
    """查询优化器"""
    
    def __init__(self, db_session: Session):
        self.db = db_session
        self.query_stats = {}
    
    def optimize_query(self, query: Query, use_cache: bool = True, cache_expire: int = 300) -> Query:
        """优化查询"""
        # 应用查询优化策略
        query = self._apply_optimizations(query)
        
        # 如果启用缓存，包装查询
        if use_cache:
            return self._cached_query(query, cache_expire)
        
        return query
    
    def _apply_optimizations(self, query: Query) -> Query:
        """应用查询优化策略"""
        # 1. 限制返回字段
        if hasattr(query, '_entities') and len(query._entities) > 10:
            # 如果查询字段过多，考虑是否需要优化
            logger.debug("查询字段较多，考虑优化字段选择")
        
        # 2. 添加索引提示（如果支持）
        # 这里可以添加数据库特定的索引提示
        
        # 3. 确保使用正确的排序
        if not query._order_by:
            # 如果没有排序，添加默认排序（通常是主键）
            # query = query.order_by(desc("id"))
            pass
        
        return query
    
    def _cached_query(self, query: Query, expire: int) -> Query:
        """缓存查询结果"""
        # 这里简化实现，实际应用中需要更复杂的缓存策略
        # 生成缓存键
        cache_key = f"query:{hash(str(query.statement))}"
        
        # 在实际应用中，这里应该实现完整的缓存逻辑
        # 目前返回原始查询
        return query
    
    def paginate(self, query: Query, page: int = 1, per_page: int = 20) -> Dict[str, Any]:
        """分页查询"""
        start_time = time.time()
        
        # 计算总数
        total = query.count()
        
        # 计算分页
        total_pages = (total + per_page - 1) // per_page
        offset = (page - 1) * per_page
        
        # 执行查询
        items = query.offset(offset).limit(per_page).all()
        
        # 记录查询统计
        execution_time = time.time() - start_time
        self._record_query_stat(query, execution_time)
        
        return {
            "items": items,
            "total": total,
            "page": page,
            "per_page": per_page,
            "total_pages": total_pages,
            "execution_time": execution_time
        }
    
    def _record_query_stat(self, query: Query, execution_time: float):
        """记录查询统计"""
        query_key = str(query.statement)[:100]  # 截取前100字符作为标识
        
        if query_key not in self.query_stats:
            self.query_stats[query_key] = {
                "count": 0,
                "total_time": 0,
                "avg_time": 0,
                "last_executed": None
            }
        
        stat = self.query_stats[query_key]
        stat["count"] += 1
        stat["total_time"] += execution_time
        stat["avg_time"] = stat["total_time"] / stat["count"]
        stat["last_executed"] = datetime.now()
    
    def get_query_stats(self) -> Dict[str, Any]:
        """获取查询统计"""
        return {
            "total_queries": len(self.query_stats),
            "slow_queries": {k: v for k, v in self.query_stats.items() if v["avg_time"] > 1.0},
            "stats": self.query_stats
        }

class PerformanceMonitor:
    """性能监控器"""
    
    def __init__(self):
        self.metrics = {
            "queries": [],
            "response_times": [],
            "cache_hits": 0,
            "cache_misses": 0
        }
        self.start_time = datetime.now()
    
    def record_query(self, query: str, execution_time: float):
        """记录查询性能"""
        self.metrics["queries"].append({
            "query": query[:200],  # 截取前200字符
            "execution_time": execution_time,
            "timestamp": datetime.now()
        })
        
        # 保持最近1000个查询记录
        if len(self.metrics["queries"]) > 1000:
            self.metrics["queries"] = self.metrics["queries"][-1000:]
    
    def record_response_time(self, endpoint: str, response_time: float):
        """记录响应时间"""
        self.metrics["response_times"].append({
            "endpoint": endpoint,
            "response_time": response_time,
            "timestamp": datetime.now()
        })
        
        # 保持最近1000个响应时间记录
        if len(self.metrics["response_times"]) > 1000:
            self.metrics["response_times"] = self.metrics["response_times"][-1000:]
    
    def record_cache_hit(self):
        """记录缓存命中"""
        self.metrics["cache_hits"] += 1
    
    def record_cache_miss(self):
        """记录缓存未命中"""
        self.metrics["cache_misses"] += 1
    
    def get_performance_report(self) -> Dict[str, Any]:
        """获取性能报告"""
        uptime = datetime.now() - self.start_time
        
        # 计算平均查询时间
        if self.metrics["queries"]:
            avg_query_time = sum(q["execution_time"] for q in self.metrics["queries"]) / len(self.metrics["queries"])
        else:
            avg_query_time = 0
        
        # 计算平均响应时间
        if self.metrics["response_times"]:
            avg_response_time = sum(r["response_time"] for r in self.metrics["response_times"]) / len(self.metrics["response_times"])
        else:
            avg_response_time = 0
        
        # 计算缓存命中率
        total_cache_operations = self.metrics["cache_hits"] + self.metrics["cache_misses"]
        if total_cache_operations > 0:
            cache_hit_rate = self.metrics["cache_hits"] / total_cache_operations
        else:
            cache_hit_rate = 0
        
        return {
            "uptime": str(uptime),
            "total_queries": len(self.metrics["queries"]),
            "average_query_time": avg_query_time,
            "average_response_time": avg_response_time,
            "cache_hit_rate": cache_hit_rate,
            "cache_hits": self.metrics["cache_hits"],
            "cache_misses": self.metrics["cache_misses"],
            "slow_queries": [q for q in self.metrics["queries"] if q["execution_time"] > 1.0][-10:],  # 最近10个慢查询
            "recent_response_times": self.metrics["response_times"][-10:]  # 最近10个响应时间
        }

# 全局性能监控器
performance_monitor = PerformanceMonitor()

# 查询优化装饰器
def optimize_query(use_cache: bool = True, cache_expire: int = 300):
    """查询优化装饰器"""
    def decorator(func):
        def wrapper(db: Session, *args, **kwargs):
            optimizer = QueryOptimizer(db)
            
            # 执行原始函数获取查询
            query = func(db, *args, **kwargs)
            
            # 优化查询
            optimized_query = optimizer.optimize_query(query, use_cache, cache_expire)
            
            return optimized_query
        
        return wrapper
    return decorator

# 性能监控装饰器
def monitor_performance(endpoint: str = "unknown"):
    """性能监控装饰器"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            start_time = time.time()
            
            try:
                result = await func(*args, **kwargs)
                
                # 记录响应时间
                response_time = time.time() - start_time
                performance_monitor.record_response_time(endpoint, response_time)
                
                # 如果响应时间过长，记录警告
                if response_time > 5.0:
                    logger.warning(f"慢响应检测: {endpoint} 耗时 {response_time:.2f}秒")
                
                return result
            except Exception as e:
                # 记录错误响应时间
                response_time = time.time() - start_time
                performance_monitor.record_response_time(f"{endpoint}_error", response_time)
                raise e
        
        return wrapper
    return decorator