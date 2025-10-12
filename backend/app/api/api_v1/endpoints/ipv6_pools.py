"""
IPv6前缀池管理API端点 - 简化版本
"""
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def get_ipv6_pools():
    """获取IPv6前缀池信息"""
    return {"message": "ipv6_pools endpoint is working", "data": []}

@router.post("/")
async def create_ipv6_pools(data: dict):
    """创建IPv6前缀池配置"""
    return {"message": "ipv6_pools created successfully", "data": data}