# IPv6 WireGuard Manager - 技术架构设计文档

## 📋 架构概述

### 设计原则
- **微服务架构**: 服务拆分，独立部署，松耦合
- **云原生**: 容器化，Kubernetes编排，服务网格
- **高可用**: 多实例部署，负载均衡，故障转移
- **可扩展**: 水平扩展，弹性伸缩，性能优化
- **安全性**: 零信任架构，端到端加密，安全审计

### 技术选型理由

#### 后端技术栈
| 技术 | 版本 | 选择理由 |
|------|------|----------|
| **FastAPI** | 0.104+ | 高性能异步框架，自动API文档，类型提示 |
| **PostgreSQL** | 15+ | 成熟的关系数据库，JSON支持，高并发 |
| **Redis** | 7+ | 高性能缓存，会话存储，消息队列 |
| **SQLAlchemy** | 2.0+ | 成熟ORM，异步支持，迁移工具 |
| **Celery** | 5.3+ | 分布式任务队列，异步处理 |
| **Pydantic** | 2.4+ | 数据验证，序列化，类型安全 |

#### 前端技术栈
| 技术 | 版本 | 选择理由 |
|------|------|----------|
| **React** | 18+ | 成熟框架，生态丰富，性能优秀 |
| **TypeScript** | 5.0+ | 类型安全，开发效率，代码质量 |
| **Vite** | 5.0+ | 快速构建，热更新，现代化工具链 |
| **Ant Design** | 5.0+ | 企业级UI组件库，设计规范 |
| **Redux Toolkit** | 1.9+ | 状态管理，数据流控制 |
| **React Query** | 5.0+ | 服务端状态管理，缓存优化 |

---

## 🏗️ 系统架构

### 整体架构图
```
┌─────────────────────────────────────────────────────────────────┐
│                        IPv6 WireGuard Manager v3.0              │
│                        现代化微服务架构                          │
└─────────────────────┬───────────────────────────────────────────┘
                      │
    ┌─────────────────┼─────────────────┐
    │                 │                 │
┌───▼────┐      ┌────▼────┐      ┌─────▼─────┐
│ 前端层  │      │ 网关层   │      │  服务层    │
│Frontend│      │Gateway  │      │ Services  │
└───┬────┘      └────┬────┘      └─────┬─────┘
    │                │                 │
    │                │                 │
┌───▼────┐      ┌────▼────┐      ┌─────▼─────┐
│React   │      │Kong/    │      │FastAPI    │
│+TS     │      │Nginx    │      │Services   │
└────────┘      └─────────┘      └─────┬─────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
            ┌───────▼──────┐   ┌───────▼──────┐   ┌───────▼──────┐
            │   数据层      │   │   缓存层      │   │   消息层      │
            │ PostgreSQL   │   │   Redis      │   │  RabbitMQ    │
            └──────────────┘   └──────────────┘   └──────────────┘
```

### 微服务架构设计

#### 1. API网关服务 (Gateway Service)
**职责**: 统一入口，路由分发，认证授权，限流熔断

```yaml
# API网关配置
services:
  api-gateway:
    image: kong:3.4
    ports:
      - "8000:8000"    # HTTP API
      - "8443:8443"    # HTTPS API
      - "8001:8001"    # Admin API
    environment:
      - KONG_DATABASE=postgres
      - KONG_PG_HOST=postgres
      - KONG_PG_DATABASE=kong
    plugins:
      - jwt
      - rate-limiting
      - cors
      - request-transformer
```

**功能特性**:
- [ ] **路由管理**: 动态路由配置
- [ ] **负载均衡**: 多实例负载均衡
- [ ] **认证授权**: JWT令牌验证
- [ ] **限流熔断**: 请求限流和熔断保护
- [ ] **监控日志**: 请求监控和日志记录
- [ ] **SSL终止**: HTTPS证书管理

#### 2. 用户认证服务 (Auth Service)
**职责**: 用户管理，认证授权，权限控制

