# API文档

## 概述

IPv6 WireGuard Manager提供完整的RESTful API接口，支持WireGuard服务器和客户端管理、用户认证、系统监控等功能。

## 基础信息

- **Base URL**: `http://localhost:8000/api/v1`
- **认证方式**: JWT Bearer Token
- **数据格式**: JSON
- **字符编码**: UTF-8

## 认证

### 获取访问令牌

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "admin123"
}
```

**响应示例:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 11520,
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 刷新令牌

```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 登出

```http
POST /api/v1/auth/logout
Authorization: Bearer <access_token>
```

## 用户管理

### 获取用户列表

```http
GET /api/v1/users
Authorization: Bearer <access_token>
```

**查询参数:**
- `page`: 页码 (默认: 1)
- `size`: 每页数量 (默认: 20)
- `search`: 搜索关键词
- `role`: 角色过滤
- `status`: 状态过滤

**响应示例:**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": 1,
        "username": "admin",
        "email": "admin@example.com",
        "role": "admin",
        "status": "active",
        "created_at": "2024-01-01T00:00:00Z",
        "last_login": "2024-01-01T12:00:00Z"
      }
    ],
    "total": 1,
    "page": 1,
    "size": 20
  }
}
```

### 创建用户

```http
POST /api/v1/users
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "username": "newuser",
  "email": "newuser@example.com",
  "password": "password123",
  "role": "user"
}
```

### 获取用户详情

```http
GET /api/v1/users/{user_id}
Authorization: Bearer <access_token>
```

### 更新用户

```http
PUT /api/v1/users/{user_id}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "email": "updated@example.com",
  "role": "admin"
}
```

### 删除用户

```http
DELETE /api/v1/users/{user_id}
Authorization: Bearer <access_token>
```

## WireGuard服务器管理

### 获取服务器列表

```http
GET /api/v1/wireguard/servers
Authorization: Bearer <access_token>
```

**响应示例:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Main Server",
      "interface": "wg0",
      "port": 51820,
      "private_key": "***REDACTED***",
      "public_key": "ABC123...",
      "address": "10.0.0.1/24",
      "ipv6_address": "fd00::1/64",
      "status": "running",
      "peers_count": 5,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

### 创建服务器

```http
POST /api/v1/wireguard/servers
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "New Server",
  "interface": "wg0",
  "port": 51820,
  "address": "10.0.0.1/24",
  "ipv6_address": "fd00::1/64",
  "private_key": "base64_encoded_private_key"
}
```

### 获取服务器详情

```http
GET /api/v1/wireguard/servers/{server_id}
Authorization: Bearer <access_token>
```

### 更新服务器

```http
PUT /api/v1/wireguard/servers/{server_id}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "Updated Server Name",
  "port": 51821
}
```

### 删除服务器

```http
DELETE /api/v1/wireguard/servers/{server_id}
Authorization: Bearer <access_token>
```

### 服务器状态管理

#### 启动服务器
```http
POST /api/v1/wireguard/servers/{server_id}/start
Authorization: Bearer <access_token>
```

#### 停止服务器
```http
POST /api/v1/wireguard/servers/{server_id}/stop
Authorization: Bearer <access_token>
```

#### 重启服务器
```http
POST /api/v1/wireguard/servers/{server_id}/restart
Authorization: Bearer <access_token>
```

#### 获取服务器状态
```http
GET /api/v1/wireguard/servers/{server_id}/status
Authorization: Bearer <access_token>
```

**响应示例:**
```json
{
  "success": true,
  "data": {
    "status": "running",
    "uptime": "2 days, 3 hours",
    "peers": 5,
    "bytes_received": 1024000,
    "bytes_sent": 2048000,
    "last_handshake": "2024-01-01T12:00:00Z"
  }
}
```

## WireGuard客户端管理

### 获取客户端列表

```http
GET /api/v1/wireguard/clients
Authorization: Bearer <access_token>
```

**查询参数:**
- `server_id`: 服务器ID过滤
- `status`: 状态过滤
- `page`: 页码
- `size`: 每页数量

### 创建客户端

```http
POST /api/v1/wireguard/clients
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "Client 1",
  "server_id": 1,
  "public_key": "base64_encoded_public_key",
  "allowed_ips": "10.0.0.2/32, fd00::2/128"
}
```

### 获取客户端详情

```http
GET /api/v1/wireguard/clients/{client_id}
Authorization: Bearer <access_token>
```

### 更新客户端

```http
PUT /api/v1/wireguard/clients/{client_id}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "Updated Client Name",
  "allowed_ips": "10.0.0.2/32, fd00::2/128, 192.168.1.0/24"
}
```

### 删除客户端

```http
DELETE /api/v1/wireguard/clients/{client_id}
Authorization: Bearer <access_token>
```

### 获取客户端配置

```http
GET /api/v1/wireguard/clients/{client_id}/config
Authorization: Bearer <access_token>
```

**响应示例:**
```json
{
  "success": true,
  "data": {
    "config": "[Interface]\nPrivateKey = ABC123...\nAddress = 10.0.0.2/32, fd00::2/128\n\n[Peer]\nPublicKey = XYZ789...\nEndpoint = server.example.com:51820\nAllowedIPs = 0.0.0.0/0, ::/0",
    "qr_code": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA..."
  }
}
```

### 获取二维码

```http
GET /api/v1/wireguard/clients/{client_id}/qr-code
Authorization: Bearer <access_token>
```

### 客户端状态管理

#### 启用客户端
```http
POST /api/v1/wireguard/clients/{client_id}/enable
Authorization: Bearer <access_token>
```

#### 禁用客户端
```http
POST /api/v1/wireguard/clients/{client_id}/disable
Authorization: Bearer <access_token>
```

## BGP管理

### 获取BGP会话列表

```http
GET /api/v1/bgp/sessions
Authorization: Bearer <access_token>
```

### 创建BGP会话

```http
POST /api/v1/bgp/sessions
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "BGP Session 1",
  "local_as": 65001,
  "remote_as": 65002,
  "remote_ip": "192.168.1.1",
  "password": "bgp_password"
}
```

### 获取BGP会话详情

```http
GET /api/v1/bgp/sessions/{session_id}
Authorization: Bearer <access_token>
```

### 更新BGP会话

```http
PUT /api/v1/bgp/sessions/{session_id}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "Updated BGP Session",
  "password": "new_password"
}
```

### 删除BGP会话

```http
DELETE /api/v1/bgp/sessions/{session_id}
Authorization: Bearer <access_token>
```

## IPv6管理

### 获取IPv6子网列表

```http
GET /api/v1/ipv6/subnets
Authorization: Bearer <access_token>
```

### 创建IPv6子网

```http
POST /api/v1/ipv6/subnets
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "subnet": "2001:db8::/64",
  "description": "Main IPv6 Subnet"
}
```

### 获取IPv6地址分配

```http
GET /api/v1/ipv6/allocations
Authorization: Bearer <access_token>
```

## 系统监控

### 获取监控仪表板数据

```http
GET /api/v1/monitoring/dashboard
Authorization: Bearer <access_token>
```

**响应示例:**
```json
{
  "success": true,
  "data": {
    "system": {
      "cpu_usage": 45.2,
      "memory_usage": 67.8,
      "disk_usage": 23.1,
      "load_average": [1.2, 1.5, 1.8]
    },
    "network": {
      "interfaces": [
        {
          "name": "eth0",
          "bytes_sent": 1024000,
          "bytes_received": 2048000,
          "packets_sent": 1000,
          "packets_received": 2000
        }
      ]
    },
    "wireguard": {
      "servers": 2,
      "clients": 15,
      "total_traffic": 3072000
    }
  }
}
```

### 获取系统指标

```http
GET /api/v1/monitoring/metrics
Authorization: Bearer <access_token>
```

### 获取网络统计

```http
GET /api/v1/monitoring/network
Authorization: Bearer <access_token>
```

## 异常监控

### 获取异常摘要

```http
GET /api/v1/exceptions/summary
Authorization: Bearer <access_token>
```

**响应示例:**
```json
{
  "success": true,
  "data": {
    "total_exceptions": 25,
    "unique_exceptions": 8,
    "recent_hour_count": 3,
    "recent_day_count": 15,
    "error_code_counts": {
      "VALIDATION_ERROR": 10,
      "AUTHENTICATION_ERROR": 5,
      "INTERNAL_SERVER_ERROR": 3
    },
    "last_updated": "2024-01-01T12:00:00Z"
  }
}
```

### 获取最频繁异常

```http
GET /api/v1/exceptions/top?limit=10
Authorization: Bearer <access_token>
```

### 获取最近异常

```http
GET /api/v1/exceptions/recent?limit=50
Authorization: Bearer <access_token>
```

## 告警管理

### 获取活跃告警

```http
GET /api/v1/alerts/active
Authorization: Bearer <access_token>
```

**响应示例:**
```json
{
  "success": true,
  "data": [
    {
      "id": "alert_1234567890_high_frequency_exceptions",
      "title": "系统异常频率过高",
      "description": "系统在过去一小时内产生了大量异常",
      "severity": "high",
      "status": "active",
      "created_at": "2024-01-01T12:00:00Z",
      "metadata": {
        "rule": {
          "name": "高频率异常",
          "condition": {
            "recent_hour_count": {
              "threshold": 100,
              "operator": ">"
            }
          }
        },
        "summary": {
          "recent_hour_count": 150
        }
      }
    }
  ]
}
```

### 确认告警

```http
POST /api/v1/alerts/{alert_id}/acknowledge
Authorization: Bearer <access_token>
```

### 解决告警

```http
POST /api/v1/alerts/{alert_id}/resolve
Authorization: Bearer <access_token>
```

## 日志管理

### 获取日志列表

```http
GET /api/v1/logs
Authorization: Bearer <access_token>
```

**查询参数:**
- `level`: 日志级别过滤
- `service`: 服务过滤
- `start_time`: 开始时间
- `end_time`: 结束时间
- `page`: 页码
- `size`: 每页数量

### 获取日志详情

```http
GET /api/v1/logs/{log_id}
Authorization: Bearer <access_token>
```

## 网络管理

### 获取网络接口列表

```http
GET /api/v1/network/interfaces
Authorization: Bearer <access_token>
```

### 获取路由表

```http
GET /api/v1/network/routes
Authorization: Bearer <access_token>
```

### 获取ARP表

```http
GET /api/v1/network/arp
Authorization: Bearer <access_token>
```

## 审计日志

### 获取审计日志列表

```http
GET /api/v1/audit/logs
Authorization: Bearer <access_token>
```

**查询参数:**
- `user_id`: 用户ID过滤
- `action`: 操作类型过滤
- `resource`: 资源类型过滤
- `start_time`: 开始时间
- `end_time`: 结束时间

## 文件上传

### 上传配置文件

```http
POST /api/v1/upload/config
Authorization: Bearer <access_token>
Content-Type: multipart/form-data

