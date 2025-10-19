"""
状态服务
"""
from typing import Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
import psutil
import time
import subprocess
import asyncio
from ..core.logging import get_logger

logger = get_logger(__name__)

class StatusService:
    """状态服务类"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_system_status(self) -> Dict[str, Any]:
        """获取系统状态"""
        try:
            # 获取系统信息
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            # 获取网络信息
            network = psutil.net_io_counters()
            
            return {
                "system": {
                    "cpu_percent": cpu_percent,
                    "memory": {
                        "total": memory.total,
                        "available": memory.available,
                        "percent": memory.percent,
                        "used": memory.used
                    },
                    "disk": {
                        "total": disk.total,
                        "used": disk.used,
                        "free": disk.free,
                        "percent": (disk.used / disk.total) * 100
                    },
                    "network": {
                        "bytes_sent": network.bytes_sent,
                        "bytes_recv": network.bytes_recv,
                        "packets_sent": network.packets_sent,
                        "packets_recv": network.packets_recv
                    }
                },
                "timestamp": time.time()
            }
        except Exception as e:
            logger.error(f"获取系统状态失败: {e}")
            return {
                "error": str(e),
                "timestamp": time.time()
            }
    
    async def get_services_status(self) -> Dict[str, Any]:
        """获取服务状态"""
        services = {
            "postgresql": self._check_service("postgresql"),
            "redis": self._check_service("redis-server"),
            "nginx": self._check_service("nginx"),
            "wireguard": self._check_wireguard_service()
        }
        
        return {
            "services": services,
            "timestamp": time.time()
        }
    
    def _check_service(self, service_name: str) -> Dict[str, Any]:
        """检查服务状态"""
        try:
            result = subprocess.run(
                ["systemctl", "is-active", service_name],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            is_active = result.returncode == 0
            status = result.stdout.strip()
            
            return {
                "name": service_name,
                "active": is_active,
                "status": status,
                "error": None
            }
        except Exception as e:
            logger.error(f"检查服务{service_name}状态失败: {e}")
            return {
                "name": service_name,
                "active": False,
                "status": "unknown",
                "error": str(e)
            }
    
    def _check_wireguard_service(self) -> Dict[str, Any]:
        """检查WireGuard服务状态"""
        try:
            result = subprocess.run(
                ["wg", "show"],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            is_active = result.returncode == 0
            interfaces = []
            
            if is_active:
                # 解析WireGuard输出
                lines = result.stdout.strip().split('\n')
                current_interface = None
                
                for line in lines:
                    if line.startswith('interface:'):
                        current_interface = line.split(':')[1].strip()
                        interfaces.append({
                            "name": current_interface,
                            "peers": []
                        })
                    elif line.startswith('peer:') and current_interface:
                        peer_id = line.split(':')[1].strip()
                        interfaces[-1]["peers"].append(peer_id)
            
            return {
                "name": "wireguard",
                "active": is_active,
                "interfaces": interfaces,
                "error": None
            }
        except Exception as e:
            logger.error(f"检查WireGuard服务状态失败: {e}")
            return {
                "name": "wireguard",
                "active": False,
                "interfaces": [],
                "error": str(e)
            }
