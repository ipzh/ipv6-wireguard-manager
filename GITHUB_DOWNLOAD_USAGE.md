# GitHub 下载使用指南

## 📋 概述

本文档说明如何从GitHub直接下载和使用IPv6 WireGuard Manager的各种工具和脚本，无需本地克隆整个仓库。

## 🚀 主要工具下载使用

### 1. 智能安装脚本

```bash
# 一键安装（推荐）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 指定安装类型
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --type native --silent

# 智能安装演示
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/smart_install_demo.sh | bash
```

### 2. 后端错误检查和修复工具

```bash
# 后端错误检查器
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/backend_error_checker.py | python3 - --backend-path backend --verbose

# 生成详细报告
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/backend_error_checker.py | python3 - --backend-path backend --output backend_report.json

# 自动修复发现的问题
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/backend_error_checker.py | python3 - --backend-path backend --fix

# 后端错误修复器
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_backend_errors.py | python3 - --backend-path backend --verbose

# 干运行模式（仅检查，不修复）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_backend_errors.py | python3 - --backend-path backend --dry-run
```

### 3. 系统诊断和修复工具

```bash
# 系统兼容性测试
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/test_system_compatibility.sh | bash

# 深度API诊断
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/deep_api_diagnosis.sh | bash

# 综合API修复
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/comprehensive_api_fix.sh | bash

# Debian 12 环境修复
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_debian12_environment.sh | bash

# Apache依赖问题修复
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_apache_dependency_issue.sh | bash

# 仅安装PHP-FPM（避免Apache依赖）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install_php_fpm_only.sh | bash
```

### 4. 权限和配置修复工具

```bash
# 修复权限问题
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_permissions.sh | bash

# 快速修复WireGuard权限
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/quick_fix_wireguard_permissions.sh | bash

# 清理Apache配置
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/cleanup_apache_configs.sh | bash

# 修复PHP-FPM服务
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_php_fpm.sh | bash
```

### 5. 服务管理工具

```bash
# 检查API服务状态
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/check_api_service.sh | bash

# 修复API服务问题
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_api_service.sh | bash

# 诊断服务问题
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/diagnose_service.sh | bash

# 快速修复服务
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/quick_fix_service.sh | bash
```

## 🔧 使用说明

### 基本语法

```bash
# 下载并执行脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/SCRIPT_NAME | bash

# 下载并执行Python脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/SCRIPT_NAME.py | python3 - [参数]

# 下载到本地文件
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/SCRIPT_NAME -o SCRIPT_NAME
chmod +x SCRIPT_NAME
./SCRIPT_NAME
```

### 参数说明

- `-f`: 静默失败（不显示HTTP错误）
- `-s`: 静默模式（不显示进度）
- `-S`: 显示错误（与-s结合使用）
- `-L`: 跟随重定向

### 安全注意事项

1. **验证脚本来源**: 确保从官方GitHub仓库下载
2. **检查脚本内容**: 在执行前可以查看脚本内容
3. **备份重要数据**: 在执行修复脚本前备份重要数据
4. **测试环境**: 建议先在测试环境中验证

## 📋 常用组合命令

### 1. 完整系统诊断

```bash
# 系统兼容性检查
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/test_system_compatibility.sh | bash

# 后端错误检查
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/backend_error_checker.py | python3 - --backend-path backend --output system_check.json

# API服务检查
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/check_api_service.sh | bash
```

### 2. 自动修复流程

```bash
# 1. 检查问题
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/backend_error_checker.py | python3 - --backend-path backend --output before_fix.json

# 2. 自动修复
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_backend_errors.py | python3 - --backend-path backend --verbose

# 3. 验证修复结果
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/backend_error_checker.py | python3 - --backend-path backend --output after_fix.json

# 4. 比较结果
diff before_fix.json after_fix.json
```

### 3. 环境问题修复

```bash
# Debian 12 环境修复
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_debian12_environment.sh | bash

# Apache依赖问题修复
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_apache_dependency_issue.sh | bash

# 权限问题修复
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_permissions.sh | bash
```

## 🛠️ 故障排除

### 1. 下载失败

```bash
# 检查网络连接
ping github.com

# 使用wget替代curl
wget -qO- https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 检查DNS解析
nslookup raw.githubusercontent.com
```

### 2. 权限问题

```bash
# 确保有执行权限
chmod +x script_name

# 使用sudo执行
sudo bash script_name

# 检查用户权限
whoami
groups
```

### 3. Python脚本问题

```bash
# 检查Python版本
python3 --version

# 检查Python路径
which python3

# 使用完整路径
/usr/bin/python3 script.py
```

## 📚 相关文档

- [安装指南](INSTALLATION_GUIDE.md)
- [后端错误修复指南](BACKEND_ERROR_FIX_GUIDE.md)
- [后端安装故障排除](BACKEND_INSTALLATION_TROUBLESHOOTING.md)
- [Debian 12 修复指南](DEBIAN12_FIX_GUIDE.md)

## 🔄 更新说明

### 最新版本特性

- ✅ 所有工具都支持从GitHub直接下载使用
- ✅ 无需本地克隆整个仓库
- ✅ 自动获取最新版本的工具
- ✅ 支持参数传递和输出重定向
- ✅ 提供完整的错误处理和日志记录

### 版本兼容性

- **Python**: 3.8+ (推荐 3.11+)
- **Bash**: 4.0+
- **curl**: 7.0+
- **wget**: 1.12+ (可选)

## 🆘 获取帮助

如果遇到问题，请：

1. 检查网络连接和DNS解析
2. 验证脚本URL是否正确
3. 查看错误日志和输出信息
4. 参考相关文档和故障排除指南
5. 联系技术支持团队

```bash
# 收集系统信息用于故障排除
echo "系统信息:"
uname -a
python3 --version
curl --version
echo "网络连接测试:"
ping -c 3 github.com
```
