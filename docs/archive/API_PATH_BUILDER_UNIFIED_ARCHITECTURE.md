# API路径构建器统一架构设计

## 概述

本文档描述了IPv6 WireGuard管理系统中API路径构建器的统一架构设计，旨在将分散在多个文件中的API路径构建功能合并为每种语言的单个模块，提高代码的可维护性和一致性。

## 当前问题分析

### 后端Python API路径构建器现状

1. **分散的文件结构**：
   - `api_paths.py`: 定义API路径常量和基本类
   - `api_config.py`: 定义路径常量和辅助函数
   - `path_manager.py`: 实现路径管理器类
   - `api_docs.py`: API文档生成相关

2. **功能重叠**：
   - `api_paths.py`和`api_config.py`都定义了路径常量
   - 多个文件中都有路径构建函数
   - 路径验证逻辑分散在多个地方

3. **命名不一致**：
   - 有些使用下划线命名（如`AUTH_LOGIN`）
   - 有些使用连字符命名（如`WIREGUARD_SEARCH`）
   - 有些使用字典嵌套结构

### 前端PHP API路径构建器现状

1. **相对集中的结构**：
   - `ApiPathManager.php`: 主要的路径管理类
   - `api_config.php`: 路径配置数组

2. **功能完整**：
   - 路径构建、验证、标准化功能齐全
   - 支持嵌套路径和参数替换

## 统一架构设计

### 设计原则

1. **单一职责**：每个模块只负责一个明确的功能
2. **统一接口**：前后端提供相似的接口设计
3. **配置驱动**：路径定义与业务逻辑分离
4. **版本控制**：内置API版本管理机制
5. **类型安全**：提供类型提示和验证

### 后端Python统一API路径构建器

#### 1. 文件结构

```
backend/app/core/api_path_builder/
├── __init__.py              # 导出主要接口
├── config.py                # 路径配置定义
├── builder.py               # 路径构建器核心类
├── validator.py             # 路径验证器
├── version_manager.py       # 版本管理器
└── middleware.py            # FastAPI中间件
```

#### 2. 核心类设计

##### APIPathBuilder

```python
class APIPathBuilder:
    """统一的API路径构建器"""
    
    def __init__(self, config: PathConfig = None, version_manager: VersionManager = None):
        self.config = config or PathConfig()
        self.version_manager = version_manager or VersionManager()
        self.validator = PathValidator(self.config, self.version_manager)
    
    def build_path(self, category: str, action: str = None, **kwargs) -> str:
        """构建API路径"""
        
    def validate_path(self, path: str) -> ValidationResult:
        """验证API路径"""
        
    def normalize_path(self, path: str) -> str:
        """标准化API路径"""
```

##### PathConfig

```python
class PathConfig:
    """路径配置管理"""
    
    def __init__(self):
        self.paths = self._load_default_paths()
    
    def get_path(self, category: str, action: str = None) -> str:
        """获取路径配置"""
        
    def update_path(self, category: str, action: str, path: str) -> None:
        """更新路径配置"""
```

##### VersionManager

```python
class VersionManager:
    """API版本管理"""
    
    def __init__(self):
        self.current_version = APIVersion.V1
        self.supported_versions = {APIVersion.V1}
        self.deprecated_versions = set()
    
    def set_current_version(self, version: APIVersion) -> None:
        """设置当前版本"""
        
    def add_version(self, version: APIVersion, is_deprecated: bool = False) -> None:
        """添加支持的版本"""
```

#### 3. 配置结构

```python
PATHS = {
    "auth": {
        "login": "/auth/login",
        "logout": "/auth/logout",
        "refresh": "/auth/refresh",
        "me": "/auth/me"
    },
    "users": {
        "list": "/users",
        "detail": "/users/{user_id}",
        "update": "/users/{user_id}",
        "delete": "/users/{user_id}",
        "lock": "/users/{user_id}/lock",
        "unlock": "/users/{user_id}/unlock"
    },
    "wireguard": {
        "servers": {
            "list": "/wireguard/servers",
            "detail": "/wireguard/servers/{server_id}",
            "status": "/wireguard/servers/{server_id}/status"
        },
        "clients": {
            "list": "/wireguard/clients",
            "detail": "/wireguard/clients/{client_id}",
            "config": "/wireguard/clients/{client_id}/config"
        }
    }
}
```

