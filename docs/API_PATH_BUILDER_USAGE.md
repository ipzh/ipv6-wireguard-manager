# API路径构建器使用指南

## 概述

API路径构建器是IPv6 WireGuard Manager v3.1.0引入的新功能，它提供了一个统一的方式来管理API路径，简化了前端与后端的集成，并提高了API的可维护性。通过路径构建器，开发者可以轻松地构建、管理和维护API端点，而无需手动拼接URL字符串。

## 功能特点

- **统一路径管理**: 集中管理所有API端点路径
- **多语言支持**: 提供PHP、JavaScript和Python版本
- **参数替换**: 支持路径参数的动态替换
- **缓存机制**: 内置缓存提高性能
- **版本控制**: 支持API版本管理
- **类型安全**: 提供类型提示和验证

## 安装与配置

### 1. 自动安装

使用安装脚本自动安装时，API路径构建器会自动安装和配置：

```bash
# 使用默认设置安装（包含API路径构建器）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 使用自定义参数安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- \
  --enable-path-builder
```

### 2. 手动安装

#### 2.1 后端安装

```bash
# 1. 安装Python依赖
cd /opt/ipv6-wireguard-manager/backend
pip install -r requirements_path_builder.txt

# 2. 初始化路径构建器
python -m app.core.path_builder --init

# 3. 验证安装
python -m app.core.path_builder --test
```

#### 2.2 前端安装

```bash
# 1. 复制路径构建器文件
sudo cp -r /opt/ipv6-wireguard-manager/php-frontend/api_path_builder /var/www/html/
sudo cp -r /opt/ipv6-wireguard-manager/php-frontend/js_path_builder /var/www/html/

# 2. 设置权限
sudo chown -R www-data:www-data /var/www/html/api_path_builder
sudo chown -R www-data:www-data /var/www/html/js_path_builder
sudo chmod -R 755 /var/www/html/api_path_builder
sudo chmod -R 755 /var/www/html/js_path_builder
```

### 3. 配置文件

创建配置文件 `/etc/ipv6-wireguard-manager/path_builder/path_builder_config.json`:

```json
{
  "api_version": "v1",
  "base_url": "http://localhost:8000",
  "endpoints": {
    "auth": {
      "login": "/auth/login",
      "logout": "/auth/logout",
      "refresh": "/auth/refresh"
    },
    "users": {
      "list": "/users/",
      "create": "/users/",
      "detail": "/users/{id}",
      "update": "/users/{id}",
      "delete": "/users/{id}"
    },
    "servers": {
      "list": "/servers/",
      "create": "/servers/",
      "detail": "/servers/{id}",
      "update": "/servers/{id}",
      "delete": "/servers/{id}",
      "status": "/servers/{id}/status",
      "clients": "/servers/{id}/clients"
    },
    "clients": {
      "list": "/clients/",
      "create": "/clients/",
      "detail": "/clients/{id}",
      "update": "/clients/{id}",
      "delete": "/clients/{id}",
      "config": "/clients/{id}/config",
      "enable": "/clients/{id}/enable",
      "disable": "/clients/{id}/disable"
    }
  },
  "cache_enabled": true,
  "cache_ttl": 3600,
  "cache_strategy": "lru",
  "cache_size": 1000
}
```

## 使用方法

### 1. PHP版本使用

#### 1.1 基本用法

```php
<?php
require_once 'api_path_builder/PathBuilder.php';

// 创建路径构建器实例
$pathBuilder = new PathBuilder();

// 获取登录API路径
$loginPath = $pathBuilder->getPath('auth.login');
echo $loginPath; // 输出: /auth/login

// 获取用户详情API路径（带参数）
$userId = 123;
$userDetailPath = $pathBuilder->getPath('users.detail', ['id' => $userId]);
echo $userDetailPath; // 输出: /users/123

// 获取完整URL
$fullUrl = $pathBuilder->getUrl('servers.list');
echo $fullUrl; // 输出: http://localhost:8000/api/v1/servers/
?>
```

