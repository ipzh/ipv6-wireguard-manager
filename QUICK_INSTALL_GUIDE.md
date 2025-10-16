# IPv6 WireGuard Manager - 快速安装指南

## 🚀 一键安装

### 完整功能安装 (推荐)
```bash
# 下载并运行完整安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --enable-all
```

### 生产环境安装
```bash
# 生产环境 + 安全加固
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --production --enable-security --enable-ssl
```

### 开发环境安装
```bash
# 开发环境 + 监控
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --debug --enable-monitoring
```

## 📋 安装选项

### 基础选项
- `--type full` - 完整安装 (推荐)
- `--type native` - 原生安装
- `--type minimal` - 最小化安装
- `--dir /path` - 自定义安装目录
- `--port 80` - Web端口
- `--api-port 8000` - API端口

### 功能选项
- `--enable-all` - 启用所有功能
- `--enable-monitoring` - 系统监控
- `--enable-backup` - 自动备份
- `--enable-security` - 安全加固
- `--enable-ssl` - SSL支持
- `--enable-firewall` - 防火墙配置

### 环境选项
- `--production` - 生产环境模式
- `--performance` - 性能优化模式
- `--debug` - 调试模式
- `--silent` - 静默安装

## 🎯 安装示例

### 1. 企业级部署
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- \
  --type full \
  --production \
  --enable-all \
  --enable-security \
  --enable-ssl \
  --enable-firewall
```

### 2. 开发测试环境
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- \
  --type native \
  --debug \
  --enable-monitoring \
  --port 8080 \
  --api-port 9000
```

### 3. 低资源环境
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- \
  --type minimal \
  --silent
```

## 🔧 安装后管理

### 服务管理
```bash
# 启动服务
ipv6-wireguard-manager start

# 停止服务
ipv6-wireguard-manager stop

# 重启服务
ipv6-wireguard-manager restart

# 查看状态
ipv6-wireguard-manager status
```

### 系统管理
```bash
# 查看日志
ipv6-wireguard-manager logs

# 更新系统
ipv6-wireguard-manager update

# 创建备份
ipv6-wireguard-manager backup

# 系统监控
ipv6-wireguard-manager monitor
```

## 🌐 访问地址

安装完成后，访问以下地址：

- **Web界面**: http://your-server-ip/
- **API文档**: http://your-server-ip:8000/docs
- **健康检查**: http://your-server-ip:8000/health

## 👤 默认账户

- **用户名**: admin
- **密码**: admin123

> ⚠️ 首次登录后请立即修改默认密码！

## 📊 系统要求

### 最低要求
- **内存**: 512MB
- **磁盘**: 2GB
- **CPU**: 1核心
- **系统**: Ubuntu 18.04+, Debian 9+, CentOS 7+

### 推荐配置
- **内存**: 2GB+
- **磁盘**: 10GB+
- **CPU**: 2核心+
- **系统**: Ubuntu 20.04+, Debian 11+, CentOS 8+

## 🆘 常见问题

### Q: 安装失败怎么办？
A: 检查系统要求，确保有足够的磁盘空间和内存，然后重新运行安装脚本。

### Q: 如何修改端口？
A: 使用 `--port` 和 `--api-port` 参数指定端口。

### Q: 如何启用SSL？
A: 使用 `--enable-ssl` 参数，然后手动配置SSL证书。

### Q: 如何备份数据？
A: 使用 `ipv6-wireguard-manager backup` 命令或配置自动备份。

### Q: 如何更新系统？
A: 使用 `ipv6-wireguard-manager update` 命令。

## 📞 技术支持

- **项目地址**: https://github.com/ipzh/ipv6-wireguard-manager
- **问题反馈**: https://github.com/ipzh/ipv6-wireguard-manager/issues
- **文档**: https://github.com/ipzh/ipv6-wireguard-manager/wiki

## 🎉 安装完成！

恭喜！您已经成功安装了IPv6 WireGuard Manager。现在可以开始使用这个强大的VPN管理平台了！

### 下一步
1. 访问Web界面
2. 修改默认密码
3. 配置WireGuard服务器
4. 添加客户端
5. 开始使用！

享受您的VPN管理体验！ 🚀
