#!/bin/bash

echo "🔧 修复auth.py中的依赖注入问题..."

# 停止服务
systemctl stop ipv6-wireguard-manager.service

# 进入应用目录
cd /opt/ipv6-wireguard-manager/backend

# 备份原文件
cp app/api/api_v1/endpoints/auth.py app/api/api_v1/endpoints/auth.py.backup

# 修复auth.py文件
cat > app/api/api_v1/endpoints/auth.py << 'EOF'
"""
认证相关API端点
"""
from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.config import settings
from ....core.database import get_async_db
from ....core.security import create_access_token, get_current_user
from ....schemas.user import LoginResponse, User
from ....services.user_service import UserService

router = APIRouter()


@router.post("/login")
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_async_db)
):
    """用户登录"""
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


@router.post("/login-json")
async def login_json(
    login_data: dict,
    db: AsyncSession = Depends(get_async_db)
):
    """用户登录（JSON格式）"""
    user_service = UserService(db)
    user = await user_service.authenticate_user(login_data.get("username"), login_data.get("password"))
    
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


@router.post("/logout")
async def logout():
    """用户登出"""
    return {"message": "登出成功"}


@router.get("/me", response_model=None)
async def get_current_user_info(current_user: dict = Depends(get_current_user)):
    """获取当前用户信息"""
    return current_user


@router.post("/refresh", response_model=None)
async def refresh_token(current_user: dict = Depends(get_current_user)):
    """刷新访问令牌"""
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(current_user.get("id"))}, expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }
EOF

echo "✅ auth.py文件已修复"

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
