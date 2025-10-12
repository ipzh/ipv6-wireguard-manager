# 远程访问配置指南

## 🌐 概述

本指南介绍如何配置IPv6 WireGuard Manager的远程访问，包括防火墙配置和云服务商安全组设置。

## 🔌 需要开放的端口

### 必需端口

| 端口 | 协议 | 服务 | 说明 |
|------|------|------|------|
| 80 | TCP | HTTP | 前端Web界面访问 |
| 443 | TCP | HTTPS | 加密Web访问（推荐） |
| 22 | TCP | SSH | 服务器管理访问 |

## 🚀 快速配置

### 自动配置

```bash
# 自动配置远程访问
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/configure-remote-access.sh | bash
```

### 手动配置

#### UFW防火墙配置

```bash
# 安装UFW（如果未安装）
sudo apt update
sudo apt install ufw

# 开放端口
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS

# 启用防火墙
sudo ufw enable

# 查看状态
sudo ufw status
```

#### Firewalld防火墙配置

```bash
# 开放端口
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# 重新加载配置
sudo firewall-cmd --reload

# 查看状态
sudo firewall-cmd --list-all
```

## ☁️ 云服务商安全组配置

### AWS EC2

1. 登录AWS控制台
2. 进入EC2服务
3. 选择"安全组"
4. 编辑入站规则：
   - 类型：HTTP，端口：80，源：0.0.0.0/0
   - 类型：HTTPS，端口：443，源：0.0.0.0/0
   - 类型：SSH，端口：22，源：您的IP

### 阿里云ECS

1. 登录阿里云控制台
2. 进入ECS服务
3. 选择"安全组"
4. 添加入方向规则：
   - 协议类型：TCP，端口范围：80/80，授权对象：0.0.0.0/0
   - 协议类型：TCP，端口范围：443/443，授权对象：0.0.0.0/0
   - 协议类型：TCP，端口范围：22/22，授权对象：您的IP

### 腾讯云CVM

1. 登录腾讯云控制台
2. 进入CVM服务
3. 选择"安全组"
4. 添加入站规则：
   - 类型：HTTP，端口：80，来源：0.0.0.0/0
   - 类型：HTTPS，端口：443，来源：0.0.0.0/0
   - 类型：SSH，端口：22，来源：您的IP

## 🔍 端口检查

### 检查端口监听状态

```bash
# 检查所有监听端口
ss -tlnp

# 检查特定端口
ss -tlnp | grep :80
ss -tlnp | grep :443
```

### 检查防火墙状态

```bash
# UFW状态
sudo ufw status

# Firewalld状态
sudo firewall-cmd --list-all
```

### 测试端口连通性

```bash
# 从外部测试端口
telnet 您的服务器IP 80
telnet 您的服务器IP 443

# 使用nc测试
nc -zv 您的服务器IP 80
nc -zv 您的服务器IP 443
```

## 🌐 访问地址

### IPv4访问

```
http://您的服务器IPv4地址
https://您的服务器IPv4地址
```

### IPv6访问

```
http://[您的服务器IPv6地址]
https://[您的服务器IPv6地址]
```

### API访问

```
http://您的服务器IP/api/v1/status
http://您的服务器IP/health
```

## 🔧 故障排除

### 常见问题

#### 1. 端口未监听

```bash
# 检查服务状态
sudo systemctl status nginx
sudo systemctl status ipv6-wireguard-manager

# 启动服务
sudo systemctl start nginx
sudo systemctl start ipv6-wireguard-manager
```

#### 2. 防火墙阻止访问

```bash
# 检查防火墙规则
sudo ufw status
sudo firewall-cmd --list-all

# 临时关闭防火墙测试
sudo ufw disable
# 或
sudo systemctl stop firewalld
```

#### 3. 云服务商安全组问题

- 检查安全组规则是否正确
- 确认源IP地址范围
- 验证协议类型和端口号

#### 4. 网络连接问题

```bash
# 测试网络连通性
ping 您的服务器IP

# 测试端口连通性
telnet 您的服务器IP 80

# 检查路由
traceroute 您的服务器IP
```

## 🔐 安全建议

### 1. 最小权限原则

- 只开放必要的端口
- 限制SSH访问源IP
- 使用非标准端口（可选）

### 2. 加密传输

```bash
# 配置HTTPS（推荐）
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d 您的域名
```

### 3. 定期更新

```bash
# 更新系统
sudo apt update && sudo apt upgrade

# 更新应用
./manage.sh update
```

### 4. 监控访问

```bash
# 查看访问日志
sudo tail -f /var/log/nginx/access.log

# 查看连接状态
ss -tuln
```

## 📊 端口使用说明

### 端口80 (HTTP)
- **用途**: 前端Web界面访问
- **必需**: 是
- **安全**: 建议配置HTTPS

### 端口443 (HTTPS)
- **用途**: 加密Web访问
- **必需**: 推荐
- **安全**: 高

### 端口22 (SSH)
- **用途**: 服务器管理
- **必需**: 是
- **安全**: 限制访问源IP

## 🎯 最佳实践

### 1. 分层防护

- 云服务商安全组（第一层）
- 系统防火墙（第二层）
- 应用层安全（第三层）

### 2. 监控和日志

- 启用访问日志
- 监控异常连接
- 定期检查安全状态

### 3. 备份和恢复

- 定期备份配置
- 测试恢复流程
- 文档化配置变更

## 📋 检查清单

### 安装后检查

- [ ] 服务正常运行
- [ ] 端口正确监听
- [ ] 防火墙规则配置
- [ ] 云服务商安全组设置
- [ ] 远程访问测试
- [ ] 日志记录正常

### 定期维护

- [ ] 检查端口状态
- [ ] 更新防火墙规则
- [ ] 监控访问日志
- [ ] 测试远程访问
- [ ] 更新安全配置

## 🆘 获取帮助

### 在线资源

- **GitHub仓库**: https://github.com/ipzh/ipv6-wireguard-manager
- **问题报告**: https://github.com/ipzh/ipv6-wireguard-manager/issues

### 本地帮助

```bash
# 查看管理脚本帮助
./manage.sh help

# 运行健康检查
./manage.sh health

# 查看访问地址
./manage.sh access
```

## 📝 总结

配置远程访问需要：

1. **开放必要端口** (80, 443, 22)
2. **配置系统防火墙** (UFW/Firewalld)
3. **设置云服务商安全组**
4. **测试远程访问**
5. **监控和维护**

使用提供的配置脚本可以自动化大部分配置过程，确保IPv6 WireGuard Manager能够正常远程访问。