#!/usr/bin/env python3
"""
修复远程服务器导入路径问题
"""
import os
import sys
from pathlib import Path

def fix_imports_in_file(file_path, replacements):
    """修复文件中的导入路径"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        for old_import, new_import in replacements.items():
            content = content.replace(old_import, new_import)
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ 修复文件: {file_path}")
            return True
        else:
            print(f"⏭️ 跳过文件: {file_path} (无需修复)")
            return False
            
    except Exception as e:
        print(f"❌ 修复文件失败: {file_path} - {e}")
        return False

def main():
    """主函数"""
    print("🔧 开始修复远程服务器导入路径问题...")
    
    # 定义需要修复的导入路径
    replacements = {
        # 将绝对导入改为相对导入
        'from app.core.database import get_db': 'from ....core.database import get_db',
        'from app.core.security_enhanced import security_manager': 'from ....core.security_enhanced import security_manager',
        'from app.models.models_complete import User': 'from ....models.models_complete import User',
        'from app.schemas.common import MessageResponse': 'from ....schemas.common import MessageResponse',
        'from app.schemas.bgp import': 'from ....schemas.bgp import',
        'from app.schemas.ipv6 import': 'from ....schemas.ipv6 import',
        'from app.schemas.network import': 'from ....schemas.network import',
        'from app.schemas.status import': 'from ....schemas.status import',
        'from app.services.ipv6_service import': 'from ....services.ipv6_service import',
        'from app.services.status_service import': 'from ....services.status_service import',
        
        # 修复API v1目录中的导入
        'from app.core.database import get_db': 'from ...core.database import get_db',
        'from app.core.config_enhanced import settings': 'from ...core.config_enhanced import settings',
        'from app.core.security_enhanced import': 'from ...core.security_enhanced import',
        'from app.models.models_complete import': 'from ...models.models_complete import',
        'from app.schemas.auth import': 'from ...schemas.auth import',
        'from app.schemas.user import': 'from ...schemas.user import',
        'from app.services.user_service import': 'from ...services.user_service import',
        'from app.utils.rate_limit import': 'from ...utils.rate_limit import',
        
        # 修复核心模块中的导入
        'from app.core.config_enhanced import settings': 'from .config_enhanced import settings',
        'from app.models.models_complete import': 'from ..models.models_complete import',
        
        # 修复服务模块中的导入
        'from app.models.models_complete import': 'from ..models.models_complete import',
        'from app.schemas.user import': 'from ..schemas.user import',
        'from app.core.security_enhanced import': 'from ..core.security_enhanced import',
        'from app.utils.audit import': 'from ..utils.audit import',
        
        # 修复模型模块中的导入
        'from app.core.database import Base': 'from ..core.database import Base',
        
        # 修复工具模块中的导入
        'from app.models.models_complete import': 'from ..models.models_complete import',
    }
    
    # 需要修复的文件列表
    files_to_fix = [
        "backend/app/api/api_v1/endpoints/auth.py",
        "backend/app/api/api_v1/endpoints/system.py",
        "backend/app/api/api_v1/endpoints/monitoring.py",
        "backend/app/api/api_v1/endpoints/bgp.py",
        "backend/app/api/api_v1/endpoints/ipv6.py",
        "backend/app/api/api_v1/endpoints/network.py",
        "backend/app/api/api_v1/endpoints/logs.py",
        "backend/app/api/api_v1/endpoints/status.py",
        "backend/app/api/api_v1/auth.py",
        "backend/app/core/security_enhanced.py",
        "backend/app/services/user_service.py",
        "backend/app/models/models_complete.py",
        "backend/app/utils/audit.py"
    ]
    
    fixed_count = 0
    total_count = len(files_to_fix)
    
    for file_path in files_to_fix:
        if os.path.exists(file_path):
            if fix_imports_in_file(file_path, replacements):
                fixed_count += 1
        else:
            print(f"⚠️ 文件不存在: {file_path}")
    
    print(f"\n📊 修复完成: {fixed_count}/{total_count} 个文件")
    
    if fixed_count > 0:
        print("✅ 导入路径修复完成！")
        print("🚀 现在可以重新启动后端服务了。")
    else:
        print("ℹ️ 没有文件需要修复。")

if __name__ == "__main__":
    main()
