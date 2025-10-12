#!/usr/bin/env python3
"""
直接修复auth.py文件中的FastAPI问题
"""
import os
import sys

def fix_auth_file():
    auth_file = "/opt/ipv6-wireguard-manager/backend/app/api/api_v1/endpoints/auth.py"
    
    if not os.path.exists(auth_file):
        print(f"❌ 文件不存在: {auth_file}")
        return False
    
    # 读取文件内容
    with open(auth_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print("🔍 检查当前文件内容...")
    
    # 检查是否已经修复
    if "response_model=None" in content:
        print("✅ 文件已经修复")
        return True
    
    # 修复导入问题
    if "get_current_user_id" not in content:
        print("🔧 修复导入问题...")
        content = content.replace(
            "from ....core.security import create_access_token, verify_password, get_password_hash",
            "from ....core.security import create_access_token, verify_password, get_password_hash, get_current_user_id"
        )
    
    # 修复FastAPI响应模型问题
    print("🔧 修复FastAPI响应模型问题...")
    content = content.replace(
        '@router.post("/test-token", response_model=User)',
        '@router.post("/test-token", response_model=None)'
    )
    
    # 修复函数参数顺序
    print("🔧 修复函数参数顺序...")
    old_func = '''async def test_token(
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_async_db)
) -> User:'''
    
    new_func = '''async def test_token(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> User:'''
    
    content = content.replace(old_func, new_func)
    
    # 写回文件
    with open(auth_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ 文件修复完成")
    return True

if __name__ == "__main__":
    if fix_auth_file():
        print("🎉 修复成功！")
        sys.exit(0)
    else:
        print("❌ 修复失败！")
        sys.exit(1)