file: <config_file>
```

### 上传证书文件

```http
POST /api/v1/upload/certificate
Authorization: Bearer <access_token>
Content-Type: multipart/form-data

file: <certificate_file>
```

## API路径构建器

### 概述

API路径构建器提供了一种统一的方式来管理API端点路径，确保前后端路径一致性。它支持模块化路径定义、参数替换和版本控制。

### 基本用法

#### 后端使用 (PHP)

```php
// 引入API路径构建器
require_once __DIR__ . '/includes/ApiPathBuilder/ApiPathBuilder.php';

// 获取路径构建器实例
$pathBuilder = ApiPathBuilder::getInstance();

// 获取API路径
$loginPath = $pathBuilder->getPath('auth.login'); // 返回: /api/v1/auth/login
$serverPath = $pathBuilder->getPath('wireguard.servers.list'); // 返回: /api/v1/wireguard/servers

// 获取完整URL
$fullUrl = $pathBuilder->getUrl('wireguard.clients.create', ['server_id' => 123]);
// 返回: http://localhost:8000/api/v1/wireguard/servers/123/clients

// 带参数替换
$peerPath = $pathBuilder->getPath('wireguard.peers.detail', ['peer_id' => 'abc123']);
// 返回: /api/v1/wireguard/peers/abc123
```

#### 前端使用 (JavaScript)

```javascript
// 引入API路径构建器
import ApiPathBuilder from './includes/ApiPathBuilder/ApiPathBuilder.js';

