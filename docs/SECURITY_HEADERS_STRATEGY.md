# 安全头设置策略文档

## 📋 概述

本文档说明IPv6 WireGuard Manager系统中安全头的设置策略，帮助开发者和运维人员理解不同环境下安全头的配置方式。

**最后更新**: 2024年12月  
**版本**: 1.0

---

## 🎯 核心原则

### 原则1: 单一来源设置
- ✅ **推荐**: 在一个地方统一设置安全头
- ❌ **避免**: 在多个层（Nginx、FastAPI、PHP）重复设置

### 原则2: 优先级策略
```
Nginx (最高优先级) > FastAPI中间件 (备选) > PHP (已移除)
```

### 原则3: 环境适配
- **生产环境**: Nginx统一设置（推荐）
- **开发环境**: FastAPI中间件自动添加（备选）

---

## 🏗️ 架构说明

### 当前实现架构

```
┌─────────────────────────────────────────┐
│        客户端请求                        │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│        Nginx反向代理                     │
│  ✅ 统一设置安全头（最高优先级）         │
│  - X-Frame-Options                      │
│  - X-Content-Type-Options               │
│  - X-XSS-Protection                     │
│  - Referrer-Policy                      │
└────────────────┬────────────────────────┘
                 │
        ┌────────┴────────┐
        ▼                 ▼
┌──────────────┐  ┌──────────────┐
│  PHP前端     │  │  FastAPI后端 │
│  (无安全头)  │  │  (备选检查)  │
│              │  │  仅在未设置时│
│              │  │  自动添加    │
└──────────────┘  └──────────────┘
```

### 各层职责

#### 1. Nginx层（主要设置点）
**职责**: 统一设置所有安全头
**位置**: `install.sh` 或 Nginx配置文件
**特点**:
- ✅ 最高优先级
- ✅ 统一管理
- ✅ 适用于所有请求（静态、PHP、API）

**配置示例**:
```nginx
server {
    # 安全头（统一在Nginx层设置）
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
```

#### 2. FastAPI中间件（备选设置点）
**职责**: 仅在安全头未设置时添加（避免重复）
**位置**: `backend/app/main_production.py`
**特点**:
- ✅ 自动检测避免重复
- ✅ 适用于无Nginx的开发环境
- ✅ 智能检查：仅在响应头不存在时设置

**实现逻辑**:
```python
# 仅在响应头中不存在时设置
for header, value in security_headers.items():
    if header not in response.headers:
        response.headers[header] = value
```

#### 3. PHP层（已移除）
**职责**: ~~设置安全头~~（已移除）
**原因**:
- ❌ `$_SERVER['HTTP_X_*']`检查不准确
- ❌ 可能导致重复设置
- ✅ 简化架构，完全依赖Nginx

**当前状态**: 
- `index_jwt.php`: 已移除安全头设置
- `SecurityEnhancer.php`: `setSecurityHeaders()`方法保留为接口兼容，但不执行操作

---

## 🌍 环境区分策略

### 生产环境（推荐配置）

#### 配置方式
```bash
# 使用Nginx统一设置
DEBUG=false
APP_ENV=production
```

#### 安全头设置
- **位置**: Nginx配置文件
- **方法**: `add_header ... always;`
- **特点**: 
  - ✅ 统一管理
  - ✅ 性能最优
  - ✅ 易于维护

#### 验证方法
```bash
# 使用测试脚本
./scripts/tests/test_security_headers.sh

# 或手动检查
curl -I http://your-domain.com/
```

### 开发环境（备选配置）

#### 配置方式
```bash
# 可能没有Nginx
DEBUG=true
APP_ENV=development
```

#### 安全头设置
- **位置**: FastAPI中间件
- **方法**: 自动检测并设置
- **特点**:
  - ✅ 自动适配
  - ✅ 无需手动配置
  - ✅ 适合开发测试

#### 验证方法
```bash
# 直接访问FastAPI
curl -I http://127.0.0.1:8000/
```

---

## 🔍 安全头配置详情

### X-Frame-Options
**值**: `DENY`
**说明**: 防止页面被嵌入iframe
**优先级**: Nginx > FastAPI

