"""
系统监控API端点
"""
import uuid
from datetime import datetime, timedelta
from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query, Response
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db
from ....core.security import get_current_user_id
from ....schemas.monitoring import (
    SystemMetric, SystemMetricCreate, AuditLog, AuditLogCreate,
    OperationLog, OperationLogCreate, SystemStats, ServiceStatus,
    Alert, LogQuery, LogResponse
)
from ....schemas.common import Message
from ....services.monitoring_service import MonitoringService

router = APIRouter()

# 系统指标端点
@router.get("/system/metrics", response_model=List[SystemMetric])
async def get_system_metrics(
    start_time: Optional[datetime] = Query(None, description="开始时间"),
    end_time: Optional[datetime] = Query(None, description="结束时间"),
    metric_name: Optional[str] = Query(None, description="指标名称"),
    limit: int = Query(100, ge=1, le=1000, description="限制记录数"),
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取系统性能指标
    """
    monitoring_service = MonitoringService(db)
    metrics = await monitoring_service.get_system_metrics(
        start_time=start_time,
        end_time=end_time,
        metric_name=metric_name,
        limit=limit
    )
    return metrics

@router.get("/system/stats", response_model=SystemStats)
async def get_system_stats(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取当前系统统计信息
    """
    monitoring_service = MonitoringService(db)
    stats = await monitoring_service.collect_system_metrics()
    return stats

@router.get("/system/status")
async def get_system_status(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取系统状态
    """
    monitoring_service = MonitoringService(db)
    data = await monitoring_service.get_dashboard_data()
    return data

@router.post("/system/metrics", response_model=SystemMetric, status_code=status.HTTP_201_CREATED)
async def create_system_metric(
    metric_in: SystemMetricCreate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    创建系统指标记录
    """
    monitoring_service = MonitoringService(db)
    metric = await monitoring_service.save_system_metric(metric_in)
    return metric

# 审计日志端点
@router.get("/audit/logs", response_model=List[AuditLog])
async def get_audit_logs(
    start_time: Optional[datetime] = Query(None, description="开始时间"),
    end_time: Optional[datetime] = Query(None, description="结束时间"),
    user_id: Optional[uuid.UUID] = Query(None, description="用户ID"),
    action: Optional[str] = Query(None, description="操作类型"),
    limit: int = Query(100, ge=1, le=1000, description="限制记录数"),
    offset: int = Query(0, ge=0, description="偏移量"),
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取审计日志
    """
    monitoring_service = MonitoringService(db)
    logs = await monitoring_service.get_audit_logs(
        start_time=start_time,
        end_time=end_time,
        user_id=user_id,
        action=action,
        limit=limit,
        offset=offset
    )
    return logs

@router.post("/audit/logs", response_model=AuditLog, status_code=status.HTTP_201_CREATED)
async def create_audit_log(
    log_in: AuditLogCreate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    创建审计日志记录
    """
    monitoring_service = MonitoringService(db)
    log = await monitoring_service.create_audit_log(log_in)
    return log

# 操作日志端点
@router.get("/operation/logs", response_model=List[OperationLog])
async def get_operation_logs(
    start_time: Optional[datetime] = Query(None, description="开始时间"),
    end_time: Optional[datetime] = Query(None, description="结束时间"),
    operation_type: Optional[str] = Query(None, description="操作类型"),
    status: Optional[str] = Query(None, description="状态"),
    limit: int = Query(100, ge=1, le=1000, description="限制记录数"),
    offset: int = Query(0, ge=0, description="偏移量"),
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取操作日志
    """
    monitoring_service = MonitoringService(db)
    logs = await monitoring_service.get_operation_logs(
        start_time=start_time,
        end_time=end_time,
        operation_type=operation_type,
        status=status,
        limit=limit,
        offset=offset
    )
    return logs

@router.post("/operation/logs", response_model=OperationLog, status_code=status.HTTP_201_CREATED)
async def create_operation_log(
    log_in: OperationLogCreate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    创建操作日志记录
    """
    monitoring_service = MonitoringService(db)
    log = await monitoring_service.create_operation_log(log_in)
    return log

# 服务状态端点
@router.get("/services/status", response_model=List[ServiceStatus])
async def get_services_status(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取服务状态
    """
    monitoring_service = MonitoringService(db)
    services = await monitoring_service.get_service_status()
    return services

# 告警端点
@router.get("/alerts", response_model=List[Alert])
async def get_alerts(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取当前告警
    """
    monitoring_service = MonitoringService(db)
    alerts = await monitoring_service.check_alerts()
    return alerts

# 仪表板端点
@router.get("/dashboard")
async def get_dashboard_data(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取仪表板数据
    """
    monitoring_service = MonitoringService(db)
    data = await monitoring_service.get_dashboard_data()
    return data

# 日志搜索端点
@router.post("/logs/search", response_model=LogResponse)
async def search_logs(
    query: LogQuery,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    搜索日志
    """
    monitoring_service = MonitoringService(db)
    result = await monitoring_service.search_logs(query)
    return result

# 日志导出端点
@router.get("/logs/export")
async def export_logs(
    start_time: Optional[datetime] = Query(None, description="开始时间"),
    end_time: Optional[datetime] = Query(None, description="结束时间"),
    log_type: str = Query("all", description="日志类型"),
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    导出日志
    """
    monitoring_service = MonitoringService(db)
    logs_json = await monitoring_service.export_logs(
        start_time=start_time,
        end_time=end_time,
        log_type=log_type
    )
    
    return Response(
        content=logs_json,
        media_type="application/json",
        headers={
            "Content-Disposition": f"attachment; filename=logs_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        }
    )