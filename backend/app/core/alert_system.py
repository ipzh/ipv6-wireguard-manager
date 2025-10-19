# 告警和通知系统

import asyncio
import smtplib
import json
import requests
from typing import Dict, List, Any, Optional, Callable
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
from enum import Enum
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import threading
from collections import defaultdict
import redis

class AlertSeverity(Enum):
    """告警严重程度"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class AlertStatus(Enum):
    """告警状态"""
    ACTIVE = "active"
    ACKNOWLEDGED = "acknowledged"
    RESOLVED = "resolved"
    SUPPRESSED = "suppressed"

class NotificationChannel(Enum):
    """通知渠道"""
    EMAIL = "email"
    SLACK = "slack"
    WEBHOOK = "webhook"
    SMS = "sms"
    DINGTALK = "dingtalk"
    TELEGRAM = "telegram"

@dataclass
class Alert:
    """告警"""
    id: str
    title: str
    description: str
    severity: AlertSeverity
    status: AlertStatus
    source: str
    timestamp: datetime
    resolved_at: Optional[datetime] = None
    acknowledged_by: Optional[str] = None
    acknowledged_at: Optional[datetime] = None
    metadata: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}

@dataclass
class AlertRule:
    """告警规则"""
    id: str
    name: str
    description: str
    condition: Dict[str, Any]
    severity: AlertSeverity
    enabled: bool = True
    cooldown: int = 300  # 冷却时间（秒）
    notification_channels: List[NotificationChannel] = None
    
    def __post_init__(self):
        if self.notification_channels is None:
            self.notification_channels = [NotificationChannel.EMAIL]

@dataclass
class NotificationConfig:
    """通知配置"""
    channel: NotificationChannel
    enabled: bool
    config: Dict[str, Any]

class AlertManager:
    """告警管理器"""
    
    def __init__(self, redis_client: redis.Redis = None):
        self.redis_client = redis_client
        self.logger = logging.getLogger(__name__)
        
        # 告警存储
        self.active_alerts: Dict[str, Alert] = {}
        self.alert_rules: Dict[str, AlertRule] = {}
        self.alert_history: List[Alert] = []
        
        # 通知管理器
        self.notification_manager = NotificationManager()
        
        # 告警处理线程
        self.processing_thread = None
        self.processing = False
        
        # 告警统计
        self.alert_stats = {
            'total_alerts': 0,
            'active_alerts': 0,
            'resolved_alerts': 0,
            'alerts_by_severity': defaultdict(int),
            'alerts_by_source': defaultdict(int)
        }
    
    def start_processing(self):
        """开始告警处理"""
        if self.processing:
            return
        
        self.processing = True
        self.processing_thread = threading.Thread(target=self._process_alerts)
        self.processing_thread.daemon = True
        self.processing_thread.start()
        
        self.logger.info("告警管理器已启动")
    
    def stop_processing(self):
        """停止告警处理"""
        self.processing = False
        if self.processing_thread:
            self.processing_thread.join()
        
        self.logger.info("告警管理器已停止")
    
    def add_alert_rule(self, rule: AlertRule):
        """添加告警规则"""
        self.alert_rules[rule.id] = rule
        self.logger.info(f"添加告警规则: {rule.name}")
    
    def remove_alert_rule(self, rule_id: str):
        """移除告警规则"""
        if rule_id in self.alert_rules:
            del self.alert_rules[rule_id]
            self.logger.info(f"移除告警规则: {rule_id}")
    
    def evaluate_metrics(self, metrics: Dict[str, Any]):
        """评估指标并触发告警"""
        for rule_id, rule in self.alert_rules.items():
            if not rule.enabled:
                continue
            
            if self._evaluate_rule(rule, metrics):
                self._trigger_alert(rule, metrics)
    
    def _evaluate_rule(self, rule: AlertRule, metrics: Dict[str, Any]) -> bool:
        """评估告警规则"""
        condition = rule.condition
        condition_type = condition.get('type')
        
        if condition_type == 'threshold':
            metric_name = condition.get('metric')
            threshold = condition.get('threshold')
            operator = condition.get('operator', 'gt')
            
            if metric_name not in metrics:
                return False
            
            value = metrics[metric_name]
            
            if operator == 'gt':
                return value > threshold
            elif operator == 'lt':
                return value < threshold
            elif operator == 'eq':
                return value == threshold
            elif operator == 'gte':
                return value >= threshold
            elif operator == 'lte':
                return value <= threshold
        
        elif condition_type == 'rate':
            metric_name = condition.get('metric')
            threshold = condition.get('threshold')
            time_window = condition.get('time_window', 300)  # 5分钟
            
            # 这里需要从时间序列数据中计算速率
            # 为了示例，我们使用模拟数据
            rate = 0.05  # 5%的错误率
            return rate > threshold
        
        elif condition_type == 'anomaly':
            metric_name = condition.get('metric')
            sensitivity = condition.get('sensitivity', 0.1)
            
            # 这里需要实现异常检测算法
            # 为了示例，我们使用简单的阈值检测
            if metric_name not in metrics:
                return False
            
            value = metrics[metric_name]
            baseline = 50  # 基线值
            
            return abs(value - baseline) / baseline > sensitivity
        
        return False
    
    def _trigger_alert(self, rule: AlertRule, metrics: Dict[str, Any]):
        """触发告警"""
        # 检查冷却时间
        if self._is_in_cooldown(rule):
            return
        
        # 创建告警
        alert = Alert(
            id=f"{rule.id}_{int(datetime.now().timestamp())}",
            title=rule.name,
            description=rule.description,
            severity=rule.severity,
            status=AlertStatus.ACTIVE,
            source=rule.id,
            timestamp=datetime.now(),
            metadata={
                'rule_id': rule.id,
                'metrics': metrics,
                'condition': rule.condition
            }
        )
        
        # 存储告警
        self.active_alerts[alert.id] = alert
        self.alert_history.append(alert)
        
        # 更新统计
        self._update_alert_stats(alert)
        
        # 发送通知
        self._send_notifications(alert, rule)
        
        self.logger.warning(f"告警触发: {alert.title}")
    
    def _is_in_cooldown(self, rule: AlertRule) -> bool:
        """检查是否在冷却时间内"""
        if rule.cooldown <= 0:
            return False
        
        # 检查最近是否有相同规则的告警
        cutoff_time = datetime.now() - timedelta(seconds=rule.cooldown)
        
        for alert in self.alert_history:
            if (alert.source == rule.id and 
                alert.timestamp > cutoff_time and 
                alert.status == AlertStatus.ACTIVE):
                return True
        
        return False
    
    def _update_alert_stats(self, alert: Alert):
        """更新告警统计"""
        self.alert_stats['total_alerts'] += 1
        self.alert_stats['active_alerts'] += 1
        self.alert_stats['alerts_by_severity'][alert.severity.value] += 1
        self.alert_stats['alerts_by_source'][alert.source] += 1
    
    def _send_notifications(self, alert: Alert, rule: AlertRule):
        """发送通知"""
        for channel in rule.notification_channels:
            try:
                self.notification_manager.send_notification(channel, alert)
            except Exception as e:
                self.logger.error(f"发送通知失败 {channel}: {e}")
    
    def acknowledge_alert(self, alert_id: str, user: str):
        """确认告警"""
        if alert_id in self.active_alerts:
            alert = self.active_alerts[alert_id]
            alert.status = AlertStatus.ACKNOWLEDGED
            alert.acknowledged_by = user
            alert.acknowledged_at = datetime.now()
            
            self.logger.info(f"告警已确认: {alert_id} by {user}")
    
    def resolve_alert(self, alert_id: str, user: str):
        """解决告警"""
        if alert_id in self.active_alerts:
            alert = self.active_alerts[alert_id]
            alert.status = AlertStatus.RESOLVED
            alert.resolved_at = datetime.now()
            
            # 移动到历史记录
            self.alert_history.append(alert)
            del self.active_alerts[alert_id]
            
            # 更新统计
            self.alert_stats['active_alerts'] -= 1
            self.alert_stats['resolved_alerts'] += 1
            
            self.logger.info(f"告警已解决: {alert_id} by {user}")
    
    def suppress_alert(self, alert_id: str, user: str, reason: str):
        """抑制告警"""
        if alert_id in self.active_alerts:
            alert = self.active_alerts[alert_id]
            alert.status = AlertStatus.SUPPRESSED
            alert.metadata['suppression_reason'] = reason
            alert.metadata['suppressed_by'] = user
            alert.metadata['suppressed_at'] = datetime.now().isoformat()
            
            self.logger.info(f"告警已抑制: {alert_id} by {user}")
    
    def get_active_alerts(self) -> List[Alert]:
        """获取活跃告警"""
        return list(self.active_alerts.values())
    
    def get_alert_history(self, limit: int = 100) -> List[Alert]:
        """获取告警历史"""
        return self.alert_history[-limit:]
    
    def get_alert_stats(self) -> Dict[str, Any]:
        """获取告警统计"""
        return dict(self.alert_stats)
    
    def _process_alerts(self):
        """处理告警"""
        while self.processing:
            try:
                # 检查告警状态
                self._check_alert_status()
                
                # 清理过期告警
                self._cleanup_expired_alerts()
                
                time.sleep(60)  # 每分钟检查一次
                
            except Exception as e:
                self.logger.error(f"告警处理错误: {e}")
                time.sleep(60)
    
    def _check_alert_status(self):
        """检查告警状态"""
        # 这里可以检查告警是否仍然有效
        # 例如：检查指标是否恢复正常
        pass
    
    def _cleanup_expired_alerts(self):
        """清理过期告警"""
        # 清理超过24小时的已解决告警
        cutoff_time = datetime.now() - timedelta(hours=24)
        
        expired_alerts = [
            alert for alert in self.alert_history
            if alert.status == AlertStatus.RESOLVED and 
               alert.resolved_at and 
               alert.resolved_at < cutoff_time
        ]
        
        for alert in expired_alerts:
            self.alert_history.remove(alert)

class NotificationManager:
    """通知管理器"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.notification_configs: Dict[NotificationChannel, NotificationConfig] = {}
        self._init_default_configs()
    
    def _init_default_configs(self):
        """初始化默认配置"""
        # 邮件配置
        self.notification_configs[NotificationChannel.EMAIL] = NotificationConfig(
            channel=NotificationChannel.EMAIL,
            enabled=False,
            config={
                'smtp_server': 'smtp.gmail.com',
                'smtp_port': 587,
                'username': '',
                'password': '',
                'from_email': '',
                'to_emails': []
            }
        )
        
        # Slack配置
        self.notification_configs[NotificationChannel.SLACK] = NotificationConfig(
            channel=NotificationChannel.SLACK,
            enabled=False,
            config={
                'webhook_url': '',
                'channel': '#alerts',
                'username': 'AlertBot'
            }
        )
        
        # Webhook配置
        self.notification_configs[NotificationChannel.WEBHOOK] = NotificationConfig(
            channel=NotificationChannel.WEBHOOK,
            enabled=False,
            config={
                'url': '',
                'method': 'POST',
                'headers': {},
                'timeout': 30
            }
        )
    
    def configure_notification(self, channel: NotificationChannel, config: Dict[str, Any]):
        """配置通知渠道"""
        if channel in self.notification_configs:
            self.notification_configs[channel].config.update(config)
            self.notification_configs[channel].enabled = True
            self.logger.info(f"配置通知渠道: {channel}")
    
    def send_notification(self, channel: NotificationChannel, alert: Alert):
        """发送通知"""
        if channel not in self.notification_configs:
            self.logger.error(f"未配置的通知渠道: {channel}")
            return
        
        config = self.notification_configs[channel]
        if not config.enabled:
            self.logger.warning(f"通知渠道未启用: {channel}")
            return
        
        try:
            if channel == NotificationChannel.EMAIL:
                self._send_email_notification(alert, config.config)
            elif channel == NotificationChannel.SLACK:
                self._send_slack_notification(alert, config.config)
            elif channel == NotificationChannel.WEBHOOK:
                self._send_webhook_notification(alert, config.config)
            else:
                self.logger.error(f"不支持的通知渠道: {channel}")
                
        except Exception as e:
            self.logger.error(f"发送通知失败 {channel}: {e}")
    
    def _send_email_notification(self, alert: Alert, config: Dict[str, Any]):
        """发送邮件通知"""
        msg = MIMEMultipart()
        msg['From'] = config['from_email']
        msg['To'] = ', '.join(config['to_emails'])
        msg['Subject'] = f"[{alert.severity.value.upper()}] {alert.title}"
        
        # 邮件正文
        body = f"""
告警详情:
标题: {alert.title}
描述: {alert.description}
严重程度: {alert.severity.value}
时间: {alert.timestamp.strftime('%Y-%m-%d %H:%M:%S')}
来源: {alert.source}

详细信息:
{json.dumps(alert.metadata, indent=2, ensure_ascii=False)}
        """
        
        msg.attach(MIMEText(body, 'plain', 'utf-8'))
        
        # 发送邮件
        server = smtplib.SMTP(config['smtp_server'], config['smtp_port'])
        server.starttls()
        server.login(config['username'], config['password'])
        server.send_message(msg)
        server.quit()
        
        self.logger.info(f"邮件通知已发送: {alert.title}")
    
    def _send_slack_notification(self, alert: Alert, config: Dict[str, Any]):
        """发送Slack通知"""
        # 根据严重程度选择颜色
        color_map = {
            AlertSeverity.LOW: '#36a64f',      # 绿色
            AlertSeverity.MEDIUM: '#ffeb3b',    # 黄色
            AlertSeverity.HIGH: '#ff9800',      # 橙色
            AlertSeverity.CRITICAL: '#f44336'    # 红色
        }
        
        payload = {
            'channel': config['channel'],
            'username': config['username'],
            'attachments': [{
                'color': color_map[alert.severity],
                'title': alert.title,
                'text': alert.description,
                'fields': [
                    {
                        'title': '严重程度',
                        'value': alert.severity.value.upper(),
                        'short': True
                    },
                    {
                        'title': '时间',
                        'value': alert.timestamp.strftime('%Y-%m-%d %H:%M:%S'),
                        'short': True
                    },
                    {
                        'title': '来源',
                        'value': alert.source,
                        'short': True
                    }
                ],
                'footer': 'IPv6 WireGuard Manager',
                'ts': int(alert.timestamp.timestamp())
            }]
        }
        
        response = requests.post(config['webhook_url'], json=payload, timeout=30)
        response.raise_for_status()
        
        self.logger.info(f"Slack通知已发送: {alert.title}")
    
    def _send_webhook_notification(self, alert: Alert, config: Dict[str, Any]):
        """发送Webhook通知"""
        payload = {
            'alert_id': alert.id,
            'title': alert.title,
            'description': alert.description,
            'severity': alert.severity.value,
            'status': alert.status.value,
            'source': alert.source,
            'timestamp': alert.timestamp.isoformat(),
            'metadata': alert.metadata
        }
        
        headers = {
            'Content-Type': 'application/json',
            **config.get('headers', {})
        }
        
        response = requests.request(
            config['method'],
            config['url'],
            json=payload,
            headers=headers,
            timeout=config.get('timeout', 30)
        )
        response.raise_for_status()
        
        self.logger.info(f"Webhook通知已发送: {alert.title}")

