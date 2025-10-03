# IPv6 WireGuard Manager 高级用户指南

## 📚 目录

1. [快速开始](#快速开始)
2. [高级配置](#高级配置)
3. [性能优化](#性能优化)
4. [安全最佳实践](#安全最佳实践)
5. [监控和告警](#监控和告警)
6. [故障排除](#故障排除)
7. [扩展功能](#扩展功能)

## 🚀 快速开始

### 自动化部署（推荐）

使用我们新开发的部署向导，可以快速完成整个系统的配置和部署：

```bash
# 启动交互式部署向导
sudo bash modules/deployment_wizard.sh
```

部署向导将会：
- ✅ 自动检测系统环境
- ✅ 收集配置信息
- ✅ 验证设置有效性
- ✅ 执行自动化安装
- ✅ 生成部署报告

### 手动部署

如果您需要手动配置，请按照以下步骤：

#### 1. 系统环境准备

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装依赖
sudo apt install -y wireguard-tools curl wget iptables nginx

# 启用IP转发
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

#### 2. WireGuard服务器配置

```bash
# 生成服务器密钥
sudo wg genkey | sudo tee /etc/wireguard/server_private_key | sudo wg pubkey > /etc/wireguard/server_public_key

# 配置服务器接口
sudo cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $(sudo cat /etc/wireguard/server_private_key)
Address = 10.0.0.1/24, 2001:db8::1/64
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF
```

#### 3. 启动服务

```bash
# 启用并启动WireGuard
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

# 验证状态
sudo wg show
```

## ⚙️ 高级配置

### 1. IPv6配置优化

#### 为客户端分配IPv6子网

```bash
# 为主机分配更大的子网（例如 /48）
sudo cat >> /etc/wireguard/wg0.conf << EOF
[Peer]
PublicKey = <client-public-key>
AllowedIPs = 10.0.1.0/24
AllowedIPs = 2001:db8:1::/64
EOF
```

#### BGP路由配置

```bash
# 安装BIRD BGP路由器
sudo apt install -y bird

# 配置BGP
sudo cat > /etc/bird/bird.conf << EOF
router id 192.168.1.1;
protocol device {}
protocol kernel {
    learn;
    scan time 10;
    export filter {
        if source = RTS_DEVICE then reject;
        accept;
    };
}
protocol bgp {
    local as 65001;
    neighbor 10.0.0.2 as 65002;
    import filter {
        accept;
    };
    export filter {
        accept;
    };
}
EOF

sudo systemctl start bird
```

### 2. 缓存系统配置

我们新实现的智能缓存系统可以通过环境变量进行配置：

```bash
# 导出缓存配置
export IPV6WGM_CACHE_ENABLED=true
export IPV6WGM_CACHE_TTL=600
export IPV6WGM_CACHE_MAX_SIZE=500
export IPV6WGM_CACHE_STRATEGY=aggressive

# 启动缓存预热
bash modules/enhanced_cache_system.sh
```

### 3. 并行处理配置

```bash
# 配置并行处理
export IPV6WGM_PARALLEL_ENABLED=true
export IPV6WGM_MAX_PARALLEL_JOBS=8
export PARALLEL_PROCS=4  # GNU parallel作业数

# 批量处理客户端
CLIENTS=("client1" "client2" "client3")
bash -c 'source modules/parallel_processor.sh && parallel_process_clients "${@}"' "${CLIENTS[@]}"
```

## ⚡ 性能优化

### 1. 内存优化建议

使用我们的内存优化器模块：

```bash
# 启动内存监控
bash modules/memory_optimizer.sh
start_memory_monitor

# 设置内存限制
export IPV6WGM_MEMORY_LIMIT=1073741824  # 1GB

# 定期内存清理
crontab -e
# 添加: */30 * * * * /opt/ipv6-wireguard-manager/modules/memory_optimizer.sh
```

### 2. 启动时间优化

通过优化后的懒加载机制：

```bash
# 启用模块懒加载
export IPV6WGM_LAZY_LOADING=true

# 仅加载核心模块
export IPV6WGM_CORE_MODULES="common_functions,wireguard_config"
```

### 3. 网络性能调优

```bash
# WireGuard性能优化
sudo cat >> /etc/wireguard/wg0.conf << EOF
# 性能优化
MTU = 1420
Table = off
SaveConfig = false
EOF

# 内核参数优化
sudo cat >> /etc/sysctl.conf << EOF
# 网络性能优化
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 65535
net.ipv4.tcp_congestion_control = bbr
EOF

sudo sysctl -p
```

## 🔒 安全最佳实践

### 1. 安全配置管理

```bash
# 使用我们的安全配置加载器
source modules/secure_config_loader.sh

# 验证配置安全
validate_config_security

# 自动修复安全问题
auto_fix_config_security
```

### 2. 密钥管理

```bash
# 生成高强度密钥
generate_wireguard_key_pair() {
    local private_key=$(wg genkey)
    local public_key=$(echo "$private_key" | wg pubkey)
    
    # 安全存储私钥
    echo "$private_key" | sudo tee "/etc/wireguard/keys/client_private_key_$(date +%s)"
    
    # 显示公钥（用于客户端配置）
    echo "公钥: $public_key"
}

# 定期轮换密钥
setup_key_rotation() {
    # 每30天轮换服务器密钥
    0 2 1 * * /opt/ipv6-wireguard-manager/scripts/rotate_keys.sh
}
```

### 3. 访问控制

```bash
# 基于IP的访问控制
iptables -A INPUT -p tcp --dport 51820 -s 192.168.1.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 51820 -j DROP

# Web管理访问控制
nginx -s reload
password_protect_admin() {
    sudo htpasswd -c /etc/nginx/.htpasswd admin
}
```

## 📊 监控和告警

### 1. 系统监控

使用我们新的监控模块：

```bash
# 启动系统监控
source modules/system_monitoring.sh
start_system_monitoring

# 设置监控阈值
export MEMORY_THRESHOLD=80
export CPU_THRESHOLD=85
export DISK_THRESHOLD=90
```

### 2. WireGuard连接监控

```bash
# 监控连接状态
monitor_wireguard_connections() {
    while true; do
        PEER_COUNT=$(wg show wg0 peers | wc -l)
        echo "[$(date)] Active peers: $PEER_COUNT"
        
        # 检查异常连接
        wg show wg0 peers | while read -r peer; do
            # 分析最新握手时间
            LAST_HANDSHAKE=$(echo "$peer" | awk '{print $(NF-1)}')
            # 如果超过5分钟未握手，发送告警
        done
        
        sleep 60
    done
}

monitor_wireguard_connections &
```

### 3. 告警配置

```bash
# 配置邮件告警
cat > ~/.alerts.conf << EOF
[email]
smtp_server = smtp.gmail.com
smtp_port = 587
auth_user = your-email@gmail.com
auth_password = your-app-password
alert_recipients = admin@yourdomain.com

[thresholds]
memory_threshold = 85
disk_threshold = 90
peer_timeout = 300
EOF

# 测试告警
source modules/monitoring_alerting.sh
send_email_alert "测试告警" "这是一个测试告警消息"
```

## 🔧 故障排除

### 1. 常见问题诊断

使用我们新的故障诊断工具：

```bash
# 运行全面诊断
bash modules/self_diagnosis.sh

# 检查特定组件
diagnose_wireguard() {
    echo "=== WireGuard诊断 ==="
    systemctl status wg-quick@wg0
    wg show
    ip link show wg0
    iptables -L -n
}
```

### 2. 日志分析

```bash
# 查看详细日志
tail -f /var/log/ipv6-wireguard-manager/manager.log

# 分析错误日志
grep ERROR /var/log/ipv6-wireguard-manager/error.log | tail -20

# 查看连接日志
journalctl -u wg-quick@wg0 -f
```

### 3. 性能分析

```bash
# 运行性能基准测试
bash modules/performance_benchmark.sh

# 查看性能报告
ls /var/log/ipv6-wireguard-manager/performance_*

# 网络性能测试
iperf3 -s &  # 在服务器运行
# 客户端: iperf3 -c <server-ip> -t 30
```

## 🚀 扩展功能

### 1. API集成

我们的系统支持完整的REST API：

```bash
# 获取API文档
bash modules/api_doc_generator.sh

# 测试API功能
curl -X GET "http://localhost:8080/api/status" | jq

# 通过API添加客户端
curl -X POST "http://localhost:8080/api/clients" \
  -H "Content-Type: application/json" \
  -d '{"name":"client1","ip":"10.0.1.2"}'
```

### 2. 自动化脚本

```bash
# 批量添加客户端
CLIENTS_FILE="/tmp/clients.csv"
cat > "$CLIENTS_FILE" << EOF
name,ipv4,ipv6
client1,10.0.1.2,2001:db8:1::2
client2,10.0.1.3,2001:db8:1::3
EOF

# 使用我们的处理脚本
bash modules/bulk_client_manager.sh "$CLIENTS_FILE"
```

### 3. 自定义模块开发

您可以根据我们的模块标准开发自定义功能：

```bash
# 创建自定义模块
cat > modules/my_custom_feature.sh << 'EOF'
#!/bin/bash

# 导入必要模块
source modules/common_functions.sh

# 自定义功能
my_custom_function() {
    log_info "执行自定义功能..."
    # 您的代码
}

# 导出函数
export -f my_custom_function

log_success "自定义模块加载完成"
EOF

# 在主脚本中注册
echo "modules/unified_module_loader.sh my_custom_feature" >> modules/module_dependencies.conf
```

## 📱 移动端管理

我们提供了现代化的Web界面，支持移动端访问：

- 📱 响应式设计，完美适配手机和平板
- 🔄 实时状态更新
- 📊 直观的仪表板
- 🎛️ 触摸友好的控制界面

访问 `http://your-server:8080` 即可使用。

## 🛠️ 开发人员友好

### 1. 调试模式

```bash
# 启用调试模式
export IPV6WGM_DEBUG_MODE=true

# 详细日志
tail -f /var/log/ipv6-wireguard-manager/debug.log
```

### 2. 配置热重载

```bash
# 修改配置后无需重启
echo "配置变更..." >> /etc/wireguard/wg0.conf
# 系统自动检测并应用变更
```

### 3. 测试框架

```bash
# 运行单元测试
bash modules/comprehensive_test_suite.sh

# 运行性能测试
bash modules/performance_benchmark.sh

# 生成测试报告
open /var/log/ipv6-wireguard-manager/test_report_*.html
```

## 🎯 最佳实践总结

1. **安全第一**: 始终使用最新版本，定期轮换密钥
2. **监控先行**: 设置全面的监控和告警
3. **备份重要**: 自动备份配置文件和数据
4. **文档更新**: 记录所有自定义配置
5. **定期维护**: 执行系统更新和性能优化
6. **测试验证**: 在生产环境部署前充分测试

---

**需要帮助？**

- 📖 查看完整的API文档: `bash modules/api_doc_generator.sh`
- 🔧 运行部署向导: `bash modules/deployment_wizard.sh`
- 📋 生成测试报告: `bash modules/comprehensive_test_suite.sh`
- 🏥 系统健康检查: `bash modules/self_diagnosis.sh`

*最后更新: 2024年12月*
