"""
MFA (多因素认证) API端点
"""
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any
import pyotp
import qrcode
import io
import base64

from ...core.database import get_async_db
from ...core.security_enhanced import get_current_user
from ...core.mfa_manager import MFAManager, MFAConfig
from ...models.models_complete import User
from ...schemas.user import UserResponse

router = APIRouter()
security = HTTPBearer()

@router.post("/setup", summary="设置MFA")
async def setup_mfa(
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """设置MFA"""
    try:
        mfa_manager = MFAManager(config=MFAConfig())
        
        # 生成TOTP密钥
        secret = mfa_manager.generate_totp_secret()
        
        # 生成QR码
        totp_uri = pyotp.totp.TOTP(secret).provisioning_uri(
            name=current_user.username,
            issuer_name="IPv6 WireGuard Manager"
        )
        
        qr = qrcode.QRCode(version=1, box_size=10, border=5)
        qr.add_data(totp_uri)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        qr_code = base64.b64encode(buffer.getvalue()).decode()
        
        # 生成备用代码
        backup_codes = mfa_manager.generate_backup_codes()
        
        return {
            "secret": secret,
            "qr_code": f"data:image/png;base64,{qr_code}",
            "backup_codes": backup_codes,
            "message": "请使用认证器应用扫描QR码，并保存备用代码"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"MFA设置失败: {str(e)}"
        )

@router.post("/verify", summary="验证MFA")
async def verify_mfa(
    code: str,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """验证MFA代码"""
    try:
        mfa_manager = MFAManager(config=MFAConfig())
        
        # 验证TOTP代码
        is_valid = await mfa_manager.verify_totp_code(db, current_user.id, code)
        
        if is_valid:
            return {"message": "MFA验证成功", "verified": True}
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="MFA验证失败"
            )
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"MFA验证失败: {str(e)}"
        )

@router.post("/enable", summary="启用MFA")
async def enable_mfa(
    secret: str,
    verification_code: str,
    backup_codes: list,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """启用MFA"""
    try:
        mfa_manager = MFAManager(config=MFAConfig())
        
        # 验证代码
        totp = pyotp.TOTP(secret)
        if not totp.verify(verification_code):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="验证代码无效"
            )
        
        # 启用MFA
        await mfa_manager.enable_mfa(db, current_user.id, secret, backup_codes)
        
        return {"message": "MFA已启用", "enabled": True}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"MFA启用失败: {str(e)}"
        )

@router.post("/disable", summary="禁用MFA")
async def disable_mfa(
    verification_code: str,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """禁用MFA"""
    try:
        mfa_manager = MFAManager(config=MFAConfig())
        
        # 验证代码
        is_valid = await mfa_manager.verify_totp_code(db, current_user.id, verification_code)
        if not is_valid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="验证代码无效"
            )
        
        # 禁用MFA
        await mfa_manager.disable_mfa(db, current_user.id)
        
        return {"message": "MFA已禁用", "enabled": False}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"MFA禁用失败: {str(e)}"
        )

@router.get("/status", summary="获取MFA状态")
async def get_mfa_status(
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """获取MFA状态"""
    try:
        mfa_manager = MFAManager(config=MFAConfig())
        status = await mfa_manager.get_mfa_status(db, current_user.id)
        
        return {
            "enabled": status.get("enabled", False),
            "totp_enabled": status.get("totp_enabled", False),
            "backup_codes_count": status.get("backup_codes_count", 0)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取MFA状态失败: {str(e)}"
        )

@router.post("/backup-codes", summary="重新生成备用代码")
async def regenerate_backup_codes(
    verification_code: str,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """重新生成备用代码"""
    try:
        mfa_manager = MFAManager(config=MFAConfig())
        
        # 验证代码
        is_valid = await mfa_manager.verify_totp_code(db, current_user.id, verification_code)
        if not is_valid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="验证代码无效"
            )
        
        # 生成新的备用代码
        backup_codes = mfa_manager.generate_backup_codes()
        await mfa_manager.update_backup_codes(db, current_user.id, backup_codes)
        
        return {
            "backup_codes": backup_codes,
            "message": "备用代码已重新生成"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"重新生成备用代码失败: {str(e)}"
        )
