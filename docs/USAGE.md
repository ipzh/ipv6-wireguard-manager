# 使用指南

## 基本操作

### 启动管理界面

```bash
sudo ./ipv6-wireguard-manager.sh
```

### 命令行选项

```bash
# 查看帮助
./ipv6-wireguard-manager.sh --help

# 查看状态
./ipv6-wireguard-manager.sh --status

# 重启服务
./ipv6-wireguard-manager.sh --restart

# 查看日志
./ipv6-wireguard-manager.sh --logs

# 查看版本
./ipv6-wireguard-manager.sh --version
```

## 客户端管理

### 添加客户端

```bash
# 交互式添加
sudo ./ipv6-wireguard-manager.sh --add-client

# 命令行添加
sudo ./ipv6-wireguard-manager.sh --add-client client1 2001:db8::2
```

### 管理客户端

```bash
# 列出所有客户端
sudo ./ipv6-wireguard-manager.sh --list-clients

# 生成客户端配置
sudo ./ipv6-wireguard-manager.sh --gen-config client1

# 下载客户端配置
sudo ./ipv6-wireguard-manager.sh --download-config client1

# 删除客户端
sudo ./ipv6-wireguard-manager.sh --del-client client1

# 禁用客户端
sudo ./ipv6-wireguard-manager.sh --disable-client client1

# 启用客户端
sudo ./ipv6-wireguard-manager.sh --enable-client client1
```

### 批量管理

```bash
# 从CSV文件导入客户端
sudo ./ipv6-wireguard-manager.sh --import-clients clients.csv

# 导出客户端列表
sudo ./ipv6-wireguard-manager.sh --export-clients clients.csv

# 批量生成配置
sudo ./ipv6-wireguard-manager.sh --batch-gen-config
```

## 网络配置

### IPv6配置

```bash
# 查看IPv6配置
sudo ./ipv6-wireguard-manager.sh --show-ipv6-config

# 更新IPv6前缀
sudo ./ipv6-wireguard-manager.sh --update-ipv6-prefix 2001:db8::/64

# 添加IPv6路由
sudo ./ipv6-wireguard-manager.sh --add-route 2001:db8:1::/64
```

### BGP配置

```bash
# 查看BGP状态
sudo ./ipv6-wireguard-manager.sh --bgp-status

# 添加BGP邻居
sudo ./ipv6-wireguard-manager.sh --add-bgp-neighbor 2001:db8::100 65000

# 删除BGP邻居
sudo ./ipv6-wireguard-manager.sh --del-bgp-neighbor 2001:db8::100

# 查看BGP路由
sudo ./ipv6-wireguard-manager.sh --bgp-routes
```

## 系统管理

### 服务管理

```bash
# 启动所有服务
sudo ./ipv6-wireguard-manager.sh --start

# 停止所有服务
sudo ./ipv6-wireguard-manager.sh --stop

# 重启特定服务
sudo ./ipv6-wireguard-manager.sh --restart-service wireguard
sudo ./ipv6-wireguard-manager.sh --restart-service bird
sudo ./ipv6-wireguard-manager.sh --restart-service nginx
```

### 配置管理

```bash
# 备份配置
sudo ./ipv6-wireguard-manager.sh --backup-config

# 恢复配置
sudo ./ipv6-wireguard-manager.sh --restore-config backup.tar.gz

# 重置配置
sudo ./ipv6-wireguard-manager.sh --reset-config

# 验证配置
sudo ./ipv6-wireguard-manager.sh --validate-config
```

### 监控和诊断

```bash
# 系统监控
sudo ./ipv6-wireguard-manager.sh --monitor

# 资源使用情况
sudo ./ipv6-wireguard-manager.sh --resources

# 网络诊断
sudo ./ipv6-wireguard-manager.sh --network-diagnosis

# 性能测试
sudo ./ipv6-wireguard-manager.sh --performance-test

# 健康检查
sudo ./ipv6-wireguard-manager.sh --health-check
```

## Web界面使用

### 登录

