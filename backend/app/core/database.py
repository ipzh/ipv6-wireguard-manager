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
async_engine = create_async_engine(
    settings.DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://"),
    pool_size=settings.DATABASE_POOL_SIZE,
    max_overflow=settings.DATABASE_MAX_OVERFLOW,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=settings.DEBUG,
)

# 创建异步会话工厂
AsyncSessionLocal = async_sessionmaker(
    bind=async_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)

# 创建同步数据库引擎（用于Alembic迁移）
sync_engine = create_engine(
    settings.DATABASE_URL,
    pool_size=settings.DATABASE_POOL_SIZE,
    max_overflow=settings.DATABASE_MAX_OVERFLOW,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=settings.DEBUG,
)

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
    async with async_engine.begin() as conn:
        # 创建所有表
        await conn.run_sync(Base.metadata.create_all)


async def close_db():
    """关闭数据库连接"""
    await async_engine.dispose()
    if redis_pool:
        await redis_pool.disconnect()
