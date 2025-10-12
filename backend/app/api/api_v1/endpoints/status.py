"""
系统状态API端点
"""
from fastapi import APIRouter
from pydantic import BaseModel
from typing import Dict, Any

router = APIRouter()

class StatusResponse(BaseModel):
    status: str
    service: str
    version: str
    message: str

@router.get("/status", response_model=StatusResponse)
async def get_status() -> StatusResponse:
    """获取系统状态"""
    return StatusResponse(
        status="ok",
        service="IPv6 WireGuard Manager",
        version="1.0.0",
        message="IPv6 WireGuard Manager API is running"
    )

@router.get("/health")
async def health_check() -> Dict[str, Any]:
    """健康检查"""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": "2024-10-12T00:00:00Z"
    }
