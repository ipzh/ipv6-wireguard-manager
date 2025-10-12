# BGP高级功能实现指南

## 🎯 功能概述

本指南详细介绍了IPv6 WireGuard Manager中新增的BGP高级功能，包括：

- **ExaBGP服务管理**: 支持systemctl和supervisorctl的重载/重启操作
- **IPv6前缀池管理**: 智能地址分配和"分配即宣告"功能
- **BGP会话管理**: 完整的会话生命周期管理
- **前缀白名单**: 安全的前缀访问控制
- **RPKI预检**: 路由来源验证
- **实时监控**: WebSocket状态订阅和告警系统

## 🏗️ 架构设计

### 后端架构

```
backend/
├── app/
│   ├── models/
│   │   ├── bgp.py              # BGP会话和操作模型
│   │   └── ipv6_pool.py        # IPv6前缀池模型
│   ├── services/
│   │   └── bgp_service.py      # BGP服务管理核心
│   └── api/api_v1/endpoints/
│       ├── bgp_sessions.py     # BGP会话API
│       └── ipv6_pools.py       # IPv6前缀池API
```

### 前端架构

```
frontend/src/
├── pages/
│   ├── BGPSessionsPage.tsx     # BGP会话管理页面
│   └── IPv6PoolsPage.tsx       # IPv6前缀池管理页面
└── components/layout/
    └── Sidebar.tsx             # 更新导航菜单
```

## 🚀 快速开始

### 1. 环境准备

确保您的系统已安装以下组件：

```bash
# 安装ExaBGP
pip install exabgp

# 安装PostgreSQL和Redis
sudo apt-get install postgresql redis-server

# 安装Node.js和npm
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 2. 启动本地开发环境

```bash
# 克隆项目
git clone <repository-url>
cd ipv6-wireguard-manager

# 设置环境配置
chmod +x setup-env.sh
./setup-env.sh

# 启动本地开发环境
chmod +x start-local.sh
./start-local.sh
```

### 3. 访问应用

- **前端**: http://localhost:5173
- **后端API**: http://127.0.0.1:8000
- **API文档**: http://127.0.0.1:8000/docs

## 📋 功能详解

### BGP会话管理

#### 核心功能

1. **会话配置管理**
   - 创建/编辑/删除BGP会话
   - 支持IPv4和IPv6邻居
   - 配置保持时间、密码等参数

2. **服务操作**
   - 重载ExaBGP配置 (`systemctl reload exabgp`)
   - 重启ExaBGP服务 (`supervisorctl restart exabgp`)
   - 批量操作支持

3. **状态监控**
   - 实时会话状态显示
   - 运行时间统计
   - 前缀收发统计

4. **操作审计**
   - 完整的操作历史记录
   - 失败回滚机制
   - 详细错误日志

#### API端点

```bash
# 获取BGP会话列表
GET /api/v1/bgp/sessions

# 创建BGP会话
POST /api/v1/bgp/sessions
{
  "name": "peer-1",
  "neighbor": "192.168.1.2",
  "remote_as": 65002,
  "hold_time": 180,
  "password": "optional-password",
  "description": "主要对等体",
  "enabled": true
}

# 重载会话配置
POST /api/v1/bgp/sessions/{session_id}/reload

# 重启会话
POST /api/v1/bgp/sessions/{session_id}/restart

# 批量重载
POST /api/v1/bgp/sessions/batch/reload
["session_id_1", "session_id_2"]

# 获取操作历史
GET /api/v1/bgp/sessions/{session_id}/operations
```

### IPv6前缀池管理

#### 核心功能

1. **前缀池配置**
   - 创建IPv6前缀池
   - 设置总容量和分配长度
   - 配置自动宣告功能

2. **智能地址分配**
   - 自动计算可用前缀
   - 与WireGuard客户端联动
   - 支持"分配即宣告"

3. **安全控制**
   - 前缀白名单管理
   - 最大前缀限制
   - RPKI预检验证

4. **监控告警**
   - 容量使用监控
   - 异常告警系统
   - 操作审计日志

#### API端点

```bash
# 获取前缀池列表
GET /api/v1/ipv6/pools

# 创建前缀池
POST /api/v1/ipv6/pools
{
  "name": "pool-1",
  "prefix": "2001:db8::/48",
  "prefix_length": 64,
  "total_capacity": 1000,
  "auto_announce": true,
  "whitelist_enabled": true,
  "rpki_enabled": true
}

# 分配IPv6前缀
POST /api/v1/ipv6/pools/{pool_id}/allocate
{
  "client_id": "client-uuid",
  "auto_announce": true
}

