# IPv6 WireGuard Manager API 参考文档

## 📋 概述

IPv6 WireGuard Manager 提供完整的 RESTful API，支持所有核心功能的程序化访问。所有API都基于HTTP/HTTPS协议，使用JSON格式进行数据交换。

## 🔐 认证

### JWT令牌认证
所有API请求都需要在请求头中包含有效的JWT令牌：

```http
Authorization: Bearer <your-jwt-token>
```

### 获取令牌
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "admin123"
}
```

**响应**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": "uuid",
    "username": "admin",
    "email": "admin@ipv6wg.local",
    "is_active": true,
    "is_superuser": true
  }
}
```

### 刷新令牌
```http
POST /api/v1/auth/refresh-token
Authorization: Bearer <your-jwt-token>
```

## 🌐 BGP会话管理API

### 获取BGP会话列表
```http
GET /api/v1/bgp/sessions
Authorization: Bearer <token>
```

**响应**:
```json
[
  {
    "id": "uuid",
    "name": "peer-1",
    "neighbor": "192.168.1.2",
    "remote_as": 65002,
    "hold_time": 180,
    "password": "***",
    "description": "主要对等体",
    "enabled": true,
    "status": "established",
    "last_status_change": "2024-01-01T12:00:00Z",
    "uptime": 3600,
    "prefixes_received": 100,
    "prefixes_sent": 50,
    "created_at": "2024-01-01T10:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z"
  }
]
```

### 创建BGP会话
```http
POST /api/v1/bgp/sessions
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "peer-1",
  "neighbor": "192.168.1.2",
  "remote_as": 65002,
  "hold_time": 180,
  "password": "optional-password",
  "description": "主要对等体",
  "enabled": true
}
```

### 更新BGP会话
```http
PATCH /api/v1/bgp/sessions/{session_id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "enabled": false,
  "description": "更新的描述"
}
```

### 删除BGP会话
```http
DELETE /api/v1/bgp/sessions/{session_id}
Authorization: Bearer <token>
```

### 重载BGP会话配置
```http
POST /api/v1/bgp/sessions/{session_id}/reload
Authorization: Bearer <token>
```

### 重启BGP会话
```http
POST /api/v1/bgp/sessions/{session_id}/restart
Authorization: Bearer <token>
```

### 批量操作
```http
POST /api/v1/bgp/sessions/batch/reload
Authorization: Bearer <token>
Content-Type: application/json

["session_id_1", "session_id_2"]
```

## 📢 BGP宣告管理API

### 获取BGP宣告列表
```http
GET /api/v1/bgp/announcements
Authorization: Bearer <token>
```

**响应**:
```json
{
  "announcements": [
    {
      "id": "uuid",
      "session_id": "uuid",
      "prefix": "192.0.2.0/24",
      "asn": 65001,
      "next_hop": "192.168.1.1",
      "description": "客户前缀",
      "enabled": true,
      "created_at": "2024-01-01T10:00:00Z",
      "updated_at": "2024-01-01T12:00:00Z"
    }
  ]
}
```

### 创建BGP宣告
```http
POST /api/v1/bgp/announcements
Authorization: Bearer <token>
Content-Type: application/json

{
  "prefix": "192.0.2.0/24",
  "asn": 65001,
  "next_hop": "192.168.1.1",
  "description": "客户前缀",
  "enabled": true
}
```

### 更新BGP宣告
```http
PATCH /api/v1/bgp/announcements/{ann_id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "enabled": false,
  "description": "更新的描述"
}
```

### 删除BGP宣告
```http
DELETE /api/v1/bgp/announcements/{ann_id}
Authorization: Bearer <token>
```

## 🏊 IPv6前缀池管理API

### 获取前缀池列表
```http
GET /api/v1/ipv6/pools
Authorization: Bearer <token>
```

**响应**:
```json
[
  {
    "id": "uuid",
    "name": "pool-1",
    "prefix": "2001:db8::/48",
    "description": "生产环境前缀池",
    "status": "active",
    "total_addresses": 1000,
    "allocated_addresses": 100,
    "max_prefix_length": 64,
    "min_prefix_length": 128,
    "auto_announce_bgp": true,
    "created_at": "2024-01-01T10:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z"
  }
]
```

