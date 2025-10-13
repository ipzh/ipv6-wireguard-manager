import uuid
import subprocess
import os
import qrcode
import io
import base64
import re
import time
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

    async def get_server_status(self, server_id: str) -> WireGuardStatus:
        """获取服务器状态 - 优化版本"""
        try:
            # 执行 wg show 命令获取状态
            result = subprocess.run(
                ['wg', 'show', 'all', 'dump'],
                capture_output=True,
                text=True,
                check=True
            )
            
            lines = result.stdout.strip().split('\n')
            if not lines or lines[0] == '':
                return WireGuardStatus(
                    interface=WireGuardInterfaceStatus(
                        name="wg0",
                        public_key="",
                        private_key="",
                        listen_port=0,
                        fwmark=0,
                        peers=0
                    ),
                    peers=[]
                )
            
            # 解析接口信息
            interface_info = self.parse_interface_info(lines[0])
            
            # 解析peer信息
            peers = []
            for line in lines[1:]:
                if line.strip():
                    peer_info = self.parse_peer_dump(line)
                    if peer_info:
                        peers.append(peer_info)
            
            interface_info.peers = len(peers)
            
            return WireGuardStatus(
                interface=interface_info,
                peers=peers
            )
        except subprocess.CalledProcessError as e:
            logger.error(f"执行wg命令失败: {e}")
            # 返回默认状态
            return WireGuardStatus(
                interface=WireGuardInterfaceStatus(
                    name="wg0",
                    public_key="",
                    private_key="",
                    listen_port=0,
                    fwmark=0,
                    peers=0
                ),
                peers=[]
            )
        except Exception as e:
            logger.error(f"获取服务器状态失败: {e}")
            raise

    def parse_interface_info(self, interface_line: str) -> WireGuardInterfaceStatus:
        """解析接口信息"""
        try:
            # wg dump格式: interface private_key public_key listen_port fwmark
            parts = interface_line.split('\t')
            if len(parts) >= 5:
                return WireGuardInterfaceStatus(
                    name="wg0",  # 默认接口名
                    public_key=parts[2] if parts[2] != '(none)' else "",
                    private_key=parts[1] if parts[1] != '(none)' else "",
                    listen_port=int(parts[3]) if parts[3] != '0' else 0,
                    fwmark=int(parts[4]) if parts[4] != '0' else 0,
                    peers=0  # 将在后面设置
                )
            else:
                return WireGuardInterfaceStatus(
                    name="wg0",
                    public_key="",
                    private_key="",
                    listen_port=0,
                    fwmark=0,
                    peers=0
                )
        except Exception as e:
            logger.error(f"解析接口信息失败: {e}")
            return WireGuardInterfaceStatus(
                name="wg0",
                public_key="",
                private_key="",
                listen_port=0,
                fwmark=0,
                peers=0
            )

    def parse_peer_dump(self, peer_line: str) -> Optional[WireGuardPeerStatus]:
        """解析peer dump信息 - 优化版本"""
        try:
            # wg dump格式: peer public_key preshared_key endpoint allowed_ips latest_handshake transfer_rx transfer_tx persistent_keepalive
            parts = peer_line.split('\t')
            if len(parts) < 9:
                return None
            
            # 解析时间戳
            latest_handshake = None
            if parts[5] != '0':
                try:
                    latest_handshake = int(parts[5])
                except ValueError:
                    latest_handshake = None
            
            # 解析传输数据
            transfer_rx = 0
            transfer_tx = 0
            try:
                transfer_rx = int(parts[6]) if parts[6] != '0' else 0
                transfer_tx = int(parts[7]) if parts[7] != '0' else 0
            except ValueError:
                pass
            
            # 解析persistent keepalive
            persistent_keepalive = 0
            try:
                persistent_keepalive = int(parts[8]) if parts[8] != 'off' else 0
            except ValueError:
                pass
            
            # 解析allowed IPs
            allowed_ips = []
            if parts[4] and parts[4] != '(none)':
                allowed_ips = parts[4].split(',')
            
            return WireGuardPeerStatus(
                public_key=parts[0],
                preshared_key=parts[1] if parts[1] != '(none)' else "",
                endpoint=parts[3] if parts[3] != '(none)' else None,
                allowed_ips=allowed_ips,
                latest_handshake=latest_handshake,
                transfer_rx=transfer_rx,
                transfer_tx=transfer_tx,
                persistent_keepalive=persistent_keepalive
            )
        except Exception as e:
            logger.error(f"解析peer信息失败: {e}")
            return None

    def get_peer_connection_status(self, latest_handshake: Optional[int]) -> str:
        """获取peer连接状态"""
        if latest_handshake is None:
            return "disconnected"
        
        # 计算时间差
        current_time = datetime.now().timestamp()
        time_diff = current_time - latest_handshake
        
        if time_diff < 180:  # 3分钟内
            return "connected"
        elif time_diff < 3600:  # 1小时内
            return "recent"
        else:
            return "disconnected"

    def format_transfer_bytes(self, bytes_count: int) -> str:
        """格式化传输字节数"""
        if bytes_count == 0:
            return "0 B"
        
        units = ['B', 'KB', 'MB', 'GB', 'TB']
        unit_index = 0
        size = float(bytes_count)
        
        while size >= 1024 and unit_index < len(units) - 1:
            size /= 1024
            unit_index += 1
        
        return f"{size:.2f} {units[unit_index]}"

    async def get_real_time_metrics(self) -> Dict[str, Any]:
        """获取实时指标"""
        try:
            status = await self.get_server_status("wg0")
            
            total_rx = sum(peer.transfer_rx for peer in status.peers)
            total_tx = sum(peer.transfer_tx for peer in status.peers)
            
            connected_peers = sum(
                1 for peer in status.peers 
                if self.get_peer_connection_status(peer.latest_handshake) == "connected"
            )
            
            return {
                "total_peers": len(status.peers),
                "connected_peers": connected_peers,
                "total_rx": total_rx,
                "total_tx": total_tx,
                "total_rx_formatted": self.format_transfer_bytes(total_rx),
                "total_tx_formatted": self.format_transfer_bytes(total_tx),
                "interface_name": status.interface.name,
                "listen_port": status.interface.listen_port,
                "peers": [
                    {
                        "public_key": peer.public_key[:8] + "...",  # 只显示前8位
                        "endpoint": peer.endpoint,
                        "allowed_ips": peer.allowed_ips,
                        "status": self.get_peer_connection_status(peer.latest_handshake),
                        "transfer_rx": self.format_transfer_bytes(peer.transfer_rx),
                        "transfer_tx": self.format_transfer_bytes(peer.transfer_tx),
                        "latest_handshake": peer.latest_handshake
                    }
                    for peer in status.peers
                ]
            }
        except Exception as e:
            logger.error(f"获取实时指标失败: {e}")
            return {
                "total_peers": 0,
                "connected_peers": 0,
                "total_rx": 0,
                "total_tx": 0,
                "total_rx_formatted": "0 B",
                "total_tx_formatted": "0 B",
                "interface_name": "wg0",
                "listen_port": 0,
                "peers": []
            }

    # 其他现有方法保持不变...
    async def create_server(self, server_data: WireGuardServerCreate) -> WireGuardServer:
        """创建WireGuard服务器"""
        # 实现创建服务器的逻辑
        pass

    async def get_server(self, server_id: str) -> Optional[WireGuardServer]:
        """获取服务器"""
        # 实现获取服务器的逻辑
        pass

    async def update_server(self, server_id: str, server_data: WireGuardServerUpdate) -> Optional[WireGuardServer]:
        """更新服务器"""
        # 实现更新服务器的逻辑
        pass

    async def delete_server(self, server_id: str) -> bool:
        """删除服务器"""
        # 实现删除服务器的逻辑
        pass

    async def create_client(self, client_data: WireGuardClientCreate) -> WireGuardClient:
        """创建客户端"""
        # 实现创建客户端的逻辑
        pass

    async def get_client(self, client_id: str) -> Optional[WireGuardClient]:
        """获取客户端"""
        # 实现获取客户端的逻辑
        pass

    async def update_client(self, client_id: str, client_data: WireGuardClientUpdate) -> Optional[WireGuardClient]:
        """更新客户端"""
        # 实现更新客户端的逻辑
        pass

    async def delete_client(self, client_id: str) -> bool:
        """删除客户端"""
        # 实现删除客户端的逻辑
        pass
