"""
数据库配置和连接管理 - 增强版本
支持连接池监控、多数据库、读写分离等功能
"""
import os
import logging
import asyncio
import threading
import time
from sqlalchemy import create_engine, MetaData, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from typing import AsyncGenerator, Dict, Any, Optional, List
from dataclasses import dataclass
from enum import Enum
from collections import defaultdict, deque

from .database_url_utils import (
    ensure_mysql_connect_args,
    get_mysql_connect_args_from_url,
    prepare_sqlalchemy_mysql_url,
)
from .unified_config import settings

logger = logging.getLogger(__name__)

class DatabaseType(Enum):
    """数据库类型枚举"""
    MYSQL = "mysql"
    POSTGRESQL = "postgresql"
    # 不再支持SQLite

@dataclass
class ConnectionPoolStats:
    """连接池统计信息"""
    total_connections: int
    active_connections: int
    idle_connections: int
    overflow_connections: int
    checked_out_connections: int
    checked_in_connections: int
    pool_size: int
    max_overflow: int
    pool_timeout: float
    pool_recycle: int
    last_checked: float

class DatabaseConnectionMonitor:
    """数据库连接池监控器"""
    
    def __init__(self, engine, pool_name: str = "default"):
        self.engine = engine
        self.pool_name = pool_name
        self.stats_history: List[ConnectionPoolStats] = []
        self.monitoring = False
        self.monitor_thread = None
        
    def start_monitoring(self, interval: int = 30):
        """启动连接池监控"""
        if self.monitoring:
            return
            
        self.monitoring = True
        self.monitor_thread = threading.Thread(
            target=self._monitor_loop,
            args=(interval,),
            daemon=True
        )
        self.monitor_thread.start()
        logger.info(f"连接池监控已启动: {self.pool_name}")
    
    def stop_monitoring(self):
        """停止连接池监控"""
        self.monitoring = False
        if self.monitor_thread:
            self.monitor_thread.join()
        logger.info(f"连接池监控已停止: {self.pool_name}")
    
    def _monitor_loop(self, interval: int):
        """监控循环"""
        while self.monitoring:
            try:
                stats = self.get_pool_stats()
                self.stats_history.append(stats)
                
                # 保持历史记录在合理范围内
                if len(self.stats_history) > 100:
                    self.stats_history = self.stats_history[-50:]
                
                # 检查连接池健康状态
                self._check_pool_health(stats)
                
                time.sleep(interval)
            except Exception as e:
                logger.error(f"连接池监控错误: {e}")
                time.sleep(interval)
    
    def get_pool_stats(self) -> ConnectionPoolStats:
        """获取连接池统计信息"""
        pool = self.engine.pool
        
        return ConnectionPoolStats(
            total_connections=pool.size(),
            active_connections=pool.checkedout(),
            idle_connections=pool.checkedin(),
            overflow_connections=pool.overflow(),
            checked_out_connections=pool.checkedout(),
            checked_in_connections=pool.checkedin(),
            pool_size=pool.size(),
            max_overflow=pool._max_overflow,
            pool_timeout=pool._timeout,
            pool_recycle=pool._recycle,
            last_checked=time.time()
        )
    
    def _check_pool_health(self, stats: ConnectionPoolStats):
        """检查连接池健康状态"""
        # 检查连接池使用率
        usage_ratio = stats.active_connections / stats.pool_size
        
        if usage_ratio > 0.8:
            logger.warning(f"连接池使用率过高: {usage_ratio:.2%} ({self.pool_name})")
        
        # 检查溢出连接
        if stats.overflow_connections > 0:
            logger.warning(f"连接池溢出: {stats.overflow_connections} ({self.pool_name})")
        
        # 检查连接超时
        if stats.pool_timeout < 30:
            logger.warning(f"连接池超时时间过短: {stats.pool_timeout}s ({self.pool_name})")
    
    def get_health_report(self) -> Dict[str, Any]:
        """获取健康报告"""
        if not self.stats_history:
            return {"status": "no_data", "message": "暂无监控数据"}
        
        latest_stats = self.stats_history[-1]
        
        # 计算趋势
        if len(self.stats_history) > 1:
            prev_stats = self.stats_history[-2]
            active_trend = latest_stats.active_connections - prev_stats.active_connections
        else:
            active_trend = 0
        
        return {
            "status": "healthy",
            "pool_name": self.pool_name,
            "current_stats": {
                "total_connections": latest_stats.total_connections,
                "active_connections": latest_stats.active_connections,
                "idle_connections": latest_stats.idle_connections,
                "overflow_connections": latest_stats.overflow_connections,
                "usage_ratio": latest_stats.active_connections / latest_stats.pool_size,
            },
            "trends": {
                "active_connections_change": active_trend,
            },
            "recommendations": self._get_recommendations(latest_stats)
        }
    
    def _get_recommendations(self, stats: ConnectionPoolStats) -> List[str]:
        """获取优化建议"""
        recommendations = []
        
        usage_ratio = stats.active_connections / stats.pool_size
        
        if usage_ratio > 0.8:
            recommendations.append("考虑增加连接池大小")
        
        if stats.overflow_connections > 0:
            recommendations.append("考虑增加max_overflow参数")
        
        if stats.pool_timeout < 30:
            recommendations.append("考虑增加连接超时时间")
        
        if stats.pool_recycle < 3600:
            recommendations.append("考虑增加连接回收时间")
        
        return recommendations

