# 应用监控模块

import time
import psutil
import asyncio
import logging
from typing import Dict, List, Any, Optional, Callable
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
from enum import Enum
import json
import threading
from collections import defaultdict, deque
import prometheus_client
from prometheus_client import Counter, Histogram, Gauge, Summary, CollectorRegistry

class MetricType(Enum):
    """指标类型"""
    COUNTER = "counter"
    GAUGE = "gauge"
    HISTOGRAM = "histogram"
    SUMMARY = "summary"

@dataclass
class MetricData:
    """指标数据"""
    name: str
    value: float
    labels: Dict[str, str]
    timestamp: datetime
    metric_type: MetricType

class PrometheusMetrics:
    """Prometheus指标收集器"""
    
    def __init__(self):
        self.registry = CollectorRegistry()
        self.metrics = {}
        self._init_metrics()
    
    def _init_metrics(self):
        """初始化指标"""
        # HTTP请求指标
        self.metrics['http_requests_total'] = Counter(
            'http_requests_total',
            'Total HTTP requests',
            ['method', 'endpoint', 'status_code'],
            registry=self.registry
        )
        
        self.metrics['http_request_duration_seconds'] = Histogram(
            'http_request_duration_seconds',
            'HTTP request duration in seconds',
            ['method', 'endpoint'],
            registry=self.registry
        )
        
        # 系统指标
        self.metrics['system_cpu_usage_percent'] = Gauge(
            'system_cpu_usage_percent',
            'System CPU usage percentage',
            registry=self.registry
        )
        
        self.metrics['system_memory_usage_bytes'] = Gauge(
            'system_memory_usage_bytes',
            'System memory usage in bytes',
            registry=self.registry
        )
        
        self.metrics['system_disk_usage_bytes'] = Gauge(
            'system_disk_usage_bytes',
            'System disk usage in bytes',
            ['device'],
            registry=self.registry
        )
        
        # 应用指标
        self.metrics['app_active_connections'] = Gauge(
            'app_active_connections',
            'Number of active connections',
            registry=self.registry
        )
        
        self.metrics['app_database_connections'] = Gauge(
            'app_database_connections',
            'Number of database connections',
            registry=self.registry
        )
        
        self.metrics['app_cache_hits_total'] = Counter(
            'app_cache_hits_total',
            'Total cache hits',
            ['cache_type'],
            registry=self.registry
        )
        
        self.metrics['app_cache_misses_total'] = Counter(
            'app_cache_misses_total',
            'Total cache misses',
            ['cache_type'],
            registry=self.registry
        )
        
        # 业务指标
        self.metrics['wireguard_active_sessions'] = Gauge(
            'wireguard_active_sessions',
            'Number of active WireGuard sessions',
            registry=self.registry
        )
        
        self.metrics['bgp_sessions_total'] = Gauge(
            'bgp_sessions_total',
            'Total BGP sessions',
            ['state'],
            registry=self.registry
        )
        
        self.metrics['ipv6_allocations_total'] = Gauge(
            'ipv6_allocations_total',
            'Total IPv6 allocations',
            registry=self.registry
        )
    
    def record_http_request(self, method: str, endpoint: str, status_code: int, duration: float):
        """记录HTTP请求"""
        self.metrics['http_requests_total'].labels(
            method=method, endpoint=endpoint, status_code=str(status_code)
        ).inc()
        
        self.metrics['http_request_duration_seconds'].labels(
            method=method, endpoint=endpoint
        ).observe(duration)
    
    def update_system_metrics(self):
        """更新系统指标"""
        # CPU使用率
        cpu_percent = psutil.cpu_percent(interval=1)
        self.metrics['system_cpu_usage_percent'].set(cpu_percent)
        
        # 内存使用
        memory = psutil.virtual_memory()
        self.metrics['system_memory_usage_bytes'].set(memory.used)
        
        # 磁盘使用
        for partition in psutil.disk_partitions():
            try:
                usage = psutil.disk_usage(partition.mountpoint)
                self.metrics['system_disk_usage_bytes'].labels(
                    device=partition.device
                ).set(usage.used)
            except PermissionError:
                continue
    
    def update_app_metrics(self, active_connections: int, db_connections: int):
        """更新应用指标"""
        self.metrics['app_active_connections'].set(active_connections)
        self.metrics['app_database_connections'].set(db_connections)
    
    def record_cache_metrics(self, cache_type: str, hits: int, misses: int):
        """记录缓存指标"""
        self.metrics['app_cache_hits_total'].labels(cache_type=cache_type).inc(hits)
        self.metrics['app_cache_misses_total'].labels(cache_type=cache_type).inc(misses)
    
    def update_business_metrics(self, wireguard_sessions: int, bgp_sessions: Dict[str, int], 
                              ipv6_allocations: int):
        """更新业务指标"""
        self.metrics['wireguard_active_sessions'].set(wireguard_sessions)
        
        for state, count in bgp_sessions.items():
            self.metrics['bgp_sessions_total'].labels(state=state).set(count)
        
        self.metrics['ipv6_allocations_total'].set(ipv6_allocations)