class AlertDashboard:
    """告警仪表板"""
    
    def __init__(self, alert_manager: AlertManager):
        self.alert_manager = alert_manager
        self.logger = logging.getLogger(__name__)
    
    def get_dashboard_data(self) -> Dict[str, Any]:
        """获取仪表板数据"""
        active_alerts = self.alert_manager.get_active_alerts()
        alert_history = self.alert_manager.get_alert_history(50)
        alert_stats = self.alert_manager.get_alert_stats()
        
        # 按严重程度分组
        alerts_by_severity = defaultdict(list)
        for alert in active_alerts:
            alerts_by_severity[alert.severity.value].append(alert)
        
        # 按来源分组
        alerts_by_source = defaultdict(list)
        for alert in active_alerts:
            alerts_by_source[alert.source].append(alert)
        
        return {
            'timestamp': datetime.now().isoformat(),
            'summary': {
                'total_alerts': alert_stats['total_alerts'],
                'active_alerts': alert_stats['active_alerts'],
                'resolved_alerts': alert_stats['resolved_alerts'],
                'alerts_by_severity': dict(alert_stats['alerts_by_severity']),
                'alerts_by_source': dict(alert_stats['alerts_by_source'])
            },
            'active_alerts': {
                'by_severity': {k: [asdict(alert) for alert in v] for k, v in alerts_by_severity.items()},
                'by_source': {k: [asdict(alert) for alert in v] for k, v in alerts_by_source.items()},
                'all': [asdict(alert) for alert in active_alerts]
            },
            'recent_history': [asdict(alert) for alert in alert_history]
        }
    
    def get_alert_trends(self, hours: int = 24) -> Dict[str, Any]:
        """获取告警趋势"""
        cutoff_time = datetime.now() - timedelta(hours=hours)
        
        # 按小时分组
        hourly_alerts = defaultdict(int)
        hourly_by_severity = defaultdict(lambda: defaultdict(int))
        
        for alert in self.alert_manager.alert_history:
            if alert.timestamp > cutoff_time:
                hour_key = alert.timestamp.strftime('%Y-%m-%d %H:00')
                hourly_alerts[hour_key] += 1
                hourly_by_severity[hour_key][alert.severity.value] += 1
        
        return {
            'hourly_trends': dict(hourly_alerts),
            'hourly_by_severity': {k: dict(v) for k, v in hourly_by_severity.items()}
        }

