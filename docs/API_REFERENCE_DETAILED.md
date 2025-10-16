# IPv6 WireGuard Manager - 详细API参考文档

## 📋 目录

- [概述](#概述)
- [认证和授权](#认证和授权)
- [API端点详细说明](#api端点详细说明)
- [数据模型](#数据模型)
- [错误处理](#错误处理)
- [速率限制](#速率限制)
- [WebSocket API](#websocket-api)
- [SDK和示例](#sdk和示例)

## 概述

IPv6 WireGuard Manager 提供完整的RESTful API，支持IPv4/IPv6双栈网络管理、WireGuard VPN管理、BGP路由管理等功能。

### 基础信息

- **API版本**: v1
- **基础URL**: `https://your-domain.com/api/v1`
- **协议**: HTTPS (生产环境)
- **数据格式**: JSON
- **字符编码**: UTF-8
- **认证方式**: JWT Bearer Token / API Key

### 版本信息

```http
GET /api/v1/version
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "version": "3.0.0",
    "build_date": "2024-01-01T00:00:00Z",
    "api_version": "v1",
    "features": [
      "wireguard_management",
      "bgp_routing",
      "ipv6_management",
      "monitoring",
      "backup_restore",
      "cluster_management"
    ]
  }
}
```

## 认证和授权

### JWT认证

#### 登录获取令牌

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "password123",
  "remember_me": false
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "token_type": "bearer",
    "expires_in": 3600,
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "user": {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com",
      "role": "admin",
      "permissions": ["*"],
      "two_factor_enabled": true,
      "last_login": "2024-01-01T00:00:00Z"
    }
  }
}
```

#### 刷新令牌

```http
POST /api/v1/auth/refresh
Authorization: Bearer <refresh_token>
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "token_type": "bearer",
    "expires_in": 3600
  }
}
```

#### 双因子认证

```http
POST /api/v1/auth/verify-2fa
Content-Type: application/json
Authorization: Bearer <access_token>

{
  "code": "123456",
  "method": "totp"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "verified": true,
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "expires_in": 3600
  }
}
```

### API密钥认证

#### 创建API密钥

```http
POST /api/v1/auth/api-keys
Content-Type: application/json
Authorization: Bearer <access_token>

{
  "name": "My API Key",
  "access_level": "read",
  "permissions": ["wireguard.view", "bgp.view"],
  "allowed_ips": ["192.168.1.0/24"],
  "allowed_endpoints": ["/api/v1/wireguard/*", "/api/v1/bgp/*"],
  "rate_limit": {
    "requests_per_minute": 1000,
    "burst_limit": 2000
  },
  "expires_at": "2024-12-31T23:59:59Z",
  "description": "用于监控系统的API密钥"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "id": "ak_1234567890",
    "name": "My API Key",
    "api_key": "ak_1234567890_abcdefghijklmnopqrstuvwxyz123456",
    "access_level": "read",
    "permissions": ["wireguard.view", "bgp.view"],
    "allowed_ips": ["192.168.1.0/24"],
    "allowed_endpoints": ["/api/v1/wireguard/*", "/api/v1/bgp/*"],
    "rate_limit": {
      "requests_per_minute": 1000,
      "burst_limit": 2000
    },
    "expires_at": "2024-12-31T23:59:59Z",
    "status": "active",
    "created_at": "2024-01-01T00:00:00Z",
    "last_used": null
  }
}
```

#### 使用API密钥

```http
GET /api/v1/wireguard/servers
X-API-Key: ak_1234567890_abcdefghijklmnopqrstuvwxyz123456
```

或者

```http
GET /api/v1/wireguard/servers
Authorization: Bearer ak_1234567890_abcdefghijklmnopqrstuvwxyz123456
```

## API端点详细说明

### 用户管理

#### 获取用户列表

```http
GET /api/v1/users?page=1&size=20&search=admin&role=admin&status=active
Authorization: Bearer <access_token>
```

**查询参数**:
- `page` (integer, optional): 页码，默认1
- `size` (integer, optional): 每页数量，默认20，最大100
- `search` (string, optional): 搜索关键词（用户名、邮箱）
- `role` (string, optional): 角色筛选 (admin, manager, user)
- `status` (string, optional): 状态筛选 (active, inactive, suspended)
- `sort` (string, optional): 排序字段 (username, email, created_at, last_login)
- `order` (string, optional): 排序方向 (asc, desc)

**响应示例**:
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": 1,
        "username": "admin",
        "email": "admin@example.com",
        "full_name": "Administrator",
        "role": "admin",
        "status": "active",
        "two_factor_enabled": true,
        "last_login": "2024-01-01T14:30:00Z",
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T14:30:00Z",
        "permissions": ["*"],
        "login_attempts": 0,
        "locked_until": null
      }
    ],
    "pagination": {
      "page": 1,
      "size": 20,
      "total": 1,
      "pages": 1,
      "has_next": false,
      "has_prev": false
    }
  }
}
```

#### 创建用户

```http
POST /api/v1/users
Content-Type: application/json
Authorization: Bearer <access_token>

{
  "username": "newuser",
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "full_name": "New User",
  "role": "user",
  "status": "active",
  "permissions": ["wireguard.view", "wireguard.edit"],
  "two_factor_enabled": false,
  "send_welcome_email": true
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "id": 2,
    "username": "newuser",
    "email": "user@example.com",
    "full_name": "New User",
    "role": "user",
    "status": "active",
    "two_factor_enabled": false,
    "created_at": "2024-01-01T15:00:00Z",
    "permissions": ["wireguard.view", "wireguard.edit"]
  },
  "message": "用户创建成功"
}
```

#### 更新用户

```http
PUT /api/v1/users/{user_id}
Content-Type: application/json
Authorization: Bearer <access_token>

{
  "email": "updated@example.com",
  "full_name": "Updated User",
  "role": "manager",
  "status": "active",
  "permissions": ["wireguard.view", "wireguard.edit", "bgp.view"]
}
```

#### 删除用户

```http
DELETE /api/v1/users/{user_id}
Authorization: Bearer <access_token>
```

#### 重置用户密码

```http
POST /api/v1/users/{user_id}/reset-password
Content-Type: application/json
Authorization: Bearer <access_token>

{
  "new_password": "NewSecurePassword123!",
  "force_change": true,
  "send_email": true
}
```

### WireGuard管理

#### 获取服务器列表

```http
GET /api/v1/wireguard/servers?page=1&size=20&status=running&search=wg
Authorization: Bearer <access_token>
```

**查询参数**:
- `page` (integer, optional): 页码
- `size` (integer, optional): 每页数量
- `status` (string, optional): 状态筛选 (running, stopped, error)
- `search` (string, optional): 搜索关键词
- `sort` (string, optional): 排序字段
- `order` (string, optional): 排序方向

**响应示例**:
```json
{
  "success": true,
  "data": {
    "servers": [
      {
        "id": 1,
        "name": "wg0",
        "interface": "wg0",
        "listen_port": 51820,
        "ipv4_address": "10.0.0.1/24",
        "ipv6_address": "2001:db8::1/64",
        "public_key": "public_key_here",
        "private_key": "private_key_here",
        "status": "running",
        "clients_count": 5,
        "bytes_received": 1073741824,
        "bytes_sent": 2147483648,
        "last_handshake": "2024-01-01T14:30:00Z",
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T14:30:00Z",
        "config": {
          "dns_servers": ["8.8.8.8", "2001:4860:4860::8888"],
          "mtu": 1420,
          "persistent_keepalive": 25,
          "allowed_ips": ["0.0.0.0/0", "::/0"]
        }
      }
    ],
    "pagination": {
      "page": 1,
      "size": 20,
      "total": 1,
      "pages": 1
    }
  }
}
```

#### 创建服务器

```http
POST /api/v1/wireguard/servers
Content-Type: application/json
Authorization: Bearer <access_token>

{
  "name": "wg1",
  "interface": "wg1",
  "listen_port": 51821,
  "ipv4_address": "10.0.1.1/24",
  "ipv6_address": "2001:db8:1::1/64",
  "dns_servers": ["8.8.8.8", "8.8.4.4"],
  "mtu": 1420,
  "persistent_keepalive": 25,
  "allowed_ips": ["0.0.0.0/0", "::/0"],
  "auto_start": true,
  "description": "新的WireGuard服务器"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "id": 2,
    "name": "wg1",
    "interface": "wg1",
    "listen_port": 51821,
    "ipv4_address": "10.0.1.1/24",
    "ipv6_address": "2001:db8:1::1/64",
    "public_key": "generated_public_key",
    "private_key": "generated_private_key",
    "status": "stopped",
    "created_at": "2024-01-01T15:00:00Z",
    "config_file": "[Interface]\nPrivateKey = generated_private_key\nAddress = 10.0.1.1/24, 2001:db8:1::1/64\nListenPort = 51821\nMTU = 1420\nDNS = 8.8.8.8, 8.8.4.4\n\n[Peer]\n# 客户端配置将在这里添加"
  },
  "message": "服务器创建成功"
}
```

#### 启动服务器

```http
POST /api/v1/wireguard/servers/{server_id}/start
Authorization: Bearer <access_token>
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "status": "running",
    "started_at": "2024-01-01T15:00:00Z",
    "pid": 12345
  },
  "message": "服务器启动成功"
}
```

#### 停止服务器

```http
POST /api/v1/wireguard/servers/{server_id}/stop
Authorization: Bearer <access_token>
```

#### 获取服务器状态

```http
GET /api/v1/wireguard/servers/{server_id}/status
Authorization: Bearer <access_token>
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "wg0",
    "status": "running",
    "uptime": 86400,
    "clients": [
      {
        "public_key": "client_public_key",
        "allowed_ips": "10.0.0.2/32",
        "latest_handshake": "2024-01-01T14:30:00Z",
        "transfer_rx": 1073741824,
        "transfer_tx": 2147483648
      }
    ],
    "interface_stats": {
      "rx_bytes": 1073741824,
      "tx_bytes": 2147483648,
      "rx_packets": 1000000,
      "tx_packets": 2000000
    }
  }
}
```

#### 获取客户端列表

```http
GET /api/v1/wireguard/clients?server_id=1&page=1&size=20&status=active
Authorization: Bearer <access_token>
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "clients": [
      {
        "id": 1,
        "name": "client1",
        "server_id": 1,
        "ipv4_address": "10.0.0.2/32",
        "ipv6_address": "2001:db8::2/128",
        "public_key": "client_public_key",
        "private_key": "client_private_key",
        "status": "active",
        "last_handshake": "2024-01-01T14:30:00Z",
        "bytes_received": 1073741824,
        "bytes_sent": 2147483648,
        "allowed_ips": ["0.0.0.0/0", "::/0"],
        "dns_servers": ["8.8.8.8"],
        "persistent_keepalive": 25,
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T14:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "size": 20,
      "total": 1,
      "pages": 1
    }
  }
}
```

#### 创建客户端

```http
POST /api/v1/wireguard/clients
Content-Type: application/json
Authorization: Bearer <access_token>

{
  "name": "client2",
  "server_id": 1,
  "ipv4_address": "10.0.0.3/32",
  "ipv6_address": "2001:db8::3/128",
  "allowed_ips": ["0.0.0.0/0", "::/0"],
  "dns_servers": ["8.8.8.8", "8.8.4.4"],
  "persistent_keepalive": 25,
  "auto_assign_ip": true,
  "description": "新的客户端"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "id": 2,
    "name": "client2",
    "server_id": 1,
    "ipv4_address": "10.0.0.3/32",
    "ipv6_address": "2001:db8::3/128",
    "public_key": "generated_client_public_key",
    "private_key": "generated_client_private_key",
    "status": "active",
    "created_at": "2024-01-01T15:00:00Z",
    "config": "[Interface]\nPrivateKey = generated_client_private_key\nAddress = 10.0.0.3/32, 2001:db8::3/128\nDNS = 8.8.8.8, 8.8.4.4\n\n[Peer]\nPublicKey = server_public_key\nEndpoint = your-server.com:51820\nAllowedIPs = 0.0.0.0/0, ::/0\nPersistentKeepalive = 25",
    "qr_code": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA..."
  },
  "message": "客户端创建成功"
}
```

### BGP管理

#### 获取BGP会话列表

```http
GET /api/v1/bgp/sessions?page=1&size=20&status=established&neighbor=192.168.1.1
Authorization: Bearer <access_token>
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "sessions": [
      {
        "id": 1,
        "name": "session1",
        "neighbor": "192.168.1.1",
        "remote_as": 65001,
        "local_as": 65000,
        "status": "established",
        "uptime": 86400,
        "routes_received": 150,
        "routes_advertised": 25,
        "last_update": "2024-01-01T14:30:00Z",
        "last_error": null,
        "config": {
          "password": "***REDACTED***",
          "hold_time": 90,
          "keepalive": 30,
          "connect_retry": 120,
          "multihop": false,
          "ttl_security": false
        },
        "statistics": {
          "messages_received": 1000,
          "messages_sent": 1000,
          "updates_received": 150,
          "updates_sent": 25,
          "notifications_received": 0,
          "notifications_sent": 0
        },
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T14:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "size": 20,
      "total": 1,
      "pages": 1
    }
  }
}
```

#### 创建BGP会话

```http
POST /api/v1/bgp/sessions
Content-Type: application/json
Authorization: Bearer <access_token>

{
  "name": "session2",
  "neighbor": "192.168.1.2",
  "remote_as": 65002,
  "local_as": 65000,
  "password": "bgp_password",
  "hold_time": 90,
  "keepalive": 30,
  "connect_retry": 120,
  "multihop": false,
  "ttl_security": false,
  "enabled": true,
  "description": "新的BGP会话"
}
```

#### 启动BGP会话

```http
POST /api/v1/bgp/sessions/{session_id}/start
Authorization: Bearer <access_token>
```

#### 获取BGP路由表

```http
GET /api/v1/bgp/routes?session_id=1&prefix=192.168.0.0/16&page=1&size=20
Authorization: Bearer <access_token>
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "routes": [
      {
        "prefix": "192.168.1.0/24",
        "next_hop": "192.168.1.1",
        "as_path": "65001 65002",
        "origin": "igp",
        "local_pref": 100,
        "med": 0,
        "community": ["65001:100", "65001:200"],
        "session_id": 1,
        "last_update": "2024-01-01T14:30:00Z",
        "status": "active"
      }
    ],
    "pagination": {
      "page": 1,
      "size": 20,
      "total": 1,
      "pages": 1
    }
  }
}
```

### IPv6管理

#### 获取IPv6前缀池列表

```http
GET /api/v1/ipv6/pools?page=1&size=20&status=active&search=pool
Authorization: Bearer <access_token>
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "pools": [
      {
        "id": 1,
        "name": "pool1",
        "prefix": "2001:db8::/48",
        "prefix_length": 64,
        "total_prefixes": 65536,
        "allocated_prefixes": 100,
        "available_prefixes": 65436,
        "status": "active",
        "description": "主要IPv6前缀池",
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T14:30:00Z",
        "allocations": [
          {
            "id": 1,
            "client_name": "client1",
            "allocated_prefix": "2001:db8::/64",
            "status": "active",
            "allocated_at": "2024-01-01T10:00:00Z"
          }
        ]
      }
    ],
    "pagination": {
      "page": 1,
      "size": 20,
      "total": 1,
      "pages": 1
    }
  }
}
```

#### 创建IPv6前缀池

```http
POST /api/v1/ipv6/pools
Content-Type: application/json
Authorization: Bearer <access_token>

{
  "name": "pool2",
  "prefix": "2001:db8:1::/48",
  "prefix_length": 64,
  "description": "备用IPv6前缀池",
  "auto_assign": true,
  "reserved_prefixes": 100
}
```

#### 分配IPv6前缀

```http
POST /api/v1/ipv6/allocations
Content-Type: application/json
Authorization: Bearer <access_token>

{
  "pool_id": 1,
  "client_name": "client2",
  "description": "客户端2的IPv6前缀",
  "auto_assign": true,
  "custom_prefix": null
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "id": 2,
    "pool_id": 1,
    "client_name": "client2",
    "allocated_prefix": "2001:db8:1::/64",
    "status": "active",
    "allocated_at": "2024-01-01T15:00:00Z",
    "expires_at": null,
    "description": "客户端2的IPv6前缀"
  },
  "message": "IPv6前缀分配成功"
}
```

### 监控管理

#### 获取监控仪表板数据

```http
GET /api/v1/monitoring/dashboard?time_range=1h&refresh=true
Authorization: Bearer <access_token>
```

**查询参数**:
- `time_range` (string, optional): 时间范围 (1h, 6h, 24h, 7d, 30d)
- `refresh` (boolean, optional): 强制刷新数据

**响应示例**:
```json
{
  "success": true,
  "data": {
    "system_metrics": {
      "cpu": {
        "usage": 45.2,
        "cores": 4,
        "load_average": [1.2, 1.5, 1.8],
        "temperature": 65.5
      },
      "memory": {
        "total": 8589934592,
        "used": 4294967296,
        "free": 4294967296,
        "usage_percent": 50.0,
        "cached": 1073741824,
        "buffers": 536870912
      },
      "disk": {
        "total": 107374182400,
        "used": 53687091200,
        "free": 53687091200,
        "usage_percent": 50.0,
        "read_iops": 100,
        "write_iops": 50
      },
      "network": {
        "interfaces": [
          {
            "name": "eth0",
            "bytes_sent": 1073741824,
            "bytes_recv": 2147483648,
            "packets_sent": 1000000,
            "packets_recv": 2000000,
            "errors": 0,
            "drops": 0
          }
        ]
      }
    },
    "application_metrics": {
      "database": {
        "pool_size": 10,
        "checked_out": 2,
        "active_connections": 8,
        "query_time_avg": 5.2,
        "slow_queries": 0
      },
      "cache": {
        "hit_rate": 85.5,
        "miss_rate": 14.5,
        "memory_usage": 1048576,
        "keys_count": 1000
      },
      "api": {
        "requests_per_minute": 100,
        "response_time_avg": 150,
        "error_rate": 0.1,
        "active_connections": 25
      }
    },
    "service_metrics": {
      "wireguard": {
        "servers_count": 2,
        "clients_count": 15,
        "total_traffic": 3221225472,
        "active_connections": 12
      },
      "bgp": {
        "sessions_count": 3,
        "established_sessions": 2,
        "routes_received": 150,
        "routes_advertised": 25
      }
    },
    "alerts": {
      "active": 2,
      "critical": 0,
      "warning": 2,
      "info": 0,
      "recent": [
        {
          "id": "alert_1",
          "name": "CPU使用率过高",
          "level": "warning",
          "status": "active",
          "current_value": 85.2,
          "threshold": 80.0,
          "created_at": "2024-01-01T14:30:00Z"
        }
      ]
    }
  }
}
```

#### 获取系统指标历史数据

```http
GET /api/v1/monitoring/metrics/system?metric=cpu.usage&start_time=2024-01-01T00:00:00Z&end_time=2024-01-01T23:59:59Z&interval=5m
Authorization: Bearer <access_token>
```

**查询参数**:
- `metric` (string, required): 指标名称 (cpu.usage, memory.usage, disk.usage, network.bytes_sent)
- `start_time` (string, required): 开始时间 (ISO 8601)
- `end_time` (string, required): 结束时间 (ISO 8601)
- `interval` (string, optional): 数据间隔 (1m, 5m, 15m, 1h)

**响应示例**:
```json
{
  "success": true,
  "data": {
    "metric": "cpu.usage",
    "unit": "percent",
    "data_points": [
      {
        "timestamp": "2024-01-01T00:00:00Z",
        "value": 45.2,
        "tags": {"host": "server1"}
      },
      {
        "timestamp": "2024-01-01T00:05:00Z",
        "value": 47.8,
        "tags": {"host": "server1"}
      }
    ],
    "statistics": {
      "min": 35.2,
      "max": 85.2,
      "avg": 52.1,
      "count": 288
    }
  }
}
```

#### 创建告警规则

```http
POST /api/v1/monitoring/alerts/rules
Content-Type: application/json
Authorization: Bearer <access_token>

{
  "name": "内存使用率过高",
  "description": "当内存使用率超过85%时触发告警",
  "metric_name": "system.memory.usage",
  "condition": ">",
  "threshold": 85.0,
  "level": "error",
  "duration": 300,
  "enabled": true,
  "cooldown_minutes": 5,
  "notification_channels": ["email", "webhook"],
  "tags": {
    "environment": "production",
    "service": "system"
  }
}
```

### 日志管理

#### 获取日志列表

```http
GET /api/v1/logs?page=1&size=20&level=ERROR&start_time=2024-01-01T00:00:00Z&end_time=2024-01-01T23:59:59Z&search=error
Authorization: Bearer <access_token>
```

**查询参数**:
- `page` (integer, optional): 页码
- `size` (integer, optional): 每页数量
- `level` (string, optional): 日志级别 (DEBUG, INFO, WARN, ERROR, CRITICAL)
- `start_time` (string, optional): 开始时间
- `end_time` (string, optional): 结束时间
- `search` (string, optional): 搜索关键词
- `module` (string, optional): 模块名称
- `user_id` (string, optional): 用户ID

**响应示例**:
```json
{
  "success": true,
  "data": {
    "logs": [
      {
        "id": 1,
        "level": "ERROR",
        "message": "数据库连接失败",
        "module": "database",
        "user_id": 1,
        "ip_address": "192.168.1.100",
        "timestamp": "2024-01-01T14:30:00Z",
        "details": {
          "error": "Connection timeout",
          "host": "localhost",
          "port": 3306,
          "database": "ipv6wgm"
        },
        "stack_trace": "Traceback (most recent call last)...",
        "tags": ["database", "connection", "error"]
      }
    ],
    "pagination": {
      "page": 1,
      "size": 20,
      "total": 100,
      "pages": 5
    }
  }
}
```

#### 导出日志

```http
GET /api/v1/logs/export?format=json&start_time=2024-01-01T00:00:00Z&end_time=2024-01-01T23:59:59Z&level=ERROR
Authorization: Bearer <access_token>
```

**查询参数**:
- `format` (string, required): 导出格式 (json, csv, txt)
- `start_time` (string, required): 开始时间
- `end_time` (string, required): 结束时间
- `level` (string, optional): 日志级别
- `module` (string, optional): 模块名称

**响应示例**:
```json
{
  "success": true,
  "data": {
    "download_url": "/api/v1/logs/export/download/export_20240101_000000.json",
    "file_size": 1048576,
    "expires_at": "2024-01-01T16:00:00Z",
    "format": "json"
  }
}
```

### 系统管理

#### 获取系统信息

```http
GET /api/v1/system/info
Authorization: Bearer <access_token>
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "system": {
      "hostname": "server1",
      "os": "Ubuntu 22.04 LTS",
      "kernel": "5.15.0-91-generic",
      "architecture": "x86_64",
      "uptime": 86400,
      "load_average": [1.2, 1.5, 1.8],
      "timezone": "Asia/Shanghai",
      "locale": "zh_CN.UTF-8"
    },
    "application": {
      "name": "IPv6 WireGuard Manager",
      "version": "3.0.0",
      "build_date": "2024-01-01T00:00:00Z",
      "python_version": "3.11.2",
      "environment": "production",
      "debug_mode": false
    },
    "database": {
      "type": "MySQL",
      "version": "8.0.35",
      "status": "connected",
      "pool_size": 10,
      "active_connections": 3,
      "max_connections": 200
    },
    "services": {
      "wireguard": {
        "status": "running",
        "version": "1.0.20210914",
        "pid": 12345
      },
      "bgp": {
        "status": "running",
        "version": "4.2.16",
        "pid": 12346
      },
      "nginx": {
        "status": "running",
        "version": "1.18.0",
        "pid": 12347
      }
    }
  }
}
```

#### 获取系统配置

```http
GET /api/v1/system/config
Authorization: Bearer <access_token>
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "app_name": "IPv6 WireGuard Manager",
    "app_version": "3.0.0",
    "debug_mode": false,
    "log_level": "INFO",
    "max_log_size": 100,
    "backup_retention": 30,
    "session_timeout": 3600,
    "api_rate_limit": 1000,
    "database_pool_size": 10,
    "cache_enabled": true,
    "monitoring_enabled": true,
    "two_factor_enabled": true,
    "password_policy": {
      "min_length": 12,
      "require_uppercase": true,
      "require_lowercase": true,
      "require_digits": true,
      "require_special": true,
      "max_age_days": 90
    },
    "security": {
      "enable_rate_limiting": true,
      "enable_ip_whitelist": false,
      "enable_audit_logging": true,
      "max_login_attempts": 5,
      "lockout_duration": 900
    }
  }
}
```

#### 更新系统配置

```http
PUT /api/v1/system/config
Content-Type: application/json
Authorization: Bearer <access_token>

{
  "log_level": "DEBUG",
  "max_log_size": 200,
  "backup_retention": 60,
  "session_timeout": 7200,
  "api_rate_limit": 2000,
  "password_policy": {
    "min_length": 14,
    "require_uppercase": true,
    "require_lowercase": true,
    "require_digits": true,
    "require_special": true,
    "max_age_days": 60
  }
}
```

### 备份管理

#### 获取备份列表

```http
GET /api/v1/backup/backups?page=1&size=20&type=full&status=completed
Authorization: Bearer <access_token>
```

**响应示例**:
```json
{
  "success": true,
  "data": [
    {
      "id": "backup_20240101_000000",
      "name": "Daily Backup",
      "type": "full",
      "status": "completed",
      "created_at": "2024-01-01T00:00:00Z",
      "completed_at": "2024-01-01T00:05:00Z",
      "size_bytes": 104857600,
      "file_path": "/backups/backup_20240101_000000_full.tar.gz",
      "checksum": "md5_hash_here",
      "compression": "gzip",
      "encryption": false,
      "metadata": {
        "database_size": 52428800,
        "files_size": 52428800,
        "config_size": 1024
      }
    }
  ],
  "pagination": {
    "page": 1,
    "size": 20,
    "total": 10,
    "pages": 1
  }
}
```

#### 创建备份

```http
POST /api/v1/backup/backups/create
Content-Type: application/json
Authorization: Bearer <access_token>

{
  "name": "Manual Backup",
  "backup_type": "full",
  "description": "手动创建的完整备份",
  "compression": true,
  "encryption": false,
  "include_logs": true,
  "include_config": true,
  "include_database": true
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "backup_id": "backup_20240101_150000",
    "name": "Manual Backup",
    "type": "full",
    "status": "running",
    "created_at": "2024-01-01T15:00:00Z",
    "estimated_duration": 300,
    "progress": 0
  },
  "message": "备份创建已开始"
}
```

#### 恢复备份

```http
POST /api/v1/backup/backups/{backup_id}/restore
Content-Type: application/json
Authorization: Bearer <access_token>

{
  "target_dir": "/tmp/restore",
  "include_database": true,
  "include_config": true,
  "include_logs": false,
  "force": false
}
```

### 集群管理

#### 获取集群状态

```http
GET /api/v1/cluster/status
Authorization: Bearer <access_token>
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "current_node_id": "node1",
    "is_leader": true,
    "total_nodes": 3,
    "healthy_nodes": 3,
    "nodes": [
      {
        "id": "node1",
        "host": "192.168.1.10",
        "port": 8000,
        "status": "healthy",
        "last_heartbeat": "2024-01-01T14:30:00Z",
        "load_factor": 0.2,
        "capabilities": ["api", "database", "cache"],
        "metadata": {
          "version": "3.0.0",
          "environment": "production",
          "region": "us-west-1"
        }
      }
    ],
    "services": {
      "ipv6-wireguard-manager": {
        "nodes": ["node1", "node2", "node3"],
        "metadata": {},
        "last_updated": "2024-01-01T14:30:00Z"
      }
    },
    "load_balancer": {
      "strategy": "round_robin",
      "node_weights": {}
    }
  }
}
```

## 数据模型

### 用户模型

```json
{
  "id": "integer",
  "username": "string",
  "email": "string",
  "full_name": "string",
  "role": "enum[admin, manager, user]",
  "status": "enum[active, inactive, suspended]",
  "two_factor_enabled": "boolean",
  "last_login": "datetime",
  "created_at": "datetime",
  "updated_at": "datetime",
  "permissions": "array[string]",
  "login_attempts": "integer",
  "locked_until": "datetime|null"
}
```

### WireGuard服务器模型

```json
{
  "id": "integer",
  "name": "string",
  "interface": "string",
  "listen_port": "integer",
  "ipv4_address": "string",
  "ipv6_address": "string",
  "public_key": "string",
  "private_key": "string",
  "status": "enum[running, stopped, error]",
  "clients_count": "integer",
  "bytes_received": "integer",
  "bytes_sent": "integer",
  "last_handshake": "datetime",
  "created_at": "datetime",
  "updated_at": "datetime",
  "config": {
    "dns_servers": "array[string]",
    "mtu": "integer",
    "persistent_keepalive": "integer",
    "allowed_ips": "array[string]"
  }
}
```

### BGP会话模型

```json
{
  "id": "integer",
  "name": "string",
  "neighbor": "string",
  "remote_as": "integer",
  "local_as": "integer",
  "status": "enum[established, idle, active, connect, opensent, openconfirm]",
  "uptime": "integer",
  "routes_received": "integer",
  "routes_advertised": "integer",
  "last_update": "datetime",
  "last_error": "string|null",
  "config": {
    "password": "string",
    "hold_time": "integer",
    "keepalive": "integer",
    "connect_retry": "integer",
    "multihop": "boolean",
    "ttl_security": "boolean"
  },
  "statistics": {
    "messages_received": "integer",
    "messages_sent": "integer",
    "updates_received": "integer",
    "updates_sent": "integer",
    "notifications_received": "integer",
    "notifications_sent": "integer"
  }
}
```

## 错误处理

### 错误响应格式

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述",
    "details": {
      "field": "具体字段错误信息"
    },
    "request_id": "req_1234567890",
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

### HTTP状态码

| 状态码 | 说明 | 示例 |
|--------|------|------|
| 200 | 请求成功 | 获取数据成功 |
| 201 | 创建成功 | 创建资源成功 |
| 400 | 请求参数错误 | 缺少必需参数 |
| 401 | 未授权 | 令牌无效或过期 |
| 403 | 禁止访问 | 权限不足 |
| 404 | 资源不存在 | 用户不存在 |
| 409 | 资源冲突 | 用户名已存在 |
| 422 | 数据验证失败 | 密码不符合要求 |
| 429 | 请求频率限制 | 超出速率限制 |
| 500 | 服务器内部错误 | 数据库连接失败 |
| 503 | 服务不可用 | 维护模式 |

### 错误代码

| 错误代码 | HTTP状态码 | 说明 |
|----------|------------|------|
| INVALID_CREDENTIALS | 401 | 无效的认证凭据 |
| TOKEN_EXPIRED | 401 | 令牌已过期 |
| TOKEN_INVALID | 401 | 令牌无效 |
| INSUFFICIENT_PERMISSIONS | 403 | 权限不足 |
| RESOURCE_NOT_FOUND | 404 | 资源不存在 |
| RESOURCE_ALREADY_EXISTS | 409 | 资源已存在 |
| VALIDATION_ERROR | 422 | 数据验证失败 |
| RATE_LIMIT_EXCEEDED | 429 | 请求频率超限 |
| INTERNAL_ERROR | 500 | 内部服务器错误 |
| SERVICE_UNAVAILABLE | 503 | 服务不可用 |
| MAINTENANCE_MODE | 503 | 维护模式 |

## 速率限制

### 默认限制

- **认证用户**: 1000 请求/分钟
- **API密钥**: 根据配置
- **未认证用户**: 100 请求/分钟

### 限制头信息

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
X-RateLimit-Retry-After: 60
```

### 超出限制响应

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "请求频率超出限制",
    "details": {
      "limit": 1000,
      "remaining": 0,
      "reset_time": "2024-01-01T01:00:00Z",
      "retry_after": 60
    }
  }
}
```

## WebSocket API

### 连接WebSocket

```javascript
const ws = new WebSocket('wss://your-domain.com/ws/connect?token=your_jwt_token');
```

### 消息格式

```json
{
  "type": "message_type",
  "data": {},
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### 消息类型

#### 系统状态更新

```json
{
  "type": "system_status",
  "data": {
    "cpu_usage": 45.2,
    "memory_usage": 50.0,
    "disk_usage": 60.0,
    "network_traffic": {
      "bytes_sent": 1024000,
      "bytes_recv": 2048000
    }
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

#### WireGuard状态更新

```json
{
  "type": "wireguard_status",
  "data": {
    "servers": [
      {
        "id": 1,
        "name": "wg0",
        "status": "running",
        "clients_count": 5,
        "bytes_received": 1024000,
        "bytes_sent": 2048000
      }
    ]
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

#### 告警通知

```json
{
  "type": "alert",
  "data": {
    "id": "alert_1",
    "name": "CPU使用率过高",
    "level": "warning",
    "status": "active",
    "current_value": 85.2,
    "threshold": 80.0,
    "message": "CPU使用率超过80%"
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## SDK和示例

### Python SDK示例

```python
import requests
import json

class IPv6WireGuardManager:
    def __init__(self, base_url, api_key=None, username=None, password=None):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
        
        if api_key:
            self.session.headers.update({'X-API-Key': api_key})
        elif username and password:
            self._authenticate(username, password)
    
    def _authenticate(self, username, password):
        response = self.session.post(
            f"{self.base_url}/api/v1/auth/login",
            json={"username": username, "password": password}
        )
        response.raise_for_status()
        data = response.json()
        self.session.headers.update({
            'Authorization': f"Bearer {data['data']['access_token']}"
        })
    
    def get_servers(self, page=1, size=20):
        response = self.session.get(
            f"{self.base_url}/api/v1/wireguard/servers",
            params={"page": page, "size": size}
        )
        response.raise_for_status()
        return response.json()
    
    def create_server(self, server_data):
        response = self.session.post(
            f"{self.base_url}/api/v1/wireguard/servers",
            json=server_data
        )
        response.raise_for_status()
        return response.json()
    
    def start_server(self, server_id):
        response = self.session.post(
            f"{self.base_url}/api/v1/wireguard/servers/{server_id}/start"
        )
        response.raise_for_status()
        return response.json()

# 使用示例
client = IPv6WireGuardManager(
    base_url="https://your-domain.com",
    username="admin",
    password="password123"
)

# 获取服务器列表
servers = client.get_servers()
print(json.dumps(servers, indent=2))

# 创建新服务器
new_server = client.create_server({
    "name": "wg1",
    "interface": "wg1",
    "listen_port": 51821,
    "ipv4_address": "10.0.1.1/24",
    "ipv6_address": "2001:db8:1::1/64"
})
print(f"服务器创建成功: {new_server['data']['id']}")
```

### JavaScript SDK示例

```javascript
class IPv6WireGuardManager {
    constructor(baseUrl, apiKey = null, username = null, password = null) {
        this.baseUrl = baseUrl.replace(/\/$/, '');
        this.apiKey = apiKey;
        this.accessToken = null;
        
        if (username && password) {
            this.authenticate(username, password);
        }
    }
    
    async authenticate(username, password) {
        const response = await fetch(`${this.baseUrl}/api/v1/auth/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ username, password })
        });
        
        if (!response.ok) {
            throw new Error('认证失败');
        }
        
        const data = await response.json();
        this.accessToken = data.data.access_token;
    }
    
    async request(endpoint, options = {}) {
        const url = `${this.baseUrl}/api/v1${endpoint}`;
        const headers = {
            'Content-Type': 'application/json',
            ...options.headers
        };
        
        if (this.apiKey) {
            headers['X-API-Key'] = this.apiKey;
        } else if (this.accessToken) {
            headers['Authorization'] = `Bearer ${this.accessToken}`;
        }
        
        const response = await fetch(url, {
            ...options,
            headers
        });
        
        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.error?.message || '请求失败');
        }
        
        return response.json();
    }
    
    async getServers(page = 1, size = 20) {
        return this.request(`/wireguard/servers?page=${page}&size=${size}`);
    }
    
    async createServer(serverData) {
        return this.request('/wireguard/servers', {
            method: 'POST',
            body: JSON.stringify(serverData)
        });
    }
    
    async startServer(serverId) {
        return this.request(`/wireguard/servers/${serverId}/start`, {
            method: 'POST'
        });
    }
}

