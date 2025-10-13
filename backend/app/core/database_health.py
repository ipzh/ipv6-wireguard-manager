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
                # 提取用户名
                username = self.db_url.split("://")[1].split(":")[0]
                
                with self.engine.connect() as conn:
                    # 检查用户是否存在
                    result = conn.execute(
                        text("SELECT 1 FROM pg_roles WHERE rolname = :username"),
                        {"username": username}
                    )
                    if not result.scalar():
                        self.issues_found.append({
                            "type": "user_missing",
                            "message": f"数据库用户 '{username}' 不存在",
                            "severity": "critical"
                        })
                        return
                    
                    # 检查用户权限
                    result = conn.execute(
                        text("""
                            SELECT has_database_privilege(:username, :db_name, 'CONNECT') as can_connect,
                                   has_database_privilege(:username, :db_name, 'CREATE') as can_create
                        """),
                        {
                            "username": username,
                            "db_name": self.db_url.split("/")[-1].split("?")[0]
                        }
                    )
                    row = result.fetchone()
                    if row:
                        if not row[0]:  # can_connect
                            self.issues_found.append({
                                "type": "permission_connect",
                                "message": f"用户 '{username}' 没有数据库连接权限",
                                "severity": "critical"
                            })
                        if not row[1]:  # can_create
                            self.issues_found.append({
                                "type": "permission_create",
                                "message": f"用户 '{username}' 没有数据库创建权限",
                                "severity": "warning"
                            })
                            
        except Exception as e:
            logger.warning(f"用户权限检查失败: {e}")
    
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
                password = self.db_url.split("://")[1].split(":")[1].split("@")[0]
                
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
                
                # 使用系统命令创建用户，避免认证问题
                import subprocess
                
                # 设置环境变量并使用createuser命令
                env = os.environ.copy()
                env['PGPASSWORD'] = 'password'  # 使用默认postgres密码
                
                result = subprocess.run([
                    'createuser', '-h', 'localhost', '-p', '5432', '-U', 'postgres', 
                    '--createdb', '--login', '--pwprompt', username
                ], env=env, capture_output=True, text=True, input=password)
                
                if result.returncode == 0:
                    self.fixes_applied.append({
                        "type": "user_created",
                        "message": f"创建用户 '{username}'"
                    })
                    logger.info(f"成功创建用户 '{username}'")
                else:
                    logger.error(f"创建用户失败: {result.stderr}")
                
        except Exception as e:
            logger.error(f"创建用户失败: {e}")
    
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


def check_and_fix_database() -> bool:
    """检查并修复数据库问题（主入口函数）"""
    checker = DatabaseHealthChecker()
    
    # 检查数据库健康状态
    health_status = checker.check_database_health()
    
    if health_status["healthy"]:
        logger.info("数据库健康，无需修复")
        return True
    
    # 显示发现的问题
    logger.warning(f"发现 {len(health_status['issues'])} 个数据库问题:")
    for issue in health_status["issues"]:
        logger.warning(f"  - {issue['message']} ({issue['severity']})")
    
    # 尝试自动修复
    logger.info("开始自动修复数据库问题...")
    success = checker.fix_database_issues()
    
    if success:
        logger.info("数据库问题修复成功")
    else:
        logger.error("数据库问题修复失败，需要手动干预")
    
    return success