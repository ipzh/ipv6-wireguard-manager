"""
IPv6 WireGuard Manager 主应用
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
import time
import logging

from .core.config_enhanced import settings
from .core.database import init_db, close_db
from .api.api_v1.api import api_router

# 配置日志
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL.upper()),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时执行
    logger.info("Starting IPv6 WireGuard Manager...")
    
    # 简化的数据库初始化
    try:
        await init_db()
        logger.info("Database initialization completed")
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        logger.warning("Application starting with database issues")
    
    logger.info("Application started successfully")
    
    yield
    
    # 关闭时执行
    logger.info("Shutting down IPv6 WireGuard Manager...")
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

# 禁用受信任主机中间件以支持所有主机访问
# app.add_middleware(
#     TrustedHostMiddleware,
#     allowed_hosts=["*"]  # 这会报错，所以完全禁用
# )


@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    """添加处理时间头"""
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
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
    return {
        "status": "healthy",
        "version": settings.APP_VERSION,
        "timestamp": time.time()
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
