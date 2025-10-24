"""
全局异常处理器
提供统一的错误处理和响应格式
"""

import logging
import traceback
from typing import Any, Dict, Optional
from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from sqlalchemy.exc import SQLAlchemyError, IntegrityError
from pydantic import ValidationError
import structlog

# 配置结构化日志
logger = structlog.get_logger()

class CustomHTTPException(HTTPException):
    """自定义HTTP异常"""
    
    def __init__(
        self,
        status_code: int,
        detail: str,
        error_code: Optional[str] = None,
        headers: Optional[Dict[str, Any]] = None
    ):
        super().__init__(status_code=status_code, detail=detail, headers=headers)
        self.error_code = error_code

class BusinessLogicError(Exception):
    """业务逻辑错误"""
    
    def __init__(self, message: str, error_code: str = "BUSINESS_ERROR"):
        self.message = message
        self.error_code = error_code
        super().__init__(message)

class DatabaseError(Exception):
    """数据库错误"""
    
    def __init__(self, message: str, original_error: Optional[Exception] = None):
        self.message = message
        self.original_error = original_error
        super().__init__(message)

class SecurityError(Exception):
    """安全相关错误"""
    
    def __init__(self, message: str, error_code: str = "SECURITY_ERROR"):
        self.message = message
        self.error_code = error_code
        super().__init__(message)

def create_error_response(
    status_code: int,
    message: str,
    error_code: Optional[str] = None,
    details: Optional[Dict[str, Any]] = None
) -> JSONResponse:
    """创建标准错误响应"""
    
    error_response = {
        "error": True,
        "message": message,
        "status_code": status_code,
        "timestamp": structlog.get_logger().info("timestamp"),
    }
    
    if error_code:
        error_response["error_code"] = error_code
    
    if details:
        error_response["details"] = details
    
    return JSONResponse(
        status_code=status_code,
        content=error_response
    )

async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """HTTP异常处理器"""
    
    logger.warning(
        "HTTP异常",
        status_code=exc.status_code,
        detail=exc.detail,
        path=request.url.path,
        method=request.method,
        client_ip=request.client.host if request.client else None
    )
    
    return create_error_response(
        status_code=exc.status_code,
        message=exc.detail,
        error_code=getattr(exc, 'error_code', None)
    )

async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    """请求验证异常处理器"""
    
    logger.warning(
        "请求验证失败",
        errors=exc.errors(),
        path=request.url.path,
        method=request.method,
        client_ip=request.client.host if request.client else None
    )
    
    return create_error_response(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        message="请求数据验证失败",
        error_code="VALIDATION_ERROR",
        details={"validation_errors": exc.errors()}
    )

async def sqlalchemy_exception_handler(request: Request, exc: SQLAlchemyError) -> JSONResponse:
    """SQLAlchemy异常处理器"""
    
    logger.error(
        "数据库错误",
        error_type=type(exc).__name__,
        error_message=str(exc),
        path=request.url.path,
        method=request.method,
        client_ip=request.client.host if request.client else None
    )
    
    # 根据异常类型返回不同的错误信息
    if isinstance(exc, IntegrityError):
        return create_error_response(
            status_code=status.HTTP_409_CONFLICT,
            message="数据完整性约束违反",
            error_code="INTEGRITY_ERROR"
        )
    else:
        return create_error_response(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            message="数据库操作失败",
            error_code="DATABASE_ERROR"
        )

async def business_logic_exception_handler(request: Request, exc: BusinessLogicError) -> JSONResponse:
    """业务逻辑异常处理器"""
    
    logger.warning(
        "业务逻辑错误",
        error_code=exc.error_code,
        message=exc.message,
        path=request.url.path,
        method=request.method,
        client_ip=request.client.host if request.client else None
    )
    
    return create_error_response(
        status_code=status.HTTP_400_BAD_REQUEST,
        message=exc.message,
        error_code=exc.error_code
    )

async def security_exception_handler(request: Request, exc: SecurityError) -> JSONResponse:
    """安全异常处理器"""
    
    logger.warning(
        "安全错误",
        error_code=exc.error_code,
        message=exc.message,
        path=request.url.path,
        method=request.method,
        client_ip=request.client.host if request.client else None
    )
    
    return create_error_response(
        status_code=status.HTTP_403_FORBIDDEN,
        message=exc.message,
        error_code=exc.error_code
    )

async def database_exception_handler(request: Request, exc: DatabaseError) -> JSONResponse:
    """数据库异常处理器"""
    
    logger.error(
        "数据库错误",
        message=exc.message,
        original_error=str(exc.original_error) if exc.original_error else None,
        path=request.url.path,
        method=request.method,
        client_ip=request.client.host if request.client else None
    )
    
    return create_error_response(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        message="数据库操作失败",
        error_code="DATABASE_ERROR"
    )