# 释放前缀
POST /api/v1/ipv6/pools/{pool_id}/release/{allocation_id}

# 添加白名单
POST /api/v1/ipv6/pools/{pool_id}/whitelist
{
  "prefix": "2001:db8::/64",
  "description": "允许的前缀"
}

# RPKI验证
POST /api/v1/ipv6/pools/{pool_id}/validate-rpki
{
  "prefix": "2001:db8::/64"
}
```

## 🔧 配置示例

### ExaBGP配置生成

系统会自动生成ExaBGP配置文件：

```ini
group exabgp {
    router-id 192.168.1.1;
    
    process announce-routes {
        run /usr/bin/python3 /etc/exabgp/announce-routes.py;
        encoder json;
    }
    
    neighbor 192.168.1.2 {
        router-id 192.168.1.1;
        local-address 192.168.1.1;
        local-as 65001;
        peer-as 65002;
        
        capability {
            graceful-restart 120;
        }
        
        family {
            ipv4 unicast;
            ipv6 unicast;
        }
    }
}
```

### 前缀池配置示例

```json
{
  "name": "production-pool",
  "prefix": "2001:db8::/48",
  "prefix_length": 64,
  "total_capacity": 10000,
  "auto_announce": true,
  "max_prefix_limit": 100,
  "whitelist_enabled": true,
  "rpki_enabled": true,
  "description": "生产环境IPv6前缀池"
}
```

## 🔄 WebSocket实时通信

### 状态订阅

前端通过WebSocket订阅BGP会话和前缀池的实时状态：

```javascript
// 连接WebSocket
const ws = new WebSocket('ws://localhost:8000/api/v1/ws/user-id?connection_type=bgp_status')

// 订阅BGP会话状态
ws.send(JSON.stringify({
  type: 'subscribe',
  channel: 'bgp_sessions',
  session_id: 'session-uuid'
}))

