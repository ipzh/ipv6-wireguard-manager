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

# 创建同步数据库引擎
engine = create_engine(
    DATABASE_URL,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=False,
)

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
