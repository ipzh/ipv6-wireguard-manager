"""
数据库健康检查和自动修复模块
专门处理VPS环境中的数据库配置问题
"""
import os
import sys
import subprocess
import logging
from typing import Optional, Dict, Any
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError, ProgrammingError

from .config import settings

logger = logging.getLogger(__name__)


class DatabaseHealthChecker:
    """数据库健康检查器"""
    
    def __init__(self):
        self.db_url = settings.DATABASE_URL
        self.engine = create_engine(self.db_url)
        self.issues_found = []
        self.fixes_applied = []
    
    def check_database_health(self) -> Dict[str, Any]:
        """检查数据库健康状况"""
        logger.info("开始检查数据库健康状况...")
        
        # 重置状态
        self.issues_found = []
        self.fixes_applied = []
        
        # 执行各项检查
        self._check_connection()
        self._check_database_exists()
        self._check_user_permissions()
        self._check_tables()
        
        return {
            "healthy": len(self.issues_found) == 0,
            "issues": self.issues_found,
            "fixes": self.fixes_applied
        }
    
    def _check_connection(self):
        """检查数据库连接"""
        try:
            with self.engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            logger.info("数据库连接正常")
        except OperationalError as e:
            self.issues_found.append({
                "type": "connection",
                "message": f"数据库连接失败: {e}",
                "severity": "critical"
            })
    
    def _check_database_exists(self):
        """检查数据库是否存在"""
        try:
            # 尝试连接到默认数据库来检查目标数据库是否存在
            if self.db_url.startswith("postgresql://"):
                # 提取数据库名称
                db_name = self.db_url.split("/")[-1].split("?")[0]
                
                # 使用当前配置的用户连接，而不是尝试使用postgres用户
                try:
                    with self.engine.connect() as conn:
                        result = conn.execute(
                            text("SELECT 1 FROM pg_database WHERE datname = :db_name"),
                            {"db_name": db_name}
                        )
                        if not result.scalar():
                            self.issues_found.append({
                                "type": "database_missing",
                                "message": f"数据库 '{db_name}' 不存在",
                                "severity": "critical"
                            })
                except Exception as e:
                    logger.warning(f"无法检查数据库是否存在: {e}")
                    
        except Exception as e:
            logger.warning(f"数据库存在性检查失败: {e}")
    
    def _check_user_permissions(self):
        """检查用户权限"""
        try:
            if self.db_url.startswith("postgresql://"):
                # 测试连接权限
                test_engine = create_engine(self.db_url)
                with test_engine.connect() as conn:
                    # 检查是否能执行简单查询
                    conn.execute(text("SELECT 1"))
                    
                # 检查创建表权限
                test_db_url = self.db_url
                test_engine = create_engine(test_db_url)
                
                # 尝试创建临时表
                metadata = MetaData()
                test_table = Table('permission_test', metadata,
                    Column('id', Integer, primary_key=True),
                    Column('name', String)
                )
                
                try:
                    metadata.create_all(test_engine)
                    test_table.drop(test_engine)
                    return True
                except Exception as e:
                    logger.warning(f"用户权限不足，需要修复: {e}")
                    return False
                    
            return True
            
        except Exception as e:
            logger.error(f"检查用户权限失败: {e}")
            return False
    
    def _check_tables(self):
        """检查表是否存在"""
        try:
            with self.engine.connect() as conn:
                # 检查核心表是否存在
                tables_to_check = ["users", "wireguard_servers", "wireguard_clients"]
                
                for table in tables_to_check:
                    result = conn.execute(
                        text("SELECT 1 FROM information_schema.tables WHERE table_name = :table_name"),
                        {"table_name": table}
                    )
                    if not result.scalar():
                        self.issues_found.append({
                            "type": "table_missing",
                            "message": f"表 '{table}' 不存在",
                            "severity": "warning"
                        })
                        
        except Exception as e:
            logger.warning(f"表检查失败: {e}")
    
    def fix_database_issues(self) -> bool:
        """尝试修复数据库问题"""
        logger.info("开始修复数据库问题...")
        
        # 先检查问题
        health_status = self.check_database_health()
        
        if health_status["healthy"]:
            logger.info("数据库健康，无需修复")
            return True
        
        # 根据问题类型进行修复
        for issue in health_status["issues"]:
            if issue["type"] == "database_missing":
                self._fix_missing_database()
            elif issue["type"] == "user_missing":
                self._fix_missing_user()
            elif issue["type"] == "permission_connect":
                self._fix_connect_permissions()
            elif issue["type"] == "permission_create":
                self._fix_create_permissions()
        
        # 重新检查修复结果
        health_status_after = self.check_database_health()
        
        if health_status_after["healthy"]:
            logger.info("数据库问题修复成功")
            return True
        else:
            logger.error("数据库问题修复失败")
            return False
    
    def _fix_missing_database(self):
        """修复缺失的数据库"""
        try:
            if self.db_url.startswith("postgresql://"):
                db_name = self.db_url.split("/")[-1].split("?")[0]
                
                # 使用系统命令创建数据库，避免认证问题
                import subprocess
                
                # 提取用户名和密码
                username = self.db_url.split("://")[1].split(":")[0]
                
                # 使用sudo权限创建数据库和用户
                result = subprocess.run([
                    'sudo', '-u', 'postgres', 'psql', '-c', 
                    f"CREATE DATABASE {db_name};"
                ], capture_output=True, text=True)
                
                if result.returncode == 0:
                    logger.info(f"数据库 {db_name} 创建成功")
                    self.fixes_applied.append({"type": "database_created", "database": db_name})
                else:
                    logger.error(f"数据库创建失败: {result.stderr}")
                    
                # 创建用户并授予权限
                result = subprocess.run([
                    'sudo', '-u', 'postgres', 'psql', '-c',
                    f"CREATE USER {username} WITH PASSWORD 'password';"
                ], capture_output=True, text=True)
                
                if result.returncode == 0:
                    logger.info(f"用户 {username} 创建成功")
                    self.fixes_applied.append({"type": "user_created", "user": username})
                else:
                    logger.warning(f"用户创建失败（可能已存在）: {result.stderr}")
                    
                # 授予权限
                result = subprocess.run([
                    'sudo', '-u', 'postgres', 'psql', '-c',
                    f"GRANT ALL PRIVILEGES ON DATABASE {db_name} TO {username};"
                ], capture_output=True, text=True)
                
                if result.returncode == 0:
                    logger.info(f"数据库权限授予成功")
                    self.fixes_applied.append({"type": "permissions_granted", "database": db_name, "user": username})
                else:
                    logger.error(f"权限授予失败: {result.stderr}")
                    
        except Exception as e:
            logger.error(f"修复缺失数据库失败: {e}")
                
                # 设置环境变量并使用createdb命令
                env = os.environ.copy()
                env['PGPASSWORD'] = password
                
                result = subprocess.run([
                    'createdb', '-h', 'localhost', '-p', '5432', '-U', username, db_name
                ], env=env, capture_output=True, text=True)
                
                if result.returncode == 0:
                    self.fixes_applied.append({
                        "type": "database_created",
                        "message": f"创建数据库 '{db_name}'"
                    })
                    logger.info(f"成功创建数据库 '{db_name}'")
                else:
                    logger.error(f"创建数据库失败: {result.stderr}")
                    
        except Exception as e:
            logger.error(f"创建数据库失败: {e}")
    
    def _fix_missing_user(self):
        """修复缺失的用户"""
        try:
            if self.db_url.startswith("postgresql://"):
                username = self.db_url.split("://")[1].split(":")[0]
                password = self.db_url.split("://")[1].split(":")[1].split("@")[0]
                
                # 使用sudo权限创建用户
                result = subprocess.run([
                    'sudo', '-u', 'postgres', 'psql', '-c',
                    f"CREATE USER {username} WITH PASSWORD '{password}' SUPERUSER;"
                ], capture_output=True, text=True)
                
                if result.returncode == 0:
                    logger.info(f"用户 {username} 创建成功")
                    self.fixes_applied.append({"type": "user_created", "user": username})
                else:
                    # 如果用户已存在，尝试授予权限
                    logger.warning(f"用户创建失败（可能已存在）: {result.stderr}")
                    
                    # 授予超级用户权限
                    result = subprocess.run([
                        'sudo', '-u', 'postgres', 'psql', '-c',
                        f"ALTER USER {username} WITH SUPERUSER;"
                    ], capture_output=True, text=True)
                    
                    if result.returncode == 0:
                        logger.info(f"用户 {username} 权限修复成功")
                        self.fixes_applied.append({"type": "user_permission_fixed", "user": username})
                    else:
                        logger.error(f"用户权限修复失败: {result.stderr}")
                    
        except Exception as e:
            logger.error(f"修复缺失用户失败: {e}")
    
    def _fix_connect_permissions(self):
        """修复连接权限"""
        try:
            if self.db_url.startswith("postgresql://"):
                username = self.db_url.split("://")[1].split(":")[0]
                db_name = self.db_url.split("/")[-1].split("?")[0]
                
                # 使用系统命令授予权限，避免认证问题
                import subprocess
                
                # 设置环境变量并使用psql命令
                env = os.environ.copy()
                env['PGPASSWORD'] = 'password'  # 使用默认postgres密码
                
                result = subprocess.run([
                    'psql', '-h', 'localhost', '-p', '5432', '-U', 'postgres', '-d', 'postgres',
                    '-c', f"GRANT CONNECT ON DATABASE {db_name} TO {username}"
                ], env=env, capture_output=True, text=True)
                
                if result.returncode == 0:
                    self.fixes_applied.append({
                        "type": "permission_granted",
                        "message": f"授予用户 '{username}' 连接数据库 '{db_name}' 的权限"
                    })
                    logger.info(f"成功授予连接权限")
                else:
                    logger.error(f"授予连接权限失败: {result.stderr}")
                
        except Exception as e:
            logger.error(f"授予连接权限失败: {e}")
    
    def _fix_create_permissions(self):
        """修复创建权限"""
        try:
            if self.db_url.startswith("postgresql://"):
                username = self.db_url.split("://")[1].split(":")[0]
                db_name = self.db_url.split("/")[-1].split("?")[0]
                
                # 连接到目标数据库授予权限
                temp_engine = create_engine(self.db_url)
                
                with temp_engine.connect() as conn:
                    conn.execute(text(f"GRANT CREATE ON SCHEMA public TO {username}"))
                    conn.execute(text(f"GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO {username}"))
                    conn.execute(text(f"GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO {username}"))
                    conn.commit()
                
                self.fixes_applied.append({
                    "type": "permission_granted",
                    "message": f"授予用户 '{username}' 在数据库 '{db_name}' 上的完整权限"
                })
                logger.info(f"成功授予完整权限")
                
        except Exception as e:
            logger.error(f"授予创建权限失败: {e}")


