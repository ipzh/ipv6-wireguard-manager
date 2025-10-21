# IPv6 WireGuard Manager 快速原生安装指南

## 🚀 一键安装

### Linux/Unix系统
```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 运行原生安装脚本
./scripts/install_native.sh

# 或使用模块化安装脚本
./scripts/install.sh --native-only
```

### 分步安装
```bash
# 1. 环境检查
./scripts/install.sh environment

# 2. 安装依赖
./scripts/install.sh dependencies

# 3. 配置系统
./scripts/install.sh configuration

# 4. 部署应用
./scripts/install.sh deployment

# 5. 启动服务
./scripts/install.sh service

# 6. 验证安装
./scripts/install.sh verification
```

## 🔧 系统要求

### 操作系统
- **Linux**: Ubuntu 20.04+, CentOS 8+, Debian 11+
- **macOS**: macOS 10.15+ (开发环境)
- **架构**: x86_64, ARM64

### 硬件要求
- **CPU**: 2核心以上
- **内存**: 4GB以上
- **存储**: 20GB以上可用空间
- **网络**: 支持IPv6的网络环境

### 软件依赖
- **Python**: 3.8+ (推荐3.9+)
- **PHP**: 8.1+ (推荐8.2+)
- **MySQL**: 8.0+ (推荐8.0.30+)
- **Redis**: 6.0+ (推荐7.0+)
- **Nginx**: 1.18+ (推荐1.20+)
- **Git**: 2.20+

## 📦 依赖安装

### Ubuntu/Debian系统
```bash
# 更新系统包
sudo apt update && sudo apt upgrade -y

# 安装基础依赖
sudo apt install -y \
    python3 python3-pip python3-venv \
    php8.1 php8.1-fpm php8.1-mysql php8.1-curl php8.1-json \
    mysql-server redis-server nginx \
    git curl wget unzip \
    build-essential libssl-dev libffi-dev

# 启动服务
sudo systemctl start mysql redis nginx php8.1-fpm
sudo systemctl enable mysql redis nginx php8.1-fpm
```

### CentOS/RHEL系统
```bash
# 更新系统包
sudo yum update -y

# 安装EPEL仓库
sudo yum install -y epel-release

# 安装基础依赖
sudo yum install -y \
    python3 python3-pip \
    php php-fpm php-mysql php-curl php-json \
    mysql-server redis nginx \
    git curl wget unzip \
    gcc gcc-c++ make openssl-devel libffi-devel

# 启动服务
sudo systemctl start mysqld redis nginx php-fpm
sudo systemctl enable mysqld redis nginx php-fpm
```

### macOS系统
```bash
# 安装Homebrew（如果未安装）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装依赖
brew install python@3.9 php mysql redis nginx git

# 启动服务
brew services start mysql
brew services start redis
brew services start nginx
```

## ⚙️ 配置步骤

### 1. 数据库配置
```bash
# 启动MySQL服务
sudo systemctl start mysql
sudo systemctl enable mysql

# 安全配置
sudo mysql_secure_installation

# 创建数据库和用户
sudo mysql -e "CREATE DATABASE ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER 'ipv6wgm'@'localhost' IDENTIFIED BY 'your_password';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
```

### 2. 应用配置
```bash
# 复制环境配置
cp env.template .env

# 编辑配置文件
nano .env

# 配置内容示例
APP_NAME=IPv6 WireGuard Manager
APP_VERSION=3.1.0
DEBUG=false
ENVIRONMENT=production
DATABASE_URL=mysql://ipv6wgm:your_password@localhost:3306/ipv6wgm
SECRET_KEY=your-secret-key-here
SERVER_HOST=127.0.0.1
SERVER_PORT=8000
REDIS_URL=redis://localhost:6379/0
USE_REDIS=true
```

### 3. 安装Python依赖
```bash
# 进入后端目录
cd backend

# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt
```

### 4. 初始化数据库
```bash
# 运行数据库迁移
alembic upgrade head

# 或使用初始化脚本
python init_database.py
```

