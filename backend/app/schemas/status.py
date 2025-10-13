"""
状态相关模式定义
"""
from typing import Dict, Any, List, Optional
from pydantic import BaseModel


class SystemStatus(BaseModel):
    """系统状态"""
    cpu_percent: float
    memory: Dict[str, Any]
    disk: Dict[str, Any]
    network: Dict[str, Any]


class ServiceStatus(BaseModel):
    """服务状态"""
    name: str
    active: bool
    status: str
    error: Optional[str] = None
    interfaces: Optional[List[Dict[str, Any]]] = None


class SystemStatusResponse(BaseModel):
    """系统状态响应"""
    system: SystemStatus
    timestamp: float


class ServicesStatusResponse(BaseModel):
    """服务状态响应"""
    services: Dict[str, ServiceStatus]
    timestamp: float


class HealthCheckResponse(BaseModel):
    """健康检查响应"""
    status: str
    message: str