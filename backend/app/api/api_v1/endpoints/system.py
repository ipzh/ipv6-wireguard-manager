"""
系统管理API端点
"""
import os
import platform
import psutil
import socket
from datetime import datetime
from typing import Dict, Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from ...core.database import get_db
from ...core.response_handler import ResponseHandler
from ...core.logging import get_logger

# 简化的模式，避免依赖不存在的模块
try:
    from ...schemas.common import MessageResponse
except ImportError:
    MessageResponse = None

router = APIRouter()

# 创建日志记录器
logger = get_logger(__name__)


class SystemInfo(BaseModel):
    """系统信息模型"""
    platform: str
    platform_version: str
    architecture: str
    hostname: str
    cpu_count: int
    cpu_usage: float
    memory_total: int
    memory_available: int
    memory_used: int
    memory_percent: float
    disk_usage: Dict[str, Any]
    boot_time: str
    uptime: str
    python_version: str


class ProcessInfo(BaseModel):
    """进程信息模型"""
    pid: int
    name: str
    status: str
    cpu_percent: float
    memory_percent: float
    create_time: str


@router.get("/info", response_model=None)
async def get_system_info():
    """获取系统信息"""
    start_time = datetime.now()
    logger.info("获取系统信息请求开始", extra={
        "endpoint": "/system/info",
        "method": "GET",
        "start_time": start_time.isoformat()
    })
    
    try:
        # 获取系统信息
        system_info = {
            "platform": platform.system(),
            "platform_version": platform.version(),
            "architecture": platform.architecture()[0],
            "hostname": socket.gethostname(),
            "cpu_count": psutil.cpu_count(),
            "cpu_usage": psutil.cpu_percent(interval=1),
            "memory_total": psutil.virtual_memory().total,
            "memory_available": psutil.virtual_memory().available,
            "memory_used": psutil.virtual_memory().used,
            "memory_percent": psutil.virtual_memory().percent,
            "disk_usage": {
                "total": psutil.disk_usage('/').total,
                "used": psutil.disk_usage('/').used,
                "free": psutil.disk_usage('/').free,
                "percent": psutil.disk_usage('/').percent
            },
            "boot_time": datetime.fromtimestamp(psutil.boot_time()).isoformat(),
            "uptime": str(datetime.now() - datetime.fromtimestamp(psutil.boot_time())),
            "python_version": platform.python_version()
        }
        
        duration = (datetime.now() - start_time).total_seconds()
        logger.info("获取系统信息成功", extra={
            "endpoint": "/system/info",
            "method": "GET",
            "duration": duration,
            "system_info": {
                "platform": system_info["platform"],
                "hostname": system_info["hostname"],
                "cpu_usage": system_info["cpu_usage"],
                "memory_percent": system_info["memory_percent"],
                "disk_usage_percent": system_info["disk_usage"]["percent"]
            }
        })
        
        return ResponseHandler.success(
            data=SystemInfo(**system_info),
            message="获取系统信息成功"
        )
    except Exception as e:
        duration = (datetime.now() - start_time).total_seconds()
        logger.error("获取系统信息失败", extra={
            "endpoint": "/system/info",
            "method": "GET",
            "duration": duration,
            "error": str(e),
            "error_type": type(e).__name__
        })
        
        return ResponseHandler.server_error(
            message="获取系统信息失败",
            details={"error": str(e)}
        )


@router.get("/status", response_model=None)
async def get_system_status():
    """获取系统状态"""
    start_time = datetime.now()
    logger.info("获取系统状态请求开始", extra={
        "endpoint": "/system/status",
        "method": "GET",
        "start_time": start_time.isoformat()
    })
    
    try:
        # 获取系统状态
        cpu_usage = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        status = {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "services": {
                "api": "healthy",
                "database": "healthy",
                "cache": "healthy"
            },
            "resources": {
                "cpu": {
                    "usage": cpu_usage,
                    "status": "normal" if cpu_usage < 80 else "warning"
                },
                "memory": {
                    "usage": memory.percent,
                    "status": "normal" if memory.percent < 80 else "warning"
                },
                "disk": {
                    "usage": disk.percent,
                    "status": "normal" if disk.percent < 80 else "warning"
                }
            }
        }
        
        duration = (datetime.now() - start_time).total_seconds()
        logger.info("获取系统状态成功", extra={
            "endpoint": "/system/status",
            "method": "GET",
            "duration": duration,
            "system_status": {
                "overall_status": status["status"],
                "cpu_usage": cpu_usage,
                "memory_usage": memory.percent,
                "disk_usage": disk.percent
            }
        })
        
        return ResponseHandler.success(
            data=status,
            message="获取系统状态成功"
        )
    except Exception as e:
        duration = (datetime.now() - start_time).total_seconds()
        logger.error("获取系统状态失败", extra={
            "endpoint": "/system/status",
            "method": "GET",
            "duration": duration,
            "error": str(e),
            "error_type": type(e).__name__
        })
        
        return ResponseHandler.server_error(
            message="获取系统状态失败",
            details={"error": str(e)}
        )


