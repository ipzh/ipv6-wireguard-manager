"""
用户相关模式定义
"""
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
import uuid


class UserBase(BaseModel):
    """用户基础模式"""
    username: str = Field(..., min_length=3, max_length=50, description="用户名")
    email: EmailStr = Field(..., description="邮箱地址")
    is_active: bool = Field(True, description="是否激活")
    is_superuser: bool = Field(False, description="是否超级用户")


class UserCreate(UserBase):
    """创建用户模式"""
    password: str = Field(..., min_length=6, max_length=100, description="密码")


class UserUpdate(BaseModel):
    """更新用户模式"""
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    email: Optional[EmailStr] = None
    password: Optional[str] = Field(None, min_length=6, max_length=100)
    is_active: Optional[bool] = None
    is_superuser: Optional[bool] = None


class UserInDBBase(UserBase):
    """数据库用户基础模式"""
    id: uuid.UUID
    last_login: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class User(UserInDBBase):
    """用户模式"""
    pass


class UserInDB(UserInDBBase):
    """数据库用户模式"""
    password_hash: str
    salt: str


class RoleBase(BaseModel):
    """角色基础模式"""
    name: str = Field(..., min_length=2, max_length=50, description="角色名称")
    description: Optional[str] = Field(None, description="角色描述")
    permissions: Dict[str, Any] = Field(default_factory=dict, description="权限配置")


class RoleCreate(RoleBase):
    """创建角色模式"""
    pass


class RoleUpdate(BaseModel):
    """更新角色模式"""
    name: Optional[str] = Field(None, min_length=2, max_length=50)
    description: Optional[str] = None
    permissions: Optional[Dict[str, Any]] = None


class Role(RoleBase):
    """角色模式"""
    id: uuid.UUID
    created_at: datetime

    class Config:
        from_attributes = True


class UserWithRoles(User):
    """带角色的用户模式"""
    roles: List[Role] = []


class LoginRequest(BaseModel):
    """登录请求"""
    username: str = Field(..., description="用户名")
    password: str = Field(..., description="密码")


class LoginResponse(BaseModel):
    """登录响应"""
    access_token: str
    token_type: str = "bearer"
    user: User
