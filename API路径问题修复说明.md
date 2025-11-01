# API路径问题修复说明

## 📋 问题描述

用户反馈：
- ❌ API路径错误
- ❌ 检查的API地址是 `http://192.168.1.110/api/status`
- ❌ 应该是API路径配置错误

---

## 🔍 问题分析

### 1. API路径混淆 🔴

**问题**:
- 前端调用 `/api/status` - 这是PHP路由，应该由`AuthController@checkApiStatus`处理
- 但Nginx可能错误地将此路径代理到了后端
- 后端没有 `/api/status` 端点，只有 `/api/v1/health`

**当前架构**:
```
前端调用 /api/status
  ↓
Nginx处理
  ↓
应该：PHP路由处理 (AuthController@checkApiStatus)
   ↓
  检查后端 /api/v1/health

实际：可能被Nginx代理到了后端（错误）
```

### 2. Nginx代理路径问题 🔴

**问题**:
- Nginx正则匹配 `location ~ ^/api(/.*)?$`
- 当请求 `/api/v1/health` 时，`$1` 是 `/v1/health`
- `proxy_pass http://backend_api$1` 会变成 `http://backend_api/v1/health`
- **但后端需要完整路径 `/api/v1/health`**

---

## ✅ 修复方案

### 修复1: Nginx API代理路径修复

**修复前（错误）**:
```nginx
location ~ ^/api(/.*)?$ {
    proxy_pass http://backend_api$1;  # 变成 /v1/health (缺少 /api 前缀)
}
```

**修复后（正确）**:
```nginx
location ~ ^/api(/.*)?$ {
    # 检查是否是PHP路由（如 /api/status, /api/health）
    set $is_php_route 0;
    if ($uri ~ "^/api/(status|health)$") {
        set $is_php_route 1;
    }
    
    # PHP路由不代理，让PHP处理
    if ($is_php_route = 1) {
        break;
    }
    
    # 代理到后端时，保留 /api 前缀
    set $api_path $1;
    proxy_pass http://backend_api/api$api_path;
}
```

### 修复2: AuthController API检查优化

**修复内容**:
- ✅ 优先尝试通过Nginx代理访问 `/api/v1/health`
- ✅ 如果失败，回退到直接访问后端 `http://192.168.1.110:8000/api/v1/health`
- ✅ 确保使用正确的API路径 `/api/v1/health`

---

## 📝 修复后的架构

```
前端登录页面
  ↓
调用 /api/status
  ↓
PHP路由 (AuthController@checkApiStatus)
  ↓
尝试通过Nginx代理访问: http://192.168.1.110/api/v1/health
  ↓ (如果失败)
直接访问后端: http://192.168.1.110:8000/api/v1/health
  ↓
返回API状态给前端
```

---

## 🔍 验证步骤

修复后验证：

```powershell
# 1. 测试PHP路由 /api/status
try {
    $response = Invoke-WebRequest -Uri http://192.168.1.110/api/status -Method GET -UseBasicParsing
    Write-Host "Status: $($response.StatusCode)"
    $response.Content
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}

# 2. 测试Nginx代理 /api/v1/health
try {
    $response = Invoke-WebRequest -Uri http://192.168.1.110/api/v1/health -Method GET -UseBasicParsing
    Write-Host "Status: $($response.StatusCode)"
    $response.Content
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}

# 3. 测试直接后端访问
try {
    $response = Invoke-WebRequest -Uri http://192.168.1.110:8000/api/v1/health -Method GET -UseBasicParsing
    Write-Host "Status: $($response.StatusCode)"
    $response.Content
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}
```

---

## ⚠️ 注意事项

### 1. 必须重新加载Nginx

修复后必须重新加载Nginx配置：
```bash
sudo nginx -t  # 测试配置
sudo systemctl reload nginx  # 重新加载配置
```

### 2. 路由优先级

- `/api/status` → PHP路由（AuthController处理）
- `/api/v1/*` → Nginx代理到后端FastAPI
- `/health` → Nginx直接代理到后端 `/api/v1/health`

---

## 📊 修复文件

1. **install.sh** - Nginx配置修复
   - ✅ 修复API代理路径（保留/api前缀）
   - ✅ 添加PHP路由检查（避免错误代理）

2. **php-frontend/controllers/AuthController.php** - API检查优化
   - ✅ 优先使用Nginx代理
   - ✅ 回退到直接访问后端
   - ✅ 确保使用正确路径

---

**修复完成时间**: 2024年12月  
**状态**: ✅ 已修复API路径问题

