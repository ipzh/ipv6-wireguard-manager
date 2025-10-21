#!/usr/bin/env python3
"""
数据库模型初始化脚本
解决PostgreSQL特定类型在MySQL中的兼容性问题
"""
import os
import sys
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from urllib.parse import urlparse

# 导入所有模型
from backend.app.models.models_complete import (
    Base, User, Role, Permission, UserRole, RolePermission,
    WireGuardServer, WireGuardClient, BGPSession, BGPAnnouncement,
    IPv6Pool, IPv6Allocation, AuditLog, SystemLog,
    NetworkInterface, NetworkAddress
)

def init_database():
    """初始化数据库表结构"""
    try:
        # 从环境变量获取数据库连接信息
        database_url = os.getenv('DATABASE_URL', 'mysql://ipv6wgm:password@localhost:3306/ipv6wgm')
        
        # 检查是否为MySQL数据库
        if not database_url.startswith("mysql://"):
            print("❌ 错误：此系统仅支持MySQL数据库")
            print("💡 请安装MySQL服务器或修改DATABASE_URL环境变量指向MySQL数据库")
            print("📖 安装指南:")
            print("   Windows: 下载并安装MySQL Community Server from https://dev.mysql.com/downloads/mysql/")
            print("   Linux: sudo apt-get install mysql-server (Ubuntu/Debian)")
            print("   macOS: brew install mysql")
            return False
        
        # 确保使用正确的MySQL驱动
        database_url = database_url.replace("mysql://", "mysql+pymysql://", 1)
        
        print(f"🔗 连接到MySQL数据库: {database_url}")
        
        # 创建数据库引擎
        engine = create_engine(database_url)
        
        # 测试数据库连接
        try:
            with engine.connect() as conn:
                print("✅ MySQL数据库连接成功")
        except Exception as e:
            print(f"❌ MySQL数据库连接失败: {e}")
            print("💡 请确保MySQL服务器已启动并且连接配置正确")
            print("📖 检查清单:")
            print("   1. MySQL服务器是否已安装并运行")
            print("   2. 数据库连接参数是否正确 (主机、端口、用户名、密码)")
            print("   3. 数据库用户是否有足够的权限")
            return False
        
        print("📊 创建所有表...")
        # 创建所有表
        Base.metadata.create_all(bind=engine)
        
        print("✅ 数据库表创建成功")
        
        # 创建会话
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        
        try:
            # 检查是否已有管理员用户
            admin_user = db.query(User).filter(User.username == 'admin').first()
            
            if not admin_user:
                # 创建默认角色
                admin_role = Role(name='admin', display_name='管理员', description='系统管理员', is_system=True)
                operator_role = Role(name='operator', display_name='操作员', description='系统操作员', is_system=True)
                user_role = Role(name='user', display_name='普通用户', description='普通用户', is_system=True)
                
                db.add_all([admin_role, operator_role, user_role])
                db.flush()  # 获取角色ID
                
                # 创建默认权限
                permissions = [
                    # 用户管理权限
                    Permission(name='users.view', resource='users', action='view', description='查看用户'),
                    Permission(name='users.create', resource='users', action='create', description='创建用户'),
                    Permission(name='users.edit', resource='users', action='edit', description='编辑用户'),
                    Permission(name='users.delete', resource='users', action='delete', description='删除用户'),
                    Permission(name='users.manage', resource='users', action='manage', description='管理用户'),
                    
                    # WireGuard管理权限
                    Permission(name='wireguard.view', resource='wireguard', action='view', description='查看WireGuard配置'),
                    Permission(name='wireguard.create', resource='wireguard', action='create', description='创建WireGuard配置'),
                    Permission(name='wireguard.edit', resource='wireguard', action='edit', description='编辑WireGuard配置'),
                    Permission(name='wireguard.delete', resource='wireguard', action='delete', description='删除WireGuard配置'),
                    Permission(name='wireguard.manage', resource='wireguard', action='manage', description='管理WireGuard配置'),
                    
                    # BGP管理权限
                    Permission(name='bgp.view', resource='bgp', action='view', description='查看BGP配置'),
                    Permission(name='bgp.create', resource='bgp', action='create', description='创建BGP配置'),
                    Permission(name='bgp.edit', resource='bgp', action='edit', description='编辑BGP配置'),
                    Permission(name='bgp.delete', resource='bgp', action='delete', description='删除BGP配置'),
                    Permission(name='bgp.manage', resource='bgp', action='manage', description='管理BGP配置'),
                    
                    # IPv6管理权限
                    Permission(name='ipv6.view', resource='ipv6', action='view', description='查看IPv6配置'),
                    Permission(name='ipv6.create', resource='ipv6', action='create', description='创建IPv6配置'),
                    Permission(name='ipv6.edit', resource='ipv6', action='edit', description='编辑IPv6配置'),
                    Permission(name='ipv6.delete', resource='ipv6', action='delete', description='删除IPv6配置'),
                    Permission(name='ipv6.manage', resource='ipv6', action='manage', description='管理IPv6配置'),
                    
                    # 系统管理权限
                    Permission(name='system.view', resource='system', action='view', description='查看系统信息'),
                    Permission(name='system.manage', resource='system', action='manage', description='管理系统'),
                ]
                
                db.add_all(permissions)
                db.flush()  # 获取权限ID
                
                # 为管理员角色分配所有权限
                for permission in permissions:
                    db.add(RolePermission(role_id=admin_role.id, permission_id=permission.id))
                
                # 为操作员角色分配部分权限
                operator_permissions = [p for p in permissions if 'manage' not in p.name and 'delete' not in p.name]
                for permission in operator_permissions:
                    db.add(RolePermission(role_id=operator_role.id, permission_id=permission.id))
                
                # 为普通用户角色分配基本权限
                user_permissions = [p for p in permissions if 'view' in p.name]
                for permission in user_permissions:
                    db.add(RolePermission(role_id=user_role.id, permission_id=permission.id))
                
                # 创建默认管理员用户
                from passlib.context import CryptContext
                pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
                password = "Admin@2024"
                hashed_password = pwd_context.hash(password)
                
                admin_user = User(
                    username='admin',
                    email='admin@example.com',
                    hashed_password=hashed_password,
                    full_name='系统管理员',
                    is_active=True,
                    is_superuser=True,
                    is_verified=True
                )
                
                db.add(admin_user)
                db.flush()  # 获取用户ID
                
                # 为管理员用户分配管理员角色
                db.add(UserRole(user_id=admin_user.id, role_id=admin_role.id))
                
                # 创建示例IPv6池
                ipv6_pool1 = IPv6Pool(
                    name='默认IPv6池',
                    description='系统默认IPv6地址池',
                    prefix='2001:db8::',
                    prefix_length=32,
                    total_addresses=2**96,  # 2^(128-32)
                    allocated_addresses=0,
                    available_addresses=2**96,
                    created_by=admin_user.id
                )
                
                ipv6_pool2 = IPv6Pool(
                    name='用户IPv6池',
                    description='用户分配IPv6地址池',
                    prefix='2001:db8:1000::',
                    prefix_length=40,
                    total_addresses=2**88,  # 2^(128-40)
                    allocated_addresses=0,
                    available_addresses=2**88,
                    created_by=admin_user.id
                )
                
                db.add_all([ipv6_pool1, ipv6_pool2])
                
                print("✅ 默认数据创建成功")
            else:
                print("ℹ️ 管理员用户已存在，跳过默认数据创建")
            
            # 提交所有更改
            db.commit()
            print("🎉 数据库初始化完成！")
            print("📝 默认管理员账户:")
            print("   用户名: admin")
            print("   密码: Admin@2024")
            
            return True
            
        except Exception as e:
            db.rollback()
            print(f"❌ 数据初始化失败: {e}")
            return False
        finally:
            db.close()
            
    except Exception as e:
        print(f"❌ 数据库连接失败: {e}")
        return False

