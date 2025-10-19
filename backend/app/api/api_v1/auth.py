"""
认证API端点 - 实现完整的JWT认证系统
"""
from datetime import datetime, timedelta
from typing import Any, Dict
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from ...core.database import get_db
from ...core.config_enhanced import settings
from ...core.logging import get_logger
from ...core.security_enhanced import (
    security_manager, authenticate_user, create_tokens, 
    refresh_access_token, get_current_active_user
)
from ...models.models_complete import User
from ...schemas.auth import (
    Token, TokenRefresh, UserLogin, UserResponse, 
    PasswordChange, PasswordReset
)
from ...schemas.user import UserCreate, UserUpdate
from ...services.user_service import UserService
from ...utils.rate_limit import rate_limit

logger = get_logger(__name__)
router = APIRouter()


@router.post("/login", response_model=Token, summary="用户登录")
@rate_limit(requests=5, window=300)  # 5分钟内最多5次登录尝试
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    用户登录接口
    
    - **username**: 用户名或邮箱
    - **password**: 密码
    
    返回访问令牌和刷新令牌
    """
    try:
        # 认证用户
        user = await authenticate_user(db, form_data.username, form_data.password)
        if not user:
            logger.warning("Login failed", username=form_data.username)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="用户名或密码错误",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 检查用户是否被锁定
        if user.locked_until and user.locked_until > datetime.utcnow():
            logger.warning("Login blocked - user locked", user_id=str(user.id))
            raise HTTPException(
                status_code=status.HTTP_423_LOCKED,
                detail="账户已被锁定，请稍后重试"
            )
        
        # 重置失败登录次数
        if user.failed_login_attempts > 0:
            user.failed_login_attempts = 0
            user.locked_until = None
            await db.commit()
        
        # 创建令牌
        tokens = create_tokens(str(user.id))
        
        logger.info("User logged in successfully", user_id=str(user.id), username=user.username)
        
        return {
            "access_token": tokens["access_token"],
            "refresh_token": tokens["refresh_token"],
            "token_type": "bearer",
            "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            "user": {
                "id": str(user.id),
                "username": user.username,
                "email": user.email,
                "full_name": user.full_name,
                "is_superuser": user.is_superuser
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Login error", username=form_data.username, error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="登录失败，请稍后重试"
        )


@router.post("/refresh", response_model=Token, summary="刷新令牌")
async def refresh_token(
    token_data: TokenRefresh,
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    刷新访问令牌
    
    - **refresh_token**: 刷新令牌
    
    返回新的访问令牌和刷新令牌
    """
    try:
        tokens = await refresh_access_token(db, token_data.refresh_token)
        if not tokens:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="无效的刷新令牌"
            )
        
        return {
            "access_token": tokens["access_token"],
            "refresh_token": tokens["refresh_token"],
            "token_type": "bearer",
            "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Token refresh error", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="令牌刷新失败"
        )


@router.post("/logout", summary="用户登出")
async def logout(
    current_user: User = Depends(get_current_active_user)
) -> Dict[str, str]:
    """
    用户登出
    
    注意：由于JWT是无状态的，客户端需要删除本地存储的令牌
    """
    logger.info("User logged out", user_id=str(current_user.id))
    
    return {"message": "登出成功"}


@router.get("/me", response_model=UserResponse, summary="获取当前用户信息")
async def get_current_user_info(
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
) -> User:
    """
    获取当前登录用户的详细信息
    """
    return current_user


@router.put("/me", response_model=UserResponse, summary="更新当前用户信息")
async def update_current_user(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
) -> User:
    """
    更新当前用户的信息
    """
    try:
        user_service = UserService(db)
        updated_user = await user_service.update_user(current_user.id, user_update)
        
        logger.info("User profile updated", user_id=str(current_user.id))
        
        return updated_user
        
    except Exception as e:
        logger.error("Profile update error", user_id=str(current_user.id), error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="更新用户信息失败"
        )


