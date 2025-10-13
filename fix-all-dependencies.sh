#!/bin/bash

echo "🔧 修复所有端点的依赖注入问题..."

# 停止服务
systemctl stop ipv6-wireguard-manager.service

# 进入应用目录
cd /opt/ipv6-wireguard-manager/backend

# 备份原文件
cp app/api/api_v1/endpoints/auth.py app/api/api_v1/endpoints/auth.py.backup
cp app/api/api_v1/endpoints/users.py app/api/api_v1/endpoints/users.py.backup
cp app/api/api_v1/endpoints/wireguard.py app/api/api_v1/endpoints/wireguard.py.backup
cp app/api/api_v1/endpoints/status.py app/api/api_v1/endpoints/status.py.backup

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


@router.post("/login", response_model=None)
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


@router.post("/login-json", response_model=None)
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


@router.post("/logout", response_model=None)
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

# 修复users.py文件
cat > app/api/api_v1/endpoints/users.py << 'EOF'
"""
用户管理API端点
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db
from ....schemas.user import User, UserCreate, UserUpdate
from ....services.user_service import UserService

router = APIRouter()


@router.get("/", response_model=None)
async def get_users(db: AsyncSession = Depends(get_async_db)):
    """获取用户列表"""
    user_service = UserService(db)
    users = await user_service.get_users()
    return users


@router.get("/{user_id}", response_model=None)
async def get_user(user_id: str, db: AsyncSession = Depends(get_async_db)):
    """获取单个用户"""
    user_service = UserService(db)
    user = await user_service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="用户不存在")
    return user


@router.post("/", response_model=None)
async def create_user(user: UserCreate, db: AsyncSession = Depends(get_async_db)):
    """创建新用户"""
    user_service = UserService(db)
    existing_user = await user_service.get_user_by_username(user.username)
    if existing_user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="用户名已存在")
    
    new_user = await user_service.create_user(user)
    return new_user


@router.put("/{user_id}", response_model=None)
async def update_user(
    user_id: str, 
    user_update: UserUpdate, 
    db: AsyncSession = Depends(get_async_db)
):
    """更新用户信息"""
    user_service = UserService(db)
    user = await user_service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="用户不存在")
    
    updated_user = await user_service.update_user(user_id, user_update)
    return updated_user


@router.delete("/{user_id}", response_model=None)
async def delete_user(user_id: str, db: AsyncSession = Depends(get_async_db)):
    """删除用户"""
    user_service = UserService(db)
    user = await user_service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="用户不存在")
    
    await user_service.delete_user(user_id)
    return {"message": "用户删除成功"}
EOF

# 修复wireguard.py文件
cat > app/api/api_v1/endpoints/wireguard.py << 'EOF'
"""
WireGuard管理API端点
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db
from ....schemas.wireguard import WireGuardConfig, WireGuardPeer
from ....services.wireguard_service import WireGuardService

router = APIRouter()


@router.get("/config", response_model=None)
async def get_wireguard_config(db: AsyncSession = Depends(get_async_db)):
    """获取WireGuard配置"""
    wireguard_service = WireGuardService(db)
    config = await wireguard_service.get_config()
    return config


@router.post("/config", response_model=None)
async def update_wireguard_config(
    config: WireGuardConfig, 
    db: AsyncSession = Depends(get_async_db)
):
    """更新WireGuard配置"""
    wireguard_service = WireGuardService(db)
    updated_config = await wireguard_service.update_config(config)
    return updated_config


@router.get("/peers", response_model=None)
async def get_peers(db: AsyncSession = Depends(get_async_db)):
    """获取所有对等节点"""
    wireguard_service = WireGuardService(db)
    peers = await wireguard_service.get_peers()
    return peers


@router.post("/peers", response_model=None)
async def create_peer(peer: WireGuardPeer, db: AsyncSession = Depends(get_async_db)):
    """创建新的对等节点"""
    wireguard_service = WireGuardService(db)
    new_peer = await wireguard_service.create_peer(peer)
    return new_peer


@router.get("/peers/{peer_id}", response_model=None)
async def get_peer(peer_id: str, db: AsyncSession = Depends(get_async_db)):
    """获取单个对等节点"""
    wireguard_service = WireGuardService(db)
    peer = await wireguard_service.get_peer(peer_id)
    if not peer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="对等节点不存在")
    return peer


@router.put("/peers/{peer_id}", response_model=None)
async def update_peer(
    peer_id: str, 
    peer: WireGuardPeer, 
    db: AsyncSession = Depends(get_async_db)
):
    """更新对等节点"""
    wireguard_service = WireGuardService(db)
    updated_peer = await wireguard_service.update_peer(peer_id, peer)
    if not updated_peer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="对等节点不存在")
    return updated_peer


@router.delete("/peers/{peer_id}", response_model=None)
async def delete_peer(peer_id: str, db: AsyncSession = Depends(get_async_db)):
    """删除对等节点"""
    wireguard_service = WireGuardService(db)
    success = await wireguard_service.delete_peer(peer_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="对等节点不存在")
    return {"message": "对等节点删除成功"}


@router.post("/peers/{peer_id}/restart", response_model=None)
async def restart_peer(peer_id: str, db: AsyncSession = Depends(get_async_db)):
    """重启对等节点"""
    wireguard_service = WireGuardService(db)
    success = await wireguard_service.restart_peer(peer_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="对等节点不存在")
    return {"message": "对等节点重启成功"}
EOF

# 修复status.py文件
cat > app/api/api_v1/endpoints/status.py << 'EOF'
"""
状态检查API端点
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db
from ....services.status_service import StatusService

router = APIRouter()


@router.get("/", response_model=None)
async def get_system_status(db: AsyncSession = Depends(get_async_db)):
    """获取系统状态"""
    status_service = StatusService(db)
    status_info = await status_service.get_system_status()
    return status_info


@router.get("/health", response_model=None)
async def health_check():
    """健康检查"""
    return {"status": "healthy", "message": "系统运行正常"}


@router.get("/services", response_model=None)
async def get_services_status(db: AsyncSession = Depends(get_async_db)):
    """获取服务状态"""
    status_service = StatusService(db)
    services_status = await status_service.get_services_status()
    return services_status
EOF

echo "✅ 所有端点文件已修复"

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
        echo "✅ 所有依赖注入问题已修复"
    else
        echo "❌ API测试失败"
        echo "查看详细日志:"
        journalctl -u ipv6-wireguard-manager.service -n 10 --no-pager
    fi
else
    echo "导入失败，请检查错误信息"
fi

echo "修复完成！"
