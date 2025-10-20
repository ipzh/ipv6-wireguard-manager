#!/usr/bin/env python3
"""
远程服务器数据库问题修复脚本
专门处理远程PostgreSQL服务器的连接和配置问题
"""
import asyncio
import sys
import os
import logging
import urllib.parse
import socket

# 添加项目根目录到Python路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings
from app.core.database import sync_engine, async_engine
from sqlalchemy import text

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class RemoteDatabaseFixer:
    """远程数据库修复器"""
    
    def __init__(self):
        self.issues_found = []
        self.fixes_applied = []
    
    def check_remote_connection(self) -> bool:
        """检查远程数据库连接"""
        logger.info("=== 检查远程数据库连接 ===")
        
        # 检查数据库URL配置
        if not settings.DATABASE_URL:
            logger.error("❌ 数据库URL未配置")
            self.issues_found.append("数据库URL未配置")
            return False
        
        # 检查是否为PostgreSQL连接
        if not settings.DATABASE_URL.startswith("postgresql://"):
            logger.info("ℹ️ 当前使用非PostgreSQL数据库，跳过远程连接检查")
            return True
        
        # 解析数据库URL
        parsed_url = urllib.parse.urlparse(settings.DATABASE_URL)
        hostname = parsed_url.hostname
        port = parsed_url.port or 5432
        
        logger.info(f"🔍 连接目标: {hostname}:{port}")
        
        # 检查是否为远程服务器
        if hostname in ['localhost', '${LOCAL_HOST}', '::1']:
            logger.info("ℹ️ 检测到本地数据库连接")
            return True
        
        logger.info("🌐 检测到远程PostgreSQL服务器连接")
        
        # 检查网络连接
        logger.info("🔌 检查网络连接...")
        try:
            sock = socket.socket(socket.AF_String(45), socket.SOCK_STREAM)
            sock.settimeout(10)  # 10秒超时
            result = sock.connect_ex((hostname, port))
            sock.close()
            
            if result == 0:
                logger.info("✅ 网络连接正常")
            else:
                logger.error(f"❌ 网络连接失败 (错误代码: {result})")
                self.issues_found.append(f"远程服务器 {hostname}:{port} 无法连接")
                return False
                
        except Exception as e:
            logger.error(f"❌ 网络连接检查失败: {e}")
            self.issues_found.append(f"网络连接检查失败: {e}")
            return False
        
        # 测试数据库连接
        logger.info("🔗 测试数据库连接...")
        try:
            with sync_engine.connect() as conn:
                result = conn.execute(text("SELECT 1"))
                if result.scalar() == 1:
                    logger.info("✅ 数据库连接正常")
                    return True
                else:
                    logger.error("❌ 数据库连接测试失败")
                    self.issues_found.append("数据库连接测试失败")
                    return False
                    
        except Exception as e:
            error_msg = str(e)
            logger.error(f"❌ 数据库连接失败: {error_msg}")
            
            # 分析错误类型
            if "Connection refused" in error_msg or "10061" in error_msg:
                self.issues_found.append("数据库服务器连接被拒绝")
            elif "timeout" in error_msg.lower():
                self.issues_found.append("数据库连接超时")
            elif "authentication failed" in error_msg.lower():
                self.issues_found.append("数据库认证失败")
            elif "database" in error_msg.lower() and "does not exist" in error_msg.lower():
                self.issues_found.append("数据库不存在")
            elif "permission" in error_msg.lower():
                self.issues_found.append("用户权限不足")
            else:
                self.issues_found.append(f"数据库连接错误: {error_msg}")
            
            return False
    
    def fix_remote_issues(self) -> bool:
        """修复远程数据库问题"""
        logger.info("=== 尝试修复远程数据库问题 ===")
        
        if not self.issues_found:
            logger.info("✅ 未发现需要修复的问题")
            return True
        
        # SQLite回退功能已移除，现在只支持MySQL和PostgreSQL
        logger.warning("⚠️ 当前问题需要手动修复，不再支持SQLite回退")
        logger.info("建议检查以下配置:")
        logger.info("1. 确保数据库服务器正常运行")
        logger.info("2. 检查数据库连接配置是否正确")
        logger.info("3. 验证数据库用户权限")
        logger.info("4. 确认网络连接正常")
        
        return False
    
    def get_status(self) -> dict:
        """获取修复状态"""
        return {
            "issues_found": self.issues_found,
            "fixes_applied": self.fixes_applied,
            "current_database_url": settings.DATABASE_URL,
            "using_sqlite_fallback": False  # 不再支持SQLite回退
        }


async def main():
    """主函数"""
    logger.info("=== 远程服务器数据库问题修复工具 ===")
    
    # 创建修复器
    fixer = RemoteDatabaseFixer()
    
    # 检查连接
    connection_ok = fixer.check_remote_connection()
    
    if connection_ok:
        logger.info("✅ 远程数据库连接正常，无需修复")
        return 0
    
    # 尝试修复
    fix_success = fixer.fix_remote_issues()
    
    # 显示结果
    status = fixer.get_status()
    
    logger.info("=== 修复结果 ===")
    logger.info(f"发现的问题: {status['issues_found']}")
    logger.info(f"应用的修复: {status['fixes_applied']}")
    logger.info(f"当前数据库URL: {status['current_database_url']}")
    logger.info(f"使用SQLite回退: {status['using_sqlite_fallback']}")
    
    if fix_success:
        logger.info("✅ 修复成功")
        return 0
    else:
        logger.error("❌ 修复失败，需要手动处理")
        return 1


if __name__ == "__main__":
    # 运行异步主函数
    exit_code = asyncio.run(main())
    sys.exit(exit_code)