#!/usr/bin/env python3
"""
创建初始数据库迁移脚本
"""
import sys
import os
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

def create_initial_migration():
    """创建初始迁移"""
    print("🚀 开始创建初始数据库迁移...")
    
    try:
        # 导入必要的模块
        from backend.app.core.database import Base
        from backend.app.models.models_complete import *
        
        # 设置Alembic配置
        os.chdir(project_root / "backend")
        
        # 生成迁移脚本
        import subprocess
        
        # 创建迁移
        result = subprocess.run([
            "alembic", "revision", "--autogenerate", "-m", "Initial migration"
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ 初始迁移脚本创建成功")
            print(f"输出: {result.stdout}")
        else:
            print(f"❌ 创建迁移脚本失败: {result.stderr}")
            return False
        
        # 应用迁移
        result = subprocess.run([
            "alembic", "upgrade", "head"
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ 数据库迁移应用成功")
            print(f"输出: {result.stdout}")
        else:
            print(f"❌ 应用迁移失败: {result.stderr}")
            return False
        
        print("🎉 数据库迁移完成！")
        return True
        
    except Exception as e:
        print(f"❌ 创建数据库迁移失败: {e}")
        return False

if __name__ == "__main__":
    success = create_initial_migration()
    sys.exit(0 if success else 1)
