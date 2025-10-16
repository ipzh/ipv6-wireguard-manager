"""
监控API端点
提供系统监控、指标收集、告警管理等功能
"""
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import JSONResponse

from ....core.monitoring_enhanced import (
    monitoring_dashboard,
    AlertManager,
    AlertRule,
    AlertLevel,
    AlertStatus,
    Metric
)
from ....core.security_enhanced import security_manager, rate_limit
from ....core.cluster_manager import cluster_manager, cluster_aware

router = APIRouter()

@router.get("/dashboard", response_model=None)
@rate_limit
async def get_dashboard_data():
    """获取监控仪表板数据"""
    try:
        data = monitoring_dashboard.get_dashboard_data()
        return JSONResponse(content=data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get dashboard data: {str(e)}")

@router.get("/metrics/system", response_model=List[Dict[str, Any]], response_model=None)
@rate_limit
async def get_system_metrics(
    hours: int = Query(24, description="获取最近几小时的指标", ge=1, le=168)
):
    """获取系统指标"""
    try:
        metrics = []
        metric_names = [
            "system.cpu.usage",
            "system.memory.usage", 
            "system.disk.usage",
            "system.network.bytes_sent",
            "system.network.bytes_recv"
        ]
        
        for metric_name in metric_names:
            history = monitoring_dashboard.get_metric_history(metric_name, hours)
            metrics.extend(history)
        
        return JSONResponse(content=metrics)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get system metrics: {str(e)}")

@router.get("/metrics/application", response_model=List[Dict[str, Any]], response_model=None)
@rate_limit
async def get_application_metrics(
    hours: int = Query(24, description="获取最近几小时的指标", ge=1, le=168)
):
    """获取应用指标"""
    try:
        metrics = []
        metric_names = [
            "app.database.pool_size",
            "app.database.checked_out",
            "app.cache.connected_clients",
            "app.cache.used_memory",
            "app.task_queue.size",
            "app.task_queue.workers"
        ]
        
        for metric_name in metric_names:
            history = monitoring_dashboard.get_metric_history(metric_name, hours)
            metrics.extend(history)
        
        return JSONResponse(content=metrics)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get application metrics: {str(e)}")

@router.get("/alerts/active", response_model=List[Dict[str, Any]], response_model=None)
@rate_limit
async def get_active_alerts():
    """获取活跃告警"""
    try:
        alerts = monitoring_dashboard.alert_manager.get_active_alerts()
        return JSONResponse(content=[alert.to_dict() for alert in alerts])
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get active alerts: {str(e)}")

@router.get("/alerts/history", response_model=List[Dict[str, Any]], response_model=None)
@rate_limit
async def get_alert_history(
    hours: int = Query(24, description="获取最近几小时的告警历史", ge=1, le=168)
):
    """获取告警历史"""
    try:
        alerts = monitoring_dashboard.alert_manager.get_alert_history(hours)
        return JSONResponse(content=[alert.to_dict() for alert in alerts])
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get alert history: {str(e)}")

@router.get("/alerts/rules", response_model=List[Dict[str, Any]], response_model=None)
@rate_limit
async def get_alert_rules():
    """获取告警规则"""
    try:
        rules = monitoring_dashboard.alert_manager.get_alert_rules()
        return JSONResponse(content=[rule.to_dict() for rule in rules])
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get alert rules: {str(e)}")

@router.post("/alerts/rules", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def create_alert_rule(rule_data: Dict[str, Any]):
    """创建告警规则"""
    try:
        rule = AlertRule(
            id=rule_data["id"],
            name=rule_data["name"],
            metric_name=rule_data["metric_name"],
            condition=rule_data["condition"],
            threshold=rule_data["threshold"],
            level=AlertLevel(rule_data["level"]),
            enabled=rule_data.get("enabled", True),
            cooldown_minutes=rule_data.get("cooldown_minutes", 5),
            description=rule_data.get("description", ""),
            tags=rule_data.get("tags", {})
        )
        
        monitoring_dashboard.alert_manager.add_alert_rule(rule)
        return JSONResponse(content={"message": "Alert rule created successfully", "rule": rule.to_dict()})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create alert rule: {str(e)}")

@router.put("/alerts/rules/{rule_id}", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def update_alert_rule(rule_id: str, rule_data: Dict[str, Any]):
    """更新告警规则"""
    try:
        existing_rules = monitoring_dashboard.alert_manager.get_alert_rules()
        existing_rule = next((rule for rule in existing_rules if rule.id == rule_id), None)
        
        if not existing_rule:
            raise HTTPException(status_code=404, detail="Alert rule not found")
        
        # 更新规则
        for key, value in rule_data.items():
            if hasattr(existing_rule, key):
                if key == "level":
                    setattr(existing_rule, key, AlertLevel(value))
                else:
                    setattr(existing_rule, key, value)
        
        return JSONResponse(content={"message": "Alert rule updated successfully", "rule": existing_rule.to_dict()})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update alert rule: {str(e)}")

@router.delete("/alerts/rules/{rule_id}", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def delete_alert_rule(rule_id: str):
    """删除告警规则"""
    try:
        monitoring_dashboard.alert_manager.remove_alert_rule(rule_id)
        return JSONResponse(content={"message": "Alert rule deleted successfully"})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete alert rule: {str(e)}")

@router.post("/alerts/{rule_id}/acknowledge", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def acknowledge_alert(rule_id: str, user: str = Query(..., description="确认用户")):
    """确认告警"""
    try:
        monitoring_dashboard.alert_manager.acknowledge_alert(rule_id, user)
        return JSONResponse(content={"message": "Alert acknowledged successfully"})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to acknowledge alert: {str(e)}")

@router.post("/alerts/{rule_id}/suppress", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def suppress_alert(
    rule_id: str, 
    duration_minutes: int = Query(60, description="抑制时长（分钟）", ge=1, le=1440)
):
    """抑制告警"""
    try:
        monitoring_dashboard.alert_manager.suppress_alert(rule_id, duration_minutes)
        return JSONResponse(content={"message": f"Alert suppressed for {duration_minutes} minutes"})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to suppress alert: {str(e)}")

@router.get("/health", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def health_check():
    """健康检查"""
    try:
        # 获取最新指标
        cpu_metric = monitoring_dashboard.system_collector.get_latest_metric("system.cpu.usage")
        memory_metric = monitoring_dashboard.system_collector.get_latest_metric("system.memory.usage")
        
        # 检查系统状态
        is_healthy = True
        issues = []
        
        if cpu_metric and cpu_metric.value > 90:
            is_healthy = False
            issues.append("CPU usage too high")
        
        if memory_metric and memory_metric.value > 95:
            is_healthy = False
            issues.append("Memory usage too high")
        
        return JSONResponse(content={
            "status": "healthy" if is_healthy else "unhealthy",
            "timestamp": datetime.utcnow().isoformat(),
            "issues": issues,
            "metrics": {
                "cpu_usage": cpu_metric.value if cpu_metric else None,
                "memory_usage": memory_metric.value if memory_metric else None
            }
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Health check failed: {str(e)}")

@router.get("/cluster/status", response_model=Dict[str, Any], response_model=None)
@cluster_aware
@rate_limit
async def get_cluster_status():
    """获取集群状态"""
    try:
        status = cluster_manager.get_cluster_status()
        return JSONResponse(content=status)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get cluster status: {str(e)}")

@router.post("/cluster/sync", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def sync_cluster_data(sync_data: Dict[str, Any]):
    """同步集群数据"""
    try:
        data_type = sync_data.get("data_type")
        data = sync_data.get("data")
        source_node = sync_data.get("source_node")
        
        # 这里应该实现实际的数据同步逻辑
        logger.info(f"Received sync data from {source_node}: {data_type}")
        
        return JSONResponse(content={"message": "Data synced successfully"})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to sync data: {str(e)}")

@router.get("/performance", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def get_performance_stats():
    """获取性能统计"""
    try:
        stats = performance_manager.get_status()
        return JSONResponse(content=stats)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get performance stats: {str(e)}")

@router.post("/metrics/collect", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def collect_metrics_now():
    """立即收集指标"""
    try:
        # 收集系统指标
        system_metrics = await monitoring_dashboard.system_collector.collect_system_metrics()
        
        # 收集应用指标
        app_metrics = await monitoring_dashboard.app_collector.collect_application_metrics()
        
        # 评估告警
        all_metrics = system_metrics + app_metrics
        monitoring_dashboard.alert_manager.evaluate_metrics(all_metrics)
        
        return JSONResponse(content={
            "message": "Metrics collected successfully",
            "system_metrics_count": len(system_metrics),
            "app_metrics_count": len(app_metrics),
            "total_metrics": len(all_metrics)
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to collect metrics: {str(e)}")

@router.get("/metrics/{metric_name}", response_model=List[Dict[str, Any]], response_model=None)
@rate_limit
async def get_metric_history(
    metric_name: str,
    hours: int = Query(24, description="获取最近几小时的指标", ge=1, le=168)
):
    """获取特定指标的历史数据"""
    try:
        history = monitoring_dashboard.get_metric_history(metric_name, hours)
        return JSONResponse(content=history)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get metric history: {str(e)}")

@router.get("/alerts/stats", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def get_alert_statistics():
    """获取告警统计"""
    try:
        active_alerts = monitoring_dashboard.alert_manager.get_active_alerts()
        alert_history = monitoring_dashboard.alert_manager.get_alert_history(24)
        
        # 按级别统计
        level_stats = {}
        for level in AlertLevel:
            level_stats[level.value] = len([a for a in alert_history if a.level == level])
        
        # 按状态统计
        status_stats = {}
        for status in AlertStatus:
            status_stats[status.value] = len([a for a in alert_history if a.status == status])
        
        return JSONResponse(content={
            "active_alerts_count": len(active_alerts),
            "total_alerts_24h": len(alert_history),
            "level_statistics": level_stats,
            "status_statistics": status_stats,
            "alert_rules_count": len(monitoring_dashboard.alert_manager.get_alert_rules())
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get alert statistics: {str(e)}")