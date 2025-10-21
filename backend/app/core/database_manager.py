"""
统一的数据库连接管理器
"""
import logging
from typing import Optional, Dict, Any, Union, AsyncGenerator
from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.pool import QueuePool
from contextlib import asynccontextmanager, contextmanager
from enum import Enum

from .config_enhanced import settings

logger = logging.getLogger(__name__)

class DatabaseMode(Enum):
    """数据库模式枚举"""
    ASYNC = "async"
    SYNC = "sync"
    HYBRID = "hybrid"  # 混合模式，同时支持异步和同步

class DatabaseType(Enum):
    """数据库类型枚举"""
    MYSQL = "mysql"
    POSTGRESQL = "postgresql"
    # 不再支持SQLite

class DatabaseManager:
    """统一的数据库连接管理器"""
    
    def __init__(self, mode: DatabaseMode = DatabaseMode.HYBRID):
        self.mode = mode
        self.async_engine: Optional[Any] = None
        self.sync_engine: Optional[Any] = None
        self.async_session_factory: Optional[async_sessionmaker] = None
        self.sync_session_factory: Optional[sessionmaker] = None
        self.database_type = self._detect_database_type()
        self._initialize_engines()
    
    def _detect_database_type(self) -> DatabaseType:
        """检测数据库类型 - 强制使用MySQL，仅支持mysql://前缀"""
        if not settings.DATABASE_URL.startswith("mysql://"):
            logger.error("仅支持mysql://前缀的数据库URL")
            logger.info("请将DATABASE_URL修改为mysql://格式")
            raise ValueError(f"仅支持mysql://前缀的数据库URL: {settings.DATABASE_URL}")
        return DatabaseType.MYSQL
    
    def _get_connection_args(self, is_async: bool = False) -> Dict[str, Any]:
        """获取连接参数 - 强制使用MySQL"""
        # 获取连接超时参数并确保类型为整数
        connect_timeout = getattr(settings, 'DATABASE_CONNECT_TIMEOUT', 30)
        try:
            connect_timeout = int(connect_timeout) if connect_timeout is not None else 30
        except (ValueError, TypeError):
            connect_timeout = 30
            
        # 仅保留通用连接参数，避免驱动兼容性问题
        base_args = {
            "connect_timeout": connect_timeout,
            "charset": "utf8mb4",
            "use_unicode": True,
        }
        
        return base_args
    
    def _get_pool_args(self, is_async: bool = False) -> Dict[str, Any]:
        """获取连接池参数"""
        # 根据模式调整连接池大小
        pool_size = getattr(settings, 'DATABASE_POOL_SIZE', 10)
        max_overflow = getattr(settings, 'DATABASE_MAX_OVERFLOW', 15)
        
        # 确保类型为整数
        try:
            pool_size = int(pool_size) if pool_size is not None else 10
            max_overflow = int(max_overflow) if max_overflow is not None else 15
        except (ValueError, TypeError):
            pool_size = 10
            max_overflow = 15
        
        # 异步模式通常可以支持更多连接
        if is_async:
            pool_size = min(pool_size, 20)
            max_overflow = min(max_overflow, 10)
            # 异步引擎不使用QueuePool
            return {
                "pool_size": pool_size,
                "max_overflow": max_overflow,
                "pool_pre_ping": getattr(settings, 'DATABASE_POOL_PRE_PING', True),
                "pool_recycle": getattr(settings, 'DATABASE_POOL_RECYCLE', 3600),
                "pool_timeout": 30,
                "pool_reset_on_return": "commit"
            }
        else:
            pool_size = min(pool_size, 10)
            max_overflow = min(max_overflow, 5)
            # 同步引擎使用QueuePool
            return {
                "pool_size": pool_size,
                "max_overflow": max_overflow,
                "pool_pre_ping": getattr(settings, 'DATABASE_POOL_PRE_PING', True),
                "pool_recycle": getattr(settings, 'DATABASE_POOL_RECYCLE', 3600),
                "pool_timeout": 30,
                "poolclass": QueuePool,
                "pool_reset_on_return": "commit"
            }
    
    def _initialize_engines(self):
        """初始化数据库引擎"""
        try:
            # 初始化异步引擎
            if self.mode in [DatabaseMode.ASYNC, DatabaseMode.HYBRID]:
                self._initialize_async_engine()
            
            # 初始化同步引擎
            if self.mode in [DatabaseMode.SYNC, DatabaseMode.HYBRID]:
                self._initialize_sync_engine()
                
        except Exception as e:
            logger.error(f"数据库引擎初始化失败: {e}")
            raise
    
    def _initialize_async_engine(self):
        """初始化异步数据库引擎 - 强制使用MySQL"""
        # 仅支持MySQL数据库
        if self.database_type != DatabaseType.MYSQL:
            logger.error(f"不支持的数据库类型: {self.database_type}，仅支持MySQL数据库")
            return
        
        try:
            import aiomysql
        except ImportError:
            logger.error("aiomysql驱动未安装，异步引擎初始化失败")
            return
        
        # 强制使用mysql://前缀并转换为异步格式
        if not settings.DATABASE_URL.startswith("mysql://"):
            logger.error(f"无效的数据库URL格式: {settings.DATABASE_URL}，必须以mysql://开头")
            return
            
        # 转换URL为异步格式，统一使用aiomysql驱动
        async_url = settings.DATABASE_URL.replace("mysql://", "mysql+aiomysql://")
        logger.info(f"使用MySQL异步驱动初始化数据库引擎: {async_url}")
        
        try:
            self.async_engine = create_async_engine(
                async_url,
                echo=getattr(settings, 'DEBUG', False),
                connect_args=self._get_connection_args(is_async=True),
                **self._get_pool_args(is_async=True)
            )
            
            self.async_session_factory = async_sessionmaker(
                bind=self.async_engine,
                class_=AsyncSession,
                expire_on_commit=False,
                autoflush=False,
                autocommit=False
            )
            
            logger.info("MySQL异步数据库引擎初始化成功")
            
        except Exception as e:
            logger.error(f"MySQL异步数据库引擎初始化失败: {e}")
            self.async_engine = None
            self.async_session_factory = None
    
    def _initialize_sync_engine(self):
        """初始化同步数据库引擎 - 强制使用MySQL"""
        # 仅支持MySQL数据库
        if self.database_type != DatabaseType.MYSQL:
            logger.error(f"不支持的数据库类型: {self.database_type}，仅支持MySQL数据库")
            return
        
        try:
            import pymysql
        except ImportError:
            logger.error("pymysql驱动未安装，同步引擎初始化失败")
            return
        
        # 强制使用mysql://前缀并转换为pymysql格式
        if not settings.DATABASE_URL.startswith("mysql://"):
            logger.error(f"无效的数据库URL格式: {settings.DATABASE_URL}，必须以mysql://开头")
            return
        
        # 转换URL为pymysql格式，统一使用pymysql驱动
        sync_url = settings.DATABASE_URL.replace("mysql://", "mysql+pymysql://")
        logger.info(f"使用MySQL同步驱动初始化数据库引擎: {sync_url}")
        
        try:
            self.sync_engine = create_engine(
                sync_url,
                echo=getattr(settings, 'DEBUG', False),
                connect_args=self._get_connection_args(is_async=False),
                **self._get_pool_args(is_async=False)
            )
            
            self.sync_session_factory = sessionmaker(
                bind=self.sync_engine,
                autocommit=False,
                autoflush=False
            )
            
            logger.info("MySQL同步数据库引擎初始化成功")
            
        except Exception as e:
            logger.error(f"MySQL同步数据库引擎初始化失败: {e}")
            self.sync_engine = None
            self.sync_session_factory = None
    
    @asynccontextmanager
    async def get_async_session(self) -> AsyncGenerator[AsyncSession, None]:
        """获取异步数据库会话"""
        if not self.async_session_factory:
            raise RuntimeError("异步数据库会话工厂不可用")
        
        async with self.async_session_factory() as session:
            try:
                yield session
            except Exception:
                await session.rollback()
                raise
            finally:
                await session.close()
    
    @contextmanager
    def get_sync_session(self) -> Session:
        """获取同步数据库会话"""
        if not self.sync_session_factory:
            raise RuntimeError("同步数据库会话工厂不可用")
        
        session = self.sync_session_factory()
        try:
            yield session
        except Exception:
            session.rollback()
            raise
        finally:
            session.close()
    
    async def check_connection(self, is_async: bool = True) -> Dict[str, Any]:
        """检查数据库连接状态"""
        result = {
            "status": "unknown",
            "database_type": self.database_type.value,
            "connection_ok": False,
            "error": None,
            "details": {}
        }
        
        try:
            if is_async and self.async_engine:
                async with self.async_engine.begin() as conn:
                    await conn.execute(text("SELECT 1"))
                    result["connection_ok"] = True
                    result["status"] = "healthy"
            elif not is_async and self.sync_engine:
                with self.sync_engine.begin() as conn:
                    conn.execute(text("SELECT 1"))
                    result["connection_ok"] = True
                    result["status"] = "healthy"
            else:
                result["error"] = f"{'异步' if is_async else '同步'}数据库引擎不可用"
                result["status"] = "engine_unavailable"
                
        except Exception as e:
            result["error"] = str(e)
            result["status"] = "connection_failed"
            logger.error(f"数据库连接检查失败: {e}")
            
        return result
    
    async def close(self):
        """关闭数据库连接"""
        if self.async_engine:
            await self.async_engine.dispose()
        if self.sync_engine:
            self.sync_engine.dispose()
        logger.info("数据库连接已关闭")

# 创建全局数据库管理器实例
database_manager = DatabaseManager(
    mode=DatabaseMode.HYBRID  # 默认使用混合模式
)

# 导出便捷函数
async def get_async_db() -> AsyncGenerator[AsyncSession, None]:
    """获取异步数据库会话（便捷函数）"""
    async with database_manager.get_async_session() as session:
        yield session

def get_sync_db():
    """获取同步数据库会话（便捷函数）"""
    with database_manager.get_sync_session() as session:
        yield session

# 创建基础模型类
Base = declarative_base()
