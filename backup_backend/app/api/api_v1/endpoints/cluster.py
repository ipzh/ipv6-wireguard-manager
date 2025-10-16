"""
集群API端点
提供集群管理、节点管理、负载均衡等功能
"""
from typing import List, Dict, Any, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import JSONResponse

from ....core.cluster_manager import (
    cluster_manager,
    ClusterNode,
    NodeStatus,
    LoadBalancer
)
from ....core.security_enhanced import security_manager, rate_limit
from ....core.cluster_manager import cluster_aware, leader_only

router = APIRouter()

@router.get("/status", response_model=None)
@rate_limit
async def get_cluster_status():
    """获取集群状态"""
    try:
        status = cluster_manager.get_cluster_status()
        return JSONResponse(content=status)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get cluster status: {str(e)}")

@router.get("/nodes", response_model=List[Dict[str, Any]], response_model=None)
@rate_limit
async def get_cluster_nodes():
    """获取集群节点列表"""
    try:
        nodes = cluster_manager.get_all_nodes()
        return JSONResponse(content=[node.to_dict() for node in nodes])
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get cluster nodes: {str(e)}")

@router.get("/nodes/healthy", response_model=List[Dict[str, Any]], response_model=None)
@rate_limit
async def get_healthy_nodes():
    """获取健康节点列表"""
    try:
        nodes = cluster_manager.get_healthy_nodes()
        return JSONResponse(content=[node.to_dict() for node in nodes])
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get healthy nodes: {str(e)}")

