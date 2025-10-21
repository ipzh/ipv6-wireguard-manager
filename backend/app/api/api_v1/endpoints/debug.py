"""
调试和诊断API端点
"""
import time
import psutil
import platform
import sys
from typing import Dict, Any, List
from fastapi import APIRouter, HTTPException
from datetime import datetime
from ...schemas.common import SystemInfoResponse, DatabaseStatusResponse

router = APIRouter()

@router.get("/system-info", response_model=SystemInfoResponse)
async def get_system_info() -> SystemInfoResponse:
    """获取系统信息"""
    try:
        return SystemInfoResponse(
            system={
                "platform": platform.platform(),
                "system": platform.system(),
                "release": platform.release(),
                "version": platform.version(),
                "machine": platform.machine(),
                "processor": platform.processor(),
                "python_version": sys.version,
                "python_implementation": platform.python_implementation()
            },
            hardware={
                "cpu_count": psutil.cpu_count(),
                "cpu_percent": psutil.cpu_percent(interval=1),
                "boot_time": psutil.boot_time()
            },
            memory={
                "total": psutil.virtual_memory().total,
                "available": psutil.virtual_memory().available,
                "percent": psutil.virtual_memory().percent,
                "used": psutil.virtual_memory().used,
                "free": psutil.virtual_memory().free
            },
            disk={
                "total": psutil.disk_usage('/').total,
                "used": psutil.disk_usage('/').used,
                "free": psutil.disk_usage('/').free,
                "percent": psutil.disk_usage('/').percent
            },
            network={
                "connections": len(psutil.net_connections()),
                "interfaces": list(psutil.net_if_addrs().keys())
            },
            timestamp=time.time()
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get system info: {str(e)}")

@router.get("/process-info", response_model=None)
async def get_process_info() -> Dict[str, Any]:
    """获取进程信息"""
    try:
        current_process = psutil.Process()
        return {
            "current_process": {
                "pid": current_process.pid,
                "name": current_process.name(),
                "status": current_process.status(),
                "create_time": current_process.create_time(),
                "cpu_percent": current_process.cpu_percent(),
                "memory_info": current_process.memory_info()._asdict(),
                "num_threads": current_process.num_threads(),
                "connections": len(current_process.connections())
            },
            "all_processes": {
                "total": len(psutil.pids()),
                "running": len([p for p in psutil.process_iter(['status']) if p.info['status'] == 'running'])
            },
            "timestamp": time.time()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get process info: {str(e)}")

@router.get("/network-info", response_model=None)
async def get_network_info() -> Dict[str, Any]:
    """获取网络信息"""
    try:
        return {
            "network_interfaces": {
                name: {
                    "addresses": [addr.address for addr in addrs],
                    "is_up": stats.isup,
                    "mtu": stats.mtu
                }
                for name, addrs in psutil.net_if_addrs().items()
                for stats in [psutil.net_if_stats().get(name)]
                if stats
            },
            "network_connections": {
                "total": len(psutil.net_connections()),
                "listening": len([conn for conn in psutil.net_connections() if conn.status == 'LISTEN']),
                "established": len([conn for conn in psutil.net_connections() if conn.status == 'ESTABLISHED'])
            },
            "network_io": psutil.net_io_counters()._asdict(),
            "timestamp": time.time()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get network info: {str(e)}")

@router.get("/api-status", response_model=None)
async def get_api_status() -> Dict[str, Any]:
    """获取API状态"""
    try:
        from ...main import app
        
        # 获取路由信息
        routes = []
        for route in app.routes:
            if hasattr(route, 'path') and hasattr(route, 'methods'):
                routes.append({
                    "path": route.path,
                    "methods": list(route.methods),
                    "name": getattr(route, 'name', 'unknown')
                })
        
        return {
            "api_info": {
                "title": app.title,
                "version": app.version,
                "description": app.description,
                "total_routes": len(routes),
                "routes": routes[:10]  # 只返回前10个路由
            },
            "middleware": [
                middleware.__class__.__name__ 
                for middleware in app.user_middleware
            ],
            "timestamp": time.time()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get API status: {str(e)}")

@router.get("/database-status", response_model=DatabaseStatusResponse)
async def get_database_status() -> DatabaseStatusResponse:
    """获取数据库状态"""
    try:
        from ...core.database import engine, AsyncSessionLocal, SessionLocal
        from ...core.database_manager import database_manager
        
        status = DatabaseStatusResponse(
            async_engine=database_manager.async_engine is not None,
            sync_engine=database_manager.sync_engine is not None,
            async_session=AsyncSessionLocal is not None,
            sync_session=SessionLocal is not None,
            timestamp=time.time()
        )
        
        # 尝试测试连接
        if database_manager.sync_engine:
            try:
                with database_manager.sync_engine.connect() as conn:
                    result = conn.execute("SELECT 1 as test")
                    status.connection_test = "success"
            except Exception as e:
                status.connection_test = f"failed: {str(e)}"
        
        return status
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get database status: {str(e)}")

@router.get("/comprehensive-check", response_model=None)
async def comprehensive_check() -> Dict[str, Any]:
    """综合检查"""
    try:
        results = {
            "timestamp": time.time(),
            "checks": {}
        }
        
        # 系统检查
        try:
            results["checks"]["system"] = await get_system_info()
        except Exception as e:
            results["checks"]["system"] = {"error": str(e)}
        
        # 进程检查
        try:
            results["checks"]["process"] = await get_process_info()
        except Exception as e:
            results["checks"]["process"] = {"error": str(e)}
        
        # 网络检查
        try:
            results["checks"]["network"] = await get_network_info()
        except Exception as e:
            results["checks"]["network"] = {"error": str(e)}
        
        # API检查
        try:
            results["checks"]["api"] = await get_api_status()
        except Exception as e:
            results["checks"]["api"] = {"error": str(e)}
        
        # 数据库检查
        try:
            results["checks"]["database"] = await get_database_status()
        except Exception as e:
            results["checks"]["database"] = {"error": str(e)}
        
        # 计算总体状态
        error_count = sum(1 for check in results["checks"].values() if "error" in check)
        total_checks = len(results["checks"])
        
        results["overall_status"] = {
            "healthy": error_count == 0,
            "total_checks": total_checks,
            "failed_checks": error_count,
            "success_rate": round((total_checks - error_count) / total_checks * 100, 2) if total_checks > 0 else 0
        }
        
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to perform comprehensive check: {str(e)}")

@router.get("/ping", response_model=None)
async def ping() -> Dict[str, Any]:
    """简单的ping检查"""
    return {
        "status": "pong",
        "timestamp": time.time(),
        "message": "API is responding"
    }