class MultiDatabaseManager:
    """多数据库管理器"""
    
    def __init__(self):
        self.engines: Dict[str, Any] = {}
        self.monitors: Dict[str, DatabaseConnectionMonitor] = {}
        self.read_engines: List[Any] = []
        self.write_engine: Optional[Any] = None
        
    def add_database(self, name: str, database_url: str, db_type: DatabaseType):
        """添加数据库连接"""
        try:
            if db_type == DatabaseType.MYSQL:
                # MySQL异步引擎
                url_obj = prepare_sqlalchemy_mysql_url(database_url)
                async_url = url_obj
                drivername = (async_url.drivername or "").lower()
                if drivername.startswith("mysql") and "+aiomysql" not in drivername:
                    async_url = async_url.set(drivername="mysql+aiomysql")
                engine = create_async_engine(
                    async_url,
                    pool_size=20,
                    max_overflow=30,
                    pool_timeout=30,
                    pool_recycle=3600,
                    echo=False,
                    connect_args=ensure_mysql_connect_args(),
                )
            elif db_type == DatabaseType.POSTGRESQL:
                # PostgreSQL异步引擎
                async_url = database_url.replace("postgresql://", "postgresql+asyncpg://")
                engine = create_async_engine(
                    async_url,
                    pool_size=20,
                    max_overflow=30,
                    pool_timeout=30,
                    pool_recycle=3600,
                    echo=False
                )
            else:
                raise ValueError(f"不支持的数据库类型: {db_type}，仅支持MySQL和PostgreSQL")
            
            self.engines[name] = engine
            
            # 创建监控器
            monitor = DatabaseConnectionMonitor(engine, name)
            monitor.start_monitoring()
            self.monitors[name] = monitor
            
            logger.info(f"数据库连接已添加: {name} ({db_type.value})")
            
        except Exception as e:
            logger.error(f"添加数据库连接失败: {name} - {e}")
            raise
    
    def setup_read_write_separation(self, write_db: str, read_dbs: List[str]):
        """设置读写分离"""
        if write_db not in self.engines:
            raise ValueError(f"写数据库不存在: {write_db}")
        
        self.write_engine = self.engines[write_db]
        
        for read_db in read_dbs:
            if read_db not in self.engines:
                raise ValueError(f"读数据库不存在: {read_db}")
            self.read_engines.append(self.engines[read_db])
        
        logger.info(f"读写分离已设置: 写={write_db}, 读={read_dbs}")
    
    async def get_read_session(self) -> AsyncSession:
        """获取读数据库会话"""
        if not self.read_engines:
            raise RuntimeError("未配置读数据库")
        
        # 简单的负载均衡：轮询选择读数据库
        engine = self.read_engines[0]  # 简化实现
        async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
        return async_session()
    
    async def get_write_session(self) -> AsyncSession:
        """获取写数据库会话"""
        if not self.write_engine:
            raise RuntimeError("未配置写数据库")
        
        async_session = sessionmaker(self.write_engine, class_=AsyncSession, expire_on_commit=False)
        return async_session()
    
    def get_health_report(self) -> Dict[str, Any]:
        """获取所有数据库的健康报告"""
        reports = {}
        
        for name, monitor in self.monitors.items():
            reports[name] = monitor.get_health_report()
        
        return {
            "overall_status": "healthy",
            "databases": reports,
            "read_write_separation": {
                "enabled": bool(self.write_engine),
                "write_db": "configured" if self.write_engine else "not_configured",
                "read_dbs_count": len(self.read_engines)
            }
        }
    
    async def close_all(self):
        """关闭所有数据库连接"""
        for name, engine in self.engines.items():
            try:
                await engine.dispose()
                logger.info(f"数据库连接已关闭: {name}")
            except Exception as e:
                logger.error(f"关闭数据库连接失败: {name} - {e}")
        
        for monitor in self.monitors.values():
            monitor.stop_monitoring()

