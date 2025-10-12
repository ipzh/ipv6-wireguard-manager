# IPv6 WireGuard Manager

一个现代化的IPv6 WireGuard管理平台，支持IPv4和IPv6双栈网络，提供直观的Web界面进行WireGuard配置和管理。

## ✨ 特性

- 🌐 **双栈支持**: 完整支持IPv4和IPv6网络
- 🎨 **现代化界面**: 基于React + TypeScript + Ant Design
- 🚀 **一键安装**: 支持Docker和原生安装方式
- 📱 **响应式设计**: 适配桌面和移动设备
- 🔧 **智能管理**: 自动检测系统环境，智能选择安装方式
- 🛡️ **安全可靠**: 内置安全配置和权限管理

## 🖥️ 支持的操作系统

- **Ubuntu** 18.04+ (推荐)
- **Debian** 9+
- **CentOS** 7+
- **RHEL** 7+
- **Fedora** 30+
- **Alpine** 3.10+

## 🚀 快速开始

### 一键安装

```bash
# 自动选择最佳安装方式
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

### 安装选项

```bash
# 下载安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh -o install.sh
chmod +x install.sh

# 运行安装脚本
./install.sh
```

安装脚本提供以下选项：
1. **Docker安装** - 环境隔离，易于管理
2. **原生安装** - 性能最优，资源占用少
3. **自动选择** - 根据系统环境智能选择

## 🌐 访问地址

安装完成后，您可以通过以下地址访问：

### IPv4访问
```
http://您的服务器IPv4地址
```

### IPv6访问
```
http://[您的服务器IPv6地址]
```

### 默认登录信息
- **用户名**: admin
- **密码**: admin123

## 🔧 管理命令

### 服务管理
```bash
# 查看服务状态
sudo systemctl status ipv6-wireguard-manager nginx

# 启动服务
sudo systemctl start ipv6-wireguard-manager nginx

# 停止服务
sudo systemctl stop ipv6-wireguard-manager nginx

# 重启服务
sudo systemctl restart ipv6-wireguard-manager nginx
```

### 日志查看
```bash
# 查看后端服务日志
sudo journalctl -u ipv6-wireguard-manager -f

# 查看Nginx日志
sudo journalctl -u nginx -f

# 查看Nginx错误日志
sudo tail -f /var/log/nginx/error.log
```

### 配置管理
```bash
# 测试Nginx配置
sudo nginx -t

# 重新加载Nginx配置
sudo systemctl reload nginx

# 编辑环境配置
sudo nano /opt/ipv6-wireguard-manager/backend/.env
```

## 🛠️ 故障排除

### 常见问题

#### 1. 服务无法启动
```bash
# 检查服务状态
sudo systemctl status ipv6-wireguard-manager

# 查看详细日志
sudo journalctl -u ipv6-wireguard-manager -n 50
```

#### 2. 前端访问异常
```bash
# 检查前端文件
ls -la /opt/ipv6-wireguard-manager/frontend/dist/

# 重新构建前端
cd /opt/ipv6-wireguard-manager/frontend
npm run build
```

#### 3. IPv6访问问题
```bash
# 检查IPv6地址
ip -6 addr show

# 检查IPv6监听
ss -tlnp | grep :80 | grep "::"
```

### 快速修复

如果遇到问题，可以使用以下快速修复脚本：

```bash
# 修复常见问题
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix-common-issues.sh | bash

# 验证安装状态
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/verify-installation.sh | bash
```

## 📁 项目结构

```
ipv6-wireguard-manager/
├── backend/                 # 后端服务
│   ├── app/                # 应用代码
│   ├── requirements.txt    # Python依赖
│   └── .env               # 环境配置
├── frontend/               # 前端应用
│   ├── src/               # 源代码
│   ├── dist/              # 构建输出
│   └── package.json       # 前端依赖
├── install.sh             # 主安装脚本
├── install-robust.sh      # 健壮安装脚本
└── README.md              # 项目文档
```

## 🔐 安全建议

1. **更改默认密码**: 安装后立即更改默认登录密码
2. **配置防火墙**: 只开放必要的端口（80, 443, 22）
3. **启用HTTPS**: 配置SSL证书以加密传输
4. **定期更新**: 保持系统和应用更新

## 📊 系统要求

### 最低要求
- **CPU**: 1核心
- **内存**: 1GB RAM
- **存储**: 2GB 可用空间
- **网络**: IPv4/IPv6网络连接

### 推荐配置
- **CPU**: 2核心
- **内存**: 2GB RAM
- **存储**: 5GB 可用空间
- **网络**: 稳定的IPv4/IPv6双栈连接

## 🆘 获取帮助

- **GitHub Issues**: [提交问题](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- **文档**: 查看项目Wiki获取详细文档
- **社区**: 参与讨论和交流

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🤝 贡献

欢迎贡献代码！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解如何参与项目开发。

---

**注意**: 请确保在生产环境中更改默认密码并配置适当的安全措施。