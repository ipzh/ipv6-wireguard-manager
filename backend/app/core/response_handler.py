"""
统一响应处理器
提供标准化的API响应格式，匹配模拟API的格式（success/data/message）
"""

from typing import Dict, Any, Optional, Union, List
from fastapi import Response
from fastapi.responses import JSONResponse
from datetime import datetime
import json


class ResponseHandler:
    """统一响应处理器"""
    
    @staticmethod
    def success(
        data: Optional[Any] = None,
        message: str = "操作成功",
        status_code: int = 200,
        additional_data: Optional[Dict[str, Any]] = None
    ) -> JSONResponse:
        """
        成功响应
        
        Args:
            data: 响应数据
            message: 响应消息
            status_code: HTTP状态码
            additional_data: 额外的响应数据
            
        Returns:
            JSONResponse: 格式化的成功响应
        """
        response = {
            "success": True,
            "message": message,
            "timestamp": datetime.now().isoformat()
        }
        
        # 添加数据
        if data is not None:
            response["data"] = data
        
        # 添加额外数据
        if additional_data:
            response.update(additional_data)
        
        return JSONResponse(
            status_code=status_code,
            content=response
        )
    
    @staticmethod
    def error(
        message: str = "操作失败",
        status_code: int = 400,
        error_code: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None,
        errors: Optional[List[Dict[str, Any]]] = None
    ) -> JSONResponse:
        """
        错误响应
        
        Args:
            message: 错误消息
            status_code: HTTP状态码
            error_code: 错误代码
            details: 错误详情
            errors: 验证错误列表
            
        Returns:
            JSONResponse: 格式化的错误响应
        """
        response = {
            "success": False,
            "message": message,
            "timestamp": datetime.now().isoformat()
        }
        
        # 添加错误代码
        if error_code:
            response["error_code"] = error_code
        
        # 添加错误详情
        if details:
            response["details"] = details
        
        # 添加验证错误
        if errors:
            response["errors"] = errors
        
        return JSONResponse(
            status_code=status_code,
            content=response
        )
    
    @staticmethod
    def paginated(
        data: List[Any],
        total: int,
        page: int,
        size: int,
        message: str = "获取成功"
    ) -> JSONResponse:
        """
        分页响应
        
        Args:
            data: 数据列表
            total: 总记录数
            page: 当前页码
            size: 每页大小
            message: 响应消息
            
        Returns:
            JSONResponse: 格式化的分页响应
        """
        total_pages = (total + size - 1) // size if size > 0 else 0
        
        return ResponseHandler.success(
            data=data,
            message=message,
            additional_data={
                "pagination": {
                    "total": total,
                    "page": page,
                    "size": size,
                    "total_pages": total_pages,
                    "has_next": page < total_pages,
                    "has_prev": page > 1
                }
            }
        )
    
    @staticmethod
    def created(
        data: Optional[Any] = None,
        message: str = "创建成功"
    ) -> JSONResponse:
        """
        创建成功响应
        
        Args:
            data: 创建的数据
            message: 响应消息
            
        Returns:
            JSONResponse: 格式化的创建成功响应
        """
        return ResponseHandler.success(
            data=data,
            message=message,
            status_code=201
        )
    
    @staticmethod
    def updated(
        data: Optional[Any] = None,
        message: str = "更新成功"
    ) -> JSONResponse:
        """
        更新成功响应
        
        Args:
            data: 更新的数据
            message: 响应消息
            
        Returns:
            JSONResponse: 格式化的更新成功响应
        """
        return ResponseHandler.success(
            data=data,
            message=message
        )
    
    @staticmethod
    def deleted(
        message: str = "删除成功"
    ) -> JSONResponse:
        """
        删除成功响应
        
        Args:
            message: 响应消息
            
        Returns:
            JSONResponse: 格式化的删除成功响应
        """
        return ResponseHandler.success(
            message=message
        )
    
    @staticmethod
    def not_found(
        resource: str = "资源",
        identifier: str = ""
    ) -> JSONResponse:
        """
        资源未找到响应
        
        Args:
            resource: 资源名称
            identifier: 资源标识符
            
        Returns:
            JSONResponse: 格式化的未找到响应
        """
        message = f"{resource}未找到"
        if identifier:
            message += f": {identifier}"
            
        return ResponseHandler.error(
            message=message,
            status_code=404,
            error_code="NOT_FOUND"
        )
    
    @staticmethod
    def validation_error(
        errors: List[Dict[str, Any]],
        message: str = "验证失败"
    ) -> JSONResponse:
        """
        验证错误响应
        
        Args:
            errors: 验证错误列表
            message: 响应消息
            
        Returns:
            JSONResponse: 格式化的验证错误响应
        """
        return ResponseHandler.error(
            message=message,
            status_code=422,
            error_code="VALIDATION_ERROR",
            errors=errors
        )
    
    @staticmethod
    def unauthorized(
        message: str = "未授权访问"
    ) -> JSONResponse:
        """
        未授权响应
        
        Args:
            message: 响应消息
            
        Returns:
            JSONResponse: 格式化的未授权响应
        """
        return ResponseHandler.error(
            message=message,
            status_code=401,
            error_code="UNAUTHORIZED"
        )
    
    @staticmethod
    def forbidden(
        message: str = "权限不足"
    ) -> JSONResponse:
        """
        权限不足响应
        
        Args:
            message: 响应消息
            
        Returns:
            JSONResponse: 格式化的权限不足响应
        """
        return ResponseHandler.error(
            message=message,
            status_code=403,
            error_code="FORBIDDEN"
        )
    
    @staticmethod
    def server_error(
        message: str = "服务器内部错误",
        details: Optional[Dict[str, Any]] = None
    ) -> JSONResponse:
        """
        服务器错误响应
        
        Args:
            message: 响应消息
            details: 错误详情
            
        Returns:
            JSONResponse: 格式化的服务器错误响应
        """
        return ResponseHandler.error(
            message=message,
            status_code=500,
            error_code="INTERNAL_SERVER_ERROR",
            details=details
        )


# 创建默认实例
response_handler = ResponseHandler()

# 导出主要组件
__all__ = [
    "ResponseHandler",
    "response_handler"
]