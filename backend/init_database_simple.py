"""
简化的数据库初始化脚本
"""
import asyncio
import logging
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import text
import os

# 设置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 数据库配置
DATABASE_URL = os.getenv("DATABASE_URL", "mysql://ipv6wgm:password@localhost:3306/ipv6wgm")
ASYNC_DATABASE_URL = DATABASE_URL.replace("mysql://", "mysql+aiomysql://")

async def init_database():
    """初始化数据库"""
    try:
        # 创建异步引擎
        engine = create_async_engine(
            ASYNC_DATABASE_URL,
            echo=False,
            pool_pre_ping=True,
            pool_recycle=3600
        )
        
        # 测试连接
        async with engine.begin() as conn:
            result = await conn.execute(text("SELECT 1"))
            logger.info("Database connection successful")
        
        # 创建表
        from app.models.models_complete import Base
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
            logger.info("Database tables created successfully")
        
        # 创建默认用户
        await create_default_user(engine)
        
        await engine.dispose()
        logger.info("Database initialization completed successfully")
        return True
        
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        return False

async def create_default_user(engine):
    """创建默认管理员用户"""
    try:
        from app.core.security_enhanced import security_manager
        from app.models.models_complete import User
        
        async_session = async_sessionmaker(engine, expire_on_commit=False)
        
        async with async_session() as session:
            # 检查是否已存在管理员用户
            result = await session.execute(
                text("SELECT id FROM users WHERE username = 'admin'")
            )
            existing_user = result.fetchone()
            
            if not existing_user:
                # 创建默认管理员用户
                hashed_password = security_manager.get_password_hash("admin123")
                
                await session.execute(
                    text("""
                        INSERT INTO users (username, email, hashed_password, is_active, is_superuser, created_at, updated_at)
                        VALUES ('admin', 'admin@example.com', :password, 1, 1, NOW(), NOW())
                    """),
                    {"password": hashed_password}
                )
                
                await session.commit()
                logger.info("Default admin user created successfully")
            else:
                logger.info("Admin user already exists")
                
    except Exception as e:
        logger.error(f"Failed to create default user: {e}")

if __name__ == "__main__":
    asyncio.run(init_database())
