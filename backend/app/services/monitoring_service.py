import uuid
import psutil
import time
import json
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import and_, desc
from ..models.monitoring import SystemMetric, AuditLog, OperationLog
from ..schemas.monitoring import (
    SystemMetricCreate, AuditLogCreate, OperationLogCreate,
    SystemStats, ServiceStatus, AlertRule, Alert, LogQuery, LogResponse
)
from ..core.logging import get_logger

logger = get_logger(__name__)

class MonitoringService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def collect_system_metrics(self) -> SystemStats:
        """收集系统性能指标"""
        try:
            # CPU使用率
            cpu_percent = psutil.cpu_percent(interval=1)
            
            # 内存使用率
            memory = psutil.virtual_memory()
            memory_percent = memory.percent
            
            # 磁盘使用率
            disk = psutil.disk_usage('/')
            disk_percent = (disk.used / disk.total) * 100
            
            # 网络统计
            net_io = psutil.net_io_counters()
            network_rx = net_io.bytes_recv
            network_tx = net_io.bytes_sent
            
            # 活跃连接数
            connections = len(psutil.net_connections())
            
            return SystemStats(
                cpu_usage=cpu_percent,
                memory_usage=memory_percent,
                disk_usage=disk_percent,
                network_rx=network_rx,
                network_tx=network_tx,
                active_connections=connections,
                timestamp=datetime.utcnow()
            )
        except Exception as e:
            logger.error(f"收集系统指标失败: {e}")
            raise

    async def save_system_metric(self, metric_in: SystemMetricCreate) -> SystemMetric:
        """保存系统指标"""
        try:
            metric = SystemMetric(**metric_in.model_dump())
            self.db.add(metric)
            await self.db.commit()
            await self.db.refresh(metric)
            return metric
        except Exception as e:
            await self.db.rollback()
            logger.error(f"保存系统指标失败: {e}")
            raise

    async def get_system_metrics(
        self, 
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        metric_name: Optional[str] = None,
        limit: int = 100
    ) -> List[SystemMetric]:
        """获取系统指标"""
        try:
            query = select(SystemMetric)
            
            conditions = []
            if start_time:
                conditions.append(SystemMetric.timestamp >= start_time)
            if end_time:
                conditions.append(SystemMetric.timestamp <= end_time)
            if metric_name:
                conditions.append(SystemMetric.metric_name == metric_name)
            
            if conditions:
                query = query.where(and_(*conditions))
            
            query = query.order_by(desc(SystemMetric.timestamp)).limit(limit)
            
            result = await self.db.execute(query)
            return result.scalars().all()
        except Exception as e:
            logger.error(f"获取系统指标失败: {e}")
            raise

    async def create_audit_log(self, log_in: AuditLogCreate) -> AuditLog:
        """创建审计日志"""
        try:
            audit_log = AuditLog(**log_in.model_dump())
            self.db.add(audit_log)
            await self.db.commit()
            await self.db.refresh(audit_log)
            return audit_log
        except Exception as e:
            await self.db.rollback()
            logger.error(f"创建审计日志失败: {e}")
            raise

    async def get_audit_logs(
        self,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        user_id: Optional[uuid.UUID] = None,
        action: Optional[str] = None,
        limit: int = 100,
        offset: int = 0
    ) -> List[AuditLog]:
        """获取审计日志"""
        try:
            query = select(AuditLog)
            
            conditions = []
            if start_time:
                conditions.append(AuditLog.timestamp >= start_time)
            if end_time:
                conditions.append(AuditLog.timestamp <= end_time)
            if user_id:
                conditions.append(AuditLog.user_id == user_id)
            if action:
                conditions.append(AuditLog.action == action)
            
            if conditions:
                query = query.where(and_(*conditions))
            
            query = query.order_by(desc(AuditLog.timestamp)).offset(offset).limit(limit)
            
            result = await self.db.execute(query)
            return result.scalars().all()
        except Exception as e:
            logger.error(f"获取审计日志失败: {e}")
            raise

    async def create_operation_log(self, log_in: OperationLogCreate) -> OperationLog:
        """创建操作日志"""
        try:
            operation_log = OperationLog(**log_in.model_dump())
            self.db.add(operation_log)
            await self.db.commit()
            await self.db.refresh(operation_log)
            return operation_log
        except Exception as e:
            await self.db.rollback()
            logger.error(f"创建操作日志失败: {e}")
            raise

    async def get_operation_logs(
        self,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        operation_type: Optional[str] = None,
        status: Optional[str] = None,
        limit: int = 100,
        offset: int = 0
    ) -> List[OperationLog]:
        """获取操作日志"""
        try:
            query = select(OperationLog)
            
            conditions = []
            if start_time:
                conditions.append(OperationLog.timestamp >= start_time)
            if end_time:
                conditions.append(OperationLog.timestamp <= end_time)
            if operation_type:
                conditions.append(OperationLog.operation_type == operation_type)
            if status:
                conditions.append(OperationLog.status == status)
            
            if conditions:
                query = query.where(and_(*conditions))
            
            query = query.order_by(desc(OperationLog.timestamp)).offset(offset).limit(limit)
            
            result = await self.db.execute(query)
            return result.scalars().all()
        except Exception as e:
            logger.error(f"获取操作日志失败: {e}")
            raise

    async def get_service_status(self) -> List[ServiceStatus]:
        """获取服务状态"""
        try:
            services = []
            
            # 检查主要服务
            service_checks = [
                ("postgresql", "systemctl is-active postgresql"),
                ("redis", "systemctl is-active redis"),
                ("nginx", "systemctl is-active nginx"),
                ("wireguard", "systemctl is-active wg-quick@wg0")
            ]
            
            for service_name, check_cmd in service_checks:
                try:
                    import subprocess
                    result = subprocess.run(
                        check_cmd.split(), 
                        capture_output=True, 
                        text=True, 
                        timeout=5
                    )
                    
                    status = "running" if result.returncode == 0 else "stopped"
                    
                    # 获取运行时间
                    uptime = None
                    try:
                        uptime_result = subprocess.run(
                            ["systemctl", "show", service_name, "--property=ActiveEnterTimestamp"],
                            capture_output=True, text=True, timeout=5
                        )
                        if uptime_result.returncode == 0:
                            # 解析运行时间
                            uptime = 0  # 简化实现
                    except:
                        pass
                    
                    services.append(ServiceStatus(
                        service_name=service_name,
                        status=status,
                        uptime=uptime,
                        last_check=datetime.utcnow()
                    ))
                except Exception as e:
                    services.append(ServiceStatus(
                        service_name=service_name,
                        status="error",
                        last_check=datetime.utcnow()
                    ))
            
            return services
        except Exception as e:
            logger.error(f"获取服务状态失败: {e}")
            return []

    async def check_alerts(self) -> List[Alert]:
        """检查告警规则"""
        try:
            alerts = []
            
            # 获取当前系统指标
            stats = await self.collect_system_metrics()
            
            # 定义告警规则
            alert_rules = [
                {
                    "metric": "cpu_usage",
                    "threshold": 80.0,
                    "operator": "gt",
                    "severity": "warning",
                    "message": "CPU使用率过高"
                },
                {
                    "metric": "memory_usage",
                    "threshold": 85.0,
                    "operator": "gt",
                    "severity": "warning",
                    "message": "内存使用率过高"
                },
                {
                    "metric": "disk_usage",
                    "threshold": 90.0,
                    "operator": "gt",
                    "severity": "critical",
                    "message": "磁盘使用率过高"
                }
            ]
            
            for rule in alert_rules:
                metric_value = getattr(stats, rule["metric"])
                threshold = rule["threshold"]
                operator = rule["operator"]
                
                should_alert = False
                if operator == "gt" and metric_value > threshold:
                    should_alert = True
                elif operator == "lt" and metric_value < threshold:
                    should_alert = True
                elif operator == "eq" and metric_value == threshold:
                    should_alert = True
                
                if should_alert:
                    alert = Alert(
                        id=uuid.uuid4(),
                        rule_id=uuid.uuid4(),  # 简化实现
                        message=f"{rule['message']}: {metric_value:.1f}%",
                        severity=rule["severity"],
                        status="active",
                        created_at=datetime.utcnow()
                    )
                    alerts.append(alert)
            
            return alerts
        except Exception as e:
            logger.error(f"检查告警失败: {e}")
            return []

    async def get_dashboard_data(self) -> Dict[str, Any]:
        """获取仪表板数据"""
        try:
            # 获取系统统计
            stats = await self.collect_system_metrics()
            
            # 获取服务状态
            services = await self.get_service_status()
            
            # 获取最近的告警
            alerts = await self.check_alerts()
            
            # 获取最近的审计日志
            recent_audit_logs = await self.get_audit_logs(limit=10)
            
            # 获取最近的系统指标
            recent_metrics = await self.get_system_metrics(limit=50)
            
            return {
                "system_stats": stats,
                "services": services,
                "alerts": alerts,
                "recent_audit_logs": recent_audit_logs,
                "recent_metrics": recent_metrics
            }
        except Exception as e:
            logger.error(f"获取仪表板数据失败: {e}")
            raise

    async def search_logs(self, query: LogQuery) -> LogResponse:
        """搜索日志"""
        try:
            # 这里应该实现更复杂的日志搜索逻辑
            # 简化实现，只搜索操作日志
            
            logs = await self.get_operation_logs(
                start_time=query.start_time,
                end_time=query.end_time,
                operation_type=query.service,
                status=query.level,
                limit=query.limit,
                offset=query.offset
            )
            
            # 转换为字典格式
            log_dicts = []
            for log in logs:
                log_dict = {
                    "timestamp": log.timestamp.isoformat(),
                    "level": log.status,
                    "service": log.operation_type,
                    "message": log.operation_data.get("message", ""),
                    "details": log.operation_data
                }
                log_dicts.append(log_dict)
            
            # 检查是否有更多数据
            has_more = len(logs) == query.limit
            
            return LogResponse(
                logs=log_dicts,
                total=len(log_dicts),  # 简化实现
                has_more=has_more
            )
        except Exception as e:
            logger.error(f"搜索日志失败: {e}")
            raise

    async def export_logs(
        self,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        log_type: str = "all"
    ) -> str:
        """导出日志"""
        try:
            logs = []
            
            if log_type in ["all", "audit"]:
                audit_logs = await self.get_audit_logs(
                    start_time=start_time,
                    end_time=end_time,
                    limit=10000
                )
                for log in audit_logs:
                    logs.append({
                        "type": "audit",
                        "timestamp": log.timestamp.isoformat(),
                        "user_id": str(log.user_id) if log.user_id else None,
                        "action": log.action,
                        "resource_type": log.resource_type,
                        "resource_id": str(log.resource_id) if log.resource_id else None,
                        "details": log.details,
                        "ip_address": log.ip_address,
                        "user_agent": log.user_agent
                    })
            
            if log_type in ["all", "operation"]:
                operation_logs = await self.get_operation_logs(
                    start_time=start_time,
                    end_time=end_time,
                    limit=10000
                )
                for log in operation_logs:
                    logs.append({
                        "type": "operation",
                        "timestamp": log.timestamp.isoformat(),
                        "operation_type": log.operation_type,
                        "status": log.status,
                        "error_message": log.error_message,
                        "execution_time": log.execution_time,
                        "operation_data": log.operation_data
                    })
            
            # 转换为JSON格式
            return json.dumps(logs, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.error(f"导出日志失败: {e}")
            raise