```python
# 认证服务架构
class AuthService:
    def __init__(self):
        self.user_repo = UserRepository()
        self.role_repo = RoleRepository()
        self.permission_repo = PermissionRepository()
        self.jwt_handler = JWTHandler()
    
    async def authenticate(self, username: str, password: str) -> AuthResult:
        """用户认证"""
        user = await self.user_repo.get_by_username(username)
        if not user or not self.verify_password(password, user.password_hash):
            raise AuthenticationError("Invalid credentials")
        
        token = self.jwt_handler.create_token(user)
        return AuthResult(token=token, user=user)
    
    async def authorize(self, user: User, resource: str, action: str) -> bool:
        """权限验证"""
        permissions = await self.get_user_permissions(user.id)
        return self.check_permission(permissions, resource, action)
```

**功能特性**:
- [ ] **用户管理**: 用户CRUD操作
- [ ] **角色管理**: 角色和权限管理
- [ ] **JWT认证**: 无状态认证
- [ ] **多因素认证**: MFA支持
- [ ] **会话管理**: 会话状态管理
- [ ] **权限验证**: 细粒度权限控制

#### 3. WireGuard管理服务 (WireGuard Service)
**职责**: WireGuard服务器和客户端管理

```python
# WireGuard服务架构
class WireGuardService:
    def __init__(self):
        self.server_repo = ServerRepository()
        self.client_repo = ClientRepository()
        self.config_manager = ConfigManager()
        self.key_manager = KeyManager()
    
    async def create_server(self, server_data: ServerCreate) -> Server:
        """创建WireGuard服务器"""
        # 生成密钥对
        private_key, public_key = self.key_manager.generate_keypair()
        
        # 创建服务器记录
        server = Server(
            name=server_data.name,
            interface=server_data.interface,
            listen_port=server_data.listen_port,
            private_key=private_key,
            public_key=public_key,
            ipv4_address=server_data.ipv4_address,
            ipv6_address=server_data.ipv6_address
        )
        
        # 保存到数据库
        await self.server_repo.create(server)
        
        # 生成配置文件
        await self.config_manager.generate_server_config(server)
        
        return server
    
    async def create_client(self, client_data: ClientCreate) -> Client:
        """创建WireGuard客户端"""
        # 生成客户端密钥对
        private_key, public_key = self.key_manager.generate_keypair()
        
        # 分配IP地址
        ipv4_address = await self.allocate_ipv4_address()
        ipv6_address = await self.allocate_ipv6_address()
        
        # 创建客户端记录
        client = Client(
            name=client_data.name,
            private_key=private_key,
            public_key=public_key,
            ipv4_address=ipv4_address,
            ipv6_address=ipv6_address
        )
        
        # 保存到数据库
        await self.client_repo.create(client)
        
        # 生成客户端配置
        config = await self.config_manager.generate_client_config(client)
        
        return client
```

**功能特性**:
- [ ] **服务器管理**: 服务器配置和管理
- [ ] **客户端管理**: 客户端配置和管理
- [ ] **密钥管理**: 密钥生成和管理
- [ ] **配置生成**: 配置文件生成
- [ ] **服务控制**: 服务启停控制
- [ ] **状态监控**: 连接状态监控

#### 4. 网络管理服务 (Network Service)
**职责**: 网络接口，路由，防火墙管理

```python
# 网络服务架构
class NetworkService:
    def __init__(self):
        self.interface_manager = InterfaceManager()
        self.route_manager = RouteManager()
        self.firewall_manager = FirewallManager()
        self.ip_manager = IPManager()
    
    async def get_interfaces(self) -> List[NetworkInterface]:
        """获取网络接口列表"""
        interfaces = await self.interface_manager.list_interfaces()
        return [NetworkInterface.from_system(iface) for iface in interfaces]
    
    async def configure_interface(self, interface_id: str, config: InterfaceConfig) -> bool:
        """配置网络接口"""
        interface = await self.interface_manager.get_interface(interface_id)
        if not interface:
            raise InterfaceNotFoundError(f"Interface {interface_id} not found")
        
        # 应用配置
        await self.interface_manager.configure(interface, config)
        
        # 更新数据库
        await self.interface_repo.update(interface_id, config)
        
        return True
    
    async def manage_firewall_rules(self, rules: List[FirewallRule]) -> bool:
        """管理防火墙规则"""
        # 验证规则
        for rule in rules:
            if not self.firewall_manager.validate_rule(rule):
                raise InvalidFirewallRuleError(f"Invalid rule: {rule}")
        
        # 应用规则
        await self.firewall_manager.apply_rules(rules)
        
        # 保存到数据库
        await self.firewall_repo.save_rules(rules)
        
        return True
```

