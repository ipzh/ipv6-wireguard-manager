# 前端 API 使用指南

## 概述

本文档介绍如何在 IPv6 WireGuard Manager 前端应用中使用新的 API 配置和客户端系统。

## 快速开始

### 基本导入

```javascript
// 导入 API 配置和路径构建器
import { 
  API_CONFIG, 
  apiPathBuilder, 
  buildUrl, 
  validatePath 
} from '../config/api_endpoints.js';

// 导入 API 客户端
import apiClient from '../services/api_client.js';
```

### 构建 API URL

```javascript
// 基本 URL 构建
const loginUrl = buildUrl('auth.login');
const userUrl = buildUrl('users.get', { user_id: '123' });
const serverUrl = buildUrl('wireguard.servers.status', { server_id: '456' });

console.log(loginUrl); // /api/auth/login
console.log(userUrl);  // /api/users/123
console.log(serverUrl); // /api/wireguard/servers/456/status
```

### 使用 API 客户端

```javascript
// 基本 API 请求
try {
  // GET 请求
  const users = await apiClient.get('users');
  
  // POST 请求
  const newUser = await apiClient.post('users', {
    username: 'testuser',
    email: 'test@example.com',
    password: 'password123'
  });
  
  // PUT 请求
  const updatedUser = await apiClient.put('users.update', {
    username: 'newusername'
  }, { user_id: '123' });
  
  // DELETE 请求
  await apiClient.delete('users.delete', { user_id: '123' });
  
} catch (error) {
  console.error('API 请求失败:', error);
}
```

## API 配置

### 配置选项

```javascript
const API_CONFIG = {
  BASE_URL: '/api',           // API 基础 URL
  TIMEOUT: 30000,             // 请求超时时间（毫秒）
  VERSION: 'v1',              // API 版本
  DEFAULT_HEADERS: {          // 默认请求头
    'Content-Type': 'application/json',
  },
};
```

### 环境特定配置

```javascript
// 自动检测环境
const baseUrl = typeof window !== 'undefined' && window.location.hostname === 'localhost'
  ? 'http://localhost:8000/api'  // 开发环境
  : '/api';                      // 生产环境
```

## API 路径管理

### 注册新路径

```javascript
// 注册新的 API 路径
apiPathBuilder.registerPath('custom.endpoint', '/custom/{id}', 'GET');

// 使用新路径
const customUrl = buildUrl('custom.endpoint', { id: '123' });
```

### 路径验证

```javascript
// 验证路径和参数
const validation = validatePath('users.get', { user_id: '123' }, 'GET');

if (validation.valid) {
  console.log('路径验证通过');
} else {
  console.error('路径验证失败:', validation.error);
}
```

### 获取所有路径

```javascript
// 获取所有已注册的路径
const allPaths = apiPathBuilder.getAllPaths();
console.log('所有 API 路径:', allPaths);
```

## 认证处理

### 自动 Token 管理

API 客户端会自动处理认证 token：

```javascript
// 登录后，token 会自动添加到后续请求
const loginResponse = await apiClient.login({
  username: 'admin',
  password: 'password'
});

// 后续请求会自动包含 Authorization 头
const userInfo = await apiClient.getCurrentUser();
```

### Token 刷新

```javascript
// 当 access token 过期时，会自动尝试刷新
// 如果刷新失败，会自动跳转到登录页面
try {
  const data = await apiClient.get('protected-endpoint');
  // 处理数据
} catch (error) {
  // 如果认证失败，用户会被重定向到登录页面
}
```

## 错误处理

### 统一错误处理

```javascript
// API 客户端提供统一的错误处理
try {
  const response = await apiClient.get('users');
  return response.data;
} catch (error) {
  if (error.response) {
    // 服务器响应错误
    const { status, data } = error.response;
    switch (status) {
      case 400:
        console.error('请求错误:', data.detail);
        break;
      case 401:
        console.error('认证失败:', data.detail);
        break;
      case 403:
        console.error('权限不足:', data.detail);
        break;
      case 404:
        console.error('资源不存在:', data.detail);
        break;
      case 500:
        console.error('服务器错误:', data.detail);
        break;
      default:
        console.error('未知错误:', data.detail);
    }
  } else if (error.request) {
    // 网络错误
    console.error('网络错误: 无法连接到服务器');
  } else {
    // 其他错误
    console.error('请求配置错误:', error.message);
  }
}
```

## 文件上传

### 上传文件

