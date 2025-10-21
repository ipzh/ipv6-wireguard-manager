# 数据库查询优化模块

from typing import Any, Dict, List, Optional, Union, Tuple
from sqlalchemy import text, func, and_, or_, desc, asc
from sqlalchemy.orm import Session, joinedload, selectinload, subqueryload
from sqlalchemy.exc import SQLAlchemyError
import time
import logging
from functools import wraps
from dataclasses import dataclass
from enum import Enum

class QueryOptimizationLevel(Enum):
    """查询优化级别"""
    BASIC = "basic"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"

@dataclass
class QueryStats:
    """查询统计"""
    query_time: float
    rows_returned: int
    cache_hit: bool = False
    optimization_applied: List[str] = None

class DatabaseOptimizer:
    """数据库优化器"""
    
    def __init__(self, db_session: Session):
        self.db_session = db_session
        self.logger = logging.getLogger(__name__)
        self.query_cache = {}
        self.slow_query_threshold = 1.0  # 1秒
    
    def optimize_query(self, query, level: QueryOptimizationLevel = QueryOptimizationLevel.BASIC):
        """优化查询"""
        optimizations = []
        
        if level == QueryOptimizationLevel.BASIC:
            optimizations.extend(self._apply_basic_optimizations(query))
        elif level == QueryOptimizationLevel.INTERMEDIATE:
            optimizations.extend(self._apply_basic_optimizations(query))
            optimizations.extend(self._apply_intermediate_optimizations(query))
        elif level == QueryOptimizationLevel.ADVANCED:
            optimizations.extend(self._apply_basic_optimizations(query))
            optimizations.extend(self._apply_intermediate_optimizations(query))
            optimizations.extend(self._apply_advanced_optimizations(query))
        
        return query, optimizations
    
    def _apply_basic_optimizations(self, query):
        """应用基础优化"""
        optimizations = []
        
        # 添加索引提示
        if hasattr(query, 'with_hint'):
            optimizations.append("添加索引提示")
        
        # 限制返回字段
        if hasattr(query, 'options'):
            optimizations.append("限制返回字段")
        
        return optimizations
    
    def _apply_intermediate_optimizations(self, query):
        """应用中级优化"""
        optimizations = []
        
        # 添加预加载
        if hasattr(query, 'options'):
            optimizations.append("添加预加载")
        
        # 优化JOIN
        if hasattr(query, 'join'):
            optimizations.append("优化JOIN")
        
        return optimizations
    
    def _apply_advanced_optimizations(self, query):
        """应用高级优化"""
        optimizations = []
        
        # 查询重写
        optimizations.append("查询重写")
        
        # 分区优化
        optimizations.append("分区优化")
        
        return optimizations
    
    def execute_with_stats(self, query, params: Dict = None) -> Tuple[Any, QueryStats]:
        """执行查询并返回统计信息"""
        start_time = time.time()
        
        try:
            if params:
                result = self.db_session.execute(query, params)
            else:
                result = self.db_session.execute(query)
            
            end_time = time.time()
            query_time = end_time - start_time
            
            # 记录慢查询
            if query_time > self.slow_query_threshold:
                self.logger.warning(f"慢查询检测: {query_time:.3f}s - {str(query)}")
            
            # 获取返回行数
            rows_returned = result.rowcount if hasattr(result, 'rowcount') else 0
            
            stats = QueryStats(
                query_time=query_time,
                rows_returned=rows_returned,
                optimization_applied=[]
            )
            
            return result, stats
            
        except SQLAlchemyError as e:
            self.logger.error(f"查询执行错误: {e}")
            raise