// 获取路径构建器实例
const pathBuilder = ApiPathBuilder.getInstance();

// 获取API路径
const loginPath = pathBuilder.getPath('auth.login'); // 返回: /api/v1/auth/login
const serverPath = pathBuilder.getPath('wireguard.servers.list'); // 返回: /api/v1/wireguard/servers

// 获取完整URL
const fullUrl = pathBuilder.getUrl('wireguard.clients.create', { server_id: 123 });
// 返回: http://localhost:8000/api/v1/wireguard/servers/123/clients

// 带参数替换
const peerPath = pathBuilder.getPath('wireguard.peers.detail', { peer_id: 'abc123' });
// 返回: /api/v1/wireguard/peers/abc123
```

### 可用路径

#### 认证路径
- `auth.login` - `/api/v1/auth/login`
- `auth.refresh` - `/api/v1/auth/refresh`
- `auth.logout` - `/api/v1/auth/logout`

#### 用户管理路径
- `users.list` - `/api/v1/users`
- `users.create` - `/api/v1/users`
- `users.detail` - `/api/v1/users/{user_id}`
- `users.update` - `/api/v1/users/{user_id}`
- `users.delete` - `/api/v1/users/{user_id}`

#### WireGuard服务器路径
- `wireguard.servers.list` - `/api/v1/wireguard/servers`
- `wireguard.servers.create` - `/api/v1/wireguard/servers`
- `wireguard.servers.detail` - `/api/v1/wireguard/servers/{server_id}`
- `wireguard.servers.update` - `/api/v1/wireguard/servers/{server_id}`
- `wireguard.servers.delete` - `/api/v1/wireguard/servers/{server_id}`
- `wireguard.servers.start` - `/api/v1/wireguard/servers/{server_id}/start`
- `wireguard.servers.stop` - `/api/v1/wireguard/servers/{server_id}/stop`
- `wireguard.servers.restart` - `/api/v1/wireguard/servers/{server_id}/restart`
- `wireguard.servers.config` - `/api/v1/wireguard/servers/{server_id}/config`

#### WireGuard客户端路径
- `wireguard.clients.list` - `/api/v1/wireguard/servers/{server_id}/clients`
- `wireguard.clients.create` - `/api/v1/wireguard/servers/{server_id}/clients`
- `wireguard.clients.detail` - `/api/v1/wireguard/clients/{client_id}`
- `wireguard.clients.update` - `/api/v1/wireguard/clients/{client_id}`
- `wireguard.clients.delete` - `/api/v1/wireguard/clients/{client_id}`
- `wireguard.clients.config` - `/api/v1/wireguard/clients/{client_id}/config`

#### WireGuard对等节点路径
- `wireguard.peers.list` - `/api/v1/wireguard/servers/{server_id}/peers`
- `wireguard.peers.create` - `/api/v1/wireguard/servers/{server_id}/peers`
- `wireguard.peers.detail` - `/api/v1/wireguard/peers/{peer_id}`
- `wireguard.peers.update` - `/api/v1/wireguard/peers/{peer_id}`
- `wireguard.peers.delete` - `/api/v1/wireguard/peers/{peer_id}`
- `wireguard.peers.sync` - `/api/v1/wireguard/servers/{server_id}/peers/sync`

#### 系统监控路径
- `monitoring.status` - `/api/v1/monitoring/status`
- `monitoring.metrics` - `/api/v1/monitoring/metrics`
- `monitoring.logs` - `/api/v1/monitoring/logs`
- `monitoring.alerts` - `/api/v1/monitoring/alerts`

#### 系统设置路径
- `settings.general` - `/api/v1/settings/general`
- `settings.security` - `/api/v1/settings/security`
- `settings.network` - `/api/v1/settings/network`
- `settings.backup` - `/api/v1/settings/backup`

#### 文件上传路径
- `upload.config` - `/api/v1/upload/config`
- `upload.certificate` - `/api/v1/upload/certificate`

#### WebSocket路径
- `ws.monitoring` - `ws://localhost:8000/api/v1/ws/monitoring`
- `ws.logs` - `ws://localhost:8000/api/v1/ws/logs`

