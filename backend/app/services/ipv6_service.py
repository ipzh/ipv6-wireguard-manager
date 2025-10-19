"""
IPv6前缀池服务：分配/释放/保留
"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import update, delete
import ipaddress
import logging

from ..models.ipv6 import PrefixPool as PrefixPoolModel, PoolPrefix as PoolPrefixModel
from ..schemas.ipv6 import PrefixPoolCreate, PrefixPoolUpdate, PoolPrefixUpdate
from ..core.logging import get_logger

logger = get_logger(__name__)


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

    async def update_pool(self, pool_id: int, data: PrefixPoolUpdate) -> Optional[PrefixPoolModel]:
        await self.db.execute(
            update(PrefixPoolModel)
            .where(PrefixPoolModel.id == pool_id)
            .values(**{k: v for k, v in data.dict(exclude_unset=True).items()})
        )
        await self.db.flush()
        result = await self.db.execute(select(PrefixPoolModel).where(PrefixPoolModel.id == pool_id))
        return result.scalars().first()

    async def delete_pool(self, pool_id: int) -> bool:
        await self.db.execute(delete(PrefixPoolModel).where(PrefixPoolModel.id == pool_id))
        await self.db.flush()
        return True

    # 分配管理
    async def list_prefixes(self, pool_id: int) -> List[PoolPrefixModel]:
        result = await self.db.execute(select(PoolPrefixModel).where(PoolPrefixModel.pool_id == pool_id))
        return result.scalars().all()

    async def allocate_next(self, pool_id: int, assigned_to_type: Optional[str] = None, assigned_to_id: Optional[str] = None, note: Optional[str] = None) -> Optional[PoolPrefixModel]:
        """智能分配下一个可用的IPv6前缀"""
        try:
            # 获取池信息
            result = await self.db.execute(select(PrefixPoolModel).where(PrefixPoolModel.id == pool_id))
            pool = result.scalars().first()
            if not pool:
                return None

            # 获取已分配的前缀
            existing_result = await self.db.execute(
                select(PoolPrefixModel).where(PoolPrefixModel.pool_id == pool_id)
            )
            existing_prefixes = {p.prefix for p in existing_result.scalars().all()}

            # 解析基础前缀
            network = ipaddress.ip_network(pool.base_prefix, strict=False)
            target_len = pool.prefix_len
            
            # 如果目标长度小于基础前缀长度，使用基础前缀长度
            if target_len < network.prefixlen:
                target_len = network.prefixlen

            # 智能分配策略：优先分配连续的地址块
            allocated_subnets = []
            for prefix in existing_prefixes:
                try:
                    subnet = ipaddress.ip_network(prefix, strict=False)
                    if subnet.prefixlen == target_len:
                        allocated_subnets.append(subnet)
                except ValueError:
                    continue

            # 按网络地址排序
            allocated_subnets.sort()
            
            # 查找第一个可用的子网
            for i, subnet in enumerate(allocated_subnets):
                if i == 0:
                    # 检查第一个子网之前是否有空间
                    first_subnet = list(network.subnets(new_prefix=target_len))[0]
                    if subnet != first_subnet:
                        # 分配第一个子网
                        new_prefix = str(first_subnet)
                        break
                
                if i < len(allocated_subnets) - 1:
                    next_subnet = allocated_subnets[i + 1]
                    # 检查当前子网和下一个子网之间是否有空间
                    if next_subnet > subnet:
                        # 尝试分配下一个连续的子网
                        try:
                            next_available = list(subnet.subnets(new_prefix=target_len))[1]
                            if next_available < next_subnet:
                                new_prefix = str(next_available)
                                break
                        except ValueError:
                            continue
            else:
                # 如果所有已分配子网之间没有空间，分配最后一个子网之后的下一个
                if allocated_subnets:
                    last_subnet = allocated_subnets[-1]
                    try:
                        next_subnets = list(last_subnet.subnets(new_prefix=target_len))
                        if len(next_subnets) > 1:
                            new_prefix = str(next_subnets[1])
                        else:
                            # 尝试从整个网络中找到下一个可用的
                            new_prefix = None
                    except ValueError:
                        new_prefix = None
                else:
                    # 分配第一个子网
                    first_subnet = list(network.subnets(new_prefix=target_len))[0]
                    new_prefix = str(first_subnet)

            # 如果通过智能分配没有找到，回退到顺序分配
            if new_prefix is None:
                for subnet in network.subnets(new_prefix=target_len):
                    cidr = str(subnet)
                    if cidr not in existing_prefixes:
                        new_prefix = cidr
                        break

            if new_prefix:
                record = PoolPrefixModel(
                    pool_id=pool_id,
                    prefix=new_prefix,
                    status="allocated",
                    assigned_to_type=assigned_to_type,
                    assigned_to_id=assigned_to_id,
                    note=note,
                )
                self.db.add(record)
                await self.db.flush()
                
                # 记录分配日志
                logger.info(f"IPv6前缀分配成功: {new_prefix} -> {assigned_to_type}:{assigned_to_id}")
                
                return record
            
            return None
        except Exception as e:
            logger.error(f"IPv6前缀分配失败: {e}")
            return None

    async def release(self, prefix_id: int) -> bool:
        # 将记录标记为free
        await self.db.execute(
            update(PoolPrefixModel)
            .where(PoolPrefixModel.id == prefix_id)
            .values(status="free", assigned_to_type=None, assigned_to_id=None)
        )
        await self.db.flush()
        return True

    async def reserve(self, pool_id: int, prefix: str, note: Optional[str] = None) -> PoolPrefixModel:
        record = PoolPrefixModel(
            pool_id=pool_id,
            prefix=prefix,
            status="reserved",
            note=note,
        )
        self.db.add(record)
        await self.db.flush()
        return record