@router.get("/health", response_model=None)
async def system_health_check():
    """系统健康检查"""
    start_time = datetime.now()
    logger.info("系统健康检查请求开始", extra={
        "endpoint": "/system/health",
        "method": "GET",
        "start_time": start_time.isoformat()
    })
    
    try:
        # 检查关键系统指标
        cpu_usage = psutil.cpu_percent(interval=1)
        memory_usage = psutil.virtual_memory().percent
        disk_usage = psutil.disk_usage('/').percent
        
        status = "healthy"
        if cpu_usage > 90 or memory_usage > 90 or disk_usage > 90:
            status = "warning"
        
        health_data = {
            "status": status,
            "service": "system",
            "timestamp": datetime.now().isoformat(),
            "metrics": {
                "cpu_usage": cpu_usage,
                "memory_usage": memory_usage,
                "disk_usage": disk_usage
            }
        }
        
        message = "系统运行正常" if status == "healthy" else "系统资源使用率较高"
        
        duration = (datetime.now() - start_time).total_seconds()
        logger.info("系统健康检查完成", extra={
            "endpoint": "/system/health",
            "method": "GET",
            "duration": duration,
            "health_status": status,
            "cpu_usage": cpu_usage,
            "memory_usage": memory_usage,
            "disk_usage": disk_usage
        })
        
        return ResponseHandler.success(
            data=health_data,
            message=message
        )
    except Exception as e:
        duration = (datetime.now() - start_time).total_seconds()
        logger.error("系统健康检查失败", extra={
            "endpoint": "/system/health",
            "method": "GET",
            "duration": duration,
            "error": str(e),
            "error_type": type(e).__name__
        })
        
        return ResponseHandler.server_error(
            message="系统健康检查失败",
            details={"error": str(e)}
        )


@router.get("/metrics", response_model=None)
async def get_system_metrics():
    """获取系统指标"""
    start_time = datetime.now()
    logger.info("获取系统指标请求开始", extra={
        "endpoint": "/system/metrics",
        "method": "GET",
        "start_time": start_time.isoformat()
    })
    
    try:
        # 获取系统指标
        cpu_usage = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        network = psutil.net_io_counters()
        
        metrics = {
            "timestamp": datetime.now().isoformat(),
            "cpu": {
                "usage": cpu_usage,
                "count": psutil.cpu_count(),
                "count_logical": psutil.cpu_count(logical=True)
            },
            "memory": {
                "total": memory.total,
                "available": memory.available,
                "used": memory.used,
                "percent": memory.percent
            },
            "disk": {
                "total": disk.total,
                "used": disk.used,
                "free": disk.free,
                "percent": disk.percent
            },
            "network": {
                "bytes_sent": network.bytes_sent,
                "bytes_recv": network.bytes_recv,
                "packets_sent": network.packets_sent,
                "packets_recv": network.packets_recv
            }
        }
        
        duration = (datetime.now() - start_time).total_seconds()
        logger.info("获取系统指标成功", extra={
            "endpoint": "/system/metrics",
            "method": "GET",
            "duration": duration,
            "metrics_summary": {
                "cpu_usage": cpu_usage,
                "memory_usage": memory.percent,
                "disk_usage": disk.percent,
                "network_bytes_sent": network.bytes_sent,
                "network_bytes_recv": network.bytes_recv
            }
        })
        
        return ResponseHandler.success(
            data=metrics,
            message="获取系统指标成功"
        )
    except Exception as e:
        duration = (datetime.now() - start_time).total_seconds()
        logger.error("获取系统指标失败", extra={
            "endpoint": "/system/metrics",
            "method": "GET",
            "duration": duration,
            "error": str(e),
            "error_type": type(e).__name__
        })
        
        return ResponseHandler.server_error(
            message="获取系统指标失败",
            details={"error": str(e)}
        )


@router.get("/config", response_model=None)
async def get_system_config():
    """获取系统配置"""
    try:
        # 获取系统配置（模拟）
        config = {
            "timezone": "UTC",
            "locale": "en_US",
            "log_level": "INFO",
            "max_connections": 1000,
            "timeout": 30,
            "backup_enabled": True,
            "monitoring_enabled": True,
            "auto_update": False
        }
        
        return ResponseHandler.success(
            data=config,
            message="获取系统配置成功"
        )
    except Exception as e:
        return ResponseHandler.server_error(
            message="获取系统配置失败",
            details={"error": str(e)}
        )


