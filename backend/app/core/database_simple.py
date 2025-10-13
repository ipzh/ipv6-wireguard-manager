"""
简化的数据库配置（用于修复启动问题）
"""
from sqlalchemy import create_engine, MetaData
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# 创建基础模型类
Base = declarative_base()

# 创建元数据
metadata = MetaData()

# 数据库URL
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://ipv6wgm:ipv6wgm123@localhost:5432/ipv6wgm")

# 创建同步数据库引擎（带连接重试机制）
def create_engine_with_retry():
    """创建带重试机制的数据库引擎"""
    import time
    max_retries = 3
    retry_delay = 5
    
    for attempt in range(max_retries):
        try:
            # 根据数据库类型设置不同的连接参数
            if DATABASE_URL.startswith("sqlite://"):
                # SQLite数据库不需要连接超时参数
                engine = create_engine(
                    DATABASE_URL,
                    pool_size=10,
                    max_overflow=20,
                    pool_pre_ping=True,
                    pool_recycle=3600,
                    echo=False,
                    connect_args={
                        "check_same_thread": False
                    }
                )
            else:
                # PostgreSQL数据库使用完整的连接参数
                engine = create_engine(
                    DATABASE_URL,
                    pool_size=10,
                    max_overflow=20,
                    pool_pre_ping=True,
                    pool_recycle=3600,
                    echo=False,
                    connect_args={
                        "connect_timeout": 30,
                        "application_name": "ipv6-wireguard-manager"
                    }
                )
            
            # 测试连接
            with engine.connect() as conn:
                if DATABASE_URL.startswith("sqlite://"):
                    # SQLite连接测试 - 使用text()包装器
                    from sqlalchemy import text
                    conn.execute(text("SELECT 1"))
                else:
                    # PostgreSQL连接测试
                    from sqlalchemy import text
                    conn.execute(text("SELECT 1"))
            return engine
        except Exception as e:
            if attempt < max_retries - 1:
                print(f"数据库连接失败，{retry_delay}秒后重试 (尝试 {attempt + 1}/{max_retries}): {e}")
                time.sleep(retry_delay)
            else:
                print(f"数据库连接失败，使用内存数据库模式: {e}")
                # 创建内存SQLite引擎作为后备
                return create_engine("sqlite:///:memory:", echo=False)

engine = create_engine_with_retry()

# 创建会话工厂
SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
)

# 为了兼容性，导出sync_engine
sync_engine = engine

def get_db():
    """获取数据库会话"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """初始化数据库"""
    Base.metadata.create_all(bind=engine)

def close_db():
    """关闭数据库连接"""
    engine.dispose()