class ApplicationMonitor:
    """应用监控器"""
    
    def __init__(self, metrics_collector: PrometheusMetrics):
        self.metrics = metrics_collector
        self.logger = logging.getLogger(__name__)
        self.monitoring = False
        self.monitor_thread = None
        
        # 监控数据存储
        self.metrics_history = defaultdict(lambda: deque(maxlen=1000))
        self.alerts = []
        
        # 监控配置
        self.monitor_config = {
            "cpu_threshold": 80.0,
            "memory_threshold": 85.0,
            "disk_threshold": 90.0,
            "response_time_threshold": 2.0,
            "error_rate_threshold": 5.0
        }
    
    def start_monitoring(self, interval: int = 30):
        """开始监控"""
        if self.monitoring:
            return
        
        self.monitoring = True
        self.monitor_thread = threading.Thread(target=self._monitor_loop, args=(interval,))
        self.monitor_thread.daemon = True
        self.monitor_thread.start()
        
        self.logger.info("应用监控已启动")
    
    def stop_monitoring(self):
        """停止监控"""
        self.monitoring = False
        if self.monitor_thread:
            self.monitor_thread.join()
        
        self.logger.info("应用监控已停止")
    
    def _monitor_loop(self, interval: int):
        """监控循环"""
        while self.monitoring:
            try:
                # 收集系统指标
                self._collect_system_metrics()
                
                # 收集应用指标
                self._collect_app_metrics()
                
                # 收集业务指标
                self._collect_business_metrics()
                
                # 检查告警
                self._check_alerts()
                
                time.sleep(interval)
                
            except Exception as e:
                self.logger.error(f"监控循环错误: {e}")
                time.sleep(interval)
    
    def _collect_system_metrics(self):
        """收集系统指标"""
        self.metrics.update_system_metrics()
        
        # 存储历史数据
        cpu_percent = psutil.cpu_percent()
        memory = psutil.virtual_memory()
        
        self.metrics_history['cpu'].append({
            'timestamp': datetime.now(),
            'value': cpu_percent
        })
        
        self.metrics_history['memory'].append({
            'timestamp': datetime.now(),
            'value': memory.percent
        })
    
    def _collect_app_metrics(self):
        """收集应用指标"""
        # 这里需要从应用获取实际的连接数
        # 为了示例，我们使用模拟数据
        active_connections = 50  # 从应用获取
        db_connections = 10      # 从数据库连接池获取
        
        self.metrics.update_app_metrics(active_connections, db_connections)
    
    def _collect_business_metrics(self):
        """收集业务指标"""
        # 这里需要从业务模块获取实际数据
        # 为了示例，我们使用模拟数据
        wireguard_sessions = 25
        bgp_sessions = {"established": 5, "idle": 2, "active": 3}
        ipv6_allocations = 100
        
        self.metrics.update_business_metrics(wireguard_sessions, bgp_sessions, ipv6_allocations)
    
    def _check_alerts(self):
        """检查告警"""
        # 检查CPU使用率
        if self.metrics_history['cpu']:
            latest_cpu = self.metrics_history['cpu'][-1]['value']
            if latest_cpu > self.monitor_config['cpu_threshold']:
                self._create_alert('cpu_high', f"CPU使用率过高: {latest_cpu:.1f}%")
        
        # 检查内存使用率
        if self.metrics_history['memory']:
            latest_memory = self.metrics_history['memory'][-1]['value']
            if latest_memory > self.monitor_config['memory_threshold']:
                self._create_alert('memory_high', f"内存使用率过高: {latest_memory:.1f}%")
    
    def _create_alert(self, alert_type: str, message: str):
        """创建告警"""
        alert = {
            'type': alert_type,
            'message': message,
            'timestamp': datetime.now(),
            'severity': 'warning'
        }
        
        self.alerts.append(alert)
        self.logger.warning(f"告警: {message}")
    
    def get_metrics_summary(self) -> Dict[str, Any]:
        """获取指标摘要"""
        summary = {
            'timestamp': datetime.now(),
            'system': {},
            'application': {},
            'business': {},
            'alerts': len(self.alerts)
        }
        
        # 系统指标
        if self.metrics_history['cpu']:
            summary['system']['cpu'] = self.metrics_history['cpu'][-1]['value']
        
        if self.metrics_history['memory']:
            summary['system']['memory'] = self.metrics_history['memory'][-1]['value']
        
        # 应用指标
        summary['application']['active_connections'] = 50  # 从实际数据获取
        summary['application']['database_connections'] = 10
        
        # 业务指标
        summary['business']['wireguard_sessions'] = 25
        summary['business']['bgp_sessions'] = 10
        summary['business']['ipv6_allocations'] = 100
        
        return summary
    
    def get_metrics_history(self, metric_name: str, hours: int = 24) -> List[Dict[str, Any]]:
        """获取指标历史"""
        if metric_name not in self.metrics_history:
            return []
        
        cutoff_time = datetime.now() - timedelta(hours=hours)
        return [
            data for data in self.metrics_history[metric_name]
            if data['timestamp'] > cutoff_time
        ]