### 创建前缀池
```http
POST /api/v1/ipv6/pools
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "pool-1",
  "prefix": "2001:db8::/48",
  "description": "生产环境前缀池",
  "max_prefix_length": 64,
  "min_prefix_length": 128,
  "auto_announce_bgp": true
}
```

### 分配IPv6前缀
```http
POST /api/v1/ipv6/pools/{pool_id}/allocate
Authorization: Bearer <token>
Content-Type: application/json

{
  "client_id": "client-uuid",
  "auto_announce": true
}
```

**响应**:
```json
{
  "success": true,
  "allocation_id": "uuid",
  "allocated_prefix": "2001:db8:1::/64",
  "message": "前缀分配成功"
}
```

### 释放IPv6前缀
```http
POST /api/v1/ipv6/pools/{pool_id}/release/{allocation_id}
Authorization: Bearer <token>
```

### 添加白名单
```http
POST /api/v1/ipv6/pools/{pool_id}/whitelist
Authorization: Bearer <token>
Content-Type: application/json

{
  "prefix": "2001:db8:1::/64",
  "description": "允许的客户端前缀"
}
```

### RPKI验证
```http
POST /api/v1/ipv6/pools/{pool_id}/validate-rpki
Authorization: Bearer <token>
Content-Type: application/json

{
  "prefix": "2001:db8::/64"
}
```

**响应**:
```json
{
  "prefix": "2001:db8::/64",
  "valid": true,
  "reason": "Valid",
  "asn": 65001,
  "max_length": 48
}
```

## 🔒 WireGuard管理API

### 获取WireGuard服务器列表
```http
GET /api/v1/wireguard/servers
Authorization: Bearer <token>
```

**响应**:
```json
[
  {
    "id": "uuid",
    "name": "server-1",
    "interface": "wg0",
    "listen_port": 51820,
    "public_key": "public_key_here",
    "ipv4_address": "10.0.0.1/24",
    "ipv6_address": "fd00:1234::1/64",
    "dns_servers": ["8.8.8.8", "8.8.4.4"],
    "mtu": 1420,
    "config_file_path": "/etc/wireguard/wg0.conf",
    "is_active": true,
    "created_at": "2024-01-01T10:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z"
  }
]
```

### 创建WireGuard服务器
```http
POST /api/v1/wireguard/servers
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "server-1",
  "interface": "wg0",
  "listen_port": 51820,
  "ipv4_address": "10.0.0.1/24",
  "ipv6_address": "fd00:1234::1/64",
  "dns_servers": ["8.8.8.8", "8.8.4.4"],
  "mtu": 1420
}
```

### 获取WireGuard客户端列表
```http
GET /api/v1/wireguard/clients
Authorization: Bearer <token>
```

**响应**:
```json
[
  {
    "id": "uuid",
    "server_id": "uuid",
    "name": "client-1",
    "description": "客户端描述",
    "public_key": "client_public_key",
    "ipv4_address": "10.0.0.2/32",
    "ipv6_address": "fd00:1234::2/128",
    "allowed_ips": ["0.0.0.0/0", "::/0"],
    "created_at": "2024-01-01T10:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z"
  }
]
```

### 创建WireGuard客户端
```http
POST /api/v1/wireguard/clients
Authorization: Bearer <token>
Content-Type: application/json

{
  "server_id": "server-uuid",
  "name": "client-1",
  "description": "客户端描述",
  "ipv4_address": "10.0.0.2/32",
  "ipv6_address": "fd00:1234::2/128"
}
```

### 获取客户端配置
```http
GET /api/v1/wireguard/clients/{client_id}/config
Authorization: Bearer <token>
```

**响应**:
```json
{
  "config": "[Interface]\nPrivateKey = client_private_key\nAddress = 10.0.0.2/32\nDNS = 8.8.8.8\n\n[Peer]\nPublicKey = server_public_key\nEndpoint = server_ip:51820\nAllowedIPs = 0.0.0.0/0, ::/0\nPersistentKeepalive = 25"
}
```

### 获取客户端QR码
```http
GET /api/v1/wireguard/clients/{client_id}/qrcode
Authorization: Bearer <token>
```

**响应**:
```json
{
  "qrcode": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA..."
}
```

## 👤 用户管理API

### 获取用户列表
```http
GET /api/v1/users
Authorization: Bearer <token>
```