### 5. 配置Nginx
```bash
# 创建Nginx配置
sudo nano /etc/nginx/sites-available/ipv6-wireguard-manager

# 配置内容
server {
    listen 80;
    server_name localhost;
    root /path/to/ipv6-wireguard-manager/php-frontend;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# 启用站点
sudo ln -s /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

### 6. 创建systemd服务
```bash
# 创建服务文件
sudo nano /etc/systemd/system/ipv6-wireguard-manager.service

# 服务配置
[Unit]
Description=IPv6 WireGuard Manager API
After=network.target mysql.service redis.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/path/to/ipv6-wireguard-manager/backend
Environment=PATH=/path/to/ipv6-wireguard-manager/backend/venv/bin
ExecStart=/path/to/ipv6-wireguard-manager/backend/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target

# 启用服务
sudo systemctl daemon-reload
sudo systemctl enable ipv6-wireguard-manager
sudo systemctl start ipv6-wireguard-manager
```

## 🚀 启动服务

### 启动所有服务
```bash
# 启动系统服务
sudo systemctl start mysql redis nginx php8.1-fpm

# 启动应用服务
sudo systemctl start ipv6-wireguard-manager

# 启用开机自启
sudo systemctl enable mysql redis nginx php8.1-fpm ipv6-wireguard-manager
```

### 检查服务状态
```bash
# 查看服务状态
sudo systemctl status ipv6-wireguard-manager
sudo systemctl status nginx
sudo systemctl status php8.1-fpm
sudo systemctl status redis
sudo systemctl status mysql
```

## 🧪 验证安装

### 功能验证
```bash
# 验证API健康状态
curl http://localhost:8000/health

# 验证前端访问
curl http://localhost/

# 验证数据库连接
mysql -u ipv6wgm -p -e "SELECT 1;"
```

### 运行测试
```bash
# 运行测试套件
python scripts/run_tests.py --all

# 运行特定测试
python scripts/run_tests.py --unit
python scripts/run_tests.py --integration
```

## 📊 监控和日志

### 查看日志
```bash
# 查看应用日志
sudo journalctl -u ipv6-wireguard-manager -f

# 查看Nginx日志
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# 查看PHP-FPM日志
sudo tail -f /var/log/php8.1-fpm.log
```

### 健康检查
```bash
# 检查API健康状态
curl http://localhost:8000/health

# 检查前端访问
curl http://localhost/

# 检查数据库连接
python backend/test_db_connection.py
```

## 🔧 故障排除

### 常见问题

#### 1. 服务启动失败
```bash
# 检查端口占用
sudo netstat -tlnp | grep :8000
sudo netstat -tlnp | grep :80

# 检查配置文件
sudo nginx -t
sudo systemctl status ipv6-wireguard-manager
```

#### 2. 数据库连接失败
```bash
# 检查MySQL服务
sudo systemctl status mysql

# 检查数据库配置
mysql -u ipv6wgm -p -e "SHOW DATABASES;"

# 检查连接参数
python backend/test_db_connection.py
```

#### 3. 权限问题
```bash
# 设置正确的文件权限
sudo chown -R www-data:www-data /path/to/ipv6-wireguard-manager
sudo chmod -R 755 /path/to/ipv6-wireguard-manager
```

## 📚 相关文档

- [原生安装指南](docs/NATIVE_INSTALLATION_GUIDE.md) - 详细的安装说明
- [部署指南](docs/DEPLOYMENT_GUIDE.md) - 完整的部署说明
- [配置管理](docs/CONFIGURATION_GUIDE.md) - 系统配置说明
- [故障排除](docs/TROUBLESHOOTING_GUIDE.md) - 问题诊断解决

## 🎉 安装完成

安装完成后，您可以：

1. **访问前端界面**: http://localhost
2. **访问API接口**: http://localhost:8000
3. **查看健康状态**: http://localhost:8000/health
4. **查看API文档**: http://localhost:8000/docs

## 📞 技术支持

### 获取帮助
- **文档**: [docs/](docs/)
- **问题反馈**: [GitHub Issues](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- **讨论**: [GitHub Discussions](https://github.com/ipzh/ipv6-wireguard-manager/discussions)

### 社区支持
- **技术交流**: 参与社区讨论
- **经验分享**: 分享部署经验
- **问题解答**: 帮助其他用户

---

**快速安装指南版本**: 3.1.0  
**最后更新**: 2024-01-01  
**维护团队**: IPv6 WireGuard Manager团队
