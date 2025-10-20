#!/usr/bin/env python3
"""
环境检查脚本
检查Python环境、依赖和数据库连接
"""
import os
import sys
import subprocess
from pathlib import Path

def check_python_version():
    """检查Python版本"""
    print("🐍 检查Python版本...")
    version = sys.version_info
    print(f"   Python版本: {version.major}.{version.minor}.{version.micro}")
    
    if version.major == 3 and version.minor >= 8:
        print("   ✅ Python版本符合要求")
        return True
    else:
        print("   ❌ Python版本过低，需要Python 3.8+")
        return False

def check_virtual_environment():
    """检查虚拟环境"""
    print("\n🔧 检查虚拟环境...")
    
    if hasattr(sys, 'real_prefix') or (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix):
        print("   ✅ 检测到虚拟环境")
        print(f"   虚拟环境路径: {sys.prefix}")
        return True
    else:
        print("   ⚠️ 未检测到虚拟环境")
        print("   💡 建议使用虚拟环境: python -m venv venv")
        return False

def check_dependencies():
    """检查依赖包"""
    print("\n📦 检查依赖包...")
    
    required_packages = [
        ('fastapi', 'fastapi'),
        ('uvicorn', 'uvicorn'),
        ('pydantic', 'pydantic'),
        ('sqlalchemy', 'sqlalchemy'),
        ('python-dotenv', 'dotenv')
    ]
    
    missing_packages = []
    
    for package_name, import_name in required_packages:
        try:
            __import__(import_name)
            print(f"   ✅ {package_name}")
        except ImportError:
            print(f"   ❌ {package_name} - 未安装")
            missing_packages.append(package_name)
    
    if missing_packages:
        print(f"\n   💡 安装缺失的依赖:")
        print(f"   pip install {' '.join(missing_packages)}")
        return False
    else:
        print("   ✅ 所有核心依赖已安装")
        return True

def check_database_connection():
    """检查数据库连接"""
    print("\n🗄️ 检查数据库连接...")
    
    # 检查环境变量
    database_url = os.getenv('DATABASE_URL', 'mysql://ipv6wgm:password@localhost:${DB_PORT}/ipv6wgm')
    print(f"   数据库URL: {database_url}")
    
    if database_url.startswith('mysql://'):
        return check_mysql_connection(database_url)
    else:
        print("   ❌ 仅支持MySQL数据库")
        return False

def check_mysql_connection(database_url):
    """检查MySQL连接"""
    try:
        import pymysql
        from urllib.parse import urlparse
        
        parsed = urlparse(database_url)
        conn = pymysql.connect(
            host=parsed.hostname,
            port=parsed.port or 3306,
            user=parsed.username,
            password=parsed.password,
            database=parsed.path[1:]  # 移除开头的 '/'
        )
        conn.close()
        print("   ✅ MySQL连接成功")
        return True
    except ImportError:
        print("   ❌ pymysql未安装")
        print("   💡 安装命令: pip install pymysql")
        return False
    except Exception as e:
        print(f"   ❌ MySQL连接失败: {e}")
        return False

def check_postgresql_connection(database_url):
    """检查PostgreSQL连接"""
    try:
        import psycopg2
        from urllib.parse import urlparse
        
        parsed = urlparse(database_url)
        conn = psycopg2.connect(
            host=parsed.hostname,
            port=parsed.port or 5432,
            user=parsed.username,
            password=parsed.password,
            database=parsed.path[1:]  # 移除开头的 '/'
        )
        conn.close()
        print("   ✅ PostgreSQL连接成功")
        return True
    except ImportError:
        print("   ❌ psycopg2未安装")
        print("   💡 安装命令: pip install psycopg2-binary")
        return False
    except Exception as e:
        print(f"   ❌ PostgreSQL连接失败: {e}")
        return False

def check_sqlite_connection(database_url):
    """检查SQLite连接"""
    try:
        import sqlite3
        
        # 解析SQLite路径
        if database_url.startswith('sqlite:///'):
            db_path = database_url[10:]  # 移除 'sqlite:///'
        else:
            db_path = 'ipv6wgm.db'
        
        # 确保目录存在
        db_file = Path(db_path)
        db_file.parent.mkdir(parents=True, exist_ok=True)
        
        # 测试连接
        conn = sqlite3.connect(str(db_file))
        conn.close()
        print(f"   ✅ SQLite连接成功: {db_path}")
        return True
    except Exception as e:
        print(f"   ❌ SQLite连接失败: {e}")
        return False

def check_environment_file():
    """检查环境变量文件"""
    print("\n📄 检查环境变量文件...")
    
    env_file = Path('.env')
    if env_file.exists():
        print(f"   ✅ 环境变量文件存在: {env_file.absolute()}")
        return True
    else:
        print("   ⚠️ 环境变量文件不存在")
        print("   💡 创建.env文件或设置环境变量")
        return False

def main():
    """主函数"""
    print("🔍 IPv6 WireGuard Manager 环境检查")
    print("=" * 50)
    
    checks = [
        check_python_version,
        check_virtual_environment,
        check_dependencies,
        check_environment_file,
        check_database_connection
    ]
    
    results = []
    for check in checks:
        results.append(check())
    
    print("\n" + "=" * 50)
    print("📊 检查结果汇总:")
    
    if all(results):
        print("🎉 所有检查通过！环境配置正确")
        print("\n🚀 可以启动服务器:")
        print("   python scripts/start_server.py")
        return 0
    else:
        print("⚠️ 部分检查未通过，请解决上述问题")
        print("\n💡 常见解决方案:")
        print("   1. 创建虚拟环境: python -m venv venv")
        print("   2. 激活虚拟环境: source venv/bin/activate (Linux) 或 venv\\Scripts\\activate (Windows)")
        print("   3. 安装依赖: pip install -r requirements-minimal.txt")
        print("   4. 初始化数据库: python scripts/init_database.py")
        return 1

if __name__ == "__main__":
    sys.exit(main())
