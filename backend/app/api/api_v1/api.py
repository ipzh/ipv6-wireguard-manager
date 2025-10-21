"""
API v1 路由聚合
简化版API路由管理
"""
from fastapi import APIRouter
import logging
import importlib

# 创建API路由器
api_router = APIRouter()

# 路由配置映射
ROUTE_CONFIGS = [
    {
        "module": ".endpoints.auth",
        "router_attr": "router",
        "prefix": "/auth",
        "tags": ['认证'],
        "description": "auth相关接口"
    },
    {
        "module": ".endpoints.users",
        "router_attr": "router",
        "prefix": "/users",
        "tags": ['用户管理'],
        "description": "users相关接口"
    },
    {
        "module": ".endpoints.wireguard",
        "router_attr": "router",
        "prefix": "/wireguard",
        "tags": ['WireGuard管理'],
        "description": "wireguard相关接口"
    },
    {
        "module": ".endpoints.network",
        "router_attr": "router",
        "prefix": "/network",
        "tags": ['网络管理'],
        "description": "network相关接口"
    },
    {
        "module": ".endpoints.monitoring",
        "router_attr": "router",
        "prefix": "/monitoring",
        "tags": ['监控'],
        "description": "monitoring相关接口"
    },
    {
        "module": ".endpoints.logs",
        "router_attr": "router",
        "prefix": "/logs",
        "tags": ['日志'],
        "description": "logs相关接口"
    },
    {
        "module": ".endpoints.system",
        "router_attr": "router",
        "prefix": "/system",
        "tags": ['系统管理'],
        "description": "system相关接口"
    },
    {
        "module": ".endpoints.health",
        "router_attr": "router",
        "prefix": "",
        "tags": ['健康检查'],
        "description": "health相关接口"
    }
]

def register_routes():
    """注册所有API路由"""
    logger = logging.getLogger(__name__)
    registered_count = 0
    
    for config in ROUTE_CONFIGS:
        try:
            # 使用延迟导入
            module = importlib.import_module(config["module"], package=__package__)
            router = getattr(module, config["router_attr"])
            
            # 注册路由
            api_router.include_router(
                router,
                prefix=config["prefix"],
                tags=config["tags"]
            )
            
            registered_count += 1
            logger.info(f"✅ 成功注册路由: {config['prefix']} - {config['description']}")
            
        except ImportError as e:
            logger.warning(f"⚠️ 模块导入失败 {config['module']}: {e}")
        except AttributeError as e:
            logger.warning(f"⚠️ 路由器属性未找到 {config['module']}.{config['router_attr']}: {e}")
        except Exception as e:
            logger.error(f"❌ 注册路由失败 {config['prefix']}: {e}")
    
    logger.info(f"📊 路由注册完成: {registered_count}/{len(ROUTE_CONFIGS)} 个模块成功注册")

# 注册所有路由
register_routes()
