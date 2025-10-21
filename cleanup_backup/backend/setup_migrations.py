#!/usr/bin/env python3
"""
设置 Alembic 迁移环境
"""
import os
import sys
import subprocess
from pathlib import Path

# 添加项目根目录到Python路径
sys.path.insert(0, str(Path(__file__).parent))

def setup_alembic():
    """设置 Alembic 迁移环境"""
    print("设置 Alembic 迁移环境...")
    
    # 检查是否已存在 migrations 目录
    migrations_dir = Path(__file__).parent / "migrations"
    if migrations_dir.exists():
        print("迁移目录已存在，跳过初始化")
        return True
    
    try:
        # 初始化 Alembic
        result = subprocess.run(
            ["alembic", "init", "migrations"],
            cwd=Path(__file__).parent,
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            print(f"初始化失败: {result.stderr}")
            return False
        
        print("Alembic 初始化成功")
        
        # 创建初始迁移
        print("创建初始迁移...")
        result = subprocess.run(
            ["alembic", "revision", "--autogenerate", "-m", "Initial migration"],
            cwd=Path(__file__).parent,
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            print(f"创建迁移失败: {result.stderr}")
            return False
        
        print("初始迁移创建成功")
        return True
        
    except Exception as e:
        print(f"设置失败: {e}")
        return False

def main():
    """主函数"""
    success = setup_alembic()
    if success:
        print("✅ Alembic 迁移环境设置完成")
        print("现在可以使用以下命令管理数据库迁移:")
        print("  python migrate_db.py upgrade     - 升级数据库")
        print("  python migrate_db.py current     - 查看当前版本")
        print("  python migrate_db.py history     - 查看迁移历史")
    else:
        print("❌ Alembic 迁移环境设置失败")
        sys.exit(1)

if __name__ == "__main__":
    main()