**功能特性**:
- [ ] **接口管理**: 网络接口配置
- [ ] **路由管理**: 路由表管理
- [ ] **防火墙管理**: 防火墙规则管理
- [ ] **IP管理**: IP地址分配管理
- [ ] **网络监控**: 网络状态监控
- [ ] **配置验证**: 网络配置验证

#### 5. 监控服务 (Monitoring Service)
**职责**: 系统监控，指标收集，告警管理

```python
# 监控服务架构
class MonitoringService:
    def __init__(self):
        self.metrics_collector = MetricsCollector()
        self.alert_manager = AlertManager()
        self.prometheus_client = PrometheusClient()
    
    async def collect_system_metrics(self) -> SystemMetrics:
        """收集系统指标"""
        metrics = await self.metrics_collector.collect()
        
        # 发送到Prometheus
        await self.prometheus_client.push_metrics(metrics)
        
        return SystemMetrics(
            cpu_usage=metrics.cpu_usage,
            memory_usage=metrics.memory_usage,
            disk_usage=metrics.disk_usage,
            network_stats=metrics.network_stats,
            timestamp=datetime.utcnow()
        )
    
    async def check_alerts(self, metrics: SystemMetrics) -> List[Alert]:
        """检查告警条件"""
        alerts = []
        
        # CPU使用率告警
        if metrics.cpu_usage > 80:
            alerts.append(Alert(
                type="cpu_high",
                severity="warning",
                message=f"CPU usage is {metrics.cpu_usage}%",
                timestamp=datetime.utcnow()
            ))
        
        # 内存使用率告警
        if metrics.memory_usage > 90:
            alerts.append(Alert(
                type="memory_high",
                severity="critical",
                message=f"Memory usage is {metrics.memory_usage}%",
                timestamp=datetime.utcnow()
            ))
        
        # 发送告警
        for alert in alerts:
            await self.alert_manager.send_alert(alert)
        
        return alerts
```

**功能特性**:
- [ ] **指标收集**: 系统性能指标收集
- [ ] **实时监控**: 实时监控数据
- [ ] **告警管理**: 告警规则和通知
- [ ] **历史数据**: 历史数据存储和查询
- [ ] **图表展示**: 监控数据可视化
- [ ] **自定义指标**: 自定义监控指标

#### 6. 日志服务 (Logging Service)
**职责**: 日志收集，存储，查询，分析

```python
# 日志服务架构
class LoggingService:
    def __init__(self):
        self.log_collector = LogCollector()
        self.log_processor = LogProcessor()
        self.log_storage = LogStorage()
        self.log_search = LogSearch()
    
    async def collect_logs(self, source: str) -> List[LogEntry]:
        """收集日志"""
        raw_logs = await self.log_collector.collect_from_source(source)
        processed_logs = []
        
        for raw_log in raw_logs:
            processed_log = await self.log_processor.process(raw_log)
            processed_logs.append(processed_log)
        
        # 存储日志
        await self.log_storage.store_logs(processed_logs)
        
        return processed_logs
    
    async def search_logs(self, query: LogQuery) -> List[LogEntry]:
        """搜索日志"""
        return await self.log_search.search(query)
    
    async def get_audit_logs(self, user_id: str, start_time: datetime, end_time: datetime) -> List[AuditLog]:
        """获取审计日志"""
        return await self.log_search.get_audit_logs(user_id, start_time, end_time)
```

**功能特性**:
- [ ] **日志收集**: 多源日志收集
- [ ] **日志处理**: 日志解析和结构化
- [ ] **日志存储**: 高效日志存储
- [ ] **日志搜索**: 全文搜索和过滤
- [ ] **审计日志**: 操作审计日志
- [ ] **日志分析**: 日志分析和统计

#### 7. 配置管理服务 (Config Service)
**职责**: 配置管理，版本控制，热重载

