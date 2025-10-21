#!/usr/bin/env python3
"""
简化的服务器启动脚本
用于测试和开发环境
"""
import os
import sys
import uvicorn
from pathlib import Path

# 添加项目根目录到Python路径
try:
    project_root = Path(__file__).parent.parent
except NameError:
    # 如果__file__未定义，使用当前工作目录
    project_root = Path.cwd()
sys.path.insert(0, str(project_root))

def main():
    """启动服务器"""
    # 设置环境变量
    os.environ.setdefault('PYTHONPATH', str(project_root))
    
    # 检查环境变量文件
    env_file = project_root / '.env'
    if env_file.exists():
        print(f"📄 加载环境变量文件: {env_file}")
        from dotenv import load_dotenv
        load_dotenv(env_file)
    
    # 获取配置
    host = os.getenv('SERVER_HOST', '::')  # 使用::支持IPv6
    port = int(os.getenv('SERVER_PORT', '8000'))
    debug = os.getenv('DEBUG', 'false').lower() == 'true'
    log_level = os.getenv('LOG_LEVEL', 'info').lower()
    
    print(f"🚀 启动IPv6 WireGuard Manager服务器...")
    print(f"📍 地址: http://{host}:{port}")
    print(f"🔧 调试模式: {debug}")
    print(f"📊 日志级别: {log_level}")
    print(f"📚 API文档: http://{host}:{port}/docs")
    print(f"❤️ 健康检查: http://{host}:{port}/health")
    print("=" * 50)
    
    try:
        # 启动服务器
        uvicorn.run(
            "app.main:app",
            host=host,
            port=port,
            reload=debug,
            log_level=log_level,
            access_log=True
        )
    except KeyboardInterrupt:
        print("\n👋 服务器已停止")
    except Exception as e:
        print(f"❌ 服务器启动失败: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
