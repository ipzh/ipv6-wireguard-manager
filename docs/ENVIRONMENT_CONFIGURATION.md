# 环境配置文档

## 概述

本文档详细说明IPv6 WireGuard Manager项目的环境配置，包括环境变量、配置文件、路径设置等内容。

## 环境变量配置

### 1. 基础环境变量

#### 1.1 应用配置

```bash
# 应用基本信息
APP_NAME=IPv6 WireGuard Manager
APP_VERSION=1.0.0
APP_DESCRIPTION=现代化的企业级IPv6 WireGuard VPN管理系统

# 调试模式
DEBUG=false
LOG_LEVEL=INFO
LOG_FORMAT=json

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
SERVER_WORKERS=4
```

#### 1.2 API配置

```bash
# API版本和路径
API_V1_STR=/api/v1
API_V2_STR=/api/v2

# 安全配置
SECRET_KEY=your_very_secure_secret_key_here_change_in_production
ACCESS_TOKEN_EXPIRE_MINUTES=11520
REFRESH_TOKEN_EXPIRE_DAYS=30
ALGORITHM=HS256

# CORS配置
BACKEND_CORS_ORIGINS=["http://localhost:3000","https://localhost:3000","http://localhost","https://localhost"]
```

#### 1.3 数据库配置

```bash
# 数据库连接
DATABASE_URL=mysql://ipv6wgm:password@localhost:3306/ipv6wgm
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_NAME=ipv6wgm
DATABASE_USER=ipv6wgm
DATABASE_PASSWORD=password

# 数据库连接池
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=30
DATABASE_POOL_RECYCLE=3600
DATABASE_POOL_PRE_PING=true
```

### 2. 路径配置

#### 2.1 安装路径

```bash
# 主安装目录
INSTALL_DIR=/opt/ipv6-wireguard-manager

# 前端Web目录
FRONTEND_DIR=/var/www/html

# WireGuard配置目录
WIREGUARD_CONFIG_DIR=/etc/wireguard
WIREGUARD_CLIENTS_DIR=/etc/wireguard/clients

# 日志目录
LOG_DIR=/var/log/ipv6-wireguard-manager
LOG_FILE=/var/log/ipv6-wireguard-manager/app.log

# 配置文件目录
CONFIG_DIR=/opt/ipv6-wireguard-manager/config
DATA_DIR=/opt/ipv6-wireguard-manager/data
TEMP_DIR=/opt/ipv6-wireguard-manager/temp
BACKUP_DIR=/opt/ipv6-wireguard-manager/backups
```

#### 2.2 系统路径

```bash
# Nginx配置目录
NGINX_CONFIG_DIR=/etc/nginx/sites-available
NGINX_LOG_DIR=/var/log/nginx

# Systemd服务目录
SYSTEMD_CONFIG_DIR=/etc/systemd/system

# 二进制文件目录
BIN_DIR=/opt/ipv6-wireguard-manager/bin
```

### 3. WireGuard配置

#### 3.1 服务器配置

```bash
# WireGuard服务器配置
WIREGUARD_PRIVATE_KEY=base64_encoded_private_key
WIREGUARD_PUBLIC_KEY=base64_encoded_public_key
WIREGUARD_PORT=51820
WIREGUARD_INTERFACE=wg0
WIREGUARD_NETWORK=10.0.0.0/24
WIREGUARD_IPV6_NETWORK=fd00::/64
WIREGUARD_DNS=8.8.8.8,8.8.4.4
WIREGUARD_MTU=1420
```

#### 3.2 客户端配置

```bash
# 客户端默认配置
WIREGUARD_CLIENT_DEFAULT_ALLOWED_IPS=0.0.0.0/0,::/0
WIREGUARD_CLIENT_DEFAULT_PERSISTENT_KEEPALIVE=25
WIREGUARD_CLIENT_DEFAULT_MTU=1420
```

### 4. 安全配置

#### 4.1 认证配置

```bash
# 默认管理员账户
FIRST_SUPERUSER=admin
FIRST_SUPERUSER_PASSWORD=admin123
FIRST_SUPERUSER_EMAIL=admin@example.com

# 密码策略
PASSWORD_MIN_LENGTH=8
PASSWORD_REQUIRE_UPPERCASE=true
PASSWORD_REQUIRE_LOWERCASE=true
PASSWORD_REQUIRE_NUMBERS=true
PASSWORD_REQUIRE_SYMBOLS=true
```

