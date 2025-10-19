# 迁移指南

## 概述

本文档帮助开发者从旧版本的 IPv6 WireGuard Manager 迁移到新架构版本 (v3.0.0)。新版本引入了统一配置管理、依赖注入容器、路径配置工厂和前端API系统重构。

## 迁移检查清单

### ✅ 迁移前准备

- [ ] 备份现有数据和配置
- [ ] 记录当前环境变量设置
- [ ] 备份数据库
- [ ] 记录自定义配置修改
- [ ] 测试当前系统功能

### ✅ 后端迁移

- [ ] 更新配置管理方式
- [ ] 迁移到依赖注入容器
- [ ] 更新路径配置使用方式
- [ ] 修复循环导入问题
- [ ] 更新服务注册方式

### ✅ 前端迁移

- [ ] 更新API端点配置
- [ ] 迁移到新的API客户端
- [ ] 移除外部依赖
- [ ] 更新错误处理机制
- [ ] 测试API连接

### ✅ 部署迁移

- [ ] 更新部署脚本
- [ ] 更新Docker配置
- [ ] 更新systemd服务配置
- [ ] 更新Nginx配置
- [ ] 验证服务启动

## 详细迁移步骤

### 1. 后端配置管理迁移

#### 旧版本 (v2.x)

```python
# 旧版本：多个配置文件
from app.core.config import settings
from app.core.path_config import PathConfig
from app.core.database import get_database_url

# 直接使用全局实例
path_config = PathConfig(settings.INSTALL_DIR)
wg_dir = path_config.wireguard_config_dir
```

#### 新版本 (v3.0)

```python
# 新版本：统一配置管理
from app.core.unified_config import settings
from app.core.path_config import create_path_config

# 使用工厂函数创建配置实例
path_config = create_path_config()
wg_dir = path_config.get_path('wireguard_config_dir')
```

#### 迁移步骤

1. **更新导入语句**
   ```python
   # 替换所有旧导入
   # 旧: from app.core.config import settings
   # 新: from app.core.unified_config import settings
   ```

2. **更新路径配置使用**
   ```python
   # 旧方式
   path_config = PathConfig(settings.INSTALL_DIR)
   wg_dir = path_config.wireguard_config_dir
   
   # 新方式
   path_config = create_path_config()
   wg_dir = path_config.get_path('wireguard_config_dir')
   ```

3. **更新配置访问**
   ```python
   # 旧方式
   db_url = get_database_url()
   
   # 新方式
   db_url = settings.DATABASE_URL
   ```

### 2. 依赖注入迁移

#### 旧版本 (v2.x)

```python
# 旧版本：直接实例化
from app.core.config import settings
from app.services.database import DatabaseService

# 直接创建实例
db_service = DatabaseService(settings.DATABASE_URL)
logger = get_logger(__name__)
```

#### 新版本 (v3.0)

```python
# 新版本：依赖注入
from app.core.di_container import (
    register_singleton, register_factory, get_service, ServiceNames
)
from app.core.unified_config import settings

# 注册服务
register_singleton(ServiceNames.CONFIG, settings)
register_singleton(ServiceNames.DATABASE, DatabaseService())

# 使用服务
config = get_service(ServiceNames.CONFIG)
db_service = get_service(ServiceNames.DATABASE)
```

#### 迁移步骤

1. **创建服务注册函数**
   ```python
   def setup_services():
       """设置所有服务"""
       register_singleton(ServiceNames.CONFIG, settings)
       register_singleton(ServiceNames.DATABASE, DatabaseService())
       register_singleton(ServiceNames.LOGGER, get_logger(__name__))
   ```

2. **更新服务使用**
   ```python
   # 旧方式
   def get_user(user_id):
       db = DatabaseService(settings.DATABASE_URL)
       return db.get_user(user_id)
   
   # 新方式
   @inject(ServiceNames.DATABASE)
   def get_user(db, user_id):
       return db.get_user(user_id)
   ```

