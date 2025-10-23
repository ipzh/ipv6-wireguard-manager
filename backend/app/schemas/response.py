"""
统一API响应格式定义
确保前后端数据结构一致
"""
from typing import Optional, Any, Dict, List
from pydantic import BaseModel, Field


class APIResponse(BaseModel):
    """
    统一的API响应格式
    所有API端点应返回此格式
    """
    success: bool = Field(..., description="操作是否成功")
    data: Optional[Any] = Field(None, description="响应数据")
    message: Optional[str] = Field(None, description="响应消息")
    error: Optional[str] = Field(None, description="错误代码")
    detail: Optional[str] = Field(None, description="错误详情")
    
    class Config:
        json_schema_extra = {
            "example": {
                "success": True,
                "data": {"id": 1, "name": "example"},
                "message": "操作成功"
            }
        }


class SuccessResponse(APIResponse):
    """成功响应"""
    success: bool = True
    error: Optional[str] = None
    detail: Optional[str] = None


class ErrorResponse(APIResponse):
    """错误响应"""
    success: bool = False
    data: Optional[Any] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "success": False,
                "error": "VALIDATION_ERROR",
                "detail": "请求参数不正确",
                "message": "操作失败"
            }
        }


class PaginatedResponse(BaseModel):
    """分页响应"""
    success: bool = True
    data: List[Any] = Field(default_factory=list, description="数据列表")
    total: int = Field(0, description="总记录数")
    page: int = Field(1, description="当前页码")
    page_size: int = Field(20, description="每页记录数")
    total_pages: int = Field(0, description="总页数")
    
    class Config:
        json_schema_extra = {
            "example": {
                "success": True,
                "data": [{"id": 1}, {"id": 2}],
                "total": 100,
                "page": 1,
                "page_size": 20,
                "total_pages": 5
            }
        }


class TokenResponse(BaseModel):
    """令牌响应"""
    access_token: str = Field(..., description="访问令牌")
    refresh_token: Optional[str] = Field(None, description="刷新令牌")
    token_type: str = Field("bearer", description="令牌类型")
    expires_in: int = Field(..., description="过期时间（秒）")


class MessageResponse(BaseModel):
    """简单消息响应"""
    message: str = Field(..., description="消息内容")


# 辅助函数
def success_response(data: Any = None, message: str = "操作成功") -> Dict:
    """
    创建成功响应
    
    Args:
        data: 响应数据
        message: 响应消息
        
    Returns:
        响应字典
    """
    return {
        "success": True,
        "data": data,
        "message": message
    }


def error_response(
    error_code: str = "UNKNOWN_ERROR",
    detail: str = "未知错误",
    message: str = "操作失败"
) -> Dict:
    """
    创建错误响应
    
    Args:
        error_code: 错误代码
        detail: 错误详情
        message: 错误消息
        
    Returns:
        响应字典
    """
    return {
        "success": False,
        "error": error_code,
        "detail": detail,
        "message": message
    }


def paginated_response(
    data: List,
    total: int,
    page: int = 1,
    page_size: int = 20
) -> Dict:
    """
    创建分页响应
    
    Args:
        data: 数据列表
        total: 总记录数
        page: 当前页码
        page_size: 每页记录数
        
    Returns:
        响应字典
    """
    total_pages = (total + page_size - 1) // page_size
    
    return {
        "success": True,
        "data": data,
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": total_pages
    }
