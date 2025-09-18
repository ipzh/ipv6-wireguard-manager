# IPv6 WireGuard Manager - 安装指南

## 概述

本指南将帮助您在Linux系统上安装和配置IPv6 WireGuard Manager。该工具支持IPv6前缀分发和BGP路由，提供完整的VPN服务器管理功能。

## 系统要求

### 支持的操作系统

- **Ubuntu** 18.04+
- **Debian** 9+
- **CentOS** 7+
- **RHEL** 7+
- **Fedora** 30+
- **Rocky Linux** 8+
- **AlmaLinux** 8+
- **Arch Linux** 最新

### 硬件要求

#### 最低要求
- CPU: 1核心
- 内存: 512MB
- 磁盘: 1GB可用空间
- 网络: 公网IPv4地址
- BIRD: 1.x或2.x版本（自动安装）

#### 推荐配置
- CPU: 2核心或更多
- 内存: 1GB或更多
- 磁盘: 5GB可用空间
- 网络: 公网IPv4地址 + IPv6地址
- BIRD: 2.x版本（默认安装，性能更佳）

### 网络要求

- **公网IPv4地址**: 必需，用于客户端连接
- **IPv6地址**: 可选，用于IPv6前缀分发
- **开放端口**: WireGuard端口（默认51820/UDP）
- **防火墙**: 支持UFW、firewalld、nftables或iptables

## 安装前准备

### 1. 系统更新

在安装前，建议先更新系统：

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL/Fedora/Rocky/AlmaLinux
sudo yum update -y
# 或
sudo dnf update -y

# Arch Linux
sudo pacman -Syu
```

### 2. 检查网络连接

确保服务器可以访问互联网：

```bash
ping -c 4 8.8.8.8
```

### 3. 检查IPv6支持

检查系统是否支持IPv6：

```bash
ip -6 addr show
```

### 4. 检查防火墙状态

检查当前防火墙状态：

```bash
# Ubuntu/Debian (UFW)
sudo ufw status

# CentOS/RHEL/Fedora/Rocky/AlmaLinux (firewalld)
sudo firewall-cmd --state

# 其他系统 (iptables)
sudo iptables -L
```

### 5. 检查端口占用

检查WireGuard默认端口是否被占用：

```bash
sudo netstat -tulpn | grep 51820
```

## BIRD版本说明

### 支持的BIRD版本

- **BIRD 2.x** (推荐) - 默认安装版本，提供更好的性能和功能
- **BIRD 1.x** (兼容) - 自动回退版本，确保在BIRD 2.x不可用时仍能正常工作

### 版本选择策略

1. 优先尝试安装BIRD 2.x (`bird2`包)
2. 如果BIRD 2.x不可用，自动安装BIRD 1.x (`bird`包)
3. 支持所有主要Linux发行版

### 手动检查BIRD版本

```bash
# 检查BIRD 2.x
which birdc2
birdc2 --version

# 检查BIRD 1.x
which birdc
birdc --version
```

## 安装方法

### 方法1: 自动安装（推荐）

1. **下载安装脚本**：

```bash
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh
chmod +x install.sh
```

2. **运行安装脚本**：

```bash
sudo ./install.sh
```

安装脚本将自动：
- 检测系统环境
- 安装必要的依赖包
- 优先安装BIRD 2.x（如果可用）
- 创建必要的目录结构
- 设置符号链接
- 配置基本环境

### 方法2: 手动安装

如果自动安装失败，可以手动安装：

1. **安装依赖包**：

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y wireguard wireguard-tools bird2 iptables ufw curl wget

# CentOS/RHEL/Fedora/Rocky/AlmaLinux
sudo yum install -y epel-release
sudo yum install -y wireguard-tools bird2 iptables firewalld curl wget

# Arch Linux
sudo pacman -S wireguard-tools bird2 iptables ufw curl wget
```

2. **下载管理器脚本**：

```bash
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/ipv6-wireguard-manager-core.sh
chmod +x ipv6-wireguard-manager-core.sh
```

