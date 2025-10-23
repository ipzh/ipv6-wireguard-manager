"""
IPv6 WireGuard Manager - 主应用入口
为了保持兼容性，此文件仅作为生产版入口(app.main_production)的瘦包装器。
"""
from .main_production import app  # noqa: F401

# 为了兼容 `uvicorn app.main:app` 的用法，保留主入口
if __name__ == "__main__":
    import uvicorn
    from .core.unified_config import settings  # 延迟导入避免循环依赖
    
    uvicorn.run(
        "app.main_production:app",
        host=settings.SERVER_HOST,
        port=settings.SERVER_PORT,
        reload=settings.DEBUG,
        log_level="info" if not settings.DEBUG else "debug"
    )