```python
# 配置服务架构
class ConfigService:
    def __init__(self):
        self.config_repo = ConfigRepository()
        self.version_manager = VersionManager()
        self.hot_reloader = HotReloader()
    
    async def save_config(self, config: Config) -> ConfigVersion:
        """保存配置"""
        # 验证配置
        if not self.validate_config(config):
            raise InvalidConfigError("Configuration validation failed")
        
        # 创建版本
        version = await self.version_manager.create_version(config)
        
        # 保存到数据库
        await self.config_repo.save(config, version)
        
        # 热重载配置
        await self.hot_reloader.reload_config(config)
        
        return version
    
    async def get_config_history(self, config_name: str) -> List[ConfigVersion]:
        """获取配置历史"""
        return await self.config_repo.get_history(config_name)
    
    async def rollback_config(self, config_name: str, version: int) -> bool:
        """回滚配置"""
        config = await self.config_repo.get_by_version(config_name, version)
        if not config:
            raise ConfigNotFoundError(f"Config {config_name} version {version} not found")
        
        # 应用配置
        await self.hot_reloader.reload_config(config)
        
        # 更新当前版本
        await self.config_repo.set_current_version(config_name, version)
        
        return True
```

**功能特性**:
- [ ] **配置管理**: 配置文件管理
- [ ] **版本控制**: 配置版本管理
- [ ] **热重载**: 配置热重载
- [ ] **配置验证**: 配置语法验证
- [ ] **配置备份**: 配置备份恢复
- [ ] **配置模板**: 配置模板管理

---

## 🗄️ 数据架构

### 数据库设计

#### 1. 主数据库 (PostgreSQL)
**用途**: 存储业务数据，用户数据，配置数据

```sql
-- 数据库架构
CREATE DATABASE ipv6wgm_main;

-- 用户和权限相关表
CREATE SCHEMA auth;
CREATE SCHEMA wireguard;
CREATE SCHEMA network;
CREATE SCHEMA monitoring;
CREATE SCHEMA audit;
```

**表结构设计**:
```sql
-- 用户表
CREATE TABLE auth.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    is_superuser BOOLEAN DEFAULT false,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 角色表
CREATE TABLE auth.roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- WireGuard服务器表
CREATE TABLE wireguard.servers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    interface VARCHAR(20) DEFAULT 'wg0',
    listen_port INTEGER NOT NULL,
    private_key TEXT NOT NULL,
    public_key TEXT NOT NULL,
    ipv4_address INET,
    ipv6_address INET6,
    dns_servers INET[],
    mtu INTEGER DEFAULT 1420,
    config_file_path TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- WireGuard客户端表
CREATE TABLE wireguard.clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    private_key TEXT NOT NULL,
    public_key TEXT NOT NULL,
    ipv4_address INET,
    ipv6_address INET6,
    allowed_ips INET[],
    persistent_keepalive INTEGER DEFAULT 25,
    qr_code TEXT,
    config_file_path TEXT,
    is_active BOOLEAN DEFAULT true,
    last_seen TIMESTAMP,
    bytes_received BIGINT DEFAULT 0,
    bytes_sent BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 2. 缓存数据库 (Redis)
**用途**: 缓存，会话存储，消息队列

```yaml
# Redis配置
redis:
  master:
    host: redis-master
    port: 6379
    db: 0
  slave:
    host: redis-slave
    port: 6379
    db: 0
  cluster:
    nodes:
      - redis-node-1:6379
      - redis-node-2:6379
      - redis-node-3:6379
```

**数据结构设计**:
```python
# Redis数据结构
class RedisDataStructures:
    # 用户会话
    USER_SESSION = "session:{user_id}"
    
    # 系统缓存
    SYSTEM_CACHE = "cache:system:{key}"
    
    # 实时数据
    REALTIME_METRICS = "metrics:realtime"
    
    # 任务队列
    TASK_QUEUE = "queue:tasks"
    
    # 分布式锁
    DISTRIBUTED_LOCK = "lock:{resource}"
    
    # 限流计数器
    RATE_LIMIT = "rate_limit:{user_id}:{endpoint}"
```

#### 3. 时序数据库 (InfluxDB)
**用途**: 监控数据，性能指标，日志数据

```sql
-- InfluxDB数据库
CREATE DATABASE monitoring;
CREATE DATABASE logs;

-- 系统指标表
CREATE MEASUREMENT system_metrics (
    time TIMESTAMP,
    cpu_usage FLOAT,
    memory_usage FLOAT,
    disk_usage FLOAT,
    network_rx INTEGER,
    network_tx INTEGER,
    host TAG,
    service TAG
);

