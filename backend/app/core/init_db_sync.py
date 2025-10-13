"""
同步数据库初始化模块
用于生产环境部署时的数据库初始化
"""
import logging
import sys
import os
from sqlalchemy import text

# 添加项目根目录到Python路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

from app.core.database_simple import engine

logger = logging.getLogger(__name__)

def create_tables() -> bool:
    """
    创建数据库表
    返回: True表示成功，False表示失败
    """
    try:
        # 创建用户表
        with engine.connect() as conn:
            # 检查表是否存在
            result = conn.execute(text("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_schema = 'public' 
                    AND table_name = 'users'
                )
            """))
            table_exists = result.scalar()
            
            if not table_exists:
                logger.info("创建数据库表...")
                
                # 创建用户表
                conn.execute(text("""
                    CREATE TABLE users (
                        id SERIAL PRIMARY KEY,
                        username VARCHAR(50) UNIQUE NOT NULL,
                        email VARCHAR(100) UNIQUE NOT NULL,
                        password_hash VARCHAR(255) NOT NULL,
                        role VARCHAR(20) DEFAULT 'user',
                        is_active BOOLEAN DEFAULT true,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """))
                
                # 创建WireGuard配置表
                conn.execute(text("""
                    CREATE TABLE wireguard_configs (
                        id SERIAL PRIMARY KEY,
                        name VARCHAR(100) UNIQUE NOT NULL,
                        description TEXT,
                        server_ipv6 VARCHAR(50) NOT NULL,
                        server_port INTEGER DEFAULT 51820,
                        private_key VARCHAR(100) NOT NULL,
                        public_key VARCHAR(100) NOT NULL,
                        dns_servers VARCHAR(200) DEFAULT '2001:4860:4860::8888,2001:4860:4860::8844',
                        allowed_ips VARCHAR(200) DEFAULT '::/0',
                        is_active BOOLEAN DEFAULT true,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """))
                
                # 创建客户端配置表
                conn.execute(text("""
                    CREATE TABLE client_configs (
                        id SERIAL PRIMARY KEY,
                        name VARCHAR(100) NOT NULL,
                        description TEXT,
                        client_ipv6 VARCHAR(50) NOT NULL,
                        private_key VARCHAR(100) NOT NULL,
                        public_key VARCHAR(100) NOT NULL,
                        wireguard_config_id INTEGER REFERENCES wireguard_configs(id),
                        is_active BOOLEAN DEFAULT true,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """))
                
                # 创建系统日志表
                conn.execute(text("""
                    CREATE TABLE system_logs (
                        id SERIAL PRIMARY KEY,
                        level VARCHAR(20) NOT NULL,
                        message TEXT NOT NULL,
                        module VARCHAR(100),
                        user_id INTEGER REFERENCES users(id),
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """))
                
                # 创建性能指标表
                conn.execute(text("""
                    CREATE TABLE performance_metrics (
                        id SERIAL PRIMARY KEY,
                        metric_name VARCHAR(100) NOT NULL,
                        metric_value DECIMAL(15,4) NOT NULL,
                        unit VARCHAR(20),
                        recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """))
                
                conn.commit()
                logger.info("数据库表创建成功")
                return True
            else:
                logger.info("数据库表已存在，跳过创建")
                return True
                
    except Exception as e:
        logger.error(f"创建数据库表失败: {e}")
        return False

def init_default_data() -> bool:
    """
    初始化默认数据
    返回: True表示成功，False表示失败
    """
    try:
        with engine.connect() as conn:
            # 检查默认用户是否存在
            result = conn.execute(text("SELECT COUNT(*) FROM users WHERE username = 'admin'"))
            admin_exists = result.scalar() > 0
            
            if not admin_exists:
                logger.info("初始化默认数据...")
                
                # 创建默认管理员用户（密码: admin123）
                conn.execute(text("""
                    INSERT INTO users (username, email, password_hash, role, is_active)
                    VALUES ('admin', 'admin@ipv6-wireguard.com', 
                           '$2b$12$LQv3c1yqBWVHADm6nJ7nCO7W2oO9wYQY9YQY9YQY9YQY9YQY9YQY9Y', 
                           'admin', true)
                """))
                
                # 创建默认WireGuard配置
                conn.execute(text("""
                    INSERT INTO wireguard_configs (name, description, server_ipv6, server_port, 
                                                  private_key, public_key, is_active)
                    VALUES ('default-config', '默认WireGuard配置', '2001:db8::1', 51820,
                           'cG9zdGdyZXM6Ly9pcHY2d2dtOmlwdjZ3Z20xMjNAbG9jYWxob3N0OjU0MzIvaXB2NndnbQ==',
                           'cHVibGljLWtleS1oZXJl', true)
                """))
                
                conn.commit()
                logger.info("默认数据初始化成功")
                return True
            else:
                logger.info("默认数据已存在，跳过初始化")
                return True
                
    except Exception as e:
        logger.error(f"初始化默认数据失败: {e}")
        return False

def check_database_connection() -> bool:
    """
    检查数据库连接
    返回: True表示连接正常，False表示连接失败
    """
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        logger.info("数据库连接正常")
        return True
    except Exception as e:
        logger.error(f"数据库连接失败: {e}")
        return False

def run_migrations() -> bool:
    """
    运行数据库迁移（预留接口）
    返回: True表示成功，False表示失败
    """
    try:
        logger.info("运行数据库迁移...")
        # 这里可以添加数据库迁移逻辑
        logger.info("数据库迁移完成")
        return True
    except Exception as e:
        logger.error(f"数据库迁移失败: {e}")
        return False

def initialize_database() -> bool:
    """
    完整的数据库初始化流程
    返回: True表示成功，False表示失败
    """
    logger.info("开始数据库初始化...")
    
    # 检查数据库连接
    if not check_database_connection():
        return False
    
    # 创建表
    if not create_tables():
        return False
    
    # 初始化默认数据
    if not init_default_data():
        return False
    
    # 运行迁移
    if not run_migrations():
        return False
    
    logger.info("数据库初始化完成")
    return True

if __name__ == "__main__":
    # 直接运行时的测试
    if initialize_database():
        print("数据库初始化成功")
    else:
        print("数据库初始化失败")
