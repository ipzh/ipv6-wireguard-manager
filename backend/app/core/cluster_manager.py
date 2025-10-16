"""
集群管理器
实现集群部署支持，包括负载均衡、服务发现、故障转移
"""
import asyncio
import json
import time
import logging
from typing import Dict, List, Optional, Any, Set
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict
from enum import Enum
import aiohttp
import hashlib
from fastapi import HTTPException

from .config_enhanced import settings
from .performance_enhanced import performance_manager

logger = logging.getLogger(__name__)

class NodeStatus(Enum):
    """节点状态枚举"""
    HEALTHY = "healthy"
    UNHEALTHY = "unhealthy"
    MAINTENANCE = "maintenance"
    UNKNOWN = "unknown"

@dataclass
class ClusterNode:
    """集群节点信息"""
    id: str
    host: str
    port: int
    status: NodeStatus
    last_heartbeat: datetime
    load_factor: float
    capabilities: Set[str]
    metadata: Dict[str, Any]
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典"""
        return {
            "id": self.id,
            "host": self.host,
            "port": self.port,
            "status": self.status.value,
            "last_heartbeat": self.last_heartbeat.isoformat(),
            "load_factor": self.load_factor,
            "capabilities": list(self.capabilities),
            "metadata": self.metadata
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'ClusterNode':
        """从字典创建"""
        return cls(
            id=data["id"],
            host=data["host"],
            port=data["port"],
            status=NodeStatus(data["status"]),
            last_heartbeat=datetime.fromisoformat(data["last_heartbeat"]),
            load_factor=data["load_factor"],
            capabilities=set(data["capabilities"]),
            metadata=data["metadata"]
        )

class LoadBalancer:
    """负载均衡器"""
    
    def __init__(self):
        self.strategy = "round_robin"  # round_robin, least_connections, weighted
        self.node_weights: Dict[str, float] = {}
    
    def select_node(self, nodes: List[ClusterNode], strategy: str = None) -> Optional[ClusterNode]:
        """选择节点"""
        if not nodes:
            return None
        
        healthy_nodes = [node for node in nodes if node.status == NodeStatus.HEALTHY]
        if not healthy_nodes:
            return None
        
        strategy = strategy or self.strategy
        
        if strategy == "round_robin":
            return self._round_robin(healthy_nodes)
        elif strategy == "least_connections":
            return self._least_connections(healthy_nodes)
        elif strategy == "weighted":
            return self._weighted(healthy_nodes)
        else:
            return healthy_nodes[0]
    
    def _round_robin(self, nodes: List[ClusterNode]) -> ClusterNode:
        """轮询算法"""
        # 简单的轮询实现
        return nodes[0]
    
    def _least_connections(self, nodes: List[ClusterNode]) -> ClusterNode:
        """最少连接算法"""
        return min(nodes, key=lambda node: node.load_factor)
    
    def _weighted(self, nodes: List[ClusterNode]) -> ClusterNode:
        """加权算法"""
        # 根据节点权重和负载因子选择
        def weight_score(node):
            weight = self.node_weights.get(node.id, 1.0)
            return weight / (node.load_factor + 0.1)
        
        return max(nodes, key=weight_score)

class ServiceDiscovery:
    """服务发现"""
    
    def __init__(self):
        self.services: Dict[str, List[ClusterNode]] = {}
        self.service_registry: Dict[str, Dict[str, Any]] = {}
    
    def register_service(self, service_name: str, node: ClusterNode, metadata: Dict[str, Any] = None):
        """注册服务"""
        if service_name not in self.services:
            self.services[service_name] = []
        
        # 检查节点是否已存在
        existing_node = None
        for existing in self.services[service_name]:
            if existing.id == node.id:
                existing_node = existing
                break
        
        if existing_node:
            # 更新现有节点
            existing_node.status = node.status
            existing_node.last_heartbeat = node.last_heartbeat
            existing_node.load_factor = node.load_factor
            existing_node.capabilities = node.capabilities
            existing_node.metadata = node.metadata
        else:
            # 添加新节点
            self.services[service_name].append(node)
        
        # 更新服务注册表
        self.service_registry[service_name] = {
            "nodes": [n.to_dict() for n in self.services[service_name]],
            "metadata": metadata or {},
            "last_updated": datetime.utcnow().isoformat()
        }
        
        logger.info(f"Service {service_name} registered with node {node.id}")
    
    def discover_service(self, service_name: str) -> List[ClusterNode]:
        """发现服务"""
        return self.services.get(service_name, [])
    
    def get_healthy_nodes(self, service_name: str) -> List[ClusterNode]:
        """获取健康的节点"""
        nodes = self.discover_service(service_name)
        return [node for node in nodes if node.status == NodeStatus.HEALTHY]
    
    def unregister_service(self, service_name: str, node_id: str):
        """注销服务"""
        if service_name in self.services:
            self.services[service_name] = [
                node for node in self.services[service_name] 
                if node.id != node_id
            ]
            
            # 更新服务注册表
            if self.services[service_name]:
                self.service_registry[service_name] = {
                    "nodes": [n.to_dict() for n in self.services[service_name]],
                    "metadata": self.service_registry.get(service_name, {}).get("metadata", {}),
                    "last_updated": datetime.utcnow().isoformat()
                }
            else:
                del self.service_registry[service_name]
            
            logger.info(f"Service {service_name} unregistered for node {node_id}")

class HealthChecker:
    """健康检查器"""
    
    def __init__(self):
        self.check_interval = 30  # 秒
        self.timeout = 10  # 秒
        self.failure_threshold = 3
        self.node_failures: Dict[str, int] = {}
    
    async def check_node_health(self, node: ClusterNode) -> bool:
        """检查节点健康状态"""
        try:
            url = f"http://{node.host}:{node.port}/health"
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=self.timeout)) as session:
                async with session.get(url) as response:
                    if response.status == 200:
                        data = await response.json()
                        return data.get("status") == "healthy"
                    return False
        except Exception as e:
            logger.warning(f"Health check failed for node {node.id}: {e}")
            return False
    
    async def check_all_nodes(self, nodes: List[ClusterNode]) -> Dict[str, bool]:
        """检查所有节点健康状态"""
        tasks = []
        for node in nodes:
            task = asyncio.create_task(self.check_node_health(node))
            tasks.append((node.id, task))
        
        results = {}
        for node_id, task in tasks:
            try:
                results[node_id] = await task
            except Exception as e:
                logger.error(f"Health check error for node {node_id}: {e}")
                results[node_id] = False
        
        return results
    
    def update_node_status(self, node: ClusterNode, is_healthy: bool):
        """更新节点状态"""
        if is_healthy:
            self.node_failures[node.id] = 0
            if node.status != NodeStatus.HEALTHY:
                node.status = NodeStatus.HEALTHY
                logger.info(f"Node {node.id} is now healthy")
        else:
            self.node_failures[node.id] = self.node_failures.get(node.id, 0) + 1
            if self.node_failures[node.id] >= self.failure_threshold:
                if node.status != NodeStatus.UNHEALTHY:
                    node.status = NodeStatus.UNHEALTHY
                    logger.warning(f"Node {node.id} is now unhealthy")

class ClusterManager:
    """集群管理器"""
    
    def __init__(self):
        self.nodes: Dict[str, ClusterNode] = {}
        self.load_balancer = LoadBalancer()
        self.service_discovery = ServiceDiscovery()
        self.health_checker = HealthChecker()
        self.current_node_id = self._generate_node_id()
        self.is_leader = False
        self.leader_election_interval = 60  # 秒
        self.last_leader_election = 0
        
    def _generate_node_id(self) -> str:
        """生成节点ID"""
        hostname = settings.SERVER_HOST
        port = settings.SERVER_PORT
        timestamp = str(int(time.time()))
        return hashlib.md5(f"{hostname}:{port}:{timestamp}".encode()).hexdigest()[:8]
    
    def register_current_node(self, capabilities: Set[str] = None, metadata: Dict[str, Any] = None):
        """注册当前节点"""
        node = ClusterNode(
            id=self.current_node_id,
            host=settings.SERVER_HOST,
            port=settings.SERVER_PORT,
            status=NodeStatus.HEALTHY,
            last_heartbeat=datetime.utcnow(),
            load_factor=0.0,
            capabilities=capabilities or set(),
            metadata=metadata or {}
        )
        
        self.nodes[self.current_node_id] = node
        self.service_discovery.register_service("ipv6-wireguard-manager", node, metadata)
        
        logger.info(f"Current node {self.current_node_id} registered")
    
    def add_node(self, node: ClusterNode):
        """添加节点"""
        self.nodes[node.id] = node
        self.service_discovery.register_service("ipv6-wireguard-manager", node)
        logger.info(f"Node {node.id} added to cluster")
    
    def remove_node(self, node_id: str):
        """移除节点"""
        if node_id in self.nodes:
            del self.nodes[node_id]
            self.service_discovery.unregister_service("ipv6-wireguard-manager", node_id)
            logger.info(f"Node {node_id} removed from cluster")
    
    def get_node(self, node_id: str) -> Optional[ClusterNode]:
        """获取节点"""
        return self.nodes.get(node_id)
    
    def get_all_nodes(self) -> List[ClusterNode]:
        """获取所有节点"""
        return list(self.nodes.values())
    
    def get_healthy_nodes(self) -> List[ClusterNode]:
        """获取健康节点"""
        return [node for node in self.nodes.values() if node.status == NodeStatus.HEALTHY]
    
    def select_node_for_request(self, strategy: str = None) -> Optional[ClusterNode]:
        """为请求选择节点"""
        healthy_nodes = self.get_healthy_nodes()
        return self.load_balancer.select_node(healthy_nodes, strategy)
    
    async def perform_health_checks(self):
        """执行健康检查"""
        nodes = self.get_all_nodes()
        if not nodes:
            return
        
        health_results = await self.health_checker.check_all_nodes(nodes)
        
        for node in nodes:
            is_healthy = health_results.get(node.id, False)
            self.health_checker.update_node_status(node, is_healthy)
            
            # 更新心跳时间
            if is_healthy:
                node.last_heartbeat = datetime.utcnow()
    
    async def elect_leader(self):
        """选举领导者"""
        current_time = time.time()
        if current_time - self.last_leader_election < self.leader_election_interval:
            return
        
        self.last_leader_election = current_time
        
        healthy_nodes = self.get_healthy_nodes()
        if not healthy_nodes:
            self.is_leader = False
            return
        
        # 简单的领导者选举：选择ID最小的健康节点
        leader_node = min(healthy_nodes, key=lambda node: node.id)
        
        if leader_node.id == self.current_node_id:
            if not self.is_leader:
                self.is_leader = True
                logger.info(f"Node {self.current_node_id} elected as leader")
        else:
            if self.is_leader:
                self.is_leader = False
                logger.info(f"Node {self.current_node_id} is no longer leader")
    
    async def start_cluster_services(self):
        """启动集群服务"""
        # 注册当前节点
        self.register_current_node(
            capabilities={"api", "database", "cache"},
            metadata={
                "version": settings.APP_VERSION,
                "environment": settings.ENVIRONMENT,
                "started_at": datetime.utcnow().isoformat()
            }
        )
        
        # 启动后台任务
        asyncio.create_task(self._health_check_loop())
        asyncio.create_task(self._leader_election_loop())
        
        logger.info("Cluster services started")
    
    async def _health_check_loop(self):
        """健康检查循环"""
        while True:
            try:
                await self.perform_health_checks()
                await asyncio.sleep(self.health_checker.check_interval)
            except Exception as e:
                logger.error(f"Health check loop error: {e}")
                await asyncio.sleep(5)
    
    async def _leader_election_loop(self):
        """领导者选举循环"""
        while True:
            try:
                await self.elect_leader()
                await asyncio.sleep(self.leader_election_interval)
            except Exception as e:
                logger.error(f"Leader election loop error: {e}")
                await asyncio.sleep(5)
    
    def get_cluster_status(self) -> Dict[str, Any]:
        """获取集群状态"""
        nodes = self.get_all_nodes()
        healthy_nodes = self.get_healthy_nodes()
        
        return {
            "current_node_id": self.current_node_id,
            "is_leader": self.is_leader,
            "total_nodes": len(nodes),
            "healthy_nodes": len(healthy_nodes),
            "nodes": [node.to_dict() for node in nodes],
            "services": self.service_discovery.service_registry,
            "load_balancer": {
                "strategy": self.load_balancer.strategy,
                "node_weights": self.load_balancer.node_weights
            }
        }
    
    async def distribute_task(self, task_type: str, task_data: Dict[str, Any]) -> bool:
        """分发任务到集群节点"""
        if not self.is_leader:
            return False
        
        # 选择最适合的节点执行任务
        target_node = self.select_node_for_request("least_connections")
        if not target_node:
            return False
        
        try:
            # 这里应该实现实际的任务分发逻辑
            # 例如通过HTTP API调用目标节点
            logger.info(f"Distributing task {task_type} to node {target_node.id}")
            return True
        except Exception as e:
            logger.error(f"Failed to distribute task: {e}")
            return False
    
    async def sync_data(self, data_type: str, data: Any) -> bool:
        """同步数据到集群节点"""
        if not self.is_leader:
            return False
        
        healthy_nodes = self.get_healthy_nodes()
        if len(healthy_nodes) <= 1:
            return True
        
        # 同步数据到其他节点
        sync_tasks = []
        for node in healthy_nodes:
            if node.id != self.current_node_id:
                task = asyncio.create_task(self._sync_to_node(node, data_type, data))
                sync_tasks.append(task)
        
        if sync_tasks:
            results = await asyncio.gather(*sync_tasks, return_exceptions=True)
            success_count = sum(1 for result in results if result is True)
            logger.info(f"Data sync completed: {success_count}/{len(sync_tasks)} nodes")
            return success_count > 0
        
        return True
    
    async def _sync_to_node(self, node: ClusterNode, data_type: str, data: Any) -> bool:
        """同步数据到指定节点"""
        try:
            url = f"http://{node.host}:{node.port}/api/v1/cluster/sync"
            payload = {
                "data_type": data_type,
                "data": data,
                "source_node": self.current_node_id
            }
            
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=30)) as session:
                async with session.post(url, json=payload) as response:
                    return response.status == 200
        except Exception as e:
            logger.error(f"Failed to sync to node {node.id}: {e}")
            return False

# 创建全局集群管理器实例
cluster_manager = ClusterManager()

# 装饰器
def cluster_aware(func):
    """集群感知装饰器"""
    @wraps(func)
    async def wrapper(*args, **kwargs):
        # 检查是否应该由当前节点处理
        if cluster_manager.is_leader or len(cluster_manager.get_healthy_nodes()) <= 1:
            return await func(*args, **kwargs)
        else:
            # 转发到领导者节点
            leader_node = cluster_manager.select_node_for_request("round_robin")
            if leader_node:
                # 这里应该实现实际的请求转发逻辑
                logger.info(f"Forwarding request to leader node {leader_node.id}")
                return {"message": "Request forwarded to leader"}
            else:
                raise HTTPException(status_code=503, detail="No leader available")
    return wrapper

def leader_only(func):
    """仅领导者装饰器"""
    @wraps(func)
    async def wrapper(*args, **kwargs):
        if not cluster_manager.is_leader:
            raise HTTPException(status_code=403, detail="Only leader can perform this action")
        return await func(*args, **kwargs)
    return wrapper

# 导出
__all__ = [
    "ClusterManager",
    "ClusterNode",
    "NodeStatus",
    "LoadBalancer",
    "ServiceDiscovery",
    "HealthChecker",
    "cluster_manager",
    "cluster_aware",
    "leader_only"
]
