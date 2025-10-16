"""
告警服务 - 完整的告警检查和通知系统
"""
import asyncio
import time
import psutil
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload

from ..models.alert import Alert, AlertRule
from ..schemas.alert import AlertCreate, AlertRuleCreate, AlertRuleUpdate
from ..core.config_enhanced import settings
import logging

logger = logging.getLogger(__name__)

class AlertService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.alert_rules = []
        self.last_check_time = time.time()
        self.alert_history = []

    async def create_alert_rule(self, rule_data: AlertRuleCreate) -> AlertRule:
        """创建告警规则"""
        try:
            rule = AlertRule(
                name=rule_data.name,
                description=rule_data.description,
                metric_type=rule_data.metric_type,
                threshold=rule_data.threshold,
                comparison_operator=rule_data.comparison_operator,
                severity=rule_data.severity,
                is_enabled=rule_data.is_enabled,
                check_interval=rule_data.check_interval,
                notification_channels=rule_data.notification_channels
            )
            
            self.db.add(rule)
            await self.db.commit()
            await self.db.refresh(rule)
            
            # 添加到内存中的规则列表
            self.alert_rules.append(rule)
            
            return rule
        except Exception as e:
            logger.error(f"创建告警规则失败: {e}")
            await self.db.rollback()
            raise

    async def get_alert_rules(self) -> List[AlertRule]:
        """获取所有告警规则"""
        try:
            result = await self.db.execute(select(AlertRule))
            rules = result.scalars().all()
            self.alert_rules = list(rules)
            return rules
        except Exception as e:
            logger.error(f"获取告警规则失败: {e}")
            return []

    async def update_alert_rule(self, rule_id: str, rule_data: AlertRuleUpdate) -> Optional[AlertRule]:
        """更新告警规则"""
        try:
            result = await self.db.execute(select(AlertRule).where(AlertRule.id == rule_id))
            rule = result.scalar_one_or_none()
            
            if not rule:
                return None
            
            # 更新字段
            for field, value in rule_data.dict(exclude_unset=True).items():
                setattr(rule, field, value)
            
            await self.db.commit()
            await self.db.refresh(rule)
            
            # 更新内存中的规则
            for i, r in enumerate(self.alert_rules):
                if r.id == rule.id:
                    self.alert_rules[i] = rule
                    break
            
            return rule
        except Exception as e:
            logger.error(f"更新告警规则失败: {e}")
            await self.db.rollback()
            raise

    async def delete_alert_rule(self, rule_id: str) -> bool:
        """删除告警规则"""
        try:
            result = await self.db.execute(select(AlertRule).where(AlertRule.id == rule_id))
            rule = result.scalar_one_or_none()
            
            if not rule:
                return False
            
            await self.db.delete(rule)
            await self.db.commit()
            
            # 从内存中移除
            self.alert_rules = [r for r in self.alert_rules if r.id != rule_id]
            
            return True
        except Exception as e:
            logger.error(f"删除告警规则失败: {e}")
            await self.db.rollback()
            return False

    async def check_alerts(self) -> List[Dict[str, Any]]:
        """检查告警"""
        try:
            current_time = time.time()
            alerts = []
            
            # 获取系统指标
            system_metrics = await self.get_system_metrics()
            
            # 检查每个告警规则
            for rule in self.alert_rules:
                if not rule.is_enabled:
                    continue
                
                # 检查检查间隔
                if current_time - self.last_check_time < rule.check_interval:
                    continue
                
                # 获取指标值
                metric_value = self.get_metric_value(system_metrics, rule.metric_type)
                if metric_value is None:
                    continue
                
                # 检查是否触发告警
                if self.evaluate_condition(metric_value, rule.threshold, rule.comparison_operator):
                    # 创建告警
                    alert = await self.create_alert(rule, metric_value)
                    if alert:
                        alerts.append(alert)
            
            self.last_check_time = current_time
            return alerts
            
        except Exception as e:
            logger.error(f"检查告警失败: {e}")
            return []

    async def get_system_metrics(self) -> Dict[str, Any]:
        """获取系统指标"""
        try:
            # CPU指标
            cpu_percent = psutil.cpu_percent(interval=1)
            cpu_count = psutil.cpu_count()
            load_avg = psutil.getloadavg() if hasattr(psutil, 'getloadavg') else (0, 0, 0)
            
            # 内存指标
            memory = psutil.virtual_memory()
            swap = psutil.swap_memory()
            
            # 磁盘指标
            disk = psutil.disk_usage('/')
            
            # 网络指标
            network = psutil.net_io_counters()
            
            # 进程指标
            process_count = len(psutil.pids())
            
            return {
                "cpu": {
                    "percent": cpu_percent,
                    "count": cpu_count,
                    "load_1min": load_avg[0],
                    "load_5min": load_avg[1],
                    "load_15min": load_avg[2]
                },
                "memory": {
                    "total": memory.total,
                    "available": memory.available,
                    "used": memory.used,
                    "percent": memory.percent,
                    "free": memory.free
                },
                "swap": {
                    "total": swap.total,
                    "used": swap.used,
                    "free": swap.free,
                    "percent": swap.percent
                },
                "disk": {
                    "total": disk.total,
                    "used": disk.used,
                    "free": disk.free,
                    "percent": (disk.used / disk.total) * 100
                },
                "network": {
                    "bytes_sent": network.bytes_sent,
                    "bytes_recv": network.bytes_recv,
                    "packets_sent": network.packets_sent,
                    "packets_recv": network.packets_recv
                },
                "processes": {
                    "count": process_count
                }
            }
        except Exception as e:
            logger.error(f"获取系统指标失败: {e}")
            return {}

    def get_metric_value(self, metrics: Dict[str, Any], metric_type: str) -> Optional[float]:
        """获取指标值"""
        try:
            # 解析指标路径，如 "cpu.percent", "memory.percent" 等
            parts = metric_type.split('.')
            value = metrics
            
            for part in parts:
                if isinstance(value, dict) and part in value:
                    value = value[part]
                else:
                    return None
            
            return float(value) if isinstance(value, (int, float)) else None
        except Exception as e:
            logger.error(f"获取指标值失败: {e}")
            return None

    def evaluate_condition(self, value: float, threshold: float, operator: str) -> bool:
        """评估告警条件"""
        try:
            if operator == "gt":
                return value > threshold
            elif operator == "gte":
                return value >= threshold
            elif operator == "lt":
                return value < threshold
            elif operator == "lte":
                return value <= threshold
            elif operator == "eq":
                return value == threshold
            elif operator == "ne":
                return value != threshold
            else:
                return False
        except Exception as e:
            logger.error(f"评估条件失败: {e}")
            return False

    async def create_alert(self, rule: AlertRule, metric_value: float) -> Optional[Dict[str, Any]]:
        """创建告警"""
        try:
            # 检查是否已经存在相同的活跃告警
            existing_alert = await self.get_active_alert(rule.id)
            if existing_alert:
                # 更新现有告警
                existing_alert.last_triggered = datetime.now()
                existing_alert.trigger_count += 1
                await self.db.commit()
                return None
            
            # 创建新告警
            alert = Alert(
                rule_id=rule.id,
                title=f"{rule.name} 告警",
                message=f"{rule.description} - 当前值: {metric_value:.2f}, 阈值: {rule.threshold}",
                severity=rule.severity,
                status="active",
                triggered_at=datetime.now(),
                last_triggered=datetime.now(),
                trigger_count=1,
                metric_value=metric_value,
                threshold_value=rule.threshold
            )
            
            self.db.add(alert)
            await self.db.commit()
            await self.db.refresh(alert)
            
            # 发送通知
            await self.send_notifications(alert, rule)
            
            return {
                "id": str(alert.id),
                "title": alert.title,
                "message": alert.message,
                "severity": alert.severity,
                "status": alert.status,
                "triggered_at": alert.triggered_at.isoformat(),
                "metric_value": alert.metric_value,
                "threshold_value": alert.threshold_value
            }
            
        except Exception as e:
            logger.error(f"创建告警失败: {e}")
            await self.db.rollback()
            return None

    async def get_active_alert(self, rule_id: str) -> Optional[Alert]:
        """获取活跃的告警"""
        try:
            result = await self.db.execute(
                select(Alert).where(
                    Alert.rule_id == rule_id,
                    Alert.status == "active"
                )
            )
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"获取活跃告警失败: {e}")
            return None

    async def send_notifications(self, alert: Alert, rule: AlertRule):
        """发送通知"""
        try:
            # 这里可以实现各种通知渠道
            # 例如：邮件、短信、Slack、钉钉等
            
            notification_data = {
                "alert_id": str(alert.id),
                "title": alert.title,
                "message": alert.message,
                "severity": alert.severity,
                "triggered_at": alert.triggered_at.isoformat(),
                "channels": rule.notification_channels
            }
            
            # 记录通知日志
            logger.info(f"发送告警通知: {notification_data}")
            
            # 实际实现中，这里会调用各种通知服务
            # await self.send_email_notification(notification_data)
            # await self.send_slack_notification(notification_data)
            # await self.send_webhook_notification(notification_data)
            
        except Exception as e:
            logger.error(f"发送通知失败: {e}")

    async def resolve_alert(self, alert_id: str) -> bool:
        """解决告警"""
        try:
            result = await self.db.execute(select(Alert).where(Alert.id == alert_id))
            alert = result.scalar_one_or_none()
            
            if not alert:
                return False
            
            alert.status = "resolved"
            alert.resolved_at = datetime.now()
            
            await self.db.commit()
            return True
            
        except Exception as e:
            logger.error(f"解决告警失败: {e}")
            await self.db.rollback()
            return False

    async def get_alert_history(self, limit: int = 100) -> List[Dict[str, Any]]:
        """获取告警历史"""
        try:
            result = await self.db.execute(
                select(Alert)
                .order_by(Alert.triggered_at.desc())
                .limit(limit)
            )
            alerts = result.scalars().all()
            
            return [
                {
                    "id": str(alert.id),
                    "title": alert.title,
                    "message": alert.message,
                    "severity": alert.severity,
                    "status": alert.status,
                    "triggered_at": alert.triggered_at.isoformat(),
                    "resolved_at": alert.resolved_at.isoformat() if alert.resolved_at else None,
                    "trigger_count": alert.trigger_count,
                    "metric_value": alert.metric_value,
                    "threshold_value": alert.threshold_value
                }
                for alert in alerts
            ]
        except Exception as e:
            logger.error(f"获取告警历史失败: {e}")
            return []

    async def get_alert_statistics(self) -> Dict[str, Any]:
        """获取告警统计"""
        try:
            # 获取总告警数
            total_result = await self.db.execute(select(Alert))
            total_alerts = len(total_result.scalars().all())
            
            # 获取活跃告警数
            active_result = await self.db.execute(
                select(Alert).where(Alert.status == "active")
            )
            active_alerts = len(active_result.scalars().all())
            
            # 获取按严重程度分组的告警数
            severity_stats = {}
            for severity in ["low", "medium", "high", "critical"]:
                result = await self.db.execute(
                    select(Alert).where(Alert.severity == severity)
                )
                severity_stats[severity] = len(result.scalars().all())
            
            # 获取最近24小时的告警数
            yesterday = datetime.now() - timedelta(days=1)
            recent_result = await self.db.execute(
                select(Alert).where(Alert.triggered_at >= yesterday)
            )
            recent_alerts = len(recent_result.scalars().all())
            
            return {
                "total_alerts": total_alerts,
                "active_alerts": active_alerts,
                "resolved_alerts": total_alerts - active_alerts,
                "recent_alerts_24h": recent_alerts,
                "severity_breakdown": severity_stats
            }
        except Exception as e:
            logger.error(f"获取告警统计失败: {e}")
            return {}
