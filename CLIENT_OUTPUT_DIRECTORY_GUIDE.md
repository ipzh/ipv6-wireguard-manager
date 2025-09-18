# 客户端输出目录管理指南

## 功能概述

IPv6 WireGuard Manager 现在支持灵活的客户端输出目录管理，用户可以选择使用默认安装目录或手动指定目录。

## 默认输出目录

### 默认路径
- **默认目录**: `/opt/ipv6-wireguard-manager/client-packages`
- **自动创建**: 如果目录不存在，系统会自动创建
- **权限设置**: 目录权限设置为 755，确保可访问性

### 目录结构
```
/opt/ipv6-wireguard-manager/client-packages/
├── client1/
│   ├── install-linux.sh
│   ├── install-windows.ps1
│   ├── client1.conf
│   ├── update-config.json
│   ├── qr-code.png
│   └── README.txt
├── client2/
│   ├── install-linux.sh
│   ├── install-windows.ps1
│   ├── client2.conf
│   ├── update-config.json
│   ├── qr-code.png
│   └── README.txt
└── ...
```

## 使用方法

### 1. 生成客户端包

#### 方法1：使用默认目录
```bash
# 进入客户端管理菜单
sudo ipv6-wg-manager
# 选择 "5. 生成客户端配置包" 或 "6. 生成客户端安装包"
# 选择 "1. 使用默认安装目录"
```

#### 方法2：手动指定目录
```bash
# 进入客户端管理菜单
sudo ipv6-wg-manager
# 选择 "5. 生成客户端配置包" 或 "6. 生成客户端安装包"
# 选择 "2. 手动输入目录"
# 输入自定义目录路径
```

### 2. 客户端输出目录管理

#### 进入管理界面
```bash
sudo ipv6-wg-manager
# 选择 "3. 客户端管理"
# 选择 "13. 客户端输出目录管理"
```

#### 管理功能
1. **查看目录内容** - 显示目录中的文件和子目录
2. **创建默认目录** - 如果目录不存在，自动创建
3. **清理目录内容** - 删除目录中的所有文件（谨慎使用）
4. **更改默认目录** - 设置新的默认目录（当前会话有效）
5. **批量生成所有客户端包** - 为所有客户端生成包到默认目录

### 3. 命令行使用

#### 直接调用函数
```bash
# 获取默认目录
default_dir=$(get_default_client_output_dir)
echo "默认目录: $default_dir"

# 确保目录存在
ensure_client_output_dir "/custom/path"

# 生成客户端包到指定目录
generate_client_installer_package "client1" "/custom/output/path"
```

## 配置选项

### 环境变量
```bash
# 设置自定义默认目录（可选）
export CLIENT_OUTPUT_DIR="/custom/client/packages"

# 在脚本中使用
if [[ -n "$CLIENT_OUTPUT_DIR" ]]; then
    output_dir="$CLIENT_OUTPUT_DIR"
else
    output_dir=$(get_default_client_output_dir)
fi
```

### 配置文件
可以在 `/etc/ipv6-wireguard/manager.conf` 中添加：
```ini
[client_output]
default_directory = /opt/ipv6-wireguard-manager/client-packages
auto_create = true
```

## 目录管理功能详解

### 1. 查看目录内容
- 显示目录中的文件和子目录
- 显示文件数量、目录大小等统计信息
- 支持分页显示（超过20个文件时）

### 2. 创建默认目录
- 自动创建默认目录结构
- 设置正确的权限（755）
- 记录创建日志

### 3. 清理目录内容
- **警告**: 此操作会删除目录中的所有文件
- 需要用户确认操作
- 保留目录结构，只删除文件

### 4. 更改默认目录
- 设置新的默认目录路径
- 仅在当前会话中有效
- 持久化设置需要修改配置文件

### 5. 批量生成客户端包
- 为所有现有客户端生成安装包
- 自动使用默认目录
- 显示生成进度和结果

## 最佳实践

### 1. 目录选择建议
- **默认目录**: 适合大多数用户，便于管理
- **自定义目录**: 适合有特殊需求或组织环境
- **网络共享目录**: 可以设置为网络共享路径

### 2. 权限管理
```bash
# 设置目录权限
sudo chmod 755 /opt/ipv6-wireguard-manager/client-packages

# 设置所有者
sudo chown -R root:root /opt/ipv6-wireguard-manager/client-packages
```

### 3. 备份策略
```bash
# 备份客户端包目录
tar -czf client-packages-backup-$(date +%Y%m%d).tar.gz /opt/ipv6-wireguard-manager/client-packages

# 定期清理旧文件
find /opt/ipv6-wireguard-manager/client-packages -type f -mtime +30 -delete
```

### 4. 网络共享
```bash
# 通过HTTP服务器共享
cd /opt/ipv6-wireguard-manager/client-packages
python3 -m http.server 8000

# 通过SCP下载
scp -r /opt/ipv6-wireguard-manager/client-packages user@client-ip:/tmp/
```

## 故障排除

### 常见问题

1. **目录创建失败**
   - 检查权限：确保有创建目录的权限
   - 检查路径：确保父目录存在
   - 检查磁盘空间：确保有足够的磁盘空间

2. **文件生成失败**
   - 检查目录权限：确保有写入权限
   - 检查磁盘空间：确保有足够的空间
   - 检查客户端数据：确保客户端存在

3. **权限问题**
   ```bash
   # 修复权限
   sudo chown -R root:root /opt/ipv6-wireguard-manager/client-packages
   sudo chmod -R 755 /opt/ipv6-wireguard-manager/client-packages
   ```

### 调试命令

```bash
# 检查目录状态
ls -la /opt/ipv6-wireguard-manager/client-packages

# 检查磁盘空间
df -h /opt/ipv6-wireguard-manager/

# 检查权限
stat /opt/ipv6-wireguard-manager/client-packages

# 测试目录创建
mkdir -p /tmp/test-client-packages
```

## 高级用法

### 1. 自定义目录结构
```bash
# 创建自定义目录结构
mkdir -p /custom/client-packages/{linux,windows,mobile}
```

### 2. 自动化脚本
```bash
#!/bin/bash
# 自动生成所有客户端包
for client in $(grep -v "^#" /etc/ipv6-wireguard/clients.db | cut -d'|' -f1); do
    generate_client_installer_package "$client" "/custom/output"
done
```

### 3. 集成到CI/CD
```yaml
# GitHub Actions 示例
- name: Generate client packages
  run: |
    sudo ipv6-wg-manager << EOF
    3
    13
    5
    0
    0
    EOF
```

## 总结

客户端输出目录管理功能提供了：

- ✅ **灵活的目录选择**: 默认目录或自定义目录
- ✅ **自动目录创建**: 无需手动创建目录
- ✅ **完整的目录管理**: 查看、创建、清理、更改
- ✅ **批量操作**: 一次性生成所有客户端包
- ✅ **权限管理**: 自动设置正确的权限
- ✅ **用户友好**: 直观的菜单界面

这个功能大大简化了客户端包的管理和分发，提高了工作效率。

---

**最后更新**: 2024年1月
**版本**: 1.0.8
**状态**: 已实现 ✅
