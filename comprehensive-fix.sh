#!/bin/bash

echo "🔧 全面修复后端问题..."

# 停止服务
systemctl stop ipv6-wireguard-manager

# 使用Python脚本直接修复auth.py
echo "🔧 使用Python脚本修复auth.py..."
python3 << 'EOF'
import os

auth_file = "/opt/ipv6-wireguard-manager/backend/app/api/api_v1/endpoints/auth.py"

if not os.path.exists(auth_file):
    print(f"❌ 文件不存在: {auth_file}")
    exit(1)

# 读取文件内容
with open(auth_file, 'r', encoding='utf-8') as f:
    content = f.read()

print("🔍 检查当前文件内容...")

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
EOF

# 验证修复
echo "验证修复..."
cd /opt/ipv6-wireguard-manager/backend
source venv/bin/activate

python -c "
import sys
sys.path.insert(0, '/opt/ipv6-wireguard-manager/backend')
try:
    from app.main import app
    print('✅ 主应用导入成功')
except Exception as e:
    print(f'❌ 主应用导入失败: {e}')
    import traceback
    traceback.print_exc()
"

# 启动服务
echo "启动服务..."
systemctl start ipv6-wireguard-manager
sleep 5

# 检查状态
echo "检查服务状态..."
systemctl status ipv6-wireguard-manager --no-pager

# 检查端口
echo "检查端口监听..."
netstat -tlnp | grep :8000 || echo "端口8000未监听"

# 测试API
echo "测试API..."
curl -s http://127.0.0.1:8000/health || echo "API无响应"

echo "✅ 修复完成"
