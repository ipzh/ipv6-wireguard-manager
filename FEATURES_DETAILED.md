# IPv6 WireGuard Manager 详细功能文档

## 📋 功能概述

IPv6 WireGuard Manager 是一个企业级的网络管理平台，集成了 WireGuard VPN、BGP 路由管理和 IPv6 前缀池管理功能。本文档详细介绍了系统的所有功能特性和使用方法。

## 🏗️ 系统架构

### 技术栈
- **后端**: FastAPI + Python 3.8+
- **前端**: React 18 + TypeScript + Ant Design
- **数据库**: PostgreSQL + Redis
- **Web服务器**: Nginx
- **BGP服务**: ExaBGP
- **VPN服务**: WireGuard

### 系统组件
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   前端界面      │    │   后端API       │    │   数据库        │
│   React + TS    │◄──►│   FastAPI       │◄──►│   PostgreSQL    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx代理     │    │   BGP服务       │    │   缓存服务      │
│   静态文件+API  │    │   ExaBGP        │    │   Redis         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   VPN服务       │
                       │   WireGuard     │
                       └─────────────────┘
```

## 🔐 用户认证与权限管理

### 认证系统
- **JWT令牌认证**: 安全的无状态认证
- **自动令牌刷新**: 无缝的用户体验
- **会话管理**: 完整的登录/登出流程
- **密码安全**: bcrypt加密存储

### 用户管理
- **用户创建**: 支持创建新用户
- **角色分配**: 管理员、操作员、查看者角色
- **权限控制**: 细粒度的功能权限
- **用户状态**: 启用/禁用用户账户

### 默认用户
- **管理员**: admin / admin123
- **测试用户**: test / test123

## 🌐 BGP 会话管理

### 会话配置
- **邻居配置**: 支持IPv4和IPv6邻居
- **ASN管理**: 本地AS和远程AS配置
- **保持时间**: 可配置的BGP保持时间
- **认证密码**: MD5密码保护
- **描述信息**: 详细的会话描述

### 会话状态监控
- **实时状态**: established, idle, connect, active等
- **运行时间**: 会话运行时间统计
- **前缀统计**: 接收和发送的前缀数量
- **状态变更**: 最后状态变更时间记录

### 会话操作
- **启用/禁用**: 动态控制会话状态
- **重载配置**: 重新加载ExaBGP配置
- **重启会话**: 重启BGP会话
- **批量操作**: 支持批量启停多个会话

### API端点
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

# 更新BGP会话
PATCH /api/v1/bgp/sessions/{session_id}

# 删除BGP会话
DELETE /api/v1/bgp/sessions/{session_id}

# 重载会话配置
POST /api/v1/bgp/sessions/{session_id}/reload

# 重启会话
POST /api/v1/bgp/sessions/{session_id}/restart

# 批量操作
POST /api/v1/bgp/sessions/batch/reload
POST /api/v1/bgp/sessions/batch/restart
```

## 📢 BGP 宣告管理

### 宣告配置
- **前缀管理**: 支持IPv4和IPv6前缀
- **ASN配置**: 可选的ASN设置
- **下一跳**: 路由下一跳配置
- **启用状态**: 动态控制宣告状态
- **描述信息**: 详细的宣告描述

### 宣告操作
- **创建宣告**: 添加新的BGP宣告
- **修改宣告**: 更新现有宣告配置
- **删除宣告**: 移除不需要的宣告
- **批量启停**: 批量启用/禁用宣告

### 宣告验证
- **前缀格式**: 自动验证前缀格式
- **ASN有效性**: 检查ASN范围
- **重复检查**: 防止重复宣告
- **冲突检测**: 检测宣告冲突

### API端点
```bash
# 获取BGP宣告列表
GET /api/v1/bgp/announcements

# 创建BGP宣告
POST /api/v1/bgp/announcements
{
  "prefix": "192.0.2.0/24",
  "asn": 65001,
  "next_hop": "192.168.1.1",
  "description": "客户前缀",
  "enabled": true
}

# 更新BGP宣告
PATCH /api/v1/bgp/announcements/{ann_id}

# 删除BGP宣告
DELETE /api/v1/bgp/announcements/{ann_id}

# 启用/禁用宣告
POST /api/v1/bgp/announcements/{ann_id}/enable
POST /api/v1/bgp/announcements/{ann_id}/disable
```

## 🏊 IPv6 前缀池管理

### 前缀池配置
- **池名称**: 唯一的前缀池标识
- **基础前缀**: 如 2001:db8::/48
- **前缀长度**: 分配的前缀长度
- **总容量**: 前缀池总容量
- **自动宣告**: 分配时自动BGP宣告
- **白名单**: 前缀访问控制
- **RPKI**: 路由来源验证

### 智能分配算法
- **自动分配**: 智能选择可用前缀
- **容量跟踪**: 实时监控使用情况
- **冲突避免**: 防止前缀冲突
- **回收机制**: 自动回收未使用前缀