def check_and_fix_database():
    """
    检查并修复数据库问题
    返回True表示数据库健康，False表示存在问题
    """
    try:
        from .config import settings
        
        # 首先尝试PostgreSQL连接
        checker = DatabaseHealthChecker()
        health_status = checker.check_database_health()
        
        if health_status["healthy"]:
            return True
        
        # 尝试修复
        success = checker.fix_database_issues()
        
        if not success:
            logger.warning("PostgreSQL connection failed, attempting to switch to SQLite fallback")
            
            # 设置SQLite回退标志
            import os
            os.environ["USE_SQLITE_FALLBACK"] = "true"
            
            # 检查SQLite数据库
            sqlite_db_url = f"sqlite:///{settings.SQLITE_DATABASE_PATH}"
            sqlite_checker = DatabaseHealthChecker()
            sqlite_checker.db_url = sqlite_db_url
            sqlite_checker.engine = create_engine(sqlite_db_url)
            
            sqlite_health_status = sqlite_checker.check_database_health()
            
            if sqlite_health_status["healthy"]:
                logger.info("Successfully switched to SQLite database")
                return True
            else:
                logger.error("Both PostgreSQL and SQLite connections failed")
                return False
        
        return True
        
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        
        # 尝试SQLite回退
        try:
            from .config import settings
            import os
            os.environ["USE_SQLITE_FALLBACK"] = "true"
            
            sqlite_db_url = f"sqlite:///{settings.SQLITE_DATABASE_PATH}"
            sqlite_checker = DatabaseHealthChecker()
            sqlite_checker.db_url = sqlite_db_url
            sqlite_checker.engine = create_engine(sqlite_db_url)
            
            health_status = sqlite_checker.check_database_health()
            return health_status["healthy"]
        except Exception as sqlite_error:
            logger.error(f"SQLite fallback also failed: {sqlite_error}")
            return False