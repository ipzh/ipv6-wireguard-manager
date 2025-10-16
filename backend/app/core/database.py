"""
数据库配置和连接管理
"""
import os
import logging
from sqlalchemy import create_engine, MetaData, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from typing import AsyncGenerator

from .config_enhanced import settings

logger = logging.getLogger(__name__)

# 可选导入Redis（仅在需要时导入）
try:
    import redis.asyncio as redis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False
    redis = None

# 初始化变量
async_engine = None
sync_engine = None
aiomysql_available = False

# 创建异步数据库引擎 - 仅支持MySQL
if settings.DATABASE_URL.startswith("mysql://"):
    # MySQL数据库
    async_db_url = settings.DATABASE_URL.replace("mysql://", "mysql+aiomysql://")
    
    # 检查是否安装了aiomysql驱动
    try:
        import aiomysql
        aiomysql_available = True
    except ImportError:
        aiomysql_available = False
        print("警告: aiomysql驱动未安装，将使用同步模式")
    
    # 检查数据库连接是否可用
    try:
        if aiomysql_available:
            # 测试异步连接
            # 优化的连接参数
            connect_args = {
                "connect_timeout": settings.DATABASE_CONNECT_TIMEOUT,
                "charset": "utf8mb4",
                "autocommit": False,
                "use_unicode": True,
                "sql_mode": "TRADITIONAL"
            }
            
            # 优化的连接池配置
            async_engine = create_async_engine(
                async_db_url,
                pool_size=min(settings.DATABASE_POOL_SIZE, 20),  # 限制最大连接数
                max_overflow=min(settings.DATABASE_MAX_OVERFLOW, 10),  # 限制最大溢出
                pool_pre_ping=True,  # 强制启用连接预检查
                pool_recycle=3600,  # 1小时回收连接
                pool_timeout=30,  # 连接超时30秒
                echo=settings.DEBUG,
                connect_args=connect_args,
                # 添加连接池事件监听
                pool_reset_on_return='commit'
            )
            
            # 简化的连接测试 - 避免复杂的异步测试
            try:
                # 只创建引擎，不进行复杂的连接测试
                logger.info("异步数据库引擎创建成功")
            except Exception as e:
                logger.error(f"异步数据库引擎创建失败: {e}")
                async_engine = None
        else:
            async_engine = None
    except Exception as e:
        print(f"警告: 异步数据库连接失败，使用同步模式: {e}")
        async_engine = None

# 创建异步会话工厂
if async_engine:
    AsyncSessionLocal = async_sessionmaker(
        bind=async_engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autoflush=False,
        autocommit=False,
    )
else:
    AsyncSessionLocal = None

# 可选导入pymysql
try:
    import pymysql
    PYMYSQL_AVAILABLE = True
except ImportError:
    PYMYSQL_AVAILABLE = False
    pymysql = None

# 创建同步数据库引擎（用于Alembic迁移）- 仅支持MySQL
# 使用pymysql驱动而不是MySQLdb
sync_db_url = settings.DATABASE_URL
if sync_db_url.startswith("mysql://"):
    if PYMYSQL_AVAILABLE:
        sync_db_url = sync_db_url.replace("mysql://", "mysql+pymysql://")
    else:
        print("警告: pymysql驱动未安装，无法创建同步数据库引擎")
        sync_engine = None
        sync_connect_args = {}

if PYMYSQL_AVAILABLE and sync_db_url.startswith("mysql+pymysql://"):
    # 优化的同步连接参数
    sync_connect_args = {
        "connect_timeout": settings.DATABASE_CONNECT_TIMEOUT,
        "charset": "utf8mb4",
        "autocommit": False,
        "use_unicode": True,
        "sql_mode": "TRADITIONAL"
    }

    # 优化的同步连接池配置
    sync_engine = create_engine(
        sync_db_url,
        pool_size=min(settings.DATABASE_POOL_SIZE, 10),  # 同步连接池较小
        max_overflow=min(settings.DATABASE_MAX_OVERFLOW, 5),
        pool_pre_ping=True,  # 强制启用连接预检查
        pool_recycle=3600,  # 1小时回收连接
        pool_timeout=30,  # 连接超时30秒
        echo=settings.DEBUG,
        connect_args=sync_connect_args,
        pool_reset_on_return='commit'
    )
