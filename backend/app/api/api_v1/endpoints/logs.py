"""
日志管理API端点
"""
import uuid
from datetime import datetime
from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query, Response
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db
from ....core.security import get_current_user_id
from ....schemas.monitoring import AuditLog, OperationLog, LogQuery, LogResponse
from ....services.monitoring_service import MonitoringService

router = APIRouter()

@router.get("/system", response_model=List[OperationLog])
async def get_system_logs(
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
    获取系统日志
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

@router.get("/audit", response_model=List[AuditLog])
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

@router.get("/application", response_model=List[OperationLog])
async def get_application_logs(
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
    获取应用日志
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

@router.post("/search", response_model=LogResponse)
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

@router.get("/export")
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