#### 1.2 高级用法

```php
<?php
require_once 'api_path_builder/PathBuilder.php';

// 创建自定义配置的路径构建器
$config = [
    'api_version' => 'v2',
    'base_url' => 'https://api.example.com',
    'endpoints' => [
        'custom' => [
            'endpoint' => '/custom/{param1}/{param2}'
        ]
    ]
];
$pathBuilder = new PathBuilder($config);

// 批量获取路径
$paths = $pathBuilder->getPaths(['auth.login', 'users.list', 'servers.detail']);

// 检查路径是否存在
if ($pathBuilder->hasPath('auth.login')) {
    // 路径存在
}

// 获取所有可用路径
$allPaths = $pathBuilder->getAllPaths();

// 刷新缓存
$pathBuilder->refreshCache();
?>
```

#### 1.3 在API客户端中使用

```php
<?php
require_once 'api_path_builder/PathBuilder.php';
require_once 'api_client/ApiClient.php';

class MyApiClient {
    private $pathBuilder;
    private $baseUrl;
    
    public function __construct() {
        $this->pathBuilder = new PathBuilder();
        $this->baseUrl = $this->pathBuilder->getBaseUrl();
    }
    
    public function login($username, $password) {
        $url = $this->baseUrl . $this->pathBuilder->getPath('auth.login');
        $data = [
            'username' => $username,
            'password' => $password
        ];
        
        return $this->post($url, $data);
    }
    
    public function getUser($userId) {
        $url = $this->baseUrl . $this->pathBuilder->getPath('users.detail', ['id' => $userId]);
        return $this->get($url);
    }
    
    public function getServers() {
        $url = $this->baseUrl . $this->pathBuilder->getPath('servers.list');
        return $this->get($url);
    }
    
    private function get($url) {
        // 实现GET请求
    }
    
    private function post($url, $data) {
        // 实现POST请求
    }
}

// 使用示例
$client = new MyApiClient();
$result = $client->login('admin', 'password');
$user = $client->getUser(1);
$servers = $client->getServers();
?>
```

### 2. JavaScript版本使用

#### 2.1 基本用法

```javascript
// 引入路径构建器
import PathBuilder from './js_path_builder/PathBuilder.js';

// 创建路径构建器实例
const pathBuilder = new PathBuilder();

// 获取登录API路径
const loginPath = pathBuilder.getPath('auth.login');
console.log(loginPath); // 输出: /auth/login

// 获取用户详情API路径（带参数）
const userId = 123;
const userDetailPath = pathBuilder.getPath('users.detail', { id: userId });
console.log(userDetailPath); // 输出: /users/123

// 获取完整URL
const fullUrl = pathBuilder.getUrl('servers.list');
console.log(fullUrl); // 输出: http://localhost:8000/api/v1/servers/
```

#### 2.2 高级用法

```javascript
// 引入路径构建器
import PathBuilder from './js_path_builder/PathBuilder.js';

// 创建自定义配置的路径构建器
const config = {
    api_version: 'v2',
    base_url: 'https://api.example.com',
    endpoints: {
        custom: {
            endpoint: '/custom/{param1}/{param2}'
        }
    }
};
const pathBuilder = new PathBuilder(config);

// 批量获取路径
const paths = pathBuilder.getPaths(['auth.login', 'users.list', 'servers.detail']);

// 检查路径是否存在
if (pathBuilder.hasPath('auth.login')) {
    // 路径存在
}

// 获取所有可用路径
const allPaths = pathBuilder.getAllPaths();

// 刷新缓存
pathBuilder.refreshCache();

// 异步获取路径
async function example() {
    const path = await pathBuilder.getPathAsync('auth.login');
    console.log(path);
}
```

#### 2.3 在API客户端中使用

