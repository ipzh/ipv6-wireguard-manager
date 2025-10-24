"""
标准化日志记录模块
提供统一的日志格式和配置
"""

import os
import sys
import json
import logging
import logging.handlers
import asyncio
from datetime import datetime
from typing import Any, Dict, Optional, Union
from pathlib import Path
import structlog
from structlog.stdlib import LoggerFactory

from .unified_config import settings

class JSONFormatter(logging.Formatter):
    """JSON日志格式化器"""
    
    def format(self, record: logging.LogRecord) -> str:
        """格式化日志记录为JSON"""
        log_entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }
        
        # 添加异常信息
        if record.exc_info:
            log_entry["exception"] = self.formatException(record.exc_info)
        
        # 添加额外字段
        if hasattr(record, 'extra_fields'):
            log_entry.update(record.extra_fields)
        
        # 添加请求信息
        if hasattr(record, 'request_id'):
            log_entry["request_id"] = record.request_id
        if hasattr(record, 'user_id'):
            log_entry["user_id"] = record.user_id
        if hasattr(record, 'ip_address'):
            log_entry["ip_address"] = record.ip_address
        
        return json.dumps(log_entry, ensure_ascii=False)

class SecurityFilter(logging.Filter):
    """安全过滤器，移除敏感信息"""
    
    SENSITIVE_PATTERNS = [
        'password', 'secret', 'key', 'token', 'auth',
        'credential', 'private', 'sensitive'
    ]
    
    def filter(self, record: logging.LogRecord) -> bool:
        """过滤敏感信息"""
        message = record.getMessage().lower()
        
        # 检查是否包含敏感信息
        for pattern in self.SENSITIVE_PATTERNS:
            if pattern in message:
                # 在生产环境中完全过滤敏感日志
                if settings.ENVIRONMENT == "production":
                    return False
                # 在开发环境中替换敏感信息
                else:
                    record.msg = self._mask_sensitive_info(record.msg)
        
        return True
    
    def _mask_sensitive_info(self, message: str) -> str:
        """掩码敏感信息"""
        import re
        
        # 掩码密码
        message = re.sub(r'password["\']?\s*[:=]\s*["\']?[^"\'\s]+', 
                        'password="***"', message, flags=re.IGNORECASE)
        
        # 掩码密钥
        message = re.sub(r'(secret|key|token)["\']?\s*[:=]\s*["\']?[^"\'\s]+', 
                        r'\1="***"', message, flags=re.IGNORECASE)
        
        return message

class LogManager:
    """日志管理器"""
    
    def __init__(self):
        self.loggers = {}
        self._setup_structlog()
        self._setup_standard_logging()
    
    def _setup_structlog(self):
        """设置结构化日志"""
        
        # 配置structlog
        structlog.configure(
            processors=[
                structlog.stdlib.filter_by_level,
                structlog.stdlib.add_logger_name,
                structlog.stdlib.add_log_level,
                structlog.stdlib.PositionalArgumentsFormatter(),
                structlog.processors.TimeStamper(fmt="iso"),
                structlog.processors.StackInfoRenderer(),
                structlog.processors.format_exc_info,
                structlog.processors.UnicodeDecoder(),
                structlog.processors.JSONRenderer()
            ],
            context_class=dict,
            logger_factory=LoggerFactory(),
            wrapper_class=structlog.stdlib.BoundLogger,
            cache_logger_on_first_use=True,
        )
    
    def _setup_standard_logging(self):
        """设置标准日志"""
        
        # 创建日志目录
        log_dir = Path("logs")  # 使用默认日志目录
        log_dir.mkdir(exist_ok=True)
        
        # 配置根日志器
        root_logger = logging.getLogger()
        root_logger.setLevel(getattr(logging, settings.LOG_LEVEL))
        
        # 清除现有处理器
        root_logger.handlers.clear()
        
        # 控制台处理器
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.INFO)
        
        if settings.LOG_FORMAT == "json":
            console_formatter = JSONFormatter()
        else:
            console_formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
        
        console_handler.setFormatter(console_formatter)
        console_handler.addFilter(SecurityFilter())
        root_logger.addHandler(console_handler)
        
        # 文件处理器
        if settings.LOG_FILE:
            file_handler = logging.handlers.RotatingFileHandler(
                log_dir / settings.LOG_FILE,
                maxBytes=10 * 1024 * 1024,  # 10MB
                backupCount=5
            )
            file_handler.setLevel(logging.DEBUG)
            file_handler.setFormatter(JSONFormatter())
            file_handler.addFilter(SecurityFilter())
            root_logger.addHandler(file_handler)
        
        # 错误日志文件
        error_handler = logging.handlers.RotatingFileHandler(
            log_dir / "error.log",
            maxBytes=10 * 1024 * 1024,  # 10MB
            backupCount=5
        )
        error_handler.setLevel(logging.ERROR)
        error_handler.setFormatter(JSONFormatter())
        error_handler.addFilter(SecurityFilter())
        root_logger.addHandler(error_handler)
        
        # 安全日志文件
        security_handler = logging.handlers.RotatingFileHandler(
            log_dir / "security.log",
            maxBytes=10 * 1024 * 1024,  # 10MB
            backupCount=10
        )
        security_handler.setLevel(logging.WARNING)
        security_handler.setFormatter(JSONFormatter())
        root_logger.addHandler(security_handler)
    
    def get_logger(self, name: str) -> structlog.BoundLogger:
        """获取日志器"""
        if name not in self.loggers:
            self.loggers[name] = structlog.get_logger(name)
        return self.loggers[name]
    
    def get_standard_logger(self, name: str) -> logging.Logger:
        """获取标准日志器"""
        return logging.getLogger(name)