1. 打开浏览器访问 `http://your-server:8080`
2. 使用默认账号登录：
   - 用户名: `admin`
   - 密码: `admin123`
3. 首次登录后立即修改密码

### 主要功能

#### 仪表板
- 系统状态概览
- 客户端连接统计
- 网络流量图表
- 资源使用情况

#### 客户端管理
- 添加/删除客户端
- 生成/下载配置
- 查看连接状态
- 管理客户端权限

#### 网络配置
- IPv6网络设置
- BGP路由配置
- 防火墙规则
- 网络拓扑图

#### 系统监控
- 实时资源监控
- 日志查看
- 告警设置
- 性能分析

#### 系统设置
- 基本配置
- 安全设置
- 备份恢复
- 更新管理

## 高级功能

### 自动化脚本

```bash
#!/bin/bash
# 自动添加客户端脚本

CLIENT_NAME="client_$(date +%s)"
IPV6_ADDR="2001:db8::$(shuf -i 2-254 -n 1)"

sudo ./ipv6-wireguard-manager.sh --add-client "$CLIENT_NAME" "$IPV6_ADDR"
sudo ./ipv6-wireguard-manager.sh --gen-config "$CLIENT_NAME"
```

### 监控脚本

```bash
#!/bin/bash
# 监控脚本

# 检查服务状态
if ! systemctl is-active --quiet wg-quick@wg0; then
    echo "WireGuard服务异常，正在重启..."
    sudo systemctl restart wg-quick@wg0
fi

# 检查BGP状态
if ! birdc show protocols | grep -q "Established"; then
    echo "BGP连接异常，正在重启..."
    sudo systemctl restart bird
fi
```

### 备份脚本

```bash
#!/bin/bash
# 自动备份脚本

BACKUP_DIR="/backup/ipv6-wireguard-manager"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 备份配置
sudo ./ipv6-wireguard-manager.sh --backup-config
mv /tmp/ipv6-wireguard-manager-backup.tar.gz "$BACKUP_DIR/config_$DATE.tar.gz"

# 备份数据库
cp /etc/ipv6-wireguard-manager/database.db "$BACKUP_DIR/database_$DATE.db"

# 清理旧备份（保留7天）
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
find "$BACKUP_DIR" -name "*.db" -mtime +7 -delete
```

## 故障排除

### 常见问题

1. **客户端无法连接**
   ```bash
   # 检查WireGuard状态
   sudo wg show
   
   # 检查防火墙规则
   sudo iptables -L
   sudo ip6tables -L
   
   # 检查网络配置
   ip addr show wg0
   ```

2. **BGP路由不工作**
   ```bash
   # 检查BIRD状态
   sudo birdc show protocols
   
   # 检查BGP邻居
   sudo birdc show protocols all
   
   # 查看路由表
   sudo birdc show route
   ```

3. **Web界面无法访问**
   ```bash
   # 检查Nginx状态
   sudo systemctl status nginx
   
   # 检查端口监听
   sudo netstat -tulpn | grep :8080
   
   # 检查防火墙
   sudo ufw status
   ```

### 日志分析

```bash
# 查看主日志
sudo tail -f /var/log/ipv6-wireguard-manager/manager.log

# 查看错误日志
sudo tail -f /var/log/ipv6-wireguard-manager/error.log

# 查看WireGuard日志
sudo journalctl -u wg-quick@wg0 -f

# 查看BIRD日志
sudo journalctl -u bird -f

# 查看Nginx日志
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 性能优化

```bash
# 优化WireGuard性能
echo 'net.core.rmem_max = 134217728' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 134217728' >> /etc/sysctl.conf
sysctl -p

# 优化BGP性能
# 编辑 /etc/bird/bird.conf
# 调整 BGP 参数

# 优化Nginx性能
# 编辑 /etc/nginx/nginx.conf
# 调整 worker_processes 和 worker_connections
```

## 安全建议

1. **修改默认密码**
2. **启用SSL/TLS**
3. **配置防火墙**
4. **定期更新**
5. **监控日志**
6. **备份配置**
7. **限制访问**
8. **使用强密钥**