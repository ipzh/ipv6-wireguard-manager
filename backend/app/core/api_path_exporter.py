"""
统一的API路径导出器
从后端导出机器可读的路径清单，供前端使用
"""
import json
from typing import Dict, List, Any
from fastapi import APIRouter
from fastapi.routing import APIRoute
from .unified_config import settings

class APIPathExporter:
    """API路径导出器"""
    
    def __init__(self, app_router: APIRouter):
        self.app_router = app_router
        self.api_version = "v1"
        self.base_url = f"/api/{self.api_version}"
    
    def export_paths(self) -> Dict[str, Any]:
        """导出所有API路径"""
        paths = {
            "version": self.api_version,
            "base_url": self.base_url,
            "endpoints": {}
        }
        
        # 遍历所有路由
        for route in self.app_router.routes:
            if isinstance(route, APIRoute):
                endpoint_info = {
                    "path": route.path,
                    "methods": list(route.methods),
                    "name": route.name,
                    "summary": getattr(route, 'summary', ''),
                    "description": getattr(route, 'description', ''),
                    "tags": getattr(route, 'tags', [])
                }
                
                # 按标签分组
                for tag in endpoint_info["tags"]:
                    if tag not in paths["endpoints"]:
                        paths["endpoints"][tag] = []
                    paths["endpoints"][tag].append(endpoint_info)
        
        return paths
    
    def export_for_php(self) -> str:
        """导出PHP格式的路径配置"""
        paths = self.export_paths()
        
        php_config = f"""<?php
/**
 * 自动生成的API路径配置
 * 生成时间: {__import__('datetime').datetime.now().isoformat()}
 * 版本: {settings.APP_VERSION}
 */

return {json.dumps(paths, indent=2, ensure_ascii=False)};
"""
        return php_config
    
    def export_for_js(self) -> str:
        """导出JavaScript格式的路径配置"""
        paths = self.export_paths()
        
        js_config = f"""/**
 * 自动生成的API路径配置
 * 生成时间: {__import__('datetime').datetime.now().isoformat()}
 * 版本: {settings.APP_VERSION}
 */

export const API_PATHS = {json.dumps(paths, indent=2, ensure_ascii=False)};

export const API_BASE_URL = '{settings.SERVER_HOST}:{settings.SERVER_PORT}{self.base_url}';

export default API_PATHS;
"""
        return js_config
    
    def export_json(self) -> str:
        """导出JSON格式的路径配置"""
        paths = self.export_paths()
        return json.dumps(paths, indent=2, ensure_ascii=False)

# 便捷函数
def export_api_paths(app_router: APIRouter, format: str = "json") -> str:
    """导出API路径的便捷函数"""
    exporter = APIPathExporter(app_router)
    
    if format == "php":
        return exporter.export_for_php()
    elif format == "js":
        return exporter.export_for_js()
    else:
        return exporter.export_json()

def get_api_endpoints(app_router: APIRouter) -> Dict[str, List[Dict[str, Any]]]:
    """获取API端点列表"""
    exporter = APIPathExporter(app_router)
    return exporter.export_paths()["endpoints"]
