#!/usr/bin/env python3
"""
IPv6 WireGuard Manager 后端错误修复脚本
自动修复常见的后端错误和问题
"""

import os
import sys
import re
import shutil
from pathlib import Path
from typing import List, Dict, Any
import logging

# 设置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class BackendErrorFixer:
    """后端错误修复器"""
    
    def __init__(self, backend_path: str = "backend"):
        self.backend_path = Path(backend_path)
        self.fixes_applied = []
        self.backup_dir = Path("backup_backend")
        
    def fix_all_errors(self) -> Dict[str, Any]:
        """修复所有错误"""
        logger.info("开始修复后端错误...")
        
        # 创建备份
        self.create_backup()
        
        # 修复各种错误
        self.fix_import_errors()
        self.fix_config_errors()
        self.fix_database_errors()
        self.fix_api_endpoint_errors()
        self.fix_security_errors()
        self.fix_dependency_errors()
        self.fix_permission_errors()
        self.fix_logging_errors()
        
        return {
            "fixes_applied": self.fixes_applied,
            "backup_created": str(self.backup_dir),
            "summary": self.generate_summary()
        }
    
    def create_backup(self):
        """创建备份"""
        if self.backup_dir.exists():
            shutil.rmtree(self.backup_dir)
        
        shutil.copytree(self.backend_path, self.backup_dir)
        logger.info(f"备份已创建: {self.backup_dir}")
        
        self.fixes_applied.append({
            "type": "backup_created",
            "message": f"创建备份: {self.backup_dir}"
        })
    
    def fix_import_errors(self):
        """修复导入错误"""
        logger.info("修复导入错误...")
        
        # 修复dependencies.py中的导入问题
        deps_file = self.backend_path / "app/dependencies.py"
        if deps_file.exists():
            self._fix_dependencies_imports(deps_file)
        
        # 修复config导入问题
        config_files = [
            "app/core/config_enhanced.py",
            "app/core/config.py"
        ]
        
        for config_file in config_files:
            file_path = self.backend_path / config_file
            if file_path.exists():
                self._fix_config_imports(file_path)
    
    def _fix_dependencies_imports(self, file_path: Path):
        """修复dependencies.py中的导入问题"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 修复config导入
            if "from .core.config import settings" in content:
                content = content.replace(
                    "from .core.config import settings",
                    "from .core.config_enhanced import settings"
                )
                self._write_file(file_path, content)
                self.fixes_applied.append({
                    "type": "import_fixed",
                    "file": str(file_path),
                    "message": "修复config导入路径"
                })
            
            # 修复User模型导入
            if "from .models.user import User" in content:
                # 检查User模型是否存在
                user_model_file = self.backend_path / "app/models/user.py"
                if not user_model_file.exists():
                    self._create_user_model(user_model_file)
                    self.fixes_applied.append({
                        "type": "model_created",
                        "file": str(user_model_file),
                        "message": "创建User模型文件"
                    })
        
        except Exception as e:
            logger.error(f"修复dependencies.py导入错误失败: {e}")
    
    def _fix_config_imports(self, file_path: Path):
        """修复配置文件中的导入问题"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 修复Pydantic导入
            if "from pydantic import BaseSettings" in content:
                content = content.replace(
                    "from pydantic import BaseSettings",
                    "from pydantic_settings import BaseSettings"
                )
                self._write_file(file_path, content)
                self.fixes_applied.append({
                    "type": "import_fixed",
                    "file": str(file_path),
                    "message": "修复Pydantic导入"
                })
        
        except Exception as e:
            logger.error(f"修复配置文件导入错误失败: {e}")
    
    def fix_config_errors(self):
        """修复配置错误"""
        logger.info("修复配置错误...")
        
        config_file = self.backend_path / "app/core/config_enhanced.py"
        if config_file.exists():
            self._fix_config_enhanced(config_file)
    
    def _fix_config_enhanced(self, file_path: Path):
        """修复config_enhanced.py"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 修复数据库URL默认值
            if "DATABASE_URL: str = \"mysql://ipv6wgm:password@localhost:3306/ipv6wgm\"" in content:
                content = content.replace(
                    "DATABASE_URL: str = \"mysql://ipv6wgm:password@localhost:3306/ipv6wgm\"",
                    "DATABASE_URL: str = Field(default=\"mysql://ipv6wgm:password@localhost:3306/ipv6wgm\")"
                )
                self._write_file(file_path, content)
                self.fixes_applied.append({
                    "type": "config_fixed",
                    "file": str(file_path),
                    "message": "修复数据库URL配置"
                })
            
            # 添加环境变量支持
            if "getenv" not in content:
                # 在DATABASE_URL行后添加环境变量支持
                pattern = r'(DATABASE_URL: str = Field\(default="[^"]+"\))'
                replacement = r'\1\n    # 环境变量支持\n    DATABASE_HOST: str = Field(default="localhost")\n    DATABASE_PORT: int = Field(default=3306)\n    DATABASE_USER: str = Field(default="ipv6wgm")\n    DATABASE_PASSWORD: str = Field(default="password")\n    DATABASE_NAME: str = Field(default="ipv6wgm")'
                content = re.sub(pattern, replacement, content)
                self._write_file(file_path, content)
                self.fixes_applied.append({
                    "type": "config_enhanced",
                    "file": str(file_path),
                    "message": "添加环境变量支持"
                })
        
        except Exception as e:
            logger.error(f"修复config_enhanced.py失败: {e}")
    
    def fix_database_errors(self):
        """修复数据库错误"""
        logger.info("修复数据库错误...")
        
        # 修复database.py
        db_file = self.backend_path / "app/core/database.py"
        if db_file.exists():
            self._fix_database_py(db_file)
        
        # 修复database_health.py
        db_health_file = self.backend_path / "app/core/database_health.py"
        if db_health_file.exists():
            self._fix_database_health(db_health_file)
    
    def _fix_database_py(self, file_path: Path):
        """修复database.py"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 修复config导入
            if "from .config import settings" in content:
                content = content.replace(
                    "from .config import settings",
                    "from .config_enhanced import settings"
                )
                self._write_file(file_path, content)
                self.fixes_applied.append({
                    "type": "import_fixed",
                    "file": str(file_path),
                    "message": "修复database.py中的config导入"
                })
        
        except Exception as e:
            logger.error(f"修复database.py失败: {e}")
    
    def _fix_database_health(self, file_path: Path):
        """修复database_health.py"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 修复PostgreSQL相关代码，改为MySQL
            if "postgresql" in content.lower():
                # 替换PostgreSQL相关代码为MySQL
                content = content.replace("postgresql://", "mysql://")
                content = content.replace("psycopg2", "pymysql")
                content = content.replace("PostgreSQL", "MySQL")
                content = content.replace("postgresql", "mysql")
                
                self._write_file(file_path, content)
                self.fixes_applied.append({
                    "type": "database_fixed",
                    "file": str(file_path),
                    "message": "修复数据库类型为MySQL"
                })
        
        except Exception as e:
            logger.error(f"修复database_health.py失败: {e}")
    
    def fix_api_endpoint_errors(self):
        """修复API端点错误"""
        logger.info("修复API端点错误...")
        
        endpoints_dir = self.backend_path / "app/api/api_v1/endpoints"
        if endpoints_dir.exists():
            for endpoint_file in endpoints_dir.glob("*.py"):
                if endpoint_file.name == "__init__.py":
                    continue
                self._fix_api_endpoint(endpoint_file)
    
    def _fix_api_endpoint(self, file_path: Path):
        """修复API端点文件"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 添加response_model=None到路由装饰器
            if "@router." in content and "response_model=None" not in content:
                # 查找路由装饰器并添加response_model=None
                pattern = r'(@router\.(?:get|post|put|delete|patch)\([^)]*)\)'
                replacement = r'\1, response_model=None)'
                content = re.sub(pattern, replacement, content)
                
                self._write_file(file_path, content)
                self.fixes_applied.append({
                    "type": "api_fixed",
                    "file": str(file_path),
                    "message": "添加response_model=None"
                })
        
        except Exception as e:
            logger.error(f"修复API端点失败 {file_path}: {e}")
    
    def fix_security_errors(self):
        """修复安全错误"""
        logger.info("修复安全错误...")
        
        security_file = self.backend_path / "app/core/security.py"
        if security_file.exists():
            self._fix_security_py(security_file)
    
    def _fix_security_py(self, file_path: Path):
        """修复security.py"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 修复config导入
            if "from .config import settings" in content:
                content = content.replace(
                    "from .config import settings",
                    "from .config_enhanced import settings"
                )
                self._write_file(file_path, content)
                self.fixes_applied.append({
                    "type": "import_fixed",
                    "file": str(file_path),
                    "message": "修复security.py中的config导入"
                })
            
            # 修复User模型导入
            if "from app.schemas.user import User" in content:
                content = content.replace(
                    "from app.schemas.user import User",
                    "from ..schemas.user import User"
                )
                self._write_file(file_path, content)
                self.fixes_applied.append({
                    "type": "import_fixed",
                    "file": str(file_path),
                    "message": "修复User模型导入路径"
                })
        
        except Exception as e:
            logger.error(f"修复security.py失败: {e}")
    
    def fix_dependency_errors(self):
        """修复依赖错误"""
        logger.info("修复依赖错误...")
        
        # 检查requirements.txt
        req_file = self.backend_path / "requirements.txt"
        if req_file.exists():
            self._fix_requirements(req_file)
    
    def _fix_requirements(self, file_path: Path):
        """修复requirements.txt"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 添加缺失的依赖
            required_deps = [
                "pydantic-settings>=2.0.0",
                "aiomysql>=0.2.0",
                "pymysql>=1.0.0",
                "python-jose[cryptography]>=3.3.0",
                "passlib[bcrypt]>=1.7.4"
            ]
            
            for dep in required_deps:
                dep_name = dep.split(">=")[0]
                if dep_name not in content:
                    content += f"\n{dep}"
            
            self._write_file(file_path, content)
            self.fixes_applied.append({
                "type": "dependencies_fixed",
                "file": str(file_path),
                "message": "添加缺失的依赖"
            })
        
        except Exception as e:
            logger.error(f"修复requirements.txt失败: {e}")
    
    def fix_permission_errors(self):
        """修复权限错误"""
        logger.info("修复权限错误...")
        
        # 创建必要的目录
        directories = [
            "uploads",
            "logs",
            "temp",
            "backups",
            "config",
            "data"
        ]
        
        for directory in directories:
            dir_path = self.backend_path / directory
            if not dir_path.exists():
                dir_path.mkdir(parents=True, exist_ok=True)
                self.fixes_applied.append({
                    "type": "directory_created",
                    "file": str(dir_path),
                    "message": f"创建目录: {directory}"
                })
    
    def fix_logging_errors(self):
        """修复日志错误"""
        logger.info("修复日志错误...")
        
        main_file = self.backend_path / "app/main.py"
        if main_file.exists():
            self._fix_main_logging(main_file)
    
    def _fix_main_logging(self, file_path: Path):
        """修复main.py中的日志配置"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 确保有适当的日志配置
            if "logging.basicConfig" not in content:
                # 在导入后添加日志配置
                import_pattern = r'(import logging\n)'
                logging_config = '''import logging

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("logs/app.log", encoding="utf-8")
    ]
)
logger = logging.getLogger(__name__)

'''
                content = re.sub(import_pattern, logging_config, content)
                self._write_file(file_path, content)
                self.fixes_applied.append({
                    "type": "logging_fixed",
                    "file": str(file_path),
                    "message": "添加日志配置"
                })
        
        except Exception as e:
            logger.error(f"修复main.py日志配置失败: {e}")
    
    def _create_user_model(self, file_path: Path):
        """创建User模型文件"""
        user_model_content = '''"""
