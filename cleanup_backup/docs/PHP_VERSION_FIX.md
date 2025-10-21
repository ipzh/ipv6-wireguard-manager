# PHP版本修复说明

## 问题描述

在IPv6 WireGuard Manager项目中，存在多处硬编码PHP版本（如php8.1）的问题，这会导致在不同PHP版本的系统上安装失败。

## 修复内容

### 1. 安装脚本优化

- **动态PHP版本检测**: 添加了`detect_php_version()`函数，能够自动检测系统已安装的PHP版本或可用的PHP版本
- **智能安装策略**: 支持多版本PHP安装策略，优先使用检测到的版本，失败时尝试其他版本
- **服务名动态检测**: 自动检测PHP-FPM服务名，支持不同发行版的服务命名规范

### 2. 配置文件修复

- **Nginx配置**: 动态生成PHP-FPM socket路径
- **系统服务**: 使用检测到的PHP版本配置systemd服务
- **部署脚本**: 修复所有部署脚本中的硬编码PHP版本

### 3. 修复脚本

### 修复脚本

提供了Linux/macOS修复脚本：

```bash
./scripts/fix_php_version.sh
```
```

## 支持的PHP版本

- PHP 8.2
- PHP 8.1
- PHP 8.0
- PHP 7.4

## 检测逻辑

### 1. 已安装PHP检测
```bash
php -v | grep -oP 'PHP \K[0-9]+\.[0-9]+'
```

### 2. 可用版本检测
```bash
apt-cache show php8.2-fpm  # 检测8.2版本
apt-cache show php8.1-fpm  # 检测8.1版本
apt-cache show php8.0-fpm  # 检测8.0版本
apt-cache show php7.4-fpm  # 检测7.4版本
```

### 3. 服务名检测
```bash
systemctl list-unit-files | grep php-fpm
```

### 4. Socket路径检测
```bash
ls /var/run/php/php*-fpm.sock
```

## 使用方法

### 自动修复（推荐）
```bash
# Linux/macOS
./scripts/fix_php_version.sh
```

### 手动修复
1. 检测PHP版本：
   ```bash
   php -v
   ```

2. 更新配置文件中的PHP版本引用

3. 重启相关服务：
   ```bash
   systemctl restart php-fpm
   systemctl reload nginx
   ```

## 修复的文件

### 配置文件
- `/etc/nginx/sites-available/ipv6-wireguard-manager`
- `/etc/nginx/conf.d/ipv6-wireguard-manager.conf`
- `php-frontend/nginx.conf` ⭐ **重要修复**
- `nginx/nginx.conf`
- `/etc/systemd/system/ipv6-wireguard-manager.service`

### 脚本文件
- `install.sh`
- `deploy/deploy.sh`
- `deploy/setup.sh`

### 文档文件
- `INSTALLATION_GUIDE.md`
- `docs/DEPLOYMENT_GUIDE.md`
- `docs/archive/PRODUCTION_DEPLOYMENT_GUIDE.md`

### 新增修复脚本
- `scripts/fix_php_version.sh` - 通用PHP版本修复脚本
- `scripts/fix_nginx_php_config.sh` - 专门的nginx配置修复脚本

## 验证修复

修复完成后，可以通过以下命令验证：

```bash
# 检查PHP版本
php -v

# 检查PHP-FPM服务状态
systemctl status php-fpm

# 检查Nginx配置
nginx -t

# 检查PHP-FPM socket
ls -la /var/run/php/php*-fpm.sock
```

## 注意事项

1. **备份**: 修复脚本会自动备份原文件
2. **权限**: 确保有足够的权限修改系统配置文件
3. **服务重启**: 修复后需要重启相关服务
4. **测试**: 建议在测试环境中先验证修复效果

## 故障排除

### 问题1: PHP-FPM服务启动失败
```bash
# 检查服务状态
systemctl status php-fpm

# 查看错误日志
journalctl -u php-fpm -f

# 手动启动
systemctl start php-fpm
```

### 问题2: Nginx配置错误
```bash
# 测试配置
nginx -t

# 查看错误信息
nginx -T

# 重新加载配置
systemctl reload nginx
```

### 问题3: Socket文件不存在
```bash
# 检查socket文件
ls -la /var/run/php/

# 检查PHP-FPM配置
php-fpm -t

# 重启PHP-FPM
systemctl restart php-fpm
```

## 更新日志

- **v1.0.0**: 初始版本，支持PHP 8.1-8.2动态检测
- **v1.1.0**: 添加PHP 7.4和8.0支持
- **v1.2.0**: 优化服务检测逻辑，支持更多发行版
