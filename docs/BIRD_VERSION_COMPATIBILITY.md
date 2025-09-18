# BIRD版本兼容性说明

## 概述

IPv6 WireGuard Manager 支持多个版本的BIRD BGP路由守护进程，确保在不同Linux发行版上的兼容性和最佳性能。

## 重要更新

**BIRD版本默认设置**: 从版本1.11开始，系统默认优先安装BIRD 2.x版本，如果BIRD 2.x不可用，则自动回退到BIRD 1.x版本。这确保了更好的性能和功能支持。

## 支持的BIRD版本

### BIRD 2.x (推荐/默认)
- **版本**: 2.0.x 系列
- **状态**: 推荐版本，默认安装
- **特点**: 
  - 更好的性能和稳定性
  - 改进的配置语法
  - 增强的BGP功能
  - 更好的IPv6支持
- **包名**: `bird2`
- **服务名**: `bird2`
- **控制台**: `birdc2`

### BIRD 1.x (兼容/回退)
- **版本**: 1.6.x 系列
- **状态**: 兼容版本，自动回退
- **特点**:
  - 稳定可靠
  - 广泛支持
  - 成熟的功能集
- **包名**: `bird`
- **服务名**: `bird`
- **控制台**: `birdc`

### BIRD 3.x (实验性)
- **版本**: 3.0.x 系列
- **状态**: 实验性支持
- **特点**:
  - 最新功能
  - 可能不稳定
  - 需要手动安装
- **包名**: `bird3` (如果可用)
- **服务名**: `bird3`
- **控制台**: `birdc3`

## 版本检测机制

### 安装优先级

系统按以下优先级安装BIRD版本：

1. **优先尝试BIRD 2.x**
   ```bash
   # Ubuntu/Debian
   apt install -y bird2
   
   # CentOS/RHEL/Fedora/Rocky/AlmaLinux
   yum install -y bird2
   
   # Arch Linux
   pacman -S bird2
   ```

2. **回退到BIRD 1.x**
   ```bash
   # 如果BIRD 2.x安装失败
   apt install -y bird
   yum install -y bird
   pacman -S bird
   ```

### 版本检测函数

系统使用以下逻辑检测已安装的BIRD版本：

```bash
# 检测BIRD版本
detect_bird_version() {
    if command -v birdc2 >/dev/null 2>&1; then
        echo "bird2"
    elif command -v birdc >/dev/null 2>&1; then
        echo "bird1"
    else
        echo "none"
    fi
}
```

### 服务管理适配

系统自动适配不同版本的服务管理：

```bash
# 服务状态检查
check_bird_service() {
    local bird_version=$(detect_bird_version)
    case $bird_version in
        "bird2")
            systemctl is-active bird2
            ;;
        "bird1")
            systemctl is-active bird
            ;;
        *)
            echo "BIRD未安装"
            ;;
    esac
}
```

## 发行版支持

### Ubuntu/Debian
- **BIRD 2.x**: 默认可用
- **BIRD 1.x**: 默认可用
- **安装命令**: `apt install -y bird2` 或 `apt install -y bird`

### CentOS/RHEL/Fedora/Rocky/AlmaLinux
- **BIRD 2.x**: 需要EPEL仓库
- **BIRD 1.x**: 默认可用
- **安装命令**: `yum install -y bird2` 或 `yum install -y bird`

### Arch Linux
- **BIRD 2.x**: 默认可用
- **BIRD 1.x**: 默认可用
- **安装命令**: `pacman -S bird2` 或 `pacman -S bird`

## 配置文件兼容性

### BIRD 2.x配置
```bash
# /etc/bird/bird.conf
router id 192.168.1.1;

protocol device {
    scan time 10;
}

protocol direct {
    interface "wg*";
}

protocol bgp {
    local as 65001;
    neighbor 192.168.1.2 as 65002;
    import all;
    export all;
}
```

### BIRD 1.x配置
```bash
# /etc/bird/bird.conf
router id 192.168.1.1;

protocol device {
    scan time 10;
}

protocol direct {
    interface "wg*";
}

protocol bgp {
    local as 65001;
    neighbor 192.168.1.2 as 65002;
    import all;
    export all;
}
```

## 控制台命令

### BIRD 2.x命令
```bash
# 查看协议状态
birdc2 show protocols

# 查看路由表
birdc2 show route

# 重载配置
birdc2 configure

# 查看BGP状态
birdc2 show protocols all bgp
```

### BIRD 1.x命令
```bash
# 查看协议状态
birdc show protocols

# 查看路由表
birdc show route

# 重载配置
birdc configure

# 查看BGP状态
birdc show protocols all bgp
```

## 服务管理

### 启动服务
```bash
# BIRD 2.x
sudo systemctl start bird2
sudo systemctl enable bird2

# BIRD 1.x
sudo systemctl start bird
sudo systemctl enable bird
```

### 停止服务
```bash
# BIRD 2.x
sudo systemctl stop bird2

# BIRD 1.x
sudo systemctl stop bird
```

