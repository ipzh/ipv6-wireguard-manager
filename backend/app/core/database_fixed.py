"""
修复的数据库配置（解决异步驱动问题）
"""
from sqlalchemy import create_engine, MetaData
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
import redis.asyncio as redis
from typing import AsyncGenerator
import os

from .config import settings

# 创建基础模型类
Base = declarative_base()

# 创建元数据
metadata = MetaData()

# 修复异步数据库引擎创建
def create_fixed_async_engine():
    """创建修复的异步数据库引擎"""
    # 确保使用正确的异步驱动
    db_url = settings.DATABASE_URL
    
    # 如果是PostgreSQL URL，确保使用asyncpg驱动
    if db_url.startswith("postgresql://"):
        if "+asyncpg" not in db_url:
            db_url = db_url.replace("postgresql://", "postgresql+asyncpg://")
    
    # 如果是SQLite URL，使用同步引擎（SQLite不支持异步）
    elif db_url.startswith("sqlite://"):
        # SQLite不支持异步，使用同步引擎
        return None
    
    try:
        async_engine = create_async_engine(
            db_url,
            pool_size=settings.DATABASE_POOL_SIZE,
            max_overflow=settings.DATABASE_MAX_OVERFLOW,
            pool_pre_ping=True,
            pool_recycle=3600,
            echo=settings.DEBUG,
        )
        return async_engine
    except Exception as e:
        print(f"创建异步引擎失败: {e}")
        return None

# 创建同步数据库引擎（用于Alembic迁移和SQLite）
def create_fixed_sync_engine():
    """创建修复的同步数据库引擎"""
    db_url = settings.DATABASE_URL
    
    # 如果是PostgreSQL URL，确保使用psycopg2驱动
    if db_url.startswith("postgresql://"):
        if "+psycopg2" not in db_url and "+asyncpg" not in db_url:
            db_url = db_url.replace("postgresql://", "postgresql+psycopg2://")
    
    try:
        sync_engine = create_engine(
            db_url,
            pool_size=settings.DATABASE_POOL_SIZE,
            max_overflow=settings.DATABASE_MAX_OVERFLOW,
            pool_pre_ping=True,
            pool_recycle=3600,
            echo=settings.DEBUG,
        )
        return sync_engine
    except Exception as e:
        print(f"创建同步引擎失败: {e}")
        return None

# 创建引擎
async_engine = create_fixed_async_engine()
sync_engine = create_fixed_sync_engine()

# 为了向后兼容，导出engine别名
engine = sync_engine

# 创建异步会话工厂（如果异步引擎可用）
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

# 创建同步会话工厂
if sync_engine:
    SessionLocal = sessionmaker(
        bind=sync_engine,
        autocommit=False,
        autoflush=False,
    )
else:
    SessionLocal = None


async def get_async_db() -> AsyncGenerator[AsyncSession, None]:
    """获取异步数据库会话"""
    if not AsyncSessionLocal:
        raise RuntimeError("异步数据库会话不可用")
    
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


def get_sync_db():
    """获取同步数据库会话"""
    if not SessionLocal:
        raise RuntimeError("同步数据库会话不可用")
    
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
    if async_engine:
        async with async_engine.begin() as conn:
            # 创建所有表
            await conn.run_sync(Base.metadata.create_all)
    elif sync_engine:
        Base.metadata.create_all(bind=sync_engine)


async def close_db():
    """关闭数据库连接"""
    if async_engine:
        await async_engine.dispose()
    if sync_engine:
        sync_engine.dispose()
    if redis_pool:
        await redis_pool.disconnect()