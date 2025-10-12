"""
IPv6前缀池与分配Schema
"""
from typing import Optional, List
from pydantic import BaseModel
from uuid import UUID


class PrefixPoolBase(BaseModel):
    name: str
    base_prefix: str
    prefix_len: int
    description: Optional[str] = None
    enabled: bool = True


class PrefixPoolCreate(PrefixPoolBase):
    pass


class PrefixPoolUpdate(BaseModel):
    name: Optional[str] = None
    base_prefix: Optional[str] = None
    prefix_len: Optional[int] = None
    description: Optional[str] = None
    enabled: Optional[bool] = None


class PrefixPool(PrefixPoolBase):
    id: UUID

    class Config:
        from_attributes = True


class PoolPrefixBase(BaseModel):
    prefix: str
    status: str = "free"
    assigned_to_type: Optional[str] = None
    assigned_to_id: Optional[str] = None
    note: Optional[str] = None
    pool_id: UUID


class PoolPrefixCreate(BaseModel):
    pool_id: UUID
    assigned_to_type: Optional[str] = None
    assigned_to_id: Optional[str] = None
    note: Optional[str] = None


class PoolPrefixUpdate(BaseModel):
    status: Optional[str] = None
    assigned_to_type: Optional[str] = None
    assigned_to_id: Optional[str] = None
    note: Optional[str] = None


class PoolPrefix(PoolPrefixBase):
    id: UUID

    class Config:
        from_attributes = True


class PrefixPoolList(BaseModel):
    pools: List[PrefixPool]


class PoolPrefixList(BaseModel):
    prefixes: List[PoolPrefix]