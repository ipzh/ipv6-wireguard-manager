#!/usr/bin/env python3
"""
VPS环境数据库初始化脚本
专门处理VPS上的PostgreSQL权限和配置问题
"""
import asyncio
import sys
import os
import logging

# 添加项目根目录到Python路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.init_database_vps import VPSDatabaseInitializer

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def main():
    """主函数"""
    logger.info("=== VPS数据库初始化工具 ===")
    
    # 创建初始化器
    initializer = VPSDatabaseInitializer()
    
    # 执行初始化
    success = await initializer.initialize_database()
    
    # 显示结果
    if success:
        logger.info("✅ 数据库初始化成功")
        status = initializer.get_status()
        logger.info(f"初始化状态: {status}")
        return 0
    else:
        logger.error("❌ 数据库初始化失败")
        return 1


if __name__ == "__main__":
    # 运行异步主函数
    exit_code = asyncio.run(main())
    sys.exit(exit_code)