# 默认告警规则
DEFAULT_ALERT_RULES = [
    AlertRule(
        id="high_cpu_usage",
        name="CPU使用率过高",
        description="系统CPU使用率超过80%",
        condition={
            "type": "threshold",
            "metric": "cpu_usage",
            "operator": "gt",
            "threshold": 80.0
        },
        severity=AlertSeverity.HIGH,
        cooldown=300,
        notification_channels=[NotificationChannel.EMAIL, NotificationChannel.SLACK]
    ),
    AlertRule(
        id="high_memory_usage",
        name="内存使用率过高",
        description="系统内存使用率超过85%",
        condition={
            "type": "threshold",
            "metric": "memory_usage",
            "operator": "gt",
            "threshold": 85.0
        },
        severity=AlertSeverity.HIGH,
        cooldown=300,
        notification_channels=[NotificationChannel.EMAIL, NotificationChannel.SLACK]
    ),
    AlertRule(
        id="high_error_rate",
        name="错误率过高",
        description="应用错误率超过5%",
        condition={
            "type": "rate",
            "metric": "error_rate",
            "threshold": 0.05
        },
        severity=AlertSeverity.CRITICAL,
        cooldown=600,
        notification_channels=[NotificationChannel.EMAIL, NotificationChannel.SLACK, NotificationChannel.WEBHOOK]
    ),
    AlertRule(
        id="slow_response_time",
        name="响应时间过慢",
        description="API响应时间超过2秒",
        condition={
            "type": "threshold",
            "metric": "response_time",
            "operator": "gt",
            "threshold": 2.0
        },
        severity=AlertSeverity.MEDIUM,
        cooldown=300,
        notification_channels=[NotificationChannel.SLACK]
    )
]
