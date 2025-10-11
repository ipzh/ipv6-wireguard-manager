export interface SystemMetric {
  id: string;
  metric_name: string;
  metric_value: number;
  metric_unit?: string;
  tags?: Record<string, any>;
  timestamp: string;
}

export interface SystemMetricCreate {
  metric_name: string;
  metric_value: number;
  metric_unit?: string;
  tags?: Record<string, any>;
}

export interface AuditLog {
  id: string;
  user_id?: string;
  action: string;
  resource_type?: string;
  resource_id?: string;
  details?: Record<string, any>;
  ip_address?: string;
  user_agent?: string;
  timestamp: string;
}

export interface AuditLogCreate {
  user_id?: string;
  action: string;
  resource_type?: string;
  resource_id?: string;
  details?: Record<string, any>;
  ip_address?: string;
  user_agent?: string;
}

export interface OperationLog {
  id: string;
  operation_type: string;
  operation_data: Record<string, any>;
  status: string;
  error_message?: string;
  execution_time?: number;
  timestamp: string;
}

export interface OperationLogCreate {
  operation_type: string;
  operation_data: Record<string, any>;
  status: string;
  error_message?: string;
  execution_time?: number;
}

export interface SystemStats {
  cpu_usage: number;
  memory_usage: number;
  disk_usage: number;
  network_rx: number;
  network_tx: number;
  active_connections: number;
  timestamp: string;
}

export interface ServiceStatus {
  service_name: string;
  status: string;
  uptime?: number;
  last_check: string;
}

export interface AlertRule {
  id: string;
  name: string;
  metric_name: string;
  threshold: number;
  operator: string;
  severity: string;
  is_enabled: boolean;
  created_at: string;
}

export interface Alert {
  id: string;
  rule_id: string;
  message: string;
  severity: string;
  status: string;
  created_at: string;
  resolved_at?: string;
}

export interface LogQuery {
  start_time?: string;
  end_time?: string;
  level?: string;
  service?: string;
  message?: string;
  limit: number;
  offset: number;
}

export interface LogResponse {
  logs: Record<string, any>[];
  total: number;
  has_more: boolean;
}
