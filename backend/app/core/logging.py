"""
结构化日志记录器
提供统一的日志记录格式和配置
"""

import logging
import logging.handlers
import json
import sys
from datetime import datetime
from typing import Dict, Any, Optional
from pathlib import Path
import os
from .config_manager import get_config

class StructuredFormatter(logging.Formatter):
    """结构化日志格式化器"""
    
    def __init__(self, include_extra: bool = True):
        super().__init__()
        self.include_extra = include_extra
    
    def format(self, record: logging.LogRecord) -> str:
        """格式化日志记录"""
        # 基础日志信息
        log_data = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
            "thread": record.thread,
            "process": record.process
        }
        
        # 添加异常信息
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)
        
        # 添加额外字段
        if self.include_extra and hasattr(record, "__dict__"):
            extra_fields = {
                k: v for k, v in record.__dict__.items()
                if k not in {
                    "name", "msg", "args", "levelname", "levelno", "pathname",
                    "filename", "module", "lineno", "funcName", "created",
                    "msecs", "relativeCreated", "thread", "threadName",
                    "processName", "process", "getMessage", "exc_info",
                    "exc_text", "stack_info"
                }
            }
            if extra_fields:
                log_data["extra"] = extra_fields
        
        # 过滤敏感信息
        log_data = self._filter_sensitive_data(log_data)
        
        return json.dumps(log_data, ensure_ascii=False)
    
    def _filter_sensitive_data(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """过滤敏感数据"""
        sensitive_keys = [
            "password", "token", "secret", "key", "credential",
            "authorization", "auth", "cookie", "session"
        ]
        
        if isinstance(data, dict):
            filtered_data = {}
            for key, value in data.items():
                # 检查键名是否包含敏感信息
                if any(sensitive_key in key.lower() for sensitive_key in sensitive_keys):
                    filtered_data[key] = "***REDACTED***"
                elif isinstance(value, (dict, list)):
                    # 递归处理嵌套结构
                    filtered_data[key] = self._filter_sensitive_data(value)
                else:
                    filtered_data[key] = value
            return filtered_data
        elif isinstance(data, list):
            return [self._filter_sensitive_data(item) for item in data]
        else:
            return data

class ContextFilter(logging.Filter):
    """上下文过滤器"""
    
    def filter(self, record: logging.LogRecord) -> bool:
        """添加上下文信息"""
        # 添加请求ID（如果存在）
        try:
            from fastapi import Request
            from contextvars import ContextVar
            
            request_id: ContextVar = ContextVar('request_id', default=None)
            request_id_value = request_id.get()
            if request_id_value:
                record.request_id = request_id_value
        except (ImportError, LookupError):
            pass
        
        # 添加用户ID（如果存在）
        try:
            user_id: ContextVar = ContextVar('user_id', default=None)
            user_id_value = user_id.get()
            if user_id_value:
                record.user_id = user_id_value
        except (ImportError, LookupError):
            pass
        
        return True

def setup_logging():
    """设置日志系统"""
    # 获取日志配置
    log_level = get_config("LOG_LEVEL", "INFO")
    log_format = get_config("LOG_FORMAT", "json")
    log_file = get_config("LOG_FILE", None)
    log_rotation = get_config("LOG_ROTATION", "1 day")
    log_retention = get_config("LOG_RETENTION", "30 days")
    
    # 创建根日志记录器
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, log_level.upper()))
    
    # 清除现有处理器
    for handler in root_logger.handlers[:]:
        root_logger.removeHandler(handler)
    
    # 创建控制台处理器
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(getattr(logging, log_level.upper()))
    
    if log_format.lower() == "json":
        console_formatter = StructuredFormatter()
    else:
        console_formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )
    
    console_handler.setFormatter(console_formatter)
    root_logger.addHandler(console_handler)
    
    # 创建文件处理器（如果配置了日志文件）
    if log_file:
        # 确保日志目录存在
        log_dir = Path(log_file).parent
        log_dir.mkdir(parents=True, exist_ok=True)
        
        # 解析轮转配置
        if "day" in log_rotation:
            when = "D"
            interval = int(log_rotation.split()[0])
        elif "hour" in log_rotation:
            when = "H"
            interval = int(log_rotation.split()[0])
        else:
            when = "midnight"
            interval = 1
        
        # 解析保留配置
        if "day" in log_retention:
            backup_count = int(log_retention.split()[0])
        else:
            backup_count = 30
        
        # 创建轮转文件处理器
        file_handler = logging.handlers.TimedRotatingFileHandler(
            filename=log_file,
            when=when,
            interval=interval,
            backupCount=backup_count,
            encoding="utf-8"
        )
        file_handler.setLevel(getattr(logging, log_level.upper()))
        
        if log_format.lower() == "json":
            file_formatter = StructuredFormatter()
        else:
            file_formatter = logging.Formatter(
                "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
            )
        
        file_handler.setFormatter(file_formatter)
        root_logger.addHandler(file_handler)
    
    # 添加上下文过滤器
    context_filter = ContextFilter()
    for handler in root_logger.handlers:
        handler.addFilter(context_filter)
    
    # 设置特定日志记录器的级别
    logging.getLogger("uvicorn").setLevel(logging.INFO)
    logging.getLogger("uvicorn.access").setLevel(logging.INFO)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
    
    # 记录日志系统初始化完成
    logger = logging.getLogger(__name__)
    logger.info("日志系统初始化完成", extra={
        "log_level": log_level,
        "log_format": log_format,
        "log_file": log_file,
        "log_rotation": log_rotation,
        "log_retention": log_retention
    })

def get_logger(name: str) -> logging.Logger:
    """获取日志记录器"""
    return logging.getLogger(name)

# 导出主要组件
__all__ = [
    "StructuredFormatter",
    "ContextFilter",
    "setup_logging",
    "get_logger"
]