@router.post("/change-password", summary="修改密码")
async def change_password(
    password_data: PasswordChange,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, str]:
    """
    修改当前用户密码
    
    - **old_password**: 旧密码
    - **new_password**: 新密码
    """
    try:
        # 验证旧密码
        if not security_manager.verify_password(password_data.old_password, current_user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="旧密码错误"
            )
        
        # 验证新密码强度
        try:
            new_password_hash = security_manager.get_password_hash(password_data.new_password)
        except ValueError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(e)
            )
        
        # 更新密码
        user_service = UserService(db)
        await user_service.update_password(current_user.id, new_password_hash)
        
        logger.info("Password changed", user_id=str(current_user.id))
        
        return {"message": "密码修改成功"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Password change error", user_id=str(current_user.id), error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="密码修改失败"
        )


@router.post("/register", response_model=UserResponse, summary="用户注册")
@rate_limit(requests=3, window=3600)  # 1小时内最多3次注册
async def register(
    user_data: UserCreate,
    db: AsyncSession = Depends(get_db)
) -> User:
    """
    用户注册
    
    - **username**: 用户名
    - **email**: 邮箱
    - **password**: 密码
    - **full_name**: 全名（可选）
    """
    try:
        user_service = UserService(db)
        
        # 检查用户名和邮箱是否已存在
        existing_user = await user_service.get_user_by_username_or_email(
            user_data.username, user_data.email
        )
        if existing_user:
            if existing_user.username == user_data.username:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="用户名已存在"
                )
            else:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="邮箱已存在"
                )
        
        # 创建用户
        new_user = await user_service.create_user(user_data)
        
        logger.info("User registered", user_id=str(new_user.id), username=new_user.username)
        
        return new_user
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Registration error", username=user_data.username, error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="注册失败，请稍后重试"
        )


@router.post("/forgot-password", summary="忘记密码")
@rate_limit(requests=3, window=3600)  # 1小时内最多3次请求
async def forgot_password(
    email: str,
    db: AsyncSession = Depends(get_db)
) -> Dict[str, str]:
    """
    忘记密码 - 发送密码重置邮件
    
    - **email**: 用户邮箱
    """
    try:
        user_service = UserService(db)
        user = await user_service.get_user_by_email(email)
        
        if not user:
            # 为了安全，即使用户不存在也返回成功消息
            return {"message": "如果邮箱存在，密码重置邮件已发送"}
        
        # 生成密码重置令牌
        reset_token = security_manager.create_access_token(
            {"sub": str(user.id), "type": "password_reset"},
            expires_delta=timedelta(hours=1)
        )
        
        # TODO: 发送密码重置邮件
        # 这里应该实现邮件发送逻辑
        
        logger.info("Password reset requested", user_id=str(user.id), email=email)
        
        return {"message": "如果邮箱存在，密码重置邮件已发送"}
        
    except Exception as e:
        logger.error("Forgot password error", email=email, error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="密码重置请求失败"
        )


@router.post("/reset-password", summary="重置密码")
async def reset_password(
    reset_data: PasswordReset,
    db: AsyncSession = Depends(get_db)
) -> Dict[str, str]:
    """
    重置密码
    
    - **token**: 密码重置令牌
    - **new_password**: 新密码
    """
    try:
        # 验证重置令牌
        payload = security_manager.verify_token(reset_data.token, "password_reset")
        if not payload:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="无效或过期的重置令牌"
            )
        
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="无效的重置令牌"
            )
        
        # 验证新密码强度
        try:
            new_password_hash = security_manager.get_password_hash(reset_data.new_password)
        except ValueError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(e)
            )
        
        # 更新密码
        user_service = UserService(db)
        await user_service.update_password(user_id, new_password_hash)
        
        logger.info("Password reset completed", user_id=user_id)
        
        return {"message": "密码重置成功"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Password reset error", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="密码重置失败"
        )


@router.get("/verify-token", summary="验证令牌")
async def verify_token(
    current_user: User = Depends(get_current_active_user)
) -> Dict[str, Any]:
    """
    验证当前令牌是否有效
    """
    return {
        "valid": True,
        "user": {
            "id": str(current_user.id),
            "username": current_user.username,
            "email": current_user.email,
            "is_superuser": current_user.is_superuser
        }
    }
