#!/usr/bin/env python3
"""
简化的数据库初始化脚本
解决依赖问题，支持MySQL和PostgreSQL（不支持SQLite）
"""
import os
import sys
from pathlib import Path

# 添加项目根目录到Python路径
try:
    project_root = Path(__file__).parent.parent.parent
except NameError:
    # 如果__file__未定义，使用当前工作目录的父目录
    project_root = Path.cwd().parent
sys.path.insert(0, str(project_root))

def init_mysql_database():
    """初始化MySQL数据库"""
    try:
        import pymysql
        from urllib.parse import urlparse
        
        # 从环境变量获取数据库连接信息
        database_url = os.getenv('DATABASE_URL', 'mysql://ipv6wgm:password@localhost:3306/ipv6wgm?charset=utf8mb4')
        
        # 解析数据库URL
        parsed = urlparse(database_url)
        
        # 连接到MySQL服务器
        conn = pymysql.connect(
            host=parsed.hostname,
            port=parsed.port or 3306,
            user=parsed.username,
            password=parsed.password,
            database='mysql',  # 连接到默认数据库
            charset='utf8mb4'
        )
        cursor = conn.cursor()
        
        # 检查数据库是否存在
        db_name = parsed.path[1:]  # 移除开头的 '/'
        cursor.execute(f"SHOW DATABASES LIKE '{db_name}'")
        
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
            )
        """)
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS wireguard_configs (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                private_key VARCHAR(255) NOT NULL,
                public_key VARCHAR(255) NOT NULL,
                address VARCHAR(50) NOT NULL,
                listen_port INT DEFAULT 51820,
                is_active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
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
        print("❌ pymysql未安装，无法初始化MySQL数据库")
        return False
    except Exception as e:
        print(f"❌ MySQL数据库初始化失败: {e}")
        return False

def init_postgresql_database():
    """初始化PostgreSQL数据库 - 已废弃，不再支持PostgreSQL"""
    print("❌ PostgreSQL数据库初始化已废弃，不再支持PostgreSQL数据库")
    print("💡 请使用MySQL数据库，并将DATABASE_URL修改为mysql://格式")
    return False

def main():
    """主函数 - 强制使用MySQL"""
    print("🚀 开始初始化数据库...")
    
    # 检查环境变量
    database_url = os.getenv('DATABASE_URL', 'mysql://ipv6wgm:password@localhost:3306/ipv6wgm?charset=utf8mb4')
    
    # 强制使用MySQL，不再支持PostgreSQL
    if database_url.startswith('mysql://'):
        print("📊 检测到MySQL数据库配置")
        success = init_mysql_database()
    elif database_url.startswith('postgresql://'):
        print("❌ 不再支持PostgreSQL数据库，请使用MySQL")
        print("💡 请将DATABASE_URL修改为mysql://格式")
        success = False
    else:
        print(f"❌ 不支持的数据库类型: {database_url}")
        print("💡 仅支持MySQL数据库，请将DATABASE_URL修改为mysql://格式")
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
