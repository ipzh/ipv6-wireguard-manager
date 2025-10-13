"""
数据库配置和连接管理
"""
from sqlalchemy import create_engine, MetaData
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
import redis.asyncio as redis
from typing import AsyncGenerator

from .config import settings

# 创建异步数据库引擎
# 检查数据库类型并创建相应的引擎
if settings.DATABASE_URL.startswith("postgresql://"):
    # PostgreSQL数据库
    async_db_url = settings.DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")
    
    # 检查是否安装了asyncpg驱动
    try:
        import asyncpg
        asyncpg_available = True
    except ImportError:
        asyncpg_available = False
        print("警告: asyncpg驱动未安装，将使用同步模式")
    
    if asyncpg_available:
        async_engine = create_async_engine(
            async_db_url,
            pool_size=settings.DATABASE_POOL_SIZE,
            max_overflow=settings.DATABASE_MAX_OVERFLOW,
            pool_pre_ping=True,
            pool_recycle=3600,
            echo=settings.DEBUG,
        )
    else:
        # 如果asyncpg不可用，设置为None
        async_engine = None
else:
    # SQLite数据库（不支持异步）
    async_engine = None
    print("使用SQLite数据库（同步模式）")

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

# 创建同步数据库引擎（用于Alembic迁移）
sync_engine = create_engine(
    settings.DATABASE_URL,
    pool_size=settings.DATABASE_POOL_SIZE,
    max_overflow=settings.DATABASE_MAX_OVERFLOW,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=settings.DEBUG,
)

# 为了向后兼容，导出engine别名
engine = sync_engine

# 创建同步会话工厂
SessionLocal = sessionmaker(
    bind=sync_engine,
    autocommit=False,
    autoflush=False,
)

# 创建基础模型类
Base = declarative_base()

# 创建元数据
metadata = MetaData()


async def get_async_db() -> AsyncGenerator[AsyncSession, None]:
    """获取异步数据库会话"""
    if not AsyncSessionLocal:
        raise RuntimeError("异步数据库会话不可用，请检查asyncpg驱动是否安装")
    
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


def get_sync_db():
    """获取同步数据库会话"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Redis连接池
redis_pool = None


async def get_redis() -> redis.Redis:
    """获取Redis连接"""
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
    if not async_engine:
        raise RuntimeError("异步数据库引擎不可用，请检查数据库配置和asyncpg驱动")
    
    async with async_engine.begin() as conn:
        # 创建所有表
        await conn.run_sync(Base.metadata.create_all)


async def close_db():
    """关闭数据库连接"""
    if async_engine:
        await async_engine.dispose()
    if redis_pool:
        await redis_pool.disconnect()
