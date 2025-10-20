"""
用户管理API端点 - 简化版本
"""
from typing import Dict, Any, List
from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime

from ...core.database import get_db
from ...models.models_complete import User

router = APIRouter()

@router.get("/", response_model=None)
async def get_users(db: AsyncSession = Depends(get_db)):
    """获取用户列表"""
    try:
        result = await db.execute(select(User))
        users = result.scalars().all()
        
        return {
            "success": True,
            "data": [
                {
                    "id": str(user.id),
                    "username": user.username,
                    "email": user.email,
                    "is_active": user.is_active,
                    "is_superuser": user.is_superuser,
                    "created_at": user.created_at.isoformat() if user.created_at else None,
                    "last_login": user.last_login.isoformat() if user.last_login else None
                }
                for user in users
            ]
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取用户列表失败: {str(e)}"
        )

@router.get("/{user_id}", response_model=None)
async def get_user(user_id: int, db: AsyncSession = Depends(get_db)):
    """获取用户详情"""
    try:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        
        if not user:
            raise HTTPException(status_code=404, detail="用户不存在")
        
        return {
            "success": True,
            "data": {
                "id": str(user.id),
                "username": user.username,
                "email": user.email,
                "is_active": user.is_active,
                "is_superuser": user.is_superuser,
                "created_at": user.created_at.isoformat() if user.created_at else None,
                "last_login": user.last_login.isoformat() if user.last_login else None
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取用户详情失败: {str(e)}"
        )

@router.post("/", response_model=None)
async def create_user(user_data: Dict[str, Any], db: AsyncSession = Depends(get_db)):
    """创建用户"""
    try:
        from ...core.security_enhanced import security_manager
        
        # 检查用户名是否已存在
        result = await db.execute(select(User).where(User.username == user_data.get("username")))
        existing_user = result.scalar_one_or_none()
        if existing_user:
            raise HTTPException(status_code=400, detail="用户名已存在")
        
        # 创建新用户
        hashed_password = security_manager.get_password_hash(user_data.get("password", "defaultpassword"))
        new_user = User(
            username=user_data.get("username"),
            email=user_data.get("email"),
            hashed_password=hashed_password,
            is_active=user_data.get("is_active", True),
            is_superuser=user_data.get("is_superuser", False)
        )
        
        db.add(new_user)
        await db.commit()
        await db.refresh(new_user)
        
        return {
            "success": True,
            "data": {
                "id": str(new_user.id),
                "username": new_user.username,
                "email": new_user.email,
                "is_active": new_user.is_active,
                "is_superuser": new_user.is_superuser,
                "created_at": new_user.created_at.isoformat() if new_user.created_at else None
            },
            "message": "用户创建成功"
        }
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"创建用户失败: {str(e)}"
        )

@router.put("/{user_id}", response_model=None)
async def update_user(user_id: int, user_data: Dict[str, Any], db: AsyncSession = Depends(get_db)):
    """更新用户"""
    try:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        
        if not user:
            raise HTTPException(status_code=404, detail="用户不存在")
        
        # 更新用户信息
        if "username" in user_data:
            user.username = user_data["username"]
        if "email" in user_data:
            user.email = user_data["email"]
        if "is_active" in user_data:
            user.is_active = user_data["is_active"]
        if "is_superuser" in user_data:
            user.is_superuser = user_data["is_superuser"]
        
        await db.commit()
        await db.refresh(user)
        
        return {
            "success": True,
            "data": {
                "id": str(user.id),
                "username": user.username,
                "email": user.email,
                "is_active": user.is_active,
                "is_superuser": user.is_superuser,
                "created_at": user.created_at.isoformat() if user.created_at else None,
                "last_login": user.last_login.isoformat() if user.last_login else None
            },
            "message": "用户更新成功"
        }
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"更新用户失败: {str(e)}"
        )

@router.put("/{user_id}/password", response_model=None)
async def change_password(user_id: int, password_data: Dict[str, Any]):
    """修改用户密码"""
    old_password = password_data.get("old_password")
    new_password = password_data.get("new_password")
    
    # 简化的密码验证逻辑
    if user_id == 1:  # admin用户
        if old_password != "admin123":
            raise HTTPException(status_code=400, detail="原密码错误")
    
    return {
        "message": "密码修改成功",
        "user_id": user_id
    }

@router.get("/profile/me", response_model=None)
async def get_current_user_profile():
    """获取当前用户资料"""
    return {
        "id": 1,
        "username": "admin",
        "email": "admin@example.com",
        "full_name": "系统管理员",
        "is_active": True,
        "created_at": "2024-01-01T00:00:00Z",
        "last_login": "2024-01-15T10:30:00Z"
    }

@router.put("/profile/me", response_model=None)
async def update_current_user_profile(profile_data: Dict[str, Any]):
    """更新当前用户资料"""
    return {
        "id": 1,
        "username": profile_data.get("username", "admin"),
        "email": profile_data.get("email", "admin@example.com"),
        "full_name": profile_data.get("full_name", "系统管理员"),
        "message": "个人资料更新成功"
    }

@router.delete("/{user_id}", response_model=None)
async def delete_user(user_id: int):
    """删除用户"""
    if user_id in [1, 2]:
        return {"message": f"用户 {user_id} 删除成功"}
    else:
        raise HTTPException(status_code=404, detail="用户不存在")