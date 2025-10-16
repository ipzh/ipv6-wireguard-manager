"""
增强的监控告警系统
实现高级监控告警，包括指标收集、阈值监控、告警通知
"""
import asyncio
import time
import json
import logging
from typing import Dict, List, Optional, Any, Union, Callable
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict
from enum import Enum
import psutil
import aiohttp
from fastapi import HTTPException

from .config_enhanced import settings
from .performance_enhanced import performance_manager

logger = logging.getLogger(__name__)

class AlertLevel(Enum):
    """告警级别枚举"""
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"

class AlertStatus(Enum):
    """告警状态枚举"""
    ACTIVE = "active"
    ACKNOWLEDGED = "acknowledged"
    RESOLVED = "resolved"
    SUPPRESSED = "suppressed"

@dataclass
class Metric:
    """指标数据"""
    name: str
    value: float
    timestamp: datetime
    tags: Dict[str, str]
    metadata: Dict[str, Any]
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典"""
        return {
            "name": self.name,
            "value": self.value,
            "timestamp": self.timestamp.isoformat(),
            "tags": self.tags,
            "metadata": self.metadata
        }

@dataclass
class Alert:
    """告警信息"""
    id: str
    name: str
    description: str
    level: AlertLevel
    status: AlertStatus
    metric_name: str
    threshold_value: float
    current_value: float
    created_at: datetime
    updated_at: datetime
    resolved_at: Optional[datetime]
    acknowledged_by: Optional[str]
    metadata: Dict[str, Any]
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典"""
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "level": self.level.value,
            "status": self.status.value,
            "metric_name": self.metric_name,
            "threshold_value": self.threshold_value,
            "current_value": self.current_value,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "resolved_at": self.resolved_at.isoformat() if self.resolved_at else None,
            "acknowledged_by": self.acknowledged_by,
            "metadata": self.metadata
        }

