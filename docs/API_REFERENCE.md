# IPv6 WireGuard Manager API 参考文档

## 📋 API概述

IPv6 WireGuard Manager提供完整的RESTful API，支持IPv6地址管理、WireGuard配置、BGP路由、用户管理等功能。

## 🔗 基础信息

- **基础URL**: `http://localhost/api/v1`
- **认证方式**: JWT Bearer Token
- **数据格式**: JSON
- **字符编码**: UTF-8

## 🔐 认证

### 获取访问令牌
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "password123"
}
```

**响应:**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "token_type": "bearer",
    "expires_in": 86400,
    "user": {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com",
      "role": "admin"
    }
  }
}
```

### 使用访问令牌
```http
GET /api/v1/users
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

## 📊 核心API端点

### 用户管理
- `GET /api/v1/users` - 获取用户列表
- `POST /api/v1/users` - 创建用户
- `GET /api/v1/users/{id}` - 获取用户详情
- `PUT /api/v1/users/{id}` - 更新用户
- `DELETE /api/v1/users/{id}` - 删除用户

### WireGuard管理
- `GET /api/v1/wireguard/servers` - 获取服务器列表
- `POST /api/v1/wireguard/servers` - 创建服务器
- `GET /api/v1/wireguard/servers/{id}` - 获取服务器详情
- `PUT /api/v1/wireguard/servers/{id}` - 更新服务器
- `DELETE /api/v1/wireguard/servers/{id}` - 删除服务器

### IPv6地址管理
- `GET /api/v1/ipv6/pools` - 获取地址池列表
- `POST /api/v1/ipv6/pools` - 创建地址池
- `GET /api/v1/ipv6/pools/{id}` - 获取地址池详情
- `PUT /api/v1/ipv6/pools/{id}` - 更新地址池
- `DELETE /api/v1/ipv6/pools/{id}` - 删除地址池

### BGP路由管理
- `GET /api/v1/bgp/sessions` - 获取BGP会话列表
- `POST /api/v1/bgp/sessions` - 创建BGP会话
- `GET /api/v1/bgp/sessions/{id}` - 获取BGP会话详情
- `PUT /api/v1/bgp/sessions/{id}` - 更新BGP会话
- `DELETE /api/v1/bgp/sessions/{id}` - 删除BGP会话

### 系统监控
- `GET /api/v1/health` - 健康检查
- `GET /api/v1/health/detailed` - 详细健康检查
- `GET /api/v1/metrics` - 系统指标
- `GET /api/v1/monitoring/dashboard` - 监控仪表盘

## 📝 请求示例

### 创建WireGuard服务器
```http
POST /api/v1/wireguard/servers
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "server1",
  "public_key": "public_key_here",
  "private_key": "private_key_here",
  "listen_port": 51820,
  "address": "10.0.0.1/24"
}
```

### 创建IPv6地址池
```http
POST /api/v1/ipv6/pools
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "pool1",
  "network": "2001:db8::/64",
  "description": "IPv6地址池"
}
```

### 创建BGP会话
```http
POST /api/v1/bgp/sessions
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "session1",
  "neighbor": "192.168.1.1",
  "remote_as": 65001,
  "local_as": 65000,
  "password": "bgp_password"
}
```

## 📤 响应格式

### 成功响应
```json
{
  "success": true,
  "data": {
    // 响应数据
  },
  "message": "操作成功",
  "timestamp": 1640995200
}
```

### 错误响应
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
      }
    ]
  },
  "timestamp": 1640995200
}
```

### 分页响应
```json
{
  "success": true,
  "data": {
    "items": [
      // 数据项列表
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 100,
      "pages": 5
    }
  },
  "message": "获取成功"
}
```

## 🔧 错误处理

### HTTP状态码
- `200` - 成功
- `201` - 创建成功
- `400` - 请求参数错误
- `401` - 认证失败
- `403` - 权限不足
- `404` - 资源不存在
- `409` - 资源冲突
- `422` - 验证错误
- `500` - 服务器内部错误

### 错误码说明
- `VALIDATION_ERROR` - 参数验证失败
- `AUTHENTICATION_ERROR` - 认证失败
- `AUTHORIZATION_ERROR` - 权限不足
- `NOT_FOUND` - 资源不存在
- `CONFLICT` - 资源冲突
- `INTERNAL_ERROR` - 服务器内部错误

## 🔒 安全特性

### 认证机制
- JWT令牌认证
- 令牌刷新机制
- 会话管理

### 权限控制
- 基于角色的访问控制（RBAC）
- 资源级权限控制
- API端点权限验证

### 安全头
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security: max-age=31536000`

## 📊 性能优化

### 缓存策略
- 静态数据长期缓存
- 动态数据短期缓存
- 用户数据会话缓存

### 分页查询
- 默认每页20条记录
- 最大每页100条记录
- 支持排序和过滤

### 响应时间
- 简单查询: < 100ms
- 复杂查询: < 500ms
- 数据操作: < 1000ms

## 🧪 测试

### API测试工具
- **Postman**: 推荐使用
- **Insomnia**: 轻量级选择
- **curl**: 命令行测试

### 测试示例
```bash
# 健康检查
curl -X GET http://localhost/api/v1/health

# 获取用户列表
curl -X GET http://localhost/api/v1/users   -H "Authorization: Bearer {token}"

# 创建WireGuard服务器
curl -X POST http://localhost/api/v1/wireguard/servers   -H "Authorization: Bearer {token}"   -H "Content-Type: application/json"   -d '{"name": "server1", "listen_port": 51820}'
```

## 📚 相关文档

- [API设计标准](API_DESIGN_STANDARD.md) - API设计规范
- [开发者指南](DEVELOPER_GUIDE.md) - 开发环境搭建
- [架构设计](ARCHITECTURE_DESIGN.md) - 系统架构说明
- [安全指南](SECURITY_GUIDE.md) - 安全配置说明

---

**API版本**: v1.0.0  
**最后更新**: 2024-01-01  
**维护团队**: IPv6 WireGuard Manager团队
