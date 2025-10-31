# 前端 404 问题修复指南

## 问题描述

通过 IPv4 或 IPv6 访问前端时都返回 `404 Not Found`。

## 根本原因

1. **Nginx location / 配置问题**
   - 原配置：`try_files $uri $uri/ /index.html /index.php?$query_string;`
   - 问题：先尝试 `/index.html`，如果文件不存在可能导致 404

2. **IPv6 监听配置依赖检测**
   - IPv6 监听仅在 `IPV6_SUPPORT=true` 时添加
   - 如果检测失败，IPv6 请求无法处理

3. **PHP-FPM 服务或 socket 路径问题**
   - PHP-FPM 服务未启动
   - Socket 路径不匹配

## 已修复的问题

### 1. Nginx location / 配置修复

**修复前**:
```nginx
location / {
    try_files $uri $uri/ /index.html /index.php?$query_string;
}
```

**修复后**:
```nginx
location / {
    try_files $uri $uri/ /index.php$is_args$args;
}
```

**改进说明**:
- 移除了 `/index.html` 回退（因为项目中不存在该文件）
- 使用 `$is_args$args` 代替 `?$query_string`（更标准的 Nginx 变量）
- 直接使用 `index.php` 作为最终回退

### 2. 增强的 IPv6 支持检测

IPv6 监听配置会根据 `IPV6_SUPPORT` 变量自动添加，确保双栈支持。

## 验证修复

### 在服务器上执行以下命令：

```bash
# 1. 运行诊断脚本
chmod +x fix_frontend_404.sh
sudo ./fix_frontend_404.sh

# 2. 检查 Nginx 配置
sudo nginx -t

# 3. 检查配置文件中的 location /
sudo grep -A 2 "location / {" /etc/nginx/sites-available/ipv6-wireguard-manager

# 4. 检查 IPv4 和 IPv6 监听
sudo grep "listen" /etc/nginx/sites-available/ipv6-wireguard-manager

# 5. 检查 PHP-FPM 服务
sudo systemctl status php*-fpm

# 6. 检查 PHP-FPM socket
ls -l /var/run/php/*.sock

# 7. 重新加载 Nginx
sudo systemctl reload nginx

# 8. 测试访问
curl -v http://localhost/
curl -v http://[::1]/
```

## 手动修复步骤

如果重新安装不可行，可以手动修复：

### 步骤 1: 修复 location / 配置

编辑 Nginx 配置文件：
```bash
sudo nano /etc/nginx/sites-available/ipv6-wireguard-manager
```

找到 `location /` 部分，修改为：
```nginx
location / {
    try_files $uri $uri/ /index.php$is_args$args;
}
```

### 步骤 2: 确保 IPv6 监听配置

检查是否有 IPv6 监听：
```nginx
server {
    listen 80;
    listen [::]:80;  # 确保这行存在
    ...
}
```

如果没有，添加 IPv6 监听：
```bash
sudo sed -i '/listen 80;/a\    listen [::]:80;' /etc/nginx/sites-available/ipv6-wireguard-manager
```

### 步骤 3: 验证并重载

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### 步骤 4: 检查 PHP-FPM

```bash
# 确保 PHP-FPM 正在运行
sudo systemctl start php*-fpm
sudo systemctl enable php*-fpm

# 检查 socket
ls -l /var/run/php/*.sock

# 如果 socket 路径不匹配，更新 Nginx 配置中的 fastcgi_pass
```

## 预期结果

修复后应该能够：

1. ✅ 通过 IPv4 访问前端：`http://服务器IP/`
2. ✅ 通过 IPv6 访问前端：`http://[服务器IPv6]/`
3. ✅ 访问返回 PHP 路由的页面，而不是 404

## 故障排除

### 如果仍然返回 404

1. **检查前端文件是否存在**:
```bash
ls -la /var/www/html/index.php
```

2. **检查文件权限**:
```bash
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

3. **检查 Nginx 错误日志**:
```bash
sudo tail -f /var/log/nginx/error.log
```

4. **检查 PHP-FPM 错误日志**:
```bash
sudo tail -f /var/log/php*-fpm.log
```

5. **测试 PHP 文件直接执行**:
```bash
php /var/www/html/index.php
```

### 如果 IPv6 仍然无法访问

1. **检查系统 IPv6 支持**:
```bash
ip -6 addr show
ping6 -c 4 ::1
```

2. **检查 Nginx 是否监听 IPv6**:
```bash
sudo netstat -tlnp | grep :80
# 应该看到 :::80 和 0.0.0.0:80
```

3. **检查防火墙**:
```bash
sudo ufw status
sudo firewall-cmd --list-all
```

## 预防措施

1. **在新安装时**:
   - 使用最新版本的 `install.sh`
   - 确保 `IPV6_SUPPORT` 检测正常工作
   - 验证前端文件正确部署

2. **定期检查**:
   - 运行 `fix_frontend_404.sh` 诊断脚本
   - 检查 Nginx 和 PHP-FPM 服务状态
   - 监控错误日志

---

**修复版本**: 3.0.0  
**最后更新**: 2025-11-01

