# 开发者指南

## 概述

本文档为IPv6 WireGuard Manager项目的开发者提供详细的开发指南，包括项目架构、开发环境设置、代码规范、API开发等内容。

## 项目架构

### 整体架构

```
IPv6 WireGuard Manager
├── backend/                 # 后端服务 (FastAPI)
│   ├── app/
│   │   ├── core/           # 核心模块
│   │   ├── api/            # API路由
│   │   ├── models/         # 数据模型
│   │   ├── services/       # 业务逻辑
│   │   └── utils/          # 工具函数
│   ├── migrations/         # 数据库迁移
│   ├── tests/              # 测试文件
│   └── requirements.txt    # 依赖包
├── php-frontend/           # 前端应用 (PHP)
│   ├── config/             # 配置文件
│   ├── includes/           # 公共文件
│   ├── assets/             # 静态资源
│   ├── pages/              # 页面文件
│   └── services/           # 服务文件
├── docs/                   # 项目文档
├── scripts/                # 部署脚本
└── docker/                 # Docker配置
```

### 技术栈

| 组件 | 技术 | 版本 |
|------|------|------|
| **后端框架** | FastAPI | 0.100+ |
| **数据库** | MySQL | 8.0+ |
| **ORM** | SQLAlchemy | 2.0+ |
| **认证** | JWT | PyJWT |
| **前端** | PHP | 8.1+ |
| **Web服务器** | Nginx | 1.18+ |
| **容器化** | Docker | 20.10+ |
| **监控** | Prometheus | 2.40+ |

## 开发环境设置

### 1. 环境要求

```bash
# Python 3.8+
python --version

# Node.js 16+
node --version

# MySQL 8.0+
mysql --version

# Git
git --version
```

### 2. 项目克隆

```bash
# 克隆项目
git clone https://github.com/your-repo/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 创建开发分支
git checkout -b feature/your-feature-name
```

### 3. 后端环境设置

```bash
# 进入后端目录
cd backend

# 创建虚拟环境
python -m venv venv

# 激活虚拟环境
source venv/bin/activate  # Linux/macOS
# 或
venv\Scripts\activate  # Windows

# 安装依赖
pip install -r requirements.txt
pip install -r requirements-dev.txt  # 开发依赖
```

### 4. 前端环境设置

```bash
# 进入前端目录
cd php-frontend

# 安装依赖
npm install

# 安装开发工具
npm install -g eslint prettier
```

### 5. 数据库设置

```bash
# 启动MySQL服务
sudo systemctl start mysql

# 创建开发数据库
mysql -u root -p
```

```sql
CREATE DATABASE ipv6wgm_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'ipv6wgm_dev'@'localhost' IDENTIFIED BY 'dev_password';
GRANT ALL PRIVILEGES ON ipv6wgm_dev.* TO 'ipv6wgm_dev'@'localhost';
FLUSH PRIVILEGES;
```

```bash
# 导入数据库结构
mysql -u ipv6wgm_dev -p ipv6wgm_dev < migrations/init.sql
```

### 6. 环境变量配置

```bash
# 复制环境变量模板
cp env.example .env

# 编辑环境变量
nano .env
```

```bash
# .env 文件内容
DEBUG=true
LOG_LEVEL=DEBUG
DATABASE_URL=mysql://ipv6wgm_dev:dev_password@localhost:3306/ipv6wgm_dev
SECRET_KEY=dev_secret_key_change_in_production
API_V1_STR=/api/v1
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
```

### 7. 启动开发服务器

```bash
# 启动后端服务
cd backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# 启动前端服务 (另一个终端)
cd php-frontend
php -S localhost:8080
```

## 代码规范

### 1. Python代码规范

#### 1.1 PEP 8规范