// 订阅前缀池状态
ws.send(JSON.stringify({
  type: 'subscribe',
  channel: 'ipv6_pools',
  pool_id: 'pool-uuid'
}))
```

### 消息格式

```json
{
  "type": "bgp_status_update",
  "session_id": "session-uuid",
  "status": "established",
  "uptime": 3600,
  "prefixes_received": 100,
  "prefixes_sent": 50,
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## 🛡️ 安全特性

### 1. 前缀白名单

```bash
# 添加白名单条目
POST /api/v1/ipv6/pools/{pool_id}/whitelist
{
  "prefix": "2001:db8:1::/64",
  "description": "允许的客户端前缀",
  "enabled": true
}
```

### 2. RPKI预检

```bash
# 验证前缀的RPKI状态
POST /api/v1/ipv6/pools/{pool_id}/validate-rpki
{
  "prefix": "2001:db8::/64"
}

# 响应
{
  "prefix": "2001:db8::/64",
  "valid": true,
  "reason": "Valid",
  "asn": 65001,
  "max_length": 48
}
```

### 3. 操作审计

所有BGP操作都会记录详细的审计日志：

```json
{
  "id": "operation-uuid",
  "session_id": "session-uuid",
  "operation_type": "reload",
  "status": "SUCCESS",
  "message": "ExaBGP配置重载成功",
  "started_at": "2024-01-01T12:00:00Z",
  "completed_at": "2024-01-01T12:00:05Z"
}
```

## 🚨 告警系统

### 告警类型

1. **RPKI_INVALID**: RPKI验证失败
2. **PREFIX_LIMIT**: 前缀数量超限
3. **SESSION_DOWN**: BGP会话断开
4. **POOL_DEPLETED**: 前缀池耗尽
5. **CONFIG_ERROR**: 配置错误

### 告警严重程度

- **INFO**: 信息性告警
- **WARNING**: 警告级别
- **ERROR**: 错误级别
- **CRITICAL**: 严重级别

### 创建告警

```bash
POST /api/v1/ipv6/pools/{pool_id}/alerts
{
  "alert_type": "PREFIX_LIMIT",
  "severity": "WARNING",
  "message": "前缀池使用率超过90%",
  "prefix": "2001:db8::/48"
}
```

## 🔍 故障排除

### 常见问题

1. **ExaBGP服务无法启动**
   ```bash
   # 检查配置文件语法
   exabgp --test /etc/exabgp/exabgp.conf
   
   # 查看服务日志
   journalctl -u exabgp -f
   ```

2. **BGP会话无法建立**
   ```bash
   # 检查网络连通性
   ping <neighbor-ip>
   
   # 检查防火墙设置
   ufw status
   ```

3. **前缀分配失败**
   ```bash
   # 检查前缀池状态
   curl http://localhost:8000/api/v1/ipv6/pools/{pool_id}
   
   # 检查白名单配置
   curl http://localhost:8000/api/v1/ipv6/pools/{pool_id}/whitelist
   ```

### 调试模式

启用调试模式获取详细日志：

```bash
# 设置环境变量
export DEBUG=true
export LOG_LEVEL=DEBUG

# 重启服务
systemctl restart ipv6-wireguard-manager
```

## 📊 性能优化

### 1. 数据库优化

```sql
-- 创建索引
CREATE INDEX idx_bgp_sessions_neighbor ON bgp_sessions(neighbor);
CREATE INDEX idx_ipv6_allocations_pool_id ON ipv6_allocations(pool_id);
CREATE INDEX idx_bgp_operations_session_id ON bgp_operations(session_id);
```

### 2. 缓存策略

```python
# Redis缓存配置
REDIS_CACHE_TTL = {
    'bgp_status': 30,      # BGP状态缓存30秒
    'pool_usage': 60,      # 前缀池使用情况缓存60秒
    'whitelist': 300,      # 白名单缓存5分钟
}
```

### 3. 连接池配置

```python
# 数据库连接池
DATABASE_POOL_SIZE = 20
DATABASE_MAX_OVERFLOW = 30

# Redis连接池
REDIS_POOL_SIZE = 10
```

## 🧪 测试指南

### 单元测试

```bash
# 运行BGP服务测试
python -m pytest tests/test_bgp_service.py -v

# 运行前缀池测试
python -m pytest tests/test_ipv6_pools.py -v
```

### 集成测试

```bash
# 运行完整集成测试
python -m pytest tests/integration/ -v

# 测试ExaBGP集成
python -m pytest tests/integration/test_exabgp_integration.py -v
```

### 前端测试

```bash
# 运行前端测试
cd frontend
npm test

# 运行E2E测试
npm run test:e2e
```

## 📈 监控指标

### 关键指标

1. **BGP会话指标**
   - 会话建立成功率
   - 平均运行时间
   - 前缀收发速率

2. **前缀池指标**
   - 分配成功率
   - 平均分配时间
   - 池使用率

3. **系统指标**
   - API响应时间
   - 数据库连接数
   - 内存使用率

### 监控配置

```yaml
# Prometheus配置示例
scrape_configs:
  - job_name: 'ipv6-wireguard-manager'
    static_configs:
      - targets: ['localhost:9090']
    metrics_path: '/metrics'
    scrape_interval: 30s
```

## 🔄 部署指南

### 生产环境部署

1. **系统要求**
   - Ubuntu 20.04+ / CentOS 8+
   - 4GB+ RAM
   - 50GB+ 存储空间
   - 稳定的网络连接

2. **安装步骤**
   ```bash
   # 使用一键安装脚本
   curl -fsSL https://your-domain.com/install.sh | bash
   
   # 或手动安装
   git clone <repository-url>
   cd ipv6-wireguard-manager
   ./install-robust.sh
   ```

3. **配置优化**
   ```bash
   # 优化系统参数
   echo 'net.core.rmem_max = 134217728' >> /etc/sysctl.conf
   echo 'net.core.wmem_max = 134217728' >> /etc/sysctl.conf
   sysctl -p
   ```

### Docker部署

```yaml
# docker-compose.yml
version: '3.8'
services:
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/ipv6wgm
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
  
  frontend:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - backend
  
  db:
    image: postgres:13
    environment:
      - POSTGRES_DB=ipv6wgm
      - POSTGRES_USER=ipv6wgm
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  redis:
    image: redis:6-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

## 📚 API文档

完整的API文档可通过以下方式访问：

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

## 🤝 贡献指南

### 开发流程

1. Fork项目仓库
2. 创建功能分支
3. 提交代码变更
4. 创建Pull Request
5. 代码审查和合并

### 代码规范

- 后端使用Python 3.8+和FastAPI
- 前端使用React 18+和TypeScript
- 遵循PEP 8和ESLint规范
- 编写完整的单元测试

## 📞 支持与反馈

如果您在使用过程中遇到问题或有改进建议，请：

1. 查看本文档的故障排除部分
2. 搜索已有的Issues
3. 创建新的Issue描述问题
4. 联系开发团队

---

**注意**: 本功能仍在积极开发中，某些高级特性可能需要额外的系统配置。建议在生产环境使用前进行充分测试。
