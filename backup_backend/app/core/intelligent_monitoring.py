"""
智能监控和告警系统
提供智能监控、预测分析、自动告警等功能
"""
import asyncio
import logging
import statistics
import numpy as np
from typing import Dict, Any, List, Optional, Tuple, Callable
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
import json
import math

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import redis.asyncio as redis

logger = logging.getLogger(__name__)

class AlertLevel(Enum):
    """告警级别"""
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"

class MetricType(Enum):
    """指标类型"""
    COUNTER = "counter"
    GAUGE = "gauge"
    HISTOGRAM = "histogram"
    SUMMARY = "summary"

@dataclass
class Metric:
    """监控指标"""
    name: str
    value: float
    metric_type: MetricType
    labels: Dict[str, str] = field(default_factory=dict)
    timestamp: datetime = field(default_factory=datetime.now)
    description: str = ""

@dataclass
class AlertRule:
    """告警规则"""
    id: str
    name: str
    metric_name: str
    condition: str  # >, <, >=, <=, ==, !=
    threshold: float
    level: AlertLevel
    duration: int = 0  # 持续时间（秒）
    enabled: bool = True
    description: str = ""
    tags: Dict[str, str] = field(default_factory=dict)

@dataclass
class Alert:
    """告警"""
    id: str
    rule_id: str
    metric_name: str
    current_value: float
    threshold: float
    level: AlertLevel
    message: str
    timestamp: datetime
    resolved: bool = False
    resolved_at: Optional[datetime] = None
    labels: Dict[str, str] = field(default_factory=dict)

@dataclass
class PredictionResult:
    """预测结果"""
    metric_name: str
    current_value: float
    predicted_value: float
    confidence: float
    trend: str  # "increasing", "decreasing", "stable"
    time_horizon: int  # 预测时间范围（分钟）
    timestamp: datetime

