"""
监控API端点 - 简化版本
"""
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def get_monitoring():
    """获取监控信息"""
    return {"message": "monitoring endpoint is working", "data": []}

@router.post("/")
async def create_monitoring(data: dict):
    """创建监控配置"""
    return {"message": "monitoring created successfully", "data": data}