"""
速率限制工具 - 提供API请求速率限制功能
"""
import time
from typing import Callable, Dict, Optional, Tuple
from functools import wraps
from fastapi import HTTPException, Request, status

from ..core.logging import get_logger

logger = get_logger(__name__)

# 简单的内存限流器
_rate_limit_storage: Dict[str, Dict[str, Tuple[int, float]]] = {}


def rate_limit(requests: int = 100, window: int = 60):
    """
    API限流装饰器
    
    Args:
        requests: 时间窗口内允许的请求数
        window: 时间窗口（秒）
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # 获取请求对象
            request = None
            for arg in args:
                if isinstance(arg, Request):
                    request = arg
                    break
            
            if not request:
                # 如果没有请求对象，跳过限流
                return await func(*args, **kwargs)
            
            # 获取客户端IP
            client_ip = request.client.host if request.client else "unknown"
            
            # 获取当前时间
            current_time = time.time()
            
            # 获取或创建客户端记录
            if client_ip not in _rate_limit_storage:
                _rate_limit_storage[client_ip] = {}
            
            client_data = _rate_limit_storage[client_ip]
            
            # 清理过期的请求记录
            expired_keys = []
            for key, (count, timestamp) in client_data.items():
                if current_time - timestamp > window:
                    expired_keys.append(key)
            
            for key in expired_keys:
                del client_data[key]
            
            # 检查当前请求的限流
            request_key = f"{request.method}:{request.url.path}"
            
            if request_key in client_data:
                count, timestamp = client_data[request_key]
                if current_time - timestamp <= window:
                    if count >= requests:
                        logger.warning(
                            "Rate limit exceeded",
                            client_ip=client_ip,
                            request_key=request_key,
                            count=count,
                            limit=requests
                        )
                        raise HTTPException(
                            status_code=429,
                            detail=f"请求过于频繁，请稍后再试。限制：{requests}次/{window}秒"
                        )
                    else:
                        client_data[request_key] = (count + 1, timestamp)
                else:
                    client_data[request_key] = (1, current_time)
            else:
                client_data[request_key] = (1, current_time)
            
            return await func(*args, **kwargs)
        
        return wrapper
    return decorator


def clear_rate_limit_storage():
    """清理限流存储"""
    global _rate_limit_storage
    _rate_limit_storage.clear()


def get_rate_limit_stats() -> Dict[str, Dict[str, Tuple[int, float]]]:
    """获取限流统计信息"""
    return _rate_limit_storage.copy()
