"""
日志管理API端点
"""
import os
import glob
import json
from datetime import datetime
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Response
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from ...core.database import get_db
from ...core.logging import get_logger

router = APIRouter()

# 创建日志记录器
logger = get_logger(__name__)


class LogEntry(BaseModel):
    """日志条目模型"""
    id: str
    timestamp: str
    level: str
    message: str
    source: str
    details: Optional[Dict[str, Any]] = None


class LogListResponse(BaseModel):
    """日志列表响应模型"""
    logs: List[LogEntry]
    total: int
    page: int
    page_size: int


class LogDetailResponse(BaseModel):
    """日志详情响应模型"""
    log: LogEntry


@router.get("")
async def get_logs(
    page: int = Query(1, ge=1, description="页码"),
    size: int = Query(20, ge=1, le=100, description="每页数量"),
    level: Optional[str] = Query(None, description="日志级别"),
    service: Optional[str] = Query(None, description="服务名称"),
    start_time: Optional[str] = Query(None, description="开始时间"),
    end_time: Optional[str] = Query(None, description="结束时间")
):
    """获取日志列表"""
    try:
        # 模拟日志数据
        logs = [
            {
                "id": "log-1",
                "timestamp": datetime.now().isoformat(),
                "level": "INFO",
                "service": "api",
                "message": "API请求成功",
                "details": {
                    "request_id": "req-123",
                    "user_id": "user-456",
                    "ip": "192.168.1.1"
                }
            },
            {
                "id": "log-2",
                "timestamp": datetime.now().isoformat(),
                "level": "ERROR",
                "service": "database",
                "message": "数据库连接失败",
                "details": {
                    "error": "Connection timeout",
                    "retry_count": 3
                }
            }
        ]
        
        # 应用过滤条件
        filtered_logs = logs
        if level:
            filtered_logs = [log for log in filtered_logs if log["level"] == level]
        if service:
            filtered_logs = [log for log in filtered_logs if log["service"] == service]
            
        # 分页
        total = len(filtered_logs)
        start_idx = (page - 1) * size
        end_idx = start_idx + size
        paginated_logs = filtered_logs[start_idx:end_idx]
        
        return {
            "items": paginated_logs,
            "total": total,
            "page": page,
            "size": size,
            "pages": (total + size - 1) // size
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get logs: {str(e)}")


@router.get("/{log_id}")
async def get_log(log_id: str):
    """获取单个日志"""
    try:
        # 模拟获取单个日志
        log = {
            "id": log_id,
            "timestamp": datetime.now().isoformat(),
            "level": "INFO",
            "service": "api",
            "message": "API请求成功",
            "details": {
                "request_id": "req-123",
                "user_id": "user-456",
                "ip": "192.168.1.1",
                "user_agent": "Mozilla/5.0",
                "request_path": "/api/v1/users",
                "method": "GET",
                "status_code": 200,
                "response_time": 120
            }
        }
        
        return JSONResponse(content=log)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get log: {str(e)}")


@router.delete("/{log_id}")
async def delete_log(log_id: str):
    """删除日志"""
    try:
        # 模拟删除操作
        return {"message": f"日志 {log_id} 已删除", "success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"删除日志失败: {str(e)}")


@router.delete("")
async def clear_logs(
    level: Optional[str] = Query(None, description="日志级别"),
    service: Optional[str] = Query(None, description="服务名称"),
    older_than: Optional[str] = Query(None, description="删除早于此时间的日志")
):
    """清空日志"""
    try:
        # 模拟清空日志
        return {
            "message": "日志已清空",
            "success": True,
            "timestamp": datetime.now().isoformat(),
            "filters": {
                "level": level,
                "service": service,
                "older_than": older_than
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to clear logs: {str(e)}")


@router.get("/health")
async def logs_health_check():
    """日志服务健康检查"""
    try:
        return {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "service": "logs",
            "details": {
                "storage": "available",
                "search_index": "available",
                "total_logs": 12345,
                "last_log_time": datetime.now().isoformat()
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Health check failed: {str(e)}")

@router.get("/search")
async def search_logs(
    query: str = Query(..., description="搜索查询"),
    page: int = Query(1, ge=1, description="页码"),
    size: int = Query(20, ge=1, le=100, description="每页数量"),
    level: Optional[str] = Query(None, description="日志级别"),
    service: Optional[str] = Query(None, description="服务名称"),
    start_time: Optional[str] = Query(None, description="开始时间"),
    end_time: Optional[str] = Query(None, description="结束时间")
):
    """搜索日志"""
    try:
        # 模拟日志数据
        logs = [
            {
                "id": "log-1",
                "timestamp": datetime.now().isoformat(),
                "level": "INFO",
                "service": "api",
                "message": "API请求成功",
                "details": {
                    "request_id": "req-123",
                    "user_id": "user-456",
                    "ip": "192.168.1.1"
                }
            },
            {
                "id": "log-2",
                "timestamp": datetime.now().isoformat(),
                "level": "ERROR",
                "service": "database",
                "message": "数据库连接失败",
                "details": {
                    "error": "Connection timeout",
                    "retry_count": 3
                }
            }
        ]
        
        # 搜索过滤
        filtered_logs = [
            log for log in logs 
            if query.lower() in log["message"].lower() or 
               query.lower() in log["service"].lower()
        ]
        
        # 应用其他过滤条件
        if level:
            filtered_logs = [log for log in filtered_logs if log["level"] == level]
        if service:
            filtered_logs = [log for log in filtered_logs if log["service"] == service]
            
        # 分页
        total = len(filtered_logs)
        start_idx = (page - 1) * size
        end_idx = start_idx + size
        paginated_logs = filtered_logs[start_idx:end_idx]
        
        return {
            "items": paginated_logs,
            "total": total,
            "page": page,
            "size": size,
            "pages": (total + size - 1) // size,
            "query": query
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to search logs: {str(e)}")

@router.get("/export")
async def export_logs(
    format: str = Query("json", description="导出格式"),
    level: Optional[str] = Query(None, description="日志级别"),
    service: Optional[str] = Query(None, description="服务名称"),
    start_time: Optional[str] = Query(None, description="开始时间"),
    end_time: Optional[str] = Query(None, description="结束时间")
):
    """导出日志"""
    try:
        # 模拟导出日志
        logs = [
            {
                "id": "log-1",
                "timestamp": datetime.now().isoformat(),
                "level": "INFO",
                "service": "api",
                "message": "API请求成功",
                "details": {
                    "request_id": "req-123",
                    "user_id": "user-456",
                    "ip": "192.168.1.1"
                }
            }
        ]
        
        # 应用过滤条件
        filtered_logs = logs
        if level:
            filtered_logs = [log for log in filtered_logs if log["level"] == level]
        if service:
            filtered_logs = [log for log in filtered_logs if log["service"] == service]
            
        # 根据格式返回数据
        if format == "csv":
            # 简化的CSV导出
            csv_data = "id,timestamp,level,service,message\n"
            for log in filtered_logs:
                csv_data += f"{log['id']},{log['timestamp']},{log['level']},{log['service']},{log['message']}\n"
            
            return Response(
                content=csv_data,
                media_type="text/csv",
                headers={"Content-Disposition": "attachment; filename=logs.csv"}
            )
        else:
            # JSON格式
            return JSONResponse(content=filtered_logs)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to export logs: {str(e)}")

@router.get("/levels")
async def get_log_levels():
    """获取日志级别列表"""
    try:
        levels = [
            {"value": "DEBUG", "label": "调试"},
            {"value": "INFO", "label": "信息"},
            {"value": "WARNING", "label": "警告"},
            {"value": "ERROR", "label": "错误"},
            {"value": "CRITICAL", "label": "严重"}
        ]
        
        return JSONResponse(content=levels)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get log levels: {str(e)}")

@router.get("/services")
async def get_log_services():
    """获取日志服务列表"""
    try:
        services = [
            {"value": "api", "label": "API服务"},
            {"value": "database", "label": "数据库服务"},
            {"value": "cache", "label": "缓存服务"},
            {"value": "auth", "label": "认证服务"},
            {"value": "monitoring", "label": "监控服务"}
        ]
        
        return JSONResponse(content=services)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get log services: {str(e)}")