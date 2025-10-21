"""
IPv6 WireGuard Manager 主应用
使用延迟导入避免循环依赖
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import time
import logging
import json
import importlib

# 核心导入 - 这些是必需的，不会造成循环依赖
from .core.unified_config import settings
from .core.logging import setup_logging, get_logger

# 延迟导入函数
def lazy_import(module_name: str, attribute_name: str = None):
    """延迟导入模块或属性"""
    try:
        module = importlib.import_module(module_name)
        if attribute_name:
            return getattr(module, attribute_name)
        return module
    except ImportError as e:
        logging.warning(f"延迟导入失败 {module_name}: {e}")
        return None

# 延迟导入的模块
def get_database_module():
    """获取数据库模块"""
    return lazy_import('.core.database', 'init_db'), lazy_import('.core.database', 'close_db')

def get_api_router():
    """获取API路由"""
    return lazy_import('.api.api_v1.api', 'api_router')

def get_monitoring_modules():
    """获取监控模块"""
    return (
        lazy_import('.core.application_monitoring', 'PrometheusMetrics'),
        lazy_import('.core.application_monitoring', 'ApplicationMonitor'),
        lazy_import('.core.application_monitoring', 'HealthChecker')
    )

def get_log_aggregation():
    """获取日志聚合模块"""
    return lazy_import('.core.log_aggregation', 'LogAggregator')

def get_alert_system():
    """获取告警系统模块"""
    return (
        lazy_import('.core.alert_system', 'AlertManager'),
        lazy_import('.core.alert_system', 'NotificationManager')
    )

def get_api_security():
    """获取API安全模块"""
    return (
        lazy_import('.core.api_security', 'APISecurityManager'),
        lazy_import('.core.api_security', 'RateLimitConfig'),
        lazy_import('.core.api_security', 'SecurityConfig')
    )

def get_response_compression():
    """获取响应压缩模块"""
    return (
        lazy_import('.core.response_compression', 'CompressionMiddleware'),
        lazy_import('.core.response_compression', 'DEFAULT_COMPRESSION_CONFIG')
    )

def get_api_enhancement():
    """获取API增强模块"""
    return (
        lazy_import('.core.api_enhancement', 'path_validator'),
        lazy_import('.core.api_enhancement', 'doc_generator'),
        lazy_import('.core.api_enhancement', 'cache_manager'),
        lazy_import('.core.api_enhancement', 'api_endpoint'),
        lazy_import('.core.api_enhancement', 'HTTPMethod')
    )

def get_path_manager():
    """获取路径管理模块"""
    return lazy_import('.core.path_manager', 'path_manager')

def get_api_paths():
    """获取API路径模块"""
    return (
        lazy_import('.core.api_paths', 'api_path_middleware'),
        lazy_import('.core.api_paths', 'VersionedAPIRoute')
    )

def get_api_docs():
    """获取API文档模块"""
    return lazy_import('.core.api_docs', 'setup_api_docs')

def get_database_middleware():
    """获取数据库中间件"""
    return (
        lazy_import('.core.database_middleware', 'DatabaseSessionMiddleware'),
        lazy_import('.core.database_middleware', 'DatabaseHealthMiddleware')
    )

def get_database_enhanced():
    """获取增强数据库模块"""
    return (
        lazy_import('.core.database_enhanced', 'start_database_monitoring'),
        lazy_import('.core.database_enhanced', 'stop_database_monitoring'),
        lazy_import('.core.database_enhanced', 'db_manager'),
        lazy_import('.core.database_enhanced', 'check_db_health')
    )

def get_config_management():
    """获取配置管理模块"""
    return lazy_import('.core.config_management_enhanced', 'EnhancedConfigManager')

def get_error_handling_enhanced():
    """获取增强错误处理模块"""
    return lazy_import('.core.error_handling_enhanced', 'EnhancedErrorHandler')

def get_error_handling():
    """获取错误处理模块"""
    return (
        lazy_import('.core.error_handling', 'ErrorCode'),
        lazy_import('.core.error_handling', 'APIError'),
        lazy_import('.core.error_handling', 'ValidationError'),
        lazy_import('.core.error_handling', 'AuthenticationError'),
        lazy_import('.core.error_handling', 'AuthorizationError'),
        lazy_import('.core.error_handling', 'NotFoundError'),
        lazy_import('.core.error_handling', 'ConflictError'),
        lazy_import('.core.error_handling', 'api_error_handler'),
        lazy_import('.core.error_handling', 'validation_error_handler'),
        lazy_import('.core.error_handling', 'authentication_error_handler'),
        lazy_import('.core.error_handling', 'authorization_error_handler'),
        lazy_import('.core.error_handling', 'not_found_error_handler'),
        lazy_import('.core.error_handling', 'conflict_error_handler'),
        lazy_import('.core.error_handling', 'http_exception_handler'),
        lazy_import('.core.error_handling', 'request_validation_error_handler'),
        lazy_import('.core.error_handling', 'global_exception_handler')
    )

def get_exception_monitoring():
    """获取异常监控模块"""
    return (
        lazy_import('.core.exception_monitoring', 'exception_monitor'),
        lazy_import('.core.exception_monitoring', 'ExceptionMonitor'),
        lazy_import('.core.exception_monitoring', 'AlertSeverity'),
        lazy_import('.core.exception_monitoring', 'AlertStatus')
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

# 数据库和监控实例
db_manager = None
exception_monitor = None
cache_manager = None
doc_generator = None
check_db_health = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理 - 使用延迟导入"""
    global metrics_collector, app_monitor, log_aggregator, alert_manager, security_manager, health_checker
    global config_manager, error_handler, db_manager, exception_monitor, cache_manager, doc_generator, check_db_health
    
    # 启动时执行
    logger.info("🚀 启动IPv6 WireGuard Manager...")
    
    try:
        # 获取数据库模块
        init_db_func, close_db_func = get_database_module()
        if init_db_func:
            logger.info("📊 初始化数据库连接...")
            await init_db_func()
        
        # 获取数据库增强模块
        start_monitoring, stop_monitoring, db_manager_instance, check_health = get_database_enhanced()
        if start_monitoring:
            logger.info("🔍 启动数据库监控...")
            start_monitoring()  # 这是同步函数，不需要 await
        if db_manager_instance:
            db_manager = db_manager_instance
        if check_health:
            check_db_health = check_health
        
        # 初始化配置管理器
        config_manager_class = get_config_management()
        if config_manager_class:
            logger.info("⚙️ 初始化配置管理器...")
            config_manager = config_manager_class(encrypted=True)
            if hasattr(config_manager, 'enable_hot_reload'):
                config_manager.enable_hot_reload()
            logger.info("✅ 配置管理器初始化完成")
        
        # 初始化错误处理器
        error_handler_class = get_error_handling_enhanced()
        if error_handler_class:
            logger.info("🛡️ 初始化错误处理器...")
            error_handler = error_handler_class()
            if hasattr(error_handler, 'start_monitoring'):
                error_handler.start_monitoring()
            logger.info("✅ 错误处理器初始化完成")
        
        # 初始化监控系统
        PrometheusMetrics, ApplicationMonitor, HealthChecker = get_monitoring_modules()
        if PrometheusMetrics and ApplicationMonitor and HealthChecker:
            logger.info("📈 初始化监控系统...")
            metrics_collector = PrometheusMetrics()
            app_monitor = ApplicationMonitor()
            health_checker = HealthChecker()
            logger.info("✅ 监控系统初始化完成")
        
        # 初始化日志聚合
        LogAggregator = get_log_aggregation()
        if LogAggregator:
            logger.info("📝 初始化日志聚合...")
            log_aggregator = LogAggregator()
            logger.info("✅ 日志聚合初始化完成")
        
        # 初始化告警系统
        AlertManager, NotificationManager = get_alert_system()
        if AlertManager and NotificationManager:
            logger.info("🚨 初始化告警系统...")
            alert_manager = AlertManager()
            logger.info("✅ 告警系统初始化完成")
        
        # 初始化API安全
        APISecurityManager, RateLimitConfig, SecurityConfig = get_api_security()
        if APISecurityManager and RateLimitConfig and SecurityConfig:
            logger.info("🔒 初始化API安全...")
            try:
                rate_limit_config = RateLimitConfig()
                security_config = SecurityConfig()
                security_manager = APISecurityManager(rate_limit_config, security_config)
                logger.info("✅ API安全初始化完成")
            except Exception as e:
                logger.warning(f"⚠️ API安全初始化失败，使用默认配置: {e}")
                security_manager = None
        else:
            logger.warning("⚠️ API安全模块不可用，跳过安全初始化")
            security_manager = None
        
        # 初始化异常监控
        exception_monitor_instance, ExceptionMonitor, AlertSeverity, AlertStatus = get_exception_monitoring()
        if ExceptionMonitor:
            logger.info("⚠️ 初始化异常监控...")
            exception_monitor = ExceptionMonitor()
            if hasattr(exception_monitor, 'start'):
                exception_monitor.start()
            logger.info("✅ 异常监控初始化完成")
        elif exception_monitor_instance:
            exception_monitor = exception_monitor_instance
        
        # 初始化API增强模块
        path_validator, doc_generator_instance, cache_manager_instance, api_endpoint, HTTPMethod = get_api_enhancement()
        if doc_generator_instance:
            doc_generator = doc_generator_instance
        if cache_manager_instance:
            cache_manager = cache_manager_instance
        
        logger.info("✅ 应用启动完成!")
        
    except Exception as e:
        logger.error(f"❌ 应用启动失败: {e}")
        raise
    
    yield
    
    # 关闭时执行
    logger.info("🛑 关闭IPv6 WireGuard Manager...")
    
    try:
        # 停止功能模块
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
        if exception_monitor and hasattr(exception_monitor, 'stop'):
            exception_monitor.stop()
        
        # 停止数据库监控
        start_monitoring, stop_monitoring, db_manager_instance, check_health = get_database_enhanced()
        if stop_monitoring:
            logger.info("🔍 停止数据库监控...")
            await stop_monitoring()
        
        # 关闭数据库连接
        init_db_func, close_db_func = get_database_module()
        if close_db_func:
            logger.info("📊 关闭数据库连接...")
            await close_db_func()
        
        logger.info("✅ 应用关闭完成!")
        
    except Exception as e:
        logger.error(f"❌ 应用关闭失败: {e}")

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

