# IPv6 WireGuard Manager PHP前端

## 📋 概述

IPv6 WireGuard Manager的PHP前端应用，提供完整的Web管理界面。基于PHP 8.1+和现代Web技术构建。

## 🚀 快速开始

### 环境要求

- **PHP**: 8.1+ (推荐8.2+)
- **Web服务器**: Nginx/Apache
- **数据库**: MySQL 8.0+
- **扩展**: session, json, mbstring, filter, pdo, pdo_mysql, curl, openssl

### 安装步骤

1. **检查环境要求**
   ```bash
   ./scripts/check_requirements.sh
   ```

2. **配置应用**
   ```bash
   cp env.example config/config.php
   # 编辑 config/config.php 配置数据库和API连接
   ```

3. **部署应用**
   ```bash
   ./scripts/deploy.sh
   ```

4. **配置Web服务器**
   - 复制 `nginx.conf` 到Nginx配置目录
   - 重启Nginx服务

## 🐳 Docker部署

### 构建镜像
```bash
docker build -t ipv6-wireguard-frontend .
```

### 运行容器
```bash
docker run -d -p 80:80 ipv6-wireguard-frontend
```

### 使用Docker Compose
```bash
# 在项目根目录运行
docker-compose up -d frontend
```

## 📁 目录结构

```
php-frontend/
├── api/                    # API代理和状态检查
├── assets/                 # 静态资源 (CSS, JS, 图片)
├── classes/                # PHP类库
│   ├── ApiClientJWT.php    # JWT API客户端
│   ├── AuthJWT.php         # JWT认证
│   ├── Router.php          # 路由管理
│   └── ...
├── config/                 # 配置文件
│   ├── config.php         # 主配置文件
│   ├── database.php       # 数据库配置
│   └── api_endpoints.php   # API端点配置
├── controllers/            # 控制器
│   ├── AuthController.php  # 认证控制器
│   ├── DashboardController.php # 仪表盘控制器
│   └── ...
├── includes/              # 包含文件
│   ├── ApiPathBuilder/    # API路径构建器
│   └── ssl_security.php   # SSL安全配置
├── views/                  # 视图模板
│   ├── auth/              # 认证页面
│   ├── dashboard/         # 仪表盘页面
│   ├── wireguard/        # WireGuard管理页面
│   └── ...
├── scripts/               # 部署脚本
│   ├── deploy.sh          # 部署脚本
│   └── check_requirements.sh # 环境检查脚本
├── docker/                # Docker配置
│   ├── nginx.conf         # Nginx配置
│   └── supervisord.conf   # 进程管理配置
├── Dockerfile             # Docker镜像构建文件
├── index.php              # 主入口文件
└── README.md              # 说明文档
```

## ⚙️ 配置说明

### 主配置文件 (config/config.php)

```php
<?php
// 应用配置
define('APP_NAME', 'IPv6 WireGuard Manager');
define('APP_VERSION', '3.1.0');
define('APP_DEBUG', false);

// API配置
define('API_BASE_URL', 'http://backend:8000');
define('API_TIMEOUT', 30);

// 会话配置
define('SESSION_LIFETIME', 3600);

// 安全配置
define('CSRF_TOKEN_NAME', '_token');
define('PASSWORD_MIN_LENGTH', 8);
?>
```

### 数据库配置 (config/database.php)

```php
<?php
// 数据库配置
define('DB_HOST', 'mysql');
define('DB_PORT', 3306);
define('DB_NAME', 'ipv6wgm');
define('DB_USER', 'ipv6wgm');
define('DB_PASS', 'password');
define('DB_CHARSET', 'utf8mb4');
?>
```

## 🔧 功能特性

### 认证系统
- JWT令牌认证
- 会话管理
- 权限控制
- 密码策略

### 管理功能
- WireGuard服务器管理
- 客户端管理
- IPv6地址池管理
- BGP会话管理
- 网络监控

### 用户界面
- 响应式设计
- 现代化UI
- 实时数据更新
- 错误处理

## 🛠️ 开发指南

### 添加新功能

1. **创建控制器**
   ```php
   // controllers/NewController.php
   <?php
   class NewController {
       public function index() {
           // 控制器逻辑
       }
   }
   ```

2. **创建视图**
   ```php
   // views/new/index.php
   <div class="container">
       <!-- 视图内容 -->
   </div>
   ```

3. **更新路由**
   ```php
   // 在 Router.php 中添加路由
   $router->addRoute('GET', '/new', 'NewController@index');
   ```

### API集成

```php
// 使用API客户端
$apiClient = new ApiClientJWT();
$response = $apiClient->get('/api/v1/wireguard/servers');
```

## 🐛 故障排除

### 常见问题

1. **PHP扩展缺失**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install php8.1-mysql php8.1-curl php8.1-mbstring
   
   # CentOS/RHEL
   sudo yum install php-mysql php-curl php-mbstring
   ```

2. **权限问题**
   ```bash
   chmod -R 755 .
   chmod -R 777 logs uploads cache
   ```

3. **数据库连接失败**
   - 检查数据库配置
   - 确认数据库服务运行
   - 检查网络连接

### 日志查看

```bash
# 应用日志
tail -f logs/app.log

# 错误日志
tail -f logs/error.log

# Nginx日志
tail -f /var/log/nginx/error.log
```

## 📞 支持

- 查看项目文档
- 提交Issue
- 联系开发团队

---

**版本**: 3.1.0  
**PHP要求**: 8.1+  
**许可证**: MIT