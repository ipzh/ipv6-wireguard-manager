"""
IPv6 WireGuard Manager 主应用
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
import time
import logging
import json

from .core.config_enhanced import settings
from .core.database import init_db, close_db
from .api.api_v1.api import api_router

# 导入新的功能模块
from .core.application_monitoring import PrometheusMetrics, ApplicationMonitor, HealthChecker
from .core.log_aggregation import LogAggregator
from .core.alert_system import AlertManager, NotificationManager
from .core.api_security import APISecurityManager, RateLimitConfig, SecurityConfig
from .core.response_compression import CompressionMiddleware, DEFAULT_COMPRESSION_CONFIG

# 导入增强功能模块
from .core.api_enhancement import (
    path_validator, doc_generator, cache_manager,
    api_endpoint, HTTPMethod
)

# 导入API路径标准化模块
from .core.api_paths import path_manager, api_path_middleware, VersionedAPIRoute
from .core.api_config import get_api_path, get_auth_path, get_users_path, get_wireguard_path
from .core.api_docs import setup_api_docs

# 导入数据库优化模块
from .core.database_middleware import DatabaseSessionMiddleware, DatabaseHealthMiddleware
from .core.database_enhanced import (
    start_database_monitoring, stop_database_monitoring,
    db_manager, check_db_health
)
from .core.config_management_enhanced import EnhancedConfigManager
from .core.error_handling_enhanced import EnhancedErrorHandler

# 导入错误处理和日志记录机制
from .core.error_handling import (
    ErrorCode, APIError, ValidationError, AuthenticationError,
    AuthorizationError, NotFoundError, ConflictError,
    api_error_handler, validation_error_handler,
    authentication_error_handler, authorization_error_handler,
    not_found_error_handler, conflict_error_handler,
    http_exception_handler, request_validation_error_handler,
    global_exception_handler as error_global_exception_handler
)
from .core.logging import setup_logging, get_logger, StructuredFormatter, ContextFilter
from .core.exception_monitoring import (
    exception_monitor, ExceptionMonitor, AlertSeverity, AlertStatus
)

# 配置结构化日志
setup_logging()
logger = get_logger(__name__)

# 全局功能模块实例
metrics_collector = None
app_monitor = None
log_aggregator = None
alert_manager = None
security_manager = None
health_checker = None

# 增强功能模块实例
config_manager = None
error_handler = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    global metrics_collector, app_monitor, log_aggregator, alert_manager, security_manager, health_checker
    global config_manager, error_handler
    
    # 启动时执行
    logger.info("Starting IPv6 WireGuard Manager...")
    
    # 启动异常监控
    try:
        exception_monitor.start()
        logger.info("Exception monitoring started")
    except Exception as e:
        logger.error(f"Failed to start exception monitoring: {e}")
    
    # 初始化增强功能模块
    try:
        # 初始化配置管理器
        config_manager = EnhancedConfigManager(encrypted=True)
        config_manager.enable_hot_reload()
        logger.info("Enhanced config manager initialized")
        
        # 初始化错误处理器
        error_handler = EnhancedErrorHandler()
        error_handler.start_monitoring()
        logger.info("Enhanced error handler initialized")
        
        # 启动数据库监控
        start_database_monitoring()
        logger.info("Database monitoring started")
        
    except Exception as e:
        logger.error(f"Failed to initialize enhanced modules: {e}")
    
    # 简化的数据库初始化
    try:
        await init_db()
        logger.info("Database initialization completed")
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        logger.warning("Application starting with database issues")
    
    # 初始化功能模块
    try:
        # 初始化监控模块
        metrics_collector = PrometheusMetrics()
        app_monitor = ApplicationMonitor(metrics_collector)
        app_monitor.start_monitoring()
        logger.info("Application monitoring started")
        
        # 初始化日志聚合
        log_aggregator = LogAggregator()
        log_aggregator.start_processing()
        logger.info("Log aggregation started")
        
        # 初始化告警系统
        alert_manager = AlertManager()
        alert_manager.start_processing()
        logger.info("Alert system started")
        
        # 初始化安全模块
        rate_config = RateLimitConfig()
        security_config = SecurityConfig()
        security_manager = APISecurityManager(rate_config, security_config)
        logger.info("Security manager initialized")
        
        # 初始化健康检查
        health_checker = HealthChecker()
        logger.info("Health checker initialized")
        
    except Exception as e:
        logger.error(f"Feature modules initialization failed: {e}")
        logger.warning("Application starting with limited functionality")
    
    logger.info("Application started successfully")
    
    yield
    
    # 关闭时执行
    logger.info("Shutting down IPv6 WireGuard Manager...")
    
    # 停止功能模块
    try:
        if app_monitor:
            app_monitor.stop_monitoring()
        if log_aggregator:
            log_aggregator.stop_processing()
        if alert_manager:
            alert_manager.stop_processing()
        if error_handler:
            error_handler.stop_monitoring()
        if config_manager:
            config_manager.disable_hot_reload()
        
        # 停止异常监控
        exception_monitor.stop()
        
        # 停止数据库监控
        await stop_database_monitoring()
        
        logger.info("Feature modules stopped")
    except Exception as e:
        logger.error(f"Error stopping feature modules: {e}")
    
    await close_db()
    logger.info("Application shutdown complete")

# 创建FastAPI应用
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="现代化的企业级IPv6 WireGuard VPN管理系统",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# 添加CORS中间件
if settings.BACKEND_CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[str(origin) for origin in settings.BACKEND_CORS_ORIGINS],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# 添加API路径验证中间件
app.middleware("http")(api_path_middleware)

# 设置API文档生成
doc_generator = setup_api_docs(app)

# 添加数据库中间件
app.add_middleware(DatabaseSessionMiddleware)
app.add_middleware(DatabaseHealthMiddleware, check_interval=60)

# 添加错误处理异常处理器
app.add_exception_handler(APIError, api_error_handler)
app.add_exception_handler(ValidationError, validation_error_handler)
app.add_exception_handler(AuthenticationError, authentication_error_handler)
app.add_exception_handler(AuthorizationError, authorization_error_handler)
app.add_exception_handler(NotFoundError, not_found_error_handler)
app.add_exception_handler(ConflictError, conflict_error_handler)
app.add_exception_handler(HTTPException, http_exception_handler)
app.add_exception_handler(RequestValidationError, request_validation_error_handler)
app.add_exception_handler(Exception, error_global_exception_handler)

# 添加响应压缩中间件
compression_middleware = CompressionMiddleware(DEFAULT_COMPRESSION_CONFIG)
app.middleware("http")(compression_middleware)

# 禁用受信任主机中间件以支持所有主机访问
# app.add_middleware(
#     TrustedHostMiddleware,
#     allowed_hosts=["*"]  # 这会报错，所以完全禁用
# )


@app.middleware("http")
async def enhanced_request_middleware(request: Request, call_next):
    """增强的请求中间件"""
    start_time = time.time()
    
    # 安全检查
    if security_manager:
        try:
            # 获取用户ID（如果已认证）
            user_id = None
            if hasattr(request.state, 'user_id'):
                user_id = request.state.user_id
            
            # 检查速率限制
            client_ip = request.client.host if request.client else "unknown"
            rate_allowed, rate_info = security_manager.check_rate_limit(client_ip, user_id)
            
            if not rate_allowed:
                return JSONResponse(
                    status_code=429,
                    content={
                        "success": False,
                        "message": "请求过于频繁",
                        "error_code": "RATE_LIMIT_EXCEEDED",
                        "retry_after": 60
                    }
                )
            
            # 记录HTTP请求指标
            if metrics_collector:
                metrics_collector.record_http_request(
                    method=request.method,
                    endpoint=request.url.path,
                    status_code=200,  # 将在响应后更新
                    duration=0  # 将在响应后更新
                )
            
        except Exception as e:
            logger.error(f"Security middleware error: {e}")
    
    # 处理请求
    response = await call_next(request)
    
    # 计算处理时间
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    
    # 记录异常（如果有）
    if response.status_code >= 400:
        try:
            # 记录异常到监控系统
            error_code = f"HTTP_{response.status_code}"
            message = f"HTTP {response.status_code} error for {request.method} {request.url.path}"
            stack_trace = ""  # HTTP错误通常没有堆栈跟踪
            
            context = {
                "method": request.method,
                "path": request.url.path,
                "status_code": response.status_code,
                "process_time": process_time,
                "client_ip": request.client.host if request.client else "unknown",
                "user_agent": request.headers.get("user-agent", "unknown")
            }
            
            exception_monitor.record_exception(error_code, message, stack_trace, context)
        except Exception as e:
            logger.error(f"Exception monitoring error: {e}")
    
    # 添加安全头
    if security_manager:
        security_headers = security_manager.get_security_headers()
        for header, value in security_headers.items():
            response.headers[header] = value
    
    # 记录日志
    if log_aggregator:
        try:
            from .core.log_aggregation import LogEntry, LogLevel, LogSource
            log_entry = LogEntry(
                timestamp=time.time(),
                level=LogLevel.INFO,
                source=LogSource.APPLICATION,
                service="api",
                message=f"{request.method} {request.url.path} - {response.status_code}",
                context={
                    "method": request.method,
                    "path": request.url.path,
                    "status_code": response.status_code,
                    "process_time": process_time,
                    "client_ip": request.client.host if request.client else "unknown"
                }
            )
            log_aggregator.add_log(log_entry)
        except Exception as e:
            logger.error(f"Log aggregation error: {e}")
    
    return response


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """全局异常处理器 - 增强版本"""
    # 记录详细的错误信息
    error_details = {
        "error_type": type(exc).__name__,
        "error_message": str(exc),
        "request_url": str(request.url),
        "request_method": request.method,
        "client_ip": request.client.host if request.client else "unknown",
        "user_agent": request.headers.get("user-agent", "unknown"),
        "timestamp": time.time()
    }
    
    logger.error(f"Global exception occurred: {error_details}", exc_info=True)
    
    # 根据异常类型返回不同的错误信息
    if isinstance(exc, ValueError):
        status_code = 400
        message = "请求参数错误"
        error_code = "INVALID_REQUEST"
    elif isinstance(exc, PermissionError):
        status_code = 403
        message = "权限不足"
        error_code = "PERMISSION_DENIED"
    elif isinstance(exc, ConnectionError):
        status_code = 503
        message = "服务暂时不可用"
        error_code = "SERVICE_UNAVAILABLE"
    else:
        status_code = 500
        message = "内部服务器错误"
        error_code = "INTERNAL_SERVER_ERROR"
    
    return JSONResponse(
        status_code=status_code,
        content={
            "success": False,
            "message": message,
            "error_code": error_code,
            "error_id": f"ERR_{int(time.time())}",
            "timestamp": time.time()
        }
    )


# 旧的on_event处理器已被lifespan替代


@app.get("/")
async def root():
    """根路径"""
    return {
        "message": "IPv6 WireGuard Manager API",
        "version": settings.APP_VERSION,
        "docs": "/docs",
        "redoc": "/redoc"
    }


@app.get("/health")
async def health_check():
    """健康检查"""
    if health_checker:
        try:
            health_status = await health_checker.run_checks()
            return {
                "status": health_status["overall_status"],
                "version": settings.APP_VERSION,
                "timestamp": time.time(),
                "checks": health_status["checks"]
            }
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return {
                "status": "unhealthy",
                "version": settings.APP_VERSION,
                "timestamp": time.time(),
                "error": str(e)
            }
    else:
        return {
            "status": "healthy",
            "version": settings.APP_VERSION,
            "timestamp": time.time()
        }


@app.get("/metrics")
async def prometheus_metrics():
    """Prometheus指标端点"""
    if metrics_collector:
        from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
        from fastapi.responses import Response
        return Response(
            generate_latest(metrics_collector.registry),
            media_type=CONTENT_TYPE_LATEST
        )
    else:
        return {"error": "Metrics not available"}


@app.get("/monitoring/dashboard")
async def monitoring_dashboard():
    """监控仪表板数据"""
    if app_monitor:
        try:
            dashboard_data = app_monitor.get_dashboard_data()
            return {
                "success": True,
                "data": dashboard_data
            }
        except Exception as e:
            logger.error(f"Dashboard data error: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    else:
        return {
            "success": False,
            "error": "Monitoring not available"
        }


@app.get("/api/v1/docs/openapi.json")
async def get_openapi_json():
    """获取OpenAPI JSON文档"""
    if doc_generator:
        try:
            openapi_json = doc_generator.generate_openapi_json()
            return JSONResponse(content=json.loads(openapi_json))
        except Exception as e:
            logger.error(f"OpenAPI JSON generation failed: {e}")
            return {"error": "OpenAPI documentation not available"}
    else:
        return {"error": "Documentation generator not available"}


@app.get("/api/v1/docs/swagger")
async def get_swagger_ui():
    """获取Swagger UI"""
    if doc_generator:
        try:
            swagger_html = doc_generator.generate_swagger_html()
            from fastapi.responses import HTMLResponse
            return HTMLResponse(content=swagger_html)
        except Exception as e:
            logger.error(f"Swagger UI generation failed: {e}")
            return {"error": "Swagger UI not available"}
    else:
        return {"error": "Documentation generator not available"}


@app.get("/api/v1/database/health")
async def database_health():
    """数据库健康检查"""
    try:
        health_status = await check_db_health()
        return {
            "success": True,
            "data": health_status
        }
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        return {
            "success": False,
            "error": str(e)
        }


@app.get("/api/v1/database/monitoring")
async def database_monitoring():
    """数据库监控信息"""
    try:
        health_report = db_manager.get_health_report()
        return {
            "success": True,
            "data": health_report
        }
    except Exception as e:
        logger.error(f"Database monitoring failed: {e}")
        return {
            "success": False,
            "error": str(e)
        }


@app.get("/api/v1/config/summary")
async def config_summary():
    """配置摘要"""
    if config_manager:
        try:
            summary = config_manager.get_config_summary()
            return {
                "success": True,
                "data": summary
            }
        except Exception as e:
            logger.error(f"Config summary failed: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    else:
        return {
            "success": False,
            "error": "Config manager not available"
        }


@app.get("/api/v1/errors/statistics")
async def error_statistics():
    """错误统计"""
    if error_handler:
        try:
            stats = error_handler.get_error_statistics()
            return {
                "success": True,
                "data": stats
            }
        except Exception as e:
            logger.error(f"Error statistics failed: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    else:
        return {
            "success": False,
            "error": "Error handler not available"
        }


@app.get("/api/v1/cache/stats")
async def cache_statistics():
    """缓存统计"""
    try:
        stats = cache_manager.get_stats()
        return {
            "success": True,
            "data": stats
        }
    except Exception as e:
        logger.error(f"Cache statistics failed: {e}")
        return {
            "success": False,
            "error": str(e)
        }


@app.get("/api/v1/exceptions/summary")
async def exception_summary():
    """异常摘要"""
    try:
        summary = exception_monitor.get_exception_summary()
        return {
            "success": True,
            "data": summary
        }
    except Exception as e:
        logger.error(f"Exception summary failed: {e}")
        return {
            "success": False,
            "error": str(e)
        }


@app.get("/api/v1/exceptions/top")
async def top_exceptions(limit: int = 10):
    """最频繁的异常"""
    try:
        top_exceptions = exception_monitor.get_top_exceptions(limit)
        return {
            "success": True,
            "data": [
                {
                    "error_code": exc.error_code,
                    "message": exc.message,
                    "count": exc.count,
                    "first_seen": exc.first_seen.isoformat(),
                    "last_seen": exc.last_seen.isoformat(),
                    "context": exc.context
                }
                for exc in top_exceptions
            ]
        }
    except Exception as e:
        logger.error(f"Top exceptions failed: {e}")
        return {
            "success": False,
            "error": str(e)
        }


@app.get("/api/v1/exceptions/recent")
async def recent_exceptions(limit: int = 50):
    """最近的异常"""
    try:
        recent_exceptions = exception_monitor.get_recent_exceptions(limit)
        return {
            "success": True,
            "data": [
                {
                    "error_code": exc.error_code,
                    "message": exc.message,
                    "timestamp": exc.timestamp.isoformat(),
                    "context": exc.context
                }
                for exc in recent_exceptions
            ]
        }
    except Exception as e:
        logger.error(f"Recent exceptions failed: {e}")
        return {
            "success": False,
            "error": str(e)
        }


@app.get("/api/v1/alerts/active")
async def active_alerts():
    """活跃告警"""
    try:
        alerts = exception_monitor.get_active_alerts()
        return {
            "success": True,
            "data": [
                {
                    "id": alert.id,
                    "title": alert.title,
                    "description": alert.description,
                    "severity": alert.severity.value,
                    "status": alert.status.value,
                    "created_at": alert.created_at.isoformat(),
                    "metadata": alert.metadata
                }
                for alert in alerts
            ]
        }
    except Exception as e:
        logger.error(f"Active alerts failed: {e}")
        return {
            "success": False,
            "error": str(e)
        }


@app.post("/api/v1/alerts/{alert_id}/acknowledge")
async def acknowledge_alert(alert_id: str):
    """确认告警"""
    try:
        success = exception_monitor.acknowledge_alert(alert_id)
        if success:
            return {
                "success": True,
                "message": "告警已确认"
            }
        else:
            return {
                "success": False,
                "error": "告警不存在或状态不正确"
            }
    except Exception as e:
        logger.error(f"Acknowledge alert failed: {e}")
        return {
            "success": False,
            "error": str(e)
        }


@app.post("/api/v1/alerts/{alert_id}/resolve")
async def resolve_alert(alert_id: str):
    """解决告警"""
    try:
        success = exception_monitor.resolve_alert(alert_id)
        if success:
            return {
                "success": True,
                "message": "告警已解决"
            }
        else:
            return {
                "success": False,
                "error": "告警不存在或状态不正确"
            }
    except Exception as e:
        logger.error(f"Resolve alert failed: {e}")
        return {
            "success": False,
            "error": str(e)
        }


# 包含API路由
app.include_router(api_router, prefix=settings.API_V1_STR)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.SERVER_HOST,
        port=settings.SERVER_PORT,
        reload=settings.DEBUG,
        log_level=settings.LOG_LEVEL.lower()
    )
