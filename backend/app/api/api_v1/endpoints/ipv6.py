"""
IPv6管理API端点 - 简化版本
"""
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def get_ipv6():
    """获取IPv6信息"""
    return {"message": "ipv6 endpoint is working", "data": []}

@router.post("/")
async def create_ipv6(data: dict):
    """创建IPv6配置"""
    return {"message": "ipv6 created successfully", "data": data}