```javascript
// 引入路径构建器
import PathBuilder from './js_path_builder/PathBuilder.js';

class ApiClient {
    constructor() {
        this.pathBuilder = new PathBuilder();
        this.baseUrl = this.pathBuilder.getBaseUrl();
    }
    
    async login(username, password) {
        const url = this.baseUrl + this.pathBuilder.getPath('auth.login');
        const data = {
            username: username,
            password: password
        };
        
        return this.post(url, data);
    }
    
    async getUser(userId) {
        const url = this.baseUrl + this.pathBuilder.getPath('users.detail', { id: userId });
        return this.get(url);
    }
    
    async getServers() {
        const url = this.baseUrl + this.pathBuilder.getPath('servers.list');
        return this.get(url);
    }
    
    async get(url) {
        const response = await fetch(url, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        return response.json();
    }
    
    async post(url, data) {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        });
        return response.json();
    }
}

// 使用示例
const client = new ApiClient();
client.login('admin', 'password')
    .then(result => console.log(result))
    .catch(error => console.error(error));

client.getUser(1)
    .then(user => console.log(user))
    .catch(error => console.error(error));

client.getServers()
    .then(servers => console.log(servers))
    .catch(error => console.error(error));
```

### 3. Python版本使用

#### 3.1 基本用法

```python
from app.core.path_builder import PathBuilder

# 创建路径构建器实例
path_builder = PathBuilder()

# 获取登录API路径
login_path = path_builder.get_path('auth.login')
print(login_path)  # 输出: /auth/login

# 获取用户详情API路径（带参数）
user_id = 123
user_detail_path = path_builder.get_path('users.detail', id=user_id)
print(user_detail_path)  # 输出: /users/123

# 获取完整URL
full_url = path_builder.get_url('servers.list')
print(full_url)  # 输出: http://localhost:8000/api/v1/servers/
```

#### 3.2 高级用法

```python
from app.core.path_builder import PathBuilder

# 创建自定义配置的路径构建器
config = {
    'api_version': 'v2',
    'base_url': 'https://api.example.com',
    'endpoints': {
        'custom': {
            'endpoint': '/custom/{param1}/{param2}'
        }
    }
}
path_builder = PathBuilder(config)

# 批量获取路径
paths = path_builder.get_paths(['auth.login', 'users.list', 'servers.detail'])

# 检查路径是否存在
if path_builder.has_path('auth.login'):
    # 路径存在
    pass

# 获取所有可用路径
all_paths = path_builder.get_all_paths()

# 刷新缓存
path_builder.refresh_cache()

# 异步获取路径
import asyncio

async def example():
    path = await path_builder.get_path_async('auth.login')
    print(path)

asyncio.run(example())
```

#### 3.3 在API客户端中使用

```python
import requests
from app.core.path_builder import PathBuilder

class ApiClient:
    def __init__(self):
        self.path_builder = PathBuilder()
        self.base_url = self.path_builder.get_base_url()
        self.session = requests.Session()
    
    def login(self, username, password):
        url = self.base_url + self.path_builder.get_path('auth.login')
        data = {
            'username': username,
            'password': password
        }
        
        response = self.session.post(url, json=data)
        return response.json()
    
    def get_user(self, user_id):
        url = self.base_url + self.path_builder.get_path('users.detail', id=user_id)
        response = self.session.get(url)
        return response.json()
    
    def get_servers(self):
        url = self.base_url + self.path_builder.get_path('servers.list')
        response = self.session.get(url)
        return response.json()
    
    def get(self, url):
        response = self.session.get(url)
        response.raise_for_status()
        return response.json()
    
    def post(self, url, data):
        response = self.session.post(url, json=data)
        response.raise_for_status()
        return response.json()

# 使用示例
client = ApiClient()
try:
    result = client.login('admin', 'password')
    print(result)
    
    user = client.get_user(1)
    print(user)
    
    servers = client.get_servers()
    print(servers)
except requests.exceptions.RequestException as e:
    print(f"API请求失败: {e}")
```