def main():
    """主函数"""
    print("🚀 开始初始化数据库模型...")
    
    # 检查并安装必要的依赖
    try:
        import passlib
        print("✅ passlib模块已安装")
    except ImportError:
        print("❌ passlib模块未安装，正在尝试安装...")
        try:
            import subprocess
            import sys
            subprocess.check_call([sys.executable, "-m", "pip", "install", "passlib[argon2,bcrypt]"])
            print("✅ passlib模块安装成功")
        except Exception as e:
            print(f"❌ passlib模块安装失败: {e}")
            print("请手动运行: pip install passlib[argon2,bcrypt]")
            return 1
    
    # 检查环境变量
    database_url = os.getenv('DATABASE_URL', 'mysql://ipv6wgm:password@localhost:3306/ipv6wgm')
    print(f"🔍 检测到DATABASE_URL: {database_url}")
    
    # 如果是默认的MySQL URL，提示用户可能需要安装MySQL
    if "localhost:3306" in database_url and not os.getenv('MYSQL_INSTALLED'):
        print("⚠️ 检测到使用本地MySQL数据库，但可能未安装MySQL服务器")
        print("💡 如果尚未安装MySQL，请参考以下安装指南:")
        print("   Windows: 下载并安装MySQL Community Server from https://dev.mysql.com/downloads/mysql/")
        print("   Linux: sudo apt-get install mysql-server (Ubuntu/Debian)")
        print("   macOS: brew install mysql")
        print("   安装后，请确保MySQL服务已启动")
        print("")
    
    success = init_database()
    
    if success:
        print("✅ 数据库初始化成功")
        return 0
    else:
        print("❌ 数据库初始化失败")
        return 1

if __name__ == "__main__":
    sys.exit(main())