#!/usr/bin/env python3
"""
修复导入和目录创建问题的专用脚本
解决后端启动时的导入错误和权限问题
"""

import os
import sys
import shutil
from pathlib import Path
import logging

# 设置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def fix_import_issues():
    """修复导入问题"""
    logger.info("修复导入问题...")
    
    backend_path = Path("backend")
    
    # 1. 修复security.py中的导入问题
    security_file = backend_path / "app/core/security.py"
    if security_file.exists():
        try:
            with open(security_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 修复User模型导入
            if "from ..schemas.user import User" in content:
                content = content.replace(
                    "from ..schemas.user import User",
                    "from ...schemas.user import User"
                )
                with open(security_file, 'w', encoding='utf-8') as f:
                    f.write(content)
                logger.info("修复了security.py中的User模型导入")
        except Exception as e:
            logger.error(f"修复security.py失败: {e}")
    
    # 2. 修复dependencies.py中的导入问题
    deps_file = backend_path / "app/dependencies.py"
    if deps_file.exists():
        try:
            with open(deps_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 修复config导入
            if "from .core.config import settings" in content:
                content = content.replace(
                    "from .core.config import settings",
                    "from .core.config_enhanced import settings"
                )
                with open(deps_file, 'w', encoding='utf-8') as f:
                    f.write(content)
                logger.info("修复了dependencies.py中的config导入")
        except Exception as e:
            logger.error(f"修复dependencies.py失败: {e}")

def create_necessary_directories():
    """创建必要的目录"""
    logger.info("创建必要的目录...")
    
    directories = [
        "backend/uploads",
        "backend/logs", 
        "backend/temp",
        "backend/backups",
        "backend/config",
        "backend/data",
        "backend/wireguard",
        "backend/wireguard/clients"
    ]
    
    for directory in directories:
        try:
            dir_path = Path(directory)
            dir_path.mkdir(parents=True, exist_ok=True)
            logger.info(f"创建目录: {directory}")
        except Exception as e:
            logger.error(f"创建目录失败 {directory}: {e}")

def fix_model_issues():
    """修复模型问题"""
    logger.info("修复模型问题...")
    
    backend_path = Path("backend")
    
    # 修复所有模型文件中的UUID和PostgreSQL特定类型
    model_files = [
        "app/models/user.py",
        "app/models/wireguard.py", 
        "app/models/network.py",
        "app/models/monitoring.py",
        "app/models/bgp.py",
        "app/models/ipv6.py",
        "app/models/ipv6_pool.py",
        "app/models/config.py"
    ]
    
    for model_file in model_files:
        file_path = backend_path / model_file
        if file_path.exists():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 替换PostgreSQL特定导入
                if "from sqlalchemy.dialects.postgresql import UUID, JSONB" in content:
                    content = content.replace(
                        "from sqlalchemy.dialects.postgresql import UUID, JSONB",
                        "from sqlalchemy import Integer"
                    )
                    logger.info(f"修复了 {model_file} 中的PostgreSQL导入")
                
                # 替换UUID类型
                if "UUID(as_uuid=True)" in content:
                    content = content.replace("UUID(as_uuid=True)", "Integer")
                    logger.info(f"修复了 {model_file} 中的UUID类型")
                
                # 替换JSONB类型
                if "JSONB" in content:
                    content = content.replace("JSONB", "Text")
                    logger.info(f"修复了 {model_file} 中的JSONB类型")
                
                # 替换uuid.uuid4默认值
                if "default=uuid.uuid4" in content:
                    content = content.replace("default=uuid.uuid4", "autoincrement=True")
                    logger.info(f"修复了 {model_file} 中的UUID默认值")
                
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                    
            except Exception as e:
                logger.error(f"修复模型文件失败 {model_file}: {e}")

def fix_schema_issues():
    """修复模式问题"""
    logger.info("修复模式问题...")
    
    backend_path = Path("backend")
    
    # 修复所有模式文件中的UUID类型
    schema_files = [
        "app/schemas/user.py",
        "app/schemas/wireguard.py",
        "app/schemas/network.py", 
        "app/schemas/monitoring.py",
        "app/schemas/bgp.py",
        "app/schemas/ipv6.py",
        "app/schemas/config.py"
    ]
    
    for schema_file in schema_files:
        file_path = backend_path / schema_file
        if file_path.exists():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 替换uuid.UUID类型
                if "uuid.UUID" in content:
                    content = content.replace("uuid.UUID", "int")
                    logger.info(f"修复了 {schema_file} 中的UUID类型")
                
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                    
            except Exception as e:
                logger.error(f"修复模式文件失败 {schema_file}: {e}")

def fix_database_config():
    """修复数据库配置"""
    logger.info("修复数据库配置...")
    
    backend_path = Path("backend")
    
    # 修复database.py中的配置导入
    db_file = backend_path / "app/core/database.py"
    if db_file.exists():
        try:
            with open(db_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 修复config导入
            if "from .config import settings" in content:
                content = content.replace(
                    "from .config import settings",
                    "from .config_enhanced import settings"
                )
                with open(db_file, 'w', encoding='utf-8') as f:
                    f.write(content)
                logger.info("修复了database.py中的config导入")
        except Exception as e:
            logger.error(f"修复database.py失败: {e}")

def main():
    """主函数"""
    logger.info("开始修复导入和目录问题...")
    
    try:
        # 修复导入问题
        fix_import_issues()
        
        # 创建必要目录
        create_necessary_directories()
        
        # 修复模型问题
        fix_model_issues()
        
        # 修复模式问题
        fix_schema_issues()
        
        # 修复数据库配置
        fix_database_config()
        
        logger.info("所有修复完成！")
        
    except Exception as e:
        logger.error(f"修复过程中出现错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
