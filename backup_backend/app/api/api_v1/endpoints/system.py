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

from ....core.database import get_async_db
from ....schemas.common import MessageResponse

router = APIRouter()


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
async def get_system_info(db: AsyncSession = Depends(get_async_db)):
    """获取系统信息"""
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
        
        return SystemInfo(**system_info)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取系统信息失败: {str(e)}")


@router.get("/processes", response_model=None)
async def get_system_processes(db: AsyncSession = Depends(get_async_db)):
    """获取系统进程列表"""
    try:
        processes = []
        for proc in psutil.process_iter(['pid', 'name', 'status', 'cpu_percent', 'memory_percent', 'create_time']):
            try:
                process_info = ProcessInfo(
                    pid=proc.info['pid'],
                    name=proc.info['name'],
                    status=proc.info['status'],
                    cpu_percent=proc.info['cpu_percent'] or 0.0,
                    memory_percent=proc.info['memory_percent'] or 0.0,
                    create_time=datetime.fromtimestamp(proc.info['create_time']).isoformat() if proc.info['create_time'] else ""
                )
                processes.append(process_info)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
        
        # 按CPU使用率排序，只返回前50个进程
        processes.sort(key=lambda x: x.cpu_percent, reverse=True)
        return processes[:50]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取进程列表失败: {str(e)}")


@router.post("/restart", response_model=None)
async def restart_system(db: AsyncSession = Depends(get_async_db)):
    """重启系统（模拟）"""
    try:
        # 在实际生产环境中，这里应该调用系统重启命令
        # 例如：os.system("sudo reboot")
        # 但为了安全，这里只返回模拟响应
        return MessageResponse(
            message="系统重启命令已发送（模拟操作）",
            details={
                "warning": "这是模拟操作，实际环境中需要适当的权限和安全性考虑",
                "timestamp": datetime.now().isoformat()
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"系统重启失败: {str(e)}")


@router.post("/shutdown", response_model=None)
async def shutdown_system(db: AsyncSession = Depends(get_async_db)):
    """关闭系统（模拟）"""
    try:
        # 在实际生产环境中，这里应该调用系统关机命令
        # 例如：os.system("sudo shutdown -h now")
        # 但为了安全，这里只返回模拟响应
        return MessageResponse(
            message="系统关机命令已发送（模拟操作）",
            details={
                "warning": "这是模拟操作，实际环境中需要适当的权限和安全性考虑",
                "timestamp": datetime.now().isoformat()
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"系统关机失败: {str(e)}")


@router.get("/health/check")
async def system_health_check(db: AsyncSession = Depends(get_async_db)):
    """系统健康检查"""
    try:
        # 检查关键系统指标
        cpu_usage = psutil.cpu_percent(interval=1)
        memory_usage = psutil.virtual_memory().percent
        disk_usage = psutil.disk_usage('/').percent
        
        status = "healthy"
        if cpu_usage > 90 or memory_usage > 90 or disk_usage > 90:
            status = "warning"
        
        return {
            "status": status,
            "service": "system",
            "timestamp": datetime.now().isoformat(),
            "metrics": {
                "cpu_usage": cpu_usage,
                "memory_usage": memory_usage,
                "disk_usage": disk_usage
            },
            "message": "系统运行正常" if status == "healthy" else "系统资源使用率较高"
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"系统健康检查失败: {str(e)}")