### 高级用法

#### 批量获取路径

```php
// PHP示例
$paths = $pathBuilder->getPaths([
    'auth.login',
    'wireguard.servers.list',
    'users.list'
]);
// 返回: [
//   'auth.login' => '/api/v1/auth/login',
//   'wireguard.servers.list' => '/api/v1/wireguard/servers',
//   'users.list' => '/api/v1/users'
// ]
```

```javascript
// JavaScript示例
const paths = pathBuilder.getPaths([
    'auth.login',
    'wireguard.servers.list',
    'users.list'
]);
// 返回: {
//   'auth.login': '/api/v1/auth/login',
//   'wireguard.servers.list': '/api/v1/wireguard/servers',
//   'users.list': '/api/v1/users'
// }
```

#### 获取所有路径

```php
// PHP示例
$allPaths = $pathBuilder->getAllPaths();
// 返回所有可用路径的关联数组
```

```javascript
// JavaScript示例
const allPaths = pathBuilder.getAllPaths();
// 返回所有可用路径的对象
```

#### 设置基础URL

```php
// PHP示例
$pathBuilder->setBaseUrl('https://api.example.com');
$url = $pathBuilder->getUrl('auth.login');
// 返回: https://api.example.com/api/v1/auth/login
```

```javascript
// JavaScript示例
pathBuilder.setBaseUrl('https://api.example.com');
const url = pathBuilder.getUrl('auth.login');
// 返回: https://api.example.com/api/v1/auth/login
```

