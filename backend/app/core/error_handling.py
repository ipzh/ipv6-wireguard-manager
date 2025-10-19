"""
统一错误处理框架
提供统一的错误定义、处理和响应格式
"""

from typing import Dict, Any, Optional, List
from fastapi import HTTPException, Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
import traceback
from datetime import datetime
import uuid
from .response_handler import ResponseHandler
from .logging import get_logger

logger = get_logger(__name__)

class ErrorCode:
    """错误码常量"""
    
    # 通用错误
    INTERNAL_SERVER_ERROR = "INTERNAL_SERVER_ERROR"
    BAD_REQUEST = "BAD_REQUEST"
    UNAUTHORIZED = "UNAUTHORIZED"
    FORBIDDEN = "FORBIDDEN"
    NOT_FOUND = "NOT_FOUND"
    METHOD_NOT_ALLOWED = "METHOD_NOT_ALLOWED"
    CONFLICT = "CONFLICT"
    UNPROCESSABLE_ENTITY = "UNPROCESSABLE_ENTITY"
    TOO_MANY_REQUESTS = "TOO_MANY_REQUESTS"
    
    # 认证相关错误
    INVALID_CREDENTIALS = "INVALID_CREDENTIALS"
    TOKEN_EXPIRED = "TOKEN_EXPIRED"
    TOKEN_INVALID = "TOKEN_INVALID"
    ACCOUNT_LOCKED = "ACCOUNT_LOCKED"
    ACCOUNT_NOT_VERIFIED = "ACCOUNT_NOT_VERIFIED"
    
    # 用户相关错误
    USER_NOT_FOUND = "USER_NOT_FOUND"
    USER_ALREADY_EXISTS = "USER_ALREADY_EXISTS"
    INVALID_PASSWORD = "INVALID_PASSWORD"
    PASSWORD_TOO_WEAK = "PASSWORD_TOO_WEAK"
    
    # 权限相关错误
    PERMISSION_DENIED = "PERMISSION_DENIED"
    ROLE_NOT_FOUND = "ROLE_NOT_FOUND"
    ROLE_ALREADY_EXISTS = "ROLE_ALREADY_EXISTS"
    
    # WireGuard相关错误
    WIREGUARD_SERVER_NOT_FOUND = "WIREGUARD_SERVER_NOT_FOUND"
    WIREGUARD_SERVER_ALREADY_EXISTS = "WIREGUARD_SERVER_ALREADY_EXISTS"
    WIREGUARD_SERVER_OPERATION_FAILED = "WIREGUARD_SERVER_OPERATION_FAILED"
    WIREGUARD_CLIENT_NOT_FOUND = "WIREGUARD_CLIENT_NOT_FOUND"
    WIREGUARD_CLIENT_ALREADY_EXISTS = "WIREGUARD_CLIENT_ALREADY_EXISTS"
    WIREGUARD_CLIENT_OPERATION_FAILED = "WIREGUARD_CLIENT_OPERATION_FAILED"
    
    # BGP相关错误
    BGP_SESSION_NOT_FOUND = "BGP_SESSION_NOT_FOUND"
    BGP_SESSION_ALREADY_EXISTS = "BGP_SESSION_ALREADY_EXISTS"
    BGP_SESSION_OPERATION_FAILED = "BGP_SESSION_OPERATION_FAILED"
    
    # IPv6相关错误
    IPV6_POOL_NOT_FOUND = "IPV6_POOL_NOT_FOUND"
    IPV6_POOL_ALREADY_EXISTS = "IPV6_POOL_ALREADY_EXISTS"
    IPV6_POOL_EXHAUSTED = "IPV6_POOL_EXHAUSTED"
    IPV6_ADDRESS_NOT_FOUND = "IPV6_ADDRESS_NOT_FOUND"
    IPV6_ADDRESS_ALREADY_EXISTS = "IPV6_ADDRESS_ALREADY_EXISTS"
    
    # 系统相关错误
    SYSTEM_ERROR = "SYSTEM_ERROR"
    DATABASE_ERROR = "DATABASE_ERROR"
    NETWORK_ERROR = "NETWORK_ERROR"
    FILE_OPERATION_ERROR = "FILE_OPERATION_ERROR"
    CONFIGURATION_ERROR = "CONFIGURATION_ERROR"