-- WireGuard指标表
CREATE MEASUREMENT wireguard_metrics (
    time TIMESTAMP,
    client_id TAG,
    bytes_received INTEGER,
    bytes_sent INTEGER,
    last_handshake TIMESTAMP,
    endpoint TEXT
);
```

### 数据流架构

#### 1. 数据写入流程
```
用户操作 → API网关 → 业务服务 → 数据库
                ↓
            消息队列 → 异步处理 → 缓存更新
```

#### 2. 数据读取流程
```
用户请求 → API网关 → 缓存检查 → 数据库查询
                ↓
            缓存更新 ← 数据返回
```

#### 3. 数据同步流程
```
主数据库 → 变更日志 → 消息队列 → 缓存更新
                ↓
            从数据库同步
```

---

## 🔄 服务通信

### 1. 同步通信 (HTTP/gRPC)
**用途**: 服务间直接调用，实时数据交换

```python
# HTTP客户端示例
class ServiceClient:
    def __init__(self, base_url: str):
        self.client = httpx.AsyncClient(base_url=base_url)
    
    async def call_service(self, endpoint: str, data: dict) -> dict:
        response = await self.client.post(endpoint, json=data)
        return response.json()

# gRPC客户端示例
class GRPCClient:
    def __init__(self, service_url: str):
        self.channel = grpc.aio.insecure_channel(service_url)
        self.stub = ServiceStub(self.channel)
    
    async def call_method(self, request: Request) -> Response:
        return await self.stub.method(request)
```

### 2. 异步通信 (消息队列)
**用途**: 异步任务处理，事件驱动架构

```python
# 消息队列配置
class MessageQueue:
    def __init__(self):
        self.redis_client = redis.Redis()
        self.celery_app = Celery('ipv6wgm')
    
    async def publish_event(self, event: Event):
        """发布事件"""
        await self.redis_client.publish('events', event.json())
    
    async def subscribe_events(self, callback: Callable):
        """订阅事件"""
        pubsub = self.redis_client.pubsub()
        await pubsub.subscribe('events')
        
        async for message in pubsub.listen():
            if message['type'] == 'message':
                event = Event.parse_raw(message['data'])
                await callback(event)
```

### 3. 服务发现
**用途**: 动态服务发现，负载均衡

```yaml
# Consul配置
consul:
  host: consul-server
  port: 8500
  services:
    - name: auth-service
      port: 8001
      health_check: /health
    - name: wireguard-service
      port: 8002
      health_check: /health
    - name: network-service
      port: 8003
      health_check: /health
```

---

## 🚀 部署架构

### 1. 容器化部署

#### Docker配置
```dockerfile
# 多阶段构建
FROM python:3.11-slim AS base

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装Python依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . /app
WORKDIR /app

# 创建非root用户
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# 暴露端口
EXPOSE 8000

# 启动命令
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

#### Docker Compose配置
```yaml
version: '3.8'

services:
  # 数据库服务
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: ipv6wgm
      POSTGRES_USER: ipv6wgm
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  # Redis服务
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"

  # API网关
  api-gateway:
    image: kong:3.4
    environment:
      KONG_DATABASE: postgres
      KONG_PG_HOST: postgres
      KONG_PG_DATABASE: kong
    ports:
      - "8000:8000"
      - "8443:8443"
    depends_on:
      - postgres

  # 认证服务
  auth-service:
    build: ./services/auth
    environment:
      DATABASE_URL: postgresql://ipv6wgm:${DB_PASSWORD}@postgres:5432/ipv6wgm
      REDIS_URL: redis://redis:6379/0
    depends_on:
      - postgres
      - redis

  # WireGuard服务
  wireguard-service:
    build: ./services/wireguard
    environment:
      DATABASE_URL: postgresql://ipv6wgm:${DB_PASSWORD}@postgres:5432/ipv6wgm
      REDIS_URL: redis://redis:6379/0
    depends_on:
      - postgres
      - redis

  # 前端服务
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      REACT_APP_API_URL: http://localhost:8000

volumes:
  postgres_data:
  redis_data:
```

### 2. Kubernetes部署

#### 命名空间配置
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ipv6wgm
```

#### 配置映射
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ipv6wgm-config
  namespace: ipv6wgm
data:
  database_url: "postgresql://ipv6wgm:password@postgres:5432/ipv6wgm"
  redis_url: "redis://redis:6379/0"
  jwt_secret: "your-jwt-secret"
```

#### 部署配置
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
  namespace: ipv6wgm