```javascript
// 上传单个文件
const file = document.getElementById('fileInput').files[0];
const uploadResponse = await apiClient.upload('upload.file', file);

// 上传头像
const avatarFile = document.getElementById('avatarInput').files[0];
const avatarResponse = await apiClient.uploadAvatar(avatarFile);

// 带进度回调的上传
const uploadWithProgress = await apiClient.upload('upload.file', file, {}, (progressEvent) => {
  const percentCompleted = Math.round((progressEvent.loaded * 100) / progressEvent.total);
  console.log(`上传进度: ${percentCompleted}%`);
});
```

## 高级用法

### 自定义请求配置

```javascript
// 自定义请求头
const customHeaders = {
  'X-Custom-Header': 'custom-value',
  'Authorization': 'Bearer custom-token'
};

const response = await apiClient.get('users', {}, {
  headers: customHeaders
});

// 自定义超时时间
const response = await apiClient.get('users', {}, {
  timeout: 60000  // 60秒超时
});
```

### 请求拦截器

```javascript
// 添加请求拦截器
apiClient.interceptors.request.use(
  (config) => {
    // 在请求发送前修改配置
    config.headers['X-Request-ID'] = generateRequestId();
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 添加响应拦截器
apiClient.interceptors.response.use(
  (response) => {
    // 在响应返回前处理数据
    return response;
  },
  (error) => {
    // 处理响应错误
    return Promise.reject(error);
  }
);
```

## 最佳实践

### 1. 错误处理

```javascript
// 创建统一的错误处理函数
function handleApiError(error, context = '') {
  console.error(`API 错误 ${context}:`, error);
  
  if (error.response?.status === 401) {
    // 处理认证错误
    window.location.href = '/login';
  } else if (error.response?.status >= 500) {
    // 处理服务器错误
    showNotification('服务器错误，请稍后重试', 'error');
  }
}

// 使用错误处理函数
try {
  const users = await apiClient.get('users');
} catch (error) {
  handleApiError(error, '获取用户列表');
}
```

### 2. 加载状态管理

```javascript
// 使用加载状态
const [loading, setLoading] = useState(false);
const [data, setData] = useState(null);

const fetchData = async () => {
  setLoading(true);
  try {
    const response = await apiClient.get('users');
    setData(response.data);
  } catch (error) {
    handleApiError(error, '获取数据');
  } finally {
    setLoading(false);
  }
};
```

### 3. 缓存策略

```javascript
// 简单的内存缓存
const cache = new Map();

async function getCachedData(key, fetcher) {
  if (cache.has(key)) {
    return cache.get(key);
  }
  
  const data = await fetcher();
  cache.set(key, data);
  return data;
}

// 使用缓存
const users = await getCachedData('users', () => apiClient.get('users'));
```

## 故障排除

### 常见问题

1. **导入错误**
   ```javascript
   // 错误：导入不存在的模块
   import { ApiPathBuilder } from '../public/js/ApiPathBuilder.js';
   
   // 正确：使用新的导入方式
   import { apiPathBuilder } from '../config/api_endpoints.js';
   ```

2. **路径构建错误**
   ```javascript
   // 错误：缺少必需参数
   const url = buildUrl('users.get'); // 缺少 user_id
   
   // 正确：提供必需参数
   const url = buildUrl('users.get', { user_id: '123' });
   ```

3. **认证问题**
   ```javascript
   // 确保在请求前已登录
   const token = localStorage.getItem('access_token');
   if (!token) {
     window.location.href = '/login';
     return;
   }
   ```

### 调试技巧

```javascript
// 启用详细日志
const DEBUG = true;

if (DEBUG) {
  console.log('API 配置:', API_CONFIG);
  console.log('所有路径:', apiPathBuilder.getAllPaths());
}

// 监控请求
apiClient.interceptors.request.use((config) => {
  if (DEBUG) {
    console.log('发送请求:', config.method, config.url);
  }
  return config;
});
```

## 更新日志

### v3.0.0 (2024-10-19)
- ✅ 修复了 API 端点配置问题
- ✅ 移除了外部依赖
- ✅ 添加了本地 API 路径构建器
- ✅ 改进了错误处理机制
- ✅ 简化了 API 客户端初始化

### 迁移指南

如果你正在从旧版本迁移，请参考 [迁移指南](./MIGRATION_GUIDE.md)。

## 支持

如果你在使用过程中遇到问题，请：

1. 查看本文档的故障排除部分
2. 检查浏览器控制台的错误信息
3. 参考项目的 GitHub Issues
4. 联系开发团队
