"""
通用模式定义
"""
from typing import Optional, Any, Dict
from pydantic import BaseModel, Field
from datetime import datetime


class Token(BaseModel):
    """访问令牌"""
    access_token: str
    token_type: str = "bearer"


class TokenPayload(BaseModel):
    """令牌载荷"""
    sub: Optional[str] = None
    exp: Optional[datetime] = None


class Message(BaseModel):
    """通用消息"""
    message: str


class BaseResponse(BaseModel):
    """基础响应"""
    success: bool = True
    message: str = "操作成功"
    data: Optional[Any] = None


class PaginationParams(BaseModel):
    """分页参数"""
    page: int = Field(1, ge=1, description="页码")
    size: int = Field(10, ge=1, le=100, description="每页大小")


class PaginatedResponse(BaseModel):
    """分页响应"""
    items: list
    total: int
    page: int
    size: int
    pages: int


class ErrorResponse(BaseModel):
    """错误响应"""
    success: bool = False
    message: str
    error_code: Optional[str] = None
    details: Optional[Dict[str, Any]] = None