spec:
  replicas: 3
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
    spec:
      containers:
      - name: auth-service
        image: ipv6wgm/auth-service:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            configMapKeyRef:
              name: ipv6wgm-config
              key: database_url
        - name: REDIS_URL
          valueFrom:
            configMapKeyRef:
              name: ipv6wgm-config
              key: redis_url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
```

#### 服务配置
```yaml
apiVersion: v1
kind: Service
metadata:
  name: auth-service
  namespace: ipv6wgm
spec:
  selector:
    app: auth-service
  ports:
  - port: 8000
    targetPort: 8000
  type: ClusterIP
```

#### 入口配置
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ipv6wgm-ingress
  namespace: ipv6wgm
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - api.ipv6wgm.com
    secretName: ipv6wgm-tls
  rules:
  - host: api.ipv6wgm.com
    http:
      paths:
      - path: /api/v1/auth
        pathType: Prefix
        backend:
          service:
            name: auth-service
            port:
              number: 8000
      - path: /api/v1/wireguard
        pathType: Prefix
        backend:
          service:
            name: wireguard-service
            port:
              number: 8000
```

### 3. 监控和日志

#### Prometheus配置
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: ipv6wgm
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'ipv6wgm-services'
      kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names:
          - ipv6wgm
      relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
```

#### Grafana配置
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
  namespace: ipv6wgm
data:
  ipv6wgm-dashboard.json: |
    {
      "dashboard": {
        "title": "IPv6 WireGuard Manager",
        "panels": [
          {
            "title": "System Metrics",
            "type": "graph",
            "targets": [
              {
                "expr": "cpu_usage_percent",
                "legendFormat": "CPU Usage"
              }
            ]
          }
        ]
      }
    }
```

---

## 🔒 安全架构

### 1. 认证和授权

#### JWT认证流程
```python
# JWT认证实现
class JWTAuthentication:
    def __init__(self, secret_key: str):
        self.secret_key = secret_key
        self.algorithm = "HS256"
    
    def create_token(self, user: User) -> str:
        """创建JWT令牌"""
        payload = {
            "user_id": str(user.id),
            "username": user.username,
            "roles": [role.name for role in user.roles],
            "exp": datetime.utcnow() + timedelta(hours=24),
            "iat": datetime.utcnow()
        }
        return jwt.encode(payload, self.secret_key, algorithm=self.algorithm)
    
    def verify_token(self, token: str) -> dict:
        """验证JWT令牌"""
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
            return payload
        except jwt.ExpiredSignatureError:
            raise AuthenticationError("Token has expired")
        except jwt.InvalidTokenError:
            raise AuthenticationError("Invalid token")
```

#### RBAC权限控制
```python
# 权限控制实现
class RBACAuthorization:
    def __init__(self):
        self.permission_cache = {}
    
    async def check_permission(self, user: User, resource: str, action: str) -> bool:
        """检查用户权限"""
        cache_key = f"{user.id}:{resource}:{action}"
        
        if cache_key in self.permission_cache:
            return self.permission_cache[cache_key]
        
        # 获取用户权限
        permissions = await self.get_user_permissions(user)
        
        # 检查权限
        has_permission = self._check_permission(permissions, resource, action)
        
        # 缓存结果
        self.permission_cache[cache_key] = has_permission
        
        return has_permission
    
    def _check_permission(self, permissions: List[Permission], resource: str, action: str) -> bool:
        """检查权限"""
        for permission in permissions:
            if permission.resource == resource and action in permission.actions:
                return True
        return False
```

### 2. 数据安全

#### 数据加密
```python
# 数据加密实现
class DataEncryption:
    def __init__(self, key: bytes):
        self.cipher = Fernet(key)
    
    def encrypt(self, data: str) -> str:
        """加密数据"""
        encrypted_data = self.cipher.encrypt(data.encode())
        return base64.b64encode(encrypted_data).decode()
    
    def decrypt(self, encrypted_data: str) -> str:
        """解密数据"""
        decoded_data = base64.b64decode(encrypted_data.encode())
        decrypted_data = self.cipher.decrypt(decoded_data)
        return decrypted_data.decode()
```

