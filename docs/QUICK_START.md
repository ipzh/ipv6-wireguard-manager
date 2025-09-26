# IPv6 WireGuard Manager 快速启动指南

## 🚀 安装后立即启动

### 方法一：直接启动管理界面（推荐）
```bash
ipv6-wireguard-manager
```

### 方法二：启动系统服务
```bash
# 启动服务
sudo systemctl start ipv6-wireguard-manager

# 设置开机自启
sudo systemctl enable ipv6-wireguard-manager

# 查看服务状态
sudo systemctl status ipv6-wireguard-manager
```

## ⚙️ 基本管理命令

### 服务管理
```bash
# 启动服务
sudo systemctl start ipv6-wireguard-manager

# 停止服务
sudo systemctl stop ipv6-wireguard-manager

# 重启服务
sudo systemctl restart ipv6-wireguard-manager

# 查看服务状态
sudo systemctl status ipv6-wireguard-manager

# 查看服务日志
sudo journalctl -u ipv6-wireguard-manager -f
```

### 管理界面命令
```bash
# 启动管理界面
ipv6-wireguard-manager

# 查看帮助
ipv6-wireguard-manager --help

# 查看系统状态
ipv6-wireguard-manager --status

# 配置WireGuard
ipv6-wireguard-manager --configure-wireguard

# 配置BGP路由
ipv6-wireguard-manager --configure-bird

# 添加客户端
ipv6-wireguard-manager --add-client
```

## 🌐 Web管理界面

如果安装了Web管理界面，可以通过以下方式访问：

- **HTTP访问**: `http://服务器IP:8080`
- **HTTPS访问**: `https://服务器IP:8443`
- **本地访问**: `http://localhost:8080`

## 📋 配置文件位置

- **主配置文件**: `/etc/ipv6-wireguard-manager/manager.conf`
- **WireGuard配置**: `/etc/ipv6-wireguard-manager/wireguard/`
- **BIRD配置**: `/etc/ipv6-wireguard-manager/bird/`
- **日志文件**: `/var/log/ipv6-wireguard-manager/manager.log`

## 🔧 故障排除

### 查看详细日志
```bash
# 查看管理日志
sudo tail -f /var/log/ipv6-wireguard-manager/manager.log

# 查看系统服务日志
sudo journalctl -u ipv6-wireguard-manager -f

# 查看错误日志
sudo tail -f /var/log/ipv6-wireguard-manager/errors.log
```

### 常见问题解决
```bash
# 重启服务
sudo systemctl restart ipv6-wireguard-manager

# 重新配置
/opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh --reconfigure

# 检查端口占用
sudo netstat -tlnp | grep :8080
sudo netstat -tlnp | grep :51820
```

## 📝 下一步操作

1. **配置WireGuard服务器**
   ```bash
   ipv6-wireguard-manager --configure-wireguard
   ```

2. **配置BGP路由**
   ```bash
   ipv6-wireguard-manager --configure-bird
   ```

3. **添加客户端**
   ```bash
   ipv6-wireguard-manager --add-client
   ```

4. **查看系统状态**
   ```bash
   ipv6-wireguard-manager --status
   ```

## ⚠️ 重要提示

- 请根据需要修改配置文件中的默认设置
- 确保防火墙已正确配置相关端口
- 建议定期备份配置文件
- 首次使用前请阅读完整文档

## 📞 获取帮助

- **项目地址**: https://github.com/ipzh/ipv6-wireguard-manager
- **文档目录**: `/opt/ipv6-wireguard-manager/docs/`
- **问题反馈**: https://github.com/ipzh/ipv6-wireguard-manager/issues

## 🗑️ 卸载方法

如需卸载，请运行：
```bash
sudo /opt/ipv6-wireguard-manager/uninstall.sh
```

---

**感谢使用IPv6 WireGuard Manager！** 🎉
