"""
通用响应模式
"""
from typing import Any, Dict, List, Optional, Union
from pydantic import BaseModel, Field
from datetime import datetime

class BaseResponse(BaseModel):
    """基础响应模式"""
    success: bool = Field(default=True, description="操作是否成功")
    message: str = Field(default="操作成功", description="响应消息")
    data: Optional[Any] = Field(default=None, description="响应数据")
    timestamp: datetime = Field(default_factory=datetime.now, description="响应时间")

class ErrorResponse(BaseModel):
    """错误响应模式"""
    success: bool = Field(default=False, description="操作是否成功")
    error: str = Field(description="错误类型")
    detail: str = Field(description="错误详情")
    timestamp: datetime = Field(default_factory=datetime.now, description="响应时间")

class PaginationResponse(BaseModel):
    """分页响应模式"""
    items: List[Any] = Field(description="数据列表")
    total: int = Field(description="总数量")
    page: int = Field(description="当前页码")
    size: int = Field(description="每页大小")
    pages: int = Field(description="总页数")

class HealthCheckResponse(BaseModel):
    """健康检查响应模式"""
    status: str = Field(description="服务状态")
    service: str = Field(description="服务名称")
    version: str = Field(description="版本号")
    timestamp: float = Field(description="时间戳")
    components: Optional[Dict[str, Any]] = Field(default=None, description="组件状态")

class SystemInfoResponse(BaseModel):
    """系统信息响应模式"""
    system: Dict[str, Any] = Field(description="系统信息")
    hardware: Dict[str, Any] = Field(description="硬件信息")
    memory: Dict[str, Any] = Field(description="内存信息")
    disk: Dict[str, Any] = Field(description="磁盘信息")
    network: Dict[str, Any] = Field(description="网络信息")
    timestamp: float = Field(description="时间戳")

class DatabaseStatusResponse(BaseModel):
    """数据库状态响应模式"""
    async_engine: bool = Field(description="异步引擎状态")
    sync_engine: bool = Field(description="同步引擎状态")
    async_session: bool = Field(description="异步会话状态")
    sync_session: bool = Field(description="同步会话状态")
    timestamp: float = Field(description="时间戳")
    connection_test: Optional[str] = Field(default=None, description="连接测试结果")