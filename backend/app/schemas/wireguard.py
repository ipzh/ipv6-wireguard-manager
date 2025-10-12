import uuid
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, field_validator
from ipaddress import IPv4Address, IPv6Address, IPv4Network, IPv6Network

# WireGuard Server Schemas
class WireGuardServerBase(BaseModel):
    name: str
    interface: str = "wg0"
    listen_port: int
    ipv4_address: Optional[str] = None
    ipv6_address: Optional[str] = None
    dns_servers: Optional[List[str]] = None
    mtu: int = 1420

    @field_validator('listen_port')
    @classmethod
    def validate_port(cls, v):
        if not 1 <= v <= 65535:
            raise ValueError('端口必须在1-65535之间')
        return v

    @field_validator('mtu')
    @classmethod
    def validate_mtu(cls, v):
        if not 68 <= v <= 65535:
            raise ValueError('MTU必须在68-65535之间')
        return v

class WireGuardServerCreate(WireGuardServerBase):
    pass

class WireGuardServerUpdate(WireGuardServerBase):
    name: Optional[str] = None
    interface: Optional[str] = None
    listen_port: Optional[int] = None
    ipv4_address: Optional[str] = None
    ipv6_address: Optional[str] = None
    dns_servers: Optional[List[str]] = None
    mtu: Optional[int] = None

class WireGuardServer(WireGuardServerBase):
    id: uuid.UUID
    private_key: str
    public_key: str
    config_file_path: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# WireGuard Client Schemas
class WireGuardClientBase(BaseModel):
    server_id: uuid.UUID
    name: str
    description: Optional[str] = None
    ipv4_address: Optional[str] = None
    ipv6_address: Optional[str] = None
    allowed_ips: Optional[List[str]] = None
    persistent_keepalive: int = 25

    @field_validator('persistent_keepalive')
    @classmethod
    def validate_keepalive(cls, v):
        if not 0 <= v <= 65535:
            raise ValueError('Keepalive必须在0-65535之间')
        return v

class WireGuardClientCreate(WireGuardClientBase):
    pass

class WireGuardClientUpdate(WireGuardClientBase):
    server_id: Optional[uuid.UUID] = None
    name: Optional[str] = None
    description: Optional[str] = None
    ipv4_address: Optional[str] = None
    ipv6_address: Optional[str] = None
    allowed_ips: Optional[List[str]] = None
    persistent_keepalive: Optional[int] = None

class WireGuardClient(WireGuardClientBase):
    id: uuid.UUID
    private_key: str
    public_key: str
    qr_code: Optional[str] = None
    config_file_path: Optional[str] = None
    is_active: bool
    last_seen: Optional[datetime] = None
    bytes_received: int = 0
    bytes_sent: int = 0
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# WireGuard Status Schemas
class WireGuardInterfaceStatus(BaseModel):
    interface: str
    public_key: str
    private_key: str
    listening_port: int
    peers: int

class WireGuardPeerStatus(BaseModel):
    public_key: str
    preshared_key: str
    endpoint: Optional[str] = None
    allowed_ips: List[str]
    latest_handshake: Optional[datetime] = None
    transfer_rx: int = 0
    transfer_tx: int = 0
    persistent_keepalive: int = 0

class WireGuardStatus(BaseModel):
    interface: WireGuardInterfaceStatus
    peers: List[WireGuardPeerStatus]

# Configuration Schemas
class WireGuardConfig(BaseModel):
    server_config: str
    client_configs: List[dict]

class QRCodeResponse(BaseModel):
    qr_code: str
    config: str