# 全局多数据库管理器实例
db_manager = MultiDatabaseManager()

# 可选导入Redis（仅在需要时导入）
try:
    import redis.asyncio as redis
    REDIS_AVAILABLE = True
except ImportError:
    try:
        import redis
        REDIS_AVAILABLE = True
    except ImportError:
        REDIS_AVAILABLE = False
        redis = None

# 初始化变量
async_engine = None
sync_engine = None
aiomysql_available = False

# 创建异步数据库引擎 - 强制使用MySQL
# 仅支持MySQL数据库，不支持PostgreSQL和SQLite
normalized_mysql_url = prepare_sqlalchemy_mysql_url(settings.DATABASE_URL)
drivername = (normalized_mysql_url.drivername or "").lower()
if not drivername.startswith("mysql"):
    logger.error(f"不支持的数据库类型，仅支持MySQL。当前URL: {settings.DATABASE_URL}")
    async_engine = None
else:
    # MySQL数据库
    async_db_url = normalized_mysql_url
    if "+aiomysql" not in drivername:
        async_db_url = async_db_url.set(drivername="mysql+aiomysql")
    logger.info(
        "强制使用MySQL异步驱动: %s",
        async_db_url.render_as_string(hide_password=True),
    )
    
    # 检查是否安装了aiomysql驱动
    try:
        import aiomysql
        aiomysql_available = True
    except ImportError:
        aiomysql_available = False
        logger.error("aiomysql驱动未安装，异步引擎初始化失败")
    
    # 检查数据库连接是否可用
    try:
        if aiomysql_available:
            # 测试异步连接
            # 优化的连接参数
            async_engine = create_async_engine(
                async_db_url,
                pool_size=20,  # 连接池大小
                max_overflow=30,  # 最大溢出连接数
                pool_timeout=30,  # 连接超时时间
                pool_recycle=3600,  # 连接回收时间
                pool_pre_ping=True,  # 连接前ping检查
                echo=False,  # 不打印SQL语句
                future=True,
                connect_args=get_mysql_connect_args_from_url(async_db_url.render_as_string(hide_password=False)),
            )
            logger.info("MySQL异步引擎创建成功")
        else:
            logger.error("aiomysql不可用，无法创建异步引擎")
    except Exception as e:
        logger.error(f"创建MySQL异步引擎失败: {e}")
        aiomysql_available = False

# 创建同步数据库引擎 - 强制使用MySQL
# 仅支持MySQL数据库，不支持PostgreSQL和SQLite
sync_driver = (normalized_mysql_url.drivername or "").lower()
if not sync_driver.startswith("mysql"):
    logger.error(f"不支持的数据库类型，仅支持MySQL。当前URL: {settings.DATABASE_URL}")
    sync_engine = None
else:
    # MySQL数据库
    sync_db_url = normalized_mysql_url
    if "+pymysql" not in sync_driver:
        sync_db_url = sync_db_url.set(drivername="mysql+pymysql")
    logger.info(
        "强制使用MySQL同步驱动: %s",
        sync_db_url.render_as_string(hide_password=True),
    )

    try:
        # 优化的连接参数
        sync_engine = create_engine(
            sync_db_url,
            pool_size=20,
            max_overflow=30,
            pool_timeout=30,
            pool_recycle=3600,
            pool_pre_ping=True,
            echo=False,
            future=True,
            connect_args=ensure_mysql_connect_args(),
        )
        logger.info("MySQL同步引擎创建成功")
    except Exception as e:
        logger.error(f"创建MySQL同步引擎失败: {e}")
        sync_engine = None

