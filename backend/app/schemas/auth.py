"""
认证相关的数据模式定义
"""
from typing import Optional
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime


class Token(BaseModel):
    """访问令牌响应"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: Optional[dict] = None


class TokenRefresh(BaseModel):
    """刷新令牌请求"""
    refresh_token: str


class UserLogin(BaseModel):
    """用户登录请求"""
    username: str = Field(..., min_length=3, max_length=50, description="用户名或邮箱")
    password: str = Field(..., min_length=8, description="密码")


class UserResponse(BaseModel):
    """用户响应"""
    id: str
    username: str
    email: str
    full_name: Optional[str] = None
    phone: Optional[str] = None
    is_active: bool = True
    is_superuser: bool = False
    created_at: datetime
    last_login: Optional[datetime] = None
    roles: Optional[list] = None

    class Config:
        from_attributes = True


class PasswordChange(BaseModel):
    """密码修改请求"""
    old_password: str = Field(..., description="旧密码")
    new_password: str = Field(..., min_length=8, description="新密码")


class PasswordReset(BaseModel):
    """密码重置请求"""
    token: str = Field(..., description="重置令牌")
    new_password: str = Field(..., min_length=8, description="新密码")


class UserRegister(BaseModel):
    """用户注册请求"""
    username: str = Field(..., min_length=3, max_length=50, description="用户名")
    email: EmailStr = Field(..., description="邮箱")
    password: str = Field(..., min_length=8, description="密码")
    full_name: Optional[str] = Field(None, max_length=100, description="全名")
    phone: Optional[str] = Field(None, max_length=20, description="手机号")


class ForgotPassword(BaseModel):
    """忘记密码请求"""
    email: EmailStr = Field(..., description="邮箱")


class TokenVerify(BaseModel):
    """令牌验证响应"""
    valid: bool
    user: Optional[dict] = None