3. **在应用启动时调用**
   ```python
   # 在 main.py 中
   from app.core.di_container import setup_services
   setup_services()
   ```

### 3. 前端API系统迁移

#### 旧版本 (v2.x)

```javascript
// 旧版本：外部依赖
import { ApiPathBuilder } from '../public/js/ApiPathBuilder.js';

// 直接使用外部类
const apiPathBuilder = new ApiPathBuilder('http://localhost:8000/api');
const userUrl = apiPathBuilder.buildUrl('users.get', { user_id: '123' });
```

#### 新版本 (v3.0)

```javascript
// 新版本：本地API系统
import { buildUrl, API_CONFIG } from '../config/api_endpoints.js';

// 使用本地函数
const userUrl = buildUrl('users.get', { user_id: '123' });
```

#### 迁移步骤

1. **更新API端点配置**
   ```javascript
   // 旧方式
   const apiPathBuilder = new ApiPathBuilder('http://localhost:8000/api');
   
   // 新方式
   import { API_CONFIG, buildUrl } from '../config/api_endpoints.js';
   ```

2. **更新API客户端**
   ```javascript
   // 旧方式
   const apiClient = new ApiClient(apiPathBuilder);
   
   // 新方式
   import apiClient from '../services/api_client.js';
   ```

3. **更新错误处理**
   ```javascript
   // 旧方式
   try {
       const response = await apiClient.get('users');
   } catch (error) {
       console.error('API错误:', error);
   }
   
   // 新方式（自动错误处理）
   const users = await apiClient.get('users');
   ```

### 4. 部署配置迁移

#### 旧版本 (v2.x)

```bash
# 旧版本：systemd服务配置
ExecStart=/opt/ipv6-wireguard-manager/venv/bin/uvicorn backend.app.main:app --host :: --port 8000
```

#### 新版本 (v3.0)

```bash
# 新版本：修复的systemd服务配置
ExecStart=/opt/ipv6-wireguard-manager/venv/bin/uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
```

#### 迁移步骤

1. **更新systemd服务文件**
   ```bash
   # 停止服务
   sudo systemctl stop ipv6-wireguard-manager
   
   # 编辑服务文件
   sudo nano /etc/systemd/system/ipv6-wireguard-manager.service
   
   # 修改ExecStart行
   # 旧: --host ::
   # 新: --host 0.0.0.0
   
   # 重新加载并启动
   sudo systemctl daemon-reload
   sudo systemctl start ipv6-wireguard-manager
   ```

2. **更新Docker配置**
   ```yaml
   # docker-compose.yml
   services:
     api:
       command: uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
   ```

3. **更新部署脚本**
   ```bash
   # install.sh
   ExecStart=$INSTALL_DIR/venv/bin/uvicorn backend.app.main:app --host 0.0.0.0 --port $API_PORT --workers 1
   ```

## 常见迁移问题

### 1. 循环导入问题

#### 问题描述
```
ImportError: cannot import name 'settings' from partially initialized module 'backend.app.core.config_enhanced'
```

#### 解决方案
```python
# 旧版本：模块级导入
from .path_config import PathConfig

class Settings:
    @property
    def WIREGUARD_CONFIG_DIR(self) -> str:
        path_config = PathConfig(self.INSTALL_DIR)
        return str(path_config.wireguard_config_dir)

# 新版本：局部导入
class Settings:
    @property
    def WIREGUARD_CONFIG_DIR(self) -> str:
        from .path_config import PathConfig
        path_config = PathConfig(self.INSTALL_DIR)
        return str(path_config.wireguard_config_dir)
```

### 2. API端点配置问题

#### 问题描述
```
ReferenceError: ApiPathBuilder is not defined
```

