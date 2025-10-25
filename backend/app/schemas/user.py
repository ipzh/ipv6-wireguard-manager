"""
用户相关的数据模式定义
"""
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime


class UserBase(BaseModel):
    """用户基础信息"""
    username: str = Field(..., min_length=3, max_length=50, description="用户名")
    email: EmailStr = Field(..., description="邮箱")
    full_name: Optional[str] = Field(None, max_length=100, description="全名")
    phone: Optional[str] = Field(None, max_length=20, description="手机号")
    is_active: bool = Field(True, description="是否活跃")
    is_superuser: bool = Field(False, description="是否超级用户")


class UserCreate(UserBase):
    """创建用户请求"""
    password: str = Field(..., min_length=8, description="密码")


class UserUpdate(BaseModel):
    """更新用户请求"""
    username: Optional[str] = Field(None, min_length=3, max_length=50, description="用户名")
    email: Optional[EmailStr] = Field(None, description="邮箱")
    full_name: Optional[str] = Field(None, max_length=100, description="全名")
    phone: Optional[str] = Field(None, max_length=20, description="手机号")
    is_active: Optional[bool] = Field(None, description="是否活跃")
    is_superuser: Optional[bool] = Field(None, description="是否超级用户")


class UserResponse(UserBase):
    """用户响应"""
    id: str
    created_at: datetime
    updated_at: datetime
    last_login: Optional[datetime] = None
    roles: Optional[List[dict]] = None

    class Config:
        from_attributes = True


class UserListResponse(BaseModel):
    """用户列表响应"""
    users: List[UserResponse]
    total: int
    page: int
    page_size: int
    total_pages: int


class RoleBase(BaseModel):
    """角色基础信息"""
    name: str = Field(..., min_length=2, max_length=50, description="角色名称")
    display_name: str = Field(..., min_length=2, max_length=100, description="显示名称")
    description: Optional[str] = Field(None, description="角色描述")


class RoleCreate(RoleBase):
    """创建角色请求"""
    pass


class RoleUpdate(BaseModel):
    """更新角色请求"""
    name: Optional[str] = Field(None, min_length=2, max_length=50, description="角色名称")
    display_name: Optional[str] = Field(None, min_length=2, max_length=100, description="显示名称")
    description: Optional[str] = Field(None, description="角色描述")


class RoleResponse(RoleBase):
    """角色响应"""
    id: int
    is_system: bool
    created_at: datetime
    updated_at: datetime
    permissions: Optional[List[dict]] = None

    class Config:
        from_attributes = True


class PermissionBase(BaseModel):
    """权限基础信息"""
    name: str = Field(..., min_length=3, max_length=100, description="权限名称")
    description: Optional[str] = Field(None, description="权限描述")
    resource: str = Field(..., min_length=2, max_length=50, description="资源类型")
    action: str = Field(..., min_length=2, max_length=50, description="操作类型")


class PermissionCreate(PermissionBase):
    """创建权限请求"""
    pass


class PermissionResponse(PermissionBase):
    """权限响应"""
    id: int
    created_at: datetime

    class Config:
        from_attributes = True