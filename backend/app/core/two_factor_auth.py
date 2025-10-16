"""
双因子认证(2FA)支持
提供TOTP、SMS、邮件等多种2FA认证方式
"""
import asyncio
import base64
import hashlib
import hmac
import secrets
import time
import qrcode
import io
import logging
from typing import Dict, Any, Optional, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass
import pyotp
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import redis.asyncio as redis

logger = logging.getLogger(__name__)

@dataclass
class TwoFactorConfig:
    """双因子认证配置"""
    user_id: str
    method: str  # totp, sms, email
    secret: Optional[str] = None
    backup_codes: list = None
    enabled: bool = False
    created_at: datetime = None
    last_used: Optional[datetime] = None

@dataclass
class TwoFactorSession:
    """双因子认证会话"""
    session_id: str
    user_id: str
    method: str
    expires_at: datetime
    attempts: int = 0
    max_attempts: int = 3

class TOTPManager:
    """TOTP认证管理器"""
    
    def __init__(self):
        self.issuer_name = "IPv6 WireGuard Manager"
        self.window = 1  # 允许的时间窗口
    
    def generate_secret(self) -> str:
        """生成TOTP密钥"""
        return pyotp.random_base32()
    
    def generate_qr_code(self, user_email: str, secret: str) -> str:
        """生成QR码"""
        totp_uri = pyotp.totp.TOTP(secret).provisioning_uri(
            name=user_email,
            issuer_name=self.issuer_name
        )
        
        qr = qrcode.QRCode(version=1, box_size=10, border=5)
        qr.add_data(totp_uri)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        
        # 转换为base64字符串
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        img_str = base64.b64encode(buffer.getvalue()).decode()
        
        return f"data:image/png;base64,{img_str}"
    
    def verify_totp(self, secret: str, token: str) -> bool:
        """验证TOTP令牌"""
        try:
            totp = pyotp.TOTP(secret)
            return totp.verify(token, valid_window=self.window)
        except Exception as e:
            logger.error(f"TOTP验证失败: {e}")
            return False
    
    def get_current_token(self, secret: str) -> str:
        """获取当前TOTP令牌"""
        totp = pyotp.TOTP(secret)
        return totp.now()

class SMSManager:
    """SMS认证管理器"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.provider = config.get('provider', 'twilio')
        self.api_key = config.get('api_key')
        self.api_secret = config.get('api_secret')
        self.from_number = config.get('from_number')
    
    async def send_sms_code(self, phone_number: str, code: str) -> bool:
        """发送SMS验证码"""
        try:
            if self.provider == 'twilio':
                return await self._send_twilio_sms(phone_number, code)
            elif self.provider == 'aliyun':
                return await self._send_aliyun_sms(phone_number, code)
            else:
                logger.error(f"不支持的SMS提供商: {self.provider}")
                return False
        except Exception as e:
            logger.error(f"发送SMS失败: {e}")
            return False
    
    async def _send_twilio_sms(self, phone_number: str, code: str) -> bool:
        """使用Twilio发送SMS"""
        try:
            from twilio.rest import Client
            
            client = Client(self.api_key, self.api_secret)
            message = client.messages.create(
                body=f"您的验证码是: {code}，有效期5分钟。",
                from_=self.from_number,
                to=phone_number
            )
            
            logger.info(f"SMS发送成功: {message.sid}")
            return True
        except Exception as e:
            logger.error(f"Twilio SMS发送失败: {e}")
            return False
    
    async def _send_aliyun_sms(self, phone_number: str, code: str) -> bool:
        """使用阿里云发送SMS"""
        try:
            from aliyunsdkcore.client import AcsClient
            from aliyunsdkcore.request import CommonRequest
            
            client = AcsClient(self.api_key, self.api_secret, 'cn-hangzhou')
            request = CommonRequest()
            request.set_accept_format('json')
            request.set_domain('dysmsapi.aliyuncs.com')
            request.set_method('POST')
            request.set_protocol_type('https')
            request.set_version('2017-05-25')
            request.set_action_name('SendSms')
            
            request.add_query_param('RegionId', "cn-hangzhou")
            request.add_query_param('PhoneNumbers', phone_number)
            request.add_query_param('SignName', "IPv6 WireGuard")
            request.add_query_param('TemplateCode', "SMS_123456789")
            request.add_query_param('TemplateParam', f'{{"code":"{code}"}}')
            
            response = client.do_action(request)
            logger.info(f"阿里云SMS发送成功: {response}")
            return True
        except Exception as e:
            logger.error(f"阿里云SMS发送失败: {e}")
            return False

class EmailManager:
    """邮件认证管理器"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.smtp_server = config.get('smtp_server')
        self.smtp_port = config.get('smtp_port', 587)
        self.username = config.get('username')
        self.password = config.get('password')
        self.from_email = config.get('from_email')
    
    async def send_email_code(self, email: str, code: str) -> bool:
        """发送邮件验证码"""
        try:
            msg = MIMEMultipart()
            msg['From'] = self.from_email
            msg['To'] = email
            msg['Subject'] = "IPv6 WireGuard Manager - 验证码"
            
            body = f"""
            <html>
            <body>
                <h2>IPv6 WireGuard Manager</h2>
                <p>您的验证码是: <strong>{code}</strong></p>
                <p>验证码有效期为5分钟，请及时使用。</p>
                <p>如果这不是您的操作，请忽略此邮件。</p>
                <br>
                <p>此邮件由系统自动发送，请勿回复。</p>
            </body>
            </html>
            """
            
            msg.attach(MIMEText(body, 'html'))
            
            server = smtplib.SMTP(self.smtp_server, self.smtp_port)
            server.starttls()
            server.login(self.username, self.password)
            text = msg.as_string()
            server.sendmail(self.from_email, email, text)
            server.quit()
            
            logger.info(f"邮件验证码发送成功: {email}")
            return True
        except Exception as e:
            logger.error(f"邮件验证码发送失败: {e}")
            return False

