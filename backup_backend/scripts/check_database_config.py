#!/usr/bin/env python3
"""
数据库配置检查工具
检查当前数据库配置并诊断问题
"""
import sys
import os
import logging
import urllib.parse
import socket

# 添加项目根目录到Python路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def check_database_config():
    """检查数据库配置"""
    logger.info("=== 数据库配置检查 ===")
    
    # 检查基础配置
    logger.info(f"📋 应用名称: {settings.APP_NAME}")
    logger.info(f"📋 应用版本: {settings.APP_VERSION}")
    logger.info(f"🔧 调试模式: {settings.DEBUG}")
    
    # 检查数据库URL
    if not settings.DATABASE_URL:
        logger.error("❌ 数据库URL未配置")
        return False
    
    logger.info(f"🔗 数据库URL: {settings.DATABASE_URL}")
    
    # 解析数据库URL
    try:
        parsed_url = urllib.parse.urlparse(settings.DATABASE_URL)
        
        logger.info(f"🌐 数据库类型: {'PostgreSQL' if parsed_url.scheme == 'postgresql' else parsed_url.scheme}")
        logger.info(f"🏠 主机地址: {parsed_url.hostname}")
        logger.info(f"🔌 端口号: {parsed_url.port or '默认(5432)'}")
        logger.info(f"🗄️ 数据库名: {parsed_url.path.lstrip('/')}")
        logger.info(f"👤 用户名: {parsed_url.username}")
        
        # 检查是否为远程连接
        if parsed_url.hostname not in ['localhost', '127.0.0.1', '::1']:
            logger.info("🌍 检测到远程数据库连接")
            
            # 检查网络连接
            logger.info("🔌 检查网络连接...")
            try:
                hostname = parsed_url.hostname
                port = parsed_url.port or 5432
                
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(10)
                result = sock.connect_ex((hostname, port))
                sock.close()
                
                if result == 0:
                    logger.info("✅ 网络连接正常")
                else:
                    logger.error(f"❌ 网络连接失败 (错误代码: {result})")
                    logger.info("💡 建议: 检查防火墙设置和网络连接")
                    
            except Exception as e:
                logger.error(f"❌ 网络连接检查失败: {e}")
        else:
            logger.info("💻 检测到本地数据库连接")
            
    except Exception as e:
        logger.error(f"❌ 数据库URL解析失败: {e}")
        return False
    
    # 检查连接池配置
    logger.info(f"📊 连接池大小: {settings.DATABASE_POOL_SIZE}")
    logger.info(f"📊 最大溢出连接: {settings.DATABASE_MAX_OVERFLOW}")
    logger.info(f"⏱️ 连接超时: {settings.DATABASE_CONNECT_TIMEOUT}秒")
    logger.info(f"⏱️ 语句超时: {settings.DATABASE_STATEMENT_TIMEOUT}毫秒")
    
    # 检查SQLite回退配置
    logger.info(f"🔄 SQLite回退URL: {settings.SQLITE_DATABASE_URL}")
    logger.info(f"🔄 使用SQLite回退: {settings.USE_SQLITE_FALLBACK}")
    
    # 检查Redis配置
    logger.info(f"🔴 Redis URL: {settings.REDIS_URL}")
    logger.info(f"🔴 Redis连接池大小: {settings.REDIS_POOL_SIZE}")
    
    return True


def check_environment():
    """检查运行环境"""
    logger.info("=== 运行环境检查 ===")
    
    logger.info(f"💻 操作系统: {os.name}")
    logger.info(f"🐍 Python版本: {sys.version}")
    logger.info(f"📁 工作目录: {os.getcwd()}")
    
    # 检查环境变量
    env_vars = [
        'DATABASE_URL', 'REDIS_URL', 'SECRET_KEY'
    ]
    
    for var in env_vars:
        value = os.environ.get(var)
        if value:
            logger.info(f"🔧 环境变量 {var}: 已设置")
        else:
            logger.info(f"🔧 环境变量 {var}: 未设置")
    
    return True


def check_dependencies():
    """检查依赖包"""
    logger.info("=== 依赖包检查 ===")
    
    dependencies = [
        'sqlalchemy', 'asyncpg', 'psycopg2', 'redis', 'pydantic'
    ]
    
    for dep in dependencies:
        try:
            __import__(dep)
            logger.info(f"✅ {dep}: 已安装")
        except ImportError:
            logger.warning(f"⚠️ {dep}: 未安装")
    
    return True


def main():
    """主函数"""
    logger.info("=== 数据库配置诊断工具 ===")
    
    # 检查运行环境
    if not check_environment():
        logger.error("❌ 运行环境检查失败")
        return 1
    
    # 检查依赖包
    if not check_dependencies():
        logger.error("❌ 依赖包检查失败")
        return 1
    
    # 检查数据库配置
    if not check_database_config():
        logger.error("❌ 数据库配置检查失败")
        return 1
    
    logger.info("✅ 所有检查完成")
    
    # 提供诊断建议
    logger.info("\n=== 诊断建议 ===")
    logger.info("💡 如果遇到远程数据库连接问题:")
    logger.info("  1. 检查远程PostgreSQL服务器是否运行")
    logger.info("  2. 检查防火墙设置，确保端口5432开放")
    logger.info("  3. 检查pg_hba.conf文件中的认证设置")
    logger.info("  4. 检查数据库用户权限")
    logger.info("  5. 考虑使用SQLite作为临时解决方案")
    
    return 0


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)