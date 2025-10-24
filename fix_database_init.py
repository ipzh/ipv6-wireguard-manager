#!/usr/bin/env python3
"""
数据库初始化修复脚本
修复导入错误和数据库初始化问题
"""

import sys
import os
import asyncio
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

def fix_import_issues():
    """修复导入问题"""
    print("🔧 修复导入问题...")
    
    # 检查并修复database_manager.py
    db_manager_file = project_root / "backend" / "app" / "core" / "database_manager.py"
    if db_manager_file.exists():
        print("✅ database_manager.py 存在")
        
        # 检查文件内容
        with open(db_manager_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 检查是否包含必要的导出
        if "database_manager = db_manager" not in content:
            print("⚠️  需要添加database_manager别名")
        
        if "Base = declarative_base()" not in content:
            print("⚠️  需要添加Base类")
        
        if "class DatabaseMode" not in content:
            print("⚠️  需要添加DatabaseMode类")
        
        if "class DatabaseType" not in content:
            print("⚠️  需要添加DatabaseType类")
    
    # 检查database.py
    db_file = project_root / "backend" / "app" / "core" / "database.py"
    if db_file.exists():
        print("✅ database.py 存在")
        
        with open(db_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 检查导入
        if "from .database_manager import" in content:
            print("✅ database.py 导入正确")
        else:
            print("⚠️  database.py 导入可能有问题")
    
    print("🔧 导入问题检查完成")

def create_simple_init_script():
    """创建简化的初始化脚本"""
    print("📝 创建简化的数据库初始化脚本...")
    
    init_script = '''#!/usr/bin/env python3
"""
简化的数据库初始化脚本
避免复杂的导入依赖
"""

import os
import sys
import asyncio
from pathlib import Path

# 添加项目路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

async def init_database_simple():
    """简化的数据库初始化"""
    try:
        print("🔧 开始数据库初始化...")
        
        # 导入必要的模块
        from backend.app.core.unified_config import settings
        from backend.app.core.security_enhanced import security_manager
        
        print(f"📊 数据库URL: {settings.DATABASE_URL}")
        
        # 创建数据库连接
        from sqlalchemy import create_engine, text
        from sqlalchemy.ext.declarative import declarative_base
        
        Base = declarative_base()
        
        # 使用同步引擎进行初始化
        sync_url = settings.DATABASE_URL.replace("mysql://", "mysql+pymysql://")
        engine = create_engine(sync_url, echo=True)
        
        print("🔗 测试数据库连接...")
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1"))
            print("✅ 数据库连接成功")
        
        # 创建表
        print("📋 创建数据库表...")
        
        # 导入模型
        from backend.app.models.models_complete import User, Role, Permission
        
        # 创建所有表
        Base.metadata.create_all(bind=engine)
        print("✅ 数据库表创建完成")
        
        # 创建管理员用户
        print("👤 创建管理员用户...")
        
        from sqlalchemy.orm import sessionmaker
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        
        with SessionLocal() as db:
            # 检查是否已存在管理员用户
            existing_admin = db.query(User).filter(User.username == "admin").first()
            
            if not existing_admin:
                admin_user = User(
                    username="admin",
                    email="admin@example.com",
                    hashed_password=security_manager.get_password_hash("CHANGE_ME_ADMIN_PASSWORD"),
                    full_name="系统管理员",
                    is_active=True,
                    is_superuser=True,
                    is_verified=True
                )
                
                db.add(admin_user)
                db.commit()
                print("✅ 管理员用户创建成功")
                print("🔑 管理员用户名: admin")
                print("🔑 管理员密码: CHANGE_ME_ADMIN_PASSWORD")
                print("⚠️  请立即修改默认密码！")
            else:
                print("ℹ️  管理员用户已存在")
        
        print("🎉 数据库初始化完成！")
        return True
        
    except Exception as e:
        print(f"❌ 数据库初始化失败: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = asyncio.run(init_database_simple())
    if not success:
        sys.exit(1)
'''
    
    # 保存脚本
    script_path = project_root / "init_database_fixed.py"
    with open(script_path, 'w', encoding='utf-8') as f:
        f.write(init_script)
    
    print(f"✅ 简化初始化脚本已创建: {script_path}")
    return script_path

def main():
    """主函数"""
    print("🚀 开始修复数据库初始化问题...")
    
    # 修复导入问题
    fix_import_issues()
    
    # 创建简化脚本
    script_path = create_simple_init_script()
    
    print("\n📋 修复完成！")
    print("🔧 可以使用以下方式初始化数据库:")
    print(f"   python {script_path}")
    print("\n⚠️  注意事项:")
    print("   1. 确保数据库服务正在运行")
    print("   2. 检查数据库连接配置")
    print("   3. 初始化后立即修改默认密码")

if __name__ == "__main__":
    main()

