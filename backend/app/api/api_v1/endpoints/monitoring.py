"""
系统监控API端点
"""
import psutil
import time
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from ....core.database import get_async_db

router = APIRouter()


class SystemMetrics(BaseModel):
    """系统指标模型"""
    timestamp: str
    cpu_usage: float
    memory_usage: float
    disk_usage: float
    network_sent: int
    network_recv: int
    load_average: Dict[str, float]


class Alert(BaseModel):
    """告警模型"""
    id: str
    severity: str  # critical, warning, info
    message: str
    source: str
    timestamp: str
    resolved: bool
    details: Optional[Dict[str, Any]] = None


class AlertResponse(BaseModel):
    """告警响应模型"""
    alerts: List[Alert]
    total: int
    critical_count: int
    warning_count: int


# 模拟历史数据存储
metrics_history = []
alerts_history = []


@router.get("/metrics", response_model=None)
async def get_system_metrics(db: AsyncSession = Depends(get_async_db)):
    """获取当前系统指标"""
    try:
        # 获取当前系统指标
        cpu_usage = psutil.cpu_percent(interval=1)
        memory_usage = psutil.virtual_memory().percent
        disk_usage = psutil.disk_usage('/').percent
        
        # 获取网络IO
        net_io = psutil.net_io_counters()
        
        # 获取负载平均值（在Windows上使用模拟值）
        load_avg = {
            "1min": psutil.getloadavg()[0] if hasattr(psutil, 'getloadavg') else cpu_usage / 100,
            "5min": psutil.getloadavg()[1] if hasattr(psutil, 'getloadavg') else cpu_usage / 100 * 0.8,
            "15min": psutil.getloadavg()[2] if hasattr(psutil, 'getloadavg') else cpu_usage / 100 * 0.6
        }
        
        current_metrics = SystemMetrics(
            timestamp=datetime.now().isoformat(),
            cpu_usage=cpu_usage,
            memory_usage=memory_usage,
            disk_usage=disk_usage,
            network_sent=net_io.bytes_sent,
            network_recv=net_io.bytes_recv,
            load_average=load_avg
        )
        
        # 存储历史数据（限制为最近100条）
        metrics_history.append(current_metrics)
        if len(metrics_history) > 100:
            metrics_history.pop(0)
        
        return current_metrics
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取系统指标失败: {str(e)}")


@router.get("/metrics/history", response_model=None)
async def get_metrics_history(
    hours: int = 24,
    db: AsyncSession = Depends(get_async_db)
):
    """获取历史系统指标"""
    try:
        # 如果历史数据为空，生成一些模拟数据
        if not metrics_history:
            generate_mock_metrics()
        
        # 过滤指定时间范围内的数据
        cutoff_time = datetime.now() - timedelta(hours=hours)
        filtered_metrics = [
            metric for metric in metrics_history 
            if datetime.fromisoformat(metric.timestamp) >= cutoff_time
        ]
        
        return filtered_metrics
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取历史指标失败: {str(e)}")


@router.get("/alerts", response_model=None)
async def get_alerts(
    severity: Optional[str] = None,
    resolved: Optional[bool] = None,
    db: AsyncSession = Depends(get_async_db)
):
    """获取告警信息"""
    try:
        # 如果告警历史为空，生成一些模拟数据
        if not alerts_history:
            generate_mock_alerts()
        
        # 过滤告警
        filtered_alerts = alerts_history
        if severity:
            filtered_alerts = [alert for alert in filtered_alerts if alert.severity == severity]
        if resolved is not None:
            filtered_alerts = [alert for alert in filtered_alerts if alert.resolved == resolved]
        
        # 统计告警数量
        critical_count = len([alert for alert in filtered_alerts if alert.severity == "critical"])
        warning_count = len([alert for alert in filtered_alerts if alert.severity == "warning"])
        
        return AlertResponse(
            alerts=filtered_alerts,
            total=len(filtered_alerts),
            critical_count=critical_count,
            warning_count=warning_count
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取告警信息失败: {str(e)}")


@router.post("/alerts/{alert_id}/resolve")
async def resolve_alert(alert_id: str, db: AsyncSession = Depends(get_async_db)):
    """解决告警"""
    try:
        # 查找并解决告警
        for alert in alerts_history:
            if alert.id == alert_id:
                alert.resolved = True
                return {"message": f"告警 {alert_id} 已解决", "success": True}
        
        raise HTTPException(status_code=404, detail=f"告警 {alert_id} 不存在")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"解决告警失败: {str(e)}")


@router.get("/health/check")
async def monitoring_health_check(db: AsyncSession = Depends(get_async_db)):
    """监控服务健康检查"""
    try:
        # 检查监控服务状态
        cpu_usage = psutil.cpu_percent(interval=1)
        memory_usage = psutil.virtual_memory().percent
        
        status = "healthy"
        if cpu_usage > 95 or memory_usage > 95:
            status = "warning"
        
        return {
            "status": status,
            "service": "monitoring",
            "timestamp": datetime.now().isoformat(),
            "metrics": {
                "cpu_usage": cpu_usage,
                "memory_usage": memory_usage
            },
            "message": "监控服务运行正常" if status == "healthy" else "系统资源使用率较高"
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"监控服务异常: {str(e)}")


def generate_mock_metrics():
    """生成模拟指标数据"""
    global metrics_history
    base_time = datetime.now() - timedelta(hours=24)
    
    for i in range(100):
        timestamp = base_time + timedelta(minutes=i * 15)
        metrics_history.append(SystemMetrics(
            timestamp=timestamp.isoformat(),
            cpu_usage=20 + (i % 50),
            memory_usage=30 + (i % 40),
            disk_usage=10 + (i % 20),
            network_sent=1000 + i * 100,
            network_recv=2000 + i * 150,
            load_average={"1min": 0.5 + (i % 30) / 100, "5min": 0.4 + (i % 25) / 100, "15min": 0.3 + (i % 20) / 100}
        ))


def generate_mock_alerts():
    """生成模拟告警数据"""
    global alerts_history
    base_time = datetime.now() - timedelta(hours=24)
    
    alert_messages = [
        ("critical", "CPU使用率超过90%"),
        ("warning", "内存使用率超过80%"),
        ("info", "磁盘使用率超过70%"),
        ("critical", "网络连接异常"),
        ("warning", "服务响应时间过长")
    ]
    
    for i, (severity, message) in enumerate(alert_messages):
        alerts_history.append(Alert(
            id=f"alert_{i}",
            severity=severity,
            message=message,
            source="system",
            timestamp=(base_time + timedelta(hours=i * 6)).isoformat(),
            resolved=i % 3 == 0,  # 每3个告警解决1个
            details={"threshold": 90 if severity == "critical" else 80}
        ))