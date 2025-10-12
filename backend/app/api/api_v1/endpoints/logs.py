"""
日志API端点 - 简化版本
"""
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def get_logs():
    """获取日志信息"""
    return {"message": "logs endpoint is working", "data": []}

@router.post("/")
async def create_logs(data: dict):
    """创建日志配置"""
    return {"message": "logs created successfully", "data": data}