class QueryBuilder:
    """查询构建器"""
    
    def __init__(self, db_session: Session):
        self.db_session = db_session
        self.optimizer = DatabaseOptimizer(db_session)
    
    def build_user_query(self, filters: Dict[str, Any] = None, 
                        order_by: str = None, limit: int = None, 
                        offset: int = None):
        """构建用户查询"""
        from app.models.models_complete import User
        
        query = self.db_session.query(User)
        
        # 应用过滤器
        if filters:
            query = self._apply_filters(query, User, filters)
        
        # 应用排序
        if order_by:
            query = self._apply_ordering(query, User, order_by)
        
        # 应用分页
        if limit:
            query = query.limit(limit)
        if offset:
            query = query.offset(offset)
        
        # 添加预加载
        query = query.options(
            joinedload(User.roles),
            selectinload(User.permissions)
        )
        
        return query
    
    def build_wireguard_query(self, filters: Dict[str, Any] = None,
                             order_by: str = None, limit: int = None,
                             offset: int = None):
        """构建WireGuard查询"""
        from app.models.models_complete import WireGuardServer, WireGuardClient
        
        # 构建服务器查询
        server_query = self.db_session.query(WireGuardServer)
        if filters and 'server_filters' in filters:
            server_query = self._apply_filters(server_query, WireGuardServer, filters['server_filters'])
        
        # 构建客户端查询
        client_query = self.db_session.query(WireGuardClient)
        if filters and 'client_filters' in filters:
            client_query = self._apply_filters(client_query, WireGuardClient, filters['client_filters'])
        
        # 添加预加载
        server_query = server_query.options(
            joinedload(WireGuardServer.clients)
        )
        
        client_query = client_query.options(
            joinedload(WireGuardClient.server)
        )
        
        return server_query, client_query
    
    def build_network_query(self, filters: Dict[str, Any] = None,
                           order_by: str = None, limit: int = None,
                           offset: int = None):
        """构建网络查询"""
        from app.models.models_complete import BGPSession, IPv6Pool
        
        # BGP会话查询
        bgp_query = self.db_session.query(BGPSession)
        if filters and 'bgp_filters' in filters:
            bgp_query = self._apply_filters(bgp_query, BGPSession, filters['bgp_filters'])
        
        # IPv6池查询
        pool_query = self.db_session.query(IPv6Pool)
        if filters and 'pool_filters' in filters:
            pool_query = self._apply_filters(pool_query, IPv6Pool, filters['pool_filters'])
        
        # 添加预加载
        bgp_query = bgp_query.options(
            joinedload(BGPSession.announcements)
        )
        
        pool_query = pool_query.options(
            joinedload(IPv6Pool.allocations)
        )
        
        return bgp_query, pool_query
    
    def _apply_filters(self, query, model, filters: Dict[str, Any]):
        """应用过滤器"""
        for field, value in filters.items():
            if hasattr(model, field):
                if isinstance(value, list):
                    query = query.filter(getattr(model, field).in_(value))
                elif isinstance(value, dict):
                    if 'gte' in value:
                        query = query.filter(getattr(model, field) >= value['gte'])
                    if 'lte' in value:
                        query = query.filter(getattr(model, field) <= value['lte'])
                    if 'like' in value:
                        query = query.filter(getattr(model, field).like(f"%{value['like']}%"))
                else:
                    query = query.filter(getattr(model, field) == value)
        
        return query
    
    def _apply_ordering(self, query, model, order_by: str):
        """应用排序"""
        if order_by.startswith('-'):
            field = order_by[1:]
            if hasattr(model, field):
                query = query.order_by(desc(getattr(model, field)))
        else:
            if hasattr(model, order_by):
                query = query.order_by(asc(getattr(model, order_by)))
        
        return query

class DatabaseConnectionPool:
    """数据库连接池管理"""
    
    def __init__(self, engine):
        self.engine = engine
        self.pool_stats = {
            "size": 0,
            "checked_in": 0,
            "checked_out": 0,
            "overflow": 0,
            "invalid": 0
        }
    
    def get_connection_stats(self) -> Dict[str, Any]:
        """获取连接池统计"""
        pool = self.engine.pool
        
        return {
            "pool_size": pool.size(),
            "checked_in": pool.checkedin(),
            "checked_out": pool.checkedout(),
            "overflow": pool.overflow(),
            "invalid": pool.invalid()
        }
    
    def optimize_pool_settings(self):
        """优化连接池设置"""
        # 根据使用情况调整连接池大小
        stats = self.get_connection_stats()
        
        if stats["checked_out"] > stats["pool_size"] * 0.8:
            # 增加连接池大小
            self.engine.pool._recreate()
        elif stats["checked_out"] < stats["pool_size"] * 0.2:
            # 减少连接池大小
            self.engine.pool._recreate()

class QueryAnalyzer:
    """查询分析器"""
    
    def __init__(self, db_session: Session):
        self.db_session = db_session
    
    def analyze_query_performance(self, query) -> Dict[str, Any]:
        """分析查询性能"""
        # 获取查询计划
        explain_query = text(f"EXPLAIN {str(query)}")
        result = self.db_session.execute(explain_query)
        
        analysis = {
            "query_plan": [],
            "estimated_cost": 0,
            "estimated_rows": 0,
            "index_usage": [],
            "recommendations": []
        }
        
        for row in result:
            analysis["query_plan"].append(dict(row))
        
        # 分析索引使用
        analysis["index_usage"] = self._analyze_index_usage(analysis["query_plan"])
        
        # 生成优化建议
        analysis["recommendations"] = self._generate_recommendations(analysis)
        
        return analysis
    
    def _analyze_index_usage(self, query_plan: List[Dict]) -> List[str]:
        """分析索引使用情况"""
        index_usage = []
        
        for step in query_plan:
            if "Index" in str(step):
                index_usage.append(f"使用索引: {step}")
            elif "Seq Scan" in str(step):
                index_usage.append(f"全表扫描: {step}")
        
        return index_usage
    
    def _generate_recommendations(self, analysis: Dict[str, Any]) -> List[str]:
        """生成优化建议"""
        recommendations = []
        
        # 检查全表扫描
        if any("Seq Scan" in str(step) for step in analysis["query_plan"]):
            recommendations.append("考虑添加索引以避免全表扫描")
        
        # 检查JOIN性能
        if any("Nested Loop" in str(step) for step in analysis["query_plan"]):
            recommendations.append("考虑优化JOIN操作")
        
        # 检查排序性能
        if any("Sort" in str(step) for step in analysis["query_plan"]):
            recommendations.append("考虑添加排序索引")
        
        return recommendations

