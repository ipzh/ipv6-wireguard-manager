"""
BGP管理API端点 - 简化版本
"""
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def get_bgp():
    """获取BGP信息"""
    return {"message": "bgp endpoint is working", "data": []}

@router.post("/")
async def create_bgp(data: dict):
    """创建BGP配置"""
    return {"message": "bgp created successfully", "data": data}