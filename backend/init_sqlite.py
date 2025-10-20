"""
使用SQLite的简化数据库初始化脚本
"""
import asyncio
import logging
import sys
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import text
import os

# 设置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 使用SQLite数据库
DATABASE_URL = "sqlite:///./ipv6wgm.db"
ASYNC_DATABASE_URL = "sqlite+aiosqlite:///./ipv6wgm.db"

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
        await create_tables(engine)
        
        # 创建默认用户
        await create_default_user(engine)
        
        await engine.dispose()
        logger.info("Database initialization completed successfully")
        return True
        
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        return False

async def create_tables(engine):
    """创建数据库表"""
    try:
        # 创建基础表
        async with engine.begin() as conn:
            # 创建用户表
            await conn.execute(text("""
                CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username VARCHAR(50) UNIQUE NOT NULL,
                    email VARCHAR(100) UNIQUE NOT NULL,
                    hashed_password VARCHAR(255) NOT NULL,
                    full_name VARCHAR(100),
                    is_active BOOLEAN DEFAULT 1,
                    is_superuser BOOLEAN DEFAULT 0,
                    is_verified BOOLEAN DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """))
            
            # 创建角色表
            await conn.execute(text("""
                CREATE TABLE IF NOT EXISTS roles (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name VARCHAR(50) UNIQUE NOT NULL,
                    description TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """))
            
            # 创建权限表
            await conn.execute(text("""
                CREATE TABLE IF NOT EXISTS permissions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name VARCHAR(50) UNIQUE NOT NULL,
                    description TEXT,
                    resource VARCHAR(50),
                    action VARCHAR(50),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """))
            
            # 创建用户角色关联表
            await conn.execute(text("""
                CREATE TABLE IF NOT EXISTS user_roles (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER NOT NULL,
                    role_id INTEGER NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users (id),
                    FOREIGN KEY (role_id) REFERENCES roles (id),
                    UNIQUE(user_id, role_id)
                )
            """))
            
            # 创建角色权限关联表
            await conn.execute(text("""
                CREATE TABLE IF NOT EXISTS role_permissions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    role_id INTEGER NOT NULL,
                    permission_id INTEGER NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (role_id) REFERENCES roles (id),
                    FOREIGN KEY (permission_id) REFERENCES permissions (id),
                    UNIQUE(role_id, permission_id)
                )
            """))
            
            # 创建WireGuard服务器表
            await conn.execute(text("""
                CREATE TABLE IF NOT EXISTS wireguard_servers (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name VARCHAR(100) NOT NULL,
                    public_key VARCHAR(44) NOT NULL,
                    private_key VARCHAR(44) NOT NULL,
                    endpoint VARCHAR(255),
                    port INTEGER DEFAULT 51820,
                    ipv4_network VARCHAR(18),
                    ipv6_network VARCHAR(43),
                    is_active BOOLEAN DEFAULT 1,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """))
            
            # 创建BGP会话表
            await conn.execute(text("""
                CREATE TABLE IF NOT EXISTS bgp_sessions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    wireguard_server_id INTEGER NOT NULL,
                    local_as INTEGER NOT NULL,
                    remote_as INTEGER NOT NULL,
                    local_address VARCHAR(43),
                    remote_address VARCHAR(43),
                    is_active BOOLEAN DEFAULT 1,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (wireguard_server_id) REFERENCES wireguard_servers (id)
                )
            """))
            
            # 创建IPv6地址池表
            await conn.execute(text("""
                CREATE TABLE IF NOT EXISTS ipv6_pools (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name VARCHAR(100) NOT NULL,
                    network VARCHAR(43) NOT NULL,
                    gateway VARCHAR(43),
                    start_address VARCHAR(43),
                    end_address VARCHAR(43),
                    is_active BOOLEAN DEFAULT 1,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """))
            
            # 创建审计日志表
            await conn.execute(text("""
                CREATE TABLE IF NOT EXISTS audit_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER,
                    action VARCHAR(50) NOT NULL,
                    resource VARCHAR(50),
                    resource_id INTEGER,
                    details TEXT,
                    ip_address VARCHAR(45),
                    user_agent TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users (id)
                )
            """))
            
            logger.info("Database tables created successfully")
    except Exception as e:
        logger.error(f"Failed to create tables: {e}")
        raise

