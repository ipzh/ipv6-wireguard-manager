# IPv6 WireGuard Manager - API 完整文档

## 📋 目录

- [概述](#概述)
- [认证](#认证)
- [用户管理](#用户管理)
- [WireGuard管理](#wireguard管理)
- [BGP管理](#bgp管理)
- [IPv6管理](#ipv6管理)
- [监控管理](#监控管理)
- [日志管理](#日志管理)
- [系统管理](#系统管理)
- [备份管理](#备份管理)
- [集群管理](#集群管理)
- [WebSocket实时通信](#websocket实时通信)
- [状态检查](#状态检查)
- [错误处理](#错误处理)
- [响应格式](#响应格式)

## 概述

IPv6 WireGuard Manager 提供完整的RESTful API，支持IPv4/IPv6双栈网络管理、WireGuard VPN管理、BGP路由管理等功能。

### 基础信息

- **API版本**: v1
- **基础URL**: `http://your-server:8000/api/v1`
- **认证方式**: JWT Bearer Token
- **数据格式**: JSON
- **字符编码**: UTF-8

### 通用响应格式

```json
{
  "success": true,
  "data": {},
  "message": "操作成功",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### 错误响应格式

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述",
    "details": {}
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## 认证

### 用户登录

**POST** `/auth/login`

#### 请求参数

```json
{
  "username": "admin",
  "password": "password123"
}
```

#### 响应示例

```json
{
  "success": true,
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "token_type": "bearer",
    "expires_in": 691200,
    "user": {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com",
      "role": "admin",
      "permissions": ["*"]
    }
  }
}
```

### 刷新令牌

**POST** `/auth/refresh`

#### 请求头

```
Authorization: Bearer <access_token>
```

#### 响应示例

```json
{
  "success": true,
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "expires_in": 691200
  }
}
```

### 用户登出

**POST** `/auth/logout`

#### 请求头

```
Authorization: Bearer <access_token>
```

#### 响应示例

```json
{
  "success": true,
  "message": "登出成功"
}
```

### 获取当前用户信息

**GET** `/auth/me`

#### 请求头

```
Authorization: Bearer <access_token>
```

#### 响应示例

```json
{
  "success": true,
  "data": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "full_name": "Administrator",
    "role": "admin",
    "permissions": ["*"],
    "last_login": "2024-01-01T00:00:00Z",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

## 用户管理

### 获取用户列表

**GET** `/users`

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | integer | 否 | 页码，默认1 |
| size | integer | 否 | 每页数量，默认20 |
| search | string | 否 | 搜索关键词 |
| role | string | 否 | 角色筛选 |

#### 响应示例

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
        "is_active": true,
        "last_login": "2024-01-01T00:00:00Z",
        "created_at": "2024-01-01T00:00:00Z"
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

### 创建用户

**POST** `/users`

#### 请求参数

```json
{
  "username": "newuser",
  "email": "user@example.com",
  "password": "password123",
  "full_name": "New User",
  "role": "user",
  "is_active": true
}
```

#### 响应示例

```json
{
  "success": true,
  "data": {
    "id": 2,
    "username": "newuser",
    "email": "user@example.com",
    "full_name": "New User",
    "role": "user",
    "is_active": true,
    "created_at": "2024-01-01T00:00:00Z"
  },
  "message": "用户创建成功"
}
```

### 获取用户详情

**GET** `/users/{user_id}`

#### 路径参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| user_id | integer | 是 | 用户ID |

#### 响应示例

```json
{
  "success": true,
  "data": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "full_name": "Administrator",
    "role": "admin",
    "is_active": true,
    "permissions": ["*"],
    "last_login": "2024-01-01T00:00:00Z",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
}
```

### 更新用户

**PUT** `/users/{user_id}`

#### 请求参数

```json
{
  "email": "newemail@example.com",
  "full_name": "Updated Name",
  "role": "manager",
  "is_active": true
}
```

#### 响应示例

```json
{
  "success": true,
  "data": {
    "id": 1,
    "username": "admin",
    "email": "newemail@example.com",
    "full_name": "Updated Name",
    "role": "manager",
    "is_active": true,
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "message": "用户更新成功"
}
```

### 删除用户

**DELETE** `/users/{user_id}`

#### 响应示例

```json
{
  "success": true,
  "message": "用户删除成功"
}
```

### 重置用户密码

**POST** `/users/{user_id}/reset-password`

#### 请求参数

```json
{
  "new_password": "newpassword123"
}
```

#### 响应示例

```json
{
  "success": true,
  "message": "密码重置成功"
}
```

## WireGuard管理

### 获取服务器列表

**GET** `/wireguard/servers`

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | integer | 否 | 页码 |
| size | integer | 否 | 每页数量 |
| status | string | 否 | 状态筛选 |

#### 响应示例

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
        "created_at": "2024-01-01T00:00:00Z"
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

### 创建服务器

**POST** `/wireguard/servers`

#### 请求参数

```json
{
  "name": "wg1",
  "interface": "wg1",
  "listen_port": 51821,
  "ipv4_address": "10.0.1.1/24",
  "ipv6_address": "2001:db8:1::1/64",
  "dns_servers": ["8.8.8.8", "2001:4860:4860::8888"],
  "mtu": 1420,
  "is_active": true
}
```

#### 响应示例

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
    "created_at": "2024-01-01T00:00:00Z"
  },
  "message": "服务器创建成功"
}
```

### 启动服务器

**POST** `/wireguard/servers/{server_id}/start`

#### 响应示例

```json
{
  "success": true,
  "data": {
    "id": 1,
    "status": "running",
    "started_at": "2024-01-01T00:00:00Z"
  },
  "message": "服务器启动成功"
}
```

### 停止服务器

**POST** `/wireguard/servers/{server_id}/stop`

#### 响应示例

```json
{
  "success": true,
  "data": {
    "id": 1,
    "status": "stopped",
    "stopped_at": "2024-01-01T00:00:00Z"
  },
  "message": "服务器停止成功"
}
```

### 获取客户端列表

**GET** `/wireguard/clients`

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| server_id | integer | 否 | 服务器ID筛选 |
| page | integer | 否 | 页码 |
| size | integer | 否 | 每页数量 |

#### 响应示例

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
        "last_handshake": "2024-01-01T00:00:00Z",
        "bytes_received": 1024000,
        "bytes_sent": 2048000,
        "created_at": "2024-01-01T00:00:00Z"
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

### 创建客户端

**POST** `/wireguard/clients`

#### 请求参数

```json
{
  "name": "client2",
  "server_id": 1,
  "ipv4_address": "10.0.0.3/32",
  "ipv6_address": "2001:db8::3/128",
  "dns_servers": ["8.8.8.8"],
  "allowed_ips": ["0.0.0.0/0", "::/0"]
}
```

#### 响应示例

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
    "config": "完整的客户端配置文件内容",
    "qr_code": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
    "created_at": "2024-01-01T00:00:00Z"
  },
  "message": "客户端创建成功"
}
```

## BGP管理

### 获取BGP会话列表

**GET** `/bgp/sessions`

#### 响应示例

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
        "uptime": 3600,
        "routes_received": 100,
        "routes_advertised": 50,
        "last_update": "2024-01-01T00:00:00Z",
        "created_at": "2024-01-01T00:00:00Z"
      }
    ]
  }
}
```

### 创建BGP会话

**POST** `/bgp/sessions`

#### 请求参数

```json
{
  "name": "session2",
  "neighbor": "192.168.1.2",
  "remote_as": 65002,
  "local_as": 65000,
  "password": "bgp_password",
  "enabled": true
}
```

#### 响应示例

```json
{
  "success": true,
  "data": {
    "id": 2,
    "name": "session2",
    "neighbor": "192.168.1.2",
    "remote_as": 65002,
    "local_as": 65000,
    "status": "idle",
    "created_at": "2024-01-01T00:00:00Z"
  },
  "message": "BGP会话创建成功"
}
```

### 启动BGP会话

**POST** `/bgp/sessions/{session_id}/start`

#### 响应示例

```json
{
  "success": true,
  "data": {
    "id": 1,
    "status": "established",
    "started_at": "2024-01-01T00:00:00Z"
  },
  "message": "BGP会话启动成功"
}
```

### 获取BGP宣告列表

**GET** `/bgp/announcements`

#### 响应示例

```json
{
  "success": true,
  "data": {
    "announcements": [
      {
        "id": 1,
        "prefix": "192.168.1.0/24",
        "next_hop": "192.168.1.1",
        "as_path": "65000",
        "community": "65000:100",
        "status": "active",
        "created_at": "2024-01-01T00:00:00Z"
      }
    ]
  }
}
```

### 创建BGP宣告

**POST** `/bgp/announcements`

#### 请求参数

```json
{
  "prefix": "192.168.2.0/24",
  "next_hop": "192.168.2.1",
  "as_path": "65000",
  "community": "65000:200",
  "enabled": true
}
```

#### 响应示例

```json
{
  "success": true,
  "data": {
    "id": 2,
    "prefix": "192.168.2.0/24",
    "next_hop": "192.168.2.1",
    "as_path": "65000",
    "community": "65000:200",
    "status": "active",
    "created_at": "2024-01-01T00:00:00Z"
  },
  "message": "BGP宣告创建成功"
}
```

## IPv6管理

### 获取IPv6前缀池列表

**GET** `/ipv6/pools`

#### 响应示例

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
        "created_at": "2024-01-01T00:00:00Z"
      }
    ]
  }
}
```

### 创建IPv6前缀池

**POST** `/ipv6/pools`

#### 请求参数

```json
{
  "name": "pool2",
  "prefix": "2001:db8:1::/48",
  "prefix_length": 64,
  "description": "IPv6前缀池2"
}
```

#### 响应示例

```json
{
  "success": true,
  "data": {
    "id": 2,
    "name": "pool2",
    "prefix": "2001:db8:1::/48",
    "prefix_length": 64,
    "total_prefixes": 65536,
    "allocated_prefixes": 0,
    "available_prefixes": 65536,
    "status": "active",
    "created_at": "2024-01-01T00:00:00Z"
  },
  "message": "IPv6前缀池创建成功"
}
```

### 分配IPv6前缀

**POST** `/ipv6/allocations`

#### 请求参数

```json
{
  "pool_id": 1,
  "client_name": "client1",
  "description": "客户端1的IPv6前缀"
}
```

#### 响应示例

```json
{
  "success": true,
  "data": {
    "id": 1,
    "pool_id": 1,
    "client_name": "client1",
    "allocated_prefix": "2001:db8::/64",
    "status": "active",
    "allocated_at": "2024-01-01T00:00:00Z"
  },
  "message": "IPv6前缀分配成功"
}
```

## 监控管理

### 获取监控仪表板数据

**GET** `/monitoring/dashboard`

#### 响应示例

```json
{
  "success": true,
  "data": {
    "system_metrics": {
      "cpu": {
        "usage": 45.2,
        "cores": 4,
        "load_average": [1.2, 1.5, 1.8]
      },
      "memory": {
        "total": 8589934592,
        "used": 4294967296,
        "free": 4294967296,
        "usage_percent": 50.0
      },
      "disk": {
        "total": 107374182400,
        "used": 53687091200,
        "free": 53687091200,
        "usage_percent": 50.0
      },
      "network": {
        "bytes_sent": 1024000,
        "bytes_recv": 2048000,
        "packets_sent": 1000,
        "packets_recv": 2000
      }
    },
    "application_metrics": {
      "database": {
        "pool_size": 10,
        "checked_out": 2,
        "active_connections": 8
      },
      "cache": {
        "hit_rate": 85.5,
        "miss_rate": 14.5,
        "memory_usage": 1048576
      }
    },
    "alerts": {
      "active": 2,
      "critical": 0,
      "warning": 2,
      "info": 0
    }
  }
}
```

### 获取系统指标

**GET** `/monitoring/metrics/system`

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| hours | integer | 否 | 获取最近几小时的指标，默认24 |

#### 响应示例

```json
{
  "success": true,
  "data": [
    {
      "name": "system.cpu.usage",
      "value": 45.2,
      "timestamp": "2024-01-01T00:00:00Z",
      "tags": {"type": "system"},
      "metadata": {"unit": "percent"}
    }
  ]
}
```

### 获取活跃告警

**GET** `/monitoring/alerts/active`

#### 响应示例

```json
{
  "success": true,
  "data": [
    {
      "id": "cpu_high_20240101_000000",
      "name": "CPU使用率过高",
      "description": "CPU使用率超过80%",
      "level": "warning",
      "status": "active",
      "metric_name": "system.cpu.usage",
      "threshold_value": 80.0,
      "current_value": 85.2,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

### 创建告警规则

**POST** `/monitoring/alerts/rules`

#### 请求参数

```json
{
  "id": "memory_high",
  "name": "内存使用率过高",
  "metric_name": "system.memory.usage",
  "condition": ">",
  "threshold": 85.0,
  "level": "error",
  "enabled": true,
  "cooldown_minutes": 5,
  "description": "内存使用率超过85%"
}
```

#### 响应示例

```json
{
  "success": true,
  "data": {
    "id": "memory_high",
    "name": "内存使用率过高",
    "metric_name": "system.memory.usage",
    "condition": ">",
    "threshold": 85.0,
    "level": "error",
    "enabled": true,
    "cooldown_minutes": 5,
    "description": "内存使用率超过85%"
  },
  "message": "告警规则创建成功"
}
```

## 日志管理

### 获取日志列表

**GET** `/logs`

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | integer | 否 | 页码 |
| size | integer | 否 | 每页数量 |
| level | string | 否 | 日志级别筛选 |
| start_time | string | 否 | 开始时间 |
| end_time | string | 否 | 结束时间 |
| search | string | 否 | 搜索关键词 |

#### 响应示例

```json
{
  "success": true,
  "data": {
    "logs": [
      {
        "id": 1,
        "level": "INFO",
        "message": "用户登录成功",
        "module": "auth",
        "user_id": 1,
        "ip_address": "192.168.1.100",
        "timestamp": "2024-01-01T00:00:00Z",
        "details": {
          "username": "admin",
          "user_agent": "Mozilla/5.0..."
        }
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

### 获取日志详情

**GET** `/logs/{log_id}`

#### 响应示例

```json
{
  "success": true,
  "data": {
    "id": 1,
    "level": "ERROR",
    "message": "数据库连接失败",
    "module": "database",
    "timestamp": "2024-01-01T00:00:00Z",
    "details": {
      "error": "Connection timeout",
      "host": "localhost",
      "port": 3306,
      "database": "ipv6wgm"
    },
    "stack_trace": "Traceback (most recent call last)..."
  }
}
```

### 导出日志

**GET** `/logs/export`

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| format | string | 否 | 导出格式 (json, csv, txt) |
| start_time | string | 否 | 开始时间 |
| end_time | string | 否 | 结束时间 |
| level | string | 否 | 日志级别 |

#### 响应示例

```json
{
  "success": true,
  "data": {
    "download_url": "/logs/export/download/export_20240101_000000.json",
    "file_size": 1048576,
    "expires_at": "2024-01-01T01:00:00Z"
  }
}
```

## 系统管理

### 获取系统信息

**GET** `/system/info`

#### 响应示例

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
      "load_average": [1.2, 1.5, 1.8]
    },
    "application": {
      "name": "IPv6 WireGuard Manager",
      "version": "3.0.0",
      "build_date": "2024-01-01T00:00:00Z",
      "python_version": "3.11.2",
      "environment": "production"
    },
    "database": {
      "type": "MySQL",
      "version": "8.0.35",
      "status": "connected",
      "pool_size": 10,
      "active_connections": 3
    }
  }
}
```

### 获取系统配置

**GET** `/system/config`

#### 响应示例

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
    "monitoring_enabled": true
  }
}
```

### 更新系统配置

**PUT** `/system/config`

#### 请求参数

```json
{
  "log_level": "DEBUG",
  "max_log_size": 200,
  "backup_retention": 60,
  "session_timeout": 7200,
  "api_rate_limit": 2000
}
```

#### 响应示例

```json
{
  "success": true,
  "data": {
    "log_level": "DEBUG",
    "max_log_size": 200,
    "backup_retention": 60,
    "session_timeout": 7200,
    "api_rate_limit": 2000,
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "message": "系统配置更新成功"
}
```

## 备份管理

### 获取备份列表

**GET** `/backup/backups`

#### 响应示例

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
      "checksum": "md5_hash_here"
    }
  ]
}
```

### 创建备份

**POST** `/backup/backups/create`

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | 是 | 备份名称 |
| backup_type | string | 否 | 备份类型 (full, database, files, config) |
| metadata | object | 否 | 备份元数据 |

#### 响应示例

```json
{
  "success": true,
  "data": {
    "message": "备份创建已开始",
    "name": "Manual Backup",
    "type": "full"
  }
}
```

### 恢复备份

**POST** `/backup/backups/{backup_id}/restore`

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| target_dir | string | 否 | 恢复目标目录 |

#### 响应示例

```json
{
  "success": true,
  "data": {
    "message": "备份恢复已开始",
    "backup_id": "backup_20240101_000000",
    "backup_name": "Daily Backup"
  }
}
```

### 下载备份

**GET** `/backup/backups/{backup_id}/download`

#### 响应

返回备份文件的二进制流，Content-Type为application/gzip。

### 获取备份统计

**GET** `/backup/stats`

#### 响应示例

```json
{
  "success": true,
  "data": {
    "total_backups": 10,
    "successful_backups": 9,
    "failed_backups": 1,
    "total_size_bytes": 1048576000,
    "total_size_mb": 1000,
    "schedules": {
      "daily_full": {
        "type": "daily",
        "backup_type": "full",
        "enabled": true,
        "last_run": "2024-01-01T00:00:00Z"
      }
    },
    "running_backups": []
  }
}
```

## 集群管理

### 获取集群状态

**GET** `/cluster/status`

#### 响应示例

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
        "last_heartbeat": "2024-01-01T00:00:00Z",
        "load_factor": 0.2,
        "capabilities": ["api", "database", "cache"],
        "metadata": {
          "version": "3.0.0",
          "environment": "production"
        }
      }
    ],
    "services": {
      "ipv6-wireguard-manager": {
        "nodes": ["node1", "node2", "node3"],
        "metadata": {},
        "last_updated": "2024-01-01T00:00:00Z"
      }
    },
    "load_balancer": {
      "strategy": "round_robin",
      "node_weights": {}
    }
  }
}
```

### 获取集群节点列表

**GET** `/cluster/nodes`

#### 响应示例

```json
{
  "success": true,
  "data": [
    {
      "id": "node1",
      "host": "192.168.1.10",
      "port": 8000,
      "status": "healthy",
      "last_heartbeat": "2024-01-01T00:00:00Z",
      "load_factor": 0.2,
      "capabilities": ["api", "database", "cache"],
      "metadata": {
        "version": "3.0.0",
        "environment": "production"
      }
    }
  ]
}
```

### 添加节点到集群

**POST** `/cluster/nodes`

#### 请求参数

```json
{
  "id": "node4",
  "host": "192.168.1.13",
  "port": 8000,
  "status": "healthy",
  "load_factor": 0.0,
  "capabilities": ["api", "cache"],
  "metadata": {
    "version": "3.0.0",
    "environment": "production"
  }
}
```

#### 响应示例

```json
{
  "success": true,
  "data": {
    "message": "节点添加成功",
    "node": {
      "id": "node4",
      "host": "192.168.1.13",
      "port": 8000,
      "status": "healthy",
      "last_heartbeat": "2024-01-01T00:00:00Z",
      "load_factor": 0.0,
      "capabilities": ["api", "cache"],
      "metadata": {
        "version": "3.0.0",
        "environment": "production"
      }
    }
  }
}
```

### 检查节点健康状态

**POST** `/cluster/nodes/{node_id}/health-check`

#### 响应示例

```json
{
  "success": true,
  "data": {
    "node_id": "node1",
    "is_healthy": true,
    "status": "healthy",
    "last_checked": "2024-01-01T00:00:00Z"
  }
}
```

### 获取负载均衡器信息

**GET** `/cluster/load-balancer`

#### 响应示例

```json
{
  "success": true,
  "data": {
    "strategy": "round_robin",
    "node_weights": {},
    "available_strategies": ["round_robin", "least_connections", "weighted"]
  }
}
```

### 更新负载均衡策略

**PUT** `/cluster/load-balancer/strategy`

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| strategy | string | 是 | 负载均衡策略 |

#### 响应示例

```json
{
  "success": true,
  "data": {
    "message": "负载均衡策略更新成功",
    "strategy": "least_connections"
  }
}
```

## WebSocket实时通信

### 连接WebSocket

**WebSocket** `/ws/connect`

#### 连接参数

```json
{
  "token": "jwt_token_here",
  "channels": ["system", "wireguard", "bgp", "monitoring"]
}
```

#### 消息格式

```json
{
  "type": "message_type",
  "data": {},
  "timestamp": "2024-01-01T00:00:00Z"
}
```

#### 消息类型

- `system_status`: 系统状态更新
- `wireguard_status`: WireGuard状态更新
- `bgp_status`: BGP状态更新
- `monitoring_alert`: 监控告警
- `log_entry`: 新日志条目

### 系统状态流

**WebSocket** `/ws/system/status`

#### 消息示例

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

### WireGuard状态流

**WebSocket** `/ws/wireguard/status`

#### 消息示例

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

### BGP状态流

**WebSocket** `/ws/bgp/status`

#### 消息示例

```json
{
  "type": "bgp_status",
  "data": {
    "sessions": [
      {
        "id": 1,
        "name": "session1",
        "status": "established",
        "uptime": 3600,
        "routes_received": 100,
        "routes_advertised": 50
      }
    ]
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### 监控告警流

**WebSocket** `/ws/monitoring/alerts`

#### 消息示例

```json
{
  "type": "monitoring_alert",
  "data": {
    "id": "cpu_high_20240101_000000",
    "name": "CPU使用率过高",
    "level": "warning",
    "status": "active",
    "metric_name": "system.cpu.usage",
    "current_value": 85.2,
    "threshold_value": 80.0
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## 状态检查

### 基础健康检查

**GET** `/status/health`

#### 响应示例

```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "service": "IPv6 WireGuard Manager",
    "version": "3.0.0",
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

### 详细健康检查

**GET** `/status/health/detailed`

#### 响应示例

```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "service": "IPv6 WireGuard Manager",
    "version": "3.0.0",
    "components": {
      "database": {
        "status": "healthy",
        "response_time": 5,
        "connections": 3
      },
      "cache": {
        "status": "healthy",
        "response_time": 2,
        "hit_rate": 85.5
      },
      "wireguard": {
        "status": "healthy",
        "servers": 2,
        "clients": 10
      },
      "bgp": {
        "status": "healthy",
        "sessions": 1,
        "routes": 50
      }
    },
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

### 系统状态

**GET** `/status/system`

#### 响应示例

```json
{
  "success": true,
  "data": {
    "system": {
      "hostname": "server1",
      "os": "Ubuntu 22.04 LTS",
      "uptime": 86400,
      "load_average": [1.2, 1.5, 1.8]
    },
    "resources": {
      "cpu": {
        "usage": 45.2,
        "cores": 4
      },
      "memory": {
        "total": 8589934592,
        "used": 4294967296,
        "usage_percent": 50.0
      },
      "disk": {
        "total": 107374182400,
        "used": 53687091200,
        "usage_percent": 50.0
      }
    },
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

## 错误处理

### HTTP状态码

| 状态码 | 说明 |
|--------|------|
| 200 | 请求成功 |
| 201 | 创建成功 |
| 400 | 请求参数错误 |
| 401 | 未授权 |
| 403 | 禁止访问 |
| 404 | 资源不存在 |
| 409 | 资源冲突 |
| 422 | 数据验证失败 |
| 429 | 请求频率限制 |
| 500 | 服务器内部错误 |
| 503 | 服务不可用 |

### 错误代码

| 错误代码 | 说明 |
|----------|------|
| INVALID_CREDENTIALS | 无效的认证凭据 |
| TOKEN_EXPIRED | 令牌已过期 |
| INSUFFICIENT_PERMISSIONS | 权限不足 |
| RESOURCE_NOT_FOUND | 资源不存在 |
| VALIDATION_ERROR | 数据验证失败 |
| RATE_LIMIT_EXCEEDED | 请求频率超限 |
| INTERNAL_ERROR | 内部服务器错误 |
| SERVICE_UNAVAILABLE | 服务不可用 |

### 错误响应示例

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "数据验证失败",
    "details": {
      "field": "username",
      "message": "用户名不能为空"
    }
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## 响应格式

### 成功响应

```json
{
  "success": true,
  "data": {},
  "message": "操作成功",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### 分页响应

```json
{
  "success": true,
  "data": {
    "items": [],
    "pagination": {
      "page": 1,
      "size": 20,
      "total": 100,
      "pages": 5
    }
  }
}
```

### 错误响应

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述",
    "details": {}
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

---

**IPv6 WireGuard Manager API** - 完整的企业级API文档 🚀
