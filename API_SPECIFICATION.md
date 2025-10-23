# IPv6 WireGuard Manager - API规范文档

## 版本信息
- **API版本**: v1
- **基础路径**: `/api/v1`
- **文档路径**: `/docs` (Swagger UI), `/redoc` (ReDoc)

---

## 统一响应格式

所有API端点必须遵循以下统一响应格式：

### 成功响应

```json
{
  "success": true,
  "data": <响应数据>,
  "message": "操作成功"
}
```

### 错误响应

```json
{
  "success": false,
  "error": "ERROR_CODE",
  "detail": "详细错误信息",
  "message": "操作失败"
}
```

### 分页响应

```json
{
  "success": true,
  "data": [<数据列表>],
  "total": 100,
  "page": 1,
  "page_size": 20,
  "total_pages": 5
}
```

---

## 认证机制

### JWT Bearer Token

所有需要认证的请求必须在Header中包含：

```
Authorization: Bearer <access_token>
```

### 令牌生命周期

- **访问令牌(access_token)**: 30分钟
- **刷新令牌(refresh_token)**: 7天

### 认证端点

#### 1. 登录

**端点**: `POST /api/v1/auth/login` 或 `POST /api/v1/auth/login-json`

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
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "token_type": "bearer",
    "expires_in": 1800,
    "user": {
      "id": "1",
      "username": "admin",
      "email": "admin@example.com",
      "is_active": true,
      "is_superuser": true
    }
  }
}
```

#### 2. 刷新令牌

**端点**: `POST /api/v1/auth/refresh-json`

**请求体**:
```json
{
  "refresh_token": "eyJ..."
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "token_type": "bearer",
    "expires_in": 1800
  }
}
```

#### 3. 登出

**端点**: `POST /api/v1/auth/logout`

**响应**:
```json
{
  "success": true,
  "message": "登出成功"
}
```

---

## 错误代码

| 错误代码 | HTTP状态码 | 说明 |
|---------|-----------|------|
| `VALIDATION_ERROR` | 422 | 请求参数验证失败 |
| `AUTHENTICATION_ERROR` | 401 | 认证失败 |
| `AUTHORIZATION_ERROR` | 403 | 权限不足 |
| `NOT_FOUND` | 404 | 资源不存在 |
| `CONFLICT` | 409 | 资源冲突 |
| `INTERNAL_ERROR` | 500 | 服务器内部错误 |
| `DATABASE_ERROR` | 500 | 数据库错误 |
| `NETWORK_ERROR` | 503 | 网络错误 |

---

## 资源端点

### 用户管理 (/api/v1/users)

#### 获取用户列表
- **方法**: GET
- **路径**: `/api/v1/users`
- **参数**: 
  - `page`: 页码 (默认: 1)
  - `page_size`: 每页数量 (默认: 20)
  - `search`: 搜索关键字
- **响应**: 分页响应

#### 获取用户详情
- **方法**: GET
- **路径**: `/api/v1/users/{user_id}`
- **响应**: 成功响应 (data为用户对象)

#### 创建用户
- **方法**: POST
- **路径**: `/api/v1/users`
- **请求体**:
  ```json
  {
    "username": "newuser",
    "email": "user@example.com",
    "password": "password123",
    "is_active": true
  }
  ```

#### 更新用户
- **方法**: PUT
- **路径**: `/api/v1/users/{user_id}`
- **请求体**: 部分或全部用户字段

#### 删除用户
- **方法**: DELETE
- **路径**: `/api/v1/users/{user_id}`

---

### WireGuard管理 (/api/v1/wireguard)

#### 服务器列表
- **方法**: GET
- **路径**: `/api/v1/wireguard/servers`

#### 客户端列表
- **方法**: GET
- **路径**: `/api/v1/wireguard/clients`

#### 创建服务器
- **方法**: POST
- **路径**: `/api/v1/wireguard/servers`

#### 创建客户端
- **方法**: POST
- **路径**: `/api/v1/wireguard/clients`

---

### 监控 (/api/v1/monitoring)

#### 获取系统指标
- **方法**: GET
- **路径**: `/api/v1/monitoring/metrics`

#### 获取服务状态
- **方法**: GET
- **路径**: `/api/v1/monitoring/services`

---

## 前端集成指南

### 配置API基础URL

在 `php-frontend/config/config.php` 中：

```php
// ✅ 正确配置（不含版本路径）
define('API_BASE_URL', 'http://localhost:8000');

// ❌ 错误配置（包含版本路径会导致双重前缀）
// define('API_BASE_URL', 'http://localhost:8000/api/v1');
```

### 调用API示例

```php
// 前端会自动添加 /api/v1 前缀
$apiClient = new ApiClientJWT();

// GET请求 - 实际URL: http://localhost:8000/api/v1/users
$users = $apiClient->get('/users');

// POST请求 - 实际URL: http://localhost:8000/api/v1/users
$newUser = $apiClient->post('/users', $userData);

// 根级端点（不添加前缀）- 实际URL: http://localhost:8000/health
$health = $apiClient->get('/health');
```

---

## 数据类型

### 枚举类型

#### WireGuardStatus
- `active`: 活跃
- `inactive`: 非活跃
- `pending`: 待处理
- `error`: 错误

#### BGPStatus
- `established`: 已建立
- `idle`: 空闲
- `connect`: 连接中
- `active`: 活跃
- `opensent`: 已发送OPEN
- `openconfirm`: 已确认OPEN

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

---

## 最佳实践

### 1. 错误处理

前端应统一处理API响应：

```php
try {
    $response = $apiClient->get('/users');
    
    if (isset($response['success']) && $response['success']) {
        // 成功处理
        $data = $response['data'];
    } else {
        // 错误处理
        $error = $response['error'] ?? 'UNKNOWN_ERROR';
        $detail = $response['detail'] ?? '未知错误';
    }
} catch (Exception $e) {
    // 异常处理
    log_error($e->getMessage());
}
```

### 2. 分页处理

```php
$page = $_GET['page'] ?? 1;
$pageSize = $_GET['page_size'] ?? 20;

$response = $apiClient->get('/users', [
    'page' => $page,
    'page_size' => $pageSize
]);

$users = $response['data'];
$total = $response['total'];
$totalPages = $response['total_pages'];
```

### 3. 认证令牌管理

```php
// 登录时保存令牌
$loginResponse = $apiClient->post('/auth/login-json', [
    'username' => $username,
    'password' => $password
]);

if ($loginResponse['success']) {
    $accessToken = $loginResponse['data']['access_token'];
    $refreshToken = $loginResponse['data']['refresh_token'];
    
    // ApiClientJWT会自动保存到session
    $_SESSION['access_token'] = $accessToken;
    $_SESSION['refresh_token'] = $refreshToken;
}

// 令牌过期时自动刷新
// ApiClientJWT会自动处理令牌刷新
```

---

## 版本控制

### URL版本控制

当前版本: **v1**

所有API端点都在 `/api/v1` 路径下。

未来版本（v2）将在 `/api/v2` 路径下，保持向后兼容。

### 变更日志

#### v1.0.0 (当前)
- 初始API版本
- 用户管理
- WireGuard管理
- BGP路由管理
- IPv6地址管理
- 监控和日志
- JWT认证

---

## 支持与联系

- **文档地址**: `/docs` (Swagger UI)
- **ReDoc地址**: `/redoc`
- **健康检查**: `/health`
- **API版本**: `/api/v1/`

---

**最后更新**: 2024年
**维护者**: IPv6 WireGuard Manager Team
