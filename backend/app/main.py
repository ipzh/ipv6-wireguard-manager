"""
IPv6 WireGuard Manager 主应用
"""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
import time
import logging

from .core.config import settings
from .core.database import init_db, close_db
from .api.api_v1.api import api_router

# 配置日志
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL.upper()),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# 创建FastAPI应用
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="现代化的企业级IPv6 WireGuard VPN管理系统",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
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

# 添加受信任主机中间件
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=[
        "*",  # 允许所有主机
        # IPv4本地访问
        "localhost",
        "127.0.0.1",
        # IPv6本地访问
        "::1",
        "[::1]",
        # 内网IPv4段
        "172.16.*",
        "172.17.*",
        "172.18.*",
        "172.19.*",
        "172.20.*",
        "172.21.*",
        "172.22.*",
        "172.23.*",
        "172.24.*",
        "172.25.*",
        "172.26.*",
        "172.27.*",
        "172.28.*",
        "172.29.*",
        "172.30.*",
        "172.31.*",
        "192.168.*",
        "10.*",
        # 内网IPv6段（常见内网IPv6）
        "fd00:*",
        "fe80:*"
    ]
)


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
    """全局异常处理器"""
    logger.error(f"Global exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "message": "内部服务器错误",
            "error_code": "INTERNAL_SERVER_ERROR"
        }
    )


@app.on_event("startup")
async def startup_event():
    """应用启动事件"""
    logger.info("Starting IPv6 WireGuard Manager...")
    
    # 使用增强的数据库初始化
    try:
        from .core.database_health import check_and_fix_database
        
        # 先检查并修复数据库问题（使用超时机制）
        logger.info("Checking database health...")
        import asyncio
        
        # 异步执行数据库检查，避免阻塞
        async def check_db():
            return check_and_fix_database()
        
        try:
            # 设置超时时间为30秒
            result = await asyncio.wait_for(asyncio.to_thread(check_db), timeout=30.0)
            if not result:
                logger.warning("Database health check found issues, continuing with initialization...")
        except asyncio.TimeoutError:
            logger.warning("Database health check timed out, continuing with initialization...")
        except Exception as e:
            logger.error(f"Database health check failed: {e}")
        
        # 初始化数据库
        await init_db()
        logger.info("Database initialization completed")
        
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        # 继续启动应用，但记录错误
        logger.warning("Application starting with database issues")
    
    logger.info("Application started successfully")


@app.on_event("shutdown")
async def shutdown_event():
    """应用关闭事件"""
    logger.info("Shutting down IPv6 WireGuard Manager...")
    await close_db()
    logger.info("Application shutdown complete")


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