### 优势

1. **一致性**: 确保前后端使用相同的API路径
2. **可维护性**: 集中管理所有API路径，便于修改和维护
3. **类型安全**: 使用预定义的路径键，减少拼写错误
4. **参数替换**: 自动处理路径参数，避免手动拼接
5. **版本控制**: 支持API版本管理，便于升级

## WebSocket连接

### 实时监控连接

```javascript
const ws = new WebSocket('ws://localhost:8000/api/v1/ws/monitoring');

ws.onmessage = function(event) {
  const data = JSON.parse(event.data);
  console.log('监控数据:', data);
};
```

### 实时日志连接

```javascript
const ws = new WebSocket('ws://localhost:8000/api/v1/ws/logs');

ws.onmessage = function(event) {
  const log = JSON.parse(event.data);
  console.log('日志:', log);
};
```

## 错误处理

### 错误响应格式

所有API错误都遵循统一的响应格式：

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述",
    "details": {
      "field": "具体错误详情"
    },
    "request_id": "req_1234567890",
    "timestamp": "2024-01-01T12:00:00Z"
  }
}
```

### 常见错误码

| 错误码 | HTTP状态码 | 描述 |
|--------|------------|------|
| `BAD_REQUEST` | 400 | 请求参数错误 |
| `UNAUTHORIZED` | 401 | 未授权访问 |
| `FORBIDDEN` | 403 | 权限不足 |
| `NOT_FOUND` | 404 | 资源不存在 |
| `CONFLICT` | 409 | 资源冲突 |
| `VALIDATION_ERROR` | 422 | 验证失败 |
| `INTERNAL_SERVER_ERROR` | 500 | 内部服务器错误 |
| `SERVICE_UNAVAILABLE` | 503 | 服务不可用 |

### 速率限制

API请求受到速率限制保护：

- **认证接口**: 每分钟最多5次请求
- **一般接口**: 每分钟最多100次请求
- **上传接口**: 每分钟最多10次请求

超出限制时返回429状态码：

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "请求过于频繁",
    "retry_after": 60
  }
}
```

## 版本控制

API支持版本控制，当前版本为v1：

- **当前版本**: `/api/v1`
- **版本头**: `API-Version: v1`
- **弃用通知**: 通过响应头`X-API-Deprecated`通知

## 最佳实践

### 1. 认证
- 始终在请求头中包含有效的Bearer Token
- 定期刷新访问令牌
- 安全存储令牌，避免在日志中泄露

### 2. 错误处理
- 检查响应状态码
- 处理所有可能的错误情况
- 使用错误码进行条件判断

### 3. 分页
- 使用分页参数处理大量数据
- 设置合理的页面大小
- 实现无限滚动或分页导航

### 4. 缓存
- 合理使用HTTP缓存头
- 实现客户端缓存策略
- 避免频繁请求相同数据

### 5. 监控
- 监控API响应时间
- 跟踪错误率和成功率
- 设置告警阈值

## SDK和工具

### Python SDK
```python
from ipv6_wireguard_manager import WireGuardManager

client = WireGuardManager(
    base_url="http://localhost:8000/api/v1",
    token="your_access_token"
)

# 获取服务器列表
servers = client.wireguard.servers.list()

# 创建客户端
client.wireguard.clients.create({
    "name": "New Client",
    "server_id": 1
})
```

### JavaScript SDK
```javascript
import { WireGuardManager } from 'ipv6-wireguard-manager-sdk';

const client = new WireGuardManager({
  baseURL: 'http://localhost:8000/api/v1',
  token: 'your_access_token'
});

// 获取服务器列表
const servers = await client.wireguard.servers.list();

// 创建客户端
await client.wireguard.clients.create({
  name: 'New Client',
  serverId: 1
});
```

### cURL示例
```bash
# 获取服务器列表
curl -H "Authorization: Bearer your_token" \
     http://localhost:8000/api/v1/wireguard/servers

# 创建客户端
curl -X POST \
     -H "Authorization: Bearer your_token" \
     -H "Content-Type: application/json" \
     -d '{"name":"New Client","server_id":1}' \
     http://localhost:8000/api/v1/wireguard/clients
```

---

**注意**: 本文档基于API v1版本，如有更新请查看最新版本文档。