```python
# 导入顺序
import os
import sys
from typing import List, Dict, Optional

from fastapi import FastAPI, HTTPException
from sqlalchemy import Column, Integer, String

from app.core.config import settings
from app.models.user import User

# 类定义
class UserService:
    """用户服务类"""
    
    def __init__(self):
        self.db = get_database()
    
    async def create_user(self, user_data: Dict[str, str]) -> User:
        """创建用户"""
        # 实现逻辑
        pass

# 函数定义
def calculate_total_price(items: List[Dict]) -> float:
    """计算总价格"""
    return sum(item['price'] for item in items)
```

#### 1.2 类型注解

```python
from typing import List, Dict, Optional, Union
from pydantic import BaseModel

# 函数类型注解
async def get_user_by_id(user_id: int) -> Optional[User]:
    """根据ID获取用户"""
    pass

# 类类型注解
class UserCreate(BaseModel):
    username: str
    email: str
    password: str

# 复杂类型注解
def process_data(
    data: List[Dict[str, Union[str, int]]]
) -> Dict[str, List[str]]:
    """处理数据"""
    pass
```

#### 1.3 文档字符串

```python
def create_wireguard_client(
    name: str,
    server_id: int,
    public_key: str,
    allowed_ips: str = "0.0.0.0/0"
) -> Dict[str, str]:
    """
    创建WireGuard客户端
    
    Args:
        name: 客户端名称
        server_id: 服务器ID
        public_key: 客户端公钥
        allowed_ips: 允许的IP地址范围，默认为所有IP
    
    Returns:
        包含客户端配置信息的字典
        
    Raises:
        ValidationError: 当输入参数无效时
        ServerNotFoundError: 当服务器不存在时
        
    Example:
        >>> client = create_wireguard_client(
        ...     name="test_client",
        ...     server_id=1,
        ...     public_key="ABC123..."
        ... )
        >>> print(client['config'])
    """
    pass
```

### 2. JavaScript/PHP代码规范

#### 2.1 JavaScript规范

```javascript
// 使用ES6+语法
const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || 'http://localhost:8000/api/v1';

// 函数定义
const createWireGuardClient = async (clientData) => {
  try {
    const response = await fetch(`${API_BASE_URL}/wireguard/clients`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${getToken()}`
      },
      body: JSON.stringify(clientData)
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('Error creating client:', error);
    throw error;
  }
};

// 类定义
class ApiClient {
  constructor(baseURL, token) {
    this.baseURL = baseURL;
    this.token = token;
  }
  
  async request(endpoint, options = {}) {
    // 实现逻辑
  }
}
```

#### 2.2 PHP规范

```php
<?php
/**
 * WireGuard客户端管理类
 */
class WireGuardClientManager
{
    private $apiClient;
    private $config;
    
    /**
     * 构造函数
     * 
     * @param ApiClient $apiClient API客户端实例
     * @param array $config 配置数组
     */
    public function __construct(ApiClient $apiClient, array $config = [])
    {
        $this->apiClient = $apiClient;
        $this->config = array_merge($this->getDefaultConfig(), $config);
    }
    
    /**
     * 创建客户端
     * 
     * @param array $clientData 客户端数据
     * @return array 创建结果
     * @throws Exception 当创建失败时
     */
    public function createClient(array $clientData): array
    {
        try {
            $response = $this->apiClient->post('/wireguard/clients', $clientData);
            return $response['data'];
        } catch (Exception $e) {
            error_log("Failed to create client: " . $e->getMessage());
            throw $e;
        }
    }
    
    /**
     * 获取默认配置
     * 
     * @return array 默认配置
     */
    private function getDefaultConfig(): array
    {
        return [
            'timeout' => 30,
            'retry_count' => 3
        ];
    }
}
```

### 3. 提交规范

#### 3.1 提交信息格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### 3.2 提交类型

| 类型 | 描述 |
|------|------|
| `feat` | 新功能 |
| `fix` | 修复bug |
| `docs` | 文档更新 |
| `style` | 代码格式调整 |
| `refactor` | 代码重构 |
| `test` | 测试相关 |
| `chore` | 构建过程或辅助工具的变动 |

#### 3.3 提交示例

```bash
# 新功能
git commit -m "feat(auth): add JWT token refresh functionality"

