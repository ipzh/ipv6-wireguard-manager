"""
系统管理API端点 - 简化版本
"""
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def get_system():
    """获取系统信息"""
    return {"message": "system endpoint is working", "data": []}

@router.post("/")
async def create_system(data: dict):
    """创建系统配置"""
    return {"message": "system created successfully", "data": data}