"""
认证相关API端点 - 使用真正的JWT认证
"""
import time
from datetime import timedelta
from typing import Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Body
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ...core.database import get_db
from ...core.security_enhanced import security_manager, get_current_user_id, get_current_user
from ...models.models_complete import User

router = APIRouter()

# 定义JSON格式的登录请求模型
class LoginRequest(BaseModel):
    username: str
    password: str

# 定义JSON格式的刷新令牌请求模型
class RefreshTokenRequest(BaseModel):
    refresh_token: str

@router.post("/login", response_model=None)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db)
):
    """用户登录 - 支持表单编码数据"""
    try:
        # 查询用户
        result = await db.execute(
            select(User).where(User.username == form_data.username)
        )
        user = result.scalar_one_or_none()
        
        # 验证用户和密码
        if not user or not security_manager.verify_password(form_data.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="用户名或密码错误",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 检查用户是否活跃
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="用户账户已被禁用",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 创建JWT访问令牌和刷新令牌
        access_token = security_manager.create_access_token(
            data={"sub": str(user.id), "username": user.username}
        )
        refresh_token = security_manager.create_refresh_token(str(user.id))
        
        # 更新用户最后登录时间
        from datetime import datetime
        user.last_login = datetime.utcnow()
        await db.commit()
        
        return {
            "success": True,
            "data": {
                "access_token": access_token,
                "refresh_token": refresh_token,
                "token_type": "bearer",
                "expires_in": security_manager.access_token_expire_minutes * 60,
                "user": {
                    "id": str(user.id),
                    "username": user.username,
                    "email": user.email,
                    "is_active": user.is_active,
                    "is_superuser": user.is_superuser
                }
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"登录失败: {str(e)}"
        )

@router.post("/login-json", response_model=None)
async def login_json(
    login_data: LoginRequest,
    db: AsyncSession = Depends(get_db)
):
    """JSON格式登录 - 兼容前端JSON请求"""
    try:
        # 查询用户
        result = await db.execute(
            select(User).where(User.username == login_data.username)
        )
        user = result.scalar_one_or_none()
        
        # 验证用户和密码
        if not user or not security_manager.verify_password(login_data.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="用户名或密码错误",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 检查用户是否活跃
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="用户账户已被禁用",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 创建JWT访问令牌和刷新令牌
        access_token = security_manager.create_access_token(
            data={"sub": str(user.id), "username": user.username}
        )
        refresh_token = security_manager.create_refresh_token(str(user.id))
        
        # 更新用户最后登录时间
        from datetime import datetime
        user.last_login = datetime.utcnow()
        await db.commit()
        
        return {
            "success": True,
            "data": {
                "access_token": access_token,
                "refresh_token": refresh_token,
                "token_type": "bearer",
                "expires_in": security_manager.access_token_expire_minutes * 60,
                "user": {
                    "id": str(user.id),
                    "username": user.username,
                    "email": user.email,
                    "is_active": user.is_active,
                    "is_superuser": user.is_superuser
                }
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"登录失败: {str(e)}"
        )


@router.post("/logout", response_model=None)
async def logout(
    current_user_id: str = Depends(get_current_user_id)
):
    """用户登出"""
    try:
        # 在实际应用中，这里可以将令牌加入黑名单
        # 目前只是返回成功消息
        return {"message": "登出成功"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"登出失败: {str(e)}"
        )

@router.get("/me", response_model=None)
async def get_current_user_info(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取当前用户信息"""
    return {
        "id": str(current_user.id),
        "username": current_user.username,
        "email": current_user.email,
        "is_active": current_user.is_active,
        "is_superuser": current_user.is_superuser,
        "last_login": current_user.last_login
    }

@router.post("/refresh", response_model=None)
async def refresh_token(
    refresh_token: str,
    db: AsyncSession = Depends(get_db)
):
    """刷新访问令牌 - 支持查询参数"""
    try:
        # 验证刷新令牌
        token_data = security_manager.verify_token(refresh_token, "refresh")
        if not token_data:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="无效的刷新令牌",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 查询用户
        user_id = token_data.sub
        result = await db.execute(
            select(User).where(User.id == user_id)
        )
        user = result.scalar_one_or_none()
        
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="用户不存在或已被禁用",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 创建新的访问令牌
        access_token = security_manager.create_access_token(
            data={"sub": str(user.id), "username": user.username}
        )
        
        return {
            "success": True,
            "data": {
                "access_token": access_token,
                "token_type": "bearer",
                "expires_in": security_manager.access_token_expire_minutes * 60,
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"刷新令牌失败: {str(e)}"
        )

@router.post("/refresh-json", response_model=None)
async def refresh_token_json(
    refresh_data: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)
):
    """刷新访问令牌 - 支持JSON请求体"""
    try:
        # 验证刷新令牌
        token_data = security_manager.verify_token(refresh_data.refresh_token, "refresh")
        if not token_data:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="无效的刷新令牌",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 查询用户
        user_id = token_data.sub
        result = await db.execute(
            select(User).where(User.id == user_id)
        )
        user = result.scalar_one_or_none()
        
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="用户不存在或已被禁用",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 创建新的访问令牌
        access_token = security_manager.create_access_token(
            data={"sub": str(user.id), "username": user.username}
        )
        
        return {
            "success": True,
            "data": {
                "access_token": access_token,
                "token_type": "bearer",
                "expires_in": security_manager.access_token_expire_minutes * 60,
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"刷新令牌失败: {str(e)}"
        )

@router.get("/health", response_model=None)
async def auth_health_check():
    """认证服务健康检查"""
    return {
        "status": "healthy",
        "service": "Authentication Service",
        "timestamp": time.time()
    }

@router.post("/verify-token", response_model=None)
async def verify_token(
    token_data: Dict[str, str] = Body(...),
    db: AsyncSession = Depends(get_db)
):
    """验证令牌有效性"""
    try:
        # 验证访问令牌
        token = token_data.get("token")
        if not token:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="缺少令牌参数"
            )
        token_data = security_manager.verify_token(token)
        if not token_data:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="无效的访问令牌",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 查询用户
        user_id = token_data.sub
        result = await db.execute(
            select(User).where(User.id == user_id)
        )
        user = result.scalar_one_or_none()
        
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="用户不存在或已被禁用",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        return {
            "valid": True,
            "user_id": str(user.id),
            "username": user.username,
            "expires_at": token_data.exp
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"验证令牌失败: {str(e)}"
        )