# 自动下载必需文件功能示例

## 概述

IPv6 WireGuard Manager 现在支持自动下载必需文件功能，当检测到缺失的模块或必需文件时，可以自动从 GitHub 下载并安装。

## 功能特性

### 1. 智能检测
- 自动检测缺失的模块文件
- 检查文件完整性
- 报告具体的缺失文件列表

### 2. 一键下载
- 从 GitHub 自动下载所有必需文件
- 支持 17 个核心文件（14 个模块 + 3 个主脚本）
- 自动设置正确的文件权限

### 3. 网络容错
- 支持部分下载失败时的重试机制
- 显示下载进度和结果统计
- 提供详细的错误信息

## 使用方法

### 方法1: 自动触发

当脚本检测到缺失文件时，会自动提示下载：

```bash
# 运行主脚本
./ipv6-wireguard-manager.sh

# 输出示例：
# 警告: 未找到模块目录，尝试自动下载必需文件...
# 正在下载必需文件...
#   下载 system_detection.sh... ✓
#   下载 wireguard_config.sh... ✓
#   下载 bird_config.sh... ✓
#   ...
# 下载完成: 17/17 个文件
# 所有必需文件下载成功！
```

### 方法2: 手动触发

通过主菜单选择下载选项：

```bash
# 运行主脚本
./ipv6-wireguard-manager.sh

# 选择菜单选项：10. 下载必需文件
# 系统会检查文件完整性并提示下载
```

## 下载的文件列表

### 核心模块 (14个)
- `modules/system_detection.sh` - 系统检测模块
- `modules/wireguard_config.sh` - WireGuard 配置模块
- `modules/bird_config.sh` - BIRD 配置模块
- `modules/firewall_config.sh` - 防火墙配置模块
- `modules/client_management.sh` - 客户端管理模块
- `modules/network_management.sh` - 网络管理模块
- `modules/server_management.sh` - 服务器管理模块
- `modules/system_maintenance.sh` - 系统维护模块
- `modules/backup_restore.sh` - 备份恢复模块
- `modules/update_management.sh` - 更新管理模块
- `modules/wireguard_diagnostics.sh` - WireGuard 诊断模块
- `modules/bird_permissions.sh` - BIRD 权限模块
- `modules/client_script_generator.sh` - 客户端脚本生成模块
- `modules/client_auto_update.sh` - 客户端自动更新模块

### 主脚本 (3个)
- `ipv6-wireguard-manager.sh` - 主管理脚本
- `ipv6-wireguard-manager-core.sh` - 核心脚本
- `install.sh` - 安装脚本
- `uninstall.sh` - 卸载脚本

## 使用场景

### 1. 首次安装
```bash
# 只下载了主脚本，缺少模块
wget https://raw.githubusercontent.com/your-repo/ipv6-wireguard-manager/main/ipv6-wireguard-manager.sh
chmod +x ipv6-wireguard-manager.sh
./ipv6-wireguard-manager.sh

# 系统自动检测并下载缺失的模块
```

### 2. 模块损坏
```bash
# 某个模块文件损坏或丢失
rm modules/client_management.sh
./ipv6-wireguard-manager.sh

# 系统检测到缺失文件，自动下载
```

### 3. 更新后缺失文件
```bash
# 更新后某些文件可能缺失
git pull
./ipv6-wireguard-manager.sh

# 系统自动检查并下载缺失文件
```

## 配置选项

### GitHub 仓库地址
```bash
# 在脚本中配置 GitHub 仓库地址
github_base_url="https://raw.githubusercontent.com/your-repo/ipv6-wireguard-manager/main"
```

### 下载超时设置
```bash
# 设置下载超时时间（秒）
curl -s -L --connect-timeout 10 --max-time 30
```

## 错误处理

### 网络连接问题
```bash
# 输出示例：
# 下载 system_detection.sh... ✗
# 下载 wireguard_config.sh... ✗
# ...
# 下载完成: 0/17 个文件
# 文件下载失败，请检查网络连接
```

### 部分下载失败
```bash
# 输出示例：
# 下载 system_detection.sh... ✓
# 下载 wireguard_config.sh... ✗
# 下载 bird_config.sh... ✓
# ...
# 下载完成: 15/17 个文件
# 部分文件下载成功，请检查网络连接后重试
```

### 权限问题
```bash
# 输出示例：
# 下载 system_detection.sh... ✓
# 设置权限失败，但文件已下载
# ...
```

## 最佳实践

### 1. 网络环境
- 确保网络连接稳定
- 如果使用代理，配置正确的代理设置
- 检查防火墙是否阻止了 GitHub 访问

### 2. 权限设置
- 确保脚本有写入权限
- 检查目录权限设置
- 验证 curl 命令可用

### 3. 错误排查
```bash
# 检查网络连接
ping github.com

# 检查 curl 可用性
curl --version

# 手动测试下载
curl -I https://raw.githubusercontent.com/your-repo/ipv6-wireguard-manager/main/modules/system_detection.sh
```

## 故障排除

### 问题1: 下载失败
**原因**: 网络连接问题或 GitHub 访问受限
**解决**: 检查网络连接，配置代理或使用镜像源

### 问题2: 权限错误
**原因**: 脚本没有写入权限
**解决**: 使用 `chmod +x` 设置执行权限，或使用 `sudo` 运行

### 问题3: 文件不完整
**原因**: 下载过程中断或文件损坏
**解决**: 重新运行下载功能，或手动下载缺失文件

### 问题4: 模块加载失败
**原因**: 下载的文件格式不正确或权限问题
**解决**: 检查文件内容，重新设置权限

## 技术细节

### 下载机制
- 使用 `curl` 命令下载文件
- 支持 HTTP 重定向
- 自动设置文件权限
- 清理临时文件

### 完整性检查
- 检查文件是否存在
- 验证文件大小
- 确认文件权限

### 错误处理
- 网络超时处理
- 权限错误处理
- 部分下载处理
- 用户友好的错误信息

## 总结

自动下载必需文件功能大大简化了 IPv6 WireGuard Manager 的部署和维护：

- ✅ **零配置部署**: 只需下载主脚本即可
- ✅ **自动修复**: 自动检测并修复缺失文件
- ✅ **网络容错**: 支持各种网络环境
- ✅ **用户友好**: 提供清晰的进度和错误信息
- ✅ **维护简单**: 自动保持文件完整性

这使得 IPv6 WireGuard Manager 成为一个真正"开箱即用"的 VPN 管理解决方案！