## API端点参考

### 1. 认证相关

| 路径键 | 路径模板 | 方法 | 说明 |
|--------|----------|------|------|
| `auth.login` | `/auth/login` | POST | 用户登录 |
| `auth.logout` | `/auth/logout` | POST | 用户登出 |
| `auth.refresh` | `/auth/refresh` | POST | 刷新访问令牌 |

### 2. 用户管理

| 路径键 | 路径模板 | 方法 | 说明 |
|--------|----------|------|------|
| `users.list` | `/users/` | GET | 获取用户列表 |
| `users.create` | `/users/` | POST | 创建新用户 |
| `users.detail` | `/users/{id}` | GET | 获取用户详情 |
| `users.update` | `/users/{id}` | PUT | 更新用户信息 |
| `users.delete` | `/users/{id}` | DELETE | 删除用户 |

### 3. WireGuard服务器管理

| 路径键 | 路径模板 | 方法 | 说明 |
|--------|----------|------|------|
| `servers.list` | `/servers/` | GET | 获取服务器列表 |
| `servers.create` | `/servers/` | POST | 创建新服务器 |
| `servers.detail` | `/servers/{id}` | GET | 获取服务器详情 |
| `servers.update` | `/servers/{id}` | PUT | 更新服务器配置 |
| `servers.delete` | `/servers/{id}` | DELETE | 删除服务器 |
| `servers.status` | `/servers/{id}/status` | GET | 获取服务器状态 |
| `servers.clients` | `/servers/{id}/clients` | GET | 获取服务器客户端列表 |

### 4. WireGuard客户端管理

| 路径键 | 路径模板 | 方法 | 说明 |
|--------|----------|------|------|
| `clients.list` | `/clients/` | GET | 获取客户端列表 |
| `clients.create` | `/clients/` | POST | 创建新客户端 |
| `clients.detail` | `/clients/{id}` | GET | 获取客户端详情 |
| `clients.update` | `/clients/{id}` | PUT | 更新客户端配置 |
| `clients.delete` | `/clients/{id}` | DELETE | 删除客户端 |
| `clients.config` | `/clients/{id}/config` | GET | 获取客户端配置文件 |
| `clients.enable` | `/clients/{id}/enable` | POST | 启用客户端 |
| `clients.disable` | `/clients/{id}/disable` | POST | 禁用客户端 |

## 高级功能

### 1. 缓存机制

API路径构建器内置了缓存机制，可以提高性能并减少重复计算。

#### 1.1 缓存配置

```json
{
  "cache_enabled": true,
  "cache_ttl": 3600,
  "cache_strategy": "lru",
  "cache_size": 1000
}
```

#### 1.2 缓存控制

```php
// PHP
$pathBuilder = new PathBuilder();
$pathBuilder->enableCache();
$pathBuilder->disableCache();
$pathBuilder->clearCache();
$pathBuilder->setCacheTtl(1800);
```

```javascript
// JavaScript
const pathBuilder = new PathBuilder();
pathBuilder.enableCache();
pathBuilder.disableCache();
pathBuilder.clearCache();
pathBuilder.setCacheTtl(1800);
```

```python
# Python
path_builder = PathBuilder()
path_builder.enable_cache()
path_builder.disable_cache()
path_builder.clear_cache()
path_builder.set_cache_ttl(1800)
```

### 2. 版本控制

API路径构建器支持多版本API管理。

#### 2.1 版本配置

```json
{
  "api_version": "v1",
  "versioned_endpoints": {
    "v1": {
      "users": {
        "detail": "/users/{id}"
      }
    },
    "v2": {
      "users": {
        "detail": "/v2/users/{id}"
      }
    }
  }
}
```

#### 2.2 版本切换

