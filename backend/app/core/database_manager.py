"""
数据库连接和错误处理模块
提供健壮的数据库连接管理和错误处理
"""

import asyncio
import logging
from typing import Optional, Dict, Any
from contextlib import asynccontextmanager
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.exc import SQLAlchemyError, OperationalError, IntegrityError
from sqlalchemy.pool import QueuePool
from sqlalchemy import event, text
import structlog

from .unified_config import settings
from .exception_handlers import DatabaseError, ErrorCodes

logger = structlog.get_logger()

class DatabaseManager:
    """数据库管理器"""
    
    def __init__(self):
        self.engine = None
        self.session_factory = None
        self._connection_pool = None
        self._is_connected = False
        self._retry_count = 0
        self._max_retries = 3
    
    async def initialize(self) -> bool:
        """初始化数据库连接"""
        try:
            # 创建异步引擎
            self.engine = create_async_engine(
                settings.DATABASE_URL,
                poolclass=QueuePool,
                pool_size=settings.DATABASE_POOL_SIZE,
                max_overflow=settings.DATABASE_MAX_OVERFLOW,
                pool_timeout=settings.DATABASE_CONNECT_TIMEOUT,
                pool_recycle=settings.DATABASE_POOL_RECYCLE,
                pool_pre_ping=settings.DATABASE_POOL_PRE_PING,
                echo=settings.DEBUG,
                echo_pool=settings.DEBUG,
            )
            
            # 创建会话工厂
            self.session_factory = async_sessionmaker(
                self.engine,
                class_=AsyncSession,
                expire_on_commit=False
            )
            
            # 测试连接
            await self.test_connection()
            
            # 注册事件监听器
            self._register_event_listeners()
            
            self._is_connected = True
            logger.info("数据库连接初始化成功")
            return True
            
        except Exception as e:
            logger.error("数据库连接初始化失败", error=str(e))
            raise DatabaseError(f"数据库初始化失败: {str(e)}", e)
    
    async def test_connection(self) -> bool:
        """测试数据库连接"""
        try:
            async with self.engine.begin() as conn:
                await conn.execute(text("SELECT 1"))
            logger.debug("数据库连接测试成功")
            return True
        except Exception as e:
            logger.error("数据库连接测试失败", error=str(e))
            raise DatabaseError(f"数据库连接测试失败: {str(e)}", e)
    
    def _register_event_listeners(self):
        """注册数据库事件监听器"""
        
        @event.listens_for(self.engine.sync_engine, "connect")
        def set_sqlite_pragma(dbapi_connection, connection_record):
            """设置数据库连接参数"""
            if "sqlite" in str(dbapi_connection):
                cursor = dbapi_connection.cursor()
                cursor.execute("PRAGMA foreign_keys=ON")
                cursor.close()
        
        @event.listens_for(self.engine.sync_engine, "checkout")
        def receive_checkout(dbapi_connection, connection_record, connection_proxy):
            """连接检出事件"""
            logger.debug("数据库连接检出")
        
        @event.listens_for(self.engine.sync_engine, "checkin")
        def receive_checkin(dbapi_connection, connection_record):
            """连接检入事件"""
            logger.debug("数据库连接检入")
    
    @asynccontextmanager
    async def get_session(self):
        """获取数据库会话上下文管理器"""
        if not self._is_connected:
            await self.initialize()
        
        session = self.session_factory()
        try:
            yield session
            await session.commit()
        except Exception as e:
            await session.rollback()
            logger.error("数据库会话错误", error=str(e))
            raise DatabaseError(f"数据库操作失败: {str(e)}", e)
        finally:
            await session.close()
    
    async def execute_with_retry(self, operation, *args, **kwargs):
        """带重试的数据库操作"""
        for attempt in range(self._max_retries):
            try:
                return await operation(*args, **kwargs)
            except OperationalError as e:
                if attempt < self._max_retries - 1:
                    logger.warning(
                        "数据库操作失败，正在重试",
                        attempt=attempt + 1,
                        max_retries=self._max_retries,
                        error=str(e)
                    )
                    await asyncio.sleep(2 ** attempt)  # 指数退避
                    continue
                else:
                    logger.error("数据库操作重试失败", error=str(e))
                    raise DatabaseError(f"数据库操作失败: {str(e)}", e)
            except IntegrityError as e:
                logger.error("数据完整性错误", error=str(e))
                raise DatabaseError(f"数据完整性约束违反: {str(e)}", e)
            except SQLAlchemyError as e:
                logger.error("SQLAlchemy错误", error=str(e))
                raise DatabaseError(f"数据库错误: {str(e)}", e)
    
    async def health_check(self) -> Dict[str, Any]:
        """数据库健康检查"""
        try:
            async with self.get_session() as session:
                # 检查连接
                result = await session.execute(text("SELECT 1 as health"))
                health_status = result.scalar()
                
                # 检查连接池状态
                pool = self.engine.pool
                pool_status = {
                    "size": pool.size(),
                    "checked_in": pool.checkedin(),
                    "checked_out": pool.checkedout(),
                    "overflow": pool.overflow(),
                    "invalid": pool.invalid()
                }
                
                return {
                    "status": "healthy" if health_status == 1 else "unhealthy",
                    "connection_test": health_status,
                    "pool_status": pool_status,
                    "database_url": settings.DATABASE_URL.split("@")[-1] if "@" in settings.DATABASE_URL else "hidden"
                }
                
        except Exception as e:
            logger.error("数据库健康检查失败", error=str(e))
            return {
                "status": "unhealthy",
                "error": str(e),
                "database_url": "hidden"
            }
    
    async def close(self):
        """关闭数据库连接"""
        if self.engine:
            await self.engine.dispose()
            self._is_connected = False
            logger.info("数据库连接已关闭")

# 全局数据库管理器实例
db_manager = DatabaseManager()

# 便捷函数
async def get_db_session():
    """获取数据库会话"""
    async with db_manager.get_session() as session:
        yield session

async def init_database():
    """初始化数据库"""
    await db_manager.initialize()

async def close_database():
    """关闭数据库连接"""
    await db_manager.close()

async def check_database_health():
    """检查数据库健康状态"""
    return await db_manager.health_check()

# 数据库操作装饰器
def with_db_session(func):
    """数据库会话装饰器"""
    async def wrapper(*args, **kwargs):
        async with db_manager.get_session() as session:
            kwargs['db'] = session
            return await func(*args, **kwargs)
    return wrapper

def with_db_retry(max_retries: int = 3):
    """数据库重试装饰器"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            return await db_manager.execute_with_retry(func, *args, **kwargs)
        return wrapper
    return decorator

# 数据库事务管理
class TransactionManager:
    """事务管理器"""
    
    def __init__(self, session: AsyncSession):
        self.session = session
        self._transaction_started = False
    
    async def begin(self):
        """开始事务"""
        if not self._transaction_started:
            await self.session.begin()
            self._transaction_started = True
    
    async def commit(self):
        """提交事务"""
        if self._transaction_started:
            await self.session.commit()
            self._transaction_started = False
    
    async def rollback(self):
        """回滚事务"""
        if self._transaction_started:
            await self.session.rollback()
            self._transaction_started = False
    
    async def __aenter__(self):
        await self.begin()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if exc_type is not None:
            await self.rollback()
        else:
            await self.commit()

@asynccontextmanager
async def database_transaction():
    """数据库事务上下文管理器"""
    async with db_manager.get_session() as session:
        async with TransactionManager(session) as tx:
            yield tx