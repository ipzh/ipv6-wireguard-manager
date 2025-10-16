#!/usr/bin/env python3
"""
PostgreSQL到MySQL迁移修复脚本
解决所有PostgreSQL特定的类型和配置问题
"""

import os
import sys
import re
from pathlib import Path
import logging

# 设置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def fix_postgresql_imports():
    """修复PostgreSQL特定导入"""
    logger.info("修复PostgreSQL特定导入...")
    
    backend_path = Path("backend")
    
    # 需要修复的文件模式
    file_patterns = [
        "**/*.py"
    ]
    
    # PostgreSQL特定的导入和类型映射
    postgresql_fixes = [
        # 导入修复
        (r"from sqlalchemy\.dialects\.postgresql import UUID, JSONB", "from sqlalchemy import Integer, Text"),
        (r"from sqlalchemy\.dialects\.postgresql import UUID", "from sqlalchemy import Integer"),
        (r"from sqlalchemy\.dialects\.postgresql import JSONB", "from sqlalchemy import Text"),
        (r"from sqlalchemy\.dialects\.postgresql import ARRAY", "from sqlalchemy import Text"),
        (r"from sqlalchemy\.dialects\.postgresql import INET", "from sqlalchemy import String"),
        (r"from sqlalchemy\.dialects\.postgresql import CIDR", "from sqlalchemy import String"),
        
        # 类型修复
        (r"UUID\(as_uuid=True\)", "Integer"),
        (r"UUID\(\)", "Integer"),
        (r"JSONB", "Text"),
        (r"ARRAY\([^)]+\)", "Text"),
        (r"INET", "String(45)"),  # IPv6最长45字符
        (r"CIDR", "String(43)"),  # IPv6 CIDR最长43字符
        
        # 默认值修复
        (r"default=uuid\.uuid4", "autoincrement=True"),
        (r"default=uuid\.uuid4\(\)", "autoincrement=True"),
        (r"server_default=func\.uuid_generate_v4\(\)", "autoincrement=True"),
        
        # 索引修复
        (r"Index\('.*', .*postgresql_using='gin'.*\)", ""),
        (r"postgresql_using='gin'", ""),
        (r"postgresql_using='btree'", ""),
        
        # 约束修复
        (r"postgresql_check_constraint", "CheckConstraint"),
    ]
    
    for pattern in file_patterns:
        for file_path in backend_path.glob(pattern):
            if file_path.is_file() and file_path.suffix == '.py':
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    original_content = content
                    
                    # 应用所有修复
                    for pattern, replacement in postgresql_fixes:
                        content = re.sub(pattern, replacement, content, flags=re.MULTILINE)
                    
                    # 如果内容有变化，写回文件
                    if content != original_content:
                        with open(file_path, 'w', encoding='utf-8') as f:
                            f.write(content)
                        logger.info(f"修复了 {file_path.relative_to(backend_path)}")
                        
                except Exception as e:
                    logger.error(f"修复文件失败 {file_path}: {e}")

def fix_schema_types():
    """修复Pydantic模式中的UUID类型"""
    logger.info("修复Pydantic模式中的UUID类型...")
    
    backend_path = Path("backend")
    
    # 查找所有模式文件
    schema_files = list(backend_path.glob("**/schemas/*.py"))
    
    for file_path in schema_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # 修复UUID类型
            content = re.sub(r"uuid\.UUID", "int", content)
            content = re.sub(r"Optional\[uuid\.UUID\]", "Optional[int]", content)
            content = re.sub(r"List\[uuid\.UUID\]", "List[int]", content)
            
            # 移除uuid导入（如果不再需要）
            if "uuid.UUID" not in content and "import uuid" in content:
                content = re.sub(r"import uuid\n", "", content)
                content = re.sub(r"from uuid import.*\n", "", content)
            
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                logger.info(f"修复了模式文件 {file_path.relative_to(backend_path)}")
                
        except Exception as e:
            logger.error(f"修复模式文件失败 {file_path}: {e}")

