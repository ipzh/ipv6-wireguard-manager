#!/usr/bin/env python3
"""
数据库初始化脚本
创建所有必要的表和初始数据
"""
import asyncio
import sys
import os
from pathlib import Path

# 添加项目根目录到Python路径
sys.path.insert(0, str(Path(__file__).parent / "app"))

from app.core.database import init_db, Base
from app.core.config_enhanced import settings
from app.models.models_complete import User, Role, Permission, UserRole, RolePermission
from app.core.security_enhanced import security_manager
from sqlalchemy import select, text
import structlog

logger = structlog.get_logger()


async def create_tables():
    """创建所有数据库表"""
    try:
        logger.info("开始创建数据库表...")
        
        # 初始化数据库（这会创建所有表）
        await init_db()
        
        logger.info("数据库表创建完成")
        return True
        
    except Exception as e:
        logger.error(f"创建数据库表失败: {e}")
        return False


async def create_initial_data():
    """创建初始数据"""
    try:
        logger.info("开始创建初始数据...")
        
        # 初始化数据库
        await init_db()
        
        # 创建默认角色和权限
        await security_manager.init_permissions_and_roles()
        
        # 创建默认管理员用户
        admin_user = await create_admin_user()
        if admin_user:
            logger.info(f"默认管理员用户创建成功: {admin_user.username}")
        
        logger.info("初始数据创建完成")
        return True
        
    except Exception as e:
        logger.error(f"创建初始数据失败: {e}")
        return False


async def create_admin_user():
    """创建默认管理员用户"""
    try:
        from app.core.database import get_db
        
        async with get_db() as db:
            # 检查是否已存在管理员用户
            existing_admin = await db.execute(
                select(User).where(User.username == "admin")
            )
            if existing_admin.scalar_one_or_none():
                logger.info("管理员用户已存在")
                return existing_admin.scalar_one()
            
            # 创建管理员用户
            admin_user = User(
                username="admin",
                email="admin@example.com",
                hashed_password=security_manager.get_password_hash("admin123"),
                full_name="系统管理员",
                is_active=True,
                is_superuser=True,
                is_verified=True
            )
            
            db.add(admin_user)
            await db.commit()
            await db.refresh(admin_user)
            
            # 分配管理员角色
            admin_role = await db.execute(
                select(Role).where(Role.name == "admin")
            )
            admin_role = admin_role.scalar_one_or_none()
            
            if admin_role:
                user_role = UserRole(
                    user_id=admin_user.id,
                    role_id=admin_role.id
                )
                db.add(user_role)
                await db.commit()
            
            return admin_user
            
    except Exception as e:
        logger.error(f"创建管理员用户失败: {e}")
        return None


async def verify_database():
    """验证数据库连接和表结构"""
    try:
        logger.info("验证数据库连接...")
        
        from app.core.database import get_db
        
        async with get_db() as db:
            # 测试查询
            result = await db.execute(select(User).limit(1))
            users = result.scalars().all()
            
            logger.info(f"数据库连接正常，用户表中有 {len(users)} 个用户")
            
            # 检查表结构
            tables = [
                "users", "roles", "permissions", "user_roles", 
                "role_permissions", "wireguard_servers", "bgp_sessions",
                "ipv6_pools", "audit_logs"
            ]
            
            for table in tables:
                try:
                    await db.execute(text(f"SELECT 1 FROM {table} LIMIT 1"))
                    logger.info(f"表 {table} 存在")
                except Exception as e:
                    logger.warning(f"表 {table} 不存在或有问题: {e}")
            
            return True
            
    except Exception as e:
        logger.error(f"验证数据库失败: {e}")
        return False


async def main():
    """主函数"""
    logger.info("开始数据库初始化...")
    
    try:
        # 创建表
        if not await create_tables():
            logger.error("创建表失败")
            return False
        
        # 创建初始数据
        if not await create_initial_data():
            logger.error("创建初始数据失败")
            return False
        
        # 验证数据库
        if not await verify_database():
            logger.error("验证数据库失败")
            return False
        
        logger.info("数据库初始化完成！")
        return True
        
    except Exception as e:
        logger.error(f"数据库初始化失败: {e}")
        return False


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
