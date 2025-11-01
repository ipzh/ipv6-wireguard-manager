# 令牌黑名单功能说明

## 概述

令牌黑名单是IPv6 WireGuard Manager系统中的一个重要安全功能，用于撤销已签发的JWT令牌，防止已登出或已撤销的令牌被继续使用。系统支持两种存储方式：内存存储和数据库存储，可根据需要选择。

## 功能特性

- **令牌撤销**：将特定令牌添加到黑名单，使其无法继续使用
- **JTI支持**：通过JWT ID（JTI）撤销令牌
- **用户令牌批量撤销**：撤销特定用户的所有令牌（仅数据库存储）
- **自动清理**：定期清理过期的黑名单条目
- **灵活存储**：支持内存存储和数据库存储两种方式

## 存储方式

### 内存存储

- **优点**：简单、快速，无需额外配置
- **缺点**：服务重启后黑名单数据丢失，不支持按用户ID撤销令牌
- **适用场景**：开发环境、测试环境或小型部署

### 数据库存储

- **优点**：持久化存储，支持按用户ID撤销令牌，服务重启后数据不丢失
- **缺点**：需要数据库支持，性能略低于内存存储
- **适用场景**：生产环境、大型部署或需要持久化存储的场景

## 配置

### 环境变量配置

可以通过设置环境变量 `USE_DATABASE_BLACKLIST` 来选择存储方式：

```bash
# 使用内存存储（默认）
export USE_DATABASE_BLACKLIST=false

# 使用数据库存储
export USE_DATABASE_BLACKLIST=true
```

### 数据库配置（可选）

如果使用数据库存储，系统会自动创建必要的数据库表。确保数据库连接正常，并且应用有权限创建表。

## API 使用

### 基本操作

```python
from app.core.token_blacklist import (
    add_to_blacklist, 
    is_blacklisted, 
    remove_from_blacklist,
    revoke_by_jti,
    revoke_user_tokens,
    get_blacklisted_count
)

# 添加令牌到黑名单
add_to_blacklist("your_jwt_token")

# 检查令牌是否在黑名单中
if is_blacklisted("your_jwt_token"):
    print("令牌已被撤销")

# 从黑名单中移除令牌
remove_from_blacklist("your_jwt_token")

# 通过JTI撤销令牌
revoke_by_jti("jwt_id")

# 撤销用户的所有令牌（仅数据库存储）
revoked_count = revoke_user_tokens(user_id=123)

# 获取黑名单中的令牌数量
count = get_blacklisted_count()
```

### 高级操作

```python
from app.core.token_blacklist import TokenBlacklist

# 创建自定义黑名单实例
blacklist = TokenBlacklist(use_database=True)

# 添加带过期时间和JTI的令牌
blacklist.add_token(
    token="your_jwt_token",
    expires_at=1672531200,  # Unix时间戳
    jti="jwt_id"
)

# 获取所有黑名单中的令牌（仅用于调试）
all_tokens = blacklist.get_all_blacklisted()
```

## 自动清理

### 清理机制

系统会定期清理过期的黑名单条目，默认清理间隔为1小时。清理过程会自动执行，无需手动干预。

### 手动清理

如果需要手动清理，可以使用提供的清理脚本：

```bash
# 模拟运行，不实际清理
python3 backend/scripts/cleanup_blacklist.py --dry-run --verbose

# 实际清理
python3 backend/scripts/cleanup_blacklist.py --verbose
```

### 定时清理服务

为了确保黑名单不会无限增长，建议安装定时清理服务：

```bash
# 安装清理服务（需要root权限）
sudo bash backend/scripts/install_blacklist_cleanup.sh

# 检查服务状态
systemctl status wireguard-blacklist-cleanup.timer

# 手动启动清理任务
systemctl start wireguard-blacklist-cleanup.service
```

## 测试

系统提供了完整的测试脚本，用于验证令牌黑名单功能：

```bash
# 运行测试
python3 backend/scripts/test_blacklist.py
```

测试脚本会验证以下功能：
- 基本黑名单操作（添加、检查、移除）
- JTI支持
- 用户令牌批量撤销
- 黑名单计数
- 过期令牌处理
- 数据库存储功能

## 安全考虑

1. **令牌存储**：黑名单中的令牌是完整存储的，在生产环境中应确保黑名单数据的安全性
2. **访问控制**：限制对黑名单管理功能的访问，只有授权用户才能撤销令牌
3. **日志记录**：系统会记录所有黑名单操作，建议定期审查日志
4. **清理策略**：根据实际需求调整清理间隔，确保系统性能

## 故障排除

### 常见问题

1. **数据库存储初始化失败**
   - 检查数据库连接配置
   - 确保应用有创建表的权限
   - 查看日志获取详细错误信息

2. **清理服务不工作**
   - 检查systemd服务状态
   - 确认脚本路径正确
   - 查看journalctl日志获取错误信息

3. **令牌仍在黑名单中但已过期**
   - 手动触发清理：`token_blacklist._cleanup_expired_tokens()`
   - 检查系统时间是否正确

### 日志查看

```bash
# 查看清理服务日志
journalctl -u wireguard-blacklist-cleanup.service -f

# 查看应用日志
tail -f /var/log/wireguard-manager/app.log
```

## 性能优化

1. **内存优化**：定期清理过期令牌，避免内存占用过高
2. **数据库优化**：为黑名单表添加适当的索引
3. **批量操作**：对于大量令牌操作，考虑使用批量处理

## 扩展功能

未来可以考虑添加以下功能：

1. **Redis支持**：使用Redis作为黑名单存储，提高性能
2. **分布式支持**：支持多实例间的黑名单同步
3. **API接口**：提供REST API用于黑名单管理
4. **Web界面**：添加Web界面用于黑名单管理

## 版本历史

- v1.0.0：初始版本，支持基本黑名单功能
- v1.1.0：添加数据库存储支持
- v1.2.0：添加JTI支持和用户令牌批量撤销
- v1.3.0：添加自动清理机制和定时服务