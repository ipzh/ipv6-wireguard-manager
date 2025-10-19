"""
数据库健康检查和自动修复模块（增强版）
"""
import asyncio
import logging
from typing import Optional, Dict, Any, List
from sqlalchemy import create_engine, text, inspect
from sqlalchemy.exc import OperationalError, ProgrammingError
from contextlib import asynccontextmanager, contextmanager

from .database_manager import database_manager, DatabaseType
from .config_enhanced import settings

logger = logging.getLogger(__name__)

class DatabaseHealthChecker:
    """数据库健康检查器（增强版）"""
    
    def __init__(self):
        self.database_manager = database_manager
        self.last_check_time = None
        self.last_check_result = None
    
    async def check_database_health(self, detailed: bool = False) -> Dict[str, Any]:
        """检查数据库健康状况"""
        result = {
            "status": "unknown",
            "database_type": self.database_manager.database_type.value,
            "async_connection_ok": False,
            "sync_connection_ok": False,
            "error": None,
            "details": {},
            "timestamp": None,
            "recommendations": []
        }
        
        try:
            # 检查异步连接
            if self.database_manager.async_engine:
                async_result = await self.database_manager.check_connection(is_async=True)
                result["async_connection_ok"] = async_result["connection_ok"]
                if not async_result["connection_ok"]:
                    result["error"] = async_result.get("error", "异步连接失败")
                    result["recommendations"].append("检查异步数据库驱动是否安装")
            
            # 检查同步连接
            if self.database_manager.sync_engine:
                sync_result = await asyncio.get_event_loop().run_in_executor(
                    None, self._check_sync_connection
                )
                result["sync_connection_ok"] = sync_result["connection_ok"]
                if not sync_result["connection_ok"]:
                    if not result["error"]:
                        result["error"] = sync_result.get("error", "同步连接失败")
                    result["recommendations"].append("检查同步数据库驱动是否安装")
            
            # 确定整体状态
            if result["async_connection_ok"] or result["sync_connection_ok"]:
                result["status"] = "healthy"
            else:
                result["status"] = "unhealthy"
            
            # 获取详细信息
            if detailed and (result["async_connection_ok"] or result["sync_connection_ok"]):
                result["details"] = await self._get_database_details()
            
            # 添加时间戳
            from datetime import datetime
            result["timestamp"] = datetime.now().isoformat()
            
            # 保存检查结果
            self.last_check_time = result["timestamp"]
            self.last_check_result = result
            
        except Exception as e:
            result["error"] = str(e)
            result["status"] = "error"
            logger.error(f"数据库健康检查失败: {e}")
            
        return result
    
    def _check_sync_connection(self) -> Dict[str, Any]:
        """检查同步连接"""
        try:
            with self.database_manager.sync_engine.begin() as conn:
                conn.execute(text("SELECT 1"))
                return {"connection_ok": True}
        except Exception as e:
            return {"connection_ok": False, "error": str(e)}
    
    async def _get_database_details(self) -> Dict[str, Any]:
        """获取数据库详细信息"""
        details = {}
        
        try:
            # 优先使用异步连接获取详细信息
            if self.database_manager.async_engine:
                details = await self._get_async_details()
            elif self.database_manager.sync_engine:
                details = await asyncio.get_event_loop().run_in_executor(
                    None, self._get_sync_details
                )
        except Exception as e:
            logger.error(f"获取数据库详细信息失败: {e}")
            details["error"] = str(e)
            
        return details
    
    async def _get_async_details(self) -> Dict[str, Any]:
        """使用异步连接获取详细信息"""
        details = {}
        
        async with self.database_manager.async_engine.begin() as conn:
            # 获取数据库版本
            if self.database_manager.database_type == DatabaseType.MYSQL:
                version_result = await conn.execute(text("SELECT version()"))
                details["version"] = version_result.fetchone()[0]
                
                # 获取数据库大小
                try:
                    size_result = await conn.execute(text("""
                        SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'DB Size in MB' 
                        FROM information_schema.tables 
                        WHERE table_schema = DATABASE()
                    """))
                    size = size_result.fetchone()[0]
                    details["size"] = f"{size} MB"
                except Exception:
                    details["size"] = "未知"
                
                # 获取连接数
                try:
                    conn_result = await conn.execute(text("SHOW STATUS LIKE 'Threads_connected'"))
                    connections = conn_result.fetchone()[1]
                    details["connections"] = connections
                except Exception:
                    details["connections"] = "未知"
            
            # 检查表
            inspector = inspect(self.database_manager.async_engine)
            tables = inspector.get_table_names()
            details["tables"] = len(tables)
            details["table_list"] = tables
            
        return details
    
    def _get_sync_details(self) -> Dict[str, Any]:
        """使用同步连接获取详细信息"""
        details = {}
        
        with self.database_manager.sync_engine.begin() as conn:
            # 获取数据库版本
            if self.database_manager.database_type == DatabaseType.MYSQL:
                version_result = conn.execute(text("SELECT version()"))
                details["version"] = version_result.fetchone()[0]
                
                # 获取数据库大小
                try:
                    size_result = conn.execute(text("""
                        SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'DB Size in MB' 
                        FROM information_schema.tables 
                        WHERE table_schema = DATABASE()
                    """))
                    size = size_result.fetchone()[0]
                    details["size"] = f"{size} MB"
                except Exception:
                    details["size"] = "未知"
                
                # 获取连接数
                try:
                    conn_result = conn.execute(text("SHOW STATUS LIKE 'Threads_connected'"))
                    connections = conn_result.fetchone()[1]
                    details["connections"] = connections
                except Exception:
                    details["connections"] = "未知"
            
            # 检查表
            inspector = inspect(self.database_manager.sync_engine)
            tables = inspector.get_table_names()
            details["tables"] = len(tables)
            details["table_list"] = tables
            
        return details
    
    async def auto_fix_database(self) -> Dict[str, Any]:
        """自动修复数据库问题"""
        result = {
            "status": "unknown",
            "actions_taken": [],
            "success": False,
            "error": None
        }
        
        try:
            # 检查数据库健康状态
            health = await self.check_database_health()
            
            # 如果数据库不存在，尝试创建
            if health["status"] == "unhealthy" and "does not exist" in str(health.get("error", "")):
                if await self._create_database():
                    result["actions_taken"].append("创建数据库")
                    result["success"] = True
                    result["status"] = "fixed"
                else:
                    result["error"] = "无法创建数据库"
                    result["status"] = "failed"
                    return result
            
            # 如果连接失败，尝试重新初始化引擎
            if health["status"] == "unhealthy":
                await self._reinitialize_engines()
                result["actions_taken"].append("重新初始化数据库引擎")
                
                # 再次检查
                health_after = await self.check_database_health()
                if health_after["status"] == "healthy":
                    result["success"] = True
                    result["status"] = "fixed"
                else:
                    result["error"] = "重新初始化后仍无法连接数据库"
                    result["status"] = "failed"
            
        except Exception as e:
            result["error"] = str(e)
            result["status"] = "error"
            logger.error(f"自动修复数据库失败: {e}")
            
        return result
    
    async def _create_database(self) -> bool:
        """创建数据库"""
        try:
            # 解析数据库URL
            from urllib.parse import urlparse
            parsed = urlparse(settings.DATABASE_URL)
            
            # 创建不包含数据库名的URL
            db_name = parsed.path.lstrip('/')
            server_url = f"{parsed.scheme}://{parsed.netloc}"
            
            # 连接到MySQL服务器（不指定数据库）
            engine = create_engine(server_url)
            
            with engine.connect() as conn:
                # 创建数据库
                conn.execute(text(f"CREATE DATABASE IF NOT EXISTS `{db_name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"))
                logger.info(f"数据库 {db_name} 创建成功")
                return True
                
        except Exception as e:
            logger.error(f"创建数据库失败: {e}")
            return False
    
    async def _reinitialize_engines(self):
        """重新初始化数据库引擎"""
        try:
            # 关闭现有引擎
            await self.database_manager.close()
            
            # 重新初始化
            self.database_manager._initialize_engines()
            logger.info("数据库引擎重新初始化成功")
            
        except Exception as e:
            logger.error(f"数据库引擎重新初始化失败: {e}")
            raise

# 创建全局健康检查器实例
health_checker = DatabaseHealthChecker()

# 导出便捷函数
async def check_and_fix_database() -> bool:
    """检查并修复数据库（便捷函数）"""
    try:
        # 检查数据库健康状态
        health = await health_checker.check_database_health()
        
        # 如果不健康，尝试修复
        if health["status"] != "healthy":
            fix_result = await health_checker.auto_fix_database()
            return fix_result["success"]
        
        return True
    except Exception as e:
        logger.error(f"检查并修复数据库失败: {e}")
        return False
