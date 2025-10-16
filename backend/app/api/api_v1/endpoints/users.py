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

@router.delete("/{user_id}", response_model=None)
async def delete_user(user_id: int):
    """删除用户"""
    if user_id in [1, 2]:
        return {"message": f"用户 {user_id} 删除成功"}
    else:
        raise HTTPException(status_code=404, detail="用户不存在")