"""
数据库健康检查和自动修复模块
"""
import os
import sys
import time
import logging
from typing import Optional, Dict, Any
from sqlalchemy import create_engine, text, inspect
from sqlalchemy.exc import OperationalError, ProgrammingError

# 可选导入MySQL
try:
    import pymysql
    from pymysql import sql
    MYSQL_AVAILABLE = True
except ImportError:
    MYSQL_AVAILABLE = False
    pymysql = None
    sql = None

from .config import settings

logger = logging.getLogger(__name__)


class DatabaseHealthChecker:
    """数据库健康检查器"""
    
    def __init__(self):
        self.database_url = settings.DATABASE_URL
        self.auto_create_database = settings.AUTO_CREATE_DATABASE
        
    def check_database_connection(self) -> Dict[str, Any]:
        """检查数据库连接状态 - 强制使用MySQL"""
        result = {
            "status": "unknown",
            "database_type": "unknown",
            "connection_ok": False,
            "error": None,
            "details": {}
        }
        
        try:
            # 强制仅支持MySQL数据库
            if not self.database_url.startswith("mysql://"):
                result["error"] = f"不支持的数据库类型，仅支持MySQL: {self.database_url}"
                result["status"] = "unsupported"
                logger.error(f"不支持的数据库类型，仅支持MySQL: {self.database_url}")
                return result
                
            result.update(self._check_mysql_connection())
                
        except Exception as e:
            result["error"] = str(e)
            logger.error(f"数据库连接检查失败: {e}")
            
        return result
    
    def _check_postgresql_connection(self) -> Dict[str, Any]:
        """检查PostgreSQL连接 - 已废弃，不再支持PostgreSQL"""
        result = {
            "database_type": "postgresql",
            "connection_ok": False,
            "details": {}
        }
        
        logger.error("PostgreSQL连接检查已废弃，不再支持PostgreSQL数据库")
        logger.info("请使用MySQL数据库，并将DATABASE_URL修改为mysql://格式")
        
        result["error"] = "PostgreSQL支持已废弃"
        result["status"] = "deprecated"
        return result
    
    def _check_mysql_connection(self) -> Dict[str, Any]:
        """检查MySQL连接"""
        result = {
            "database_type": "mysql",
            "connection_ok": False,
            "details": {}
        }
        
        if not MYSQL_AVAILABLE:
            result["error"] = "MySQL驱动(pymysql)未安装"
            result["status"] = "driver_missing"
            return result
        
        try:
            # 解析数据库URL
            from urllib.parse import urlparse
            parsed = urlparse(self.database_url)
            
            # 强制使用pymysql驱动
            sync_db_url = self.database_url.replace("mysql://", "mysql+pymysql://")
            logger.info(f"使用MySQL同步驱动检查连接: {sync_db_url}")
            
            # 尝试连接数据库
            engine = create_engine(sync_db_url, pool_pre_ping=True)
            
            with engine.connect() as conn:
                # 检查基本连接
                conn.execute(text("SELECT 1"))
                result["connection_ok"] = True
                
                # 获取数据库信息
                version_result = conn.execute(text("SELECT version()"))
                version = version_result.fetchone()[0]
                result["details"]["version"] = version
                
                # 检查数据库大小 - 使用MySQL特定查询
                try:
                    size_result = conn.execute(text("""
                        SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'DB Size in MB' 
                        FROM information_schema.tables 
                        WHERE table_schema = DATABASE()
                    """))
                    size = size_result.fetchone()[0]
                    result["details"]["size"] = f"{size} MB"
                except Exception:
                    result["details"]["size"] = "未知"
                
                # 检查连接数 - 使用MySQL特定查询
                try:
                    conn_result = conn.execute(text("SHOW STATUS LIKE 'Threads_connected'"))
                    connections = conn_result.fetchone()[1]
                except Exception:
                    connections = "未知"
                
                result["details"]["connections"] = connections
                
                # 检查表是否存在
                inspector = inspect(engine)
                tables = inspector.get_table_names()
                result["details"]["tables"] = len(tables)
                result["details"]["table_list"] = tables
                
                result["status"] = "healthy"
                logger.info("MySQL数据库连接正常")
                
        except OperationalError as e:
            error_msg = str(e)
            if "does not exist" in error_msg.lower():
                result["error"] = "数据库不存在"
                result["status"] = "database_not_found"
                logger.warning("数据库不存在，可能需要创建")
            elif "authentication failed" in error_msg.lower() or "password authentication failed" in error_msg.lower():
                result["error"] = "认证失败"
                result["status"] = "auth_failed"
                logger.error("数据库认证失败")
            else:
                result["error"] = f"连接错误: {error_msg}"
                result["status"] = "connection_failed"
                logger.error(f"MySQL连接失败: {error_msg}")
                
        except Exception as e:
            result["error"] = f"未知错误: {str(e)}"
            result["status"] = "error"
            logger.error(f"MySQL检查失败: {e}")
            
        return result
    
    def create_database_if_not_exists(self) -> bool:
        """如果数据库不存在则创建 - 强制使用MySQL"""
        if not self.auto_create_database:
            logger.info("自动创建数据库已禁用")
            return False
            
        try:
            # 强制仅支持MySQL数据库
            if not self.database_url.startswith("mysql://"):
                logger.error(f"不支持的数据库类型，仅支持MySQL: {self.database_url}")
                return False
                
            return self._create_mysql_database()
                
        except Exception as e:
            logger.error(f"创建数据库失败: {e}")
            return False
    
    def _create_mysql_database(self) -> bool:
        """创建MySQL数据库"""
        if not MYSQL_AVAILABLE:
            logger.error("MySQL驱动(pymysql)未安装，无法创建数据库")
            return False
            
        try:
            from urllib.parse import urlparse
            parsed = urlparse(self.database_url)
            
            # 连接到默认数据库 - 强制使用pymysql驱动
            default_db_url = f"mysql+pymysql://root@localhost:3306/mysql"
            logger.info(f"使用MySQL同步驱动创建数据库: {default_db_url}")
            
            engine = create_engine(default_db_url)
            
            with engine.connect() as conn:
                # 检查数据库是否存在
                db_name = parsed.path[1:]  # 移除开头的 '/'
                
                try:
                    result = conn.execute(text("""
                        SELECT 1 FROM information_schema.schemata 
                        WHERE schema_name = :db_name
                    """), {"db_name": db_name})
                    
                    if not result.fetchone():
                        # 创建数据库
                        conn.execute(text(f"CREATE DATABASE {db_name}"))
                        conn.execute(text(f"USE {db_name}"))
                        conn.commit()
                        logger.info(f"数据库 {db_name} 创建成功")
                        return True
                    else:
                        logger.info(f"数据库 {db_name} 已存在")
                        return True
                        
                except Exception as e:
                    logger.error(f"检查或创建数据库失败: {e}")
                    return False
                
        except Exception as e:
            logger.error(f"连接到MySQL服务器失败: {e}")
            return False
    
    def _create_postgresql_database(self) -> bool:
        """创建PostgreSQL数据库 - 已废弃，不再支持PostgreSQL"""
        logger.error("PostgreSQL数据库创建已废弃，不再支持PostgreSQL数据库")
        logger.info("请使用MySQL数据库，并将DATABASE_URL修改为mysql://格式")
        return False
    
    def fix_database_issues(self) -> bool:
        """修复数据库问题"""
        try:
            # 检查连接状态
            health = self.check_database_connection()
            
            if health["status"] == "database_not_found":
                logger.info("尝试创建数据库...")
                if self.create_database_if_not_exists():
                    logger.info("数据库创建成功")
                    return True
                else:
                    logger.error("数据库创建失败")
                    return False
            
            elif health["status"] == "healthy":
                logger.info("数据库状态正常")
                return True
            
            else:
                logger.warning(f"数据库状态异常: {health['status']}")
                return False
                
        except Exception as e:
            logger.error(f"修复数据库问题失败: {e}")
            return False


def check_and_fix_database() -> bool:
    """检查并修复数据库问题"""
    checker = DatabaseHealthChecker()
    return checker.fix_database_issues()


def get_database_health() -> Dict[str, Any]:
    """获取数据库健康状态"""
    checker = DatabaseHealthChecker()
    return checker.check_database_connection()


if __name__ == "__main__":
    # 命令行测试
    import json
    
    print("检查数据库健康状态...")
    health = get_database_health()
    print(json.dumps(health, indent=2, ensure_ascii=False))
    
    if health["status"] != "healthy":
        print("\n尝试修复数据库问题...")
        if check_and_fix_database():
            print("数据库修复成功")
        else:
            print("数据库修复失败")
            sys.exit(1)
    else:
        print("数据库状态正常")