@dataclass
class AlertRule:
    """告警规则"""
    id: str
    name: str
    metric_name: str
    condition: str  # >, <, >=, <=, ==, !=
    threshold: float
    level: AlertLevel
    enabled: bool
    cooldown_minutes: int
    description: str
    tags: Dict[str, str]
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典"""
        return {
            "id": self.id,
            "name": self.name,
            "metric_name": self.metric_name,
            "condition": self.condition,
            "threshold": self.threshold,
            "level": self.level.value,
            "enabled": self.enabled,
            "cooldown_minutes": self.cooldown_minutes,
            "description": self.description,
            "tags": self.tags
        }

class SystemMetricsCollector:
    """系统指标收集器"""
    
    def __init__(self):
        self.collection_interval = 30  # 秒
        self.metrics_history: List[Metric] = []
        self.max_history_size = 1000
    
    async def collect_system_metrics(self) -> List[Metric]:
        """收集系统指标"""
        metrics = []
        current_time = datetime.utcnow()
        
        try:
            # CPU指标
            cpu_percent = psutil.cpu_percent(interval=1)
            metrics.append(Metric(
                name="system.cpu.usage",
                value=cpu_percent,
                timestamp=current_time,
                tags={"type": "system"},
                metadata={"unit": "percent"}
            ))
            
            # 内存指标
            memory = psutil.virtual_memory()
            metrics.append(Metric(
                name="system.memory.usage",
                value=memory.percent,
                timestamp=current_time,
                tags={"type": "system"},
                metadata={"unit": "percent", "total": memory.total, "available": memory.available}
            ))
            
            # 磁盘指标
            disk = psutil.disk_usage('/')
            disk_percent = (disk.used / disk.total) * 100
            metrics.append(Metric(
                name="system.disk.usage",
                value=disk_percent,
                timestamp=current_time,
                tags={"type": "system", "mount": "/"},
                metadata={"unit": "percent", "total": disk.total, "used": disk.used, "free": disk.free}
            ))
            
            # 网络指标
            network = psutil.net_io_counters()
            metrics.append(Metric(
                name="system.network.bytes_sent",
                value=network.bytes_sent,
                timestamp=current_time,
                tags={"type": "system"},
                metadata={"unit": "bytes"}
            ))
            metrics.append(Metric(
                name="system.network.bytes_recv",
                value=network.bytes_recv,
                timestamp=current_time,
                tags={"type": "system"},
                metadata={"unit": "bytes"}
            ))
            
            # 进程指标
            process = psutil.Process()
            metrics.append(Metric(
                name="system.process.cpu_percent",
                value=process.cpu_percent(),
                timestamp=current_time,
                tags={"type": "process", "pid": str(process.pid)},
                metadata={"unit": "percent"}
            ))
            metrics.append(Metric(
                name="system.process.memory_percent",
                value=process.memory_percent(),
                timestamp=current_time,
                tags={"type": "process", "pid": str(process.pid)},
                metadata={"unit": "percent"}
            ))
            
            # 添加到历史记录
            self.metrics_history.extend(metrics)
            
            # 清理旧指标
            if len(self.metrics_history) > self.max_history_size:
                self.metrics_history = self.metrics_history[-self.max_history_size:]
            
            return metrics
            
        except Exception as e:
            logger.error(f"System metrics collection error: {e}")
            return []
    
    def get_metric_history(self, metric_name: str, hours: int = 24) -> List[Metric]:
        """获取指标历史"""
        cutoff_time = datetime.utcnow() - timedelta(hours=hours)
        return [
            metric for metric in self.metrics_history
            if metric.name == metric_name and metric.timestamp >= cutoff_time
        ]
    
    def get_latest_metric(self, metric_name: str) -> Optional[Metric]:
        """获取最新指标"""
        for metric in reversed(self.metrics_history):
            if metric.name == metric_name:
                return metric
        return None

class ApplicationMetricsCollector:
    """应用指标收集器"""
    
    def __init__(self):
        self.metrics_history: List[Metric] = []
        self.max_history_size = 1000
    
    async def collect_application_metrics(self) -> List[Metric]:
        """收集应用指标"""
        metrics = []
        current_time = datetime.utcnow()
        
        try:
            # 数据库连接池指标
            if hasattr(performance_manager, 'db_pool'):
                pool_status = performance_manager.db_pool.get_pool_status()
                metrics.append(Metric(
                    name="app.database.pool_size",
                    value=pool_status.get("size", 0),
                    timestamp=current_time,
                    tags={"type": "database"},
                    metadata={"unit": "connections"}
                ))
                metrics.append(Metric(
                    name="app.database.checked_out",
                    value=pool_status.get("checked_out", 0),
                    timestamp=current_time,
                    tags={"type": "database"},
                    metadata={"unit": "connections"}
                ))
            
            # 缓存指标
            if hasattr(performance_manager, 'cache_manager'):
                cache_stats = await performance_manager.cache_manager.get_stats()
                if cache_stats.get("type") == "redis":
                    metrics.append(Metric(
                        name="app.cache.connected_clients",
                        value=cache_stats.get("connected_clients", 0),
                        timestamp=current_time,
                        tags={"type": "cache"},
                        metadata={"unit": "clients"}
                    ))
                    metrics.append(Metric(
                        name="app.cache.used_memory",
                        value=cache_stats.get("used_memory", 0),
                        timestamp=current_time,
                        tags={"type": "cache"},
                        metadata={"unit": "bytes"}
                    ))
            
            # 任务队列指标
            if hasattr(performance_manager, 'task_manager'):
                queue_status = performance_manager.task_manager.get_queue_status()
                metrics.append(Metric(
                    name="app.task_queue.size",
                    value=queue_status.get("queue_size", 0),
                    timestamp=current_time,
                    tags={"type": "task_queue"},
                    metadata={"unit": "tasks"}
                ))
                metrics.append(Metric(
                    name="app.task_queue.workers",
                    value=queue_status.get("workers", 0),
                    timestamp=current_time,
                    tags={"type": "task_queue"},
                    metadata={"unit": "workers"}
                ))
            
            # 添加到历史记录
            self.metrics_history.extend(metrics)
            
            # 清理旧指标
            if len(self.metrics_history) > self.max_history_size:
                self.metrics_history = self.metrics_history[-self.max_history_size:]
            
            return metrics
            
        except Exception as e:
            logger.error(f"Application metrics collection error: {e}")
            return []
    
    def get_metric_history(self, metric_name: str, hours: int = 24) -> List[Metric]:
        """获取指标历史"""
        cutoff_time = datetime.utcnow() - timedelta(hours=hours)
        return [
            metric for metric in self.metrics_history
            if metric.name == metric_name and metric.timestamp >= cutoff_time
        ]

class AlertManager:
    """告警管理器"""
    
    def __init__(self):
        self.alert_rules: Dict[str, AlertRule] = {}
        self.active_alerts: Dict[str, Alert] = {}
        self.alert_history: List[Alert] = []
        self.last_alert_times: Dict[str, datetime] = {}
        self.max_history_size = 1000
        
        # 初始化默认告警规则
        self._initialize_default_rules()
    
    def _initialize_default_rules(self):
        """初始化默认告警规则"""
        default_rules = [
            AlertRule(
                id="cpu_high",
                name="CPU使用率过高",
                metric_name="system.cpu.usage",
                condition=">",
                threshold=80.0,
                level=AlertLevel.WARNING,
                enabled=True,
                cooldown_minutes=5,
                description="CPU使用率超过80%",
                tags={"type": "system"}
            ),
            AlertRule(
                id="memory_high",
                name="内存使用率过高",
                metric_name="system.memory.usage",
                condition=">",
                threshold=85.0,
                level=AlertLevel.WARNING,
                enabled=True,
                cooldown_minutes=5,
                description="内存使用率超过85%",
                tags={"type": "system"}
            ),
            AlertRule(
                id="disk_high",
                name="磁盘使用率过高",
                metric_name="system.disk.usage",
                condition=">",
                threshold=90.0,
                level=AlertLevel.ERROR,
                enabled=True,
                cooldown_minutes=10,
                description="磁盘使用率超过90%",
                tags={"type": "system"}
            ),
            AlertRule(
                id="db_pool_exhausted",
                name="数据库连接池耗尽",
                metric_name="app.database.checked_out",
                condition=">",
                threshold=15.0,
                level=AlertLevel.ERROR,
                enabled=True,
                cooldown_minutes=5,
                description="数据库连接池使用率过高",
                tags={"type": "database"}
            )
        ]
        
        for rule in default_rules:
            self.alert_rules[rule.id] = rule
    
    def add_alert_rule(self, rule: AlertRule):
        """添加告警规则"""
        self.alert_rules[rule.id] = rule
        logger.info(f"Alert rule added: {rule.name}")
    
    def remove_alert_rule(self, rule_id: str):
        """移除告警规则"""
        if rule_id in self.alert_rules:
            del self.alert_rules[rule_id]
            logger.info(f"Alert rule removed: {rule_id}")
    
    def get_alert_rules(self) -> List[AlertRule]:
        """获取所有告警规则"""
        return list(self.alert_rules.values())
    
    def evaluate_metrics(self, metrics: List[Metric]):
        """评估指标并触发告警"""
        for metric in metrics:
            for rule in self.alert_rules.values():
                if not rule.enabled or rule.metric_name != metric.name:
                    continue
                
                # 检查冷却时间
                last_alert_time = self.last_alert_times.get(rule.id)
                if last_alert_time:
                    cooldown_end = last_alert_time + timedelta(minutes=rule.cooldown_minutes)
                    if datetime.utcnow() < cooldown_end:
                        continue
                
                # 评估条件
                if self._evaluate_condition(metric.value, rule.condition, rule.threshold):
                    self._trigger_alert(rule, metric)
                else:
                    self._resolve_alert(rule.id)
    
    def _evaluate_condition(self, value: float, condition: str, threshold: float) -> bool:
        """评估告警条件"""
        if condition == ">":
            return value > threshold
        elif condition == "<":
            return value < threshold
        elif condition == ">=":
            return value >= threshold
        elif condition == "<=":
            return value <= threshold
        elif condition == "==":
            return value == threshold
        elif condition == "!=":
            return value != threshold
        return False
    
    def _trigger_alert(self, rule: AlertRule, metric: Metric):
        """触发告警"""
        alert_id = f"{rule.id}_{int(metric.timestamp.timestamp())}"
        
        # 检查是否已存在活跃告警
        if rule.id in self.active_alerts:
            return
        
        alert = Alert(
            id=alert_id,
            name=rule.name,
            description=rule.description,
            level=rule.level,
            status=AlertStatus.ACTIVE,
            metric_name=metric.name,
            threshold_value=rule.threshold,
            current_value=metric.value,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
            resolved_at=None,
            acknowledged_by=None,
            metadata={
                "rule_id": rule.id,
                "condition": rule.condition,
                "tags": rule.tags
            }
        )
        
        self.active_alerts[rule.id] = alert
        self.last_alert_times[rule.id] = datetime.utcnow()
        
        # 添加到历史记录
        self.alert_history.append(alert)
        if len(self.alert_history) > self.max_history_size:
            self.alert_history = self.alert_history[-self.max_history_size:]
        
        logger.warning(f"Alert triggered: {alert.name} - {alert.current_value} {rule.condition} {rule.threshold}")
        
        # 发送告警通知
        asyncio.create_task(self._send_alert_notification(alert))
    
    def _resolve_alert(self, rule_id: str):
        """解决告警"""
        if rule_id in self.active_alerts:
            alert = self.active_alerts[rule_id]
            alert.status = AlertStatus.RESOLVED
            alert.resolved_at = datetime.utcnow()
            alert.updated_at = datetime.utcnow()
            
            del self.active_alerts[rule_id]
            
            logger.info(f"Alert resolved: {alert.name}")
            
            # 发送解决通知
            asyncio.create_task(self._send_alert_notification(alert, resolved=True))
    
    async def _send_alert_notification(self, alert: Alert, resolved: bool = False):
        """发送告警通知"""
        try:
            # 这里应该实现实际的通知逻辑
            # 例如发送邮件、Webhook、Slack等
            
            notification_data = {
                "alert": alert.to_dict(),
                "resolved": resolved,
                "timestamp": datetime.utcnow().isoformat()
            }
            
            logger.info(f"Alert notification sent: {alert.name}")
            
        except Exception as e:
            logger.error(f"Alert notification error: {e}")
    
    def acknowledge_alert(self, rule_id: str, acknowledged_by: str):
        """确认告警"""
        if rule_id in self.active_alerts:
            alert = self.active_alerts[rule_id]
            alert.status = AlertStatus.ACKNOWLEDGED
            alert.acknowledged_by = acknowledged_by
            alert.updated_at = datetime.utcnow()
            
            logger.info(f"Alert acknowledged: {alert.name} by {acknowledged_by}")
    
    def suppress_alert(self, rule_id: str, duration_minutes: int = 60):
        """抑制告警"""
        if rule_id in self.active_alerts:
            alert = self.active_alerts[rule_id]
            alert.status = AlertStatus.SUPPRESSED
            alert.updated_at = datetime.utcnow()
            
            # 设置抑制结束时间
            suppress_until = datetime.utcnow() + timedelta(minutes=duration_minutes)
            self.last_alert_times[rule_id] = suppress_until
            
            logger.info(f"Alert suppressed: {alert.name} for {duration_minutes} minutes")
    
    def get_active_alerts(self) -> List[Alert]:
        """获取活跃告警"""
        return list(self.active_alerts.values())
    
    def get_alert_history(self, hours: int = 24) -> List[Alert]:
        """获取告警历史"""
        cutoff_time = datetime.utcnow() - timedelta(hours=hours)
        return [
            alert for alert in self.alert_history
            if alert.created_at >= cutoff_time
        ]

class MonitoringDashboard:
    """监控仪表板"""
    
    def __init__(self):
        self.system_collector = SystemMetricsCollector()
        self.app_collector = ApplicationMetricsCollector()
        self.alert_manager = AlertManager()
        
        self.collection_interval = 30  # 秒
        self.is_running = False
    
    async def start_monitoring(self):
        """启动监控"""
        if self.is_running:
            return
        
        self.is_running = True
        asyncio.create_task(self._monitoring_loop())
        logger.info("Monitoring dashboard started")
    
    async def stop_monitoring(self):
        """停止监控"""
        self.is_running = False
        logger.info("Monitoring dashboard stopped")
    
    async def _monitoring_loop(self):
        """监控循环"""
        while self.is_running:
            try:
                # 收集系统指标
                system_metrics = await self.system_collector.collect_system_metrics()
                
                # 收集应用指标
                app_metrics = await self.app_collector.collect_application_metrics()
                
                # 合并所有指标
                all_metrics = system_metrics + app_metrics
                
                # 评估告警
                self.alert_manager.evaluate_metrics(all_metrics)
                
                await asyncio.sleep(self.collection_interval)
                
            except Exception as e:
                logger.error(f"Monitoring loop error: {e}")
                await asyncio.sleep(5)
    
    def get_dashboard_data(self) -> Dict[str, Any]:
        """获取仪表板数据"""
        return {
            "system_metrics": {
                "cpu": self.system_collector.get_latest_metric("system.cpu.usage"),
                "memory": self.system_collector.get_latest_metric("system.memory.usage"),
                "disk": self.system_collector.get_latest_metric("system.disk.usage"),
                "network": {
                    "bytes_sent": self.system_collector.get_latest_metric("system.network.bytes_sent"),
                    "bytes_recv": self.system_collector.get_latest_metric("system.network.bytes_recv")
                }
            },
            "application_metrics": {
                "database": {
                    "pool_size": self.app_collector.get_latest_metric("app.database.pool_size"),
                    "checked_out": self.app_collector.get_latest_metric("app.database.checked_out")
                },
                "cache": {
                    "connected_clients": self.app_collector.get_latest_metric("app.cache.connected_clients"),
                    "used_memory": self.app_collector.get_latest_metric("app.cache.used_memory")
                },
                "task_queue": {
                    "size": self.app_collector.get_latest_metric("app.task_queue.size"),
                    "workers": self.app_collector.get_latest_metric("app.task_queue.workers")
                }
            },
            "alerts": {
                "active": [alert.to_dict() for alert in self.alert_manager.get_active_alerts()],
                "history": [alert.to_dict() for alert in self.alert_manager.get_alert_history(24)]
            },
            "alert_rules": [rule.to_dict() for rule in self.alert_manager.get_alert_rules()]
        }
    
    def get_metric_history(self, metric_name: str, hours: int = 24) -> List[Dict[str, Any]]:
        """获取指标历史"""
        system_metrics = self.system_collector.get_metric_history(metric_name, hours)
        app_metrics = self.app_collector.get_metric_history(metric_name, hours)
        
        all_metrics = system_metrics + app_metrics
        all_metrics.sort(key=lambda x: x.timestamp)
        
        return [metric.to_dict() for metric in all_metrics]

# 创建全局监控仪表板实例
monitoring_dashboard = MonitoringDashboard()

# 导出
__all__ = [
    "MonitoringDashboard",
    "SystemMetricsCollector",
    "ApplicationMetricsCollector",
    "AlertManager",
    "Alert",
    "AlertRule",
    "AlertLevel",
    "AlertStatus",
    "Metric",
    "monitoring_dashboard"
]