#### 4.2 安全头配置

```bash
# 安全头配置
SECURITY_HEADERS_ENABLED=true
CORS_ALLOW_CREDENTIALS=true
CORS_ALLOW_METHODS=["GET","POST","PUT","DELETE","OPTIONS"]
CORS_ALLOW_HEADERS=["*"]
TRUSTED_HOSTS=["localhost","127.0.0.1","your-domain.com"]
```

### 5. 监控配置

#### 5.1 日志配置

```bash
# 日志级别和格式
LOG_LEVEL=INFO
LOG_FORMAT=json
LOG_ROTATION=1 day
LOG_RETENTION=30 days

# 日志文件配置
LOG_FILE_MAX_SIZE=10MB
LOG_FILE_BACKUP_COUNT=5
LOG_CONSOLE_ENABLED=true
LOG_FILE_ENABLED=true
```

#### 5.2 监控配置

```bash
# 监控功能
ENABLE_METRICS=true
METRICS_PORT=9090
ENABLE_HEALTH_CHECK=true
HEALTH_CHECK_INTERVAL=30

# 异常监控
EXCEPTION_MONITORING_ENABLED=true
EXCEPTION_MONITORING_INTERVAL=60
ALERT_RULES_CONFIG=/opt/ipv6-wireguard-manager/config/alert_rules.json
```

### 6. 缓存配置

#### 6.1 Redis配置

```bash
# Redis连接配置
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=
REDIS_MAX_CONNECTIONS=20

# 缓存配置
CACHE_ENABLED=true
CACHE_DEFAULT_TTL=300
CACHE_MAX_SIZE=1000
```

### 7. 邮件配置

#### 7.1 SMTP配置

```bash
# SMTP服务器配置
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password
SMTP_TLS=true
SMTP_SSL=false

# 邮件模板
EMAIL_FROM_NAME=IPv6 WireGuard Manager
EMAIL_FROM_ADDRESS=noreply@example.com
EMAIL_TEMPLATE_DIR=/opt/ipv6-wireguard-manager/templates/email
```

## 环境特定配置

### 1. 开发环境

#### 1.1 开发环境变量

```bash
# .env.development
DEBUG=true
LOG_LEVEL=DEBUG
LOG_FORMAT=text

# 开发数据库
DATABASE_URL=mysql://ipv6wgm_dev:dev_password@localhost:3306/ipv6wgm_dev

# 开发服务器
SERVER_HOST=127.0.0.1
SERVER_PORT=8000

# 开发路径
INSTALL_DIR=/home/developer/ipv6-wireguard-manager
FRONTEND_DIR=/home/developer/ipv6-wireguard-manager/php-frontend
LOG_DIR=/home/developer/ipv6-wireguard-manager/logs

# 开发安全配置
SECRET_KEY=dev_secret_key_not_for_production
CORS_ALLOW_ORIGINS=["http://localhost:3000","http://localhost:8080"]
```

#### 1.2 开发配置特点

- **调试模式**: 启用详细日志和错误信息
- **热重载**: 支持代码变更自动重载
- **宽松CORS**: 允许本地开发服务器访问
- **测试数据**: 使用测试数据库和测试数据

### 2. 测试环境

#### 2.1 测试环境变量

```bash
# .env.testing
DEBUG=false
LOG_LEVEL=INFO
LOG_FORMAT=json

# 测试数据库
DATABASE_URL=mysql://ipv6wgm_test:test_password@test-db:3306/ipv6wgm_test

# 测试服务器
SERVER_HOST=0.0.0.0
SERVER_PORT=8000

# 测试路径
INSTALL_DIR=/opt/ipv6-wireguard-manager-test
FRONTEND_DIR=/var/www/html-test
LOG_DIR=/var/log/ipv6-wireguard-manager-test

# 测试安全配置
SECRET_KEY=test_secret_key
CORS_ALLOW_ORIGINS=["https://test.example.com"]
```

#### 2.2 测试配置特点

- **隔离环境**: 独立的数据库和配置
- **自动化测试**: 支持自动化测试运行
- **性能测试**: 配置性能测试参数
- **集成测试**: 支持集成测试环境

### 3. 生产环境

#### 3.1 生产环境变量

