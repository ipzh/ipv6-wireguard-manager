import uuid
import subprocess
import os
import qrcode
import io
import base64
from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey
from ..models.wireguard import WireGuardServer, WireGuardClient
from ..schemas.wireguard import (
    WireGuardServerCreate, WireGuardServerUpdate,
    WireGuardClientCreate, WireGuardClientUpdate,
    WireGuardStatus, WireGuardInterfaceStatus, WireGuardPeerStatus
)
from ..core.security import get_password_hash
import logging

logger = logging.getLogger(__name__)

class WireGuardService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.config_dir = "/etc/wireguard"
        self.ensure_config_dir()

    def ensure_config_dir(self):
        """确保配置目录存在"""
        if not os.path.exists(self.config_dir):
            os.makedirs(self.config_dir, mode=0o700)

    def generate_keypair(self) -> tuple[str, str]:
        """生成WireGuard密钥对"""
        try:
            # 生成私钥
            private_key = X25519PrivateKey.generate()
            private_bytes = private_key.private_bytes(
                encoding=serialization.Encoding.Raw,
                format=serialization.PrivateFormat.Raw,
                encryption_algorithm=serialization.NoEncryption()
            )
            private_key_str = base64.b64encode(private_bytes).decode('ascii')

            # 生成公钥
            public_key = private_key.public_key()
            public_bytes = public_key.public_bytes(
                encoding=serialization.Encoding.Raw,
                format=serialization.PublicFormat.Raw
            )
            public_key_str = base64.b64encode(public_bytes).decode('ascii')

            return private_key_str, public_key_str
        except Exception as e:
            logger.error(f"生成密钥对失败: {e}")
            raise

    async def create_server(self, server_in: WireGuardServerCreate) -> WireGuardServer:
        """创建WireGuard服务器"""
        try:
            # 生成密钥对
            private_key, public_key = self.generate_keypair()
            
            # 创建服务器记录
            server = WireGuardServer(
                name=server_in.name,
                interface=server_in.interface,
                listen_port=server_in.listen_port,
                private_key=private_key,
                public_key=public_key,
                ipv4_address=server_in.ipv4_address,
                ipv6_address=server_in.ipv6_address,
                dns_servers=server_in.dns_servers,
                mtu=server_in.mtu,
                config_file_path=f"{self.config_dir}/{server_in.interface}.conf"
            )
            
            self.db.add(server)
            await self.db.commit()
            await self.db.refresh(server)
            
            # 生成配置文件
            await self.generate_server_config(server)
            
            return server
        except Exception as e:
            await self.db.rollback()
            logger.error(f"创建服务器失败: {e}")
            raise

    async def update_server(self, server: WireGuardServer, server_in: WireGuardServerUpdate) -> WireGuardServer:
        """更新WireGuard服务器"""
        try:
            update_data = server_in.model_dump(exclude_unset=True)
            for field, value in update_data.items():
                setattr(server, field, value)
            
            await self.db.commit()
            await self.db.refresh(server)
            
            # 重新生成配置文件
            await self.generate_server_config(server)
            
            return server
        except Exception as e:
            await self.db.rollback()
            logger.error(f"更新服务器失败: {e}")
            raise

    async def delete_server(self, server: WireGuardServer):
        """删除WireGuard服务器"""
        try:
            # 停止服务器
            await self.stop_server(server)
            
            # 删除配置文件
            if server.config_file_path and os.path.exists(server.config_file_path):
                os.remove(server.config_file_path)
            
            # 删除数据库记录
            await self.db.delete(server)
            await self.db.commit()
        except Exception as e:
            await self.db.rollback()
            logger.error(f"删除服务器失败: {e}")
            raise

    async def get_server_by_id(self, server_id: uuid.UUID) -> Optional[WireGuardServer]:
        """根据ID获取服务器"""
        result = await self.db.execute(
            select(WireGuardServer).where(WireGuardServer.id == server_id)
        )
        return result.scalars().first()

    async def get_servers(self) -> List[WireGuardServer]:
        """获取所有服务器"""
        result = await self.db.execute(select(WireGuardServer))
        return result.scalars().all()

    async def generate_server_config(self, server: WireGuardServer) -> str:
        """生成服务器配置文件"""
        try:
            config_content = f"""[Interface]
PrivateKey = {server.private_key}
Address = {server.ipv4_address or ''}
Address = {server.ipv6_address or ''}
ListenPort = {server.listen_port}
MTU = {server.mtu}
"""
            
            if server.dns_servers:
                dns_servers = " ".join(server.dns_servers)
                config_content += f"DNS = {dns_servers}\n"
            
            # 添加客户端配置
            clients = await self.get_clients_by_server(server.id)
            for client in clients:
                config_content += f"""
[Peer]
PublicKey = {client.public_key}
AllowedIPs = {client.ipv4_address or ''}
AllowedIPs = {client.ipv6_address or ''}
PersistentKeepalive = {client.persistent_keepalive}
"""
            
            # 写入配置文件
            with open(server.config_file_path, 'w') as f:
                f.write(config_content)
            
            # 设置文件权限
            os.chmod(server.config_file_path, 0o600)
            
            return config_content
        except Exception as e:
            logger.error(f"生成服务器配置失败: {e}")
            raise

    async def start_server(self, server: WireGuardServer) -> bool:
        """启动WireGuard服务器"""
        try:
            cmd = ["wg-quick", "up", server.interface]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                server.is_active = True
                await self.db.commit()
                logger.info(f"服务器 {server.name} 启动成功")
                return True
            else:
                logger.error(f"启动服务器失败: {result.stderr}")
                return False
        except Exception as e:
            logger.error(f"启动服务器异常: {e}")
            return False

    async def stop_server(self, server: WireGuardServer) -> bool:
        """停止WireGuard服务器"""
        try:
            cmd = ["wg-quick", "down", server.interface]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                server.is_active = False
                await self.db.commit()
                logger.info(f"服务器 {server.name} 停止成功")
                return True
            else:
                logger.error(f"停止服务器失败: {result.stderr}")
                return False
        except Exception as e:
            logger.error(f"停止服务器异常: {e}")
            return False

    async def restart_server(self, server: WireGuardServer) -> bool:
        """重启WireGuard服务器"""
        await self.stop_server(server)
        return await self.start_server(server)

    async def get_server_status(self, server: WireGuardServer) -> WireGuardStatus:
        """获取服务器状态"""
        try:
            cmd = ["wg", "show", server.interface]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode != 0:
                raise Exception(f"获取状态失败: {result.stderr}")
            
            # 解析wg show输出
            lines = result.stdout.strip().split('\n')
            interface_info = WireGuardInterfaceStatus(
                interface=server.interface,
                public_key=server.public_key,
                private_key=server.private_key,
                listening_port=server.listen_port,
                peers=0
            )
            
            peers = []
            for line in lines:
                if line.startswith('peer:'):
                    # 解析peer信息
                    peer_info = self.parse_peer_info(line)
                    if peer_info:
                        peers.append(peer_info)
            
            interface_info.peers = len(peers)
            
            return WireGuardStatus(
                interface=interface_info,
                peers=peers
            )
        except Exception as e:
            logger.error(f"获取服务器状态失败: {e}")
            raise

    def parse_peer_info(self, peer_line: str) -> Optional[WireGuardPeerStatus]:
        """解析peer信息"""
        try:
            # 这里需要根据实际的wg show输出格式来解析
            # 简化实现，实际需要更复杂的解析逻辑
            return WireGuardPeerStatus(
                public_key="",
                preshared_key="",
                allowed_ips=[],
                persistent_keepalive=0
            )
        except Exception as e:
            logger.error(f"解析peer信息失败: {e}")
            return None

    # 客户端管理方法
    async def create_client(self, client_in: WireGuardClientCreate) -> WireGuardClient:
        """创建WireGuard客户端"""
        try:
            # 生成密钥对
            private_key, public_key = self.generate_keypair()
            
            # 创建客户端记录
            client = WireGuardClient(
                server_id=client_in.server_id,
                name=client_in.name,
                description=client_in.description,
                private_key=private_key,
                public_key=public_key,
                ipv4_address=client_in.ipv4_address,
                ipv6_address=client_in.ipv6_address,
                allowed_ips=client_in.allowed_ips,
                persistent_keepalive=client_in.persistent_keepalive,
                config_file_path=f"{self.config_dir}/clients/{client_in.name}.conf"
            )
            
            self.db.add(client)
            await self.db.commit()
            await self.db.refresh(client)
            
            # 生成客户端配置和QR码
            await self.generate_client_config(client)
            
            return client
        except Exception as e:
            await self.db.rollback()
            logger.error(f"创建客户端失败: {e}")
            raise

    async def get_client_by_id(self, client_id: uuid.UUID) -> Optional[WireGuardClient]:
        """根据ID获取客户端"""
        result = await self.db.execute(
            select(WireGuardClient).where(WireGuardClient.id == client_id)
        )
        return result.scalars().first()

    async def get_clients_by_server(self, server_id: uuid.UUID) -> List[WireGuardClient]:
        """根据服务器ID获取客户端列表"""
        result = await self.db.execute(
            select(WireGuardClient).where(WireGuardClient.server_id == server_id)
        )
        return result.scalars().all()

    async def generate_client_config(self, client: WireGuardClient) -> str:
        """生成客户端配置文件"""
        try:
            server = await self.get_server_by_id(client.server_id)
            if not server:
                raise Exception("服务器不存在")
            
            config_content = f"""[Interface]
PrivateKey = {client.private_key}
Address = {client.ipv4_address or ''}
Address = {client.ipv6_address or ''}
DNS = {', '.join(server.dns_servers) if server.dns_servers else ''}

[Peer]
PublicKey = {server.public_key}
Endpoint = {server.ipv4_address or server.ipv6_address}:{server.listen_port}
AllowedIPs = {', '.join(client.allowed_ips) if client.allowed_ips else '0.0.0.0/0, ::/0'}
PersistentKeepalive = {client.persistent_keepalive}
"""
            
            # 写入配置文件
            client_dir = os.path.dirname(client.config_file_path)
            if not os.path.exists(client_dir):
                os.makedirs(client_dir, mode=0o700)
            
            with open(client.config_file_path, 'w') as f:
                f.write(config_content)
            
            # 设置文件权限
            os.chmod(client.config_file_path, 0o600)
            
            # 生成QR码
            qr_code = self.generate_qr_code(config_content)
            client.qr_code = qr_code
            await self.db.commit()
            
            return config_content
        except Exception as e:
            logger.error(f"生成客户端配置失败: {e}")
            raise

    def generate_qr_code(self, config_content: str) -> str:
        """生成配置的QR码"""
        try:
            qr = qrcode.QRCode(version=1, box_size=10, border=5)
            qr.add_data(config_content)
            qr.make(fit=True)
            
            img = qr.make_image(fill_color="black", back_color="white")
            
            # 转换为base64
            buffer = io.BytesIO()
            img.save(buffer, format='PNG')
            img_str = base64.b64encode(buffer.getvalue()).decode()
            
            return f"data:image/png;base64,{img_str}"
        except Exception as e:
            logger.error(f"生成QR码失败: {e}")
            return ""

    async def update_client(self, client: WireGuardClient, client_in: WireGuardClientUpdate) -> WireGuardClient:
        """更新WireGuard客户端"""
        try:
            update_data = client_in.model_dump(exclude_unset=True)
            for field, value in update_data.items():
                setattr(client, field, value)
            
            await self.db.commit()
            await self.db.refresh(client)
            
            # 重新生成配置
            await self.generate_client_config(client)
            
            return client
        except Exception as e:
            await self.db.rollback()
            logger.error(f"更新客户端失败: {e}")
            raise

    async def delete_client(self, client: WireGuardClient):
        """删除WireGuard客户端"""
        try:
            # 删除配置文件
            if client.config_file_path and os.path.exists(client.config_file_path):
                os.remove(client.config_file_path)
            
            # 删除数据库记录
            await self.db.delete(client)
            await self.db.commit()
        except Exception as e:
            await self.db.rollback()
            logger.error(f"删除客户端失败: {e}")
            raise
