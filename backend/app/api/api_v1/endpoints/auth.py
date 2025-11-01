"""
认证相关API端点 - 使用真正的JWT认证
"""
import time
from datetime import timedelta
from typing import Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Body, Request
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ...core.database import get_db
from ...core.security_enhanced import security_manager, get_current_user_id, get_current_user
from ...core.logging import get_logger
from ...core.unified_config import settings
from ...models.models_complete import User

router = APIRouter()
logger = get_logger(__name__)

# 简单的内存存储用于防暴力破解 (生产环境应该使用Redis)
_failed_login_attempts: Dict[str, list] = {}
_MAX_LOGIN_ATTEMPTS = 5
_LOGIN_WINDOW_SECONDS = 300  # 5分钟

def get_client_ip(request: Request) -> str:
    """获取客户端IP地址"""
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()
    
    real_ip = request.headers.get("X-Real-IP")
    if real_ip:
        return real_ip
    
    return request.client.host if request.client else "unknown"

def check_login_attempts(username: str, ip_address: str) -> bool:
    """检查登录尝试次数是否超过限制"""
    key = f"{username}:{ip_address}"
    current_time = time.time()
    
    # 清理过期记录
    if key in _failed_login_attempts:
        _failed_login_attempts[key] = [
            timestamp for timestamp in _failed_login_attempts[key]
            if current_time - timestamp < _LOGIN_WINDOW_SECONDS
        ]
    else:
        _failed_login_attempts[key] = []
    
    # 检查是否超过限制
    if len(_failed_login_attempts[key]) >= _MAX_LOGIN_ATTEMPTS:
        logger.warning(f"登录尝试次数过多: {username} from {ip_address}")
        return False
    
    return True

def record_failed_login(username: str, ip_address: str):
    """记录失败的登录尝试"""
    key = f"{username}:{ip_address}"
    if key not in _failed_login_attempts:
        _failed_login_attempts[key] = []
    
    _failed_login_attempts[key].append(time.time())
    logger.info(f"记录失败登录: {username} from {ip_address}")

def record_successful_login(username: str, ip_address: str):
    """记录成功的登录（清除失败记录）"""
    key = f"{username}:{ip_address}"
    if key in _failed_login_attempts:
        del _failed_login_attempts[key]
    logger.info(f"记录成功登录: {username} from {ip_address}")

# 定义JSON格式的登录请求模型
class LoginRequest(BaseModel):
    username: str
    password: str

# 定义JSON格式的刷新令牌请求模型
class RefreshTokenRequest(BaseModel):
    refresh_token: str

