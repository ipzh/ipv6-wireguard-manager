"""
WireGuard服务
"""
import uuid
import subprocess
import os
import qrcode
import io
import base64
from datetime import datetime
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
    WireGuardStatus, WireGuardInterfaceStatus, WireGuardPeerStatus,
    WireGuardConfig, WireGuardPeer
)
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

    async def get_config(self) -> WireGuardConfig:
        """获取WireGuard配置"""
        try:
            # 获取所有服务器
            servers = await self.get_servers()
            if not servers:
                return WireGuardConfig(server_config="", client_configs=[])
            
            server = servers[0]  # 使用第一个服务器
            server_config = await self.generate_server_config(server)
            
            # 获取所有客户端
            clients = await self.get_clients_by_server(server.id)
            client_configs = []
            
            for client in clients:
                client_config = await self.generate_client_config(client)
                client_configs.append({
                    "id": str(client.id),
                    "name": client.name,
                    "config": client_config
                })
            
            return WireGuardConfig(
                server_config=server_config,
                client_configs=client_configs
            )
        except Exception as e:
            logger.error(f"获取配置失败: {e}")
            raise

    async def update_config(self, config: WireGuardConfig) -> WireGuardConfig:
        """更新WireGuard配置"""
        try:
            # 这里可以实现配置更新逻辑
            # 暂时返回原配置
            return config
        except Exception as e:
            logger.error(f"更新配置失败: {e}")
            raise

    async def get_peers(self) -> List[WireGuardPeer]:
        """获取所有对等节点"""
        try:
            clients = await self.get_all_clients()
            peers = []
            
            for client in clients:
                peer = WireGuardPeer(
                    id=str(client.id),
                    name=client.name,
                    public_key=client.public_key,
                    allowed_ips=client.allowed_ips or [],
                    endpoint=None,
                    persistent_keepalive=client.persistent_keepalive
                )
                peers.append(peer)
            
            return peers
        except Exception as e:
            logger.error(f"获取对等节点失败: {e}")
            raise

    async def create_peer(self, peer: WireGuardPeer) -> WireGuardPeer:
        """创建新的对等节点"""
        try:
            # 获取第一个服务器
            servers = await self.get_servers()
            if not servers:
                raise Exception("没有可用的服务器")
            
            server = servers[0]
            
            # 创建客户端
            client_data = WireGuardClientCreate(
                server_id=server.id,
                name=peer.name,
                allowed_ips=peer.allowed_ips,
                persistent_keepalive=peer.persistent_keepalive
            )
            
            client = await self.create_client(client_data)
            
            return WireGuardPeer(
                id=str(client.id),
                name=client.name,
                public_key=client.public_key,
                allowed_ips=client.allowed_ips or [],
                endpoint=None,
                persistent_keepalive=client.persistent_keepalive
            )
        except Exception as e:
            logger.error(f"创建对等节点失败: {e}")
            raise

    async def get_peer(self, peer_id: str) -> Optional[WireGuardPeer]:
        """获取单个对等节点"""
        try:
            client = await self.get_client_by_id(uuid.UUID(peer_id))
            if not client:
                return None
            
            return WireGuardPeer(
                id=str(client.id),
                name=client.name,
                public_key=client.public_key,
                allowed_ips=client.allowed_ips or [],
                endpoint=None,
                persistent_keepalive=client.persistent_keepalive
            )
        except Exception as e:
            logger.error(f"获取对等节点失败: {e}")
            return None

    async def update_peer(self, peer_id: str, peer: WireGuardPeer) -> Optional[WireGuardPeer]:
        """更新对等节点"""
        try:
            client = await self.get_client_by_id(uuid.UUID(peer_id))
            if not client:
                return None
            
            # 更新客户端
            client_data = WireGuardClientUpdate(
                name=peer.name,
                allowed_ips=peer.allowed_ips,
                persistent_keepalive=peer.persistent_keepalive
            )
            
            updated_client = await self.update_client(client, client_data)
            
            return WireGuardPeer(
                id=str(updated_client.id),
                name=updated_client.name,
                public_key=updated_client.public_key,
                allowed_ips=updated_client.allowed_ips or [],
                endpoint=None,
                persistent_keepalive=updated_client.persistent_keepalive
            )
        except Exception as e:
            logger.error(f"更新对等节点失败: {e}")
            return None

    async def delete_peer(self, peer_id: str) -> bool:
        """删除对等节点"""
        try:
            client = await self.get_client_by_id(uuid.UUID(peer_id))
            if not client:
                return False
            
            await self.delete_client(client)
            return True
        except Exception as e:
            logger.error(f"删除对等节点失败: {e}")
            return False

    async def get_status(self) -> WireGuardStatus:
        """获取WireGuard状态"""
        try:
            # 获取所有服务器
            servers = await self.get_servers()
            if not servers:
                return WireGuardStatus(
                    interface=WireGuardInterfaceStatus(
                        name="wg0",
                        public_key="",
                        private_key="",
                        listen_port=51820,
                        fwmark=0,
                        peers=0
                    ),
                    peers=[]
                )
            
            # 使用第一个服务器
            server = servers[0]
            
            # 获取所有客户端作为peers
            clients = await self.get_all_clients()
            peers = []
            
            for client in clients:
                peer_status = WireGuardPeerStatus(
                    public_key=client.public_key,
                    preshared_key="",
                    allowed_ips=client.allowed_ips or [],
                    persistent_keepalive=client.persistent_keepalive or 25,
                    latest_handshake=int(datetime.now().timestamp()),
                    transfer_rx=0,
                    transfer_tx=0
                )
                peers.append(peer_status)
            
            interface_status = WireGuardInterfaceStatus(
                name=server.interface or "wg0",
                public_key=server.public_key,
                private_key=server.private_key,
                listen_port=server.listen_port or 51820,
                fwmark=0,
                peers=len(peers)
            )
            
            return WireGuardStatus(
                interface=interface_status,
                peers=peers
            )
        except Exception as e:
            logger.error(f"获取WireGuard状态失败: {e}")
            # 返回默认状态
            return WireGuardStatus(
                interface=WireGuardInterfaceStatus(
                    name="wg0",
                    public_key="",
                    private_key="",
                    listen_port=51820,
                    fwmark=0,
                    peers=0
                ),
                peers=[]
            )

    async def restart_peer(self, peer_id: str) -> bool:
        """重启对等节点"""
        try:
            # 这里可以实现重启逻辑
            # 暂时返回成功
            return True
        except Exception as e:
            logger.error(f"重启对等节点失败: {e}")
            return False

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

    async def get_all_clients(self) -> List[WireGuardClient]:
        """获取所有客户端"""
        result = await self.db.execute(select(WireGuardClient))
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