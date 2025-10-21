"""
错误处理机制增强实现
基于您的分析，实现分布式错误追踪、日志结构化、性能监控等功能
"""

import traceback
import logging
import json
import time
import uuid
from typing import Dict, Any, Optional, List, Callable
from datetime import datetime
from dataclasses import dataclass, asdict
from enum import Enum
import threading
from collections import defaultdict, deque
import psutil
import asyncio

logger = logging.getLogger(__name__)

class ErrorSeverity(Enum):
    """错误严重程度"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class ErrorCategory(Enum):
    """错误分类"""
    AUTHENTICATION = "authentication"
    AUTHORIZATION = "authorization"
    VALIDATION = "validation"
    DATABASE = "database"
    NETWORK = "network"
    SYSTEM = "system"
    BUSINESS_LOGIC = "business_logic"
    EXTERNAL_API = "external_api"

@dataclass
class ErrorContext:
    """错误上下文"""
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    request_id: Optional[str] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    endpoint: Optional[str] = None
    method: Optional[str] = None
    parameters: Optional[Dict[str, Any]] = None
    timestamp: Optional[datetime] = None

@dataclass
class ErrorEvent:
    """错误事件"""
    id: str
    error_type: str
    message: str
    severity: ErrorSeverity
    category: ErrorCategory
    context: ErrorContext
    stack_trace: Optional[str] = None
    additional_data: Optional[Dict[str, Any]] = None
    resolved: bool = False
    created_at: datetime = None
    
    def __post_init__(self):
        if self.created_at is None:
            self.created_at = datetime.now()

class DistributedTracing:
    """分布式错误追踪"""
    
    def __init__(self):
        self.traces: Dict[str, List[ErrorEvent]] = defaultdict(list)
        self.correlation_ids: Dict[str, str] = {}
    
    def start_trace(self, correlation_id: Optional[str] = None) -> str:
        """开始追踪"""
        if correlation_id is None:
            correlation_id = str(uuid.uuid4())
        
        self.correlation_ids[correlation_id] = correlation_id
        return correlation_id
    
    def add_error_to_trace(self, correlation_id: str, error_event: ErrorEvent):
        """添加错误到追踪"""
        self.traces[correlation_id].append(error_event)
    
    def get_trace(self, correlation_id: str) -> List[ErrorEvent]:
        """获取追踪信息"""
        return self.traces.get(correlation_id, [])
    
    def get_trace_summary(self, correlation_id: str) -> Dict[str, Any]:
        """获取追踪摘要"""
        errors = self.get_trace(correlation_id)
        
        if not errors:
            return {"correlation_id": correlation_id, "errors": []}
        
        severity_counts = defaultdict(int)
        category_counts = defaultdict(int)
        
        for error in errors:
            severity_counts[error.severity.value] += 1
            category_counts[error.category.value] += 1
        
        return {
            "correlation_id": correlation_id,
            "total_errors": len(errors),
            "severity_distribution": dict(severity_counts),
            "category_distribution": dict(category_counts),
            "first_error": errors[0].created_at.isoformat(),
            "last_error": errors[-1].created_at.isoformat(),
            "duration_seconds": (errors[-1].created_at - errors[0].created_at).total_seconds()
        }

class StructuredLogger:
    """结构化日志记录器"""
    
    def __init__(self, name: str = "structured_logger"):
        self.logger = logging.getLogger(name)
        self.logger.setLevel(logging.INFO)
        
        # 创建JSON格式化器
        self.json_formatter = JSONFormatter()
        
        # 创建文件处理器
        file_handler = logging.FileHandler("structured_errors.log")
        file_handler.setFormatter(self.json_formatter)
        self.logger.addHandler(file_handler)
        
        # 创建控制台处理器
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(self.json_formatter)
        self.logger.addHandler(console_handler)
    
    def log_error(self, error_event: ErrorEvent):
        """记录错误事件"""
        log_data = {
            "timestamp": error_event.created_at.isoformat(),
            "level": "ERROR",
            "error_id": error_event.id,
            "error_type": error_event.error_type,
            "message": error_event.message,
            "severity": error_event.severity.value,
            "category": error_event.category.value,
            "context": asdict(error_event.context),
            "stack_trace": error_event.stack_trace,
            "additional_data": error_event.additional_data,
            "resolved": error_event.resolved
        }
        
        self.logger.error(json.dumps(log_data, ensure_ascii=False))
    
    def log_performance(self, operation: str, duration: float, metadata: Optional[Dict[str, Any]] = None):
        """记录性能数据"""
        log_data = {
            "timestamp": datetime.now().isoformat(),
            "level": "INFO",
            "type": "performance",
            "operation": operation,
            "duration_ms": duration * 1000,
            "metadata": metadata or {}
        }
        
        self.logger.info(json.dumps(log_data, ensure_ascii=False))

class JSONFormatter(logging.Formatter):
    """JSON格式化器"""
    
    def format(self, record):
        log_entry = {
            "timestamp": datetime.fromtimestamp(record.created).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno
        }
        
        # 添加异常信息
        if record.exc_info:
            log_entry["exception"] = self.formatException(record.exc_info)
        
        # 添加额外字段
        if hasattr(record, 'extra_fields'):
            log_entry.update(record.extra_fields)
        
        return json.dumps(log_entry, ensure_ascii=False)

class PerformanceMonitor:
    """性能监控器"""
    
    def __init__(self):
        self.metrics: Dict[str, deque] = defaultdict(lambda: deque(maxlen=1000))
        self.active_operations: Dict[str, float] = {}
        self.system_metrics = {}
        self.monitoring = False
        self.monitor_thread = None
    
    def start_monitoring(self, interval: int = 30):
        """启动性能监控"""
        if self.monitoring:
            return
        
        self.monitoring = True
        self.monitor_thread = threading.Thread(
            target=self._monitor_loop,
            args=(interval,),
            daemon=True
        )
        self.monitor_thread.start()
        logger.info("性能监控已启动")
    
    def stop_monitoring(self):
        """停止性能监控"""
        self.monitoring = False
        if self.monitor_thread:
            self.monitor_thread.join()
        logger.info("性能监控已停止")
    
    def _monitor_loop(self, interval: int):
        """监控循环"""
        while self.monitoring:
            try:
                # 收集系统指标
                self._collect_system_metrics()
                
                # 记录性能指标
                self._record_performance_metrics()
                
                time.sleep(interval)
            except Exception as e:
                logger.error(f"性能监控错误: {e}")
                time.sleep(interval)
    
    def _collect_system_metrics(self):
        """收集系统指标"""
        try:
            self.system_metrics = {
                "cpu_percent": psutil.cpu_percent(),
                "memory_percent": psutil.virtual_memory().percent,
                "disk_percent": psutil.disk_usage('/').percent,
                "network_io": psutil.net_io_counters()._asdict(),
                "process_count": len(psutil.pids()),
                "load_average": psutil.getloadavg() if hasattr(psutil, 'getloadavg') else None
            }
        except Exception as e:
            logger.error(f"系统指标收集失败: {e}")
    
    def _record_performance_metrics(self):
        """记录性能指标"""
        for metric_name, values in self.metrics.items():
            if values:
                avg_value = sum(values) / len(values)
                max_value = max(values)
                min_value = min(values)
                
                logger.info(f"性能指标 {metric_name}: 平均={avg_value:.3f}s, 最大={max_value:.3f}s, 最小={min_value:.3f}s")
    
    def start_operation(self, operation_name: str) -> str:
        """开始操作计时"""
        operation_id = str(uuid.uuid4())
        self.active_operations[operation_id] = time.time()
        return operation_id
    
    def end_operation(self, operation_id: str, operation_name: str) -> float:
        """结束操作计时"""
        if operation_id not in self.active_operations:
            return 0.0
        
        start_time = self.active_operations.pop(operation_id)
        duration = time.time() - start_time
        
        # 记录到指标
        self.metrics[operation_name].append(duration)
        
        return duration
    
    def get_performance_summary(self) -> Dict[str, Any]:
        """获取性能摘要"""
        summary = {
            "system_metrics": self.system_metrics,
            "operation_metrics": {},
            "active_operations": len(self.active_operations)
        }
        
        for operation_name, values in self.metrics.items():
            if values:
                summary["operation_metrics"][operation_name] = {
                    "count": len(values),
                    "average_duration": sum(values) / len(values),
                    "max_duration": max(values),
                    "min_duration": min(values),
                    "last_duration": values[-1]
                }
        
        return summary

class EnhancedErrorHandler:
    """增强的错误处理器"""
    
    def __init__(self):
        self.tracing = DistributedTracing()
        self.structured_logger = StructuredLogger()
        self.performance_monitor = PerformanceMonitor()
        self.error_handlers: List[Callable] = []
        self.alert_thresholds = {
            ErrorSeverity.CRITICAL: 1,
            ErrorSeverity.HIGH: 5,
            ErrorSeverity.MEDIUM: 10,
            ErrorSeverity.LOW: 20
        }
        self.error_counts: Dict[str, int] = defaultdict(int)
        self.last_alert_time: Dict[str, float] = {}
    
    def register_error_handler(self, handler: Callable):
        """注册错误处理器"""
        self.error_handlers.append(handler)
    
    def handle_error(
        self,
        error: Exception,
        severity: ErrorSeverity = ErrorSeverity.MEDIUM,
        category: ErrorCategory = ErrorCategory.SYSTEM,
        context: Optional[ErrorContext] = None,
        correlation_id: Optional[str] = None,
        additional_data: Optional[Dict[str, Any]] = None
    ) -> str:
        """处理错误"""
        
        # 生成错误ID
        error_id = str(uuid.uuid4())
        
        # 创建错误上下文
        if context is None:
            context = ErrorContext()
        
        # 创建错误事件
        error_event = ErrorEvent(
            id=error_id,
            error_type=type(error).__name__,
            message=str(error),
            severity=severity,
            category=category,
            context=context,
            stack_trace=traceback.format_exc(),
            additional_data=additional_data
        )
        
        # 添加到追踪
        if correlation_id:
            self.tracing.add_error_to_trace(correlation_id, error_event)
        
        # 记录结构化日志
        self.structured_logger.log_error(error_event)
        
        # 更新错误计数
        error_key = f"{error_event.error_type}:{error_event.message}"
        self.error_counts[error_key] += 1
        
        # 检查告警阈值
        self._check_alert_thresholds(error_event)
        
        # 调用注册的错误处理器
        for handler in self.error_handlers:
            try:
                handler(error_event)
            except Exception as e:
                logger.error(f"错误处理器执行失败: {e}")
        
        return error_id
    
    def _check_alert_thresholds(self, error_event: ErrorEvent):
        """检查告警阈值"""
        error_key = f"{error_event.error_type}:{error_event.message}"
        current_time = time.time()
        
        # 检查是否需要发送告警
        threshold = self.alert_thresholds.get(error_event.severity, 0)
        count = self.error_counts[error_key]
        
        if count >= threshold:
            # 防止重复告警（5分钟内）
            last_alert = self.last_alert_time.get(error_key, 0)
            if current_time - last_alert > 300:  # 5分钟
                self._send_alert(error_event, count)
                self.last_alert_time[error_key] = current_time
    
    def _send_alert(self, error_event: ErrorEvent, count: int):
        """发送告警"""
        alert_data = {
            "type": "error_alert",
            "error_id": error_event.id,
            "error_type": error_event.error_type,
            "message": error_event.message,
            "severity": error_event.severity.value,
            "category": error_event.category.value,
            "count": count,
            "timestamp": error_event.created_at.isoformat()
        }
        
        logger.warning(f"错误告警: {json.dumps(alert_data, ensure_ascii=False)}")
    
    def get_error_statistics(self) -> Dict[str, Any]:
        """获取错误统计"""
        return {
            "total_errors": sum(self.error_counts.values()),
            "error_counts": dict(self.error_counts),
            "alert_thresholds": {k.value: v for k, v in self.alert_thresholds.items()},
            "performance_summary": self.performance_monitor.get_performance_summary()
        }
    
    def start_monitoring(self):
        """启动监控"""
        self.performance_monitor.start_monitoring()
    
    def stop_monitoring(self):
        """停止监控"""
        self.performance_monitor.stop_monitoring()

# 装饰器
def error_handler(
    severity: ErrorSeverity = ErrorSeverity.MEDIUM,
    category: ErrorCategory = ErrorCategory.SYSTEM,
    track_performance: bool = True
):
    """错误处理装饰器"""
    def decorator(func):
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            error_handler_instance = EnhancedErrorHandler()
            operation_id = None
            
            if track_performance:
                operation_id = error_handler_instance.performance_monitor.start_operation(func.__name__)
            
            try:
                result = await func(*args, **kwargs)
                return result
            except Exception as e:
                # 处理错误
                error_id = error_handler_instance.handle_error(
                    e, severity, category
                )
                raise
            finally:
                if track_performance and operation_id:
                    duration = error_handler_instance.performance_monitor.end_operation(
                        operation_id, func.__name__
                    )
                    error_handler_instance.structured_logger.log_performance(
                        func.__name__, duration
                    )
        
        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            error_handler_instance = EnhancedErrorHandler()
            operation_id = None
            
            if track_performance:
                operation_id = error_handler_instance.performance_monitor.start_operation(func.__name__)
            
            try:
                result = func(*args, **kwargs)
                return result
            except Exception as e:
                # 处理错误
                error_id = error_handler_instance.handle_error(
                    e, severity, category
                )
                raise
            finally:
                if track_performance and operation_id:
                    duration = error_handler_instance.performance_monitor.end_operation(
                        operation_id, func.__name__
                    )
                    error_handler_instance.structured_logger.log_performance(
                        func.__name__, duration
                    )
        
        return async_wrapper if asyncio.iscoroutinefunction(func) else sync_wrapper
    
    return decorator

# 使用示例
@error_handler(severity=ErrorSeverity.HIGH, category=ErrorCategory.DATABASE)
async def example_async_function():
    """示例异步函数"""
    # 模拟数据库操作
    await asyncio.sleep(0.1)
    if time.time() % 2 < 0.5:  # 50%概率出错
        raise ValueError("模拟数据库错误")
    return "success"

@error_handler(severity=ErrorSeverity.MEDIUM, category=ErrorCategory.VALIDATION)
def example_sync_function():
    """示例同步函数"""
    # 模拟验证操作
    if time.time() % 3 < 1:  # 33%概率出错
        raise ValueError("模拟验证错误")
    return "success"

if __name__ == "__main__":
    # 创建错误处理器
    error_handler_instance = EnhancedErrorHandler()
    
    # 启动监控
    error_handler_instance.start_monitoring()
    
    # 测试异步函数
    async def test_async():
        for i in range(5):
            try:
                result = await example_async_function()
                print(f"异步函数结果: {result}")
            except Exception as e:
                print(f"异步函数错误: {e}")
    
    # 测试同步函数
    def test_sync():
        for i in range(5):
            try:
                result = example_sync_function()
                print(f"同步函数结果: {result}")
            except Exception as e:
                print(f"同步函数错误: {e}")
    
    # 运行测试
    asyncio.run(test_async())
    test_sync()
    
    # 获取统计信息
    stats = error_handler_instance.get_error_statistics()
    print(f"错误统计: {json.dumps(stats, indent=2, ensure_ascii=False)}")
    
    # 停止监控
    error_handler_instance.stop_monitoring()