# 修复bug
git commit -m "fix(wireguard): resolve client configuration generation issue"

# 文档更新
git commit -m "docs(api): update API documentation for new endpoints"

# 代码重构
git commit -m "refactor(database): optimize database connection pooling"
```

## API开发

### 1. API设计原则

#### 1.1 RESTful设计

```python
# 资源命名
GET    /api/v1/users              # 获取用户列表
POST   /api/v1/users              # 创建用户
GET    /api/v1/users/{id}         # 获取特定用户
PUT    /api/v1/users/{id}         # 更新用户
DELETE /api/v1/users/{id}         # 删除用户

# 嵌套资源
GET    /api/v1/users/{id}/clients  # 获取用户的客户端列表
POST   /api/v1/users/{id}/clients # 为用户创建客户端
```

#### 1.2 响应格式

```python
# 成功响应
{
  "success": true,
  "data": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com"
  },
  "message": "操作成功"
}

# 错误响应
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "验证失败",
    "details": {
      "field": "email",
      "value": "invalid-email"
    },
    "request_id": "req_1234567890",
    "timestamp": "2024-01-01T12:00:00Z"
  }
}
```

### 2. 路由定义

#### 2.1 使用API路由管理器

```python
from app.core.api_router import api_endpoint
from app.core.api_paths import APIPaths
from app.models.user import User
from app.schemas.user import UserCreate, UserResponse

@api_endpoint(
    path=APIPaths.USERS.LIST,
    method="GET",
    tags=["用户管理"],
    summary="获取用户列表",
    description="获取系统中所有用户的列表，支持分页和搜索"
)
async def get_users(
    page: int = 1,
    size: int = 20,
    search: Optional[str] = None,
    role: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """获取用户列表"""
    # 实现逻辑
    pass
```

#### 2.2 传统路由定义

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter()

@router.get("/users", response_model=List[UserResponse])
async def get_users(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db)
):
    """获取用户列表"""
    users = await user_service.get_users(db, skip=skip, limit=limit)
    return users
```

### 3. 数据模型

#### 3.1 SQLAlchemy模型

```python
from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func

Base = declarative_base()

class User(Base):
    """用户模型"""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    def __repr__(self):
        return f"<User(id={self.id}, username='{self.username}')>"
```

#### 3.2 Pydantic模型

```python
from pydantic import BaseModel, EmailStr, validator
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    """用户基础模型"""
    username: str
    email: EmailStr
    
    @validator('username')
    def validate_username(cls, v):
        if len(v) < 3:
            raise ValueError('用户名长度不能少于3个字符')
        return v

class UserCreate(UserBase):
    """用户创建模型"""
    password: str
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('密码长度不能少于8个字符')
        return v

class UserResponse(UserBase):
    """用户响应模型"""
    id: int
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True
```

### 4. 服务层

#### 4.1 业务逻辑服务

```python
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate
from app.core.security import get_password_hash, verify_password

class UserService:
    """用户服务类"""
    
    def __init__(self):
        pass
    
    async def create_user(
        self, 
        db: AsyncSession, 
        user_data: UserCreate
    ) -> User:
        """创建用户"""
        # 检查用户名是否已存在
        existing_user = await self.get_user_by_username(db, user_data.username)
        if existing_user:
            raise ValueError("用户名已存在")
        
        # 检查邮箱是否已存在
        existing_email = await self.get_user_by_email(db, user_data.email)
        if existing_email:
            raise ValueError("邮箱已存在")
        
        # 创建用户
        hashed_password = get_password_hash(user_data.password)
        db_user = User(
            username=user_data.username,
            email=user_data.email,
            hashed_password=hashed_password
        )
        
        db.add(db_user)
        await db.commit()
        await db.refresh(db_user)
        
        return db_user
    
    async def get_user_by_id(
        self, 
        db: AsyncSession, 
        user_id: int
    ) -> Optional[User]:
        """根据ID获取用户"""
        result = await db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()
    
    async def get_user_by_username(
        self, 
        db: AsyncSession, 
        username: str
    ) -> Optional[User]:
        """根据用户名获取用户"""
        result = await db.execute(select(User).where(User.username == username))
        return result.scalar_one_or_none()
    
    async def get_user_by_email(
        self, 
        db: AsyncSession, 
        email: str
    ) -> Optional[User]:
        """根据邮箱获取用户"""
        result = await db.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()
    
    async def update_user(
        self, 
        db: AsyncSession, 
        user_id: int, 
        user_data: UserUpdate
    ) -> Optional[User]:
        """更新用户"""
        user = await self.get_user_by_id(db, user_id)
        if not user:
            return None
        
        update_data = user_data.dict(exclude_unset=True)
        if 'password' in update_data:
            update_data['hashed_password'] = get_password_hash(update_data.pop('password'))
        
        await db.execute(
            update(User).where(User.id == user_id).values(**update_data)
        )
        await db.commit()
        
        return await self.get_user_by_id(db, user_id)
    
    async def delete_user(
        self, 
        db: AsyncSession, 
        user_id: int
    ) -> bool:
        """删除用户"""
        result = await db.execute(delete(User).where(User.id == user_id))
        await db.commit()
        return result.rowcount > 0
```

### 5. 依赖注入

#### 5.1 数据库依赖

```python
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

# 创建异步引擎
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_pre_ping=True,
    pool_recycle=300
)

# 创建会话工厂
AsyncSessionLocal = sessionmaker(
    engine, 
    class_=AsyncSession, 
    expire_on_commit=False
)

async def get_db() -> AsyncSession:
    """获取数据库会话"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
```

#### 5.2 认证依赖

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.security import verify_token
from app.services.user_service import UserService

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db)
) -> User:
    """获取当前用户"""
    token = credentials.credentials
    
    try:
        payload = verify_token(token)
        username = payload.get("sub")
        if username is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="无效的认证凭据"
            )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="无效的认证凭据"
        )
    
    user_service = UserService()
    user = await user_service.get_user_by_username(db, username)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户不存在"
        )
    
    return user