#### 敏感数据保护
```python
# 敏感数据处理
class SensitiveDataHandler:
    def __init__(self):
        self.encryption = DataEncryption(os.getenv("ENCRYPTION_KEY"))
    
    def protect_private_key(self, private_key: str) -> str:
        """保护私钥"""
        return self.encryption.encrypt(private_key)
    
    def get_private_key(self, encrypted_key: str) -> str:
        """获取私钥"""
        return self.encryption.decrypt(encrypted_key)
```

### 3. 网络安全

#### API安全
```python
# API安全中间件
class APISecurityMiddleware:
    def __init__(self):
        self.rate_limiter = RateLimiter()
        self.ip_whitelist = IPWhitelist()
    
    async def __call__(self, request: Request, call_next):
        # IP白名单检查
        if not self.ip_whitelist.is_allowed(request.client.host):
            return JSONResponse(
                status_code=403,
                content={"error": "IP not allowed"}
            )
        
        # 速率限制
        if not await self.rate_limiter.is_allowed(request.client.host):
            return JSONResponse(
                status_code=429,
                content={"error": "Rate limit exceeded"}
            )
        
        response = await call_next(request)
        return response
```

#### 传输安全
```yaml
# TLS配置
tls:
  certificate: /etc/ssl/certs/ipv6wgm.crt
  private_key: /etc/ssl/private/ipv6wgm.key
  protocols:
    - TLSv1.2
    - TLSv1.3
  ciphers:
    - ECDHE-RSA-AES256-GCM-SHA384
    - ECDHE-RSA-CHACHA20-POLY1305
```

---

## 📊 性能优化

### 1. 缓存策略

#### 多级缓存
```python
# 多级缓存实现
class MultiLevelCache:
    def __init__(self):
        self.l1_cache = {}  # 内存缓存
        self.l2_cache = redis.Redis()  # Redis缓存
        self.l3_cache = DatabaseCache()  # 数据库缓存
    
    async def get(self, key: str) -> Any:
        # L1缓存
        if key in self.l1_cache:
            return self.l1_cache[key]
        
        # L2缓存
        value = await self.l2_cache.get(key)
        if value:
            self.l1_cache[key] = value
            return value
        
        # L3缓存
        value = await self.l3_cache.get(key)
        if value:
            await self.l2_cache.set(key, value, ex=3600)
            self.l1_cache[key] = value
            return value
        
        return None
```

#### 缓存预热
```python
# 缓存预热
class CacheWarmup:
    def __init__(self):
        self.cache = MultiLevelCache()
    
    async def warmup_system_data(self):
        """预热系统数据"""
        # 预热用户数据
        users = await self.user_repo.get_all()
        for user in users:
            await self.cache.set(f"user:{user.id}", user)
        
        # 预热配置数据
        configs = await self.config_repo.get_all()
        for config in configs:
            await self.cache.set(f"config:{config.name}", config)
```

### 2. 数据库优化

#### 连接池
```python
# 数据库连接池
class DatabasePool:
    def __init__(self, database_url: str):
        self.engine = create_async_engine(
            database_url,
            pool_size=20,
            max_overflow=30,
            pool_pre_ping=True,
            pool_recycle=3600
        )
    
    async def get_session(self):
        async with AsyncSession(self.engine) as session:
            yield session
```

#### 查询优化
```python
# 查询优化
class OptimizedQueries:
    def __init__(self, session: AsyncSession):
        self.session = session
    
    async def get_users_with_roles(self) -> List[User]:
        """优化的用户查询"""
        query = select(User).options(
            joinedload(User.roles)
        ).limit(100)
        
        result = await self.session.execute(query)
        return result.scalars().all()
```

### 3. 异步处理

#### 任务队列
```python
# Celery任务队列
from celery import Celery

app = Celery('ipv6wgm')

@app.task
async def process_wireguard_config(config_id: str):
    """处理WireGuard配置"""
    config = await get_config(config_id)
    
    # 生成配置文件
    await generate_config_file(config)
    
    # 重载服务
    await reload_wireguard_service()
    
    # 更新状态
    await update_config_status(config_id, "completed")
```

#### 异步API
```python
# 异步API实现
@app.post("/api/v1/wireguard/clients")
async def create_client(client_data: ClientCreate):
    """异步创建客户端"""
    # 创建客户端记录
    client = await client_service.create_client(client_data)
    
    # 异步处理配置生成
    process_wireguard_config.delay(client.id)
    
    return {"client_id": client.id, "status": "processing"}
```

