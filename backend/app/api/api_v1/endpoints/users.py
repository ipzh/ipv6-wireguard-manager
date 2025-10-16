"""
用户管理API端点 - 简化版本
"""
from typing import Dict, Any, List
from fastapi import APIRouter, HTTPException, status

router = APIRouter()

@router.get("/", response_model=None)
async def get_users():
    """获取用户列表"""
    return [
        {"id": 1, "username": "admin", "email": "admin@example.com", "is_active": True},
        {"id": 2, "username": "user1", "email": "user1@example.com", "is_active": True}
    ]

@router.get("/{user_id}", response_model=None)
async def get_user(user_id: int):
    """获取用户详情"""
    if user_id == 1:
        return {"id": 1, "username": "admin", "email": "admin@example.com", "is_active": True}
    elif user_id == 2:
        return {"id": 2, "username": "user1", "email": "user1@example.com", "is_active": True}
    else:
        raise HTTPException(status_code=404, detail="用户不存在")

@router.post("/", response_model=None)
async def create_user(user_data: Dict[str, Any]):
    """创建用户"""
    return {
        "id": 3,
        "username": user_data.get("username", "newuser"),
        "email": user_data.get("email", "newuser@example.com"),
        "is_active": True,
        "message": "用户创建成功"
    }

@router.put("/{user_id}", response_model=None)
async def update_user(user_id: int, user_data: Dict[str, Any]):
    """更新用户"""
    return {
        "id": user_id,
        "username": user_data.get("username", "updateduser"),
        "email": user_data.get("email", "updated@example.com"),
        "is_active": user_data.get("is_active", True),
        "message": "用户更新成功"
    }

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