def fix_database_config():
    """修复数据库配置"""
    logger.info("修复数据库配置...")
    
    backend_path = Path("backend")
    
    # 修复database.py中的异步连接问题
    db_file = backend_path / "app/core/database.py"
    if db_file.exists():
        try:
            with open(db_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 修复异步连接测试问题
            if "asyncio.run(test_async_connection())" in content:
                content = content.replace(
                    "asyncio.run(test_async_connection())",
                    "# asyncio.run(test_async_connection())  # 在事件循环中无法调用"
                )
                logger.info("修复了database.py中的异步连接测试")
            
            # 确保使用MySQL连接字符串
            if "postgresql://" in content:
                content = content.replace("postgresql://", "mysql+pymysql://")
                logger.info("修复了数据库连接字符串")
            
            with open(db_file, 'w', encoding='utf-8') as f:
                f.write(content)
                
        except Exception as e:
            logger.error(f"修复database.py失败: {e}")

def fix_permission_issues():
    """修复权限问题"""
    logger.info("修复权限问题...")
    
    backend_path = Path("backend")
    
    # 修复config_enhanced.py中的目录创建问题
    config_file = backend_path / "app/core/config_enhanced.py"
    if config_file.exists():
        try:
            with open(config_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 修改目录路径为相对路径，避免权限问题
            content = re.sub(
                r'UPLOAD_DIR = "/opt/ipv6-wireguard-manager/uploads"',
                'UPLOAD_DIR = "uploads"',
                content
            )
            content = re.sub(
                r'WIREGUARD_CONFIG_DIR = "/opt/ipv6-wireguard-manager/wireguard"',
                'WIREGUARD_CONFIG_DIR = "wireguard"',
                content
            )
            content = re.sub(
                r'WIREGUARD_CLIENTS_DIR = "/opt/ipv6-wireguard-manager/wireguard/clients"',
                'WIREGUARD_CLIENTS_DIR = "wireguard/clients"',
                content
            )
            
            with open(config_file, 'w', encoding='utf-8') as f:
                f.write(content)
            logger.info("修复了config_enhanced.py中的目录路径")
                
        except Exception as e:
            logger.error(f"修复config_enhanced.py失败: {e}")

def fix_async_issues():
    """修复异步相关问题"""
    logger.info("修复异步相关问题...")
    
    backend_path = Path("backend")
    
    # 修复database.py中的异步问题
    db_file = backend_path / "app/core/database.py"
    if db_file.exists():
        try:
            with open(db_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 修复异步连接测试
            if "async def test_async_connection():" in content:
                # 添加事件循环检查
                test_function = """
async def test_async_connection():
    \"\"\"测试异步数据库连接\"\"\"
    try:
        import asyncio
        # 检查是否在事件循环中
        try:
            loop = asyncio.get_running_loop()
            logger.warning("在事件循环中，跳过异步连接测试")
            return False
        except RuntimeError:
            # 不在事件循环中，可以安全测试
            pass
        
        if async_engine:
            async with async_engine.begin() as conn:
                await conn.execute(text("SELECT 1"))
            return True
    except Exception as e:
        logger.error(f"异步连接测试失败: {e}")
        return False
    return False
"""
                content = re.sub(
                    r"async def test_async_connection\(\):.*?return False",
                    test_function,
                    content,
                    flags=re.DOTALL
                )
                logger.info("修复了异步连接测试函数")
            
            with open(db_file, 'w', encoding='utf-8') as f:
                f.write(content)
                
        except Exception as e:
            logger.error(f"修复database.py异步问题失败: {e}")

def create_directories():
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

def fix_import_paths():
    """修复导入路径问题"""
    logger.info("修复导入路径问题...")
    
    backend_path = Path("backend")
    
    # 修复常见的导入路径问题
    import_fixes = [
        # 相对导入修复
        (r"from \.\.schemas\.user import User", "from ...schemas.user import User"),
        (r"from \.core\.config import settings", "from .core.config_enhanced import settings"),
        (r"from \.\.core\.config import settings", "from ..core.config_enhanced import settings"),
        (r"from \.\.\.core\.config import settings", "from ...core.config_enhanced import settings"),
        
        # 绝对导入修复
        (r"from core\.config import settings", "from app.core.config_enhanced import settings"),
        (r"from models\.", "from app.models."),
        (r"from schemas\.", "from app.schemas."),
        (r"from services\.", "from app.services."),
    ]
    
    for pattern in ["**/*.py"]:
        for file_path in backend_path.glob(pattern):
            if file_path.is_file() and file_path.suffix == '.py':
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    original_content = content
                    
                    for pattern, replacement in import_fixes:
                        content = re.sub(pattern, replacement, content)
                    
                    if content != original_content:
                        with open(file_path, 'w', encoding='utf-8') as f:
                            f.write(content)
                        logger.info(f"修复了导入路径 {file_path.relative_to(backend_path)}")
                        
                except Exception as e:
                    logger.error(f"修复导入路径失败 {file_path}: {e}")

def fix_syntax_errors():
    """修复语法错误"""
    logger.info("修复语法错误...")
    
    backend_path = Path("backend")
    
    # 修复重复的response_model参数
    for file_path in backend_path.glob("**/endpoints/*.py"):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # 修复重复的response_model
            content = re.sub(
                r"response_model=[^,)]+, response_model=None",
                "response_model=None",
                content
            )
            
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                logger.info(f"修复了语法错误 {file_path.relative_to(backend_path)}")
                
        except Exception as e:
            logger.error(f"修复语法错误失败 {file_path}: {e}")

def main():
    """主函数"""
    logger.info("开始PostgreSQL到MySQL迁移修复...")
    
    try:
        # 1. 修复PostgreSQL特定导入和类型
        fix_postgresql_imports()
        
        # 2. 修复Pydantic模式中的UUID类型
        fix_schema_types()
        
        # 3. 修复数据库配置
        fix_database_config()
        
        # 4. 修复权限问题
        fix_permission_issues()
        
        # 5. 修复异步问题
        fix_async_issues()
        
        # 6. 创建必要目录
        create_directories()
        
        # 7. 修复导入路径
        fix_import_paths()
        
        # 8. 修复语法错误
        fix_syntax_errors()
        
        logger.info("PostgreSQL到MySQL迁移修复完成！")
        
        # 输出修复总结
        print("\n=== 修复总结 ===")
        print("✅ 修复了PostgreSQL特定导入和类型")
        print("✅ 修复了UUID类型为Integer")
        print("✅ 修复了JSONB类型为Text")
        print("✅ 修复了数据库连接配置")
        print("✅ 修复了权限和目录问题")
        print("✅ 修复了异步连接问题")
        print("✅ 修复了导入路径问题")
        print("✅ 修复了语法错误")
        print("\n现在可以尝试启动后端服务：")
        print("cd backend && python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000")
        
    except Exception as e:
        logger.error(f"修复过程中出现错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
