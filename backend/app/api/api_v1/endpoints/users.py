"""
用户管理API端点
"""
from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db
from ....core.security import get_current_user_id
from ....schemas.user import User, UserCreate, UserUpdate
from ....services.user_service import UserService

router = APIRouter()


@router.get("/", response_model=List[User])
async def get_users(
    skip: int = Query(0, ge=0, description="跳过记录数"),
    limit: int = Query(100, ge=1, le=100, description="限制记录数"),
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取用户列表
    """
    user_service = UserService(db)
    users = await user_service.get_users(skip=skip, limit=limit)
    return users


@router.post("/", response_model=User)
async def create_user(
    user_data: UserCreate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    创建用户
    """
    user_service = UserService(db)
    try:
        user = await user_service.create_user(user_data)
        return user
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/{user_id}", response_model=User)
async def get_user(
    user_id: str,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取用户详情
    """
    user_service = UserService(db)
    user = await user_service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )
    return user


@router.put("/{user_id}", response_model=User)
async def update_user(
    user_id: str,
    user_data: UserUpdate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    更新用户
    """
    user_service = UserService(db)
    user = await user_service.update_user(user_id, user_data)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )
    return user


@router.delete("/{user_id}")
async def delete_user(
    user_id: str,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    删除用户
    """
    user_service = UserService(db)
    success = await user_service.delete_user(user_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )
    return {"message": "用户删除成功"}
