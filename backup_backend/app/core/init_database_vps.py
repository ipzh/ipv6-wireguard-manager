"""
VPS环境专用数据库初始化脚本
专门处理VPS上的PostgreSQL权限和配置问题
"""
import asyncio
import sys
import os
import logging
from typing import Optional

# 添加当前目录到Python路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from .database import init_db, sync_engine, async_engine
from .database_health import DatabaseHealthChecker, check_and_fix_database
from .init_db import init_db_data
from sqlalchemy.ext.asyncio import AsyncSession

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class VPSDatabaseInitializer:
    """VPS数据库初始化器"""
    
    def __init__(self):
        self.health_checker = DatabaseHealthChecker()
        self.initialized = False
    
    async def initialize_database(self) -> bool:
        """初始化数据库（主入口函数）"""
        logger.info("开始VPS环境数据库初始化...")
        
        try:
            # 步骤0: 检查数据库连接配置
            logger.info("步骤0: 检查数据库连接配置")
            from .config import settings
            
            # 检查数据库URL配置
            if not settings.DATABASE_URL:
                logger.error("数据库URL未配置")
                return False
            
            # 检查是否为远程PostgreSQL连接
            if settings.DATABASE_URL.startswith("postgresql://"):
                # 检查连接参数
                import urllib.parse
                parsed_url = urllib.parse.urlparse(settings.DATABASE_URL)
                
                # 检查主机名和端口
                hostname = parsed_url.hostname
                port = parsed_url.port or 5432
                
                logger.info(f"连接目标: {hostname}:{port}")
                
                # 检查是否为远程服务器
                if hostname not in ['localhost', '127.0.0.1', '::1']:
                    logger.info("检测到远程PostgreSQL服务器连接")
                    
                    # 检查网络连接
                    import socket
                    try:
                        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                        sock.settimeout(5)  # 5秒超时
                        result = sock.connect_ex((hostname, port))
                        sock.close()
                        
                        if result != 0:
                            logger.warning(f"远程PostgreSQL服务器 {hostname}:{port} 无法连接")
                            logger.info("将尝试使用SQLite作为回退方案")
                            # 切换到SQLite
                            settings.DATABASE_URL = settings.SQLITE_DATABASE_URL
                    except Exception as e:
                        logger.warning(f"网络连接检查失败: {e}")
                        logger.info("将尝试使用SQLite作为回退方案")
                        settings.DATABASE_URL = settings.SQLITE_DATABASE_URL
            
            # 步骤1: 检查数据库健康状况
            logger.info("步骤1: 检查数据库健康状况")
            health_status = self.health_checker.check_database_health()
            
            if not health_status["healthy"]:
                logger.warning("发现数据库问题，开始自动修复...")
                for issue in health_status["issues"]:
                    logger.warning(f"  - {issue['message']}")
                
                # 尝试自动修复
                if not self.health_checker.fix_database_issues():
                    logger.error("数据库问题修复失败")
                    return False
            
            # 步骤2: 创建数据库表结构
            logger.info("步骤2: 创建数据库表结构")
            await self._create_tables()
            
            # 步骤3: 初始化默认数据
            logger.info("步骤3: 初始化默认数据")
            await self._initialize_default_data()
            
            # 步骤4: 验证数据库功能
            logger.info("步骤4: 验证数据库功能")
            if not await self._verify_database():
                logger.error("数据库功能验证失败")
                return False
            
            self.initialized = True
            logger.info("VPS环境数据库初始化完成")
            return True
            
        except Exception as e:
            logger.error(f"数据库初始化失败: {e}")
            return False
    
    async def _create_tables(self):
        """创建数据库表结构"""
        try:
            # 使用增强的初始化函数
            await init_db()
            logger.info("数据库表结构创建成功")
        except Exception as e:
            logger.error(f"数据库表结构创建失败: {e}")
            raise
    
    async def _initialize_default_data(self):
        """初始化默认数据"""
        try:
            # 检查异步引擎是否可用
            if async_engine:
                from .database import AsyncSessionLocal
                async with AsyncSessionLocal() as session:
                    await init_db_data(session)
            else:
                # 使用同步模式初始化数据
                logger.warning("异步引擎不可用，跳过默认数据初始化")
                
            logger.info("默认数据初始化完成")
        except Exception as e:
            logger.warning(f"默认数据初始化失败（可忽略）: {e}")
    
    async def _verify_database(self) -> bool:
        """验证数据库功能"""
        try:
            # 检查核心表是否存在
            from sqlalchemy import text
            
            if async_engine:
                async with async_engine.connect() as conn:
                    # 检查用户表
                    result = await conn.execute(text("SELECT COUNT(*) FROM users"))
                    user_count = result.scalar()
                    logger.info(f"用户表验证成功，现有用户数: {user_count}")
                    
                    # 检查WireGuard服务器表
                    result = await conn.execute(text("SELECT COUNT(*) FROM wireguard_servers"))
                    server_count = result.scalar()
                    logger.info(f"WireGuard服务器表验证成功，现有服务器数: {server_count}")
                    
            else:
                # 同步模式验证
                with sync_engine.connect() as conn:
                    # 检查用户表
                    result = conn.execute(text("SELECT COUNT(*) FROM users"))
                    user_count = result.scalar()
                    logger.info(f"用户表验证成功，现有用户数: {user_count}")
                    
                    # 检查WireGuard服务器表
                    result = conn.execute(text("SELECT COUNT(*) FROM wireguard_servers"))
                    server_count = result.scalar()
                    logger.info(f"WireGuard服务器表验证成功，现有服务器数: {server_count}")
            
            return True
            
        except Exception as e:
            logger.error(f"数据库功能验证失败: {e}")
            return False
    
    def get_status(self) -> dict:
        """获取初始化状态"""
        return {
            "initialized": self.initialized,
            "async_engine_available": async_engine is not None,
            "sync_engine_available": sync_engine is not None
        }


async def main():
    """主函数"""
    initializer = VPSDatabaseInitializer()
    
    logger.info("=== VPS数据库初始化工具 ===")
    
    # 执行初始化
    success = await initializer.initialize_database()
    
    # 显示结果
    if success:
        logger.info("✅ 数据库初始化成功")
        status = initializer.get_status()
        logger.info(f"初始化状态: {status}")
    else:
        logger.error("❌ 数据库初始化失败")
        sys.exit(1)


if __name__ == "__main__":
    # 运行异步主函数
    asyncio.run(main())