class HealthChecker:
    """健康检查器"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.checks = {}
    
    def register_check(self, name: str, check_func: Callable[[], bool], 
                     timeout: int = 30, critical: bool = True):
        """注册健康检查"""
        self.checks[name] = {
            'function': check_func,
            'timeout': timeout,
            'critical': critical,
            'last_check': None,
            'last_result': None
        }
    
    async def run_checks(self) -> Dict[str, Any]:
        """运行所有健康检查"""
        results = {
            'overall_status': 'healthy',
            'checks': {},
            'timestamp': datetime.now()
        }
        
        for name, check_config in self.checks.items():
            try:
                # 运行检查
                result = await asyncio.wait_for(
                    self._run_single_check(check_config['function']),
                    timeout=check_config['timeout']
                )
                
                check_config['last_check'] = datetime.now()
                check_config['last_result'] = result
                
                results['checks'][name] = {
                    'status': 'healthy' if result else 'unhealthy',
                    'critical': check_config['critical'],
                    'last_check': check_config['last_check']
                }
                
                # 更新整体状态
                if not result and check_config['critical']:
                    results['overall_status'] = 'unhealthy'
                
            except asyncio.TimeoutError:
                self.logger.error(f"健康检查超时: {name}")
                results['checks'][name] = {
                    'status': 'timeout',
                    'critical': check_config['critical'],
                    'last_check': datetime.now()
                }
                
                if check_config['critical']:
                    results['overall_status'] = 'unhealthy'
            
            except Exception as e:
                self.logger.error(f"健康检查错误 {name}: {e}")
                results['checks'][name] = {
                    'status': 'error',
                    'critical': check_config['critical'],
                    'error': str(e),
                    'last_check': datetime.now()
                }
                
                if check_config['critical']:
                    results['overall_status'] = 'unhealthy'
        
        return results
    
    async def _run_single_check(self, check_func: Callable[[], bool]) -> bool:
        """运行单个健康检查"""
        if asyncio.iscoroutinefunction(check_func):
            return await check_func()
        else:
            return check_func()

class DatabaseHealthCheck:
    """数据库健康检查"""
    
    def __init__(self, db_session):
        self.db_session = db_session
    
    async def check_database_connection(self) -> bool:
        """检查数据库连接"""
        try:
            self.db_session.execute("SELECT 1")
            return True
        except Exception:
            return False
    
    async def check_database_performance(self) -> bool:
        """检查数据库性能"""
        try:
            start_time = time.time()
            self.db_session.execute("SELECT COUNT(*) FROM users")
            end_time = time.time()
            
            # 如果查询时间超过1秒，认为性能有问题
            return (end_time - start_time) < 1.0
        except Exception:
            return False

class RedisHealthCheck:
    """Redis健康检查"""
    
    def __init__(self, redis_client):
        self.redis_client = redis_client
    
    async def check_redis_connection(self) -> bool:
        """检查Redis连接"""
        try:
            await self.redis_client.ping()
            return True
        except Exception:
            return False
    
    async def check_redis_performance(self) -> bool:
        """检查Redis性能"""
        try:
            start_time = time.time()
            await self.redis_client.set("health_check", "ok", ex=60)
            await self.redis_client.get("health_check")
            end_time = time.time()
            
            # 如果操作时间超过100ms，认为性能有问题
            return (end_time - start_time) < 0.1
        except Exception:
            return False

class MonitoringDashboard:
    """监控仪表板"""
    
    def __init__(self, monitor: ApplicationMonitor, health_checker: HealthChecker):
        self.monitor = monitor
        self.health_checker = health_checker
        self.logger = logging.getLogger(__name__)
    
    def get_dashboard_data(self) -> Dict[str, Any]:
        """获取仪表板数据"""
        return {
            'timestamp': datetime.now(),
            'metrics_summary': self.monitor.get_metrics_summary(),
            'health_status': asyncio.run(self.health_checker.run_checks()),
            'recent_alerts': self.monitor.alerts[-10:] if self.monitor.alerts else []
        }
    
    def get_metrics_chart_data(self, metric_name: str, hours: int = 24) -> Dict[str, Any]:
        """获取指标图表数据"""
        history = self.monitor.get_metrics_history(metric_name, hours)
        
        return {
            'metric_name': metric_name,
            'data_points': [
                {
                    'timestamp': data['timestamp'].isoformat(),
                    'value': data['value']
                }
                for data in history
            ],
            'summary': {
                'min': min(data['value'] for data in history) if history else 0,
                'max': max(data['value'] for data in history) if history else 0,
                'avg': sum(data['value'] for data in history) / len(history) if history else 0
            }
        }

# 监控中间件
class MonitoringMiddleware:
    """监控中间件"""
    
    def __init__(self, metrics_collector: PrometheusMetrics):
        self.metrics = metrics_collector
    
    async def __call__(self, request, call_next):
        """中间件处理"""
        start_time = time.time()
        
        # 处理请求
        response = await call_next(request)
        
        # 计算处理时间
        duration = time.time() - start_time
        
        # 记录指标
        self.metrics.record_http_request(
            method=request.method,
            endpoint=request.url.path,
            status_code=response.status_code,
            duration=duration
        )
        
        return response

# 监控配置
MONITORING_CONFIG = {
    "prometheus": {
        "enabled": True,
        "port": 9090,
        "path": "/metrics"
    },
    "health_check": {
        "enabled": True,
        "interval": 30,
        "timeout": 30
    },
    "alerts": {
        "enabled": True,
        "cpu_threshold": 80.0,
        "memory_threshold": 85.0,
        "disk_threshold": 90.0,
        "response_time_threshold": 2.0,
        "error_rate_threshold": 5.0
    },
    "dashboard": {
        "enabled": True,
        "port": 3000,
        "refresh_interval": 30
    }
}