```php
// PHP
$pathBuilder = new PathBuilder();
$pathBuilder->setVersion('v2');
$path = $pathBuilder->getPath('users.detail', ['id' => 1]);
// 输出: /v2/users/1
```

```javascript
// JavaScript
const pathBuilder = new PathBuilder();
pathBuilder.setVersion('v2');
const path = pathBuilder.getPath('users.detail', { id: 1 });
// 输出: /v2/users/1
```

```python
# Python
path_builder = PathBuilder()
path_builder.set_version('v2')
path = path_builder.get_path('users.detail', id=1)
# 输出: /v2/users/1
```

### 3. 参数验证

API路径构建器支持参数验证，确保生成的路径正确。

#### 3.1 验证配置

```json
{
  "validation_enabled": true,
  "parameter_validation": {
    "users.detail": {
      "id": {
        "type": "integer",
        "min": 1,
        "required": true
      }
    }
  }
}
```

#### 3.2 验证使用

```php
// PHP
$pathBuilder = new PathBuilder();
try {
    $path = $pathBuilder->getPath('users.detail', ['id' => 'invalid']);
} catch (ValidationException $e) {
    echo "验证失败: " . $e->getMessage();
}
```

```javascript
// JavaScript
const pathBuilder = new PathBuilder();
try {
    const path = pathBuilder.getPath('users.detail', { id: 'invalid' });
} catch (ValidationError e) {
    console.error("验证失败:", e.message);
}
```

```python
# Python
path_builder = PathBuilder()
try:
    path = path_builder.get_path('users.detail', id='invalid')
except ValidationError as e:
    print(f"验证失败: {e}")
```

## 最佳实践

### 1. 路径命名规范

使用点号分隔的命名规范，如`users.detail`、`servers.list`等，保持一致性和可读性。

### 2. 参数命名

使用有意义的参数名，如`id`、`user_id`、`server_id`等，避免使用简写或无意义的名称。

### 3. 错误处理

始终处理可能的错误，如路径不存在、参数验证失败等。

### 4. 缓存策略

根据应用需求合理配置缓存策略，平衡性能和数据一致性。

### 5. 版本管理

使用版本控制管理API变更，确保向后兼容性。

## 故障排除

### 1. 常见问题

#### 1.1 路径不存在

**问题**: 调用`getPath()`时返回`null`或抛出异常

**解决方案**:
- 检查路径键是否正确
- 确认配置文件中是否定义了该路径
- 使用`hasPath()`方法检查路径是否存在

#### 1.2 参数替换失败

**问题**: 路径中的参数没有被正确替换

**解决方案**:
- 检查参数名是否与路径模板中的占位符匹配
- 确认参数值是否为空或null
- 使用`validateParameters()`方法验证参数

#### 1.3 缓存问题

**问题**: 路径更新后缓存未刷新

**解决方案**:
- 调用`clearCache()`方法清除缓存
- 检查缓存TTL设置是否合理
- 临时禁用缓存进行测试

### 2. 调试技巧

#### 2.1 启用调试模式

```php
// PHP
$pathBuilder = new PathBuilder();
$pathBuilder->setDebugMode(true);
```

```javascript
// JavaScript
const pathBuilder = new PathBuilder();
pathBuilder.setDebugMode(true);
```

```python
# Python
path_builder = PathBuilder()
path_builder.set_debug_mode(True)
```

#### 2.2 日志记录

```php
// PHP
$pathBuilder = new PathBuilder();
$pathBuilder->setLogger($logger);
```

```javascript
// JavaScript
const pathBuilder = new PathBuilder();
pathBuilder.setLogger(console);
```

```python
# Python
import logging
path_builder = PathBuilder()
path_builder.set_logger(logging.getLogger(__name__))
```

## 示例项目

### 1. 简单API客户端