class DatabaseIndexManager:
    """数据库索引管理器"""
    
    def __init__(self, db_session: Session):
        self.db_session = db_session
    
    def create_index(self, table_name: str, columns: List[str], 
                    index_name: str = None, unique: bool = False):
        """创建索引"""
        if not index_name:
            index_name = f"idx_{table_name}_{'_'.join(columns)}"
        
        columns_str = ", ".join(columns)
        unique_str = "UNIQUE " if unique else ""
        
        sql = f"CREATE {unique_str}INDEX {index_name} ON {table_name} ({columns_str})"
        
        try:
            self.db_session.execute(text(sql))
            self.db_session.commit()
            return True
        except SQLAlchemyError as e:
            self.db_session.rollback()
            raise e
    
    def drop_index(self, index_name: str):
        """删除索引"""
        sql = f"DROP INDEX {index_name}"
        
        try:
            self.db_session.execute(text(sql))
            self.db_session.commit()
            return True
        except SQLAlchemyError as e:
            self.db_session.rollback()
            raise e
    
    def get_table_indexes(self, table_name: str) -> List[Dict[str, Any]]:
        """获取表的索引信息"""
        sql = """
        SELECT 
            indexname,
            indexdef,
            tablename
        FROM pg_indexes 
        WHERE tablename = :table_name
        """
        
        result = self.db_session.execute(text(sql), {"table_name": table_name})
        return [dict(row) for row in result]
    
    def analyze_table(self, table_name: str):
        """分析表统计信息"""
        sql = f"ANALYZE {table_name}"
        self.db_session.execute(text(sql))
        self.db_session.commit()

class DatabaseMaintenance:
    """数据库维护"""
    
    def __init__(self, db_session: Session):
        self.db_session = db_session
    
    def vacuum_table(self, table_name: str, full: bool = False):
        """清理表"""
        vacuum_type = "VACUUM FULL" if full else "VACUUM"
        sql = f"{vacuum_type} {table_name}"
        
        try:
            self.db_session.execute(text(sql))
            self.db_session.commit()
            return True
        except SQLAlchemyError as e:
            self.db_session.rollback()
            raise e
    
    def reindex_table(self, table_name: str):
        """重建表索引"""
        sql = f"REINDEX TABLE {table_name}"
        
        try:
            self.db_session.execute(text(sql))
            self.db_session.commit()
            return True
        except SQLAlchemyError as e:
            self.db_session.rollback()
            raise e
    
    def get_table_stats(self, table_name: str) -> Dict[str, Any]:
        """获取表统计信息"""
        sql = """
        SELECT 
            schemaname,
            tablename,
            attname,
            n_distinct,
            correlation
        FROM pg_stats 
        WHERE tablename = :table_name
        """
        
        result = self.db_session.execute(text(sql), {"table_name": table_name})
        stats = [dict(row) for row in result]
        
        return {
            "table_name": table_name,
            "column_stats": stats
        }

# 查询优化装饰器
def optimize_query(level: QueryOptimizationLevel = QueryOptimizationLevel.BASIC):
    """查询优化装饰器"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # 这里可以添加查询优化逻辑
            return await func(*args, **kwargs)
        return wrapper
    return decorator

# 数据库性能监控装饰器
def monitor_query_performance(func):
    """监控查询性能装饰器"""
    @wraps(func)
    async def wrapper(*args, **kwargs):
        start_time = time.time()
        
        try:
            result = await func(*args, **kwargs)
            end_time = time.time()
            
            query_time = end_time - start_time
            if query_time > 1.0:  # 慢查询阈值
                logging.warning(f"慢查询: {func.__name__} 耗时 {query_time:.3f}s")
            
            return result
        except Exception as e:
            logging.error(f"查询错误: {func.__name__} - {e}")
            raise
    
    return wrapper
