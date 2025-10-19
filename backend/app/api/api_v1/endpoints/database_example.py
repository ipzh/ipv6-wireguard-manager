"""
API路由中使用数据库示例
"""
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List

from ..core.database_manager import get_async_db, get_sync_db, database_manager
from ..core.database_middleware import DatabaseSessionMiddleware
from ..models.models_complete import User
from ..schemas.user import UserResponse

router = APIRouter()

# 方式1: 使用依赖注入获取异步会话
@router.get("/users", response_model=List[UserResponse])
async def get_users(db: AsyncSession = Depends(get_async_db)):
    """获取用户列表（使用依赖注入）"""
    result = await db.execute(select(User))
    users = result.scalars().all()
    return users

# 方式2: 从请求状态获取数据库管理器
@router.get("/users-v2")
async def get_users_v2(request: Request):
    """获取用户列表（使用请求状态）"""
    db_manager = request.state.db_manager
    
    async with db_manager.get_async_session() as db:
        result = await db.execute(select(User))
        users = result.scalars().all()
        return {"users": users}

# 方式3: 混合使用异步和同步会话
@router.post("/users-with-sync")
async def create_user_with_sync(
    user_data: dict,
    async_db: AsyncSession = Depends(get_async_db)
):
    """创建用户并执行同步操作"""
    # 使用异步会话创建记录
    db_user = User(**user_data)
    async_db.add(db_user)
    await async_db.commit()
    await async_db.refresh(db_user)
    
    # 使用同步会话执行复杂查询
    with database_manager.get_sync_session() as sync_db:
        # 执行一些复杂的同步查询
        result = sync_db.execute(select(User).where(User.id == db_user.id))
        sync_user = result.scalar_one_or_none()
    
    return sync_user

# 方式4: 数据库健康检查端点
@router.get("/db-health")
async def get_database_health(request: Request):
    """获取数据库健康状态"""
    db_health = getattr(request.state, 'db_health', None)
    
    if not db_health:
        from ..core.database_health_enhanced import health_checker
        db_health = await health_checker.check_database_health(detailed=True)
    
    return db_health

# 方式5: 数据库连接状态检查
@router.get("/db-status")
async def get_database_status():
    """获取数据库连接状态"""
    try:
        # 检查异步连接
        async_status = await database_manager.check_connection(is_async=True)
        
        # 检查同步连接
        sync_status = await database_manager.check_connection(is_async=False)
        
        return {
            "async_connection": async_status,
            "sync_connection": sync_status,
            "database_type": database_manager.database_type.value,
            "mode": database_manager.mode.value
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"数据库状态检查失败: {str(e)}")

# 方式6: 数据库自动修复端点
@router.post("/db-fix")
async def fix_database():
    """自动修复数据库问题"""
    try:
        from ..core.database_health_enhanced import health_checker
        fix_result = await health_checker.auto_fix_database()
        
        if fix_result["success"]:
            return {
                "status": "success",
                "message": "数据库修复成功",
                "actions_taken": fix_result["actions_taken"]
            }
        else:
            raise HTTPException(
                status_code=500, 
                detail=f"数据库修复失败: {fix_result.get('error', '未知错误')}"
            )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"数据库修复异常: {str(e)}")
