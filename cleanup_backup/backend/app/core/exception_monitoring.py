"""
异常监控系统
收集、分析和报告异常，支持告警机制
"""

import logging
import json
from typing import Dict, Any, List, Optional, Callable
from datetime import datetime, timedelta
from collections import defaultdict, deque
import threading
import time
from dataclasses import dataclass, field
from enum import Enum
import asyncio

logger = logging.getLogger(__name__)

class AlertSeverity(str, Enum):
    """告警严重程度"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class AlertStatus(str, Enum):
    """告警状态"""
    ACTIVE = "active"
    ACKNOWLEDGED = "acknowledged"
    RESOLVED = "resolved"

@dataclass
class ExceptionRecord:
    """异常记录"""
    error_code: str
    message: str
    stack_trace: str
    context: Dict[str, Any] = field(default_factory=dict)
    timestamp: datetime = field(default_factory=datetime.utcnow)
    count: int = 1
    first_seen: datetime = field(default_factory=datetime.utcnow)
    last_seen: datetime = field(default_factory=datetime.utcnow)

@dataclass
class Alert:
    """告警"""
    id: str
    title: str
    description: str
    severity: AlertSeverity
    status: AlertStatus = AlertStatus.ACTIVE
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)
    acknowledged_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

class ExceptionAggregator:
    """异常聚合器"""
    
    def __init__(self, window_size_minutes: int = 60):
        self.window_size_minutes = window_size_minutes
        self.exceptions: Dict[str, ExceptionRecord] = {}
        self.recent_exceptions: deque = deque(maxlen=1000)
        self.lock = threading.Lock()
    
    def add_exception(
        self,
        error_code: str,
        message: str,
        stack_trace: str,
        context: Dict[str, Any] = None
    ) -> ExceptionRecord:
        """添加异常记录"""
        with self.lock:
            key = f"{error_code}:{message}"
            now = datetime.utcnow()
            
            if key in self.exceptions:
                # 更新现有异常记录
                record = self.exceptions[key]
                record.count += 1
                record.last_seen = now
                record.context.update(context or {})
            else:
                # 创建新异常记录
                record = ExceptionRecord(
                    error_code=error_code,
                    message=message,
                    stack_trace=stack_trace,
                    context=context or {},
                    timestamp=now,
                    first_seen=now,
                    last_seen=now
                )
                self.exceptions[key] = record
            
            # 添加到最近异常列表
            self.recent_exceptions.append(record)
            
            return record
    
    def get_exception_summary(self) -> Dict[str, Any]:
        """获取异常摘要"""
        with self.lock:
            total_exceptions = sum(record.count for record in self.exceptions.values())
            unique_exceptions = len(self.exceptions)
            
            # 按错误码分组统计
            error_code_counts = defaultdict(int)
            for record in self.exceptions.values():
                error_code_counts[record.error_code] += record.count
            
            # 最近一小时异常
            one_hour_ago = datetime.utcnow() - timedelta(hours=1)
            recent_hour_count = sum(
                record.count for record in self.exceptions.values()
                if record.last_seen >= one_hour_ago
            )
            
            # 最近一天异常
            one_day_ago = datetime.utcnow() - timedelta(days=1)
            recent_day_count = sum(
                record.count for record in self.exceptions.values()
                if record.last_seen >= one_day_ago
            )
            
            return {
                "total_exceptions": total_exceptions,
                "unique_exceptions": unique_exceptions,
                "recent_hour_count": recent_hour_count,
                "recent_day_count": recent_day_count,
                "error_code_counts": dict(error_code_counts),
                "last_updated": datetime.utcnow().isoformat()
            }
    
    def get_top_exceptions(self, limit: int = 10) -> List[ExceptionRecord]:
        """获取最频繁的异常"""
        with self.lock:
            return sorted(
                self.exceptions.values(),
                key=lambda x: x.count,
                reverse=True
            )[:limit]
    
    def get_recent_exceptions(self, limit: int = 50) -> List[ExceptionRecord]:
        """获取最近的异常"""
        with self.lock:
            return list(self.recent_exceptions)[-limit:]
    
    def cleanup_old_exceptions(self, days_to_keep: int = 7):
        """清理旧异常记录"""
        with self.lock:
            cutoff_time = datetime.utcnow() - timedelta(days=days_to_keep)
            
            # 清理异常字典
            keys_to_remove = [
                key for key, record in self.exceptions.items()
                if record.last_seen < cutoff_time
            ]
            
            for key in keys_to_remove:
                del self.exceptions[key]

class AlertManager:
    """告警管理器"""
    
    def __init__(self):
        self.alerts: Dict[str, Alert] = {}
        self.alert_rules: List[Dict[str, Any]] = []
        self.alert_handlers: List[Callable] = []
        self.lock = threading.Lock()
    
    def add_alert_rule(self, rule: Dict[str, Any]):
        """添加告警规则"""
        with self.lock:
            self.alert_rules.append(rule)
    
    def add_alert_handler(self, handler: Callable):
        """添加告警处理器"""
        with self.lock:
            self.alert_handlers.append(handler)
    
    def check_alerts(self, exception_aggregator: ExceptionAggregator):
        """检查是否需要触发告警"""
        with self.lock:
            summary = exception_aggregator.get_exception_summary()
            
            for rule in self.alert_rules:
                if self._evaluate_rule(rule, summary, exception_aggregator):
                    self._create_alert(rule, summary)
    
    def _evaluate_rule(
        self,
        rule: Dict[str, Any],
        summary: Dict[str, Any],
        exception_aggregator: ExceptionAggregator
    ) -> bool:
        """评估告警规则"""
        condition = rule.get("condition", {})
        
        # 检查总异常数
        if "total_exceptions" in condition:
            threshold = condition["total_exceptions"].get("threshold", 100)
            operator = condition["total_exceptions"].get("operator", ">")
            
            if operator == ">" and summary["total_exceptions"] <= threshold:
                return False
            elif operator == ">=" and summary["total_exceptions"] < threshold:
                return False
            elif operator == "<" and summary["total_exceptions"] >= threshold:
                return False
            elif operator == "<=" and summary["total_exceptions"] > threshold:
                return False
        
        # 检查特定错误码的异常数
        if "error_code" in condition:
            error_code = condition["error_code"].get("code")
            threshold = condition["error_code"].get("threshold", 10)
            operator = condition["error_code"].get("operator", ">")
            
            count = summary["error_code_counts"].get(error_code, 0)
            
            if operator == ">" and count <= threshold:
                return False
            elif operator == ">=" and count < threshold:
                return False
            elif operator == "<" and count >= threshold:
                return False
            elif operator == "<=" and count > threshold:
                return False
        
        # 检查最近一小时异常数
        if "recent_hour_count" in condition:
            threshold = condition["recent_hour_count"].get("threshold", 50)
            operator = condition["recent_hour_count"].get("operator", ">")
            
            if operator == ">" and summary["recent_hour_count"] <= threshold:
                return False
            elif operator == ">=" and summary["recent_hour_count"] < threshold:
                return False
            elif operator == "<" and summary["recent_hour_count"] >= threshold:
                return False
            elif operator == "<=" and summary["recent_hour_count"] > threshold:
                return False
        
        # 检查是否存在特定错误码
        if "has_error_code" in condition:
            error_codes = condition["has_error_code"]
            if not any(code in summary["error_code_counts"] for code in error_codes):
                return False
        
        return True
    
    def _create_alert(self, rule: Dict[str, Any], summary: Dict[str, Any]):
        """创建告警"""
        alert_id = f"alert_{int(time.time())}_{rule.get('name', 'unknown').replace(' ', '_')}"
        
        # 检查是否已存在相同的活跃告警
        if alert_id in self.alerts and self.alerts[alert_id].status == AlertStatus.ACTIVE:
            return
        
        # 创建新告警
        alert = Alert(
            id=alert_id,
            title=rule.get("title", "异常告警"),
            description=rule.get("description", "系统检测到异常情况"),
            severity=AlertSeverity(rule.get("severity", "medium")),
            metadata={
                "rule": rule,
                "summary": summary
            }
        )
        
        self.alerts[alert_id] = alert
        
        # 触发告警处理器
        for handler in self.alert_handlers:
            try:
                handler(alert)
            except Exception as e:
                logger.error(f"告警处理器执行失败: {e}", exc_info=True)
    
    def acknowledge_alert(self, alert_id: str) -> bool:
        """确认告警"""
        with self.lock:
            if alert_id in self.alerts:
                alert = self.alerts[alert_id]
                if alert.status == AlertStatus.ACTIVE:
                    alert.status = AlertStatus.ACKNOWLEDGED
                    alert.acknowledged_at = datetime.utcnow()
                    alert.updated_at = datetime.utcnow()
                    return True
        return False
    
    def resolve_alert(self, alert_id: str) -> bool:
        """解决告警"""
        with self.lock:
            if alert_id in self.alerts:
                alert = self.alerts[alert_id]
                if alert.status in [AlertStatus.ACTIVE, AlertStatus.ACKNOWLEDGED]:
                    alert.status = AlertStatus.RESOLVED
                    alert.resolved_at = datetime.utcnow()
                    alert.updated_at = datetime.utcnow()
                    return True
        return False
    
    def get_active_alerts(self) -> List[Alert]:
        """获取活跃告警"""
        with self.lock:
            return [
                alert for alert in self.alerts.values()
                if alert.status == AlertStatus.ACTIVE
            ]
    
    def get_all_alerts(self) -> List[Alert]:
        """获取所有告警"""
        with self.lock:
            return list(self.alerts.values())

class ExceptionMonitor:
    """异常监控器"""
    
    def __init__(self):
        self.aggregator = ExceptionAggregator()
        self.alert_manager = AlertManager()
        self.running = False
        self.monitor_thread = None
        self.check_interval = 60  # 检查间隔（秒）
        
        # 设置默认告警规则
        self._setup_default_alert_rules()
    
    def _setup_default_alert_rules(self):
        """设置默认告警规则"""
        # 高频率异常告警
        self.alert_manager.add_alert_rule({
            "name": "高频率异常",
            "title": "系统异常频率过高",
            "description": "系统在过去一小时内产生了大量异常",
            "severity": "high",
            "condition": {
                "recent_hour_count": {
                    "threshold": 100,
                    "operator": ">"
                }
            }
        })
        
        # 关键错误告警
        self.alert_manager.add_alert_rule({
            "name": "关键错误",
            "title": "系统出现关键错误",
            "description": "系统出现了关键错误，需要立即处理",
            "severity": "critical",
            "condition": {
                "has_error_code": [
                    "INTERNAL_SERVER_ERROR",
                    "DATABASE_ERROR",
                    "SYSTEM_ERROR"
                ]
            }
        })
        
        # 认证失败告警
        self.alert_manager.add_alert_rule({
            "name": "认证失败",
            "title": "认证失败次数过多",
            "description": "系统在过去一小时内出现了大量认证失败",
            "severity": "medium",
            "condition": {
                "error_code": {
                    "code": "INVALID_CREDENTIALS",
                    "threshold": 20,
                    "operator": ">"
                }
            }
        })
    
    def start(self):
        """启动异常监控"""
        if self.running:
            return
        
        self.running = True
        self.monitor_thread = threading.Thread(target=self._monitor_loop, daemon=True)
        self.monitor_thread.start()
        logger.info("异常监控已启动")
    
    def stop(self):
        """停止异常监控"""
        if not self.running:
            return
        
        self.running = False
        if self.monitor_thread:
            self.monitor_thread.join(timeout=5)
        logger.info("异常监控已停止")
    
    def _monitor_loop(self):
        """监控循环"""
        while self.running:
            try:
                # 检查告警
                self.alert_manager.check_alerts(self.aggregator)
                
                # 清理旧异常
                self.aggregator.cleanup_old_exceptions()
                
                # 等待下次检查
                time.sleep(self.check_interval)
            except Exception as e:
                logger.error(f"异常监控循环出错: {e}", exc_info=True)
    
    def record_exception(
        self,
        error_code: str,
        message: str,
        stack_trace: str,
        context: Dict[str, Any] = None
    ):
        """记录异常"""
        self.aggregator.add_exception(error_code, message, stack_trace, context)
    
    def get_exception_summary(self) -> Dict[str, Any]:
        """获取异常摘要"""
        return self.aggregator.get_exception_summary()
    
    def get_top_exceptions(self, limit: int = 10) -> List[ExceptionRecord]:
        """获取最频繁的异常"""
        return self.aggregator.get_top_exceptions(limit)
    
    def get_recent_exceptions(self, limit: int = 50) -> List[ExceptionRecord]:
        """获取最近的异常"""
        return self.aggregator.get_recent_exceptions(limit)
    
    def get_active_alerts(self) -> List[Alert]:
        """获取活跃告警"""
        return self.alert_manager.get_active_alerts()
    
    def acknowledge_alert(self, alert_id: str) -> bool:
        """确认告警"""
        return self.alert_manager.acknowledge_alert(alert_id)
    
    def resolve_alert(self, alert_id: str) -> bool:
        """解决告警"""
        return self.alert_manager.resolve_alert(alert_id)

# 创建全局异常监控器
exception_monitor = ExceptionMonitor()

# 导出主要组件
__all__ = [
    "AlertSeverity",
    "AlertStatus",
    "ExceptionRecord",
    "Alert",
    "ExceptionAggregator",
    "AlertManager",
    "ExceptionMonitor",
    "exception_monitor"
]