# 全局日志管理器
log_manager = LogManager()

# 便捷函数
def get_logger(name: str) -> structlog.BoundLogger:
    """获取结构化日志器"""
    return log_manager.get_logger(name)

def get_standard_logger(name: str) -> logging.Logger:
    """获取标准日志器"""
    return log_manager.get_standard_logger(name)

# 日志装饰器
def log_function_call(logger: structlog.BoundLogger = None):
    """函数调用日志装饰器"""
    def decorator(func):
        async def async_wrapper(*args, **kwargs):
            log = logger or get_logger(func.__module__)
            log.info(
                "函数调用开始",
                function=func.__name__,
                args_count=len(args),
                kwargs_keys=list(kwargs.keys())
            )
            
            try:
                result = await func(*args, **kwargs)
                log.info("函数调用成功", function=func.__name__)
                return result
            except Exception as e:
                log.error("函数调用失败", function=func.__name__, error=str(e))
                raise
        
        def sync_wrapper(*args, **kwargs):
            log = logger or get_logger(func.__module__)
            log.info(
                "函数调用开始",
                function=func.__name__,
                args_count=len(args),
                kwargs_keys=list(kwargs.keys())
            )
            
            try:
                result = func(*args, **kwargs)
                log.info("函数调用成功", function=func.__name__)
                return result
            except Exception as e:
                log.error("函数调用失败", function=func.__name__, error=str(e))
                raise
        
        return async_wrapper if asyncio.iscoroutinefunction(func) else sync_wrapper
    return decorator

def log_performance(logger: structlog.BoundLogger = None):
    """性能日志装饰器"""
    def decorator(func):
        async def async_wrapper(*args, **kwargs):
            log = logger or get_logger(func.__module__)
            start_time = datetime.utcnow()
            
            try:
                result = await func(*args, **kwargs)
                duration = (datetime.utcnow() - start_time).total_seconds()
                log.info(
                    "函数执行完成",
                    function=func.__name__,
                    duration_seconds=duration
                )
                return result
            except Exception as e:
                duration = (datetime.utcnow() - start_time).total_seconds()
                log.error(
                    "函数执行失败",
                    function=func.__name__,
                    duration_seconds=duration,
                    error=str(e)
                )
                raise
        
        def sync_wrapper(*args, **kwargs):
            log = logger or get_logger(func.__module__)
            start_time = datetime.utcnow()
            
            try:
                result = func(*args, **kwargs)
                duration = (datetime.utcnow() - start_time).total_seconds()
                log.info(
                    "函数执行完成",
                    function=func.__name__,
                    duration_seconds=duration
                )
                return result
            except Exception as e:
                duration = (datetime.utcnow() - start_time).total_seconds()
                log.error(
                    "函数执行失败",
                    function=func.__name__,
                    duration_seconds=duration,
                    error=str(e)
                )
                raise
        
        return async_wrapper if asyncio.iscoroutinefunction(func) else sync_wrapper
    return decorator

# 安全日志记录
class SecurityLogger:
    """安全日志记录器"""
    
    def __init__(self):
        self.logger = get_logger("security")
    
    def log_login_attempt(self, username: str, ip_address: str, success: bool, reason: str = None):
        """记录登录尝试"""
        self.logger.warning(
            "登录尝试",
            username=username,
            ip_address=ip_address,
            success=success,
            reason=reason,
            event_type="login_attempt"
        )
    
    def log_permission_denied(self, user_id: str, resource: str, action: str, ip_address: str):
        """记录权限拒绝"""
        self.logger.warning(
            "权限拒绝",
            user_id=user_id,
            resource=resource,
            action=action,
            ip_address=ip_address,
            event_type="permission_denied"
        )
    
    def log_suspicious_activity(self, user_id: str, activity: str, ip_address: str, details: Dict[str, Any]):
        """记录可疑活动"""
        self.logger.error(
            "可疑活动",
            user_id=user_id,
            activity=activity,
            ip_address=ip_address,
            details=details,
            event_type="suspicious_activity"
        )
    
    def log_password_change(self, user_id: str, ip_address: str):
        """记录密码更改"""
        self.logger.info(
            "密码更改",
            user_id=user_id,
            ip_address=ip_address,
            event_type="password_change"
        )
    
    def log_data_access(self, user_id: str, resource: str, action: str, ip_address: str):
        """记录数据访问"""
        self.logger.info(
            "数据访问",
            user_id=user_id,
            resource=resource,
            action=action,
            ip_address=ip_address,
            event_type="data_access"
        )

# 全局安全日志器
security_logger = SecurityLogger()

# 审计日志记录
class AuditLogger:
    """审计日志记录器"""
    
    def __init__(self):
        self.logger = get_logger("audit")
    
    def log_user_action(self, user_id: str, action: str, resource: str, details: Dict[str, Any]):
        """记录用户操作"""
        self.logger.info(
            "用户操作",
            user_id=user_id,
            action=action,
            resource=resource,
            details=details,
            event_type="user_action"
        )
    
    def log_system_event(self, event: str, details: Dict[str, Any]):
        """记录系统事件"""
        self.logger.info(
            "系统事件",
            event=event,
            details=details,
            event_type="system_event"
        )
    
    def log_configuration_change(self, user_id: str, config_key: str, old_value: Any, new_value: Any):
        """记录配置更改"""
        self.logger.info(
            "配置更改",
            user_id=user_id,
            config_key=config_key,
            old_value=str(old_value),
            new_value=str(new_value),
            event_type="config_change"
        )

# 全局审计日志器
audit_logger = AuditLogger()
