#!/bin/bash

echo "🔧 完全重写auth.py文件..."

# 停止服务
systemctl stop ipv6-wireguard-manager

# 备份原文件
cp /opt/ipv6-wireguard-manager/backend/app/api/api_v1/endpoints/auth.py /opt/ipv6-wireguard-manager/backend/app/api/api_v1/endpoints/auth.py.backup

# 完全重写auth.py文件
cat > /opt/ipv6-wireguard-manager/backend/app/api/api_v1/endpoints/auth.py << 'EOF'
"""
认证相关API端点
"""
from datetime import timedelta
from typing import Any
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.config import settings
from ....core.database import get_async_db
from ....core.security import create_access_token, verify_password, get_password_hash, get_current_user_id
from ....schemas.user import LoginRequest, LoginResponse, User, UserCreate
from ....services.user_service import UserService

router = APIRouter()


@router.post("/login", response_model=LoginResponse)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_async_db)
) -> LoginResponse:
    """
    用户登录
    """
    user_service = UserService(db)
    user = await user_service.authenticate_user(form_data.username, form_data.password)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户名或密码错误",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="用户账户已被禁用"
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)}, expires_delta=access_token_expires
    )
    
    return LoginResponse(
        access_token=access_token,
        token_type="bearer",
        user=user
    )


@router.post("/login-json", response_model=LoginResponse)
async def login_json(
    login_data: LoginRequest,
    db: AsyncSession = Depends(get_async_db)
) -> LoginResponse:
    """
    用户登录（JSON格式）
    """
    user_service = UserService(db)
    user = await user_service.authenticate_user(login_data.username, login_data.password)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户名或密码错误",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="用户账户已被禁用"
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)}, expires_delta=access_token_expires
    )
    
    return LoginResponse(
        access_token=access_token,
        token_type="bearer",
        user=user
    )


@router.post("/test-token")
async def test_token(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> User:
    """
    测试令牌有效性
    """
    user_service = UserService(db)
    user = await user_service.get_user_by_id(current_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )
    return user


@router.post("/refresh-token", response_model=LoginResponse)
async def refresh_token(
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_async_db)
) -> LoginResponse:
    """
    刷新访问令牌
    """
    user_service = UserService(db)
    user = await user_service.get_user_by_id(current_user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="用户账户已被禁用"
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)}, expires_delta=access_token_expires
    )
    
    return LoginResponse(
        access_token=access_token,
        token_type="bearer",
        user=user
    )


@router.post("/register", response_model=User)
async def register(
    user_data: UserCreate,
    db: AsyncSession = Depends(get_async_db)
) -> User:
    """
    用户注册
    """
    user_service = UserService(db)
    
    # 检查用户名是否已存在
    existing_user = await user_service.get_user_by_username(user_data.username)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="用户名已存在"
        )
    
    # 检查邮箱是否已存在
    existing_email = await user_service.get_user_by_email(user_data.email)
    if existing_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="邮箱已存在"
        )
    
    # 创建新用户
    user = await user_service.create_user(user_data)
    return user
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
