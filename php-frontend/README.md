# IPv6 WireGuard Manager - PHP前端

这是IPv6 WireGuard Manager的PHP前端实现，提供完整的Web管理界面。

## 功能特性

### ✅ 已实现功能

1. **用户认证系统**
   - 用户登录/登出
   - JWT令牌管理
   - 权限控制
   - 会话管理

2. **仪表板**
   - 系统状态概览
   - WireGuard服务器/客户端统计
   - BGP宣告状态
   - 系统监控指标
   - 最近日志显示
   - 实时数据更新

3. **WireGuard管理**
   - 服务器管理（创建、编辑、删除、启动/停止）
   - 客户端管理（创建、编辑、删除）
   - 配置文件导出
   - 二维码生成
   - 实时状态监控

### 🚧 待实现功能

4. **BGP管理**
   - BGP会话管理
   - 路由宣告管理
   - 状态监控

5. **IPv6前缀池管理**
   - 前缀池管理
   - 前缀分配
   - 使用统计

6. **监控模块**
   - 系统指标展示
   - 告警管理
   - 历史数据

7. **日志管理**
   - 日志查看
   - 日志搜索
   - 日志详情

8. **用户管理**
   - 用户列表
   - 用户创建/编辑
   - 权限管理

9. **系统设置**
   - 系统配置
   - 备份恢复
   - 系统信息

10. **实时通信**
    - Server-Sent Events
    - 实时数据推送

## 技术架构

### 技术栈
- **后端**: PHP 8.1+
- **前端**: Bootstrap 5 + jQuery
- **数据库**: MySQL (通过API)
- **认证**: JWT令牌
- **API通信**: RESTful API

### 项目结构
```
php-frontend/
├── index.php              # 入口文件
├── config/
│   └── config.php         # 配置文件
├── classes/
│   ├── ApiClient.php      # API客户端
│   ├── Auth.php           # 认证管理
│   └── Router.php         # 路由管理
├── controllers/
│   ├── AuthController.php # 认证控制器
│   ├── DashboardController.php # 仪表板控制器
│   └── WireGuardController.php # WireGuard控制器
├── views/
│   ├── layout/
│   │   ├── header.php     # 页面头部
│   │   └── footer.php     # 页面底部
│   ├── auth/
│   │   └── login.php      # 登录页面
│   ├── dashboard/
│   │   └── index.php      # 仪表板页面
│   ├── wireguard/
│   │   ├── servers.php    # 服务器管理页面
│   │   └── clients.php    # 客户端管理页面
│   └── errors/
│       ├── 404.php        # 404错误页面
│       └── error.php      # 错误页面
└── README.md              # 说明文档
```

## 安装部署

### 系统要求
- PHP 8.1+
- Apache/Nginx Web服务器
- 支持URL重写
- 后端API服务运行正常

### 安装步骤

1. **下载代码**
   ```bash
   git clone <repository-url>
   cd php-frontend
   ```

2. **配置Web服务器**
   
   **Apache配置**:
   ```apache
   <VirtualHost *:80>
       ServerName ipv6-wireguard-manager.local
       DocumentRoot /path/to/php-frontend
       <Directory /path/to/php-frontend>
           AllowOverride All
           Require all granted
       </Directory>
   </VirtualHost>
   ```

   **Nginx配置**:
   ```nginx
   server {
       listen 80;
       server_name ipv6-wireguard-manager.local;
       root /path/to/php-frontend;
       index index.php;
       
       location / {
           try_files $uri $uri/ /index.php?$query_string;
       }
       
       location ~ \.php$ {
           fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
           fastcgi_index index.php;
           fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
           include fastcgi_params;
       }
   }
   ```

3. **配置应用**
   
   编辑 `config/config.php`:
   ```php
   // 修改API地址
   define('API_BASE_URL', 'http://your-backend-api:${API_PORT}');
   ```

4. **设置权限**
   ```bash
   chmod -R 755 /path/to/php-frontend
   chown -R www-data:www-data /path/to/php-frontend
   ```

5. **访问应用**
   
   打开浏览器访问: `http://your-domain/`