class APIError(Exception):
    """API错误基类"""
    
    def __init__(
        self,
        error_code: str,
        message: str,
        status_code: int = status.HTTP_500_INTERNAL_SERVER_ERROR,
        details: Optional[Dict[str, Any]] = None,
        cause: Optional[Exception] = None
    ):
        self.error_code = error_code
        self.message = message
        self.status_code = status_code
        self.details = details or {}
        self.cause = cause
        self.timestamp = datetime.utcnow()
        self.request_id = str(uuid.uuid4())
        
        # 记录错误日志
        self._log_error()
        
        super().__init__(self.message)
    
    def _log_error(self):
        """记录错误日志"""
        error_data = {
            "error_code": self.error_code,
            "message": self.message,
            "status_code": self.status_code,
            "details": self.details,
            "request_id": self.request_id,
            "timestamp": self.timestamp.isoformat()
        }
        
        if self.cause:
            error_data["cause"] = str(self.cause)
            error_data["traceback"] = traceback.format_exc()
        
        logger.error(f"API Error: {error_data}")
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典格式"""
        return {
            "success": False,
            "message": self.message,
            "error_code": self.error_code,
            "timestamp": self.timestamp.isoformat(),
            "details": self.details,
            "request_id": self.request_id
        }

class ValidationError(APIError):
    """验证错误"""
    
    def __init__(
        self,
        message: str = "Validation failed",
        details: Optional[Dict[str, Any]] = None,
        cause: Optional[Exception] = None
    ):
        super().__init__(
            error_code=ErrorCode.UNPROCESSABLE_ENTITY,
            message=message,
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            details=details,
            cause=cause
        )

class AuthenticationError(APIError):
    """认证错误"""
    
    def __init__(
        self,
        message: str = "Authentication failed",
        details: Optional[Dict[str, Any]] = None,
        cause: Optional[Exception] = None
    ):
        super().__init__(
            error_code=ErrorCode.UNAUTHORIZED,
            message=message,
            status_code=status.HTTP_401_UNAUTHORIZED,
            details=details,
            cause=cause
        )

class AuthorizationError(APIError):
    """授权错误"""
    
    def __init__(
        self,
        message: str = "Access denied",
        details: Optional[Dict[str, Any]] = None,
        cause: Optional[Exception] = None
    ):
        super().__init__(
            error_code=ErrorCode.FORBIDDEN,
            message=message,
            status_code=status.HTTP_403_FORBIDDEN,
            details=details,
            cause=cause
        )

class NotFoundError(APIError):
    """资源未找到错误"""
    
    def __init__(
        self,
        resource: str,
        identifier: str,
        details: Optional[Dict[str, Any]] = None,
        cause: Optional[Exception] = None
    ):
        message = f"{resource} with identifier '{identifier}' not found"
        super().__init__(
            error_code=ErrorCode.NOT_FOUND,
            message=message,
            status_code=status.HTTP_404_NOT_FOUND,
            details=details,
            cause=cause
        )

class ConflictError(APIError):
    """资源冲突错误"""
    
    def __init__(
        self,
        resource: str,
        identifier: str,
        details: Optional[Dict[str, Any]] = None,
        cause: Optional[Exception] = None
    ):
        message = f"{resource} with identifier '{identifier}' already exists"
        super().__init__(
            error_code=ErrorCode.CONFLICT,
            message=message,
            status_code=status.HTTP_409_CONFLICT,
            details=details,
            cause=cause
        )

class BusinessLogicError(APIError):
    """业务逻辑错误"""
    
    def __init__(
        self,
        error_code: str,
        message: str,
        details: Optional[Dict[str, Any]] = None,
        cause: Optional[Exception] = None
    ):
        super().__init__(
            error_code=error_code,
            message=message,
            status_code=status.HTTP_400_BAD_REQUEST,
            details=details,
            cause=cause
        )

class SystemError(APIError):
    """系统错误"""
    
    def __init__(
        self,
        message: str = "Internal system error",
        details: Optional[Dict[str, Any]] = None,
        cause: Optional[Exception] = None
    ):
        super().__init__(
            error_code=ErrorCode.INTERNAL_SERVER_ERROR,
            message=message,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            details=details,
            cause=cause
        )

async def api_error_handler(request: Request, exc: APIError) -> JSONResponse:
    """API错误处理器"""
    return ResponseHandler.error(
        message=exc.message,
        status_code=exc.status_code,
        error_code=exc.error_code,
        details=exc.details,
        errors=None
    )

async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """HTTP异常处理器"""
    return ResponseHandler.error(
        message=exc.detail,
        status_code=exc.status_code,
        error_code="HTTP_ERROR"
    )

async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    """验证异常处理器"""
    errors = []
    for error in exc.errors():
        errors.append({
            "field": ".".join(str(loc) for loc in error["loc"]),
            "message": error["msg"],
            "type": error["type"]
        })
    
    return ResponseHandler.validation_error(
        errors=errors,
        message="验证失败"
    )

async def general_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """通用异常处理器"""
    return ResponseHandler.server_error(
        message="发生意外错误",
        details={
            "exception_type": type(exc).__name__,
            "exception_message": str(exc)
        }
    )

# 导出主要组件
__all__ = [
    "ErrorCode",
    "APIError",
    "ValidationError",
    "AuthenticationError",
    "AuthorizationError",
    "NotFoundError",
    "ConflictError",
    "BusinessLogicError",
    "SystemError",
    "api_error_handler",
    "http_exception_handler",
    "validation_exception_handler",
    "general_exception_handler",
    "ResponseHandler"
]
