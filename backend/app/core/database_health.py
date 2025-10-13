"""
数据库健康检查和自动修复模块
专门处理VPS环境中的数据库配置问题
"""
import os
import sys
import subprocess
import logging
from typing import Optional, Dict, Any
from sqlalchemy import create_engine, text, MetaData, Table, Column, Integer, String
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
                result = conn.execute(text("SELECT 1"))
                if result.scalar() == 1:
                    logger.info("数据库连接正常")
                else:
                    self.issues_found.append({
                        "type": "connection",
                        "message": "数据库连接测试失败",
                        "severity": "critical"
                    })
        except Exception as e:
            error_msg = str(e)
            # 针对远程服务器连接错误进行特殊处理
            if "Connection refused" in error_msg or "10061" in error_msg:
                message = "远程数据库服务器连接被拒绝，请检查服务器是否运行"
            elif "timeout" in error_msg.lower():
                message = "数据库连接超时，请检查网络连接"
            elif "authentication failed" in error_msg.lower():
                message = "数据库认证失败，请检查用户名和密码"
            else:
                message = f"数据库连接失败: {error_msg}"
            
            self.issues_found.append({
                "type": "connection",
                "message": message,
                "severity": "critical"
            })
    
    def _check_database_exists(self):
        """检查数据库是否存在"""
        try:
            # 检查当前数据库是否存在
            with self.engine.connect() as conn:
                result = conn.execute(text("SELECT current_database()"))
                db_name = result.scalar()
                logger.info(f"数据库 {db_name} 存在")
        except Exception as e:
            error_msg = str(e)
            # 针对远程服务器错误进行特殊处理
            if "database" in error_msg.lower() and "does not exist" in error_msg.lower():
                message = "数据库不存在"
            else:
                message = f"数据库检查失败: {error_msg}"
            
            self.issues_found.append({
                "type": "database_missing",
                "message": message,
                "severity": "critical"
            })
    
    def _check_user_permissions(self):
        """检查用户权限"""
        try:
            with self.engine.connect() as conn:
                # 检查当前用户权限
                result = conn.execute(text("SELECT current_user"))
                current_user = result.scalar()
                
                # 检查连接权限
                result = conn.execute(text("SELECT has_database_privilege(current_user, current_database(), 'CONNECT')"))
                can_connect = result.scalar()
                
                # 检查创建权限
                result = conn.execute(text("SELECT has_database_privilege(current_user, current_database(), 'CREATE')"))
                can_create = result.scalar()
                
                if can_connect and can_create:
                    logger.info(f"用户 {current_user} 具有足够的权限")
                else:
                    self.issues_found.append({
                        "type": "permission_insufficient",
                        "message": f"用户 {current_user} 权限不足",
                        "severity": "warning"
                    })
        except Exception as e:
            error_msg = str(e)
            # 针对权限错误进行特殊处理
            if "permission" in error_msg.lower():
                message = "用户权限不足，无法访问数据库"
            else:
                message = f"权限检查失败: {error_msg}"
            
            self.issues_found.append({
                "type": "permission_error",
                "message": message,
                "severity": "critical"
            })
    
    def _check_tables(self):
        """检查核心表是否存在"""
        try:
            with self.engine.connect() as conn:
                # 检查用户表
                result = conn.execute(text("SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'users'"))
                users_table_exists = result.scalar() > 0
                
                # 检查WireGuard服务器表
                result = conn.execute(text("SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'wireguard_servers'"))
                servers_table_exists = result.scalar() > 0
                
                if users_table_exists and servers_table_exists:
                    logger.info("核心表存在")
                else:
                    self.issues_found.append({
                        "type": "table_missing",
                        "message": "部分核心表缺失",
                        "severity": "warning"
                    })
        except Exception as e:
            error_msg = str(e)
            # 针对表不存在错误进行特殊处理
            if "relation" in error_msg.lower() and "does not exist" in error_msg.lower():
                message = "数据库表不存在，需要初始化"
            else:
                message = f"表检查失败: {error_msg}"
            
            self.issues_found.append({
                "type": "table_error",
                "message": message,
                "severity": "warning"
            })
    
    def fix_database_issues(self) -> bool:
        """尝试修复数据库问题"""
        logger.info("开始修复数据库问题...")
        
        # 先检查连接是否正常，避免无限循环
        try:
            with self.engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            logger.info("数据库连接正常，无需修复")
            return True
        except Exception as e:
            logger.warning(f"数据库连接失败，尝试修复: {e}")
        
        # 尝试修复常见问题
        try:
            self._fix_missing_database()
            self._fix_missing_user()
            self._fix_connect_permissions()
            self._fix_create_permissions()
        except Exception as e:
            logger.error(f"修复过程中出错: {e}")
            return False
        
        # 重新检查连接
        try:
            with self.engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            logger.info("数据库问题修复成功")
            return True
        except Exception as e:
            logger.error(f"数据库问题修复失败: {e}")
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
            sqlite_db_url = settings.SQLITE_DATABASE_URL
            sqlite_checker = DatabaseHealthChecker()
            sqlite_checker.db_url = sqlite_db_url
            sqlite_checker.engine = create_engine(sqlite_db_url)
            
            # 直接尝试SQLite连接，不进行健康检查以避免循环
            try:
                with sqlite_checker.engine.connect() as conn:
                    conn.execute(text("SELECT 1"))
                logger.info("Successfully switched to SQLite database")
                return True
            except Exception as sqlite_error:
                logger.error(f"SQLite connection failed: {sqlite_error}")
                return False
        
        # 修复后再次检查PostgreSQL连接
        try:
            with checker.engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            return True
        except Exception as postgres_error:
            logger.error(f"PostgreSQL connection still failed after fixes: {postgres_error}")
            return False
        
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        
        # 尝试SQLite回退
        try:
            from .config import settings
            import os
            os.environ["USE_SQLITE_FALLBACK"] = "true"
            
            sqlite_db_url = settings.SQLITE_DATABASE_URL
            sqlite_checker = DatabaseHealthChecker()
            sqlite_checker.db_url = sqlite_db_url
            sqlite_checker.engine = create_engine(sqlite_db_url)
            
            # 直接尝试SQLite连接
            with sqlite_checker.engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            return True
        except Exception as sqlite_error:
            logger.error(f"SQLite fallback also failed: {sqlite_error}")
            return False