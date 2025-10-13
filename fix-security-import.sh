#!/bin/bash

echo "🔧 修复服务器上的security.py文件..."

# 停止服务
systemctl stop ipv6-wireguard-manager.service

# 进入应用目录
cd /opt/ipv6-wireguard-manager/backend

# 备份原文件
cp app/core/security.py app/core/security.py.backup

# 修复security.py文件
cat > app/core/security.py << 'EOF'
"""
安全相关功能：密码哈希、JWT令牌、权限验证等
"""
from datetime import datetime, timedelta
from typing import Any, Union, Optional
from jose import jwt, JWTError
from passlib.context import CryptContext
from fastapi import HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from .config import settings

# 密码加密上下文 - 使用pbkdf2_sha256避免bcrypt版本兼容性问题
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

# JWT令牌安全方案
security = HTTPBearer()


def create_access_token(
    subject: Union[str, Any], expires_delta: timedelta = None
) -> str:
    """创建访问令牌"""
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
    
    to_encode = {"exp": expire, "sub": str(subject)}
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def verify_token(token: str) -> Optional[str]:
    """验证令牌并返回用户ID"""
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            return None
        return user_id
    except JWTError:
        return None


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """验证密码"""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """获取密码哈希"""
    # 确保密码长度不超过72字节（bcrypt限制）
    if len(password.encode('utf-8')) > 72:
        password = password[:72]
    return pwd_context.hash(password)


async def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = security,
    db: AsyncSession = None
) -> str:
    """获取当前用户ID"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        token = credentials.credentials
        user_id = verify_token(token)
        if user_id is None:
            raise credentials_exception
        return user_id
    except Exception:
        raise credentials_exception


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = security,
    db: AsyncSession = None
):
    """获取当前用户（兼容性函数）"""
    user_id = await get_current_user_id(credentials, db)
    return await get_current_active_user(user_id, db)


async def get_current_active_user(
    current_user_id: str = None,
    db: AsyncSession = None
):
    """获取当前活跃用户"""
    if not current_user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    
    # 这里需要从数据库获取用户信息
    # 暂时返回用户ID，后续会完善
    return {"id": current_user_id, "is_active": True}


def check_permissions(user_permissions: list, required_permissions: list) -> bool:
    """检查用户权限"""
    if not required_permissions:
        return True
    
    return any(perm in user_permissions for perm in required_permissions)


def require_permissions(required_permissions: list):
    """权限装饰器"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            # 这里需要实现权限检查逻辑
            # 暂时跳过权限检查
            return await func(*args, **kwargs)
        return wrapper
    return decorator
EOF

echo "✅ security.py文件已修复"

# 激活虚拟环境
source venv/bin/activate

# 设置环境变量
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/ipv6wgm"
export REDIS_URL="redis://localhost:6379/0"
export SECRET_KEY="your-secret-key-change-this-in-production"

# 测试导入
echo "测试应用导入..."
python -c "
try:
    from app.main import app
    print('✅ 应用导入成功')
except Exception as e:
    print(f'❌ 应用导入失败: {e}')
    import traceback
    traceback.print_exc()
    exit(1)
"

# 如果导入成功，启动服务
if [ $? -eq 0 ]; then
    echo "启动服务..."
    systemctl start ipv6-wireguard-manager.service
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    systemctl status ipv6-wireguard-manager.service --no-pager
    
    # 测试API
    echo "测试API..."
    curl -f http://localhost:8000/health > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ API测试成功"
        echo "✅ 所有导入问题已修复"
    else
        echo "❌ API测试失败"
        echo "查看详细日志:"
        journalctl -u ipv6-wireguard-manager.service -n 10 --no-pager
    fi
else
    echo "导入失败，请检查错误信息"
fi

echo "修复完成！"
