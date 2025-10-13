# 开发指南

本文档为IPv6 WireGuard Manager项目的开发指南，包含开发环境搭建、代码规范、测试流程等内容。

## 📋 目录

- [开发环境搭建](#开发环境搭建)
- [项目结构](#项目结构)
- [代码规范](#代码规范)
- [测试指南](#测试指南)
- [部署流程](#部署流程)
- [贡献流程](#贡献流程)

## 🛠️ 开发环境搭建

### 系统要求

- **操作系统**：Ubuntu 20.04+, macOS 10.15+, Windows 10+
- **Python**：3.11+
- **Node.js**：18+
- **Docker**：20.10+
- **Git**：2.30+

### 环境准备

#### 1. 克隆项目

```bash
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager
```

#### 2. 后端环境

```bash
# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/macOS
# 或
venv\Scripts\activate  # Windows

# 安装依赖
pip install -r backend/requirements.txt
pip install -r backend/requirements-dev.txt
```

#### 3. 前端环境

```bash
cd frontend
npm install
```

#### 4. 数据库设置

```bash
# 启动PostgreSQL和Redis
docker-compose -f docker-compose.dev.yml up -d db redis

# 运行数据库迁移
cd backend
alembic upgrade head
```

### 开发环境启动

#### 使用Docker Compose（推荐）

```bash
# 启动所有服务
docker-compose -f docker-compose.dev.yml up -d

# 查看日志
docker-compose -f docker-compose.dev.yml logs -f
```

#### 手动启动

```bash
# 启动后端
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 启动前端
cd frontend
npm run dev
```

## 📁 项目结构

```
ipv6-wireguard-manager/
├── backend/                    # 后端代码
│   ├── app/
│   │   ├── api/               # API路由
│   │   │   └── api_v1/
│   │   │       └── endpoints/ # API端点
│   │   ├── core/              # 核心配置
│   │   ├── models/            # 数据模型
│   │   ├── schemas/           # Pydantic模式
│   │   ├── services/          # 业务逻辑
│   │   └── main.py           # 应用入口
│   ├── tests/                 # 测试代码
│   ├── alembic/              # 数据库迁移
│   └── requirements.txt      # Python依赖
├── frontend/                  # 前端代码
│   ├── src/
│   │   ├── components/       # React组件
│   │   ├── hooks/           # 自定义Hook
│   │   ├── services/        # API服务
│   │   ├── types/           # TypeScript类型
│   │   └── utils/           # 工具函数
│   ├── public/              # 静态资源
│   └── package.json         # Node.js依赖
├── docker-compose.dev.yml    # 开发环境配置
├── docker-compose.production.yml # 生产环境配置
├── .github/workflows/        # CI/CD配置
└── docs/                    # 文档
```

## 📝 代码规范

### Python代码规范

#### 代码格式化

```bash
# 使用black格式化代码
black backend/

# 使用isort排序导入
isort backend/

# 使用flake8检查代码质量
flake8 backend/
```

#### 类型注解

```python
from typing import List, Dict, Optional, Union
from datetime import datetime

def get_user(user_id: str) -> Optional[Dict[str, Any]]:
    """获取用户信息"""
    pass

async def create_user(
    user_data: UserCreate,
    db: AsyncSession
) -> User:
    """创建用户"""
    pass
```

#### 文档字符串

```python
def calculate_metrics(data: List[Dict[str, Any]]) -> Dict[str, float]:
    """
    计算系统指标
    
    Args:
        data: 原始数据列表
        
    Returns:
        计算后的指标字典
        
    Raises:
        ValueError: 当数据格式不正确时
    """
    pass
```

### TypeScript代码规范

#### 代码格式化

```bash
# 使用Prettier格式化代码
npm run format

# 使用ESLint检查代码
npm run lint
```

#### 类型定义

```typescript
interface User {
  id: string;
  username: string;
  email: string;
  isActive: boolean;
  createdAt: Date;
}

interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
}
```

#### 组件规范

```typescript
import React, { useState, useEffect } from 'react';
import { Card, Button } from 'antd';

interface UserCardProps {
  user: User;
  onEdit: (user: User) => void;
  onDelete: (userId: string) => void;
}

const UserCard: React.FC<UserCardProps> = ({ user, onEdit, onDelete }) => {
  const [loading, setLoading] = useState(false);

  const handleEdit = () => {
    onEdit(user);
  };

  const handleDelete = async () => {
    setLoading(true);
    try {
      await onDelete(user.id);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card
      title={user.username}
      actions={[
        <Button key="edit" onClick={handleEdit}>编辑</Button>,
        <Button key="delete" danger loading={loading} onClick={handleDelete}>
          删除
        </Button>
      ]}
    >
      <p>邮箱: {user.email}</p>
      <p>状态: {user.isActive ? '活跃' : '禁用'}</p>
    </Card>
  );
};

export default UserCard;
```

## 🧪 测试指南

### 后端测试

#### 单元测试

```bash
# 运行所有测试
pytest backend/tests/

# 运行特定测试文件
pytest backend/tests/test_user_service.py

# 运行测试并生成覆盖率报告
pytest backend/tests/ --cov=app --cov-report=html
```

#### 测试示例

```python
import pytest
from unittest.mock import AsyncMock, patch
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.user_service import UserService
from app.schemas.user import UserCreate

@pytest.mark.asyncio
async def test_create_user():
    """测试创建用户"""
    # 模拟数据库会话
    mock_db = AsyncMock(spec=AsyncSession)
    
    # 创建服务实例
    user_service = UserService(mock_db)
    
    # 测试数据
    user_data = UserCreate(
        username="testuser",
        email="test@example.com",
        password="password123"
    )
    
    # 执行测试
    with patch.object(user_service, 'get_user_by_username', return_value=None):
        result = await user_service.create_user(user_data)
    
    # 验证结果
    assert result.username == "testuser"
    assert result.email == "test@example.com"
    mock_db.add.assert_called_once()
    mock_db.commit.assert_called_once()
```

#### 集成测试

```python
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_user_endpoints():
    """测试用户API端点"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # 测试创建用户
        response = await client.post("/api/v1/users/", json={
            "username": "testuser",
            "email": "test@example.com",
            "password": "password123"
        })
        assert response.status_code == 201
        
        # 测试获取用户
        response = await client.get("/api/v1/users/")
        assert response.status_code == 200
        assert len(response.json()) > 0
```

### 前端测试

#### 单元测试

```bash
# 运行所有测试
npm test

# 运行测试并生成覆盖率报告
npm run test:coverage
```

#### 测试示例

```typescript
import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import UserCard from '../UserCard';

const mockUser = {
  id: '1',
  username: 'testuser',
  email: 'test@example.com',
  isActive: true,
  createdAt: new Date()
};

const mockProps = {
  user: mockUser,
  onEdit: jest.fn(),
  onDelete: jest.fn()
};

describe('UserCard', () => {
  it('renders user information correctly', () => {
    render(
      <BrowserRouter>
        <UserCard {...mockProps} />
      </BrowserRouter>
    );
    
    expect(screen.getByText('testuser')).toBeInTheDocument();
    expect(screen.getByText('test@example.com')).toBeInTheDocument();
    expect(screen.getByText('活跃')).toBeInTheDocument();
  });

  it('calls onEdit when edit button is clicked', () => {
    render(
      <BrowserRouter>
        <UserCard {...mockProps} />
      </BrowserRouter>
    );
    
    fireEvent.click(screen.getByText('编辑'));
    expect(mockProps.onEdit).toHaveBeenCalledWith(mockUser);
  });
});
```

## 🚀 部署流程

### 开发环境部署

```bash
# 构建开发镜像
docker-compose -f docker-compose.dev.yml build

# 启动开发环境
docker-compose -f docker-compose.dev.yml up -d
```

### 生产环境部署

#### 使用Docker Compose部署
```bash
# 构建生产镜像
docker-compose -f docker-compose.production.yml build

# 启动生产环境
docker-compose -f docker-compose.production.yml up -d
```

#### 使用自动化部署脚本
```bash
# Linux/Mac系统
./deploy-production.sh

# Windows系统
./deploy-production.bat
```

#### 手动部署步骤
```bash
# 1. 检查依赖
python --version
node --version
docker --version

# 2. 创建环境文件
cp .env.example .env
# 编辑.env文件，配置数据库连接、Redis连接等

# 3. 启动数据库服务
docker-compose -f docker-compose.production.yml up -d db redis

# 4. 初始化数据库
cd backend
python -m app.core.init_db_sync

# 5. 启动应用服务
docker-compose -f docker-compose.production.yml up -d backend frontend nginx

# 6. 验证部署
curl http://localhost:8000/api/v1/status/health
```

### 性能优化部署

#### 数据库优化配置
```python
# 数据库连接池配置
DATABASE_POOL_SIZE = 20
DATABASE_MAX_OVERFLOW = 30
DATABASE_POOL_RECYCLE = 3600

# 查询优化配置
QUERY_TIMEOUT = 30
MAX_QUERY_RESULTS = 1000
```

#### 缓存优化配置
```python
# Redis缓存配置
REDIS_CACHE_TTL = 3600
REDIS_CACHE_PREFIX = "ipv6wg:"
REDIS_CONNECTION_POOL_SIZE = 20

# 内存缓存配置
MEMORY_CACHE_SIZE = 1000
MEMORY_CACHE_TTL = 300
```

#### 应用性能优化
```python
# 异步任务配置
ASYNC_WORKERS = 4
ASYNC_QUEUE_SIZE = 1000

# API性能配置
API_RATE_LIMIT = 1000  # 每分钟请求数
API_TIMEOUT = 30  # 请求超时时间
```

### 数据库迁移

```bash
# 生成迁移文件
alembic revision --autogenerate -m "描述"

# 执行迁移
alembic upgrade head

# 回滚迁移
alembic downgrade -1
```

### 健康检查配置

#### Kubernetes健康检查
```yaml
livenessProbe:
  httpGet:
    path: /api/v1/status/live
    port: 8000
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /api/v1/status/ready
    port: 8000
  initialDelaySeconds: 5
  periodSeconds: 5
```

#### 自定义健康检查
```python
# 健康检查配置
HEALTH_CHECK_TIMEOUT = 5
HEALTH_CHECK_RETRY_COUNT = 3
HEALTH_CHECK_INTERVAL = 30
```

## 🤝 贡献流程

### 1. Fork项目

在GitHub上Fork项目到你的账户。

### 2. 创建分支

```bash
git checkout -b feature/your-feature-name
```

### 3. 提交代码

```bash
# 添加修改
git add .

# 提交代码
git commit -m "feat: add new feature"

# 推送分支
git push origin feature/your-feature-name
```

### 4. 创建Pull Request

在GitHub上创建Pull Request，详细描述你的修改。

### 5. 代码审查

等待维护者审查代码，根据反馈进行修改。

### 6. 合并代码

审查通过后，代码将被合并到主分支。

## 📋 提交规范

### 提交消息格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 类型说明

- `feat`: 新功能
- `fix`: 修复bug
- `docs`: 文档更新
- `style`: 代码格式修改
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

### 示例

```
feat(auth): add JWT token refresh functionality

- Add refresh token endpoint
- Implement token validation
- Update authentication middleware

Closes #123
```

## 🔍 调试指南

### 后端调试

```bash
# 启用调试模式
export DEBUG=true
export LOG_LEVEL=DEBUG

# 启动应用
uvicorn app.main:app --reload --log-level debug
```

### 前端调试

```bash
# 启动开发服务器
npm run dev

# 使用React DevTools
# 安装浏览器扩展进行调试
```

### 数据库调试

```bash
# 连接数据库
psql -h localhost -U postgres -d ipv6_wireguard_manager

# 查看表结构
\dt

# 查看数据
SELECT * FROM users LIMIT 10;
```

## 📚 相关资源

- [FastAPI文档](https://fastapi.tiangolo.com/)
- [React文档](https://reactjs.org/docs/)
- [Ant Design文档](https://ant.design/)
- [PostgreSQL文档](https://www.postgresql.org/docs/)
- [Docker文档](https://docs.docker.com/)

## ❓ 常见问题

### Q: 如何添加新的API端点？

A: 在`backend/app/api/api_v1/endpoints/`目录下创建新的端点文件，然后在`api.py`中注册路由。

### Q: 如何添加新的前端页面？

A: 在`frontend/src/components/`目录下创建新的组件，然后在路由配置中添加路径。

### Q: 如何运行数据库迁移？

A: 使用`alembic upgrade head`命令执行数据库迁移。

### Q: 如何调试WebSocket连接？

A: 检查浏览器开发者工具的Network标签页，查看WebSocket连接状态。

---

如有其他问题，请查看项目文档或提交Issue。