**响应**:
```json
[
  {
    "id": "uuid",
    "username": "admin",
    "email": "admin@ipv6wg.local",
    "is_active": true,
    "is_superuser": true,
    "last_login": "2024-01-01T12:00:00Z",
    "created_at": "2024-01-01T10:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z"
  }
]
```

### 创建用户
```http
POST /api/v1/users
Authorization: Bearer <token>
Content-Type: application/json

{
  "username": "newuser",
  "email": "user@example.com",
  "password": "password123",
  "is_active": true,
  "is_superuser": false
}
```

### 更新用户
```http
PATCH /api/v1/users/{user_id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "email": "newemail@example.com",
  "is_active": false
}
```

### 删除用户
```http
DELETE /api/v1/users/{user_id}
Authorization: Bearer <token>
```

## ⚙️ 系统管理API

### 健康检查端点
```http
GET /api/v1/status/health
```

**响应**:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z",
  "version": "1.0.0"
}
```

### 详细健康检查
```http
GET /api/v1/status/health/detailed
Authorization: Bearer <token>
```

**响应**:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z",
  "components": {
    "database": {
      "status": "healthy",
      "response_time": 15.2
    },
    "redis": {
      "status": "healthy",
      "response_time": 2.1
    },
    "cache": {
      "status": "healthy",
      "hit_rate": 85.5
    }
  }
}
```

### 就绪检查（Kubernetes）
```http
GET /api/v1/status/ready
```

