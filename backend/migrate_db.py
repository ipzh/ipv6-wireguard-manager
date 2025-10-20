#!/usr/bin/env python3
"""
数据库迁移管理脚本
使用 Alembic 进行数据库版本控制
"""
import os
import sys
import subprocess
from pathlib import Path

# 添加项目根目录到Python路径
sys.path.insert(0, str(Path(__file__).parent))

def run_alembic_command(command, *args):
    """运行 Alembic 命令"""
    try:
        cmd = ["alembic"] + [command] + list(args)
        print(f"运行命令: {' '.join(cmd)}")
        result = subprocess.run(cmd, cwd=Path(__file__).parent, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"错误: {result.stderr}")
            return False
        
        print(result.stdout)
        return True
    except Exception as e:
        print(f"执行命令失败: {e}")
        return False

def init_migrations():
    """初始化迁移环境"""
    print("初始化 Alembic 迁移环境...")
    return run_alembic_command("init", "migrations")

def create_initial_migration():
    """创建初始迁移"""
    print("创建初始迁移...")
    return run_alembic_command("revision", "--autogenerate", "-m", "Initial migration")

def upgrade_database():
    """升级数据库到最新版本"""
    print("升级数据库...")
    return run_alembic_command("upgrade", "head")

def downgrade_database(revision="base"):
    """降级数据库"""
    print(f"降级数据库到 {revision}...")
    return run_alembic_command("downgrade", revision)

def show_current_revision():
    """显示当前数据库版本"""
    print("当前数据库版本:")
    return run_alembic_command("current")

def show_migration_history():
    """显示迁移历史"""
    print("迁移历史:")
    return run_alembic_command("history")

def main():
    """主函数"""
    if len(sys.argv) < 2:
        print("用法: python migrate_db.py <command>")
        print("可用命令:")
        print("  init        - 初始化迁移环境")
        print("  create      - 创建初始迁移")
        print("  upgrade     - 升级数据库")
        print("  downgrade   - 降级数据库")
        print("  current     - 显示当前版本")
        print("  history     - 显示迁移历史")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "init":
        success = init_migrations()
    elif command == "create":
        success = create_initial_migration()
    elif command == "upgrade":
        success = upgrade_database()
    elif command == "downgrade":
        revision = sys.argv[2] if len(sys.argv) > 2 else "base"
        success = downgrade_database(revision)
    elif command == "current":
        success = show_current_revision()
    elif command == "history":
        success = show_migration_history()
    else:
        print(f"未知命令: {command}")
        sys.exit(1)
    
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()