### 分配管理
- **客户端分配**: 为WireGuard客户端分配前缀
- **服务器分配**: 为WireGuard服务器分配前缀
- **手动分配**: 手动指定前缀分配
- **批量分配**: 批量分配多个前缀

### 安全控制
- **前缀白名单**: 允许的前缀范围
- **最大前缀限制**: 防止前缀滥用
- **RPKI验证**: 路由来源验证
- **告警系统**: 异常情况告警

### API端点
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
  "prefix": "2001:db8:1::/64",
  "description": "允许的客户端前缀"
}

# RPKI验证
POST /api/v1/ipv6/pools/{pool_id}/validate-rpki
{
  "prefix": "2001:db8::/64"
}
```

## 🔒 WireGuard 管理

### 服务器管理
- **服务器配置**: 创建和管理WireGuard服务器
- **接口配置**: 网络接口设置
- **端口管理**: 监听端口配置
- **密钥管理**: 自动生成密钥对
- **IP地址**: IPv4和IPv6地址配置
- **DNS设置**: DNS服务器配置
- **MTU配置**: 网络MTU设置

### 客户端管理
- **客户端创建**: 为服务器添加客户端
- **密钥生成**: 自动生成客户端密钥
- **IP分配**: 自动分配客户端IP
- **配置生成**: 生成客户端配置文件
- **QR码**: 生成客户端配置QR码
- **状态监控**: 实时客户端状态

### 状态监控
- **连接状态**: 客户端连接状态
- **流量统计**: 上传下载流量统计
- **握手时间**: 最后握手时间
- **端点信息**: 客户端端点信息
- **保持连接**: 持久连接配置

### 配置管理
- **配置文件**: 自动生成WireGuard配置
- **配置重载**: 动态重载配置
- **配置备份**: 配置文件备份
- **配置恢复**: 从备份恢复配置

### API端点
```bash
# 获取WireGuard服务器列表
GET /api/v1/wireguard/servers

# 创建WireGuard服务器
POST /api/v1/wireguard/servers
{
  "name": "server-1",
  "interface": "wg0",
  "listen_port": 51820,
  "ipv4_address": "10.0.0.1/24",
  "ipv6_address": "fd00:1234::1/64",
  "dns_servers": ["8.8.8.8", "8.8.4.4"],
  "mtu": 1420
}

# 获取WireGuard客户端列表
GET /api/v1/wireguard/clients

# 创建WireGuard客户端
POST /api/v1/wireguard/clients
{
  "server_id": "server-uuid",
  "name": "client-1",
  "description": "客户端描述",
  "ipv4_address": "10.0.0.2/32",
  "ipv6_address": "fd00:1234::2/128"
}

# 获取客户端配置
GET /api/v1/wireguard/clients/{client_id}/config