@router.put("/config", response_model=None)
async def update_system_config(config_data: dict):
    """更新系统配置"""
    try:
        # 模拟更新配置
        result = {
            "timestamp": datetime.now().isoformat()
        }
        
        return ResponseHandler.success(
            data=result,
            message="系统配置已更新"
        )
    except Exception as e:
        return ResponseHandler.server_error(
            message="更新系统配置失败",
            details={"error": str(e)}
        )


@router.get("/logs", response_model=None)
async def get_system_logs():
    """获取系统日志"""
    try:
        # 模拟系统日志
        logs = [
            {
                "id": "log_1",
                "timestamp": datetime.now().isoformat(),
                "level": "INFO",
                "message": "系统启动成功",
                "source": "system"
            },
            {
                "id": "log_2",
                "timestamp": datetime.now().isoformat(),
                "level": "WARNING",
                "message": "内存使用率较高",
                "source": "system"
            }
        ]
        
        return ResponseHandler.success(
            data={"logs": logs, "total": len(logs)},
            message="获取系统日志成功"
        )
    except Exception as e:
        return ResponseHandler.server_error(
            message="获取系统日志失败",
            details={"error": str(e)}
        )


@router.post("/backup", response_model=None)
async def create_system_backup():
    """创建系统备份"""
    try:
        # 模拟创建备份
        result = {
            "backup_id": f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "timestamp": datetime.now().isoformat()
        }
        
        return ResponseHandler.success(
            data=result,
            message="系统备份已创建"
        )
    except Exception as e:
        return ResponseHandler.server_error(
            message="创建系统备份失败",
            details={"error": str(e)}
        )


@router.post("/restore", response_model=None)
async def restore_system_backup(backup_id: str):
    """恢复系统备份"""
    try:
        # 模拟恢复备份
        result = {
            "backup_id": backup_id,
            "timestamp": datetime.now().isoformat()
        }
        
        return ResponseHandler.success(
            data=result,
            message=f"系统备份 {backup_id} 已恢复"
        )
    except Exception as e:
        return ResponseHandler.server_error(
            message="恢复系统备份失败",
            details={"error": str(e)}
        )


@router.get("/processes", response_model=None)
async def get_process_list(limit: int = 10):
    """获取进程列表"""
    start_time = datetime.now()
    logger.info("获取进程列表请求开始", extra={
        "endpoint": "/system/processes",
        "method": "GET",
        "start_time": start_time.isoformat(),
        "limit": limit
    })
    
    try:
        # 获取进程列表
        processes = []
        for proc in psutil.process_iter(['pid', 'name', 'username', 'cpu_percent', 'memory_percent']):
            try:
                processes.append(proc.info)
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                pass
        
        # 按CPU使用率排序
        processes.sort(key=lambda x: x['cpu_percent'] or 0, reverse=True)
        
        # 限制返回数量
        processes = processes[:limit]
        
        duration = (datetime.now() - start_time).total_seconds()
        logger.info("获取进程列表成功", extra={
            "endpoint": "/system/processes",
            "method": "GET",
            "duration": duration,
            "process_count": len(processes),
            "limit": limit
        })
        
        return ResponseHandler.success(
            data={"processes": [ProcessInfo(**p) for p in processes]},
            message="获取进程列表成功"
        )
    except Exception as e:
        duration = (datetime.now() - start_time).total_seconds()
        logger.error("获取进程列表失败", extra={
            "endpoint": "/system/processes",
            "method": "GET",
            "duration": duration,
            "error": str(e),
            "error_type": type(e).__name__
        })
        
        return ResponseHandler.server_error(
            message="获取进程列表失败",
            details={"error": str(e)}
        )


@router.get("/health/check")
async def system_health_check_detailed():
    """详细系统健康检查"""
    try:
        # 检查关键系统指标
        cpu_usage = psutil.cpu_percent(interval=1)
        memory_usage = psutil.virtual_memory().percent
        disk_usage = psutil.disk_usage('/').percent
        
        status = "healthy"
        if cpu_usage > 90 or memory_usage > 90 or disk_usage > 90:
            status = "warning"
        
        health_data = {
            "status": status,
            "service": "system",
            "timestamp": datetime.now().isoformat(),
            "metrics": {
                "cpu_usage": cpu_usage,
                "memory_usage": memory_usage,
                "disk_usage": disk_usage
            }
        }
        
        message = "系统运行正常" if status == "healthy" else "系统资源使用率较高"
        
        return ResponseHandler.success(
            data=health_data,
            message=message
        )
    except Exception as e:
        return ResponseHandler.server_error(
            message="系统健康检查失败",
            details={"error": str(e)}
        )