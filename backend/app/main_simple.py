"""
简化的IPv6 WireGuard Manager主应用（用于修复启动问题）
"""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import time
import logging
import os

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# 创建FastAPI应用
app = FastAPI(
    title="IPv6 WireGuard Manager",
    version="1.0.0",
    description="现代化的企业级IPv6 WireGuard VPN管理系统",
    openapi_url="/api/v1/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
)

# 添加CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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
    try:
        # 尝试初始化数据库
        from .core.database_simple import init_db
        init_db()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        # 不退出，继续启动
    logger.info("Application started successfully")

@app.on_event("shutdown")
async def shutdown_event():
    """应用关闭事件"""
    logger.info("Shutting down IPv6 WireGuard Manager...")
    try:
        from .core.database_simple import close_db
        close_db()
    except Exception as e:
        logger.error(f"Database shutdown failed: {e}")
    logger.info("Application shutdown complete")

@app.get("/")
async def root():
    """根路径"""
    return {
        "message": "IPv6 WireGuard Manager API",
        "version": "1.0.0",
        "docs": "/docs",
        "redoc": "/redoc"
    }

@app.get("/health")
async def health_check():
    """健康检查"""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": time.time()
    }

@app.get("/api/v1/status/status")
async def get_status():
    """获取系统状态"""
    return {
        "status": "ok",
        "service": "IPv6 WireGuard Manager",
        "version": "1.0.0",
        "message": "IPv6 WireGuard Manager API is running"
    }

@app.get("/api/v1/status/health")
async def api_health_check():
    """API健康检查"""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": time.time()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main_simple:app",
        host="127.0.0.1",
        port=8000,
        reload=False,
        log_level="info"
    )
