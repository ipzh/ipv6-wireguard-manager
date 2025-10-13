# IPv6 WireGuard Manager 快速开始指南

## 🚀 5分钟快速部署

### 步骤1：环境准备
```bash
# 检查系统要求
uname -a
python3 --version
docker --version

# 检查性能优化参数
ulimit -n
cat /proc/sys/net/core/somaxconn
```

### 步骤2：一键安装
```bash
# 下载并执行安装脚本（性能优化版）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --performance

# 或者克隆项目手动安装
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager
./scripts/install.sh --performance
```

### 步骤2.5：性能优化配置（可选）
```bash
# 启用系统性能优化
sudo ./scripts/optimize-system.sh

# 配置数据库性能优化
sudo ./scripts/optimize-database.sh

# 配置缓存性能优化
sudo ./scripts/optimize-cache.sh
```

### 步骤3：验证部署和性能
```bash
# 健康检查验证
curl http://localhost:8000/api/v1/status/health

# 详细健康检查
curl http://localhost:8000/api/v1/status/health/detailed

# 性能指标检查
curl http://localhost:8000/api/v1/status/metrics

# Kubernetes就绪检查
curl http://localhost:8000/api/v1/status/ready

# Kubernetes存活检查
curl http://localhost:8000/api/v1/status/live
```

### 步骤4：访问系统
- 打开浏览器访问: `http://your-server-ip:8000`
- 使用默认账号登录:
  - 用户名: `admin`
  - 密码: `admin123`

### 3. 开始使用
登录后您将看到系统仪表板，可以开始配置和管理您的网络服务。

## 🎯 核心功能快速上手

### BGP会话管理
1. **创建BGP会话**
   - 点击左侧菜单 "BGP会话"
   - 点击 "新建会话" 按钮
   - 填写邻居信息（IP地址、AS号等）
   - 保存并启用会话

2. **监控会话状态**
   - 在会话列表中查看实时状态
   - 绿色表示已建立连接
   - 查看前缀收发统计

### IPv6前缀池管理
1. **创建前缀池**
   - 点击左侧菜单 "IPv6前缀池"
   - 点击 "新建前缀池" 按钮
   - 设置基础前缀（如：2001:db8::/48）
   - 配置分配参数

2. **分配前缀**
   - 在前缀池中点击 "分配前缀"
   - 选择分配对象（客户端或服务器）
   - 系统自动分配可用前缀

### WireGuard管理
1. **创建VPN服务器**
   - 点击左侧菜单 "服务器管理"
   - 点击 "新建服务器" 按钮
   - 配置网络参数（IP地址、端口等）
   - 系统自动生成密钥对

2. **添加客户端**
   - 点击左侧菜单 "客户端管理"
   - 点击 "新建客户端" 按钮
   - 选择所属服务器
   - 下载配置文件或扫描QR码

## 🔧 常见配置场景

### 场景1: 企业VPN部署
```bash
# 1. 创建WireGuard服务器
# 2. 为员工创建客户端
# 3. 配置路由和防火墙规则
# 4. 测试连接
```

### 场景2: BGP路由管理
```bash
# 1. 创建BGP会话
# 2. 配置路由宣告
# 3. 监控连接状态
# 4. 设置告警规则
```

### 场景3: IPv6前缀分配
```bash
# 1. 创建前缀池
# 2. 配置白名单规则
# 3. 为客户端分配前缀
# 4. 启用自动宣告
```

## 📊 系统监控

### 实时状态监控
- **仪表板**: 查看系统整体状态
- **服务状态**: 监控各服务运行情况
- **资源使用**: CPU、内存、磁盘使用率
- **网络流量**: 实时流量统计

### 告警设置
- **BGP会话断开**: 自动检测并告警
- **前缀池耗尽**: 容量不足时告警
- **系统资源**: 资源使用过高时告警
- **服务异常**: 服务停止时告警

## 🛠️ 故障排除

### 常见问题快速解决

#### 1. 无法访问系统
```bash
# 检查服务状态
systemctl status ipv6-wireguard-manager

# 重启服务
systemctl restart ipv6-wireguard-manager

# 检查端口
ss -tlnp | grep :80
```

#### 2. BGP会话无法建立
```bash
# 检查网络连通性
ping <neighbor-ip>

# 检查防火墙
ufw status

# 查看BGP日志
journalctl -u exabgp -f
```

#### 3. WireGuard客户端无法连接
```bash
# 检查服务器状态
wg show

# 检查配置文件
cat /etc/wireguard/wg0.conf

# 重启WireGuard
systemctl restart wg-quick@wg0
```

### 使用修复脚本
```bash
# 修复所有问题
./fix-installation-issues.sh all

# 修复特定问题
./fix-installation-issues.sh backend
./fix-installation-issues.sh frontend
./fix-installation-issues.sh database
```

## 📚 进阶配置

### 自定义配置
- **SSL证书**: 配置HTTPS访问
- **域名绑定**: 使用自定义域名
- **防火墙规则**: 自定义安全策略
- **备份策略**: 配置自动备份

### 性能优化
- **数据库优化**: 调整连接池参数
- **缓存配置**: 优化Redis缓存
- **负载均衡**: 配置多实例部署
- **监控告警**: 设置性能阈值

## 🔒 安全最佳实践

### 基础安全
- **修改默认密码**: 首次登录后立即修改
- **启用防火墙**: 配置必要的防火墙规则
- **定期更新**: 保持系统和依赖更新
- **备份数据**: 定期备份重要配置

### 高级安全
- **SSL/TLS**: 启用HTTPS加密
- **访问控制**: 配置IP白名单
- **审计日志**: 启用操作审计
- **入侵检测**: 配置安全监控

## 📞 获取帮助

### 文档资源
- [📖 完整安装指南](INSTALLATION_GUIDE.md)
- [🔧 详细功能文档](FEATURES_DETAILED.md)
- [👤 用户操作手册](USER_MANUAL.md)
- [🌐 API参考文档](API_REFERENCE.md)

### 社区支持
- **GitHub Issues**: 报告问题和功能请求
- **讨论区**: 技术讨论和经验分享
- **Wiki**: 社区维护的文档
- **示例**: 配置示例和最佳实践

### 快速链接
- [⭐ 给个Star](https://github.com/ipzh/ipv6-wireguard-manager)
- [🐛 报告Bug](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- [💡 功能请求](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- [💬 参与讨论](https://github.com/ipzh/ipv6-wireguard-manager/discussions)

## 🎉 下一步

现在您已经完成了快速开始，可以：

1. **探索功能**: 尝试各个功能模块
2. **阅读文档**: 深入了解系统功能
3. **配置服务**: 根据需求配置服务
4. **监控系统**: 设置监控和告警
5. **加入社区**: 参与讨论和贡献

---

**恭喜！** 您已经成功部署了IPv6 WireGuard Manager。开始享受强大的网络管理功能吧！

如有任何问题，请随时查看文档或联系社区获取帮助。