3. **创建符号链接**：

```bash
sudo ln -s $(pwd)/ipv6-wireguard-manager-core.sh /usr/local/bin/ipv6-wg-manager
sudo ln -s $(pwd)/ipv6-wireguard-manager-core.sh /usr/local/bin/wg-manager
```

## 运行方式

IPv6 WireGuard Manager 提供两种运行方式：

### 方式1: 模块化版本（推荐）
```bash
./ipv6-wireguard-manager-core.sh
```
- **特点**: 轻量级核心脚本，按需加载功能模块
- **优势**: 启动更快，内存占用更少，便于维护
- **适用**: 日常使用和开发环境

### 方式2: 完整版本
```bash
./ipv6-wireguard-manager.sh
```
- **特点**: 包含所有功能的完整脚本
- **优势**: 无需模块文件，单文件部署
- **适用**: 离线环境或简化部署

### 使用符号链接
```bash
# 使用完整命令
ipv6-wg-manager

# 或使用简写命令
wg-manager
```

**建议**: 推荐使用模块化版本，它提供了更好的性能和可维护性。

## 验证安装

### 1. 检查脚本权限

```bash
ls -la ipv6-wireguard-manager-core.sh
```

### 2. 检查模块文件

```bash
ls -la modules/
```

### 3. 检查符号链接

```bash
which ipv6-wg-manager
which wg-manager
```

### 4. 运行管理器

```bash
sudo ./ipv6-wireguard-manager-core.sh
```

如果看到主菜单，说明安装成功。

## 配置选项

### 1. 快速安装模式

- 使用默认配置
- 适合快速部署
- 最小用户交互

### 2. 交互式安装模式

- 完整配置向导
- 自定义所有参数
- 适合生产环境

## 故障排除

### 常见问题

1. **权限问题**
   ```bash
   sudo ./ipv6-wireguard-manager-core.sh
   ```

2. **BIRD服务未启动**
   ```bash
   # 检查BIRD版本
   systemctl status bird2  # BIRD 2.x
   systemctl status bird   # BIRD 1.x
   
   # 启动服务
   sudo systemctl start bird2  # BIRD 2.x
   sudo systemctl start bird   # BIRD 1.x
   ```

3. **防火墙问题**
   ```bash
   # 检查防火墙状态
   sudo ufw status          # Ubuntu/Debian
   sudo firewall-cmd --state # CentOS/RHEL/Fedora
   ```

4. **端口占用**
   ```bash
   # 检查端口占用
   sudo netstat -tulpn | grep 51820
   ```

5. **模块文件缺失**
   ```bash
   # 检查模块文件
   ls -la modules/
   
   # 重新安装
   sudo ./install.sh
   ```

6. **IPv6地址配置错误**
   - 问题：WireGuard接口使用子网段作为地址
   - 解决：管理器自动将子网段转换为正确的服务器地址
   - 验证：检查WireGuard配置中的Address行
   ```bash
   # 查看WireGuard配置
   sudo cat /etc/wireguard/wg0.conf | grep Address
   # 应该显示类似：Address = 10.0.0.1/24, 2001:db8::1/64
   # 而不是：Address = 10.0.0.1/24, 2001:db8::/48
   ```

7. **IPv6前缀管理功能缺失**
   - 问题：网络配置菜单中某些功能不可用
   - 解决：确保使用最新版本的管理器
   - 验证：检查网络管理模块是否完整
   ```bash
   # 检查网络管理模块
   grep -c "modify_ipv6_prefix\|remove_ipv6_prefix\|show_prefix_statistics" modules/network_management.sh
   # 应该返回 3
   ```

8. **客户端地址分配问题**
   - 问题：客户端地址分配不支持/56到/72的子网段
   - 解决：使用最新版本的管理器，支持灵活的子网段分配
   - 验证：检查客户端管理模块是否支持新的地址分配
   ```bash
   # 检查客户端地址分配功能
   grep -c "get_current_ipv6_network\|client_subnet_mask" modules/client_management.sh
   # 应该返回 2
   ```

