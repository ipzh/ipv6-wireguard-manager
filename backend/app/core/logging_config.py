"""
日志配置模块
使用路径配置管理器
"""
import logging
import logging.handlers
from pathlib import Path
from .path_config import path_config

def setup_logging():
    """设置日志配置"""
    # 使用路径配置获取日志目录
    log_dir = path_config.logs_dir
    log_dir.mkdir(parents=True, exist_ok=True)
    
    # 配置日志文件路径
    log_file = log_dir / "app.log"
    error_log_file = log_dir / "error.log"
    debug_log_file = log_dir / "debug.log"
    
    # 创建日志处理器
    file_handler = logging.handlers.RotatingFileHandler(
        log_file, maxBytes=10*1024*1024, backupCount=5
    )
    error_handler = logging.handlers.RotatingFileHandler(
        error_log_file, maxBytes=10*1024*1024, backupCount=5
    )
    debug_handler = logging.handlers.RotatingFileHandler(
        debug_log_file, maxBytes=10*1024*1024, backupCount=5
    )
    
    # 设置日志级别
    file_handler.setLevel(logging.INFO)
    error_handler.setLevel(logging.ERROR)
    debug_handler.setLevel(logging.DEBUG)
    
    # 创建格式化器
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    json_formatter = logging.Formatter(
        '{"timestamp": "%(asctime)s", "logger": "%(name)s", "level": "%(levelname)s", "message": "%(message)s"}'
    )
    
    file_handler.setFormatter(formatter)
    error_handler.setFormatter(formatter)
    debug_handler.setFormatter(json_formatter)
    
    # 配置根日志器
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)
    root_logger.addHandler(file_handler)
    root_logger.addHandler(error_handler)
    root_logger.addHandler(debug_handler)
    
    # 配置应用特定日志器
    app_logger = logging.getLogger("ipv6_wireguard")
    app_logger.setLevel(logging.INFO)
    
    # 配置数据库日志器
    db_logger = logging.getLogger("sqlalchemy")
    db_logger.setLevel(logging.WARNING)
    
    # 配置WireGuard日志器
    wg_logger = logging.getLogger("wireguard")
    wg_logger.setLevel(logging.INFO)
    
    return root_logger

def get_logger(name: str) -> logging.Logger:
    """获取指定名称的日志器"""
    return logging.getLogger(name)

def set_log_level(level: str):
    """设置日志级别"""
    numeric_level = getattr(logging, level.upper(), logging.INFO)
    logging.getLogger().setLevel(numeric_level)
    
    # 更新所有处理器
    for handler in logging.getLogger().handlers:
        handler.setLevel(numeric_level)

def add_file_handler(logger: logging.Logger, filename: str, level: int = logging.INFO):
    """为指定日志器添加文件处理器"""
    log_dir = path_config.logs_dir
    log_file = log_dir / filename
    
    handler = logging.handlers.RotatingFileHandler(
        log_file, maxBytes=10*1024*1024, backupCount=5
    )
    handler.setLevel(level)
    
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    handler.setFormatter(formatter)
    
    logger.addHandler(handler)
    return handler

def cleanup_old_logs(days: int = 30):
    """清理旧日志文件"""
    import time
    from datetime import datetime, timedelta
    
    log_dir = path_config.logs_dir
    cutoff_time = time.time() - (days * 24 * 60 * 60)
    
    cleaned_count = 0
    for log_file in log_dir.glob("*.log*"):
        if log_file.stat().st_mtime < cutoff_time:
            try:
                log_file.unlink()
                cleaned_count += 1
            except Exception as e:
                logging.error(f"删除旧日志文件失败 {log_file}: {e}")
    
    return cleaned_count