// 使用示例
const client = new IPv6WireGuardManager(
    'https://your-domain.com',
    null,
    'admin',
    'password123'
);

// 获取服务器列表
client.getServers().then(servers => {
    console.log('服务器列表:', servers);
});

// 创建新服务器
client.createServer({
    name: 'wg1',
    interface: 'wg1',
    listen_port: 51821,
    ipv4_address: '10.0.1.1/24',
    ipv6_address: '2001:db8:1::1/64'
}).then(result => {
    console.log('服务器创建成功:', result.data.id);
});
```

### cURL示例

```bash
# 认证
curl -X POST https://your-domain.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "password123"}'

# 获取服务器列表
curl -X GET https://your-domain.com/api/v1/wireguard/servers \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# 创建服务器
curl -X POST https://your-domain.com/api/v1/wireguard/servers \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "wg1",
    "interface": "wg1",
    "listen_port": 51821,
    "ipv4_address": "10.0.1.1/24",
    "ipv6_address": "2001:db8:1::1/64"
  }'

# 启动服务器
curl -X POST https://your-domain.com/api/v1/wireguard/servers/1/start \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

**IPv6 WireGuard Manager API** - 完整的企业级API参考文档 🚀

通过本文档，您可以充分利用IPv6 WireGuard Manager的所有API功能，构建强大的网络管理解决方案！
