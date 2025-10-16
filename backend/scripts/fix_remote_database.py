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
        if hostname in ['localhost', '127.0.0.1', '::1']:
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
        
        # 检查是否需要切换到SQLite
        need_sqlite_fallback = False
        for issue in self.issues_found:
            if any(keyword in issue.lower() for keyword in [
                "无法连接", "连接被拒绝", "连接超时", "认证失败"
            ]):
                need_sqlite_fallback = True
                break
        
        if need_sqlite_fallback:
            logger.info("🔄 检测到连接问题，尝试切换到SQLite回退模式")
            
            # 检查SQLite配置
            if not settings.SQLITE_DATABASE_URL:
                logger.error("❌ SQLite回退URL未配置")
                return False
            
            # 切换到SQLite
            original_url = settings.DATABASE_URL
            settings.DATABASE_URL = settings.SQLITE_DATABASE_URL
            settings.USE_SQLITE_FALLBACK = True
            
            logger.info(f"🔄 数据库URL已从 {original_url} 切换到 {settings.DATABASE_URL}")
            self.fixes_applied.append("切换到SQLite回退模式")
            
            # 测试SQLite连接
            logger.info("🔗 测试SQLite连接...")
            try:
                # 重新创建引擎
                from sqlalchemy import create_engine
                test_engine = create_engine(settings.DATABASE_URL)
                
                with test_engine.connect() as conn:
                    result = conn.execute(text("SELECT 1"))
                    if result.scalar() == 1:
                        logger.info("✅ SQLite连接正常")
                        return True
                    else:
                        logger.error("❌ SQLite连接测试失败")
                        return False
                        
            except Exception as e:
                logger.error(f"❌ SQLite连接失败: {e}")
                return False
        
        # 其他问题的修复逻辑可以在这里添加
        logger.warning("⚠️ 当前问题需要手动修复")
        return False
    
    def get_status(self) -> dict:
        """获取修复状态"""
        return {
            "issues_found": self.issues_found,
            "fixes_applied": self.fixes_applied,
            "current_database_url": settings.DATABASE_URL,
            "using_sqlite_fallback": settings.USE_SQLITE_FALLBACK
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