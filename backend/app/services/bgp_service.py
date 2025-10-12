"""
BGP服务管理模块
"""
import asyncio
import subprocess
import json
import logging
from typing import List, Dict, Optional, Tuple
from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_

from ..models.bgp import BGPSession, BGPOperation, OperationType, SessionStatus
from ..models.ipv6_pool import IPv6PrefixPool, IPv6Allocation, BGPAlert
from ..core.database import get_db

logger = logging.getLogger(__name__)


class BGPService:
    """BGP服务管理类"""
    
    def __init__(self):
        self.exabgp_config_path = "/etc/exabgp/exabgp.conf"
        self.exabgp_service_name = "exabgp"
        self.supervisor_service_name = "supervisor"
    
    async def reload_exabgp(self, session_id: Optional[str] = None) -> Dict:
        """重载ExaBGP配置"""
        operation_id = None
        rollback_data = None
        
        try:
            # 记录操作开始
            if session_id:
                operation_id = await self._record_operation(
                    session_id, OperationType.RELOAD, "PENDING", "开始重载ExaBGP配置"
                )
            
            # 备份当前配置
            rollback_data = await self._backup_config()
            
            # 生成新配置
            config_content = await self._generate_exabgp_config()
            
            # 写入配置文件
            with open(self.exabgp_config_path, 'w') as f:
                f.write(config_content)
            
            # 重载服务
            result = await self._reload_service()
            
            if result["success"]:
                # 更新操作状态
                if operation_id:
                    await self._update_operation(operation_id, "SUCCESS", "ExaBGP配置重载成功")
                
                return {
                    "success": True,
                    "message": "ExaBGP配置重载成功",
                    "operation_id": operation_id
                }
            else:
                # 回滚配置
                await self._rollback_config(rollback_data)
                
                if operation_id:
                    await self._update_operation(
                        operation_id, "FAILED", "ExaBGP配置重载失败", result.get("error")
                    )
                
                return {
                    "success": False,
                    "message": "ExaBGP配置重载失败",
                    "error": result.get("error"),
                    "operation_id": operation_id
                }
                
        except Exception as e:
            logger.error(f"ExaBGP重载失败: {str(e)}")
            
            # 回滚配置
            if rollback_data:
                await self._rollback_config(rollback_data)
            
            if operation_id:
                await self._update_operation(
                    operation_id, "FAILED", "ExaBGP配置重载异常", str(e)
                )
            
            return {
                "success": False,
                "message": "ExaBGP配置重载异常",
                "error": str(e),
                "operation_id": operation_id
            }
    
    async def restart_exabgp(self, session_id: Optional[str] = None) -> Dict:
        """重启ExaBGP服务"""
        operation_id = None
        
        try:
            # 记录操作开始
            if session_id:
                operation_id = await self._record_operation(
                    session_id, OperationType.RESTART, "PENDING", "开始重启ExaBGP服务"
                )
            
            # 重启服务
            result = await self._restart_service()
            
            if result["success"]:
                if operation_id:
                    await self._update_operation(operation_id, "SUCCESS", "ExaBGP服务重启成功")
                
                return {
                    "success": True,
                    "message": "ExaBGP服务重启成功",
                    "operation_id": operation_id
                }
            else:
                if operation_id:
                    await self._update_operation(
                        operation_id, "FAILED", "ExaBGP服务重启失败", result.get("error")
                    )
                
                return {
                    "success": False,
                    "message": "ExaBGP服务重启失败",
                    "error": result.get("error"),
                    "operation_id": operation_id
                }
                
        except Exception as e:
            logger.error(f"ExaBGP重启失败: {str(e)}")
            
            if operation_id:
                await self._update_operation(
                    operation_id, "FAILED", "ExaBGP服务重启异常", str(e)
                )
            
            return {
                "success": False,
                "message": "ExaBGP服务重启异常",
                "error": str(e),
                "operation_id": operation_id
            }
    
    async def get_session_status(self, session_id: str) -> Dict:
        """获取BGP会话状态"""
        try:
            # 这里应该从ExaBGP或BGP监控工具获取实际状态
            # 目前返回模拟数据
            return {
                "session_id": session_id,
                "status": "established",
                "uptime": 3600,
                "prefixes_received": 100,
                "prefixes_sent": 50,
                "last_update": datetime.now().isoformat()
            }
        except Exception as e:
            logger.error(f"获取BGP会话状态失败: {str(e)}")
            return {
                "session_id": session_id,
                "status": "unknown",
                "error": str(e)
            }
    
    async def allocate_ipv6_prefix(
        self, 
        pool_id: str, 
        client_id: str, 
        auto_announce: bool = False
    ) -> Dict:
        """分配IPv6前缀"""
        db = next(get_db())
        
        try:
            # 获取前缀池
            pool = db.query(IPv6PrefixPool).filter(IPv6PrefixPool.id == pool_id).first()
            if not pool:
                return {"success": False, "message": "前缀池不存在"}
            
            # 检查容量
            if pool.used_count >= pool.total_capacity:
                return {"success": False, "message": "前缀池已满"}
            
            # 分配前缀
            allocated_prefix = await self._calculate_next_prefix(pool)
            
            # 创建分配记录
            allocation = IPv6Allocation(
                pool_id=pool_id,
                client_id=client_id,
                allocated_prefix=allocated_prefix,
                is_active=True
            )
            db.add(allocation)
            
            # 更新池使用计数
            pool.used_count += 1
            if pool.used_count >= pool.total_capacity:
                pool.status = "depleted"
            
            db.commit()
            
            # 如果启用自动宣告，则创建BGP宣告
            if auto_announce and pool.auto_announce:
                await self._create_bgp_announcement(allocated_prefix, pool)
            
            return {
                "success": True,
                "message": "IPv6前缀分配成功",
                "allocated_prefix": allocated_prefix,
                "allocation_id": str(allocation.id)
            }
            
        except Exception as e:
            db.rollback()
            logger.error(f"IPv6前缀分配失败: {str(e)}")
            return {
                "success": False,
                "message": "IPv6前缀分配失败",
                "error": str(e)
            }
        finally:
            db.close()
    
    async def release_ipv6_prefix(self, allocation_id: str) -> Dict:
        """释放IPv6前缀"""
        db = next(get_db())
        
        try:
            # 获取分配记录
            allocation = db.query(IPv6Allocation).filter(
                IPv6Allocation.id == allocation_id
            ).first()
            
            if not allocation:
                return {"success": False, "message": "分配记录不存在"}
            
            # 更新分配记录
            allocation.is_active = False
            allocation.released_at = datetime.now()
            
            # 更新池使用计数
            pool = allocation.pool
            pool.used_count -= 1
            if pool.status == "depleted" and pool.used_count < pool.total_capacity:
                pool.status = "active"
            
            db.commit()
            
            return {
                "success": True,
                "message": "IPv6前缀释放成功",
                "released_prefix": allocation.allocated_prefix
            }
            
        except Exception as e:
            db.rollback()
            logger.error(f"IPv6前缀释放失败: {str(e)}")
            return {
                "success": False,
                "message": "IPv6前缀释放失败",
                "error": str(e)
            }
        finally:
            db.close()
    
    async def check_rpki_validation(self, prefix: str) -> Dict:
        """检查RPKI验证"""
        try:
            # 这里应该调用RPKI验证服务
            # 目前返回模拟数据
            return {
                "prefix": prefix,
                "valid": True,
                "reason": "Valid",
                "asn": 65001,
                "max_length": 48
            }
        except Exception as e:
            logger.error(f"RPKI验证失败: {str(e)}")
            return {
                "prefix": prefix,
                "valid": False,
                "reason": "Validation error",
                "error": str(e)
            }
    
    async def create_alert(
        self, 
        alert_type: str, 
        severity: str, 
        message: str, 
        prefix: Optional[str] = None,
        session_id: Optional[str] = None,
        pool_id: Optional[str] = None
    ) -> Dict:
        """创建告警"""
        db = next(get_db())
        
        try:
            alert = BGPAlert(
                alert_type=alert_type,
                severity=severity,
                message=message,
                prefix=prefix,
                session_id=session_id,
                pool_id=pool_id
            )
            db.add(alert)
            db.commit()
            
            return {
                "success": True,
                "message": "告警创建成功",
                "alert_id": str(alert.id)
            }
            
        except Exception as e:
            db.rollback()
            logger.error(f"创建告警失败: {str(e)}")
            return {
                "success": False,
                "message": "创建告警失败",
                "error": str(e)
            }
        finally:
            db.close()
    
    # 私有方法
    async def _record_operation(
        self, 
        session_id: str, 
        operation_type: OperationType, 
        status: str, 
        message: str
    ) -> str:
        """记录操作"""
        db = next(get_db())
        
        try:
            operation = BGPOperation(
                session_id=session_id,
                operation_type=operation_type,
                status=status,
                message=message
            )
            db.add(operation)
            db.commit()
            return str(operation.id)
        except Exception as e:
            db.rollback()
            logger.error(f"记录操作失败: {str(e)}")
            return None
        finally:
            db.close()
    
    async def _update_operation(
        self, 
        operation_id: str, 
        status: str, 
        message: str, 
        error_details: Optional[str] = None
    ):
        """更新操作状态"""
        db = next(get_db())
        
        try:
            operation = db.query(BGPOperation).filter(
                BGPOperation.id == operation_id
            ).first()
            
            if operation:
                operation.status = status
                operation.message = message
                operation.error_details = error_details
                operation.completed_at = datetime.now()
                db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"更新操作状态失败: {str(e)}")
        finally:
            db.close()
    
    async def _backup_config(self) -> str:
        """备份当前配置"""
        try:
            with open(self.exabgp_config_path, 'r') as f:
                return f.read()
        except Exception as e:
            logger.error(f"备份配置失败: {str(e)}")
            return None
    
    async def _rollback_config(self, rollback_data: str):
        """回滚配置"""
        if rollback_data:
            try:
                with open(self.exabgp_config_path, 'w') as f:
                    f.write(rollback_data)
            except Exception as e:
                logger.error(f"回滚配置失败: {str(e)}")
    
    async def _generate_exabgp_config(self) -> str:
        """生成ExaBGP配置"""
        # 这里应该根据数据库中的BGP会话和宣告生成配置
        # 目前返回基本配置模板
        return """
group exabgp {
    router-id 192.168.1.1;
    
    process announce-routes {
        run /usr/bin/python3 /etc/exabgp/announce-routes.py;
        encoder json;
    }
    
    neighbor 192.168.1.2 {
        router-id 192.168.1.1;
        local-address 192.168.1.1;
        local-as 65001;
        peer-as 65002;
        
        capability {
            graceful-restart 120;
        }
        
        family {
            ipv4 unicast;
            ipv6 unicast;
        }
    }
}
"""
    
    async def _reload_service(self) -> Dict:
        """重载服务"""
        try:
            # 尝试使用systemctl
            result = subprocess.run(
                ["systemctl", "reload", self.exabgp_service_name],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                return {"success": True}
            else:
                # 尝试使用supervisorctl
                result = subprocess.run(
                    ["supervisorctl", "restart", self.exabgp_service_name],
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                
                if result.returncode == 0:
                    return {"success": True}
                else:
                    return {
                        "success": False,
                        "error": f"重载失败: {result.stderr}"
                    }
                    
        except subprocess.TimeoutExpired:
            return {"success": False, "error": "重载超时"}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def _restart_service(self) -> Dict:
        """重启服务"""
        try:
            # 尝试使用systemctl
            result = subprocess.run(
                ["systemctl", "restart", self.exabgp_service_name],
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode == 0:
                return {"success": True}
            else:
                # 尝试使用supervisorctl
                result = subprocess.run(
                    ["supervisorctl", "restart", self.exabgp_service_name],
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                
                if result.returncode == 0:
                    return {"success": True}
                else:
                    return {
                        "success": False,
                        "error": f"重启失败: {result.stderr}"
                    }
                    
        except subprocess.TimeoutExpired:
            return {"success": False, "error": "重启超时"}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def _calculate_next_prefix(self, pool: IPv6PrefixPool) -> str:
        """计算下一个可用的前缀"""
        # 这里应该实现前缀分配算法
        # 目前返回模拟数据
        base_prefix = pool.prefix.split('/')[0]
        used_count = pool.used_count
        
        # 简单的递增分配（实际应该更复杂）
        next_suffix = hex(used_count + 1)[2:].zfill(4)
        return f"{base_prefix}:{next_suffix}::{pool.prefix_length}"
    
    async def _create_bgp_announcement(self, prefix: str, pool: IPv6PrefixPool):
        """创建BGP宣告"""
        # 这里应该创建BGP宣告记录
        pass


# 全局BGP服务实例
bgp_service = BGPService()