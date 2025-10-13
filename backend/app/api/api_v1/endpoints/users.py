"""
用户管理API端点 - 修复版本
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db
from ....schemas.user import User, UserCreate, UserUpdate
from ....services.user_service import UserService

router = APIRouter()


@router.get("/")
async def get_users(db: AsyncSession = Depends(get_async_db)):
    """获取用户列表"""
    user_service = UserService(db)
    users = await user_service.get_users()
    return users


@router.get("/{user_id}")
async def get_user(user_id: str, db: AsyncSession = Depends(get_async_db)):
    """获取单个用户"""
    user_service = UserService(db)
    user = await user_service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="用户不存在")
    return user


@router.post("/")
async def create_user(user: UserCreate, db: AsyncSession = Depends(get_async_db)):
    """创建新用户"""
    user_service = UserService(db)
    existing_user = await user_service.get_user_by_username(user.username)
    if existing_user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="用户名已存在")
    
    new_user = await user_service.create_user(user)
    return new_user


@router.put("/{user_id}")
async def update_user(
    user_id: str, 
    user_update: UserUpdate, 
    db: AsyncSession = Depends(get_async_db)
):
    """更新用户信息"""
    user_service = UserService(db)
    user = await user_service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="用户不存在")
    
    updated_user = await user_service.update_user(user_id, user_update)
    return updated_user


@router.delete("/{user_id}")
async def delete_user(user_id: str, db: AsyncSession = Depends(get_async_db)):
    """删除用户"""
    user_service = UserService(db)
    user = await user_service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="用户不存在")
    
    await user_service.delete_user(user_id)
    return {"message": "用户删除成功"}