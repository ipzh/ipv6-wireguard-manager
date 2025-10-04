# API 文档

## 概述

IPv6 WireGuard Manager 提供完整的REST API接口，支持客户端管理、配置操作和系统监控。

## 基础信息

- **Base URL**: `http://your-server:8080/api`
- **认证方式**: Bearer Token
- **数据格式**: JSON
- **字符编码**: UTF-8

## 认证

### 获取Token

```http
POST /api/auth/login
Content-Type: application/json

{
    "username": "admin",
    "password": "admin123"
}
```

**响应**:
```json
{
    "success": true,
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 3600
}
```

### 使用Token

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 客户端管理

### 获取客户端列表

```http
GET /api/clients
```

**响应**:
```json
{
    "success": true,
    "clients": [
        {
            "id": "client1",
            "name": "Client 1",
            "ipv6_address": "2001:db8::2",
            "public_key": "base64-public-key",
            "created_at": "2025-01-01T00:00:00Z",
            "last_seen": "2025-01-01T12:00:00Z",
            "status": "active"
        }
    ]
}
```

### 创建客户端

```http
POST /api/clients
Content-Type: application/json

{
    "name": "New Client",
    "ipv6_address": "2001:db8::3"
}
```

**响应**:
```json
{
    "success": true,
    "client": {
        "id": "client3",
        "name": "New Client",
        "ipv6_address": "2001:db8::3",
        "public_key": "base64-public-key",
        "private_key": "base64-private-key",
        "config": "WireGuard配置文件内容"
    }
}
```

### 获取客户端配置

```http
GET /api/clients/{client_id}/config
```

**响应**:
```json
{
    "success": true,
    "config": "[Interface]\nPrivateKey = base64-private-key\nAddress = 2001:db8::3/128\n\n[Peer]\nPublicKey = base64-server-key\nEndpoint = server:51820\nAllowedIPs = ::/0"
}
```

### 删除客户端

```http
DELETE /api/clients/{client_id}
```

**响应**:
```json
{
    "success": true,
    "message": "客户端已删除"
}
```

## 服务器配置

### 获取服务器状态

```http
GET /api/server/status
```

**响应**:
```json
{
    "success": true,
    "status": {
        "wireguard": "running",
        "bird": "running",
        "nginx": "running",
        "uptime": 3600,
        "clients_connected": 5,
        "total_clients": 10
    }
}
```

### 获取服务器配置

```http
GET /api/server/config
```

**响应**:
```json
{
    "success": true,
    "config": {
        "wireguard_port": 51820,
        "ipv6_prefix": "2001:db8::/64",
        "ipv6_gateway": "2001:db8::1",
        "bgp_enabled": true,
        "bgp_as": 65001,
        "web_port": 8080
    }
}
```

### 更新服务器配置

```http
PUT /api/server/config
Content-Type: application/json

{
    "wireguard_port": 51821,
    "bgp_as": 65002
}
```

**响应**:
```json
{
    "success": true,
    "message": "配置已更新",
    "restart_required": true
}
```

## 网络管理

### 获取网络状态

```http
GET /api/network/status
```

**响应**:
```json
{
    "success": true,
    "network": {
        "ipv6_enabled": true,
        "ipv6_addresses": ["2001:db8::1/64"],
        "wireguard_interface": "wg0",
        "bgp_neighbors": [
            {
                "ip": "2001:db8::100",
                "as": 65000,
                "state": "Established"
            }
        ],
        "routes": [
            {
                "network": "2001:db8:1::/64",
                "next_hop": "2001:db8::100",
                "protocol": "BGP"
            }
        ]
    }
}
```

### 获取BGP状态

```http
GET /api/network/bgp
```

**响应**:
```json
{
    "success": true,
    "bgp": {
        "enabled": true,
        "as_number": 65001,
        "router_id": "192.168.1.1",
        "neighbors": [
            {
                "ip": "2001:db8::100",
                "as": 65000,
                "state": "Established",
                "uptime": 3600,
                "routes_received": 10,
                "routes_advertised": 5
            }
        ]
    }
}
```

## 系统监控

### 获取系统资源

```http
GET /api/monitor/resources
```

**响应**:
```json
{
    "success": true,
    "resources": {
        "cpu": {
            "usage_percent": 25.5,
            "load_average": [0.5, 0.8, 1.2]
        },
        "memory": {
            "total": 2048000000,
            "used": 1024000000,
            "free": 1024000000,
            "usage_percent": 50.0
        },
        "disk": {
            "total": 50000000000,
            "used": 25000000000,
            "free": 25000000000,
            "usage_percent": 50.0
        },
        "network": {
            "interfaces": [
                {
                    "name": "eth0",
                    "rx_bytes": 1000000,
                    "tx_bytes": 2000000,
                    "rx_packets": 1000,
                    "tx_packets": 2000
                }
            ]
        }
    }
}
```

### 获取服务状态

```http
GET /api/monitor/services
```