#### 解决方案
```javascript
// 旧版本：外部依赖
import { ApiPathBuilder } from '../public/js/ApiPathBuilder.js';

// 新版本：本地实现
import { buildUrl, API_CONFIG } from '../config/api_endpoints.js';
```

### 3. 服务启动问题

#### 问题描述
```
API服务无法启动，IPv6连接失败
```

#### 解决方案
```bash
# 检查服务配置
sudo systemctl status ipv6-wireguard-manager

# 修复host绑定
sudo sed -i 's/--host ::/--host 0.0.0.0/' /etc/systemd/system/ipv6-wireguard-manager.service

# 重启服务
sudo systemctl daemon-reload
sudo systemctl restart ipv6-wireguard-manager
```

## 迁移验证

### 1. 后端验证

```bash
# 检查API服务状态
sudo systemctl status ipv6-wireguard-manager

# 检查端口监听
netstat -tuln | grep :8000

# 测试API连接
curl -X GET "http://localhost:8000/api/v1/health"
```

### 2. 前端验证

```javascript
// 测试API配置
console.log('API配置:', API_CONFIG);

// 测试路径构建
const testUrl = buildUrl('auth.login');
console.log('测试URL:', testUrl);

// 测试API客户端
apiClient.get('health').then(response => {
    console.log('API连接正常:', response.data);
}).catch(error => {
    console.error('API连接失败:', error);
});
```

### 3. 功能验证

- [ ] 用户登录功能
- [ ] WireGuard配置管理
- [ ] 服务器状态监控
- [ ] 文件上传功能
- [ ] 系统设置功能

## 回滚计划

如果迁移过程中遇到问题，可以按以下步骤回滚：

### 1. 停止新服务

```bash
sudo systemctl stop ipv6-wireguard-manager
```

### 2. 恢复旧配置

```bash
# 恢复systemd服务文件
sudo cp /etc/systemd/system/ipv6-wireguard-manager.service.backup /etc/systemd/system/ipv6-wireguard-manager.service

# 恢复环境变量
cp .env.backup .env
```

### 3. 恢复代码

```bash
# 切换到旧版本
git checkout v2.x

# 重新安装依赖
pip install -r requirements.txt
```

### 4. 重启服务

```bash
sudo systemctl daemon-reload
sudo systemctl start ipv6-wireguard-manager
```

## 迁移后优化

### 1. 性能优化

```python
# 使用依赖注入提高性能
@singleton(ServiceNames.CACHE)
class CacheManager:
    def __init__(self):
        self.cache = {}
```

### 2. 代码质量

```python
# 使用类型提示
from typing import Optional
from app.core.di_container import get_service, ServiceNames

def get_user(user_id: int) -> Optional[dict]:
    db = get_service(ServiceNames.DATABASE)
    return db.get_user(user_id)
```

### 3. 测试覆盖

```python
# 添加单元测试
def test_service_injection():
    container = DIContainer()
    container.register_singleton('test_service', TestService())
    
    service = container.get('test_service')
    assert isinstance(service, TestService)
```

## 支持与帮助

如果在迁移过程中遇到问题，请：

1. 查看本文档的常见问题部分
2. 检查应用日志中的错误信息
3. 参考项目的 GitHub Issues
4. 联系开发团队

## 更新日志

### v3.0.0 (2024-10-19)
- ✅ 统一配置管理系统
- ✅ 依赖注入容器
- ✅ 路径配置工厂函数
- ✅ 前端API系统重构
- ✅ 循环导入问题修复
- ✅ 服务启动问题修复

### 迁移工具

我们提供了自动化迁移脚本来帮助简化迁移过程：

```bash
# 运行迁移脚本
./scripts/migrate_to_v3.sh

# 验证迁移结果
./scripts/verify_migration.sh
```

## 总结

新架构版本 (v3.0.0) 提供了更好的可维护性、测试性和稳定性。通过遵循本迁移指南，您可以安全地将现有系统升级到新版本，并享受新架构带来的优势。