async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """获取当前活跃用户"""
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="用户已被禁用"
        )
    return current_user
```

## 测试

### 1. 测试框架

#### 1.1 后端测试

```python
import pytest
from httpx import AsyncClient
from app.main import app
from app.core.database import get_db
from app.models.user import User

@pytest.fixture
async def client():
    """测试客户端"""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.fixture
async def test_user(db: AsyncSession):
    """测试用户"""
    user = User(
        username="testuser",
        email="test@example.com",
        hashed_password="hashed_password"
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user

@pytest.mark.asyncio
async def test_create_user(client: AsyncClient):
    """测试创建用户"""
    user_data = {
        "username": "newuser",
        "email": "newuser@example.com",
        "password": "password123"
    }
    
    response = await client.post("/api/v1/users", json=user_data)
    
    assert response.status_code == 201
    data = response.json()
    assert data["success"] is True
    assert data["data"]["username"] == user_data["username"]

@pytest.mark.asyncio
async def test_get_user(client: AsyncClient, test_user: User):
    """测试获取用户"""
    response = await client.get(f"/api/v1/users/{test_user.id}")
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["username"] == test_user.username
```

#### 1.2 前端测试

```javascript
// Jest测试示例
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { ApiClient } from '../services/api_client';
import { UserList } from '../components/UserList';

// Mock API客户端
jest.mock('../services/api_client');
const mockApiClient = ApiClient as jest.Mocked<typeof ApiClient>;

describe('UserList Component', () => {
  beforeEach(() => {
    mockApiClient.get.mockClear();
  });

  test('renders user list', async () => {
    const mockUsers = [
      { id: 1, username: 'user1', email: 'user1@example.com' },
      { id: 2, username: 'user2', email: 'user2@example.com' }
    ];
    
    mockApiClient.get.mockResolvedValue({
      success: true,
      data: mockUsers
    });

    render(<UserList />);

    await waitFor(() => {
      expect(screen.getByText('user1')).toBeInTheDocument();
      expect(screen.getByText('user2')).toBeInTheDocument();
    });
  });

  test('handles API error', async () => {
    mockApiClient.get.mockRejectedValue(new Error('API Error'));

    render(<UserList />);

    await waitFor(() => {
      expect(screen.getByText('加载用户列表失败')).toBeInTheDocument();
    });
  });
});
```

### 2. 测试运行

#### 2.1 运行测试

```bash
# 运行所有测试
pytest

# 运行特定测试文件
pytest tests/test_user_service.py

# 运行特定测试函数
pytest tests/test_user_service.py::test_create_user

# 运行测试并生成覆盖率报告
pytest --cov=app --cov-report=html

# 运行测试并显示详细输出
pytest -v

# 运行测试并停止在第一个失败
pytest -x
```

#### 2.2 测试配置

```python
# pytest.ini
[tool:pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = 
    -v
    --tb=short
    --strict-markers
    --disable-warnings
markers =
    slow: marks tests as slow (deselect with '-m "not slow"')
    integration: marks tests as integration tests
```

## 调试

### 1. 后端调试

#### 1.1 日志调试

```python
import logging
from app.core.logging import get_logger

logger = get_logger(__name__)

async def create_user(user_data: UserCreate):
    """创建用户"""
    logger.info("开始创建用户", extra={
        "username": user_data.username,
        "email": user_data.email
    })
    
    try:
        # 业务逻辑
        user = await user_service.create_user(user_data)
        logger.info("用户创建成功", extra={
            "user_id": user.id,
            "username": user.username
        })
        return user
    except Exception as e:
        logger.error("用户创建失败", extra={
            "error": str(e),
            "username": user_data.username
        }, exc_info=True)
        raise
```

#### 1.2 断点调试

```python
# 使用pdb调试
import pdb

async def debug_function():
    """调试函数"""
    data = {"key": "value"}
    pdb.set_trace()  # 设置断点
    result = process_data(data)
    return result

# 使用ipdb调试（更友好的界面）
import ipdb

async def debug_function():
    """调试函数"""
    data = {"key": "value"}
    ipdb.set_trace()  # 设置断点
    result = process_data(data)
    return result
```

### 2. 前端调试

#### 2.1 浏览器调试

```javascript
// 使用console调试
const createUser = async (userData) => {
  console.log('Creating user:', userData);
  
  try {
    const response = await apiClient.post('/users', userData);
    console.log('User created successfully:', response);
    return response;
  } catch (error) {
    console.error('Failed to create user:', error);
    throw error;
  }
};

// 使用debugger语句
const processData = (data) => {
  debugger; // 浏览器会在此处暂停
  const processed = data.map(item => item.value);
  return processed;
};
```

#### 2.2 网络调试

```javascript
// 拦截网络请求
const originalFetch = window.fetch;
window.fetch = async (...args) => {
  console.log('Fetch request:', args);
  const response = await originalFetch(...args);
  console.log('Fetch response:', response);
  return response;
};
```

## 性能优化

### 1. 数据库优化

#### 1.1 查询优化

```python
# 使用索引
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True)  # 添加索引
    email = Column(String(100), unique=True, index=True)    # 添加索引

# 使用预加载
from sqlalchemy.orm import selectinload

async def get_users_with_clients(db: AsyncSession):
    """获取用户及其客户端"""
    result = await db.execute(
        select(User).options(selectinload(User.clients))
    )
    return result.scalars().all()

# 使用分页
async def get_users_paginated(
    db: AsyncSession, 
    skip: int = 0, 
    limit: int = 100
):
    """分页获取用户"""
    result = await db.execute(
        select(User).offset(skip).limit(limit)
    )
    return result.scalars().all()
```

#### 1.2 连接池优化

```python
from sqlalchemy.ext.asyncio import create_async_engine

engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=20,          # 连接池大小
    max_overflow=30,        # 最大溢出连接数
    pool_pre_ping=True,    # 连接前ping检查
    pool_recycle=3600,     # 连接回收时间
    echo=settings.DEBUG
)
```

### 2. 缓存优化

#### 2.1 Redis缓存

```python
import redis
from app.core.config import settings

