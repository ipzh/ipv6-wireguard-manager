"""
IPv6 WireGuard Manager 主应用 - 生产版
完全移除不存在的模块导入，只使用已验证的功能
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import time
import logging

# 核心导入 - 只导入确实存在的模块
from .core.unified_config import settings
from .core.logging import setup_logging, get_logger
from .core.database import init_db, close_db
from .api.api_v1.api import api_router

# 设置日志
setup_logging()
logger = get_logger(__name__)

# 应用生命周期管理
@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理 - 只使用核心功能"""
    logger.info("🚀 启动IPv6 WireGuard Manager (生产版)...")
    
    # 初始化数据库
    try:
        logger.info("📊 初始化数据库连接...")
        await init_db()
        logger.info("✅ 数据库初始化完成")
    except Exception as e:
        logger.error(f"❌ 数据库初始化失败: {e}")
        raise
    
    logger.info("✅ 应用启动完成！")
    
    yield
    
    # 关闭时执行
    logger.info("🛑 关闭IPv6 WireGuard Manager...")
    try:
        await close_db()
        logger.info("✅ 数据库连接已关闭")
    except Exception as e:
        logger.error(f"❌ 数据库关闭失败: {e}")
    
    logger.info("✅ 应用关闭完成")

# 创建FastAPI应用
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="现代化的企业级IPv6 WireGuard VPN管理系统",
    openapi_url=f"/api/v1/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# 配置CORS中间件
if settings.BACKEND_CORS_ORIGINS:
    allowed_origins = [str(origin) for origin in settings.BACKEND_CORS_ORIGINS]
    
    # 生产环境不允许通配符
    if not settings.DEBUG and "*" in allowed_origins:
        logger.warning("⚠️ 生产环境不建议使用CORS通配符")
        allowed_origins = [origin for origin in allowed_origins if origin != "*"]
    
    app.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["Content-Type", "Authorization", "X-Requested-With", "Accept", "Origin"],
        expose_headers=["X-Process-Time"],
        max_age=3600,
    )

# 安全头中间件
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    """添加安全头"""
    response = await call_next(request)
    
    # 基础安全头
    security_headers = {
        "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "DENY",
        "X-XSS-Protection": "1; mode=block",
        "Referrer-Policy": "strict-origin-when-cross-origin",
    }
    
    # HTTPS环境添加HSTS
    if request.url.scheme == "https":
        security_headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    
    for header, value in security_headers.items():
        response.headers[header] = value
    
    return response

# 请求处理时间中间件
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    """添加请求处理时间"""
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    
    # 记录慢请求
    if process_time > 1.0:
        logger.warning(f"⚠️ 慢请求: {request.method} {request.url.path} - {process_time:.2f}s")
    
    return response

# 统一的API响应格式
class APIResponse:
    """统一的API响应格式"""
    @staticmethod
    def success(data=None, message="操作成功"):
        return {
            "success": True,
            "data": data,
            "message": message
        }
    
    @staticmethod
    def error(error_code="UNKNOWN_ERROR", detail="未知错误", status_code=500):
        return {
            "success": False,
            "error": error_code,
            "detail": detail,
            "status_code": status_code
        }

# 全局异常处理
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """HTTP异常处理 - 统一返回格式"""
    logger.error(f"HTTP异常: {exc.status_code} - {exc.detail} - Path: {request.url.path}")
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "error": f"HTTP_{exc.status_code}",
            "detail": exc.detail,
            "status_code": exc.status_code
        }
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """请求验证异常处理 - 统一返回格式"""
    logger.error(f"验证异常: {exc.errors()} - Path: {request.url.path}")
    return JSONResponse(
        status_code=422,
        content={
            "success": False,
            "error": "VALIDATION_ERROR",
            "detail": "请求参数验证失败",
            "errors": exc.errors()
        }
    )

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """全局异常处理 - 统一返回格式"""
    logger.error(f"未处理异常: {type(exc).__name__}: {exc} - Path: {request.url.path}", exc_info=True)
    
    # 生产环境隐藏详细错误信息
    if settings.DEBUG:
        detail = str(exc)
    else:
        detail = "服务器内部错误，请联系管理员"
    
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": "INTERNAL_ERROR",
            "detail": detail
        }
    )

# 根路径
@app.get("/")
async def root():
    """API根路径"""
    return {
        "success": True,
        "message": "IPv6 WireGuard Manager API",
        "version": settings.APP_VERSION,
        "status": "running",
        "docs": "/docs",
        "api": "/api/v1"
    }

# 健康检查端点
@app.get("/health")
async def health_check():
    """健康检查端点"""
    return {
        "status": "healthy",
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "timestamp": time.time()
    }

# 注册API路由
app.include_router(api_router, prefix="/api/v1")

# 主程序入口
if __name__ == "__main__":
    import uvicorn
    logger.info(f"🌟 启动 {settings.APP_NAME} v{settings.APP_VERSION}")
    logger.info(f"📝 API文档: http://{settings.SERVER_HOST}:{settings.SERVER_PORT}/docs")
    logger.info(f"🔗 API端点: http://{settings.SERVER_HOST}:{settings.SERVER_PORT}/api/v1")
    
    uvicorn.run(
        "app.main_production:app",
        host=settings.SERVER_HOST,
        port=settings.SERVER_PORT,
        reload=settings.DEBUG,
        log_level="info" if not settings.DEBUG else "debug"
    )
