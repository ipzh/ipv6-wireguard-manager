from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, field_validator
from decimal import Decimal

# System Metric Schemas
class SystemMetricBase(BaseModel):
    metric_name: str
    metric_value: Decimal
    metric_unit: Optional[str] = None
    tags: Optional[Dict[str, Any]] = None

class SystemMetricCreate(SystemMetricBase):
    pass

class SystemMetric(SystemMetricBase):
    id: int
    timestamp: datetime

    class Config:
        from_attributes = True

# Audit Log Schemas
class AuditLogBase(BaseModel):
    user_id: Optional[int] = None
    action: str
    resource_type: Optional[str] = None
    resource_id: Optional[int] = None
    details: Optional[Dict[str, Any]] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None

class AuditLogCreate(AuditLogBase):
    pass

class AuditLog(AuditLogBase):
    id: int
    timestamp: datetime

    class Config:
        from_attributes = True

# Operation Log Schemas
class OperationLogBase(BaseModel):
    operation_type: str
    operation_data: Dict[str, Any]
    status: str  # 'success', 'failed', 'in_progress'
    error_message: Optional[str] = None
    execution_time: Optional[int] = None  # in milliseconds

    @field_validator('status')
    @classmethod
    def validate_status(cls, v):
        allowed_statuses = ['success', 'failed', 'in_progress']
        if v not in allowed_statuses:
            raise ValueError(f'状态必须是: {", ".join(allowed_statuses)}')
        return v

class OperationLogCreate(OperationLogBase):
    pass

class OperationLog(OperationLogBase):
    id: int
    timestamp: datetime

    class Config:
        from_attributes = True

# Monitoring Dashboard Schemas
class SystemStats(BaseModel):
    cpu_usage: float
    memory_usage: float
    disk_usage: float
    network_rx: int
    network_tx: int
    active_connections: int
    timestamp: datetime

class ServiceStatus(BaseModel):
    service_name: str
    status: str  # 'running', 'stopped', 'error'
    uptime: Optional[int] = None
    last_check: datetime

class AlertRule(BaseModel):
    id: int
    name: str
    metric_name: str
    threshold: float
    operator: str  # 'gt', 'lt', 'eq', 'gte', 'lte'
    severity: str  # 'info', 'warning', 'error', 'critical'
    is_enabled: bool
    created_at: datetime

class Alert(BaseModel):
    id: int
    rule_id: int
    message: str
    severity: str
    status: str  # 'active', 'resolved', 'acknowledged'
    created_at: datetime
    resolved_at: Optional[datetime] = None

# Log Query Schemas
class LogQuery(BaseModel):
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    level: Optional[str] = None
    service: Optional[str] = None
    message: Optional[str] = None
    limit: int = 100
    offset: int = 0

class LogResponse(BaseModel):
    logs: List[Dict[str, Any]]
    total: int
    has_more: bool