### X-Content-Type-Options
**值**: `nosniff`
**说明**: 防止MIME类型嗅探
**优先级**: Nginx > FastAPI

### X-XSS-Protection
**值**: `1; mode=block`
**说明**: 启用XSS过滤器
**优先级**: Nginx > FastAPI

### Referrer-Policy
**值**: `strict-origin-when-cross-origin`
**说明**: 控制Referer头信息
**优先级**: Nginx > FastAPI

### Strict-Transport-Security (HSTS)
**值**: `max-age=31536000; includeSubDomains`
**说明**: 强制HTTPS（仅HTTPS环境）
**优先级**: FastAPI（仅在HTTPS时设置）

---

## ✅ 最佳实践

### 1. 生产环境推荐做法
```nginx
# ✅ 推荐：在Nginx统一设置
server {
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
```

### 2. 避免的做法
```nginx
# ❌ 避免：在多个location块重复设置
location / {
    add_header X-Frame-Options "DENY" always;
}
location /api/ {
    add_header X-Frame-Options "DENY" always;  # 重复！
}
```

```python
# ❌ 避免：在应用层无条件设置（已修复）
# 现在已改为条件检查，避免重复
if header not in response.headers:  # ✅ 正确
    response.headers[header] = value
```

---

## 🧪 测试验证

### 自动化测试

#### Linux/Mac
```bash
# 运行测试脚本
./scripts/tests/test_security_headers.sh

# 自定义URL
TEST_BASE_URL=http://192.168.1.110 ./scripts/tests/test_security_headers.sh
```

#### Windows PowerShell
```powershell
# 运行测试脚本
.\scripts\tests\test_security_headers.ps1

# 自定义URL
.\scripts\tests\test_security_headers.ps1 -BaseUrl "http://192.168.1.110" -Verbose
```

### 手动验证

#### 检查安全头
```bash
# 使用curl
curl -I http://your-domain.com/

# 检查特定安全头
curl -I http://your-domain.com/ | grep -i "x-frame-options"
```

#### 检查是否重复
```bash
# 查看所有安全头
curl -I http://your-domain.com/ | grep -iE "(x-frame-options|x-content-type-options|x-xss-protection|referrer-policy)"

# 如果看到逗号分隔的值，说明有重复
# 例如: X-Frame-Options: DENY,SAMEORIGIN  ❌ 错误
# 正确应该是: X-Frame-Options: DENY  ✅
```

---

## 🐛 故障排除

### 问题1: 安全头重复

**症状**:
```
X-Frame-Options: DENY,SAMEORIGIN
```

**原因**:
- Nginx和应用层都设置了安全头

**解决方案**:
1. 检查Nginx配置，确保只在Nginx设置
2. FastAPI中间件已修复，会自动检查避免重复
3. PHP层已移除安全头设置

### 问题2: 安全头缺失

**症状**:
- 响应头中没有安全头

**原因**:
- Nginx配置未应用
- 开发环境无Nginx

**解决方案**:
1. 检查Nginx配置是否正确
2. 重新加载Nginx: `sudo systemctl reload nginx`
3. 开发环境：FastAPI会自动添加（备选）

### 问题3: 值不一致

**症状**:
- 不同请求返回不同的安全头值

**原因**:
- 不同location块设置了不同的值

**解决方案**:
- 统一在server块设置
- 使用`always`参数确保所有响应都包含

---

## 📊 配置检查清单

### 部署前检查
- [ ] Nginx配置中安全头设置正确
- [ ] 没有在多个location块重复设置
- [ ] FastAPI中间件正确检查避免重复
- [ ] PHP层安全头设置已移除
- [ ] 测试脚本验证通过

### 部署后检查
- [ ] 使用测试脚本验证安全头
- [ ] 检查安全头不重复
- [ ] 验证所有端点都有安全头
- [ ] 确认值符合预期

---

## 📚 相关文档

- [部署指南](DEPLOYMENT_GUIDE.md) - 生产环境部署配置
- [安全特性](SECURITY_FEATURES.md) - 完整安全特性说明
- [故障排除指南](TROUBLESHOOTING_GUIDE.md) - 安全相关问题排查

---

**文档版本**: 1.0  
**最后更新**: 2024年12月  
**维护者**: 技术总监

