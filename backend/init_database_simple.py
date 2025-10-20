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

# 数据库配置 - 仅支持MySQL
DATABASE_URL = os.getenv("DATABASE_URL", "mysql://ipv6wgm:password@localhost:3306/ipv6wgm")

# 检查是否为MySQL数据库，如果不是则退出
if not DATABASE_URL.startswith("mysql://") and not DATABASE_URL.startswith("mysql+aiomysql://"):
    logger.error("仅支持MySQL数据库，请确保DATABASE_URL使用mysql://或mysql+aiomysql://格式")
    exit(1)

# 确保使用aiomysql异步驱动
if DATABASE_URL.startswith("mysql://"):
    ASYNC_DATABASE_URL = DATABASE_URL.replace("mysql://", "mysql+aiomysql://")
else:
    ASYNC_DATABASE_URL = DATABASE_URL

logger.info(f"使用异步数据库URL: {ASYNC_DATABASE_URL}")

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
        
        # 创建表（包括增强功能表）
        from app.models.models_complete import Base
        from app.models.enhanced_models import Base as EnhancedBase
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
            await conn.run_sync(EnhancedBase.metadata.create_all)
            logger.info("Database tables (including enhanced features) created successfully")
        
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
        from app.models.enhanced_models import (
            PasswordHistory, MFASettings, MFASession, UserSession,
            AlertRule, Alert, NotificationConfig, CacheStats,
            PerformanceMetrics, SystemMetrics, SecurityLog,
            APIAccessLog, SystemConfig, HealthCheck
        )
        
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
                
                # 获取新创建的用户ID
                result = await session.execute(
                    text("SELECT id FROM users WHERE username = 'admin'")
                )
                user_id = result.fetchone()[0]
                
                # 创建默认MFA设置
                await session.execute(
                    text("""
                        INSERT INTO mfa_settings (user_id, totp_enabled, backup_codes, created_at, updated_at)
                        VALUES (:user_id, 0, '[]', NOW(), NOW())
                    """),
                    {"user_id": user_id}
                )
                
                # 创建默认系统配置
                await session.execute(
                    text("""
                        INSERT INTO system_config (key, value, description, created_at, updated_at)
                        VALUES 
                        ('password_policy_enabled', 'true', '密码策略启用状态', NOW(), NOW()),
                        ('mfa_required', 'false', '是否强制要求MFA', NOW(), NOW()),
                        ('rate_limit_enabled', 'true', 'API限流启用状态', NOW(), NOW()),
                        ('monitoring_enabled', 'true', '监控功能启用状态', NOW(), NOW()),
                        ('alert_email', 'admin@example.com', '告警邮件地址', NOW(), NOW())
                    """)
                )
                
                # 创建默认告警规则
                await session.execute(
                    text("""
                        INSERT INTO alert_rules (name, description, metric_type, threshold_value, severity, is_enabled, created_at, updated_at)
                        VALUES 
                        ('CPU使用率告警', 'CPU使用率超过80%时告警', 'cpu_usage', 80.0, 'warning', 1, NOW(), NOW()),
                        ('内存使用率告警', '内存使用率超过85%时告警', 'memory_usage', 85.0, 'warning', 1, NOW(), NOW()),
                        ('磁盘使用率告警', '磁盘使用率超过90%时告警', 'disk_usage', 90.0, 'critical', 1, NOW(), NOW()),
                        ('API错误率告警', 'API错误率超过5%时告警', 'api_error_rate', 5.0, 'warning', 1, NOW(), NOW())
                    """)
                )
                
                await session.commit()
                logger.info("Default admin user and enhanced features initialized successfully")
            else:
                logger.info("Admin user already exists")
                
    except Exception as e:
        logger.error(f"Failed to create default user: {e}")

if __name__ == "__main__":
    asyncio.run(init_database())
