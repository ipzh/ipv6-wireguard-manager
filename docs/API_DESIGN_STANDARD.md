# IPv6 WireGuard Manager API设计标准

## 📋 概述

本文档定义了IPv6 WireGuard Manager的API设计标准，确保前后端API的一致性、可维护性和用户体验。

## 🎯 设计原则

### 1. RESTful设计
- 使用标准HTTP方法（GET、POST、PUT、DELETE）
- 资源导向的URL设计
- 状态码语义化
- 无状态通信

### 2. 一致性原则
- 统一的响应格式
- 一致的错误处理
- 标准化的分页和排序
- 统一的认证和授权

### 3. 可扩展性
- 版本化API设计
- 向后兼容性
- 模块化结构
- 清晰的接口定义

## 🔧 API规范

### 基础URL结构
```
https://api.example.com/api/v1/{resource}
```

### HTTP方法映射
| 操作 | HTTP方法 | 路径 | 描述 |
|------|----------|------|------|
| 列表 | GET | /{resource} | 获取资源列表 |
| 详情 | GET | /{resource}/{id} | 获取单个资源 |
| 创建 | POST | /{resource} | 创建新资源 |
| 更新 | PUT | /{resource}/{id} | 完全更新资源 |
| 部分更新 | PATCH | /{resource}/{id} | 部分更新资源 |
| 删除 | DELETE | /{resource}/{id} | 删除资源 |

### 标准响应格式

#### 成功响应
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

#### 错误响应
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

#### 分页响应
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

## 📊 资源设计

### 1. 认证资源 (auth)

#### 登录
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
  },
  "message": "登录成功"
}
```

#### 刷新令牌
```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

#### 登出
```http
POST /api/v1/auth/logout
Authorization: Bearer {access_token}
```

### 2. 用户资源 (users)

#### 获取用户列表
```http
GET /api/v1/users?page=1&per_page=20&search=admin
Authorization: Bearer {access_token}
```

#### 创建用户
```http
POST /api/v1/users
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "username": "newuser",
  "email": "user@example.com",
  "password": "password123",
  "role": "user"
}
```

### 3. WireGuard资源 (wireguard)

#### 获取服务器列表
```http
GET /api/v1/wireguard/servers
Authorization: Bearer {access_token}
```

#### 创建服务器
```http
POST /api/v1/wireguard/servers
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "name": "server1",
  "public_key": "public_key_here",
  "private_key": "private_key_here",
  "listen_port": 51820,
  "address": "10.0.0.1/24"
}
```

#### 获取客户端列表
```http
GET /api/v1/wireguard/clients
Authorization: Bearer {access_token}
```

#### 创建客户端
```http
POST /api/v1/wireguard/clients
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "name": "client1",
  "public_key": "client_public_key",
  "allowed_ips": "10.0.0.2/32",
  "server_id": 1
}
```

### 4. IPv6资源 (ipv6)

#### 获取地址池列表
```http
GET /api/v1/ipv6/pools
Authorization: Bearer {access_token}
```

#### 创建地址池
```http
POST /api/v1/ipv6/pools
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "name": "pool1",
  "network": "2001:db8::/64",
  "description": "IPv6地址池"
}
```

### 5. BGP资源 (bgp)

#### 获取BGP会话列表
```http
GET /api/v1/bgp/sessions
Authorization: Bearer {access_token}
```

#### 创建BGP会话
```http
POST /api/v1/bgp/sessions
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "name": "session1",
  "neighbor": "192.168.1.1",
  "remote_as": 65001,
  "local_as": 65000,
  "password": "bgp_password"
}
```

## 🔐 认证和授权

### JWT令牌认证
- 使用Bearer Token认证
- 访问令牌有效期：24小时
- 刷新令牌有效期：7天
- 令牌包含用户信息和权限

### 权限控制
- 基于角色的访问控制（RBAC）
- 资源级权限控制
- API端点权限验证

## 📝 错误处理

### 标准错误码
| 错误码 | HTTP状态 | 描述 |
|--------|----------|------|
| VALIDATION_ERROR | 400 | 请求参数验证失败 |
| AUTHENTICATION_ERROR | 401 | 认证失败 |
| AUTHORIZATION_ERROR | 403 | 权限不足 |
| NOT_FOUND | 404 | 资源不存在 |
| CONFLICT | 409 | 资源冲突 |
| INTERNAL_ERROR | 500 | 服务器内部错误 |

### 错误响应格式
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

## 📊 分页和排序

### 分页参数
- `page`: 页码（从1开始）
- `per_page`: 每页数量（默认20，最大100）
- `total`: 总数量
- `pages`: 总页数

### 排序参数
- `sort`: 排序字段
- `order`: 排序方向（asc/desc）

### 搜索参数
- `search`: 搜索关键词
- `filter`: 过滤条件

## 🔄 版本控制

### API版本策略
- 使用URL路径版本控制：`/api/v1/`
- 向后兼容性保证
- 废弃通知机制

### 版本生命周期
1. **开发阶段**: 内部测试
2. **测试阶段**: 公开测试
3. **稳定阶段**: 生产使用
4. **废弃阶段**: 维护模式
5. **废弃阶段**: 停止支持

## 📈 性能优化

### 响应时间要求
- 简单查询：< 100ms
- 复杂查询：< 500ms
- 数据操作：< 1000ms

### 缓存策略
- 静态数据：长期缓存
- 动态数据：短期缓存
- 用户数据：会话缓存

### 限流策略
- 认证用户：1000请求/小时
- 匿名用户：100请求/小时
- 管理操作：100请求/小时

## 🧪 测试标准

### 单元测试
- 覆盖率要求：> 80%
- 关键路径：100%覆盖
- 边界条件测试

### 集成测试
- API端点测试
- 数据库集成测试
- 第三方服务集成测试

### 性能测试
- 负载测试
- 压力测试
- 稳定性测试

## 📚 文档要求

### API文档
- 使用OpenAPI 3.0规范
- 提供交互式文档
- 包含示例和错误码

### 代码文档
- 函数和类注释
- 参数和返回值说明
- 使用示例

### 变更日志
- 版本变更记录
- 破坏性变更说明
- 迁移指南

## 🔧 实施指南

### 后端实施
1. 使用FastAPI框架
2. 实现统一的响应格式
3. 添加请求验证
4. 实现错误处理
5. 添加日志记录

### 前端实施
1. 使用统一的API客户端
2. 实现错误处理
3. 添加加载状态
4. 实现缓存机制
5. 添加重试逻辑

### 测试实施
1. 编写单元测试
2. 实现集成测试
3. 添加性能测试
4. 自动化测试流程

---

**版本**: 1.0.0  
**最后更新**: 2024-01-01  
**维护者**: IPv6 WireGuard Manager团队
