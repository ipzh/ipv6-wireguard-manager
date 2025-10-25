"""
IPv6前缀池与分配Schema
"""
from typing import Optional, List
from pydantic import BaseModel


class IPv6PrefixPoolBase(BaseModel):
    name: str
    base_prefix: str
    prefix_len: int
    description: Optional[str] = None
    enabled: bool = True


class PrefixPoolBase(IPv6PrefixPoolBase):
    """向后兼容的别名"""
    pass


class IPv6PrefixPoolCreate(IPv6PrefixPoolBase):
    pass


class IPv6PrefixPoolUpdate(BaseModel):
    name: Optional[str] = None
    base_prefix: Optional[str] = None
    prefix_len: Optional[int] = None
    description: Optional[str] = None
    enabled: Optional[bool] = None


class IPv6PrefixPool(IPv6PrefixPoolBase):
    id: int

    class Config:
        from_attributes = True


# 向后兼容的别名
PrefixPoolCreate = IPv6PrefixPoolCreate
PrefixPoolUpdate = IPv6PrefixPoolUpdate
PrefixPool = IPv6PrefixPool


class PoolPrefixBase(BaseModel):
    prefix: str
    status: str = "free"
    assigned_to_type: Optional[str] = None
    assigned_to_id: Optional[str] = None
    note: Optional[str] = None
    pool_id: int


class PoolPrefixCreate(BaseModel):
    pool_id: int
    assigned_to_type: Optional[str] = None
    assigned_to_id: Optional[str] = None
    note: Optional[str] = None


class PoolPrefixUpdate(BaseModel):
    status: Optional[str] = None
    assigned_to_type: Optional[str] = None
    assigned_to_id: Optional[str] = None
    note: Optional[str] = None


class PoolPrefix(PoolPrefixBase):
    id: int

    class Config:
        from_attributes = True


class PrefixPoolList(BaseModel):
    pools: List[PrefixPool]


class PoolPrefixList(BaseModel):
    prefixes: List[PoolPrefix]


class IPv6AllocationBase(BaseModel):
    """IPv6分配基础模型"""
    prefix: str
    pool_id: int
    client_id: Optional[str] = None
    server_id: Optional[str] = None
    is_active: bool = True
    note: Optional[str] = None


class IPv6AllocationCreate(BaseModel):
    """创建IPv6分配"""
    pool_id: int
    client_id: Optional[str] = None
    server_id: Optional[str] = None
    note: Optional[str] = None


class IPv6AllocationUpdate(BaseModel):
    """更新IPv6分配"""
    is_active: Optional[bool] = None
    note: Optional[str] = None


class IPv6Allocation(IPv6AllocationBase):
    """IPv6分配完整模型"""
    id: int
    created_at: str
    updated_at: str

    class Config:
        from_attributes = True


class IPv6AllocationList(BaseModel):
    """IPv6分配列表"""
    allocations: List[IPv6Allocation]