# 添加CORS中间件 - 强化安全配置
if settings.BACKEND_CORS_ORIGINS:
    # 生产环境使用严格的白名单，开发环境相对宽松
    allowed_origins = [str(origin) for origin in settings.BACKEND_CORS_ORIGINS]
    
    # 生产环境不允许通配符
    if not settings.DEBUG:
        allowed_origins = [origin for origin in allowed_origins if origin != "*"]
    
    app.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],  # 限制允许的方法
        allow_headers=[
            "Content-Type", 
            "Authorization", 
            "X-Requested-With",
            "Accept",
            "Origin"
        ],  # 限制允许的头部
        expose_headers=["X-Process-Time"],  # 只暴露必要的响应头
        max_age=3600,  # 预检请求缓存时间
    )

# 添加安全头中间件
@app.middleware("http")
async def add_security_headers(request, call_next):
    """添加安全头"""
    response = await call_next(request)
    
    # 安全头配置
    security_headers = {
        "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "DENY",
        "X-XSS-Protection": "1; mode=block",
        "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
        "Referrer-Policy": "strict-origin-when-cross-origin",
        "Permissions-Policy": "geolocation=(), microphone=(), camera=()"
    }
    
    # 只在 HTTPS 环境下添加 HSTS
    if request.url.scheme == "https":
        security_headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    
    for header, value in security_headers.items():
        response.headers[header] = value
    
    return response