class TimeSeriesAnalyzer:
    """时间序列分析器"""
    
    def __init__(self, window_size: int = 100):
        self.window_size = window_size
        self.data_points = {}
    
    def add_data_point(self, metric_name: str, value: float, timestamp: datetime):
        """添加数据点"""
        if metric_name not in self.data_points:
            self.data_points[metric_name] = []
        
        self.data_points[metric_name].append({
            'value': value,
            'timestamp': timestamp
        })
        
        # 保持窗口大小
        if len(self.data_points[metric_name]) > self.window_size:
            self.data_points[metric_name].pop(0)
    
    def get_trend(self, metric_name: str) -> str:
        """获取趋势"""
        if metric_name not in self.data_points or len(self.data_points[metric_name]) < 2:
            return "unknown"
        
        values = [point['value'] for point in self.data_points[metric_name]]
        
        # 计算线性回归斜率
        n = len(values)
        x = list(range(n))
        y = values
        
        # 计算斜率
        slope = self._calculate_slope(x, y)
        
        if slope > 0.1:
            return "increasing"
        elif slope < -0.1:
            return "decreasing"
        else:
            return "stable"
    
    def get_anomaly_score(self, metric_name: str, current_value: float) -> float:
        """获取异常分数"""
        if metric_name not in self.data_points or len(self.data_points[metric_name]) < 10:
            return 0.0
        
        values = [point['value'] for point in self.data_points[metric_name]]
        
        # 计算统计信息
        mean = statistics.mean(values)
        std = statistics.stdev(values) if len(values) > 1 else 0
        
        if std == 0:
            return 0.0
        
        # 计算Z分数
        z_score = abs(current_value - mean) / std
        
        # 转换为0-1的异常分数
        anomaly_score = min(1.0, z_score / 3.0)  # 3-sigma规则
        
        return anomaly_score
    
    def predict_next_value(self, metric_name: str, time_horizon: int = 60) -> PredictionResult:
        """预测下一个值"""
        if metric_name not in self.data_points or len(self.data_points[metric_name]) < 5:
            return PredictionResult(
                metric_name=metric_name,
                current_value=0.0,
                predicted_value=0.0,
                confidence=0.0,
                trend="unknown",
                time_horizon=time_horizon,
                timestamp=datetime.now()
            )
        
        values = [point['value'] for point in self.data_points[metric_name]]
        current_value = values[-1]
        
        # 简单的线性预测
        n = len(values)
        x = list(range(n))
        y = values
        
        # 计算线性回归
        slope, intercept = self._linear_regression(x, y)
        
        # 预测下一个值
        predicted_value = slope * n + intercept
        
        # 计算置信度（基于R²）
        confidence = self._calculate_r_squared(x, y, slope, intercept)
        
        # 获取趋势
        trend = self.get_trend(metric_name)
        
        return PredictionResult(
            metric_name=metric_name,
            current_value=current_value,
            predicted_value=predicted_value,
            confidence=confidence,
            trend=trend,
            time_horizon=time_horizon,
            timestamp=datetime.now()
        )
    
    def _calculate_slope(self, x: List[float], y: List[float]) -> float:
        """计算斜率"""
        n = len(x)
        sum_x = sum(x)
        sum_y = sum(y)
        sum_xy = sum(x[i] * y[i] for i in range(n))
        sum_x2 = sum(x[i] ** 2 for i in range(n))
        
        if n * sum_x2 - sum_x ** 2 == 0:
            return 0.0
        
        slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x ** 2)
        return slope
    
    def _linear_regression(self, x: List[float], y: List[float]) -> Tuple[float, float]:
        """线性回归"""
        n = len(x)
        sum_x = sum(x)
        sum_y = sum(y)
        sum_xy = sum(x[i] * y[i] for i in range(n))
        sum_x2 = sum(x[i] ** 2 for i in range(n))
        
        if n * sum_x2 - sum_x ** 2 == 0:
            return 0.0, sum_y / n
        
        slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x ** 2)
        intercept = (sum_y - slope * sum_x) / n
        
        return slope, intercept
    
    def _calculate_r_squared(self, x: List[float], y: List[float], slope: float, intercept: float) -> float:
        """计算R²"""
        n = len(x)
        y_mean = sum(y) / n
        
        # 计算预测值
        y_pred = [slope * x[i] + intercept for i in range(n)]
        
        # 计算R²
        ss_res = sum((y[i] - y_pred[i]) ** 2 for i in range(n))
        ss_tot = sum((y[i] - y_mean) ** 2 for i in range(n))
        
        if ss_tot == 0:
            return 0.0
        
        r_squared = 1 - (ss_res / ss_tot)
        return max(0.0, min(1.0, r_squared))