## 配置说明

### 主要配置项

```php
// 应用配置
define('APP_NAME', 'IPv6 WireGuard Manager');
define('APP_VERSION', '3.0.0');
define('APP_DEBUG', true);

// API配置
define('API_BASE_URL', 'http://localhost:${API_PORT}');
define('API_TIMEOUT', 30);

// 会话配置
define('SESSION_LIFETIME', 3600); // 1小时

// 分页配置
define('DEFAULT_PAGE_SIZE', 20);
define('MAX_PAGE_SIZE', 100);
```

### 环境变量

可以通过环境变量覆盖配置：

```bash
export API_BASE_URL="http://your-api-server:${API_PORT}"
export APP_DEBUG="false"
```

## API集成

### 认证流程

1. 用户登录时，前端调用 `/auth/login` API
2. 后端返回JWT令牌
3. 前端将令牌存储在会话中
4. 后续请求自动携带令牌

### API调用示例

```php
// 获取服务器列表
$servers = $apiClient->get('/wireguard/servers');

// 创建服务器
$response = $apiClient->post('/wireguard/servers', $serverData);

// 更新服务器
$response = $apiClient->put('/wireguard/servers/123', $serverData);

// 删除服务器
$response = $apiClient->delete('/wireguard/servers/123');
```

## 开发指南

### 添加新功能

1. **创建控制器**
   ```php
   class NewController {
       private $auth;
       private $apiClient;
       
       public function __construct() {
           $this->auth = new Auth();
           $this->apiClient = new ApiClient();
           $this->auth->requireLogin();
       }
       
       public function index() {
           // 实现功能
       }
   }
   ```

2. **添加路由**
   ```php
   $router->addRoute('GET', '/new-feature', 'NewController@index');
   ```

3. **创建视图**
   ```php
   // views/new-feature/index.php
   $pageTitle = '新功能';
   $showSidebar = true;
   
   include 'views/layout/header.php';
   // 页面内容
   include 'views/layout/footer.php';
   ```

### 权限控制

```php
// 要求特定权限
$this->auth->requirePermission('wireguard.manage');

// 检查权限
if ($this->auth->hasPermission('admin')) {
    // 管理员功能
}
```

### 错误处理

```php
try {
    $data = $this->apiClient->get('/api/endpoint');
} catch (Exception $e) {
    $this->handleError('操作失败: ' . $e->getMessage());
}
```

## 故障排除

### 常见问题

1. **API连接失败**
   - 检查 `API_BASE_URL` 配置
   - 确认后端服务运行正常
   - 检查网络连接

2. **页面404错误**
   - 确认Nginx配置正确
   - 检查Nginx重写规则
   - 确认PHP-FPM服务正常

3. **权限错误**
   - 检查文件权限
   - 确认Web服务器用户权限
   - 检查目录权限

4. **会话问题**
   - 检查PHP会话配置
   - 确认会话目录可写
   - 检查会话超时设置

### 调试模式

启用调试模式查看详细错误信息：

```php
define('APP_DEBUG', true);
```

## 性能优化

### 缓存策略

1. **静态资源缓存**
   - 使用CDN加速
   - 设置适当的缓存头
   - 启用Gzip压缩

2. **API响应缓存**
   - 实现客户端缓存
   - 使用ETag验证
   - 合理设置缓存时间

### 安全建议

1. **输入验证**
   - 验证所有用户输入
   - 使用CSRF令牌
   - 防止XSS攻击

2. **访问控制**
   - 实现权限检查
   - 限制API访问
   - 使用HTTPS

3. **错误处理**
   - 不暴露敏感信息
   - 记录安全事件
   - 实现访问日志

## 更新日志

### v1.0.0 (2024-01-XX)
- 初始版本发布
- 实现用户认证系统
- 实现仪表板功能
- 实现WireGuard管理功能

## 贡献指南

1. Fork项目
2. 创建功能分支
3. 提交更改
4. 创建Pull Request

## 许可证

MIT License

## 支持

如有问题，请提交Issue或联系开发团队。
