# IPv6 WireGuard Manager - API 完整参考文档

## 📋 API 概述

IPv6 WireGuard Manager 提供完整的 RESTful API，支持 IPv6 地址管理、WireGuard 配置、BGP 路由、用户管理等功能。

## 🔗 基础信息

### API 版本与路径

- **API 版本**: v1
- **基础路径**: `/api/v1`
- **基础 URL**: `http://localhost/api/v1`
- **认证方式**: JWT Bearer Token
- **数据格式**: JSON
- **字符编码**: UTF-8

### 交互式文档

- **Swagger UI**: `/docs`
- **ReDoc**: `/redoc`
- **健康检查**: `/health`

## 📐 统一响应格式

所有 API 端点必须遵循以下统一响应格式：

### 成功响应

```json
{
  "success": true,
  "data": <响应数据>,
  "message": "操作成功",
  "timestamp": 1640995200
}
```

### 错误响应

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "错误信息",
    "detail": "详细错误描述"
  },
  "timestamp": 1640995200
}
```

### 分页响应

```json
{
  "success": true,
  "data": [<数据列表>],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 100,
    "total_pages": 5
  },
  "message": "获取成功"
}
```

## 🔐 认证机制

### JWT Bearer Token

所有需要认证的请求必须在 Header 中包含：

```
Authorization: Bearer <access_token>
```

### 令牌生命周期

- **访问令牌 (access_token)**: 30分钟
- **刷新令牌 (refresh_token)**: 7天

### 认证端点

#### 1. 用户登录

**端点**: `POST /api/v1/auth/login`

**请求体**:
```json
{
  "username": "admin",
  "password": "password123"
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "token_type": "bearer",
    "expires_in": 1800,
    "user": {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com",
      "is_active": true,
      "is_superuser": true,
      "role": "admin"
    }
  },
  "message": "登录成功"
}
```

#### 2. 刷新令牌

**端点**: `POST /api/v1/auth/refresh`

**请求体**:
```json
{
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "token_type": "bearer",
    "expires_in": 1800
  },
  "message": "令牌刷新成功"
}
```

#### 3. 用户登出

**端点**: `POST /api/v1/auth/logout`

**Headers**:
```
Authorization: Bearer <access_token>
```

**响应**:
```json
{
  "success": true,
  "message": "登出成功"
}
```

#### 4. 获取当前用户信息

**端点**: `GET /api/v1/auth/me`

**Headers**:
```
Authorization: Bearer <access_token>
```

**响应**:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "is_active": true,
    "is_superuser": true,
    "created_at": "2024-01-01T00:00:00Z",
    "roles": ["admin"]
  }
}
```

## 📊 核心 API 端点

### 用户管理 (/api/v1/users)

#### 获取用户列表

**端点**: `GET /api/v1/users`

**查询参数**:
- `page`: 页码 (默认: 1)
- `per_page`: 每页数量 (默认: 20, 最大: 100)
- `search`: 搜索关键字
- `is_active`: 是否激活 (true/false)

**响应**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com",
      "is_active": true,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 50,
    "total_pages": 3
  }
}
```

#### 创建用户

**端点**: `POST /api/v1/users`

**请求体**:
```json
{
  "username": "newuser",
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "is_active": true,
  "is_superuser": false
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "id": 2,
    "username": "newuser",
    "email": "user@example.com",
    "is_active": true,
    "created_at": "2024-01-01T12:00:00Z"
  },
  "message": "用户创建成功"
}
```

#### 获取用户详情

**端点**: `GET /api/v1/users/{id}`

**响应**: 成功响应 (data 为用户对象)

#### 更新用户

**端点**: `PUT /api/v1/users/{id}`

**请求体**: 部分或全部用户字段

#### 删除用户

**端点**: `DELETE /api/v1/users/{id}`

### WireGuard 管理 (/api/v1/wireguard)

#### 服务器列表

**端点**: `GET /api/v1/wireguard/servers`

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `status`: 服务器状态 (active/inactive/pending)

**响应**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "server1",
      "public_key": "...",
      "listen_port": 51820,
      "address": "10.0.0.1/24",
      "status": "active",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

#### 创建服务器

**端点**: `POST /api/v1/wireguard/servers`

**请求体**:
```json
{
  "name": "server1",
  "public_key": "public_key_here",
  "private_key": "private_key_here",
  "listen_port": 51820,
  "address": "10.0.0.1/24",
  "dns": "1.1.1.1,8.8.8.8"
}
```

#### 客户端列表

**端点**: `GET /api/v1/wireguard/clients`

#### 创建客户端

**端点**: `POST /api/v1/wireguard/clients`

**请求体**:
```json
{
  "name": "client1",
  "public_key": "client_public_key",
  "allowed_ips": "10.0.0.2/32",
  "server_id": 1
}
```

#### 服务器操作

- **启动**: `POST /api/v1/wireguard/servers/{id}/start`
- **停止**: `POST /api/v1/wireguard/servers/{id}/stop`
- **重启**: `POST /api/v1/wireguard/servers/{id}/restart`
- **状态**: `GET /api/v1/wireguard/servers/{id}/status`

### IPv6 地址管理 (/api/v1/ipv6)

#### 获取地址池列表

**端点**: `GET /api/v1/ipv6/pools`

**响应**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "pool1",
      "network": "2001:db8::/64",
      "status": "active",
      "allocated": 10,
      "available": 1000,
      "description": "IPv6地址池"
    }
  ]
}
```