### 前端PHP统一API路径构建器

#### 1. 文件结构

```
php-frontend/includes/ApiPathBuilder/
├── ApiPathBuilder.php       # 主要的路径构建器类
├── PathConfig.php           # 路径配置管理
├── PathValidator.php        # 路径验证器
└── VersionManager.php       # 版本管理器
```

#### 2. 核心类设计

##### ApiPathBuilder

```php
class ApiPathBuilder {
    private $config;
    private $versionManager;
    private $validator;
    
    public function __construct($config = null, $versionManager = null) {
        $this->config = $config ?: new PathConfig();
        $this->versionManager = $versionManager ?: new VersionManager();
        $this->validator = new PathValidator($this->config, $this->versionManager);
    }
    
    public function buildPath($category, $action = null, $params = []) {
        /* 构建API路径 */
    }
    
    public function validatePath($path) {
        /* 验证API路径 */
    }
    
    public function normalizePath($path) {
        /* 标准化API路径 */
    }
}
```

##### PathConfig

```php
class PathConfig {
    private $paths;
    
    public function __construct() {
        $this->paths = $this->loadDefaultPaths();
    }
    
    public function getPath($category, $action = null) {
        /* 获取路径配置 */
    }
    
    public function updatePath($category, $action, $path) {
        /* 更新路径配置 */
    }
}
```

#### 3. 配置结构

```php
return [
    'auth' => [
        'login' => '/auth/login',
        'logout' => '/auth/logout',
        'refresh' => '/auth/refresh',
        'me' => '/auth/me'
    ],
    'users' => [
        'list' => '/users',
        'detail' => '/users/{id}',
        'update' => '/users/{id}',
        'delete' => '/users/{id}',
        'lock' => '/users/{id}/lock',
        'unlock' => '/users/{id}/unlock'
    ],
    'wireguard' => [
        'servers' => [
            'list' => '/wireguard/servers',
            'detail' => '/wireguard/servers/{id}',
            'status' => '/wireguard/servers/{id}/status'
        ],
        'clients' => [
            'list' => '/wireguard/clients',
            'detail' => '/wireguard/clients/{id}',
            'config' => '/wireguard/clients/{id}/config'
        ]
    ]
];
```

## 实施计划

### 第一阶段：后端Python统一API路径构建器

1. 创建新的目录结构 `backend/app/core/api_path_builder/`
2. 实现核心类：`APIPathBuilder`, `PathConfig`, `VersionManager`, `PathValidator`
3. 迁移现有路径配置到新的配置结构
4. 创建FastAPI中间件集成
5. 更新现有代码以使用新的API路径构建器

### 第二阶段：前端PHP统一API路径构建器

1. 创建新的目录结构 `php-frontend/includes/ApiPathBuilder/`
2. 实现核心类：`ApiPathBuilder`, `PathConfig`, `VersionManager`, `PathValidator`
3. 迁移现有路径配置到新的配置结构
4. 更新现有代码以使用新的API路径构建器

### 第三阶段：测试和优化

1. 编写单元测试
2. 集成测试
3. 性能优化
4. 文档更新

## 预期收益

1. **代码一致性**：前后端使用相似的API路径构建接口
2. **维护性提升**：集中管理路径配置，减少重复代码
3. **可扩展性**：易于添加新的API路径和版本
4. **类型安全**：提供类型提示和验证，减少运行时错误
5. **开发效率**：统一的接口减少学习成本

## 风险与缓解措施

1. **向后兼容性**：提供适配器模式确保现有代码继续工作
2. **迁移成本**：分阶段迁移，先实现新接口，再逐步替换旧代码
3. **性能影响**：通过缓存和优化减少性能开销

## 总结

通过统一API路径构建器架构，我们将解决当前系统中API路径管理分散、不一致的问题，提高代码的可维护性和开发效率。该架构设计遵循单一职责原则，提供清晰的接口和强大的功能，同时保持前后端的一致性。