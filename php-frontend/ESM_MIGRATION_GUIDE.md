# ESM 模块迁移指南

## 概述

本项目已从 UMD 模块系统迁移到现代 ESM (ES Modules) 系统，提供更好的模块化支持和开发体验。

## 主要变化

### 1. 模块系统统一
- ✅ `config/api_endpoints.js` - 从 UMD 改为 ESM
- ✅ `services/api_client.js` - 重新创建为 ESM 版本
- ✅ 所有模块使用 `import/export` 语法

### 2. 文件结构
```
php-frontend/
├── config/
│   └── api_endpoints.js          # ESM API配置
├── services/
│   └── api_client.js             # ESM API客户端
├── public/
│   ├── js/
│   │   └── app.js               # ESM主应用脚本
│   ├── index.html               # 主页面
│   └── login.html               # 登录页面
├── package.json                 # 现代前端配置
├── build.js                     # Vite构建配置
└── ESM_MIGRATION_GUIDE.md       # 本指南
```

## 使用方法

### 1. 开发环境设置

```bash
# 安装依赖
cd php-frontend
npm install

# 启动开发服务器
npm run dev
```

### 2. 在HTML中使用ESM模块

```html
<!-- 引入axios -->
<script src="https://cdn.jsdelivr.net/npm/axios@1.6.0/dist/axios.min.js"></script>

<!-- 使用ESM模块 -->
<script type="module" src="js/app.js"></script>
```

### 3. 在JavaScript中使用模块

```javascript
// 导入API客户端
import { apiClient, ApiClient } from '../services/api_client.js';
import { apiPathBuilder, API_CONFIG } from '../config/api_endpoints.js';

// 使用API客户端
const response = await apiClient.get('users.list');
console.log(response);
```

## API 使用示例

### 认证
```javascript
// 登录
const loginResponse = await apiClient.login({
    username: 'admin',
    password: 'password'
});

// 获取当前用户
const user = await apiClient.getCurrentUser();
```

### WireGuard 管理
```javascript
// 获取WireGuard状态
const status = await apiClient.getWireGuardStatus();

// 启动WireGuard
await apiClient.startWireGuard();

// 获取对等节点列表
const peers = await apiClient.getWireGuardPeers();
```

### 用户管理
```javascript
// 获取用户列表
const users = await apiClient.getUsers();

// 创建用户
const newUser = await apiClient.createUser({
    username: 'newuser',
    email: 'newuser@example.com',
    password: 'password'
});
```

## 构建和部署

### 开发模式
```bash
npm run dev
```
- 启动 Vite 开发服务器
- 支持热重载
- 自动代理 API 请求到后端

### 生产构建
```bash
npm run build
```
- 构建优化后的静态文件
- 输出到 `dist/` 目录
- 支持代码分割和压缩

### 预览构建结果
```bash
npm run preview
```
- 预览构建后的应用
- 测试生产环境配置

## 浏览器兼容性

### 支持的浏览器
- Chrome 61+
- Firefox 60+
- Safari 10.1+
- Edge 16+

### 不支持的浏览器
- Internet Explorer (所有版本)
- 旧版移动浏览器

### 降级方案
对于不支持的浏览器，可以使用以下方案：

1. **Babel 转译**：将 ESM 转换为兼容的格式
2. **Webpack 打包**：使用 Webpack 进行模块打包
3. **UMD 回退**：为旧浏览器提供 UMD 版本

## 迁移检查清单

- [x] 将 `api_endpoints.js` 从 UMD 改为 ESM
- [x] 重新创建 `api_client.js` 为 ESM 版本
- [x] 创建 ESM 主应用脚本
- [x] 创建示例 HTML 页面
- [x] 配置 Vite 构建系统
- [x] 添加 package.json 支持
- [x] 创建使用说明文档

## 故障排除

### 常见问题

1. **模块导入错误**
   - 确保使用 `type="module"` 属性
   - 检查文件路径是否正确
   - 验证模块导出语法

2. **CORS 错误**
   - 确保后端 CORS 配置正确
   - 检查 API 基础 URL 设置
   - 验证代理配置

3. **构建错误**
   - 检查 Node.js 版本 (推荐 16+)
   - 清除 node_modules 重新安装
   - 验证 Vite 配置

### 调试技巧

1. **浏览器控制台**
   - 查看网络请求
   - 检查 JavaScript 错误
   - 验证模块加载

2. **开发工具**
   - 使用 Vite 开发服务器
   - 启用热重载
   - 查看构建日志

## 总结

ESM 迁移提供了：
- ✅ 更好的模块化支持
- ✅ 现代 JavaScript 特性
- ✅ 更好的开发体验
- ✅ 优化的构建系统
- ✅ 更好的浏览器兼容性

现在可以使用现代前端开发工具链进行开发和构建！
