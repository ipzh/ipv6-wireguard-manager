# 登录问题修复说明

## 🔍 问题分析

用户报告使用 `admin` / `admin123` 登录时提示"用户名和密码错误"。

### 问题根源

前端调用的API端点与后端不匹配：

**前端代码** (`php-frontend/classes/Auth.php`):
```php
$response = $this->apiClient->post('/auth/login', [
    'username' => $username,
    'password' => $password
]);
```

**后端端点** (`backend/app/api/api_v1/endpoints/auth.py`):
- `/auth/login` - 需要 `OAuth2PasswordRequestForm`（表单格式）
- `/auth/login-json` - 接受 JSON 格式数据

### 问题说明

后端有两个登录端点：

1. **`POST /auth/login`** - 使用 `OAuth2PasswordRequestForm`
   - 期望表单数据：`username=admin&password=admin123`
   - Content-Type: `application/x-www-form-urlencoded`

2. **`POST /auth/login-json`** - 使用 JSON 格式
   - 期望 JSON 数据：`{"username": "admin", "password": "admin123"}`
   - Content-Type: `application/json`

前端的 `ApiClient` 使用 `json_encode()` 发送数据，所以应该调用 `/auth/login-json` 端点。

## ✅ 修复方案

修改 `php-frontend/classes/Auth.php` 中的登录方法：

```php
// 修改前
$response = $this->apiClient->post('/auth/login', [
    'username' => $username,
    'password' => $password
]);

// 修改后
$response = $this->apiClient->post('/auth/login-json', [
    'username' => $username,
    'password' => $password
]);
```

## 🎯 验证步骤

修复后，请按以下步骤验证：

1. **启动后端服务**（如果尚未启动）:
   ```bash
   cd backend
   uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```

2. **访问登录页面**:
   ```
   http://localhost/login
   ```

3. **使用默认凭据登录**:
   - 用户名: `admin`
   - 密码: `admin123`

4. **预期结果**:
   - ✅ 登录成功
   - ✅ 重定向到仪表板 (`/`)
   - ✅ 显示欢迎消息

## 📋 相关文件

### 已修改的文件
- ✅ `php-frontend/classes/Auth.php` - 修改登录API端点

### 相关文件（无需修改）
- `backend/app/api/api_v1/endpoints/auth.py` - 后端认证端点
- `php-frontend/controllers/AuthController.php` - 前端认证控制器
- `php-frontend/views/auth/login.php` - 登录页面
- `php-frontend/classes/ApiClient.php` - API客户端

## 🔒 默认凭据

系统默认管理员账户：

- **用户名**: `admin`
- **密码**: `admin123`

> ⚠️ **安全提示**: 首次登录后请立即修改默认密码！

## 💡 技术说明

### OAuth2PasswordRequestForm vs JSON

FastAPI 提供了两种登录方式：

1. **OAuth2PasswordRequestForm** - 标准 OAuth2 表单格式
   - 用于符合 OAuth2 规范的客户端
   - 数据格式: `application/x-www-form-urlencoded`

2. **JSON 格式** - 自定义 JSON 格式
   - 用于现代 Web 应用和 API 客户端
   - 数据格式: `application/json`

我们的前端使用 `ApiClient` 发送 JSON 数据，因此应该使用 `/auth/login-json` 端点。

## 🚀 后续建议

1. **修改默认密码**: 登录后访问 `/profile/change-password`
2. **创建新用户**: 管理员可以在 `/users` 页面创建新用户
3. **配置权限**: 在 `/users/{id}/permissions` 为用户分配权限

## 📝 总结

- **问题**: 前端调用了错误的API端点（`/auth/login` 而非 `/auth/login-json`）
- **修复**: 修改前端代码调用正确的JSON登录端点
- **状态**: ✅ 已修复
- **测试**: 请使用 `admin` / `admin123` 登录验证
