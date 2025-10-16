# IPv6 WireGuard Manager - 安装脚本总结

## 📋 概述

IPv6 WireGuard Manager 提供了完整的安装脚本套件，支持多种Linux系统，确保在各种环境下都能成功部署。

## 🚀 安装脚本套件

### 1. 主安装脚本

#### `install.sh` - 原始安装脚本
- **功能**: 完整的安装流程，支持多种安装模式
- **特点**: 功能丰富，支持Docker、原生、最小化安装
- **适用**: 生产环境和开发环境

#### `install_enhanced.sh` - 增强安装脚本
- **功能**: 改进的安装脚本，增强错误处理和兼容性
- **特点**: 
  - 更好的系统检测
  - 增强的错误处理
  - 支持更多Linux发行版
  - 智能安装类型推荐
- **适用**: 推荐用于生产环境

### 2. 辅助脚本

#### `test_system_compatibility.sh` - 系统兼容性测试
- **功能**: 测试系统兼容性，检查依赖和配置
- **特点**:
  - 全面的系统检测
  - 依赖检查
  - 兼容性评分
  - 安装建议
- **用法**: `./test_system_compatibility.sh`

#### `verify_installation.sh` - 安装验证
- **功能**: 验证安装是否成功，检查所有组件
- **特点**:
  - 服务状态检查
  - 端口监听检查
  - 数据库连接测试
  - Web服务测试
  - API服务测试
  - 性能测试
- **用法**: `./verify_installation.sh`

#### `fix_php_fpm.sh` - PHP-FPM修复
- **功能**: 修复PHP-FPM服务启动问题
- **特点**:
  - 自动检测PHP-FPM服务
  - 智能安装PHP-FPM
  - 配置优化
  - 服务启动
- **用法**: `./fix_php_fpm.sh`

## 🖥️ 支持的系统

### 完全支持的系统
- **Ubuntu**: 18.04, 20.04, 22.04, 24.04
- **Debian**: 9, 10, 11, 12
- **CentOS**: 7, 8, 9
- **RHEL**: 7, 8, 9
- **Fedora**: 30+
- **Arch Linux**: 最新版本
- **openSUSE**: 15+

### 部分支持的系统
- **Gentoo**: 需要手动配置
- **Alpine Linux**: 基础支持
- **其他发行版**: 可能需要手动调整

## 📦 支持的包管理器

- **APT**: Ubuntu/Debian
- **YUM/DNF**: CentOS/RHEL/Fedora
- **Pacman**: Arch Linux
- **Zypper**: openSUSE
- **Emerge**: Gentoo
- **APK**: Alpine Linux

## 🔧 安装模式

### 1. Docker安装
```bash
./install_enhanced.sh --type docker
```
- **优点**: 完全隔离、易于管理、可移植性强
- **缺点**: 资源占用较高、启动较慢
- **要求**: 内存 ≥ 4GB，磁盘 ≥ 10GB

### 2. 原生安装
```bash
./install_enhanced.sh --type native
```
- **优点**: 性能最佳、资源占用低、启动快速
- **缺点**: 依赖系统环境、配置复杂
- **要求**: 内存 ≥ 2GB，磁盘 ≥ 5GB

### 3. 最小化安装
```bash
./install_enhanced.sh --type minimal
```
- **优点**: 资源占用最低、启动最快
- **缺点**: 功能受限、性能一般
- **要求**: 内存 ≥ 1GB，磁盘 ≥ 3GB

## 🚀 快速开始

### 1. 系统兼容性测试
```bash
# 下载并运行兼容性测试
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/test_system_compatibility.sh | bash
```

### 2. 一键安装
```bash
# 使用增强安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install_enhanced.sh | bash

# 或指定安装类型
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install_enhanced.sh | bash -s -- --type minimal --silent
```

### 3. 验证安装
```bash
# 运行安装验证
./verify_installation.sh
```

## ⚙️ 安装选项

### 基本选项
- `--type TYPE`: 安装类型 (docker|native|minimal)
- `--dir DIR`: 安装目录 (默认: /opt/ipv6-wireguard-manager)
- `--port PORT`: Web端口 (默认: 80)
- `--api-port PORT`: API端口 (默认: 8000)

### 功能选项
- `--silent`: 静默安装
- `--production`: 生产环境安装
- `--performance`: 性能优化安装
- `--debug`: 调试模式

### 跳过选项
- `--skip-deps`: 跳过依赖安装
- `--skip-db`: 跳过数据库配置
- `--skip-service`: 跳过服务创建
- `--skip-frontend`: 跳过前端部署

## 🔍 故障排除

### 常见问题

#### 1. PHP-FPM服务启动失败
```bash
# 运行PHP-FPM修复脚本
./fix_php_fpm.sh
```

#### 2. 数据库连接失败
```bash
# 检查MySQL服务状态
sudo systemctl status mysql
# 或
sudo systemctl status mariadb

# 重启数据库服务
sudo systemctl restart mysql
```

#### 3. 端口占用问题
```bash
# 检查端口占用
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :8000

# 杀死占用进程
sudo kill -9 <PID>
```

#### 4. 权限问题
```bash
# 设置正确的文件权限
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/
```

### 日志查看
```bash
# 应用日志
sudo journalctl -u ipv6-wireguard-manager -f

# Nginx日志
sudo tail -f /var/log/nginx/error.log

# 系统日志
sudo journalctl -f
```

## 📊 安装验证

### 自动验证
```bash
# 运行完整的安装验证
./verify_installation.sh
```

### 手动验证
```bash
# 检查服务状态
sudo systemctl status ipv6-wireguard-manager

# 检查端口监听
sudo netstat -tlnp | grep -E ":(80|8000) "

# 测试Web访问
curl -f http://localhost/

# 测试API访问
curl -f http://localhost:8000/api/v1/health
```

## 🎯 最佳实践

### 1. 安装前准备
- 运行系统兼容性测试
- 确保系统资源充足
- 备份重要数据
- 更新系统包

### 2. 安装过程
- 使用增强安装脚本
- 选择合适的安装类型
- 记录安装日志
- 验证每个步骤

### 3. 安装后验证
- 运行安装验证脚本
- 检查所有服务状态
- 测试所有功能
- 配置监控和备份

## 📚 相关文档

- [生产部署指南](PRODUCTION_DEPLOYMENT_GUIDE.md)
- [故障排除手册](TROUBLESHOOTING_MANUAL.md)
- [API参考文档](docs/API_REFERENCE_DETAILED.md)
- [用户手册](docs/USER_MANUAL.md)

## 🆘 获取帮助

### 在线资源
- GitHub仓库: https://github.com/ipzh/ipv6-wireguard-manager
- 问题反馈: https://github.com/ipzh/ipv6-wireguard-manager/issues
- 文档中心: https://github.com/ipzh/ipv6-wireguard-manager/wiki

### 社区支持
- 技术讨论: GitHub Discussions
- 问题报告: GitHub Issues
- 功能请求: GitHub Issues

---

**IPv6 WireGuard Manager 安装脚本套件** - 让部署变得简单可靠！🚀

通过这套完整的安装脚本，您可以在任何支持的Linux系统上快速、可靠地部署IPv6 WireGuard Manager。