class AlertManager:
    """告警管理器"""
    
    def __init__(self, db_session: AsyncSession, redis_client: redis.Redis = None):
        self.db_session = db_session
        self.redis_client = redis_client
        self.alert_rules = {}
        self.active_alerts = {}
        self.alert_history = []
        self.notification_handlers = []
    
    async def add_alert_rule(self, rule: AlertRule):
        """添加告警规则"""
        self.alert_rules[rule.id] = rule
        
        # 保存到数据库
        await self._save_alert_rule(rule)
        
        logger.info(f"告警规则已添加: {rule.name}")
    
    async def remove_alert_rule(self, rule_id: str):
        """移除告警规则"""
        if rule_id in self.alert_rules:
            del self.alert_rules[rule_id]
            await self._delete_alert_rule(rule_id)
            logger.info(f"告警规则已移除: {rule_id}")
    
    async def evaluate_metric(self, metric: Metric):
        """评估指标"""
        for rule_id, rule in self.alert_rules.items():
            if not rule.enabled or rule.metric_name != metric.name:
                continue
            
            # 检查条件
            if self._evaluate_condition(metric.value, rule.condition, rule.threshold):
                # 触发告警
                await self._trigger_alert(rule, metric)
            else:
                # 如果之前有活跃告警，现在条件不满足，则解决告警
                if rule_id in self.active_alerts:
                    await self._resolve_alert(rule_id)
    
    def _evaluate_condition(self, value: float, condition: str, threshold: float) -> bool:
        """评估条件"""
        if condition == ">":
            return value > threshold
        elif condition == "<":
            return value < threshold
        elif condition == ">=":
            return value >= threshold
        elif condition == "<=":
            return value <= threshold
        elif condition == "==":
            return abs(value - threshold) < 0.001
        elif condition == "!=":
            return abs(value - threshold) >= 0.001
        else:
            return False
    
    async def _trigger_alert(self, rule: AlertRule, metric: Metric):
        """触发告警"""
        alert_id = f"{rule.id}_{int(datetime.now().timestamp())}"
        
        alert = Alert(
            id=alert_id,
            rule_id=rule.id,
            metric_name=metric.name,
            current_value=metric.value,
            threshold=rule.threshold,
            level=rule.level,
            message=f"{rule.name}: {metric.name} = {metric.value} {rule.condition} {rule.threshold}",
            timestamp=datetime.now(),
            labels=metric.labels
        )
        
        self.active_alerts[rule.id] = alert
        self.alert_history.append(alert)
        
        # 保存到数据库
        await self._save_alert(alert)
        
        # 发送通知
        await self._send_notifications(alert)
        
        logger.warning(f"告警触发: {alert.message}")
    
    async def _resolve_alert(self, rule_id: str):
        """解决告警"""
        if rule_id in self.active_alerts:
            alert = self.active_alerts[rule_id]
            alert.resolved = True
            alert.resolved_at = datetime.now()
            
            # 更新数据库
            await self._update_alert(alert)
            
            # 发送解决通知
            await self._send_resolution_notification(alert)
            
            del self.active_alerts[rule_id]
            logger.info(f"告警已解决: {alert.message}")
    
    async def _save_alert_rule(self, rule: AlertRule):
        """保存告警规则到数据库"""
        try:
            query = """
            INSERT INTO alert_rules 
            (id, name, metric_name, condition, threshold, level, duration, enabled, description, tags)
            VALUES (:id, :name, :metric_name, :condition, :threshold, :level, :duration, :enabled, :description, :tags)
            ON DUPLICATE KEY UPDATE
            name = VALUES(name),
            metric_name = VALUES(metric_name),
            condition = VALUES(condition),
            threshold = VALUES(threshold),
            level = VALUES(level),
            duration = VALUES(duration),
            enabled = VALUES(enabled),
            description = VALUES(description),
            tags = VALUES(tags)
            """
            await self.db_session.execute(text(query), {
                'id': rule.id,
                'name': rule.name,
                'metric_name': rule.metric_name,
                'condition': rule.condition,
                'threshold': rule.threshold,
                'level': rule.level.value,
                'duration': rule.duration,
                'enabled': rule.enabled,
                'description': rule.description,
                'tags': json.dumps(rule.tags)
            })
            await self.db_session.commit()
        except Exception as e:
            logger.error(f"保存告警规则失败: {e}")
    
    async def _delete_alert_rule(self, rule_id: str):
        """删除告警规则"""
        try:
            query = "DELETE FROM alert_rules WHERE id = :rule_id"
            await self.db_session.execute(text(query), {'rule_id': rule_id})
            await self.db_session.commit()
        except Exception as e:
            logger.error(f"删除告警规则失败: {e}")
    
    async def _save_alert(self, alert: Alert):
        """保存告警到数据库"""
        try:
            query = """
            INSERT INTO alerts 
            (id, rule_id, metric_name, current_value, threshold, level, message, timestamp, resolved, labels)
            VALUES (:id, :rule_id, :metric_name, :current_value, :threshold, :level, :message, :timestamp, :resolved, :labels)
            """
            await self.db_session.execute(text(query), {
                'id': alert.id,
                'rule_id': alert.rule_id,
                'metric_name': alert.metric_name,
                'current_value': alert.current_value,
                'threshold': alert.threshold,
                'level': alert.level.value,
                'message': alert.message,
                'timestamp': alert.timestamp,
                'resolved': alert.resolved,
                'labels': json.dumps(alert.labels)
            })
            await self.db_session.commit()
        except Exception as e:
            logger.error(f"保存告警失败: {e}")
    
    async def _update_alert(self, alert: Alert):
        """更新告警"""
        try:
            query = """
            UPDATE alerts 
            SET resolved = :resolved, resolved_at = :resolved_at
            WHERE id = :id
            """
            await self.db_session.execute(text(query), {
                'id': alert.id,
                'resolved': alert.resolved,
                'resolved_at': alert.resolved_at
            })
            await self.db_session.commit()
        except Exception as e:
            logger.error(f"更新告警失败: {e}")
    
    async def _send_notifications(self, alert: Alert):
        """发送通知"""
        for handler in self.notification_handlers:
            try:
                await handler(alert)
            except Exception as e:
                logger.error(f"发送通知失败: {e}")
    
    async def _send_resolution_notification(self, alert: Alert):
        """发送解决通知"""
        for handler in self.notification_handlers:
            try:
                await handler(alert, is_resolution=True)
            except Exception as e:
                logger.error(f"发送解决通知失败: {e}")
    
    def add_notification_handler(self, handler: Callable):
        """添加通知处理器"""
        self.notification_handlers.append(handler)
    
    async def get_active_alerts(self) -> List[Alert]:
        """获取活跃告警"""
        return list(self.active_alerts.values())
    
    async def get_alert_history(self, start_time: datetime = None, end_time: datetime = None) -> List[Alert]:
        """获取告警历史"""
        if start_time is None:
            start_time = datetime.now() - timedelta(days=7)
        if end_time is None:
            end_time = datetime.now()
        
        return [
            alert for alert in self.alert_history
            if start_time <= alert.timestamp <= end_time
        ]

