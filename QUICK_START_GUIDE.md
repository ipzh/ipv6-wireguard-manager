# IPv6 WireGuard Manager 快速启动指南

## 🚀 快速开始

### 方式一：一键安装（推荐）
使用智能安装脚本，自动配置所有参数：
```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 或者下载后运行
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh
chmod +x install.sh
./install.sh
```

### 方式二：Docker Compose 直接启动
如果您已经有项目文件：
```bash
# 直接启动（自动生成模式）
docker-compose up -d

# 查看自动生成的凭据
docker-compose logs backend | grep "自动生成的"
```

### 方式三：手动配置
复制模板文件并自定义：
```bash
cp env.template .env
# 编辑 .env 文件，设置您的密钥和密码
docker-compose up -d
```

### 3. 检查服务状态
```bash
docker-compose ps
```

### 4. 查看日志
```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs backend
docker-compose logs frontend
docker-compose logs mysql
```

## 🔧 服务访问

### 后端 API
- **地址**: http://localhost:8000
- **健康检查**: http://localhost:8000/api/v1/health
- **API 文档**: http://localhost:8000/docs

### 前端 Web 界面
- **地址**: http://localhost:80
- **健康检查**: http://localhost:80/health

### 数据库
- **类型**: MySQL 8.0
- **端口**: 3306
- **数据库**: ipv6wgm
- **用户**: ipv6wgm
- **密码**: password

### Redis (可选)
- **端口**: 6379
- **密码**: 无

## 🔐 登录信息

### 自动生成模式
- **用户名**: admin
- **密码**: 查看启动日志获取自动生成的密码
```bash
docker-compose logs backend | grep "自动生成的超级用户密码"
```

### 手动配置模式
- **用户名**: admin
- **密码**: 您在 .env 文件中设置的密码

## 📋 服务说明

### 已修复的问题
✅ 端口映射问题 - 使用固定容器端口  
✅ 健康检查问题 - 改用 curl 命令  
✅ 数据库连接问题 - 修复 URL 格式  
✅ 前端路径问题 - 移除重复前缀  
✅ 配置校验问题 - 强密码和长密钥  
✅ 文件缺失问题 - 创建必要配置文件  

### 服务依赖关系
```
mysql → backend → frontend
redis → backend
nginx → frontend + backend
```

## 🛠️ 故障排除

### 1. 服务启动失败
```bash
# 查看详细错误信息
docker-compose logs [service_name]

# 重启特定服务
docker-compose restart [service_name]
```

### 2. 数据库连接问题
```bash
# 检查数据库状态
docker-compose exec mysql mysql -u root -p -e "SHOW DATABASES;"
```

### 3. 前端无法访问
```bash
# 检查前端服务
docker-compose exec frontend curl -f http://localhost/health
```

### 4. 端口冲突
如果端口被占用，可以修改 `.env` 文件中的端口配置：
```bash
API_PORT=8001
WEB_PORT=8080
MYSQL_PORT=3307
```

## 🔒 安全建议

1. **修改默认密码**: 首次登录后立即修改管理员密码
2. **更新密钥**: 生产环境请生成新的 SECRET_KEY
3. **配置 SSL**: 生产环境请配置有效的 SSL 证书
4. **防火墙**: 仅开放必要的端口
5. **定期备份**: 定期备份数据库和配置文件

## 📞 支持

如果遇到问题，请检查：
1. Docker 和 Docker Compose 是否正确安装
2. 端口是否被其他服务占用
3. 系统资源是否充足
4. 防火墙设置是否正确

## 🎯 下一步

1. 访问 http://localhost 进行初始配置
2. 设置 WireGuard 服务器
3. 创建客户端配置
4. 配置监控和日志
5. 设置自动备份
