"""
数据库会话中间件
"""
import logging
from typing import Callable
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

from .database_manager import database_manager

logger = logging.getLogger(__name__)

class DatabaseSessionMiddleware(BaseHTTPMiddleware):
    """数据库会话中间件"""
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """处理请求"""
        # 将数据库管理器添加到请求状态
        request.state.db_manager = database_manager
        
        # 处理请求
        response = await call_next(request)
        
        return response

class DatabaseHealthMiddleware(BaseHTTPMiddleware):
    """数据库健康检查中间件"""
    
    def __init__(self, app, check_interval: int = 60):
        super().__init__(app)
        self.check_interval = check_interval
        self.last_check_time = 0
        self.health_status = None
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """处理请求"""
        import time
        
        current_time = time.time()
        
        # 定期检查数据库健康状态
        if current_time - self.last_check_time > self.check_interval:
            try:
                from .database_health_enhanced import health_checker
                self.health_status = await health_checker.check_database_health()
                self.last_check_time = current_time
                
                # 如果数据库不健康，记录警告
                if self.health_status["status"] != "healthy":
                    logger.warning(f"数据库健康检查失败: {self.health_status.get('error', '未知错误')}")
                    
            except Exception as e:
                logger.error(f"数据库健康检查异常: {e}")
                self.health_status = {"status": "error", "error": str(e)}
        
        # 将健康状态添加到请求状态
        request.state.db_health = self.health_status
        
        # 处理请求
        response = await call_next(request)
        
        return response