async def general_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """通用异常处理器"""
    
    logger.error(
        "未处理的异常",
        error_type=type(exc).__name__,
        error_message=str(exc),
        traceback=traceback.format_exc(),
        path=request.url.path,
        method=request.method,
        client_ip=request.client.host if request.client else None
    )
    
    # 在生产环境中不暴露详细错误信息
    from .unified_config import settings
    
    if settings.is_production():
        message = "服务器内部错误"
        details = None
    else:
        message = f"未处理的异常: {str(exc)}"
        details = {"traceback": traceback.format_exc()}
    
    return create_error_response(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        message=message,
        error_code="INTERNAL_ERROR",
        details=details
    )

def register_exception_handlers(app):
    """注册异常处理器"""
    
    # HTTP异常
    app.add_exception_handler(HTTPException, http_exception_handler)
    app.add_exception_handler(CustomHTTPException, http_exception_handler)
    
    # 验证异常
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(ValidationError, validation_exception_handler)
    
    # 数据库异常
    app.add_exception_handler(SQLAlchemyError, sqlalchemy_exception_handler)
    app.add_exception_handler(DatabaseError, database_exception_handler)
    
    # 业务异常
    app.add_exception_handler(BusinessLogicError, business_logic_exception_handler)
    app.add_exception_handler(SecurityError, security_exception_handler)
    
    # 通用异常处理器（必须最后注册）
    app.add_exception_handler(Exception, general_exception_handler)

# 错误代码定义
class ErrorCodes:
    """错误代码常量"""
    
    # 认证和授权
    AUTHENTICATION_FAILED = "AUTH_FAILED"
    AUTHORIZATION_FAILED = "AUTHZ_FAILED"
    TOKEN_EXPIRED = "TOKEN_EXPIRED"
    TOKEN_INVALID = "TOKEN_INVALID"
    
    # 验证错误
    VALIDATION_ERROR = "VALIDATION_ERROR"
    REQUIRED_FIELD_MISSING = "REQUIRED_FIELD_MISSING"
    INVALID_FORMAT = "INVALID_FORMAT"
    
    # 业务逻辑错误
    RESOURCE_NOT_FOUND = "RESOURCE_NOT_FOUND"
    RESOURCE_ALREADY_EXISTS = "RESOURCE_EXISTS"
    OPERATION_NOT_ALLOWED = "OPERATION_NOT_ALLOWED"
    QUOTA_EXCEEDED = "QUOTA_EXCEEDED"
    
    # 数据库错误
    DATABASE_ERROR = "DATABASE_ERROR"
    INTEGRITY_ERROR = "INTEGRITY_ERROR"
    CONNECTION_ERROR = "CONNECTION_ERROR"
    
    # 网络错误
    NETWORK_ERROR = "NETWORK_ERROR"
    TIMEOUT_ERROR = "TIMEOUT_ERROR"
    SERVICE_UNAVAILABLE = "SERVICE_UNAVAILABLE"
    
    # 安全错误
    SECURITY_ERROR = "SECURITY_ERROR"
    RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED"
    SUSPICIOUS_ACTIVITY = "SUSPICIOUS_ACTIVITY"
    
    # 系统错误
    INTERNAL_ERROR = "INTERNAL_ERROR"
    CONFIGURATION_ERROR = "CONFIG_ERROR"
    MAINTENANCE_MODE = "MAINTENANCE_MODE"

# 便捷的错误创建函数
def raise_not_found(message: str = "资源未找到") -> CustomHTTPException:
    """抛出404错误"""
    return CustomHTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail=message,
        error_code=ErrorCodes.RESOURCE_NOT_FOUND
    )

def raise_bad_request(message: str, error_code: str = ErrorCodes.VALIDATION_ERROR) -> CustomHTTPException:
    """抛出400错误"""
    return CustomHTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail=message,
        error_code=error_code
    )

def raise_unauthorized(message: str = "未授权访问") -> CustomHTTPException:
    """抛出401错误"""
    return CustomHTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=message,
        error_code=ErrorCodes.AUTHENTICATION_FAILED
    )

def raise_forbidden(message: str = "禁止访问") -> CustomHTTPException:
    """抛出403错误"""
    return CustomHTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail=message,
        error_code=ErrorCodes.AUTHORIZATION_FAILED
    )

def raise_conflict(message: str = "资源冲突") -> CustomHTTPException:
    """抛出409错误"""
    return CustomHTTPException(
        status_code=status.HTTP_409_CONFLICT,
        detail=message,
        error_code=ErrorCodes.RESOURCE_ALREADY_EXISTS
    )

def raise_internal_error(message: str = "服务器内部错误") -> CustomHTTPException:
    """抛出500错误"""
    return CustomHTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail=message,
        error_code=ErrorCodes.INTERNAL_ERROR
    )
