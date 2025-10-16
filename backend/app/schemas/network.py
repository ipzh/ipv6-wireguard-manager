from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, field_validator

# Network Interface Schemas
class NetworkInterfaceBase(BaseModel):
    name: str
    type: str  # 'physical', 'virtual', 'tunnel'
    ipv4_address: Optional[str] = None
    ipv6_address: Optional[str] = None
    mac_address: Optional[str] = None
    mtu: Optional[int] = None

    @field_validator('type')
    @classmethod
    def validate_type(cls, v):
        allowed_types = ['physical', 'virtual', 'tunnel']
        if v not in allowed_types:
            raise ValueError(f'接口类型必须是: {", ".join(allowed_types)}')
        return v

class NetworkInterfaceCreate(NetworkInterfaceBase):
    pass

class NetworkInterfaceUpdate(NetworkInterfaceBase):
    name: Optional[str] = None
    type: Optional[str] = None
    ipv4_address: Optional[str] = None
    ipv6_address: Optional[str] = None
    mac_address: Optional[str] = None
    mtu: Optional[int] = None

class NetworkInterface(NetworkInterfaceBase):
    id: int
    is_up: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# Firewall Rule Schemas
class FirewallRuleBase(BaseModel):
    name: str
    table_name: str  # 'filter', 'nat', 'mangle', 'raw'
    chain_name: str  # 'INPUT', 'FORWARD', 'OUTPUT', 'POSTROUTING', etc.
    rule_spec: str
    action: str  # 'ACCEPT', 'DROP', 'REJECT', 'MASQUERADE', etc.
    priority: int = 0

    @field_validator('table_name')
    @classmethod
    def validate_table(cls, v):
        allowed_tables = ['filter', 'nat', 'mangle', 'raw']
        if v not in allowed_tables:
            raise ValueError(f'表名必须是: {", ".join(allowed_tables)}')
        return v

    @field_validator('action')
    @classmethod
    def validate_action(cls, v):
        allowed_actions = ['ACCEPT', 'DROP', 'REJECT', 'MASQUERADE', 'SNAT', 'DNAT']
        if v not in allowed_actions:
            raise ValueError(f'动作必须是: {", ".join(allowed_actions)}')
        return v

class FirewallRuleCreate(FirewallRuleBase):
    pass

class FirewallRuleUpdate(FirewallRuleBase):
    name: Optional[str] = None
    table_name: Optional[str] = None
    chain_name: Optional[str] = None
    rule_spec: Optional[str] = None
    action: Optional[str] = None
    priority: Optional[int] = None

class FirewallRule(FirewallRuleBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# Network Status Schemas
class NetworkStatus(BaseModel):
    interfaces: List[NetworkInterface]
    firewall_rules: List[FirewallRule]
    routing_table: List[dict]

class InterfaceStats(BaseModel):
    interface: str
    rx_bytes: int
    tx_bytes: int
    rx_packets: int
    tx_packets: int
    rx_errors: int
    tx_errors: int