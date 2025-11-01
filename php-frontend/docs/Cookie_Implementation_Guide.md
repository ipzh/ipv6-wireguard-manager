# HttpOnly Cookie方案实施指南

## 概述

本项目已实施HttpOnly Cookie方案，以增强令牌安全性，防止XSS攻击获取令牌。本方案通过HttpOnly Cookie传输令牌，同时保留会话存储作为向后兼容方案。

## 实施内容

### 1. 前端修改

#### 登录页面 (views/auth/login.php)
- 在MFA验证fetch请求中添加`credentials: 'include'`以启用Cookie支持
- 在API状态检查fetch请求中添加`credentials: 'include'`以启用Cookie支持

### 2. API代理修改 (api_proxy.php)
- 添加Cookie头处理逻辑，将前端Cookie转发到后端
- 添加响应头解析逻辑，将后端的Set-Cookie头转发到前端
- 在cURL配置中添加`CURLOPT_HEADER => true`选项以包含响应头

### 3. ApiClientJWT类修改 (classes/ApiClientJWT.php)
- 添加Cookie支持相关方法：
  - `buildCookieString()`: 构建Cookie字符串
  - `handleSetCookieHeaders()`: 处理Set-Cookie响应头
- 修改以下方法以支持Cookie：
  - `login()`: 登录方法
  - `logout()`: 登出方法
  - `refreshAccessToken()`: 令牌刷新方法
  - `getCurrentUser()`: 获取当前用户信息方法
  - `verifyToken()`: 令牌验证方法
- 更新`executeCurlRequest()`方法以支持Cookie

## 测试方法

### 1. 使用测试页面

访问 `http://your-domain/php-frontend/tests/cookie_test.php` 进行测试：

1. **登录测试**：
   - 输入用户名和密码
   - 如需要，输入MFA验证码
   - 点击登录按钮
   - 观察是否成功登录并获取用户信息

2. **状态检查**：
   - 点击"检查状态"按钮
   - 查看当前登录状态和令牌有效性
   - 查看Cookie信息

3. **登出测试**：
   - 点击"登出"按钮
   - 观察是否成功登出

### 2. 浏览器开发者工具检查

1. 打开浏览器开发者工具 (F12)
2. 切换到"网络"标签
3. 执行登录操作
4. 检查请求头中是否包含Cookie
5. 检查响应头中是否包含Set-Cookie
6. 切换到"应用"标签，查看Cookie存储情况

### 3. 安全性验证

1. 尝试通过JavaScript访问Cookie：
   ```javascript
   console.log(document.cookie);
   ```
   - 应该看不到HttpOnly Cookie的内容

2. 检查Cookie属性：
   - 确认Cookie标记为HttpOnly
   - 确认Cookie使用Secure标记（通过HTTPS时）
   - 确认Cookie使用SameSite属性

## 部署注意事项

1. **HTTPS配置**：
   - 确保生产环境使用HTTPS
   - Secure Cookie属性仅在HTTPS下有效

2. **域名配置**：
   - 确保Cookie的Domain属性设置正确
   - 跨域配置需要适当设置CORS和Cookie属性

3. **会话配置**：
   - 检查PHP会话配置
   - 确保会话Cookie安全设置正确

## 故障排除

### 常见问题

1. **Cookie未发送**：
   - 检查前端请求是否包含`credentials: 'include'`
   - 检查Cookie的Domain和Path设置
   - 检查是否使用HTTPS（Secure Cookie要求）

2. **Cookie未接收**：
   - 检查后端是否正确设置Set-Cookie头
   - 检查API代理是否正确转发Set-Cookie头
   - 检查响应头格式是否正确

3. **令牌验证失败**：
   - 检查Cookie是否正确发送到后端
   - 检查后端是否正确解析Cookie
   - 检查令牌是否过期

### 调试技巧

1. 启用详细日志记录：
   ```php
   error_log('Cookie Debug: ' . print_r($_COOKIE, true));
   ```

2. 使用浏览器开发者工具检查网络请求和响应头

3. 检查PHP错误日志：
   ```bash
   tail -f /var/log/php_errors.log
   ```

## 回滚方案

如果需要回滚到原有方案：

1. 移除前端请求中的`credentials: 'include'`
2. 移除API代理中的Cookie处理逻辑
3. 恢复ApiClientJWT类中的原有方法实现
4. 确保会话存储方案正常工作

## 安全建议

1. 定期轮换令牌密钥
2. 设置合理的令牌过期时间
3. 实施令牌撤销机制
4. 监控异常登录活动
5. 定期进行安全审计

## 相关文件

- `views/auth/login.php`: 登录页面
- `api_proxy.php`: API代理
- `classes/ApiClientJWT.php`: API客户端类
- `tests/cookie_test.php`: 测试页面
- `config/ssl_config.php`: SSL配置文件