"""
数据库配置管理
"""
from typing import Dict, Any, Optional
from pydantic import BaseModel, field_validator
from enum import Enum

class DatabaseType(str, Enum):
    """数据库类型枚举"""
    MYSQL = "mysql"
    POSTGRESQL = "postgresql"
    SQLITE = "sqlite"

class DatabaseConfig(BaseModel):
    """数据库配置类"""
    
    # 基础配置
    database_url: str
    database_type: DatabaseType
    pool_size: int = 10
    max_overflow: int = 15
    connect_timeout: int = 30
    pool_recycle: int = 3600
    pool_pre_ping: bool = True
    
    # 高级配置
    statement_timeout: int = 30000
    idle_in_transaction_session_timeout: int = 10000
    auto_create_database: bool = True
    
    # 连接池配置
    pool_timeout: int = 30
    pool_reset_on_return: str = "commit"
    
    # 回退配置
    use_fallback: bool = False
    fallback_database_url: Optional[str] = None
    
    @field_validator('database_type', mode='before')
    @classmethod
    def extract_database_type(cls, v, info):
        if isinstance(v, str):
            return v
        elif 'database_url' in info.data:
            url = info.data['database_url']
            if url.startswith("mysql://"):
                return DatabaseType.MYSQL
            elif url.startswith("postgresql://"):
                return DatabaseType.POSTGRESQL
            elif url.startswith("sqlite://"):
                return DatabaseType.SQLITE
        raise ValueError("无法确定数据库类型")
    
    def get_connection_args(self, is_async: bool = False) -> Dict[str, Any]:
        """获取连接参数"""
        base_args = {
            "connect_timeout": self.connect_timeout,
            "charset": "utf8mb4" if self.database_type == DatabaseType.MYSQL else "utf8",
            "autocommit": False,
            "use_unicode": True,
        }
        
        # 根据数据库类型添加特定参数
        if self.database_type == DatabaseType.MYSQL:
            base_args["sql_mode"] = "TRADITIONAL"
        elif self.database_type == DatabaseType.POSTGRESQL:
            base_args["application_name"] = "IPv6 WireGuard Manager"
        
        return base_args
    
    def get_pool_args(self, is_async: bool = False) -> Dict[str, Any]:
        """获取连接池参数"""
        # 根据模式调整连接池大小
        pool_size = self.pool_size
        max_overflow = self.max_overflow
        
        # 异步模式通常可以支持更多连接
        if is_async:
            pool_size = min(pool_size, 20)
            max_overflow = min(max_overflow, 10)
        else:
            pool_size = min(pool_size, 10)
            max_overflow = min(max_overflow, 5)
        
        return {
            "pool_size": pool_size,
            "max_overflow": max_overflow,
            "pool_pre_ping": self.pool_pre_ping,
            "pool_recycle": self.pool_recycle,
            "pool_timeout": self.pool_timeout,
            "pool_reset_on_return": self.pool_reset_on_return
        }
    
    def get_async_url(self) -> str:
        """获取异步数据库URL"""
        if self.database_type == DatabaseType.MYSQL:
            return self.database_url.replace("mysql://", "mysql+aiomysql://")
        elif self.database_type == DatabaseType.POSTGRESQL:
            return self.database_url.replace("postgresql://", "postgresql+asyncpg://")
        elif self.database_type == DatabaseType.SQLITE:
            return self.database_url.replace("sqlite://", "sqlite+aiosqlite://")
        return self.database_url
    
    def get_sync_url(self) -> str:
        """获取同步数据库URL"""
        if self.database_type == DatabaseType.MYSQL:
            return self.database_url.replace("mysql://", "mysql+pymysql://")
        elif self.database_type == DatabaseType.POSTGRESQL:
            return self.database_url.replace("postgresql://", "postgresql+psycopg2://")
        return self.database_url

def create_database_config(settings) -> DatabaseConfig:
    """从应用设置创建数据库配置"""
    return DatabaseConfig(
        database_url=settings.DATABASE_URL,
        pool_size=getattr(settings, 'DATABASE_POOL_SIZE', 10),
        max_overflow=getattr(settings, 'DATABASE_MAX_OVERFLOW', 15),
        connect_timeout=getattr(settings, 'DATABASE_CONNECT_TIMEOUT', 30),
        statement_timeout=getattr(settings, 'DATABASE_STATEMENT_TIMEOUT', 30000),
        idle_in_transaction_session_timeout=getattr(settings, 'DATABASE_IDLE_IN_TRANSACTION_SESSION_TIMEOUT', 10000),
        pool_recycle=getattr(settings, 'DATABASE_POOL_RECYCLE', 3600),
        pool_pre_ping=getattr(settings, 'DATABASE_POOL_PRE_PING', True),
        auto_create_database=getattr(settings, 'AUTO_CREATE_DATABASE', True),
    )
