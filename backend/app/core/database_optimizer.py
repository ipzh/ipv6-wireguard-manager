"""
数据库优化配置
提供数据库索引、查询优化和性能监控
"""

from sqlalchemy import Index, text
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Dict, Any
import asyncio
from datetime import datetime, timedelta

from .database_manager import db_manager, get_logger
from .unified_config import settings

logger = get_logger("database_optimizer")

class DatabaseOptimizer:
    """数据库优化器"""
    
    def __init__(self):
        self.logger = logger
    
    async def create_indexes(self, session: AsyncSession):
        """创建数据库索引"""
        try:
            # 用户表索引
            await self._create_user_indexes(session)
            
            # WireGuard相关索引
            await self._create_wireguard_indexes(session)
            
            # BGP相关索引
            await self._create_bgp_indexes(session)
            
            # IPv6相关索引
            await self._create_ipv6_indexes(session)
            
            # 日志和审计索引
            await self._create_audit_indexes(session)
            
            await session.commit()
            self.logger.info("数据库索引创建完成")
            
        except Exception as e:
            await session.rollback()
            self.logger.error("数据库索引创建失败", error=str(e))
            raise
    
    async def _create_user_indexes(self, session: AsyncSession):
        """创建用户表索引"""
        indexes = [
            "CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)",
            "CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)",
            "CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active)",
            "CREATE INDEX IF NOT EXISTS idx_users_is_superuser ON users(is_superuser)",
            "CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at)",
            "CREATE INDEX IF NOT EXISTS idx_users_last_login ON users(last_login_at)",
        ]
        
        for index_sql in indexes:
            await session.execute(text(index_sql))
    
    async def _create_wireguard_indexes(self, session: AsyncSession):
        """创建WireGuard相关索引"""
        indexes = [
            "CREATE INDEX IF NOT EXISTS idx_wireguard_servers_name ON wireguard_servers(name)",
            "CREATE INDEX IF NOT EXISTS idx_wireguard_servers_status ON wireguard_servers(status)",
            "CREATE INDEX IF NOT EXISTS idx_wireguard_servers_created_at ON wireguard_servers(created_at)",
            "CREATE INDEX IF NOT EXISTS idx_wireguard_clients_user_id ON wireguard_clients(user_id)",
            "CREATE INDEX IF NOT EXISTS idx_wireguard_clients_server_id ON wireguard_clients(server_id)",
            "CREATE INDEX IF NOT EXISTS idx_wireguard_clients_status ON wireguard_clients(status)",
            "CREATE INDEX IF NOT EXISTS idx_wireguard_clients_created_at ON wireguard_clients(created_at)",
        ]
        
        for index_sql in indexes:
            await session.execute(text(index_sql))
    
    async def _create_bgp_indexes(self, session: AsyncSession):
        """创建BGP相关索引"""
        indexes = [
            "CREATE INDEX IF NOT EXISTS idx_bgp_sessions_name ON bgp_sessions(name)",
            "CREATE INDEX IF NOT EXISTS idx_bgp_sessions_status ON bgp_sessions(status)",
            "CREATE INDEX IF NOT EXISTS idx_bgp_sessions_peer_ip ON bgp_sessions(peer_ip)",
            "CREATE INDEX IF NOT EXISTS idx_bgp_sessions_created_at ON bgp_sessions(created_at)",
            "CREATE INDEX IF NOT EXISTS idx_bgp_announcements_prefix ON bgp_announcements(prefix)",
            "CREATE INDEX IF NOT EXISTS idx_bgp_announcements_session_id ON bgp_announcements(session_id)",
            "CREATE INDEX IF NOT EXISTS idx_bgp_announcements_status ON bgp_announcements(status)",
        ]
        
        for index_sql in indexes:
            await session.execute(text(index_sql))
    
    async def _create_ipv6_indexes(self, session: AsyncSession):
        """创建IPv6相关索引"""
        indexes = [
            "CREATE INDEX IF NOT EXISTS idx_ipv6_pools_name ON ipv6_pools(name)",
            "CREATE INDEX IF NOT EXISTS idx_ipv6_pools_prefix ON ipv6_pools(prefix)",
            "CREATE INDEX IF NOT EXISTS idx_ipv6_pools_status ON ipv6_pools(status)",
            "CREATE INDEX IF NOT EXISTS idx_ipv6_allocations_pool_id ON ipv6_allocations(pool_id)",
            "CREATE INDEX IF NOT EXISTS idx_ipv6_allocations_user_id ON ipv6_allocations(user_id)",
            "CREATE INDEX IF NOT EXISTS idx_ipv6_allocations_prefix ON ipv6_allocations(prefix)",
            "CREATE INDEX IF NOT EXISTS idx_ipv6_allocations_status ON ipv6_allocations(status)",
            "CREATE INDEX IF NOT EXISTS idx_ipv6_allocations_created_at ON ipv6_allocations(created_at)",
        ]
        
        for index_sql in indexes:
            await session.execute(text(index_sql))
    
    async def _create_audit_indexes(self, session: AsyncSession):
        """创建审计日志索引"""
        indexes = [
            "CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id)",
            "CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action)",
            "CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON audit_logs(resource)",
            "CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at)",
            "CREATE INDEX IF NOT EXISTS idx_audit_logs_ip_address ON audit_logs(ip_address)",
            "CREATE INDEX IF NOT EXISTS idx_security_logs_event_type ON security_logs(event_type)",
            "CREATE INDEX IF NOT EXISTS idx_security_logs_user_id ON security_logs(user_id)",
            "CREATE INDEX IF NOT EXISTS idx_security_logs_created_at ON security_logs(created_at)",
        ]
        
        for index_sql in indexes:
            await session.execute(text(index_sql))
    
    async def analyze_query_performance(self, session: AsyncSession) -> Dict[str, Any]:
        """分析查询性能"""
        try:
            # 获取慢查询
            slow_queries = await self._get_slow_queries(session)
            
            # 获取表统计信息
            table_stats = await self._get_table_statistics(session)
            
            # 获取索引使用情况
            index_usage = await self._get_index_usage(session)
            
            return {
                "slow_queries": slow_queries,
                "table_statistics": table_stats,
                "index_usage": index_usage,
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            self.logger.error("查询性能分析失败", error=str(e))
            return {"error": str(e)}
    
    async def _get_slow_queries(self, session: AsyncSession) -> List[Dict[str, Any]]:
        """获取慢查询"""
        # MySQL慢查询日志查询
        query = text("""
            SELECT 
                sql_text,
                exec_count,
                avg_timer_wait/1000000000 as avg_time_seconds,
                max_timer_wait/1000000000 as max_time_seconds
            FROM performance_schema.events_statements_summary_by_digest 
            WHERE avg_timer_wait > 1000000000  -- 大于1秒的查询
            ORDER BY avg_timer_wait DESC 
            LIMIT 10
        """)
        
        try:
            result = await session.execute(query)
            return [dict(row._mapping) for row in result.fetchall()]
        except Exception:
            # 如果performance_schema不可用，返回空列表
            return []
    
    async def _get_table_statistics(self, session: AsyncSession) -> List[Dict[str, Any]]:
        """获取表统计信息"""
        query = text("""
            SELECT 
                table_name,
                table_rows,
                data_length,
                index_length,
                (data_length + index_length) as total_size
            FROM information_schema.tables 
            WHERE table_schema = DATABASE()
            ORDER BY total_size DESC
        """)
        
        result = await session.execute(query)
        return [dict(row._mapping) for row in result.fetchall()]
    
    async def _get_index_usage(self, session: AsyncSession) -> List[Dict[str, Any]]:
        """获取索引使用情况"""
        query = text("""
            SELECT 
                table_name,
                index_name,
                seq_in_index,
                column_name,
                cardinality
            FROM information_schema.statistics 
            WHERE table_schema = DATABASE()
            ORDER BY table_name, seq_in_index
        """)
        
        result = await session.execute(query)
        return [dict(row._mapping) for row in result.fetchall()]
    
    async def optimize_tables(self, session: AsyncSession):
        """优化数据库表"""
        try:
            # 获取所有表
            tables_query = text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = DATABASE()
            """)
            
            result = await session.execute(tables_query)
            tables = [row[0] for row in result.fetchall()]
            
            # 优化每个表
            for table in tables:
                optimize_query = text(f"OPTIMIZE TABLE {table}")
                await session.execute(optimize_query)
                self.logger.info("表优化完成", table=table)
            
            await session.commit()
            self.logger.info("数据库表优化完成")
            
        except Exception as e:
            await session.rollback()
            self.logger.error("数据库表优化失败", error=str(e))
            raise
    
    async def cleanup_old_data(self, session: AsyncSession, days: int = 30):
        """清理旧数据"""
        try:
            cutoff_date = datetime.utcnow() - timedelta(days=days)
            
            # 清理旧的审计日志
            audit_query = text("""
                DELETE FROM audit_logs 
                WHERE created_at < :cutoff_date
            """)
            await session.execute(audit_query, {"cutoff_date": cutoff_date})
            
            # 清理旧的安全日志
            security_query = text("""
                DELETE FROM security_logs 
                WHERE created_at < :cutoff_date
            """)
            await session.execute(security_query, {"cutoff_date": cutoff_date})
            
            # 清理旧的会话记录
            session_query = text("""
                DELETE FROM user_sessions 
                WHERE expires_at < :cutoff_date
            """)
            await session.execute(session_query, {"cutoff_date": cutoff_date})
            
            await session.commit()
            self.logger.info("旧数据清理完成", days=days)
            
        except Exception as e:
            await session.rollback()
            self.logger.error("旧数据清理失败", error=str(e))
            raise

# 数据库配置优化
class DatabaseConfigOptimizer:
    """数据库配置优化器"""
    
    def __init__(self):
        self.logger = logger
    
    def get_optimized_config(self) -> Dict[str, Any]:
        """获取优化的数据库配置"""
        return {
            # 连接池配置
            "pool_size": settings.DATABASE_POOL_SIZE,
            "max_overflow": settings.DATABASE_MAX_OVERFLOW,
            "pool_timeout": settings.DATABASE_CONNECT_TIMEOUT,
            "pool_recycle": settings.DATABASE_POOL_RECYCLE,
            "pool_pre_ping": settings.DATABASE_POOL_PRE_PING,
            
            # MySQL特定优化
            "mysql_optimizations": {
                "innodb_buffer_pool_size": "256M",
                "innodb_log_file_size": "64M",
                "innodb_flush_log_at_trx_commit": 2,
                "innodb_flush_method": "O_DIRECT",
                "query_cache_size": "32M",
                "query_cache_type": 1,
                "max_connections": 100,
                "thread_cache_size": 8,
                "table_open_cache": 400,
                "tmp_table_size": "32M",
                "max_heap_table_size": "32M",
            },
            
            # 索引优化
            "index_optimizations": {
                "enable_index_optimization": True,
                "auto_create_indexes": True,
                "index_usage_monitoring": True,
            },
            
            # 查询优化
            "query_optimizations": {
                "enable_query_cache": True,
                "slow_query_log": True,
                "long_query_time": 1.0,
                "log_queries_not_using_indexes": True,
            }
        }
    
    def generate_mysql_config(self) -> str:
        """生成MySQL优化配置"""
        config = self.get_optimized_config()
        mysql_config = config["mysql_optimizations"]
        
        config_lines = [
            "[mysqld]",
            "# IPv6 WireGuard Manager 优化配置",
            "",
            "# 基础配置",
            f"innodb_buffer_pool_size = {mysql_config['innodb_buffer_pool_size']}",
            f"innodb_log_file_size = {mysql_config['innodb_log_file_size']}",
            f"innodb_flush_log_at_trx_commit = {mysql_config['innodb_flush_log_at_trx_commit']}",
            f"innodb_flush_method = {mysql_config['innodb_flush_method']}",
            "",
            "# 查询缓存",
            f"query_cache_size = {mysql_config['query_cache_size']}",
            f"query_cache_type = {mysql_config['query_cache_type']}",
            "",
            "# 连接配置",
            f"max_connections = {mysql_config['max_connections']}",
            f"thread_cache_size = {mysql_config['thread_cache_size']}",
            f"table_open_cache = {mysql_config['table_open_cache']}",
            "",
            "# 临时表配置",
            f"tmp_table_size = {mysql_config['tmp_table_size']}",
            f"max_heap_table_size = {mysql_config['max_heap_table_size']}",
            "",
            "# 慢查询日志",
            "slow_query_log = 1",
            "long_query_time = 1.0",
            "log_queries_not_using_indexes = 1",
            "",
            "# 字符集",
            "character_set_server = utf8mb4",
            "collation_server = utf8mb4_unicode_ci",
            "",
            "# 安全配置",
            "local_infile = 0",
            "skip_show_database",
        ]
        
        return "\n".join(config_lines)

# 全局优化器实例
db_optimizer = DatabaseOptimizer()
config_optimizer = DatabaseConfigOptimizer()

# 便捷函数
async def optimize_database():
    """优化数据库"""
    async with db_manager.get_session() as session:
        await db_optimizer.create_indexes(session)
        await db_optimizer.optimize_tables(session)

async def analyze_database_performance():
    """分析数据库性能"""
    async with db_manager.get_session() as session:
        return await db_optimizer.analyze_query_performance(session)

async def cleanup_old_logs(days: int = 30):
    """清理旧日志"""
    async with db_manager.get_session() as session:
        await db_optimizer.cleanup_old_data(session, days)

def get_database_config():
    """获取数据库配置"""
    return config_optimizer.get_optimized_config()

def generate_mysql_config():
    """生成MySQL配置"""
    return config_optimizer.generate_mysql_config()