### 重启服务
```bash
# BIRD 2.x
sudo systemctl restart bird2

# BIRD 1.x
sudo systemctl restart bird
```

### 查看服务状态
```bash
# BIRD 2.x
sudo systemctl status bird2

# BIRD 1.x
sudo systemctl status bird
```

## 日志管理

### 查看日志
```bash
# BIRD 2.x
sudo journalctl -u bird2 -f

# BIRD 1.x
sudo journalctl -u bird -f
```

### 日志文件位置
```bash
# BIRD 2.x
/var/log/bird2.log

# BIRD 1.x
/var/log/bird.log
```

## 性能对比

| 特性 | BIRD 1.x | BIRD 2.x | BIRD 3.x |
|------|----------|----------|----------|
| 稳定性 | 优秀 | 优秀 | 良好 |
| 性能 | 良好 | 优秀 | 优秀 |
| 功能 | 完整 | 完整 | 最新 |
| 配置语法 | 传统 | 改进 | 最新 |
| 社区支持 | 广泛 | 广泛 | 有限 |
| 推荐程度 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |

## 升级指南

### 从BIRD 1.x升级到BIRD 2.x

1. **备份配置**
   ```bash
   sudo cp /etc/bird/bird.conf /etc/bird/bird.conf.backup
   ```

2. **停止BIRD 1.x**
   ```bash
   sudo systemctl stop bird
   sudo systemctl disable bird
   ```

3. **安装BIRD 2.x**
   ```bash
   sudo apt install -y bird2  # Ubuntu/Debian
   sudo yum install -y bird2  # CentOS/RHEL/Fedora
   sudo pacman -S bird2       # Arch Linux
   ```

4. **迁移配置**
   ```bash
   sudo cp /etc/bird/bird.conf /etc/bird2/bird.conf
   ```

5. **启动BIRD 2.x**
   ```bash
   sudo systemctl start bird2
   sudo systemctl enable bird2
   ```

6. **验证配置**
   ```bash
   sudo birdc2 show protocols
   ```

### 从BIRD 2.x降级到BIRD 1.x

1. **备份配置**
   ```bash
   sudo cp /etc/bird2/bird.conf /etc/bird2/bird.conf.backup
   ```

2. **停止BIRD 2.x**
   ```bash
   sudo systemctl stop bird2
   sudo systemctl disable bird2
   ```

3. **安装BIRD 1.x**
   ```bash
   sudo apt install -y bird  # Ubuntu/Debian
   sudo yum install -y bird  # CentOS/RHEL/Fedora
   sudo pacman -S bird       # Arch Linux
   ```

4. **迁移配置**
   ```bash
   sudo cp /etc/bird2/bird.conf /etc/bird/bird.conf
   ```

5. **启动BIRD 1.x**
   ```bash
   sudo systemctl start bird
   sudo systemctl enable bird
   ```

6. **验证配置**
   ```bash
   sudo birdc show protocols
   ```

## 故障排除

### 常见问题

1. **BIRD服务启动失败**
   ```bash
   # 检查配置文件语法
   sudo birdc2 configure check  # BIRD 2.x
   sudo birdc configure check   # BIRD 1.x
   ```

2. **BGP邻居连接失败**
   ```bash
   # 检查BGP状态
   sudo birdc2 show protocols all bgp  # BIRD 2.x
   sudo birdc show protocols all bgp   # BIRD 1.x
   ```

3. **路由不生效**
   ```bash
   # 检查路由表
   sudo birdc2 show route  # BIRD 2.x
   sudo birdc show route   # BIRD 1.x
   ```

4. **配置文件错误**
   ```bash
   # 检查配置文件
   sudo birdc2 configure check  # BIRD 2.x
   sudo birdc configure check   # BIRD 1.x
   ```

### 调试命令

```bash
# 启用调试模式
sudo birdc2 configure debug all  # BIRD 2.x
sudo birdc configure debug all   # BIRD 1.x

# 查看详细状态
sudo birdc2 show protocols all  # BIRD 2.x
sudo birdc show protocols all   # BIRD 1.x

# 查看路由详情
sudo birdc2 show route all  # BIRD 2.x
sudo birdc show route all   # BIRD 1.x
```

## 最佳实践

1. **使用BIRD 2.x**: 推荐使用BIRD 2.x版本，获得更好的性能和功能
2. **定期更新**: 保持BIRD版本更新，获得最新的安全补丁和功能
3. **配置备份**: 定期备份BIRD配置文件
4. **监控日志**: 定期检查BIRD日志，及时发现和解决问题
5. **测试配置**: 在生产环境部署前，先在测试环境验证配置
6. **版本兼容**: 确保BGP邻居支持相同的BIRD版本或兼容版本

## 总结

IPv6 WireGuard Manager 通过智能的版本检测和自动回退机制，确保在不同Linux发行版上都能正常工作。推荐使用BIRD 2.x版本，它提供了更好的性能和功能，同时保持与BIRD 1.x的兼容性。

---

**推荐**: 使用BIRD 2.x版本获得最佳性能和功能体验。