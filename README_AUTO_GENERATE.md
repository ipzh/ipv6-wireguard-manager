# IPv6 WireGuard Manager - 自动生成模式

## 🚀 一键启动

系统现在支持**自动生成模式**，无需手动配置即可启动！

### 快速开始

```bash
# 方式一：直接启动（推荐）
docker-compose up -d

# 方式二：使用自动安装脚本
./auto_install.sh
```

### 🔑 自动生成的凭据

系统会自动生成：
- **SECRET_KEY**: 64字符强密钥
- **FIRST_SUPERUSER_PASSWORD**: 16字符强密码

### 📋 获取登录信息

启动后查看日志获取自动生成的凭据：

```bash
# 查看所有自动生成的凭据
docker-compose logs backend | grep "自动生成的"

# 或者查看完整的后端日志
docker-compose logs backend
```

### 🌐 访问地址

- **前端界面**: http://localhost
- **后端 API**: http://localhost:8000
- **API 文档**: http://localhost:8000/docs

### 🔐 登录信息

- **用户名**: `admin`
- **密码**: 查看启动日志中的自动生成密码

## 🛠️ 高级配置

### 手动配置模式

如果您想使用自定义的密钥和密码：

```bash
# 1. 复制模板文件
cp env.template .env

# 2. 编辑 .env 文件，设置您的配置
# SECRET_KEY=your_custom_secret_key
# FIRST_SUPERUSER_PASSWORD=your_custom_password

# 3. 启动服务
docker-compose up -d
```

### 环境变量覆盖

您也可以通过环境变量覆盖自动生成的配置：

```bash
# 设置自定义密钥和密码
export SECRET_KEY="your_custom_secret_key"
export FIRST_SUPERUSER_PASSWORD="your_custom_password"

# 启动服务
docker-compose up -d
```

## 📊 服务管理

### 查看服务状态
```bash
docker-compose ps
```

### 查看服务日志
```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs backend
docker-compose logs frontend
docker-compose logs mysql
```

### 重启服务
```bash
# 重启所有服务
docker-compose restart

# 重启特定服务
docker-compose restart backend
```

### 停止服务
```bash
docker-compose down
```

## 🔧 故障排除

### 1. 服务启动失败
```bash
# 查看详细错误信息
docker-compose logs [service_name]

# 检查服务状态
docker-compose ps
```

### 2. 端口冲突
如果默认端口被占用，可以修改 `.env` 文件中的端口配置：
```bash
API_PORT=8001
WEB_PORT=8080
MYSQL_PORT=3307
```

### 3. 数据库连接问题
```bash
# 检查数据库状态
docker-compose exec mysql mysql -u root -p -e "SHOW DATABASES;"
```

## 🔒 安全建议

1. **首次登录后立即修改密码**
2. **生产环境请使用自定义密钥**
3. **定期备份数据库和配置**
4. **配置 SSL 证书**
5. **设置防火墙规则**

## 📞 支持

如果遇到问题：
1. 检查 Docker 和 Docker Compose 是否正确安装
2. 确保端口没有被其他服务占用
3. 查看服务日志获取详细错误信息
4. 检查系统资源是否充足

## 🎯 下一步

1. 访问 http://localhost 进行初始配置
2. 设置 WireGuard 服务器
3. 创建客户端配置
4. 配置监控和日志
5. 设置自动备份
