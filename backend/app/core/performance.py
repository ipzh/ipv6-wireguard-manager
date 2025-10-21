"""
性能优化模块
数据库查询优化、缓存策略、连接池管理
"""

import time
import logging
from typing import Dict, Any, Optional, List
from functools import wraps
from sqlalchemy import text, select
from sqlalchemy.orm import Session
from sqlalchemy.pool import QueuePool
import redis
from redis import ConnectionPool

logger = logging.getLogger(__name__)

class PerformanceOptimizer:
    """性能优化器"""
    
    def __init__(self, redis_pool: Optional[ConnectionPool] = None):
        self.redis_pool = redis_pool
        self.cache_enabled = redis_pool is not None
        self.query_cache = {}
        self.cache_ttl = 300  # 5分钟缓存
    
    def cache_query(self, ttl: int = None):
        """查询缓存装饰器"""
        def decorator(func):
            @wraps(func)
            async def wrapper(*args, **kwargs):
                if not self.cache_enabled:
                    return await func(*args, **kwargs)
                
                # 生成缓存键
                cache_key = f"query:{func.__name__}:{hash(str(args) + str(kwargs))}"
                
                # 尝试从缓存获取
                try:
                    cached_result = await self.get_from_cache(cache_key)
                    if cached_result:
                        logger.debug(f"缓存命中: {cache_key}")
                        return cached_result
                except Exception as e:
                    logger.warning(f"缓存读取失败: {e}")
                
                # 执行查询
                result = await func(*args, **kwargs)
                
                # 存储到缓存
                try:
                    await self.set_cache(cache_key, result, ttl or self.cache_ttl)
                    logger.debug(f"缓存存储: {cache_key}")
                except Exception as e:
                    logger.warning(f"缓存存储失败: {e}")
                
                return result
            return wrapper
        return decorator
    
    async def get_from_cache(self, key: str) -> Optional[Any]:
        """从缓存获取数据"""
        if not self.cache_enabled:
            return None
        
        try:
            redis_client = redis.Redis(connection_pool=self.redis_pool)
            cached_data = redis_client.get(key)
            if cached_data:
                import json
                return json.loads(cached_data)
        except Exception as e:
            logger.error(f"缓存读取错误: {e}")
        
        return None
    
    async def set_cache(self, key: str, data: Any, ttl: int = 300):
        """设置缓存数据"""
        if not self.cache_enabled:
            return
        
        try:
            redis_client = redis.Redis(connection_pool=self.redis_pool)
            import json
            redis_client.setex(key, ttl, json.dumps(data, default=str))
        except Exception as e:
            logger.error(f"缓存设置错误: {e}")
    
    def optimize_database_connection(self, engine):
        """优化数据库连接池"""
        # 配置连接池参数
        engine.pool = QueuePool(
            creator=engine.pool._creator,
            pool_size=20,  # 连接池大小
            max_overflow=30,  # 最大溢出连接
            pool_pre_ping=True,  # 连接前ping
            pool_recycle=3600,  # 连接回收时间
            pool_timeout=30,  # 获取连接超时
        )
        
        logger.info("数据库连接池已优化")
    
    def create_indexes(self, session: Session):
        """创建数据库索引"""
        indexes = [
            # 用户表索引
            "CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)",
            "CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)",
            "CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at)",
            
            # WireGuard服务器索引
            "CREATE INDEX IF NOT EXISTS idx_wireguard_servers_name ON wireguard_servers(name)",
            "CREATE INDEX IF NOT EXISTS idx_wireguard_servers_status ON wireguard_servers(status)",
            
            # WireGuard客户端索引
            "CREATE INDEX IF NOT EXISTS idx_wireguard_clients_name ON wireguard_clients(name)",
            "CREATE INDEX IF NOT EXISTS idx_wireguard_clients_server_id ON wireguard_clients(server_id)",
            "CREATE INDEX IF NOT EXISTS idx_wireguard_clients_status ON wireguard_clients(status)",
            
            # IPv6地址池索引
            "CREATE INDEX IF NOT EXISTS idx_ipv6_pools_name ON ipv6_pools(name)",
            "CREATE INDEX IF NOT EXISTS idx_ipv6_pools_network ON ipv6_pools(network)",
            
            # BGP会话索引
            "CREATE INDEX IF NOT EXISTS idx_bgp_sessions_name ON bgp_sessions(name)",
            "CREATE INDEX IF NOT EXISTS idx_bgp_sessions_remote_ip ON bgp_sessions(remote_ip)",
            "CREATE INDEX IF NOT EXISTS idx_bgp_sessions_status ON bgp_sessions(status)",
            
            # 审计日志索引
            "CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id)",
            "CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action)",
            "CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at)",
        ]
        
        for index_sql in indexes:
            try:
                session.execute(text(index_sql))
                logger.info(f"创建索引: {index_sql}")
            except Exception as e:
                logger.warning(f"索引创建失败: {e}")
        
        session.commit()
        logger.info("数据库索引创建完成")
    
    def analyze_slow_queries(self, session: Session):
        """分析慢查询"""
        try:
            # 启用慢查询日志
            session.execute(text("SET GLOBAL slow_query_log = 'ON'"))
            session.execute(text("SET GLOBAL long_query_time = 1"))
            session.execute(text("SET GLOBAL log_queries_not_using_indexes = 'ON'"))
            
            logger.info("慢查询分析已启用")
        except Exception as e:
            logger.warning(f"慢查询分析启用失败: {e}")
    
    def optimize_query(self, query: str) -> str:
        """优化SQL查询"""
        # 移除不必要的空格
        query = ' '.join(query.split())
        
        # 添加查询提示
        if 'SELECT' in query.upper():
            if 'LIMIT' not in query.upper():
                query += ' LIMIT 1000'  # 默认限制
        
        return query
    
    def get_performance_stats(self) -> Dict[str, Any]:
        """获取性能统计"""
        stats = {
            'cache_enabled': self.cache_enabled,
            'cache_hits': getattr(self, 'cache_hits', 0),
            'cache_misses': getattr(self, 'cache_misses', 0),
            'query_count': getattr(self, 'query_count', 0),
            'avg_query_time': getattr(self, 'avg_query_time', 0),
            'timestamp': time.time()
        }
        
        return stats

