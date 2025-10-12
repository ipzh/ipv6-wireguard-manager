"""
网络管理API端点 - 简化版本
"""
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def get_network():
    """获取网络信息"""
    return {"message": "network endpoint is working", "data": []}

@router.post("/")
async def create_network(data: dict):
    """创建网络配置"""
    return {"message": "network created successfully", "data": data}