"""
认证相关API端点 - 使用真正的JWT认证
"""
import time
from datetime import timedelta, datetime
from typing import Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ...core.database import get_db
from ...core.security_enhanced import security_manager, get_current_user_id, get_current_user
from ...models.models_complete import User

router = APIRouter()

@router.post("/login", response_model=None)
async def login(
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    """用户登录（同时兼容JSON与表单）"""
    try:
        username: Optional[str] = None
        password: Optional[str] = None

        content_type = request.headers.get("content-type", "")
        if "application/json" in content_type:
            data = await request.json()
            username = (data or {}).get("username")
            password = (data or {}).get("password")
        else:
            form = await request.form()
            username = form.get("username")
            password = form.get("password")

        if not username or not password:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="缺少用户名或密码"
            )

        # 查询用户
        result = await db.execute(
            select(User).where(User.username == username)
        )
        user = result.scalar_one_or_none()
        
        # 验证用户和密码
        if not user or not security_manager.verify_password(password, user.hashed_password):
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
        try:
            user.last_login = datetime.utcnow()
            await db.commit()
        except Exception:
            # 不影响登录流程
            await db.rollback()
        
        return {
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
    request: Request,
    refresh_token: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """刷新访问令牌（支持JSON body和query参数）"""
    try:
        token_value = refresh_token
        if not token_value:
            # 尝试从JSON body中获取
            if request.headers.get("content-type", "").startswith("application/json"):
                try:
                    body = await request.json()
                    token_value = (body or {}).get("refresh_token")
                except Exception:
                    token_value = None
            # 再次尝试从表单
            if not token_value:
                try:
                    form = await request.form()
                    token_value = form.get("refresh_token")
                except Exception:
                    pass
        
        if not token_value:
            raise HTTPException(status_code=400, detail="缺少刷新令牌")

        # 验证刷新令牌
        token_data = security_manager.verify_token(token_value, "refresh")
        if not token_data:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="无效的刷新令牌",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 查询用户
        user_id = token_data.get("sub") if isinstance(token_data, dict) else getattr(token_data, "sub", None)
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
            "access_token": access_token,
            "token_type": "bearer",
            "expires_in": security_manager.access_token_expire_minutes * 60,
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
    request: Request,
    token: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """验证令牌有效性（支持Authorization头、JSON或query参数）"""
    try:
        access_token = token
        # 优先从Authorization头读取
        if not access_token:
            auth_header = request.headers.get("authorization")
            if auth_header and auth_header.lower().startswith("bearer "):
                access_token = auth_header.split(" ", 1)[1]
        # JSON体
        if not access_token and request.headers.get("content-type", "").startswith("application/json"):
            try:
                body = await request.json()
                access_token = (body or {}).get("token")
            except Exception:
                pass

        if not access_token:
            raise HTTPException(status_code=400, detail="缺少访问令牌")

        # 验证访问令牌
        token_data = security_manager.verify_token(access_token)
        if not token_data:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="无效的访问令牌",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 查询用户
        user_id = token_data.get("sub") if isinstance(token_data, dict) else getattr(token_data, "sub", None)
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
            "expires_at": token_data.get("exp") if isinstance(token_data, dict) else getattr(token_data, "exp", None)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"验证令牌失败: {str(e)}"
        )