class TwoFactorAuthManager:
    """双因子认证管理器"""
    
    def __init__(self, db_session: AsyncSession, redis_client: redis.Redis = None):
        self.db_session = db_session
        self.redis_client = redis_client
        
        # 初始化组件
        self.totp_manager = TOTPManager()
        self.sms_manager = None
        self.email_manager = None
        
        # 配置
        self.config = {
            'totp_enabled': True,
            'sms_enabled': False,
            'email_enabled': True,
            'backup_codes_count': 10,
            'session_timeout': 300,  # 5分钟
            'max_attempts': 3
        }
        
        # 验证码存储
        self.verification_codes = {}
    
    def configure_sms(self, sms_config: Dict[str, Any]):
        """配置SMS"""
        self.sms_manager = SMSManager(sms_config)
        self.config['sms_enabled'] = True
    
    def configure_email(self, email_config: Dict[str, Any]):
        """配置邮件"""
        self.email_manager = EmailManager(email_config)
        self.config['email_enabled'] = True
    
    async def setup_totp(self, user_id: str, user_email: str) -> Dict[str, Any]:
        """设置TOTP"""
        try:
            # 生成密钥
            secret = self.totp_manager.generate_secret()
            
            # 生成QR码
            qr_code = self.totp_manager.generate_qr_code(user_email, secret)
            
            # 生成备用码
            backup_codes = self._generate_backup_codes()
            
            # 保存配置（临时，需要用户验证后正式启用）
            temp_config = TwoFactorConfig(
                user_id=user_id,
                method='totp',
                secret=secret,
                backup_codes=backup_codes,
                enabled=False,
                created_at=datetime.now()
            )
            
            # 临时存储到Redis
            if self.redis_client:
                await self.redis_client.setex(
                    f"2fa_setup:{user_id}",
                    600,  # 10分钟过期
                    secret
                )
            
            return {
                'secret': secret,
                'qr_code': qr_code,
                'backup_codes': backup_codes,
                'manual_entry_key': secret
            }
        except Exception as e:
            logger.error(f"TOTP设置失败: {e}")
            raise
    
    async def verify_totp_setup(self, user_id: str, token: str) -> bool:
        """验证TOTP设置"""
        try:
            # 从Redis获取临时密钥
            if self.redis_client:
                secret = await self.redis_client.get(f"2fa_setup:{user_id}")
                if not secret:
                    return False
                
                secret = secret.decode()
            else:
                return False
            
            # 验证令牌
            if self.totp_manager.verify_totp(secret, token):
                # 保存到数据库
                await self._save_2fa_config(user_id, 'totp', secret)
                
                # 删除临时密钥
                await self.redis_client.delete(f"2fa_setup:{user_id}")
                
                logger.info(f"用户 {user_id} TOTP设置成功")
                return True
            
            return False
        except Exception as e:
            logger.error(f"TOTP设置验证失败: {e}")
            return False
    
    async def send_sms_code(self, user_id: str, phone_number: str) -> bool:
        """发送SMS验证码"""
        if not self.sms_manager:
            return False
        
        try:
            # 生成验证码
            code = self._generate_verification_code()
            
            # 发送SMS
            success = await self.sms_manager.send_sms_code(phone_number, code)
            
            if success:
                # 存储验证码
                await self._store_verification_code(user_id, 'sms', code)
                return True
            
            return False
        except Exception as e:
            logger.error(f"发送SMS验证码失败: {e}")
            return False
    
    async def send_email_code(self, user_id: str, email: str) -> bool:
        """发送邮件验证码"""
        if not self.email_manager:
            return False
        
        try:
            # 生成验证码
            code = self._generate_verification_code()
            
            # 发送邮件
            success = await self.email_manager.send_email_code(email, code)
            
            if success:
                # 存储验证码
                await self._store_verification_code(user_id, 'email', code)
                return True
            
            return False
        except Exception as e:
            logger.error(f"发送邮件验证码失败: {e}")
            return False
    
    async def verify_2fa(self, user_id: str, method: str, code: str) -> bool:
        """验证双因子认证"""
        try:
            # 获取用户2FA配置
            config = await self._get_2fa_config(user_id, method)
            if not config:
                return False
            
            if method == 'totp':
                return self.totp_manager.verify_totp(config.secret, code)
            elif method in ['sms', 'email']:
                return await self._verify_verification_code(user_id, method, code)
            elif method == 'backup_code':
                return await self._verify_backup_code(user_id, code)
            
            return False
        except Exception as e:
            logger.error(f"2FA验证失败: {e}")
            return False
    
    async def create_2fa_session(self, user_id: str, method: str) -> str:
        """创建2FA会话"""
        session_id = secrets.token_hex(16)
        expires_at = datetime.now() + timedelta(seconds=self.config['session_timeout'])
        
        session = TwoFactorSession(
            session_id=session_id,
            user_id=user_id,
            method=method,
            expires_at=expires_at
        )
        
        # 存储到Redis
        if self.redis_client:
            await self.redis_client.setex(
                f"2fa_session:{session_id}",
                self.config['session_timeout'],
                f"{user_id}:{method}:{expires_at.isoformat()}"
            )
        
        return session_id
    
    async def verify_2fa_session(self, session_id: str, code: str) -> Tuple[bool, Optional[str]]:
        """验证2FA会话"""
        try:
            # 从Redis获取会话信息
            if self.redis_client:
                session_data = await self.redis_client.get(f"2fa_session:{session_id}")
                if not session_data:
                    return False, "会话已过期"
                
                session_data = session_data.decode()
                user_id, method, expires_at_str = session_data.split(':')
                expires_at = datetime.fromisoformat(expires_at_str)
                
                if datetime.now() > expires_at:
                    return False, "会话已过期"
                
                # 验证2FA代码
                if await self.verify_2fa(user_id, method, code):
                    # 删除会话
                    await self.redis_client.delete(f"2fa_session:{session_id}")
                    return True, user_id
                
                return False, "验证码错误"
            
            return False, "会话验证失败"
        except Exception as e:
            logger.error(f"2FA会话验证失败: {e}")
            return False, "验证失败"
    
    async def disable_2fa(self, user_id: str, method: str) -> bool:
        """禁用2FA"""
        try:
            await self._delete_2fa_config(user_id, method)
            logger.info(f"用户 {user_id} 的 {method} 2FA已禁用")
            return True
        except Exception as e:
            logger.error(f"禁用2FA失败: {e}")
            return False
    
    async def get_2fa_status(self, user_id: str) -> Dict[str, Any]:
        """获取2FA状态"""
        try:
            configs = await self._get_user_2fa_configs(user_id)
            
            status = {
                'totp_enabled': False,
                'sms_enabled': False,
                'email_enabled': False,
                'backup_codes_count': 0
            }
            
            for config in configs:
                if config.method == 'totp' and config.enabled:
                    status['totp_enabled'] = True
                elif config.method == 'sms' and config.enabled:
                    status['sms_enabled'] = True
                elif config.method == 'email' and config.enabled:
                    status['email_enabled'] = True
                
                if config.backup_codes:
                    status['backup_codes_count'] = len(config.backup_codes)
            
            return status
        except Exception as e:
            logger.error(f"获取2FA状态失败: {e}")
            return {}
    
    def _generate_verification_code(self) -> str:
        """生成验证码"""
        return str(secrets.randbelow(900000) + 100000)  # 6位数字
    
    def _generate_backup_codes(self) -> list:
        """生成备用码"""
        codes = []
        for _ in range(self.config['backup_codes_count']):
            code = secrets.token_hex(4).upper()
            codes.append(code)
        return codes
    
    async def _store_verification_code(self, user_id: str, method: str, code: str):
        """存储验证码"""
        if self.redis_client:
            key = f"2fa_code:{user_id}:{method}"
            await self.redis_client.setex(key, 300, code)  # 5分钟过期
    
    async def _verify_verification_code(self, user_id: str, method: str, code: str) -> bool:
        """验证验证码"""
        if self.redis_client:
            key = f"2fa_code:{user_id}:{method}"
            stored_code = await self.redis_client.get(key)
            if stored_code and stored_code.decode() == code:
                await self.redis_client.delete(key)
                return True
        return False
    
    async def _verify_backup_code(self, user_id: str, code: str) -> bool:
        """验证备用码"""
        try:
            config = await self._get_2fa_config(user_id, 'totp')
            if not config or not config.backup_codes:
                return False
            
            if code.upper() in config.backup_codes:
                # 移除已使用的备用码
                config.backup_codes.remove(code.upper())
                await self._update_2fa_config(config)
                return True
            
            return False
        except Exception as e:
            logger.error(f"备用码验证失败: {e}")
            return False
    
    async def _save_2fa_config(self, user_id: str, method: str, secret: str):
        """保存2FA配置"""
        try:
            query = """
            INSERT INTO two_factor_configs 
            (user_id, method, secret, enabled, created_at)
            VALUES (:user_id, :method, :secret, :enabled, :created_at)
            ON DUPLICATE KEY UPDATE
            secret = VALUES(secret),
            enabled = VALUES(enabled),
            updated_at = NOW()
            """
            await self.db_session.execute(text(query), {
                'user_id': user_id,
                'method': method,
                'secret': secret,
                'enabled': True,
                'created_at': datetime.now()
            })
            await self.db_session.commit()
        except Exception as e:
            logger.error(f"保存2FA配置失败: {e}")
            raise
    
    async def _get_2fa_config(self, user_id: str, method: str) -> Optional[TwoFactorConfig]:
        """获取2FA配置"""
        try:
            query = """
            SELECT * FROM two_factor_configs 
            WHERE user_id = :user_id AND method = :method AND enabled = 1
            """
            result = await self.db_session.execute(text(query), {
                'user_id': user_id,
                'method': method
            })
            row = result.fetchone()
            
            if row:
                return TwoFactorConfig(
                    user_id=row.user_id,
                    method=row.method,
                    secret=row.secret,
                    backup_codes=json.loads(row.backup_codes) if row.backup_codes else [],
                    enabled=row.enabled,
                    created_at=row.created_at,
                    last_used=row.last_used
                )
            return None
        except Exception as e:
            logger.error(f"获取2FA配置失败: {e}")
            return None
    
    async def _get_user_2fa_configs(self, user_id: str) -> list:
        """获取用户所有2FA配置"""
        try:
            query = """
            SELECT * FROM two_factor_configs 
            WHERE user_id = :user_id AND enabled = 1
            """
            result = await self.db_session.execute(text(query), {'user_id': user_id})
            rows = result.fetchall()
            
            configs = []
            for row in rows:
                config = TwoFactorConfig(
                    user_id=row.user_id,
                    method=row.method,
                    secret=row.secret,
                    backup_codes=json.loads(row.backup_codes) if row.backup_codes else [],
                    enabled=row.enabled,
                    created_at=row.created_at,
                    last_used=row.last_used
                )
                configs.append(config)
            
            return configs
        except Exception as e:
            logger.error(f"获取用户2FA配置失败: {e}")
            return []
    
    async def _update_2fa_config(self, config: TwoFactorConfig):
        """更新2FA配置"""
        try:
            query = """
            UPDATE two_factor_configs 
            SET backup_codes = :backup_codes, updated_at = NOW()
            WHERE user_id = :user_id AND method = :method
            """
            await self.db_session.execute(text(query), {
                'user_id': config.user_id,
                'method': config.method,
                'backup_codes': json.dumps(config.backup_codes)
            })
            await self.db_session.commit()
        except Exception as e:
            logger.error(f"更新2FA配置失败: {e}")
            raise
    
    async def _delete_2fa_config(self, user_id: str, method: str):
        """删除2FA配置"""
        try:
            query = """
            UPDATE two_factor_configs 
            SET enabled = 0, updated_at = NOW()
            WHERE user_id = :user_id AND method = :method
            """
            await self.db_session.execute(text(query), {
                'user_id': user_id,
                'method': method
            })
            await self.db_session.commit()
        except Exception as e:
            logger.error(f"删除2FA配置失败: {e}")
            raise

# 全局2FA管理器实例
two_factor_auth_manager: Optional[TwoFactorAuthManager] = None

async def get_two_factor_auth_manager() -> TwoFactorAuthManager:
    """获取2FA管理器实例"""
    global two_factor_auth_manager
    if two_factor_auth_manager is None:
        raise ValueError("2FA管理器未初始化")
    return two_factor_auth_manager

async def init_two_factor_auth_manager(db_session: AsyncSession, redis_client: redis.Redis = None):
    """初始化2FA管理器"""
    global two_factor_auth_manager
    two_factor_auth_manager = TwoFactorAuthManager(db_session, redis_client)
    logger.info("2FA管理器初始化完成")