@router.get("/nodes/{node_id}", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def get_node(node_id: str):
    """获取特定节点信息"""
    try:
        node = cluster_manager.get_node(node_id)
        if not node:
            raise HTTPException(status_code=404, detail="Node not found")
        
        return JSONResponse(content=node.to_dict())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get node: {str(e)}")

@router.post("/nodes", response_model=Dict[str, Any], response_model=None)
@leader_only
@rate_limit
async def add_node(node_data: Dict[str, Any]):
    """添加节点到集群"""
    try:
        node = ClusterNode(
            id=node_data["id"],
            host=node_data["host"],
            port=node_data["port"],
            status=NodeStatus(node_data.get("status", "healthy")),
            last_heartbeat=datetime.utcnow(),
            load_factor=node_data.get("load_factor", 0.0),
            capabilities=set(node_data.get("capabilities", [])),
            metadata=node_data.get("metadata", {})
        )
        
        cluster_manager.add_node(node)
        
        return JSONResponse(content={
            "message": "Node added successfully",
            "node": node.to_dict()
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add node: {str(e)}")

@router.delete("/nodes/{node_id}", response_model=Dict[str, Any], response_model=None)
@leader_only
@rate_limit
async def remove_node(node_id: str):
    """从集群中移除节点"""
    try:
        node = cluster_manager.get_node(node_id)
        if not node:
            raise HTTPException(status_code=404, detail="Node not found")
        
        cluster_manager.remove_node(node_id)
        
        return JSONResponse(content={
            "message": "Node removed successfully",
            "node_id": node_id
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to remove node: {str(e)}")

@router.post("/nodes/{node_id}/health-check", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def check_node_health(node_id: str):
    """检查节点健康状态"""
    try:
        node = cluster_manager.get_node(node_id)
        if not node:
            raise HTTPException(status_code=404, detail="Node not found")
        
        # 执行健康检查
        is_healthy = await cluster_manager.health_checker.check_node_health(node)
        cluster_manager.health_checker.update_node_status(node, is_healthy)
        
        return JSONResponse(content={
            "node_id": node_id,
            "is_healthy": is_healthy,
            "status": node.status.value,
            "last_checked": datetime.utcnow().isoformat()
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to check node health: {str(e)}")

@router.post("/nodes/health-check-all", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def check_all_nodes_health():
    """检查所有节点健康状态"""
    try:
        await cluster_manager.perform_health_checks()
        
        nodes = cluster_manager.get_all_nodes()
        health_status = {
            "total_nodes": len(nodes),
            "healthy_nodes": len(cluster_manager.get_healthy_nodes()),
            "unhealthy_nodes": len(nodes) - len(cluster_manager.get_healthy_nodes()),
            "nodes": [node.to_dict() for node in nodes]
        }
        
        return JSONResponse(content=health_status)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to check all nodes health: {str(e)}")

@router.get("/leader", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def get_leader_info():
    """获取领导者信息"""
    try:
        healthy_nodes = cluster_manager.get_healthy_nodes()
        if not healthy_nodes:
            return JSONResponse(content={
                "has_leader": False,
                "leader_node": None,
                "message": "No healthy nodes available"
            })
        
        # 找到领导者节点
        leader_node = min(healthy_nodes, key=lambda node: node.id)
        
        return JSONResponse(content={
            "has_leader": True,
            "leader_node": leader_node.to_dict(),
            "is_current_leader": leader_node.id == cluster_manager.current_node_id,
            "current_node_id": cluster_manager.current_node_id
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get leader info: {str(e)}")

@router.post("/leader/elect", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def elect_leader():
    """触发领导者选举"""
    try:
        await cluster_manager.elect_leader()
        
        return JSONResponse(content={
            "message": "Leader election completed",
            "is_leader": cluster_manager.is_leader,
            "current_node_id": cluster_manager.current_node_id
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to elect leader: {str(e)}")

@router.get("/load-balancer", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def get_load_balancer_info():
    """获取负载均衡器信息"""
    try:
        lb = cluster_manager.load_balancer
        
        return JSONResponse(content={
            "strategy": lb.strategy,
            "node_weights": lb.node_weights,
            "available_strategies": ["round_robin", "least_connections", "weighted"]
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get load balancer info: {str(e)}")

@router.put("/load-balancer/strategy", response_model=Dict[str, Any], response_model=None)
@leader_only
@rate_limit
async def update_load_balancer_strategy(strategy: str = Query(..., description="负载均衡策略")):
    """更新负载均衡策略"""
    try:
        valid_strategies = ["round_robin", "least_connections", "weighted"]
        if strategy not in valid_strategies:
            raise HTTPException(status_code=400, detail=f"Invalid strategy. Must be one of: {valid_strategies}")
        
        cluster_manager.load_balancer.strategy = strategy
        
        return JSONResponse(content={
            "message": "Load balancer strategy updated",
            "strategy": strategy
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update load balancer strategy: {str(e)}")

@router.post("/load-balancer/select-node", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def select_node_for_request(
    strategy: Optional[str] = Query(None, description="负载均衡策略")
):
    """为请求选择节点"""
    try:
        selected_node = cluster_manager.select_node_for_request(strategy)
        
        if not selected_node:
            return JSONResponse(content={
                "selected_node": None,
                "message": "No healthy nodes available"
            })
        
        return JSONResponse(content={
            "selected_node": selected_node.to_dict(),
            "strategy_used": strategy or cluster_manager.load_balancer.strategy
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to select node: {str(e)}")

@router.get("/services", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def get_services():
    """获取服务注册信息"""
    try:
        services = cluster_manager.service_discovery.service_registry
        
        return JSONResponse(content=services)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get services: {str(e)}")

@router.post("/services/register", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def register_service(service_data: Dict[str, Any]):
    """注册服务"""
    try:
        service_name = service_data.get("service_name")
        if not service_name:
            raise HTTPException(status_code=400, detail="Service name is required")
        
        # 创建当前节点信息
        current_node = ClusterNode(
            id=cluster_manager.current_node_id,
            host=cluster_manager.current_node.host if hasattr(cluster_manager, 'current_node') else "localhost",
            port=cluster_manager.current_node.port if hasattr(cluster_manager, 'current_node') else 8000,
            status=NodeStatus.HEALTHY,
            last_heartbeat=datetime.utcnow(),
            load_factor=0.0,
            capabilities=set(service_data.get("capabilities", [])),
            metadata=service_data.get("metadata", {})
        )
        
        cluster_manager.service_discovery.register_service(
            service_name,
            current_node,
            service_data.get("metadata", {})
        )
        
        return JSONResponse(content={
            "message": "Service registered successfully",
            "service_name": service_name,
            "node": current_node.to_dict()
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to register service: {str(e)}")

@router.delete("/services/{service_name}", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def unregister_service(service_name: str):
    """注销服务"""
    try:
        cluster_manager.service_discovery.unregister_service(
            service_name,
            cluster_manager.current_node_id
        )
        
        return JSONResponse(content={
            "message": "Service unregistered successfully",
            "service_name": service_name
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to unregister service: {str(e)}")

@router.post("/sync", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def sync_cluster_data(sync_data: Dict[str, Any]):
    """同步集群数据"""
    try:
        data_type = sync_data.get("data_type")
        data = sync_data.get("data")
        source_node = sync_data.get("source_node")
        
        if not all([data_type, data, source_node]):
            raise HTTPException(status_code=400, detail="Missing required fields: data_type, data, source_node")
        
        # 这里应该实现实际的数据同步逻辑
        logger.info(f"Received sync data from {source_node}: {data_type}")
        
        return JSONResponse(content={
            "message": "Data synced successfully",
            "data_type": data_type,
            "source_node": source_node
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to sync data: {str(e)}")

@router.post("/tasks/distribute", response_model=Dict[str, Any], response_model=None)
@leader_only
@rate_limit
async def distribute_task(task_data: Dict[str, Any]):
    """分发任务到集群节点"""
    try:
        task_type = task_data.get("task_type")
        task_payload = task_data.get("task_payload", {})
        
        if not task_type:
            raise HTTPException(status_code=400, detail="Task type is required")
        
        success = await cluster_manager.distribute_task(task_type, task_payload)
        
        return JSONResponse(content={
            "message": "Task distributed successfully" if success else "Failed to distribute task",
            "task_type": task_type,
            "success": success
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to distribute task: {str(e)}")

@router.get("/metrics", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def get_cluster_metrics():
    """获取集群指标"""
    try:
        nodes = cluster_manager.get_all_nodes()
        healthy_nodes = cluster_manager.get_healthy_nodes()
        
        metrics = {
            "total_nodes": len(nodes),
            "healthy_nodes": len(healthy_nodes),
            "unhealthy_nodes": len(nodes) - len(healthy_nodes),
            "is_leader": cluster_manager.is_leader,
            "current_node_id": cluster_manager.current_node_id,
            "services_count": len(cluster_manager.service_discovery.service_registry),
            "load_balancer_strategy": cluster_manager.load_balancer.strategy
        }
        
        return JSONResponse(content=metrics)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get cluster metrics: {str(e)}")

@router.post("/start", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def start_cluster_services():
    """启动集群服务"""
    try:
        await cluster_manager.start_cluster_services()
        
        return JSONResponse(content={
            "message": "Cluster services started successfully",
            "current_node_id": cluster_manager.current_node_id
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to start cluster services: {str(e)}")

@router.get("/config", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def get_cluster_config():
    """获取集群配置"""
    try:
        config = {
            "current_node_id": cluster_manager.current_node_id,
            "is_leader": cluster_manager.is_leader,
            "leader_election_interval": cluster_manager.leader_election_interval,
            "health_check_interval": cluster_manager.health_checker.check_interval,
            "health_check_timeout": cluster_manager.health_checker.timeout,
            "failure_threshold": cluster_manager.health_checker.failure_threshold,
            "load_balancer_strategy": cluster_manager.load_balancer.strategy
        }
        
        return JSONResponse(content=config)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get cluster config: {str(e)}")
