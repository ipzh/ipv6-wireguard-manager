#!/usr/bin/env python3
"""
全面检查所有文件的导入问题
"""
import sys
import os
from pathlib import Path

# 添加项目根目录到Python路径
sys.path.insert(0, str(Path(__file__).parent / "app"))

def check_imports():
    """检查所有导入"""
    print("🔍 开始检查所有导入...")
    
    # 检查核心模块
    try:
        from app.core.config_enhanced import settings
        print("✅ app.core.config_enhanced 导入成功")
    except ImportError as e:
        print(f"❌ app.core.config_enhanced 导入失败: {e}")
        return False
    
    try:
        from app.core.database import get_db, init_db, close_db
        print("✅ app.core.database 导入成功")
    except ImportError as e:
        print(f"❌ app.core.database 导入失败: {e}")
        return False
    
    try:
        from app.core.security_enhanced import security_manager
        print("✅ app.core.security_enhanced 导入成功")
    except ImportError as e:
        print(f"❌ app.core.security_enhanced 导入失败: {e}")
        return False
    
    # 检查模型
    try:
        from app.models.models_complete import User, Role, Permission, UserRole, RolePermission
        print("✅ app.models.models_complete 导入成功")
    except ImportError as e:
        print(f"❌ app.models.models_complete 导入失败: {e}")
        return False
    
    # 检查服务
    try:
        from app.services.user_service import UserService
        print("✅ app.services.user_service 导入成功")
    except ImportError as e:
        print(f"❌ app.services.user_service 导入失败: {e}")
        return False
    
    # 检查工具
    try:
        from app.utils.rate_limit import rate_limit
        print("✅ app.utils.rate_limit 导入成功")
    except ImportError as e:
        print(f"❌ app.utils.rate_limit 导入失败: {e}")
        return False
    
    try:
        from app.utils.audit import audit_log
        print("✅ app.utils.audit 导入成功")
    except ImportError as e:
        print(f"❌ app.utils.audit 导入失败: {e}")
        return False
    
    # 检查Schema
    try:
        from app.schemas.auth import Token, UserLogin, UserResponse
        print("✅ app.schemas.auth 导入成功")
    except ImportError as e:
        print(f"❌ app.schemas.auth 导入失败: {e}")
        return False
    
    try:
        from app.schemas.user import UserCreate, UserUpdate, UserResponse
        print("✅ app.schemas.user 导入成功")
    except ImportError as e:
        print(f"❌ app.schemas.user 导入失败: {e}")
        return False
    
    # 检查API端点
    try:
        from app.api.api_v1.auth import router as auth_router
        print("✅ app.api.api_v1.auth 导入成功")
    except ImportError as e:
        print(f"❌ app.api.api_v1.auth 导入失败: {e}")
        return False
    
    try:
        from app.api.api_v1.api import api_router
        print("✅ app.api.api_v1.api 导入成功")
    except ImportError as e:
        print(f"❌ app.api.api_v1.api 导入失败: {e}")
        return False
    
    # 检查主应用
    try:
        from app.main import app
        print("✅ app.main 导入成功")
    except ImportError as e:
        print(f"❌ app.main 导入失败: {e}")
        return False
    
    print("\n🎉 所有导入检查通过！")
    return True


def check_database_models():
    """检查数据库模型"""
    print("\n🔍 检查数据库模型...")
    
    try:
        from app.models.models_complete import (
            User, Role, Permission, UserRole, RolePermission,
            WireGuardServer, BGPSession, BGPAnnouncement,
            IPv6Pool, IPv6Allocation, AuditLog, SystemLog
        )
        print("✅ 所有数据库模型导入成功")
        
        # 检查模型字段
        user_fields = [field.name for field in User.__table__.columns]
        print(f"✅ User模型字段: {user_fields}")
        
        role_fields = [field.name for field in Role.__table__.columns]
        print(f"✅ Role模型字段: {role_fields}")
        
        return True
        
    except ImportError as e:
        print(f"❌ 数据库模型导入失败: {e}")
        return False
    except Exception as e:
        print(f"❌ 数据库模型检查失败: {e}")
        return False


def check_api_endpoints():
    """检查API端点"""
    print("\n🔍 检查API端点...")
    
    endpoints = [
        "app.api.api_v1.endpoints.auth",
        "app.api.api_v1.endpoints.users",
        "app.api.api_v1.endpoints.wireguard",
        "app.api.api_v1.endpoints.network",
        "app.api.api_v1.endpoints.monitoring",
        "app.api.api_v1.endpoints.logs",
        "app.api.api_v1.endpoints.websocket",
        "app.api.api_v1.endpoints.system",
        "app.api.api_v1.endpoints.status",
        "app.api.api_v1.endpoints.bgp",
        "app.api.api_v1.endpoints.ipv6",
        "app.api.api_v1.endpoints.health",
        "app.api.api_v1.endpoints.debug"
    ]
    
    success_count = 0
    for endpoint in endpoints:
        try:
            __import__(endpoint)
            print(f"✅ {endpoint} 导入成功")
            success_count += 1
        except ImportError as e:
            print(f"❌ {endpoint} 导入失败: {e}")
        except Exception as e:
            print(f"❌ {endpoint} 检查失败: {e}")
    
    print(f"\n📊 API端点检查结果: {success_count}/{len(endpoints)} 成功")
    return success_count == len(endpoints)


def main():
    """主函数"""
    print("🚀 开始全面检查导入问题...\n")
    
    # 检查基本导入
    if not check_imports():
        print("\n❌ 基本导入检查失败")
        return False
    
    # 检查数据库模型
    if not check_database_models():
        print("\n❌ 数据库模型检查失败")
        return False
    
    # 检查API端点
    if not check_api_endpoints():
        print("\n❌ API端点检查失败")
        return False
    
    print("\n🎉 所有检查通过！系统可以正常启动。")
    return True


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
