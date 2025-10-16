"""
配置和备份相关模式定义
"""
from typing import Optional
from pydantic import BaseModel, Field
from datetime import datetime
import uuid


class ConfigVersionBase(BaseModel):
    """配置版本基础模式"""
    config_type: str = Field(..., max_length=50, description="配置类型")
    config_name: str = Field(..., max_length=100, description="配置名称")
    version: int = Field(..., ge=1, description="版本号")
    content: str = Field(..., description="配置内容")
    checksum: str = Field(..., max_length=64, description="校验和")


class ConfigVersion(ConfigVersionBase):
    """配置版本模式"""
    id: uuid.UUID
    is_active: bool = False
    created_by: Optional[uuid.UUID] = None
    created_at: datetime

    class Config:
        from_attributes = True


class BackupRecordBase(BaseModel):
    """备份记录基础模式"""
    backup_name: str = Field(..., max_length=100, description="备份名称")
    backup_type: str = Field(..., max_length=50, description="备份类型")
    file_path: str = Field(..., description="文件路径")
    file_size: Optional[int] = Field(None, description="文件大小")
    checksum: Optional[str] = Field(None, max_length=64, description="校验和")
    status: str = Field(..., max_length=20, description="状态")


class BackupRecord(BackupRecordBase):
    """备份记录模式"""
    id: uuid.UUID
    created_by: Optional[uuid.UUID] = None
    created_at: datetime

    class Config:
        from_attributes = True
