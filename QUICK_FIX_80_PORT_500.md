# 80端口500错误快速修复指南

## 📋 当前状态

✅ PHP-FPM socket存在: `/var/run/php/php8.2-fpm.sock`  
✅ Socket权限: `www-data:www-data`  
⚠️ 需要诊断具体错误原因

---

## 🔍 快速诊断步骤

### 方法1: 使用诊断脚本（推荐）

```bash
# 下载最新版本
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/check_500_error.sh

chmod +x check_500_error.sh
sudo ./check_500_error.sh
```

### 方法2: 手动检查关键项

```bash
# 1. 查看Nginx错误日志（最重要！）
sudo tail -50 /var/log/nginx/error.log

# 2. 查看PHP-FPM错误日志
sudo tail -50 /var/log/php8.2-fpm.log

# 3. 测试index.php直接执行
cd /var/www/html
php -f index.php 2>&1 | head -50

# 4. 检查文件权限
ls -la /var/www/html/index.php
ls -ld /var/www/html
```

---

## 🎯 常见问题及快速修复

### 问题1: PHP扩展缺失

**症状**: 日志显示 "undefined function" 或扩展相关错误

**快速检查**:
```bash
php -m | grep -E "session|json|mbstring|pdo_mysql|curl|openssl"
```

**修复**:
```bash
# Ubuntu/Debian
sudo apt-get install php8.2-session php8.2-json php8.2-mbstring php8.2-curl php8.2-openssl php8.2-mysql php8.2-xml
sudo systemctl restart php8.2-fpm
```

### 问题2: 文件权限错误

**症状**: 日志显示 "Permission denied" 或 "failed to open stream"

**快速检查**:
```bash
ls -la /var/www/html/index.php
ps aux | grep php-fpm | grep -v grep
```

**修复**:
```bash
# 确保www-data用户有权限
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
sudo chmod 775 /var/www/html/logs 2>/dev/null
sudo systemctl restart php8.2-fpm
sudo systemctl restart nginx
```

### 问题3: 配置文件错误

**症状**: 日志显示 "require_once failed" 或配置相关错误

**快速检查**:
```bash
php -r "require_once '/var/www/html/config/config.php'; echo 'OK';"
php -r "require_once '/var/www/html/config/database.php'; echo 'OK';"
```

**修复**: 检查配置文件语法是否正确

### 问题4: 会话目录权限

**症状**: 日志显示 "session_start() failed"

**快速修复**:
```bash
session_path=$(php -r "echo session_save_path() ?: '/var/lib/php/sessions';")
sudo chmod 1733 "$session_path"
sudo chown -R www-data:www-data "$session_path"
```

### 问题5: 类文件找不到

**症状**: 日志显示 "Class not found"

**快速检查**:
```bash
ls -la /var/www/html/classes/*.php
php -l /var/www/html/index.php
```

---

## 🔧 一键修复脚本

如果诊断脚本显示权限问题，运行：

```bash
# 修复文件权限
sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo find /var/www/html -type f -exec chmod 644 {} \;
sudo chmod -R 775 /var/www/html/logs 2>/dev/null

# 修复会话目录
session_path=$(php -r "echo session_save_path() ?: '/var/lib/php/sessions';")
sudo chmod 1733 "$session_path" 2>/dev/null
sudo chown -R www-data:www-data "$session_path" 2>/dev/null

# 重启服务
sudo systemctl restart php8.2-fpm
sudo systemctl restart nginx

# 测试
curl -I http://localhost/
```

---

## 📊 诊断脚本输出解读

运行诊断脚本后，请关注：

1. **PHP-FPM服务状态**: 应该是 `active (running)`
2. **错误日志**: 查找 `ERROR`、`WARNING`、`Permission denied`
3. **文件权限**: index.php应该可读
4. **PHP扩展**: 所有必需的扩展都应该显示为已加载
5. **配置文件加载**: 应该显示 "Config loaded: IPv6 WireGuard Manager"
6. **直接执行**: 如果CLI执行失败，说明代码有问题

---

## 🚨 最紧急的检查

如果时间紧迫，先检查这两项：

```bash
# 1. 查看最新的Nginx错误（最关键！）
sudo tail -20 /var/log/nginx/error.log

# 2. 查看最新的PHP-FPM错误
sudo tail -20 /var/log/php8.2-fpm.log
```

把错误信息发给我，我可以立即给出精确的修复方案。

---

## 💡 下一步

1. 运行诊断脚本: `sudo ./check_500_error.sh`
2. 复制输出结果
3. 特别是错误日志的最后几行
4. 我会根据输出提供精确的修复方案