# 获取客户端QR码
GET /api/v1/wireguard/clients/{client_id}/qrcode
```

## 📊 实时监控与告警

### 系统监控
- **CPU使用率**: 实时CPU监控
- **内存使用率**: 内存使用情况
- **磁盘使用率**: 磁盘空间监控
- **网络流量**: 网络接口流量统计
- **服务状态**: 所有服务运行状态

### BGP监控
- **会话状态**: BGP会话实时状态
- **前缀统计**: 接收和发送前缀数量
- **路由变化**: 路由表变化监控
- **邻居状态**: 邻居连接状态

### 前缀池监控
- **使用率**: 前缀池使用率统计
- **分配速度**: 前缀分配速度
- **回收情况**: 前缀回收统计
- **容量预警**: 容量不足预警

### 告警系统
- **告警类型**: RPKI无效、前缀超限、会话断开等
- **告警级别**: INFO、WARNING、ERROR、CRITICAL
- **告警通知**: 实时告警通知
- **告警历史**: 告警历史记录

### WebSocket实时通信
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

## 🔧 系统设置

### 用户设置
- **个人信息**: 用户名、邮箱、密码修改
- **偏好设置**: 界面语言、主题设置
- **通知设置**: 告警通知配置

### 系统配置
- **网络设置**: 网络接口配置
- **防火墙**: 防火墙规则管理
- **服务配置**: 各种服务配置
- **备份设置**: 自动备份配置

### 域名与SSL
- **域名绑定**: 自定义域名配置
- **SSL证书**: Let's Encrypt自动证书
- **自定义证书**: 上传自定义证书
- **Cloudflare**: Cloudflare SSL配置

### 系统管理
- **系统信息**: 系统版本、运行时间等
- **服务管理**: 启动、停止、重启服务
- **日志管理**: 系统日志查看和导出
- **备份恢复**: 系统备份和恢复
- **卸载重装**: 系统卸载和重新安装

## 📈 性能优化

### 数据库优化
- **查询优化器**: 智能查询优化，减少数据库负载
- **索引优化**: 关键字段索引，提升查询性能
- **连接池**: 数据库连接池配置，支持高并发
- **缓存策略**: Redis缓存配置，减少数据库访问
- **异步操作**: 异步数据库操作，提升响应速度

### 缓存优化
- **多级缓存**: 内存缓存 + Redis缓存架构
- **智能缓存**: 自动缓存热点数据
- **缓存失效**: 智能缓存失效策略
- **性能监控**: 实时缓存命中率监控

### 前端优化
- **代码分割**: 按需加载组件，减少初始加载时间
- **资源压缩**: 静态资源压缩，提升传输效率
- **CDN加速**: 静态资源CDN，全球加速访问
- **缓存策略**: 浏览器缓存配置，减少重复请求

### 网络优化
- **连接复用**: HTTP连接复用，减少连接开销
- **压缩传输**: 响应数据压缩，节省带宽
- **负载均衡**: 多实例负载均衡，支持水平扩展
- **缓存层**: 多层缓存架构，提升响应速度

### 性能监控
- **实时监控**: CPU、内存、磁盘、网络实时监控
- **性能指标**: API响应时间、数据库查询时间等关键指标
- **告警系统**: 性能异常自动告警
- **健康检查**: 系统健康状态检查，支持Kubernetes就绪和存活检查

## 🔒 安全特性

### 认证安全
- **JWT令牌**: 安全的无状态认证
- **令牌过期**: 自动令牌过期机制
- **密码策略**: 强密码策略
- **登录保护**: 登录失败保护

### 网络安全
- **HTTPS**: 强制HTTPS访问
- **CORS配置**: 跨域请求控制
- **防火墙**: 网络防火墙保护
- **IP白名单**: IP访问控制

### 数据安全
- **数据加密**: 敏感数据加密存储
- **备份加密**: 备份数据加密
- **传输加密**: 数据传输加密
- **访问控制**: 细粒度访问控制

## 📚 API文档

### 认证API
```bash
# 用户登录
POST /api/v1/auth/login
{
  "username": "admin",
  "password": "admin123"
}

# 获取当前用户
GET /api/v1/auth/test-token

# 刷新令牌
POST /api/v1/auth/refresh-token

# 用户登出
POST /api/v1/auth/logout
```

### 系统API
```bash
# 系统状态
GET /api/v1/status/status

# 系统信息
GET /api/v1/system/info

# 系统操作
POST /api/v1/system/action
{
  "action": "restart",
  "service": "ipv6-wireguard-manager"
}
```

### 用户管理API
```bash
# 获取用户列表
GET /api/v1/users

# 创建用户
POST /api/v1/users
{
  "username": "newuser",
  "email": "user@example.com",
  "password": "password123",
  "is_active": true,
  "is_superuser": false
}

# 更新用户
PATCH /api/v1/users/{user_id}

# 删除用户
DELETE /api/v1/users/{user_id}
```

## 🎯 使用场景

### 企业VPN部署
- **远程办公**: 为员工提供安全的远程访问
- **分支机构**: 连接多个分支机构
- **客户接入**: 为客户提供VPN接入服务

### 网络服务提供商
- **BGP路由**: 管理BGP路由和宣告
- **IPv6部署**: IPv6前缀分配和管理
- **客户管理**: 客户网络配置管理

### 云服务提供商
- **多租户**: 为多个租户提供网络服务
- **资源隔离**: 网络资源隔离和管理
- **自动化**: 自动化网络配置和管理

## 🚀 最佳实践

### 部署建议
- **生产环境**: 使用原生安装获得最佳性能
- **测试环境**: 使用Docker安装便于管理
- **资源受限**: 使用低内存安装优化资源使用

### 安全建议
- **定期更新**: 定期更新系统和依赖
- **备份策略**: 定期备份配置和数据
- **监控告警**: 配置监控和告警系统
- **访问控制**: 严格控制用户访问权限

### 性能建议
- **资源监控**: 定期监控系统资源使用
- **优化配置**: 根据负载调整配置参数
- **缓存策略**: 合理配置缓存策略
- **负载均衡**: 高负载时使用负载均衡

## 📞 技术支持

### 文档资源
- **安装指南**: 详细的安装说明
- **API文档**: 完整的API参考
- **故障排除**: 常见问题解决方案
- **最佳实践**: 部署和运维建议

### 社区支持
- **GitHub Issues**: 问题报告和功能请求
- **讨论区**: 技术讨论和经验分享
- **Wiki**: 社区维护的文档
- **示例**: 配置示例和用例

### 商业支持
- **技术支持**: 专业的技术支持服务
- **定制开发**: 定制功能开发
- **培训服务**: 系统使用培训
- **咨询服务**: 架构设计咨询

---

**注意**: 本文档会随着系统功能的更新而持续更新，请关注最新版本。
