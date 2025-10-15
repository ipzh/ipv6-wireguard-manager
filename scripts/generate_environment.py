#!/usr/bin/env python3
"""
环境配置生成脚本
根据安装模式和系统资源自动生成最优的环境配置
"""

import os
import sys
import argparse
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from backend.app.core.environment import EnvironmentManager, InstallMode, EnvironmentProfile

def main():
    parser = argparse.ArgumentParser(description="生成IPv6 WireGuard Manager环境配置")
    parser.add_argument("--output", "-o", default=".env", help="输出文件路径")
    parser.add_argument("--mode", choices=["docker", "native", "minimal"], help="强制指定安装模式")
    parser.add_argument("--profile", choices=["low_memory", "standard", "high_performance"], help="强制指定配置档案")
    parser.add_argument("--memory", type=int, help="强制指定内存大小(MB)")
    parser.add_argument("--show-config", action="store_true", help="显示配置摘要")
    parser.add_argument("--validate", action="store_true", help="验证生成的配置")
    
    args = parser.parse_args()
    
    print("🔧 IPv6 WireGuard Manager 环境配置生成器")
    print("=" * 50)
    
    # 创建环境管理器
    manager = EnvironmentManager()
    
    # 应用命令行参数覆盖
    if args.mode:
        manager.install_mode = InstallMode(args.mode)
        print(f"📦 安装模式: {args.mode} (手动指定)")
    else:
        print(f"📦 安装模式: {manager.install_mode.value} (自动检测)")
    
    if args.profile:
        manager.profile = EnvironmentProfile(args.profile)
        print(f"⚙️  配置档案: {args.profile} (手动指定)")
    else:
        print(f"⚙️  配置档案: {manager.profile.value} (自动检测)")
    
    if args.memory:
        manager.memory_mb = args.memory
        print(f"💾 系统内存: {args.memory}MB (手动指定)")
    else:
        print(f"💾 系统内存: {manager.memory_mb}MB (自动检测)")
    
    print()
    
    # 生成配置文件
    output_path = Path(args.output)
    manager.generate_env_file(str(output_path))
    
    # 显示配置摘要
    if args.show_config:
        print("\n📊 配置摘要:")
        config = manager.get_all_config()
        
        # 按类别显示配置
        categories = {
            "数据库配置": ["DATABASE_URL", "DATABASE_POOL_SIZE", "DATABASE_MAX_OVERFLOW", "AUTO_CREATE_DATABASE"],
            "Redis配置": ["USE_REDIS", "REDIS_URL", "REDIS_POOL_SIZE"],
            "服务器配置": ["SERVER_HOST", "SERVER_PORT", "DEBUG"],
            "性能配置": ["MAX_WORKERS", "KEEP_ALIVE", "MAX_REQUESTS"],
            "日志配置": ["LOG_LEVEL", "LOG_FILE", "LOG_ROTATION", "LOG_RETENTION"],
            "监控配置": ["ENABLE_HEALTH_CHECK", "HEALTH_CHECK_INTERVAL"],
            "环境信息": ["INSTALL_MODE", "ENVIRONMENT_PROFILE", "MEMORY_MB"],
        }
        
        for category, keys in categories.items():
            print(f"\n  {category}:")
            for key in keys:
                if key in config:
                    value = config[key]
                    if key == "BACKEND_CORS_ORIGINS":
                        print(f"    {key}: {len(value)} 个源")
                    else:
                        print(f"    {key}: {value}")
    
    # 验证配置
    if args.validate:
        print("\n🔍 验证配置...")
        try:
            # 尝试导入配置
            from backend.app.core.config import Settings
            settings = Settings()
            print("✅ 配置验证通过")
            
            # 检查关键配置
            checks = [
                ("数据库URL", settings.DATABASE_URL),
                ("服务器端口", settings.SERVER_PORT),
                ("Redis状态", "启用" if settings.USE_REDIS else "禁用"),
                ("工作进程数", settings.MAX_WORKERS),
            ]
            
            print("\n  📋 关键配置检查:")
            for name, value in checks:
                print(f"    {name}: {value}")
                
        except Exception as e:
            print(f"❌ 配置验证失败: {e}")
            return 1
    
    print(f"\n🎉 环境配置生成完成!")
    print(f"   文件路径: {output_path.absolute()}")
    print(f"   安装模式: {manager.install_mode.value}")
    print(f"   配置档案: {manager.profile.value}")
    
    # 提供使用建议
    print(f"\n💡 使用建议:")
    if manager.profile == EnvironmentProfile.LOW_MEMORY:
        print("   - 低内存配置已优化，适合内存受限环境")
        print("   - Redis已禁用以节省内存")
        print("   - 工作进程数已减少到2个")
    elif manager.profile == EnvironmentProfile.STANDARD:
        print("   - 标准配置适合大多数环境")
        print("   - 平衡了性能和资源使用")
    else:
        print("   - 高性能配置适合资源充足的环境")
        print("   - 启用了所有优化选项")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
