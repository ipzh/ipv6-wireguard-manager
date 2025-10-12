"""
BGP会话管理API端点 - 简化版本
"""
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def get_bgp_sessions():
    """获取BGP会话信息"""
    return {"message": "bgp_sessions endpoint is working", "data": []}

@router.post("/")
async def create_bgp_sessions(data: dict):
    """创建BGP会话配置"""
    return {"message": "bgp_sessions created successfully", "data": data}