# 创建会话工厂
if async_engine:
    AsyncSessionLocal = async_sessionmaker(
        async_engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
else:
    AsyncSessionLocal = None

if sync_engine:
    SessionLocal = sessionmaker(
        autocommit=False,
        autoflush=False,
        bind=sync_engine
    )
else:
    SessionLocal = None

# 创建基础模型类
Base = declarative_base()

# Redis连接池
redis_pool = None
if REDIS_AVAILABLE and settings.USE_REDIS:
    try:
        if hasattr(redis, 'ConnectionPool'):
            # 异步Redis
            redis_pool = redis.ConnectionPool.from_url(
                settings.REDIS_URL,
                max_connections=20,
                retry_on_timeout=True
            )
        else:
            # 同步Redis
            redis_pool = redis.ConnectionPool.from_url(
                settings.REDIS_URL,
                max_connections=20,
                retry_on_timeout=True
            )
        logger.info("Redis连接池创建成功")
    except Exception as e:
        logger.error(f"创建Redis连接池失败: {e}")
        redis_pool = None

async def get_async_db() -> AsyncGenerator[AsyncSession, None]:
    """获取异步数据库会话"""
    if AsyncSessionLocal is None:
        # 如果异步会话不可用，创建一个模拟会话
        class MockAsyncSession:
            async def execute(self, *args, **kwargs):
                raise RuntimeError("异步数据库会话不可用")
            async def commit(self):
                pass
            async def rollback(self):
                pass
            async def close(self):
                pass
        
        yield MockAsyncSession()
        return
    
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception as e:
            await session.rollback()
            logger.error(f"数据库会话错误: {e}")
            raise
        finally:
            await session.close()

def get_sync_db():
    """获取同步数据库会话"""
    if SessionLocal is None:
        raise RuntimeError("同步数据库会话不可用")
    
    db = SessionLocal()
    try:
        yield db
    except Exception as e:
        db.rollback()
        logger.error(f"数据库会话错误: {e}")
        raise
    finally:
        db.close()

def get_db():
    """获取数据库会话（自动选择异步或同步）"""
    if AsyncSessionLocal is not None:
        return get_async_db()
    elif SessionLocal is not None:
        return get_sync_db()
    else:
        raise RuntimeError("数据库会话不可用")

async def init_db():
    """初始化数据库"""
    try:
        if async_engine:
            async with async_engine.begin() as conn:
                # 这里可以添加数据库初始化逻辑
                pass
            logger.info("异步数据库初始化完成")
        elif sync_engine:
            with sync_engine.begin() as conn:
                # 这里可以添加数据库初始化逻辑
                pass
            logger.info("同步数据库初始化完成")
        else:
            logger.warning("没有可用的数据库引擎")
    except Exception as e:
        logger.error(f"数据库初始化失败: {e}")
        raise

async def close_db():
    """关闭数据库连接"""
    try:
        if async_engine:
            await async_engine.dispose()
            logger.info("异步数据库连接已关闭")
        if sync_engine:
            sync_engine.dispose()
            logger.info("同步数据库连接已关闭")
    except Exception as e:
        logger.error(f"关闭数据库连接失败: {e}")

# 数据库健康检查
async def check_db_health() -> Dict[str, Any]:
    """检查数据库健康状态"""
    health_status = {
        "status": "healthy",
        "async_available": aiomysql_available,
        "sync_available": sync_engine is not None,
        "redis_available": redis_pool is not None,
        "timestamp": time.time()
    }
    
    try:
        if async_engine:
            async with async_engine.begin() as conn:
                await conn.execute(text("SELECT 1"))
            health_status["async_connection"] = "ok"
        else:
            health_status["async_connection"] = "unavailable"
    except Exception as e:
        health_status["async_connection"] = f"error: {e}"
        health_status["status"] = "unhealthy"
    
    try:
        if sync_engine:
            with sync_engine.begin() as conn:
                conn.execute(text("SELECT 1"))
            health_status["sync_connection"] = "ok"
        else:
            health_status["sync_connection"] = "unavailable"
    except Exception as e:
        health_status["sync_connection"] = f"error: {e}"
        health_status["status"] = "unhealthy"
    
    return health_status

# 初始化多数据库管理器
def init_multi_database():
    """初始化多数据库管理器"""
    try:
        # 添加主数据库
        db_manager.add_database("main", settings.DATABASE_URL, DatabaseType.MYSQL)
        
        # 如果有读数据库配置，添加读数据库
        if hasattr(settings, 'READ_DATABASE_URL') and settings.READ_DATABASE_URL:
            db_manager.add_database("read", settings.READ_DATABASE_URL, DatabaseType.MYSQL)
            db_manager.setup_read_write_separation("main", ["read"])
        
        logger.info("多数据库管理器初始化完成")
    except Exception as e:
        logger.error(f"多数据库管理器初始化失败: {e}")

# 启动数据库监控
def start_database_monitoring():
    """启动数据库监控"""
    try:
        init_multi_database()
        logger.info("数据库监控已启动")
    except Exception as e:
        logger.error(f"启动数据库监控失败: {e}")

# 停止数据库监控
async def stop_database_monitoring():
    """停止数据库监控"""
    try:
        await db_manager.close_all()
        logger.info("数据库监控已停止")
    except Exception as e:
        logger.error(f"停止数据库监控失败: {e}")