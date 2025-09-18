# WireGuard 服务启动失败修复指南

## 问题描述

当运行 `ipv6-wg-manager` 时，可能会遇到以下错误：

```
Created symlink /etc/systemd/system/multi-user.target.wants/wg-quick@wg0.service → /lib/systemd/system/wg-quick@.service.
Job for wg-quick@wg0.service failed because the control process exited with error code.
See "systemctl status wg-quick@wg0.service" and "journalctl -xeu wg-quick@wg0.service" for details.
[2025-09-17 05:25:44] [ERROR] Failed to start WireGuard service
[2025-09-17 05:25:44] [ERROR] WireGuard service startup failed
```

### 具体错误示例

查看详细日志时，可能会看到：

```
Sep 17 05:25:44 VM117 wg-quick[2508]: [#] wg setconf wg0 /dev/fd/63
Sep 17 05:25:44 VM117 wg-quick[2508]: [#] ip -4 address add 10.0.0.1/24 dev wg0
Sep 17 05:25:44 VM117 wg-quick[2508]: [#] ip -6 address add 2001:db8::::1/64 dev wg0
Sep 17 05:25:44 VM117 wg-quick[2532]: Error: inet6 prefix is expected rather than "2001:db8::::1/64".
Sep 17 05:25:44 VM117 wg-quick[2508]: [#] ip link delete dev wg0
Sep 17 05:25:44 VM117 systemd[1]: wg-quick@wg0.service: Main process exited, code=exited, status=1/FAILURE
```

**问题原因**：IPv6 地址格式错误，`2001:db8::::1/64` 中有过多的冒号，正确的格式应该是 `2001:db8::1/64`。

## 快速修复（推荐）

### 方法1：使用自动修复脚本

```bash
# 运行 WireGuard 服务修复脚本
sudo ./fix_wireguard_service.sh

# 运行 IPv6 配置修复脚本
sudo ./fix_ipv6_config.sh
```

### 方法2：使用项目内置诊断

```bash
# 运行主管理器，选择诊断选项
ipv6-wg-manager
# 选择：3. 服务器管理 -> 诊断 WireGuard 服务
```

## 手动修复步骤

### 1. 检查服务状态

```bash
# 查看详细错误信息
sudo systemctl status wg-quick@wg0.service

# 查看系统日志
sudo journalctl -xeu wg-quick@wg0.service
```

### 2. 检查配置文件

```bash
# 查看配置文件
sudo cat /etc/wireguard/wg0.conf

# 检查配置文件语法
sudo wg-quick strip wg0
```

### 3. 修复常见问题

#### 权限问题
```bash
sudo chmod 600 /etc/wireguard/wg0.conf
sudo chown root:root /etc/wireguard/wg0.conf
```

#### IPv6 配置问题
```bash
# 启用 IPv6
echo 0 | sudo tee /proc/sys/net/ipv6/conf/all/disable_ipv6

# 启用 IPv6 转发
echo 1 | sudo tee /proc/sys/net/ipv6/conf/all/forwarding
echo 1 | sudo tee /proc/sys/net/ipv6/conf/default/forwarding
```

#### WireGuard 模块问题
```bash
# 加载 WireGuard 模块
sudo modprobe wireguard

# 检查模块是否加载
lsmod | grep wireguard
```

#### 端口占用问题
```bash
# 检查端口占用
sudo netstat -tulpn | grep 51820

# 如果端口被占用，停止占用进程
sudo kill -9 <PID>
```

#### 防火墙问题
```bash
# UFW 防火墙
sudo ufw allow 51820/udp
sudo ufw reload

# Firewalld 防火墙
sudo firewall-cmd --permanent --add-port=51820/udp
sudo firewall-cmd --reload

# iptables 防火墙
sudo iptables -A INPUT -p udp --dport 51820 -j ACCEPT
sudo ip6tables -A INPUT -p udp --dport 51820 -j ACCEPT
```

### 4. 重新启动服务

```bash
# 停止服务
sudo systemctl stop wg-quick@wg0

# 启动服务
sudo systemctl start wg-quick@wg0

# 检查状态
sudo systemctl status wg-quick@wg0.service
sudo wg show
```

## 常见错误及解决方案

### 错误1：配置文件语法错误
**症状**：`wg-quick strip wg0` 报错
**解决**：重新生成配置文件
```bash
ipv6-wg-manager
# 选择：3. 服务器管理 -> 重新配置 WireGuard
```

### 错误2：IPv6 未启用
**症状**：IPv6 相关配置失败
**解决**：启用 IPv6 支持
```bash
sudo ./fix_ipv6_config.sh
```

### 错误3：权限不足
**症状**：无法访问配置文件
**解决**：修复文件权限
```bash
sudo chmod 600 /etc/wireguard/wg0.conf
sudo chown root:root /etc/wireguard/wg0.conf
```

### 错误4：端口被占用
**症状**：端口 51820 已被使用
**解决**：停止占用进程或更改端口
```bash
# 查找占用进程
sudo lsof -i :51820

# 停止进程
sudo kill -9 <PID>

# 或更改 WireGuard 端口
sudo nano /etc/wireguard/wg0.conf
# 修改 ListenPort = 51821
```

### 错误5：WireGuard 模块未加载
**症状**：内核模块相关错误
**解决**：加载 WireGuard 模块
```bash
sudo modprobe wireguard
echo "wireguard" | sudo tee -a /etc/modules
```

## 预防措施

### 1. 系统配置
```bash
# 创建持久化 IPv6 配置
sudo tee /etc/sysctl.d/99-ipv6-wireguard.conf << EOF
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
EOF

# 应用配置
sudo sysctl -p /etc/sysctl.d/99-ipv6-wireguard.conf
```

### 2. 防火墙配置
```bash
# 确保防火墙规则正确
sudo ufw allow 51820/udp
sudo ufw allow ssh
sudo ufw reload
```

### 3. 定期检查
```bash
# 定期检查服务状态
sudo systemctl status wg-quick@wg0.service

# 检查 WireGuard 接口
sudo wg show

# 检查 IPv6 配置
ip -6 addr show
```

## 技术支持

如果以上方法都无法解决问题，请：

1. 收集详细的错误信息：
   ```bash
   sudo systemctl status wg-quick@wg0.service -l
   sudo journalctl -xeu wg-quick@wg0.service --no-pager
   ```

2. 检查系统信息：
   ```bash
   uname -a
   cat /etc/os-release
   ip -6 addr show
   ```

3. 联系技术支持并提供上述信息。

## 相关文件

- `fix_wireguard_service.sh` - WireGuard 服务自动修复脚本
- `fix_ipv6_config.sh` - IPv6 配置自动修复脚本
- `/etc/wireguard/wg0.conf` - WireGuard 配置文件
- `/etc/sysctl.d/99-ipv6-wireguard.conf` - IPv6 持久化配置