```bash
# .env.production
DEBUG=false
LOG_LEVEL=WARNING
LOG_FORMAT=json

# 生产数据库
DATABASE_URL=mysql://ipv6wgm:secure_password@prod-db:3306/ipv6wgm

# 生产服务器
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
SERVER_WORKERS=8

# 生产路径
INSTALL_DIR=/opt/ipv6-wireguard-manager
FRONTEND_DIR=/var/www/html
LOG_DIR=/var/log/ipv6-wireguard-manager

# 生产安全配置
SECRET_KEY=your_very_secure_production_secret_key
CORS_ALLOW_ORIGINS=["https://your-domain.com"]
TRUSTED_HOSTS=["your-domain.com","www.your-domain.com"]
```

#### 3.2 生产配置特点

- **安全优先**: 严格的安全配置
- **性能优化**: 优化的性能参数
- **监控完整**: 完整的监控和告警
- **备份策略**: 自动备份配置

## 配置文件管理

### 1. 配置文件结构

```
config/
├── base.json                 # 基础配置
├── development.json          # 开发环境配置
├── testing.json             # 测试环境配置
├── staging.json             # 预发布环境配置
├── production.json          # 生产环境配置
├── local.json               # 本地覆盖配置
├── alert_rules.json         # 告警规则配置
├── wireguard_defaults.json  # WireGuard默认配置
└── security_policies.json   # 安全策略配置
```

### 2. 配置文件示例

#### 2.1 基础配置文件

```json
{
  "app": {
    "name": "IPv6 WireGuard Manager",
    "version": "1.0.0",
    "description": "现代化的企业级IPv6 WireGuard VPN管理系统"
  },
  "server": {
    "host": "0.0.0.0",
    "port": 8000,
    "workers": 4
  },
  "database": {
    "pool_size": 20,
    "max_overflow": 30,
    "pool_recycle": 3600,
    "pool_pre_ping": true
  },
  "security": {
    "password_min_length": 8,
    "password_require_uppercase": true,
    "password_require_lowercase": true,
    "password_require_numbers": true,
    "password_require_symbols": true
  },
  "monitoring": {
    "enable_metrics": true,
    "metrics_port": 9090,
    "enable_health_check": true,
    "health_check_interval": 30
  }
}
```

#### 2.2 环境特定配置

```json
{
  "development": {
    "debug": true,
    "log_level": "DEBUG",
    "log_format": "text",
    "cors_origins": [
      "http://localhost:3000",
      "http://localhost:8080"
    ]
  },
  "production": {
    "debug": false,
    "log_level": "WARNING",
    "log_format": "json",
    "cors_origins": [
      "https://your-domain.com"
    ],
    "trusted_hosts": [
      "your-domain.com",
      "www.your-domain.com"
    ]
  }
}
```

### 3. 配置加载顺序

1. **base.json** - 基础配置
2. **{environment}.json** - 环境特定配置
3. **local.json** - 本地覆盖配置
4. **环境变量** - 环境变量覆盖
5. **命令行参数** - 命令行参数覆盖

## 环境变量管理

### 1. 环境变量加载

#### 1.1 自动加载

```python
# 使用python-dotenv自动加载
from dotenv import load_dotenv
import os

# 加载.env文件
load_dotenv()

# 获取环境变量
debug = os.getenv('DEBUG', 'false').lower() == 'true'
log_level = os.getenv('LOG_LEVEL', 'INFO')
```

#### 1.2 手动加载

```python
# 手动加载环境变量
def load_environment_variables():
    """加载环境变量"""
    env_vars = {}
    
    # 从.env文件加载
    with open('.env', 'r') as f:
        for line in f:
            if line.strip() and not line.startswith('#'):
                key, value = line.strip().split('=', 1)
                env_vars[key] = value
    
    # 从系统环境变量覆盖
    for key in env_vars:
        if key in os.environ:
            env_vars[key] = os.environ[key]
    
    return env_vars
```

### 2. 环境变量验证

#### 2.1 必需变量检查

```python
def validate_required_env_vars():
    """验证必需的环境变量"""
    required_vars = [
        'DATABASE_URL',
        'SECRET_KEY',
        'API_V1_STR'
    ]
    
    missing_vars = []
    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)
    
    if missing_vars:
        raise ValueError(f"Missing required environment variables: {', '.join(missing_vars)}")
```