class DatabaseOptimizer:
    """数据库优化器"""
    
    def __init__(self, session: Session):
        self.session = session
    
    def optimize_queries(self):
        """优化查询性能"""
        optimizations = [
            self.add_query_hints,
            self.create_materialized_views,
            self.optimize_joins,
            self.add_query_cache
        ]
        
        for optimization in optimizations:
            try:
                optimization()
            except Exception as e:
                logger.warning(f"优化失败: {e}")
    
    def add_query_hints(self):
        """添加查询提示"""
        hints = [
            "SET SESSION query_cache_type = ON",
            "SET SESSION query_cache_size = 268435456",  # 256MB
            "SET SESSION tmp_table_size = 134217728",    # 128MB
            "SET SESSION max_heap_table_size = 134217728"  # 128MB
        ]
        
        for hint in hints:
            try:
                self.session.execute(text(hint))
            except Exception as e:
                logger.warning(f"查询提示设置失败: {e}")
    
    def create_materialized_views(self):
        """创建物化视图"""
        views = [
            """
            CREATE OR REPLACE VIEW v_user_stats AS
            SELECT 
                u.id,
                u.username,
                u.email,
                COUNT(wc.id) as client_count,
                MAX(wc.created_at) as last_client_created
            FROM users u
            LEFT JOIN wireguard_clients wc ON u.id = wc.user_id
            GROUP BY u.id, u.username, u.email
            """,
            """
            CREATE OR REPLACE VIEW v_server_stats AS
            SELECT 
                ws.id,
                ws.name,
                ws.status,
                COUNT(wc.id) as client_count,
                SUM(CASE WHEN wc.status = 'active' THEN 1 ELSE 0 END) as active_clients
            FROM wireguard_servers ws
            LEFT JOIN wireguard_clients wc ON ws.id = wc.server_id
            GROUP BY ws.id, ws.name, ws.status
            """
        ]
        
        for view_sql in views:
            try:
                self.session.execute(text(view_sql))
                logger.info("物化视图创建成功")
            except Exception as e:
                logger.warning(f"物化视图创建失败: {e}")
    
    def optimize_joins(self):
        """优化JOIN查询"""
        # 设置JOIN缓冲区大小
        join_buffer_sizes = [
            "SET SESSION join_buffer_size = 134217728",  # 128MB
            "SET SESSION sort_buffer_size = 134217728",  # 128MB
            "SET SESSION read_buffer_size = 8388608"     # 8MB
        ]
        
        for buffer_sql in join_buffer_sizes:
            try:
                self.session.execute(text(buffer_sql))
            except Exception as e:
                logger.warning(f"JOIN优化设置失败: {e}")
    
    def add_query_cache(self):
        """添加查询缓存"""
        cache_settings = [
            "SET SESSION query_cache_type = ON",
            "SET SESSION query_cache_size = 268435456",  # 256MB
            "SET SESSION query_cache_limit = 1048576"   # 1MB
        ]
        
        for setting in cache_settings:
            try:
                self.session.execute(text(setting))
            except Exception as e:
                logger.warning(f"查询缓存设置失败: {e}")

# 创建全局性能优化器
performance_optimizer = PerformanceOptimizer()
