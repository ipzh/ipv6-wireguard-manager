# HttpOnly Cookie方案快速部署指南

## 概述

本指南提供了在IPv6 WireGuard Manager项目中快速部署HttpOnly Cookie方案的步骤，帮助您提高系统的安全性。

## 前置条件

1. 已有IPv6 WireGuard Manager项目
2. 项目使用Docker Compose部署
3. 具有管理员权限

## 部署步骤

### 1. 备份当前系统

```bash
# 备份关键文件
cp php-frontend/views/auth/login.php php-frontend/views/auth/login.php.bak
cp php-frontend/api_proxy.php php-frontend/api_proxy.php.bak
cp php-frontend/classes/ApiClientJWT.php php-frontend/classes/ApiClientJWT.php.bak
cp php-frontend/services/api_client.js php-frontend/services/api_client.js.bak
```

### 2. 应用修改

#### 2.1 前端登录页面修改

确保`php-frontend/views/auth/login.php`中的fetch请求包含以下配置：

```javascript
fetch('/api_proxy.php', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
    },
    body: JSON.stringify(loginData),
    credentials: 'include'  // 添加此行以支持Cookie
})
```

#### 2.2 API代理修改

确保`php-frontend/api_proxy.php`包含以下Cookie处理代码：

```php
// 转发Cookie到后端API
$cookieHeaders = [];
foreach ($_COOKIE as $name => $value) {
    $cookieHeaders[] = $name . '=' . urlencode($value);
}
if (!empty($cookieHeaders)) {
    curl_setopt($ch, CURLOPT_COOKIE, implode('; ', $cookieHeaders));
}

// 启用响应头获取，用于处理Set-Cookie
curl_setopt($ch, CURLOPT_HEADER, true);

// 在响应处理中添加Set-Cookie处理
$response = curl_exec($ch);
$headerSize = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
$responseHeaders = substr($response, 0, $headerSize);
$responseBody = substr($response, $headerSize);

// 处理Set-Cookie头
preg_match_all('/^Set-Cookie:\s*(.*)$/mi', $responseHeaders, $matches);
foreach ($matches[1] as $cookie) {
    header('Set-Cookie: ' . $cookie, false);
}
```

#### 2.3 ApiClientJWT类修改

确保`php-frontend/classes/ApiClientJWT.php`包含以下Cookie支持方法：

```php
/**
 * 构建Cookie字符串
 */
private function buildCookieString() {
    $cookieString = '';
    
    // 添加所有可用的Cookie
    foreach ($_COOKIE as $name => $value) {
        if (!empty($cookieString)) {
            $cookieString .= '; ';
        }
        $cookieString .= $name . '=' . urlencode($value);
    }
    
    return $cookieString;
}

/**
 * 处理Set-Cookie头
 */
private function handleSetCookieHeaders($responseHeaders) {
    // 提取Set-Cookie头
    preg_match_all('/^Set-Cookie:\s*(.*)$/mi', $responseHeaders, $matches);
    
    foreach ($matches[1] as $cookie) {
        // 解析Cookie
        $parts = explode('=', $cookie, 2);
        if (count($parts) >= 2) {
            $name = trim($parts[0]);
            $value = trim($parts[1]);
            
            // 提取值部分（忽略其他属性如路径、过期等）
            $valueParts = explode(';', $value);
            $cookieValue = trim($valueParts[0]);
            
            // 设置到$_COOKIE数组
            $_COOKIE[$name] = $cookieValue;
        }
    }
}
```

#### 2.4 API客户端修改

确保`php-frontend/services/api_client.js`包含以下配置：

```javascript
// 创建axios实例
const apiClient = axios.create({
    baseURL: getApiBaseUrl(),
    timeout: 30000,
    withCredentials: true  // 添加此行以支持Cookie
});
```

### 3. 后端API修改

确保后端API在登录成功时设置HttpOnly Cookie：

```python
# 在登录成功后设置Cookie
response = JSONResponse(content={
    "access_token": access_token,
    "token_type": "bearer",
    "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    "refresh_token": refresh_token
})

# 设置HttpOnly Cookie
response.set_cookie(
    key="access_token",
    value=access_token,
    max_age=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    expires=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    path="/",
    domain=None,
    secure=False,  # 生产环境应设为True
    httponly=True,
    samesite="lax"
)

response.set_cookie(
    key="refresh_token",
    value=refresh_token,
    max_age=REFRESH_TOKEN_EXPIRE_DAYS * 24 * 60 * 60,
    expires=REFRESH_TOKEN_EXPIRE_DAYS * 24 * 60 * 60,
    path="/",
    domain=None,
    secure=False,  # 生产环境应设为True
    httponly=True,
    samesite="lax"
)
```

### 4. PHP配置

确保PHP配置支持HttpOnly Cookie：

```ini
; 在php.ini中设置
session.cookie_httponly = 1
session.cookie_secure = 1  ; 仅HTTPS
session.cookie_samesite = "Lax"
```

### 5. 部署和测试

#### 5.1 重新构建和启动容器

```bash
# 停止当前容器
docker-compose down

# 重新构建前端镜像
docker-compose build frontend

# 启动容器
docker-compose up -d
```

#### 5.2 运行验证脚本

```bash
# Docker环境
docker exec -it ipv6-wireguard-frontend php /var/www/html/tests/verify_cookie_implementation.php

# 或使用提供的脚本
./php-frontend/tests/run_verification_docker.sh
```

#### 5.3 手动测试

1. 访问登录页面: `http://localhost/views/auth/login.php`
2. 尝试登录
3. 检查浏览器开发者工具中的Cookie
4. 确认Cookie标记为HttpOnly

### 6. 生产环境配置

#### 6.1 HTTPS配置

确保生产环境使用HTTPS：

```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    
    # 其他配置...
}
```

#### 6.2 安全Cookie配置

更新后端API中的Cookie设置，确保生产环境安全：

```python
response.set_cookie(
    key="access_token",
    value=access_token,
    max_age=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    expires=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    path="/",
    domain=".your-domain.com",  # 设置适当的域名
    secure=True,  # 生产环境必须为True
    httponly=True,
    samesite="Strict"  # 更严格的SameSite策略
)
```

## 故障排除

### 1. Cookie未设置

- 检查浏览器控制台是否有错误
- 确认响应中包含Set-Cookie头
- 检查域名、路径和Secure标志设置

### 2. 登录失败

- 检查API代理是否正确转发Cookie
- 确认后端API是否正确验证Cookie
- 检查CORS配置是否允许凭证

### 3. 跨域问题

- 确保后端API的CORS配置允许凭证
- 检查前端的withCredentials设置
- 确认Cookie的域名设置正确

## 回滚方案

如果需要回滚到原始方案：

```bash
# 恢复备份文件
cp php-frontend/views/auth/login.php.bak php-frontend/views/auth/login.php
cp php-frontend/api_proxy.php.bak php-frontend/api_proxy.php
cp php-frontend/classes/ApiClientJWT.php.bak php-frontend/classes/ApiClientJWT.php
cp php-frontend/services/api_client.js.bak php-frontend/services/api_client.js

# 重新构建和启动容器
docker-compose down
docker-compose build frontend
docker-compose up -d
```

## 总结

通过以上步骤，您已成功部署了HttpOnly Cookie方案，提高了系统的安全性。请确保在生产环境中进行充分测试，并定期检查系统的安全状态。