**响应**:
```json
{
  "status": "ready",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### 存活检查（Kubernetes）
```http
GET /api/v1/status/live
```

**响应**:
```json
{
  "status": "alive",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### 性能指标端点
```http
GET /api/v1/status/metrics
Authorization: Bearer <token>
```

**响应**:
```json
{
  "timestamp": "2024-01-01T12:00:00Z",
  "performance": {
    "api_response_time": {
      "avg": 45.2,
      "p95": 120.5,
      "p99": 250.8
    },
    "database_query_time": {
      "avg": 12.3,
      "p95": 35.6,
      "p99": 89.2
    },
    "cache_hit_rate": 85.5,
    "active_connections": 125
  },
  "system": {
    "cpu_usage": 25.5,
    "memory_usage": 60.2,
    "disk_usage": 45.8
  }
}
```

### 获取系统状态
```http
GET /api/v1/status/status
Authorization: Bearer <token>
```

**响应**:
```json
{
  "system": {
    "status": "healthy",
    "uptime": 3600,
    "version": "1.0.0"
  },
  "services": {
    "backend": "running",
    "database": "running",
    "redis": "running",
    "nginx": "running"
  },
  "resources": {
    "cpu_usage": 25.5,
    "memory_usage": 60.2,
    "disk_usage": 45.8
  }
}
```

### 获取系统信息
```http
GET /api/v1/system/info
Authorization: Bearer <token>
```

**响应**:
```json
{
  "system": {
    "hostname": "server-1",
    "os": "Ubuntu 20.04",
    "kernel": "5.4.0-74-generic",
    "architecture": "x86_64"
  },
  "network": {
    "interfaces": [
      {
        "name": "eth0",
        "ipv4": "192.168.1.100",
        "ipv6": "2001:db8::100"
      }
    ]
  },
  "services": {
    "wireguard": "active",
    "bgp": "active",
    "database": "active"
  }
}
```

### 执行系统操作
```http
POST /api/v1/system/action
Authorization: Bearer <token>
Content-Type: application/json

{
  "action": "restart",
  "service": "ipv6-wireguard-manager"
}
```

## 📊 监控API

### 获取系统指标
```http
GET /api/v1/monitoring/metrics
Authorization: Bearer <token>
```

**响应**:
```json
{
  "timestamp": "2024-01-01T12:00:00Z",
  "metrics": {
    "cpu": {
      "usage": 25.5,
      "load_avg": [1.2, 1.5, 1.8]
    },
    "memory": {
      "total": 8192,
      "used": 4915,
      "free": 3277,
      "usage_percent": 60.0
    },
    "disk": {
      "total": 100000,
      "used": 45000,
      "free": 55000,
      "usage_percent": 45.0
    },
    "network": {
      "interfaces": [
        {
          "name": "eth0",
          "bytes_sent": 1024000,
          "bytes_recv": 2048000,
          "packets_sent": 1000,
          "packets_recv": 2000
        }
      ]
    }
  }
}
```

### 获取BGP会话状态
```http
GET /api/v1/monitoring/bgp/sessions
Authorization: Bearer <token>
```

**响应**:
```json
[
  {
    "session_id": "uuid",
    "name": "peer-1",
    "status": "established",
    "uptime": 3600,
    "prefixes_received": 100,
    "prefixes_sent": 50,
    "last_update": "2024-01-01T12:00:00Z"
  }
]
```

### 获取前缀池状态
```http
GET /api/v1/monitoring/ipv6/pools
Authorization: Bearer <token>
```

**响应**:
```json
[
  {
    "pool_id": "uuid",
    "name": "pool-1",
    "total_capacity": 1000,
    "allocated": 100,
    "usage_percent": 10.0,
    "status": "healthy"
  }
]
```

## 🔔 WebSocket API

### 连接WebSocket
```javascript
const ws = new WebSocket('ws://localhost:8000/api/v1/ws/user-id?connection_type=bgp_status');
```

### 订阅BGP会话状态
```javascript
ws.send(JSON.stringify({
  type: 'subscribe',
  channel: 'bgp_sessions',
  session_id: 'session-uuid'
}));
```

### 订阅前缀池状态
```javascript
ws.send(JSON.stringify({
  type: 'subscribe',
  channel: 'ipv6_pools',
  pool_id: 'pool-uuid'
}));
```

### 接收状态更新
```javascript
ws.onmessage = function(event) {
  const data = JSON.parse(event.data);
  
  switch(data.type) {
    case 'bgp_status_update':
      console.log('BGP状态更新:', data);
      break;
    case 'pool_status_update':
      console.log('前缀池状态更新:', data);
      break;
    case 'system_alert':
      console.log('系统告警:', data);
      break;
  }
};
```

## 📝 错误处理

### 错误响应格式
```json
{
  "detail": "错误描述",
  "error_code": "ERROR_CODE",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### 常见错误码
- `400` - 请求参数错误
- `401` - 未授权访问
- `403` - 权限不足
- `404` - 资源不存在
- `409` - 资源冲突
- `422` - 数据验证失败
- `500` - 服务器内部错误

### 错误示例
```json
{
  "detail": "用户名或密码错误",
  "error_code": "INVALID_CREDENTIALS",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## 🔒 安全注意事项

### API安全
- 所有API请求必须使用HTTPS
- JWT令牌有过期时间，需要定期刷新
- 敏感操作需要管理员权限
- 所有输入数据都会进行验证和清理

### 最佳实践
- 使用强密码和定期更换
- 限制API访问频率
- 记录所有API操作日志
- 定期备份重要数据

## 📚 示例代码

### Python示例
```python
import requests
import json

# 登录获取令牌
login_data = {
    "username": "admin",
    "password": "admin123"
}
response = requests.post("http://localhost:8000/api/v1/auth/login", json=login_data)
token = response.json()["access_token"]

# 设置请求头
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

# 获取BGP会话列表
response = requests.get("http://localhost:8000/api/v1/bgp/sessions", headers=headers)
sessions = response.json()
print(f"找到 {len(sessions)} 个BGP会话")

# 创建新的BGP会话
new_session = {
    "name": "peer-2",
    "neighbor": "192.168.1.3",
    "remote_as": 65003,
    "hold_time": 180,
    "description": "新的对等体"
}
response = requests.post("http://localhost:8000/api/v1/bgp/sessions", 
                        headers=headers, json=new_session)
print("BGP会话创建成功")
```

### JavaScript示例
```javascript
// 登录获取令牌
async function login() {
  const response = await fetch('/api/v1/auth/login', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      username: 'admin',
      password: 'admin123'
    })
  });
  
  const data = await response.json();
  return data.access_token;
}

// 获取BGP会话列表
async function getBGPSessions(token) {
  const response = await fetch('/api/v1/bgp/sessions', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  return await response.json();
}

// 使用示例
async function main() {
  const token = await login();
  const sessions = await getBGPSessions(token);
  console.log('BGP会话:', sessions);
}
```

---

**注意**: 本API文档会随着系统功能的更新而持续更新，请关注最新版本。
