# IPv6 WireGuard Manager

一个现代化的IPv6 WireGuard管理平台，支持IPv4和IPv6双栈网络，提供直观的Web界面进行WireGuard配置和管理。

## ✨ 特性

- 🌐 **双栈支持**: 完整支持IPv4和IPv6网络
- 🎨 **现代化界面**: 基于React + TypeScript + Ant Design
- 🚀 **一键安装**: 支持Docker和原生安装方式
- 📱 **响应式设计**: 适配桌面和移动设备
- 🔧 **智能管理**: 自动检测系统环境，智能选择安装方式
- 🛡️ **安全可靠**: 内置安全配置和权限管理
- 🌍 **域名绑定**: 支持自定义域名配置和SSL证书管理
- 🔐 **SSL支持**: 多种SSL证书提供商，支持自动续期
- 👥 **用户管理**: 完整的用户权限和角色管理系统
- 📊 **实时监控**: WireGuard服务器和客户端状态监控
- 🚦 **BGP管理**: BGP路由宣告和网络管理功能

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

> ⚠️ **安全提醒**: 首次登录后请立即修改默认密码！

## 🎯 主要功能

### 1. 仪表板
- 📊 系统状态概览
- 📈 实时监控数据
- 🔗 快速访问链接
- 📋 最近活动记录

### 2. WireGuard管理
- 🖥️ **服务器管理**: 创建、配置、启动/停止WireGuard服务器
- 👤 **客户端管理**: 添加、编辑、删除客户端配置
- 📱 **QR码生成**: 快速分享客户端配置
- 📄 **配置文件下载**: 支持.conf文件下载

### 3. 网络管理
- 🚦 **BGP宣告**: 管理BGP路由宣告
- 🌐 **网络接口**: 监控网络接口状态
- 🔥 **防火墙规则**: 配置防火墙规则

### 4. 用户管理
- 👥 **用户列表**: 查看和管理系统用户
- 🔐 **权限控制**: 基于角色的权限管理
- 📊 **登录统计**: 用户登录记录和统计

### 5. 系统设置
- ⚙️ **系统配置**: 网络参数、日志级别等
- 🔐 **安全设置**: 密码策略、会话管理等
- 🌍 **域名与SSL**: 自定义域名和SSL证书配置
- 🔧 **系统管理**: 完全卸载、重新安装、备份恢复

## 🌍 域名与SSL配置

### 域名绑定
1. 进入 **系统设置** → **域名与SSL**
2. 在 **域名配置** 部分输入您的自定义域名
3. 点击 **测试域名连接** 验证域名解析
4. 保存配置

### SSL证书配置

#### 方式一：Let's Encrypt（推荐）
1. 启用 **SSL** 选项
2. 选择 **Let's Encrypt** 作为SSL提供商
3. 配置DNS提供商（Cloudflare、阿里云DNS等）
4. 输入DNS API密钥
5. 启用 **自动续期SSL证书**
6. 点击 **生成SSL证书**

#### 方式二：自定义证书
1. 启用 **SSL** 选项
2. 选择 **自定义证书** 作为SSL提供商
3. 选择以下任一方式：
   - **文件路径方式**：输入证书和私钥文件路径
   - **内容方式**：直接粘贴证书和私钥内容
4. 保存配置

#### 方式三：Cloudflare SSL
1. 启用 **SSL** 选项
2. 选择 **Cloudflare** 作为SSL提供商
3. 配置Cloudflare API密钥
4. 保存配置

### 支持的DNS提供商
- **Cloudflare**: 全球CDN，性能优秀
- **阿里云DNS**: 国内访问速度快
- **腾讯云DNS**: 稳定可靠
- **DNSPod**: 腾讯旗下DNS服务

### SSL证书类型
- **Let's Encrypt**: 免费，自动续期，有效期90天
- **自定义证书**: 支持任何有效的SSL证书
- **Cloudflare**: 通过Cloudflare代理的SSL

## 🔧 系统管理

### 系统操作
系统管理功能允许管理员通过Web界面执行高级系统操作：

#### 完全卸载系统
1. 进入 **系统设置** → **系统管理**
2. 点击 **"完全卸载系统"** 按钮
3. 输入 **"UNINSTALL"** 确认操作
4. 系统将自动执行以下操作：
   - 停止所有相关服务
   - 备份重要配置文件
   - 删除应用文件
   - 清理数据库
   - 移除系统配置

