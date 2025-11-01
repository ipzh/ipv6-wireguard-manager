# IPv6 WireGuard Manager 安全特性文档

## 📋 概述

本文档详细说明了IPv6 WireGuard Manager系统的所有安全特性，帮助用户了解和配置安全机制。

**最后更新**: 2024年12月  
**版本**: 3.1.0

---

## 🔐 认证与授权

### 1. JWT令牌认证

#### 令牌类型
- **访问令牌 (Access Token)**: 用于API请求认证
- **刷新令牌 (Refresh Token)**: 用于刷新访问令牌

#### 令牌生命周期
- **访问令牌**: 默认8天（11520分钟），可配置范围：1分钟 - 1年
- **刷新令牌**: 默认30天，可配置范围：1天 - 1年

#### 令牌存储方案

##### HttpOnly Cookie（推荐）✅
- **安全性**: ⭐⭐⭐⭐⭐
- **XSS防护**: ✅ 完全防护
- **实现状态**: ✅ 已实现并默认启用

**特性**:
- `HttpOnly=True` - JavaScript无法访问
- `Secure=True` - 仅HTTPS传输（生产环境）
- `SameSite=Lax` - CSRF保护
- 自动环境适配（开发/生产）

**使用方式**:
```javascript
// 前端配置
const apiClient = axios.create({
  withCredentials: true  // 启用Cookie
});

// 登录后Cookie自动设置，无需手动管理
```

##### Authorization Header（兼容）✅
- **向后兼容**: ✅ 仍然支持
- **使用场景**: 旧客户端、API调用

**使用方式**:
```javascript
headers: {
  'Authorization': 'Bearer <access_token>'
}
```

---

### 2. 令牌撤销机制 ✅

#### 功能说明
- ✅ 登出时自动将令牌加入黑名单
- ✅ 黑名单中的令牌无法继续使用
- ✅ 自动清理过期令牌

#### 存储方式

**内存存储**（默认）:
- 适合：开发环境、单实例部署
- 限制：重启后清空，不支持分布式

**数据库存储**（推荐）:
```bash
export USE_DATABASE_BLACKLIST=true
```
- 适合：生产环境、多实例部署
- 优点：持久化、支持分布式

**Redis存储**（最佳）:
```bash
export REDIS_URL=redis://localhost:6379/0
export USE_REDIS=true
```
- 适合：高并发、大规模部署
- 优点：高性能、分布式、自动过期

---

### 3. 防暴力破解 ✅

#### 机制说明
- **限制**: 5分钟内最多5次登录尝试
- **基于**: 用户名 + IP地址的组合
- **超过限制**: 返回429状态码，锁定5分钟

#### 实现细节
```python
_MAX_LOGIN_ATTEMPTS = 5
_LOGIN_WINDOW_SECONDS = 300  # 5分钟
```

#### 记录内容
- 失败的登录尝试时间戳
- 用户名和IP地址
- 成功登录后自动清除记录

#### 生产环境建议
- 使用Redis存储失败记录
- 支持分布式部署
- 多实例共享状态

---

### 4. 密码安全 ✅

#### 哈希算法
- **bcrypt**（推荐）✅
  - 自适应成本因子
  - 自动加盐
  - 抗暴力破解
  - 密码长度限制：72字节

- **pbkdf2_sha256**（备选）
  - bcrypt不可用时自动回退
  - 仍然安全，但bcrypt更推荐

#### 密码策略
- 长度验证
- 复杂度建议（可在前端实现）
- 哈希存储（绝不存储明文）

---

### 5. 权限控制 ✅

#### RBAC（基于角色的访问控制）
- 角色管理：admin、operator、viewer等
- 权限分配：细粒度权限控制
- 资源级权限：针对特定资源的权限

#### API端点权限验证
- 自动权限检查
- 基于JWT令牌的用户信息
- 角色和权限验证

---

## 🛡️ 防护机制

### 1. XSS防护

#### HttpOnly Cookie ✅
- ✅ Cookie无法通过JavaScript访问
- ✅ 防止XSS攻击窃取令牌

#### 安全头 ✅
```
X-XSS-Protection: 1; mode=block
```

### 2. CSRF防护

#### SameSite Cookie ✅
- ✅ `SameSite=Lax` - 基本CSRF保护
- ✅ 同站请求自动携带Cookie
- ✅ 跨站请求限制