class IntelligentMonitoring:
    """智能监控系统"""
    
    def __init__(self, db_session: AsyncSession, redis_client: redis.Redis = None):
        self.db_session = db_session
        self.redis_client = redis_client
        
        # 初始化组件
        self.time_series_analyzer = TimeSeriesAnalyzer()
        self.alert_manager = AlertManager(db_session, redis_client)
        
        # 监控配置
        self.config = {
            'enable_intelligent_monitoring': True,
            'enable_anomaly_detection': True,
            'enable_prediction': True,
            'enable_auto_scaling': False,
            'monitoring_interval': 30,  # 秒
            'prediction_horizon': 60,  # 分钟
            'anomaly_threshold': 0.8
        }
        
        # 监控状态
        self.metrics_buffer = {}
        self.prediction_cache = {}
        self.anomaly_scores = {}
    
    async def start(self):
        """启动智能监控"""
        if self.config['enable_intelligent_monitoring']:
            # 启动监控任务
            asyncio.create_task(self._monitoring_loop())
            logger.info("智能监控系统已启动")
    
    async def stop(self):
        """停止智能监控"""
        logger.info("智能监控系统已停止")
    
    async def _monitoring_loop(self):
        """监控循环"""
        while True:
            try:
                await self._collect_and_analyze_metrics()
                await asyncio.sleep(self.config['monitoring_interval'])
            except Exception as e:
                logger.error(f"监控循环错误: {e}")
                await asyncio.sleep(60)
    
    async def _collect_and_analyze_metrics(self):
        """收集和分析指标"""
        # 收集系统指标
        system_metrics = await self._collect_system_metrics()
        
        # 收集应用指标
        app_metrics = await self._collect_application_metrics()
        
        # 合并指标
        all_metrics = system_metrics + app_metrics
        
        # 分析每个指标
        for metric in all_metrics:
            await self._analyze_metric(metric)
    
    async def _collect_system_metrics(self) -> List[Metric]:
        """收集系统指标"""
        metrics = []
        
        try:
            import psutil
            
            # CPU使用率
            cpu_usage = psutil.cpu_percent(interval=1)
            metrics.append(Metric(
                name="system.cpu.usage",
                value=cpu_usage,
                metric_type=MetricType.GAUGE,
                labels={"type": "system"},
                description="CPU使用率"
            ))
            
            # 内存使用率
            memory = psutil.virtual_memory()
            metrics.append(Metric(
                name="system.memory.usage",
                value=memory.percent,
                metric_type=MetricType.GAUGE,
                labels={"type": "system"},
                description="内存使用率"
            ))
            
            # 磁盘使用率
            disk = psutil.disk_usage('/')
            disk_usage = (disk.used / disk.total) * 100
            metrics.append(Metric(
                name="system.disk.usage",
                value=disk_usage,
                metric_type=MetricType.GAUGE,
                labels={"type": "system", "mount": "/"},
                description="磁盘使用率"
            ))
            
            # 网络IO
            network = psutil.net_io_counters()
            metrics.append(Metric(
                name="system.network.bytes_sent",
                value=network.bytes_sent,
                metric_type=MetricType.COUNTER,
                labels={"type": "system", "direction": "sent"},
                description="网络发送字节数"
            ))
            
            metrics.append(Metric(
                name="system.network.bytes_recv",
                value=network.bytes_recv,
                metric_type=MetricType.COUNTER,
                labels={"type": "system", "direction": "recv"},
                description="网络接收字节数"
            ))
            
        except Exception as e:
            logger.error(f"收集系统指标失败: {e}")
        
        return metrics
    
    async def _collect_application_metrics(self) -> List[Metric]:
        """收集应用指标"""
        metrics = []
        
        try:
            # 数据库连接数
            db_connections = await self._get_database_connections()
            metrics.append(Metric(
                name="app.database.connections",
                value=db_connections,
                metric_type=MetricType.GAUGE,
                labels={"type": "application", "component": "database"},
                description="数据库连接数"
            ))
            
            # 缓存命中率
            cache_hit_rate = await self._get_cache_hit_rate()
            metrics.append(Metric(
                name="app.cache.hit_rate",
                value=cache_hit_rate,
                metric_type=MetricType.GAUGE,
                labels={"type": "application", "component": "cache"},
                description="缓存命中率"
            ))
            
            # API响应时间
            api_response_time = await self._get_api_response_time()
            metrics.append(Metric(
                name="app.api.response_time",
                value=api_response_time,
                metric_type=MetricType.HISTOGRAM,
                labels={"type": "application", "component": "api"},
                description="API响应时间"
            ))
            
        except Exception as e:
            logger.error(f"收集应用指标失败: {e}")
        
        return metrics
    
    async def _analyze_metric(self, metric: Metric):
        """分析指标"""
        # 添加到时间序列分析器
        self.time_series_analyzer.add_data_point(metric.name, metric.value, metric.timestamp)
        
        # 异常检测
        if self.config['enable_anomaly_detection']:
            anomaly_score = self.time_series_analyzer.get_anomaly_score(metric.name, metric.value)
            self.anomaly_scores[metric.name] = anomaly_score
            
            if anomaly_score > self.config['anomaly_threshold']:
                await self._handle_anomaly(metric, anomaly_score)
        
        # 预测分析
        if self.config['enable_prediction']:
            prediction = self.time_series_analyzer.predict_next_value(
                metric.name, 
                self.config['prediction_horizon']
            )
            self.prediction_cache[metric.name] = prediction
            
            # 检查预测是否触发告警
            await self._check_prediction_alerts(prediction)
        
        # 评估告警规则
        await self.alert_manager.evaluate_metric(metric)
    
    async def _handle_anomaly(self, metric: Metric, anomaly_score: float):
        """处理异常"""
        logger.warning(f"检测到异常: {metric.name} = {metric.value}, 异常分数: {anomaly_score:.2f}")
        
        # 创建异常告警
        alert = Alert(
            id=f"anomaly_{metric.name}_{int(datetime.now().timestamp())}",
            rule_id="anomaly_detection",
            metric_name=metric.name,
            current_value=metric.value,
            threshold=self.config['anomaly_threshold'],
            level=AlertLevel.WARNING,
            message=f"检测到异常: {metric.name} = {metric.value}, 异常分数: {anomaly_score:.2f}",
            timestamp=datetime.now(),
            labels=metric.labels
        )
        
        # 发送通知
        await self.alert_manager._send_notifications(alert)
    
    async def _check_prediction_alerts(self, prediction: PredictionResult):
        """检查预测告警"""
        # 如果预测值超过阈值，提前告警
        if prediction.confidence > 0.7:  # 高置信度
            if prediction.trend == "increasing" and prediction.predicted_value > 80:
                alert = Alert(
                    id=f"prediction_{prediction.metric_name}_{int(datetime.now().timestamp())}",
                    rule_id="prediction_alert",
                    metric_name=prediction.metric_name,
                    current_value=prediction.current_value,
                    threshold=80,
                    level=AlertLevel.INFO,
                    message=f"预测告警: {prediction.metric_name} 预计在{prediction.time_horizon}分钟内达到{prediction.predicted_value:.1f}",
                    timestamp=datetime.now()
                )
                await self.alert_manager._send_notifications(alert)
    
    async def _get_database_connections(self) -> int:
        """获取数据库连接数"""
        try:
            query = "SHOW STATUS LIKE 'Threads_connected'"
            result = await self.db_session.execute(text(query))
            row = result.fetchone()
            return int(row[1]) if row else 0
        except Exception as e:
            logger.error(f"获取数据库连接数失败: {e}")
            return 0
    
    async def _get_cache_hit_rate(self) -> float:
        """获取缓存命中率"""
        try:
            if self.redis_client:
                info = await self.redis_client.info('stats')
                hits = info.get('keyspace_hits', 0)
                misses = info.get('keyspace_misses', 0)
                total = hits + misses
                return (hits / total * 100) if total > 0 else 0
            return 0
        except Exception as e:
            logger.error(f"获取缓存命中率失败: {e}")
            return 0
    
    async def _get_api_response_time(self) -> float:
        """获取API响应时间"""
        # 这里应该从实际的API监控数据获取
        # 简化实现
        return 100.0  # 毫秒
    
    async def get_monitoring_summary(self) -> Dict[str, Any]:
        """获取监控摘要"""
        active_alerts = await self.alert_manager.get_active_alerts()
        
        return {
            'system_status': {
                'monitoring_enabled': self.config['enable_intelligent_monitoring'],
                'anomaly_detection_enabled': self.config['enable_anomaly_detection'],
                'prediction_enabled': self.config['enable_prediction'],
                'active_alerts': len(active_alerts),
                'monitored_metrics': len(self.time_series_analyzer.data_points)
            },
            'anomaly_scores': self.anomaly_scores,
            'predictions': {
                metric_name: {
                    'predicted_value': pred.predicted_value,
                    'confidence': pred.confidence,
                    'trend': pred.trend
                }
                for metric_name, pred in self.prediction_cache.items()
            },
            'alert_summary': {
                'total_alerts': len(active_alerts),
                'critical_alerts': len([a for a in active_alerts if a.level == AlertLevel.CRITICAL]),
                'error_alerts': len([a for a in active_alerts if a.level == AlertLevel.ERROR]),
                'warning_alerts': len([a for a in active_alerts if a.level == AlertLevel.WARNING]),
                'info_alerts': len([a for a in active_alerts if a.level == AlertLevel.INFO])
            }
        }

# 全局智能监控实例
intelligent_monitoring: Optional[IntelligentMonitoring] = None

async def get_intelligent_monitoring() -> IntelligentMonitoring:
    """获取智能监控实例"""
    global intelligent_monitoring
    if intelligent_monitoring is None:
        raise ValueError("智能监控系统未初始化")
    return intelligent_monitoring

async def init_intelligent_monitoring(db_session: AsyncSession, redis_client: redis.Redis = None):
    """初始化智能监控系统"""
    global intelligent_monitoring
    intelligent_monitoring = IntelligentMonitoring(db_session, redis_client)
    await intelligent_monitoring.start()
    logger.info("智能监控系统初始化完成")

async def shutdown_intelligent_monitoring():
    """关闭智能监控系统"""
    global intelligent_monitoring
    if intelligent_monitoring:
        await intelligent_monitoring.stop()
        intelligent_monitoring = None
    logger.info("智能监控系统已关闭")
