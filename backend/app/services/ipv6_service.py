"""
IPv6前缀池服务：分配/释放/保留
"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import update, delete
from uuid import UUID
import ipaddress

from ..models.ipv6 import PrefixPool as PrefixPoolModel, PoolPrefix as PoolPrefixModel
from ..schemas.ipv6 import PrefixPoolCreate, PrefixPoolUpdate, PoolPrefixUpdate


class IPv6PoolService:
    def __init__(self, db: AsyncSession):
        self.db = db

    # 池管理
    async def list_pools(self) -> List[PrefixPoolModel]:
        result = await self.db.execute(select(PrefixPoolModel))
        return result.scalars().all()

    async def create_pool(self, data: PrefixPoolCreate) -> PrefixPoolModel:
        pool = PrefixPoolModel(**data.dict())
        self.db.add(pool)
        await self.db.flush()
        return pool

    async def update_pool(self, pool_id: UUID, data: PrefixPoolUpdate) -> Optional[PrefixPoolModel]:
        await self.db.execute(
            update(PrefixPoolModel)
            .where(PrefixPoolModel.id == pool_id)
            .values(**{k: v for k, v in data.dict(exclude_unset=True).items()})
        )
        await self.db.flush()
        result = await self.db.execute(select(PrefixPoolModel).where(PrefixPoolModel.id == pool_id))
        return result.scalars().first()

    async def delete_pool(self, pool_id: UUID) -> bool:
        await self.db.execute(delete(PrefixPoolModel).where(PrefixPoolModel.id == pool_id))
        await self.db.flush()
        return True

    # 分配管理
    async def list_prefixes(self, pool_id: UUID) -> List[PoolPrefixModel]:
        result = await self.db.execute(select(PoolPrefixModel).where(PoolPrefixModel.pool_id == pool_id))
        return result.scalars().all()

    async def allocate_next(self, pool_id: UUID, assigned_to_type: Optional[str] = None, assigned_to_id: Optional[str] = None, note: Optional[str] = None) -> Optional[PoolPrefixModel]:
        # 获取池信息
        result = await self.db.execute(select(PrefixPoolModel).where(PrefixPoolModel.id == pool_id))
        pool = result.scalars().first()
        if not pool:
            return None

        # 已存在前缀集合
        existing_result = await self.db.execute(select(PoolPrefixModel).where(PoolPrefixModel.pool_id == pool_id))
        existing = {p.prefix for p in existing_result.scalars().all()}

        # 遍历子网，找到第一个未使用的
        network = ipaddress.ip_network(pool.base_prefix, strict=False)
        if pool.prefix_len < network.prefixlen:
            # 要分配的子网比base前缀更大（更短的len），按base子网继续
            target_len = network.prefixlen
        else:
            target_len = pool.prefix_len

        for subnet in network.subnets(new_prefix=target_len):
            cidr = str(subnet)
            if cidr not in existing:
                record = PoolPrefixModel(
                    pool_id=pool_id,
                    prefix=cidr,
                    status="allocated",
                    assigned_to_type=assigned_to_type,
                    assigned_to_id=assigned_to_id,
                    note=note,
                )
                self.db.add(record)
                await self.db.flush()
                return record
        return None

    async def release(self, prefix_id: UUID) -> bool:
        # 将记录标记为free
        await self.db.execute(
            update(PoolPrefixModel)
            .where(PoolPrefixModel.id == prefix_id)
            .values(status="free", assigned_to_type=None, assigned_to_id=None)
        )
        await self.db.flush()
        return True

    async def reserve(self, pool_id: UUID, prefix: str, note: Optional[str] = None) -> PoolPrefixModel:
        record = PoolPrefixModel(
            pool_id=pool_id,
            prefix=prefix,
            status="reserved",
            note=note,
        )
        self.db.add(record)
        await self.db.flush()
        return record