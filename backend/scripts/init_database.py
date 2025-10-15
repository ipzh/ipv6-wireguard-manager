#!/usr/bin/env python3
"""
简化的数据库初始化脚本
解决依赖问题，支持PostgreSQL和SQLite
"""
import os
import sys
import sqlite3
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

def init_sqlite_database():
    """初始化SQLite数据库"""
    try:
        db_path = project_root / "backend" / "ipv6wgm.db"
        db_path.parent.mkdir(parents=True, exist_ok=True)
        
        # 创建数据库文件
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()
        
        # 创建基本表结构
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username VARCHAR(50) UNIQUE NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                hashed_password VARCHAR(255) NOT NULL,
                is_active BOOLEAN DEFAULT TRUE,
                is_superuser BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS wireguard_configs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name VARCHAR(100) NOT NULL,
                private_key VARCHAR(255) NOT NULL,
                public_key VARCHAR(255) NOT NULL,
                address VARCHAR(50) NOT NULL,
                listen_port INTEGER DEFAULT 51820,
                is_active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # 插入默认管理员用户
        cursor.execute("""
            INSERT OR IGNORE INTO users (username, email, hashed_password, is_active, is_superuser)
            VALUES ('admin', 'admin@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8KzKz2K', TRUE, TRUE)
        """)
        
        conn.commit()
        conn.close()
        
        print(f"✅ SQLite数据库初始化成功: {db_path}")
        return True
        
    except Exception as e:
        print(f"❌ SQLite数据库初始化失败: {e}")
        return False

def init_postgresql_database():
    """初始化PostgreSQL数据库"""
    try:
        import psycopg2
        from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
        
        # 从环境变量获取数据库连接信息
        database_url = os.getenv('DATABASE_URL', 'postgresql://ipv6wgm:password@localhost:5432/ipv6wgm')
        
        # 解析数据库URL
        from urllib.parse import urlparse
        parsed = urlparse(database_url)
        
        # 连接到PostgreSQL服务器
        conn = psycopg2.connect(
            host=parsed.hostname,
            port=parsed.port or 5432,
            user=parsed.username,
            password=parsed.password,
            database='postgres'  # 连接到默认数据库
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        # 检查数据库是否存在
        db_name = parsed.path[1:]  # 移除开头的 '/'
        cursor.execute("SELECT 1 FROM pg_database WHERE datname = %s", (db_name,))
        
        if not cursor.fetchone():
            # 创建数据库
            cursor.execute(f'CREATE DATABASE "{db_name}"')
            print(f"✅ 数据库 {db_name} 创建成功")
        else:
            print(f"ℹ️ 数据库 {db_name} 已存在")
        
        cursor.close()
        conn.close()
        
        # 连接到新创建的数据库
        conn = psycopg2.connect(database_url)
        cursor = conn.cursor()
        
        # 创建基本表结构
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                username VARCHAR(50) UNIQUE NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                hashed_password VARCHAR(255) NOT NULL,
                is_active BOOLEAN DEFAULT TRUE,
                is_superuser BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS wireguard_configs (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                private_key VARCHAR(255) NOT NULL,
                public_key VARCHAR(255) NOT NULL,
                address VARCHAR(50) NOT NULL,
                listen_port INTEGER DEFAULT 51820,
                is_active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # 插入默认管理员用户
        cursor.execute("""
            INSERT INTO users (username, email, hashed_password, is_active, is_superuser)
            VALUES ('admin', 'admin@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8KzKz2K', TRUE, TRUE)
            ON CONFLICT (username) DO NOTHING
        """)
        
        conn.commit()
        cursor.close()
        conn.close()
        
        print(f"✅ PostgreSQL数据库初始化成功")
        return True
        
    except ImportError:
        print("❌ psycopg2未安装，无法初始化PostgreSQL数据库")
        return False
    except Exception as e:
        print(f"❌ PostgreSQL数据库初始化失败: {e}")
        return False

def main():
    """主函数"""
    print("🚀 开始初始化数据库...")
    
    # 检查环境变量
    database_url = os.getenv('DATABASE_URL', 'sqlite:///./ipv6wgm.db')
    
    if database_url.startswith('postgresql://'):
        print("📊 检测到PostgreSQL数据库配置")
        success = init_postgresql_database()
    elif database_url.startswith('sqlite://'):
        print("📊 检测到SQLite数据库配置")
        success = init_sqlite_database()
    else:
        print(f"❌ 不支持的数据库类型: {database_url}")
        success = False
    
    if success:
        print("🎉 数据库初始化完成！")
        print("📝 默认管理员账户:")
        print("   用户名: admin")
        print("   密码: admin123")
        return 0
    else:
        print("💥 数据库初始化失败！")
        return 1

if __name__ == "__main__":
    sys.exit(main())
