# 前端 500 错误修复指南

## 问题描述

访问前端时返回 `500 Internal Server Error`。

## 常见原因

### 1. PHP 扩展缺失

**症状**: 访问时直接返回 500，无详细错误信息

**检查**:
```bash
php -m | grep -E "session|json|mbstring|curl|openssl|pdo|pdo_mysql"
```

**修复**:
```bash
# Ubuntu/Debian
sudo apt-get install php8.1-session php8.1-json php8.1-mbstring php8.1-curl php8.1-openssl php8.1-mysql

# CentOS/RHEL
sudo yum install php-session php-json php-mbstring php-curl php-openssl php-mysql
```

### 2. 文件权限问题

**症状**: 日志显示权限被拒绝

**修复**:
```bash
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
sudo chmod -R 775 /var/www/html/logs
```

### 3. 会话目录权限问题

**症状**: 日志显示会话启动失败

**检查**:
```bash
php -r "echo session_save_path();"
ls -ld $(php -r "echo session_save_path();")
```

**修复**:
```bash
session_path=$(php -r "echo session_save_path() ?: '/var/lib/php/sessions';")
sudo chmod 1733 "$session_path"
sudo chown -R www-data:www-data "$session_path"
```

### 4. PHP 语法错误

**症状**: 日志显示语法错误

**检查**:
```bash
php -l /var/www/html/index.php
php -l /var/www/html/config/config.php
php -l /var/www/html/config/database.php
```

### 5. 类文件加载失败

**症状**: 日志显示 "Class not found" 或 "Cannot redeclare class"

**检查**:
```bash
# 检查类文件是否存在
ls -la /var/www/html/classes/*.php
ls -la /var/www/html/controllers/*.php
```

**修复**: 确保所有必需的类文件都存在且语法正确

### 6. 配置文件错误

**症状**: 日志显示配置相关错误

**检查**:
```bash
# 测试配置文件加载
php -r "require_once '/var/www/html/config/config.php'; echo 'Config OK';"
```

### 7. 数据库连接失败（如果前端直接访问数据库）

**症状**: 日志显示数据库连接错误

**检查**:
```bash
# 检查环境变量
env | grep DB_

# 测试数据库连接
mysql -h ${DB_HOST:-localhost} -u ${DB_USER:-ipv6wgm} -p${DB_PASS} ${DB_NAME:-ipv6wgm} -e "SELECT 1;"
```

## 诊断步骤

### 方法 1: 使用诊断脚本（推荐）

```bash
chmod +x diagnose_frontend_500.sh
sudo ./diagnose_frontend_500.sh
```

### 方法 2: 手动检查

#### 步骤 1: 检查 PHP-FPM 错误日志

```bash
sudo tail -50 /var/log/php*-fpm.log
sudo tail -50 /var/www/html/logs/php_errors.log
sudo tail -50 /var/www/html/logs/error.log
```

#### 步骤 2: 检查 Nginx 错误日志

```bash
sudo tail -50 /var/log/nginx/error.log
```

#### 步骤 3: 启用 PHP 错误显示（临时）

编辑 `/var/www/html/config/config.php`:

```php
define('APP_DEBUG', true);
```

然后访问前端，查看具体错误信息。

#### 步骤 4: 测试 PHP 文件直接执行

```bash
cd /var/www/html
php -f index.php
```

#### 步骤 5: 创建测试文件

访问 `/test_php.php`（如果已创建）查看详细 PHP 信息。

## 快速修复

### 使用修复脚本

```bash
chmod +x fix_frontend_500.sh
sudo ./fix_frontend_500.sh
```

### 手动修复步骤

#### 1. 修复文件权限

```bash
sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo find /var/www/html -type f -exec chmod 644 {} \;
sudo chmod -R 775 /var/www/html/logs
```

#### 2. 修复会话目录

```bash
session_path=$(php -r "echo session_save_path() ?: '/var/lib/php/sessions';")
sudo chmod 1733 "$session_path"
sudo chown -R www-data:www-data "$session_path"
```

#### 3. 检查 PHP 扩展

```bash
php -m | grep -E "session|json|mbstring|curl|openssl"
```

缺少的扩展需要安装。

#### 4. 重启服务

```bash
sudo systemctl restart php*-fpm
sudo systemctl restart nginx
```

## 已修复的代码问题

### 1. 会话启动错误处理

**修复前**:
```php
SecurityEnhancer::startSecureSession();
```

**修复后**:
```php
try {
    SecurityEnhancer::startSecureSession();
    SecurityEnhancer::setSecurityHeaders();
} catch (Exception $e) {
    error_log("SecurityEnhancer 初始化失败: " . $e->getMessage());
    if (session_status() === PHP_SESSION_NONE) {
        @session_start();
    }
}
```

**改进**: 添加了错误处理，避免会话启动失败导致整个应用无法运行。

### 2. 数据库配置可选加载

数据库配置现在只在文件存在时加载，因为前端主要通过 API 访问数据，不需要直接数据库连接。

## 调试技巧

### 1. 启用详细错误显示

在 `config/config.php` 中:

```php
define('APP_DEBUG', true);
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
```

### 2. 检查 PHP-FPM 配置

```bash
sudo php-fpm -t
sudo systemctl status php*-fpm
```

### 3. 检查 Nginx FastCGI 配置

确保 Nginx 配置中的 `fastcgi_pass` 指向正确的 PHP-FPM socket 或地址。

### 4. 检查 SELinux（如果启用）

```bash
getenforce
# 如果是 Enforcing，可能需要调整上下文
sudo chcon -R -t httpd_sys_rw_content_t /var/www/html
```

## 预防措施

### 1. 安装时检查

确保安装脚本正确检测和安装所有必需的 PHP 扩展。

### 2. 权限设置

在部署时自动设置正确的文件和目录权限。

### 3. 日志监控

定期检查错误日志，及时发现问题。

### 4. 测试验证

部署后访问测试页面验证所有功能正常。

## 常见错误消息及解决方案

### "Class 'X' not found"

**原因**: 类文件未加载或路径错误

**解决**: 检查 `require_once` 路径是否正确

### "session_start(): Failed to initialize storage module"

**原因**: 会话目录权限问题

**解决**: 修复会话目录权限（见上方）

### "Call to undefined function"

**原因**: PHP 扩展未安装

**解决**: 安装缺失的扩展

### "PDO Exception: could not find driver"

**原因**: PDO MySQL 驱动未安装

**解决**: 安装 `php-pdo-mysql` 或 `php8.1-mysql`

### "Maximum execution time exceeded"

**原因**: PHP 执行超时

**解决**: 增加 `max_execution_time` 或检查代码性能

---

**修复版本**: 3.0.0  
**最后更新**: 2025-11-01