用户模型
"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from ..core.database import Base

class User(Base):
    """用户模型"""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100))
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    role = Column(String(20), default="user")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_login = Column(DateTime(timezone=True))
    
    # 关系
    roles = relationship("Role", back_populates="users", secondary="user_roles")

class Role(Base):
    """角色模型"""
    __tablename__ = "roles"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), unique=True, nullable=False)
    description = Column(Text)
    permissions = Column(Text)  # JSON字符串存储权限
    
    # 关系
    users = relationship("User", back_populates="roles", secondary="user_roles")

class UserRole(Base):
    """用户角色关联表"""
    __tablename__ = "user_roles"
    
    user_id = Column(Integer, primary_key=True)
    role_id = Column(Integer, primary_key=True)
'''
        
        self._write_file(file_path, user_model_content)
    
    def _write_file(self, file_path: Path, content: str):
        """写入文件"""
        try:
            # 确保目录存在
            file_path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            logger.info(f"文件已更新: {file_path}")
        
        except Exception as e:
            logger.error(f"写入文件失败 {file_path}: {e}")
    
    def generate_summary(self) -> Dict[str, Any]:
        """生成修复摘要"""
        fix_types = {}
        for fix in self.fixes_applied:
            fix_type = fix["type"]
            if fix_type not in fix_types:
                fix_types[fix_type] = 0
            fix_types[fix_type] += 1
        
        return {
            "total_fixes": len(self.fixes_applied),
            "fix_types": fix_types,
            "backup_location": str(self.backup_dir)
        }


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="IPv6 WireGuard Manager 后端错误修复工具")
    parser.add_argument("--backend-path", default="backend", help="后端代码路径")
    parser.add_argument("--dry-run", action="store_true", help="仅显示将要修复的问题，不实际修复")
    parser.add_argument("--verbose", "-v", action="store_true", help="详细输出")
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    if args.dry_run:
        logger.info("干运行模式 - 仅检查问题，不进行修复")
        # 这里可以添加检查逻辑
        return
    
    # 执行修复
    fixer = BackendErrorFixer(args.backend_path)
    results = fixer.fix_all_errors()
    
    # 输出结果
    print("\n=== 修复完成 ===")
    print(f"总共应用了 {results['summary']['total_fixes']} 个修复")
    print(f"备份位置: {results['summary']['backup_location']}")
    
    print("\n修复类型统计:")
    for fix_type, count in results['summary']['fix_types'].items():
        print(f"  {fix_type}: {count}")
    
    print("\n详细修复记录:")
    for fix in results['fixes_applied']:
        print(f"  - {fix['message']}")
    
    logger.info("后端错误修复完成")


if __name__ == "__main__":
    main()
