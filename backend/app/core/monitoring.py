"""
监控系统集成
集成Prometheus监控，提供系统指标收集
"""

import time
import logging
from typing import Dict, Any, Optional
from prometheus_client import Counter, Histogram, Gauge, Info, CollectorRegistry, generate_latest
from fastapi import Request, Response
from fastapi.responses import PlainTextResponse

logger = logging.getLogger(__name__)

# 创建Prometheus注册表
registry = CollectorRegistry()

# 定义指标
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status'],
    registry=registry
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint'],
    registry=registry
)

active_connections = Gauge(
    'active_connections',
    'Number of active connections',
    registry=registry
)

wireguard_peers_connected = Gauge(
    'wireguard_peers_connected',
    'Number of connected WireGuard peers',
    registry=registry
)

database_connections = Gauge(
    'database_connections',
    'Number of database connections',
    registry=registry
)

system_info = Info(
    'system_info',
    'System information',
    registry=registry
)

# 设置系统信息
system_info.info({
    'version': '3.1.0',
    'service': 'ipv6-wireguard-manager',
    'environment': 'production'
})

class MonitoringManager:
    """监控管理器"""
    
    def __init__(self):
        self.start_time = time.time()
        self.request_count = 0
        self.error_count = 0
    
    def record_request(self, method: str, endpoint: str, status_code: int, duration: float):
        """记录HTTP请求"""
        http_requests_total.labels(
            method=method,
            endpoint=endpoint,
            status=status_code
        ).inc()
        
        http_request_duration_seconds.labels(
            method=method,
            endpoint=endpoint
        ).observe(duration)
        
        self.request_count += 1
        if status_code >= 400:
            self.error_count += 1
    
    def update_wireguard_peers(self, count: int):
        """更新WireGuard连接数"""
        wireguard_peers_connected.set(count)
    
    def update_database_connections(self, count: int):
        """更新数据库连接数"""
        database_connections.set(count)
    
    def update_active_connections(self, count: int):
        """更新活跃连接数"""
        active_connections.set(count)
    
    def get_metrics(self) -> str:
        """获取Prometheus指标"""
        return generate_latest(registry).decode('utf-8')
    
    def get_health_status(self) -> Dict[str, Any]:
        """获取健康状态"""
        uptime = time.time() - self.start_time
        error_rate = (self.error_count / self.request_count * 100) if self.request_count > 0 else 0
        
        return {
            'status': 'healthy',
            'uptime': uptime,
            'request_count': self.request_count,
            'error_count': self.error_count,
            'error_rate': error_rate,
            'timestamp': time.time()
        }

# 创建全局监控管理器
monitoring_manager = MonitoringManager()

def setup_monitoring_middleware(app):
    """设置监控中间件"""
    
    @app.middleware("http")
    async def monitoring_middleware(request: Request, call_next):
        """监控中间件"""
        start_time = time.time()
        
        # 处理请求
        response = await call_next(request)
        
        # 计算处理时间
        duration = time.time() - start_time
        
        # 记录指标
        method = request.method
        endpoint = request.url.path
        status_code = response.status_code
        
        monitoring_manager.record_request(method, endpoint, status_code, duration)
        
        return response
    
    @app.get("/metrics")
    async def metrics():
        """Prometheus指标端点"""
        return PlainTextResponse(
            monitoring_manager.get_metrics(),
            media_type="text/plain"
        )
    
    @app.get("/health/detailed")
    async def detailed_health():
        """详细健康检查"""
        return monitoring_manager.get_health_status()

def update_wireguard_metrics(peer_count: int):
    """更新WireGuard指标"""
    monitoring_manager.update_wireguard_peers(peer_count)

def update_database_metrics(connection_count: int):
    """更新数据库指标"""
    monitoring_manager.update_database_connections(connection_count)

def update_connection_metrics(connection_count: int):
    """更新连接指标"""
    monitoring_manager.update_active_connections(connection_count)