#### 2.2 变量类型转换

```python
def get_env_bool(key: str, default: bool = False) -> bool:
    """获取布尔类型环境变量"""
    value = os.getenv(key, str(default)).lower()
    return value in ('true', '1', 'yes', 'on')

def get_env_int(key: str, default: int = 0) -> int:
    """获取整数类型环境变量"""
    try:
        return int(os.getenv(key, str(default)))
    except ValueError:
        return default

def get_env_list(key: str, default: list = None, separator: str = ',') -> list:
    """获取列表类型环境变量"""
    if default is None:
        default = []
    
    value = os.getenv(key)
    if not value:
        return default
    
    return [item.strip() for item in value.split(separator) if item.strip()]
```

### 3. 环境变量模板

#### 3.1 环境变量模板文件

```bash
# env.template
# 复制此文件为 .env 并修改相应的值

# 应用配置
APP_NAME=IPv6 WireGuard Manager
APP_VERSION=1.0.0
DEBUG=false
LOG_LEVEL=INFO

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=8000

# 数据库配置
DATABASE_URL=mysql://ipv6wgm:password@localhost:3306/ipv6wgm

# 安全配置
SECRET_KEY=your_secret_key_here
ACCESS_TOKEN_EXPIRE_MINUTES=11520

# 路径配置
INSTALL_DIR=/opt/ipv6-wireguard-manager
FRONTEND_DIR=/var/www/html
LOG_DIR=/var/log/ipv6-wireguard-manager

# WireGuard配置
WIREGUARD_PORT=51820
WIREGUARD_INTERFACE=wg0
WIREGUARD_NETWORK=10.0.0.0/24

# 监控配置
ENABLE_METRICS=true
METRICS_PORT=9090
```

## 配置热更新

### 1. 配置文件监控

#### 1.1 文件监控设置

```python
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class ConfigFileHandler(FileSystemEventHandler):
    """配置文件变更处理器"""
    
    def __init__(self, config_manager):
        self.config_manager = config_manager
    
    def on_modified(self, event):
        """文件修改事件"""
        if event.src_path.endswith('.json'):
            self.config_manager.reload_config()
    
    def on_created(self, event):
        """文件创建事件"""
        if event.src_path.endswith('.json'):
            self.config_manager.reload_config()

# 启动文件监控
def start_config_monitoring():
    """启动配置文件监控"""
    event_handler = ConfigFileHandler(config_manager)
    observer = Observer()
    observer.schedule(event_handler, path='config/', recursive=True)
    observer.start()
    return observer
```

### 2. 配置变更通知

#### 2.1 变更回调机制

```python
class ConfigManager:
    """配置管理器"""
    
    def __init__(self):
        self.config = {}
        self.callbacks = []
    
    def add_change_callback(self, callback):
        """添加配置变更回调"""
        self.callbacks.append(callback)
    
    def reload_config(self):
        """重新加载配置"""
        old_config = self.config.copy()
        self.config = self.load_config()
        
        # 通知变更
        for callback in self.callbacks:
            callback(old_config, self.config)
    
    def load_config(self):
        """加载配置"""
        # 实现配置加载逻辑
        pass
```

## 最佳实践

### 1. 环境隔离

- **完全隔离**: 开发、测试、生产环境完全隔离
- **独立数据库**: 每个环境使用独立的数据库
- **独立配置**: 每个环境使用独立的配置文件
- **独立资源**: 每个环境使用独立的服务器资源

### 2. 安全配置

- **敏感信息**: 敏感信息使用环境变量存储
- **权限控制**: 配置文件设置适当的文件权限
- **加密存储**: 敏感配置信息加密存储
- **访问控制**: 限制配置文件的访问权限

### 3. 配置管理

- **版本控制**: 配置文件纳入版本控制
- **配置验证**: 启动时验证配置的有效性
- **默认值**: 为所有配置项提供合理的默认值
- **文档同步**: 保持配置文档与代码同步

### 4. 环境变量使用

- **命名规范**: 使用统一的命名规范
- **类型转换**: 正确处理环境变量的类型转换
- **默认值**: 为环境变量提供合理的默认值
- **验证检查**: 启动时验证必需的环境变量

---

**注意**: 本文档基于当前版本，如有更新请查看最新版本文档。