**响应**:
```json
{
    "success": true,
    "services": [
        {
            "name": "wireguard",
            "status": "running",
            "uptime": 3600,
            "pid": 1234,
            "memory_usage": 1024000
        },
        {
            "name": "bird",
            "status": "running",
            "uptime": 3600,
            "pid": 1235,
            "memory_usage": 2048000
        }
    ]
}
```

## 日志管理

### 获取日志列表

```http
GET /api/logs
```

**查询参数**:
- `type`: 日志类型 (manager, error, access)
- `level`: 日志级别 (debug, info, warn, error)
- `limit`: 返回条数 (默认100)
- `offset`: 偏移量 (默认0)

**响应**:
```json
{
    "success": true,
    "logs": [
        {
            "timestamp": "2025-01-01T12:00:00Z",
            "level": "info",
            "message": "客户端连接成功",
            "source": "wireguard"
        }
    ],
    "total": 1000,
    "limit": 100,
    "offset": 0
}
```

### 下载日志文件

```http
GET /api/logs/download
```

**查询参数**:
- `type`: 日志类型
- `date`: 日期 (YYYY-MM-DD)

**响应**: 日志文件下载

## 错误处理

### 错误响应格式

```json
{
    "success": false,
    "error": {
        "code": "INVALID_REQUEST",
        "message": "请求参数无效",
        "details": "缺少必需的参数: name"
    }
}
```

### 错误代码

| 代码 | 描述 |
|------|------|
| `INVALID_REQUEST` | 请求参数无效 |
| `UNAUTHORIZED` | 未授权访问 |
| `FORBIDDEN` | 禁止访问 |
| `NOT_FOUND` | 资源不存在 |
| `CONFLICT` | 资源冲突 |
| `INTERNAL_ERROR` | 内部服务器错误 |

## 速率限制

- **认证请求**: 5次/分钟
- **API请求**: 100次/分钟
- **文件下载**: 10次/分钟

超出限制时返回:
```json
{
    "success": false,
    "error": {
        "code": "RATE_LIMIT_EXCEEDED",
        "message": "请求频率过高，请稍后重试"
    }
}
```

## WebSocket 实时更新

### 连接

```javascript
const ws = new WebSocket('ws://your-server:8080/ws');
```

### 事件类型

```json
{
    "type": "client_connected",
    "data": {
        "client_id": "client1",
        "ipv6_address": "2001:db8::2"
    }
}
```

**事件类型**:
- `client_connected` - 客户端连接
- `client_disconnected` - 客户端断开
- `config_updated` - 配置更新
- `system_alert` - 系统告警

## SDK 示例

### Python

```python
import requests

class IPv6WireGuardManager:
    def __init__(self, base_url, username, password):
        self.base_url = base_url
        self.token = self.login(username, password)
        self.headers = {'Authorization': f'Bearer {self.token}'}
    
    def login(self, username, password):
        response = requests.post(f'{self.base_url}/api/auth/login', 
                               json={'username': username, 'password': password})
        return response.json()['token']
    
    def get_clients(self):
        response = requests.get(f'{self.base_url}/api/clients', 
                              headers=self.headers)
        return response.json()
    
    def create_client(self, name, ipv6_address):
        response = requests.post(f'{self.base_url}/api/clients',
                               json={'name': name, 'ipv6_address': ipv6_address},
                               headers=self.headers)
        return response.json()
```

### JavaScript

```javascript
class IPv6WireGuardManager {
    constructor(baseUrl, username, password) {
        this.baseUrl = baseUrl;
        this.token = null;
        this.login(username, password);
    }
    
    async login(username, password) {
        const response = await fetch(`${this.baseUrl}/api/auth/login`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({username, password})
        });
        const data = await response.json();
        this.token = data.token;
    }
    
    async getClients() {
        const response = await fetch(`${this.baseUrl}/api/clients`, {
            headers: {'Authorization': `Bearer ${this.token}`}
        });
        return await response.json();
    }
}
```
## Cache API（统一缓存接口）

统一入口位于 `modules/cache_api.sh`，提供跨模块一致的缓存调用方式，避免绕过底层实现。

可用函数：

- `cache_set key value [ttl]`：写入缓存。
- `cache_get key`：读取缓存，命中则输出值并返回 0，未命中返回非 0。
- `cache_invalidate key`：失效指定键。
- `cache_exists key`：判断是否存在（返回码表示结果）。
- `cache_exec command cache_key [ttl] [force_refresh]`：执行命令并根据键进行缓存；优先委托增强缓存后端。
- `cache_stats`：输出“结构化JSON”统计信息，字段包含：`backend`、`entries`、`hits`、`misses`、`evictions`、`total_size`、`hit_rate`。某些字段在特定后端可能为 `null`。
- `cache_clear`：清空后端缓存。

说明：

- 后端优先级：`enhanced_cache_system` > `smart_caching` > `config_cache`，缺失后端时回退到直接执行。
- 为保持兼容性，`smart_caching` 与其他模块内部统计/持久化逻辑仍保留，但统一入口会优先使用后端的原生能力。
- `cache_stats` 的输出不强制统一；若需要统一格式，可在各后端实现中约定标准化输出。
