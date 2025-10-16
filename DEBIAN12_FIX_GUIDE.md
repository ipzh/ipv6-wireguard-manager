# Debian 12 环境修复指南

## 🎯 问题概述

在Debian 12系统上安装IPv6 WireGuard Manager时，可能遇到以下问题：

1. **Apache意外安装** - 系统可能安装了Apache而不是Nginx
2. **PHP-FPM未安装** - PHP-FPM服务缺失
3. **Python版本检测错误** - 系统兼容性测试脚本的版本比较问题
4. **API服务启动失败** - 由于环境问题导致的后端服务无法启动

## 🔧 修复步骤

### 步骤1: 修复系统兼容性测试脚本

首先修复Python版本检测问题：

```bash
# 修复后的脚本会正确检测Python 3.11版本
./test_system_compatibility.sh
```

### 步骤2: 修复Debian 12环境问题

运行环境修复脚本，解决Apache和PHP-FPM问题：

```bash
# 设置执行权限
chmod +x fix_debian12_environment.sh

# 运行环境修复
./fix_debian12_environment.sh
```

这个脚本会：
- ✅ 停止并卸载Apache
- ✅ 安装PHP-FPM
- ✅ 确保Nginx正常运行
- ✅ 检查端口冲突

### 步骤3: 修复API服务

运行API服务修复脚本：

```bash
# 设置执行权限
chmod +x fix_debian12_api_service.sh

# 运行API服务修复
./fix_debian12_api_service.sh
```

这个脚本会：
- ✅ 修复Python环境
- ✅ 修复权限问题
- ✅ 修复配置文件
- ✅ 测试应用启动
- ✅ 启动API服务

### 步骤4: 验证修复结果

运行系统兼容性测试验证修复：

```bash
./test_system_compatibility.sh
```

期望结果：
- ✅ Python版本检测正确
- ✅ 未检测到Apache
- ✅ PHP-FPM已安装
- ✅ Nginx正常运行

## 📋 详细修复说明

### Apache问题修复

**问题**: 系统意外安装了Apache，与Nginx冲突

**解决方案**:
```bash
# 停止Apache服务
sudo systemctl stop apache2
sudo systemctl disable apache2

# 卸载Apache
sudo apt-get remove --purge -y apache2 apache2-utils apache2-bin apache2-data
sudo apt-get autoremove -y

# 删除Apache配置文件
sudo rm -f /opt/ipv6-wireguard-manager/php-frontend/.htaccess
sudo rm -rf /etc/apache2
```

### PHP-FPM问题修复

**问题**: PHP-FPM未安装，导致PHP前端无法正常工作

**解决方案**:
```bash
# 检查PHP版本
php --version

# 安装对应版本的PHP-FPM
sudo apt-get install -y php8.2-fpm  # 对于PHP 8.2
# 或
sudo apt-get install -y php8.1-fpm  # 对于PHP 8.1

# 启动PHP-FPM服务
sudo systemctl start php8.2-fpm
sudo systemctl enable php8.2-fpm
```

### Python版本检测修复

**问题**: 系统兼容性测试脚本使用字符串比较导致Python 3.11被误判为版本过低

**解决方案**: 已修复为使用Python内置版本比较：
```python
python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)"
```

### API服务启动修复

**问题**: 由于环境问题导致API服务无法启动

**解决方案**:
1. 修复Python环境依赖
2. 修复目录权限
3. 修复配置文件
4. 测试应用导入
5. 重新启动服务

## 🚀 一键修复

如果你想要一键修复所有问题，可以运行：

```bash
# 1. 修复环境问题
./fix_debian12_environment.sh

# 2. 修复API服务
./fix_debian12_api_service.sh

# 3. 验证修复结果
./test_system_compatibility.sh
```

## 🔍 故障排除

### 如果环境修复失败

```bash
# 检查系统状态
sudo systemctl status nginx
sudo systemctl status php8.2-fpm

# 检查端口占用
sudo netstat -tlnp | grep -E ":(80|443) "

# 查看错误日志
sudo journalctl -u nginx -f
sudo journalctl -u php8.2-fpm -f
```

### 如果API服务修复失败

```bash
# 检查服务状态
sudo systemctl status ipv6-wireguard-manager

# 查看服务日志
sudo journalctl -u ipv6-wireguard-manager -f

# 手动测试应用启动
cd /opt/ipv6-wireguard-manager
sudo -u ipv6wgm ./venv/bin/python -c "from backend.app.main import app; print('OK')"
```

### 如果端口冲突

```bash
# 查看端口占用
sudo netstat -tlnp | grep ":80 "

# 停止冲突的服务
sudo systemctl stop apache2
sudo systemctl stop httpd

# 启动正确的服务
sudo systemctl start nginx
```

## 📊 修复后验证

修复完成后，你应该看到：

1. **系统兼容性测试**:
   ```
   [SUCCESS] ✓ Python版本满足要求 (>= 3.8)
   [SUCCESS] ✓ Nginx已安装
   [SUCCESS] ✓ PHP-FPM已安装
   [SUCCESS] 🎉 系统完全兼容！
   ```

2. **API服务状态**:
   ```bash
   sudo systemctl status ipv6-wireguard-manager
   # 应该显示: Active: active (running)
   ```

3. **端口监听**:
   ```bash
   sudo netstat -tlnp | grep ":8000 "
   # 应该显示API服务监听8000端口
   ```

4. **API健康检查**:
   ```bash
   curl http://localhost:8000/api/v1/health
   # 应该返回健康状态
   ```

## 🎉 完成

修复完成后，你的IPv6 WireGuard Manager应该能够正常运行：

- ✅ 前端页面: http://localhost/
- ✅ API文档: http://localhost:8000/docs
- ✅ API健康检查: http://localhost:8000/api/v1/health

如果还有问题，请运行综合诊断脚本：
```bash
./comprehensive_api_diagnosis.sh
```