#### 创建地址池

**端点**: `POST /api/v1/ipv6/pools`

**请求体**:
```json
{
  "name": "pool1",
  "network": "2001:db8::/64",
  "description": "IPv6地址池"
}
```

#### 获取地址分配

**端点**: `GET /api/v1/ipv6/allocations`

#### 创建地址分配

**端点**: `POST /api/v1/ipv6/allocations`

**请求体**:
```json
{
  "pool_id": 1,
  "address": "2001:db8::1",
  "client_id": 1,
  "description": "客户端IP分配"
}
```

### BGP 路由管理 (/api/v1/bgp)

#### 获取 BGP 会话列表

**端点**: `GET /api/v1/bgp/sessions`

**响应**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "session1",
      "neighbor": "192.168.1.1",
      "remote_as": 65001,
      "local_as": 65000,
      "status": "established",
      "uptime": 3600
    }
  ]
}
```

#### 创建 BGP 会话

**端点**: `POST /api/v1/bgp/sessions`

**请求体**:
```json
{
  "name": "session1",
  "neighbor": "192.168.1.1",
  "remote_as": 65001,
  "local_as": 65000,
  "password": "bgp_password",
  "description": "BGP会话"
}
```

#### BGP 公告管理

- **列表**: `GET /api/v1/bgp/announcements`
- **创建**: `POST /api/v1/bgp/announcements`
- **详情**: `GET /api/v1/bgp/announcements/{id}`
- **更新**: `PUT /api/v1/bgp/announcements/{id}`
- **删除**: `DELETE /api/v1/bgp/announcements/{id}`

### 系统管理 (/api/v1/system)

#### 系统信息

**端点**: `GET /api/v1/system/info`

**响应**:
```json
{
  "success": true,
  "data": {
    "version": "1.0.0",
    "python_version": "3.11.0",
    "os": "Linux 5.15.0",
    "cpu_count": 4,
    "memory_total": 8589934592
  }
}
```

#### 健康检查

**端点**: `GET /api/v1/health` 或 `GET /health`

**响应**:
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "database": "connected",
    "redis": "connected",
    "timestamp": 1640995200
  }
}
```

#### 系统指标

**端点**: `GET /api/v1/system/metrics`

**响应**:
```json
{
  "success": true,
  "data": {
    "cpu_percent": 45.2,
    "memory_percent": 62.5,
    "disk_percent": 35.8,
    "network_in": 1024000,
    "network_out": 2048000
  }
}
```

### 监控 (/api/v1/monitoring)

#### 仪表盘数据

**端点**: `GET /api/v1/monitoring/dashboard`

**响应**:
```json
{
  "success": true,
  "data": {
    "servers_total": 10,
    "servers_active": 8,
    "clients_total": 50,
    "clients_active": 42,
    "traffic_in": 1073741824,
    "traffic_out": 2147483648
  }
}
```

#### 监控指标

**端点**: `GET /api/v1/monitoring/metrics`

#### 告警列表

**端点**: `GET /api/v1/monitoring/alerts`

### 日志管理 (/api/v1/logs)

#### 获取日志列表

**端点**: `GET /api/v1/logs`

**查询参数**:
- `level`: 日志级别 (debug/info/warning/error/critical)
- `start_time`: 开始时间
- `end_time`: 结束时间
- `page`: 页码
- `per_page`: 每页数量

**响应**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "level": "info",
      "message": "系统启动成功",
      "timestamp": "2024-01-01T00:00:00Z",
      "module": "main"
    }
  ]
}
```

#### 搜索日志

**端点**: `GET /api/v1/logs/search`

**查询参数**:
- `query`: 搜索关键字
- `level`: 日志级别
- `start_time`: 开始时间
- `end_time`: 结束时间

## 🔧 错误处理

### HTTP 状态码

| 状态码 | 说明 |
|--------|------|
| 200 | 请求成功 |
| 201 | 创建成功 |
| 400 | 请求参数错误 |
| 401 | 认证失败/令牌无效 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 409 | 资源冲突 |
| 422 | 请求参数验证失败 |
| 500 | 服务器内部错误 |
| 503 | 服务不可用 |

### 错误代码

| 错误代码 | 说明 |
|---------|------|
| `VALIDATION_ERROR` | 请求参数验证失败 |
| `AUTHENTICATION_ERROR` | 认证失败 |
| `AUTHORIZATION_ERROR` | 权限不足 |
| `NOT_FOUND` | 资源不存在 |
| `CONFLICT` | 资源冲突 |
| `INTERNAL_ERROR` | 服务器内部错误 |
| `DATABASE_ERROR` | 数据库错误 |
| `NETWORK_ERROR` | 网络错误 |

### 错误响应示例

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "请求参数验证失败",
    "details": [
      {
        "field": "username",
        "message": "用户名不能为空"
      },
      {
        "field": "email",
        "message": "邮箱格式不正确"
      }
    ]
  },
  "timestamp": 1640995200
}
```

