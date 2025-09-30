# 安装指南

## 系统要求

### 最低要求
- **操作系统**: Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+, Windows (WSL), macOS
- **架构**: x86_64, ARM64
- **内存**: 512MB RAM
- **磁盘**: 1GB 可用空间
- **网络**: 支持IPv6

### 推荐配置
- **内存**: 1GB+ RAM
- **磁盘**: 2GB+ 可用空间
- **CPU**: 2核心+

## 安装方法

### 方法1: 一键安装 (推荐)

```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

### 方法2: 下载安装

```bash
wget -O install.sh https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

### 方法3: 克隆安装

```bash
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager
sudo ./install.sh
```

## 安装步骤

### 1. 系统检查

安装脚本会自动检查：
- 操作系统兼容性
- 必要依赖软件
- 网络连接状态
- 磁盘空间

### 2. 依赖安装

自动安装以下软件：
- WireGuard
- BIRD (BGP路由)
- Nginx
- SQLite3
- Python 3.6+

### 3. 配置生成

自动生成：
- WireGuard配置
- BGP路由配置
- Web服务器配置
- 系统服务配置

### 4. 服务启动

自动启动：
- WireGuard服务
- BGP路由服务
- Web服务器
- 监控服务

## 安装后配置

### 1. 访问Web界面

```
http://your-server-ip:8080
```

默认登录：
- 用户名: `admin`
- 密码: `admin123`

### 2. 修改默认密码

```bash
sudo ./ipv6-wireguard-manager.sh --change-password
```

### 3. 配置IPv6网络

编辑配置文件：
```bash
sudo nano /etc/ipv6-wireguard-manager/manager.conf
```

主要配置项：
```bash
# IPv6配置
IPV6_PREFIX=2001:db8::/64
IPV6_GATEWAY=2001:db8::1

# WireGuard配置
WIREGUARD_PORT=51820
WIREGUARD_PRIVATE_KEY=your-private-key

# BGP配置
BGP_ENABLED=true
BGP_AS=65001
BGP_ROUTER_ID=192.168.1.1
```

### 4. 重启服务

```bash
sudo ./ipv6-wireguard-manager.sh --restart
```

## 验证安装

### 1. 检查服务状态

```bash
# WireGuard状态
sudo wg show

# BGP状态
sudo birdc show protocols

# Web服务状态
sudo systemctl status nginx
```

### 2. 测试连接

```bash
# 测试IPv6连接
ping6 2001:db8::1

# 测试Web界面
curl http://localhost:8080
```

### 3. 查看日志

```bash
# 主日志
sudo tail -f /var/log/ipv6-wireguard-manager/manager.log

# 错误日志
sudo tail -f /var/log/ipv6-wireguard-manager/error.log
```

## 故障排除

### 常见问题

1. **权限错误**
   ```bash
   sudo chown -R root:root /etc/ipv6-wireguard-manager
   sudo chmod -R 755 /etc/ipv6-wireguard-manager
   ```

2. **端口冲突**
   ```bash
   # 检查端口占用
   sudo netstat -tulpn | grep :51820
   sudo netstat -tulpn | grep :8080
   ```

3. **IPv6配置问题**
   ```bash
   # 检查IPv6支持
   cat /proc/net/if_inet6
   
   # 启用IPv6转发
   echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
   sysctl -p
   ```

### 重新安装

```bash
# 完全卸载
sudo ./uninstall.sh

# 清理残留文件
sudo rm -rf /etc/ipv6-wireguard-manager
sudo rm -rf /var/log/ipv6-wireguard-manager

# 重新安装
sudo ./install.sh
```

## 安全建议

1. **修改默认密码**
2. **配置防火墙规则**
3. **启用SSL/TLS**
4. **定期更新系统**
5. **备份配置文件**

## 卸载

### 完全卸载

```bash
sudo ./uninstall.sh
```

### 保留配置

```bash
sudo ./uninstall.sh --keep-config
```

卸载后手动清理：
```bash
sudo rm -rf /etc/ipv6-wireguard-manager
sudo rm -rf /var/log/ipv6-wireguard-manager
sudo rm -rf /opt/ipv6-wireguard-manager
```