#### 重新安装系统
1. 进入 **系统设置** → **系统管理**
2. 点击 **"重新安装系统"** 按钮
3. 输入 **"REINSTALL"** 确认操作
4. 系统将自动执行以下操作：
   - 创建当前配置备份
   - 下载最新版本
   - 重新安装依赖
   - 恢复配置
   - 重启服务

### 系统信息监控
- **版本信息**: 显示当前系统版本
- **安装时间**: 系统首次安装时间
- **服务状态**: 实时监控后端服务、数据库、Nginx状态
- **运行时间**: 系统运行时长统计

### 备份与恢复
- **自动备份**: 重要操作前自动创建备份
- **手动备份**: 支持手动创建系统备份
- **备份恢复**: 从备份文件恢复系统
- **配置导出**: 导出系统配置文件

### 安全特性
- **权限控制**: 只有管理员可以执行系统操作
- **双重确认**: 需要输入特定文本确认操作
- **操作日志**: 记录所有系统操作
- **进度跟踪**: 实时显示操作进度和状态

## 👥 用户管理

### 用户角色
- **管理员**: 拥有所有权限，可以管理用户、系统设置等
- **操作员**: 可以管理WireGuard服务器和客户端
- **查看者**: 只能查看系统状态，不能进行修改操作

### 用户操作
1. **添加用户**: 在用户管理页面点击"添加用户"
2. **编辑用户**: 点击用户列表中的"编辑"按钮
3. **删除用户**: 点击用户列表中的"删除"按钮
4. **激活/停用**: 可以临时停用用户而不删除

### 个人信息管理
- **修改用户名**: 在系统设置中修改用户名
- **修改邮箱**: 更新联系邮箱地址
- **修改密码**: 更改登录密码
- **查看登录记录**: 查看最近登录时间和次数

## 📊 监控与统计

### 实时监控
- **服务器状态**: 实时显示WireGuard服务器运行状态
- **客户端连接**: 监控客户端连接数和流量统计
- **系统资源**: CPU、内存、磁盘使用情况
- **网络流量**: 实时网络流量监控

### 统计报告
- **用户登录统计**: 用户登录次数和时间分布
- **流量统计**: 各客户端流量使用情况
- **系统性能**: 系统运行性能指标
- **错误日志**: 系统错误和警告信息

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

#### 4. SSL证书问题
```bash
# 检查SSL证书状态
sudo certbot certificates

# 检查证书文件权限
ls -la /etc/ssl/certs/ipv6wg.crt
ls -la /etc/ssl/private/ipv6wg.key

# 测试SSL连接
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

#### 5. 域名解析问题
```bash
# 检查域名解析
nslookup your-domain.com
dig your-domain.com

# 检查DNS配置
cat /etc/resolv.conf
```

#### 6. 用户权限问题
```bash
# 检查数据库用户权限
sudo -u postgres psql -c "\du"

# 重置用户密码
sudo -u postgres psql -c "ALTER USER ipv6wgm PASSWORD 'new_password';"
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

### 基础安全
1. **更改默认密码**: 安装后立即更改默认登录密码
2. **配置防火墙**: 只开放必要的端口（80, 443, 22）
3. **启用HTTPS**: 配置SSL证书以加密传输
4. **定期更新**: 保持系统和应用更新

### 高级安全
5. **用户权限管理**: 
   - 创建不同角色的用户账户
   - 定期审查用户权限
   - 禁用不必要的用户账户
6. **SSL证书管理**:
   - 使用Let's Encrypt自动续期
   - 定期检查证书有效期
   - 配置HSTS安全头
7. **网络安全**:
   - 配置IP白名单
   - 启用访问日志记录
   - 监控异常登录行为
8. **数据备份**:
   - 定期备份配置文件
   - 备份用户数据和设置
   - 测试备份恢复流程

### 生产环境建议
- 使用强密码策略
- 启用双因素认证（如支持）
- 配置日志监控和告警
- 定期进行安全审计

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

## 📚 文档资源

- **[快速入门指南](QUICK_START.md)**: 5分钟快速部署指南
- **[功能详细说明](FEATURES.md)**: 完整功能文档
- **[API文档](API.md)**: RESTful API接口文档
- **[部署指南](DEPLOYMENT.md)**: 详细部署说明

## 🆘 获取帮助

- **GitHub Issues**: [提交问题](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- **快速修复**: 使用内置的故障排除脚本
- **社区支持**: 参与用户讨论和经验分享

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🤝 贡献

欢迎贡献代码！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解如何参与项目开发。

---

**注意**: 请确保在生产环境中更改默认密码并配置适当的安全措施。