# Redis连接
redis_client = redis.Redis(
    host=settings.REDIS_HOST,
    port=settings.REDIS_PORT,
    db=settings.REDIS_DB,
    decode_responses=True
)

# 缓存装饰器
def cache_result(expire_time: int = 300):
    """缓存结果装饰器"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            # 生成缓存键
            cache_key = f"{func.__name__}:{hash(str(args) + str(kwargs))}"
            
            # 尝试从缓存获取
            cached_result = redis_client.get(cache_key)
            if cached_result:
                return json.loads(cached_result)
            
            # 执行函数并缓存结果
            result = await func(*args, **kwargs)
            redis_client.setex(
                cache_key, 
                expire_time, 
                json.dumps(result, default=str)
            )
            
            return result
        return wrapper
    return decorator

# 使用缓存
@cache_result(expire_time=600)
async def get_user_by_id(user_id: int):
    """获取用户（带缓存）"""
    return await user_service.get_user_by_id(user_id)
```

### 3. API优化

#### 3.1 响应压缩

```python
from fastapi.middleware.gzip import GZipMiddleware

app.add_middleware(GZipMiddleware, minimum_size=1000)
```

#### 3.2 异步处理

```python
import asyncio
from concurrent.futures import ThreadPoolExecutor

# 线程池执行器
executor = ThreadPoolExecutor(max_workers=4)

async def process_large_data(data):
    """处理大量数据"""
    # 将CPU密集型任务放到线程池
    loop = asyncio.get_event_loop()
    result = await loop.run_in_executor(
        executor, 
        cpu_intensive_function, 
        data
    )
    return result
```

## 部署

### 1. 开发环境部署

```bash
# 使用Docker Compose
docker-compose up -d

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart
```

### 2. 生产环境部署

```bash
# 使用生产配置
docker-compose -f docker-compose.production.yml up -d

# 使用微服务架构
docker-compose -f docker-compose.microservices.yml up -d
```

### 3. CI/CD集成

#### 3.1 GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: ipv6wgm_test
        ports:
          - 3306:3306
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: |
        cd backend
        pip install -r requirements.txt
        pip install -r requirements-dev.txt
    
    - name: Run tests
      run: |
        cd backend
        pytest --cov=app --cov-report=xml
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: backend/coverage.xml
```

## 最佳实践

### 1. 代码质量

- **类型注解**: 为所有函数和变量添加类型注解
- **文档字符串**: 为所有公共函数和类添加文档字符串
- **错误处理**: 使用统一的错误处理机制
- **日志记录**: 记录关键操作和错误信息
- **测试覆盖**: 保持高测试覆盖率

### 2. 安全实践

- **输入验证**: 验证所有用户输入
- **SQL注入防护**: 使用参数化查询
- **XSS防护**: 对输出进行转义
- **CSRF防护**: 使用CSRF令牌
- **权限检查**: 检查用户权限

### 3. 性能实践

- **数据库优化**: 使用索引和查询优化
- **缓存策略**: 合理使用缓存
- **异步处理**: 使用异步编程
- **资源管理**: 及时释放资源
- **监控指标**: 监控关键性能指标

### 4. 维护实践

- **版本控制**: 使用语义化版本
- **文档更新**: 保持文档同步
- **代码审查**: 进行代码审查
- **持续集成**: 使用CI/CD
- **监控告警**: 设置监控告警

---

**注意**: 本文档基于当前版本，如有更新请查看最新版本文档。