```php
<?php
require_once 'api_path_builder/PathBuilder.php';

class SimpleApiClient {
    private $pathBuilder;
    private $baseUrl;
    private $token;
    
    public function __construct() {
        $this->pathBuilder = new PathBuilder();
        $this->baseUrl = $this->pathBuilder->getBaseUrl();
    }
    
    public function login($username, $password) {
        $url = $this->baseUrl . $this->pathBuilder->getPath('auth.login');
        $data = [
            'username' => $username,
            'password' => $password
        ];
        
        $response = $this->post($url, $data);
        $this->token = $response['access_token'];
        return $response;
    }
    
    public function getServers() {
        $url = $this->baseUrl . $this->pathBuilder->getPath('servers.list');
        return $this->get($url);
    }
    
    public function createServer($name, $address, $port) {
        $url = $this->baseUrl . $this->pathBuilder->getPath('servers.create');
        $data = [
            'name' => $name,
            'address' => $address,
            'port' => $port
        ];
        
        return $this->post($url, $data);
    }
    
    public function getServerClients($serverId) {
        $url = $this->baseUrl . $this->pathBuilder->getPath('servers.clients', ['id' => $serverId]);
        return $this->get($url);
    }
    
    private function get($url) {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $this->token,
            'Content-Type: application/json'
        ]);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($httpCode >= 400) {
            throw new Exception("API请求失败: HTTP {$httpCode}");
        }
        
        return json_decode($response, true);
    }
    
    private function post($url, $data) {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json'
        ]);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($httpCode >= 400) {
            throw new Exception("API请求失败: HTTP {$httpCode}");
        }
        
        return json_decode($response, true);
    }
}

// 使用示例
$client = new SimpleApiClient();
try {
    // 登录
    $loginResult = $client->login('admin', 'password');
    echo "登录成功\n";
    
    // 获取服务器列表
    $servers = $client->getServers();
    echo "服务器列表:\n";
    foreach ($servers as $server) {
        echo "- {$server['name']} ({$server['address']}:{$server['port']})\n";
    }
    
    // 创建新服务器
    $newServer = $client->createServer('新服务器', '192.168.1.100', 51820);
    echo "创建服务器成功: {$newServer['id']}\n";
    
    // 获取服务器客户端
    if (!empty($servers)) {
        $clients = $client->getServerClients($servers[0]['id']);
        echo "服务器客户端数量: " . count($clients) . "\n";
    }
} catch (Exception $e) {
    echo "错误: " . $e->getMessage() . "\n";
}
?>
```

### 2. React组件示例

```javascript
import React, { useState, useEffect } from 'react';
import PathBuilder from './js_path_builder/PathBuilder.js';

const ServerList = () => {
    const [servers, setServers] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    
    const pathBuilder = new PathBuilder();
    const baseUrl = pathBuilder.getBaseUrl();
    
    useEffect(() => {
        fetchServers();
    }, []);
    
    const fetchServers = async () => {
        setLoading(true);
        setError(null);
        
        try {
            const url = baseUrl + pathBuilder.getPath('servers.list');
            const response = await fetch(url, {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('token')}`,
                    'Content-Type': 'application/json'
                }
            });
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            const data = await response.json();
            setServers(data);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };
    
    const createServer = async (name, address, port) => {
        try {
            const url = baseUrl + pathBuilder.getPath('servers.create');
            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('token')}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ name, address, port })
            });
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            const newServer = await response.json();
            setServers([...servers, newServer]);
            return newServer;
        } catch (err) {
            setError(err.message);
            throw err;
        }
    };
    
    const deleteServer = async (serverId) => {
        try {
            const url = baseUrl + pathBuilder.getPath('servers.delete', { id: serverId });
            const response = await fetch(url, {
                method: 'DELETE',
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('token')}`
                }
            });
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            setServers(servers.filter(server => server.id !== serverId));
        } catch (err) {
            setError(err.message);
            throw err;
        }
    };
    
    const viewServerClients = async (serverId) => {
        try {
            const url = baseUrl + pathBuilder.getPath('servers.clients', { id: serverId });
            const response = await fetch(url, {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('token')}`,
                    'Content-Type': 'application/json'
                }
            });
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            const clients = await response.json();
            console.log(`服务器 ${serverId} 的客户端:`, clients);
            return clients;
        } catch (err) {
            setError(err.message);
            throw err;
        }
    };
    
    if (loading) return <div>加载中...</div>;
    if (error) return <div>错误: {error}</div>;
    
    return (
        <div>
            <h2>WireGuard服务器列表</h2>
            <ul>
                {servers.map(server => (
                    <li key={server.id}>
                        {server.name} ({server.address}:{server.port})
                        <button onClick={() => viewServerClients(server.id)}>
                            查看客户端
                        </button>
                        <button onClick={() => deleteServer(server.id)}>
                            删除
                        </button>
                    </li>
                ))}
            </ul>
            <button onClick={() => createServer('新服务器', '192.168.1.100', 51820)}>
                添加服务器
            </button>
        </div>
    );
};