async def create_default_user(engine):
    """创建默认管理员用户"""
    try:
        async_session = async_sessionmaker(engine, expire_on_commit=False)
        
        async with async_session() as session:
            # 检查是否已存在管理员用户
            result = await session.execute(
                text("SELECT id FROM users WHERE username = 'admin'")
            )
            existing_user = result.fetchone()
            
            if not existing_user:
                # 创建默认管理员用户
                # 使用简单的哈希密码，实际应用中应该使用更安全的方法
                hashed_password="${HASHED_PASSWORD}"  # 简化的密码哈希
                
                await session.execute(
                    text("""
                        INSERT INTO users (username, email, hashed_password, is_active, is_superuser, is_verified)
                        VALUES ('admin', 'admin@example.com', :password, 1, 1, 1)
                    """),
                    {"password": hashed_password}
                )
                
                # 获取新创建的用户ID
                result = await session.execute(
                    text("SELECT id FROM users WHERE username = 'admin'")
                )
                user_id = result.fetchone()[0]
                
                # 创建默认角色
                await session.execute(
                    text("""
                        INSERT OR IGNORE INTO roles (name, description)
                        VALUES 
                        ('admin', '系统管理员'),
                        ('user', '普通用户'),
                        ('operator', '操作员')
                    """)
                )
                
                # 创建默认权限
                await session.execute(
                    text("""
                        INSERT OR IGNORE INTO permissions (name, description, resource, action)
                        VALUES 
                        ('user_read', '查看用户', 'user', 'read'),
                        ('user_write', '修改用户', 'user', 'write'),
                        ('server_read', '查看服务器', 'server', 'read'),
                        ('server_write', '修改服务器', 'server', 'write'),
                        ('bgp_read', '查看BGP配置', 'bgp', 'read'),
                        ('bgp_write', '修改BGP配置', 'bgp', 'write'),
                        ('system_admin', '系统管理', 'system', 'admin')
                    """)
                )
                
                # 分配管理员角色给默认用户
                await session.execute(
                    text("""
                        INSERT INTO user_roles (user_id, role_id)
                        SELECT :user_id, id FROM roles WHERE name = 'admin'
                    """),
                    {"user_id": user_id}
                )
                
                # 分配所有权限给管理员角色
                await session.execute(
                    text("""
                        INSERT INTO role_permissions (role_id, permission_id)
                        SELECT r.id, p.id FROM roles r, permissions p WHERE r.name = 'admin'
                    """)
                )
                
                await session.commit()
                logger.info("Default admin user and roles/permissions initialized successfully")
            else:
                logger.info("Admin user already exists")
                
    except Exception as e:
        logger.error(f"Failed to create default user: {e}")
        raise

async def verify_database():
    """验证数据库"""
    try:
        engine = create_async_engine(ASYNC_DATABASE_URL)
        
        async with engine.begin() as conn:
            # 检查表是否存在
            tables = [
                "users", "roles", "permissions", "user_roles", 
                "role_permissions", "wireguard_servers", "bgp_sessions",
                "ipv6_pools", "audit_logs"
            ]
            
            for table in tables:
                try:
                    result = await conn.execute(text(f"SELECT COUNT(*) FROM {table}"))
                    count = result.fetchone()[0]
                    logger.info(f"表 {table} 存在，包含 {count} 行数据")
                except Exception as e:
                    logger.warning(f"表 {table} 不存在或有问题: {e}")
            
            # 检查默认用户
            result = await conn.execute(text("SELECT username FROM users WHERE username = 'admin'"))
            admin_user = result.fetchone()
            if admin_user:
                logger.info("默认管理员用户存在")
            else:
                logger.warning("默认管理员用户不存在")
        
        await engine.dispose()
        return True
        
    except Exception as e:
        logger.error(f"验证数据库失败: {e}")
        return False

async def main():
    """主函数"""
    logger.info("开始数据库初始化...")
    
    try:
        # 初始化数据库
        if not await init_database():
            logger.error("数据库初始化失败")
            return False
        
        # 验证数据库
        if not await verify_database():
            logger.error("验证数据库失败")
            return False
        
        logger.info("数据库初始化完成！")
        return True
        
    except Exception as e:
        logger.error(f"数据库初始化失败: {e}")
        return False

if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)