# 使用延迟导入添加中间件和处理器
def setup_middleware_and_handlers():
    """设置中间件和异常处理器"""
    try:
        # 获取API路径中间件
        api_path_middleware_func, VersionedAPIRoute = get_api_paths()
        if api_path_middleware_func:
            app.middleware("http")(api_path_middleware_func)
        
        # 设置API文档生成
        setup_api_docs_func = get_api_docs()
        if setup_api_docs_func:
            setup_api_docs_func(app)
        
        # 添加数据库中间件
        DatabaseSessionMiddleware, DatabaseHealthMiddleware = get_database_middleware()
        if DatabaseSessionMiddleware:
            app.add_middleware(DatabaseSessionMiddleware)
        if DatabaseHealthMiddleware:
            app.add_middleware(DatabaseHealthMiddleware, check_interval=60)
        
        # 添加错误处理异常处理器
        error_handlers = get_error_handling()
        if error_handlers:
            ErrorCode, APIError, ValidationError, AuthenticationError, AuthorizationError, NotFoundError, ConflictError, api_error_handler, validation_error_handler, authentication_error_handler, authorization_error_handler, not_found_error_handler, conflict_error_handler, http_exception_handler, request_validation_error_handler, global_exception_handler = error_handlers
            
            app.add_exception_handler(APIError, api_error_handler)
            app.add_exception_handler(ValidationError, validation_error_handler)
            app.add_exception_handler(AuthenticationError, authentication_error_handler)
            app.add_exception_handler(AuthorizationError, authorization_error_handler)
            app.add_exception_handler(NotFoundError, not_found_error_handler)
            app.add_exception_handler(ConflictError, conflict_error_handler)
            app.add_exception_handler(HTTPException, http_exception_handler)
            app.add_exception_handler(RequestValidationError, request_validation_error_handler)
            app.add_exception_handler(Exception, global_exception_handler)
        
        # 添加响应压缩中间件
        CompressionMiddleware, DEFAULT_COMPRESSION_CONFIG = get_response_compression()
        if CompressionMiddleware and DEFAULT_COMPRESSION_CONFIG:
            compression_middleware = CompressionMiddleware(DEFAULT_COMPRESSION_CONFIG)
            app.middleware("http")(compression_middleware)
        
        logger.info("✅ 中间件和异常处理器设置完成")
        
    except Exception as e:
        logger.error(f"❌ 设置中间件和异常处理器失败: {e}")

# 设置中间件和处理器
setup_middleware_and_handlers()

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
        if check_db_health:
            health_status = await check_db_health()
            return {
                "success": True,
                "data": health_status
            }
        else:
            return {
                "success": False,
                "error": "Database health check function not available"
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
# 使用延迟导入注册API路由
def register_api_routes():
    """注册API路由"""
    try:
        api_router_instance = get_api_router()
        if api_router_instance:
            app.include_router(api_router_instance, prefix=settings.API_V1_STR)
            logger.info("✅ API路由注册完成")
        else:
            logger.warning("⚠️ API路由未找到，跳过注册")
    except Exception as e:
        logger.error(f"❌ API路由注册失败: {e}")

# 注册API路由
register_api_routes()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.SERVER_HOST,
        port=settings.SERVER_PORT,
        reload=settings.DEBUG,
        log_level=settings.LOG_LEVEL.lower()
    )
