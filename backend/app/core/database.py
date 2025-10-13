"""
数据库配置和连接管理
"""
import os
from sqlalchemy import create_engine, MetaData, text
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
    
    # 检查数据库连接是否可用
    try:
        if asyncpg_available:
            # 测试异步连接
            async_engine = create_async_engine(
                async_db_url,
                pool_size=settings.DATABASE_POOL_SIZE,
                max_overflow=settings.DATABASE_MAX_OVERFLOW,
                pool_pre_ping=True,
                pool_recycle=3600,
                echo=settings.DEBUG,
                connect_args={
                    "server_settings": {
                        "jit": "off"
                    },
                    "timeout": settings.DATABASE_CONNECT_TIMEOUT,
                    "command_timeout": settings.DATABASE_STATEMENT_TIMEOUT
                }
            )
            
            # 测试连接
            import asyncio
            async def test_async_connection():
                try:
                    async with async_engine.connect() as conn:
                        await conn.execute(text("SELECT 1"))
                    return True
                except Exception:
                    return False
            
            # 在Windows上使用不同的策略
            if os.name == 'nt':
                # Windows环境，使用线程池执行
                import concurrent.futures
                with concurrent.futures.ThreadPoolExecutor() as executor:
                    connection_ok = executor.submit(asyncio.run, test_async_connection()).result()
            else:
                # Linux环境，直接运行
                connection_ok = asyncio.run(test_async_connection())
            
            if not connection_ok:
                print("警告: 异步数据库连接测试失败，使用同步模式")
                async_engine = None
        else:
            async_engine = None
    except Exception as e:
        print(f"警告: 异步数据库连接失败，使用同步模式: {e}")
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
    try:
        # 首先检查数据库健康状况
        from .database_health import check_and_fix_database
        
        print("检查数据库健康状况...")
        if not check_and_fix_database():
            print("警告: 数据库健康检查发现问题，继续尝试初始化...")
        
        if not async_engine:
            # 如果异步引擎不可用，使用同步引擎
            print("警告: 异步数据库引擎不可用，使用同步模式")
            Base.metadata.create_all(bind=sync_engine)
            return
        
        async with async_engine.begin() as conn:
            # 创建所有表
            await conn.run_sync(Base.metadata.create_all)
    except Exception as e:
        print(f"数据库初始化失败: {e}")
        print("尝试使用同步模式初始化数据库...")
        try:
            Base.metadata.create_all(bind=sync_engine)
            print("同步模式数据库初始化成功")
        except Exception as sync_error:
            print(f"同步模式数据库初始化也失败: {sync_error}")
            raise


async def close_db():
    """关闭数据库连接"""
    if async_engine:
        await async_engine.dispose()
    if redis_pool:
        await redis_pool.disconnect()
