# IPv6 WireGuard Manager - 快速开始指南

## 🚀 快速安装

### 一键安装 (推荐)
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

### 其他安装方式
```bash
# 下载安装
wget -O install.sh https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh
chmod +x install.sh
sudo ./install.sh

# 克隆安装
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager
sudo ./install.sh

# Docker安装
docker-compose up -d
```

## 🎯 基本使用

### 启动管理程序
```bash
sudo ipv6-wireguard-manager
```

### 主要功能菜单
1. **快速安装** - 一键配置所有服务
2. **交互式安装** - 自定义配置安装
3. **服务器管理** - 服务状态管理
4. **客户端管理** - 客户端配置管理
5. **客户端自动安装** - 生成安装链接
6. **Web管理界面** - 启动Web管理界面
7. **网络配置** - IPv6前缀和BGP配置
8. **BGP配置管理** - BGP路由配置
9. **防火墙管理** - 防火墙规则管理
10. **配置备份/恢复** - 配置备份和恢复

## 🔧 核心配置

### 1. WireGuard配置
- 自动生成服务器密钥
- 配置客户端连接
- 管理客户端权限

### 2. IPv6网络配置
- 设置IPv6前缀
- 配置子网分配
- 管理路由表

### 3. BGP配置
- 配置BGP邻居
- 设置路由策略
- 监控路由状态

### 4. 防火墙配置
- 自动配置防火墙规则
- 管理端口访问
- 安全策略设置

## 📊 监控和管理

### 系统监控
- CPU、内存、磁盘使用率
- 网络流量统计
- 系统负载监控

### 客户端管理
- 客户端注册和认证
- 配置自动生成
- 状态监控和管理

### Web界面
- 访问地址: `http://your-server:8080`
- 默认用户名: `admin`
- 默认密码: `admin123`

## 🛠️ 高级功能

### 性能优化
- 模块懒加载
- 配置缓存
- 并行处理

### 安全增强
- 权限管理
- 安全审计
- 漏洞扫描

### 自动化测试
```bash
# 运行测试套件
bash test_optimizations.sh

# 权限测试
bash test_root_permission.sh

# 全面测试
bash comprehensive_test_suite.sh
```

## 🔍 故障排除

### 常见问题
1. **权限问题**: 确保以root权限运行
2. **端口冲突**: 检查端口占用情况
3. **网络问题**: 验证IPv6网络配置
4. **依赖问题**: 检查系统依赖安装

### 日志查看
```bash
# 查看主日志
tail -f /var/log/ipv6-wireguard-manager/manager.log

# 查看系统日志
journalctl -u ipv6-wireguard-manager
```

### 系统诊断
```bash
# 运行系统自检
sudo ipv6-wireguard-manager
# 选择 "21. 系统自检"
```

## 📚 更多文档

- [功能特性总览](FEATURES_OVERVIEW.md) - 详细功能说明
- [安装指南](docs/INSTALLATION.md) - 详细安装说明
- [使用手册](docs/USAGE.md) - 完整使用指南
- [API文档](docs/API.md) - API接口文档
 - [测试指南](docs/TESTING.md) - 测试说明

## 🆘 获取帮助

- **GitHub Issues**: [提交问题](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- **文档**: 查看项目文档
- **测试**: 运行测试套件诊断问题

---

*快速开始指南 - 2025-09-30*
