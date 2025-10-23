"""
简化的API启动脚本 - 使用生产版入口
"""
import uvicorn
import os
import sys
import logging
import socket
from pathlib import Path

# 添加项目根目录到Python路径
try:
    project_root = Path(__file__).parent
except NameError:
    # 如果__file__未定义，使用当前工作目录
    project_root = Path.cwd()
sys.path.insert(0, str(project_root))

# 设置环境变量
os.environ.setdefault("DATABASE_URL", "mysql://ipv6wgm:password@127.0.0.1:3306/ipv6wgm")
os.environ.setdefault("DEBUG", "true")
os.environ.setdefault("LOG_LEVEL", "INFO")

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

def main():
    """启动API服务"""
    try:
        logger.info("Starting IPv6 WireGuard Manager API (production)...")
        
        # 使用生产版入口，避免导入不存在的模块
        app_module = os.environ.get("UVICORN_APP", "app.main_production:app")
        logger.info(f"Loading app from: {app_module}")
        
        # 启动服务器 - 支持IPv4和IPv6双栈
        uvicorn.run(
            app_module,
            host="::",
            port=8000,
            reload=True,
            log_level="info",
            access_log=True,
            # 双栈配置
            http="httptools",
            loop="asyncio",
            ws="websockets",
            # 启用IPv6支持
            family=socket.AF_UNSPEC
        )
        
    except Exception as e:
        logger.error(f"Failed to start API server: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