9. **子网段配置说明**
   - 支持范围：/56 到 /72 的IPv6子网段
   - 自动分配：根据网络前缀自动确定客户端子网掩码
   - 配置示例：
     - /56网络 → 客户端使用/64子网掩码
     - /64网络 → 客户端使用/72子网掩码
     - /72网络 → 客户端使用/80子网掩码

10. **WireGuard服务启动失败**
    - 问题：WireGuard服务启动失败，显示"control process exited with error code"
    - 解决：使用以下步骤诊断和修复
    
    **快速修复（推荐）**
    ```bash
    # 使用自动修复脚本
    sudo ./fix_wireguard_service.sh
    ```
    
    **手动诊断步骤**
    ```bash
    # 1. 查看详细错误信息
    sudo systemctl status wg-quick@wg0.service
    sudo journalctl -xeu wg-quick@wg0.service
    
    # 2. 检查配置文件
    sudo cat /etc/wireguard/wg0.conf
    
    # 3. 检查配置文件语法
    sudo wg-quick strip wg0
    
    # 4. 检查网络接口
    ip link show wg0
    
    # 5. 检查端口占用
    sudo netstat -tulpn | grep 51820
    ```
    
    **常见解决方案**
    ```bash
    # 方案1：重新生成配置
    ipv6-wg-manager
    # 选择：3. 服务器管理 -> 重新配置 WireGuard
    
    # 方案2：修复权限问题
    sudo chmod 600 /etc/wireguard/wg0.conf
    sudo chown root:root /etc/wireguard/wg0.conf
    
    # 方案3：启用IPv6支持
    echo 0 | sudo tee /proc/sys/net/ipv6/conf/all/disable_ipv6
    echo 1 | sudo tee /proc/sys/net/ipv6/conf/all/forwarding
    
    # 方案4：加载WireGuard模块
    sudo modprobe wireguard
    
    # 方案5：检查防火墙设置
    sudo ufw allow 51820/udp
    sudo ufw reload
    
    # 方案6：修复IPv6配置
    sudo ./fix_ipv6_config.sh
    ```
    
    **验证修复**
    ```bash
    # 启动服务
    sudo systemctl start wg-quick@wg0.service
    
    # 检查状态
    sudo systemctl status wg-quick@wg0.service
    sudo wg show
    ```

### 日志检查

```bash
# 查看系统日志
sudo journalctl -u wireguard
sudo journalctl -u bird2  # BIRD 2.x
sudo journalctl -u bird   # BIRD 1.x

# 查看安装日志
tail -f /var/log/ipv6-wireguard-manager.log
```

## 卸载

如果需要卸载IPv6 WireGuard Manager：

```bash
sudo ./uninstall.sh
```

卸载脚本将：
- 停止相关服务
- 删除配置文件
- 删除符号链接
- 清理安装文件

## 更新

### 自动更新

```bash
# 使用管理器内置的更新功能
ipv6-wg-manager
# 选择 "9. 更新检查"
```

### 手动更新

```bash
# 下载最新版本
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/ipv6-wireguard-manager-core.sh
chmod +x ipv6-wireguard-manager-core.sh

# 重启服务
sudo systemctl restart wireguard
sudo systemctl restart bird2  # BIRD 2.x
sudo systemctl restart bird   # BIRD 1.x
```

## 安全建议

1. **定期更新系统**
2. **使用强密码**
3. **配置防火墙规则**
4. **定期备份配置**
5. **监控系统日志**
6. **使用HTTPS连接**

## 支持

如果遇到问题，请：

1. 查看本文档的故障排除部分
2. 检查系统日志
3. 在GitHub Issues中报告问题
4. 提供详细的错误信息和系统环境

---

**推荐**: 使用模块化版本 `./ipv6-wireguard-manager-core.sh` 获得最佳性能体验。