export default ServerList;
```

### 3. Python命令行工具示例

```python
#!/usr/bin/env python3
import argparse
import sys
import json
from app.core.path_builder import PathBuilder
import requests

class WireGuardCli:
    def __init__(self):
        self.path_builder = PathBuilder()
        self.base_url = self.path_builder.get_base_url()
        self.token = None
        self.session = requests.Session()
    
    def login(self, username, password):
        """登录获取访问令牌"""
        url = self.base_url + self.path_builder.get_path('auth.login')
        data = {
            'username': username,
            'password': password
        }
        
        try:
            response = self.session.post(url, json=data)
            response.raise_for_status()
            result = response.json()
            self.token = result['access_token']
            self.session.headers.update({
                'Authorization': f'Bearer {self.token}'
            })
            print("登录成功")
            return True
        except requests.exceptions.RequestException as e:
            print(f"登录失败: {e}")
            return False
    
    def list_servers(self):
        """列出所有服务器"""
        url = self.base_url + self.path_builder.get_path('servers.list')
        
        try:
            response = self.session.get(url)
            response.raise_for_status()
            servers = response.json()
            
            if not servers:
                print("没有找到服务器")
                return
            
            print("服务器列表:")
            for server in servers:
                print(f"- {server['name']} ({server['address']}:{server['port']}) [ID: {server['id']}]")
        except requests.exceptions.RequestException as e:
            print(f"获取服务器列表失败: {e}")
    
    def create_server(self, name, address, port):
        """创建新服务器"""
        url = self.base_url + self.path_builder.get_path('servers.create')
        data = {
            'name': name,
            'address': address,
            'port': port
        }
        
        try:
            response = self.session.post(url, json=data)
            response.raise_for_status()
            server = response.json()
            print(f"创建服务器成功: {server['name']} (ID: {server['id']})")
            return server
        except requests.exceptions.RequestException as e:
            print(f"创建服务器失败: {e}")
            return None
    
    def get_server(self, server_id):
        """获取服务器详情"""
        url = self.base_url + self.path_builder.get_path('servers.detail', id=server_id)
        
        try:
            response = self.session.get(url)
            response.raise_for_status()
            server = response.json()
            
            print(f"服务器详情:")
            print(f"- 名称: {server['name']}")
            print(f"- 地址: {server['address']}")
            print(f"- 端口: {server['port']}")
            print(f"- 状态: {server['status']}")
            return server
        except requests.exceptions.RequestException as e:
            print(f"获取服务器详情失败: {e}")
            return None
    
    def delete_server(self, server_id):
        """删除服务器"""
        url = self.base_url + self.path_builder.get_path('servers.delete', id=server_id)
        
        try:
            response = self.session.delete(url)
            response.raise_for_status()
            print(f"删除服务器成功 (ID: {server_id})")
            return True
        except requests.exceptions.RequestException as e:
            print(f"删除服务器失败: {e}")
            return False
    
    def list_clients(self, server_id=None):
        """列出客户端"""
        if server_id:
            url = self.base_url + self.path_builder.get_path('servers.clients', id=server_id)
        else:
            url = self.base_url + self.path_builder.get_path('clients.list')
        
        try:
            response = self.session.get(url)
            response.raise_for_status()
            clients = response.json()
            
            if not clients:
                print("没有找到客户端")
                return
            
            print("客户端列表:")
            for client in clients:
                print(f"- {client['name']} ({client['ip_address']}) [ID: {client['id']}]")
        except requests.exceptions.RequestException as e:
            print(f"获取客户端列表失败: {e}")