#### CSRF令牌（可选增强）
- 可扩展实现CSRF令牌机制
- 当前使用SameSite Cookie已提供基础保护

### 3. 点击劫持防护

#### X-Frame-Options ✅
```
X-Frame-Options: DENY
```
- ✅ 防止页面被嵌入iframe
- ✅ 防止点击劫持攻击

### 4. MIME类型嗅探防护

#### X-Content-Type-Options ✅
```
X-Content-Type-Options: nosniff
```
- ✅ 防止浏览器MIME类型嗅探
- ✅ 强制使用声明的Content-Type

### 5. HTTPS强制（生产环境）

#### HSTS ✅
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
```
- ✅ 强制HTTPS连接
- ✅ 防止降级攻击
- ✅ 仅在生产环境HTTPS下启用

---

## 📊 速率限制

### 登录限制 ✅
- **限制**: 5次/5分钟
- **目的**: 防暴力破解
- **返回**: 429 Too Many Requests

### API请求限制 ✅
- **一般请求**: 60次/分钟
- **敏感操作**: 10次/分钟
- **可配置**: 通过配置文件调整

---

## 🔍 安全审计

### 日志记录 ✅
- ✅ 登录尝试记录（成功/失败）
- ✅ 可疑活动记录
- ✅ 安全事件记录
- ✅ 操作审计日志

### 日志内容
- 用户名
- IP地址
- 时间戳
- 操作类型
- 结果（成功/失败）

---

## ⚙️ 配置说明

### 环境变量

```bash
# 令牌配置
ACCESS_TOKEN_EXPIRE_MINUTES=11520  # 8天
REFRESH_TOKEN_EXPIRE_DAYS=30       # 30天

# 令牌黑名单存储
USE_DATABASE_BLACKLIST=false       # 使用内存存储
USE_REDIS=false                    # 使用Redis存储

# 安全配置
DEBUG=false                        # 生产环境设为false
APP_ENV=production                # 生产环境
```

### 前端配置

```javascript
// axios配置
const apiClient = axios.create({
  baseURL: '/api/v1',
  withCredentials: true  // 启用Cookie支持
});

// fetch配置
fetch('/api/v1/endpoint', {
  credentials: 'include'  // 启用Cookie支持
});
```

---

## 📋 安全检查清单

### 部署前检查

- [ ] **HTTPS配置** - 生产环境必须使用HTTPS
- [ ] **Cookie Secure标志** - 生产环境必须为true
- [ ] **环境变量** - DEBUG=false, APP_ENV=production
- [ ] **令牌黑名单** - 配置数据库或Redis存储
- [ ] **防暴力破解** - 验证正常工作
- [ ] **密码策略** - 确认bcrypt正常工作
- [ ] **安全头** - 验证所有安全头设置正确

### 运行时检查

- [ ] **Cookie设置** - 登录后Cookie是否正确设置
- [ ] **Cookie标志** - HttpOnly, Secure, SameSite正确
- [ ] **令牌撤销** - 登出后令牌无法使用
- [ ] **防暴力破解** - 5次失败后是否锁定
- [ ] **日志记录** - 安全事件是否正确记录

---

## 🚨 安全建议

### 必须实施（生产环境）

1. ✅ **使用HTTPS** - 所有传输必须加密
2. ✅ **配置Redis** - 令牌黑名单和防暴力破解使用Redis
3. ✅ **设置强密码策略** - 最小长度、复杂度要求
4. ✅ **定期安全审计** - 检查日志和异常活动
5. ✅ **更新依赖** - 保持依赖包最新

### 建议实施

1. ⚠️ **实现CSRF令牌** - 增强CSRF保护
2. ⚠️ **添加IP白名单** - 限制管理接口访问
3. ⚠️ **实现双因素认证** - 增强登录安全
4. ⚠️ **安全监控告警** - 异常活动实时告警
5. ⚠️ **定期渗透测试** - 发现潜在安全漏洞

---

## 📚 相关文档

- [API参考文档](API_REFERENCE.md) - API端点和安全配置
- [部署指南](DEPLOYMENT_GUIDE.md) - 安全部署配置
- [安装指南](INSTALLATION_GUIDE.md) - 安装和初始配置
- [故障排除指南](TROUBLESHOOTING_GUIDE.md) - 安全相关问题排查

---

**文档版本**: 1.0  
**最后更新**: 2024年12月  
**维护者**: IPv6 WireGuard Manager团队