## 📦 数据类型

### 枚举类型

#### WireGuardStatus
- `active`: 活跃
- `inactive`: 非活跃
- `pending`: 待处理
- `error`: 错误

#### BGPStatus
- `idle`: 空闲
- `connect`: 连接中
- `active`: 活跃
- `opensent`: 已发送OPEN
- `openconfirm`: 已确认OPEN
- `established`: 已建立

#### IPv6PoolStatus
- `active`: 活跃
- `inactive`: 非活跃
- `depleted`: 已耗尽

#### LogLevel
- `debug`: 调试
- `info`: 信息
- `warning`: 警告
- `error`: 错误
- `critical`: 严重

## 🔒 安全特性

### 认证机制
- JWT 令牌认证
- 令牌自动刷新机制
- 会话管理

### 权限控制
- 基于角色的访问控制 (RBAC)
- 资源级权限控制
- API 端点权限验证

### 安全头
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security: max-age=31536000`

### 速率限制
- 登录: 5次/分钟
- 一般请求: 60次/分钟
- 敏感操作: 10次/分钟

## 📈 最佳实践

### 1. 错误处理

前端应统一处理 API 响应：

```javascript
try {
  const response = await apiClient.get('/users');
  
  if (response.success) {
    // 成功处理
    const data = response.data;
  } else {
    // 错误处理
    const error = response.error.code;
    const message = response.error.message;
    console.error(`错误: ${error} - ${message}`);
  }
} catch (error) {
  // 异常处理
  console.error('请求失败:', error);
}
```

### 2. 分页处理

```javascript
const page = 1;
const perPage = 20;

const response = await apiClient.get('/users', {
  page: page,
  per_page: perPage
});

const users = response.data;
const total = response.pagination.total;
const totalPages = response.pagination.total_pages;
```

### 3. 认证令牌管理

```javascript
// 登录并保存令牌
const loginResponse = await apiClient.post('/auth/login', {
  username: 'admin',
  password: 'password'
});

if (loginResponse.success) {
  localStorage.setItem('access_token', loginResponse.data.access_token);
  localStorage.setItem('refresh_token', loginResponse.data.refresh_token);
}

// 自动刷新令牌
apiClient.interceptors.response.use(
  response => response,
  async error => {
    if (error.response?.status === 401) {
      // 令牌过期，尝试刷新
      const refreshToken = localStorage.getItem('refresh_token');
      const refreshResponse = await apiClient.post('/auth/refresh', {
        refresh_token: refreshToken
      });
      
      if (refreshResponse.success) {
        localStorage.setItem('access_token', refreshResponse.data.access_token);
        // 重试原请求
        return apiClient.request(error.config);
      }
    }
    return Promise.reject(error);
  }
);
```

## 🧪 测试

### 使用 cURL

```bash
# 健康检查
curl -X GET http://localhost/api/v1/health

# 用户登录
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "password"}'

# 获取用户列表（需要令牌）
curl -X GET http://localhost/api/v1/users \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# 创建 WireGuard 服务器
curl -X POST http://localhost/api/v1/wireguard/servers \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "server1", "listen_port": 51820}'
```

### 使用 Python

```python
import requests

# 登录
response = requests.post('http://localhost/api/v1/auth/login', json={
    'username': 'admin',
    'password': 'password'
})
token = response.json()['data']['access_token']

# 获取用户列表
headers = {'Authorization': f'Bearer {token}'}
response = requests.get('http://localhost/api/v1/users', headers=headers)
users = response.json()['data']
```

## 📚 相关文档

- [API 设计标准](API_DESIGN_STANDARD.md) - API 设计规范
- [部署指南](DEPLOYMENT_GUIDE.md) - 生产环境部署
- [安全指南](SECURITY_GUIDE.md) - 安全配置说明
- [开发者指南](DEVELOPER_GUIDE.md) - 开发环境搭建

## 🔄 版本控制

### URL 版本控制

当前版本: **v1**

所有 API 端点都在 `/api/v1` 路径下。

未来版本（v2）将在 `/api/v2` 路径下，保持向后兼容。

### 变更日志

#### v1.0.0 (当前)
- 初始 API 版本
- 用户管理
- WireGuard 管理
- BGP 路由管理
- IPv6 地址管理
- 监控和日志
- JWT 认证

---

**API 版本**: v1.0.0  
**最后更新**: 2024-01-01  
**维护团队**: IPv6 WireGuard Manager Team
