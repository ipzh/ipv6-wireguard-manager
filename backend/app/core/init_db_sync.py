"""
同步数据库初始化脚本（用于安装脚本）
"""
import asyncio
import sys
import os

# 添加项目根目录到Python路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

from app.core.database import sync_engine, Base
from app.models import Base as ModelsBase
from app.core.init_db import init_db

def create_tables():
    """创建数据库表"""
    try:
        print("🔧 创建数据库表...")
        Base.metadata.create_all(bind=sync_engine)
        print("✅ 数据库表创建成功")
        return True
    except Exception as e:
        print(f"❌ 数据库表创建失败: {e}")
        return False

def init_default_data():
    """初始化默认数据"""
    try:
        print("🔧 初始化默认数据...")
        # 运行异步初始化函数
        asyncio.run(init_db())
        print("✅ 默认数据初始化成功")
        return True
    except Exception as e:
        print(f"❌ 默认数据初始化失败: {e}")
        return False

if __name__ == "__main__":
    # 创建表
    if create_tables():
        # 初始化默认数据
        init_default_data()
    else:
        print("⚠️  数据库表创建失败，跳过默认数据初始化")
