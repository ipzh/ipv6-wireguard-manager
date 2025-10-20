"""
数据库配置和连接管理（重构版）
"""
from typing import AsyncGenerator

from .database_manager import (
    database_manager, 
    get_async_db, 
    get_sync_db,
    Base,
    DatabaseMode,
    DatabaseType
)
from .config_enhanced import settings
from .logging import get_logger

logger = get_logger(__name__)

# 为了向后兼容，保留原有导出
engine = database_manager.sync_engine
AsyncSessionLocal = database_manager.async_session_factory
SessionLocal = database_manager.sync_session_factory

# 兼容性函数
def get_db():
    """获取数据库会话（兼容性函数，优先使用异步，回退到同步）"""
    if database_manager.async_session_factory:
        return get_async_db()
    else:
        return get_sync_db()

# 初始化和关闭函数
async def init_db():
    """初始化数据库"""
    try:
        # 检查数据库健康状况
        from .database_health_enhanced import check_and_fix_database
        
        logger.info("检查数据库健康状况...")
        if not await check_and_fix_database():
            logger.warning("数据库健康检查发现问题，继续尝试初始化...")
            
        # 使用数据库管理器初始化
        if database_manager.async_engine:
            async with database_manager.async_engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
        elif database_manager.sync_engine:
            logger.warning("异步数据库引擎不可用，使用同步模式")
            Base.metadata.create_all(bind=database_manager.sync_engine)
        else:
            logger.error("数据库引擎不可用，无法初始化数据库")
            return
            
    except Exception as e:
        logger.error(f"数据库初始化失败: {e}")
        raise

async def close_db():
    """关闭数据库连接"""
    await database_manager.close()

# Redis连接池（保持原有功能）
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

# Redis连接池
redis_pool = None
if REDIS_AVAILABLE and getattr(settings, 'USE_REDIS', False):
    try:
        redis_pool = redis.ConnectionPool.from_url(
            getattr(settings, 'REDIS_URL', 'redis://localhost:${REDIS_PORT}/0'),
            max_connections=20,
            retry_on_timeout=True
        )
        logger.info("Redis连接池创建成功")
    except Exception as e:
        logger.warning(f"Redis连接池创建失败: {e}")
        redis_pool = None