def main():
    parser = argparse.ArgumentParser(description='WireGuard管理命令行工具')
    subparsers = parser.add_subparsers(dest='command', help='可用命令')
    
    # 登录命令
    login_parser = subparsers.add_parser('login', help='登录系统')
    login_parser.add_argument('username', help='用户名')
    login_parser.add_argument('password', help='密码')
    
    # 服务器相关命令
    server_parser = subparsers.add_parser('server', help='服务器管理')
    server_subparsers = server_parser.add_subparsers(dest='server_command', help='服务器命令')
    
    server_list_parser = server_subparsers.add_parser('list', help='列出服务器')
    
    server_create_parser = server_subparsers.add_parser('create', help='创建服务器')
    server_create_parser.add_argument('name', help='服务器名称')
    server_create_parser.add_argument('address', help='服务器地址')
    server_create_parser.add_argument('port', type=int, help='服务器端口')
    
    server_get_parser = server_subparsers.add_parser('get', help='获取服务器详情')
    server_get_parser.add_argument('id', type=int, help='服务器ID')
    
    server_delete_parser = server_subparsers.add_parser('delete', help='删除服务器')
    server_delete_parser.add_argument('id', type=int, help='服务器ID')
    
    # 客户端相关命令
    client_parser = subparsers.add_parser('client', help='客户端管理')
    client_subparsers = client_parser.add_subparsers(dest='client_command', help='客户端命令')
    
    client_list_parser = client_subparsers.add_parser('list', help='列出客户端')
    client_list_parser.add_argument('--server-id', type=int, help='服务器ID（可选）')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    cli = WireGuardCli()
    
    # 处理登录命令
    if args.command == 'login':
        cli.login(args.username, args.password)
        return
    
    # 对于其他命令，需要先登录
    if not cli.token:
        print("请先使用 'login' 命令登录")
        return
    
    # 处理服务器命令
    if args.command == 'server':
        if args.server_command == 'list':
            cli.list_servers()
        elif args.server_command == 'create':
            cli.create_server(args.name, args.address, args.port)
        elif args.server_command == 'get':
            cli.get_server(args.id)
        elif args.server_command == 'delete':
            cli.delete_server(args.id)
        else:
            server_parser.print_help()
    
    # 处理客户端命令
    elif args.command == 'client':
        if args.client_command == 'list':
            cli.list_clients(args.server_id)
        else:
            client_parser.print_help()

if __name__ == '__main__':
    main()
```

## 更新日志

### v3.1.0 (当前版本)

- 新增API路径构建器功能
- 支持PHP、JavaScript和Python版本
- 添加缓存机制提高性能
- 支持API版本控制
- 添加参数验证功能

### 未来计划

- 添加更多语言支持（Java、C#、Go等）
- 实现动态路径加载
- 添加路径权限控制
- 支持路径模板继承

## 许可证

API路径构建器遵循与IPv6 WireGuard Manager相同的许可证。

## 贡献指南

欢迎贡献代码！请参考[贡献指南](CONTRIBUTING.md)了解详细信息。

## 支持

如有问题或建议，请提交Issue或联系开发团队。

---

**注意**: 本文档基于API路径构建器v3.1.0版本编写，如有更新请查看最新版本文档。