"""
WebSocket API端点 - 简化版本
"""
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def get_websocket():
    """获取WebSocket信息"""
    return {"message": "websocket endpoint is working", "data": []}

@router.post("/")
async def create_websocket(data: dict):
    """创建WebSocket配置"""
    return {"message": "websocket created successfully", "data": data}