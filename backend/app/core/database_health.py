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
import psycopg2
from psycopg2 import sql

from .config import settings

logger = logging.getLogger(__name__)


class DatabaseHealthChecker:
    """数据库健康检查器"""
    
    def __init__(self):
        self.database_url = settings.DATABASE_URL
        self.sqlite_url = settings.SQLITE_DATABASE_URL
        self.use_sqlite_fallback = settings.USE_SQLITE_FALLBACK
        self.auto_create_database = settings.AUTO_CREATE_DATABASE
        
    def check_database_connection(self) -> Dict[str, Any]:
        """检查数据库连接状态"""
        result = {
            "status": "unknown",
            "database_type": "unknown",
            "connection_ok": False,
            "error": None,
            "details": {}
        }
        
        try:
            if self.database_url.startswith("postgresql://"):
                result.update(self._check_postgresql_connection())
            elif self.database_url.startswith("sqlite://"):
                result.update(self._check_sqlite_connection())
            else:
                result["error"] = f"不支持的数据库类型: {self.database_url}"
                
        except Exception as e:
            result["error"] = str(e)
            logger.error(f"数据库连接检查失败: {e}")
            
        return result
    
    def _check_postgresql_connection(self) -> Dict[str, Any]:
        """检查PostgreSQL连接"""
        result = {
            "database_type": "postgresql",
            "connection_ok": False,
            "details": {}
        }
        
        try:
            # 解析数据库URL
            from urllib.parse import urlparse
            parsed = urlparse(self.database_url)
            
            # 尝试连接数据库
            engine = create_engine(self.database_url, pool_pre_ping=True)
            
            with engine.connect() as conn:
                # 检查基本连接
                conn.execute(text("SELECT 1"))
                result["connection_ok"] = True
                
                # 获取数据库信息
                version_result = conn.execute(text("SELECT version()"))
                version = version_result.fetchone()[0]
                result["details"]["version"] = version
                
                # 检查数据库大小
                size_result = conn.execute(text("""
                    SELECT pg_size_pretty(pg_database_size(current_database()))
                """))
                size = size_result.fetchone()[0]
                result["details"]["size"] = size
                
                # 检查连接数
                conn_result = conn.execute(text("""
                    SELECT count(*) FROM pg_stat_activity 
                    WHERE datname = current_database()
                """))
                connections = conn_result.fetchone()[0]
                result["details"]["connections"] = connections
                
                # 检查表是否存在
                inspector = inspect(engine)
                tables = inspector.get_table_names()
                result["details"]["tables"] = len(tables)
                result["details"]["table_list"] = tables
                
                result["status"] = "healthy"
                logger.info("PostgreSQL数据库连接正常")
                
        except OperationalError as e:
            error_msg = str(e)
            if "does not exist" in error_msg.lower():
                result["error"] = "数据库不存在"
                result["status"] = "database_not_found"
                logger.warning("数据库不存在，可能需要创建")
            elif "authentication failed" in error_msg.lower():
                result["error"] = "认证失败"
                result["status"] = "auth_failed"
                logger.error("数据库认证失败")
            else:
                result["error"] = f"连接错误: {error_msg}"
                result["status"] = "connection_failed"
                logger.error(f"PostgreSQL连接失败: {error_msg}")
                
        except Exception as e:
            result["error"] = f"未知错误: {str(e)}"
            result["status"] = "error"
            logger.error(f"PostgreSQL检查失败: {e}")
            
        return result
    
    def _check_sqlite_connection(self) -> Dict[str, Any]:
        """检查SQLite连接"""
        result = {
            "database_type": "sqlite",
            "connection_ok": False,
            "details": {}
        }
        
        try:
            engine = create_engine(self.database_url)
            
            with engine.connect() as conn:
                # 检查基本连接
                conn.execute(text("SELECT 1"))
                result["connection_ok"] = True
                
                # 获取数据库文件信息
                db_path = self.database_url.replace("sqlite:///", "")
                if os.path.exists(db_path):
                    file_size = os.path.getsize(db_path)
                    result["details"]["file_size"] = f"{file_size} bytes"
                    result["details"]["file_path"] = db_path
                
                # 检查表
                inspector = inspect(engine)
                tables = inspector.get_table_names()
                result["details"]["tables"] = len(tables)
                result["details"]["table_list"] = tables
                
                result["status"] = "healthy"
                logger.info("SQLite数据库连接正常")
                
        except Exception as e:
            result["error"] = f"SQLite连接失败: {str(e)}"
            result["status"] = "error"
            logger.error(f"SQLite检查失败: {e}")
            
        return result
    
    def create_database_if_not_exists(self) -> bool:
        """如果数据库不存在则创建"""
        if not self.auto_create_database:
            logger.info("自动创建数据库已禁用")
            return False
            
        try:
            if self.database_url.startswith("postgresql://"):
                return self._create_postgresql_database()
            elif self.database_url.startswith("sqlite://"):
                return self._create_sqlite_database()
            else:
                logger.error(f"不支持的数据库类型: {self.database_url}")
                return False
                
        except Exception as e:
            logger.error(f"创建数据库失败: {e}")
            return False
    
    def _create_postgresql_database(self) -> bool:
        """创建PostgreSQL数据库"""
        try:
            from urllib.parse import urlparse
            parsed = urlparse(self.database_url)
            
            # 连接到默认数据库
            default_db_url = f"postgresql://{parsed.username}:{parsed.password}@{parsed.hostname}:{parsed.port}/postgres"
            
            engine = create_engine(default_db_url)
            
            with engine.connect() as conn:
                # 检查数据库是否存在
                db_name = parsed.path[1:]  # 移除开头的 '/'
                
                result = conn.execute(text("""
                    SELECT 1 FROM pg_database WHERE datname = :db_name
                """), {"db_name": db_name})
                
                if result.fetchone():
                    logger.info(f"数据库 {db_name} 已存在")
                    return True
                
                # 创建数据库
                conn.execute(text("COMMIT"))  # 结束当前事务
                conn.execute(text(f'CREATE DATABASE "{db_name}"'))
                logger.info(f"成功创建数据库: {db_name}")
                
                # 创建用户（如果不存在）
                try:
                    conn.execute(text(f"""
                        CREATE USER "{parsed.username}" WITH PASSWORD '{parsed.password}'
                    """))
                    logger.info(f"成功创建用户: {parsed.username}")
                except ProgrammingError:
                    # 用户可能已存在
                    logger.info(f"用户 {parsed.username} 可能已存在")
                
                # 授权
                conn.execute(text(f"""
                    GRANT ALL PRIVILEGES ON DATABASE "{db_name}" TO "{parsed.username}"
                """))
                logger.info(f"已授权用户 {parsed.username} 访问数据库 {db_name}")
                
                return True
                
        except Exception as e:
            logger.error(f"创建PostgreSQL数据库失败: {e}")
            return False
    
    def _create_sqlite_database(self) -> bool:
        """创建SQLite数据库"""
        try:
            db_path = self.database_url.replace("sqlite:///", "")
            db_dir = os.path.dirname(db_path)
            
            # 创建目录
            if db_dir and not os.path.exists(db_dir):
                os.makedirs(db_dir, exist_ok=True)
                logger.info(f"创建数据库目录: {db_dir}")
            
            # 创建数据库文件
            engine = create_engine(self.database_url)
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
                
            logger.info(f"成功创建SQLite数据库: {db_path}")
            return True
            
        except Exception as e:
            logger.error(f"创建SQLite数据库失败: {e}")
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