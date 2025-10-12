"""
WireGuard API端点 - 简化版本
"""
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def get_wireguard():
    """获取WireGuard信息"""
    return {"message": "wireguard endpoint is working", "data": []}

@router.post("/")
async def create_wireguard(data: dict):
    """创建WireGuard"""
    return {"message": "wireguard created successfully", "data": data}