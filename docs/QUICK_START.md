# IPv6 WireGuard Manager 快速开始指南

## 🚀 快速安装

### 方式一：一键安装（推荐）

智能安装脚本会自动检测系统环境并配置所有参数：

```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 或者下载后运行
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh
chmod +x install.sh
./install.sh
```

#### 安装选项

```bash
# 指定安装类型
./install.sh --type docker          # Docker安装
./install.sh --type native           # 原生安装
./install.sh --type minimal          # 最小化安装

# 智能安装模式
./install.sh --auto                  # 自动选择参数并退出
./install.sh --silent                # 静默安装（非交互）

# 跳过特定步骤
./install.sh --skip-deps             # 跳过依赖安装
./install.sh --skip-db               # 跳过数据库配置
./install.sh --skip-service          # 跳过服务创建
./install.sh --skip-frontend         # 跳过前端部署

# 生产环境配置
./install.sh --production            # 生产环境安装
./install.sh --performance           # 性能优化安装
./install.sh --debug                 # 调试模式

# 自定义配置
./install.sh --dir /opt/custom       # 自定义安装目录
./install.sh --port 8080             # 自定义Web端口
./install.sh --api-port 9000         # 自定义API端口
```

### 方式二：Docker Compose 快速启动

如果您已经克隆了项目：

```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 直接启动（自动生成模式）
docker-compose up -d

# 查看自动生成的凭据
docker-compose logs backend | grep "自动生成的"
```

### 方式三：手动配置

```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 复制环境配置
cp env.template .env

# 编辑 .env 文件，设置您的密钥和密码
vim .env

# 启动服务
docker-compose up -d
```

### 方式四：原生安装

```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 使用主安装脚本进行原生安装
./install.sh --type native

# 或使用智能模式
./install.sh --auto --type native

# 跳过某些步骤的原生安装
./install.sh --type native --skip-deps --skip-frontend
```

## 🔍 检查服务状态

### Docker 环境

```bash
# 查看所有服务状态
docker-compose ps

# 查看服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs backend
docker-compose logs frontend
docker-compose logs mysql
```

### 原生环境

```bash
# 检查服务状态
sudo systemctl status ipv6-wireguard-manager
sudo systemctl status nginx
sudo systemctl status mysql

# 查看日志
sudo journalctl -u ipv6-wireguard-manager -f
sudo tail -f /var/log/nginx/error.log
```

## 🌐 访问系统

### 主要服务地址

- **Web界面**: http://localhost
- **API接口**: http://localhost/api/v1
- **API文档**: http://localhost/docs
- **健康检查**: http://localhost/health

### 监控面板

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **系统指标**: http://localhost/metrics

### 默认凭据

**自动生成模式（推荐）：**
- **用户名**: admin
- **密码**: 查看启动日志获取
  ```bash
  # Docker环境
  docker-compose logs backend | grep "自动生成的超级用户密码"
  
  # 原生环境
  sudo journalctl -u ipv6-wireguard-manager | grep "自动生成的超级用户密码"
  ```

**手动配置模式：**
- **用户名**: admin
- **密码**: .env 文件中设置的 FIRST_SUPERUSER_PASSWORD

**注意**: 脚本会自动生成强密码，不会使用默认的弱密码。请查看安装日志获取实际密码。

## 🔧 常见操作

### 重启服务

```bash
# Docker 环境
docker-compose restart

# 原生环境
sudo systemctl restart ipv6-wireguard-manager
sudo systemctl restart nginx
```

### 查看日志

```bash
# Docker 环境
docker-compose logs -f

# 原生环境
tail -f logs/app.log
sudo journalctl -u ipv6-wireguard-manager -f
```

### 备份数据

```bash
# 创建备份
docker-compose exec backend python scripts/backup/backup_manager.py --backup

# 或使用内置命令
curl -X POST http://localhost/api/v1/system/backup \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🛠️ 故障排除

### 1. 端口冲突

```bash
# 检查端口占用
netstat -tulpn | grep :80
netstat -tulpn | grep :3306

# 修改端口配置（编辑 .env 文件）
vim .env
# 修改: SERVER_PORT=8080, MYSQL_PORT=3307
```

### 2. 数据库连接失败

```bash
# Docker 环境
docker-compose logs mysql
docker-compose restart mysql

# 原生环境
sudo systemctl status mysql
sudo systemctl restart mysql
```

### 3. 前端无法访问

```bash
# 检查 Nginx 配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx

# 检查前端服务
docker-compose logs frontend
```

### 4. 权限问题

```bash
# 修复文件权限
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# 修复日志权限
sudo chown -R $USER:$USER logs/
sudo chmod -R 755 logs/
```

## 🔒 安全建议

1. **修改默认密码**: 首次登录后立即修改管理员密码
2. **更新密钥**: 生产环境请生成新的 SECRET_KEY 和 JWT_SECRET
3. **配置 SSL**: 生产环境必须配置有效的 SSL 证书
4. **限制访问**: 配置防火墙，仅开放必要的端口
5. **定期备份**: 设置自动备份任务，定期备份数据库和配置
6. **更新系统**: 及时更新系统和依赖包

## 📋 下一步

1. [部署指南](DEPLOYMENT_GUIDE.md) - 生产环境部署
2. [API参考](API_REFERENCE.md) - API接口文档
3. [配置指南](CONFIGURATION_GUIDE.md) - 系统配置说明
4. [故障排除](TROUBLESHOOTING_GUIDE.md) - 常见问题解决

## 📞 获取帮助

如果遇到问题：

1. 检查 [故障排除指南](TROUBLESHOOTING_GUIDE.md)
2. 查看 [文档中心](README.md)
3. 提交 [Issue](https://github.com/ipzh/ipv6-wireguard-manager/issues)
4. 参与 [讨论](https://github.com/ipzh/ipv6-wireguard-manager/discussions)

---

**版本**: v1.0.0  
**最后更新**: 2024-01-01  
**维护团队**: IPv6 WireGuard Manager Team
