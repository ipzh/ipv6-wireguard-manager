#!/usr/bin/env python3
"""
支持MySQL的数据库初始化脚本
解决依赖问题，支持MySQL、PostgreSQL和SQLite
"""
import os
import sys
import sqlite3
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

def init_mysql_database():
    """初始化MySQL数据库"""
    try:
        import pymysql
        
        # 从环境变量获取数据库连接信息
        database_url = os.getenv('DATABASE_URL', 'mysql://ipv6wgm:password@localhost:${DB_PORT}/ipv6wgm')
        
        # 解析数据库URL
        from urllib.parse import urlparse
        parsed = urlparse(database_url)
        
        # 连接到MySQL服务器
        conn = pymysql.connect(
            host=parsed.hostname,
            port=parsed.port or 3306,
            user=parsed.username,
            password=parsed.password,
            charset='utf8mb4'
        )
        cursor = conn.cursor()
        
        # 检查数据库是否存在
        db_name = parsed.path[1:]  # 移除开头的 '/'
        cursor.execute("SHOW DATABASES LIKE %s", (db_name,))
        
        if not cursor.fetchone():
            # 创建数据库
            cursor.execute(f'CREATE DATABASE `{db_name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci')
            print(f"✅ 数据库 {db_name} 创建成功")
        else:
            print(f"ℹ️ 数据库 {db_name} 已存在")
        
        cursor.close()
        conn.close()
        
        # 连接到新创建的数据库
        conn = pymysql.connect(
            host=parsed.hostname,
            port=parsed.port or 3306,
            user=parsed.username,
            password=parsed.password,
            database=db_name,
            charset='utf8mb4'
        )
        cursor = conn.cursor()
        
        # 创建基本表结构
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                username VARCHAR(50) UNIQUE NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                hashed_password VARCHAR(255) NOT NULL,
                is_active BOOLEAN DEFAULT TRUE,
                is_superuser BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        """)
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS wireguard_configs (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                private_key VARCHAR(255) NOT NULL,
                public_key VARCHAR(255) NOT NULL,
                address VARCHAR(50) NOT NULL,
                listen_port INTEGER DEFAULT 51820,
                is_active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        """)
        
        # 插入默认管理员用户
        cursor.execute("""
            INSERT IGNORE INTO users (username, email, hashed_password, is_active, is_superuser)
            VALUES ('admin', 'admin@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8KzKz2K', TRUE, TRUE)
        """)
        
        conn.commit()
        cursor.close()
        conn.close()
        
        print(f"✅ MySQL数据库初始化成功")
        return True
        
    except ImportError:
        print("❌ pymysql未安装")
        print("💡 安装命令: pip install pymysql")
        return False
    except Exception as e:
        print(f"❌ MySQL数据库初始化失败: {e}")
        return False

def main():
    """主函数"""
    print("🚀 开始初始化数据库...")
    
    # 检查环境变量
    database_url = os.getenv('DATABASE_URL', 'mysql://ipv6wgm:password@localhost:${DB_PORT}/ipv6wgm')
    
    if database_url.startswith('mysql://'):
        print("📊 检测到MySQL数据库配置")
        success = init_mysql_database()
    else:
        print(f"❌ 仅支持MySQL数据库: {database_url}")
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