---

## 🔍 监控和告警

### 1. 指标监控

#### 自定义指标
```python
# Prometheus指标
from prometheus_client import Counter, Histogram, Gauge

# 请求计数器
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

# 请求延迟
REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['endpoint']
)

# 系统指标
SYSTEM_METRICS = Gauge(
    'system_metrics',
    'System metrics',
    ['metric_type']
)
```

#### 指标收集
```python
# 指标收集器
class MetricsCollector:
    def __init__(self):
        self.prometheus_client = PrometheusClient()
    
    async def collect_system_metrics(self):
        """收集系统指标"""
        # CPU使用率
        cpu_usage = psutil.cpu_percent()
        SYSTEM_METRICS.labels(metric_type='cpu_usage').set(cpu_usage)
        
        # 内存使用率
        memory = psutil.virtual_memory()
        SYSTEM_METRICS.labels(metric_type='memory_usage').set(memory.percent)
        
        # 磁盘使用率
        disk = psutil.disk_usage('/')
        SYSTEM_METRICS.labels(metric_type='disk_usage').set(disk.percent)
```

### 2. 日志监控

#### 结构化日志
```python
# 结构化日志
import structlog

logger = structlog.get_logger()

async def log_user_action(user_id: str, action: str, resource: str):
    """记录用户操作"""
    logger.info(
        "user_action",
        user_id=user_id,
        action=action,
        resource=resource,
        timestamp=datetime.utcnow().isoformat()
    )
```

#### 日志聚合
```yaml
# ELK Stack配置
elasticsearch:
  image: elasticsearch:8.8.0
  environment:
    - discovery.type=single-node
    - xpack.security.enabled=false
  ports:
    - "9200:9200"

logstash:
  image: logstash:8.8.0
  volumes:
    - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
  ports:
    - "5044:5044"

kibana:
  image: kibana:8.8.0
  environment:
    - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
  ports:
    - "5601:5601"
```

### 3. 告警系统

#### 告警规则
```yaml
# Prometheus告警规则
groups:
- name: ipv6wgm.rules
  rules:
  - alert: HighCPUUsage
    expr: cpu_usage_percent > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage detected"
      description: "CPU usage is above 80% for more than 5 minutes"
  
  - alert: HighMemoryUsage
    expr: memory_usage_percent > 90
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "High memory usage detected"
      description: "Memory usage is above 90% for more than 2 minutes"
```

#### 告警通知
```python
# 告警通知
class AlertNotifier:
    def __init__(self):
        self.email_client = EmailClient()
        self.slack_client = SlackClient()
    
    async def send_alert(self, alert: Alert):
        """发送告警通知"""
        if alert.severity == "critical":
            await self.email_client.send_alert(alert)
            await self.slack_client.send_alert(alert)
        elif alert.severity == "warning":
            await self.slack_client.send_alert(alert)
```

---

## 🚀 部署和运维

### 1. CI/CD流水线

#### GitLab CI配置
```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"

test:
  stage: test
  image: python:3.11
  script:
    - pip install -r requirements.txt
    - pytest tests/
  coverage: '/TOTAL.*\s+(\d+%)$/'

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  only:
    - main

deploy:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl set image deployment/auth-service auth-service=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - kubectl rollout status deployment/auth-service
  only:
    - main
```

### 2. 健康检查

#### 服务健康检查
```python
# 健康检查端点
@app.get("/health")
async def health_check():
    """健康检查"""
    health_status = {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "services": {}
    }
    
    # 检查数据库连接
    try:
        await database.execute("SELECT 1")
        health_status["services"]["database"] = "healthy"
    except Exception as e:
        health_status["services"]["database"] = f"unhealthy: {str(e)}"
        health_status["status"] = "unhealthy"
    
    # 检查Redis连接
    try:
        await redis_client.ping()
        health_status["services"]["redis"] = "healthy"
    except Exception as e:
        health_status["services"]["redis"] = f"unhealthy: {str(e)}"
        health_status["status"] = "unhealthy"
    
    return health_status
```

### 3. 自动扩缩容

#### HPA配置
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: auth-service-hpa
  namespace: ipv6wgm
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: auth-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

---

*本技术架构文档详细描述了IPv6 WireGuard Manager现代化改造的技术实现方案，为开发团队提供完整的技术指导。*