@router.post("/login", response_model=None)
async def login(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db)
):
    """用户登录 - 支持表单编码数据"""
    client_ip = get_client_ip(request)
    
    try:
        # 检查登录尝试次数（防暴力破解）
        if not check_login_attempts(form_data.username, client_ip):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"登录尝试次数过多，请{_LOGIN_WINDOW_SECONDS // 60}分钟后再试",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 查询用户
        result = await db.execute(
            select(User).where(User.username == form_data.username)
        )
        user = result.scalar_one_or_none()
        
        # 验证用户和密码
        if not user or not security_manager.verify_password(form_data.password, user.hashed_password):
            record_failed_login(form_data.username, client_ip)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="用户名或密码错误",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 检查用户是否活跃
        if not user.is_active:
            record_failed_login(form_data.username, client_ip)
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
        
        # 记录成功登录（清除失败记录）
        record_successful_login(form_data.username, client_ip)
        
        # 创建响应
        from fastapi.responses import JSONResponse
        from datetime import timedelta
        
        response_data = {
            "success": True,
            "data": {
                "access_token": access_token,  # 仍然返回，用于兼容
                "refresh_token": refresh_token,  # 仍然返回，用于兼容
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
        
        # 创建响应对象
        response = JSONResponse(content=response_data)
        
        # 根据环境设置secure标志（开发环境允许HTTP，生产环境必须HTTPS）
        secure_flag = not settings.DEBUG or (request.url.scheme == "https" if hasattr(request.url, 'scheme') else False)
        
        # 设置HttpOnly Cookie存储访问令牌（更安全，防止XSS）
        access_token_expires = timedelta(minutes=security_manager.access_token_expire_minutes)
        response.set_cookie(
            key="access_token",
            value=access_token,
            max_age=int(access_token_expires.total_seconds()),
            httponly=True,  # 防止JavaScript访问，防止XSS
            secure=secure_flag,  # 根据环境动态设置
            samesite="lax",  # CSRF保护
            path="/",
        )
        
        # 设置HttpOnly Cookie存储刷新令牌
        refresh_token_expires = timedelta(days=security_manager.refresh_token_expire_days)
        response.set_cookie(
            key="refresh_token",
            value=refresh_token,
            max_age=int(refresh_token_expires.total_seconds()),
            httponly=True,
            secure=secure_flag,  # 根据环境动态设置
            samesite="lax",
            path="/",
        )
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"登录失败: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"登录失败: {str(e)}"
        )

@router.post("/login-json", response_model=None)
async def login_json(
    request: Request,
    login_data: LoginRequest,
    db: AsyncSession = Depends(get_db)
):
    """JSON格式登录 - 兼容前端JSON请求"""
    client_ip = get_client_ip(request)
    
    try:
        # 检查登录尝试次数（防暴力破解）
        if not check_login_attempts(login_data.username, client_ip):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"登录尝试次数过多，请{_LOGIN_WINDOW_SECONDS // 60}分钟后再试",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 查询用户
        result = await db.execute(
            select(User).where(User.username == login_data.username)
        )
        user = result.scalar_one_or_none()
        
        # 验证用户和密码
        if not user or not security_manager.verify_password(login_data.password, user.hashed_password):
            record_failed_login(login_data.username, client_ip)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="用户名或密码错误",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 检查用户是否活跃
        if not user.is_active:
            record_failed_login(login_data.username, client_ip)
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
        
        # 记录成功登录（清除失败记录）
        record_successful_login(login_data.username, client_ip)
        
        # 创建响应
        from fastapi.responses import JSONResponse
        from datetime import timedelta
        
        response_data = {
            "success": True,
            "data": {
                "access_token": access_token,  # 仍然返回，用于兼容
                "refresh_token": refresh_token,  # 仍然返回，用于兼容
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
        
        # 创建响应对象
        response = JSONResponse(content=response_data)
        
        # 根据环境设置secure标志（开发环境允许HTTP，生产环境必须HTTPS）
        secure_flag = not settings.DEBUG or (request.url.scheme == "https" if hasattr(request.url, 'scheme') else False)
        
        # 设置HttpOnly Cookie存储访问令牌
        access_token_expires = timedelta(minutes=security_manager.access_token_expire_minutes)
        response.set_cookie(
            key="access_token",
            value=access_token,
            max_age=int(access_token_expires.total_seconds()),
            httponly=True,
            secure=secure_flag,  # 根据环境动态设置
            samesite="lax",
            path="/",
        )
        
        # 设置HttpOnly Cookie存储刷新令牌
        refresh_token_expires = timedelta(days=security_manager.refresh_token_expire_days)
        response.set_cookie(
            key="refresh_token",
            value=refresh_token,
            max_age=int(refresh_token_expires.total_seconds()),
            httponly=True,
            secure=secure_flag,  # 根据环境动态设置
            samesite="lax",
            path="/",
        )
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"登录失败: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"登录失败: {str(e)}"
        )


@router.post("/logout", response_model=None)
async def logout(
    request: Request,
    current_user_id: str = Depends(get_current_user_id)
):
    """用户登出 - 将令牌加入黑名单"""
    try:
        from ...core.token_blacklist import add_to_blacklist
        
        # 获取访问令牌
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            token = auth_header[7:]  # 移除 "Bearer " 前缀
            
            # 解码令牌获取过期时间
            try:
                from jose import jwt
                from ...core.unified_config import settings
                payload = jwt.decode(
                    token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
                )
                expires_at = payload.get("exp")
                
                # 将令牌添加到黑名单
                add_to_blacklist(token, expires_at)
                logger.info(f"用户 {current_user_id} 已登出，令牌已加入黑名单")
            except Exception as e:
                logger.warning(f"无法解析令牌添加到黑名单: {str(e)}")
        
        # 创建响应并清除Cookie
        from fastapi.responses import JSONResponse
        
        response = JSONResponse({"success": True, "message": "登出成功"})
        
        # 清除访问令牌Cookie
        response.delete_cookie(
            key="access_token",
            path="/",
            httponly=True,
            samesite="lax"
        )
        
        # 清除刷新令牌Cookie
        response.delete_cookie(
            key="refresh_token",
            path="/",
            httponly=True,
            samesite="lax"
        )
        
        return response
    except Exception as e:
        logger.error(f"登出失败: {str(e)}")
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
        "success": True,
        "data": {
            "id": str(current_user.id),
            "username": current_user.username,
            "email": current_user.email,
            "is_active": current_user.is_active,
            "is_superuser": current_user.is_superuser,
            "last_login": current_user.last_login.isoformat() if getattr(current_user, "last_login", None) else None
        }
    }

@router.post("/refresh", response_model=None)
async def refresh_token(
    request: Request,
    refresh_data: Optional[RefreshTokenRequest] = Body(None),
    refresh_token: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """刷新访问令牌 - 统一端点，支持查询参数和JSON请求体
    
    支持两种方式：
    1. JSON请求体: {"refresh_token": "..."}
    2. 查询参数: ?refresh_token=...
    """
    try:
        # 提取刷新令牌 - 优先使用JSON body，其次查询参数
        token = None
        if refresh_data and refresh_data.refresh_token:
            token = refresh_data.refresh_token
        elif refresh_token:
            token = refresh_token
        else:
            # 尝试从查询参数获取
            token = request.query_params.get("refresh_token")
        
        if not token:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="缺少刷新令牌参数",
            )
        
        # 验证刷新令牌
        token_data = security_manager.verify_token(token, "refresh")
        if not token_data:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="无效的刷新令牌",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 查询用户
        user_id = token_data.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="无效的令牌载荷",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
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
        
        # 创建响应
        from fastapi.responses import JSONResponse
        from datetime import timedelta
        
        response_data = {
            "success": True,
            "data": {
                "access_token": access_token,  # 仍然返回，用于兼容
                "token_type": "bearer",
                "expires_in": security_manager.access_token_expire_minutes * 60,
            }
        }
        
        response = JSONResponse(content=response_data)
        
        # 根据环境设置secure标志
        # 开发环境允许HTTP，生产环境必须HTTPS
        secure_flag = not settings.DEBUG or (request.url.scheme == "https" if hasattr(request.url, 'scheme') else False)
        
        # 更新访问令牌Cookie
        access_token_expires = timedelta(minutes=security_manager.access_token_expire_minutes)
        response.set_cookie(
            key="access_token",
            value=access_token,
            max_age=int(access_token_expires.total_seconds()),
            httponly=True,
            secure=secure_flag,
            samesite="lax",
            path="/",
        )
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"刷新令牌失败: {str(e)}")
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
            "success": True,
            "data": {
                "valid": True,
                "user": {
                    "id": str(user.id),
                    "username": user.username
                },
                "expires_at": token_data.exp
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"验证令牌失败: {str(e)}"
        )
