#!/usr/bin/env python3
"""
简化的数据库初始化脚本
避免复杂的导入依赖，直接使用SQLAlchemy
"""

import os
import sys
import asyncio
from pathlib import Path

# 添加项目路径
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

def init_database_simple():
    """简化的数据库初始化"""
    try:
        print("🔧 开始数据库初始化...")
        
        # 读取环境变量
        from dotenv import load_dotenv
        load_dotenv(project_root / ".env.local")
        
        database_url = os.getenv("DATABASE_URL", "mysql://ipv6wgm:ipv6wgm_password@127.0.0.1:3306/ipv6wgm")
        print(f"📊 数据库URL: {database_url}")
        
        # 创建数据库连接
        from sqlalchemy import create_engine, text
        from sqlalchemy.ext.declarative import declarative_base
        
        Base = declarative_base()
        
        # 使用同步引擎进行初始化
        sync_url = database_url.replace("mysql://", "mysql+pymysql://")
        engine = create_engine(sync_url, echo=True)
        
        print("🔗 测试数据库连接...")
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1"))
            print("✅ 数据库连接成功")
        
        # 创建表
        print("📋 创建数据库表...")
        
        # 定义基础模型
        from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey
        from sqlalchemy.orm import relationship
        from datetime import datetime
        
        class User(Base):
            __tablename__ = "users"
            
            id = Column(Integer, primary_key=True, index=True)
            username = Column(String(50), unique=True, index=True, nullable=False)
            email = Column(String(100), unique=True, index=True, nullable=False)
            hashed_password = Column(String(255), nullable=False)
            full_name = Column(String(100))
            is_active = Column(Boolean, default=True)
            is_superuser = Column(Boolean, default=False)
            is_verified = Column(Boolean, default=False)
            created_at = Column(DateTime, default=datetime.utcnow)
            updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
        
        class Role(Base):
            __tablename__ = "roles"
            
            id = Column(Integer, primary_key=True, index=True)
            name = Column(String(50), unique=True, index=True, nullable=False)
            description = Column(Text)
            created_at = Column(DateTime, default=datetime.utcnow)
        
        class Permission(Base):
            __tablename__ = "permissions"
            
            id = Column(Integer, primary_key=True, index=True)
            name = Column(String(100), unique=True, index=True, nullable=False)
            description = Column(Text)
            resource = Column(String(100))
            action = Column(String(50))
            created_at = Column(DateTime, default=datetime.utcnow)
        
        # 创建所有表
        Base.metadata.create_all(bind=engine)
        print("✅ 数据库表创建完成")
        
        # 创建管理员用户
        print("👤 创建管理员用户...")
        
        from sqlalchemy.orm import sessionmaker
        from passlib.context import CryptContext
        
        # 密码加密
        pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        
        with SessionLocal() as db:
            # 检查是否已存在管理员用户
            existing_admin = db.query(User).filter(User.username == "admin").first()
            
            if not existing_admin:
                admin_password = os.getenv("FIRST_SUPERUSER_PASSWORD", "CHANGE_ME_ADMIN_PASSWORD")
                admin_user = User(
                    username="admin",
                    email="admin@example.com",
                    hashed_password=pwd_context.hash(admin_password),
                    full_name="系统管理员",
                    is_active=True,
                    is_superuser=True,
                    is_verified=True
                )
                
                db.add(admin_user)
                db.commit()
                print("✅ 管理员用户创建成功")
                print("🔑 管理员用户名: admin")
                print(f"🔑 管理员密码: {admin_password}")
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
    success = init_database_simple()
    if not success:
        sys.exit(1)