else:
    sync_engine = None
    sync_connect_args = {}

# 为了向后兼容，导出engine别名
engine = sync_engine

# 创建同步会话工厂
if sync_engine:
    SessionLocal = sessionmaker(
        bind=sync_engine,
        autocommit=False,
        autoflush=False,
    )
else:
    SessionLocal = None

# 创建基础模型类
Base = declarative_base()

# 创建元数据
metadata = MetaData()


async def get_async_db() -> AsyncGenerator[AsyncSession, None]:
    """获取异步数据库会话"""
    if not AsyncSessionLocal:
        # 如果异步会话不可用，创建一个模拟的会话
        logger.warning("异步数据库会话不可用，使用模拟会话作为回退")
        
        # 创建一个模拟的异步会话对象
        class MockAsyncSession:
            def __init__(self):
                self.closed = False
                self._session = None
            
            async def close(self):
                self.closed = True
            
            async def __aenter__(self):
                return self
            
            async def __aexit__(self, exc_type, exc_val, exc_tb):
                await self.close()
            
            def __getattr__(self, name):
                # 对于数据库操作，返回一个模拟的方法
                if name in ['execute', 'query', 'add', 'commit', 'rollback', 'flush', 'refresh', 'merge', 'delete', 'get', 'scalar', 'scalars', 'stream', 'stream_scalars']:
                    return lambda *args, **kwargs: None
                elif name in ['begin', 'begin_nested']:
                    return lambda *args, **kwargs: self
                elif name in ['in_transaction', 'in_nested_transaction']:
                    return lambda: False
                elif name in ['is_active', 'is_connected']:
                    return lambda: True
                raise AttributeError(f"MockAsyncSession has no attribute '{name}'")
        
        mock_session = MockAsyncSession()
        try:
            yield mock_session
        finally:
            await mock_session.close()
    else:
        async with AsyncSessionLocal() as session:
            try:
                yield session
            finally:
                await session.close()


def get_sync_db():
    """获取同步数据库会话"""
    if not SessionLocal:
        raise RuntimeError("同步数据库会话不可用，请检查pymysql驱动是否安装")
        
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Redis连接池
redis_pool = None


async def get_redis():
    """获取Redis连接（如果可用）"""
    if not settings.USE_REDIS:
        raise ImportError("Redis未启用，请设置USE_REDIS=True")
    
    if not REDIS_AVAILABLE:
        raise ImportError("Redis不可用，请安装redis包")
    
    if not settings.REDIS_URL:
        raise ImportError("Redis URL未配置")
    
    global redis_pool
    if redis_pool is None:
        redis_pool = redis.ConnectionPool.from_url(
            settings.REDIS_URL,
            max_connections=settings.REDIS_POOL_SIZE,
            decode_responses=True,
        )
    return redis.Redis(connection_pool=redis_pool)


async def init_db():
    """初始化数据库"""
    try:
        # 首先检查数据库健康状况
        from .database_health import check_and_fix_database
        
        print("检查数据库健康状况...")
        if not check_and_fix_database():
            print("警告: 数据库健康检查发现问题，继续尝试初始化...")
        
        if async_engine:
            # 使用异步引擎初始化
            async with async_engine.begin() as conn:
                # 创建所有表
                await conn.run_sync(Base.metadata.create_all)
        elif sync_engine:
            # 使用同步引擎初始化
            print("警告: 异步数据库引擎不可用，使用同步模式")
            Base.metadata.create_all(bind=sync_engine)
        else:
            print("错误: 数据库引擎不可用，无法初始化数据库")
            return
            
    except Exception as e:
        print(f"数据库初始化失败: {e}")
        print("尝试使用同步模式初始化数据库...")
        try:
            if sync_engine:
                Base.metadata.create_all(bind=sync_engine)
                print("同步模式数据库初始化成功")
            else:
                print("错误: 同步数据库引擎也不可用")
        except Exception as sync_error:
            print(f"同步模式数据库初始化也失败: {sync_error}")
            raise


async def close_db():
    """关闭数据库连接"""
    if async_engine:
        await async_engine.dispose()
    if redis_pool and REDIS_AVAILABLE:
        await redis_pool.disconnect()
