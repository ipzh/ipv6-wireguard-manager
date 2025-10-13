# IPv6 WireGuard Manager 快速开始指南

## 🚀 快速部署

### 一键安装

```bash
# 一键安装脚本（推荐）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 或使用完整安装脚本
./install-complete.sh
```

### 安装选项

支持多种安装方式：

```bash
# Docker安装
./install-complete.sh docker

# 原生安装
./install-complete.sh native

# 低内存安装
./install-complete.sh low-memory
```

### 安装验证

安装完成后，验证服务状态：

```bash
# 检查服务状态
systemctl status ipv6-wireguard-manager

# 查看服务日志
journalctl -u ipv6-wireguard-manager -f

# 健康检查
curl http://localhost:8000/api/v1/health
```

### 步骤3：访问系统
- 浏览器访问: `http://your-server-ip:8000`
- 默认账号: `admin` / `admin123`

登录后即可开始配置和管理网络服务。

## 🎯 核心功能

### BGP会话管理
- 创建和配置BGP会话
- 实时监控会话状态
- 路由宣告控制

### IPv6前缀池管理
- 创建前缀池并分配前缀
- 自动BGP宣告
- 智能前缀分配

### WireGuard管理
- 创建VPN服务器和客户端
- 密钥管理和配置导出
- 实时连接监控

## 🔧 配置场景

### 企业VPN部署
- 创建WireGuard服务器和客户端
- 配置路由和防火墙规则
- 测试连接状态

### BGP路由管理
- 创建BGP会话
- 配置路由宣告
- 监控连接状态

### IPv6前缀分配
- 创建前缀池
- 配置白名单规则
- 为客户端分配前缀

## 📊 系统监控

- 实时状态监控
- 资源使用监控
- 网络流量统计
- 多级告警系统

## 🛠️ 故障排除

### 常见问题
- 无法访问系统：检查服务状态和端口
- BGP会话问题：检查网络连通性和防火墙
- WireGuard连接问题：检查服务器状态和配置

详细故障排除请参考[TROUBLESHOOTING.md](TROUBLESHOOTING.md)
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